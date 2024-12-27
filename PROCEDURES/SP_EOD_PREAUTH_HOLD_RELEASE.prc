CREATE OR REPLACE PROCEDURE vmscms.sp_eod_preauth_hold_release (
   prm_inst_code   IN       NUMBER,
   prm_mbr_numb    IN       VARCHAR2,
   prm_resp_msg    OUT      VARCHAR2
)
IS
/********************************************************************

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 09-SEP-2015
     * Modified for     : FSS 3643
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.1_B00010

     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06
	 
	 * Modified By      : PUVANESH.N
     * Modified Date    : 07-SEP-2021
     * Purpose          : VMS-4656 - AC3: Create or edit current job to release credit after "x" number of days.
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R51 - BUILD 2 

     * Modified by      : Pankaj S.
     * Modified for     : VMS-7652:Pre-auth Reversals
     * Modified Date    : 02-Aug-2023
     * Reviewer         : Venkat S.
     * Build Number     : VMS_7652_CHANGES
********************************************************************/

   exp_reject_record   EXCEPTION;
   v_err_msg           VARCHAR2 (1000);
   v_resp_cde          transactionlog.response_id%TYPE;
   V_PARAM_VALUE       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   --SN:VMS-7652 Changes
   v_preauth_flag      cms_preauth_transaction.cpt_preauth_validflag%TYPE;
   v_hold_amt          cms_preauth_transaction.cpt_totalhold_amt%TYPE;
   --EN:VMS-7652 Changes   	   

   CURSOR c1
   IS
      SELECT ROWID row_id, cpt_expiry_date AS preauthexpdate,
             cpt_totalhold_amt, cpt_rrn, cpt_txn_date, cpt_txn_time,
             cpt_terminalid, cpt_acct_no, cpt_card_no,
             fn_dmaps_main (cpt_card_no_encr) cardno, cpt_match_rule,
             cpt_completion_fee, cpt_preauth_type,
             --Sn Added for Transactionlog Functional Removal Phase-II changes
             cpt_delivery_channel, cpt_txn_code, cpt_mcc_code, cpt_merchant_id,
             cpt_merchant_name, cpt_merchant_city, cpt_merchant_state,
             cpt_merchant_zip , cpt_pos_verification, cpt_internation_ind_response,cpt_ins_date,
             --En Added for Transactionlog Functional Removal Phase-II changes
             NVL(cpt_complfree_flag,'N') complfree_flag, cpt_payment_type
        FROM cms_preauth_transaction
       WHERE cpt_expiry_flag = 'N'
         AND cpt_preauth_validflag = 'Y'
         AND cpt_completion_flag = 'N'
         AND cpt_inst_code = prm_inst_code
         AND cpt_expiry_date <= SYSDATE
         AND cpt_totalhold_amt > 0;
