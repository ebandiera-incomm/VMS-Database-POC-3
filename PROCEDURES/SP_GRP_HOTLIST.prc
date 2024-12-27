CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_hotlist (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,   
   prm_errmsg     OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 27/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Group Hotlist Card , only if ard is open
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
AS
   v_remark                 cms_pan_spprt.cps_func_remark%TYPE;
   v_cardstat               cms_appl_pan.cap_card_stat%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
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
   v_prod_catg              cms_appl_pan.cap_prod_catg%TYPE;
   v_reasondesc             cms_spprt_reasons.csr_reasondesc%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
   v_expry_date                CMS_APPL_PAN.cap_expry_date%TYPE;
   exp_loop_reject_record   EXCEPTION;

   CURSOR c1
   IS
      SELECT TRIM (cgh_card_no) cgh_card_no, cgh_file_name, cgh_remarks,
             cgh_mbr_numb, cgh_card_no_encr, ROWID
        FROM cms_group_hotlist_temp
       WHERE cgh_process_flag = 'N' AND cgh_inst_code = prm_instcode;
---------------------------------SN Start hot listing of given card  -----------------------------------------
BEGIN
   prm_errmsg := 'OK';
   v_remark := 'Group Hotlist';

   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'HTLST' AND cfm_inst_code = prm_instcode;
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
      SELECT csr_spprt_rsncode, csr_reasondesc
        INTO v_resoncode, v_reasondesc
        FROM cms_spprt_reasons
       WHERE csr_spprt_key = 'HTLST'
         AND csr_inst_code = prm_instcode
         AND ROWNUM < 2;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         prm_errmsg := 'Hotlist  reason code not present in master ';
         RETURN;
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Hotlist  reason code not present in master';
         RETURN;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
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

--------------------------
         BEGIN
            SELECT cap_prod_catg,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE,CAP_EXPRY_DATE
              INTO v_prod_catg,v_cardstat,v_applcode, v_acctno, v_prodcode, v_expry_date
              FROM cms_appl_pan
             WHERE cap_pan_code = x.cgh_card_no
               AND cap_mbr_numb = x.cgh_mbr_numb
               AND cap_inst_code = prm_instcode;

            IF v_prod_catg IS NULL OR v_cardstat IS NULL
            THEN
               prm_errmsg :=
                  'Product category or card status is not defined for the card';
               RAISE exp_loop_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_errmsg := 'Card is not defined in master';
               RAISE exp_loop_reject_record;
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;

         IF v_cardstat <> '1'
         THEN
            prm_errmsg := 'Card status is not open, cannot be hotlisted';
            RAISE exp_loop_reject_record;
         END IF;
         
         IF  TRUNC (v_expry_date) < TRUNC (SYSDATE)     --siva added on 25 mar 2011 for expiry card check
            THEN
                prm_errmsg :=  'Card ' || x.cgh_card_no || ' is already Expired ,cannot be hotlisted';
                RAISE exp_loop_reject_record;
                --RETURN;
         END IF;

         -------------------------Sn Find the card status, is open or not-------------------------------------
         IF v_prod_catg = 'P'
         THEN
--             BEGIN
--                SELECT cap_card_stat
--                  INTO v_cardstat
--                  FROM CMS_APPL_PAN
--                 WHERE cap_pan_code = x.cgh_card_no AND cap_mbr_numb = x.cgh_mbr_numb;
--             EXCEPTION
--                WHEN VALUE_ERROR
--                THEN
--                   prm_errmsg := 'No Status defined For Given card';
--                   RAISE exp_loop_reject_record;
--                WHEN NO_DATA_FOUND
--                THEN
--                   prm_errmsg := 'No Status defined For Given card';
--                   -- RETURN;
--                   RAISE exp_loop_reject_record;
--                WHEN OTHERS
--                THEN
--                   prm_errmsg :=
--                         'Error while values from sequence '
--                      || SUBSTR (SQLERRM, 1, 200);
--                   --RETURN;
--                   RAISE exp_loop_reject_record;
--             END;

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
                 FROM cms_appl_pan, cms_bin_param, cms_prod_cattype
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = x.cgh_card_no
                  AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code
                  AND cbp_inst_code = prm_instcode;
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
            IF v_cardstat = 1
            THEN
               sp_hotlist_pan_prepaid
                             (prm_instcode,                     --prm_instcode
                              fn_dmaps_main (x.cgh_card_no_encr),
                                                                 --prm_pancode
                              x.cgh_mbr_numb,                    --prm_mbrnumb
                              x.cgh_remarks,                     -- prm_remark
                              v_resoncode,                       --prm_rsncode
                              v_rrn,                                 --prm_rrn
                              'offline',                      --prm_terminalid
                              v_stan,                              -- prm_stan
                              TO_CHAR (SYSDATE, 'YYYYMMDD'),    --prm_trandate
                              TO_CHAR (SYSDATE, 'HH24:MI:SS'),  --prm_trantime
                              fn_dmaps_main (x.cgh_card_no_encr), --prm_acctno
                              x.cgh_file_name,                  --prm_filename
                              0,                                  --prm_amount
                              NULL,                                --prm_refno
                              NULL,                          --prm_paymentmode
                              NULL,                         --prm_instrumentno
                              NULL,                            --prm_drawndate
                              v_card_curr,                     -- prm_currcode
                              prm_lupduser,                     --prm_lupduser
                              1,                                --prm_workmode
                              v_authmsg,                    --prm_auth_message
                              prm_errmsg                          --prm_errmsg
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

                  UPDATE cms_group_hotlist_temp
                     SET cgh_process_flag = 'S',
                         cgh_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               ELSIF prm_errmsg = 'OK' AND v_authmsg <> 'OK'
               THEN
                  v_errflag := 'E';
                  v_succ_flag := 'E';
                  prm_errmsg := v_authmsg;
               --RAISE exp_loop_reject_record;
               END IF;

               BEGIN
                  INSERT INTO cms_hotlist_detail
                              (chd_inst_code, chd_card_no, chd_file_name,
                               chd_remarks, chd_msg24_flag,
                               chd_process_flag, chd_process_msg,
                               chd_process_mode, chd_ins_user, chd_ins_date,
                               chd_lupd_user, chd_lupd_date
                              )
                       VALUES (prm_instcode, x.cgh_card_no, x.cgh_file_name,
                               x.cgh_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_hotlist_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_hotlist_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cgh_card_no
                  || ' is not available  as Open  ';
               RAISE exp_loop_reject_record;
            END IF;
         ELSIF v_prod_catg IN ('D', 'A')
         THEN
            ------------------------------Sn get reason code from support reason master--------------------
            /*BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'HTLST' AND ROWNUM < 2;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  prm_errmsg := 'Hotlist  reason code not present in master ';
                  RAISE exp_loop_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'Hotlist  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;*/

            ------------------------------En get reason code from support reason master---------------------
--             BEGIN
--                SELECT cap_card_stat
--                  INTO v_cardstat
--                  FROM CMS_APPL_PAN
--                 WHERE cap_pan_code = x.cgh_card_no AND cap_mbr_numb = x.cgh_mbr_numb;
--             EXCEPTION
--                WHEN VALUE_ERROR
--                THEN
--                   prm_errmsg := 'No Status defined For Given card';
--                   RAISE exp_loop_reject_record;
--                WHEN NO_DATA_FOUND
--                THEN
--                   prm_errmsg := 'No Status defined For Given card';
--                   -- RETURN;
--                   RAISE exp_loop_reject_record;
--                WHEN OTHERS
--                THEN
--                   prm_errmsg :=
--                         'Error while values from sequence '
--                      || SUBSTR (SQLERRM, 1, 200);
--                   --RETURN;
--                   RAISE exp_loop_reject_record;
--             END;
            IF v_cardstat = 1
            THEN
               sp_hotlist_pan_debit (prm_instcode,
                                     fn_dmaps_main (x.cgh_card_no_encr),
                                     x.cgh_mbr_numb,
                                     x.cgh_remarks,
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

                  UPDATE cms_group_hotlist_temp
                     SET cgh_process_flag = 'S',
                         cgh_process_msg = 'SUCCESSFULL'
                   WHERE ROWID = x.ROWID;
               END IF;

               BEGIN
                  INSERT INTO cms_hotlist_detail
                              (chd_inst_code, chd_card_no, chd_file_name,
                               chd_remarks, chd_msg24_flag,
                               chd_process_flag, chd_process_msg,
                               chd_process_mode, chd_ins_user, chd_ins_date,
                               chd_lupd_user, chd_lupd_date
                              )
                       VALUES (prm_instcode, x.cgh_card_no, x.cgh_file_name,
                               x.cgh_remarks, 'N',
                               v_errflag, prm_errmsg,
                               'G', prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE
                              );
               EXCEPTION
                  WHEN VALUE_ERROR
                  THEN
                     prm_errmsg := ' insert in to cms_hotlist_detail';
                     RAISE exp_loop_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while inserting records cms_hotlist_detail from master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
            ELSE
               prm_errmsg :=
                     'The Given Pan :'
                  || x.cgh_card_no
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

            UPDATE cms_group_hotlist_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;

            INSERT INTO cms_hotlist_detail
                        (chd_inst_code, chd_card_no, chd_file_name,
                         chd_remarks, chd_msg24_flag, chd_process_flag,
                         chd_process_msg, chd_process_mode, chd_ins_user,
                         chd_ins_date, chd_lupd_user, chd_lupd_date
                        )
                 VALUES (prm_instcode, x.cgh_card_no, x.cgh_file_name,
                         x.cgh_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_htlstsavepoint;
            v_succ_flag := 'E';
            prm_errmsg :=
                         'Error from processing ' || SUBSTR (SQLERRM, 1, 150);

            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE cms_group_hotlist_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = prm_errmsg
             WHERE ROWID = x.ROWID;

            INSERT INTO cms_hotlist_detail
                        (chd_inst_code, chd_card_no, chd_file_name,
                         chd_remarks, chd_msg24_flag, chd_process_flag,
                         chd_process_msg, chd_process_mode, chd_ins_user,
                         chd_ins_date, chd_lupd_user, chd_lupd_date
                        )
                 VALUES (prm_instcode, x.cgh_card_no, x.cgh_file_name,
                         x.cgh_remarks, 'N', 'E',
                         prm_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
      END;

      --siva mar 21 2011
        --siva start for audit lod
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
                         x.cgh_card_no, v_prodcode, 'GROUP HOTLIST',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgh_card_no_encr,
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

      --siva end for audit log
      --siva start for failure
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
                         x.cgh_card_no, v_prodcode, 'GROUP HOTLIST',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgh_card_no_encr,
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

      --siva end for failure status
          --siva end mar 21 2011
      BEGIN
         INSERT INTO process_audit_log
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type, pal_inst_code
                     )
              VALUES (x.cgh_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      prm_errmsg, v_reasondesc, x.cgh_remarks,
                      'G', prm_instcode
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE cms_group_hotlist_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = 'Error while inserting into Audit log'
             WHERE ROWID = x.ROWID;
      END;
   END LOOP;                                             -- <<END loop begin>>

------------------------En find the pan details Cursor loop Begin---------------------------------------
   prm_errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Excp from group hotlist  -- ' || SQLERRM;
END;
---------------------------------EN End hot listing of given card  --------------------------------------
/


