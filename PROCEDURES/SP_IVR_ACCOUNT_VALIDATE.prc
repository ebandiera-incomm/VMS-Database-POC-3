create or replace
PROCEDURE        VMSCMS.SP_IVR_ACCOUNT_VALIDATE (
   p_instcode           IN       NUMBER,
   p_cardnum            IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2, 
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_acct_bal           OUT      VARCHAR2, 
   p_card_status        OUT      VARCHAR2,
   p_pin_offset         OUT      VARCHAR2,
   p_errmsg             OUT      VARCHAR2,
   p_card_status_mesg   OUT      VARCHAR2,
   p_saving_acct_info   OUT      NUMBER,
   p_savingss_acct_no   OUT      VARCHAR2,
   p_feeamount          OUT      VARCHAR2,
   p_spending_acct_no   OUT      VARCHAR2,     --Added on 27.02.2013 for CR-046
   p_routingnumber      OUT      VARCHAR2,      --ADDED ON 17.09.2013 FOR JH-FR-15
   P_ADDRESS_VERIFIED_FLAG OUT   VARCHAR2, --Added on 18-02-2014: MVCSD-4121 & FWR
   P_EXPIRY_DAYS       OUT       VARCHAR2,--Added on 18-02-2014: MVCSD-4121 & FWR
   P_SHIPPED_DATE      OUT       VARCHAR2,--Added on 18-02-2014: MVCSD-4121 & FWR
   P_PROXY_NUM         OUT       VARCHAR2 --Added for FSS-3489 of 3.0.3 release

)
AS
   -- Added by siva kumar for Adding Card Status Description

   /*************************************************
       * Created Date     : 10-Dec-2011
       * Created By       : Deepa
       * PURPOSE          : For validate account
       * Modified By      : B.Besky
       * Modified Date    : 14/02/13
       * Modified Reason  : Modified  for CR - 40 in release 23.1.1
       * Reviewer         : Saravanakumar
       * Reviewed Date    : 14/02/13
       * Modified By      : Sachin P.
       * Modified Date    : 20/02/13
       * Modified Reason  : Modified  for Mantis ID 10299 Account balance NULL
       * Modified By      : Sachin P.
       * Modified Date    : 27/02/13
       * Modified Reason  : Modified for CR-046 (Spending account as out parameter)
       * Reviewer         :
       * Reviewed Date    :
       * Release Number   : CMS3.5.1_RI0023.1.1_B0006

       * Modified By      : Mageshkumar
       * Modified Date    : 19-sep-2013
       * Modified Reason  : Modified FOR JH-FR-15
       * Reviewer         : Dhiraj
       * Reviewed Date    : 19-sep-2013
       * Release Number   : RI0024.5_B0001

       * Modified By      : Sagar More
       * Modified Date    : 26-Sep-2013
       * Modified For     : LYFEHOST-63
       * Modified Reason  : To fetch saving acct parameter based on product code
       * Reviewer         : Dhiraj
       * Reviewed Date    : 28-Sep-2013
       * Build Number     : RI0024.5_B0001


       * Modified By      : Sagar More
       * Modified Date    : 16-OCT-2013
       * Modified For     : review observation changes for LYFEHOST-63
       * Reviewer         : Dhiraj
       * Reviewed Date    : 16-OCT-2013
       * Build Number     : RI0024.6_B0001

       * Modified Date    : 16-Dec-2013
       * Modified By      : Sagar More
       * Modified for     : Defect ID 13160
       * Modified reason  : To log below details in transactinlog if applicable
                            Acct_type,timestamp,dr_cr_flag,product code,cardtype,error_msg
       * Reviewer         : Dhiraj
       * Reviewed Date    : 16-Dec-2013
       * Release Number   : RI0024.7_B0001

       * Modified By      : DINESH B.
       * Modified Date    : 18-Feb-2014
       * Modified Reason  : MVCSD-4121 and FWR-43 :Fetching address verified flag and expiry days and shipped date for the customer.
       * Reviewer         : Dhiraj
       * Reviewed Date    : 06/Mar/2013
       * Build Number     : RI0027.2_B0002

        * Modified by       : Ramesh A
        * Modified Date     : 02-Mar-15
        * Modified For      : DFCTNM-26
        * Reviewer          : Saravanakumar
	    * Reviewed Date     : 06/03/15
        * Build Number      : 3.0_B0001

        * Modified by       : MageshKumar S
        * Modified Date     : 21-May-15
        * Modified For      : FSS-3489
        * Reviewer          : Pankaj
        * Reviewed Date     :
        * Build Number      : VMSGPRHOSTCSD_3.0.3_B0001

        * Modified by       : A.Sivakaminathan
        * Modified Date     : 29-Mar-16
        * Modified For      : Partner_id logged null
        * Reviewer          : Saravanakumar
        * Build Number      : VMSGPRHOSTCSD_4.0
		
			 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
	 
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

     * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

   *************************************************/
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_currcode               VARCHAR2 (3);
   v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_authmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_inil_authid            transactionlog.auth_id%TYPE;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count              NUMBER;
   v_delchannel_code        VARCHAR2 (2);
   v_base_curr              cms_bin_param.cbp_param_value%TYPE;
   v_tran_date              DATE;
   v_tran_amt               NUMBER;
   v_business_date          DATE;
   v_business_time          VARCHAR2 (5);
   v_cutoff_time            VARCHAR2 (5);
   v_cust_code              cms_cust_mast.ccm_cust_code%TYPE;
   v_tran_count             NUMBER;
   v_tran_count_reversal    NUMBER;
   v_cap_prod_catg          VARCHAR2 (100);
   -- Commented by UBAIDUR RAHMAN on 25-Sep-2017
