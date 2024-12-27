CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Dehot (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,   
   prm_errmsg     OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date        : 27-May-2010
     * Created By          : Chinmaya Behera
     * PURPOSE             : Group deHotlist Card , only if ard is open
     * Modified By:        :
     * Modified Date       :
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
   v_dhtlstsavepoint        NUMBER (9)                             DEFAULT 99;
   v_errflag                CHAR (1);
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_prod_catg              CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
  
   exp_loop_reject_record   EXCEPTION;
   
    v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   CURSOR c1
   IS
      SELECT TRIM (cgd_card_no) cgd_pan_code, cgd_file_name, cgd_remarks,
             cgd_mbr_numb, cgd_card_no_encr,
             ROWID
        FROM CMS_GROUP_DEHOTLIST_TEMP
       WHERE cgd_process_flag = 'N'
       AND cgd_inst_code= prm_instcode;
---------------------------------SN Start hot listing of given card  -----------------------------------------
BEGIN
   prm_errmsg := 'OK';
   v_remark := 'Group DeHotlist';
   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'DHTLST'
       AND cfm_inst_code= prm_instcode;
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
        WHERE csr_spprt_key = 'DHTLST'
        AND csr_inst_code= prm_instcode 
        AND ROWNUM < 2;
    EXCEPTION
       WHEN VALUE_ERROR
       THEN
          prm_errmsg := 'Dehotlist  reason code not present in master ';
          RAISE exp_loop_reject_record;
       WHEN NO_DATA_FOUND
       THEN
          prm_errmsg := 'Dehotlist  reason code not present in master';
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
         v_dhtlstsavepoint := v_dhtlstsavepoint + 1;
         SAVEPOINT v_dhtlstsavepoint;
         v_errmsg := 'OK';
          prm_errmsg := 'OK';
     
     

--SN create decr pan
BEGIN
    v_decr_pan := Fn_Dmaps_Main(x.cgd_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan
--------------------------
         BEGIN
            SELECT cap_prod_catg,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
              INTO v_prod_catg,v_cardstat,v_applcode, v_acctno, v_prodcode
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = x.cgd_pan_code
               AND cap_mbr_numb = x.cgd_mbr_numb
               AND cap_inst_code=prm_instcode;
               
                      IF v_prod_catg IS NULL THEN
                   prm_errmsg := 'Product category not found in master for card no ';
                   RAISE exp_loop_reject_record;
                   END IF;
                   
         EXCEPTION
             WHEN exp_loop_reject_record THEN
            RAISE;
            
            WHEN NO_DATA_FOUND
            THEN
               prm_errmsg := 'Card not found in master';
               RAISE exp_loop_reject_record;
               
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while getting product catg and card status from appl pan table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;
         
                                 
         IF v_prod_catg = 'P'
         THEN 
         --NULL;
         --uncommented by siva on 18 mar 11 for prepaid dehot
         -------------------------Sn Find the card status, is open or not-------------------------------------
            BEGIN
               SELECT cap_card_stat
                 INTO v_cardstat
                 FROM CMS_APPL_PAN
                WHERE cap_pan_code = x.cgd_pan_code
                  AND cap_mbr_numb = x.cgd_mbr_numb
                  AND cap_inst_code= prm_instcode;
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
                  AND cap_pan_code = x.cgd_pan_code
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
            IF   (v_cardstat = 2) OR (v_cardstat = 3)
            THEN
               Sp_Dehot_Pan_prepaid (prm_instcode,                      --prm_instcode
                             v_decr_pan,                     --prm_pancode
                             x.cgd_mbr_numb,                     --prm_mbrnumb
                             x.cgd_remarks,                      -- prm_remark
                             v_resoncode,                        --prm_rsncode
                             v_rrn,                                  --prm_rrn
                             'offline',                       --prm_terminalid
                             v_stan,                               -- prm_stan
                             TO_CHAR (SYSDATE, 'YYYYMMDD'),     --prm_trandate
                             TO_CHAR (SYSDATE, 'HH24:MI:SS'),   --prm_trantime
                             v_decr_pan,                      --prm_acctno
                             x.cgd_file_name,                   --prm_filename
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
                  UPDATE CMS_GROUP_DEHOTLIST_TEMP
                     SET cgd_process_flag = 'S',
                         cgd_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               ELSIF prm_errmsg = 'OK' AND v_authmsg <> 'OK'
               THEN
                  v_errflag := 'E';
                  v_succ_flag := 'E';
                  prm_errmsg := v_authmsg;              
               --RAISE exp_loop_reject_record;
               END IF;
               BEGIN
                  INSERT INTO CMS_DEHOTLIST_DETAIL
                              (cdd_inst_code, cdd_card_no,
                               cdd_file_name, cdd_remarks, cdd_msg24_flag,
                               cdd_process_flag, cdd_process_msg,
                               cdd_process_mode, cdd_ins_user, cdd_ins_date,
                               cdd_lupd_user, cdd_lupd_date
                              )
                       VALUES (prm_instcode, x.cgd_pan_code,
                               x.cgd_file_name, x.cgd_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_dehotlist_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_dehotlist_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cgd_pan_code
                  || ' is not available  as Open  ';
               RAISE exp_loop_reject_record;
            END IF;
            --siva uncommented on mar 18 11
         ELSIF v_prod_catg in('D','A')
         THEN
             IF  (v_cardstat = 2) OR (v_cardstat = 3)
            THEN
               Sp_Dehot_Pan_Debit (prm_instcode,
                                   --x.cgd_pan_code
                                   v_decr_pan,
                                   x.cgd_mbr_numb,
                                   x.cgd_remarks,
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
                  UPDATE CMS_GROUP_DEHOTLIST_TEMP
                     SET cgd_process_flag = 'S',
                         cgd_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               END IF;
               BEGIN
                  INSERT INTO CMS_DEHOTLIST_DETAIL
                              (cdd_inst_code, cdd_card_no,
                               cdd_file_name, cdd_remarks, cdd_msg24_flag,
                               cdd_process_flag, cdd_process_msg,
                               cdd_process_mode, cdd_ins_user, cdd_ins_date,
                               cdd_lupd_user, cdd_lupd_date,cdd_card_no_encr
                              )
                       VALUES (prm_instcode, x.cgd_pan_code,
                               x.cgd_file_name, x.cgd_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE, x.cgd_card_no_encr
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_dedehotlist_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_dehotlist_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cgd_pan_code
                  || ' is invalid status for dehot  ';
               RAISE exp_loop_reject_record;
            END IF;
         END IF;
      ------------------------------En Call Sp_hotlist for hot listing pan----------------------------
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_dhtlstsavepoint;
            v_succ_flag := 'E';
            UPDATE CMS_GROUP_DEHOTLIST_TEMP
               SET cgd_process_flag = 'E',
                   cgd_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;
            INSERT INTO CMS_DEHOTLIST_DETAIL
                        (cdd_inst_code, cdd_card_no, cdd_file_name,
                         cdd_remarks, cdd_msg24_flag, cdd_process_flag,
                         cdd_process_msg, cdd_process_mode, cdd_ins_user,
                         cdd_ins_date, cdd_lupd_user, cdd_lupd_date,cdd_card_no_encr
                        )
                 VALUES (prm_instcode, x.cgd_pan_code, x.cgd_file_name,
                         x.cgd_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE, x.cgd_card_no_encr
                        );
         WHEN OTHERS
         THEN
             ROLLBACK TO v_dhtlstsavepoint;
            v_succ_flag := 'E';
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_DEHOTLIST_TEMP
               SET cgd_process_flag = 'E',
                   cgd_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;
            INSERT INTO CMS_DEHOTLIST_DETAIL
                        (cdd_inst_code, cdd_card_no, cdd_file_name,
                         cdd_remarks, cdd_msg24_flag, cdd_process_flag,
                         cdd_process_msg, cdd_process_mode, cdd_ins_user,
                         cdd_ins_date, cdd_lupd_user, cdd_lupd_date,cdd_card_no_encr
                        )
                 VALUES (prm_instcode, x.cgd_pan_code, x.cgd_file_name,
                         x.cgd_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE, x.cgd_card_no_encr
                        );
      END;
      
      --siva mar 21 2011
        --start for audit log success
      IF prm_errmsg = 'Successful'
      THEN
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.cgd_pan_code, v_prodcode, 'GROUP DEHOTLIST',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgd_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table

       --end for audit log success
      -- start for failure record
      ELSE
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.cgd_pan_code, v_prodcode, 'GROUP DEHOTLIST',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgd_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --siva end for failure status record
          --siva end mar 21 2011
          
      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,
                      pal_inst_code,pal_card_no_encr
                     )
              VALUES (x.cgd_pan_code, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      prm_errmsg, v_reasondesc, x.cgd_remarks,
                      'G',
                      prm_instcode,x.cgd_card_no_encr
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_DEHOTLIST_TEMP
               SET cgd_process_flag = 'E',
                   cgd_process_msg = 'Error while inserting into Audit log'
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


