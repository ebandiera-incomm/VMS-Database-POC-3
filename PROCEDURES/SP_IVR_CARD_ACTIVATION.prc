SET DEFINE OFF;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_IVR_CARD_ACTIVATION (
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
   p_errmsg             OUT      VARCHAR2,
   p_closed_card        IN OUT      VARCHAR2
)
AS
   /*************************************************
      * Modified By      :  Dhiraj G
      * Modified Date    :  30-Oct-2012
      * Modified Reason  :  Maintain Card level profile after activation/deactivation of card
      * Reviewer         : Saravanakumar
      * Reviewed Date    : 08-OCT-12
      * Build Number     :  CMS3.5.1_RI0019_B0007

      * Modified By      :  Pankaj S.
      * Modified Date    :  15-Feb-2013
      * Modified Reason  :  Multiple SSN check &card replacement changes
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      
      * Modified By      : Pankaj S.
      * Modified Date    : 15-Mar-2013
      * Modified Reason  : Logging of system initiated card status change(FSS-390)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : CMS3.5.1_RI0024_B0008
      
      * Modified By      : B>Dhinakaran
      * Modified Date    : 27-Mar-2013
      * Modified For     : FSS-813
      * Modified Reason  : Commented  PIN Generation check(FSS-813)
      * Reviewer         :  
      * Reviewed Date    : 
      * Build Number     : RI0024_B0011  
    
      * Modified By      : Ramesh
      * Modified Date    : 01-Apr-2013
      * Modified Reason  : Mantis DI 10766
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : CMS3.5.1_RI0024_B0017
      
      * Modified By      : Ramesh A
      * Modified Date    : 18-Sep-2013
      * Modified Reason  : MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : RI0024.4_B0016
      
      * Modified By      : Sivakumar A
      * Modified Date    : 05-dec-2013
      * Modified Reason  : Added for Mantis id-12153
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0024.7_B0001
      
      * Modified Date    : 16-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog if applicable
                           Acct_type,timestamp,dr_cr_flag,product code,cardtype
      * Reviewer         : Dhiraj
      * Reviewed Date    : 16-Dec-2013
      * Release Number   : RI0024.7_B0002     

    * Modified By      : Ramesh
    * Modified Date    : 06/Mar/2013
    * Modified Reason  : MVCSD-4121 and FWR-43
    * Reviewer         : Dhiraj
    * Reviewed Date    : 06/Mar/2013
    * Build Number     : RI0027.2_B0002       
    
    * Modified By      : Dinesh
    * Modified Date    : 25/Mar/2013
    * Modified Reason  : Review changes done for MVCSD-4121 and FWR-43
    * Reviewer         : Pankaj S.
    * Reviewed Date    : 01-April-2014
    * Build Number     : RI0027.2_B0003      
    
    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal
    * Modified Date    : 14-May-2015
    * Reviewer         :  Saravanankumar
    * Build Number     : VMSGPRHOAT_3.0.3_B0001
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 23-June-15
    * Modified For         : MVCAN-77
    * Modified reason      : Canada account limit check
    * Reviewer             : Spankaj
    * Build Number         : VMSGPRHOSTCSD3.1_B0001
    
    * Modified by        : Spankaj
    * Modified Date     : 23-Dec-15
    * Modified For      : FSS-3925
    * Reviewer             : Saravanankumar
    * Build Number      : VMSGPRHOSTCSD3.3    
    
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006  
       
    * Modified by          : MageshKumar S.
    * Modified Date        : 19-July-16
    * Modified For         : FSS-4423
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0001
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 02-Aug-16
    * Modified For         : FSS-4423 Additional Changes
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0002
    
     * Modified by          : Saravankumar A
    * Modified Date        : 07-September-16
    * Modified reason      : Performance Changes
    * Reviewer             : Spankaj
    * Build Number         : VMSGPRHOSTCSD4.9

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
   v_base_curr              CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
   v_tran_date              DATE;
   v_tran_amt               NUMBER;
   v_business_date          DATE;
   v_business_time          VARCHAR2 (5);
   v_cutoff_time            VARCHAR2 (5);
   v_valid_cardstat_count   NUMBER;
   v_card_topup_flag        NUMBER;
   v_cust_code              cms_cust_mast.ccm_cust_code%TYPE;
   v_tran_count             NUMBER;
   v_tran_count_reversal    NUMBER;
   v_cap_prod_catg          VARCHAR2 (100);
 --  v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
 --  v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     DATE;
   v_acct_balance           NUMBER;
   v_ledger_balance         NUMBER;
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_remrk                  VARCHAR2 (100);
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_crd_iss_count          NUMBER;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_pin_offset             cms_appl_pan.cap_pin_off%TYPE;  --Commented for FSS-813 on 270313 --Uncommented MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
   -- Added by T.Narayanan to check the PIN Generation before activation
   v_starter_card_flag      VARCHAR2 (2);
   -- T.Narayanan added to check the SPIL activation check for starter card
   v_tran_count_spil        NUMBER;
     -- T.Narayanan added to check the SPIL activation check for starter card
   /* START  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_inst_code              cms_appl_pan.cap_inst_code%TYPE;
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;
-- NUMBER (2);  --added by amit on 20-Jul-2012 for activation part in LIMITS modified by type Dhiraj
   /* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   --Added for transaction detail report on 210812
    --Sn added on 05-Feb-13 for multiple SSN checks
   v_ssn                    cms_cust_mast.ccm_ssn%TYPE;
   v_ssn_crddtls            VARCHAR2 (4000);
--En added on 05-Feb-13 for multiple SSN checks
  --Sn Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
   v_dup_check              NUMBER (3);
   v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;
  --En Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
  --Sn Added by Pankaj S. for FSS-390
  v_oldcrd_encr           cms_appl_pan.cap_pan_code_encr%TYPE;
  v_crdstat_chnge         VARCHAR2(2):='N';
  --En Added by Pankaj S. for FSS-390
v_oldcardstat NUMBER;

V_KYC_FLAG     CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;  --Uncommented MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013

    --SN Added for 13160
    v_acct_type cms_acct_mast.cam_type_code%type;
    v_timestamp timestamp(3);
    --EN Added for 13160
V_RENEWAL_CARD_HASH  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  --Added for MVCSD-4121 & FWR-43
V_RENEWAL_CARD_ENCR  CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE; --Added for MVCSD-4121 & FWR-43
v_cardactive_dt    cms_appl_pan.cap_active_date%TYPE;
  
  V_FLDOB_HASHKEY_ID         CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;  --Added for MVCAN-77 OF 3.1 RELEASE
  v_chkcurr              cms_bin_param.cbp_param_value%TYPE;
  v_oldcrd_clear varchar2(19);
  v_replace_expdt    cms_appl_pan.cap_replace_exprydt%TYPE;

v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
   p_errmsg := 'OK';
   v_remrk := 'IVR Card Activation';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting hash pan  ' || SUBSTR (SQLERRM, 1, 200);
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
                    'Error while converting encryption pan   ' || SUBSTR (SQLERRM, 1, 200);
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
         v_respcode := 'Error while selecting transaction details';
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


  --Sn select Pan detail
   BEGIN
      /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_firsttime_topup, cap_mbr_numb,
             cap_cust_code, cap_proxy_number, cap_acct_no,
              cap_pin_off, --Commented for FSS-813 on 270313 --Uncommented MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
             -- Added by T.Narayanan to check the PIN Generation before activation
             cap_prod_code,                    -- Added by Dhiraj G Limits BRD
                           cap_card_type,      -- Added by Dhiraj G Limits BRD
                                         cap_inst_code,
             --Added by Dhiraj G Limits BRD
             cap_startercard_flag,                 -- Added on 30102012 Dhiraj
                                  cap_prfl_code,   -- Added on 30102012 Dhiraj
             cap_prfl_levl ,                        -- Added on 30102012 Dhiraj
             cap_replace_exprydt, cap_active_date             
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb,
             v_cust_code, v_proxunumber, v_acct_number,
               v_pin_offset,--Commented for FSS-813 on 270313  --Uncommented MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
             -- Added by T.Narayanan to check the PIN Generation before activation
             v_prod_code,                      -- Added by Dhiraj G Limits BRD
                         v_card_type,          -- Added by Dhiraj G Limits BRD
                                     v_inst_code,
             --Added by Dhiraj G Limits BRD
             v_starter_card_flag,                  -- Added on 30102012 Dhiraj
                                 v_lmtprfl,        -- Added on 30102012 Dhiraj
             v_profile_level ,                      -- Added on 30102012 Dhiraj
             v_replace_expdt, v_cardactive_dt
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
   /* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;


  --En select Pan detail

   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'IVR' AND cdm_inst_code = p_instcode;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN
         
            SELECT trim(cbp_param_value)
	    INTO v_base_curr 
	    FROM cms_bin_param WHERE cbp_param_name = 'Currency' 
	    AND cbp_inst_code= p_instcode
	    AND cbp_profile_code = (select  cpc_profile_code from 
            cms_prod_cattype where cpc_prod_code = v_prod_code and
	    cpc_card_type = v_card_type and cpc_inst_code=p_instcode);
	
	          
	     
--            SELECT cip_param_value
--              INTO v_base_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

            IF  v_base_curr IS NULL
            THEN
               v_respcode := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record THEN
            RAISE;
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               v_errmsg :=
                          'Base currency is not defined for the BIN PROFILE ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting base currency for bin  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := '840';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of IVR  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
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
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
  else
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
end if;

      --Added by ramkumar.Mk on 25 march 2012
      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || ' on ' || p_trandate;
         RAISE exp_main_reject_record;
      END IF;
   END;

    --En Duplicate RRN Check
   -- T.Narayanan added to check the SPIL activation check for starter card beg

   /*

   --Commented by dhiraj G on 30102012  same block is added after below block
   --query is runnig two times oon cms_appl_pan
   BEGIN

       SELECT CAP_STARTERCARD_FLAG
        INTO V_STARTER_CARD_FLAG
        FROM CMS_APPL_PAN
       WHERE CAP_PAN_CODE = V_HASH_PAN;

       IF V_STARTER_CARD_FLAG = 'Y' THEN
        SELECT COUNT(*)
          INTO V_TRAN_COUNT_SPIL
          FROM TRANSACTIONLOG
         WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
              TXN_CODE = '26' AND DELIVERY_CHANNEL = '08';
         IF V_TRAN_COUNT_SPIL=0 THEN
                    SELECT COUNT(*)
          INTO V_TRAN_COUNT_SPIL
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
              TXN_CODE = '26' AND DELIVERY_CHANNEL = '08';
    END IF;

       IF V_TRAN_COUNT_SPIL < 1 THEN
          V_RESPCODE := '126';
          V_ERRMSG   := 'SPIL Activation not done for this starter card ';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
       END IF;

     EXCEPTION
       WHEN EXP_MAIN_REJECT_RECORD THEN
        V_RESPCODE := '126';
        V_ERRMSG   := 'SPIL Activation not done for this starter card ';
        RAISE EXP_MAIN_REJECT_RECORD;

       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting transaction details';
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
   */
     -- T.Narayanan added to check the SPIL activation check for starter card end

 

  IF v_replace_expdt IS NULL THEN 
   --Sn Added by Pankaj S. on 15-Feb-2013 for card replacement changes(FSS-391)
   BEGIN
      SELECT chr_pan_code,chr_pan_code_encr,fn_dmaps_main(chr_pan_code_encr)
        INTO v_oldcrd,v_oldcrd_encr,v_oldcrd_clear  --v_oldcrd_encr added by Pankaj S. for FSS-390
        FROM cms_htlst_reisu
       WHERE chr_inst_code = p_instcode
         AND chr_new_pan = v_hash_pan
         AND chr_reisu_cause = 'R'
         AND chr_pan_code IS NOT NULL;

      BEGIN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_appl_pan
          WHERE cap_inst_code = p_instcode
            AND cap_acct_no = v_acct_number
            AND cap_startercard_flag='N'  --ADDED FOR MANTIS-12153
            AND cap_card_stat IN ('0', '1', '2', '5', '6', '8', '12');

         IF v_dup_check <> 1
         THEN
            v_errmsg := 'Card is not allowed for activation';
            v_respcode := '89';         --need to configure new response code
            RAISE exp_main_reject_record;
         END IF;
      END;

      BEGIN
       SELECT cap_card_stat into v_oldcardstat from cms_appl_pan WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;

        if v_oldcardstat = 3  or v_oldcardstat = 7 then

         UPDATE cms_appl_pan
            SET cap_card_stat = '9'
          WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;

         IF SQL%ROWCOUNT != 1
         THEN
            v_errmsg := 'Problem in updation of status for old damage card';
            v_respcode := '89';         --need to configure new response code
            RAISE exp_main_reject_record;
         END IF;
           v_crdstat_chnge:='Y'; --Added for FSS-390
           
           p_closed_card :=v_oldcrd_clear;
         end if;
      END;
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
 END IF;