--   v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
--   v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     DATE;
   v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal             cms_acct_mast.cam_acct_bal%TYPE;
   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype           cms_prod_cattype.cpc_card_type%TYPE;
   v_expry_date             DATE;
   v_atmonline_limit        cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit        cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_toacct_bal             cms_acct_mast.cam_acct_bal%TYPE;
  -- v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE; -- commented not used variable for 3.0.3 release
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_count                  NUMBER;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   -- Added by siva kumar on july 11 2012 Adding Description for Card Status .
   v_status_count           NUMBER;
   v_txncode                transactionlog.txn_code%TYPE;
   v_cardstatus             VARCHAR2 (50);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   --Added for transaction detail report on 210812
   v_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   v_acct_type              cms_acct_type.cat_type_code%TYPE;
   v_last_updatedate        cms_acct_mast.cam_lupd_date%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_acct_status            cms_acct_mast.cam_stat_code%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_switch_acct_stats      cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '2';
   --Added for CR - 40 in release 23.1.1
   v_status_code            cms_acct_mast.cam_stat_code%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_reopen_period          cms_dfg_param.cdp_param_value%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_fee_desc               cms_fee_mast.cfm_fee_desc%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_feeflag                VARCHAR2 (1);
   --Added for CR - 40 in release 23.1.1
   v_avail_bal              cms_acct_mast.cam_acct_bal%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_led_bal                cms_acct_mast.cam_ledger_bal%TYPE;
   --Added for CR - 40 in release 23.1.1
   v_clawback_flag          cms_fee_mast.cfm_clawback_flag%TYPE;