BEGIN                                                       -- << MAIN BEGIN>>
   prm_resp_msg := 'OK';
   
   BEGIN
		SELECT
			NVL(CIP_PARAM_VALUE,'N')
		INTO V_PARAM_VALUE
		FROM
			CMS_INST_PARAM
		WHERE
			CIP_PARAM_KEY = 'VMS_4199_TOGGLE'
			AND CIP_INST_CODE = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				V_PARAM_VALUE := 'N';
			WHEN OTHERS THEN
				V_RESP_CDE := '12';
				V_ERR_MSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
			 RAISE EXP_REJECT_RECORD;
	   END;

   FOR i IN c1
   LOOP
      BEGIN
         v_err_msg := 'OK';
         v_resp_cde := '1';
         
         --SN: VMS-7652 Changes
         v_preauth_flag:='Y';
         v_hold_amt:=i.cpt_totalhold_amt;
         
         BEGIN
             SELECT cpt_preauth_validflag, cpt_totalhold_amt
               INTO v_preauth_flag, v_hold_amt
               FROM cms_preauth_transaction
              WHERE ROWID = i.row_id;
         EXCEPTION
             WHEN OTHERS THEN
                v_err_msg :='Error while selecting pre-auth latest dtls-'|| SUBSTR (SQLERRM, 1, 200);
                v_resp_cde := '21';
                RAISE exp_reject_record;
         END;
         --EN: VMS-7652 Changes
         
         IF v_preauth_flag='Y' AND v_hold_amt > 0 THEN   --VMS-7652 Changes
         BEGIN
			IF I.cpt_delivery_channel = '02' AND I.cpt_txn_code = '36' AND V_PARAM_VALUE = 'Y' THEN
			
				UPDATE cms_acct_mast
                  SET CAM_ACCT_BAL =  CAM_ACCT_BAL - v_hold_amt --i.cpt_totalhold_amt --VMS-7652 Changes
                WHERE cam_acct_no = i.cpt_acct_no
                  AND cam_inst_code = prm_inst_code;

               IF SQL%ROWCOUNT = 0 THEN
                  v_resp_cde := '21';
                  v_err_msg :='No rows updated in cms_acct_mast for Hold Release';
                  RAISE exp_reject_record;
               END IF;
            ELSIF (i.cpt_preauth_type != 'C')  
			THEN
               UPDATE cms_acct_mast
                  SET cam_acct_bal =cam_acct_bal+ v_hold_amt + i.cpt_completion_fee  --VMS-7652 Changes
                WHERE cam_acct_no = i.cpt_acct_no
                  AND cam_inst_code = prm_inst_code;

               IF SQL%ROWCOUNT = 0 THEN
                  v_resp_cde := '21';
                  v_err_msg :='No rows updated in cms_acct_mast for Hold Release';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_err_msg :='Error while updating acct mast-Hold Release-'|| SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            UPDATE cms_preauth_transaction
               SET cpt_expiry_flag = 'Y',
                   cpt_exp_release_amount = v_hold_amt, --i.cpt_totalhold_amt, --VMS-7652 Changes
                   cpt_totalhold_amt = '0',
                   cpt_completion_fee = 0
                   ,cpt_approve_amt=0,CPT_PREAUTH_VALIDFLAG = 'N'
             WHERE ROWID = i.row_id;

            IF SQL%ROWCOUNT = 0 THEN
               v_resp_cde := '21';
               v_err_msg :='No rows updated in cms_preauth_transaction for Hold Release';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_err_msg :='Error while updating expired Preauth-'|| SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
        END IF; 
      EXCEPTION
         WHEN exp_reject_record THEN
            ROLLBACK;
         WHEN OTHERS THEN
            ROLLBACK;
      END;

      IF v_preauth_flag ='Y' THEN  --VMS-7652 Changes
      BEGIN
         sp_log_preauth_holdrelease (prm_inst_code,
                                     '05',
                                     '24',
                                     i.cpt_card_no,
                                     i.cardno,
                                     v_hold_amt, --i.cpt_totalhold_amt, --VMS-7652 Changes
                                     v_resp_cde,
                                     v_err_msg,
                                     i.cpt_rrn,
                                     i.cpt_txn_date,
                                     i.cpt_txn_time,
                                     i.cpt_card_no,
                                     i.cpt_terminalid,
                                     prm_mbr_numb,
                                     i.cpt_acct_no,
                                     i.cpt_match_rule,
                                     --Sn Added for Transactionlog Functional Removal Phase-II changes
                                     i.cpt_delivery_channel,
                                     i.cpt_txn_code,
                                     i.cpt_mcc_code,
                                     i.cpt_merchant_id,
                                     i.cpt_merchant_name,
                                     i.cpt_merchant_city,
                                     i.cpt_merchant_state,
                                     i.cpt_merchant_zip ,
                                     i.cpt_pos_verification,
                                     i.cpt_internation_ind_response,
                                     i.cpt_ins_date,
                                     --En Added for Transactionlog Functional Removal Phase-II changes
                                     v_err_msg,
                                     i.cpt_completion_fee,
                                     i.cpt_preauth_type,
                                     i.complfree_flag,
                                     i.cpt_payment_type
                                    );
      EXCEPTION
         WHEN OTHERS THEN
            v_err_msg :='Error while logging preauth_holdrelease-'|| SUBSTR (SQLERRM, 1, 100);
      END;
      END IF; --VMS-7652 Changes

      IF v_err_msg <> 'OK' THEN
        BEGIN
        INSERT INTO cms_sopfailure_dtl
                     (csd_card_no, csd_rrn, csd_mbr_no, csd_inst_code,
                      csd_hold_amount, csd_expiry_date, csd_preauthtxn_date,
                      csd_error_msg
                     )
              VALUES (i.cpt_card_no, i.cpt_rrn, prm_mbr_numb, prm_inst_code,
                      v_hold_amt, i.preauthexpdate, i.cpt_txn_date,  --VMS-7652 Changes
                      substr(v_err_msg,1,100)
                     );
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
            END;
      END IF;

      COMMIT;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      prm_resp_msg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 100);
END;
/

SHOW ERROR