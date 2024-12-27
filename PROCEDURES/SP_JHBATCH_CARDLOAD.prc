create or replace
PROCEDURE               VMSCMS.sp_jhbatch_cardload (
   p_instcode    IN       NUMBER,
   p_file_name   IN       VARCHAR2,
   p_errmsg      OUT      VARCHAR2
)
AS
    /*************************************************************************************

   * modified by         : Abdul Hameed M.A
   * modified Date       : 08-Jan-15
   * modified reason     : Batch card Load for JH
   * Reviewer            : 
   * Reviewed Date       : 
   * Build Number        : 
   
   * Modified by      : T.Narayanaswamy.
   * Modified Date    : 20-June-17
   * Modified For     : FSS-5157 - B2B Gift Card - Phase 2
   * Modified reason  : B2B Gift Card - Phase 2
   * Reviewer         : Saravanakumar
   * Build Number     : VMSGPRHOST_17.06  
   
   * Modified By      : MageshKumar S
   * Modified Date    : 18/07/2017
   * Purpose          : FSS-5157
   * Reviewer         : Saravanan/Pankaj S. 
   * Release Number   : VMSGPRHOST17.07
   
   * Modified By      : T.Narayanaswamy.
   * Modified Date    : 04/08/2017
   * Purpose          : FSS-5157 - B2B Gift Card - Phase 2
   * Reviewer         : Saravanan/Pankaj S. 
   * Release Number   : VMSGPRHOST17.08

    **************************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_varprodflag            cms_prod_cattype.CPC_RELOADABLE_FLAG%TYPE;
   v_currcode               VARCHAR2 (3);
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_topup_auth_id          transactionlog.auth_id%TYPE;
   exp_main_reject_record   EXCEPTION;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_business_date          VARCHAR2(8);
   v_tran_date              DATE;
   v_topupremrk             VARCHAR2 (100);
   v_acct_balance           NUMBER;
   v_tran_amt               NUMBER;
   v_card_curr              VARCHAR2 (5);
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_dr_cr_flag             VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cust_code              cms_appl_pan.cap_cust_code%TYPE;
   v_delivery_channel       cms_transaction_mast.ctm_delivery_channel%TYPE
                                                                 DEFAULT '05';
   v_resp_code              VARCHAR2 (50);
   v_rrn                    VARCHAR2 (20);
   v_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_time_stamp             TIMESTAMP;
   v_prodprof_code          cms_prod_cattype.cpc_profile_code%TYPE;
   v_savepoint              NUMBER                                  DEFAULT 0;
   v_proxy_number           cms_appl_pan.cap_proxy_number%TYPE;
   v_pan                    VARCHAR2 (19);
   v_txn_amt                NUMBER;
   v_txn_code               cms_transaction_mast.ctm_tran_code%TYPE;
   v_reason_code            VARCHAR2 (100);
   v_ledger_bal             NUMBER;
   v_cam_type_code          cms_acct_mast.cam_type_code%TYPE;
   v_upd_amt                NUMBER;
   v_upd_ledger_bal         NUMBER;
   v_rvsl_code              VARCHAR2 (2);
   v_max_card_bal           NUMBER;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_narration              VARCHAR2 (300);
   p_resp_code              VARCHAR2 (5);
   v_business_time          VARCHAR2 (10);
   v_kyc_flag               cms_cust_mast.ccm_kyc_flag%TYPE;
   v_pin_flag               cms_appl_pan.cap_pin_flag%TYPE;
   v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   V_PRFL_FLAG              CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%type;
   V_REASON_DESC             cms_jhload_reason_mast.CJM_REASON_DESC%TYPE;
   V_COMB_HASH              PKG_LIMITS_CHECK.TYPE_HASH;
   V_COMMENTS               CMS_TRANSACTION_LOG_DTL.CTD_CHW_COMMENT%type;
   V_LOGREASON_CODE          CMS_JHLOAD_REASON_MAST.CJM_LOGREASON_CODE%type;
   V_MERCHANT_NAME          cms_batchupload_detl.CBD_MERCHANT_NAME%TYPE;
   
   V_CPC_PROD_DENO        CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;   
   V_CPC_PDEN_MIN         CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
   V_CPC_PDEN_MAX         CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
   V_CPC_PDEN_FIX         CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
   V_COUNT                NUMBER;
   V_PROFILE_CODE         CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;   

   CURSOR c1
   is
      select     CBD_PROXY_NUMBER, CBD_TRAN_AMT, CBD_TRAN_CODE, CBD_RRN,
                 cbd_reson_code,cbd_comment,CBD_MERCHANT_NAME
            FROM cms_batchupload_detl
           WHERE cbd_file_name = p_file_name
             AND cbd_response_code = '00'
             AND cbd_inst_code = p_instcode
      FOR UPDATE;
BEGIN
   p_errmsg := 'OK';
   v_topupremrk := 'Online Card Topup';
   v_rvsl_code := '00';
 

   OPEN c1;

   LOOP
      BEGIN
         FETCH C1
          INTO v_proxy_number, v_txn_amt, v_txn_code, v_rrn, v_reason_code,v_comments,V_MERCHANT_NAME;

         EXIT when C1%NOTFOUND;
         V_RESPCODE := 1;
         V_LOGREASON_CODE:=v_reason_code;
         V_SAVEPOINT := V_SAVEPOINT + 1;
         savepoint V_SAVEPOINT;

          v_time_stamp := SYSTIMESTAMP;

         BEGIN
            SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'HH24MISS')
              INTO v_business_date,
                   v_business_time
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '12';
               v_errmsg :=
                     'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_tran_date := SYSDATE;

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         --En generate auth id

      
           --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
                   ctm_tran_type,ctm_tran_desc,ctm_prfl_flag
              INTO v_dr_cr_flag,
                   V_TXN_TYPE,
                   v_tran_type,V_trans_desc,v_prfl_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = v_txn_code
               AND ctm_delivery_channel = v_delivery_channel
               AND ctm_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '12';
               v_errmsg :=
                     'Transflag  not defined for txn code '
                  || v_txn_code
                  || ' and delivery channel '
                  || v_delivery_channel;
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg := 'Error while selecting transaction details';
               RAISE exp_main_reject_record;
         END;

         --En find debit and credit flag
         
         --Sn select Pan detail
         BEGIN
            SELECT   cap_card_stat, cap_prod_catg, cap_mbr_numb,
                     cap_prod_code, cap_card_type, cap_acct_no,
                     cap_cust_code, cap_pan_code, cap_pan_code_encr,
                     cap_pin_flag, cap_prfl_code
                INTO v_cap_card_stat, v_cap_prod_catg, v_mbrnumb,
                     v_prod_code, v_card_type, v_acct_number,
                     v_cust_code, v_hash_pan, v_encr_pan,
                     v_pin_flag, v_prfl_code
                FROM cms_appl_pan
               WHERE cap_proxy_number = v_proxy_number
                 AND cap_card_stat NOT IN ('0', '9')
                 AND cap_inst_code = p_instcode
            ORDER BY cap_active_date DESC;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT   cap_card_stat, cap_prod_catg, cap_mbr_numb,
                           cap_prod_code, cap_card_type, cap_acct_no,
                           cap_cust_code, cap_pan_code, cap_pan_code_encr,
                           cap_pin_flag, cap_prfl_code
                      INTO v_cap_card_stat, v_cap_prod_catg, v_mbrnumb,
                           v_prod_code, v_card_type, v_acct_number,
                           v_cust_code, v_hash_pan, v_encr_pan,
                           v_pin_flag, v_prfl_code
                      FROM cms_appl_pan
                     WHERE cap_proxy_number = v_proxy_number
                       AND cap_card_stat = 0
                       AND cap_inst_code = p_instcode
                  ORDER BY cap_ins_date DESC;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT   cap_card_stat, cap_prod_catg,
                                 cap_mbr_numb, cap_prod_code, cap_card_type,
                                 cap_acct_no, cap_cust_code, cap_pan_code,
                                 cap_pan_code_encr, cap_pin_flag,
                                 cap_prfl_code
                            INTO v_cap_card_stat, v_cap_prod_catg,
                                 v_mbrnumb, v_prod_code, v_card_type,
                                 v_acct_number, v_cust_code, v_hash_pan,
                                 v_encr_pan, v_pin_flag,
                                 v_prfl_code
                            FROM cms_appl_pan
                           WHERE cap_proxy_number = v_proxy_number
                             AND cap_card_stat = 9
                             AND cap_inst_code = p_instcode
                        ORDER BY cap_ins_date DESC;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_respcode := '21';
                           v_errmsg :=
                                     'Invalid card number ' || v_proxy_number;
                           RAISE exp_main_reject_record;
                        WHEN OTHERS
                        THEN
                           v_respcode := '21';
                           v_errmsg :=
                                 'Error while selecting card number '
                              || v_proxy_number;
                           RAISE exp_main_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                        'Error while selecting card number '
                        || v_proxy_number;
                     RAISE exp_main_reject_record;
               END;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                       'Error while selecting card number ' || v_proxy_number;
               RAISE exp_main_reject_record;
         END;

         --En select Pan detail
         BEGIN
            v_pan := fn_dmaps_main (v_encr_pan);
         EXCEPTION
            WHEN OTHERS
            then
               v_respcode := '21';
               v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
        
           --Start Generate HashKEY value
         BEGIN
            v_hashkey_id :=
               gethash (   v_delivery_channel
                        || v_txn_code
                        || v_pan
                        || v_rrn
                        || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '21';
               V_ERRMSG :=
                     'Error while selecting hashkey '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         end;


        BEGIN
               SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                     INTO v_acct_balance, v_ledger_bal, v_cam_type_code
                     FROM cms_acct_mast
                    WHERE cam_acct_no = v_acct_number
                      AND cam_inst_code = p_instcode
               FOR UPDATE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_respcode := '14';
                  v_errmsg := 'Invalid Account Number ';
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  v_respcode := '12';
                  v_errmsg :=
                        'Error while selecting data from Account Mast '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_MAIN_REJECT_RECORD;
            END;
             

         --End Generate HashKEY value
         begin
            select CJM_REASON_DESC,CJM_LOGREASON_CODE
              INTO v_reason_desc,V_LOGREASON_CODE
              FROM cms_jhload_reason_mast
             WHERE cjm_inst_code = p_instcode
               AND cjm_reason_code = SUBSTR (v_reason_code, 1, 1);

            IF (SUBSTR (v_reason_code, 1, 1) = 'F')
            THEN
               V_REASON_DESC := V_REASON_DESC ||V_TXN_AMT;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               V_RESPCODE := '21';
               V_ERRMSG :='Invalid Reson Code';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            then
               v_respcode := '21';
               V_ERRMSG :=
                     'Error while selecting reason description'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

            --Sn select variable type detail
        BEGIN
          BEGIN
              SELECT CPC_RELOADABLE_FLAG,CPC_PROD_DENOM, CPC_PDENOM_MIN, CPC_PDENOM_MAX,
              CPC_PDENOM_FIX,CPC_PROFILE_CODE
              INTO v_varprodflag,v_cpc_prod_deno, v_cpc_pden_min, v_cpc_pden_max,
              v_cpc_pden_fix,v_profile_code
              FROM cms_prod_cattype
              WHERE cpc_prod_code = v_prod_code
              AND cpc_card_type = V_CARD_TYPE
              AND cpc_inst_code = p_instcode;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
              v_respcode := '12';
              v_errmsg :=
              'No data for this Product code and category type'
              || v_prod_code;
            RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
              v_respcode := '12';
              v_errmsg :=
              'Error while selecting data from CMS_PROD_CATTYPE for Product code'
              || v_prod_code
              || SQLERRM;
            RAISE EXP_MAIN_REJECT_RECORD;
            END;  
        
          IF v_varprodflag = 'Y'  then         
            IF v_cpc_prod_deno = 1
            THEN
              IF v_txn_amt NOT BETWEEN v_cpc_pden_min AND v_cpc_pden_max
              THEN
              v_respcode := '43';
              v_errmsg := 'Invalid Amount';
              RAISE exp_main_reject_record;
              END IF;
            ELSIF v_cpc_prod_deno = 2
            THEN
              IF v_txn_amt <> v_cpc_pden_fix
              THEN
                v_respcode := '43';
                v_errmsg := 'Invalid Amount';
                RAISE exp_main_reject_record;
              END IF;
            ELSIF v_cpc_prod_deno = 3
            THEN
              SELECT COUNT (*)
              INTO v_count
              FROM VMS_PRODCAT_DENO_MAST
              WHERE VPD_INST_CODE = p_instcode
              AND VPD_PROD_CODE = v_prod_code
              AND VPD_CARD_TYPE = V_CARD_TYPE
              AND VPD_PDEN_VAL = v_txn_amt;
            
              IF v_count = 0
              THEN
                v_respcode := '43';
                v_errmsg := 'Invalid Amount';
                RAISE exp_main_reject_record;
              END IF;
          END IF;
        else           
          v_respcode := '21';
          v_errmsg :=
          'Top up is not applicable on this card number '
          || v_acct_number;
          RAISE exp_main_reject_record;
        END IF;
        EXCEPTION
        WHEN exp_main_reject_record
        THEN
          RAISE;
        WHEN NO_DATA_FOUND
        THEN
          v_respcode := '21';
          V_ERRMSG :=
          'Card type (fixed/variable ) is not defined for the card '
          || v_acct_number;
        RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
          V_RESPCODE := '21';
          v_errmsg := 'Error while selecting topup flag ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
        END;

         --En  select variable type detail
         BEGIN
            SELECT TRIM (cbp_param_value)
              INTO v_currcode
              FROM cms_bin_param
             WHERE cbp_param_name = 'Currency'
               AND cbp_inst_code = p_instcode
               AND cbp_profile_code = V_PROFILE_CODE;

            IF TRIM (v_currcode) IS NULL
            then
               V_RESPCODE := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            then
               V_RESPCODE := '21';
               v_errmsg :=
                          'Base currency is not defined for the institution ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            then
               V_RESPCODE := '21';
               v_errmsg :=
                     'Error while selecting bese currecy  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            IF (v_txn_amt > 0)
            THEN
               BEGIN
                  sp_convert_curr (p_instcode,
                                   v_currcode,
                                   v_pan,
                                   v_txn_amt,
                                   v_tran_date,
                                   v_tran_amt,
                                   v_card_curr,
                                   v_errmsg,
                                   V_PROD_CODE,
                                   V_CARD_TYPE);

                  IF v_errmsg <> 'OK'
                  THEN
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_respcode := '69';
                     v_errmsg :=
                           'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END;

         IF v_cap_card_stat = '9'
         THEN
            v_respcode := '46';
            v_errmsg := 'CLOSED CARD';
            RAISE exp_main_reject_record;
         END IF;

         IF v_cap_prod_catg = 'P'
         THEN
            

            --Sn find total transaction    amount
            IF v_dr_cr_flag = 'CR'
            THEN
               v_upd_amt := v_acct_balance + v_tran_amt;
               v_upd_ledger_bal := v_ledger_bal + v_tran_amt;
            END IF;

            --En find total transaction    amout
            BEGIN
               --Sn  for max card balance check based on product category
               SELECT TO_NUMBER (cbp_param_value)
                 INTO v_max_card_bal
                 FROM cms_bin_param
                WHERE cbp_inst_code = p_instcode
                  AND cbp_param_name = 'Max Card Balance'
                  AND cbp_profile_code = V_PROFILE_CODE;
            --En Added  for max card balance check based on product category
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_RESPCODE := '21';
                  v_errmsg :=  'Error while selecting Max card Balance '|| SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_MAIN_REJECT_RECORD;
            END;

            --Sn check balance
            IF    (v_upd_ledger_bal > v_max_card_bal)
               OR (v_upd_amt > v_max_card_bal)
            then
               v_respcode := '111';
               v_errmsg := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE exp_main_reject_record;
            END IF;

            BEGIN
               IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
               THEN
                  pkg_limits_check.sp_limits_check (v_hash_pan,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    v_txn_code,
                                                    v_tran_type,
                                                    NULL,
                                                    NULL,
                                                    p_instcode,
                                                    NULL,
                                                    v_prfl_code,
                                                    v_tran_amt,
                                                    v_delivery_channel,
                                                    v_comb_hash,
                                                    v_respcode,
                                                    v_respmsg
                                                   );
               END IF;

               IF v_respcode <> '00' AND v_respmsg <> 'OK'
               then
                     IF v_respcode = '79'
                     THEN
                        v_respcode := '231';
                        v_errmsg :=
                                'Denomination below minimal amount permitted';
                        RAISE exp_main_reject_record;
                     END IF;

                     IF v_respcode = '80'
                     THEN
                        v_respcode := '230';
                        v_errmsg := 'Denomination exceed permitted amount';
                        RAISE exp_main_reject_record;
                     end if;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error from Limit Check Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal + v_tran_amt,
                      cam_ledger_bal = cam_ledger_bal + v_tran_amt,
                      cam_topuptrans_count = cam_topuptrans_count + 1
                WHERE cam_inst_code = p_instcode
                  AND cam_acct_no = v_acct_number;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg := 'Problem while updating in account master';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error while updating CMS_ACCT_MAST '
                     || SUBSTR (SQLERRM, 1, 250);
                  RAISE exp_main_reject_record;
            END;

            IF TRIM (V_REASON_DESC) IS NOT NULL
            THEN
               v_narration := V_REASON_DESC || '/';
            end if;
            IF TRIM (v_MERCHANT_NAME) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || v_MERCHANT_NAME || '/';
            END IF;
            
            IF TRIM (v_business_date) IS NOT NULL
            THEN
               v_narration := v_narration || v_business_date || '/';
            END IF;

            IF TRIM (v_auth_id) IS NOT NULL
            THEN
               v_narration := v_narration || v_auth_id;
            END IF;

            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_inst_code,
                            csl_txn_code, csl_ins_date, csl_ins_user,
                            csl_acct_no, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_to_acctno,
                            csl_panno_last4digit,
                            csl_acct_type, csl_time_stamp, csl_prod_code
                           )
                    VALUES (v_hash_pan, ROUND (v_ledger_bal, 2),
                            ROUND (v_tran_amt, 2), v_dr_cr_flag,
                            v_tran_date,
                            ROUND (DECODE (v_dr_cr_flag,
                                           'DR', v_ledger_bal - v_tran_amt,
                                           'CR', v_ledger_bal + v_tran_amt,
                                           'NA', v_ledger_bal
                                          ),
                                   2
                                  ),
                            v_narration, v_encr_pan, v_rrn,
                            v_auth_id, v_business_date,
                            v_business_time, 'N',
                            v_delivery_channel, p_instcode,
                            v_txn_code, SYSDATE, 1,
                            v_acct_number, v_MERCHANT_NAME,
                            NULL, NULL,
                            v_acct_number,
                            (SUBSTR (v_pan, LENGTH (v_pan) - 3,
                                     LENGTH (v_pan))
                            ),
                            v_cam_type_code, v_time_stamp, v_prod_code
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '69';
                  v_errmsg :=
                        'Problem while inserting into statement log '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         END IF;

         --En create a entry in statement log
         IF v_cap_card_stat = '0'
         THEN
            BEGIN
               SELECT ccm_kyc_flag
                 INTO v_kyc_flag
                 from CMS_CUST_MAST
                WHERE ccm_cust_code = v_cust_code
                  AND ccm_inst_code = p_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_RESPCODE := '21';
                  V_ERRMSG := 'KYC FLAG not found for the customer '|| V_CUST_CODE ;
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               then
                  v_respcode := '21';
                  V_ERRMSG :=
                        'Error while selecting data from cust mast '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            IF v_kyc_flag in ('E','F')
            THEN
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '13',
                         cap_active_date = v_tran_date
                   WHERE cap_pan_code = v_hash_pan
                     AND cap_inst_code = p_instcode;

                  IF SQL%ROWCOUNT = 0
                  then
                     v_errmsg := 'Card status is not updated';
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while updating card ststus '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;

               BEGIN
                  sp_log_cardstat_chnge (p_instcode,
                                         v_hash_pan,
                                         v_encr_pan,
                                         v_auth_id,
                                         '09',
                                         v_rrn,
                                         v_business_date,
                                         v_business_time,
                                         v_respcode,
                                         v_errmsg
                                        );

                  IF v_respcode <> '00' AND v_errmsg <> 'OK'
                  THEN
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while logging system initiated card status change '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;

         --Sn select response code and insert record into txn log dtl
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode
               AND cms_delivery_channel = v_delivery_channel
               AND cms_response_id = v_respcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting data from response master '
                  || v_respcode
                  || SUBSTR (SQLERRM, 1, 300);
               v_respcode := '69';
               RAISE exp_main_reject_record;
         END;

         --En select response code and insert record into txn log dtl
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         CTD_CUST_ACCT_NUMBER, CTD_INST_CODE,
                         ctd_hashkey_id, ctd_reason_code,ctd_chw_comment
                        )
                 VALUES (v_delivery_channel, v_txn_code, v_tran_type,
                         '0', v_business_date, v_business_time,
                         v_hash_pan, v_txn_amt, v_currcode,
                         v_tran_amt, NULL,
                         NULL, NULL,
                         NULL, v_tran_amt, v_card_curr,
                         'Y', 'Successful', v_rrn,
                         NULL,
                         v_encr_pan, '0200',
                         V_ACCT_NUMBER, P_INSTCODE,
                         v_hashkey_id, V_LOGREASON_CODE,v_comments
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '69';
               v_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         topup_card_no, topup_acct_no, topup_acct_type,
                         bank_code,
                         total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         addcharge, productid, categoryid, tips,
                         decline_ruleid, atm_name_location, auth_id,
                         trans_desc,
                         amount,
                         preauthamount, partialamount, mccodegroupid,
                         currencycodegroupid, transcodegroupid, rules,
                         preauth_date, gl_upd_flag, system_trace_audit_no,
                         instcode, feecode, tranfee_amt, servicetax_amt,
                         cess_amt, cr_dr_flag, tranfee_cr_acctno,
                         tranfee_dr_acctno, tran_st_calc_flag,
                         tran_cess_calc_flag, tran_st_cr_acctno,
                         tran_st_dr_acctno, tran_cess_cr_acctno,
                         tran_cess_dr_acctno, customer_card_no_encr,
                         topup_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         response_id, add_ins_date, add_ins_user,
                         cardstatus, fee_plan, csr_achactiontaken,
                         ERROR_MSG, FEEATTACHTYPE, MERCHANT_NAME,
                         merchant_city, merchant_state, acct_type, time_stamp,REMARK
                        )
                 VALUES ('0200', v_rrn, v_delivery_channel, NULL,
                         v_tran_date, v_txn_code, v_txn_type, '0',
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         v_business_date, v_business_time, v_hash_pan,
                         NULL, NULL, NULL,
                         NULL,
                         TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                        '99999999999999990.99'
                                       )
                              ),
                         null, null, null, V_CURRCODE,
                         NULL, v_prod_code, v_card_type, NULL,
                         null, null, V_AUTH_ID,
                         NVL(V_REASON_DESC,v_trans_desc),
                         TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         '0.00', '0.00', NULL,
                         NULL, NULL, NULL,
                         NULL, NULL, NULL,
                         p_instcode, NULL, '0', '0',
                         '0', v_dr_cr_flag, NULL,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, v_encr_pan,
                         v_encr_pan, v_proxy_number, v_rvsl_code,
                         v_acct_number,
                         ROUND (DECODE (p_resp_code,
                                        '00', v_upd_amt,
                                        v_acct_balance
                                       ),
                                2
                               ),
                         ROUND (DECODE (p_resp_code,
                                        '00', v_upd_ledger_bal,
                                        v_ledger_bal
                                       ),
                                2
                               ),
                         v_respcode, SYSDATE, 1,
                         v_cap_card_stat, NULL, NULL,
                         V_ERRMSG, null, V_MERCHANT_NAME,
                         NULL, NULL, v_cam_type_code, v_time_stamp,v_comments
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '69';
               v_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_main_reject_record;
         END;

--En create a entry in txn log

         --Sn create a record in pan spprt
         BEGIN
            SELECT csr_spprt_rsncode
              INTO v_resoncode
              FROM cms_spprt_reasons
             WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            then
               v_errmsg := 'Top up reason code is not present in master';
               v_respcode := '21';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting reason code from master'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         BEGIN
            INSERT INTO cms_pan_spprt
                        (cps_inst_code, cps_pan_code, cps_mbr_numb,
                         cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                         cps_func_remark, cps_ins_user, cps_lupd_user,
                         cps_cmd_mode, cps_pan_code_encr
                        )
                 VALUES (p_instcode, v_hash_pan, v_mbrnumb,
                         v_cap_prod_catg, 'TOP', v_resoncode,
                         v_topupremrk, '1', '1',
                         0, v_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records into card support master'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         BEGIN
            IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
            THEN
               pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                                   v_hash_pan,
                                                   v_tran_amt,
                                                   v_comb_hash,
                                                   v_respcode,
                                                   v_respmsg
                                                  );
            END IF;

            IF v_respcode <> '00' AND v_respmsg <> 'OK'
            THEN
               v_errmsg := 'From Procedure sp_limitcnt_reset' || v_respmsg;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error from Limit Reset Count Process '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      EXCEPTION
         --<< MAIN EXCEPTION >>
         WHEN exp_main_reject_record
         THEN
            ROLLBACK TO v_savepoint;

           --Sn select response code and insert record into txn log dtl
            BEGIN
               -- Assign the response code to the out parameter
               SELECT cms_iso_respcde
                 INTO p_resp_code
                 FROM cms_response_mast
                WHERE cms_inst_code = p_instcode
                  AND cms_delivery_channel = v_delivery_channel
                  AND cms_response_id = v_respcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while selecting data from response master '
                     || v_respcode
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '89';
            END;

            --Sn create a entry in txn log
            BEGIN
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, terminal_id,
                            date_time, txn_code, txn_type, txn_mode,
                            txn_status,
                            response_code, business_date, business_time,
                            customer_card_no, topup_card_no, topup_acct_no,
                            topup_acct_type, bank_code,
                            total_amount,
                            currencycode, addcharge, productid, categoryid,
                            atm_name_location, auth_id,
                            amount,
                            preauthamount, partialamount, instcode,
                            customer_card_no_encr, topup_card_no_encr,
                            proxy_number, reversal_code, customer_acct_no,
                            acct_balance, ledger_balance, response_id,
                            ani, dni, ipaddress, cardstatus, trans_desc,
                            MERCHANT_NAME, MERCHANT_CITY, MERCHANT_STATE,
                            time_stamp, error_msg,cr_dr_flag,acct_type,REMARK
                           )
                    VALUES ('0200', v_rrn, v_delivery_channel, NULL,
                            v_tran_date, v_txn_code, v_txn_type, '0',
                            DECODE (p_resp_code, '00', 'C', 'F'),
                            p_resp_code, v_business_date, v_business_time,
                            v_hash_pan, NULL, NULL,
                            NULL, p_instcode,
                            TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                            v_currcode, NULL, v_prod_code, v_card_type,
                            NULL, v_auth_id,
                            TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                            NULL, NULL, p_instcode,
                            v_encr_pan, v_encr_pan,
                            v_proxy_number, v_rvsl_code, v_acct_number,
                            v_acct_balance, v_ledger_bal, v_respcode,
                            NULL, NULL, NULL, v_cap_card_stat, NVL(V_REASON_DESC,v_trans_desc),
                            V_MERCHANT_NAME, null, null,
                            v_time_stamp, v_errmsg,v_dr_cr_flag,v_cam_type_code,v_comments
                           );
            EXCEPTION
               when OTHERS
               then
                  p_resp_code := '89';
                  v_errmsg :=
                        'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
            END;

            --En create a entry in txn log

            --Sn create a entry in cms_transaction_log_dtl
            BEGIN
               INSERT INTO cms_transaction_log_dtl
                           (ctd_delivery_channel, ctd_txn_code,
                            ctd_msg_type, ctd_txn_mode, ctd_business_date,
                            ctd_business_time, ctd_customer_card_no,
                            ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                            ctd_fee_amount, ctd_waiver_amount,
                            ctd_servicetax_amount, ctd_cess_amount,
                            ctd_bill_amount, ctd_bill_curr,
                            ctd_process_flag, ctd_process_msg, ctd_rrn,
                            ctd_inst_code, ctd_customer_card_no_encr,
                            CTD_CUST_ACCT_NUMBER, CTD_REASON_CODE,
                            ctd_hashkey_id,ctd_txn_type,ctd_chw_comment
                           )
                    VALUES (v_delivery_channel, v_txn_code,
                            '0200', '0', v_business_date,
                            v_business_time, v_hash_pan,
                            v_tran_amt, v_currcode, v_txn_amt,
                            NULL, NULL,
                            NULL, NULL,
                            NULL, NULL,
                            'E', SUBSTR (v_errmsg, 0, 300), v_rrn,
                            p_instcode, v_encr_pan,
                            V_ACCT_NUMBER, V_LOGREASON_CODE,
                            v_hashkey_id,v_tran_type,v_comments
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '89';
            END;
      END;
      
      BEGIN
            UPDATE cms_batchupload_detl
               SET cbd_response_code = p_resp_code,
                   cbd_response_desc = v_errmsg,
                   cbd_pingen_flag = v_pin_flag,
                   cbd_pan_code_encr = v_encr_pan
             WHERE cbd_file_name = p_file_name
               AND cbd_inst_code = p_instcode
               AND cbd_proxy_number = v_proxy_number
               AND cbd_rrn = v_rrn;
            
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while updating data in batch upload detl'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
         END;
      
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error