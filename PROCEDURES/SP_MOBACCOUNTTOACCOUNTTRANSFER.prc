create or replace PROCEDURE               VMSCMS.SP_MOBACCOUNTTOACCOUNTTRANSFER(
   p_inst_code          IN       NUMBER,
   p_pan_code           IN       VARCHAR2,
   p_msg                IN       VARCHAR2,
   p_from_acct_no       IN       VARCHAR2,
   p_to_acct_no         IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_txn_amt            IN       NUMBER,
   p_txn_mode           IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_customer_id        IN       VARCHAR2,
   P_MOB_NO             IN       VARCHAR2,    --Added regarding Fss-1144
   P_DEVICE_ID          IN       VARCHAR2,    --Added regarding Fss-1144
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2,
   p_availed_txn        OUT      NUMBER,
                               --added  for mob-26 by siva kumar on 16/04/2013
   p_available_txn      OUT      NUMBER,
                               --added  for mob-26 by siva kumar on 16/04/2013
   p_svgacct_closrflag  IN       VARCHAR2 DEFAULT 'N'
)
AS
/*************************************************
     * Created Date     :  19-JUL-2012
     * Created By       :  Deepa T
     * PURPOSE          :  Funds Transfer(Spending to Savings or Savings to Spending

     * Modified By     :  Saravanakumar
     * Modified Date   :  15-nov-12
     * Modified Reason :  Modified the order of statment
     * Reviewer        :  Dhiraj
     * Reviewed Date   :  18-Jan-2013
     * Build Number    :  CMS3.5.1_RI0023.1_B0003

     * Modified By     :  siva kumar m
     * Modified Date   :  16-Apr-13
     * Modified Reason :  Modified for MOB-26
     * Reviewer        :  Dhiarj
     * Reviewed Date   :  16-Apr-13
     * Build Number    :  RI0024.1_B0005

     * Modified by      : S Ramkumar
     * Modified Reason  : Mantis Id - 11357
     * Modified Date    : 25-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 26-Jun-13
     * Build Number     : RI0024.2_B0009

     * Modified by      :  Pankaj S.
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  23-Aug-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  23-Aug-2013
     * Build Number     :  RI0024.4_B0004
     * modified by       :  MageshKumar.S
     * modified Date     :  29-AUG-13
     * modified reason   :  FSS-1144
     * Reviewer          :  DHIRAJ
     * Reviewed Date     :  30-AUG-13
     * Build Number      : RI0024.4_B0006

     * Modified by      : A.Sivakaminathan
     * Modified Date    : 31-Dec-2015
     * Modified for     : MVHOST-1249	Enhancement	Closure of saving account on seventh transfer
     * Reviewer         : Pankaj Salunkhe
     * Build Number     : VMSGPRHOSTCSD_3.3

        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
 *************************************************/
   v_tran_date              DATE;
   v_cardstat               VARCHAR2 (5);
   v_cardexp                DATE;
   --v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_rrn_count              NUMBER;
   v_branch_code            VARCHAR2 (5);
   -- v_errmsg                 VARCHAR2 (500);
   v_count                  NUMBER;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_spd_acct_type          cms_acct_type.cat_type_code%TYPE;
   v_saving_acct_type       cms_acct_type.cat_type_code%TYPE;
   v_acct_type              cms_acct_type.cat_type_code%TYPE;
   v_acct_stat              cms_acct_mast.cam_stat_code%TYPE;
   v_svg_acct_stat          cms_acct_mast.cam_stat_code%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_txn_type               transactionlog.txn_type%TYPE;
   v_switch_spd_acct_type   cms_acct_type.cat_switch_type%TYPE   DEFAULT '11';
   v_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   v_switch_acct_stat       cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '8';
   v_func_code              cms_func_mast.cfm_func_code%TYPE;
   v_prodcode               cms_appl_pan.cap_prod_code%TYPE;
   v_cardtype               cms_appl_pan.cap_card_type%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_saving_acct_number     cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance           NUMBER;
   v_savings_acct_balance   NUMBER;
   v_cracct_no              cms_func_prod.cfp_cracct_no%TYPE;
   v_dracct_no              cms_func_prod.cfp_dracct_no%TYPE;
   v_gl_upd_flag            VARCHAR2 (1);
   --v_min_spd_amt            cms_dfg_param.cdp_param_key%TYPE;
   --v_max_svg_lmt            cms_dfg_param.cdp_param_key%TYPE;
  -- v_max_svg_trns_limt      cms_dfg_param.cdp_param_key%TYPE;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_curr_code              transactionlog.currencycode%TYPE;
   v_spd_acct_id            cms_appl_pan.cap_acct_id%TYPE;
   v_svg_acct_id            cms_appl_pan.cap_acct_id%TYPE;
   v_term_id                VARCHAR2 (20);
   v_mcc_code               VARCHAR2 (20);
   v_card_expry             VARCHAR2 (20);
   v_stan                   VARCHAR2 (20);
   v_capture_date           DATE;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
