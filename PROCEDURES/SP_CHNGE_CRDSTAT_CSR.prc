set define off;
create or replace
PROCEDURE               VMSCMS.SP_CHNGE_CRDSTAT_CSR (
   prm_instcode        IN       NUMBER,
   prm_rrn             IN       VARCHAR2,
   prm_pan_code        IN       VARCHAR2,                               ---PAN
   prm_lupduser        IN       NUMBER,
   prm_txn_code        IN       VARCHAR2,
   prm_delivery_chnl   IN       VARCHAR2,
   prm_msg_type        IN       VARCHAR2,
   prm_revrsl_code     IN       VARCHAR2,
   prm_txn_mode        IN       VARCHAR2,
   prm_mbrnumb         IN       VARCHAR2,
   prm_trandate        IN       VARCHAR2,
   prm_trantime        IN       VARCHAR2,
   prm_rsncode         IN       NUMBER,    -- Added on 18 Nov 2011 - Ganesh S.
   prm_remark          IN       VARCHAR2,  -- Added on 18 Nov 2011 - Ganesh S.
   prm_call_id         IN       VARCHAR2,
   prm_ip_addr         IN       VARCHAR2,       --Added by amit on 20-Sep-2012
   PRM_SCHD_FLAG       in       varchar2,       -- Added for FWR-33 changes
   prm_req_rrn         IN       VARCHAR2,       -- Added for FWR-33 changes
   prm_admin_flag      IN       varchar2,
   prm_resp_code       OUT      VARCHAR2,
   prm_errmsg          OUT      VARCHAR2
)
AS
/****************************************************************************************
     * Created Date      : 13/Jan/2012.
     * Created By        : Sagar More.
     * Purpose           : to chnage card status as per input status and reason
     * modified for      : SSN validations - New CR
     * modified Date     : 08-Feb-2013
     * modified reason   : to check for thresholdlimit before pan generation
     * Reviewer          : Dhiarj
     * Reviewed Date     : 08-Feb-2013
     * Build Number      : CMS3.5.1_RI0023.2_B0001

     * modified by       : Pankaj S.
     * modified for      : FSS-193
     * modified Date     : 15-Feb-2013
     * modified reason   : Closing account with balance

     * modified for      : SSN validations - New CR
     * modified Date     : 19-Feb-2013
     * modified reason   : Response id changed from 157 to 158 on 19-Feb-2013

     * Reviewer          : Dhiarj
     * Reviewed Date     :
     * Build Number      : CMS3.5.1_RI0023.2_B0001

     * modified by       : Pankaj S.
     * modified for      : FSS-391
     * modified Date     : 19-Feb-2013
     * modified reason   : Card replacement functinality
     * Build Number      : CMS3.5.1_RI0023.2_B0007

     * modified by       : Santosh K.
     * modified for      : Defect 0010540
     * modified Date     : 06-Mar-2013
     * modified reason   : To update active date at the time of activation only
     * Reviewer          : Sagar
     * Reviewed Date     : 07-Mar-2013
     * Build Number      : RI0023.2_B0017

     * Modified By      : Pankaj S.
     * Modified Date    : 19-Mar-2013
     * Modified Reason  : Logging of system initiated card status change(FSS-390)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : CSR3.5.1_RI0024_B0007

     * Modified By      : Sagar
     * Modified For     : Defect 10756
     * Modified Date    : 29-Mar-2013
     * Modified Reason  : Size of v_cust_id_ssn variable is change as per CMS_CUST_MAST.CCM_SSN%type
     * Reviewer         : Dhiraj
     * Reviewed Date    : 29-Mar-2013
     * Build Number     : CSR3.5.1_RI0024_B0014

     * Modified By      : Santosh K
     * Modified For     : MVCSD-4074 : Resticted Card Status
     * Modified Date    : 19-APR-2013
     * Modified Reason  : To allow Resticted Card Status
     * Reviewer         : Sagar
     * Reviewed Date    : 19-APR-2013
     * Build Number     :  RI0024.1_B0009

     * Modified By      : Santosh K
     * Modified For     : 0010929 : Allow to Activate Resticted Card
     * Modified Date    : 23-APR-2013
     * Modified Reason  : Allow to Activate Resticted Card
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0010

     * Modified By      : Dnyaneshwar J
     * Modified For     : CR 073 Medagate changes
     * Modified Date    : 18-June-2013
     * Modified Reason  : new tramsaction code added for Expired card status change
     * Build Number     : RI0024.2_B0005

     * Modified By      : Dnyaneshwar J
     * Modified For     : MVCSD-4125
     * Modified Date    : 16-July-2013
     * Modified Reason  : new tramsaction code added for Spend Down status change
     * Build Number     : RI0024.3_B0005

     * Modified By      : Dnyaneshwar J
     * Modified For     : Mantis-0011849 Defect: Incomm : 'Card Status update to Closed' Transaction Type display
                          in Account Activity tab while doing the Card Activation
     * Modified Date    : 30-July-2013
     * Modified Reason  : Always (in case of Starter and GPR card) case while activation of GPR card,
                          Starter card get closed and entry get logged in transactionlog
     * Build Number     : RI0024.3_B0008

     * Modified By      : Dnyaneshwar J
     * Modified For     : MVCSD-4104 :
     * Modified Date    : 07-Aug-2013
     * Modified Reason  : Add new transaction to change card status from other than Inactive to Inactive Card status
     * Build Number     : RI0024.4_B0002

     * Modified By      : Abhay R
     * Modified For     : MVCSD-4099 :
     * Modified Date    : 26-Aug-2013
     * Modified Reason  : Durbin Changes
     * Build Number     : RI0024.4_B0004

     * Modified By      : Sagar M.
     * Modified For     : FWR-33
     * Modified Date    : 26-Aug-2013
     * Modified Reason  : To restrict call id logging based on prm_schd_flag varible
     * Build Number     : RI0024.4_B0004

     * Modified By      : Santosh K
     * Modified For     : Code Review Chanegs FWR-33
     * Modified Date    : 29-Aug-2013
     * Modified Reason  : Changes done as per review comments from DB Team
     * Build Number     : RI0024.4_B0006

     * Modified By      : Dnyaneshwar J
     * Modified For     : FSS-1655 and FSS-1656
     * Modified Date    : 20-May-2014
     * Build Number     : RI0027.1.6_B0002

     * Modified By      : Dnyaneshwar J
     * Modified For     : FSS-1655 FSS-1656 integration
     * Modified Date    : 26-May-2014
     * Build Number     : RI0027.1.6.1

     * Modified By      : MAGESHKUMAR S
     * Modified For     : FSS-2125
     * Modified Date    : 25-AUGUST-2015
     * Modified Reason  : Changes done for allowing GPR card status change
     * Build Number     : VMSGPRHOSTCSD3.1_B0005

     * Modified By      : Siva Kumar M
     * Modified For     : FSS-2279(MVCSD-5614)
     * Modified Date    : 26-AUGUST-2015
     * Modified Reason  : Changes done for accounts close while card close
     * Build Number     : VMSGPRHOSTCSD3.1_B0006

     * Modified By      : Siva Kumar M
     * Modified Date    : 09-September-2015
     * Modified Reason  : Review Changes
     * Build Number     : VMSGPRHOSTCSD3.1_B0010

     * Modified By      : Siva Kumar M
     * Modified Date    : 24-Sep-2015
     * Modified Reason  : Card Status changes
     * Reviewer         : Saravana kumar
     * Reviewed Date    : 25-Sep-2015
     * Build Number     : VMSGPRHOSTCSD3.2_B0002

      * Modified by           : Abdul Hameed M.A
      * Modified Date         : 07-Sep-15
      * Modified For          : FSS-3509 & FSS-1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2

      * Modified By      : Siva Kumar M
     * Modified Date    : 27-Nov-2015
     * Modified Reason  : Review Changes
     * Build Number     : VMSGPRHOSTCSD3.2.1_B0001

     * Modified by        : Spankaj
    * Modified Date     : 23-Dec-15
    * Modified For      : FSS-3925
    * Reviewer             : Saravanankumar
    * Build Number      : VMSGPRHOSTCSD3.3

    * Modified by                  : MageshKumar S.
    * Modified Date                : 29-DECEMBER-15
    * Modified For                 : FSS-3506
    * Modified reason              : ALERTS TRANSFER
    * Reviewer                     : SARAVANAKUMAR/SPANKAJ
    * Build Number                 : VMSGPRHOSTCSD3.3_B0002

    * Modified by      : Siva Kumar M
    * Modified Date    : 02-Mar-2016
    * Modified for     : Addition of New Card Status Fraud Hold
    * Reviewer         : Saravanakumar
    * Build Number     : VMSGPRHOSTCSD_4.0


       * Modified by       :Siva kumar
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

    * Modified By                  : MageshKumar S.
    * Modified For                 : FSS-4416 & MANTIS iD:16403
    * Purpose                      : Existing Damaged card closed issue
    * Release Number               : VMSGPRHOSTCSD4.2_B0002

     * Modified By          :  Pankaj S.
     * Modified Date      :  13-Sep-2016
     * Modified Reason  : Modified for 4.2.2 changes
     * Reviewer              : Saravanakumar
     * Build Number      :   4.2.2

    * Modified by          : Pankaj S.
    * Modified Date        : 23-May-17
    * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.05

    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

        * Modified By      :Vini
    * Modified Date    : 15-DEc-2017
    * Purpose          : VMS-103
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST17.12

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2017
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
    * Modified By      : Venkata Naga Sai S
    * Modified Date    : 05-SEP-2019
    * Modified For     : VMS-1067
    * Reviewer         : Saravanakumar
    * Release Number   : R20
	
	* Modified By      : Baskar Krishnan
    * Modified Date    : 02-MAR-2020
    * Modified For     : VMS-1885
    * Reviewer         : Saravanakumar
    * Release Number   : R27
    
    * Modified By      : Ubaidur 
    * Modified Date    : 26-APR-2021
    * Modified For     : VMS-3983 - Funding on Activation.
    * Reviewer         : Saravanakumar
    * Release Number   : R45
	
	* Modified By      : Ubaidur 
    * Modified Date    : 11-JUN-2021
    * Modified For     : BREAK FIX VMS-4634 - Card Status to Lost Stolen 
									is returning error as Card Is Activated for B2B Card Created with Fund on Activation config
    * Reviewer         : Saravanakumar
    * Release Number   : R46.2
    
    * Modified By      : Puvanesh. N
    * Modified Date    : 07-JUL-2021
    * Purpose          : VMS-4728 Funding on Activation for Replace Inactive Cards
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST48.1
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
	
	  * Modified By      : John Gingrich
    * Modified Date    : 7-20-2022
    * Purpose          : Instant Inactivity Fee
    * Reviewer         :
    * Release Number   : R66 for VMS-6072/FSP-1536
 ******************************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_req_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_topup_auth_id          transactionlog.auth_id%TYPE;
   v_spprt_key              cms_spprt_reasons.csr_spprt_key%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_base_curr              cms_bin_param.cbp_param_value%TYPE;
   v_remrk                  transactionlog.remark%TYPE;
   -- Changed by sagar on 10 Aug 2012
   v_isprepaid              BOOLEAN                             DEFAULT FALSE;
   v_cap_cafgen_flag        CHAR (1);
   v_rrn_count              NUMBER;
--   v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
--   v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     DATE;
   v_tran_date              DATE;
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance           NUMBER;
   v_ledger_balance         NUMBER;
   v_resp_cde               VARCHAR2 (2);
   /* variables added for call log info   start */
   v_table_list             VARCHAR2 (2000);
   v_colm_list              VARCHAR2 (2000);
   v_colm_qury              VARCHAR2 (2000);
   v_old_value              VARCHAR2 (2000);
   v_new_value              VARCHAR2 (2000);
   v_call_seq               NUMBER (3);
