create or replace PROCEDURE        VMSCMS.SP_CHW_CARD_ACTIVATION (
   p_instcode           IN       NUMBER,
   p_cardnum            IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_devmob_no          IN       VARCHAR2, --  Added for MOB 62 amudhan
   p_dev_id             IN       VARCHAR2, --  Added for MOB 62 amudhan
   p_resp_code          OUT      VARCHAR2,
   p_exp_date           OUT      VARCHAR2,
   p_srv_code           OUT      VARCHAR2,
   p_pin_offset         OUT      VARCHAR2,
   --Added by Sivapragasam on 24-Feb-2012 for performance
   p_errmsg             OUT      VARCHAR,
   p_closed_card        OUT      VARCHAR2
)
AS
   /*************************************************
     * Created Date     :  10-Dec-2011
     * Created By       :  Sivapragasam
     * PURPOSE          :  For card activation
     * Modified By      :  B.Besky
     * Modified Date    :  08-nov-12
     * Modified Reason  : Logging Customer Account number in to transactionlog table.
     * Reviewer         :  Saravanakumar
     * Reviewed Date    : 19-nov-12
     * Release Number   :  CMS3.5.1_RI0022_B0002

     * Modified By      :  Pankaj S.
     * Modified Date    :  15-Feb-13
     * Modified Reason  : Multiple SSN check & card replacement changes
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Release Number   :

     * Modified By      : Pankaj S.
     * Modified Date    : 15-Mar-2013
     * Modified Reason  : Logging of system initiated card status change(FSS-390)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : CMS3.5.1_RI0024_B0008

     * Modified By      : Ramesh
     * Modified Date    : 01-Apr-2013
     * Modified Reason  : Mantis DI 10766
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : CMS3.5.1_RI0024_B0017

    * Modified By      : Siva Kumar M
    * Modified Date    : 14/Sept/2013
    * Modified Reason  : MVCSD-4099 Additional changes
    * Reviewer         : dhiraj
    * Reviewed Date    :
    * Build Number     :RI0024.4_B0012

    * Modified By      : Siva Kumar A
    * Modified Date    : 05/DEC/2013
    * Modified Reason  : MANTIS-12153
    * Reviewer         : Dhiraj
    * Reviewed Date    : 05/DEC/2013
    * Build Number     : RI0024.7_B0001

    * Modified Date    : 16-Dec-2013
    * Modified By      : Sagar More
    * Modified for     : Defect ID 13160
    * Modified reason  : To log below details in transactinlog if applicable
                         Acct_type,timestamp,cr_dr_flag
    * Reviewer         : Dhiraj
    * Reviewed Date    : 16-Dec-2013
    * Release Number   : RI0024.7_B0001


     * Modified By      : Amudhan S.
     * Modified Date    : 07-Apr-2014
     * Modified Reason  : MOB 62 changes
     * Reviewer         : spankaj
     * Reviewed Date    : 07-April-2014
     * Build Number     : RI0027.2_B0004

     * Modified By      : Amudhan S.
     * Modified Date    : 11-Apr-2014
     * Modified Reason  : MOB 62 --Added delivery channel
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005

     * Modified By      : DINESH B
     * Modified Date    : 21-Apr-2014
     * Modified Reason  : Mantis -14308 -Logging hash key value.
     * Reviewer         : spankaj
     * Reviewed Date    : 22-April-2014
     * Build Number     : RI0027.2_B0007

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal
     * Modified Date    : 13-May-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.0.3_B0001

     * Modified by          : MageshKumar S.
     * Modified Date        : 23-June-15
     * Modified For         : MVCAN-77
     * Modified reason      : Canada account limit check
     * Reviewer             : Spankaj
     * Build Number         : VMSGPRHOSTCSD3.1_B0001

     * Modified by          : Saravanakumar
     * Modified Date        : 19-Aug-2015
     * Modified For         :Performance changes
     * Reviewer             : Spankaj
     * Build Number         : VMSGPRHOSTCSD3.1_B0003

     * Modified by        :Spankaj
     * Modified Date      : 23-Dec-15
     * Modified For       : FSS-3925
     * Reviewer           : Saravanankumar
     * Build Number       : VMSGPRHOSTCSD3.3

     * Modified by                  : MageshKumar S.
     * Modified Date                : 29-DECEMBER-15
     * Modified For                 : FSS-3506
     * Modified reason              : ALERTS TRANSFER
     * Reviewer                     : SARAVANAKUMAR/SPANKAJ
     * Build Number                 : VMSGPRHOSTCSD3.3_B0002

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
    * Modified By      : MageshKumar S
      * Modified Date    : 18/07/2017
      * Purpose          : FSS-5157
      * Reviewer         : Saravanan/Pankaj S.
      * Release Number   : VMSGPRHOST17.07

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
	
	* Modified By      : Mohan Kumar E
    * Modified Date    : 24-JULY-2023
    * Purpose          : VMS-7196 - Funding on Activation for Replacements
    * Reviewer         : Pankaj S.
    * Release Number   : R83
   *************************************************/
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_errmsg                 VARCHAR2 (3000);
   v_currcode               VARCHAR2 (3);
   v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
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
   valid_cardstat_count     NUMBER;
   v_card_topup_flag        NUMBER;
   v_cust_code              cms_cust_mast.ccm_cust_code%TYPE;
   v_tran_count             NUMBER;
   v_tran_count_reversal    NUMBER;
   v_cap_prod_catg          VARCHAR2 (100);