--En Added by Pankaj S. on 15-Feb-2013 for card replacement changes(FSS-391)

   -- Start Added on 30102012 Dhiraj
   --Sn modified for Transactionlog Functional Removal
     --BEGIN
      IF v_starter_card_flag = 'Y'
      THEN
         /*SELECT COUNT (*)
           INTO v_tran_count_spil
           FROM transactionlog
          WHERE customer_card_no = v_hash_pan
            AND response_code = '00'
            AND txn_code = '26'
            AND delivery_channel = '08';*/

         IF  v_firsttime_topup='N' --v_tran_count_spil < 1
         THEN
            v_respcode := '126';
            v_errmsg := 'SPIL Activation not done for this starter card ';
            RAISE exp_main_reject_record;
         END IF;
      END IF;
   /*EXCEPTION
      WHEN exp_main_reject_record
      THEN
         v_respcode := '126';
         v_errmsg := 'SPIL Activation not done for this starter card ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting transaction details';
         RAISE exp_main_reject_record;
   END;*/
   --En modified for Transactionlog Functional Removal

   -- END Added on 30102012 Dhiraj

   --En select Pan detail
   --Sn Check initial load
   IF v_firsttime_topup = 'Y' AND v_cap_card_stat = '1'
   THEN
      v_respcode := '27';                 -- response for invalid transaction
      v_errmsg := 'Card Activation Already Done';
      RAISE exp_main_reject_record;
   ELSE
      IF TRIM (v_firsttime_topup) IS NULL
      THEN
         v_errmsg := 'Invalid Card Activation ';
         RAISE exp_main_reject_record;
      END IF;
   END IF;