--Added for CR - 40 in release 23.1.1

   v_timestamp timestamp(3);    --Added for 13160
   V_RENEWAL_DATE      date;--Added on 18-02-2014: MVCSD-4121 & FWR
   V_EXPIRY_DATE         cms_appl_pan.cap_expry_date%type; --Added on 18-02-2014: MVCSD-4121 & FWR
   v_profile_code        cms_prod_cattype.cpc_profile_code%TYPE;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
   p_errmsg := 'OK';
   v_errmsg := 'OK';
   v_respcode := '1';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting into hash pan ' || SUBSTR (SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
                    'Error while converting into encrypt pan ' || SUBSTR (SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_main_reject_record;
   END;

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type,
             ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type,
             v_trans_desc      --Added for transaction detail report on 210812
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '12';                         --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';                         --Ineligible Transaction
         v_respcode := 'Error while selecting transaction details '||substr(sqlerrm,1,100); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_main_reject_record;
   END;

   --En find debit and credit flag
   BEGIN
      v_tran_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Transaction Date Check

   --Sn Transaction Time Check
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Transaction Time Check
   v_business_time := TO_CHAR (v_tran_date, 'HH24:MI');

   IF v_business_time > v_cutoff_time
   THEN
      v_business_date := TRUNC (v_tran_date) + 1;
   ELSE
      v_business_date := TRUNC (v_tran_date);
   END IF;


 BEGIN

     SELECT cap_prod_code, cap_card_type,
             TO_CHAR (cap_expry_date, 'DD-MON-YY'), cap_card_stat,
             cap_atm_online_limit, cap_pos_online_limit, cap_prod_catg,
             cap_cafgen_flag, cap_appl_code, cap_firsttime_topup,
             cap_mbr_numb, cap_cust_code, cap_proxy_number, cap_acct_no,
             cap_card_stat, cap_pin_off, cap_expry_date
        INTO v_prod_code, v_prod_cattype,
             v_expry_date, v_cap_card_stat,
             v_atmonline_limit, v_atmonline_limit, v_cap_prod_catg,
             v_cap_cafgen_flag, v_appl_code, v_firsttime_topup,
             v_mbrnumb, v_cust_code, P_PROXY_NUM, --v_proxunumber,--Modified for FSS-3489 of 3.0.3 release
               --v_acct_number, --Commented and Added on 27.02.2013 for CR-046
                                                   p_spending_acct_no,
             p_card_status,
--Modified by Sivapragasam on Feb 20 2012 for selecting card status for Changes in Account Validation
                           p_pin_offset, V_EXPIRY_DATE  --Added on 18-02-2014: MVCSD-4121 & FWR
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
       
      EXCEPTION 
       WHEN NO_DATA_FOUND
      THEN
       v_errmsg := 'NO CARD INFORMATION FOUND IN CARD MASTER';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
        v_errmsg :=
            'Problem while selecting CARD INFORMATION' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
END;

    BEGIN
      SELECT NVL (CPC_ROUT_NUM, CPC_INSTITUTION_ID ||'-'|| CPC_TRANSIT_NUMBER),cpc_profile_code --Modified for DFCTNM-26
        INTO p_routingnumber,v_profile_code
        FROM CMS_PROD_CATTYPE
       WHERE CPC_INST_CODE = p_instcode
		 AND CPC_CARD_TYPE= v_prod_cattype
         AND CPC_PROD_CODE= v_prod_code;
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';                         --Ineligible Transaction
         v_errmsg := 'Routing number not found ' || p_routingnumber;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Problem while selecting Routing Number' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;

   END;




   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'IVR' AND cdm_inst_code = p_instcode
       and   cdm_channel_code = p_delivery_channel;                     --Added as per review observation for LYFEHOST-63

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN
--            SELECT cip_param_value
--              INTO v_base_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

               SELECT TRIM(cbp_param_value)
	        INTO v_base_curr
	        FROM cms_bin_param WHERE cbp_param_name = 'Currency'
	        AND cbp_inst_code= p_instcode 
	        AND cbp_profile_code =v_profile_code;

            IF v_base_curr IS NULL
            THEN
               v_respcode := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;


         EXCEPTION WHEN exp_main_reject_record        -- Handled as per review observation for LYFEHOST-63
         THEN
             RAISE exp_main_reject_record;

            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               v_errmsg :=
                          'Base currency is not defined for the BIN profile ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting base currency for BIN  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := '840';
      END IF;

   EXCEPTION WHEN exp_main_reject_record        -- handled as per review observation for LYFEHOST-63
   THEN
       RAISE exp_main_reject_record;

      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of IVR  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
   BEGIN

--Added for VMS-5733/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
ELSE
    SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
   END IF;

      --Added by ramkumar.Mk on 25 march 2012
      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || ' on ' || p_trandate;
         RAISE exp_main_reject_record;
      END IF;

   EXCEPTION when exp_main_reject_record                        --Exception added as per review observation for LYFEHOST-63
   then
       raise exp_main_reject_record;

   WHEN OTHERS
   THEN
         v_errmsg := 'Error while duplicate rrn check  '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Duplicate RRN Check


   --Sn find card detail
   BEGIN
       --ST Added by siva kumar on july 11 2012 Adding Description for Card Status .
      IF p_card_status = '0'
      THEN

         BEGIN

             SELECT COUNT (*)
               INTO v_status_count
               FROM VMSCMS.TRANSACTIONLOG_VW --Added for VMS-5735/FSP-991
              WHERE response_code = '00'
                AND (   (txn_code = '69' AND delivery_channel = '04')
                     OR (txn_code = '05' AND delivery_channel IN ('10', '07'))
                    )
                AND customer_card_no = v_hash_pan
                AND instcode = p_instcode;


         EXCEPTION WHEN OTHERS              -- Added as per review observation for LYFEHOST-63
         THEN
             v_respcode := '12';
             v_errmsg :=
                'Problem while selecting status count'|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
         END;


         IF v_status_count = 0
         THEN
            p_card_status_mesg := 'INACTIVE';
         ELSE

             BEGIN

                SELECT txn_code
                  INTO v_txncode
                  FROM (SELECT   txn_code
                            FROM VMSCMS.TRANSACTIONLOG_VW --Added for VMS-5735/FSP-991
                           WHERE response_code = '00'
                             AND (   (txn_code = '69' AND delivery_channel = '04'
                                     )
                                  OR (    txn_code = '05'
                                      AND delivery_channel IN ('10', '07')
                                     )
                                 )
                             AND customer_card_no = v_hash_pan
                             AND instcode = p_instcode
                        ORDER BY TO_DATE (   SUBSTR (TRIM (business_date), 1, 8)
                                          || ' '
                                          || SUBSTR (TRIM (business_time), 1, 10),
                                          'yyyymmdd hh24:mi:ss'
                                         ) DESC)
                 WHERE ROWNUM = 1;

             EXCEPTION                          -- Added as per review observation for LYFEHOST-63
                  WHEN NO_DATA_FOUND
                  THEN
                 v_respcode := '16';
                 v_errmsg := 'Tran code not found ';
                 RAISE exp_main_reject_record;
             WHEN OTHERS
             THEN
                 v_respcode := '12';
                 v_errmsg :=
                    'Problem while selecting tran code' || SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_main_reject_record;
             END;

            IF v_txncode = '69'
            THEN
               p_card_status_mesg := 'INACTIVE';
            ELSE
               IF v_txncode = '05'
               THEN
                  p_card_status_mesg := 'BLOCKED';
               END IF;
            END IF;
         END IF;
      ELSE

          BEGIN

             SELECT ccs_stat_desc
               INTO v_cardstatus
               FROM cms_card_stat
              WHERE ccs_stat_code = p_card_status AND ccs_inst_code = p_instcode;

              p_card_status_mesg := v_cardstatus;

          EXCEPTION                                 -- Added as per review observation for LYFEHOST-63
              WHEN NO_DATA_FOUND
              THEN
             v_respcode := '16';
             v_errmsg := 'Card status not found ' || p_card_status;
             RAISE exp_main_reject_record;
          WHEN OTHERS
          THEN
             v_respcode := '12';
             v_errmsg :=
                'Problem while selecting card status' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
          END;


      END IF;
   --EN  Added by siva kumar for Adding Card Status Description

   EXCEPTION WHEN exp_main_reject_record            -- Added as per review observation for LYFEHOST-63
   THEN
       RAISE exp_main_reject_record;

   WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';                         --Ineligible Transaction
         v_errmsg := 'Card number not found ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En find card detail


   --Added By Siva Arcot for JH-FR-15 on 17-09-2013
   --SN find Routing number

   --En Routing Number Find
   /*
   --card status
   BEGIN
     IF V_CAP_CARD_STAT IN (2, 3) THEN

      V_RESPCODE := '41';
      V_ERRMSG   := ' Lost Card ';
      RAISE EXP_MAIN_REJECT_RECORD;

     ELSIF V_CAP_CARD_STAT = 4 THEN

      V_RESPCODE := '14';
      V_ERRMSG   := ' Restricted Card ';
      RAISE EXP_MAIN_REJECT_RECORD;

     ELSIF V_CAP_CARD_STAT = 9 THEN

      V_RESPCODE := '46';
      V_ERRMSG   := ' Closed Card ';
      RAISE EXP_MAIN_REJECT_RECORD;

     END IF;
   END;
   --card status
   */
  -- IF v_cap_prod_catg = 'P'
  -- THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (p_instcode,
                                    '0200',
                                    p_rrn,
                                    p_delivery_channel,
                                    '0',
                                    p_txn_code,
                                    0,
                                    p_trandate,
                                    p_trantime,
                                    p_cardnum,
                                    NULL,
                                    0,
                                    NULL,
                                    NULL,
                                    NULL,
                                    v_currcode,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    '0',                             -- P_stan
                                    '000',                          --Ins User
                                    '00',                           --INS Date
                                    0,
                                    v_inil_authid,
                                    v_respcode,
                                    v_respmsg,
                                    v_capture_date
                                   );

         IF v_respcode <> '00' AND v_respmsg <> 'OK'
         THEN
            v_errmsg := v_respmsg;
            RAISE exp_auth_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   --En call to authorize txn
   --END IF;

    --Added on 18-02-2014: MVCSD-4121 & FWR Starts
  BEGIN
           SELECT  CCM_ADDRVERIFY_FLAG
           INTO P_ADDRESS_VERIFIED_FLAG
           FROM CMS_CUST_MAST
           WHERE  ccm_cust_code =v_cust_code
           AND CCM_INST_CODE=p_instcode;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG    := 'No data found while selecting customer details ';
              RAISE exp_main_reject_record;
            WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg  := 'while selecting customer details'|| SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
         END;

           --Added on 18-02-2014: MVCSD-4121 & FWR ends

     --Added on 18-02-2014: MVCSD-4121 & FWR Starts


    IF P_ADDRESS_VERIFIED_FLAG ='1' THEN
        P_EXPIRY_DAYS  := TRUNC(V_EXPIRY_DATE - SYSDATE);
      END IF;
    IF P_ADDRESS_VERIFIED_FLAG ='0' THEN
    BEGIN
      SELECT cch_renewal_date
      INTO V_RENEWAL_DATE
      FROM cms_cardrenewal_hist
      WHERE CCH_INST_CODE= p_instcode
      AND cch_pan_code   =V_HASH_PAN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;
    WHEN OTHERS THEN
      P_RESP_CODE := '89';
      V_ERRMSG    := 'Error while selecting data from renewal history for card number'|| SUBSTR (SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    END IF;


    IF P_ADDRESS_VERIFIED_FLAG ='0' AND V_RENEWAL_DATE IS NOT NULL THEN
    BEGIN
      SELECT ccs_shipped_date
      INTO P_SHIPPED_DATE
      FROM cms_cardissuance_status
      WHERE ccs_pan_code = V_HASH_PAN
      AND ccs_inst_code  = p_instcode;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG    := 'No data found while selecting SHIPPED DATE';
              RAISE exp_main_reject_record;
            WHEN OTHERS THEN
            P_RESP_CODE := '21';
            v_errmsg  := 'while selecting SHIPPED DATE'|| SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
      END;
    END IF;

--Added on 18-02-2014: MVCSD-4121 & FWR Ends


   --Added for CR - 40 in release 23.1.1
   BEGIN
      SELECT cat_type_code
        INTO v_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_instcode
         AND cat_switch_type = v_switch_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Acct type not defined in master(Savings)';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting accttype(Savings) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   -- St select savings acct number.
   BEGIN
      SELECT cam_acct_no,cam_stat_code, cam_lupd_date
        INTO p_savingss_acct_no,v_status_code, v_last_updatedate
        FROM cms_acct_mast
       WHERE cam_acct_id IN (
                SELECT cca_acct_id
                  FROM cms_cust_acct
                 WHERE cca_cust_code = v_cust_code
                   AND cca_inst_code = p_instcode)
         AND cam_type_code = v_acct_type
         AND cam_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_savingss_acct_no := '';
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting savings acc number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

     -- En select savings acct number.
   --Sn Added for CR - 40 in release 23.1.1
   IF p_savingss_acct_no IS NULL
   THEN
      p_saving_acct_info := 0;               --Saving Account does not exists
   ELSE
      p_saving_acct_info := 1;              --Savings Account exists and open

      BEGIN

        /*                                      -- Query commented as per review observation for LYFEHOST-63
         SELECT cam_stat_code, cam_lupd_date
           INTO v_status_code, v_last_updatedate
           FROM cms_acct_mast
          WHERE cam_acct_no = p_savingss_acct_no
          AND cam_inst_code = p_instcode;
        */

         BEGIN
            SELECT cas_stat_code
              INTO v_acct_status
              FROM cms_acct_stat
             WHERE cas_inst_code = p_instcode
               AND cas_switch_statcode = v_switch_acct_stats;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_resp_code := '21';
               v_errmsg := 'Acct stat not defined for  master';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :=
                     'Error while selecting V_ACCT_STATS '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         IF v_acct_status = v_status_code
         THEN
            p_saving_acct_info := 2;

--Savings Account closed and incase of closed its not exceeded the number of days for reopening (Not eligible for re-opening)

            --Fetching reopen period
            BEGIN

               SELECT cdp_param_value
                 INTO v_reopen_period
                 FROM cms_dfg_param
                WHERE cdp_param_key = 'Saving account reopen period'
                and   cdp_inst_code = p_instcode                     --Added for LYFEHOST-63
                and   cdp_prod_code = v_prod_code                   --Added for LYFEHOST-63
                and   cdp_card_type = v_prod_cattype;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_resp_code := '21';
                  v_errmsg := 'Reopen period is not defined for product code '||v_prod_code||' and instcode '||p_instcode; -- Change in error message for LYFEHOST-63
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  p_resp_code := '21';
                  v_errmsg :=
                        'Error while selecting V_REOPEN_PERIOD '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            IF SYSDATE - v_last_updatedate > v_reopen_period
            THEN
               p_saving_acct_info := 3;
--Savings Account closed and it can be reopened as its exceeded number of days for reopening  (Eligible for re-opening)
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            v_errmsg :=
                  'Error while selecting V_LAST_UPDATEDATE  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

     --Sn of Getting  the Acct Balannce
   BEGIN

      SELECT     cam_acct_bal, cam_ledger_bal
            INTO p_acct_bal, v_ledger_bal
            FROM cms_acct_mast
           WHERE cam_acct_no = p_spending_acct_no                  -- Added as per review observation for LYFEHOST-63
                    /*                                             -- SubQuery commented as per review observation for LYFEHOST-63
                    (SELECT cap_acct_no
                       FROM cms_appl_pan
                      WHERE cap_pan_code = v_hash_pan              --P_card_no
                        AND cap_mbr_numb = '000'
                        AND cap_inst_code = p_instcode)
                      */
             AND cam_inst_code = p_instcode
      FOR UPDATE NOWAIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '14';                         --Ineligible Transaction
         v_errmsg := 'Invalid Card ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
               'Error while selecting data from card Master for card number '
            || v_hash_pan||' '||substr(sqlerrm,1,100);                          -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_main_reject_record;
   END;
   --En of Getting  the Acct Balannce

   BEGIN
      sp_getfee_details (p_instcode,
                         p_cardnum,
                         '000',
                         '07',
                         '1',
                         p_delivery_channel,
                         NULL,
                         p_feeamount,
                         v_fee_desc,
                         v_feeflag,
                         v_avail_bal,
                         v_led_bal,
                         v_clawback_flag,
                         --p_errmsg --Commented And Modified For mantis id  10299
                         v_errmsg
                        );

      IF v_respcode <> '00' AND v_errmsg <> 'OK'
      THEN
         v_errmsg := v_errmsg;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error from get fee details' || SUBSTR (SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_main_reject_record;
   END;

   --En Added for CR - 40 in release 23.1.1
   IF v_respcode <> '00'
   THEN
      BEGIN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      END;
   ELSE
      p_resp_code := v_respcode;
   END IF;

   --En select response code and insert record into txn log dtl

   ---Sn Updation of Usage limit and amount
   
   /* -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
   BEGIN
      SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
        INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
        FROM cms_translimit_check
       WHERE ctc_inst_code = p_instcode
         AND ctc_pan_code = v_hash_pan
         AND ctc_mbr_numb = '000';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Cannot get the Transaction Limit Details of the Card'
            || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting 1 CMS_TRANSLIMIT_CHECK'
            || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      --Sn Usage limit and amount updation for MMPOS
      IF p_delivery_channel = '04'
      THEN
         IF v_tran_date > v_business_date_tran
         THEN
            v_mmpos_usagelimit := 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = v_mmpos_usagelimit,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (p_trandate || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = '000';

                 if sql%rowcount =0                             --Added as per review observation for LYFEHOST-63
                 then

                    v_respcode := '21';
                    v_errmsg := 'Record not updated in translimit table';
                    RAISE exp_main_reject_record;
                 end if;


            EXCEPTION WHEN exp_main_reject_record
            THEN
                RAISE;

            WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating 1 CMS_TRANSLIMIT_CHECK'
                     || SUBSTR (SQLERRM, 1, 300);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         ELSE
            v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = '000';

                 if sql%rowcount =0                             --Added as per review observation for LYFEHOST-63
                 then

                    v_respcode := '21';
                    v_errmsg := 'Record not updated in translimit table 1';
                    RAISE exp_main_reject_record;
                 end if;


            EXCEPTION WHEN exp_main_reject_record
            THEN
                RAISE;

               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating 2 CMS_TRANSLIMIT_CHECK'
                     || SUBSTR (SQLERRM, 1, 300);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;
   --En Usage limit and amount updation for MMPOS
   END;
     */
	 
   ---En Updation of Usage limit and amount
    ---SN Commented And Moved up for MANTIS ID 10299
   --IF errmsg is OK then balance amount will be returned
   /*IF p_errmsg = 'OK'
   THEN
      --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal
               INTO v_acct_balance, v_ledger_bal
               FROM cms_acct_mast
              WHERE cam_acct_no =
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan           --P_card_no
                           AND cap_mbr_numb = '000'
                           AND cap_inst_code = p_instcode)
                AND cam_inst_code = p_instcode
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '14';                      --Ineligible Transaction
            v_errmsg := 'Invalid Card ';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '12';
            v_errmsg :=
                  'Error while selecting data from card Master for card number '
               || v_hash_pan;
            RAISE exp_main_reject_record;
      END;

      --En of Getting  the Acct Balannce
      IF p_errmsg = 'OK'
      THEN
         p_errmsg := '';
         p_acct_bal := v_acct_balance;
      END IF;
   END IF;*/
   ---EN Commented And Moved up for MANTIS ID 10299

   BEGIN
IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET ani = p_ani,
             dni = p_dni
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
   ELSE 
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET ani = p_ani,
             dni = p_dni
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
   END IF;


         if sql%rowcount =0                             --Added as per review observation for LYFEHOST-63
         then

            p_resp_code := '21';
            p_errmsg := 'Record not updated in transactionlog';
            RAISE exp_main_reject_record;
         end if;

   EXCEPTION WHEN exp_main_reject_record                --Added as per review observation for LYFEHOST-63
   THEN
       RAISE exp_main_reject_record;

   WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;

EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      ---Sn Updation of Usage limit and amount
      /* -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
       BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan
            AND ctc_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;             -- Change in error message as per review observation for LYFEHOST-63
            v_respcode := '21';
            --RAISE exp_main_reject_record;                            -- commented as per review observation for LYFEHOST-63
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting 2 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
            v_respcode := '21';
            --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF p_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_amt = 0,
                         ctc_mmposusage_limit = v_mmpos_usagelimit,
                         ctc_atmusage_amt = 0,
                         ctc_atmusage_limit = 0,
                         ctc_business_date =
                            TO_DATE (p_trandate || '23:59:59',
                                     'yymmdd' || 'hh24:mi:ss'
                                    ),
                         ctc_preauthusage_limit = 0,
                         ctc_posusage_amt = 0,
                         ctc_posusage_limit = 0
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating 3 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
                     v_respcode := '21';
                     --RAISE exp_main_reject_record;                           -- Commented as per review observation for LYFEHOST-63
               END;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_limit = v_mmpos_usagelimit
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating 4 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
                     v_respcode := '21';
                     --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      END;
	  */
   ---En Updation of Usage limit and amount
   WHEN exp_main_reject_record
   THEN

   if v_ledger_bal is null          --Added during review observation changes for LYFEHOST-63
   then

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_bal
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_inst_code = p_instcode)
            AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

   end if;

 --SN : Added for 13160

      v_timestamp := systimestamp;

      if v_acct_type is null
      then

           BEGIN
              SELECT cat_type_code
                INTO v_acct_type
                FROM cms_acct_type
               WHERE cat_inst_code = p_instcode
                 AND cat_switch_type = v_switch_acct_type;
           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 p_resp_code := '21';
                 v_errmsg := 'Acct type not defined in master(Savings)';
                 RAISE exp_main_reject_record;
              WHEN OTHERS
              THEN
                 p_resp_code := '12';
                 v_errmsg :=
                       'Error while selecting accttype(Savings) '
                    || SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_main_reject_record;
           END;

      end if;

     if v_dr_cr_flag is null
     then

       BEGIN
          SELECT ctm_credit_debit_flag
            INTO v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_instcode;
       EXCEPTION
          WHEN OTHERS
          THEN
            null;

       END;

     end if;

     if v_prod_code is null
     then

       BEGIN

          SELECT cap_prod_code, cap_card_type,
                 cap_card_stat,
                 cap_acct_no
            INTO v_prod_code, v_prod_cattype,
                 v_cap_card_stat,
                 p_spending_acct_no
            FROM cms_appl_pan
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;

       EXCEPTION
          WHEN OTHERS
          THEN
            null;

       END;

     end if;

   --EN : Added for 13160

      ---Sn Updation of Usage limit and amount
      /* -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
	  BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan
            AND ctc_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;           -- Change in error message as per review observation for LYFEHOST-63
            v_respcode := '21';
            --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting 3 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
            v_respcode := '21';
            --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF p_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_amt = 0,
                         ctc_mmposusage_limit = v_mmpos_usagelimit,
                         ctc_atmusage_amt = 0,
                         ctc_atmusage_limit = 0,
                         ctc_business_date =
                            TO_DATE (p_trandate || '23:59:59',
                                     'yymmdd' || 'hh24:mi:ss'
                                    ),
                         ctc_preauthusage_limit = 0,
                         ctc_posusage_amt = 0,
                         ctc_posusage_limit = 0
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating 5 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
                     v_respcode := '21';
                     --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
               END;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_limit = v_mmpos_usagelimit
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating 6 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 300)||' '||v_errmsg;            -- Change in error message as per review observation for LYFEHOST-63
                     v_respcode := '21';
                     --RAISE exp_main_reject_record;                           -- commented as per review observation for LYFEHOST-63
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      END;
	  */

      ---En Updation of Usage limit and amount

      --Sn select response code and insert record into txn log dtl
      BEGIN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      END;

      --Sn select response code and insert record into txn log dtl
      BEGIN
         IF p_resp_code = '00'
         THEN
            SELECT cam_acct_bal
              INTO v_toacct_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_instcode
               AND cam_acct_no = (SELECT cap.cap_acct_no
                                    FROM cms_appl_pan cap
                                   WHERE cap.cap_pan_code = v_hash_pan);

            p_acct_bal := v_toacct_bal;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '99';
      END;

      p_errmsg := v_errmsg;
      p_acct_bal := v_toacct_bal;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code,
                      total_amount,
                      currencycode, addcharge, productid, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id, ani,
                      dni, cardstatus,
                      --Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc,        -- FOR Transaction detail report issue
                      --SN Added for 13160
                      Acct_type,
                      Time_stamp,
                      cr_dr_flag,
                      Error_msg
                      --EN Added for 13160
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, 0,
                      v_business_date, p_txn_code, v_txn_type, 0,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                      v_currcode, NULL,
                      v_prod_code,--SUBSTR (p_cardnum, 1, 4), modified for 13160
                      v_prod_cattype,                         --modified for 13160
                      0, v_inil_authid,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')),   --NVL added for 13160
                      '0.00',--NULL,    --modified for 13160
                      '0.00',--NULL,    --modified for 13160
                      p_instcode,
                      v_encr_pan, v_encr_pan,
                      P_PROXY_NUM, 0,
                            --v_acct_number,     --Added by Besky on 09-nov-12,--Commented and Added on 27.02.2013 for CR-046
                            p_spending_acct_no,
                      nvl(v_acct_balance,0),     --NVL added for 13160
                      nvl(v_ledger_bal,0),       --NVL added for 13160
                      v_respcode, p_ani,
                      p_dni, v_cap_card_stat,
                      --Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc,      -- FOR Transaction detail report issue
                      --SN Added for 13160
                      v_acct_type,
                      v_Timestamp,
                      v_dr_cr_flag,
                      v_errmsg
                      --EN Added for 13160
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                      ctd_txn_type
                     )
              VALUES (p_delivery_channel, p_txn_code, '0200',
                      0, p_trandate, p_trantime,
                      v_hash_pan, 0, v_currcode,
                      0, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan, '',
                      v_txn_type
                     );

         p_errmsg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '22';                            -- Server Declined
            ROLLBACK;
            RETURN;
      END;
   WHEN OTHERS
   THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;

/

show error