-- v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
-- v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     DATE;
   v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype           cms_prod_cattype.cpc_card_type%TYPE;
   v_expry_date             DATE;
   v_atmonline_limit        cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit        cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_toacct_bal             cms_acct_mast.cam_acct_bal%TYPE;
   v_exp_date               VARCHAR2 (10);
   v_srv_code               VARCHAR2 (5);
   v_remrk                  VARCHAR2 (100);
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_crd_iss_count          NUMBER;
   v_count                  NUMBER;
   v_ledger_balance         NUMBER;
   v_tran_count_spil        NUMBER;
   -- T.Narayanan added to check the SPIL activation check for starter card
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_starter_card_flag      VARCHAR2 (2);
   -- T.Narayanan added to check the SPIL activation check for starter card
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   /* START  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
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
   v_starter_card          cms_appl_pan.cap_pan_code%TYPE;
   v_starter_card_encr     cms_appl_pan.cap_pan_code_encr%TYPE;
   v_oldcrd_encr           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_crdstat_chnge         VARCHAR2(2):='N';
   --En Added by Pankaj S. for FSS-390
   v_oldcardstat NUMBER;

   --SN Added for 13160
   v_acct_type cms_acct_mast.cam_type_code%type;
   v_timestamp timestamp(3);
   --EN Added for 13160
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; --Added for Mantis-14308

   V_FLDOB_HASHKEY_ID         CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE; --Added for MVCAN-77 OF 3.1 RELEASE
   v_cap_date     cms_appl_pan.cap_active_date%TYPE;
   v_chkcurr              cms_bin_param.cbp_param_value%TYPE;
   v_oldcrd_clear       VARCHAR2 (19);
   v_replace_expdt     cms_appl_pan.cap_replace_exprydt%TYPE;
   V_PROFILE_CODE      CMS_PROD_cattype.cpc_profile_code%type;
   v_Retperiod  date;  --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991
   v_txn_code               CMS_TRANSACTION_MAST.CTM_TRAN_CODE%TYPE;--Added for VMS_7196
   V_DEFUND_FLAG        	CMS_ACCT_MAST.CAM_DEFUND_FLAG%TYPE;--Added for VMS_7196
   V_INITIALLOAD_AMOUNT	    CMS_ACCT_MAST.CAM_INITIALLOAD_AMT%TYPE;--Added for VMS_7196
   V_ORDER_FUND_AMT     	VMS_ORDER_LINEITEM.VOL_FUND_AMOUNT%TYPE;--Added for VMS_7196
   V_LINEITEM_DENOM     	VMS_ORDER_LINEITEM.VOL_DENOMINATION%TYPE;--Added for VMS_7196
   v_toggle_value           cms_inst_param.cip_param_value%TYPE;--Added for VMS_7196
   v_old_pan                cms_appl_pan.cap_pan_code%TYPE;--Added for VMS_7196
   V_TXN_AMT             	NUMBER := 0;--Added for VMS_7196
BEGIN
   p_errmsg := 'OK';
   v_errmsg := 'OK';
   v_respcode := '1';
   v_remrk := 'CHW Card Activation';
   v_txn_code := p_txn_code; -- Added for VMS-7196
  v_timestamp :=SYSTIMESTAMP; -- Added for regarding FSS-1144

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN
--Start Generate HashKEY  for Mantis-14308
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||p_txn_code||p_cardnum||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_respcode := '21';
        v_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
     END;

      --End Generate HashKEY for Mantis-14308
   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc
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

      BEGIN
      SELECT cap_prod_code, cap_card_type,
             TO_CHAR (cap_expry_date, 'DD-MON-YY'), cap_card_stat,
             cap_atm_online_limit, cap_pos_online_limit, cap_prod_catg,
             cap_cafgen_flag, cap_appl_code, cap_firsttime_topup,
             cap_mbr_numb, cap_cust_code, cap_pin_off, cap_inst_code,
             --Added by Dhiraj G Limits BRD
             cap_prfl_code,                        -- Added on 30102012 Dhiraj
                           cap_prfl_levl,          -- Added on 30102012 Dhiraj
                                         cap_startercard_flag,
             -- Added on 30102012 Dhiraj
             cap_acct_no,  cap_replace_exprydt, cap_active_date                     --Added by Besky on 09-nov-12
        INTO v_prod_code, v_prod_cattype,
             v_expry_date, v_cap_card_stat,
             v_atmonline_limit, v_atmonline_limit, v_cap_prod_catg,
             v_cap_cafgen_flag, v_appl_code, v_firsttime_topup,
             v_mbrnumb, v_cust_code, p_pin_offset,
                                                  --Added by Sivapragasam on 24-Feb-2012 for performance
                                                  v_inst_code,
             --Added by Dhiraj G Limits BRD
             v_lmtprfl,                            -- Added on 30102012 Dhiraj
                       v_profile_level,            -- Added on 30102012 Dhiraj
                                       v_starter_card_flag,
             -- Added on 30102012 Dhiraj
             v_acct_number   , v_replace_expdt, v_cap_date                   --Added by Besky on 09-nov-12
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';                         --Ineligible Transaction
         v_errmsg := 'Card number not found' || p_txn_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;


   --Sn select profile code for product
 BEGIN
    SELECT CPC_PROFILE_CODE
      INTO V_PROFILE_CODE
      FROM CMS_PROD_CATTYPE
      WHERE CPC_PROD_CODE = V_PROD_CODE AND
            CPC_CARD_TYPE = v_prod_cattype AND
            CPC_INST_CODE = p_instcode;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG   := 'NO PROFILE CODE FOUND FROM PRODCATTYPE - NO DATA FOUND' ;
          v_respcode := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          V_ERRMSG   := 'ERROR WHILE FETCHING PROFILE CODE FROM PRODCATTYPE ' ||
                  SUBSTR(SQLERRM, 1, 200);
          v_respcode := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
  END;

    --Sn added for VMS_7196

            BEGIN
                SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                INTO v_toggle_value
                FROM vmscms.cms_inst_param
                    WHERE cip_inst_code = 1
                    AND cip_param_key = 'VMS_7196_TOGGLE';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                     v_toggle_value := 'Y';
            END;

    IF v_toggle_value = 'Y' THEN
        BEGIN
              SELECT NVL(CAM_DEFUND_FLAG,'N'),NVL(CAM_NEW_INITIALLOAD_AMT,CAM_INITIALLOAD_AMT)
                INTO V_DEFUND_FLAG,V_INITIALLOAD_AMOUNT
                FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO = V_ACCT_NUMBER
                AND CAM_INST_CODE = P_INSTCODE
                FOR UPDATE;
        EXCEPTION
              WHEN OTHERS
              THEN
                 V_RESPCODE := '12';
                 V_ERRMSG :=
                       'ERROR WHILE SELECTING DATA FROM ACCOUNT MASTER FOR CARD NUMBER '
                    || V_HASH_PAN
                    || SUBSTR (SQLERRM, 1, 100);
                 RAISE EXP_MAIN_REJECT_RECORD;
        END;

       if V_DEFUND_FLAG='N' and V_INITIALLOAD_AMOUNT=0 then

            BEGIN
                  select  cap_pan_code
                    into v_old_pan
                    from ( select cap_pan_code
                    from vmscms.cms_appl_pan
                    where cap_inst_code = 1
                    and cap_acct_no = V_ACCT_NUMBER
                    and  cap_repl_flag = 0
                    ORDER BY cap_ins_date
                    ) where rownum =1; 
            
			
				  SELECT TO_NUMBER(NVL(LINEITEM.VOL_DENOMINATION,'0')),LINEITEM.VOL_FUND_AMOUNT
                  INTO V_LINEITEM_DENOM,V_ORDER_FUND_AMT
                  FROM
                    VMS_LINE_ITEM_DTL DETAIL,
                    VMS_ORDER_LINEITEM LINEITEM
                  WHERE DETAIL.VLI_ORDER_ID= LINEITEM.VOL_ORDER_ID
                  AND DETAIL.VLI_PARTNER_ID=LINEITEM.VOL_PARTNER_ID
                  AND DETAIL.VLI_LINEITEM_ID = LINEITEM.VOL_LINE_ITEM_ID
                  AND DETAIL.VLI_PAN_CODE  = v_old_pan;


                IF V_ORDER_FUND_AMT = 1 AND V_LINEITEM_DENOM>0 THEN

                             V_TXN_AMT := V_LINEITEM_DENOM;
                             v_txn_code := '71';                  
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                NULL;
                    WHEN OTHERS
                    THEN
                     V_RESPCODE := '12';
                             V_ERRMSG :=
                                   'ERROR WHILE SELECTING FUND AMOUNT -  '
                                || V_HASH_PAN
                                || SUBSTR (SQLERRM, 1, 100);
                    RAISE EXP_MAIN_REJECT_RECORD;
            END;


        end if;
    END IF;
--En added for VMS_7196



   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'CHW' AND cdm_inst_code = p_instcode;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN
--            SELECT cip_param_value
--              INTO v_base_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

              SELECT TRIM (cbp_param_value)
	      INTO v_base_curr
	      FROM cms_bin_param
              WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
              AND cbp_profile_code = V_PROFILE_CODE;


            IF v_base_curr IS NULL
            THEN
               v_respcode := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               v_errmsg :=
                          'Base currency is not defined for the bin profile ';
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
               'Error while selecting the Delivery Channel of CHW  '
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

   IF (v_Retdate> v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
     SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
      --Added by ramkumar.Mk on 25 march 2012
       ELSE 
        SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
      END IF;   
         IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || ' on ' || p_trandate;
         RAISE exp_main_reject_record;
  end if;       
  END;

   --En Duplicate RRN Check
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
         AND ((txn_code = '02'  and delivery_channel = '10')  -- added  for MOB 62 - amudhan
         OR (txn_code = '21'  and delivery_channel = '13')); -- added for MOB 62 - amudhan

      IF v_tran_count > '0'
      THEN
         v_respcode := '27';
         v_errmsg := 'Card Activation Already Done For This Card ';
         RAISE exp_main_reject_record;
      END IF;
   END;
   */

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

   --Sn find card detail

  IF  v_replace_expdt is null THEN

    IF v_cap_date is not null
      THEN
         v_respcode := '27';
         v_errmsg := 'Card Activation Already Done For This Card';
         RAISE exp_main_reject_record;
      END IF;


   --Sn Added by Pankaj S. on 15-Feb-2013 for card replacement changes(Fss-391)
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

        if v_oldcardstat = 3 or v_oldcardstat = 7 then

           UPDATE cms_appl_pan
              SET cap_card_stat = '9'
            WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;

           IF SQL%ROWCOUNT != 1
           Then
              v_errmsg := 'Problem in updation of status for old damage card ';
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
   --En Added by Pankaj S. on 15-Feb-2013 for card replacement changes(Fss-391)
 END IF;
   -- Start Added on 30102012 Dhiraj
   BEGIN
      IF v_starter_card_flag = 'Y'
      THEN
         --Sn Modified for Transactionlog Functional Removal
        /*SELECT COUNT (*)
           INTO v_tran_count_spil
           FROM transactionlog
          WHERE customer_card_no = v_hash_pan
            AND response_code = '00'
            AND txn_code = '26'
            AND delivery_channel = '08';

         IF v_tran_count_spil < 1
         THEN*/
         IF v_firsttime_topup='N' THEN
        --En Modified for Transactionlog Functional Removal
            v_respcode := '126';
            v_errmsg := 'SPIL Activation not done for this starter card ';
            RAISE exp_main_reject_record;
         END IF;
      END IF;
   EXCEPTION
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
   END;

