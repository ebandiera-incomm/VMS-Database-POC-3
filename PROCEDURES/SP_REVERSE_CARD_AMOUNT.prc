create or replace
PROCEDURE        VMSCMS.SP_REVERSE_CARD_AMOUNT (
   p_inst_code         IN       NUMBER,
   p_func_code         IN       VARCHAR2,
   p_rrn               IN       VARCHAR2,
   p_delv_chnl         IN       VARCHAR2,
   p_terminal_id       IN       VARCHAR2,
   p_merc_id           IN       VARCHAR2,
   p_txn_code          IN       VARCHAR2,
   p_tran_date         IN       DATE,
   p_txn_mode          IN       VARCHAR2,
   p_card_no           IN       VARCHAR2,
   p_tran_amt          IN       NUMBER,
   p_orgnl_rrn         IN       VARCHAR2,
   p_card_acct_no      IN       VARCHAR2,
   p_txn_date          IN       VARCHAR2,
   p_tran_time         IN       VARCHAR2,
   p_auth_id           IN       VARCHAR2,
   p_narration         IN       VARCHAR2,
   p_orgnl_tran_date   IN       VARCHAR2,
   p_orgnl_tran_time   IN       VARCHAR2,
   p_merc_name         IN       VARCHAR2,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
   p_merc_city         IN       VARCHAR2,
   p_merc_state        IN       VARCHAR2,
   p_resp_cde          OUT      VARCHAR2,
   p_resp_msg          OUT      VARCHAR2,
   p_rev_txn_code      IN       VARCHAR2 DEFAULT NULL
)
AS
/*************************************************
     * Created Date     :  10-Dec-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For reverse card amount
     * Modified By      :  Trivikram
     * Modified Date    :  23-MAY-2012
     * Modified Reason  :  Looging last 4 digit of the card number in statement log incase of fees relative txn
     * Reviewer         :  Nandakumar
     * Reviewed Date    :  23-May-2012
     * Release Number   :   CMS3.4.3_RI0006.3_B0009

     * Modified By      : Sachin P.
     * Modified Date    : 22-Mar-2013
     * Modified Reason  : Merchant Logging Info for the Reversal Txn
     * Modified For     : FSS-1077
     * Reviewer         :
     * Reviewed Date    : CMS3.5.1_RI0024_B0008
     * Build Number     :

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  19-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0013

     * Modified by      :  Pankaj S.
     * Modified Reason  :  FWR-44
     * Modified Date    :  14-Jan-2014
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :

     * Modified by      :  Pankaj S.
     * Modified Reason  :  13388
     * Modified Date    :  20-Jan-2014
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  20-Jan-2014
     * Build Number     :  RI0027_B0004

     * Modified by      :  Shweta
     * Modified Reason  :  13541
     * Modified Date    :  28-Jan-2014
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0027_B0005

     * Modified by      :  Siva Kumar
     * Modified Reason  :  13787
     * Modified Date    :  05-Mar-2014
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  05-Mar-2014
     * Build Number     :  RI0027.2_B0001

     * Modified By      :  Mageshkumar S
     * Modified For     :  FWR-48
     * Modified Date    :  25-July-2014
     * Modified Reason  :  GL Mapping Removal Changes.
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0001

     * Modified By      :  Sai Prasad
     * Modified For     :  FWR-48 (0015647 / 0015653 / 0015654 / 0015655 )
     * Modified Date    :  11-Aug-2014
     * Modified Reason  :  GL Mapping Removal Changes - Credit transaction reversal issue.
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0002

     * Modified By      :  Dhinakaran B
     * Modified For     :  Mantis ID-15881
     * Modified Date    :  17-Nov-2014
     * Reviewer         :
     * Build Number     :

     * Modified By      :  Abdul Hameed M.A
     * Modified For     :  DFCTNM-4
     * Modified Date    :  1-Mar-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5_B0011


    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
 *************************************************/
   v_orgnl_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_orgnl_prod_cattype     cms_appl_pan.cap_card_type%TYPE;
  /* v_orgnl_cr_gl_code       cms_func_prod.cfp_crgl_code%TYPE;
   v_orgnl_crgl_catg        cms_func_prod.cfp_crgl_catg%TYPE;
   v_orgnl_crsubgl_code     cms_func_prod.cfp_crsubgl_code%TYPE;
   v_orgnl_cracct_no        cms_func_prod.cfp_cracct_no%TYPE;
   v_orgnl_dr_gl_code       cms_func_prod.cfp_drgl_code%TYPE;
   v_orgnl_drgl_catg        cms_func_prod.cfp_drgl_catg%TYPE;
   v_orgnl_drsubgl_code     cms_func_prod.cfp_drsubgl_code%TYPE;*/ --commented for fwr-48
   v_orgnl_dracct_no        cms_func_prod.cfp_dracct_no%TYPE;
   v_rvsl_cracct_no         cms_func_prod.cfp_cracct_no%TYPE;
   v_rvsl_dracct_no         cms_func_prod.cfp_cracct_no%TYPE;
   v_credit_acct_bal        cms_acct_mast.cam_acct_bal%TYPE;
   v_debit_acct_bal         cms_acct_mast.cam_acct_bal%TYPE;
   v_dr_cr_flag             VARCHAR (2);
   v_resp_cde               VARCHAR2 (3);
   v_err_msg                VARCHAR2 (500);
   exp_rvsl_reject_record   EXCEPTION;
   v_orgnl_rrn              VARCHAR2 (25);
   v_topup_card_no          VARCHAR2 (90);
   v_check_bin_date         NUMBER;
   v_max_card_bal_bin       NUMBER;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_narration          cms_statements_log.csl_trans_narrration%TYPE;
   v_tran_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_to_acct_no             cms_acct_mast.cam_acct_no%TYPE;
   --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
   v_txn_merchname          cms_statements_log.csl_merchant_name%TYPE;
   v_txn_merchcity          cms_statements_log.csl_merchant_city%TYPE;
   v_txn_merchstate         cms_statements_log.csl_merchant_state%TYPE;
   --Sn added by Pankaj S. for 10871
   v_debit_ledger_bal       cms_acct_mast.cam_ledger_bal%TYPE;
   v_credit_ledger_bal      cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type              cms_acct_mast.cam_type_code%TYPE;
   v_topup_accttype         cms_acct_mast.cam_type_code%TYPE;
   v_topup_prodcode         cms_appl_pan.cap_prod_code%TYPE;
   v_topup_cardtype         cms_prod_cattype.cpc_card_type%type;
   v_timestamp              timestamp(3);
   --Sn added by Pankaj S. for 10871
   v_topup_acct_no          cms_acct_mast.cam_acct_no%TYPE;  --Added fpr FWR-44
   v_loadtrans_flag        cms_transaction_mast.CTM_LOADTRANS_FLAG%TYPE; -- added for Mantis ID:13787
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   v_resp_cde := '00';
   v_err_msg := 'OK';
   v_orgnl_rrn := p_orgnl_rrn;

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN create encr pan

   --Sn find the prod code and card type
   BEGIN
      SELECT cap_prod_code, cap_card_type
        INTO v_orgnl_prod_code, v_orgnl_prod_cattype
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '16';                         --Ineligible Transaction
         v_err_msg := 'Card number not found ' || p_txn_code;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En find the prod code and card type
   BEGIN -- Modified for Mantis Id:13787
      SELECT ctm_credit_debit_flag, ctm_preauth_flag,ctm_loadtrans_flag
        INTO v_dr_cr_flag, v_tran_preauth_flag,v_loadtrans_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delv_chnl
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '12';                         --Ineligible Transaction
         v_err_msg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delv_chnl;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';                         --Ineligible Transaction
         v_err_msg := 'Error while selecting transaction details';
         RAISE exp_rvsl_reject_record;
   END;

   --Sn find the orginal debit and credit leg
   IF (v_tran_preauth_flag != 'Y') AND (v_dr_cr_flag != 'NA')
   THEN
   --Sn - commented for fwr-48
    /*  BEGIN
         SELECT cfp_crgl_code, cfp_crgl_catg, cfp_crsubgl_code,
                cfp_cracct_no, cfp_drgl_code, cfp_drgl_catg,
                cfp_drsubgl_code, cfp_dracct_no
           INTO v_orgnl_cr_gl_code, v_orgnl_crgl_catg, v_orgnl_crsubgl_code,
                v_orgnl_cracct_no, v_orgnl_dr_gl_code, v_orgnl_drgl_catg,
                v_orgnl_drsubgl_code, v_orgnl_dracct_no
           FROM cms_func_prod
          WHERE cfp_func_code = p_func_code
            AND cfp_prod_code = v_orgnl_prod_code
            AND cfp_prod_cattype = v_orgnl_prod_cattype
            AND cfp_inst_code = p_inst_code;

         IF TRIM (v_orgnl_cracct_no) IS NULL
            AND TRIM (v_orgnl_dracct_no) IS NULL
         THEN
            v_resp_cde := '99';
            v_err_msg :=
                  'Both credit and debit account cannot be null for a transaction code '
               || p_txn_code
               || ' Function code '
               || p_func_code;
            RAISE exp_rvsl_reject_record;
         END IF;

         IF TRIM (v_orgnl_cracct_no) = TRIM (v_orgnl_dracct_no)
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Credit and debit account cannot be same ';
            RAISE exp_rvsl_reject_record;
         END IF;

         IF TRIM (v_orgnl_cracct_no) IS NULL
         THEN
            v_orgnl_cracct_no := p_card_acct_no;
         END IF;

         IF TRIM (v_orgnl_dracct_no) IS NULL
         THEN
            v_orgnl_dracct_no := p_card_acct_no;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Credit and debit gl is not defined for the funcode'
               || p_func_code
               || ' Product '
               || v_orgnl_prod_code
               || 'Prod cattype '
               || v_orgnl_prod_cattype;
            RAISE exp_rvsl_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'More than one record found for function code '
               || p_func_code
               || ' Product '
               || v_orgnl_prod_code
               || 'Prod cattype '
               || v_orgnl_prod_cattype;
            RAISE exp_rvsl_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while selecting GL details '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END; */ --En - commented for fwr-48

      --En find the orginal credit and debit leg

      --Sn Set the reversal acct
   --   v_rvsl_cracct_no := v_orgnl_dracct_no; --commented for fwr-48
   --   v_rvsl_dracct_no := v_orgnl_cracct_no; --commented for fwr-48
    IF (v_dr_cr_flag != 'CR') THEN --Mantis ID 0015647
    v_rvsl_cracct_no := p_card_acct_no; --modified for fwr-48
    v_rvsl_dracct_no := null; --modified for fwr-48
    ELSE
    v_rvsl_cracct_no := null; --modified for fwr-48 Mantis ID 0015647
    v_rvsl_dracct_no := p_card_acct_no; --modified for fwr-48 Mantis ID 0015647
  END IF; --Mantis ID 0015647
   --En set the reversal acct
   elsif(v_tran_preauth_flag = 'Y') AND (v_dr_cr_flag = 'CR')
   then
    v_rvsl_cracct_no := null;
    v_rvsl_dracct_no := p_card_acct_no;
   ELSE
      v_rvsl_cracct_no := p_card_acct_no;