/* variables added for call log info   END */
   v_card_appl_stat         cms_cardissuance_status.ccs_card_status%TYPE;
   -- added for returned mail application status check
   v_starter_card           cms_appl_pan.cap_pan_code%TYPE;
   v_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
   v_startercard_found      cms_appl_pan.cap_startercard_flag%TYPE;
   V_REASON                 CMS_SPPRT_REASONS.CSR_REASONDESC%type;
   -- v_spnd_acctno            cms_appl_pan.cap_acct_no%TYPE;                   --Changes done as per review comments from DB Team : Commneted v_spnd_acctno
   -- ADDED BY GANESH ON 19-JUL-12
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   -- added on 17-Sep-2012 by sagar to log in Txnlog table
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   -- Added by sagar on 25SEP2012
   v_profile_level          NUMBER (2);        -- Added by sagar on 25SEP2012
   v_cap_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
   -- Added by sagar on 25SEp2012
   v_cap_prfl_levl          cms_appl_pan.cap_prfl_levl%TYPE;
   -- Added by sagar on 25SEp2012
   v_cap_cust_code          cms_appl_pan.cap_cust_code%TYPE;
   --added for active unregistered on 25-Sep-12 by amit
   v_ccm_kyc_flag           cms_cust_mast.ccm_kyc_flag%TYPE;
   --added for active unregistered on 25-Sep-12 by amit
   v_saletxn_cnt            NUMBER;
   --added for active unregistered on 25-Sep-12 by amit
   v_cap_firsttime_topup    cms_appl_pan.cap_firsttime_topup%TYPE;
   -- Added by Sagar on 01-Oct-2012 to update flag as 'Y' when its a GPR card
   --v_ssn                    cms_caf_info_entry.cci_ssn%TYPE;                  --Commented on 29-Apr-2013 for Defect 10756
   v_ssn                    cms_cust_mast.ccm_ssn%TYPE;                         --Added on 29-Apr-2013 for Defect 10756
   v_ssn_crddtls            VARCHAR2 (4000);
   v_exiting_appl_stat      NUMBER (2);
   v_new_appl_stat          NUMBER (2);
   v_exiting_card_stat      NUMBER (2);
   v_new_card_stat          NUMBER (2);
   --Sn Added by Pankaj S. on 15-Feb-2013 for FSS-193
   v_dcount                 NUMBER (3);
   v_ccount                 NUMBER (3);
   v_savngledgr_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   --En Added by Pankaj S. on 15-Feb-2013 for FSS-193
   --Sn Added by Pankaj S. on 13-Feb-2013 for Card replacement changes(FSS-391)
   v_dup_check              NUMBER (3);
   v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;
  --En Added by Pankaj S. on 13-Feb-2013 for Card replacement changes(FSS-391)
  --Sn Added by Pankaj S. for FSS-390
  v_crd_no                 cms_appl_pan.cap_pan_code%TYPE;
  v_crd_encr            cms_appl_pan.cap_pan_code_encr%TYPE;
  v_crdstat_chnge           VARCHAR2(2):='N';
  --En Added by Pankaj S. for FSS-390
    V_TRAN_AMT                  NUMBER; 
   v_cap_pin_flag     VARCHAR2(1):='N';-- Added by abhay for MVCSD-4099

   v_saving_acct_no    cms_acct_mast.cam_acct_no%TYPE;
   v_SPEND_ACCT_BAL    cms_acct_mast.cam_ledger_bal%TYPE DEFAULT 0;

   v_delivery_channel  cms_transaction_mast.CTM_DELIVERY_CHANNEL%TYPE  DEFAULT '05';
   v_txn_code          cms_transaction_mast.CTM_TRAN_CODE%TYPE;
  
   v_chkcurr              cms_bin_param.cbp_param_value%TYPE;
   v_prod_type         cms_product_param.cpp_product_type%type; --Added for 4.2.2 changes
   l_pin_applicable_flag    cms_prod_cattype.cpc_pin_applicable%type;
   l_b2b_enabled_flag       cms_prod_cattype.cpc_b2b_flag%type;
   v_profile_code           cms_prod_cattype.cpc_profile_code%type;
   v_user_type              cms_prod_cattype.CPC_USER_IDENTIFY_TYPE%type;
   v_riskinvest_time        NUMBER;
   v_defund_flag        cms_acct_mast.cam_defund_flag%type;
    
   v_order_prod_fund        vms_order_lineitem.VOL_PRODUCT_FUNDING%type;
   v_lineitem_denom          vms_order_lineitem.Vol_Denomination%type;
   v_prod_fund		     cms_prod_cattype.cpc_product_funding%type;
   v_fund_amt             CMS_PROD_CATTYPE.CPC_FUND_AMOUNT%TYPE;
   v_order_fund_amt        vms_order_lineitem.VOL_FUND_AMOUNT%TYPE;
   v_cap_active_date        CMS_APPL_PAN.CAP_ACTIVE_DATE%TYPE;
   V_ACTIVECARD_COUNT		PLS_INTEGER;
   V_INITIALLOAD_AMOUNT	    CMS_ACCT_MAST.CAM_INITIALLOAD_AMT%TYPE;
   VOD_REPL_ORDER          VMS_ORDER_LINEITEM.VOL_ORDER_ID%TYPE;
   V_PARAM_VALUE           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