-- END  Added on 30102012 Dhiraj
  --En find card detail
   IF v_lmtprfl IS NULL OR v_profile_level IS NULL -- Added on 30102012 Dhiraj
   THEN
      /* START   Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      BEGIN
         SELECT cpl_lmtprfl_id
           INTO v_lmtprfl
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = v_inst_code
            AND cpl_prod_code = v_prod_code
            AND cpl_card_type = v_prod_cattype;

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
   END IF;                                         -- Added on 30102012 Dhiraj

   IF v_lmtprfl IS NOT NULL
   THEN                                            -- Added on 30102012 Dhiraj
      BEGIN
         UPDATE cms_appl_pan
            SET cap_prfl_code = v_lmtprfl,
                --Added by Dhiraj G on 12072012 for  - LIMITS BRD
                cap_prfl_levl = v_profile_level
          --Added by Dhiraj G on 12072012 for  - LIMITS BRD
         WHERE  cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            v_respcode := '21';
            v_errmsg := 'Limit Profile not updated for :' || v_hash_pan;
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
   END IF;                                         -- Added on 30102012 Dhiraj

   /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */

   --Sn Check initial load
   IF v_firsttime_topup = 'Y' AND v_cap_card_stat = '1'
   THEN
      v_respcode := '27';                 -- response for invalid transaction
      v_errmsg := 'Card Activation Already Done For this Card';
      RAISE exp_main_reject_record;
   ELSE
      IF TRIM (v_firsttime_topup) IS NULL
      THEN
         v_errmsg := 'Invalid Card Activation ';
         RAISE exp_main_reject_record;
      END IF;
   END IF;

  IF v_replace_expdt IS NULL THEN
   BEGIN