--Commented for FSS-813 on 270313
--Uncommented MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
   -- Added by T.Narayanan to check the PIN Generation before activation. beg
   IF v_pin_offset IS NULL OR v_pin_offset = '' OR v_pin_offset = ' '
   THEN
      v_respcode := '101';                -- response for invalid transaction
      v_errmsg := 'PIN Generation not Done for this card';
      RAISE exp_main_reject_record;
   END IF;

   -- Added by T.Narayanan to check the PIN Generation before activation. end

   --En Check initial load
   --Check already card activation done
   --Check for activation and reversal both count is not same then  allow transaction
   --otherwise reject the transaction
  --Sn modified for Transactionlog Functional Removal
  /* BEGIN
      SELECT COUNT (*)
        INTO v_tran_count
        FROM transactionlog
       WHERE customer_card_no = v_hash_pan
         AND response_code = '00'
         AND txn_code = '68'
         AND delivery_channel = '04';

      SELECT COUNT (*)
        INTO v_tran_count_reversal
        FROM transactionlog
       WHERE customer_card_no = v_hash_pan
         AND response_code = '00'
         AND txn_code = '69'
         AND delivery_channel = '04';

      IF v_tran_count <> v_tran_count_reversal
      THEN
         v_respcode := '27';
         v_errmsg := 'Card Activation Already Done For This Card ';
         RAISE exp_main_reject_record;
      END IF;
   END;

   BEGIN
      SELECT COUNT (*)
        INTO v_tran_count
        FROM transactionlog
       WHERE customer_card_no = v_hash_pan
         AND response_code = '00'
         AND txn_code = '02'
         AND delivery_channel = '07';

      IF v_tran_count > '0'
      THEN
         v_respcode := '27';
         v_errmsg := 'Card Activation Already Done For This Card ';
         RAISE exp_main_reject_record;
      END IF;
   END;

   BEGIN
      SELECT COUNT (*)
        INTO v_tran_count
        FROM transactionlog
       WHERE customer_card_no = v_hash_pan
         AND response_code = '00'
         AND txn_code = '02'
         AND delivery_channel = '10';
     */
      IF v_cardactive_dt IS NOT NULL AND v_replace_expdt IS NULL  --v_tran_count > '0'
      THEN
         v_respcode := '27';
         v_errmsg := 'Card Activation Already Done For This Card ';
         RAISE exp_main_reject_record;
      END IF;
   --END;
   --En modified for Transactionlog Functional Removal  --We can comment below query too --Need to confirm

  IF v_replace_expdt IS NULL THEN 
   -- For Activation of card. Card must be in inactive atatus
   BEGIN
