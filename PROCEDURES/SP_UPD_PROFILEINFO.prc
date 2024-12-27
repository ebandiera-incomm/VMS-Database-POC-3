create or replace
PROCEDURE              VMSCMS.SP_UPD_PROFILEINFO (
   prm_instcode                 IN       NUMBER,
   prm_msg_type                 IN       VARCHAR2,
   prm_remark                   IN       VARCHAR2,
   prm_pan_code                 IN       VARCHAR2, 
   prm_mbrnumb                  IN       VARCHAR2,
   prm_acct_no                  IN       VARCHAR2,
   prm_rrn                      IN       VARCHAR2,
   prm_stan                     IN       VARCHAR2,
   prm_txn_code                 IN       VARCHAR2,
   prm_txn_mode                 IN       VARCHAR2,
   prm_delivery_channel         IN       VARCHAR2,
   prm_trandate                 IN       VARCHAR2,
   prm_trantime                 IN       VARCHAR2,
   prm_currcode                 IN       VARCHAR2,
   prm_lastname                 IN       VARCHAR2,
   prm_dob                      IN       VARCHAR2,
   prm_ssn                      IN       VARCHAR2,
   prm_email                    IN       VARCHAR2,
   prm_mobile_no                IN       VARCHAR2,
   prm_alternate_phone          IN       VARCHAR2,
   prm_phy_addr1                IN       VARCHAR2,
   prm_phy_addr2                IN       VARCHAR2,
   prm_phy_city                 IN       VARCHAR2,
   prm_phy_state                IN       NUMBER,
   prm_phy_zip                  IN       VARCHAR2,
   prm_phy_country              IN       NUMBER,
   prm_mailing_addr1            IN       VARCHAR2,
   prm_mailing_addr2            IN       VARCHAR2,
   prm_mailing_city             IN       VARCHAR2,
   prm_mailing_state            IN       NUMBER,
   prm_mailing_zip              IN       VARCHAR2,
   prm_mailing_country          IN       NUMBER,
   prm_rvsl_code                IN       VARCHAR2,
   prm_ins_user                 IN       NUMBER,
   prm_call_id                  IN       NUMBER,
   prm_addrupd_flag             IN       VARCHAR2,
   prm_ipaddress                IN       VARCHAR2,                             --added by amit on 06-Oct-2012
   prm_maiden_name              IN       VARCHAR2,
   prm_first_name               IN       VARCHAR2,
   prm_reason_code              IN       VARCHAR2,
   PRM_ID_TYPE                  IN       VARCHAR2,                             -- Added for SSN changes on 19-Feb-2013
   PRM_AUTH_USER                IN       VARCHAR2,                             --Added for JH-3159
   prm_business_name            IN       VARCHAR2,
   prm_occupation              IN        VARCHAR2,
   prm_occupation_others       IN        VARCHAR2,
   prm_id_province             IN        VARCHAR2,
   prm_id_country              IN        VARCHAR2,
   prm_id_verification_date    IN        VARCHAR2,
   prm_tax_res_of_canada       IN        VARCHAR2,
   prm_tax_payer_id_number     IN        VARCHAR2,
   prm_reason_for_no_tax_id    IN        VARCHAR2,
   prm_reason_for_no_taxid_others IN     VARCHAR2,
   prm_jurisdiction_of_tax_res IN        VARCHAR2,
   prm_thirdpartyenabled       IN        VARCHAR2,
   prm_thirdpartytype          IN        VARCHAR2,
   prm_thirdpartycorporationname IN      VARCHAR2,
   prm_thirdpartycorporation   IN        VARCHAR2,
   prm_thirdpartyfirstname     IN        VARCHAR2,
   prm_Thirdpartylastname      IN        VARCHAR2,
   prm_thirdpartyaddress1      IN        VARCHAR2,
   prm_thirdpartyaddress2      IN        VARCHAR2,
   prm_thirdpartycity          IN        VARCHAR2,
   prm_thirdpartystate         IN        VARCHAR2,
   prm_thirdpartyzip           IN        VARCHAR2,
   prm_thirdpartycountry       IN        VARCHAR2,
   prm_thirdpartynature        IN        VARCHAR2,
   prm_thirdpartybusiness      IN        VARCHAR2, 
   prm_Thirdpartyoccupationtype IN       VARCHAR2,
   prm_thirdpartyoccupation    IN        VARCHAR2,
   prm_Thirdpartydob           IN        VARCHAR2,                    
   Prm_Resp_Code               OUT       VARCHAR2,
   Prm_Resp_Msg                OUT       VARCHAR2,
   Prm_Optin_Flag_Out          OUT       VARCHAR2
)
IS