--      SELECT COUNT (*)
--        INTO valid_cardstat_count
--        FROM cms_appl_pan
--       WHERE cap_inst_code = p_instcode
--         AND cap_pan_code = v_hash_pan
--         AND cap_card_stat = 0;

      IF v_cap_card_stat<>'0' --valid_cardstat_count = 0
      THEN
         v_respcode := '10';
         --Modified resp code '09' to '10' by A.Sivakaminathan on 02-Oct-2012
         v_errmsg := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
         RAISE exp_main_reject_record;
      END IF;
   END;

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
   --En Check initial load

   --Sn Expiry date, service code
   BEGIN
      SELECT cbp_param_value
        INTO v_srv_code
        FROM  cms_bin_param
       WHERE cbp_profile_code = V_PROFILE_CODE
         AND cbp_inst_code = p_instcode
         AND cbp_param_name = 'Service Code';

	 v_exp_date:=to_char(v_expry_date, 'MMYY');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';                         --Ineligible Transaction
         v_errmsg := 'Card number not found' || p_txn_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En  Expiry date, service code

   --card status
   BEGIN
      IF v_cap_card_stat IN (2, 3) AND  v_replace_expdt IS NULL
      THEN
         v_respcode := '41';
         v_errmsg := ' Lost Card ';
         RAISE exp_main_reject_record;
      ELSIF v_cap_card_stat = 4
      THEN
         v_respcode := '14';
         v_errmsg := ' Restricted Card ';
         RAISE exp_main_reject_record;
      ELSIF v_cap_card_stat = 9
      THEN
         v_respcode := '46';
         v_errmsg := ' Closed Card ';
         RAISE exp_main_reject_record;
      END IF;
   END;

   --card status

 IF  v_replace_expdt IS NULL THEN
   -- Expiry Check
   BEGIN
      IF TO_DATE (p_trandate, 'YYYYMMDD') >
                               LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY'))
      THEN
         v_respcode := '13';
         v_errmsg := 'EXPIRED CARD';
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
               'ERROR IN EXPIRY DATE CHECK : Tran Date - '
            || p_trandate
            || ', Expiry Date - '
            || v_expry_date
            || ','
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
 END IF;
   -- End Expiry Check
   --IF v_cap_prod_catg = 'P'
  -- THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (p_instcode,
                                    '0200',
                                    p_rrn,
                                    p_delivery_channel,
                                    '0',
                                    v_txn_code,--p_txn_code,  --Modified for VMS_7196
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
                                    V_TXN_AMT, --0,--Modified for VMS_7196
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
  -- END IF;

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

      vmsfunutilities.get_currency_code(v_prod_code,v_prod_cattype,p_instcode,v_chkcurr,v_errmsg);

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

   --Sn Added on 05_Feb_13 to call procedure for multiple SSN check
   BEGIN
      SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)--,gethash(ccm_first_name||ccm_last_name||ccm_birth_date) --Added for MVCAN-77 OF 3.1 RELEASE
        INTO v_ssn--,V_FLDOB_HASHKEY_ID --Added for MVCAN-77 OF 3.1 RELEASE
        FROM cms_cust_mast
       WHERE ccm_inst_code = p_instcode AND ccm_cust_code = v_cust_code;

      sp_check_ssn_threshold (p_instcode,
                              v_ssn,
                              v_prod_code,
                              v_prod_cattype,
                              NULL,
                              v_ssn_crddtls,
                              v_respcode,
                              v_respmsg,
                              V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
                             );

      IF v_respmsg <> 'OK'
      THEN
         v_respcode := '157';
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
         v_errmsg := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Added on 05_Feb_13 to call procedure for multiple SSN check
   END IF;

   IF v_respcode = '00'
   THEN
     BEGIN
       --Sn added by Pankaj S. for FSS-390
       IF UPPER (v_starter_card_flag) = 'N'
       THEN
          --Sn select Starter Card
          BEGIN
             SELECT cap_pan_code, cap_pan_code_encr
               INTO v_starter_card, v_starter_card_encr
               from (SELECT cap_pan_code, cap_pan_code_encr
               FROM cms_appl_pan
              WHERE cap_inst_code = p_instcode
                AND cap_acct_no = v_acct_number
                AND cap_startercard_flag = 'Y'
                AND cap_card_stat NOT IN ('9')
                order by cap_pangen_date desc) where rownum=1;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                NULL;
             WHEN OTHERS
             THEN
                v_respcode := '21';
                v_errmsg :=
                      'Error while selecting Starter Card details for Account No '
                   || v_acct_number;
                RAISE exp_main_reject_record;
          END;
       --En select Starter Card
       END IF;

       --En added by Pankaj S. for FSS-390
       sp_chw_card_activate (p_instcode,
                             p_cardnum,
                             p_rrn,     -- added for mvcsd-4099 additional changes on 14/Sept/2013
                             p_trandate, -- added for mvcsd-4099 additional changes on 14/Sept/2013
                             p_trantime, -- added for mvcsd-4099 additional changes on 14/Sept/2013
                             v_inil_authid, -- added for mvcsd-4099 additional changes on 14/Sept/2013
                             v_respcode,
                             v_respmsg,
                             p_closed_card);

       IF v_respcode <> '00' AND v_respmsg <> 'OK'
       THEN
          v_errmsg := v_respmsg;
          RAISE exp_main_reject_record;
    --exp_auth_reject_record replace by exp_main_reject_record on 06-Feb-2013 during multiple SSN checks
       END IF;

       --Sn added by Pankaj S. for FSS-390
       IF v_starter_card IS NOT NULL
       THEN
          sp_log_cardstat_chnge (p_instcode,
                                 v_starter_card,
                                 v_starter_card_encr,
                                 v_inil_authid,
                                 '02',
                                 p_rrn,
                                 p_trandate,
                                 p_trantime,
                                 v_respcode,
                                 v_respmsg
                                );

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;

             --Sn added by MAGESHKUMAR S. for FSS-3506
        IF v_respcode = '00' AND v_respmsg = 'OK' THEN

         VMSCOMMON.TRFR_ALERTS (p_instcode,
                                 v_starter_card,
                                 v_hash_pan,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;

          END IF;

          ELSE

           IF v_oldcrd IS NOT NULL THEN

          VMSCOMMON.TRFR_ALERTS (p_instcode,
                                 v_oldcrd,
                                 v_hash_pan,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;

          END IF;

      --En added by MAGESHKUMAR S. for FSS-3506

       END IF;
    --En added by Pankaj S. for FSS-390



    EXCEPTION
       WHEN exp_main_reject_record
    --exp_auth_reject_record replace by exp_main_reject_record on 06-Feb-2013 during multiple SSN checks
       THEN
          RAISE;
       WHEN OTHERS
       THEN
          v_respcode := '21';
          v_errmsg := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
   --En call to authorize txn
   END IF;

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
                              v_respmsg
                             );

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
          v_errmsg :=
                'Error while logging system initiated card status change '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
   END IF;
    --En added by Pankaj S. for FSS-390

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
      END;
   ELSE
      p_resp_code := v_respcode;
   END IF;

   --En select response code and insert record into txn log dtl

  /* ---Sn Updation of Usage limit and amount
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
               'Error while selecting CMS_TRANSLIMIT_CHECK'
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
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updateing CMS_TRANSLIMIT_CHECK1 '
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
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updateing CMS_TRANSLIMIT_CHECK2 '
                     || SUBSTR (SQLERRM, 1, 300);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;
   --En Usage limit and amount updation for MMPOS
   END;*/

   ---En Updation of Usage limit and amount

   --IF errmsg is OK then balance amount will be returned
   IF p_errmsg = 'OK'
   THEN
      --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal
               INTO v_acct_balance
               FROM cms_acct_mast
              WHERE cam_acct_no =v_acct_number
--                       (SELECT cap_acct_no
--                          FROM cms_appl_pan
--                         WHERE cap_pan_code = v_hash_pan
--                           AND cap_mbr_numb = '000'
--                           AND cap_inst_code = p_instcode)
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

      --En of Getting  the Acct Balannce
      IF p_errmsg = 'OK'
      THEN
         p_errmsg := '';
         p_exp_date := v_exp_date;
         p_srv_code := v_srv_code;
      END IF;
   END IF;

   BEGIN
    select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';


   IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET ipaddress = p_ipaddress
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = v_txn_code
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
      ELSE
          UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
         SET ipaddress = p_ipaddress
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND txn_code = v_txn_code
         AND business_time = p_trantime
         AND delivery_channel = p_delivery_channel;
   end if;      
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);    
   END;
     --  Added for MOB 62 amudhan
      BEGIN

      --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';

  IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
          UPDATE CMS_TRANSACTION_LOG_DTL
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_MOBILE_NUMBER=p_devmob_no, --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
          CTD_DEVICE_ID=p_dev_id   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = v_TXN_CODE AND CTD_BUSINESS_DATE = p_trandate AND
           CTD_BUSINESS_TIME = p_trantime AND  CTD_MSG_TYPE = '0200' AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=p_instcode;