--      SELECT COUNT (*)
--        INTO v_valid_cardstat_count
--        FROM cms_appl_pan
--       WHERE cap_inst_code = p_instcode
--         AND cap_pan_code = v_hash_pan
--         AND cap_card_stat = 0;

      IF v_cap_card_stat<>'0' --v_valid_cardstat_count = 0
      THEN
         v_respcode := '10';
         --Modified resp code '09' to '10' by A.Sivakaminathan on 02-Oct-2012
         v_errmsg := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
         RAISE exp_main_reject_record;
      END IF;
   END;

   -- For Activation of card. Card first time topup must be in N
   BEGIN
--      SELECT COUNT (*)
--        INTO v_card_topup_flag
--        FROM cms_appl_pan
--       WHERE cap_inst_code = p_instcode
--         AND cap_pan_code = v_hash_pan
--         AND cap_firsttime_topup = 'N';

      IF v_firsttime_topup='Y' --v_card_topup_flag = 0
      THEN
         v_respcode := '28';
         v_errmsg := 'CARD FIRST TIME TOPUP MUST BE N STATUS FOR ACTIVATION';
         RAISE exp_main_reject_record;
      END IF;
   END;
 END IF;
   -- verification for card invloved in any transaction.
 --  IF v_cap_prod_catg = 'P'
 --  THEN
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

         IF    v_lmtprfl IS NULL
            OR v_profile_level IS NULL             -- Added on 30102012 Dhiraj
         THEN
            /* START   Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO v_lmtprfl
                 FROM cms_prdcattype_lmtprfl
                WHERE cpl_inst_code = v_inst_code
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
                      WHERE cpl_inst_code = v_inst_code
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
                           || SQLERRM;
                        RAISE exp_main_reject_record;
                  END;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error while selecting Limit Profile At Product Catagory Level'
                     || SQLERRM;
                  RAISE exp_main_reject_record;
            END;
         END IF;                                   -- Added on 30102012 Dhiraj

         /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
         --Sn Added for FSS-3925
        BEGIN
--           SELECT TRIM (cbp_param_value)
--             INTO v_chkcurr
--             FROM cms_bin_param, cms_prod_mast
--            WHERE     cbp_param_name = 'Currency'
--                  AND cbp_inst_code = cpm_inst_code
--                  AND cbp_profile_code = cpm_profile_code
--                  AND cpm_inst_code = p_instcode
--                  AND cpm_prod_code = v_prod_code;

    vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_instcode,v_chkcurr,v_errmsg);
      
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
           WHEN NO_DATA_FOUND THEN
              v_respcode := '21';
              v_errmsg := 'Base currency is not defined ';
              RAISE exp_main_reject_record;
           WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg :='Error while selecting base currency -' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
       IF v_chkcurr<>'124' THEN                 
       --En Added for FSS-3925
         --Sn Added on 05_Feb_13 to call procedure for multiple SSN check
         BEGIN
            SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)--,gethash(ccm_first_name||ccm_last_name||ccm_birth_date) --Added for MVCAN-77 of 3.1 release
              INTO v_ssn--,V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
              FROM cms_cust_mast
             WHERE ccm_inst_code = p_instcode AND ccm_cust_code = v_cust_code;
             
            

             sp_check_ssn_threshold (p_instcode,
                                    v_ssn,
                                    v_prod_code,
                                    V_CARD_TYPE,
                                    NULL,
                                    v_ssn_crddtls,
                                    v_respcode,
                                    v_respmsg,
                                    V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
                                   ); 

            IF v_respmsg <> 'OK'
            THEN
               v_respcode := '158';
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
               v_errmsg :=
                          'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --En Added on 05_Feb_13 to call procedure for multiple SSN check
        END IF;
 -- Sn  MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
  
   BEGIN
       SELECT CCI_KYC_FLAG
       INTO V_KYC_FLAG
       FROM CMS_CAF_INFO_ENTRY
       WHERE CCI_INST_CODE=p_instcode
       AND CCI_APPL_CODE=to_char(v_appl_code);
       
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       v_respcode := '21';
       v_errmsg   := 'KYC FLAG not found ';
       RAISE  exp_main_reject_record;
   WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   := 'Error while selecting data from caf_info ' ||SUBSTR(SQLERRM, 1, 200);
      RAISE  exp_main_reject_record;
   
   END;  
  
   -- En  MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
         --Sn update the flag in appl_pan
         BEGIN
            IF v_respcode = '00'
            THEN
             IF  V_KYC_FLAG IN ('Y','P','O') THEN   --Added MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
               /* START   Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
               UPDATE cms_appl_pan
                  SET cap_card_stat = 1,
                      cap_active_date = SYSDATE,
                      --Modified by sivapragasam on May 14 2012 to maintain active date
                      cap_prfl_code = v_lmtprfl,
                      --Added by Dhiraj G on 12072012 for  - LIMITS BRD
                      cap_prfl_levl = v_profile_level,
                      --Added by Dhiraj G on 12072012 for  - LIMITS BRD
                      cap_firsttime_topup = 'Y',
                      cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),
                      cap_replace_exprydt =NULL
-- Added on 30102012 Dhiraj  bcz below update block is repeated same is commented
               WHERE  cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;

               /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg := 'While Updating IN appl_pan error';
                  RAISE exp_main_reject_record;
               END IF;
             /*
             Commented by dhiraj G  on 30102012

            UPDATE CMS_APPL_PAN
                 SET CAP_FIRSTTIME_TOPUP = 'Y'
               WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE; */
            --Sn Addded by Pankaj S. for FSS-390
            BEGIN
               sp_log_cardstat_chnge (p_instcode,
                                      v_hash_pan,
                                      v_encr_pan,
                                      v_inil_authid,
                                      '01',
                                      p_rrn,
                                      p_trandate,
                                      p_trantime,
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
          --En Added by Pankaj S. for FSS-390   
          
           ELSIF  V_KYC_FLAG IN ('F','E') THEN   ----Added MVCSD-4099 Additional changes in IVR Card Activation (PIN check and activation based on kyc flag) on 18/09/2013
     
      BEGIN
      
          UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = 13,CAP_ACTIVE_DATE=sysdate,CAP_FIRSTTIME_TOPUP = 'Y', 
                 cap_prfl_code = v_lmtprfl,
                 cap_prfl_levl = v_profile_level 
           WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
          
           IF sql%rowcount = 0 then
           V_RESPCODE := '21';
           V_ERRMSG   := 'While Updating IN appl_pan error';
          RAISE EXP_MAIN_REJECT_RECORD;
           end if;
       EXCEPTION
         when EXP_MAIN_REJECT_RECORD then
         raise EXP_MAIN_REJECT_RECORD;
         WHEN OTHERS THEN
          V_RESPCODE := '21';
          P_ERRMSG   := 'Error while Activating GPR card' ||
                      SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
      -- Card Status logging  to Active UnRegistered
         BEGIN
           sp_log_cardstat_chnge (p_instcode,
                                  V_HASH_PAN,
                                  V_ENCR_PAN,
                                  v_inil_authid,
                                   '09',    
                                  P_RRN,              
                                  P_TRANDATE,
                                  P_TRANTIME,
                                  v_respcode,
                                  V_ERRMSG
                                 );

           IF v_respcode <> '00' AND V_ERRMSG <> 'OK'
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
              V_ERRMSG:=
                    'Error while logging system initiated card status change to Active UnRegistered'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
         
     ELSIF   V_KYC_FLAG ='N' THEN  
     
              v_respcode := '206';
              V_ERRMSG:='KYC VERIFICATION  NOT DONE';
              RAISE exp_main_reject_record;
          
     END IF;
          
          END IF;
         /*
         Commented by dhiraj G  on 30102012
         IF SQL%ROWCOUNT = 0 THEN
            V_RESPCODE := '21';
            V_ERRMSG   := 'updating CAP_FIRSTTIME_TOPUP IN appl_pan error';
            RAISE EXP_MAIN_REJECT_RECORD;
           END IF; */
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                  'Error while updating appl_pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      --En update the flag in appl_pan
      EXCEPTION
         WHEN exp_main_reject_record
         THEN              --Exception handled on 05-Feb-13 during SSN changes
            RAISE;
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
  -- END IF;
   
   --Sn added by Pankaj S. for FSS-390
   IF v_errmsg='OK' and v_crdstat_chnge='Y'
   THEN
    BEGIN
       sp_log_cardstat_chnge (p_instcode,
                              v_oldcrd,
                              v_oldcrd_encr,
                              v_inil_authid,
                              '02',
                              p_rrn,
                              p_trandate,
                              p_trantime,
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
    --En added by Pankaj S. for FSS-390

   --START ADDED FOR mvcsd-4121 AND FWR-43 ON 11/03/14
BEGIN

        select cap_pan_code,CAP_PAN_CODE_ENCR,fn_dmaps_main(CAP_PAN_CODE_ENCR) INTO V_RENEWAL_CARD_HASH ,V_RENEWAL_CARD_ENCR,v_oldcrd_clear
        from cms_appl_pan ,cms_cardrenewal_hist
        where cap_inst_code=CCH_INST_CODE and cap_pan_code=CCH_PAN_CODE 
        and cap_card_stat <>9 and cap_pan_code<>V_HASH_PAN
        and cap_acct_no = v_acct_number
        and cap_inst_code=P_INSTCODE;
                       
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
       NULL;
       WHEN OTHERS THEN
         V_RESPCODE := '21';
         P_ERRMSG   := 'Error while GETTING THE RENEWAL CARD DETAILS ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;      

END;
IF V_RENEWAL_CARD_HASH IS NOT NULL THEN
 BEGIN      
        
      UPDATE CMS_APPL_PAN
      SET CAP_CARD_STAT = 9
      WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_RENEWAL_CARD_HASH;
       
         IF SQL%ROWCOUNT = 0 THEN
             V_RESPCODE := '21';
              P_ERRMSG   := 'UPDATION OF RENEWAL CARD TO CLOSURE NOT HAPPENED'|| V_RENEWAL_CARD_HASH;
          RAISE EXP_MAIN_REJECT_RECORD;
         END IF;
         
         p_closed_card :=v_oldcrd_clear;  
         
            sp_log_cardstat_chnge (p_instcode,
                                   V_RENEWAL_CARD_HASH,
                                   V_RENEWAL_CARD_ENCR,
                                   v_inil_authid,
                                   '02',    
                                  P_RRN,              
                                  P_TRANDATE,
                                  P_TRANTIME,
                                  v_respcode,
                                  P_ERRMSG
                                 );

           IF v_respcode <> '00' AND P_ERRMSG <> 'OK'
           THEN
            RAISE exp_main_reject_record;
           END IF;        
           
       EXCEPTION    
       WHEN EXP_MAIN_REJECT_RECORD THEN
       RAISE;
       WHEN OTHERS THEN
         V_RESPCODE := '21';
         P_ERRMSG   := 'Error while CLOSING THE RENEWAL CARD ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;      

 END;
END IF;
--END



   --Sn Selecting Reason code for Online Order Replacement
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_inst_code = p_instcode AND csr_spprt_key = 'ACTVTCARD';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Card Activation reason code is present in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn create a record in pan spprt
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_instcode, v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'ACTVTCARD', v_resoncode, v_remrk,
                   '1', '1', 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En create a record in pan spprt
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
            ROLLBACK;
      END;
   ELSE
      p_resp_code := v_respcode;
   END IF;

   --En select response code and insert record into txn log dtl

   ---Sn Updation of Usage limit and amount
  /* BEGIN
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
            || SUBSTR (SQLERRM, 1, 200);
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
               AND ctc_mbr_numb = '000';
         ELSE
            v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

            UPDATE cms_translimit_check
               SET ctc_mmposusage_limit = v_mmpos_usagelimit
             WHERE ctc_inst_code = p_instcode
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = '000';
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
   END;*/

   ---En Updation of Usage limit and amount

   --IF errmsg is OK then balance amount will be returned
   IF p_errmsg = 'OK'
   THEN
      --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal
               INTO v_acct_balance, v_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no =v_acct_number
                      /* (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = '000'
                           AND cap_inst_code = p_instcode)*/
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
      p_errmsg := '  ';
   END IF;

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
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
   END;
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      ROLLBACK;
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      ---Sn Updation of Usage limit and amount
     /* BEGIN
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
                  'Error while selecting 2 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
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
                  AND ctc_mbr_numb = '000';
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = '000';
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
      END;*/

      ---En Updation of Usage limit and amount
      
  --SN Added for 13160 
    
    if v_dr_cr_flag is null
    then
    
       BEGIN
          SELECT ctm_credit_debit_flag,
                 ctm_tran_desc
            INTO v_dr_cr_flag, 
                 v_trans_desc  
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
       
          SELECT cap_card_stat, cap_acct_no,
                 cap_prod_code,cap_card_type
            INTO v_cap_card_stat,v_acct_number,
                 v_prod_code,v_card_type
            FROM cms_appl_pan
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
       EXCEPTION
          WHEN OTHERS
          THEN
              null;
       END;   
       
       BEGIN
       
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
               INTO v_acct_balance, v_ledger_balance,v_acct_type
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number
                AND cam_inst_code = p_instcode;

       EXCEPTION
         WHEN OTHERS
         THEN
               null; 
       END;
       
   end if;
       
   v_timestamp := systimestamp;   
       
    --EN Added for 13160            

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
                      dni, cardstatus,
                      --Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc ,       -- FOR Transaction detail report issue
                      error_msg,
                      --Sn Added for 13160
                      acct_type,
                      time_stamp,
                      cr_dr_flag
                      --En Added for 13160                            
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, 0,
                      v_business_date, p_txn_code, v_txn_type, 0,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')),  --NVL added for 13160
                      v_currcode, NULL, 
                      v_prod_code,--SUBSTR (p_cardnum, 1, 4),       --Modified for 13160 
                      v_card_type,--NULL,                           --Modified for 13160
                      0, v_inil_authid,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')),  --NVL added for 13160
                      '0.00',--NULL,        --Modified for 13160 
                      '0.00',--NULL,        --Modified for 13160 
                      p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, 0, v_acct_number,
                      nvl(v_acct_balance,0),            --NVL added for 13160 
                      nvl(v_ledger_balance,0),          --NVL added for 13160  
                      v_respcode, p_ani,
                      p_dni, v_cap_card_stat,
                      --Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc ,     -- FOR Transaction detail report issue
                      v_errmsg,
                      --Sn Added for 13160
                      v_acct_type,
                      v_timestamp,
                      v_dr_cr_flag
                      --En Added for 13160                      
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
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
                      v_encr_pan, v_acct_number,
                      v_txn_type
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

      p_errmsg := v_authmsg;
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
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
     /* BEGIN
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
                  'Error while selecting 3 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
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
                  AND ctc_mbr_numb = '000';
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = '000';
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating 3 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;*/

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
            ROLLBACK;
      -- RETURN;
      END;
      
 --SN Added for 13160 
    
    if v_dr_cr_flag is null
    then
    
       BEGIN
          SELECT ctm_credit_debit_flag,
                 ctm_tran_desc
            INTO v_dr_cr_flag, 
                 v_trans_desc  
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
       
          SELECT cap_card_stat, cap_acct_no,
                 cap_prod_code,cap_card_type
            INTO v_cap_card_stat,v_acct_number,
                 v_prod_code,v_card_type
            FROM cms_appl_pan
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
       EXCEPTION
          WHEN OTHERS
          THEN
              null;
       END;
          
   end if;
       
   v_timestamp := systimestamp;   
       
    --EN Added for 13160      
            

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
                      dni, cardstatus,
                                      --Added CARDSTATUS insert in transactionlog by srinivasu.k
                                      trans_desc,
                                                 -- FOR Transaction detail report issue
                                                 ssn_fail_dtls,error_msg,
                     --ssn_crd_dtls added on 05-Feb-13 for multiple SSN checks
                      --Sn Added for 13160
                      acct_type,
                      time_stamp,
                      cr_dr_flag
                      --En Added for 13160                                    
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, 0,
                      v_business_date, p_txn_code, v_txn_type, 0,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')), -- NVL added for 13160      
                      v_currcode, NULL, 
                      v_prod_code,--SUBSTR (p_cardnum, 1, 4),  -- Modified for 13160      
                      v_card_type,--NULL,                      -- Modified for 13160  
                      0, v_inil_authid,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')),  -- NVL added for 13160           
                      '0.00',--NULL,        -- Modified for 13160 
                      '0.00',--NULL,        -- Modified for 13160 
                      p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, 0, v_acct_number,
                      nvl(v_acct_balance,0),            --NVL added for 13160
                      nvl(v_ledger_balance,0),          --NVL added for 13160 
                      v_respcode, p_ani,
                      p_dni, v_cap_card_stat,
                                             --Added CARDSTATUS insert in transactionlog by srinivasu.k
                                             v_trans_desc,
                                                          -- FOR Transaction detail report issue
                                                          v_ssn_crddtls,v_errmsg,
                     --v_ssn_crddtls added on 05-Feb-13 for multiple SSN checks
                      --Sn Added for 13160
                      v_acct_type,
                      v_timestamp,
                      v_dr_cr_flag
                      --En Added for 13160                            
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
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
                      v_encr_pan, v_acct_number,
                      v_txn_type
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