--No GL Mapping for Pre-Auth.During reversal amount to be released to the acct balance
   END IF;

   v_timestamp:=systimestamp;  --added by Pankaj S. for 10871

   --SN CREDIT THE CONCERN ACCOUNT
   IF v_rvsl_cracct_no = p_card_acct_no
   THEN
      --Sn get the opening balance
      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,cam_type_code --added by Pankaj S. for 10871
           INTO v_credit_acct_bal,
                v_credit_ledger_bal,v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = p_card_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                        'Account no not found in master ' || v_rvsl_cracct_no;
            RAISE exp_rvsl_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting acct data for acct '
               || v_rvsl_cracct_no
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;

      --En get the opening balance
      BEGIN
         IF ((v_dr_cr_flag = 'NA') AND (v_tran_preauth_flag = 'Y'))
         THEN
            IF LENGTH (p_orgnl_rrn) > 2
            THEN
               IF SUBSTR (p_orgnl_rrn, 2, 1) = ':'
               THEN
                  IF SUBSTR (p_orgnl_rrn, 1, 1) = 'N'
                  THEN
                     UPDATE cms_acct_mast
                        SET cam_acct_bal = cam_acct_bal + p_tran_amt,
                            cam_ledger_bal = cam_ledger_bal + p_tran_amt
                      WHERE cam_inst_code = p_inst_code
                        AND cam_acct_no = p_card_acct_no;
                  ELSE
                     UPDATE cms_acct_mast
                        SET cam_acct_bal = cam_acct_bal + p_tran_amt
                      WHERE cam_inst_code = p_inst_code
                        AND cam_acct_no = p_card_acct_no;
                  END IF;

                  v_orgnl_rrn := SUBSTR (p_orgnl_rrn, 3, LENGTH (p_orgnl_rrn));
               ELSE
                  UPDATE cms_acct_mast
                     SET cam_acct_bal = cam_acct_bal + p_tran_amt
                   WHERE cam_inst_code = p_inst_code
                     AND cam_acct_no = p_card_acct_no;
               END IF;
            END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while updating in account master for transaction account '
                  || p_card_acct_no;
               RAISE exp_rvsl_reject_record;
            END IF;

         ELSE
                     if p_delv_chnl = '08' AND P_TXN_CODE = '28' then

                         UPDATE cms_acct_mast
                       SET cam_acct_bal = cam_acct_bal + p_tran_amt,
                           cam_ledger_bal = cam_ledger_bal + p_tran_amt,
                           cam_initialload_amt = cam_initialload_amt+ p_tran_amt,
                           cam_first_load_date = sysdate
                     WHERE cam_inst_code = p_inst_code
                           AND cam_acct_no = p_card_acct_no;

                    IF SQL%ROWCOUNT = 0
                    THEN
                       v_resp_cde := '21';
                       v_err_msg :=
                             'Problem while updating in account master for transaction account '
                          || p_card_acct_no;
                       RAISE exp_rvsl_reject_record;
                    END IF;

                    else
                    UPDATE cms_acct_mast
                       SET cam_acct_bal = cam_acct_bal + p_tran_amt,
                           cam_ledger_bal = cam_ledger_bal + p_tran_amt
                     WHERE cam_inst_code = p_inst_code
                           AND cam_acct_no = p_card_acct_no;

                    IF SQL%ROWCOUNT = 0
                    THEN
                       v_resp_cde := '21';
                       v_err_msg :=
                             'Problem while updating in account master for transaction account '
                          || p_card_acct_no;
                       RAISE exp_rvsl_reject_record;
                    END IF;
                    end if;


          end if;


       EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while updating acct balance '
               || p_card_acct_no ||p_tran_amt
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;

      -- CHANGED FOR CARD TO CARD TRANSFER REVERSAL
      BEGIN
          IF (P_DELV_CHNL='07' AND P_TXN_CODE IN('07','57'))
             OR (P_DELV_CHNL ='10' AND P_TXN_CODE IN('07','76'))
             OR (P_DELV_CHNL = '13' AND P_TXN_CODE IN('13','90'))   --Modified for FWR-44
         THEN
            BEGIN
               SELECT topup_card_no
                 INTO v_topup_card_no
                 FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                WHERE rrn = p_orgnl_rrn
                  AND customer_card_no = v_hash_pan
                  AND instcode = p_inst_code
                  AND response_code = '00';
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg := 'Error while selecting TRANSACTIONLOG '|| p_card_acct_no|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_topup_card_no IS NULL
            THEN
               v_resp_cde := '23';
               v_err_msg := 'Original Transaction not done properly';
               RAISE exp_rvsl_reject_record;
            ELSE
               BEGIN
                  SELECT fn_dmaps_main (cap_pan_code_encr),
                         cap_prod_code,cap_card_type --added by Pankaj S. for 10871
                    INTO v_topup_card_no,
                         v_topup_prodcode, --added by Pankaj S. for 10871
                         v_topup_cardtype
                    FROM cms_appl_pan
                   WHERE cap_pan_code = v_topup_card_no;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     v_err_msg :=
                           'Error while selecting CMS_APPL_PAN '
                        || p_card_acct_no
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;

            BEGIN
               SELECT cam_acct_bal, cam_acct_no,
                      cam_ledger_bal,cam_type_code --Added by Pankaj S. for 10871
                 INTO v_debit_acct_bal, v_to_acct_no,
                      v_debit_ledger_bal,v_topup_accttype --Added by Pankaj S. for 10871
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =
                         (SELECT cap.cap_acct_no
                            FROM cms_appl_pan cap
                           WHERE cap.cap_pan_code = gethash (v_topup_card_no));
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while selecting CMS_ACCT_MAST '
                     || p_card_acct_no
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_debit_acct_bal < p_tran_amt
            THEN
               v_resp_cde := '92';
               v_err_msg := 'Not Sufficient Funds in To Card Number';
               RAISE exp_rvsl_reject_record;
            END IF;

            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal - p_tran_amt,
                      cam_ledger_bal = cam_ledger_bal - p_tran_amt
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =
                         (SELECT cap.cap_acct_no
                            FROM cms_appl_pan cap
                           WHERE cap.cap_pan_code = gethash (v_topup_card_no));

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while updating in account master for transaction acct '
                     || v_topup_card_no;
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while updating CMS_ACCT_MAST '
                     || p_card_acct_no
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_dr_cr_flag <> 'NA'
            THEN
               BEGIN
			   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                  SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate
                    FROM cms_statements_log
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = gethash (v_topup_card_no)
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N';
ELSE
					 SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate
                    FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = gethash (v_topup_card_no)
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N';
END IF;					 
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_txn_narration := NULL;
                  WHEN OTHERS
                  THEN
                     v_txn_narration := NULL;
               END;

               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount,
                               csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration, csl_inst_code,
                               csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no,
             --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                           csl_ins_user, csl_ins_date,
                               csl_merchant_name,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                                                 csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit,
                               csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp  --added by Pankaj S. for 10871
                              )
    --Added by Trivikram on 22-May-2012 to log last 4 Digit of the card number
                       VALUES (gethash (v_topup_card_no), v_debit_ledger_bal,  --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                               NVL(p_tran_amt,0) --formated by Pankaj S. for 10871
                               , 'DR',
                               p_tran_date,
                               DECODE (v_dr_cr_flag,
                                       'DR', v_debit_ledger_bal - p_tran_amt, --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                       'CR', v_debit_ledger_bal + p_tran_amt, --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                       'NA', v_debit_ledger_bal               --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                      ),
                               'RVSL-' || v_txn_narration, p_inst_code,
                               fn_emaps_main (v_topup_card_no), p_rrn,
                               p_auth_id, p_txn_date,
                               p_tran_time, 'N',
                               p_delv_chnl, nvl(p_rev_txn_code,p_txn_code),
                               v_to_acct_no,
             --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                            1, SYSDATE,
                               /*V_TXN_MERCHNAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                               V_TXN_MERCHCITY,
                               V_TXN_MERCHSTATE,*/--Commented and modified on 22.03.2013 for Merchant Logging Info for the Reversal Txn
                               p_merc_name, p_merc_city,
                               p_merc_state,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               ),
                               v_topup_prodcode,v_topup_cardtype,v_topup_accttype,v_timestamp  --added by Pankaj S. for 10871
                              );
     --Added by Trivikam on 22-May-2012 to log Last 4 Digit of the card number
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     v_err_msg :=
                           'Error while inserting CMS_STATEMENTS_LOG '
                        || p_card_acct_no
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;

            BEGIN
               sp_daily_bin_bal (v_topup_card_no,
                                 p_tran_date,
                                 p_tran_amt,
                                 'DR',
                                 p_inst_code,
                                 '',
                                 v_err_msg
                                );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while calling SP_DAILY_BIN_BAL '
                     || p_card_acct_no
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;
      END;
      -- CHANGED FOR CARD TO CARD TRANSFER REVERSAL

      --Sn Added for FWR-44
      BEGIN
         IF (p_delv_chnl ='07'AND p_txn_code IN ('10','11')) OR (p_delv_chnl = '10' AND p_txn_code IN ('19','20')) OR (p_delv_chnl = '13' AND p_txn_code IN ('04','11'))
            OR (p_delv_chnl = '05' AND p_txn_code='23') THEN  --Added for Mantis ID-13388
          IF (p_delv_chnl IN ('07','13') AND p_txn_code='11') OR (p_delv_chnl = '10' AND p_txn_code='20') THEN
            BEGIN
               SELECT customer_acct_no
                 INTO v_topup_acct_no
                 FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                WHERE rrn = p_orgnl_rrn
                  AND customer_card_no = v_hash_pan
                  AND instcode = p_inst_code
                  AND response_code = '00';
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct from TRANSACTIONLOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

          ELSE
            BEGIN
               SELECT topup_acct_no
                 INTO v_topup_acct_no
                 FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                WHERE rrn = p_orgnl_rrn
                  AND customer_card_no = v_hash_pan
                  AND instcode = p_inst_code
                  AND response_code = '00';
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct from TRANSACTIONLOG 1.1-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
          END IF;

            IF v_topup_acct_no IS NULL THEN
               v_resp_cde := '23';
               v_err_msg := 'Original Transaction not done properly 1.0';
               RAISE exp_rvsl_reject_record;
            END IF;

            BEGIN
               SELECT cam_acct_bal, cam_acct_no, cam_ledger_bal,cam_type_code
                 INTO v_debit_acct_bal, v_to_acct_no, v_debit_ledger_bal,v_topup_accttype
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =v_topup_acct_no;
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct dtls 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_debit_acct_bal < p_tran_amt THEN
               v_resp_cde := '92';
               v_err_msg := 'Not Sufficient Funds in to_acct Number 1.0';
               RAISE exp_rvsl_reject_record;
            END IF;

            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal - p_tran_amt,
                      cam_ledger_bal = cam_ledger_bal - p_tran_amt
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =v_topup_acct_no;

               IF SQL%ROWCOUNT = 0 THEN
                  v_resp_cde := '21';
                  v_err_msg :='Problem while updating in account master for to_acct 1.0';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                RAISE;
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while updating account master for to_acct 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_dr_cr_flag <> 'NA' THEN
               BEGIN
			   
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                  SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state,csl_prod_code
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate,v_topup_prodcode
                    FROM cms_statements_log
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = v_hash_pan
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N'
                     AND rownum=1;
