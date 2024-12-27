CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Group_Topup_Pan (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
   v_count                  NUMBER (1);
   v_card_curr              VARCHAR2 (3);
   v_rec_cnt                NUMBER (9);
   v_errflag                VARCHAR2 (1);
   v_errmsg                 VARCHAR2 (300);
   v_authmsg                VARCHAR2 (300);
   v_rrn                    VARCHAR2 (12);
   v_stan                   VARCHAR2 (12);
   v_resoncode              NUMBER (3);
   v_topupsavepoint         NUMBER (9)     DEFAULT 0;
   init_savepoint           NUMBER (9)     DEFAULT 9999;
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_remark                 VARCHAR2 (100);
   v_prod_catg				CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.csr_reasondesc%TYPE;


      v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
 
   CURSOR c1
   IS
      SELECT cgt_acct_no, cgt_topup_amt, cgt_file_name, cgt_remarks,
             cgt_mbr_numb, cgt_ref_no,cgt_payment_mode, cgt_instrument_no, 
			 cgt_drawn_date, ROWID r
        FROM CMS_GROUP_TOPUP_TEMP
       WHERE cgt_process_flag = 'N';
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';


   --Sn check for pending records
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM CMS_GROUP_TOPUP_TEMP
       WHERE cgt_process_flag = 'N' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No record found for topup processing';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while getting records from table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En check for pending records

   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'TOP UP' and cfm_inst_code=prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   v_remark := 'GROUP TOPUP';
   
   BEGIN
      SELECT csr_spprt_rsncode, csr_reasondesc
        INTO v_resoncode, v_reasondesc
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code=prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Top up reason code is present in master';
         RAISE exp_loop_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_loop_reject_record;
   END;

   ------------------------------ En get Function Master----------------------------

   --Sn proceess loop
   FOR i IN c1
   LOOP
      v_topupsavepoint := v_topupsavepoint + 1;
      SAVEPOINT v_topupsavepoint;


            --SN CREATE HASH PAN 
            BEGIN
                v_hash_pan := Gethash(I.cgt_acct_no);
            EXCEPTION
            WHEN OTHERS THEN
            v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE    exp_main_reject_record;
            END;
            --EN CREATE HASH PAN 

            --SN create encr pan
            BEGIN
                v_encr_pan := Fn_Emaps_Main(I.cgt_acct_no);
            EXCEPTION
            WHEN OTHERS THEN
            v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE    exp_main_reject_record;
            END;
            --EN create encr pan
            
      BEGIN
         BEGIN
            SELECT cap_prod_catg,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
              INTO v_prod_catg,v_applcode, v_acctno, v_prodcode
              FROM CMS_APPL_PAN
              WHERE cap_pan_code = v_hash_pan--i.cgt_acct_no
             AND CAP_MBR_NUMB = i.cgt_mbr_numb
             AND CAP_INST_CODE= prm_instcode;
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

         IF v_prod_catg = 'P'
         THEN
            --Sn find card currency
            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_CATTYPE
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                    AND cap_pan_code = v_hash_pan--i.cgt_acct_no
                    AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                         'Currency is not defined for card ' || i.cgt_acct_no;
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while fetching currency from table '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            --En find card currency

            --Sn call procedure to TOPUP the PAN
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
                  RETURN;
            END;

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
                  RETURN;
            END;

            --Sn create a record in pan spprt
            

            Sp_Topup_Pan (prm_instcode,
                          v_rrn,
                          'Offline',
                          v_stan,
                          TO_CHAR (SYSDATE, 'YYYYMMDD'),
                          TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                          i.cgt_acct_no,
                          i.cgt_file_name,
                          i.cgt_remarks,
                          v_resoncode,
                          i.cgt_topup_amt,
                          i.cgt_ref_no,
                          i.cgt_payment_mode,
                          i.cgt_instrument_no,
                          i.cgt_drawn_date,
                          v_card_curr,
                          prm_lupduser,
                          v_authmsg,
                          v_errmsg
                         );

            IF v_errmsg <> 'OK'
            THEN
               v_succ_flag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg <> 'OK'
            THEN
               v_errflag := 'E';
               v_succ_flag := 'E';
               v_errmsg := v_authmsg;
			   UPDATE CMS_GROUP_TOPUP_TEMP
                  SET cgt_process_flag = 'E',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            --RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_succ_flag := 'S';
               v_errmsg := 'Successful';

               UPDATE CMS_GROUP_TOPUP_TEMP
                  SET cgt_process_flag = 'S',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            --RAISE exp_loop_reject_record;
            END IF;

---TO CREATE
     --En call procedure to TOPUP the PAN
            INSERT INTO CMS_TOPUP_DETAIL
                        (ctd_acct_no, ctd_topup_amt, ctd_file_name,
                         ctd_remarks, ctd_ref_no, ctd_process_flag,
                         ctd_process_msg, ctd_process_mode, ctd_ins_user,
                         ctd_ins_date, ctd_lupd_user, ctd_lupd_date,
                         ctd_inst_code,ctd_payment_mode, ctd_instrument_no, ctd_drawn_date
                        )
                 VALUES (i.cgt_acct_no, i.cgt_topup_amt, i.cgt_file_name,
                         i.cgt_remarks, i.cgt_ref_no, v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,
                         prm_instcode, i.cgt_payment_mode, i.cgt_instrument_no, 
			 			 i.cgt_drawn_date
                        );
         ELSIF v_prod_catg = 'D'
         THEN
            v_errmsg := 'Topup is only applicable for Prepaid_card';
            RAISE exp_loop_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_topupsavepoint;
            v_succ_flag := 'E';

            UPDATE CMS_GROUP_TOPUP_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_TOPUP_DETAIL
                        (ctd_acct_no, ctd_topup_amt, ctd_file_name,
                         ctd_remarks, ctd_ref_no, ctd_process_flag,
                         ctd_process_msg, ctd_process_mode, ctd_ins_user,
                         ctd_ins_date, ctd_lupd_user, ctd_lupd_date,
                         ctd_inst_code,ctd_payment_mode, ctd_instrument_no, ctd_drawn_date
                        )
                 VALUES (i.cgt_acct_no, i.cgt_topup_amt, i.cgt_file_name,
                         i.cgt_remarks, i.cgt_ref_no, 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,
                         prm_instcode, i.cgt_payment_mode, i.cgt_instrument_no, 
			 			 i.cgt_drawn_date
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_topupsavepoint;
            v_succ_flag := 'E';

            UPDATE CMS_GROUP_TOPUP_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_TOPUP_DETAIL
                        (ctd_acct_no, ctd_topup_amt, ctd_file_name,
                         ctd_remarks, ctd_ref_no, ctd_process_flag,
                         ctd_process_msg, ctd_process_mode, ctd_ins_user,
                         ctd_ins_date, ctd_lupd_user, ctd_lupd_date,
                         ctd_inst_code,ctd_payment_mode, ctd_instrument_no, ctd_drawn_date
                        )
                 VALUES (i.cgt_acct_no, i.cgt_topup_amt, i.cgt_file_name,
                         i.cgt_remarks, i.cgt_ref_no, 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,
                         prm_instcode, i.cgt_payment_mode, i.cgt_instrument_no, 
			 			 i.cgt_drawn_date
                        );
      END;
                
            --siva mar 24 2011
        --start for audit log success
      IF v_errmsg = 'Successful'
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
                         v_hash_pan, v_prodcode, 'GROUP TOPUP',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', v_encr_pan,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
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
                         v_hash_pan, v_prodcode, 'GROUP TOPUP',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', v_encr_pan,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 24 2011
          
        /*
      BEGIN
         INSERT INTO PCMS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
					  pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type
                     )
              VALUES (i.cgt_acct_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
					  v_errmsg, v_reasondesc, i.cgt_remarks,
                      'G'
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_TOPUP_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = 'Error while inserting into Audit log'
             WHERE ROWID = i.r;
      END;*/
   END LOOP;

   --En process  loop
   prm_errmsg := 'OK';
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                          --<< MAIN END;>>
/


