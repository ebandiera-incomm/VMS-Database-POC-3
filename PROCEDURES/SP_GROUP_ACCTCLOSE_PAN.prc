CREATE OR REPLACE PROCEDURE VMSCMS.sp_group_acctclose_pan (
   prm_instcode   IN       NUMBER,
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
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_prod_catg              cms_appl_pan.cap_prod_catg%TYPE;
   v_acct_id                cms_appl_pan.cap_acct_id%TYPE;
   v_rsndesc				cms_spprt_reasons.CSR_REASONDESC%TYPE;
   v_remark					VARCHAR2(100);
   v_txn_code				CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
   v_txn_mode				CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
   v_del_channel			CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
   v_txn_type				CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
   v_acct_bal 				CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
   v_blocksavepoint         NUMBER (9)                             DEFAULT 99;
   init_savepoint           NUMBER (9)                             DEFAULT 99;
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;


   CURSOR c1
   IS
      SELECT cgt_card_no, cgt_acct_no, cgt_file_name, cgt_remarks,
             cgt_process_flag, cgt_process_msg, cgt_amount, cgt_sinkamt,
             cgt_sinkbankname, cgt_sinkbranch, cgt_sinkbankacct,
             cgt_sinkbankifcs,cgt_mbr_numb, ROWID r
        FROM cms_acctclose_temp
       WHERE cgt_process_flag = 'N';
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';
   v_remark := 'Group Account Close';
------------------------------Sn check for pending records----------------------------
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM cms_acctclose_temp
       WHERE cgt_process_flag = 'N' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No record found for card Acct close processing';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while getting records from table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   ------------------------------En check for pending records----------------------------
   ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode,csr_reasondesc
                 INTO v_resoncode,v_rsndesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'ACCCLOSE' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'ACCCLOSE  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

   ------------------------------En get reason code from support reason master----------------------------
   
   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ACCCLOSE';
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   ------------------------------ En get Function Master-----------------------------
   

   --------------------------------Sn Check For Prepaid OR debit------------------------
   FOR i IN c1
   LOOP
      v_blocksavepoint := v_blocksavepoint + 1;
      SAVEPOINT v_blocksavepoint;
      v_errmsg := 'OK';

      BEGIN                                             -- << LOOP I BEGIN >>
	  
	  
	  
	  
	  
---------------------------------Sn Find product catg for the card---------------------
         BEGIN
            SELECT UNIQUE cap_prod_catg, cap_acct_id
              INTO v_prod_catg, v_acct_id
              FROM cms_appl_pan
             WHERE cap_acct_no = i.cgt_acct_no AND cap_mbr_numb = i.cgt_mbr_numb 
			 AND cap_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'No product category dfined for the card';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

---------------------------------En Find product catg for the card---------------------
         IF v_prod_catg = 'P'
         THEN
------------------------------ Sn get rrn----------------------------
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

------------------------------ En get rrn----------------------------
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
                  RETURN;
            END;

------------------------------En get STAN----------------------------

            --------------------------------Sn get card currency ----------------------------
            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM cms_appl_pan, cms_bin_param, cms_prod_cattype
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = i.cgt_acct_no
                  AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency not defined for the card';
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get card currency--------------------------------

            
            ------------------------------ Sn call prepaid card procedure----------------------------
            sp_acct_close (prm_instcode,
                           v_rrn,
                           'offline',
                           v_stan,
                           TO_CHAR (SYSDATE, 'YYYYMMDD'),
                           TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                           i.cgt_acct_no,
                           i.cgt_file_name,
                           i.cgt_remarks,
                           v_resoncode,
                           0,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           v_card_curr,
                           i.cgt_sinkbankname,
                           i.cgt_sinkbranch,
                           i.cgt_sinkbankacct,
                           i.cgt_sinkbankifcs,
                           v_acct_id,
                           prm_lupduser,
                           v_authmsg,
                           v_errmsg
                          );

            IF v_errmsg <> 'OK'
            THEN
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg <> 'OK'
            THEN
               v_errflag := 'E';
               v_errmsg := v_authmsg;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';

               UPDATE cms_acctclose_temp
                  SET cgt_process_flag = 'S',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

            INSERT INTO cms_acctclose_detail
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date,
                         crd_sink_acctno, crd_sink_bank,
                         crd_sink_branch, crd_sink_ifcs, crd_close_amount
                        )
                 VALUES (prm_instcode, i.cgt_acct_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,
                         i.cgt_sinkbankacct, i.cgt_sinkbankname,
                         i.cgt_sinkbranch, i.cgt_sinkbankifcs, i.cgt_sinkamt
                        );
          ------------------------------ En call prepaid card procedure----------------------------
         --------------------------Sn Call Debit procedure-------------------------
         ELSIF v_prod_catg = 'D'
         THEN
------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
				 select CAM_ACCT_BAL INTO v_acct_bal from cms_acct_mast 
				 where CAM_ACCT_NO = i.cgt_acct_no 
				 AND CAM_ACCT_ID = v_acct_id
				 AND cam_inst_code =prm_instcode;
			
			EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'acct balance is not defined for the acct';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting acct balance from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
			
			END;
			
			/*BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'ACCCLOSE' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'ACCCLOSE  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;*/

            ------------------------------En get reason code from support reason master----------------------------
            sp_acct_close_debit (prm_instcode,
                                 v_acct_id,
								 --i.cgt_acct_no,
                                 v_resoncode,
                                 i.cgt_remarks,
								 v_acct_bal,
                                 prm_lupduser,
                                 /* i.cgt_sinkamt,
                                  i.cgt_sinkbankname,
                                  i.cgt_sinkbranch,
                                  i.cgt_sinkbankacct,
                                  i.cgt_sinkbankifcs,*/
                                 v_errmsg
                                );

            IF v_errmsg <> 'OK'
            THEN
			v_errflag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';

               UPDATE cms_acctclose_temp
                  SET cgt_process_flag = 'S',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

            INSERT INTO cms_acctclose_detail
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date
                        )
                 VALUES (prm_instcode, i.cgt_acct_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         END IF;
      --------------------------En Call Debit procedure-------------------------
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_blocksavepoint;

            UPDATE cms_acctclose_temp
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO cms_acctclose_detail
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date
                        )
                 VALUES (prm_instcode, i.cgt_acct_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_blocksavepoint;

            UPDATE cms_acctclose_temp
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO cms_acctclose_detail
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date
                        )
                 VALUES (prm_instcode, i.cgt_acct_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
      END;
	  BEGIN
         INSERT INTO pcms_audit_log
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
					  pal_process_msg, pal_reason_desc, pal_remarks, 
					  pal_spprt_type
                     )
              VALUES (i.cgt_acct_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_errflag,prm_lupduser, SYSDATE,
					  v_errmsg,v_rsndesc, i.cgt_remarks,'G'
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
             UPDATE cms_acctclose_temp
               SET cgt_process_flag = 'E',
                   cgt_process_msg = 'Error While inserting record in audit log'
             WHERE ROWID = i.r;
      END;                                                  --<< LOOP I END >>
   END LOOP;

   prm_errmsg := 'OK';
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