--   v_trans_desc             VARCHAR2 (50);
   v_narration              VARCHAR2 (300);
   v_ledger_balance         NUMBER;
   v_card_curr              VARCHAR2 (5);
   v_spd_acct_balance       NUMBER;
   v_spd_ledger_balance     NUMBER;
   exp_reject_record        EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_tran_amt               NUMBER;
   v_from_acct_type         VARCHAR2 (1);
   v_to_acct_type           VARCHAR2 (1);
   v_masking_char           VARCHAR2 (10)                DEFAULT '**********';
   v_first                  VARCHAR (10);
   v_encrypt                VARCHAR (30);
   v_last                   VARCHAR (10);
   v_length                 NUMBER (30);
   v_masked_pan             VARCHAR (40);
   v_saving_acct_dtl        VARCHAR (50);
   v_spending_acct_dtl      VARCHAR (50);
   v_spenacctbal            VARCHAR2 (20);
   v_spenacctledgbal        VARCHAR2 (20);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
                              --Added for transaction detail report on 210812
   v_availed_txn            NUMBER;
-- Added by B.Besky  on 04/01/2013 for CR->40 To give the availed transaction as the output.
   v_available_txn          NUMBER;
--  Added by B.Besky  on 04/01/2013 for CR->40 To give the available transaction as the output.
   v_respcode               VARCHAR2 (5);    --   Added for Mantis Id - 11357

   v_timestamp              timestamp(3); -- Added  on 29-08-2013 for  FSS-1144
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  on 29-08-2013 for  FSS-1144

   --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   --En Added by Pankaj S. during DFCCSD-70(Review) changes

   --Sn Getting DFG Parameters
--   CURSOR c
--   IS
--      SELECT cdp_param_key, cdp_param_value
--        FROM cms_dfg_param
--       WHERE cdp_inst_code = p_inst_code;
--En Getting DFG Parameters