/******************************************************************************
     * Created Date                 : 13/Jan/2012.
     * Created By                   : Sagar More.
     * Purpose                      : to update profile information of customer
     * Last Modified for            : Mailing Address Update
     * Last Modification Date       : 23-Nov-2012
     * Build Number                 : RI0022

     * modified for                 : SSN Changes
     * modified Date                : 19-Feb-2013
     * modified reason              : To update prm_id_type in cms_cust_mast table
     * Build Number                 : RI0023.2_B0001


     * Modified for                 : MVCSD-4121
     * Modified Date                : 14-Mar-2014
     * Modified By                  : Narsing Ingle
     * Modified reason              : To update address verification flag
     * Build Number                 : RI0027.2_B0002

     * Modified for                 : Mantis-14101
     * Modified Date                : 14-Apr-2014
     * Modified By                  : Narsing Ingle
     * Modified reason              : To update address verification flag
     * Build Number                 : RI0027.2_B0005

     * Modified for                 : JH-3159
     * Modified Date                : 18-dEC-2014
     * Modified By                  : Abdul Hameed M.A
     * Modified reason              : To update auth user name in cust mast
     * Build Number                 :

     * Modified for                 : JH-1961
     * Modified Date                : 22-dEC-2014
     * Modified By                  : Abdul Hameed M.A
     * Modified reason              : Address Override
     * Build Number                 : RI0027.5_B0002
     * Modified for                 : MVCAN-676
     * Modified Date                : 29-May-2015
     * Modified By                  : Siva Kumar M
     * Modified reason              : CSD is Requiring SSN/SIN Number When Updating Profile
     * Build Number                  :VMSGPRHOSTCSD_3.0.3_B0001

     * Modified by      :Spankaj
     * Modified Date    : 07-Sep-15
     * Modified For     : FSS-2321
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOSTCSD3.2
	 
	   * Modified by          :Siva Kumar M
	   * Modified Date        : 05-JAN-16
	   * Modified For         : MVHOST-1255
	   * Modified reason      : reason code logging
	   * Reviewer             : Saravans kumar
	   * Build Number         : RI0027.3.3_B0002

       * Modified by       :Siva kumar
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

       * Modified by       :Mageshkumar S
       * Modified Date    : 31-May-16
       * Modified For     : Mantis id:16412
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.1_B0002

	   * Modified by       :T.Narayanaswamy
       * Modified Date    : 24-March-17
       * Modified For     : JIRA-FSS-4647 (AVQ Status issue)
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_17.03_B0003

       * Modified by       :Akhil
       * Modified Date    : 15-Dec-17
       * Modified For     : VMS-77
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12
       
       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
       
		 * Modified By      : UBAIDUR RAHMAN.H
		 * Modified Date    : 25-JAN-2018
		 * Purpose          : VMS-162 (encryption changes)
		 * Reviewer         : Vini.P
		 * Release Number   : VMSGPRHOST18.01
		 
		 * Modified by      :  Vini Pushkaran
		 * Modified Date    :  02-Feb-2018
		 * Modified For     :  VMS-162
		 * Reviewer         :  Saravanankumar
		 * Build Number     :  VMSGPRHOSTCSD_18.01
     * Modified by      :  Ubaidur Rahman H
     * Modified Date    :  17-JUN-2019
     * Modified For     :  VMS-959(Enhance CSD to support cardholder data search for Rewards products)
     * Reviewer         :  Saravanankumar A
     * Build Number     :  VMSGPRHOST_R17
     
     * Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  03-Dec-2021
     * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
     * Reviewer         :  Saravanakumar
     * Build Number     :  VMSGPRHOST_R55_RELEASE
     
     
********************************************************************************/

   v_mail_cntry_chk   gen_cntry_mast.gcm_cntry_code%TYPE;
   v_mail_state_chk   gen_state_mast.gsm_state_code%TYPE;
   v_phy_cntry_chk    gen_cntry_mast.gcm_cntry_code%TYPE;
   v_phy_state_chk    gen_state_mast.gsm_state_code%TYPE;
   v_cust_code        cms_appl_pan.cap_cust_code%TYPE;
   v_hash_pan         cms_appl_pan.cap_pan_code%TYPE;
   v_mbrnumb          cms_appl_pan.cap_mbr_numb%TYPE;
   v_proxynumber      cms_appl_pan.cap_proxy_number%TYPE;
   v_encr_pan         cms_appl_pan.cap_pan_code_encr%TYPE;
   v_prodcatg         cms_appl_pan.cap_prod_catg%TYPE;
   v_prod_cattype     cms_appl_pan.cap_card_type%TYPE;
   v_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_capture_date     DATE;
   v_auth_id          PLS_INTEGER;
   v_rrn_count        PLS_INTEGER;
   v_respcode         transactionlog.response_code%TYPE;
   v_errmsg           transactionlog.ERROR_MSG%type; 
   v_acct_balance     cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance   cms_acct_mast.cam_ledger_bal%TYPE;
   v_cnt              PLS_INTEGER;
   -- added by sagar on 16FEB2012 to check sql%rowcount fof insert

   /* variables added for call log info   start */
   v_table_list       VARCHAR2 (2000);
   v_colm_list        VARCHAR2 (2000);
   v_colm_qury        VARCHAR2 (2000);
   v_old_value_p      VARCHAR2 (4000);
   v_old_value_o      VARCHAR2 (4000);
   v_old_value        VARCHAR2 (4000);
   v_new_value_p      VARCHAR2 (4000);
   v_new_value_o      VARCHAR2 (4000);
   v_new_value        VARCHAR2 (4000);
   v_call_seq         cms_calllog_details.ccd_call_seq%TYPE;
   v_addr_flag        cms_addr_mast.cam_addr_flag%TYPE;
   v_mailaddr_cnt     PLS_INTEGER;
   v_phyaddr_cnt      PLS_INTEGER;
   v_mailaddr_cnt1    PLS_INTEGER;
   v_phyaddr_cnt1     PLS_INTEGER;
  /* variables added for call log info   END */
   v_date_format      cms_inst_param.cip_param_value%TYPE;
   -- added by sagar on 24-May-2012
   v_spnd_acctno      cms_appl_pan.cap_acct_no%TYPE;              -- ADDED BY GANESH ON 19-JUL-12
   v_resoncode        cms_spprt_reasons.csr_spprt_rsncode%TYPE;   -- added on 06NOV2012
   V_REASON           CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;      -- added on 06NOV2012
   V_ADDR_VERIF_FLAG  CMS_CUST_MAST.CCM_ADDRVERIFY_FLAG%TYPE;     -- Added By Narsing on 14th Jan 2014 for MVCSD-4121
   V_TRANS_DESC       cms_transaction_mast.ctm_tran_desc%TYPE;    -- Added By Narsing on 14th Jan 2014 for MVCSD-4121
   V_ADDRCALLSEQ      cms_calllog_details.ccd_call_seq%TYPE;      -- Added By Narsing on 14th Jan 2014 for MVCSD-4121
   ADDR_RRN           transactionlog.rrn%TYPE;                    -- Added By Narsing on 14th Jan 2014 for MVCSD-4121
   V_ENCRYPT_ENABLE   CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
   V_ZIPCODE          cms_addr_mast.cam_pin_code%type; 
   --Sn Added for JH-1961
   V_CUST_ID          CMS_CUST_MAST.CCM_CUST_ID%type;
   V_CUST_NAME        cms_cust_mast.ccm_last_name%type;
   V_PENDING_CNT      PLS_INTEGER;
   v_state_code       gen_state_mast.gsm_switch_state_code%TYPE;
   v_gprhash_pan      CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   v_gprencr_pan      CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   --En Added for JH-1961
   v_encr_first_name  cms_cust_mast.ccm_first_name%type;
   v_encr_last_name   cms_cust_mast.ccm_last_name%type;
   v_encr_mother_name cms_cust_mast.ccm_mother_name%type;
   v_encr_addr_lineone cms_addr_mast.CAM_ADD_ONE%type;
   v_encr_addr_linetwo cms_addr_mast.CAM_ADD_TWO%type;
   v_encr_city         cms_addr_mast.CAM_CITY_NAME%type;
   v_encr_email        cms_addr_mast.CAM_EMAIL%type;
   v_encr_phone_no     cms_addr_mast.CAM_PHONE_ONE%type;
   v_encr_mob_one      cms_addr_mast.CAM_MOBL_ONE%type;
   v_encr_cas_addr_one      cms_avq_status.cas_addr_one %type;       
   v_encr_cas_addr_two      cms_avq_status.cas_addr_two%type;       
   v_encr_cas_city_name     cms_avq_status.cas_city_name%type;       
   v_encr_cas_postal_code   cms_avq_status.cas_postal_code%type; 
   v_encr_full_name         cms_avq_status.cas_cust_name%type;
   V_Decr_Cellphn           Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One           Cms_Addr_Mast.Cam_Mobl_One%Type;
   L_Alert_Lang_Id          Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
   V_Doptin_Flag            PLS_INTEGER;
   Type CurrentAlert_Collection Is Table Of Varchar2(30);
   CurrentAlert CurrentAlert_Collection;
   v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag            Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type; 
   v_federal_state_flag     CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
   v_thirdparty_count       PLS_INTEGER; 
   V_State_Desc             Vms_Thirdparty_Address.Vta_State_Desc%Type;
   V_State_Switch_Code      Gen_State_Mast.Gsm_Switch_State_Code%Type;
   V_OCCUPATION_DESC        vms_occupation_mast.VOM_OCCU_NAME%TYPE;
   v_id_province            GEN_STATE_MAST.GSM_SWITCH_STATE_CODE%TYPE;
   v_id_country             GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   v_jurisdiction_of_tax_res   GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   v_cntrycode              gen_cntry_mast.gcm_cntry_code%type;
   v_occupation             cms_cust_mast.ccm_occupation%type;
   v_occupation_others      cms_cust_mast.ccm_occupation_others%type;
   v_taxresistrentcanada    cms_cust_mast.ccm_tax_res_of_canada%type;
   v_thirdpartyenabled      cms_cust_mast.CCM_THIRD_PARTY_ENABLED%type;
   exp_reject_txn           EXCEPTION;
   v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN                                                -- Main begin starts here

   BEGIN                                             -- begin 001 starts here
      v_errmsg := 'OK';
      Prm_Optin_Flag_Out :='N';
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (prm_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while converting in hashpan '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_txn;
      END;
      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (prm_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_respcode := '12';
            v_errmsg :=
                'Error while converting encrpan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;

      --EN create encr pan
      BEGIN
      
      --Added for VMS-5733/FSP-991

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
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code
            AND business_date = prm_trandate
            AND business_time = prm_trantime;    
         ELSE
                    SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code
            AND business_date = prm_trandate
            AND business_time = prm_trantime;  
          END IF;    

         IF v_rrn_count > 0
         THEN
            v_respcode := '22';
            v_errmsg := 'Duplicate RRN found';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                       'while getting rrn count ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;


     BEGIN

          IF prm_reason_code IS NOT NULL
          THEN
             v_resoncode := prm_reason_code;
             BEGIN

                SELECT csr_reasondesc
                  INTO v_reason
                  FROM cms_spprt_reasons
                 WHERE csr_spprt_rsncode = v_resoncode
                   AND csr_inst_code = prm_instcode;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   v_respcode := '21';
                   v_errmsg :=
                         'reason code not found in master for reason code '
                      || v_resoncode;
                   RAISE exp_reject_txn;
                WHEN OTHERS
                THEN
                   v_respcode := '21';
                   v_errmsg :=
                         'Error while selecting reason description'
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_txn;
             END;

          END IF;

     EXCEPTION 
	 WHEN exp_reject_txn
     THEN
        RAISE;
     WHEN OTHERS
     THEN
	   v_respcode := '21';
	   v_errmsg := 'Error from reason code block '||SUBSTR (SQLERRM, 1, 200);
	   RAISE exp_reject_txn;
     END;


      BEGIN
         sp_authorize_txn_cms_auth (prm_instcode,
                                    prm_msg_type,
                                    prm_rrn,
                                    prm_delivery_channel,
                                    NULL,
                                    prm_txn_code,
                                    prm_txn_mode,
                                    prm_trandate,
                                    prm_trantime,
                                    prm_pan_code,
                                    NULL,
                                    0,
                                    NULL,
                                    NULL,
                                    NULL,
                                    prm_currcode,
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
                                    prm_stan,
                                    prm_mbrnumb,
                                    prm_rvsl_code,
                                    NULL,
                                    v_auth_id,
                                    v_respcode,
                                    v_errmsg,
                                    v_capture_date
                                   );

         IF v_respcode <> '00'
         THEN

              BEGIN      
              

IF (v_Retdate>v_Retperiod)
    THEN                                         --added on 09-Oct-2012
                 UPDATE transactionlog
                    SET remark = prm_remark,
                        ipaddress = prm_ipaddress,
                        add_ins_user = prm_ins_user,
                        add_lupd_user = prm_ins_user,
                        reason        = v_reason,                  -- added on 06NOV2012
                        reason_code=v_resoncode                    -- added for mvhost-1255
                  WHERE instcode = prm_instcode
                    AND customer_card_no = v_hash_pan
                    AND rrn = prm_rrn
                    AND business_date = prm_trandate
                    AND business_time = prm_trantime
                    AND delivery_channel = prm_delivery_channel
                    AND txn_code = prm_txn_code;
                ELSE
                           UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                    SET remark = prm_remark,
                        ipaddress = prm_ipaddress,
                        add_ins_user = prm_ins_user,
                        add_lupd_user = prm_ins_user,
                        reason        = v_reason,                  -- added on 06NOV2012
                        reason_code=v_resoncode                    -- added for mvhost-1255
                  WHERE instcode = prm_instcode
                    AND customer_card_no = v_hash_pan
                    AND rrn = prm_rrn
                    AND business_date = prm_trandate
                    AND business_time = prm_trantime
                    AND delivery_channel = prm_delivery_channel
                    AND txn_code = prm_txn_code;
                  END IF;  

                 IF SQL%ROWCOUNT = 0
                 THEN
                    v_respcode := '21';
                    v_errmsg := 'Auth Fail - Txn not updated in transactiolog for remark ';
                    RAISE exp_reject_txn;
                 END IF;
              EXCEPTION
                 WHEN exp_reject_txn
                 THEN
                    RAISE;
                 WHEN OTHERS
                 THEN
                    v_respcode := '21';
                    v_errmsg :=
                          'Auth Fail - Error while updating into transactiolog '
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_txn;
              END;

            prm_resp_code := v_respcode;
            prm_resp_msg := v_errmsg;

            RETURN;

         END IF;

      EXCEPTION 
	  WHEN exp_reject_txn
      THEN
          RAISE;
      WHEN OTHERS
      THEN
            v_respcode := '21';
            v_errmsg :=
                  'problem while call to sp_authorize_txn_cmsauth '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_txn;
      END;


      BEGIN
         SELECT cap_cust_code, cap_mbr_numb, cap_proxy_number,
                cap_prod_code, cap_prod_catg, cap_card_type
           INTO v_cust_code, v_mbrnumb, v_proxynumber,
                v_prod_code, v_prodcatg, v_prod_cattype
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Pan not found in master';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg := 'from pan master ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;
    

      SELECT COUNT (*)
        INTO v_mailaddr_cnt
        FROM cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'O';

      SELECT COUNT (*)
        INTO v_phyaddr_cnt
        FROM cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'P';

      /*  call log info   start */
      BEGIN
         SELECT cut_table_list, cut_colm_list, cut_colm_qury
           INTO v_table_list, v_colm_list, v_colm_qury
           FROM cms_calllogquery_mast
          WHERE cut_inst_code = prm_instcode
            AND cut_devl_chnl = prm_delivery_channel
            AND cut_txn_code = prm_txn_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '16';
            v_errmsg := 'Column list not found in cms_calllogquery_mast ';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while finding Column list ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      IF prm_addrupd_flag = 'Y'
      THEN
         IF prm_mailing_zip IS NOT NULL
         THEN
            BEGIN
               SELECT gsm_state_code
                 INTO v_mail_state_chk
                 FROM gen_state_mast
                WHERE gsm_inst_code = prm_instcode
                  AND TRIM (gsm_cntry_code) = TRIM (prm_mailing_country)
                  AND TRIM (gsm_state_code) = TRIM (prm_mailing_state);

               v_mail_state_chk := NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'mailing state code '
                     || prm_mailing_state
                     || ' not found for country code '
                     || prm_mailing_country;
                  v_respcode := '16';
                  RAISE exp_reject_txn;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'while fecthing mailing state code '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_reject_txn;
            END;

            BEGIN
               SELECT gcm_cntry_code
                 INTO v_mail_cntry_chk
                 FROM gen_cntry_mast
                WHERE gcm_inst_code = prm_instcode
                  AND TRIM (gcm_cntry_code) = TRIM (prm_mailing_country);

               v_mail_cntry_chk := NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'mailing country code '
                     || prm_mailing_country
                     || ' not found in master';
                  v_respcode := '16';
                  RAISE exp_reject_txn;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'while fecthing mailing country code for cntry '
                     || prm_mailing_country
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_reject_txn;
            END;
         END IF;
      END IF;

      IF prm_phy_zip IS NOT NULL
      THEN
         BEGIN
            SELECT gsm_state_code
              INTO v_phy_state_chk
              FROM gen_state_mast
             WHERE gsm_inst_code = prm_instcode
               AND TRIM (gsm_cntry_code) = TRIM (prm_phy_country)
               AND TRIM (gsm_state_code) = TRIM (prm_phy_state);

            v_phy_state_chk := NULL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'physical state code not found for state '
                  || prm_phy_state
                  || ' and country code '
                  || prm_phy_country;
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'while fecthing physical state code '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;

         BEGIN
            SELECT gcm_cntry_code
              INTO v_phy_cntry_chk
              FROM gen_cntry_mast
             WHERE gcm_inst_code = prm_instcode
               AND TRIM (gcm_cntry_code) = TRIM (prm_phy_country);

            v_phy_cntry_chk := NULL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Physical country code not found for cntry '
                  || prm_phy_country;
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'while fecthing Physical country code for cntry '
                  || prm_phy_country
                  || ' '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      END IF;

      IF v_mailaddr_cnt > 0
      THEN
         BEGIN
            v_addr_flag := 'O';

            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_old_value_o
                        USING v_cust_code, v_addr_flag;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting old values -- '
                  || prm_addrupd_flag
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      ELSE
         v_old_value_o := 'Mailing Address not available ';
      END IF;

      v_old_value_o := 'O-|' || v_old_value_o;

      IF v_phyaddr_cnt > 0
      THEN
         BEGIN
            v_addr_flag := 'P';

            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_old_value_p
                        USING v_cust_code, v_addr_flag;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting old values -- '
                  || prm_addrupd_flag
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      ELSE
         v_old_value_p := 'Physical Address not available ';
      END IF;

      v_old_value_p := 'P-|' || v_old_value_p;
      v_old_value := v_old_value_o || '|' || v_old_value_p;

      -- SN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
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
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error While Selecting Spending account Number for Card '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_txn;
      END;

      -- EN : ADDED BY Ganesh on 18-JUL-12
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
               RAISE exp_reject_txn;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting frmo cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;

         INSERT INTO cms_calllog_details
                     (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                      ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                      ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                      ccd_colm_name, ccd_old_value, ccd_new_value,
                      ccd_comments, ccd_ins_user, ccd_ins_date,
                      ccd_lupd_user, ccd_lupd_date,
                      ccd_acct_no
                      )
              VALUES (prm_instcode, prm_call_id, v_hash_pan, v_call_seq,
                      prm_rrn, prm_delivery_channel, prm_txn_code,
                      prm_trandate, prm_trantime, v_table_list,
                      v_colm_list, v_old_value, NULL,
                      prm_remark, prm_ins_user, SYSDATE,
                      prm_ins_user, SYSDATE,
                      v_spnd_acctno
                      );
      EXCEPTION
         WHEN exp_reject_txn
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                ' Error while inserting into cms_calllog_details ' || SQLERRM;
            RAISE exp_reject_txn;
      END;

     BEGIN
         SELECT CPC_ENCRYPT_ENABLE
           INTO V_ENCRYPT_ENABLE
           FROM CMS_PROD_CATTYPE
          WHERE CPC_INST_CODE = PRM_INSTCODE 
            AND CPC_PROD_CODE = V_PROD_CODE
            AND CPC_CARD_TYPE = V_PROD_CATTYPE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Product Category not Found';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg := 'from prod catg mast ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;
      /*  call log info   END */
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_instcode AND cam_acct_no = prm_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'account not found in master';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg := 'from account master ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      BEGIN
         SELECT cip_param_value
           INTO v_date_format
           FROM cms_inst_param
          WHERE cip_inst_code = '1' AND cip_param_key = 'CSRDATEFORMAT';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Date format value not found in master';
            v_respcode := '49';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'While fetching date format from master '
               || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

       --Sn Added for FSS-2321
      BEGIN
         INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
              VALUES (prm_rrn, prm_delivery_channel, prm_txn_code, v_cust_code,prm_ins_user);
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;
      --En Added for FSS-2321
      
      IF V_ENCRYPT_ENABLE = 'Y' THEN
          v_encr_first_name := fn_emaps_main(prm_first_name);
          v_encr_last_name  := fn_emaps_main(PRM_LASTNAME); 
	        v_encr_mother_name  := fn_emaps_main(prm_maiden_name);
       else
          v_encr_first_name := prm_first_name;
          v_encr_last_name  := PRM_LASTNAME; 
	        v_encr_mother_name  := prm_maiden_name;
      end if; 
      
      
    if prm_currcode = '124' then

    IF   prm_id_province IS NOT NULL AND prm_id_country IS NOT NULL
      THEN
       begin
        SELECT gcm_switch_cntry_code
          INTO v_id_country
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = prm_instcode
          AND gcm_cntry_code  = prm_id_country;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '49';
          V_ERRMSG  := 'Invalid Data for ID Country code';
          RAISE exp_reject_txn;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_txn;
        END;


        BEGIN
          SELECT gsm_switch_state_code
          INTO v_id_province
          FROM gen_state_mast
          where gsm_inst_code   = prm_instcode
		    and gsm_alpha_cntry_code = (select gcm_alpha_cntry_code from gen_cntry_mast where gcm_switch_cntry_code=v_id_country and gcm_inst_code= 1)
            AND gsm_state_code  = prm_id_province;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '49';
          V_ERRMSG  := 'Invalid Data for ID Province';
          RAISE exp_reject_txn;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_txn;
        END;
    end if;
  
  
  else
    v_id_country:= NULL;
    v_id_province:= NULL;
end if;

if prm_currcode = '124' then

    IF  prm_jurisdiction_of_tax_res IS NOT NULL
      THEN
         begin
          SELECT gcm_switch_cntry_code
          INTO v_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = prm_instcode
          AND gcm_cntry_code  = prm_jurisdiction_of_tax_res;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '49';
          V_ERRMSG  := 'Invalid Data for Jurisdiction of Tax Residence';
          RAISE exp_reject_txn;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_txn;
        END;
    end if;

 else
    v_jurisdiction_of_tax_res:= NULL;
end if;

if prm_currcode = '124' then
 
   v_occupation:=prm_occupation;
    v_occupation_others:=prm_occupation_others;
    v_taxresistrentcanada:=prm_tax_res_of_canada;
    v_thirdpartyenabled:=prm_Thirdpartyenabled;
  else
    v_occupation:= NULL;
    v_occupation_others:= NULL;
    v_taxresistrentcanada:= NULL;
    v_thirdpartyenabled:= NULL;
 end if;
 
IF prm_addrupd_flag <>'M' THEN                                                             --Added on 23112012 by Dhiraj G as discussed with Tejas

          BEGIN
             UPDATE cms_cust_mast
                set CCM_LAST_NAME = v_encr_last_name,
                ccm_auth_user=prm_auth_user,                                                --Added for JH-3159
                    ccm_birth_date = TO_DATE (prm_dob, v_date_format),
                    ccm_ssn = fn_maskacct_ssn(prm_instcode,prm_ssn,0),
                    ccm_ssn_encr =fn_emaps_main(prm_ssn),
                    ccm_first_name  = v_encr_first_name,                                    --Added on 01NOV2012 as a new enhancement
                    ccm_mother_name = v_encr_mother_name,                                   --Added on 01NOV2012 as a new enhancement
                    ccm_id_type     = decode (prm_id_type, null, ccm_id_type, prm_id_type), --Added on 19FEB2013 for SSN changes
                    ccm_business_name = prm_business_name,
                    ccm_occupation=v_occupation,
                    ccm_occupation_others=v_occupation_others,
                    ccm_id_province=v_id_province,
                    ccm_id_country=v_id_country,
                    ccm_verification_date=to_date(prm_id_verification_date,v_date_format),
                    ccm_tax_res_of_canada=v_taxresistrentcanada,
                    ccm_tax_payer_id_num=prm_tax_payer_id_number,
                    ccm_reason_for_no_tax_id=prm_reason_for_no_tax_id,
                    ccm_reason_for_no_taxid_others=prm_reason_for_no_taxid_others,
                    ccm_jurisdiction_of_tax_res=v_jurisdiction_of_tax_res,
                    ccm_third_party_enabled=v_thirdpartyenabled,
                    ccm_first_name_encr = fn_emaps_main(prm_first_name),                                                                        --Modified for VMS-959
                    ccm_last_name_encr = fn_emaps_main(PRM_LASTNAME)                                                                            --Modified for VMS-959
              WHERE ccm_inst_code = prm_instcode
              AND ccm_cust_code = v_cust_code;

             IF SQL%ROWCOUNT = 0
             THEN
                v_errmsg := 'cust mast not updated for custcode ' || v_cust_code;
                v_respcode := '16';
                RAISE exp_reject_txn;
             END IF;
          EXCEPTION
             WHEN exp_reject_txn
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_errmsg :=
                      'Problem while updating cust mast for custcode '
                   || v_cust_code
                   || SUBSTR (SQLERRM, 1, 100);
                v_respcode := '21';
                RAISE exp_reject_txn;
          end;
       -- added bybaskar VMS-207


     If  prm_Thirdpartyenabled Is Not  Null And prm_Thirdpartyenabled='Y' 
     then
       begin
       select count(*) into v_thirdparty_count 
       from vms_thirdparty_address 
       where vta_cust_code=v_cust_code;    
       
       EXCEPTION       
        When Others Then
         v_respcode := '89';
         v_errmsg   := 'Error while select Count vms_thirdparty_address ' || Substr(Sqlerrm, 1, 300);
         raise exp_reject_txn;
      end;
      begin
      if prm_Thirdpartytype = '1' and prm_Thirdpartyenabled Is Not  Null And prm_Thirdpartyenabled='Y' then
      
       select vom_occu_name into v_occupation_desc 
       from vms_occupation_mast 
       where vom_occu_code =prm_thirdpartyoccupationtype;
       end if;
       EXCEPTION
        When No_Data_Found Then
         v_errmsg   := 'Invalid ThirdParty Occupation Code' ;
         v_respcode := '49';
         Raise exp_reject_txn;
          When Others Then
           v_respcode := '89';
           v_errmsg   := 'Error while selecting Vms_Occupation_Mast ' || Substr(Sqlerrm, 1, 300);
           raise exp_reject_txn;
      end;

      Begin
      
          select gcm_cntry_code into V_cntryCode  
          from gen_cntry_mast 
          where gcm_cntry_code=prm_ThirdPartyCountry
          and Gcm_Inst_Code=prm_instcode;
      
       EXCEPTION
        When No_Data_Found Then
          V_ERRMSG   := 'Invalid Country Code' ;
           V_RESPCODE := '49';
          Raise exp_reject_txn;
        When Others Then
         V_Respcode := '89';
         V_Errmsg   := 'Error while selecting gen_cntry_mast '  || Substr(Sqlerrm, 1, 300);
         Raise exp_reject_txn;
      end;
      
      If prm_thirdpartycountry Is Not Null And prm_thirdpartycountry  In ('3','2') Then             
      
      Begin
      v_state_code:=prm_thirdpartystate;
      
      Select Gsm_Switch_State_Code  Into V_State_Switch_Code 
      from Gen_State_Mast 
      Where Gsm_State_Code=prm_thirdpartystate 
      And Gsm_Cntry_Code=prm_thirdpartycountry 
      and Gsm_Inst_Code=prm_instcode;
      
      EXCEPTION
       When No_Data_Found Then
         v_errmsg   := 'Invalid ThirdParty State Code' ;
         v_respcode := '49';
         Raise exp_reject_txn;
      When Others Then
       v_respcode := '89';
       v_errmsg   := 'Error while selecting Gen_State_Mast ' || Substr(Sqlerrm, 1, 300);
       Raise exp_reject_txn;
      end;
      Else
         v_state_code:= NULL;
        v_state_desc:=prm_thirdpartystate;
        end if;
        
       If V_Thirdparty_Count>0
       then
 
          begin
             
           update vms_thirdparty_address set VTA_THIRDPARTY_TYPE=prm_thirdpartytype, vta_first_name=upper(prm_thirdpartyfirstname),vta_last_name=upper(prm_thirdpartylastname),
           VTA_ADDRESS_ONE=upper(prm_thirdpartyaddress1),VTA_ADDRESS_TWO=upper(prm_thirdpartyaddress2),vta_city_name=upper(prm_thirdpartycity),vta_state_code=v_state_code,
           Vta_State_Desc=upper(v_state_desc),
           vta_state_switch=V_State_Switch_Code,
           vta_cntry_code=prm_thirdpartycountry,vta_pin_code=upper(prm_thirdpartyzip),
           vta_occupation=prm_thirdpartyoccupationtype,
           vta_occupation_others=decode(prm_thirdpartyoccupationtype,'00',prm_thirdpartyoccupation,upper(v_occupation_desc)),                     
           VTA_NATURE_OF_BUSINESS=upper(prm_Thirdpartybusiness),VTA_CORPORATION_NAME=upper(prm_thirdpartycorporationname),
          VTA_INCORPORATION_NUMBER=upper(prm_thirdpartycorporation),Vta_Dob=TO_DATE(prm_thirdpartydob, v_date_format),VTA_NATURE_OF_RELEATIONSHIP=upper(prm_Thirdpartynature)
           where vta_inst_code=prm_instcode and vta_cust_code=v_cust_code;
          
          EXCEPTION
			  When Others Then
			   v_respcode := '89';
			   v_errmsg   := 'Error while updating third party  address details  in Vms_Thirdparty_Address ' || SUBSTR(SQLERRM, 1, 300);
			   raise exp_reject_txn;
          end ;

 
         ELSE
             begin
             
               insert into vms_thirdparty_address  (vta_inst_code ,vta_cust_code ,VTA_THIRDPARTY_TYPE,vta_first_name,vta_last_name,VTA_ADDRESS_ONE,VTA_ADDRESS_TWO,
               vta_city_name,vta_state_code,vta_state_desc,vta_state_switch,vta_cntry_code,vta_pin_code,vta_occupation ,vta_occupation_others ,VTA_NATURE_OF_BUSINESS,
               vta_dob,VTA_NATURE_OF_RELEATIONSHIP ,VTA_CORPORATION_NAME,VTA_INCORPORATION_NUMBER ,vta_ins_user ,vta_ins_date ,vta_lupd_user ,vta_lupd_date) 
                values(prm_instcode,v_cust_code,prm_thirdpartytype,upper(prm_thirdpartyfirstname),upper(prm_thirdpartylastname),upper(prm_thirdpartyaddress1),
                upper(prm_thirdpartyaddress2),upper(prm_thirdpartycity),v_state_code,upper(v_state_desc),V_State_Switch_Code,prm_Thirdpartycountry,upper(prm_thirdpartyzip),
                prm_thirdpartyoccupationtype,decode(prm_thirdpartyoccupationtype,'00',prm_thirdpartyoccupation,upper(v_occupation_desc)),upper(prm_thirdpartybusiness),
                TO_DATE(prm_thirdpartydob, v_date_format),upper(prm_Thirdpartynature),upper(prm_thirdpartycorporationname),upper(prm_thirdpartycorporation),1,sysdate,1,sysdate);
                                                
                
                 EXCEPTION
                    When Others Then
                     v_respcode := '89';
                     v_errmsg   := 'Error while Insert third party  address details  in Vms_Thirdparty_Address ' || SUBSTR(SQLERRM, 1, 300);
                     raise exp_reject_txn;
            end ;   
        End If;
 End If;
 
  
          IF prm_phy_zip IS NOT NULL
          THEN
          
          IF V_ENCRYPT_ENABLE = 'Y' THEN
             V_ZIPCODE := fn_emaps_main(prm_phy_zip);
             v_encr_addr_lineone := fn_emaps_main(prm_phy_addr1);
             v_encr_addr_linetwo := fn_emaps_main(prm_phy_addr2);
             v_encr_city := fn_emaps_main(prm_phy_city);
             v_encr_email := fn_emaps_main(prm_email);
             v_encr_phone_no := fn_emaps_main(prm_alternate_phone);
             v_encr_mob_one  := fn_emaps_main(prm_mobile_no);
        
         ELSE
             V_ZIPCODE :=prm_phy_zip;
             v_encr_addr_lineone := prm_phy_addr1;
             v_encr_addr_linetwo := prm_phy_addr2;
             v_encr_city := prm_phy_city;
             v_encr_email := prm_email;
             v_encr_phone_no := prm_alternate_phone;
             v_encr_mob_one  := prm_mobile_no;
         
         END IF;
          
          
             IF v_phyaddr_cnt > 0
             THEN
                BEGIN
   Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into L_Alert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=v_hash_pan  and CSA_INST_CODE=prm_instcode;
      
      EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;
  BEGIN
     select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    Where Nvl(Dbms_Lob.Substr( Cps_Alert_Msg,1,1),0) <> 0  
    And Cps_Prod_Code = v_Prod_Code
    And Cps_Card_Type = v_prod_cattype
    and cps_alert_id=33
    And Cps_Inst_Code= prm_instcode
      And ( Cps_Alert_Lang_Id = l_alert_lang_id or (l_alert_lang_id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
       Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
      If(Prm_Optin_Flag_Out = 'N' And ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then  
          Select Cam_Mobl_One Into V_Cam_Mobl_One From Cms_Addr_Mast
          Where Cam_Cust_Code=v_cust_code And Cam_Addr_Flag='P' And Cam_Inst_Code=prm_instcode;
          If(V_Encrypt_Enable = 'Y') Then 
            V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
            Else
            V_Decr_Cellphn := V_Cam_Mobl_One;
          End If;
            If(V_Decr_Cellphn <> prm_mobile_no)
            Then
                Prm_Optin_Flag_Out :='Y';
                End If; 
          End If;
      End If;
    EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;
            BEGIN
                   UPDATE cms_addr_mast
                      SET cam_add_one = v_encr_addr_lineone,
                          cam_add_two = v_encr_addr_linetwo,
                          cam_city_name = v_encr_city,
                          cam_pin_code = V_ZIPCODE,
                          cam_phone_one = v_encr_phone_no,
                          cam_mobl_one = v_encr_mob_one,
                          cam_state_code = prm_phy_state,
                          cam_cntry_code = prm_phy_country,
                          cam_email = v_encr_email,
                          --Sn:Modified for VMS-959
                          cam_add_one_encr = fn_emaps_main(prm_phy_addr1),
                          cam_add_two_encr = fn_emaps_main(prm_phy_addr2),
                          cam_city_name_encr = fn_emaps_main(prm_phy_city),
                          cam_pin_code_encr = fn_emaps_main(prm_phy_zip),
                          cam_email_encr = fn_emaps_main(prm_email)
                          --En:Modified for VMS-959
                    WHERE cam_inst_code = prm_instcode
                      AND cam_cust_code = v_cust_code
                      AND cam_addr_flag = 'P';
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'While updating physical addr for custcode-- '
                         || prm_addrupd_flag
                         || '---'
                         || v_cust_code
                         || SUBSTR (SQLERRM, 1, 100);
                      v_respcode := '21';
                      RAISE exp_reject_txn;
                END;
             ELSE
                BEGIN
                   INSERT INTO cms_addr_mast
                               (cam_inst_code, cam_cust_code,
                                cam_addr_code, cam_add_one,
                                cam_add_two, cam_pin_code, cam_phone_one,
                                cam_mobl_one, cam_cntry_code, cam_city_name,
                                cam_addr_flag, cam_state_code, cam_comm_type,
                                cam_ins_user, cam_ins_date, cam_lupd_user,
                                cam_lupd_date,
                                cam_add_one_encr,cam_add_two_encr,                  --Modified for VMS-959
                                cam_pin_code_encr, cam_city_name_encr               --Modified for VMS-959
                               )
                        VALUES (prm_instcode, v_cust_code,
                                seq_addr_code.NEXTVAL, v_encr_addr_lineone,
                                v_encr_addr_linetwo, V_ZIPCODE,
                                v_encr_phone_no, v_encr_mob_one, 
                                prm_phy_country, v_encr_city,
                                'P', prm_phy_state, 'R',
                                1, SYSDATE, 1,
                                SYSDATE,
                                --Sn:Modified for VMS-959
                                fn_emaps_main(prm_phy_addr1),
                                fn_emaps_main(prm_phy_addr2),
                                fn_emaps_main(prm_phy_zip),
                                fn_emaps_main(prm_phy_city)
                                --En:Modified for VMS-959
                               );
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'While inserting physical addr for custcode-- '
                         || prm_addrupd_flag
                         || '---'
                         || v_cust_code
                         || SUBSTR (SQLERRM, 1, 100);
                      v_respcode := '21';
                      RAISE exp_reject_txn;
                END;
             END IF;
             
             	--- Added for VMS-5253 / VMS-5372
		
             BEGIN 
            
                        UPDATE vmscms.CMS_CUST_MAST
                        SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                        WHERE CCM_INST_CODE = PRM_INSTCODE                       
                        AND CCM_CUST_CODE = V_CUST_CODE ;
                
                        EXCEPTION 
                        WHEN OTHERS
                        THEN
                            v_respcode := '21';
                            v_errmsg := 'ERROR WHILE UPDARING SYSTEM GENERATED PROFILE IN CUST MAST P ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_txn;            
             END;
           
          END IF;
      END IF  ;                                                            --Added on 23112012 by Dhiraj G as discussed with Tejas
      IF prm_addrupd_flag in ( 'Y' ,'M') 
      THEN
         IF prm_mailing_zip IS NOT NULL
            THEN
            
            IF V_ENCRYPT_ENABLE = 'Y' THEN
             V_ZIPCODE := fn_emaps_main(prm_mailing_zip);
             v_encr_addr_lineone := fn_emaps_main(prm_mailing_addr1);
             v_encr_addr_linetwo := fn_emaps_main(prm_mailing_addr2);
             v_encr_city := fn_emaps_main(prm_mailing_city);
             v_encr_phone_no := fn_emaps_main(prm_alternate_phone);
             v_encr_mob_one  := fn_emaps_main(prm_mobile_no);
        
     ELSE
             V_ZIPCODE :=prm_mailing_zip;
             v_encr_addr_lineone := prm_mailing_addr1;
             v_encr_addr_linetwo := prm_mailing_addr2;
             v_encr_city := prm_mailing_city;
             v_encr_phone_no := prm_alternate_phone;
             v_encr_mob_one  := prm_mobile_no;
         
         END IF;
            
            IF v_mailaddr_cnt > 0
            THEN
               BEGIN
                  UPDATE cms_addr_mast
                     SET cam_add_one = v_encr_addr_lineone,
                         cam_add_two = v_encr_addr_linetwo,
                         cam_city_name = v_encr_city,
                         cam_pin_code = V_ZIPCODE,
                         cam_state_code = prm_mailing_state,
                         cam_cntry_code = prm_mailing_country,
                         cam_mobl_one = v_encr_mob_one,
                         cam_phone_one = v_encr_phone_no,
                          --Sn:Modified for VMS-959
                         cam_add_one_encr = fn_emaps_main(prm_mailing_addr1),
                         cam_add_two_encr = fn_emaps_main(prm_mailing_addr2),
                         cam_city_name_encr = fn_emaps_main(prm_mailing_city),
                         cam_pin_code_encr = fn_emaps_main(prm_mailing_zip)
                          --En:Modified for VMS-959
                   WHERE cam_inst_code = prm_instcode
                     AND cam_cust_code = v_cust_code
                     AND cam_addr_flag = 'O';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'While updating mailing addr for custcode -- '
                        || prm_addrupd_flag
                        || '---'
                        || v_cust_code
                        || SUBSTR (SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            ELSE
               BEGIN
                  INSERT INTO cms_addr_mast
                              (cam_inst_code, cam_cust_code,
                               cam_addr_code, cam_add_one,
                               cam_add_two, cam_pin_code,
                               cam_phone_one, cam_mobl_one,
                               cam_cntry_code, cam_city_name, cam_addr_flag,
                               cam_state_code, cam_comm_type, cam_ins_user,
                               cam_ins_date, cam_lupd_user, cam_lupd_date,
                               cam_add_one_encr,cam_add_two_encr,                --Modified for VMS-959
                               cam_pin_code_encr,cam_city_name_encr              --Modified for VMS-959
                              )
                       VALUES (prm_instcode, v_cust_code,
                               seq_addr_code.NEXTVAL, v_encr_addr_lineone,
                               v_encr_addr_linetwo,V_ZIPCODE,
                               v_encr_phone_no, v_encr_mob_one,
                               prm_mailing_country, v_encr_city, 'O',
                               prm_mailing_state, 'R', 1,
                               SYSDATE, 1, SYSDATE,
                                --Sn:Modified for VMS-959
                               fn_emaps_main(prm_mailing_addr1),
                               fn_emaps_main(prm_mailing_addr2),
                               fn_emaps_main(prm_mailing_zip),
                               fn_emaps_main(prm_mailing_city)
                                --En:Modified for VMS-959
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'While inserting mailing addr for custcode -- '
                        || prm_addrupd_flag
                        || '---'
                        || v_cust_code
                        || SUBSTR (SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            END IF;
            
            	--- Added for VMS-5253 / VMS-5372
		
                BEGIN 
            
                        UPDATE vmscms.CMS_CUST_MAST
                        SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                        WHERE CCM_INST_CODE = PRM_INSTCODE                       
                        AND CCM_CUST_CODE = V_CUST_CODE ;
                
                        EXCEPTION 
                        WHEN OTHERS
                        THEN
                            v_respcode := '21';
                            v_errmsg := 'ERROR WHILE UPDARING SYSTEM GENERATED PROFILE IN CUST MAST M ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_txn;            
                END;
            
          
            
         end if;

            --Added by Narsing for MVCSD-4121
        BEGIN
              
          begin
           SELECT CCM_ADDRVERIFY_FLAG,ccm_cust_id,
                  decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name)||' '||
                  decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_last_name),ccm_last_name)
                  into v_addr_verif_flag,v_cust_id,v_cust_name --Added for JH-1961
                FROM cms_cust_mast
                  WHERE ccm_cust_code=v_cust_code
                  and CCM_INST_CODE  =PRM_INSTCODE;

                  EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  v_errmsg   := 'No Record found for Address verification flag reset';
                  v_respcode := '21';
                  RAISE exp_reject_txn;
                WHEN OTHERS THEN
                  v_errmsg   :='No Record found for Address verification flag reset '|| SUBSTR (SQLERRM, 1, 100);
                  V_RESPCODE := '21';
                  RAISE EXP_REJECT_TXN;
           End;
             IF v_addr_verif_flag = 1
             THEN
                UPDATE cms_cust_mast
                    SET ccm_addrverify_flag=2,
                      CCM_ADDVERIFY_DATE   =sysdate,
                      CCM_AVFSET_CHANNEL='03',--Mantis:14101 Added by Narsing I
                      CCM_AVFSET_TXNCODE='43'--Mantis:14101 Added by Narsing I
                    WHERE ccm_inst_code    =prm_instcode
                    AND ccm_cust_code      =v_cust_code;

                    v_cnt := SQL%ROWCOUNT;

                  IF v_cnt = 0
                    THEN
                       prm_resp_code := '99';
                       prm_resp_msg :=  'Error while reseting Address verification flag';
                       RAISE EXP_REJECT_TXN;

                  END IF;

                  BEGIN
                    SELECT NVL ((MAX (ccd_call_seq)), 0) + 1
                    INTO v_addrcallseq
                    FROM cms_calllog_details
                    WHERE ccd_inst_code = prm_instcode
                    AND ccd_call_id     = prm_call_id
                    AND CCD_PAN_CODE    =v_hash_pan;
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_errmsg   := 'Error while fetching call seq ID';
                    v_respcode := '21';
                    RAISE exp_reject_txn;
                  WHEN OTHERS THEN
                    v_errmsg   :='Error while fetching call seq ID '|| SUBSTR (SQLERRM, 1, 100);
                    V_RESPCODE := '21';
                    RAISE exp_reject_txn;
                END;

                 INSERT INTO cms_calllog_details
                            (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                             ccd_devl_chnl, ccd_txn_code,ccd_tran_date, ccd_tran_time,
                             ccd_comments, ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                             ccd_lupd_date,ccd_acct_no,ccd_rrn )
                      VALUES (prm_instcode, prm_call_id , v_hash_pan, v_addrcallseq ,
                             prm_delivery_channel, '43', prm_trandate, prm_trantime,
                             'Address verification flag reset through profile update', prm_ins_user, SYSDATE, prm_ins_user,
                             SYSDATE, prm_acct_no, prm_rrn );

                               v_cnt := SQL%ROWCOUNT;
                  IF v_cnt = 0
                    THEN
                       prm_resp_code := '99';
                       prm_resp_msg :=  'Error while inserting call seq ID';
                       RAISE EXP_REJECT_TXN;
                  END IF;

              BEGIN
                SELECT ctm_tran_desc
                    INTO v_trans_desc
                    FROM cms_transaction_mast
                    WHERE ctm_inst_code      = prm_instcode
                    AND ctm_tran_code        = '43'
                    AND ctm_delivery_channel =prm_delivery_channel ;

                   EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_errmsg   := 'Error while fetching transaction description';
                    v_respcode := '21';
                    RAISE exp_reject_txn;
                  WHEN OTHERS THEN
                    v_errmsg   :='Error while fetching transaction description '|| SUBSTR (SQLERRM, 1, 100);
                    V_RESPCODE := '21';
                    RAISE exp_reject_txn;
              END;

              BEGIN
                  SELECT LPAD(seq_auth_rrn.NEXTVAL,12,'0')
                  INTO addr_rrn FROM  DUAL;

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_errmsg   := 'Error while selecting rrn for address verification flag';
                    v_respcode := '21';
                    RAISE exp_reject_txn;
                  WHEN OTHERS THEN
                    v_errmsg   :='Error while selecting rrn for address verification flag '|| SUBSTR (SQLERRM, 1, 100);
                    V_RESPCODE := '21';
                    RAISE exp_reject_txn;
              END;

                 INSERT
                    INTO transactionlog
                      (
                        msgtype, rrn, delivery_channel, date_time,
                        txn_code, txn_type, txn_mode, txn_status,
                        business_date, business_time, customer_card_no,
                        total_amount, currencycode, productid, categoryid,
                        auth_id, trans_desc, amount, instcode, customer_card_no_encr,
                        proxy_number, reversal_code, acct_balance, ledger_balance,
                        customer_acct_no, add_ins_user, add_lupd_user, ipaddress,
                        error_msg, response_code,response_id,add_ins_date, CR_DR_flag
                      )
                      VALUES
                      (
                        prm_msg_type, addr_rrn, prm_delivery_channel,
                        TO_DATE (prm_trandate
                        || ' ' || prm_trantime, 'yyyymmdd hh24miss' ),
                        '43','N', prm_txn_mode, 'C',
                        prm_trandate, prm_trantime, v_hash_pan,
                        TRIM (TO_CHAR (0, '99999999999999990.99')), prm_currcode, v_prod_code, v_prod_cattype,
                        v_auth_id, v_trans_desc, TRIM (TO_CHAR (0, '99999999999999990.99')), prm_instcode, v_encr_pan,
                        v_proxynumber, prm_rvsl_code, v_acct_balance, v_ledger_balance,
                        prm_acct_no, prm_ins_user, prm_ins_user, prm_ipaddress,
                        'OK', '00', '1' , SYSDATE,'NA'
                      ) ;

                         v_cnt := SQL%ROWCOUNT;

                  IF v_cnt = 0
                   THEN
                    prm_resp_code := '99';
                     prm_resp_msg :=  'Error while inserting into transactionlog for address verification flag reset';
                     RAISE EXP_REJECT_TXN;

                  END IF;
                  prm_resp_code := '00';
                  prm_resp_msg :=  'Address verification flag Updated Successfully';


             END IF;

              EXCEPTION
                  WHEN exp_reject_txn
                 THEN
                    RAISE;
                    WHEN OTHERS
                    THEN
                       v_errmsg :=
                             'Error while Reseting address verification flag '
                          || SUBSTR (SQLERRM, 1, 100);
                       v_respcode := '99';
                       RAISE exp_reject_txn;

        END ;
        --End Narsing for MVCSD-4121
         --Sn Added for JH-1961


         BEGIN
           SELECT COUNT (*)
           INTO v_pending_cnt
           FROM CMS_AVQ_STATUS
           WHERE cas_inst_code = prm_instcode
           AND CAS_CUST_ID     = v_cust_id
          and CAS_AVQ_FLAG    = 'P';
		EXCEPTION
			WHEN OTHERS THEN
			v_respcode := '21';
			V_ERRMSG  :='Error while selecting pending count-'|| SUBSTR (SQLERRM, 1, 200);
			RAISE exp_reject_txn;
			
        end;

         BEGIN
        SELECT gsm_switch_state_code
        INTO v_state_code
        FROM GEN_STATE_MAST
        WHERE GSM_INST_CODE   =prm_instcode
        AND GSM_CNTRY_CODE  =prm_mailing_country
        AND GSM_STATE_CODE=PRM_MAILING_STATE;
      EXCEPTION
      when NO_DATA_FOUND then
        V_ERRMSG  := 'Invalid Data for Mailing Address State';
        v_respcode := '21';
      WHEN OTHERS THEN
         v_respcode := '21';
        V_ERRMSG  :='Error while selecting state detail-'|| SUBSTR (SQLERRM, 1, 200);
      end;

        begin
       IF  V_ENCRYPT_ENABLE = 'Y' then
              v_encr_cas_addr_one:=fn_emaps_main(PRM_MAILING_ADDR1);
              v_encr_cas_addr_two:=fn_emaps_main(PRM_MAILING_ADDR2);
              v_encr_cas_city_name:=fn_emaps_main(PRM_MAILING_CITY);
              v_encr_cas_postal_code:=fn_emaps_main (PRM_MAILING_ZIP);
			  v_encr_full_name := fn_emaps_main(v_cust_name);
          else
              v_encr_cas_addr_one:=PRM_MAILING_ADDR1;
              v_encr_cas_addr_two:=PRM_MAILING_ADDR2;
              v_encr_cas_city_name:=PRM_MAILING_CITY;
              v_encr_cas_postal_code:=PRM_MAILING_ZIP;
              v_encr_full_name := v_cust_name;  
        END IF;
	
        if(V_PENDING_CNT > 0 ) then
        
        update CMS_AVQ_STATUS set CAS_ADDR_ONE=v_encr_cas_addr_one,CAS_ADDR_TWO=v_encr_cas_addr_two,CAS_CITY_NAME=v_encr_cas_city_name,
         CAS_STATE_NAME=v_state_code,CAS_POSTAL_CODE=v_encr_cas_postal_code,CAS_LUPD_USER=PRM_INS_USER,CAS_LUPD_DATE=sysdate
         WHERE cas_inst_code = prm_instcode
          AND CAS_CUST_ID     = v_cust_id
        and CAS_AVQ_FLAG    = 'P';

        ELSE

        BEGIN
          SELECT COUNT (*)
            INTO v_pending_cnt
           FROM CMS_AVQ_STATUS
           WHERE cas_inst_code = prm_instcode
          AND CAS_CUST_ID     = v_cust_id
        and CAS_AVQ_FLAG    = 'F';
	EXCEPTION
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  :='Error while selecting pending count for AVQ FLAg - F-'|| SUBSTR (SQLERRM, 1, 200);
	  RAISE exp_reject_txn;
        END;

        IF v_pending_cnt <> 0 THEN

                      BEGIN
                         SELECT pan.cap_pan_code ,pan.cap_pan_code_encr
                           INTO v_gprhash_pan ,v_gprencr_pan
                           FROM cms_appl_pan pan , cms_cardissuance_status stat
                          WHERE pan.cap_appl_code = stat.ccs_appl_code
                            AND pan.cap_pan_code = stat.ccs_pan_code
                            AND pan.cap_inst_code = stat.ccs_inst_code
                            AND pan.cap_inst_code = prm_instcode
                            AND stat.ccs_card_status='17'
                            AND pan.cap_card_stat <> '9'
                            AND pan.cap_cust_code =v_cust_code
                            AND pan.cap_startercard_flag = 'N';
                      EXCEPTION
					  WHEN NO_DATA_FOUND THEN
							NULL;
                         WHEN OTHERS
                         THEN
                            v_respcode := '21';
                            V_ERRMSG := 'Error while selecting (gpr card)details from appl_pan :'
                               || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_txn;
                      END;


        IF(v_gprhash_pan IS NOT NULL) THEN
        insert into CMS_AVQ_STATUS(CAS_INST_CODE,CAS_CUST_ID,CAS_PAN_CODE,CAS_PAN_ENCR,CAS_CUST_NAME,CAS_ADDR_ONE,CAS_ADDR_TWO,CAS_CITY_NAME,CAS_STATE_NAME,CAS_POSTAL_CODE,CAS_AVQ_FLAG,
        CAS_AVQSTAT_ID,CAS_INS_USER,CAS_INS_DATE)
        values (PRM_INSTCODE,V_CUST_ID,v_gprhash_pan,v_gprencr_pan,v_encr_full_name,v_encr_cas_addr_one,v_encr_cas_addr_two,v_encr_cas_city_name,v_state_code,v_encr_cas_postal_code,'P',
        AVQ_SEQ.NEXTVAL,PRM_INS_USER,sysdate);
        end if;
        end if;

        end if;

         EXCEPTION

             WHEN OTHERS
             THEN
                V_ERRMSG :=
                      'Problem while updating CMS_AVQ_STATUS for custcode '
                   || v_cust_code
                   || SUBSTR (SQLERRM, 1, 100);
                v_respcode := '21';
          END;
--En Added for JH-1961
      END IF;

      BEGIN

         INSERT INTO cms_pan_spprt
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                      cps_func_remark, cps_ins_user, cps_ins_date,
                      cps_lupd_user, cps_lupd_date, cps_cmd_mode,
                      cps_pan_code_encr
                     )
              VALUES (prm_instcode, v_hash_pan, v_mbrnumb,
                      v_prodcatg, decode(prm_reason_code,NULL,'PROFUPD','PROFILE'), decode(prm_reason_code,NULL,63,prm_reason_code),
                      prm_remark, prm_ins_user, SYSDATE,
                      prm_ins_user, SYSDATE, 0,
                      v_encr_pan
                     );

         v_cnt := SQL%ROWCOUNT;

         IF v_cnt = 0
         THEN
            v_respcode := '21';
            v_errmsg := 'No records inserted in pan support';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting in panspprt '
               || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      --Sn get record for successful transaction
      v_respcode := '1';

      SELECT COUNT (*)
        INTO v_mailaddr_cnt1
        FROM cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'O';

      SELECT COUNT (*)
        INTO v_phyaddr_cnt1
        FROM cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'P';

      /*  call log info   start  */
      IF v_mailaddr_cnt1 > 0
      THEN
         BEGIN
            v_addr_flag := 'O';

            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_value_o
                        USING v_cust_code, v_addr_flag;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting new values   for mailing address '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      ELSE
         v_new_value_o := 'Mailing Address not available ';
      END IF;

      IF v_phyaddr_cnt1 > 0
      THEN
         BEGIN
            v_addr_flag := 'P';

            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_value_p
                        USING v_cust_code, v_addr_flag;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting new values  for physical address '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      ELSE
         v_new_value_p := 'Mailing Physical not available ';
      END IF;

      v_new_value := 'O-|' || v_new_value_o || '|' || 'P-|' || v_new_value_p;

      BEGIN
         UPDATE cms_calllog_details
            SET ccd_new_value = v_new_value
          WHERE ccd_inst_code = prm_instcode
            AND ccd_call_id = prm_call_id
            AND ccd_pan_code = v_hash_pan
            AND ccd_call_seq = v_call_seq;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg := 'call log details is not updated for ' || prm_call_id;
            v_respcode := '16';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating call log details   '
               || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      /*  call log info   end  */
      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delivery_channel
            AND cms_response_id = v_respcode;

         prm_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Problem while selecting data from response master1 '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      --En get record for successful transaction

      BEGIN
      
      
IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET remark = prm_remark,
                ipaddress = prm_ipaddress, --added by amit on 06-Oct-2012
                add_ins_user = prm_ins_user, --added by amit on 06-Oct-2012
                add_lupd_user = prm_ins_user, --added by amit on 06-Oct-2012
                REASON        = v_reason,     -- added on 06NOV2012
                reason_code=v_resoncode  -- added for mvhost-1255
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_trandate
            AND business_time = prm_trantime
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
        ELSE
        UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = prm_remark,
                ipaddress = prm_ipaddress, --added by amit on 06-Oct-2012
                add_ins_user = prm_ins_user, --added by amit on 06-Oct-2012
                add_lupd_user = prm_ins_user, --added by amit on 06-Oct-2012
                REASON        = v_reason,     -- added on 06NOV2012
                reason_code=v_resoncode  -- added for mvhost-1255
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_trandate
            AND business_time = prm_trantime
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
          END IF;      

         IF SQL%ROWCOUNT = 0
         THEN
            v_respcode := '21';
            v_errmsg := 'Txn not updated in transactiolog for remark';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;
   EXCEPTION
      WHEN exp_reject_txn
      THEN
         ROLLBACK;

         BEGIN

            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_respcode;

            prm_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master2 '
                  || v_respcode
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

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
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_trandate, prm_trantime,
                         v_hash_pan, NULL, prm_currcode,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         prm_acct_no, prm_instcode
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                    'unsucessful records inserted in transactionlog detail 1';
               RETURN;
            END IF;

            --prm_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '99';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_ins_user, --added by amit on 06-Oct-2012
                         add_lupd_user, --added by amit on 06-Oct-2012
                         ipaddress, --added by amit on 06-Oct-2012
                         remark, --added by amit on 06-Oct-2012
                         REASON,  -- added on 06NOV2012
                         reason_code  -- added for mvhost-1255
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_trandate || ' ' || prm_trantime,
                                  'yyyymmdd hh24miss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_trandate, prm_trantime,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_currcode, v_prod_code, v_prod_cattype,
                         v_auth_id, prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_instcode, 'NA',
                         v_encr_pan, v_proxynumber, prm_rvsl_code,
                         prm_acct_no, v_acct_balance, v_ledger_balance,
                         v_respcode, prm_resp_msg,
                         prm_ins_user,  --added by amit on 06-Oct-2012
                         prm_ins_user,  --added by amit on 06-Oct-2012
                         prm_ipaddress, --added by amit on 06-Oct-2012
                         prm_remark,     --added by amit on 06-Oct-2012
                         v_reason,        -- added on 06NOV2012
                         v_resoncode     -- added for mvhost-1255
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg :=
                       'unsucessful records not inserted in transactionlog 1';
               RETURN;
            END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '99';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      --En create a entry in txn log
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = '21';

            prm_resp_msg :=
                    'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master3 '
                  || v_respcode
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

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
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_trandate, prm_trantime,
                         v_hash_pan, NULL, prm_currcode,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         prm_acct_no, prm_instcode
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg :=
                  'unsucessful records not inserted in transactionlog detail 2';
               RETURN;
            END IF;

            --prm_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '99';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log dtl2'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_ins_user, --added by amit on 06-Oct-2012
                         add_lupd_user, --added by amit on 06-Oct-2012
                         ipaddress, --added by amit on 06-Oct-2012
                         remark, --added by amit on 06-Oct-2012
                         REASON,  -- added on 06NOV2012
                         reason_code  -- added for mvhost-1255
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_trandate || ' ' || prm_trantime,
                                  'yyyymmdd hh24miss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_trandate, prm_trantime,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_currcode, v_prod_code, v_prod_cattype,
                         v_auth_id, prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_instcode, 'NA',
                         v_encr_pan, v_proxynumber, prm_rvsl_code,
                         prm_acct_no, v_acct_balance, v_ledger_balance,
                         v_respcode, prm_resp_msg,
                         prm_ins_user,  --added by amit on 06-Oct-2012
                         prm_ins_user,  --added by amit on 06-Oct-2012
                         prm_ipaddress, --added by amit on 06-Oct-2012
                         prm_remark,    --added by amit on 06-Oct-2012
                         v_reason,       --Added on 06NOV2012
                         v_resoncode     -- added for mvhost-1255
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN

               prm_resp_code := '99';
               prm_resp_msg :=  'unsucessful record not inserted in transactionlog 2';
               RETURN;

            END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '99';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log4 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

   END;
END;

/
show error