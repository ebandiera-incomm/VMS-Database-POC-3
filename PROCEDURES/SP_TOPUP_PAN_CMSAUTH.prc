create or replace PROCEDURE      vmscms.SP_TOPUP_PAN_CMSAUTH  (
   p_instcode           IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_terminalid         IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_pan                IN       VARCHAR2,
   p_amount             IN       NUMBER,
   p_currcode           IN       VARCHAR2,
   p_lupduser           IN       NUMBER,
   p_msg                IN       VARCHAR2, 
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_merchant_name      IN       VARCHAR2,
   p_merchant_city      IN       VARCHAR2,
   p_reason_code        IN       VARCHAR2, --Added for JH-10
   p_merchant_zip      IN       VARCHAR2 ,--added for VMS-622 (redemption_delay zip code validation)
   p_resp_code          OUT      VARCHAR2,
   p_errmsg             OUT      VARCHAR2,
   p_acctId1            OUT      VARCHAR2, -- Spending account number added for mantis id:15563
   p_acctId2            OUT      VARCHAR2, -- Savings account number added for mantis id:15563
   p_spendtosavetrans_flag   OUT      VARCHAR2, -- Spending to Savings Transafer flag added for mantis id:15563
   p_spendtosave_amt    OUT      VARCHAR2,   -- Load time transfer amount added for mantis id:15563
   p_rrn_sptosa         out      varchar2,  --RRN added for mantis id:15563
   p_currcode_sptosa    OUT      VARCHAR2,  -- IF delivery channel is 'MMPOS' then base curency code will be the tran currency code. added for mantis id:15563
   p_termid_in          in varchar2 default null,
   p_funding_account    in   varchar2 default null,
   p_original_rrn       in   varchar2 default null
)
AS
   /*************************************************************************************

  * modified by         : B.Besky
  * modified Date       : 06-NOV-12
  * modified reason     : Changes in Exception handling
  * Reviewer            : Saravanakumar
  * Reviewed Date       : 06-NOV-12
  * Build Number        : CMS3.5.1_RI0021_B0003
  * modified by         : Sagar
  * modified Date       : 12-Feb-13
  * modified reason     : v_errmsg replaced by v_respmsg while call to sp_limitcnt_reset
  * Reviewer            : Dhiarj
  * Reviewed Date       : 12-Feb-13
  * Build Number        : CMS3.5.1_RI0022.3_B0002

 * Modified Date        : 09_May_2013
 * Modified By          : Pankaj S.
 * Purpose              : Increase errmsg size & to handle proper exception (DFCHOST-325)
 * Reviewer             :  Dhiraj
 * Release Number       : RI0024.1_B0024

  * Modified By         : Anil Kumar
  * Modified Date       : 05-SEP-13
  * Modified Reason     : logging the Reason Code in load request of MMPOS.( JH-10 )
  * Reviewer            : Dhiraj
  * Reviewed Date       : 05-SEP-13
  * Build Number        : RI0024.4_B0010

  * Modified By          : Anil Kumar
  * Modified Date        : 04-Oct-13
  * Modified Reason      : JH-60
  * Reviewer             : Dhiraj
  * Reviewed Date        : 05-SEP-13
  * Build Number         : RI0024.5_B0001

  * Modified By          : Abdul Hameed M.A
  * Modified Date        : 07-jan-14
  * Modified Reason      : 0012455:Savings Acct Initial transfer Transaction declined with 89 due to the Transaction Currency cannot be null
  * Reviewer             : Dhiraj
  * Reviewed DATE        : 07-jan-14
  * Build Number         : RI0027_B0002

  * Modified by       : Sagar
  * Modified for      :
  * Modified Reason   : Concurrent Processsing Issue
                        (1.7.6.7 changes integarted)
  * Modified Date     : 04-Mar-2014
  * Reviewer          : Dhiarj
  * Reviewed Date     : 06-Mar-2014
  * Build Number      : RI0027.1.1_B0001


  * Modified by       : Abdul Hameed M.A
  * Modified for      : Mantis ID 13893
  * Modified Reason   : Added card number for duplicate RRN check
  * Modified Date     : 06-Mar-2014
  * Reviewer          : Dhiraj
  * Reviewed Date     : 06-Mar-2014
  * Build Number      : RI0027.2_B0002

  * Modified by       : Siva Kumar M
  * Modified for      : Mantis ID 15563
  * Modified Reason   : CHW TOP UP - WSDL Web service shows the Response message as 'success' but the transaction as not registered in DB.
  * Modified Date     : 15-July-2014
  * Build Number      : RI0027.3

  * Modified by       : Abdul Hameed M.A
  * Modified for      : JH 3012
  * Modified Reason   : New error code and error message added for all fast transactions.
  * Modified Date     : 22-August-2014
  * Reviewer          : Spankaj
  * Build Number      : RI0027.3.2_B0001

  * Modified by       : Dhinakaran B
  * Modified for      : JH-3023
  * Modified Date     : 26-AUG-2014
  * Build Number      : RI0027.3.2_B0002
  * Modified by       : Sai
  * Modified for      : FWR-70
  * Modified Date     : 04-Oct-2014
  * Reviewer          : Spankaj
  * Build Number      : RI0027.4_B0003

   * Modified by       : Abdul Hameed M.A
   * Modified for      : JH-3062
   * Modified Date     : 18-Dec-2014
   * Reviewer          : Spankaj
   * Build Number      : RI0027.5_B0001

    * Modified by       : Abdul Hameed M.A
   * Modified Date     : 12-Oct-2015
   * Reviewer          : Spankaj
   * Build Number      :  VMSGPRHOST_3.1.2_B0001

       * Modified by       :Siva kumar
       * Modified Date    : 06-Jan-16
       * Modified For     : VPP-177
       * Reviewer            : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.3

       * Modified by       :Sai Prasad
       * Modified Date    : 21-MAR-16
       * Modified For     : Mantis ID 0016307
       * Reviewer          : Saravanankumar
       * Build Number     : VMSGPRHOST4.0_B0006

       * Modified by      : Pankaj S.
       * Modified Date    : 09-Mar-17
       * Modified For     : FSS-4647
       * Modified reason  : Redemption Delay Changes
       * Reviewer         : Saravanakumar
       * Build Number     : VMSGPRHOST_17.3

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

       * Modified By      : Siva Kumar M
       * Modified Date    : 26/09/2017
       * Purpose          : FSS-5157
       * Reviewer         : Saravanan/Pankaj S.
       * Release Number   : VMSGPRHOST17.07

	   * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 21/12/2017
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST17.12

	 * Modified By      : DHINAKARAN B
     * Modified Date    : 29-JUN-2018
     * Purpose          : VMS-344
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R03

      * Modified By      : Baskar K
     * Modified Date    : 21-AUG-2018
     * Purpose          : VMS-454
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R05
	 
   	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11
     
     * Modified By      : Mageshkumar S
     * Modified Date    : 21-OCT-2020
     * Purpose          : VMS-3135:Location ID received in the MMPOS Reload transactions is not stored in VMS.
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST_R37_B0002
     
     * Modified By      : Mageshkumar S
     * Modified Date    : 07-MAY-2021
     * Purpose          : VMS-3693:Card Reload and ReTry--B2B Spec Consolidation
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST_R46_B0001
     
     * Modified By      : Mageshkumar S
     * Modified Date    : 25-MAY-2021
     * Purpose          : VMS-4392:Issue in second retry case for card reload
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST_R47_B0001

    * Modified By      : venkat Singamaneni
    * Modified Date    : 5-02-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
   **************************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_cap_appl_code          cms_appl_pan.cap_appl_code%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   V_ERRMSG                 VARCHAR2 (300);
   v_varprodflag            cms_prod_cattype.CPC_RELOADABLE_FLAG%TYPE;
   v_currcode               VARCHAR2 (3);
   v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_code               cms_func_mast.cfm_txn_code%TYPE;
   v_txn_mode               cms_func_mast.cfm_txn_mode%TYPE;
   v_del_channel            cms_func_mast.cfm_delivery_channel%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_topup_auth_id          transactionlog.auth_id%TYPE;
   v_min_max_limit          VARCHAR2 (50);
   v_acct_txn_dtl           cms_topuptrans_count.ctc_totavail_days%TYPE;
   v_topup_freq             VARCHAR2 (50);
   v_topup_freq_period      VARCHAR2 (50);
   v_end_lupd_date          cms_topuptrans_count.ctc_lupd_date%TYPE;
   v_acct_txn_dtl_1         cms_topuptrans_count.ctc_totavail_days%TYPE;
   v_end_day_update         cms_topuptrans_count.ctc_lupd_date%TYPE;
   v_min_limit              VARCHAR2 (50);
   v_max_limit              VARCHAR2 (50);
   v_rrn_count              NUMBER;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_business_date          DATE;
   v_tran_date              DATE;
   v_topupremrk             VARCHAR2 (100);
   v_acct_balance           NUMBER;
   v_ledger_balance         NUMBER;
   v_tran_amt               NUMBER;
   v_delchannel_code        VARCHAR2 (2);
   v_card_curr              VARCHAR2 (5);
   v_date                   DATE;
   v_base_curr              cms_bin_param.cbp_param_value%TYPE;
   v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
   v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     DATE;
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   authid_date              VARCHAR2 (8);
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
  /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   v_comb_hash              pkg_limits_check.type_hash;
   v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
/* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD  */

    V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
    V_TRANS_DESC_MAST   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;

    v_cust_code   cms_appl_pan.cap_cust_code%type; -- Added by siva kumar m  on 22/08/2012.
    v_delivery_channel    cms_transaction_mast.ctm_delivery_channel%type default '05';
    v_txns_code            cms_transaction_mast.CTM_TRAN_CODE%type        default '23';

    v_switch_acct_type    cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
    v_saving_count        number;
    v_acct_type         cms_acct_type.cat_type_code%TYPE;
    --v_loadtime_transfer   number;
    v_saving_acct_number    cms_appl_pan.cap_acct_no%TYPE;
    v_loadtime_transfer     cms_acct_mast.cam_loadtime_transfer%type;
    v_loadtime_transferamt  cms_acct_mast.cam_loadtime_transferamt%type;

    v_spenacctbal     cms_acct_mast.cam_acct_bal%type;
    v_spenacctledgbal cms_acct_mast.cam_ledger_bal%type;
    v_resp_code       varchar2(50);
    v_resmsg          varchar2(500); --modified by Pankaj S. on 09_May_2013

    v_rrn   VARCHAR2(20);

    V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;   --Added for JH-10
    V_TIME_STAMP   TIMESTAMP;   --Added for JH-10
   v_prodprof_code           cms_prod_cattype.cpc_profile_code%TYPE; --Added for FWR-70
   V_MINRELOAD_AMOUNT  cms_acct_mast.CAM_MINRELOAD_AMOUNT%TYPE;
   --Sn Added for FSS-4647
   v_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
   v_txn_redmption_flag  cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
   --En Added for FSS-4647
   V_CPC_PROD_DENO        CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;
   V_CPC_PDEN_MIN         CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
   V_CPC_PDEN_MAX         CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
   V_CPC_PDEN_FIX         CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
   V_COUNT                NUMBER;
   V_INITIALLOAD_AMT      CMS_ACCT_MAST.CAM_INITIALLOAD_AMT%TYPE;
   v_reason_code          vms_reason_mast.VRM_ENUM_VAL%TYPE;
   v_Retperiod  date;  --Added for VMS-5735/FSP-991
   v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
   p_errmsg := 'OK';
   v_topupremrk := 'Online Card Topup';
   V_TIME_STAMP :=SYSTIMESTAMP;   --Added for JH-10
   p_spendtosavetrans_flag := 'N';  --added for Mantis id:15563 on 15-July-2014

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create encr pan

   --Start Generate HashKEY value for JH-10
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        v_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
     END;
   --End Generate HashKEY value for JH-10

   --Sn Added for JH 3012
          --Sn get date
        BEGIN
            v_business_date :=
                TO_DATE (
                        SUBSTR (TRIM (p_trandate), 1, 8)
                    || ' '
                    || SUBSTR (TRIM (p_trantime), 1, 10),
                    'yyyymmdd hh24:mi:ss');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_respcode := '21';
                v_errmsg :=
                    'Problem while converting transaction date '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_main_reject_record;
        END;

        --En get date
     --En Added for JH 3012
   --Sn find debit and credit flag
   BEGIN
   /* START  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_prfl_flag, -- prifile code added for LIMITS BRD
             CTM_TRAN_DESC,CTM_TRAN_DESC, NVL(ctm_redemption_delay_flag,'N')
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_prfl_flag,     -- prifile code added for LIMITS BRD
             V_TRANS_DESC, V_TRANS_DESC_MAST, v_txn_redmption_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
         /* END  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
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
         --v_respcode := 'Error while selecting transaction details'; -- Commented on 12-Feb-2013 , since same was incorrect
         v_errmsg := 'Error while selecting transaction details'; -- Added on 12-Feb-2013 , since same was incorrect
         RAISE exp_main_reject_record;
   END;

   --En find debit and credit flag
   
   v_reason_code := p_reason_code;
   
   IF  (p_delivery_channel='17' AND p_txn_code ='03') THEN
   
     BEGIN

        SELECT VRM_REASON_DESC,VRM_REASON_CODE
           into V_TRANS_DESC,v_reason_code
           from vms_reason_mast
          where VRM_ENUM_VAL=upper(v_reason_code)
          AND VRM_REASON_TYPE is null;
          
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          V_TRANS_DESC := V_TRANS_DESC;
         WHEN OTHERS
             THEN
             v_respcode := '21';
              v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
        END;
   
   END IF;
   
    

   IF NOT (p_delivery_channel='17' AND p_txn_code ='03') THEN
   --Added for JH-10
     begin
        /* SELECT nvl(decode(substr(p_reason_code,1,1),'F',('Fast'||p_amount),'T','Federal Assisted Refund','S','State Assisted Refund','A','Refund Advance','R','Refer a Friend','0','Fast-25'),V_TRANS_DESC) --Modified for JH-60/JH-3062
          INTO V_TRANS_DESC
          FROM dual;*/

          select  VRM_REASON_DESC
           into V_TRANS_DESC
           from vms_reason_mast
          where VRM_REASON_CODE=upper(v_reason_code)
          AND VRM_REASON_TYPE is null;

        EXCEPTION
          WHEN NO_DATA_FOUND
       THEN
                 BEGIN
                   select  VRM_REASON_DESC
                   into V_TRANS_DESC
                   from vms_reason_mast
                  where VRM_REASON_CODE=upper(substr(v_reason_code,1,1))
                   AND VRM_REASON_TYPE is null;

               EXCEPTION  WHEN NO_DATA_FOUND THEN

               V_TRANS_DESC := V_TRANS_DESC;

              WHEN OTHERS THEN
                 v_respcode := '21';
                v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_main_reject_record;

              END;

     WHEN exp_main_reject_record THEN
        RAISE;
     WHEN OTHERS
       THEN
         v_respcode := '21';
         v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
     END;
        -- Fast<<AMNT>>
        
     END IF; 
      
       begin

        SELECT REPLACE(V_TRANS_DESC,'<<AMNT>>',p_amount)
        INTO V_TRANS_DESC FROM dual;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          V_TRANS_DESC := V_TRANS_DESC;
         WHEN OTHERS
             THEN
             v_respcode := '21';
              v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
        end;

   --End for JH-10

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
 /*  BEGIN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
                                       --Added by ramkumar.Mk on 25 march 2012

      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN' || ' on ' || p_trandate;
         RAISE exp_main_reject_record;
      END IF;
   END;
*/
-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, P_TRANDATE, P_DELIVERY_CHANNEL, p_msg, p_txn_code, V_ERRMSG );
      IF V_ERRMSG <> 'OK' THEN
        V_RESPCODE := '22';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESPCODE := '22';
      V_ERRMSG  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_MAIN_REJECT_RECORD;
    END;
   --En Duplicate RRN Check

   --Sn select Pan detail
   BEGIN
   /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_firsttime_topup, cap_mbr_numb,
             cap_prod_code, cap_card_type, cap_proxy_number, cap_acct_no,
             cap_prfl_code,cap_cust_code                -- prifile code added for LIMITS BRD  -- added cap_cust_code by siva kumar m on 22/08/0212
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb,
             v_prod_code, v_card_type, v_proxunumber, v_acct_number,
             v_prfl_code ,v_cust_code                 -- prifile code added for LIMITS BRD    -- added v_cust_code by siva kumar m on 22/08/0212
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_mbr_numb = p_mbr_numb
            AND cap_inst_code = p_instcode;
       /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
   END;

   --En select Pan detail

   --Sn check the min and max limit for topup
   /*BEGIN                                        --commented by amit on 28-Jul-2012 to verify limits from limit profile
      --Profile Code of Product
      SELECT cpm_profile_code
        INTO v_profile_code
        FROM cms_prod_mast
       WHERE cpm_prod_code = v_prod_code AND cpm_inst_code = p_instcode;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
   END;
   */

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
        RAISE exp_main_reject_record;
        END;
     IF v_varprodflag = 'Y'  then
        IF v_cpc_prod_deno = 1
        THEN
          IF p_amount NOT BETWEEN v_cpc_pden_min AND v_cpc_pden_max
          THEN
          v_respcode := '43';
          v_errmsg := 'Invalid Amount';
          RAISE exp_main_reject_record;
        END IF;
        ELSIF v_cpc_prod_deno = 2
        THEN
          IF p_amount <> v_cpc_pden_fix
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
          AND VPD_PDEN_VAL = p_amount;

          IF v_count = 0
          THEN
            v_respcode := '43';
            v_errmsg := 'Invalid Amount';
            RAISE exp_main_reject_record;
          END IF;
      END IF;
      else
         v_respcode := '17';
         v_errmsg :=
             'Top up is not applicable on this card number ' || v_acct_number;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Card type (fixed/variable ) not defined for the card '
            || v_acct_number;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
   END;

   --En  select variable type detail
   --Sn Check initial load
   /*IF v_firsttime_topup = 'N'        --commented by amit on 28-Jul-2012 to verify limits from limit profile
   THEN
      v_respcode := '21';
      v_errmsg :=
            'Topup is applicable only after initial load for this acctno '
         || v_acct_number;
      RAISE exp_main_reject_record;
   END IF;
    */
   --En Check initial load
   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'MMPOS' AND cdm_inst_code = p_instcode;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN
           /* SELECT cip_param_value
              INTO v_base_curr
              FROM cms_inst_param
             WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';*/ --commented for FWR-70

	      SELECT TRIM (cbp_param_value)
	      INTO v_base_curr
	      FROM cms_bin_param --Added for FWR-70
              WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
              AND cbp_profile_code = V_PROFILE_CODE;

            IF v_base_curr IS NULL
            THEN
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                          'Base currency is not defined for the bin profile ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting base currency for bin  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := p_currcode;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of MMPOS  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Currency Conversion
   BEGIN
      v_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

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
               'Problem while converting transaction time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      IF (p_amount > 0)
      THEN
         v_tran_amt := p_amount;

         BEGIN
            sp_convert_curr (p_instcode,
                             v_currcode,
                             p_pan,
                             p_amount,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_errmsg,
                             V_PROD_CODE,
                             V_CARD_TYPE
                            );

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
               v_respcode := '69';                 -- Server Declined -220509
               v_errmsg :=
                     'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;
   END;

   /*BEGIN                                    --commented by amit on 28-Jul-2012 to verify limits from limit profile
      SELECT COUNT (1)
        INTO v_min_max_limit
        FROM cms_bin_param a, cms_bin_param b
       WHERE a.cbp_profile_code = v_profile_code
         AND a.cbp_profile_code = b.cbp_profile_code
         AND a.cbp_param_type = 'Topup Parameter'
         AND a.cbp_param_type = b.cbp_param_type
         AND a.cbp_inst_code = p_instcode
         AND a.cbp_inst_code = b.cbp_inst_code
         AND a.cbp_param_name = 'Min Topup Limit'
         AND b.cbp_param_name = 'Max Topup Limit'
         AND v_tran_amt BETWEEN a.cbp_param_value AND b.cbp_param_value;

      IF v_min_max_limit = 0
      THEN
         SELECT a.cbp_param_value, b.cbp_param_value
           INTO v_min_limit, v_max_limit
           FROM cms_bin_param a, cms_bin_param b
          WHERE a.cbp_profile_code = v_profile_code
            AND a.cbp_profile_code = b.cbp_profile_code
            AND a.cbp_param_type = 'Topup Parameter'
            AND a.cbp_param_type = b.cbp_param_type
            AND a.cbp_inst_code = p_instcode
            AND a.cbp_inst_code = b.cbp_inst_code
            AND a.cbp_param_name = 'Min Topup Limit'
            AND b.cbp_param_name = 'Max Topup Limit';

         v_errmsg :=
               'Topup Limit Exceeded.Limit is between'
            || v_min_limit
            || ' TO '
            || v_max_limit;
         v_respcode := '34';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Topup Amount is out of range '
            || v_min_limit
            || ' TO '
            || v_max_limit;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Topup Amount is out of range '
            || v_min_limit
            || ' TO '
            || v_max_limit;
         RAISE exp_main_reject_record;
   END;

   --En check the min and max limit for topup

   --Sn Check The transaction availibillity in table
   BEGIN
      SELECT a.cbp_param_value, b.cbp_param_value
        INTO v_topup_freq, v_topup_freq_period
        FROM cms_bin_param a, cms_bin_param b
       WHERE a.cbp_profile_code = v_profile_code
         AND a.cbp_profile_code = b.cbp_profile_code
         AND a.cbp_param_type = 'Topup Parameter'
         AND a.cbp_param_type = b.cbp_param_type
         AND a.cbp_inst_code = p_instcode
         AND a.cbp_inst_code = b.cbp_inst_code
         AND a.cbp_param_name = 'Topup Freq Amount'
         AND b.cbp_param_name = 'Topup Freq Period';
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Freq and period is not defined ' || v_topup_freq;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                    'Freq and period is not defined  ' || v_topup_freq_period;
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT COUNT (1)
        INTO v_acct_txn_dtl
        FROM cms_topuptrans_count
       WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;

      IF v_acct_txn_dtl = 0
      THEN
         INSERT INTO cms_topuptrans_count
                     (ctc_inst_code, ctc_pan_code, ctc_totavail_days,
                      ctc_ins_user, ctc_ins_date, ctc_lupd_user,
                      ctc_lupd_date, ctc_pan_code_encr
                     )
              VALUES (p_instcode, v_hash_pan, 0,
                      p_lupduser, SYSDATE, p_lupduser,
                      SYSDATE, v_encr_pan
                     );
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
                'Topup Transaction Days are not specifid  ' || v_acct_txn_dtl;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Topup Transaction Days are not specifid  '
            || v_acct_txn_dtl
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      --Sn Week end Process Call
      IF v_topup_freq_period = 'Week'
      THEN
         BEGIN
            SELECT NEXT_DAY (TRUNC (ctc_lupd_date), 'SUNDAY')
              INTO v_end_day_update
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;
         EXCEPTION
            --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting CMS_TOPUPTRANS_COUNT '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
         END;

         IF TRUNC (SYSDATE) > v_end_day_update - 1
         THEN
            UPDATE cms_topuptrans_count
               SET ctc_totavail_days = 0,
                   ctc_lupd_date = SYSDATE
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
               v_errmsg :=
                     'Error while updating CMS_TOPUPTRANS_COUNT '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
            END IF;
         END IF;
      END IF;

      --------THINK ON THAT----------------
      --Sn Month end Process Call
      IF v_topup_freq_period = 'Month'
      THEN
         BEGIN
            SELECT LAST_DAY (TRUNC (ctc_lupd_date))
              INTO v_end_day_update
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;
         EXCEPTION
            --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting CMS_TOPUPTRANS_COUNT '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
         END;

         IF TRUNC (SYSDATE) > (v_end_day_update)
         THEN
            UPDATE cms_topuptrans_count
               SET ctc_totavail_days = 0,
                   ctc_lupd_date = SYSDATE
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
               v_errmsg :=
                     'Error while updating CMS_TOPUPTRANS_COUNT '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
            END IF;
         END IF;
      END IF;

      --Sn Year end Process Call
      IF v_topup_freq_period = 'Year'
      THEN
         BEGIN
            SELECT ADD_MONTHS (TRUNC (ctc_lupd_date, 'YEAR'), 12) - 1
              INTO v_end_day_update
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;
         EXCEPTION
            --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting V_END_DAY_UPDATE '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
         END;

         IF TRUNC (SYSDATE) > v_end_day_update
         THEN
            UPDATE cms_topuptrans_count
               SET ctc_totavail_days = 0,
                   ctc_lupd_date = SYSDATE
             WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
               v_errmsg :=
                     'Error while updating CMS_TOPUPTRANS_COUNT '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
            END IF;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while Updating records into cms_topuptrans_count'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   --En Last Day Process Call
   BEGIN
      SELECT ctc_totavail_days
        INTO v_acct_txn_dtl_1
        FROM cms_topuptrans_count
       WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;

      IF v_acct_txn_dtl_1 >= v_topup_freq
      THEN
         v_respcode := '21';
         v_errmsg := 'Topup Transaction Days are over ' || v_acct_txn_dtl_1;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
              'Topup Transaction Days are not specifid  ' || v_acct_txn_dtl_1;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
              'Topup Transaction Days are not specifid  ' || v_acct_txn_dtl_1;
         RAISE exp_main_reject_record;
   END;*/

   --------------Sn For Debit Card No need using authorization -----------------------------------
 --  IF v_cap_prod_catg = 'P'
--THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (p_instcode,
                                    p_msg,
                                    p_rrn,
                                    p_delivery_channel,
                                    p_termid_In,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    p_pan,
                                    NULL,
                                    p_amount,
                                    p_merchant_name,
                                    p_merchant_city,
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
                                    p_stan,                          -- P_stan
                                    p_mbr_numb,                     --Ins User
                                    p_rvsl_code,                    --INS Date
                                    v_tran_amt,
                                    v_topup_auth_id,
                                    v_respcode,
                                    v_respmsg,
                                    v_capture_date,
                                    'Y',
                                    'N',
                                    'N',
                                    p_funding_account,
                                    p_merchant_Zip-- added for VMS-622 (redemption_delay zip code validation)

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
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
  -- END IF;

--------------------------En
--En call to authorize txn

   /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   BEGIN
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
      THEN
         pkg_limits_check.sp_limits_check (v_hash_pan,
                                           NULL,
                                           NULL,
                                           NULL,                -- p_mcc_code,
                                           p_txn_code,
                                           v_tran_type,
                                           NULL,        --P_INTERNATIONAL_IND,
                                           NULL,
                                           p_instcode,
                                           NULL,
                                           v_prfl_code,
                                           p_amount,                 -- p_txn_amt,
                                           p_delivery_channel,
                                           v_comb_hash,
                                           v_respcode,
                                           v_respmsg
                                          );
      END IF;

      IF v_respcode <> '00' AND v_respmsg <> 'OK'
      then
      --Sn Added for JH 3012
       IF( NVL(SUBSTR(v_reason_code,1,1),0)='F'
          OR NVL(SUBSTR(v_reason_code,1,1),0)='T'
          OR NVL(SUBSTR(v_reason_code,1,1),0)='A'
          OR NVL(SUBSTR(v_reason_code,1,1),0)='R'
          OR NVL(SUBSTR(v_reason_code,1,1),0)='S'
          OR NVL(SUBSTR(v_reason_code,1,1),1)='0') THEN

          if V_RESPCODE='79' then
          V_RESPCODE:='231';
          V_ERRMSG:='Denomination below minimal amount permitted';
          RAISE exp_main_reject_record;
       --   END IF;

           ELSIF V_RESPCODE='80' THEN
          V_RESPCODE:='230';
          v_errmsg:='Denomination exceed permitted amount';
          RAISE EXP_MAIN_REJECT_RECORD;

           ELSE
         V_ERRMSG := 'Error from Limit Check Process ' || V_RESPMSG;
         RAISE EXP_MAIN_REJECT_RECORD;
         END IF;

          ELSE
      --En Added for JH 3012
         V_ERRMSG := 'Error from Limit Check Process ' || V_RESPMSG;
         RAISE EXP_MAIN_REJECT_RECORD;
         END IF;
      end if;

   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */

   --Sn create a record in pan spprt
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Top up reason code is present in master';
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

   -- Sn Transaction availdays Count update
   BEGIN
      UPDATE cms_topuptrans_count
         SET ctc_totavail_days = ctc_totavail_days + 1
       WHERE ctc_pan_code = v_hash_pan AND ctc_inst_code = p_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   -- En Transaction availdays Count update
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_instcode, v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'TOP', v_resoncode, v_topupremrk,
                   p_lupduser, p_lupduser, 0,
                   v_encr_pan
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

   --En create a record in pan spprt
   v_respcode := 1;                         --Response code for successful txn

   --Sn select response code and insert record into txn log dtl
   BEGIN
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      -- Assign the response code to the out parameter
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = decode(p_delivery_channel,'17','10',p_delivery_channel)
         AND cms_response_id = v_respcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Problem while selecting data from response master '
            || v_respcode||v_errmsg
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '69';
         ---ISO MESSAGE FOR DATABASE ERROR Server Declined
         ROLLBACK;
   END;

   --En select response code and insert record into txn log dtl

   ---Sn Updation of Usage limit and amount
   /*BEGIN                                                                    --commented by amit on 28-Jul-2012 to verify limits from limit profile
      SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
        INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
        FROM cms_translimit_check
       WHERE ctc_inst_code = p_instcode
         AND ctc_pan_code = v_hash_pan                             --P_card_no
         AND ctc_mbr_numb = p_mbr_numb;
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
         --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
         v_errmsg :=
               'Cannot get the Transaction Limit Details of the Card'
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
               AND ctc_pan_code = v_hash_pan                      -- P_card_no
               AND ctc_mbr_numb = p_mbr_numb;

            IF SQL%ROWCOUNT = 0
            THEN
               --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
               v_errmsg :=
                     'Error while updating CMS_TRANSLIMIT_CHECK A '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
            END IF;
         ELSE
            v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

            UPDATE cms_translimit_check
               SET ctc_mmposusage_limit = v_mmpos_usagelimit
             WHERE ctc_inst_code = p_instcode
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;

            IF SQL%ROWCOUNT = 0
            THEN
               --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
               v_errmsg :=
                     'Error while updating CMS_TRANSLIMIT_CHECK B '
                  || v_hash_pan
                  || ' '
                  || SQLERRM;
               RAISE exp_main_reject_record;
            END IF;
         END IF;
      END IF;
   --En Usage limit and amount updation for MMPOS
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating CMS_TRANSLIMIT_CHECK'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;
   */
   ---En Updation of Usage limit and amount

   --IF errmsg is OK then balance amount will be returned
   IF p_errmsg = 'OK'
   THEN

      --ST getting current settings for savings account   added by siva kumar
       --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal,nvl(CAM_INITIALLOAD_AMT,'0')
               INTO v_acct_balance, v_ledger_balance,V_INITIALLOAD_AMT
               FROM cms_acct_mast
              WHERE cam_acct_no =v_acct_number
                     /*  (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = p_mbr_numb
                           AND cap_inst_code = p_instcode)*/
                AND cam_inst_code = p_instcode;
          --FOR UPDATE NOWAIT;Commented for Concurrent Processsing Issue  on 25-FEB-2014 By Revathi
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

     --COMMIT;          -- Commit commented during concurrent processing issue

          --Sn select acct type(Savings)
               BEGIN
                  SELECT cat_type_code
                    INTO v_acct_type
                    FROM cms_acct_type
                   WHERE cat_inst_code = p_instcode
                     AND cat_switch_type = v_switch_acct_type;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_respcode := '21';
                     v_errmsg := 'Acct type not defined in master(Savings)';
                     RAISE exp_main_reject_record;
                  WHEN OTHERS
                  THEN
                     v_respcode := '12';
                     v_respmsg :=
                           'Error while selecting accttype(Savings) '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;

               --En select acct type(Savings)
             --Sn Get Savings Acc number
               BEGIN
                  SELECT count(*)
                    INTO v_saving_count
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
                     v_respcode := '105';
                     v_errmsg := 'Savings Acc not created for this card';
                    -- RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_respcode := '12';
                     v_errmsg :=
                           'Error while selecting savings acc number '
                        || SUBSTR (SQLERRM, 1, 200);
                     --RAISE exp_reject_record;
               END;

             IF  v_saving_count = 1 THEN

               BEGIN
                  SELECT cam_acct_no,
                                 nvl(cam_loadtime_transfer,0 ),nvl(cam_loadtime_transferamt,0 ),nvl(CAM_MINRELOAD_AMOUNT,0)
                    INTO v_saving_acct_number,
                               v_loadtime_transfer,v_loadtime_transferamt,V_MINRELOAD_AMOUNT
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
                     v_respcode := '105';
                     v_errmsg := 'Savings Acc not created for this card';

                  WHEN OTHERS
                  THEN
                     v_respcode := '12';
                     v_errmsg :=
                           'Error while selecting savings acc number '
                        || SUBSTR (SQLERRM, 1, 200);
                    -- RAISE exp_reject_record;
               END;

              --En Get Savings Acc number

                 v_rrn := p_rrn || 1;
                 --Sn Added by Pankaj S .on 15_May_2013
                 IF length(v_rrn) >15 THEN
                    v_rrn:=substr(v_rrn,2);
                 END IF;
                 --En Added by Pankaj S .on 15_May_2013


                 -- BEGIN
--                           SELECT nvl(cam_loadtime_transfer,0 ),nvl(cam_loadtime_transferamt,0 ),nvl(CAM_MINRELOAD_AMOUNT,0)
--                           INTO v_loadtime_transfer,v_loadtime_transferamt,V_MINRELOAD_AMOUNT
--                           FROM cms_acct_mast WHERE cam_acct_id IN (
--                                SELECT cca_acct_id
--                                  FROM cms_cust_acct
--                                  WHERE cca_cust_code = v_cust_code
--                                  AND cca_inst_code =  p_instcode )
--                         AND cam_type_code = v_acct_type
--                         AND cam_inst_code = p_instcode;


                                if (v_loadtime_transfer = 1 and v_loadtime_transferamt <= v_acct_balance) then

                                -- call the spending to savings transfer
                                 --added for Mantis id:15563 on 15-July-2014
                                  IF  p_amount >= V_MINRELOAD_AMOUNT THEN  -- added for FSS-2279

                                   p_spendtosavetrans_flag :='Y';

                                  END IF;

                                   p_spendtosave_amt  := v_loadtime_transferamt;
                                   p_acctId1          := v_acct_number;
                                   p_acctId2          := v_saving_acct_number;
                                   p_rrn_sptosa       :=v_rrn;
                                   p_currcode_sptosa        := v_currcode;

                                  /*   commented for Mantis id: 15563 on 15-July-2014
                  BEGIN

                                    SP_SPENDINGTOSAVINGSTRANSFER(p_instcode,
                                                       p_pan,
                                                       p_msg,
                                                       v_acct_number,
                                                       v_saving_acct_number,
                                                       v_delivery_channel,
                                                       v_txns_code,
                                                       v_rrn,
                                                       v_loadtime_transferamt, -- tran amount
                                                       '0',            -- tran mode.
                                                       p_instcode, -- bank code is inst code.
                                                       v_currcode, -- modified by abdul hameed for mantis id 12455
                                                       p_rvsl_code,
                                                       p_trandate,
                                                       p_trantime,
                                                       p_ipaddress,
                                                       p_ani,
                                                       p_dni,
                                                       v_resp_code, -- out parameter
                                                       v_resmsg,
                                                       v_spenacctbal,
                                                       v_spenacctledgbal);


                                     EXCEPTION

                                       WHEN OTHERS  THEN
                                        v_resp_code := '21';
                                        v_resmsg :='Error while calling spendingto savings ' || SUBSTR (SQLERRM, 1, 200);

                                   END;*/

                                end if;
                  --Sn Added by Pankaj S. on 09_May_2013
--                  EXCEPTION
--                       WHEN OTHERS  THEN
--                        v_resp_code := '21';
--                        v_resmsg :='Error while selecting loadtime transfer details-' || SUBSTR (SQLERRM, 1, 200);
--                       RAISE exp_main_reject_record;
--                  --En Added by Pankaj S. on 09_May_2013
--                   END;


                  END IF;

          -- EN getting current settings for savings account

      --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal
               INTO v_acct_balance, v_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no =v_acct_number
                     /*  (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = p_mbr_numb
                           AND cap_inst_code = p_instcode)*/
                AND cam_inst_code = p_instcode;
         --FOR UPDATE NOWAIT;Commented for Concurrent Processsing Issue  on 25-FEB-2014 By Revathi
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
      --p_errmsg := TO_CHAR (v_acct_balance);
      p_errmsg := TRIM(TO_CHAR (v_acct_balance,'999999999999999990.99'));
   END IF;

   BEGIN

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress,
             customer_acct_no = v_acct_number,
             trans_desc = v_trans_desc,   --Added for JH-10
             --reason_code=v_reason_code,
             orgnl_rrn=nvl(p_original_rrn,p_rrn)
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND msgtype = p_msg
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
 ELSE
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress,
             customer_acct_no = v_acct_number,
             trans_desc = v_trans_desc,   --Added for JH-10
             --reason_code=v_reason_code,
             orgnl_rrn=nvl(p_original_rrn,p_rrn)
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND msgtype = p_msg
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
  END IF;

         IF SQL%ROWCOUNT = 0  THEN
         V_RESPMSG  := 'ERROR WHILE UPDATING  TRANSACTION_LOG ';
         P_RESP_CODE := '69';
         RAISE exp_main_reject_record;
      END IF;
     EXCEPTION
     WHEN exp_main_reject_record THEN
      RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
   END;

   -- Start Added for JH-10
   --BEGIN
    IF (v_reason_code IS NOT NULL)
    THEN
    BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
   UPDATE cms_statements_log
      SET CSL_TRANS_NARRRATION = replace (CSL_TRANS_NARRRATION,v_trans_desc_mast, v_trans_desc)
      WHERE CSL_PAN_NO = v_hash_pan
      AND CSL_RRN = p_rrn
      AND CSL_BUSINESS_DATE = p_trandate
      AND CSL_BUSINESS_TIME = p_trantime
      AND CSL_DELIVERY_CHANNEL = p_delivery_channel
      AND CSL_TXN_CODE =  p_txn_code
      AND CSL_AUTH_ID = v_topup_auth_id;
ELSE
    UPDATE VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5733/FSP-991
      SET CSL_TRANS_NARRRATION = replace (CSL_TRANS_NARRRATION,v_trans_desc_mast, v_trans_desc)
      WHERE CSL_PAN_NO = v_hash_pan
      AND CSL_RRN = p_rrn
      AND CSL_BUSINESS_DATE = p_trandate
      AND CSL_BUSINESS_TIME = p_trantime
      AND CSL_DELIVERY_CHANNEL = p_delivery_channel
      AND CSL_TXN_CODE =  p_txn_code
      AND CSL_AUTH_ID = v_topup_auth_id;
END IF;

      IF SQL%ROWCOUNT = 0  THEN
         V_RESPMSG  := 'ERROR WHILE UPDATING cms_statements_log ';
         P_RESP_CODE := '69';
         RAISE exp_main_reject_record;
    END IF;
      EXCEPTION
       WHEN exp_main_reject_record THEN
         RAISE;
        WHEN OTHERS
          THEN
          p_resp_code := '69';
          p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
   END;
END IF;

BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
  UPDATE cms_transaction_log_dtl
        SET ctd_reason_code = v_reason_code,
        ctd_location_id=p_terminalid
      WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel;
ELSE
      UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
        SET ctd_reason_code = v_reason_code,
        ctd_location_id=p_terminalid
      WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel;
END IF;
      IF SQL%ROWCOUNT = 0  THEN
         V_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
         P_RESP_CODE := '69';
         RAISE exp_main_reject_record;
      END IF;
  --  END IF;
      EXCEPTION
       WHEN exp_main_reject_record THEN
        RAISE;
        WHEN OTHERS
          THEN
          p_resp_code := '69';
          p_errmsg :=
               'Problem while updating data into CMS_TRANSACTION_LOG_DTL'
            || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
   END;
   --End for JH-10

   /* Start  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   BEGIN
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
      THEN
         pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                             v_hash_pan,
                                             p_amount,                --p_txn_amt,
                                             v_comb_hash,
                                             v_respcode,
                                             v_respmsg  -- v_errmsg replaced by v_respmsg on 12-Feb-2013
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
/* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */

    --Sn Added for FSS-4647
    BEGIN
       SELECT NVL(cpc_redemption_delay_flag,'N')
         INTO v_redmption_delay_flag
         FROM cms_prod_cattype
        WHERE     cpc_prod_code = v_prod_code
              AND cpc_card_type = v_card_type
              AND cpc_inst_code = p_instcode;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_errmsg := 'Product category not found';
          v_respcode := '21';
          RAISE exp_main_reject_record;
       WHEN OTHERS
       THEN
          v_errmsg :=
             'Error while fetching redemption delay flag from prodcattype: '
             || SUBSTR (SQLERRM, 1, 200);
          v_respcode := '21';
          RAISE exp_main_reject_record;
    END;

    IF  v_txn_redmption_flag='Y'  AND v_redmption_delay_flag='Y'THEN
        BEGIN
           vmsredemptiondelay.redemption_delay (v_acct_number,
                                p_rrn,
                                p_delivery_channel,
                                p_txn_code,
                                v_tran_amt,
                                v_prod_code,
                                v_card_type,
                                UPPER (p_merchant_name),
                                p_merchant_zip,-- added for VMS-622 (redemption_delay zip code validation)
                                v_errmsg);
            IF v_errmsg<>'OK' THEN
                 RAISE  exp_main_reject_record;
            END IF;
        EXCEPTION
           WHEN exp_main_reject_record THEN
             RAISE;
           WHEN OTHERS
           THEN
              v_errmsg :=
                 'Error while calling sp_log_delayed_load: '
                 || SUBSTR (SQLERRM, 1, 200);
              v_respcode := '21';
              RAISE exp_main_reject_record;
        END;
    END IF;
    --En Added for FSS-4647


    IF V_INITIALLOAD_AMT = 0
    then
    	 BEGIN
           UPDATE cms_acct_mast
	      SET CAM_INITIALLOAD_AMT = V_TRAN_AMT
	    WHERE cam_acct_no =v_acct_number
              AND cam_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_errmsg :=
                 'Error while update initial laod amnt in acct mast'
                 || SUBSTR (SQLERRM, 1, 200);
              v_respcode := '12';
              RAISE exp_main_reject_record;
        END;
      END IF;




EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN

   -- Start Added for JH-10
   BEGIN
    --IF (p_reason_code IS NOT NULL)
  --  THEN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
	   
	          v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');

      
IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE cms_transaction_log_dtl
        SET ctd_reason_code = v_reason_code
        , ctd_location_id=p_terminalid
      WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel;
ELSE
      UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
        SET ctd_reason_code = v_reason_code
        , ctd_location_id=p_terminalid
      WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel;
END IF;
      IF SQL%ROWCOUNT = 0 THEN
         V_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
         P_RESP_CODE := '69';
         RAISE exp_main_reject_record;
      END IF;
    --END IF;
      EXCEPTION
        WHEN OTHERS
          THEN
          p_resp_code := '69';
          p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
   END;

   BEGIN
    IF (v_reason_code IS NOT NULL)
    THEN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
        SET  trans_desc = V_TRANS_DESC,
             --reason_code = v_reason_code,
             orgnl_rrn=nvl(p_original_rrn,p_rrn)
      WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND msgtype = p_msg
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
ELSE
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET  trans_desc = V_TRANS_DESC,
             --reason_code = v_reason_code,
             orgnl_rrn=nvl(p_original_rrn,p_rrn)
      WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND msgtype = p_msg
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
END IF;
      IF SQL%ROWCOUNT = 0 THEN
         V_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
         P_RESP_CODE := '69';
         RAISE exp_main_reject_record;
      END IF;
    END IF;
      EXCEPTION
        WHEN OTHERS
          THEN
          p_resp_code := '69';
          p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
   END;
   --End for JH-10

      /*ROLLBACK;

      ---Sn Updation of Usage limit and amount
      BEGIN                                                                        --commented by amit on 28-Jul-2012 to verify limits from limit profile
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan
            AND ctc_mbr_numb = p_mbr_numb;
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
            --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
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
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
                  v_errmsg :=
                        'Error while updating CMS_TRANSLIMIT_CHECK C '
                     || v_hash_pan
                     || ' '
                     || SQLERRM;
                  RAISE exp_main_reject_record;
               END IF;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
                  v_errmsg :=
                        'Error while updating CMS_TRANSLIMIT_CHECK D '
                     || v_hash_pan
                     || ' '
                     || SQLERRM;
                  RAISE exp_main_reject_record;
               END IF;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating 1 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      */
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      --Sn create a entry in txn log
      /*BEGIN
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
                      dni, ipaddress,
                      cardstatus,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                    TRANS_DESC, -- FOR Transaction detail report issue ,
                      MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                        MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                        MERCHANT_STATE  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, p_terminalid,
                      v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (p_amount, '99999999999999999.99')),
                      p_currcode, NULL, v_prod_code, v_card_type,
                      p_terminalid, v_topup_auth_id,
                      TRIM (TO_CHAR (p_amount, '99999999999999999.99')),
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode, p_ani,
                      p_dni, p_ipaddress,
                      v_cap_card_stat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                    V_TRANS_DESC, -- FOR Transaction detail report issue
                     P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '69';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log

      --Sn create a entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delivery_channel, p_txn_code, p_msg,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, p_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      SUBSTR (p_errmsg, 0, 300), p_rrn, p_instcode,
                      v_encr_pan, v_acct_number
                     );

         p_errmsg := v_errmsg;
         RETURN;
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

      p_errmsg := v_errmsg;*/
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no
           INTO v_acct_balance, v_ledger_balance, v_acct_number
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
            v_ledger_balance := 0;
      END;

      ---Sn Updation of Usage limit and amount
      /*BEGIN                                                                    --commented by amit on 28-Jul-2012 to verify limits from limit profile
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan
            AND ctc_mbr_numb = p_mbr_numb;
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
            --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
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
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
                  v_errmsg :=
                        'Error while updating CMS_TRANSLIMIT_CHECK E '
                     || v_hash_pan
                     || ' '
                     || SQLERRM;
                  RAISE exp_main_reject_record;
               END IF;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  --Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
                  v_errmsg :=
                        'Error while updating CMS_TRANSLIMIT_CHECK F '
                     || v_hash_pan
                     || ' '
                     || SQLERRM;
                  RAISE exp_main_reject_record;
               END IF;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating 2 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      */
      --Sn generate auth id
      BEGIN
         --   SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO AUTHID_DATE FROM DUAL;

         --   SELECT AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_topup_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';                            -- Server Declined
      END;

      --En generate auth id

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
            p_resp_code := '69';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      -- RETURN;
      END;

      --Sn create a entry in txn log
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
                      dni, ipaddress,
                      cardstatus,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                    TRANS_DESC, -- FOR Transaction detail report issue
                     MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      time_stamp  ,  --Added for JH-10
      ERROR_MSG,fundingaccount--Added for JH 3012
             ,merchant_zip,orgnl_rrn)-- added for VMS-622 (redemption_delay zip code validation)
              VALUES (p_msg, p_rrn, p_delivery_channel, p_termid_In,
                      v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (p_amount, '99999999999999999.99')),
                      p_currcode, NULL, v_prod_code, v_card_type,
                      p_termid_In, v_topup_auth_id,
                      TRIM (TO_CHAR (p_amount, '99999999999999999.99')),
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode, p_ani,
                      p_dni, p_ipaddress,
                      v_cap_card_stat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                      V_TRANS_DESC, -- FOR Transaction detail report issue
                        P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      null, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      v_time_stamp ,   -- Added for JH-10
        p_errmsg,p_funding_account -- Added for JH 3012
		,p_merchant_zip,nvl(p_original_rrn,p_rrn) );-- added for VMS-622 (redemption_delay zip code validation)
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '69';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log

      --Sn create a entry in cms_transaction_log_dtl
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
                      ctd_reason_code,   --Added for JH-10
                      ctd_hashkey_id     --Added for JH-10
                      ,ctd_location_id
                     )
              VALUES (p_delivery_channel, p_txn_code, p_msg,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, p_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      SUBSTR (p_errmsg, 0, 300), p_rrn, p_instcode,
                      v_encr_pan, v_acct_number,
                      v_reason_code,   --Added for JH-10
                      v_hashkey_id   --Added for JH-10
                      ,p_terminalid
                     );

         p_errmsg := v_errmsg;
         RETURN;
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

      p_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error