V_TOGGLE_VALUE VARCHAR2(50); --Added for VMS-6072
V_COUNT NUMBER; --Added for VMS-6072
BEGIN
   --<<MAIN BEGIN >>
   prm_errmsg := 'OK';
   v_txn_code := prm_txn_code;
   v_respcode := '1';
   v_errmsg := 'OK';

   IF prm_remark IS NULL
   THEN
      v_remrk := 'CSR Card Status Change';
   ELSE
      v_remrk := prm_remark;
   END IF;

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (prm_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';                             -- added by chinmaya
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN
   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (prm_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';                             -- added by chinmaya
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create encr pan
   
      --Sn select Pan detail
   BEGIN
      SELECT cap_prod_catg, cap_card_stat, cap_prod_code, cap_card_type,
             cap_proxy_number, cap_acct_no, cap_startercard_flag,
             cap_prfl_code,                     -- Added by sagar on 25SEp2012
                           cap_prfl_levl,       -- Added by sagar on 25SEp2012
                                         cap_cust_code,
             -- Added by amit on 25-Sep2-12 for active unregistered
             cap_firsttime_topup,
             decode(cap_pin_off,null,'N','Y'),cap_active_date-- Added by abhay for MVCSD-4099
        -- Added by Sagar on 01-Oct-2012 to update flag as 'Y' when its a GPR card
      INTO   v_cap_prod_catg, v_cap_card_stat, v_prod_code, v_card_type,
             v_proxunumber, v_acct_number, v_startercard_flag,
             v_cap_prfl_code,                   -- Added by sagar on 25SEp2012
                             v_cap_prfl_levl,   -- Added by sagar on 25SEp2012
                                             v_cap_cust_code,
             -- Added by amit on 25-Sep2-12 for active unregistered
             v_cap_firsttime_topup,
             v_cap_pin_flag,v_cap_active_date-- Added by abhay for MVCSD-4099
        -- Added by Sagar on 01-Oct-2012 to update flag as 'Y' when its a GPR card
      FROM   cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = prm_instcode
         AND cap_mbr_numb = prm_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Card not found in master ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting card number '
            || v_hash_pan
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   BEGIN
          SELECT cpc_profile_code, nvl(CPC_USER_IDENTIFY_TYPE,'0'),decode(nvl(CPC_USER_IDENTIFY_TYPE,'0'),'1','N','4','N',NVL(CPC_PIN_APPLICABLE,'N')),NVL(CPC_B2B_FLAG,'N'),cpc_product_funding,cpc_fund_amount
          INTO v_profile_code, v_user_type,l_pin_applicable_flag,l_b2b_enabled_flag,v_prod_fund,v_fund_amt
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE = v_prod_code
          AND CPC_CARD_TYPE = v_card_type
          AND CPC_INST_CODE=prm_instcode;
          EXCEPTION
          WHEN OTHERS THEN
           v_respcode := '21';
           v_errmsg :='Error while getting Profile -' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
          END;

   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal,nvl(cam_defund_flag,'N'),NVL(CAM_NEW_INITIALLOAD_AMT,CAM_INITIALLOAD_AMT)
            INTO v_acct_balance, v_ledger_balance,v_defund_flag,V_INITIALLOAD_AMOUNT
            from CMS_ACCT_MAST
           WHERE cam_acct_no = v_acct_number 
             AND cam_inst_code = prm_instcode
	     FOR UPDATE;
   EXCEPTION   
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
               'Error while selecting data from card Master for card number '
            || v_hash_pan
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;
   --Sn find debit and credit flag
   
   BEGIN
    SELECT
        NVL(CIP_PARAM_VALUE,'N')
    INTO V_PARAM_VALUE
    FROM
        CMS_INST_PARAM
    WHERE
        CIP_PARAM_KEY = 'VMS_4728_TOGGLE'
        AND CIP_INST_CODE = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_PARAM_VALUE := 'N';
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            V_ERRMSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;

   --- Modified for BREAK FIX VMS-4634

    IF v_acct_balance = 0 AND v_cap_card_stat = '0' AND 
    	v_cap_active_date IS NULL AND v_txn_code = '74'
	
    THEN 
    
        BEGIN
              SELECT To_Number(Nvl(lineitem.Vol_Denomination,'0')),lineitem.VOL_PRODUCT_FUNDING,lineitem.VOL_FUND_AMOUNT,UPPER(SUBSTR(VOL_ORDER_ID,1,4))
              INTO v_lineitem_denom,v_order_prod_fund,v_order_fund_amt,VOD_REPL_ORDER
              FROM
                vms_line_item_dtl detail,
                vms_order_lineitem lineitem
              WHERE
               detail.VLI_ORDER_ID= lineitem.vol_order_id
              AND detail.VLI_PARTNER_ID=lineitem.VOL_PARTNER_ID
              AND detail.VLI_LINEITEM_ID = lineitem.VOL_LINE_ITEM_ID
              AND detail.vli_pan_code  = V_HASH_PAN;
	      
	  ---    v_order_prod_fund = 1 / 'Load on Order'
	  ---    v_order_prod_fund = 2 / 'Load on Activation'
	      
	      		IF v_order_prod_fund is null THEN
        		v_order_prod_fund := v_prod_fund ;	
                v_order_fund_amt  := v_fund_amt;	
        		END IF;
        
        
        --- Modified for BREAK FIX VMS-4634 
        
                    IF (v_order_prod_fund = 1 and v_defund_flag = 'Y') 
		    		OR (v_order_prod_fund = 2 AND v_order_fund_amt =1 )
	                THEN
                    
                    IF V_LINEITEM_DENOM = 0 AND VOD_REPL_ORDER = 'ROID' AND V_PARAM_VALUE = 'N' THEN

						SELECT
							COUNT(1)
						INTO V_ACTIVECARD_COUNT
						FROM
							CMS_APPL_PAN
						WHERE
							CAP_INST_CODE = prm_instcode
							AND CAP_ACCT_NO = V_ACCT_NUMBER
							AND CAP_ACTIVE_DATE IS NOT NULL;

						IF V_ACTIVECARD_COUNT = 0 THEN
						
							IF NVL(V_INITIALLOAD_AMOUNT,0) = 0 THEN
							
								SELECT TO_NUMBER(NVL(LINEITEM.VOL_DENOMINATION,'0'))
								  INTO V_LINEITEM_DENOM
								  FROM
									VMS_LINE_ITEM_DTL DETAIL,
									VMS_ORDER_LINEITEM LINEITEM,
									CMS_APPL_PAN PAN
								  WHERE
								   DETAIL.VLI_ORDER_ID= LINEITEM.VOL_ORDER_ID
								  AND DETAIL.VLI_PARTNER_ID=LINEITEM.VOL_PARTNER_ID
								  AND DETAIL.VLI_LINEITEM_ID = LINEITEM.VOL_LINE_ITEM_ID
								  AND DETAIL.VLI_PAN_CODE  = PAN.CAP_PAN_CODE
								  AND PAN.CAP_ACCT_NO = V_ACCT_NUMBER
								  AND CAP_INST_CODE = PRM_INSTCODE
								  AND NVL(LINEITEM.VOL_DENOMINATION,'0') <> '0';
							ELSE		
								V_LINEITEM_DENOM := V_INITIALLOAD_AMOUNT;
							END IF;
							
						ELSE
							V_LINEITEM_DENOM := 0;
						END IF;

					END IF;
                    
	                 V_TRAN_AMT := v_lineitem_denom;
                     
                     IF V_TRAN_AMT > 0 THEN
	                 v_txn_code := '64';
                     END IF;
                     
	                END IF;

   	EXCEPTION
	    WHEN NO_DATA_FOUND 
	    THEN 
	    NULL;
            WHEN OTHERS
            THEN
             v_respcode := '12';
                     v_errmsg :=
                           'Error while selecting denomination details -  '
                        || v_hash_pan
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE exp_main_reject_record;
        END; 
        
    END IF;
   
   
   
   BEGIN
      SELECT ctm_tran_desc, ctm_credit_debit_flag
        INTO v_trans_desc, v_cr_dr_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = v_txn_code
         AND ctm_delivery_channel = prm_delivery_chnl
         AND ctm_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '12';                         --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || v_txn_code
            || ' and delivery channel '
            || prm_delivery_chnl;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';                         --Ineligible Transaction
         v_respcode := 'Error while selecting transaction details';
         RAISE exp_main_reject_record;
   END;

   --Sn Duplicate RRN Check
   BEGIN
   
   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = prm_instcode
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND delivery_channel = prm_delivery_chnl
         AND txn_code = v_txn_code
         AND business_date = prm_trandate
         AND business_time = prm_trantime;
     else
         SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE instcode = prm_instcode
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND delivery_channel = prm_delivery_chnl
         AND txn_code = v_txn_code
         AND business_date = prm_trandate
         AND business_time = prm_trantime;
      end if;   

      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || prm_rrn;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'while cheking for duplicate RRN '
            || prm_rrn
            || ' '
            || SUBSTR (SQLERRM, 1, 100);
         v_respcode := '32';
         RAISE exp_main_reject_record;
   END;

   --En Duplicate RRN Check
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (prm_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_trantime), 1, 10),
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


--   IF v_txn_code IN  ('86', '74')  --'74' added by amit on 25-Sep-2012 for active unregistered
--   THEN
   --Sn Added by Pankaj S. on 19-Feb-2013 for damage card replacement changes (FSS-391)
   BEGIN
      IF v_cap_card_stat = '3'
      THEN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = prm_instcode
            AND chr_pan_code = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF v_dup_check > 0 AND v_txn_code <> '83'
         THEN
            v_errmsg := 'Only closing operation allowed for damage card';
            v_respcode := '160';
            RAISE exp_main_reject_record;
         END IF;
      ELSE
         SELECT chr_pan_code,chr_pan_code_encr
           INTO v_oldcrd,v_crd_encr
           FROM cms_htlst_reisu
          WHERE chr_inst_code = prm_instcode
            AND chr_new_pan = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_pan_code IS NOT NULL;

         BEGIN
            UPDATE cms_appl_pan
               SET cap_card_stat = '9'
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_oldcrd
             and cap_card_stat <> '3';--Added by Dnyaneshwar J on 30 July 2013 Mantis-0011849  --modified for FSS-1655 --Modified for FSS-4416

            IF SQL%ROWCOUNT != 1
            THEN
              NULL;
            ELSE
               --v_errmsg :='Problem in updation of status for old damage card';--sn Commented by Dnyaneshwar J on 30 July 2013 Mantis-0011849
               --v_respcode := '89';      --need to configure new response code
             --RAISE exp_main_reject_record;
             --END IF;
             --Sn added on 19_Mar_2013 for FSS-390--en Commented by Dnyaneshwar J on 30 July 2013 Mantis-0011849
                v_crdstat_chnge:='Y';
                v_crd_no:=v_oldcrd;
            END IF;--Added by Dnyaneshwar J on 30 July 2013 Mantis-0011849
             --En added on 19_Mar_2013 for FSS-390
         END;

          --Sn commented here & used down for FSS-1656
          /*IF v_txn_code = '74' THEN
                BEGIN
                   SELECT COUNT (1)
                     INTO v_dup_check
                     FROM cms_appl_pan
                    WHERE cap_inst_code = prm_instcode
                      AND cap_acct_no = v_acct_number
                      --AND cap_pan_code <> v_hash_pan
                      AND cap_card_stat IN ('0', '1', '2', '5', '6', '8', '12');

                   IF v_dup_check <> 1 THEN
                      v_errmsg := 'Card is not allowed for activation';
                      v_respcode := '89';   --need to carnew response code
                      RAISE exp_main_reject_record;
                   END IF;
                END;
           END IF;*/
           --Sn commented here & used down for FSS-1656
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting damage card details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   --En Added by Pankaj S. on 19-Feb-2013 for damage card replacement changes(FSS-391)
   BEGIN
      SELECT ccs_card_status
        INTO v_card_appl_stat
        FROM cms_cardissuance_status
       WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Application status not found in master ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting application status '
            || v_hash_pan
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   IF v_txn_code <> '83'
   THEN
     IF  prm_admin_flag IS NOT NULL  AND prm_admin_flag <> 'Y' THEN

      IF v_card_appl_stat NOT IN ('15', '31')
      THEN
         v_respcode := '146';
         v_errmsg := 'Card Not In Shipped Status';
         RAISE exp_main_reject_record;
      END IF;

     END IF;
   END IF;

   --END IF;

   --fOR REPORTS
   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal
            INTO v_acct_balance, v_ledger_balance
            from CMS_ACCT_MAST
           WHERE cam_acct_no = v_acct_number        -- Changes done as per review comments from DB Team : Removed inner query to get account number
             AND cam_inst_code = prm_instcode
     -- FOR UPDATE NOWAIT; --Commented for FSS-2125 of 3.1 release
      FOR UPDATE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '14';                         --Ineligible Transaction
         v_errmsg :=
               'balance not found for card '
            || v_hash_pan
            || ' and mbr numb '
            || prm_mbrnumb;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
               'Error while selecting data from card Master for card number '
            || v_hash_pan
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;


  --En select Pan detail
   BEGIN
      SELECT trim(cbp_param_value)
        INTO v_base_curr
        FROM cms_bin_param
       WHERE cbp_inst_code = prm_instcode AND cbp_param_name = 'Currency'
       and cbp_profile_code = v_profile_code ;

      IF v_base_curr IS NULL
      THEN
         v_errmsg := 'Base currency cannot be null ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record              -- this block added by chinmaya
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Base currency is not defined for the bin profile';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting base currency for bin  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn Added by Pankaj S. on 15-Feb-2013 for closing account with balance FSS-193
   IF v_txn_code = '83'
   THEN
      BEGIN
         SELECT COUNT (1)
           INTO v_ccount
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_instcode
            AND cap_acct_no = v_acct_number
            AND cap_card_stat IN ('0', '1', '2', '3', '5', '6', '8', '12');

         IF v_ccount = 1
         THEN
           /* IF v_acct_balance = 0 AND v_ledger_balance = 0
            THEN
               BEGIN
                  SELECT cam_ledger_bal
                    INTO v_savngledgr_bal
                    FROM cms_cust_acct, cms_acct_mast
                   WHERE cca_inst_code = cam_inst_code
                     AND cca_acct_id = cam_acct_id
                     AND cam_type_code = 2
                     AND cca_inst_code = prm_instcode
                     AND cca_cust_code = v_cap_cust_code;

                  IF v_savngledgr_bal <> 0
                  THEN
                     v_errmsg :=
                        'To Close card saving account ledger balance should be 0';
                     v_respcode := '161';
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                 -- SN :Changes done as per review comments from DB Team : Handled user defined exception
                  WHEN exp_main_reject_record
                  THEN
                    RAISE;
                 -- EN :Changes done as per review comments from DB Team : Handled user defined exception
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
               END;
            ELSE
               v_errmsg :=
                  'To Close card spending account available null balance should be 0';
               v_respcode := '161';
               RAISE exp_main_reject_record;
            END IF; */

            BEGIN

                      SELECT cam_ledger_bal,CAM_ACCT_NO
                            INTO v_savngledgr_bal,v_saving_acct_no
                            FROM cms_cust_acct, cms_acct_mast
                           WHERE cca_inst_code = cam_inst_code
                             AND cca_acct_id = cam_acct_id
                             AND cam_type_code = 2
                             AND cca_inst_code = prm_instcode
                             AND cca_cust_code = v_cap_cust_code
                             AND cam_stat_code <>2;


                     SP_CLOSE_SAVINGS_ACCT( prm_instcode,
                                                  prm_pan_code,
                                                  v_saving_acct_no,
                                                  v_delivery_channel,
                                                  '40',
                                                  prm_rrn,
                                                  prm_txn_mode,
                                                  prm_trandate,
                                                  prm_trantime,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  prm_instcode,
                                                  v_base_curr,
                                                  prm_revrsl_code,
                                                  prm_msg_type,
                                                  prm_mbrnumb,
                                                  NULL,
                                                  v_respcode,
                                                  v_respmsg ,
                                                  v_SPEND_ACCT_BAL);


                        IF v_respcode <> '00' AND v_respmsg <> 'OK'
                             THEN
                                  v_errmsg := v_respmsg;
                                  RAISE exp_main_reject_record;

                        ELSE
                          COMMIT;
                         v_errmsg  := 'Savings Account Closed Successfully and ';
                         END IF;



            EXCEPTION
             WHEN exp_main_reject_record THEN
               RAISE;
             WHEN NO_DATA_FOUND THEN
                NULL;
              END;

          IF  v_SPEND_ACCT_BAL > 0  THEN

                      v_errmsg := v_errmsg||
                          'To Close card spending account available  balance should be 0';
                       v_respcode := '161';
                       RAISE exp_main_reject_record;
          ELSIF v_acct_balance <> 0 AND v_ledger_balance <> 0 THEN

                       v_errmsg := 'To Close card spending account available  balance should be 0';
                       v_respcode := '161';
                       RAISE exp_main_reject_record;

          ELSE

               BEGIN

                UPDATE cms_acct_mast set CAM_STAT_CODE='2'
                WHERE cam_acct_no = v_acct_number
                AND cam_inst_code = prm_instcode;

                 IF  SQL%ROWCOUNT =0 THEN
                  v_errmsg := 'exception while updating spending account status';
                       v_respcode := '21';
                       RAISE exp_main_reject_record;


                 END IF;
               EXCEPTION
                WHEN  exp_main_reject_record THEN
                RAISE ;
                WHEN OTHERS  THEN

                    v_errmsg := 'exception while updating spending account status';
                       v_respcode := '21';
                       RAISE exp_main_reject_record;
                END;
          END IF;

         END IF;
      END;
   END IF;

   --En Added by Pankaj S. on 15-Feb-2013 for closing account with balance FSS-193

 /*  --En select Pan detail
   BEGIN
      SELECT cip_param_value
        INTO v_base_curr
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'CURRENCY';

      IF TRIM (v_base_curr) IS NULL
      THEN
         v_errmsg := 'Base currency cannot be null ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record              -- this block added by chinmaya
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Base currency is not defined for the institution ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting bese currecy  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   */

   BEGIN
      SELECT DECODE (v_txn_code,
                     '75', 'HTLST',
                     '78', 'HTLST',
                     '79','CARDEXPIRED',--added for EXPIRED CARD by Dnyaneshwar J on 18 June 2013 for CR 073
                     '80','SPENDDOWN',--added for Spend Down by Dnyaneshwar J on 16 July 2013 for MVCSD-4125
                     '81','CARDINACTIVE',--added for Inactive card by Dnyaneshwar J on 07 Aug 2013 for MVCSD-4104

                     -- Added by sagar to separate txn codes for CARD LOST and STOLEN
                     '76', 'BLOCK',
                     '77', 'DBLOK',
                     '83', 'CARDCLOSE',
                     '05', 'BLOCK',
                     '06', 'DEBLOCK',
                     '74', 'CARDACTIVE',
                     '64', 'CARDACTIVE',
                     '15', 'DHTLST',
                     '84', 'MONITORED',
                     '85', 'HOTCARDED',
                     '86', 'RETMAIL',
                     '87', 'RESTRICT',       -- Added by Santosh K for MVCSD-4074 : Resticted Card Status
                     '46', 'PRNTPENDNG',
                     '47', 'PRINTSENT',
                     '48', 'SHIPPED',
                     '49', 'ADDVERIQUE',
                     '50', 'KYCFAIL',
                     '51', 'FRAUDHOLD',
                     -- SN - Added for FSAPI-GPP changes
                     '61', 'BADCREDIT',
                     '62', 'CARDONHOLD',
                     '82', 'CONSUMED',
                     '99', 'RISKINVEST'
                     -- EN - Added for FSAPI-GPP changes
                    )
        INTO v_spprt_key
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';                                          --added
         v_errmsg :=
               'Error while selecting spprt key   for txn code'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   IF prm_rsncode IS NULL
   THEN
      BEGIN
         SELECT csr_spprt_rsncode, csr_reasondesc
           INTO v_resoncode, v_reason
           FROM cms_spprt_reasons
          WHERE csr_spprt_key = v_spprt_key
            AND csr_inst_code = prm_instcode
            AND ROWNUM < 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '21';                                       --added
            v_errmsg := 'Change status reason code not present in master';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';                                       --added
            v_errmsg :=
                  'Error while selecting reason code from master'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   ELSE
      v_resoncode := prm_rsncode;

      BEGIN
         --added by sagar on 19-Jun-2012 for reasioin desc logging in txnlog table
         SELECT csr_reasondesc
           INTO v_reason
           FROM cms_spprt_reasons
          WHERE csr_spprt_rsncode = v_resoncode
            AND csr_inst_code = prm_instcode;
      --    AND ROWNUM < 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '21';                                       --added
            v_errmsg :=
                  'reason code not found in master for reason code '
               || v_resoncode;
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';                                       --added
            v_errmsg :=
                  'Error while selecting reason description'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   IF     v_txn_code = '75'
      AND v_cap_card_stat = '2'            -- changed from 4 to 2 on 16FEB2012
   THEN
      v_respcode := '41';                                             --added
      v_errmsg := 'Card Already Lost-Stolen';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '78'
-- Added by Sagar on 20-Jun-2012 to separate txn code for CARD LOST and STOLEN
      AND v_cap_card_stat = '3'
   THEN
      v_respcode := '41';
      v_errmsg := 'Card Already Damaged';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '83' AND v_cap_card_stat = '9'
   THEN
      v_respcode := '46';
      v_errmsg := 'Card Already Closed';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '51' AND v_cap_card_stat = '15'
   THEN
      V_RESPCODE := '258';
      v_errmsg := 'Card Already Fraud Hold';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code IN ('74','64') AND v_cap_card_stat IN ('1', '13')  -- Changes done as per review comments from DB Team : Removed Card Status 4
   THEN
      IF v_cap_card_stat = 1
      --added by amit on 25-Sep-12 for active unregistered
      THEN
         v_respcode := '9';
         v_errmsg := 'Card Already Activated';
         RAISE exp_main_reject_record;
      ELSIF v_cap_card_stat = '13'
      THEN
         v_respcode := '142';
         v_errmsg := 'Card Is Already in Active Unregistered status';
         RAISE EXP_MAIN_REJECT_RECORD;

      --Sn: Commented by Santosh K for 0010929 : Allow to Activate Resticted Card
        /* ELSIF v_cap_card_stat = '4' and NVL (v_startercard_flag, 'N') = 'Y'
          then
            V_RESPCODE := '10';
            V_ERRMSG := 'Restricted Card Status can not be change to Active Unregistered';
            RAISE EXP_MAIN_REJECT_RECORD;
         */
       --En: Commented by Santosh K for 0010929 : Allow to Activate Resticted Card

      END IF;
   END IF;

   IF v_txn_code = '05' AND v_cap_card_stat = '6'
   THEN
      v_respcode := '11';
      v_errmsg := 'Card already blocked';
      RAISE exp_main_reject_record;
   END IF;

   --Sn: Added for Monitored status 22Feb2012
   IF v_txn_code = '84' AND v_cap_card_stat = '5'
   THEN
      v_respcode := '18';
      v_errmsg := 'Card Already monitored';
      RAISE exp_main_reject_record;
   END IF;

   --En: Added for Monitored status 22Feb2012

   --Sn: Added for Hotcarded status 22Feb2012
   IF v_txn_code = '85' AND v_cap_card_stat = '11'
   THEN
      v_respcode := '19';
      v_errmsg := 'Card Already hotcarded';
      RAISE exp_main_reject_record;
   END IF;

   --En: Added for Hotcarded status 22Feb2012

   --Sn: Added for returned mail status 27Feb2012
   IF v_txn_code = '86' AND v_card_appl_stat = '16'
   THEN
      v_respcode := '20';
      v_errmsg := 'Application status for card is already returned mail';
      RAISE exp_main_reject_record;
   END IF;

      IF v_txn_code = '46' AND v_card_appl_stat = '2'
   THEN
      v_respcode := '253';
      v_errmsg := 'Application status Already Printer Pending';
      RAISE exp_main_reject_record;
   END IF;


      IF v_txn_code = '47' AND v_card_appl_stat = '3'
   THEN
      v_respcode := '254';
      v_errmsg := 'Application status Already Printer Sent';
      RAISE exp_main_reject_record;
   END IF;
  /*
    IF v_txn_code = '48' AND v_card_appl_stat = '14'
   THEN
      v_respcode := '255';
      v_errmsg := 'Application status Already Printer received';
      RAISE exp_main_reject_record;
   END IF;
   */

    IF v_txn_code = '48' AND v_card_appl_stat = '15'
      THEN
      v_respcode := '255';
      v_errmsg := 'Application status Already Shipped';
      RAISE exp_main_reject_record;
   END IF;

     IF v_txn_code = '49' AND v_card_appl_stat = '17'   THEN
      v_respcode := '256';
      v_errmsg := 'Application status Already Address Verification Queue';
      RAISE exp_main_reject_record;
   END IF;

     IF v_txn_code = '50' AND v_card_appl_stat = '31'
   THEN
      v_respcode := '257';
      v_errmsg := 'Application status Already Kyc Failed';
      RAISE exp_main_reject_record;
   END IF;


   --En: Added for returned mail status 27Feb2012

   --Sn: Added by Santosh K for MVCSD-4074 : Resticted Card Status

   IF v_txn_code = '87' AND v_cap_card_stat = '4'
   then
      V_RESPCODE := '14';
      v_errmsg := 'Card Already Restricted';
      RAISE EXP_MAIN_REJECT_RECORD;
   end if;

   --En: Added by Santosh K for MVCSD-4074 : Resticted Card Status

   --Sn: Added by Dnyaneshwar J for CR 073 : Expired Card Status

   IF v_txn_code = '79' AND v_cap_card_stat = '7'
   then
      V_RESPCODE := '13';
      v_errmsg := 'Card Already Expired';
      RAISE EXP_MAIN_REJECT_RECORD;
   end if;

   --En: Added by Dnyaneshwar J for CR 073 : Expired Card Status

   --Sn: Added by Dnyaneshwar J for MVCSD-4125 : Spend Down

   IF v_txn_code = '80' AND v_cap_card_stat = '14'
   then
      V_RESPCODE := '190';
      v_errmsg := 'Card Already Spend Down';
      RAISE EXP_MAIN_REJECT_RECORD;
   end if;

   --En: Added by Dnyaneshwar J for MVCSD-4125 : Spend Down

   --Sn: Added by Dnyaneshwar J for MVCSD-4104 : Inactive

   IF v_txn_code = '81' AND v_cap_card_stat = '0'
   then
      V_RESPCODE := '191';
      v_errmsg := 'Card Already Inactive';
      RAISE EXP_MAIN_REJECT_RECORD;
   end if;

   --En: Added by Dnyaneshwar J for MVCSD-4104 : Inactive

   -- SN Added for FSAPI-GPP changes

   IF v_txn_code = '61' AND v_cap_card_stat = '18'
   THEN
      V_RESPCODE := '273';
      v_errmsg := 'Card Already set to Bad Credit';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '62' AND v_cap_card_stat = '6'
   THEN
      V_RESPCODE := '274';
      v_errmsg := 'Card Already On Hold';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '82' AND v_cap_card_stat = '17'
   THEN
      V_RESPCODE := '275';
      v_errmsg := 'Card Already Consumed';
      RAISE exp_main_reject_record;
   END IF;

   IF v_txn_code = '99' AND v_cap_card_stat = '19'
   THEN
      V_RESPCODE := '275';
      v_errmsg := 'Card Already set to Risk Investigation';
      RAISE exp_main_reject_record;
   END IF;

   -- EN Added for FSAPI-GPP changes

   BEGIN
      -- Begin And End Block Added By Chinmaya
      SELECT DECODE (v_txn_code,
                     '75', '2',

--decode (v_resoncode,'2','2','3','3'),--card status is separated based on reason code on 27FEB2012 as per requirement
                     '76', '6',

                     --changed from 0 to 6 ,as per new GPR card status change on 040212 by sagar
                     '77', '1',
                     '78', '3',
                     '79', '7',--added for EXPIRED CARD by Dnyaneshwar J on 18 June 2013 for CR 073
                     '80', '14',--added for Spend Down by Dnyaneshwar J on 16 July 2013 for MVCSD-4125
                     '81', '0',--added for Inactive Card by Dnyaneshwar J on 07 Aug 2013 for MVCSD-4104
-- Added by Sagar on 20-Jun-2012 to separate txn code for CARD LOST and STOLEN
                     '83', '9',
                     '05', '6',

                     --changed from 0 to 6 ,as per new GPR card status change on 040212 by sagar
                     '06', '1',
                     '74', '1',
                     '64', '1',
                     '15', '1',
                     '84', '5',

                     -- added for monitored card on 22-Feb-2012 by sagar
                     '85', '11',

                     -- added for hotcarded on 22-Feb-2012 by sagar
                     '86', '16',
                    -- added for returned mail application status on 27-Feb-2012 by sagar
                     '87', '4',
                     -- Added by Santosh K for MVCSD-4074 : Resticted Card Status
                     '46','2',
                     '47','3',
                     --'48','14',
                     '48','15',
                     '49','17',
                     '50','31',
                     '51','15',
                     -- SN - Added for FSAPI-GPP changes
                     '61','18',
                     '62','6',
                     '82','17',
                     '99','19'
                     -- EN - Added for FSAPI-GPP changes
                    )
        INTO v_req_card_stat
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting card stat  for support func'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

       /*  call log info   start */
       BEGIN
          SELECT cut_table_list, cut_colm_list, cut_colm_qury
            INTO v_table_list, v_colm_list, v_colm_qury
            FROM cms_calllogquery_mast
           WHERE cut_inst_code = prm_instcode
             AND cut_devl_chnl = prm_delivery_chnl
             AND cut_txn_code = v_txn_code;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_errmsg := 'Column list not found in cms_calllogquery_mast ';
             v_respcode := '16';
             RAISE exp_main_reject_record;
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while finding Column list ' || SUBSTR (SQLERRM, 1, 100);
             v_respcode := '21';
             RAISE exp_main_reject_record;
       END;

     IF v_txn_code  IN ('46','47','48','49','50')  THEN

      BEGIN
          EXECUTE IMMEDIATE v_colm_qury
                       INTO v_old_value
                      USING prm_instcode, v_hash_pan;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                 'Error while selecting old values  ' || SUBSTR (SQLERRM, 1, 100);
             v_respcode := '21';
             RAISE exp_main_reject_record;
       END;


     ELSE
       BEGIN
          EXECUTE IMMEDIATE v_colm_qury
                       INTO v_old_value
                      USING prm_instcode, v_hash_pan, prm_mbrnumb;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                 'Error while selecting old values  ' || SUBSTR (SQLERRM, 1, 100);
             v_respcode := '21';
             RAISE exp_main_reject_record;
       END;

     END IF;

-- SN :Changes done as per review comments from DB Team : Commneted below query to get account number
-- SN : ADDED BY Ganesh on 18-JUL-12
  /* BEGIN
      SELECT cap_acct_no
        INTO v_spnd_acctno
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = prm_instcode
         AND cap_mbr_numb = prm_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
              'Spending Account Number Not Found For the Card in PAN Master ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error While Selecting Spending account Number for Card '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END; */
-- EN : ADDED BY Ganesh on 18-JUL-12
-- EN :Changes done as per review comments from DB Team : Commneted below query to get account number

   IF prm_schd_flag ='N'  --Added for FWR-33
   THEN

       BEGIN
          BEGIN
             SELECT NVL (MAX (ccd_call_seq), 0) + 1
               INTO v_call_seq
               FROM cms_calllog_details
              WHERE ccd_inst_code = prm_instcode
                AND ccd_call_id = prm_call_id
                AND ccd_pan_code = v_hash_pan;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_errmsg := 'record is not present in cms_calllog_details  ';
                v_respcode := '16';
                RAISE exp_main_reject_record;
             WHEN OTHERS
             THEN
                v_errmsg :=
                      'Error while selecting frmo cms_calllog_details '
                   || SUBSTR (SQLERRM, 1, 100);
                v_respcode := '21';
                RAISE exp_main_reject_record;
          END;

          INSERT INTO cms_calllog_details
                      (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                       ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                       ccd_tran_time, ccd_tbl_names, ccd_colm_name,
                       ccd_old_value, ccd_new_value, ccd_comments, ccd_ins_user,
                       ccd_ins_date, ccd_lupd_user, ccd_lupd_date,
                       ccd_acct_no   -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                      )
               VALUES (prm_instcode, prm_call_id, v_hash_pan, v_call_seq,
                       prm_rrn, prm_delivery_chnl, v_txn_code, prm_trandate,
                       prm_trantime, v_table_list, v_colm_list,
                       v_old_value, NULL, prm_remark, prm_lupduser,
                       sysdate, PRM_LUPDUSER, sysdate,
                       -- v_spnd_acctno -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012 --Changes done as per review comments from DB Team : Commneted v_spnd_acctno
                       v_acct_number    -- Changes done as per review comments from DB Team : Added v_acct_number
                      );
       EXCEPTION
          WHEN exp_main_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_respcode := '21';
             v_errmsg :=
                    ' Error while inserting into cms_calllog_details ' || SQLERRM;
             RAISE exp_main_reject_record;
       END;

   /*  call log info   END */

   END IF;

   --------------Sn For Debit Card No need using authorization -----------------------------------
  -- IF v_cap_prod_catg = 'P'
  -- THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (prm_instcode,
                                    prm_msg_type,
                                    prm_rrn,
                                    prm_delivery_chnl,
                                    NULL,
                                    v_txn_code,
                                    prm_txn_mode,
                                    prm_trandate,
                                    prm_trantime,
                                    prm_pan_code,
                                    NULL,
                                    V_TRAN_AMT,
                                    NULL,
                                    NULL,
                                    NULL,
                                    v_base_curr,                -- v_currcode,
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
                                    NULL,                          -- prm_stan
                                    prm_mbrnumb,                    --Ins User
                                    '00',                           --INS Date
                                    V_TRAN_AMT,
                                    v_topup_auth_id,
                                    v_respcode,
                                    v_respmsg,
                                    v_capture_date,
                                    NULL,
                                    prm_admin_flag
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
            v_respcode := '21';                                      -- added
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_main_reject_record;
      END;
  -- END IF;

   begin
      select nvl(fn_dmaps_main(CCM_SSN_ENCR),CCM_SSN) , CCM_KYC_FLAG     -- SN :Changes done as per review comments from DB Team : added ccm_kyc_flag
        INTO v_ssn , v_ccm_kyc_flag     -- SN :Changes done as per review comments from DB Team : added v_ccm_kyc_flag
        FROM cms_cust_mast
       WHERE ccm_inst_code = prm_instcode AND ccm_cust_code = v_cap_cust_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Cust code '
            || v_cap_cust_code
            || ' not found in master '
            || 'for instcode '
            || prm_instcode;
         v_respcode := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      then
         v_errmsg := 'Error while selecting SSN or KYC flag ' || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   IF v_txn_code <> '86'
   --SN: if condition added for returned mail application status check on 27FEB2012
   THEN
      IF v_txn_code IN ('74','64') --AND NVL (v_startercard_flag, 'N') = 'Y' --Modified for FSS-2125 of 3.1 release
      -- added by amit on 25-Sep-12 for Active unregistered changes
      then

         begin
            --SN: Added for 4.2.2 changes
            BEGIN
               SELECT UPPER (NVL (cpp_product_type, 'O'))
                 INTO v_prod_type
                 FROM cms_product_param
                WHERE cpp_prod_code = v_prod_code AND cpp_inst_code = prm_instcode;
                if v_prod_type <> 'C' then
                if v_user_type in ('1','4') then
                    v_prod_type :='C';
                End if;
                END if;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                     'Error While selecting the product type' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
            --EN: Added for 4.2.2 changes

          -- SN :Changes done as per review comments from DB Team : Commneted below query to get KYC flag
          /*
            SELECT ccm_kyc_flag
              INTO v_ccm_kyc_flag
              FROM cms_cust_mast
             WHERE ccm_inst_code = prm_instcode
               AND ccm_cust_code = v_cap_cust_code;
          */
          -- EN :Changes done as per review comments from DB Team : Commneted below query to get KYC flag

            IF v_ccm_kyc_flag NOT IN ('Y', 'P', 'O','I') AND prm_admin_flag IS NOT NULL AND  prm_admin_flag <> 'Y'
            THEN
               --IF v_saletxn_cnt = 0 --Commented and modified on 10.01.2012 for Checking first time top up instead of sale transactiom
               IF v_cap_firsttime_topup <> 'Y' AND v_startercard_flag = 'Y' --Modified for FSS-2125 of 3.1 release
               THEN
                  v_respcode := '49';
                  v_errmsg :=
                            'Sale Transaction Not Initiated For Starter Card';
                  RAISE exp_main_reject_record;
               END IF;

               IF v_acct_balance <= 0
               THEN
                  v_respcode := '49';
                  v_errmsg := 'Starter Card Does Not Have Positive Balance';
                  RAISE exp_main_reject_record;
               END IF;

               --Sn: Added by Santosh K for 0010929 : Allow to Activate Resticted Card
                if v_cap_card_stat = '4'
                 then
                  V_RESPCODE := '166';
                  V_ERRMSG := 'Restricted Card Status can not be change to Active Unregistered';
                  RAISE exp_main_reject_record;
                end if;
               --En: Added by Santosh K for 0010929 : Allow to Activate Resticted Card
               IF v_prod_type<>'C' THEN  --Modified for 4.2.2 changes
               v_req_card_stat := '13';
               END IF;

               IF v_card_appl_stat = '31'
               THEN
                  BEGIN
                     UPDATE cms_cardissuance_status
                        SET ccs_card_status = '15'
                      WHERE ccs_inst_code = prm_instcode
                        AND ccs_pan_code = v_hash_pan;

                     IF SQL%ROWCOUNT != 1
                     THEN
                        v_respcode := '21';
                        v_errmsg :=
                              'Active Unregistered Card Not Updated To Shipped Status '
                           || fn_mask (prm_pan_code, 'X', 7, 6)
                           || '.';
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
                              'Error Ocurs While Updating Active Unregistered Card To Shipped Status-- '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
               END IF;

            elsif  v_ccm_kyc_flag  IN ('F' ,'N', 'E' ) AND prm_admin_flag IS NOT NULL AND  prm_admin_flag='Y'  then
             IF v_prod_type<>'C' THEN  --Modified for 4.2.2 changes
               v_req_card_stat := '13';
             END IF;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            -- SN :Changes done as per review comments from DB Team : Commneted below exception handling of above query used to get KYC flag
            /*
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '49';
               v_errmsg :=
                        'Kyc Flag Not Found For Custcode ' || v_cap_cust_code;
               RAISE EXP_MAIN_REJECT_RECORD;
            */
            -- EN :Changes done as per review comments from DB Team : Commneted below exception handling of above query used to get KYC flag
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                  'Error While Fetching Kyc Flag '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_main_reject_record;
         END;

      END IF;    -- added by amit on 25-Sep-12 for Active unregistered changes

    ------------------------------------------------------
    --SN: Added on 08-Feb-2013 for SSN validation changes
    ------------------------------------------------------
           IF v_txn_code IN ('74','64')  AND prm_admin_flag IS NOT NULL AND prm_admin_flag <> 'Y' THEN  --IF condition added by Pankaj S. on 26_Feb_2013 for internal defect
       /*SELECT COUNT (1)
        INTO v_exiting_card_stat
        FROM cms_ssn_cardstat
       WHERE csc_stat_flag = 'Y' AND csc_card_stat = v_cap_card_stat;

      SELECT COUNT (1)
        INTO v_new_card_stat
        FROM cms_ssn_cardstat
       WHERE csc_stat_flag = 'Y' AND csc_card_stat = v_req_card_stat;

      IF v_exiting_card_stat = 0 AND v_new_card_stat = 1
      THEN*/

       --Sn Added for FSS-3925
        BEGIN
--           SELECT TRIM (cbp_param_value)
--             INTO v_chkcurr
--             FROM cms_bin_param, cms_prod_mast
--            WHERE     cbp_param_name = 'Currency'
--                  AND cbp_inst_code = cpm_inst_code
--                  AND cbp_profile_code = cpm_profile_code
--                  AND cpm_inst_code = prm_instcode
--                  AND cpm_prod_code = v_prod_code;


vmsfunutilities.get_currency_code(v_prod_code,v_card_type,prm_instcode,v_chkcurr,v_errmsg);

      if v_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;

           IF v_chkcurr IS NULL THEN
              v_respcode := '21';
              v_errmsg := 'Base currency cannot be null ';
              RAISE exp_main_reject_record;
           END IF;
        EXCEPTION
          WHEN exp_main_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg :='Error while selecting base currency -' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
       IF v_chkcurr<>'124' THEN
       --En Added for FSS-3925

         BEGIN
            sp_check_ssn_threshold (prm_instcode,
                                    v_ssn,
                                    v_prod_code,
                                    v_card_type,
                                    NULL,
                                    v_ssn_crddtls,
                                    v_respcode,
                                    v_errmsg
                                   );

            IF v_errmsg <> 'OK'
            THEN
               v_respcode := '158';     --response id changed from 157 to 158
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
                          'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      --END IF;
       END IF;
      END IF;
      -----------------------------------------------------
     --EN: Added on 08-Feb-2013 for SSN validation changes
      -----------------------------------------------------

      IF v_txn_code  NOT IN ('46','47','48','49','50') THEN
      BEGIN
         --Begin 2 starts

         -- SN:added on 06 Mar 2013 By Santosh Kokane for Defect ID : 0010540 : to update active date at the time of Activation only
          IF v_txn_code IN ('74','64') then
          -- Added by abhay for MVCSD-4099
          --  kyc is success  but pin is not yet set .
--       --   BEGIN
--        --  SELECT NVL(CPC_PIN_APPLICABLE,'N'),NVL(CPC_B2B_FLAG,'N')
--        --  INTO l_pin_applicable_flag,l_b2b_enabled_flag
--          FROM CMS_PROD_CATTYPE
--          WHERE CPC_PROD_CODE = v_prod_code
--          AND CPC_CARD_TYPE = v_card_type
--          AND CPC_INST_CODE=prm_instcode;
--          EXCEPTION
--          WHEN OTHERS THEN
--           v_respcode := '21';
--           v_errmsg :='Error while getting PIN and B2B flags -' || SUBSTR (SQLERRM, 1, 200);
--           RAISE exp_main_reject_record;-->
          --END;
           if V_CAP_PIN_FLAG = 'N'  AND prm_admin_flag IS NOT NULL AND prm_admin_flag = 'Y' THEN
           IF l_pin_applicable_flag = 'N' AND (l_b2b_enabled_flag = 'Y' or v_user_type in ('1','4'))  THEN
           V_REQ_CARD_STAT :='1';
           ELSE
           V_REQ_CARD_STAT :='13';
           end if;

          end if;
           IF V_CAP_PIN_FLAG = 'N'  AND prm_admin_flag IS NOT NULL AND prm_admin_flag <> 'Y'
              THEN
              IF l_pin_applicable_flag <> 'N' AND l_b2b_enabled_flag = 'N'   THEN
                  v_respcode := '204';
                   v_errmsg :='PIN needs to be set in order to activate the card.Please redirect cardholder to IVR for PIN setup and activation.';
                 RAISE exp_main_reject_record;
              END IF;
            ELSE
          -- Added by abhay for MVCSD-4099
           UPDATE cms_appl_pan
            set CAP_CARD_STAT = V_REQ_CARD_STAT,
                CAP_ACTIVE_DATE = nvl(CAP_ACTIVE_DATE,sysdate),
                cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),
                cap_replace_exprydt =NULL
              -- added on 11 May 2012 Dhiraj Gaikwad as per discussion with Tejas
            WHERE  cap_inst_code = prm_instcode
            AND cap_pan_code = v_hash_pan
            and CAP_MBR_NUMB = PRM_MBRNUMB;

           END IF;

          ELSE
            IF v_req_card_stat = '19'
            THEN
                BEGIN
                    SELECT cip_param_value
                      INTO v_riskinvest_time
                      FROM cms_inst_param
                     WHERE cip_inst_code = prm_instcode AND cip_param_key = 'RISK_INVESTIGATION_TIME';

                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         v_respcode := '21';
                         v_errmsg :=
                            'Error while selecting Risk Investigation time '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_main_reject_record;
                END;
            END IF;

            UPDATE cms_appl_pan
               SET cap_card_stat = v_req_card_stat,
                   cap_cardstatus_expiry = decode(v_req_card_stat,'19', sysdate + v_riskinvest_time/24)
             WHERE cap_inst_code = prm_instcode
               AND cap_pan_code = v_hash_pan
               AND cap_mbr_numb = prm_mbrnumb;

           END IF;

          -- EN:added on 06 Mar 2013 By Santosh Kokane for Defect ID : 0010540 : to update active date at the time of Activation only

         IF SQL%ROWCOUNT != 1
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Problem In Updation Of Status For Pan '
               || fn_mask (prm_pan_code, 'X', 7, 6)
               || '.';
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
                  'Error ocurs while updating card status-- '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
     END IF;
    ----------------------------------------------------------------
    --SN:Added to update limit profie for GPR card on 25SEP2012
    ----------------------------------------------------------------
      IF v_txn_code IN ('74','64') AND prm_delivery_chnl = '03'
      THEN
         IF v_cap_prfl_code IS NULL OR v_cap_prfl_levl IS NULL
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO v_lmtprfl
                 FROM cms_prdcattype_lmtprfl
                WHERE cpl_inst_code = prm_instcode
                  AND cpl_prod_code = v_prod_code
                  AND cpl_card_type = v_card_type;

               v_profile_level := 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT cpl_lmtprfl_id
                       INTO v_lmtprfl
                       FROM cms_prod_lmtprfl
                      WHERE cpl_inst_code = prm_instcode
                        AND cpl_prod_code = v_prod_code;

                     v_profile_level := 3;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        NULL;
                     WHEN OTHERS
                     THEN
                        v_respcode := '21';
                        v_errmsg :=
                              'Error while selecting Limit Profile At Product Level'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error while selecting Limit Profile At Product Catagory Level'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            IF v_lmtprfl IS NOT NULL
            --added by amit on 25-sep-12 to update appl pan only when profile is found
            THEN
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_prfl_code = v_lmtprfl,
                         cap_prfl_levl = v_profile_level
                   WHERE cap_inst_code = prm_instcode
                     AND cap_pan_code = v_hash_pan;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                               'Limit Profile not updated for:' || v_hash_pan;
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE exp_main_reject_record;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while Limit profile Update '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;
        ----------------------------------------------------------------
        --EN:Added to update limit profie for GPR card on 25SEP2012
        ----------------------------------------------------------------
      END IF;

    -----------------------------------------------------------------------------
    --SN:Added by sagar on 20-Apr-2012 to close starter card attached to GPR card
    ------------------------------------------------------------------------------
      IF     v_txn_code IN ('74','64')
         AND prm_delivery_chnl = '03'
         AND NVL (v_startercard_flag, 'N') = 'N'
      THEN
         BEGIN
            SELECT cap_pan_code,cap_pan_code_encr
              INTO v_starter_card,v_crd_encr from
              (SELECT cap_pan_code,cap_pan_code_encr
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode
               AND cap_acct_no = v_acct_number
               AND cap_card_stat <>'9'--Added by Dnyaneshwar J on 30 July 2013, Mantis-0011849
               AND cap_startercard_flag = 'Y' order by cap_pangen_date desc) where rownum=1;

            v_startercard_found := 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'OK';
               v_startercard_found := 'N';
            WHEN TOO_MANY_ROWS
            THEN
               v_errmsg :=
                     'Multiple starter card found for account number '
                  || v_acct_number;
               v_respcode := '21';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting Starter Card number for Account No '
                  || v_acct_number;
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         --En select starter card detail
         IF v_startercard_found = 'Y'
         THEN
------------------------------------------------------
--SN: Added on 08-Feb-2013 for SSN validation changes
------------------------------------------------------
            SELECT COUNT (1)
              INTO v_exiting_card_stat
              FROM cms_ssn_cardstat
             WHERE csc_stat_flag = 'Y' AND csc_card_stat = v_cap_card_stat;

            SELECT COUNT (1)
              INTO v_new_card_stat
              FROM cms_ssn_cardstat
             WHERE csc_stat_flag = 'Y' AND csc_card_stat = v_req_card_stat;

            IF v_exiting_card_stat = 0 AND v_new_card_stat = 1
            THEN
               BEGIN
                  sp_check_ssn_threshold (prm_instcode,
                                          v_ssn,
                                          v_prod_code,
                                          v_card_type,
                                          NULL,
                                          v_ssn_crddtls,
                                          v_respcode,
                                          v_errmsg
                                         );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_respcode := '158';
                                        --response id changed from 157 to 158
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
                          'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;

-----------------------------------------------------
--EN: Added on 08-Feb-2013 for SSN validation changes
-----------------------------------------------------

            --Sn close starter card
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 9
                WHERE cap_inst_code = prm_instcode
                  AND cap_pan_code = v_starter_card;

            --Sn added on 19_Mar_2013 for FSS-390
            v_crdstat_chnge:='Y';
            v_crd_no:=v_starter_card;
            --En added on 19_Mar_2013 for FSS-390

            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error while closing the status of starter card '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         --En close starter card

         --Sn added by MAGESHKUMAR S. for FSS-3506
      BEGIN

       VMSCOMMON.TRFR_ALERTS (prm_instcode,
                                 v_starter_card,
                                 v_hash_pan,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;

          EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :='Error from alert transfer-' ||SUBSTR (v_respmsg, 1, 200);
                     RAISE exp_main_reject_record;
     END;

     ELSE

     IF v_oldcrd IS NOT NULL THEN

      BEGIN

       VMSCOMMON.TRFR_ALERTS (prm_instcode,
                                 v_oldcrd,
                                 v_hash_pan,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;

          EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :='Error from alert transfer-' ||SUBSTR (v_respmsg, 1, 200);
                     RAISE exp_main_reject_record;
     END;

     END IF;

      --En added by MAGESHKUMAR S. for FSS-3506

         END IF;

         IF v_cap_firsttime_topup = 'N'
         --  added by Sagar on 01-Oct-2012 to update flag as 'Y' when its a GPR card
         THEN
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_firsttime_topup = 'Y'
                WHERE cap_inst_code = prm_instcode
                  AND cap_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error while updating first time topup'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         END IF;
      --  added by Sagar on 01-Oct-2012 to update flag as 'Y' when its a GPR card
      END IF;
    -----------------------------------------------------------------------------
    --SN:Added by sagar on 20-Apr-2012 to close starter card attached to GPR card
    ------------------------------------------------------------------------------
   ELSIF v_txn_code = '86'
   THEN
      -- if condition added for returned mail application status check on 27FEB2012
      BEGIN
         --Begin 2 starts
         UPDATE cms_cardissuance_status
            SET ccs_card_status = v_req_card_stat
          WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT != 1
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Problem in updation of application status for pan '
               || prm_pan_code
               || '.';
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
                  'Error ocurs while updating application status-- '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;


    IF v_txn_code  IN ('46','47','48','49','50')  AND  prm_admin_flag = 'Y' THEN

        BEGIN
             UPDATE cms_cardissuance_status
                SET ccs_card_status = v_req_card_stat
              WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;

             IF SQL%ROWCOUNT != 1
             THEN
                v_respcode := '21';
                v_errmsg :=
                      'Problem in updation of application status for pan '
                   || prm_pan_code
                   || '.';
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
                      'Error ocurs while updating application status-- '
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_main_reject_record;
          END;
     END IF;


     --Sn Added for FSS-4416
     IF v_txn_code IN ('74','64') THEN

   BEGIN

   select cap_pan_code_encr,cap_pan_code into v_crd_encr, v_crd_no from cms_appl_pan
   Where cap_inst_code = prm_instcode AND cap_pan_code <> v_hash_pan
   and cap_acct_no=v_acct_number and cap_card_stat <> '9' and cap_startercard_flag='N';

   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   BEGIN
            UPDATE cms_appl_pan
               SET cap_card_stat = '9'
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_crd_no
             and cap_card_stat = '3';

            IF SQL%ROWCOUNT != 1
            THEN
              NULL;
            ELSE

                v_crdstat_chnge:='Y';
            END IF;

         END;

   END IF;
--En Added for FSS-4416
   --Sn Addded by Pankaj S. for FSS-390
   IF v_errmsg='OK' AND v_crdstat_chnge='Y' THEN
    BEGIN
       sp_log_cardstat_chnge (prm_instcode,
                              v_crd_no,
                              v_crd_encr,
                              v_topup_auth_id,
                              '02',
                              prm_rrn,
                              prm_trandate,
                              prm_trantime,
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
   --En Added by Pankaj S. for FSS-390
--EN: if condition added for returned mail application status check on 27FEB2012
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key,
                   cps_spprt_rsncode, cps_func_remark, cps_ins_user,
                   cps_lupd_user, cps_cmd_mode, cps_pan_code_encr
                  )
           VALUES (prm_instcode,                                --prm_pan_code
                                v_hash_pan, prm_mbrnumb, v_cap_prod_catg,
                   DECODE (v_txn_code,
                           '75', 'HTLST',
                           '76', 'BLOCK',
                           '77', 'DBLOK',
                           '78', 'HTLST',
                           '79','CEXPIRED',--added for EXPIRED CARD by Dnyaneshwar J on 18 June 2013 for CR 073
                           '80','SPENDDOWN',--added for Spend Down by Dnyaneshwar J on 16 July 2013 for MVCDS-4125
                           '81','INACTIVE',--added for Inactive by Dnyaneshwar J on 07 Aug 2013 for MVCDS-4104
                           --Added by sagar on 20-Jun-2012 to separate txn code for CARD LOST and STOLEN
                           '83', 'CARDCLOSE',
                           '05', 'BLOCK',
                           '06', 'DEBLOCK',
                           '74', 'CARDACTIVE',
                           '64', 'CARDACTIVE',
                           '15', 'DHTLST',
                           '84', 'MONITORED',
                           '85', 'HOTCARDED',
                           '86', 'RETMAIL',
                           '87', 'RESTRICT',   -- Added by Santosh K for MVCSD-4074 : Resticted Card Status
                           '46', 'PRNTPENDNG',
                           '47', 'PRINTSENT',
                           '48', 'SHIPPED',
                           '49', 'ADDVERIQUE',
                           '50', 'KYCFAIL',
                           '51','FRAUDHOLD',
                           -- SN - Added for FSAPI-GPP changes
                           '61', 'BADCREDIT',
                           '62', 'CARDONHOLD',
                           '82', 'CONSUMED',
                           '99', 'RISKINVEST'
                           -- EN - Added for FSAPI-GPP changes
                          ),
                   v_resoncode, v_remrk, prm_lupduser,
                   prm_lupduser, 0, v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En create a record in pan spprt

   --Sn commented above & used here for FSS-1656
   IF v_txn_code IN ('74','64') THEN
        BEGIN
           SELECT COUNT (1)
             INTO v_dup_check
             FROM cms_appl_pan
            WHERE cap_inst_code = prm_instcode
              AND cap_acct_no = v_acct_number
              AND cap_startercard_flag = 'N' --Added for FSS-4416
              --AND cap_pan_code <> v_hash_pan
              AND cap_card_stat not in ('0','9'); -- IN ('0', '1', '2', '5', '6', '8', '12','13');--Modified by Dnyaneshwar J on 26 May 2014 ,FSS-1656, Handled for activation active & unregistered & other card status.

           IF v_dup_check > 1 THEN--Modified by Dnyaneshwar J on 26 May 2014
              V_ERRMSG := 'Card is not allowed for activation';
              v_respcode := '222';--Modified by Dnyaneshwar J on 26 May 2014
              RAISE exp_main_reject_record;
           END IF;
        END;
   END IF;
   --En commented above & used here for FSS-1656

   BEGIN
      --added by sagar on 19-Jun-2012 for reason desc logging in txnlog table
  
IF (v_Retdate>v_Retperiod)
    THEN    
      UPDATE transactionlog
         SET remark = prm_remark,
             reason = v_reason,
             ipaddress = prm_ip_addr,           --added by amit on 20-Sep-2012
             add_lupd_user = prm_lupduser,      --added by amit on 20-Sep-2012
             add_ins_user = prm_lupduser        --added by amit on 20-Sep-2012
       WHERE instcode = prm_instcode
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND business_date = prm_trandate
         AND business_time = prm_trantime
         AND delivery_channel = prm_delivery_chnl
         AND txn_code = v_txn_code;
     else
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET remark = prm_remark,
             reason = v_reason,
             ipaddress = prm_ip_addr,           --added by amit on 20-Sep-2012
             add_lupd_user = prm_lupduser,      --added by amit on 20-Sep-2012
             add_ins_user = prm_lupduser        --added by amit on 20-Sep-2012
       WHERE instcode = prm_instcode
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND business_date = prm_trandate
         AND business_time = prm_trantime
         AND delivery_channel = prm_delivery_chnl
         AND txn_code = v_txn_code;
    end if;  

      IF SQL%ROWCOUNT = 0
      THEN
         v_respcode := '21';
         v_errmsg :=
                'Txn not updated in transactiolog for remark and reason desc';
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
               'Error while updating into transactiolog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   v_resp_cde := '1';

  IF v_txn_code   IN ('46','47','48','49','50')  THEN

      BEGIN
          EXECUTE IMMEDIATE v_colm_qury
                       INTO v_old_value
                      USING prm_instcode, v_hash_pan;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                 'Error while selecting old values  ' || SUBSTR (SQLERRM, 1, 100);
             v_respcode := '21';
             RAISE exp_main_reject_record;
       END;
  ELSE

       BEGIN
          EXECUTE IMMEDIATE v_colm_qury
                       INTO v_new_value
                      USING prm_instcode, v_hash_pan, prm_mbrnumb;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                 'Error while selecting old values  ' || SUBSTR (SQLERRM, 1, 100);
             V_RESPCODE := '21';
             RAISE exp_main_reject_record;
       end;

     END IF;

   IF PRM_SCHD_FLAG ='N'  --Added for FWR-33
   THEN
       BEGIN
          UPDATE cms_calllog_details
             SET ccd_new_value = v_new_value
           WHERE ccd_inst_code = ccd_inst_code
             AND ccd_call_id = prm_call_id
             AND ccd_pan_code = v_hash_pan
             AND ccd_call_seq = v_call_seq;

          IF SQL%ROWCOUNT = 0
          THEN
             v_errmsg := 'call log details is not updated for ' || prm_call_id;
             v_respcode := '16';
             RAISE exp_main_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while updating call log details   '
                || SUBSTR (SQLERRM, 1, 100);
             v_respcode := '21';
             RAISE exp_main_reject_record;
       end;
     /*  call log info   end  */
    --SN:Added for FWR-33
   else

        BEGIN
          UPDATE cms_calllog_details
             SET ccd_old_value = v_old_value,
                 ccd_new_value = v_new_value
           WHERE ccd_inst_code = ccd_inst_code
             and CCD_CALL_ID = PRM_CALL_ID
             and CCD_PAN_CODE = V_HASH_PAN
             AND ccd_rrn = PRM_REQ_RRN;

          IF SQL%ROWCOUNT = 0
          THEN
             v_errmsg := 'call log details is not updated for ' || prm_call_id;
             v_respcode := '16';
             RAISE exp_main_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while updating call log details   '
                || SUBSTR (SQLERRM, 1, 100);
             V_RESPCODE := '21';
             RAISE EXP_MAIN_REJECT_RECORD;
       END;

   end if;

   IF v_req_card_stat = '19'
   THEN
       BEGIN
           VMS_QUEUE.ENQUEUE_CARD_STATUS(
                 'RISKINVEST',
                 V_HASH_PAN,
                 v_cap_card_stat,
                 v_req_card_stat,
                 v_riskinvest_time * 3600,
                 v_errmsg);

       IF v_errmsg <> 'OK' THEN
          INSERT INTO VMS_ERROR_LOG(VEL_PAN_CODE,
                                    VEL_TRAN_CODE,
                                    VEL_DELIVERY_CHANNEL,
                                    VEL_ERROR_MSG,
                                    VEL_INS_DATE)
                             VALUES (v_hash_pan,
                                     v_txn_code,
                                     prm_delivery_chnl,
                                     v_errmsg,
                                     sysdate);
       END IF;
       EXCEPTION
         WHEN OTHERS
              THEN NULL;
       END;
 END IF;

    --EN:Added for FWR-33

   --Sn get record for successful transaction
   BEGIN
      SELECT cms_iso_respcde
        INTO prm_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = prm_instcode
         AND cms_delivery_channel = prm_delivery_chnl
         AND cms_response_id = v_resp_cde;

      prm_errmsg := v_errmsg;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Problem while selecting data from response master1 '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 100);
         prm_resp_code := '89';
         ROLLBACK;
   END;
   
   IF PRM_RESP_CODE = '00' AND PRM_ERRMSG = 'OK' THEN
   
        IF V_TXN_CODE = '64' AND V_DEFUND_FLAG = 'Y' AND V_PARAM_VALUE = 'N' THEN
            
            BEGIN
                UPDATE CMS_ACCT_MAST
                    SET CAM_DEFUND_FLAG    = 'F'
                 WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_NO = V_ACCT_NUMBER;
            EXCEPTION
                WHEN OTHERS THEN
                    prm_errmsg := 'Problem while updating in account master for transaction tran type' || SUBSTR (SQLERRM, 1, 100);
                    prm_resp_code := '21';
                    RAISE EXP_MAIN_REJECT_RECORD;
            END;
        END IF;
    END IF;
   
   
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      ROLLBACK;
      prm_errmsg := v_errmsg;
      prm_resp_code := v_respcode;                             --NOT required

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time,
                      txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code, total_amount, currencycode, addcharge,
                      productid, categoryid, atm_name_location, auth_id,
                      amount, preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      error_msg, reason, remark, trans_desc,
                      cr_dr_flag, ipaddress,    --added by amit on 20-Sep-2012
                                            add_lupd_user,
                                                          --added by amit on 20-Sep-2012
                                                          add_ins_user,
                      --added by amit on 20-Sep-2012
                      ssn_fail_dtls                    -- added on 12-Feb-2013
                     )
              VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                      TO_DATE (prm_trandate || ' ' || prm_trantime,
                               'yyyymmdd hh24miss'
                              ),
                      v_txn_code, NULL, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_trandate, prm_trantime, v_hash_pan,
                      NULL, NULL, NULL,
                      prm_instcode, NULL, NULL, NULL,
                      v_prod_code, v_card_type, NULL, v_topup_auth_id,
                      NULL, NULL, NULL, prm_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, prm_revrsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode,
                      prm_errmsg, v_reason, prm_remark, v_trans_desc,
                      v_cr_dr_flag, prm_ip_addr,
                                                --added by amit on 20-Sep-2012
                                                prm_lupduser,
                                                             --added by amit on 20-Sep-2012
                                                             prm_lupduser,
                      --added by amit on 20-Sep-2012
                      v_ssn_crddtls
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '69';
            prm_errmsg :=
                  'Problem while inserting data into transaction log1'
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      --En create a entry in txn log
      --Sn Create an entry in transaction_log_dtl
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
              VALUES (prm_delivery_chnl, v_txn_code, prm_msg_type,
                      prm_txn_mode, prm_trandate, prm_trantime,
                      --prm_card_no
                      v_hash_pan, NULL, NULL,
                      NULL, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, prm_rrn, prm_instcode,
                      v_encr_pan, v_acct_number
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while inserting data into transaction log dtl1'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '69';
            ROLLBACK;
            RETURN;
      END;
   --En Create an entry in transaction_log_dtl
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := RTRIM (v_errmsg || '|' || v_ssn_crddtls, '|');
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_inst_code = prm_instcode)
            AND cam_inst_code = prm_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      ---Sn Updation of Usage limit and amount

      --Sn select response code and insert record into txn log dtl
      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delivery_chnl
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '69';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      -- RETURN;
      END;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time,
                      txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code, total_amount, currencycode, addcharge,
                      productid, categoryid, atm_name_location, auth_id,
                      amount, preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      error_msg, reason, remark, trans_desc,
                      cr_dr_flag, ipaddress,    --added by amit on 20-Sep-2012
                                            add_lupd_user,
                                                          --added by amit on 20-Sep-2012
                                                          add_ins_user,
                      --added by amit on 20-Sep-2012
                      ssn_fail_dtls                     --added on 12-Feb-2013
                     )
              VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                      TO_DATE (prm_trandate || ' ' || prm_trantime,
                               'yyyymmdd hh24miss'
                              ),
                      v_txn_code, NULL, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_trandate, prm_trantime, v_hash_pan,
                      NULL, NULL, NULL,
                      prm_instcode, NULL, NULL, NULL,
                      v_prod_code, v_card_type, NULL, v_topup_auth_id,
                      NULL, NULL, NULL, prm_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, prm_revrsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode,
                      v_errmsg, v_reason, prm_remark, v_trans_desc,
                      v_cr_dr_flag, prm_ip_addr,
                                                --added by amit on 20-Sep-2012
                                                prm_lupduser,
                                                             --added by amit on 20-Sep-2012
                                                             prm_lupduser,
                      --added by amit on 20-Sep-2012
                      v_ssn_crddtls                     --added on 12-Feb-2013
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '69';
            prm_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      --Sn Create an entry in transaction_log_dtl
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
              VALUES (prm_delivery_chnl, v_txn_code, prm_msg_type,
                      prm_txn_mode, prm_trandate, prm_trantime,
                      --prm_card_no
                      v_hash_pan, NULL, NULL,
                      NULL, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, prm_rrn, prm_instcode,
                      v_encr_pan, v_acct_number
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '69';
            ROLLBACK;
            RETURN;
      END;
	  
	   BEGIN
        SELECT UPPER (TRIM (NVL (CIP_PARAM_VALUE, 'Y')))
          INTO V_TOGGLE_VALUE
          FROM VMSCMS.CMS_INST_PARAM
         WHERE CIP_INST_CODE = 1 AND CIP_PARAM_KEY = 'VMS_5657_TOGGLE';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            V_TOGGLE_VALUE := 'Y';
    END;

    IF V_TOGGLE_VALUE = 'Y'
    THEN
        SELECT COUNT (*)
          INTO V_COUNT
          FROM VMS_DORMANTFEE_TXNS_CONFIG
         WHERE     VDT_PROD_CODE = V_PROD_CODE
               AND VDT_CARD_TYPE = V_CARD_TYPE
               AND VDT_DELIVERY_CHNNL = PRM_DELIVERY_CHNL
               AND VDT_TXN_CODE = PRM_TXN_CODE
               AND VDT_IS_ACTIVE = 1;

        IF V_COUNT != 0
        THEN

            UPDATE CMS_APPL_PAN
               SET CAP_LAST_TXNDATE = SYSDATE
             WHERE     CAP_PAN_CODE = V_HASH_PAN
                   AND CAP_INST_CODE = PRM_INSTCODE
                   AND CAP_MBR_NUMB = PRM_MBRNUMB;
        END IF;
    END IF;

   --En Create an entry in transaction_log_dtl
   WHEN OTHERS
   THEN
      prm_resp_code := '69';
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                          --<< MAIN END;>>
/
show error;