ELSE
					SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state,csl_prod_code
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate,v_topup_prodcode
                    FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = v_hash_pan
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N'
                     AND rownum=1;
END IF;					 
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_txn_narration := NULL;
                  WHEN OTHERS THEN
                     v_txn_narration := NULL;
               END;

               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration, csl_inst_code,
                               csl_pan_no_encr, csl_rrn, csl_auth_id,
                               csl_business_date, csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code, csl_acct_no,
                               csl_ins_user, csl_ins_date, csl_merchant_name,
                               csl_merchant_city, csl_merchant_state,
                               csl_panno_last4digit,
                               csl_prod_code, csl_acct_type,
                               csl_time_stamp
                              )
                  VALUES      (v_hash_pan, v_debit_ledger_bal,NVL (p_tran_amt, 0),'DR', p_tran_date,
                               v_debit_ledger_bal - p_tran_amt,
                               'RVSL-' || v_txn_narration, p_inst_code,
                               v_encr_pan, p_rrn, p_auth_id,p_txn_date, p_tran_time, 'N',
                               p_delv_chnl, nvl(p_rev_txn_code,p_txn_code), v_topup_acct_no,
                               1, SYSDATE,p_merc_name,p_merc_city, p_merc_state,
                               (SUBSTR (p_card_no,LENGTH (p_card_no) - 3,LENGTH (p_card_no))),
                               v_topup_prodcode, v_topup_accttype,v_timestamp
                              );
               EXCEPTION
                  WHEN OTHERS THEN
                     v_resp_cde := '21';
                     v_err_msg := 'Error while inserting into CMS_STATEMENTS_LOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;

            BEGIN
               sp_daily_bin_bal (p_card_no,
                                 p_tran_date,
                                 p_tran_amt,
                                 'DR',
                                 p_inst_code,
                                 '',
                                 v_err_msg
                                );
                IF v_err_msg<>'OK' THEN
                  RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                RAISE;
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while calling SP_DAILY_BIN_BAL 1.0- '|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;
      END;
      --En Added for FWR-44

      IF ((v_dr_cr_flag != 'NA') AND (v_tran_preauth_flag != 'Y'))
      THEN
         v_dr_cr_flag := 'CR';
      ELSIF v_dr_cr_flag = 'DR' AND v_tran_preauth_flag = 'Y'
      THEN
         V_DR_CR_FLAG := 'CR';
       ELSIF v_dr_cr_flag = 'CR' AND v_tran_preauth_flag = 'Y'
      then
         v_dr_cr_flag := 'DR';
      END IF;

      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance,
                         csl_trans_narrration, csl_inst_code,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_txn_code, csl_acct_no,
             --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         csl_ins_user, csl_ins_date, csl_merchant_name,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                         csl_merchant_city, csl_merchant_state,
                         csl_panno_last4digit,
                         csl_prod_code,csl_acct_type,csl_time_stamp  --added by Pankaj S. for 10871
                        )
    --Added by Trivikram on 22-May-2012 to log last 4 Digit of the card number
                 VALUES (v_hash_pan, v_credit_ledger_bal, --v_credit_acct_bal replaced by Pankaj S. with v_credit_ledger_bal for 10871
                         NVL(p_tran_amt,0), --formatted by Pankaj S. for 10871
                         v_dr_cr_flag, p_tran_date,
                         DECODE (v_dr_cr_flag,
                                 'DR', v_credit_ledger_bal - p_tran_amt, --v_credit_acct_bal replaced by Pankaj S. with v_credit_ledger_bal for 10871
                                 'CR', v_credit_ledger_bal + p_tran_amt, --v_credit_acct_bal replaced by Pankaj S. with v_credit_ledger_bal for 10871
                                 'NA', v_credit_ledger_bal               --v_credit_acct_bal replaced by Pankaj S. with v_credit_ledger_bal for 10871
                                ),
                         'RVSL-' || p_narration, p_inst_code,
                         v_encr_pan, p_rrn, p_auth_id,
                         p_txn_date, p_tran_time, 'N',
                         p_delv_chnl, nvl(p_rev_txn_code,p_txn_code), p_card_acct_no,
             --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         1, SYSDATE, p_merc_name,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                         p_merc_city, p_merc_state,
                         (SUBSTR (p_card_no,
                                  LENGTH (p_card_no) - 3,
                                  LENGTH (p_card_no)
                                 )
                         ),
                         v_orgnl_prod_code,v_acct_type,v_timestamp  --added by Pankaj S. for 10871
                        );
     --Added by Trivikam on 22-May-2012 to log Last 4 Digit of the card number
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
      END IF;
   --En create a entry in statement log
 /*  ELSE
      --Sn insert a record into EODUPDATE_ACCT
      BEGIN
         sp_ins_eodupdate_acct (p_rrn,
                                p_terminal_id,
                                p_delv_chnl,
                                p_txn_code,
                                p_txn_mode,
                                p_tran_date,
                                p_card_acct_no,
                                v_rvsl_cracct_no,
                                p_tran_amt,
                                'C',
                                p_inst_code,
                                v_err_msg
                               );

         IF v_err_msg <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error from credit eod update acct ' || v_err_msg;
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while calling SP_INS_EODUPDATE_ACCT'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;*/--review changes for fwr-48
   END IF;

   --En  insert a record into EODUPDATE_ACCT
   --EN CREDIT THE CONCERN ACCOUNT
   --SN DEBIT THE CONCERN ACCOUNT
   IF v_rvsl_dracct_no = p_card_acct_no
   THEN
      --Sn get the opening balance
      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,cam_type_code --Added by Pankaj S. for 10871
           INTO v_debit_acct_bal,
                v_debit_ledger_bal,v_topup_accttype --Added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_rvsl_dracct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                        'Account no not found in master ' || v_rvsl_dracct_no;
            RAISE exp_rvsl_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting acct data for acct '
               || v_rvsl_dracct_no
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;

       IF ((p_delv_chnl = '08' AND P_TXN_CODE = '26') OR (p_delv_chnl = '04' AND P_TXN_CODE = '69')) THEN -- Initial Load reversal updation.

       --En get the opening balance
         BEGIN
         UPDATE cms_acct_mast
            SET cam_acct_bal = cam_acct_bal - p_tran_amt,
                cam_ledger_bal = cam_ledger_bal - p_tran_amt,
                CAM_INITIALLOAD_AMT = 0,
                cam_first_load_date = null
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_rvsl_dracct_no;

             IF SQL%ROWCOUNT = 0
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Problem while updating in account master for transaction acct '
                   || v_rvsl_dracct_no;
                RAISE exp_rvsl_reject_record;
             END IF;
         EXCEPTION
             WHEN exp_rvsl_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Error while updating acct balance '
                   || v_rvsl_dracct_no
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
            END;

      ELSE

       IF  v_loadtrans_flag = 'Y' THEN -- Top Up count updation

           BEGIN

             UPDATE cms_acct_mast
                SET cam_acct_bal = cam_acct_bal - p_tran_amt,
                    cam_ledger_bal = cam_ledger_bal - p_tran_amt,
                        cam_topuptrans_count = cam_topuptrans_count-1
              WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_rvsl_dracct_no;

             IF SQL%ROWCOUNT = 0
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Problem while updating in account master for transaction acct '
                   || v_rvsl_dracct_no;
                RAISE exp_rvsl_reject_record;
             END IF;
           EXCEPTION
             WHEN exp_rvsl_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Error while updating acct balance '
                   || v_rvsl_dracct_no
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
            END;

       ELSE
            --En get the opening balance
           BEGIN

             UPDATE cms_acct_mast
                SET cam_acct_bal = cam_acct_bal - p_tran_amt,
                    cam_ledger_bal = cam_ledger_bal - p_tran_amt
              WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_rvsl_dracct_no;

             IF SQL%ROWCOUNT = 0
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Problem while updating in account master for transaction acct '
                   || v_rvsl_dracct_no;
                RAISE exp_rvsl_reject_record;
             END IF;
           EXCEPTION
             WHEN exp_rvsl_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Error while updating acct balance '
                   || v_rvsl_dracct_no
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
            END;

        END IF;

      END IF;
      --Sn create a entry in statement log
      IF ((v_dr_cr_flag != 'NA') AND (v_tran_preauth_flag != 'Y'))
      THEN
         V_DR_CR_FLAG := 'DR';
      ELSIF ((v_dr_cr_flag = 'CR') AND (v_tran_preauth_flag = 'Y'))
      then
         V_DR_CR_FLAG := 'DR';

      END IF;

      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance,
                         csl_trans_narrration, csl_inst_code,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_txn_code, csl_acct_no,
             --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         csl_ins_user, csl_ins_date, csl_merchant_name,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                         csl_merchant_city, csl_merchant_state,
                         csl_panno_last4digit,
                         csl_prod_code,csl_acct_type,csl_time_stamp  --Added by Pankaj S. for 10871
                        )
   --Added by Trivikram on 22-May-2012 to log last 4 Digit of the card number)
                 VALUES (v_hash_pan, v_debit_ledger_bal, --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                         nvl(p_tran_amt,0), --formatted by Pankaj S. for 10871
                         v_dr_cr_flag, p_tran_date,
                         DECODE (v_dr_cr_flag,
                                 'DR', v_debit_ledger_bal - p_tran_amt, --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                 'CR', v_debit_ledger_bal + p_tran_amt, --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                 'NA', v_debit_ledger_bal               --v_debit_acct_bal replaced by Pankaj S. with v_debit_ledger_bal for 10871
                                ),
                         'RVSL-' || p_narration, p_inst_code,
                         v_encr_pan, p_rrn, p_auth_id,
                         p_txn_date, p_tran_time, 'N',
                         p_delv_chnl, nvl(p_rev_txn_code,p_txn_code), p_card_acct_no,
                         1, SYSDATE, p_merc_name,
--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                         p_merc_city, p_merc_state,
                         (SUBSTR (p_card_no,
                                  LENGTH (p_card_no) - 3,
                                  LENGTH (p_card_no)
                                 )),
                         v_orgnl_prod_code,v_topup_accttype,v_timestamp  --Added by Pankaj S. for 10871
                        );
     --Added by Trivikam on 22-May-2012 to log Last 4 Digit of the card number
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
      END IF;
     --En create a entry in statement log

      --Sn Added for FWR-44
      BEGIN
         IF (p_delv_chnl ='07'AND p_txn_code IN ('10','11')) OR (p_delv_chnl = '10' AND p_txn_code IN ('19','20'))
             OR (p_delv_chnl = '13' AND p_txn_code IN ('04','11')) THEN
          IF (p_delv_chnl IN ('07','13') AND p_txn_code='11') OR (p_delv_chnl = '10' AND p_txn_code='20') THEN
           BEGIN
               SELECT customer_acct_no
                 INTO v_topup_acct_no
                 FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                WHERE rrn = p_orgnl_rrn
                  AND customer_card_no = v_hash_pan
                  AND instcode = p_inst_code
                  AND response_code = '00';
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct from TRANSACTIONLOG 2.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

          ELSE
            BEGIN
               SELECT topup_acct_no
                 INTO v_topup_acct_no
                 FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                WHERE rrn = p_orgnl_rrn
                  AND customer_card_no = v_hash_pan
                  AND instcode = p_inst_code
                  AND response_code = '00';
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct from TRANSACTIONLOG 2.1-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
          END IF;

            IF v_topup_acct_no IS NULL THEN
               v_resp_cde := '23';
               v_err_msg := 'Original Transaction not done properly 2.0';
               RAISE exp_rvsl_reject_record;
            END IF;

            BEGIN
               SELECT cam_acct_bal, cam_acct_no, cam_ledger_bal,cam_type_code
                 INTO v_credit_acct_bal, v_to_acct_no, v_credit_ledger_bal,v_topup_accttype
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =v_topup_acct_no;
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while selecting to_acct dtls 2.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            --Sn commented on 28 Jan 14 by Shweta for Mantis: 13541
            /*IF v_credit_acct_bal < p_tran_amt THEN
               v_resp_cde := '92';
               v_err_msg := 'Not Sufficient Funds in to_acct Number 2.0';
               RAISE exp_rvsl_reject_record;
            END IF;*/
            --En commented on 28 Jan 14 by Shweta for Mantis: 13541

            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal + p_tran_amt,
                      cam_ledger_bal = cam_ledger_bal + p_tran_amt
                WHERE cam_inst_code = p_inst_code
                  AND cam_acct_no =v_topup_acct_no;

               IF SQL%ROWCOUNT = 0 THEN
                  v_resp_cde := '21';
                  v_err_msg :='Problem while updating in account master for to_acct 2.0';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                RAISE;
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while updating account master for to_acct 2.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            IF v_dr_cr_flag <> 'NA' THEN
               BEGIN
			   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                  SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state,csl_prod_code
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate,v_topup_prodcode
                    FROM cms_statements_log
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = v_hash_pan
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N'
                     AND rownum=1;
