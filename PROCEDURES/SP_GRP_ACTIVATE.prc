CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Activate (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 29/APR/2010
     * Created By        : sagar more
     * PURPOSE          : Group activate Card
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
AS
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;
   v_cardstat               CMS_APPL_PAN.cap_card_stat%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_cardstatdesc           VARCHAR2 (10);
   v_mbrnumb                VARCHAR2 (3)                        DEFAULT '000';
   v_rrn                    VARCHAR2 (12);
   v_stan                   VARCHAR2 (12);
   v_authmsg                VARCHAR2 (300);
   v_card_curr              VARCHAR2 (3);
   v_errmsg                 VARCHAR2 (300);
   v_htlstsavepoint         NUMBER (9)                             DEFAULT 99;
   v_errflag                CHAR (1);
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_prod_catg              CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   exp_loop_reject_record   EXCEPTION;

    v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;



   CURSOR c1
   IS
      SELECT TRIM (cga_card_no) cga_pan_code, cga_file_name, cga_remarks,
             cga_mbr_numb, CGA_CARD_NO_ENCR,
             ROWID
        FROM CMS_GROUP_actvtcard_TEMP
       WHERE cga_process_flag = 'N';
---------------------------------SN Start hot listing of given card  -----------------------------------------
BEGIN
   prm_errmsg := 'OK';
   v_remark := 'Group Activate';

   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ACTVTCARD';
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   ------------------------------ En get Function Master----------------------------
   
   ------------------------------Sn get reason code from support reason master--------------------
    BEGIN
       SELECT csr_spprt_rsncode,csr_reasondesc
         INTO v_resoncode, v_reasondesc
         FROM CMS_SPPRT_REASONS
        WHERE csr_spprt_key = 'ACTVTCARD' AND ROWNUM < 2;
    EXCEPTION
       WHEN VALUE_ERROR
       THEN
          prm_errmsg := 'ACTIVATE  reason code not present in master ';
          RAISE exp_loop_reject_record;
       WHEN NO_DATA_FOUND
       THEN
          prm_errmsg := 'ACTIVATE  reason code not present in master';
          RAISE exp_loop_reject_record;
       WHEN OTHERS
       THEN
          prm_errmsg :=
                'Error while selecting reason code from master'
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_loop_reject_record;
    END;

    ------------------------------En get reason code from support reason master---------------------

   FOR x IN c1
   LOOP
      ------------------------Sn find the pan details Cursor loop Begin---------------------------------------
      BEGIN                                             -- << LOOP I BEGIN >>
         v_htlstsavepoint := v_htlstsavepoint + 1;
         SAVEPOINT v_htlstsavepoint;
         v_errmsg := 'OK';
          prm_errmsg := 'OK';
          
          --SN create decr pan
BEGIN
    v_decr_pan := Fn_Dmaps_Main(x.cga_pan_code);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan

--------------------------
         BEGIN
            SELECT cap_prod_catg
              INTO v_prod_catg
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = x.cga_pan_code
               AND cap_mbr_numb = x.cga_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'No product category dfined for the card';
               RAISE exp_loop_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;

         -------------------------Sn Find the card status, is open or not-------------------------------------
         IF v_prod_catg = 'P'
         THEN
            BEGIN
               SELECT cap_card_stat
                 INTO v_cardstat
                 FROM CMS_APPL_PAN
                WHERE cap_pan_code = x.cga_pan_code
                  AND cap_mbr_numb = x.cga_mbr_numb;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  prm_errmsg := 'No Status defined For Given card';
                  RAISE exp_loop_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'No Status defined For Given card';
                  -- RETURN;
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  --RETURN;
                  RAISE exp_loop_reject_record;
            END;

------------------------------En Find the card status, is open or not---------------------------

            ------------------------------ Sn get rrn----------------------------------------------
            BEGIN
               SELECT LPAD (seq_auth_rrn.NEXTVAL, 12, '0')
                 INTO v_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  --RETURN;
                  RAISE exp_loop_reject_record;
            END;

------------------------------En get rrn---------------------------------------

            ------------------------------ Sn get STAN----------------------------
            BEGIN
               SELECT LPAD (seq_auth_stan.NEXTVAL, 6, '0')
                 INTO v_stan
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  --RAISE exp_loop_reject_record;
                  RETURN;
            END;

------------------------------En get STAN-------------------------------------------------

            --------------------------------Sn get card currency ----------------------------
            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_CATTYPE
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = x.cga_pan_code
                  AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  prm_errmsg := 'Currency not defined for the card ';
                  RAISE exp_loop_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'Currency not defined for the card';
                  --RETURN;
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting Currency code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get card currency---------------------------------------------


            ------------------------------Sn Call Sp_hotlist for hot listing pan----------------------------
            IF (v_cardstat = 1) OR (v_cardstat = 2) OR (v_cardstat = 3)
            THEN
               Sp_ACTIVATE_Pan (prm_instcode,                      --prm_instcode
                            -- x.cga_pan_code,                     --prm_pancode
                            v_decr_pan,
                             x.cga_mbr_numb,                     --prm_mbrnumb
                             x.cga_remarks,                      -- prm_remark
                             v_resoncode,                        --prm_rsncode
                             v_rrn,                                  --prm_rrn
                             'offline',                       --prm_terminalid
                             v_stan,                               -- prm_stan
                             TO_CHAR (SYSDATE, 'YYYYMMDD'),     --prm_trandate
                             TO_CHAR (SYSDATE, 'HH24:MI:SS'),   --prm_trantime
                           --  x.cga_pan_code,                      --prm_acctno
                           v_decr_pan,
                             x.cga_file_name,                   --prm_filename
                             0,                                   --prm_amount
                             NULL,                                 --prm_refno
                             NULL,                           --prm_paymentmode
                             NULL,                          --prm_instrumentno
                             NULL,                             --prm_drawndate
                             v_card_curr,                      -- prm_currcode
                             prm_lupduser,                      --prm_lupduser
                             1,                                 --prm_workmode
                             v_authmsg,                     --prm_auth_message
                             prm_errmsg                           --prm_errmsg
                            );

               IF prm_errmsg <> 'OK'
               THEN
                  v_succ_flag := 'E';
                  RAISE exp_loop_reject_record;
               ELSIF prm_errmsg = 'OK' AND v_authmsg = 'OK'
               THEN
                  v_errflag := 'S';
                  v_succ_flag := 'S';
                  prm_errmsg := 'Successful';

                  UPDATE CMS_GROUP_ACTVTCARD_TEMP
                     SET cga_process_flag = 'S',
                         cga_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               ELSIF prm_errmsg = 'OK' AND v_authmsg <> 'OK'
               THEN
                  v_errflag := 'E';
                  v_succ_flag := 'E';
                  prm_errmsg := v_authmsg;              
               --RAISE exp_loop_reject_record;
               END IF;

               BEGIN
                  INSERT INTO CMS_actvtcard_DETAIL
                              (cad_inst_code, cad_card_no,
                               cad_file_name, cad_remarks, cad_msg24_flag,
                               cad_process_flag, cad_process_msg,
                               cad_process_mode, cad_ins_user, cad_ins_date,
                               cad_lupd_user, cad_lupd_date,cad_card_no_encr
                              )
                       VALUES (prm_instcode, x.cga_pan_code,
                               x.cga_file_name, x.cga_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE,x.CGA_CARD_NO_ENCR
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_actvtcard_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_actvtcard_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cga_pan_code
                  || ' is not available  as Open  ';
               RAISE exp_loop_reject_record;
            END IF;
         ELSIF v_prod_catg = 'D'
         THEN
            ------------------------------Sn get reason code from support reason master--------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'ACTVTCARD' AND ROWNUM < 2;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  prm_errmsg :=
                              'ACTIVATE  reason code not present in master ';
                  RAISE exp_loop_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg :=
                               'ACTIVATE  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master---------------------
            BEGIN
               SELECT cap_card_stat
                 INTO v_cardstat
                 FROM CMS_APPL_PAN
                WHERE cap_pan_code = x.cga_pan_code
                  AND cap_mbr_numb = x.cga_mbr_numb;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  prm_errmsg := 'No Status defined For Given card';
                  RAISE exp_loop_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'No Status defined For Given card';
                  -- RETURN;
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  --RETURN;
                  RAISE exp_loop_reject_record;
            END;

            IF (v_cardstat = 1) OR (v_cardstat = 2) OR (v_cardstat = 3)
            THEN
               Sp_activate_Pan_Debit (prm_instcode,
                                 --  x.cga_pan_code,
                                 v_decr_pan,
                                   x.cga_mbr_numb,
                                   x.cga_remarks,
                                   v_resoncode,
                                   prm_lupduser,
                                   0,
                                   prm_errmsg
                                  );

               IF prm_errmsg <> 'OK'
               THEN
                  v_succ_flag := 'E';
                  RAISE exp_loop_reject_record;
               ELSIF prm_errmsg = 'OK'
               THEN
                  v_errflag := 'S';
                  v_succ_flag := 'S';
                  prm_errmsg := 'Successful';
                  UPDATE CMS_GROUP_ACTVTCARD_TEMP
                     SET cga_process_flag = 'S',
                         cga_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               END IF;

               BEGIN
                  INSERT INTO CMS_ACTVTCARD_DETAIL
                              (cad_inst_code, cad_card_no,
                               cad_file_name, cad_remarks, cad_msg24_flag,
                               cad_process_flag, cad_process_msg,
                               cad_process_mode, cad_ins_user, cad_ins_date,
                               cad_lupd_user, cad_lupd_date,cad_card_no_encr
                              )
                       VALUES (prm_instcode, x.cga_pan_code,
                               x.cga_file_name, x.cga_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE, x.CGA_CARD_NO_ENCR
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_actvtcard_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_actvtcard_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cga_pan_code
                  || ' is not available  as Open  ';
               RAISE exp_loop_reject_record;
            END IF;
         END IF;
      ------------------------------En Call Sp_hotlist for hot listing pan----------------------------
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_htlstsavepoint;
            v_succ_flag := 'E';

            UPDATE CMS_GROUP_ACTVTCARD_TEMP
               SET cga_process_flag = 'E',
                   cga_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;

            INSERT INTO CMS_ACTVTCARD_DETAIL
                        (cad_inst_code, cad_card_no, cad_file_name,
                         cad_remarks, cad_msg24_flag, cad_process_flag,
                         cad_process_msg, cad_process_mode, cad_ins_user,
                         cad_ins_date, cad_lupd_user, cad_lupd_date,cad_card_no_encr
                        )
                 VALUES (prm_instcode, x.cga_pan_code, x.cga_file_name,
                         x.cga_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE, x.CGA_CARD_NO_ENCR
                        );
         WHEN OTHERS
         THEN
            v_succ_flag := 'E';

            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_actvtcard_TEMP
               SET cga_process_flag = 'E',
                   cga_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;

            INSERT INTO CMS_actvtcard_DETAIL
                        (cad_inst_code, cad_card_no, cad_file_name,
                         cad_remarks, cad_msg24_flag, cad_process_flag,
                         cad_process_msg, cad_process_mode, cad_ins_user,
                         cad_ins_date, cad_lupd_user, cad_lupd_date,cad_card_no_encr
                        )
                 VALUES (prm_instcode, x.cga_pan_code, x.cga_file_name,
                         x.cga_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE, x.CGA_CARD_NO_ENCR
                        );
      END;

      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,
                      pal_inst_code,pal_card_no_encr
                     )
              VALUES (x.cga_pan_code, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      prm_errmsg, v_reasondesc, x.cga_remarks,
                      'G',
                      prm_instcode,x.CGA_CARD_NO_ENCR
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_ACTVTCARD_TEMP
               SET cga_process_flag = 'E',
                   cga_process_msg = 'Error while inserting into Audit log'
             WHERE ROWID = x.ROWID;
      END;
   END LOOP;                                             -- <<END loop begin>>

------------------------En find the pan details Cursor loop Begin---------------------------------------
   prm_errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Excp from sp_grp_dehotlist  -- ' || SQLERRM;
END;
---------------------------------EN End hot listing of given card  --------------------------------------
/


