CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Group_Chngestat (
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
   v_blocksavepoint         NUMBER (9)                             DEFAULT 99;
   init_savepoint           NUMBER (9)                             DEFAULT 99;
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_prod_catg              CMS_APPL_PAN.cap_card_stat%TYPE;
   v_acct_no				CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
   v_old_card_stat			CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;

   CURSOR c1
   IS
      SELECT cgc_card_no, cgc_file_name, cgc_remark, cgc_process_flag,cgc_pin_chngestat, 
	  		 cgc_new_stat,cgc_result,cgc_mbr_numb,cgc_process_msg,ROWID r
        FROM CMS_GROUP_CHNGESTAT
       WHERE cgc_process_flag = 'N' AND cgc_pin_chngestat = 'N';
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';
   v_remark := 'Group Card Status Change';

------------------------------Sn check for pending records----------------------------
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM CMS_GROUP_CHNGESTAT
       WHERE cgc_process_flag = 'N' AND cgc_pin_chngestat = 'N' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No record found for card blocking  processing';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while getting records from table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   ------------------------------En check for pending records----------------------------
   
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'CHGSTA';
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
   
   FOR i IN c1
   LOOP
      v_blocksavepoint := v_blocksavepoint + 1;
      SAVEPOINT v_blocksavepoint;
      v_errmsg := 'OK';

      BEGIN                                             -- << LOOP I BEGIN >>
         BEGIN
            SELECT cap_prod_catg,CAP_ACCT_NO,CAP_CARD_STAT
              INTO v_prod_catg,v_acct_no,v_old_card_stat
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = i.cgc_card_no
               AND cap_mbr_numb = i.cgc_mbr_numb;
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

------------------------------ Sn get rrn----------------------------
         IF v_prod_catg = 'P'
         THEN
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
                 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_CATTYPE
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = i.cgc_card_no
                  AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency not defined for the card';
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get card currency--------------------------------

            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'CHGSTA' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Block  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master----------------------------

            ------------------------------ Sn call to procedure----------------------------
           Sp_Chnge_Crdstat 
		   				 (prm_instcode,
						  i.cgc_card_no,
						  i.cgc_mbr_numb,
						  i.cgc_remark,
						  v_resoncode,
                          v_rrn,
                          'offline',
                          v_stan,
                          TO_CHAR (SYSDATE, 'YYYYMMDD'),
                          TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                          v_acct_no,
                          i.cgc_file_name,
						  0,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          v_card_curr,
                          prm_lupduser,
						  0,
						  i.cgc_new_stat,
                          v_authmsg,
                          v_errmsg);   

            IF v_errmsg <> 'OK'
            THEN
				v_succ_flag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg <> 'OK'
            THEN
               v_errflag := 'E';
               v_errmsg := v_authmsg;
			   v_succ_flag := 'E';
			   
			   UPDATE CMS_GROUP_CHNGESTAT
                     SET CGC_PROCESS_FLAG = 'E',
                         CGC_PROCESS_MSG = v_errmsg
                   WHERE ROWID = i.r;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';
			   v_succ_flag := 'S';

               UPDATE CMS_GROUP_CHNGESTAT
                  SET cgc_process_flag = 'S',
                      cgc_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

            INSERT INTO CMS_CHNGSTAT_DETAIL
                        (CRD_INST_CODE, CRD_CARD_NO, CRD_OLD_CARDSTAT, CRD_NEW_CARDSTAT, 
						CRD_FILE_NAME, CRD_REMARKS, CRD_MSG24_FLAG, CRD_PROCESS_FLAG, 
						CRD_PROCESS_MSG, CRD_PROCESS_MODE, CRD_INS_USER, CRD_INS_DATE, 
						CRD_LUPD_USER, CRD_LUPD_DATE
                        )
                 VALUES (prm_instcode, i.cgc_card_no, v_old_card_stat,i.cgc_new_stat,i.cgc_file_name,
                         i.cgc_remark, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         ------------------------------ En call to procedure----------------------------
         ELSIF v_prod_catg = 'D'
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'CHGSTA' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Block  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master----------------------------
            Sp_Chnge_Crdstat_Debit (prm_instcode,
								   i.cgc_card_no,
								   i.cgc_mbr_numb,
								   i.cgc_remark,
								   v_resoncode,
								   0,      
								   i.cgc_new_stat,
								   prm_lupduser,
								   v_errmsg);
								   
            IF v_errmsg <> 'OK'
            THEN
				v_succ_flag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';
			   v_succ_flag := 'S';

               UPDATE CMS_GROUP_CHNGESTAT
                  SET cgc_process_flag = 'S',
                      cgc_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

             INSERT INTO CMS_CHNGSTAT_DETAIL

                        (CRD_INST_CODE, CRD_CARD_NO, CRD_OLD_CARDSTAT, CRD_NEW_CARDSTAT, 
						CRD_FILE_NAME, CRD_REMARKS, CRD_MSG24_FLAG, CRD_PROCESS_FLAG, 
						CRD_PROCESS_MSG, CRD_PROCESS_MODE, CRD_INS_USER, CRD_INS_DATE, 
						CRD_LUPD_USER, CRD_LUPD_DATE
                        )
                 VALUES (prm_instcode, i.cgc_card_no, v_old_card_stat,i.cgc_new_stat,i.cgc_file_name,
                         i.cgc_remark, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         END IF;
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_blocksavepoint;
			v_succ_flag := 'E';

            UPDATE CMS_GROUP_CHNGESTAT
               SET cgc_process_flag = 'E',
                   cgc_process_msg = v_errmsg
             WHERE ROWID = i.r;

             INSERT INTO CMS_CHNGSTAT_DETAIL

                        (CRD_INST_CODE, CRD_CARD_NO, CRD_OLD_CARDSTAT, CRD_NEW_CARDSTAT, 
						CRD_FILE_NAME, CRD_REMARKS, CRD_MSG24_FLAG, CRD_PROCESS_FLAG, 
						CRD_PROCESS_MSG, CRD_PROCESS_MODE, CRD_INS_USER, CRD_INS_DATE, 
						CRD_LUPD_USER, CRD_LUPD_DATE
                        )
                 VALUES (prm_instcode, i.cgc_card_no, v_old_card_stat,i.cgc_new_stat,i.cgc_file_name,
                         i.cgc_remark, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_blocksavepoint;
			v_succ_flag := 'E';

            UPDATE CMS_GROUP_CHNGESTAT
               SET cgc_process_flag = 'E',
                   cgc_process_msg = v_errmsg
             WHERE ROWID = i.r;

             INSERT INTO CMS_CHNGSTAT_DETAIL

                        (CRD_INST_CODE, CRD_CARD_NO, CRD_OLD_CARDSTAT, CRD_NEW_CARDSTAT, 
						CRD_FILE_NAME, CRD_REMARKS, CRD_MSG24_FLAG, CRD_PROCESS_FLAG, 
						CRD_PROCESS_MSG, CRD_PROCESS_MODE, CRD_INS_USER, CRD_INS_DATE, 
						CRD_LUPD_USER, CRD_LUPD_DATE
                        )
                 VALUES (prm_instcode, i.cgc_card_no, v_old_card_stat,i.cgc_new_stat,i.cgc_file_name,
                         i.cgc_remark, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
      END;    
	  
	  BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date
                     )
              VALUES (i.cgc_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_CHNGESTAT
               SET CGC_PROCESS_FLAG = 'E',
                   CGC_PROCESS_MSG = 'Error while inserting into Audit log'
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