ELSE
					SELECT csl_trans_narrration, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state,csl_prod_code
                    INTO v_txn_narration, v_txn_merchname,
                         v_txn_merchcity, v_txn_merchstate,v_topup_prodcode
                    FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
                   WHERE csl_business_date = p_orgnl_tran_date
                     AND csl_business_time = p_orgnl_tran_time
                     AND csl_rrn = p_orgnl_rrn
                     AND csl_delivery_channel = p_delv_chnl
                     AND csl_txn_code = p_txn_code
                     AND csl_pan_no = v_hash_pan
                     AND csl_inst_code = p_inst_code
                     AND txn_fee_flag = 'N'
                     AND rownum=1;
END IF;					 
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_txn_narration := NULL;
                  WHEN OTHERS THEN
                     v_txn_narration := NULL;
               END;

               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration, csl_inst_code,
                               csl_pan_no_encr, csl_rrn, csl_auth_id,
                               csl_business_date, csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code, csl_acct_no,
                               csl_ins_user, csl_ins_date, csl_merchant_name,
                               csl_merchant_city, csl_merchant_state,
                               csl_panno_last4digit,
                               csl_prod_code, csl_acct_type,
                               csl_time_stamp
                              )
                  VALUES      (v_hash_pan, v_credit_ledger_bal,NVL (p_tran_amt, 0),'CR', p_tran_date,
                               v_credit_ledger_bal + p_tran_amt,
                               'RVSL-' || v_txn_narration, p_inst_code,
                               v_encr_pan, p_rrn, p_auth_id,p_txn_date, p_tran_time, 'N',
                               p_delv_chnl, nvl(p_rev_txn_code,p_txn_code), v_topup_acct_no,
                               1, SYSDATE,p_merc_name,p_merc_city, p_merc_state,
                               (SUBSTR (p_card_no,LENGTH (p_card_no) - 3,LENGTH (p_card_no))),
                               v_topup_prodcode, v_topup_accttype,v_timestamp
                              );
               EXCEPTION
                  WHEN OTHERS THEN
                     v_resp_cde := '21';
                     v_err_msg := 'Error while inserting into CMS_STATEMENTS_LOG 2.0-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;

            BEGIN
               sp_daily_bin_bal (p_card_no,
                                 p_tran_date,
                                 p_tran_amt,
                                 'CR',
                                 p_inst_code,
                                 '',
                                 v_err_msg
                                );
                IF v_err_msg<>'OK' THEN
                  RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                RAISE;
               WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :='Error while calling SP_DAILY_BIN_BAL 2.0-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;
      END;
      --En Added for FWR-44
  /* ELSE
      --Sn insert a record into EODUPDATE_ACCT
      BEGIN
         sp_ins_eodupdate_acct (p_rrn,
                                p_terminal_id,
                                p_delv_chnl,
                                p_txn_code,
                                p_txn_mode,
                                p_tran_date,
                                p_card_acct_no,
                                v_rvsl_dracct_no,
                                p_tran_amt,
                                'D',
                                p_inst_code,
                                v_err_msg
                               );

         IF v_err_msg <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error from debit eod update acct ' || v_err_msg;
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while calling SP_INS_EODUPDATE_ACCT1 '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;*/--review changes for fwr-48
   --En  insert a record into EODUPDATE_ACCT
   END IF;

   --EN DEBIT THE CONCERN ACCOUNT
   p_resp_cde := '00';
   p_resp_msg := 'OK';
EXCEPTION
   WHEN exp_rvsl_reject_record
   THEN
      p_resp_cde := v_resp_cde;
      p_resp_msg := v_err_msg;
   WHEN OTHERS
   THEN
      p_resp_cde := '21';
      p_resp_msg := ' Problem from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error;