ELSE

       UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_MOBILE_NUMBER=p_devmob_no, --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
          CTD_DEVICE_ID=p_dev_id   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = v_TXN_CODE AND CTD_BUSINESS_DATE = p_trandate AND
           CTD_BUSINESS_TIME = p_trantime AND  CTD_MSG_TYPE = '0200' AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=p_instcode;
  end if;         
          IF SQL%ROWCOUNT <> 1 THEN 
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog_detl ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
          END IF;
         EXCEPTION
         WHEN exp_main_reject_record THEN
               RAISE exp_main_reject_record;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE exp_main_reject_record;  
        END;
        --  Added for MOB 62 amudhan
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;
   ---Sn Updation of Usage limit and amount
   /*BEGIN Commented by Besky on 06-nov-12
    SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
      INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
      FROM CMS_TRANSLIMIT_CHECK
     WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
          CTC_MBR_NUMB = '000';
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                 SUBSTR(SQLERRM, 1, 300);
      V_RESPCODE := '21';
      RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
      V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK2 ' ||
                 SUBSTR(SQLERRM, 1, 300);
      V_RESPCODE := '21';
      RAISE EXP_MAIN_REJECT_RECORD;
   END;

   BEGIN

    --Sn Usage limit and amount updation for MMPOS
    IF P_DELIVERY_CHANNEL = '04' THEN
      IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
       V_MMPOS_USAGELIMIT := 1;
       BEGIN
         UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_MMPOSUSAGE_AMT     = 0,
               CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
               CTC_ATMUSAGE_AMT       = 0,
               CTC_ATMUSAGE_LIMIT     = 0,
               CTC_BUSINESS_DATE      = TO_DATE(P_TRANDATE || '23:59:59',
                                         'yymmdd' || 'hh24:mi:ss'),
               CTC_PREAUTHUSAGE_LIMIT = 0,
               CTC_POSUSAGE_AMT       = 0,
               CTC_POSUSAGE_LIMIT     = 0
          WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
               CTC_MBR_NUMB = '000';
       EXCEPTION
         WHEN OTHERS THEN
           V_ERRMSG   := 'Error while updateing CMS_TRANSLIMIT_CHECK3 ' ||
                      SUBSTR(SQLERRM, 1, 300);
           V_RESPCODE := '21';
           RAISE EXP_MAIN_REJECT_RECORD;
       END;
      ELSE
       V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
       BEGIN
         UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
          WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
               CTC_MBR_NUMB = '000';
       EXCEPTION
         WHEN OTHERS THEN
           V_ERRMSG   := 'Error while updateing CMS_TRANSLIMIT_CHECK4 ' ||
                      SUBSTR(SQLERRM, 1, 300);
           V_RESPCODE := '21';
           RAISE EXP_MAIN_REJECT_RECORD;
       END;
      END IF;
    END IF;
    --En Usage limit and amount updation for MMPOS

   END;*/

   ---En Updation of Usage limit and amount

   --Sn create a entry in txn log

   --En create a entry in txn log
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      --added by Pankaj S. on 06-Feb-2013 during multiple SSN checks



      ---Sn Updation of Usage limit and amount
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
           INTO v_acct_balance, v_ledger_balance,v_acct_type
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
                  'Error while selecting CMS_TRANSLIMIT_CHECK2 '
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updateing CMS_TRANSLIMIT_CHECK5 '
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updateing CMS_TRANSLIMIT_CHECK6 '
                        || SUBSTR (SQLERRM, 1, 300);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      END;

      ---En Updation of Usage limit and amount*/

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

            p_exp_date := v_exp_date;
            p_srv_code := v_srv_code;
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
      p_exp_date := v_exp_date;
      p_srv_code := v_srv_code;

      --Sn Added for 13160

       if v_dr_cr_flag is null OR v_txn_code='71'
        then

           BEGIN
              SELECT ctm_credit_debit_flag
                INTO v_dr_cr_flag
                FROM cms_transaction_mast
               WHERE ctm_tran_code = v_txn_code
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
                     v_acct_number
                FROM cms_appl_pan
               WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
           EXCEPTION
              WHEN  OTHERS
              THEN
              null;

           END;

       end if;
       
     IF v_txn_code='71' THEN
        BEGIN
            v_hashkey_id :=
                gethash (
                       p_delivery_channel
                    || v_txn_code
                    || p_cardnum
                    || p_rrn
                    || TO_CHAR (v_timestamp, 'YYYYMMDDHH24MISSFF5'));
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
     END IF;

      -- v_timestamp := systimestamp;

       --En Added for 13160

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
                      acct_balance, ledger_balance, error_msg,
                      response_id, ipaddress, cardstatus,
                      --Added cardstatus insert in transactionlog by srinivasu.k
                      trans_desc, ssn_fail_dtls,
                     --ssn_crd_dtls added on 05-Feb-13 for multiple SSN checks
                     --SN : Added for 13160
                     acct_type,cr_dr_flag,time_stamp
                     --EN : Added for 13160
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, 0,
                      v_business_date, v_txn_code, v_txn_type, 0,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')), -- NVL added for 13160
                      v_currcode, NULL,
                      v_prod_code,--SUBSTR (p_cardnum, 1, 4),               -- Modified for 13160
                      v_prod_cattype,--NULL,                                -- Modified for 13160
                      0, v_inil_authid,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '99999999999999990.99')),   -- NVL added for 13160
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      '', 0, v_acct_number,      --Added by Besky on 09-nov-12
                      nvl(v_acct_balance,0), nvl(v_ledger_balance,0), v_errmsg,     ---- NVL added v_acct_balance and ledger_balacne for 13160
                      v_respcode, p_ipaddress, v_cap_card_stat,
                      --Added cardstatus insert in transactionlog by srinivasu.k
                      v_trans_desc, v_ssn_crddtls,
                     --v_ssn_crddtls added on 05-Feb-13 for multiple SSN checks
                     --SN : Added for 13160
                      v_acct_type,v_dr_cr_flag,v_timestamp
                     --EN : Added for 13160
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
                      ctd_customer_card_no_encr, ctd_cust_acct_number,CTD_MOBILE_NUMBER,CTD_DEVICE_ID, ctd_hashkey_id  --Added for Mantis-14308
                     )
              VALUES (p_delivery_channel, v_txn_code, '0200',
                      0, p_trandate, p_trantime,
                      v_hash_pan, 0, v_currcode,
                      0, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan, '',p_devmob_no,p_dev_id, --  Added for MOB 62 amudhan
                      V_HASHKEY_ID --Added for Mantis-14308
                     );

         p_errmsg := v_errmsg || '|' || v_ssn_crddtls;
      --v_ssn_crddtls appended to out msg for multiple SSN check
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
show error;