--Main Begin Block Starts Here
BEGIN
   v_txn_type := '1';
   v_curr_code := p_curr_code;
   v_timestamp :=SYSTIMESTAMP; -- Added on 29-08-2013 for FSS-1144
   --SAVEPOINT v_auth_savepoint;

   --Sn Get the HashPan
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the HashPan

   --Sn Create encr pan
   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Create encr pan
    -- Start Generate HashKEY value for FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        p_resp_code := '21';
        p_resmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    --End Generate HashKEY value for FSS-1144

   --Sn Getting the Transaction Description
   BEGIN
      SELECT ctm_tran_desc,
             ctm_credit_debit_flag  --Added by Pankaj S. during DFCCSD-70(Review) changes
        INTO v_trans_desc,
             v_cr_dr_flag   --Added by Pankaj S. during DFCCSD-70(Review) changes
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
   --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
   WHEN NO_DATA_FOUND
      THEN
         --v_trans_desc := 'Transaction type' || p_txn_code;
         p_resp_code := '12';
         p_resmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         --v_trans_desc := 'Transaction type ' || p_txn_code;
         p_resp_code := '21';
         p_resmsg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
   END;

   --Sn check card details
   BEGIN
      SELECT cap_cust_code, cap_acct_no,          --Added by Besky on 09-nov-12
             cap_prod_code,cap_card_type,cap_card_stat   --Added by Pankaj S. during DFCCSD-70(Review) changes
        INTO v_cust_code, v_acct_number,          --Added by Besky on 09-nov-12
             v_prod_code,v_card_type,v_cardstat   --Added by Pankaj S. during DFCCSD-70(Review) changes
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';
         p_resmsg := 'Card number not found ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_resmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn select acct type(Savings)
   BEGIN
      SELECT cat_type_code
        INTO v_saving_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code
         AND cat_switch_type = v_switch_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_resmsg := 'Acct type not defined in master(Savings)';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
               'Error while selecting accttype(Savings) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select acct type(Savings)

   --Sn select acct type(Spending)
   BEGIN
      SELECT cat_type_code
        INTO v_spd_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code
         AND cat_switch_type = v_switch_spd_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_resmsg := 'Acct type not defined in master(Spending)';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
               'Error while selecting accttype(Spending) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select acct type(Spending)

   --Sn Check the From Account Number
   BEGIN
      SELECT cam_type_code
        INTO v_from_acct_type
        FROM cms_acct_mast, cms_cust_acct, cms_cust_mast
       WHERE cam_acct_id = cca_acct_id
         AND cca_cust_code = ccm_cust_code
         AND ccm_cust_id = p_customer_id
         AND cam_acct_no = p_from_acct_no
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '134';
         p_resmsg := 'Invalid From Account Number';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
               'Problem while selecting From Account Number Detail'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Check the From Account Number
     --Sn Check the To Account Number
   BEGIN
      SELECT cam_type_code
        INTO v_to_acct_type
        FROM cms_acct_mast, cms_cust_acct, cms_cust_mast
       WHERE cam_acct_id = cca_acct_id
         AND cca_cust_code = ccm_cust_code
         AND ccm_cust_id = p_customer_id
         AND cam_acct_no = p_to_acct_no
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '135';
         p_resmsg := 'Invalid To Account Number';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_resmsg :=
               'Problem while selecting To Account Number Detail'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Check the To Account Number
   IF (   (    v_from_acct_type = v_spd_acct_type
           AND v_to_acct_type = v_saving_acct_type
          )
       OR (    v_from_acct_type = v_saving_acct_type
           AND v_to_acct_type = v_spd_acct_type
          )
      )
   THEN
      IF p_txn_code = '04'
      THEN
         IF v_from_acct_type = v_saving_acct_type
         THEN
            p_resp_code := '134';
            p_resmsg := 'Invalid From Account Number';
            RAISE exp_reject_record;
         END IF;

         IF v_to_acct_type = v_spd_acct_type
         THEN
            p_resp_code := '135';
            p_resmsg := 'Invalid To Account Number';
            RAISE exp_reject_record;
         END IF;

         BEGIN
            sp_spendingtosavingstransfer
                         (p_inst_code,
                          p_pan_code,
                          p_msg,
                          p_from_acct_no,
                          p_to_acct_no,
                          p_delivery_channel,
                          p_txn_code,
                          p_rrn,
                          p_txn_amt,
                          p_txn_mode,
                          p_bank_code,
                          p_curr_code,
                          p_rvsl_code,
                          p_tran_date,
                          p_tran_time,
                          NULL,
                          NULL,
                          NULL,
                          p_resp_code,
                          p_resmsg,
                          v_spenacctbal, -- added by siva  kumar on 60/08/2012
                          v_spenacctledgbal
                         );              -- added by siva  kumar on 60/08/2012
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resmsg :=
                     'Error from the procedure sp_spendingtosavingstransfer'
                  || p_resmsg;
               RAISE exp_reject_record;
         END;
      ELSIF p_txn_code = '11'
      THEN
         IF v_from_acct_type = v_spd_acct_type
         THEN
            p_resp_code := '134';
            p_resmsg := 'Invalid From Account Number';
            RAISE exp_reject_record;
         END IF;

         IF v_to_acct_type = v_saving_acct_type
         THEN
            p_resp_code := '135';
            p_resmsg := 'Invalid To Account Number';
            RAISE exp_reject_record;
         END IF;

         BEGIN
            sp_savingstospendingtransfer
               (p_inst_code,
                p_pan_code,
                p_msg,
                p_to_acct_no,
                p_from_acct_no,
                p_delivery_channel,
                p_txn_code,
                p_rrn,
                p_txn_amt,
                p_txn_mode,
                p_bank_code,
                p_curr_code,
                p_rvsl_code,
                p_tran_date,
                p_tran_time,
                NULL,
                NULL,
                NULL,
                p_resp_code,
                p_resmsg,
                v_spenacctbal,           -- added by siva  kumar on 60/08/2012
                v_spenacctledgbal,
                v_availed_txn,
-- Added by B.Besky  on 04/01/2013 for CR->40 To give the availed transaction as the output.
                v_available_txn,
				p_svgacct_closrflag
               );
-- Added by B.Besky  on 04/01/2013 for CR->40 To give the availed transaction as the output
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resmsg :=
                     'Error from the procedure sp_savingstospendingtransfer'
                  || p_resmsg;
               RAISE exp_reject_record;
         END;

         p_availed_txn := v_availed_txn;
                               --added  for mob-26 by siva kumar on 16/04/2013
         p_available_txn := v_available_txn;
                               --added  for mob-26 by siva kumar on 16/04/2013
      END IF;
   ELSE
      p_resp_code := '133';
      p_resmsg := 'Both Accounts Cannot be Spending/Savings';
      RAISE exp_reject_record;
   END IF;
  --Sn Get responce code fomr master
              --Sn Updtated cms_transaction_log_dtl For regarding FSS-1144
            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE VMSCMS.CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  ELSE
			  UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  END IF;

             IF SQL%ROWCOUNT = 0 THEN
                p_resmsg  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                p_resmsg  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;
    --End Updated cms_transaction_log_dtl  for regarding  FSS-1144
   IF p_resp_code = '00' and p_resmsg <> 'C'
   THEN
      IF LENGTH (p_pan_code) > 10
      THEN
         v_first := SUBSTR (p_pan_code, 1, 6);
         v_last := SUBSTR (p_pan_code, -4, 4);
         v_length :=
                    (LENGTH (p_pan_code) - LENGTH (v_first) - LENGTH (v_last)
                    );
         v_encrypt :=
            TRANSLATE (SUBSTR (p_pan_code, 7, v_length),
                       '0123456789',
                       v_masking_char
                      );
         v_masked_pan := v_first || v_encrypt || v_last;
      ELSE
         p_resp_code := '21';
         p_resmsg := 'Invalid PAN Length';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         SELECT    0
                || '~'
                || cam_acct_no
                || '~'
                || TRIM
                      (TO_CHAR (cam_acct_bal, '99999999999990.00'))
                                       --Changed by Saravanakumar on 15-nov-12
           INTO v_saving_acct_dtl
           FROM cms_acct_mast
          WHERE cam_acct_id IN (
                   SELECT cca_acct_id
                     FROM cms_cust_acct
                    WHERE cca_cust_code = v_cust_code
                      AND cca_inst_code = p_inst_code)
            AND cam_type_code = v_saving_acct_type
            AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_saving_acct_dtl := NULL;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_resmsg := 'Error while selecting Savings Account Details';
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT    1
                || '~'
                || cam_acct_no
                || '~'
                || TRIM
                      (TO_CHAR (cam_acct_bal, '99999999999990.00'))
                                     ----Changed by Saravanakumar on 15-nov-12
           INTO v_spending_acct_dtl
           FROM cms_acct_mast
          --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
          WHERE cam_acct_no=v_acct_number
             --cam_acct_id IN (
             --      SELECT cca_acct_id
             --        FROM cms_cust_acct
             --       WHERE cca_cust_code = v_cust_code
             --         AND cca_inst_code = p_inst_code)
            --AND cam_type_code = v_spd_acct_type
            --En Modified by Pankaj S. during DFCCSD-70(Review) changes
            AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_spending_acct_dtl := NULL;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_resmsg := 'Error while selecting Spending Account Details';
            RAISE exp_reject_record;
      END;

      IF v_saving_acct_dtl IS NOT NULL
      THEN
         p_resmsg := v_masked_pan || '~' || v_saving_acct_dtl;
      END IF;

      /* IF v_spending_acct_dtl IS NOT NULL THEN


       V_ERRMSG:=V_ERRMSG || '||' || v_masked_pan||'~'||v_spending_acct_dtl;

       END IF;*/

      --Added by Deepa on 30-July-2012
      IF v_spending_acct_dtl IS NOT NULL
      THEN
         IF v_saving_acct_dtl IS NOT NULL
         THEN
            p_resmsg :=
               p_resmsg || '||' || v_masked_pan || '~' || v_spending_acct_dtl;
         ELSE
            p_resmsg := v_masked_pan || '~' || v_spending_acct_dtl;
         END IF;
      END IF;

      IF v_saving_acct_dtl IS NULL AND v_spending_acct_dtl IS NULL
      THEN
         p_resmsg := 'OK';
      END IF;
   END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK;                                       -- TO v_auth_savepoint;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           --INTO p_resp_code
           --Modified to set response code      --      Mantis Id - 11357       25th, June 2013
           INTO v_respcode
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;
      --En Get responce code fomr master

      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
       IF v_cr_dr_flag IS NULL THEN
        BEGIN
           SELECT ctm_tran_desc, ctm_credit_debit_flag
             INTO v_trans_desc, v_cr_dr_flag
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

      IF v_prod_code IS NULL THEN
        BEGIN
              SELECT cap_acct_no,cap_prod_code,cap_card_type,cap_card_stat
                INTO v_acct_number,v_prod_code,v_card_type,v_cardstat
                FROM cms_appl_pan
               WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
        EXCEPTION
         WHEN OTHERS THEN
          NULL;
        END;
      END IF;
      --En Added by Pankaj S. for DFCCSD-70(Review) changes

      --Sn Added by Pankaj S. for DFCCSD-70 changes
       IF p_txn_code = '04' THEN
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_ledger_balance,v_saving_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_to_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_ledger_balance:=0;
       END;
       ELSIF p_txn_code = '11' THEN
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_ledger_balance,v_saving_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_from_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_ledger_balance:=0;
       END;
       END IF;

       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_spd_acct_balance,v_spd_ledger_balance,v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=v_acct_number;
       EXCEPTION
          WHEN OTHERS THEN
          v_spd_acct_balance:=0;
          v_spd_ledger_balance:=0;
       END;
       --En Added by Pankaj S. for DFCCSD-70 changes

      --Sn Inserting data in transactionlog
      BEGIN
         --Sn Insert modified by Pankaj S. for DFCCSD-70 changes
         IF p_txn_code = '04' THEN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, --customer_acct_no,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      error_msg, ipaddress, add_ins_date,--Added by ramesh.a on 11/04/2012
                      add_ins_user,--Added by ramesh.a on 11/04/2012
                      cardstatus, trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      customer_acct_no, acct_type,
                      acct_balance, ledger_balance, topup_card_no,
                      topup_card_no_encr, topup_acct_no, topup_acct_type,
                      topup_acct_balance, topup_ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      productid,categoryid,cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', v_respcode,--Modified to set response code      --      Mantis Id - 11357       25th, June 2013
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, --v_acct_number,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      p_resmsg, '', SYSDATE,--Added by ramesh.a on 11/04/2012
                      1,--Added by ramesh.a on 11/04/2012
                      v_cardstat, v_trans_desc, p_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      p_from_acct_no, v_acct_type,
                      v_spd_acct_balance, v_spd_ledger_balance, v_hash_pan,
                      v_encr_pan_from, p_to_acct_no, v_saving_acct_type,
                      v_savings_acct_balance, v_ledger_balance,v_timestamp,-- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      v_prod_code,v_card_type,v_cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     );
         ELSIF  p_txn_code = '11' THEN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, --customer_acct_no,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      error_msg, ipaddress, add_ins_date,--Added by ramesh.a on 11/04/2012
                      add_ins_user,--Added by ramesh.a on 11/04/2012
                      cardstatus, trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      customer_acct_no, acct_type,
                      acct_balance, ledger_balance, topup_card_no,
                      topup_card_no_encr, topup_acct_no, topup_acct_type,
                      topup_acct_balance, topup_ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      productid,categoryid,cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', v_respcode,--Modified to set response code      --      Mantis Id - 11357       25th, June 2013
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, --v_acct_number,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      p_resmsg, '', SYSDATE,--Added by ramesh.a on 11/04/2012
                      1,--Added by ramesh.a on 11/04/2012
                      v_cardstat, v_trans_desc, p_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      p_from_acct_no, v_saving_acct_type,
                      v_savings_acct_balance, v_ledger_balance, v_hash_pan,
                      v_encr_pan_from, p_to_acct_no, v_acct_type,
                      v_spd_acct_balance, v_spd_ledger_balance,v_timestamp, -- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      v_prod_code,v_card_type,v_cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     );
         END IF;
         --En Insert modified by Pankaj S. for DFCCSD-70 changes
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            p_resmsg :=
                  'Exception while inserting to transaction log '|| SUBSTR (SQLERRM, 1, 300);--|| SQLCODE || '---' || SQLERRM; --Modified by Pankaj S. during DFCCSD-70(Review) changes
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;
      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, p_curr_code, NULL,
                      NULL, NULL,
                      NULL, 'E', p_resmsg,
                      p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan_from, p_msg,
                                              -- Added by Ramesh.A on 27/03/2012
                      '',
                      v_acct_number, '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID  --Added  on 29-08-2013 for Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;

        p_resp_code := v_respcode;      -- Added to assign Response code in OUT parameter   --Mantis Id - 11357     --  25th, June 2013

   WHEN OTHERS
   THEN
      p_resp_code := '21';
      p_resmsg := 'Main Exception ' || SUBSTR (SQLERRM, 1, 300);--|| SQLCODE || '---' || SQLERRM; --Modified by Pankaj S. during DFCCSD-70(Review) changes
      ROLLBACK;                                       -- TO v_auth_savepoint;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           --INTO p_resp_code
           --Modified to set response code      --      Mantis Id - 11357       25th, June 2013
           INTO v_respcode
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;
      --En Get responce code fomr master

      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
      IF v_cr_dr_flag IS NULL THEN
        BEGIN
           SELECT ctm_tran_desc, ctm_credit_debit_flag
             INTO v_trans_desc, v_cr_dr_flag
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

      IF v_prod_code IS NULL THEN
        BEGIN
              SELECT cap_acct_no,cap_prod_code,cap_card_type,cap_card_stat
                INTO v_acct_number,v_prod_code,v_card_type,v_cardstat
                FROM cms_appl_pan
               WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
        EXCEPTION
         WHEN OTHERS THEN
          NULL;
        END;
      END IF;
      --En Added by Pankaj S. for DFCCSD-70(Review) changes

      --Sn Added by Pankaj S. for DFCCSD-70 changes
       IF p_txn_code = '04' THEN
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_ledger_balance,v_saving_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_to_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_ledger_balance:=0;
       END;
       ELSIF p_txn_code = '11' THEN
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_ledger_balance,v_saving_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_from_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_ledger_balance:=0;
       END;
       END IF;

       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_spd_acct_balance,v_spd_ledger_balance,v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=v_acct_number;
       EXCEPTION
          WHEN OTHERS THEN
          v_spd_acct_balance:=0;
          v_spd_ledger_balance:=0;
       END;
       --En Added by Pankaj S. for DFCCSD-70 changes

      --Sn Inserting data in transactionlog
      BEGIN
         --Sn Insert modified by Pankaj S. for DFCCSD-70 changes
         IF p_txn_code = '04' THEN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, --customer_acct_no,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      error_msg, ipaddress, add_ins_date,--Added by ramesh.a on 11/04/2012
                      add_ins_user,--Added by ramesh.a on 11/04/2012
                      cardstatus, trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      customer_acct_no, acct_type,
                      acct_balance, ledger_balance, topup_card_no,
                      topup_card_no_encr, topup_acct_no, topup_acct_type,
                      topup_acct_balance, topup_ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      productid,categoryid,cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', v_respcode,--Modified to set response code      --      Mantis Id - 11357       25th, June 2013
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, --v_acct_number,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      p_resmsg, '', SYSDATE,--Added by ramesh.a on 11/04/2012
                      1,--Added by ramesh.a on 11/04/2012
                      v_cardstat, v_trans_desc, p_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      p_from_acct_no, v_acct_type,
                      v_spd_acct_balance, v_spd_ledger_balance, v_hash_pan,
                      v_encr_pan_from, p_to_acct_no, v_saving_acct_type,
                      v_savings_acct_balance, v_ledger_balance,v_timestamp, --modified by MageshKUmar S. for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      v_prod_code,v_card_type,v_cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     );
         ELSIF  p_txn_code = '11' THEN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, --customer_acct_no,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      error_msg, ipaddress, add_ins_date,--Added by ramesh.a on 11/04/2012
                      add_ins_user,--Added by ramesh.a on 11/04/2012
                      cardstatus, trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      customer_acct_no, acct_type,
                      acct_balance, ledger_balance, topup_card_no,
                      topup_card_no_encr, topup_acct_no, topup_acct_type,
                      topup_acct_balance, topup_ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      productid,categoryid,cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', v_respcode,--Modified to set response code      --      Mantis Id - 11357       25th, June 2013
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, --v_acct_number,  --commented here n used doen by Pankaj s for DFCCSD-70 changes
                      p_resmsg, '', SYSDATE,--Added by ramesh.a on 11/04/2012
                      1,--Added by ramesh.a on 11/04/2012
                      v_cardstat, v_trans_desc, p_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      p_from_acct_no, v_saving_acct_type,
                      v_savings_acct_balance, v_ledger_balance, v_hash_pan,
                      v_encr_pan_from, p_to_acct_no, v_acct_type,
                      v_spd_acct_balance, v_spd_ledger_balance,v_timestamp, --modified by MageshKUmar S. for FSS-1144
                      --En Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Added by Pankaj S. for DFCCSD-70(Review) changes
                      v_prod_code,v_card_type,v_cr_dr_flag
                      --En Added by Pankaj S. for DFCCSD-70(Review) changes
                     );
         END IF;
         --En Insert modified by Pankaj S. for DFCCSD-70 changes
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            p_resmsg :=
                  'Exception while inserting to transaction log '|| SUBSTR (SQLERRM, 1, 300);--|| SQLCODE || '---' || SQLERRM; --Modified by Pankaj S. during DFCCSD-70(Review) changes
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, p_curr_code, NULL,
                      NULL, NULL,
                      NULL, 'E', p_resmsg,
                      p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan_from, p_msg,
                                              -- Added by Ramesh.A on 27/03/2012
                      '',
                      v_acct_number, '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID  --Added  on 29-08-2013 for Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;

        p_resp_code := v_respcode;      -- Added to assign Response code in OUT parameter   --Mantis Id - 11357     --  25th, June 2013

--En Inserting data in transactionlog dtl
END;
/
SHOW ERROR;