create or replace
PROCEDURE     VMSCMS.SP_UPDATE_PROFILE
                                (P_INSTCODE                      IN        NUMBER,
                                 P_RRN                           IN        VARCHAR2,
                                 P_TERMINALID                    IN        VARCHAR2,
                                 P_STAN                          IN        VARCHAR2,
                                 P_TRANDATE                      IN        VARCHAR2,
                                 P_TRANTIME                      IN        VARCHAR2,
                                 P_ACCTNO                        IN        VARCHAR2,
                                 P_CURRCODE                      IN        VARCHAR2,
                                 P_MSG_TYPE                      IN        VARCHAR2,
                                 P_TXN_CODE                      IN        VARCHAR2,
                                 P_TXN_MODE                      IN        VARCHAR2,
                                 P_DELIVERY_CHANNEL              IN        VARCHAR2,
                                 P_MBR_NUMB                      IN        VARCHAR2,
                                 P_RVSL_CODE                     IN        VARCHAR2,
                                 P_DOB                           IN        DATE,
                                 P_FIRST_NAME                    IN        VARCHAR2,
                                 P_MIDDLE_NAME                   IN        VARCHAR2,
                                 P_LAST_NAME                     IN        VARCHAR2,
                                 P_ADDR_LINEONE                  IN        VARCHAR2,
                                 P_ADDR_LINETWO                  IN        VARCHAR2,
                                 P_CITY                          IN        VARCHAR2,
                                 P_ZIP                           IN        VARCHAR2,
                                 P_PHONE_NO                      IN        VARCHAR2,
                                 P_OTHER_NO                      IN        VARCHAR2,
                                 P_EMAIL                         IN        VARCHAR2,
                                 P_STATE                         IN        VARCHAR2,
                                 P_CNTRY_CODE                    IN        VARCHAR2,
                                 P_PROD_ID                       IN        VARCHAR2,
                                 P_PROD_CATG                     IN        VARCHAR2,
                                 P_MERCHANT_NAME                 IN        VARCHAR2,
                                 P_MERCHANT_CITY                 IN        VARCHAR2,
								 P_MAILADDR_LINEONE              IN        VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
								 P_MAILADDR_LINETWO              IN        VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
								 P_MAILADDR_CITY                 IN        VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
								 P_MAILADDR_STATE                IN        VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
								 P_MAILADDR_ZIP                  IN        VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
								 P_MAILADDR_CNRYCODE             IN        VARCHAR2, -- Added by MageshKumar.S on 25/04/2013
                                 P_MEDAGATE_REF_ID               IN        VARCHAR2, --ADDED BY NAILA FOR MEDAGATE CHANGE
								 P_ID_TYPE                       IN        VARCHAR2,
								 P_ID_NUMBER                     IN        VARCHAR2,
								 P_ID_EXPIRY_DATE                IN        VARCHAR2,
								 P_TYPE_OF_EMPLOYMENT            IN        VARCHAR2,
								 P_OCCUPATION                    IN        VARCHAR2,
								 P_ID_PROVINCE                   IN        VARCHAR2,
								 P_ID_COUNTRY                    IN        VARCHAR2,
								 P_ID_VERIFICATION_DATE          IN        VARCHAR2,
								 P_TAX_RES_OF_CANADA             IN        VARCHAR2,
								 P_Tax_Payer_Id_Number           In        Varchar2,
                                 P_REASON_FOR_NO_TAX_ID_tYPE     IN        VARCHAR2,
								 P_REASON_FOR_NO_TAX_ID          IN        VARCHAR2,
								 P_JURISDICTION_OF_TAX_RES       IN        VARCHAR2,
                                 p_ThirdPartyEnabled             In        Varchar2,
                                 p_ThirdPartyType                In        Varchar2,
                                 p_ThirdPartyFirstName           In        Varchar2,
                                 p_ThirdPartyLastName            In        Varchar2,
                                 p_ThirdPartyCorporationName     In        Varchar2,
                                 p_ThirdPartyCorporation         In        Varchar2,
                                 p_ThirdPartyAddress1            In        Varchar2,
                                 p_ThirdPartyAddress2            In        Varchar2,
                                 p_ThirdPartyCity                In        Varchar2,
                                 p_ThirdPartyState               In        Varchar2,
                                 p_ThirdPartyZIP                 In        Varchar2,
                                 p_ThirdPartyCountry             In        Varchar2,
                                 p_ThirdPartyNatureRelationship  In        Varchar2,
                                 p_ThirdPartyBusiness            In        Varchar2,
                                 p_ThirdPartyOccupationType      In        Varchar2,
                                 p_ThirdPartyOccupation          In        Varchar2,
                                 p_ThirdPartyDOB                 In        Varchar2,									  
								 P_RESP_CODE        		    OUT 	   VARCHAR2,
                                 P_ERRMSG           		    OUT 	   VARCHAR2,
                                 P_LEDGER_BAL       		    OUT        VARCHAR2,        --ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
                                 p_optin_flag_out               OUT        VARCHAR2
                     ) AS
  /*************************************************
    * Modified By      :  B.Dhinkaaran
    * Modified Date    :  10-Sep-2012
    * Modified Reason  : Loogging the merchant details in txn log table
    * Reviewer         : Saravana Kumar
    * Reviewed Date    : 11-Sep-2012
    * Build Number     :  CMS3.5.1_RI0015.3

    * Modified By      : MageshKumar S.
    * Modified Date    : 25-Apr-2013
    * Modified Reason  : Logging of Mailing Address changes in Addr mast(DFCHOST-310)
    * Reviewer         : Dhiraj
    * Reviewed Date    : 29-Apr-2013
    * Build Number     : RI0024.0.1_B004

    * Modified By      : Ramesh
    * Modified Date    : 14-Jun-2013
    * Modified for     : MVHOST 382
    * Modified Reason  : For profile update for new delivery channel medagate(14)
    * Reviewer         : Dhiraj
    * Reviewed Date    : 29-Apr-2013
    * Build Number     : RI0024.2_B0004

    * Modified By      : Ramesh
    * Modified Date    : 28-Jun-2013
    * Modified for     : defect id :  0011443
    * Modified Reason  : Profile Update transaction throws ORA error when processed through API
    * Reviewer         :
    * Reviewed Date    :
    * Build Number     : RI0024.2_B0011

    * Modified By      : Siva Kumar
    * Modified Date    : 17-Sept-2013
    * Modified for     : defect id :  0012382
    * Modified Reason  : Default PIN Flag : Medagate Activaiton : SSN is blank.
    * Reviewer         : Dhiraj
    * Reviewed Date    :
    * Build Number     : RI0024.4_B0016

     * Modified By      : Pankaj S.
     * Modified Date    : 12-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0027_B003

      * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893/EEP2.1
     * Modified Reason   : To return the ledger balance and available balance for medagate/Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 10-Mar-2014
     * Build Number      : RI0027.2_B0002

     * Modified By      : Ravi N
     * Modified Date    : 17-Apr-2014
     * Modified Reason  : Mantis:0014216 should update empty value if the ¿phonenumber¿ or MobileNO is blank or not received from reqquest
     * Reviewer         : spankaj
     * Build Number     : RI0027.3_B0001

     * Modified by      : MageshKumar S.
     * Modified Date    : 25-July-14
     * Modified For     : FWR-48
     * Modified reason  : GL Mapping removal changes
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0001

     * Modified by      : Ramesh A
     * Modified Date    : 12-DEC-14
     * Modified For     : FSS-1961(Melissa)
     * Reviewer         : Spankaj
     * Build Number     : RI0027.5_B0002

     * Modified By      : Ramesh A
     * Modified Reason  : Perf changes
     * Modified Date    : 06/MAR/2015
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 06/MAR/2015
     * Build Number     : 2.5

     * Modified by      :Spankaj
     * Modified Date    : 07-Sep-15
     * Modified For     : FSS-2321
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOSTCSD3.2

      * Modified by      :Saravanakumar A
     * Modified Date    : 13-Oct-16
     * Modified For     : FSS-4844
     * Reviewer         : PankajS
     * Build Number     : VMSGPRHOSTCSD4.10

	 * Modified by       :T.Narayanaswamy
     * Modified Date    : 24-March-17
     * Modified For     : JIRA-FSS-4647 (AVQ Status issue)
     * Reviewer         : Saravanankumar/Pankaj
     * Build Number     : VMSGPRHOSTCSD_17.03_B0003

	 * Modified by      : T.Narayanaswamy
     * Modified Date    : 04-Apr-17
     * Modified For     : FSS-5070
     * Modified reason  : Remove Hardcode/Implement Configuration for Minimum Age Validation: MMPOS
     * Reviewer         : Saravanakumar/Spankaj
     * Build Number     : VMSGPRHOST 17.4

	 * Modified by      : Vini Pushkaran
     * Modified Date    : 24-Nov-17
     * Modified For     : VMS-74
     * Reviewer         : Saravanakumar A
     * Build Number     : VMSGPRHOST 17.11

     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
		 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01
	 
	 * Modified by      :  Vini Pushkaran
      * Modified Date    :  02-Feb-2018
      * Modified For     :  VMS-162
      * Reviewer         :  Saravanankumar
      * Build Number     :  VMSGPRHOSTCSD_18.01
      
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
    
    * Modified By      :  Ubaidur Rahman.H
    * Modified Date    :  03-Dec-2021
    * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
    * Reviewer         :  Saravanakumar
    * Build Number     :  VMSGPRHOST_R55_RELEASE
  *************************************************/
  V_CAP_PROD_CATG       CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT       CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG     CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP     CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ERRMSG              TRANSACTIONLOG.ERROR_MSG%TYPE;
  V_CURRCODE            CMS_TRANSACTION_LOG_DTL.CTD_TXN_CURR%TYPE;
  V_APPL_CODE           CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE            TRANSACTIONLOG.RESPONSE_ID%TYPE;
  V_RESPMSG             TRANSACTIONLOG.ERROR_MSG%TYPE;
   
  V_CAPTURE_DATE        DATE;
  V_MBRNUMB             CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
 
  V_TXN_TYPE            CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID         TRANSACTIONLOG.AUTH_ID%TYPE;
  
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
    
  V_BASE_CURR           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_TRAN_DATE           DATE;
  V_ACCT_BALANCE        CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_LEDGER_BALANCE      CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_BUSINESS_DATE       DATE;
  V_BUSINESS_TIME       VARCHAR2(12);
  V_CUTOFF_TIME         VARCHAR2(5);
  V_CUST_CODE           CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
    
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_AUTHID_DATE        TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_TRANS_DESC         CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
  V_DR_CR_FLAG         CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_OUTPUT_TYPE        CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
  V_TRAN_TYPE          CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  
  v_mailing_addr_count          PLS_INTEGER;
  v_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE ; -- Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
  v_phys_switch_state_code      cms_addr_mast.cam_state_switch%TYPE ; -- Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
  v_curr_code                   gen_cntry_mast.gcm_curr_code%TYPE ; -- Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310

--Added for MVHOST-382 on 13/06/2013
                       
  V_MAILADDR_LINEONE    CMS_ADDR_MAST.CAM_ADD_ONE%TYPE;	             
  V_MAILADDR_LINETWO    CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;            
  V_MAILADDR_CITY       cms_addr_mast.CAM_CITY_NAME%type;            
  V_MAILADDR_ZIP        CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;            
  V_KYC_FLAG            CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;  ---added for defect id:12382  on 17/Sept/2013

  --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_acct_type          cms_acct_mast.cam_type_code%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   --Added for FSS-1961(Melissa)
   V_AVQ_STATUS         PLS_INTEGER;
   V_CUST_ID            CMS_CUST_MAST.CCM_CUST_ID%TYPE;
   V_FULL_NAME          CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
   v_gprhash_pan        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   V_GPRENCR_PAN        CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   v_check_flag         varchar2(1):='N';
   --END Added for FSS-1961(Melissa)

   v_agecal             PLS_INTEGER;
   V_KYC_AGE            CMS_PROD_CATTYPE.CPC_MIN_AGE_KYC%TYPE;
   V_PROD_CODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
   V_CARD_TYPE          CMS_appl_pan.cap_card_type%TYPE;

   v_id_province               GEN_STATE_MAST.GSM_SWITCH_STATE_CODE%TYPE;
   v_id_country                GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   v_jurisdiction_of_tax_res   GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   V_PROFILE_CODE              CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   v_encrypt_enable            cms_prod_cattype.cpc_encrypt_enable%TYPE;
   V_ENCR_ADDR_LINEONE         CMS_ADDR_MAST.CAM_ADD_ONE%TYPE;
   V_ENCR_ADDR_LINETWO         CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;
   v_encr_city                 cms_addr_mast.CAM_CITY_NAME%type;
   V_ENCR_EMAIL                CMS_ADDR_MAST.CAM_EMAIL%TYPE;
   V_ENCR_PHONE_NO             CMS_ADDR_MAST.CAM_PHONE_ONE%TYPE;
   V_ENCR_MOB_ONE              CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;
   V_ENCR_ZIP                  CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;
   V_ENCR_M_ADDR_LINEONE       CMS_ADDR_MAST.CAM_ADD_ONE%TYPE;
   V_ENCR_M_ADDR_LINETWO       CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;
   V_ENCR_M_CITY               CMS_ADDR_MAST.CAM_CITY_NAME%TYPE;
   V_ENCR_M_EMAIL              CMS_ADDR_MAST.CAM_EMAIL%TYPE;
   V_ENCR_M_PHONE_NO           CMS_ADDR_MAST.CAM_PHONE_ONE%TYPE;
   V_ENCR_M_MOB_ONE            CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;
   V_ENCR_M_ZIP                CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;
   V_ENCR_FIRST_NAME           CMS_CUST_MAST.CCM_FIRST_NAME%TYPE; 
   V_ENCR_LAST_NAME            CMS_CUST_MAST.CCM_LAST_NAME%TYPE;
   V_ENCR_MID_NAME             CMS_CUST_MAST.CCM_MID_NAME%TYPE;
   v_encr_full_name            CMS_AVQ_STATUS.CAS_CUST_NAME%TYPE;
   V_Decr_Cellphn              Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One              Cms_Addr_Mast.Cam_Mobl_One%Type;
   L_Alert_Lang_Id             Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
   V_Doptin_Flag               PLS_INTEGER;
   
   Type CurrentAlert_Collection Is Table Of Varchar2(30);
   CurrentAlert                 CurrentAlert_Collection;
   
   v_loadcredit_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag                CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag           CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag           CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag              CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag             Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag          CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag                Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type; 
   V_Federal_State_Flag         Cms_Smsandemail_Alert.Csa_Fedtax_Refund_Flag%Type;
   V_Thirdparty_Count           PLS_INTEGER;
   V_Occupation_Desc            Vms_Occupation_Mast.Vom_Occu_Name%Type;
   V_State_Switch_Code          Gen_State_Mast.Gsm_Switch_State_Code%Type;
   V_Cntrycode                  gen_cntry_mast.gcm_cntry_code%type;
   V_State_Desc                 Vms_Thirdparty_Address.Vta_State_Desc%Type;
   V_state_code                 Vms_Thirdparty_Address.Vta_State_code%Type;
   
   v_update_excp                EXCEPTION;  -- Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
   EXP_REJECT_RECORD            EXCEPTION;
   EXP_MAIN_REJECT_RECORD       EXCEPTION;
   EXP_AUTH_REJECT_RECORD       EXCEPTION;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN

  P_ERRMSG := 'OK';
 p_optin_flag_out := 'N';
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_ACCTNO);

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_ACCTNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN create encr pan

   --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,CTM_TRAN_DESC
     INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC --Added for transaction detail report on 210812
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
     V_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_RESPCODE := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  --Sn Transaction Date Check

  BEGIN

    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Date Check

  --Sn Transaction Time Check
  BEGIN

    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Time Check

  V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

  IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
  ELSE
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
  END IF;



  BEGIN
    SELECT CAP_CARD_STAT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_CUST_CODE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
		     CAP_PROD_CODE,
         cap_card_type
     INTO V_CAP_CARD_STAT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_CUST_CODE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         V_PROD_CODE,
         v_card_type
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Invalid Card number ' || P_ACCTNO;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting card number ' || P_ACCTNO;
     RAISE EXP_MAIN_REJECT_RECORD;

  END;
  -- getting kyc flag added for defect id:12382  on 17/Sept/2013




BEGIN
        SELECT cpc_min_age_kyc,CPC_PROFILE_CODE , cpc_encrypt_enable
        INTO v_kyc_age,v_profile_code , v_encrypt_enable
        FROM CMS_PROD_CATTYPE
        WHERE cpc_prod_code=v_prod_code
        AND cpc_card_type  =v_card_type
        AND cpc_inst_code  =P_INSTCODE
        ;
      EXCEPTION
      WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting KYC Age-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
      END;


  BEGIN

    IF P_DELIVERY_CHANNEL in ('04','14') THEN --Modified for MVHOST-382 on 13/06/2013

     BEGIN

            SELECT TRIM (cbp_param_value)
	     INTO v_base_curr
	     FROM cms_bin_param
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code = v_profile_code;

       IF V_BASE_CURR IS NULL THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency cannot be null ';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the BIN ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting base currency for profile  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;

    ELSE
     V_CURRCODE := P_CURRCODE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting the Delivery Channel of MMPOS  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;
 
-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, P_TRANDATE, P_DELIVERY_CHANNEL, P_MSG_TYPE, p_txn_code, V_ERRMSG );
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

    BEGIN
        SELECT CCI_KYC_FLAG
    INTO V_KYC_FLAG
    FROM CMS_CAF_INFO_ENTRY
    WHERE CCI_INST_CODE=P_INSTCODE AND
    CCI_APPL_CODE=to_char(V_APPL_CODE); --Added for Performance changes

   EXCEPTION
  WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting KYC FLAG  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;

  END;
 
 BEGIN
      --Sn KYC age validation
        v_agecal := (TRUNC(sysdate)-p_dob)/365;

        if v_agecal < 0 then

          V_RESPCODE := '21';
          V_ERRMSG   := 'Error while calculating KYC age, DOB should not be future date';
         RAISE EXP_MAIN_REJECT_RECORD;

        end if;
      EXCEPTION
      WHEN exp_reject_record THEN
       RAISE;
      WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while calculating KYC age-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      --En KYC age validation

      --En KYC age validation
      IF v_agecal   < v_kyc_age THEN
        V_RESPCODE := '11';
        V_ERRMSG   := 'Age Limit Verification Failed';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
-- added for FSS-5070 - Remove Hardcode/Implement Configuration for Minimum Age Validation: MMPOS END

  -- Customer information update
 IF p_cntry_code IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013
   -- Sn Added on 25-Apr-2013 by MageshKumar.S for Defect Id:DFCHOST-310
  BEGIN
            SELECT GCM_CURR_CODE
            INTO v_curr_code
            FROM GEN_CNTRY_MAST
            WHERE GCM_CNTRY_CODE = p_cntry_code
            AND GCM_INST_CODE = p_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
         v_respcode := '168';
         v_errmsg := 'Invalid Data for Country Code' || p_cntry_code;
         RAISE exp_main_reject_record;
   WHEN OTHERS THEN
   v_respcode := '21';
     V_ERRMSG := 'Error while selecting currency code ' || SUBSTR (SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

    IF p_state IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013

     BEGIN
         SELECT GSM_SWITCH_STATE_CODE
         INTO v_phys_switch_state_code
         FROM  GEN_STATE_MAST
         WHERE  GSM_STATE_CODE = p_state
         AND GSM_CNTRY_CODE = p_cntry_code
         AND GSM_INST_CODE = p_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
        v_respcode := '167';
         v_errmsg := 'Invalid Data for Physical Address State' || p_state;
         RAISE exp_main_reject_record;
  WHEN OTHERS THEN
     v_respcode := '21';
     V_ERRMSG := 'Error while selecting switch state code ' || SUBSTR (SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;  --Added for MVHOST-382 on 13/06/2013
 END IF;   --Added for MVHOST-382 on 13/06/2013

   --Sn Added for FSS-2321
  BEGIN
     INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
          VALUES (p_rrn, p_delivery_channel, p_txn_code, v_cust_code,1);
  EXCEPTION
     WHEN OTHERS THEN
        v_respcode := '21';
        v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
  END;
  --En Added for FSS-2321
  
     IF V_ENCRYPT_ENABLE = 'Y' THEN
        v_encr_addr_lineone := fn_emaps_main(P_ADDR_LINEONE);
		v_encr_addr_linetwo := fn_emaps_main(P_ADDR_LINETWO);
		v_encr_city         := fn_emaps_main(P_CITY);
		v_encr_email        := fn_emaps_main(P_EMAIL);
		v_encr_phone_no     := fn_emaps_main(P_PHONE_NO);
		v_encr_mob_one      := fn_emaps_main(P_OTHER_NO);
		v_encr_zip          := fn_emaps_main(P_ZIP);
     ELSE
        v_encr_addr_lineone := P_ADDR_LINEONE;
		v_encr_addr_linetwo := P_ADDR_LINETWO;
		v_encr_city         := P_CITY;
		v_encr_email        := P_EMAIL;
		v_encr_phone_no     := P_PHONE_NO;
		v_encr_mob_one      := P_OTHER_NO;
		v_encr_zip          := P_ZIP;
     END IF;

  BEGIN
   Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into L_Alert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=V_Hash_Pan   and CSA_INST_CODE=P_Instcode;
    
     EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
    BEGIN
  select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    WHERE nvl(dbms_lob.substr( cps_alert_msg,1,1),0) <>0  
    And Cps_Prod_Code = V_Prod_Code
    AND CPS_CARD_TYPE = v_card_type
    And Cps_Inst_Code= P_Instcode
    And Cps_Alert_Id=33
      And ( Cps_Alert_Lang_Id = l_alert_lang_id or (l_alert_lang_id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
      Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
         If(P_Optin_Flag_Out = 'N' And ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then   
       Select Cam_Mobl_One Into V_Cam_Mobl_One From Cms_Addr_Mast
       Where Cam_Cust_Code=V_Cust_Code And Cam_Addr_Flag='P' And Cam_Inst_Code=P_Instcode;         
        If(V_Encrypt_Enable = 'Y') Then 
            V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
            Else
            V_Decr_Cellphn := V_Cam_Mobl_One;
          End If;
               If(V_Decr_Cellphn <> P_Other_No)
               Then
                p_optin_flag_out :='Y';
                End If;
        End If;
      End If;
   EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting product category alerts(double optin) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;  
    BEGIN   
  --Query Modified for MVHOST-382 on 13/06/2013
      UPDATE CMS_ADDR_MAST
      SET CAM_ADD_ONE    = NVL(v_encr_addr_lineone,CAM_ADD_ONE),
         CAM_ADD_TWO    = NVL(v_encr_addr_linetwo,CAM_ADD_TWO),
         CAM_CITY_NAME  = NVL(v_encr_city,CAM_CITY_NAME),
         CAM_PIN_CODE   = NVL(v_encr_zip,CAM_PIN_CODE),
 --Commented on 17/04/14 for Mantis:0014216--should update empty value if the ¿phonenumber/MobileNo¿ is blank or not received from request
--       CAM_PHONE_ONE  = NVL(P_PHONE_NO,CAM_PHONE_ONE),
--       CAM_MOBL_ONE   = NVL(P_OTHER_NO,CAM_MOBL_ONE),
       --Modifed on 17/04/14 for Mantis:0014216--should update empty value if the phonenumber/MobileNo is blank or not received from request
         CAM_PHONE_ONE  = v_encr_phone_no,
         CAM_MOBL_ONE   = v_encr_mob_one,
         CAM_EMAIL      = NVL(v_encr_email,CAM_EMAIL),
         CAM_STATE_CODE = NVL(P_STATE,CAM_STATE_CODE),
         CAM_CNTRY_CODE = NVL(P_CNTRY_CODE,CAM_CNTRY_CODE),
         cam_state_switch = NVL(v_phys_switch_state_code,cam_state_switch), --Added for FSS-1961(Melissa)
         CAM_ADD_ONE_ENCR = NVL(fn_emaps_main(P_ADDR_LINEONE),CAM_ADD_ONE_ENCR),
         CAM_ADD_TWO_ENCR = NVL(fn_emaps_main(P_ADDR_LINETWO),CAM_ADD_TWO_ENCR),
         CAM_CITY_NAME_ENCR = NVL(fn_emaps_main(P_CITY),CAM_CITY_NAME_ENCR),
         CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_ZIP),CAM_PIN_CODE_ENCR),
         CAM_EMAIL_ENCR = NVL(fn_emaps_main(p_email),CAM_EMAIL_ENCR)
    WHERE CAM_CUST_CODE = V_CUST_CODE AND CAM_INST_CODE = P_INSTCODE AND
         CAM_ADDR_FLAG = 'P';

         IF SQL%ROWCOUNT =0
                 THEN
                 V_ERRMSG := 'No rows Updated for Physical Address';
                    RAISE v_update_excp;
                  END IF;
                  --- Added for VMS-5253 / VMS-5372
		  
        IF (P_ADDR_LINEONE IS NOT NULL) OR  (P_ADDR_LINETWO IS NOT NULL) OR (P_CITY IS NOT NULL) OR (P_ZIP IS NOT NULL)
        THEN
        
            BEGIN 
            
            UPDATE vmscms.CMS_CUST_MAST
            SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
            WHERE CCM_INST_CODE = P_INSTCODE                       
            AND CCM_CUST_CODE = V_CUST_CODE ;
            
            EXCEPTION 
            WHEN OTHERS
            THEN
                v_respcode := '21';
                v_errmsg := 'ERROR WHILE UPDARING SYSTEM GENERATED PROFILE IN CUST MAST P- ' || SUBSTR (SQLERRM, 1, 200);
                RAISE v_update_excp;            
            END;
        
        END IF;
    EXCEPTION
         WHEN v_update_excp THEN
         v_respcode := '21';
        --- V_ERRMSG := 'ERROR IN PROFILE UPDATE' || V_CUST_CODE;
          RAISE EXP_MAIN_REJECT_RECORD;
            WHEN OTHERS
            THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;

  END;
 
     IF P_MAILADDR_CNRYCODE IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013
        BEGIN

                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = p_mailaddr_cnrycode
                AND GCM_INST_CODE = p_instcode;

             EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
             v_respcode := '6';
             v_errmsg := 'Invalid Data for Mailing Address Country Code' || p_mailaddr_cnrycode;
             RAISE exp_main_reject_record;
              WHEN OTHERS THEN
              v_respcode := '21';
              V_ERRMSG := 'Error while selecting mailing country code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
             END;

         IF  P_MAILADDR_STATE IS NOT NULL THEN  --Added for MVHOST-382 on 13/06/2013

            BEGIN

            SELECT GSM_SWITCH_STATE_CODE
            INTO v_mailing_switch_state_code
            FROM  GEN_STATE_MAST
            WHERE  GSM_STATE_CODE = p_mailaddr_state
            AND GSM_CNTRY_CODE = p_mailaddr_cnrycode
            AND GSM_INST_CODE = p_instcode;

            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             v_respcode := '169';
             v_errmsg := 'Invalid Data for Mailing Address State' || p_mailaddr_state;
             RAISE exp_main_reject_record;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting mailing switch state code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
            END;
        END IF; --Added for MVHOST-382 on 13/06/2013
      END IF;  --Added for MVHOST-382 on 13/06/2013

        BEGIN

        SELECT count(1)
          INTO v_mailing_addr_count
          FROM cms_addr_mast
          WHERE cam_cust_code = V_CUST_CODE
          AND cam_inst_code = P_INSTCODE
          AND cam_addr_flag = 'O';
          EXCEPTION
         WHEN OTHERS THEN
         v_respcode := '21';
         V_ERRMSG := 'Error while selecting mailing address count ' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;
		
		        IF V_ENCRYPT_ENABLE = 'Y' THEN
					v_encr_m_addr_lineone := fn_emaps_main(P_MAILADDR_LINEONE);
					v_encr_m_addr_linetwo := fn_emaps_main(P_MAILADDR_LINETWO);
					v_encr_m_city         := fn_emaps_main(P_MAILADDR_CITY);
					v_encr_m_email        := fn_emaps_main(P_EMAIL);
					v_encr_m_phone_no     := fn_emaps_main(P_PHONE_NO);
					v_encr_m_mob_one      := fn_emaps_main(P_OTHER_NO);
					v_encr_m_zip          := fn_emaps_main(P_MAILADDR_ZIP);
				 ELSE
					v_encr_m_addr_lineone := P_MAILADDR_LINEONE;
					v_encr_m_addr_linetwo := P_MAILADDR_LINETWO;
					v_encr_m_city         := P_MAILADDR_CITY;
					v_encr_m_email        := P_EMAIL;
					v_encr_m_phone_no     := P_PHONE_NO;
					v_encr_m_mob_one      := P_OTHER_NO;
					v_encr_m_zip          := P_MAILADDR_ZIP;
				 END IF;
         IF v_mailing_addr_count <> 0

         THEN

            BEGIN
            --Query modified for MVHOST-382 on 13/06/2013
			v_check_flag:='Y';
				
                 UPDATE cms_addr_mast
                 SET cam_add_one = NVL(v_encr_m_addr_lineone,cam_add_one),
                     cam_add_two = NVL(v_encr_m_addr_linetwo,cam_add_two),
                     cam_city_name = NVL(v_encr_m_city,cam_city_name),
                     cam_pin_code = NVL(v_encr_m_zip,cam_pin_code),
                     --Commented on 17/04/14 for Mantis:0014216--should update empty value if the ¿phonenumber/MobileNo¿ is blank or not received from request
                     --cam_phone_one = NVL(P_PHONE_NO,cam_phone_one),
                     --cam_mobl_one = NVL(P_OTHER_NO,cam_mobl_one),
                  --Modifed on 17/04/14 for Mantis:0014216--should update empty value if the phonenumber/MobileNo is blank or not received from request
                     cam_phone_one = v_encr_m_phone_no,
                     cam_mobl_one = v_encr_m_mob_one,
                  --End
                     cam_email = NVL(v_encr_m_email,cam_email),
                     cam_state_code = NVL(P_MAILADDR_STATE,cam_state_code),
                     cam_cntry_code =NVL( P_MAILADDR_CNRYCODE,cam_cntry_code),
                     cam_state_switch = NVL(v_mailing_switch_state_code,cam_state_switch), --Added for FSS-1961(Melissa)
                     CAM_ADD_ONE_ENCR = NVL(fn_emaps_main(P_MAILADDR_LINEONE),CAM_ADD_ONE_ENCR),
                     CAM_ADD_TWO_ENCR = NVL(fn_emaps_main(P_MAILADDR_LINETWO),CAM_ADD_TWO_ENCR),
                     CAM_CITY_NAME_ENCR = NVL(fn_emaps_main(P_MAILADDR_CITY),CAM_CITY_NAME_ENCR),
                     CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_MAILADDR_ZIP),CAM_PIN_CODE_ENCR),
                     CAM_EMAIL_ENCR = NVL(fn_emaps_main(P_EMAIL),CAM_EMAIL_ENCR)
               WHERE cam_cust_code = V_CUST_CODE
                 AND cam_inst_code = P_INSTCODE
                 AND cam_addr_flag = 'O';

                 IF SQL%ROWCOUNT =0
                 THEN
                    V_ERRMSG := 'No rows Updated for Mailing Address';
                     RAISE v_update_excp;
                  END IF;
                  
                  --- Added for VMS-5253 / VMS-5372
		  
                    IF (P_MAILADDR_LINEONE IS NOT NULL) OR  (P_MAILADDR_LINETWO IS NOT NULL) OR (P_MAILADDR_CITY IS NOT NULL) OR (P_MAILADDR_ZIP IS NOT NULL)
                    THEN
                    
                    BEGIN 
            
                        UPDATE vmscms.CMS_CUST_MAST
                        SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                        WHERE CCM_INST_CODE = P_INSTCODE                       
                        AND CCM_CUST_CODE = V_CUST_CODE ;
                
                        EXCEPTION 
                        WHEN OTHERS
                        THEN
                            v_respcode := '21';
                            v_errmsg := 'ERROR WHILE UPDARING SYSTEM GENERATED PROFILE IN CUST MAST M-1 ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE v_update_excp;            
                        END;
                    END IF;
            EXCEPTION
             WHEN v_update_excp THEN
             v_respcode := '21';
            --- V_ERRMSG := 'Error while updating mailing address ' || V_CUST_CODE;
              RAISE EXP_MAIN_REJECT_RECORD;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while updating mailing address ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
            END;

         ELSE
         IF P_MAILADDR_LINEONE IS NOT NULL AND P_MAILADDR_CNRYCODE IS NOT NULL AND P_MAILADDR_CITY IS NOT NULL  THEN  --Added for defect id : 0011443 on 28/06/2013
             BEGIN
                    v_check_flag:='Y';
                     INSERT INTO cms_addr_mast
                                 (cam_inst_code,
                                  cam_cust_code,
                                  cam_addr_code,
                                  cam_add_one,
                                  cam_add_two,
                                  cam_phone_one,
                                  cam_mobl_one,
                                  cam_email,
                                  cam_pin_code,
                                  cam_cntry_code,
                                  cam_city_name,
                                  cam_addr_flag,
                                  cam_state_code,
                                  cam_state_switch,
                                  cam_ins_user,
                                  cam_ins_date,
                                  cam_lupd_user,
                                  cam_lupd_date,
                                  CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,
                                  CAM_CITY_NAME_ENCR,
                                  CAM_PIN_CODE_ENCR,CAM_EMAIL_ENCR
                                 )
                          VALUES (P_INSTCODE,
                                  V_CUST_CODE,
                                  seq_addr_code.NEXTVAL,
                                  v_encr_m_addr_lineone,
                                  v_encr_m_addr_linetwo,
                                  v_encr_m_phone_no,
                                  v_encr_m_mob_one,
                                  v_encr_m_email,
                                  v_encr_m_zip,
                                  P_MAILADDR_CNRYCODE,
                                  v_encr_m_city,
                                  'O',
                                  P_MAILADDR_STATE,
                                  v_mailing_switch_state_code,
                                  1,
                                  SYSDATE,
                                  1,
                                  SYSDATE,
                                  fn_emaps_main(P_MAILADDR_LINEONE),
                                  fn_emaps_main(P_MAILADDR_LINETWO),
                                  fn_emaps_main(P_MAILADDR_CITY),
                                  fn_emaps_main(P_MAILADDR_ZIP),
                                  fn_emaps_main(P_EMAIL)
                                 );
             EXCEPTION
             WHEN OTHERS THEN
                V_RESPCODE := '21';
                V_ERRMSG   := 'Error whiling inserting Mailing Address' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
             END;
          elsif P_ADDR_LINEONE is not null and  P_CNTRY_CODE is not null and P_CITY is not null then --Added for FSS-1961(Melissa)
           BEGIN
                      v_check_flag:='Y';
                     INSERT INTO cms_addr_mast
                                 (cam_inst_code,
                                  cam_cust_code,
                                  cam_addr_code,
                                  cam_add_one,
                                  cam_add_two,
                                  cam_phone_one,
                                  cam_mobl_one,
                                  cam_email,
                                  cam_pin_code,
                                  cam_cntry_code,
                                  cam_city_name,
                                  cam_addr_flag,
                                  cam_state_code,
                                  cam_state_switch,
                                  cam_ins_user,
                                  cam_ins_date,
                                  cam_lupd_user,
                                  cam_lupd_date,
                                  CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,
                                  CAM_CITY_NAME_ENCR,
                                  CAM_PIN_CODE_ENCR,CAM_EMAIL_ENCR
                                 )
                          VALUES (P_INSTCODE,
                                  V_CUST_CODE,
                                  seq_addr_code.NEXTVAL,
                                  v_encr_addr_lineone,
                                  v_encr_addr_linetwo,
                                  v_encr_phone_no,
                                  v_encr_mob_one,
                                  v_encr_email,
                                  v_encr_zip,
                                  P_CNTRY_CODE,
                                  v_encr_city,
                                  'O',
                                  P_STATE,
                                  v_phys_switch_state_code,
                                  1,
                                  SYSDATE,
                                  1,
                                  SYSDATE,
                                  fn_emaps_main(P_ADDR_LINEONE),
                                  fn_emaps_main(P_ADDR_LINETWO),
                                  fn_emaps_main(P_CITY),
                                  fn_emaps_main(P_ZIP),
                                  fn_emaps_main(P_EMAIL)
                                 );
             EXCEPTION
             WHEN OTHERS THEN
                V_RESPCODE := '21';
                V_ERRMSG   := 'Error whiling inserting Mailing Address' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
             END;
         --END Added for FSS-1961(Melissa)
           END IF;  --Added for defect id : 0011443 on 28/06/2013
           
           	--- Added for VMS-5253 / VMS-5372
		
                BEGIN 
            
                    UPDATE vmscms.CMS_CUST_MAST
                    SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                    WHERE CCM_INST_CODE = P_INSTCODE                       
                    AND CCM_CUST_CODE = V_CUST_CODE ;
                
                EXCEPTION 
                        WHEN OTHERS
                        THEN
                            v_respcode := '21';
                            v_errmsg := 'ERROR WHILE UPDARING SYSTEM GENERATED PROFILE IN CUST MAST M-2 ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_MAIN_REJECT_RECORD;            
                END;

         END IF;

        --END IF; --Commented for MVHOST-382 on 13/06/2013

      --Added for FSS-1961(Melissa)
      IF V_CHECK_FLAG='Y' THEN
              BEGIN

                  SELECT cust.ccm_cust_id,
				         decode(v_encrypt_enable,'Y', fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)||' '
                         ||decode(v_encrypt_enable,'Y', fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
                         decode(v_encrypt_enable,'Y', fn_dmaps_main(addr.cam_add_one),addr.cam_add_one),
						 decode(v_encrypt_enable,'Y', fn_dmaps_main(addr.cam_add_two),addr.cam_add_two),
						 decode(v_encrypt_enable,'Y', fn_dmaps_main(addr.cam_city_name),addr.cam_city_name),
						 addr.cam_state_switch,
						 decode(v_encrypt_enable,'Y', fn_dmaps_main(addr.cam_pin_code),addr.cam_pin_code)
                   INTO V_CUST_ID,V_FULL_NAME,V_MAILADDR_LINEONE,V_MAILADDR_LINETWO,
                        V_MAILADDR_CITY,v_mailing_switch_state_code,V_MAILADDR_ZIP
                   FROM CMS_CUST_MAST cust,cms_addr_mast addr
                   WHERE addr.cam_inst_code = cust.ccm_inst_code
                   AND addr.cam_cust_code = cust.ccm_cust_code
                   AND cust.CCM_INST_CODE = P_INSTCODE
                   AND cust.CCM_CUST_CODE = V_CUST_CODE
                   and addr.cam_addr_flag='O';

           EXCEPTION
             WHEN NO_DATA_FOUND THEN
             v_respcode := '21';
             V_ERRMSG := 'Mailing Addess Not Found';
              RAISE EXP_MAIN_REJECT_RECORD;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;

          END;
		  
		        IF V_ENCRYPT_ENABLE = 'Y' THEN
					v_encr_m_addr_lineone := fn_emaps_main(V_MAILADDR_LINEONE);
					v_encr_m_addr_linetwo := fn_emaps_main(V_MAILADDR_LINETWO);
					v_encr_m_city         := fn_emaps_main(V_MAILADDR_CITY);
					v_encr_m_zip          := fn_emaps_main(V_MAILADDR_ZIP);
					v_encr_full_name      := fn_emaps_main(V_FULL_NAME);
				 ELSE
					v_encr_m_addr_lineone := V_MAILADDR_LINEONE;
					v_encr_m_addr_linetwo := V_MAILADDR_LINETWO;
					v_encr_m_city         := V_MAILADDR_CITY;
					v_encr_m_zip          := V_MAILADDR_ZIP;
					v_encr_full_name      := V_FULL_NAME;
				 END IF;

          BEGIN

              SELECT COUNT(1) INTO V_AVQ_STATUS
              FROM CMS_AVQ_STATUS
              WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='P';

			   
                IF V_AVQ_STATUS = 1 THEN

                    UPDATE CMS_AVQ_STATUS
                          SET CAS_ADDR_ONE=NVL(v_encr_m_addr_lineone,CAS_ADDR_ONE),
                              CAS_ADDR_TWO=NVL(v_encr_m_addr_linetwo,CAS_ADDR_TWO),
                              CAS_CITY_NAME =NVL(v_encr_m_city,CAS_CITY_NAME),
                              CAS_STATE_NAME=NVL(v_mailing_switch_state_code,CAS_STATE_NAME),
                              CAS_POSTAL_CODE =NVL(v_encr_m_zip,CAS_POSTAL_CODE),
                              CAS_LUPD_USER=1,
                              CAS_LUPD_DATE=sysdate
                    WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='P';

                  -- SQL%ROWCOUNT =0 not required

                  else

                    BEGIN
                      SELECT COUNT(1) INTO V_AVQ_STATUS
                      FROM CMS_AVQ_STATUS
                      WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='F';

                      IF V_AVQ_STATUS <> 0 THEN

                           BEGIN
                             SELECT pan.cap_pan_code ,pan.cap_pan_code_encr
                               INTO v_gprhash_pan ,v_gprencr_pan
                               FROM cms_appl_pan pan, cms_cardissuance_status issu_stat
                              WHERE pan.cap_appl_code = issu_stat.ccs_appl_code
                                AND pan.cap_pan_code = issu_stat.ccs_pan_code
                                AND pan.cap_inst_code = issu_stat.ccs_inst_code
                                AND pan.cap_inst_code = P_INSTCODE
                                AND issu_stat.ccs_card_status='17'
                                AND pan.cap_cust_code =V_CUST_CODE
                                AND pan.cap_startercard_flag = 'N';
                          EXCEPTION
						  WHEN NO_DATA_FOUND THEN
							NULL;
                             WHEN OTHERS
                             THEN
                                v_respcode := '21';
                                V_ERRMSG := 'Error while selecting (gpr card)details from appl_pan :'
                                   || SUBSTR (SQLERRM, 1, 200);
                                RAISE EXP_MAIN_REJECT_RECORD;
                          end;
                          IF(v_gprhash_pan IS NOT NULL) THEN
                          INSERT INTO CMS_AVQ_STATUS
                          (CAS_INST_CODE,
                           CAS_AVQSTAT_ID,
                           CAS_CUST_ID,
                           CAS_PAN_CODE,
                           CAS_PAN_ENCR,
                           CAS_CUST_NAME,
                           CAS_ADDR_ONE,
                           CAS_ADDR_TWO,
                           CAS_CITY_NAME,
                           CAS_STATE_NAME,
                           CAS_POSTAL_CODE,
                           CAS_AVQ_FLAG,
                           CAS_INS_USER,
                           CAS_INS_DATE)
                          VALUES
                          (P_INSTCODE,
                           AVQ_SEQ.NEXTVAL,
                           V_CUST_ID,
                           V_HASH_PAN,
                           V_ENCR_PAN,
                           v_encr_full_name,
                           v_encr_m_addr_lineone,
                           v_encr_m_addr_linetwo,
                           v_encr_m_city,
                           v_mailing_switch_state_code,
                           v_encr_m_zip,
                           'P',
                           1,
                           SYSDATE);
						   END IF;
                      END IF;
                     EXCEPTION
                      when EXP_MAIN_REJECT_RECORD then
                     raise;
                      WHEN OTHERS THEN
                       V_RESPCODE := '21';
                       V_ERRMSG := 'Exception while Inserting in CMS_AVQ_STATUS Table ' ||
                                 SUBSTR(SQLERRM, 1, 200);
                       RAISE EXP_MAIN_REJECT_RECORD;
                  END;

                END IF;
              EXCEPTION
                 WHEN EXP_MAIN_REJECT_RECORD THEN
                  RAISE;
                 WHEN OTHERS THEN
                   v_respcode := '21';
                   V_ERRMSG := 'Error while updating mailing address(AVQ) ' || SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_MAIN_REJECT_RECORD;
          END;
     end if;
       --END Added for FSS-1961(Melissa)
      -- En Added on 25-Apr-2013 by MageshKumar.S for Defect Id:DFCHOST-310

	IF   p_id_province IS NOT NULL AND p_id_country IS NOT NULL
      THEN
       BEGIN
        SELECT GCM_CNTRY_CODE
          INTO v_id_country
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_instcode
          AND GCM_SWITCH_CNTRY_CODE = p_id_country ;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '274';
          V_ERRMSG  := 'Invalid Data for ID Country code';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;


        BEGIN
          SELECT gsm_switch_state_code
          INTO v_id_province
          FROM gen_state_mast
          WHERE gsm_inst_code   = p_instcode
		    AND gsm_cntry_code = v_id_country
            AND gsm_switch_state_code  = p_id_province;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '273';
          V_ERRMSG  := 'Invalid Data for ID Province';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;
    END IF;

	IF  p_jurisdiction_of_tax_res IS NOT NULL
      THEN
         BEGIN
          SELECT GCM_SWITCH_CNTRY_CODE
          INTO v_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_instcode
          AND GCM_SWITCH_CNTRY_CODE = p_jurisdiction_of_tax_res ;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '275';
          V_ERRMSG  := 'Invalid Data for Jurisdiction of Tax Residence';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;
    END IF;
	
	 IF V_ENCRYPT_ENABLE = 'Y' THEN
        v_encr_first_name := fn_emaps_main(P_FIRST_NAME);
		v_encr_mid_name   := fn_emaps_main(P_MIDDLE_NAME);
		v_encr_last_name  := fn_emaps_main(P_LAST_NAME);
     ELSE
        v_encr_first_name := P_FIRST_NAME;
		v_encr_mid_name   := P_MIDDLE_NAME;
		v_encr_last_name  := P_LAST_NAME;
     END IF;

	BEGIN
        --Query modified for MVHOST-382 on 13/06/2013
        UPDATE CMS_CUST_MAST
          SET CCM_BIRTH_DATE = NVL(P_DOB,CCM_BIRTH_DATE),
             CCM_FIRST_NAME = NVL(v_encr_first_name,CCM_FIRST_NAME),
             CCM_MID_NAME   = NVL(v_encr_mid_name,CCM_MID_NAME),
             CCM_LAST_NAME  =NVL(v_encr_last_name,CCM_LAST_NAME),
			 ccm_occupation  =  NVL(p_occupation,ccm_occupation),
             ccm_id_type = NVL(UPPER(p_id_type),ccm_id_type),
			 ccm_ssn  = NVL2(p_id_number,fn_maskacct_ssn(p_instcode,p_id_number,0),ccm_ssn),
			 CCM_SSN_ENCR = NVL2(p_id_number,fn_emaps_main(p_id_number),CCM_SSN_ENCR),
             ccm_id_province = NVL(p_id_province,ccm_id_province),
             ccm_id_country = NVL(p_id_country,ccm_id_country),
             ccm_idexpry_date =  NVL(DECODE (UPPER(p_id_type),
                                'SSN', NULL,'SIN', NULL,
                                 TO_DATE (p_id_expiry_date, 'mmddyyyy')
                                  ),ccm_idexpry_date),
             ccm_verification_date =  NVL(DECODE (UPPER(p_id_type),
                                'SSN', NULL,'SIN', NULL,
                                 TO_DATE (p_id_verification_date, 'mmddyyyy')
                                  ),ccm_verification_date),
             ccm_tax_res_of_canada  = NVL(p_tax_res_of_canada,ccm_tax_res_of_canada),
               ccm_tax_payer_id_num = p_tax_payer_id_number,
               --  ccm_tax_payer_id_num = NVL(p_tax_payer_id_number,ccm_tax_payer_id_num),
              ccm_reason_for_no_tax_id = p_reason_for_no_tax_id_type,
                    ccm_reason_for_no_taxid_others = upper(p_reason_for_no_tax_id),
             --ccm_reason_for_no_tax_id = NVL(p_reason_for_no_tax_id,ccm_reason_for_no_tax_id),
             ccm_jurisdiction_of_tax_res = NVL(p_jurisdiction_of_tax_res,ccm_jurisdiction_of_tax_res),
             CCM_OCCUPATION_OTHERS = NVL(p_type_of_employment,CCM_OCCUPATION_OTHERS),
             Ccm_Kyc_Flag = Case When P_Delivery_Channel = '14' And V_Kyc_Flag <> 'Y' Then 'Y' Else Ccm_Kyc_Flag End,
             CCM_KYC_SOURCE = CASE WHEN P_DELIVERY_CHANNEL = '14' AND V_KYC_FLAG <> 'Y' THEN P_DELIVERY_CHANNEL ELSE CCM_KYC_SOURCE END,Ccm_Third_Party_Enabled=upper(P_Thirdpartyenabled),
             CCM_FIRST_NAME_ENCR = NVL(fn_emaps_main(P_FIRST_NAME),CCM_FIRST_NAME_ENCR),
             CCM_LAST_NAME_ENCR  = NVL(fn_emaps_main(P_LAST_NAME),CCM_LAST_NAME_ENCR)
        WHERE CCM_CUST_CODE = V_CUST_CODE AND CCM_INST_CODE = P_INSTCODE;

    EXCEPTION
        WHEN OTHERS THEN
         V_RESPCODE := '21';
         V_ERRMSG   := 'ERROR IN PROFILE UPDATE ' || SUBSTR(SQLERRM, 1, 300);
         RAISE EXP_MAIN_REJECT_RECORD;

    END;

	BEGIN
        --Query modified for MVHOST-382 on 13/06/2013
        UPDATE cms_caf_info_entry
                SET cci_occupation   = NVL(p_occupation,cci_occupation),
				cci_id_number =DECODE (UPPER(p_id_type),
                                       'SSN',cci_id_number, NVL2(p_id_number,fn_maskacct_ssn(p_instcode,p_id_number,0),cci_id_number)),
			    cci_id_number_encr =DECODE (UPPER(p_id_type),
                                       'SSN',cci_id_number_encr, NVL2(p_id_number,fn_emaps_main(p_id_number),cci_id_number_encr)),
                cci_ssn = DECODE (UPPER(p_id_type),
                                       'SSN',NVL2(p_id_number,fn_maskacct_ssn(p_instcode,p_id_number,0),cci_ssn),cci_ssn),
			    cci_ssn_encr = DECODE (UPPER(p_id_type),
                                       'SSN',NVL2(p_id_number,fn_emaps_main(p_id_number),cci_ssn_encr),cci_ssn_encr),
                CCI_OCCUPATION_OTHERS = NVL(p_type_of_employment,CCI_OCCUPATION_OTHERS),
		        cci_id_province = NVL(p_id_province,cci_id_province),
		        cci_id_country = NVL(p_id_country,cci_id_country),
		        cci_verification_date = NVL(DECODE (UPPER(p_id_type),
                                       'SSN', NULL,'SIN', NULL,
                                       TO_DATE (p_id_verification_date, 'mmddyyyy')
                                      ),cci_verification_date),
                CCI_ID_EXPIRY_DATE =
                   NVL(DECODE (UPPER(p_id_type),
                           'SSN', NULL,'SIN', NULL,
                           TO_DATE (p_id_expiry_date, 'mmddyyyy')
                          ),CCI_ID_EXPIRY_DATE),
                cci_document_verify = NVL(UPPER(p_id_type),cci_document_verify),
		        cci_tax_res_of_canada = NVL(UPPER(p_tax_res_of_canada),cci_tax_res_of_canada),
		        Cci_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
		       -- Cci_Tax_Payer_Id_Num = Nvl(P_Tax_Payer_Id_Number,Cci_Tax_Payer_Id_Num),
             Cci_Reason_For_No_Tax_Id =  P_Reason_For_No_Tax_Id,
             Cci_Reasontype_For_No_Tax_Id=P_Reason_For_No_Tax_Id_Type,
		       -- cci_reason_for_no_tax_id = NVL(p_reason_for_no_tax_id,cci_reason_for_no_tax_id),
		        cci_jurisdiction_of_tax_res = NVL(p_jurisdiction_of_tax_res,cci_jurisdiction_of_tax_res),
                cci_kyc_flag = CASE WHEN P_DELIVERY_CHANNEL = '14' AND V_KYC_FLAG <> 'Y' THEN 'Y' ELSE cci_kyc_flag END,
                CCI_KYC_REG_DATE = CASE WHEN P_DELIVERY_CHANNEL = '14' AND V_KYC_FLAG <> 'Y' THEN sysdate ELSE CCI_KYC_REG_DATE END
                WHERE cci_appl_code = to_char(V_APPL_CODE)
                AND cci_inst_code = P_INSTCODE;

    EXCEPTION
        WHEN OTHERS THEN
         V_RESPCODE := '21';
         V_ERRMSG   := 'Error while updating kyc details in caf_info ' || SUBSTR(SQLERRM, 1, 300);
         RAISE EXP_MAIN_REJECT_RECORD;

    END;

  If  P_Thirdpartyenabled Is Not  Null And Upper(P_Thirdpartyenabled)='Y' Then
  
      Begin
      
      select gcm_cntry_code into V_cntryCode  
      from gen_cntry_mast 
     where (GCM_SWITCH_CNTRY_CODE=upper(p_ThirdPartyCountry)
        or GCM_ALPHA_CNTRY_CODE=upper(p_ThirdPartyCountry))
      and Gcm_Inst_Code=P_INSTCODE;
      
       EXCEPTION
        When No_Data_Found Then
          V_ERRMSG   := 'Invalid Country Code' ;
           V_RESPCODE := '49';
          Raise Exp_Main_Reject_Record;
        When Others Then
         V_Respcode := '89';
         V_Errmsg   := 'Error while selecting gen_cntry_mast '  || Substr(Sqlerrm, 1, 300);
         Raise Exp_Main_Reject_Record;
      end;


      if p_thirdpartytype = '1' and p_thirdpartyoccupationType is not null and p_thirdpartyoccupationType <> '00' then
        Begin
         select vom_occu_name into v_occupation_desc 
         from vms_occupation_mast
         where vom_occu_code =p_thirdpartyoccupationType;
               
         EXCEPTION
          When No_Data_Found Then
           V_ERRMSG   := 'Invalid ThirdParty Occupation Code' ;
           V_RESPCODE := '49';
           Raise Exp_Main_Reject_Record;
          when others then
           V_Respcode := '89';
           V_Errmsg   := 'Error while selecting Vms_Occupation_Mast ' || substr(sqlerrm, 1, 300);
           raise Exp_Main_Reject_Record;
        End;
      End If;

    if p_ThirdPartyCountry is not null and p_ThirdPartyCountry  in ('US','CA') then
      Begin
       -- v_state_code:=P_Thirdpartystate;

         Select Gsm_Switch_State_Code,gsm_state_code  Into V_State_Switch_Code,v_state_code
         from Gen_State_Mast
         Where GSM_SWITCH_STATE_CODE=upper(P_Thirdpartystate) and
         Gsm_Cntry_Code=v_cntryCode and Gsm_Inst_Code=P_INSTCODE;
         
       EXCEPTION
        When No_Data_Found Then
           V_ERRMSG   := 'Invalid ThirdParty State Code' ;
           V_RESPCODE := '49';
           Raise Exp_Main_Reject_Record;
        When Others Then
         V_Respcode := '89';
         V_Errmsg   := 'Error while selecting Gen_State_Mast ' || Substr(Sqlerrm, 1, 300);
         Raise Exp_Main_Reject_Record;
      End;
    Else
       v_state_code:=NULL;
      v_state_desc:=P_Thirdpartystate;
      end if;
      
    Begin

       Select Count(*) Into V_Thirdparty_Count 
       From Vms_Thirdparty_Address
       Where Vta_Cust_Code=V_Cust_Code;
       
       If V_Thirdparty_Count>0
       Then
       
       
                            UPDATE vms_thirdparty_address
                SET
                    vta_thirdparty_type = p_thirdpartytype,
                    vta_first_name = upper(p_thirdpartyfirstname),
                    vta_last_name = upper(p_thirdpartylastname),
                    vta_address_one = upper(p_thirdpartyaddress1),
                    vta_address_two = upper(p_thirdpartyaddress2),
                    vta_city_name = upper(p_thirdpartycity),
                    vta_state_code = v_state_code,
                    vta_state_desc = upper(v_state_desc),
                    vta_state_switch = v_state_switch_code,
                    vta_cntry_code = v_cntrycode,
                    vta_pin_code = p_thirdpartyzip,
                    vta_occupation = p_thirdpartyoccupationtype,
                    vta_occupation_others = upper(DECODE(
                        p_thirdpartyoccupationtype,
                        '00',
                        p_thirdpartyoccupation,
                        v_occupation_desc
                    ) ),
                    vta_nature_of_business = upper(p_thirdpartybusiness),
                    vta_dob = TO_DATE(p_thirdpartydob,'MM/DD/YYYY'),
                    vta_nature_of_releationship = upper(p_thirdpartynaturerelationship),
                    vta_corporation_name = upper(p_thirdpartycorporationname),
                    vta_incorporation_number = upper(p_thirdpartycorporation)
            WHERE
                vta_cust_code = v_cust_code;
    
    
       Else

                      INSERT INTO vms_thirdparty_address (
                vta_inst_code,
                vta_cust_code,
                vta_thirdparty_type,
                vta_first_name,
                vta_last_name,
                vta_address_one,
                vta_address_two,
                vta_city_name,
                vta_state_code,
                vta_state_desc,
                vta_state_switch,
                vta_cntry_code,
                vta_pin_code,
                vta_occupation,
                vta_occupation_others,
                vta_nature_of_business,
                vta_dob,
                vta_nature_of_releationship,
                vta_corporation_name,
                vta_incorporation_number,
                vta_ins_user,
                vta_ins_date,
                vta_lupd_user,
                vta_lupd_date
            ) VALUES (
                p_instcode,
                v_cust_code,
                p_thirdpartytype,
                upper(p_thirdpartyfirstname),
                upper(p_thirdpartylastname),
                upper(p_thirdpartyaddress1),
                upper(p_thirdpartyaddress2),
                upper(p_thirdpartycity),
                v_state_code,
                upper(v_state_desc),
                v_state_switch_code,
                v_cntrycode,
                p_thirdpartyzip,
                p_thirdpartyoccupationtype,
                upper(DECODE(
                    p_thirdpartyoccupationtype,
                    '00',
                    p_thirdpartyoccupation,
                    v_occupation_desc
                ) ),
                upper(p_thirdpartybusiness),
                TO_DATE(p_thirdpartydob,'MM/DD/YYYY'),
                upper(p_thirdpartynaturerelationship),
                upper(p_thirdpartycorporationname),
                upper(p_thirdpartycorporation),
                1,
                SYSDATE,
                1,
                SYSDATE
            );
          
     End If;

 
  EXCEPTION
        When Others Then
         V_Respcode := '89';
         V_Errmsg   := 'Error while updating/Inserting third party  address details in Vms_Thirdparty_Address ' || Substr(Sqlerrm, 1, 300);
         Raise Exp_Main_Reject_Record;
End ;
end if;
  --Sn - commented for fwr-48

 

  BEGIN
	SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                        P_MSG_TYPE,
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        P_TERMINALID,
                        P_TXN_CODE,
                        P_TXN_MODE,
                        P_TRANDATE,
                        P_TRANTIME,
                        P_ACCTNO,
                        NULL,
                        0,
                        P_MERCHANT_NAME,
                        P_MERCHANT_CITY,
                        NULL,
                        V_CURRCODE,
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
                        P_STAN, -- P_stan
                        P_MBR_NUMB, --Ins User
                        P_RVSL_CODE, --INS Date
                        NULL,
                        V_INIL_AUTHID,
                        V_RESPCODE,
                        V_RESPMSG,
                        V_CAPTURE_DATE);

    IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
     V_ERRMSG := V_RESPMSG;
     RAISE EXP_AUTH_REJECT_RECORD;
    END IF;
    IF V_RESPCODE <> '00' THEN
     BEGIN
       P_ERRMSG    := V_ERRMSG;
       P_RESP_CODE := V_RESPCODE;
       -- Assign the response code to the out parameter

       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
     EXCEPTION
       WHEN OTHERS THEN
        P_ERRMSG    := 'Problem while selecting data from response master ' ||
                    V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '89';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;

     END;
    ELSE
     P_RESP_CODE := V_RESPCODE;
    END IF;

    --En select response code and insert record into txn log dtl

 IF V_RESPCODE = '00' OR V_RESPMSG = 'OK' THEN  --Added for MVHOST-382 on 13/06/2013

     --ADDED BY NAILA FOR MEDAGATE CHANGE
BEGIN
--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN

	UPDATE TRANSACTIONLOG
	SET MEDAGATEREF_ID = P_MEDAGATE_REF_ID
	WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
			--BUSINESS_DATE = V_BUSINESS_DATE--Commented and added P_TRANDATE by deepa on Apr-04-12 to use the transaction date from XML
			 BUSINESS_DATE = P_TRANDATE AND
			 DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	ELSE
	UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
	SET MEDAGATEREF_ID = P_MEDAGATE_REF_ID
	WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
			--BUSINESS_DATE = V_BUSINESS_DATE--Commented and added P_TRANDATE by deepa on Apr-04-12 to use the transaction date from XML
			 BUSINESS_DATE = P_TRANDATE AND
			 DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	end if;		 
 EXCEPTION
        WHEN OTHERS THEN
         V_RESPCODE := '21';
         V_ERRMSG   := 'ERROR IN transactionlog UPDATE ' || SUBSTR(SQLERRM, 1, 300);
         RAISE EXP_MAIN_REJECT_RECORD;

END;

END IF;
 
    --IF errmsg is OK then balance amount will be returned

    IF P_ERRMSG = 'OK' THEN

     --Sn of Getting  the Acct Balannce
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
              cam_type_code  --Added by Pankaj S. for Logging changes(Mantis ID-13160)
        INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
             v_acct_type   --Added by Pankaj S. for Logging changes(Mantis ID-13160)
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO   = V_ACCT_NUMBER AND
              CAM_INST_CODE = P_INSTCODE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '12';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    V_HASH_PAN;
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     --En of Getting  the Acct Balannce

     P_ERRMSG := TO_CHAR(V_ACCT_BALANCE);
     P_LEDGER_BAL:=V_LEDGER_BALANCE;--ADDED BY ABDUL HAMEED FOR EEP2.1 ON 5/3/2014

    END IF;

  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_AUTH_REJECT_RECORD THEN
     ROLLBACK;
 
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     --Sn select response code and insert record into txn log dtl

     --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_cap_card_stat IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_acct_no
              INTO v_cap_card_stat, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_acctno);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;

       BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
              cam_type_code
        INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
             v_acct_type
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =v_acct_number
            AND CAM_INST_CODE = P_INSTCODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE   := 0;
        V_LEDGER_BALANCE := 0;
     END;

        IF v_dr_cr_flag IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;
        --En Added by Pankaj S. for logging changes(Mantis ID-13160)

     --Sn create a entry in txn log
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         TRANS_DESC, ----Added for transaction detail report on 210812
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MEDAGATEREF_ID, --Added for MVHOST-382 on 13/06/2013
      --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
      time_stamp,
      cr_dr_flag,
      acct_type,
      error_msg
      --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
         )
       VALUES
        (P_MSG_TYPE,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(0, '99999999999999999.99')),
         V_CURRCODE,
         NULL,
         P_PROD_ID,
         P_PROD_CATG,
         P_TERMINALID,
         V_INIL_AUTHID,
         TRIM(TO_CHAR(0, '99999999999999999.99')),
         NULL,
         NULL,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         V_RESPCODE,
         V_TRANS_DESC,--Added for transaction detail report on 210812
          P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
       P_MEDAGATE_REF_ID,  --Added for MVHOST-382 on 13/06/2013
       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
       systimestamp,
       v_dr_cr_flag,
       v_acct_type,
       v_errmsg
       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
       );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        V_ERRMSG    := 'Problem while inserting data into transactionlog' ||
                    SUBSTR(SQLERRM, 1, 300); --Modified by deepa on Apr-04-12 as the error msg is not logged proper
     END;
     --En create a entry in txn log

     BEGIN

       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_CUSTOMER_CARD_NO,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_INST_CODE,
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_CUST_ACCT_NUMBER)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         P_MSG_TYPE,
         P_TXN_MODE,
         P_TRANDATE,
         P_TRANTIME,
         V_HASH_PAN,
         0,
         V_CURRCODE,
         0,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         'E',
         V_ERRMSG,
         P_RRN,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ACCT_NUMBER);

       P_ERRMSG := V_ERRMSG;
       RETURN;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '89'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;

     P_ERRMSG := V_ERRMSG;
    WHEN EXP_MAIN_REJECT_RECORD THEN

     ROLLBACK;

     --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_cap_card_stat IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_acct_no
              INTO v_cap_card_stat, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_acctno);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;

        IF v_dr_cr_flag IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;
        --En Added by Pankaj S. for logging changes(Mantis ID-13160)

     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
              cam_type_code  --Added by Pankaj S. for Logging changes(Mantis ID-13160)
        INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
             v_acct_type  --Added by Pankaj S. for Logging changes(Mantis ID-13160)
        FROM CMS_ACCT_MAST
        --Sn Modified by Pankaj S. for Logging changes(Mantis ID-13160)
        WHERE CAM_ACCT_NO =v_acct_number AND
        --En Modified by Pankaj S. for Logging changes(Mantis ID-13160)
            CAM_INST_CODE = P_INSTCODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE   := 0;
        V_LEDGER_BALANCE := 0;
     END;
     --Sn select response code and insert record into txn log dtl
     BEGIN
 
       --Sn generate auth id
       BEGIN
        --   SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

        --   SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
        SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
          INTO V_INIL_AUTHID
          FROM DUAL;

       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while generating authid ' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESPCODE := '21'; -- Server Declined

       END;

       --En generate auth id
       ---En Updation of Usage limit and amount
       P_ERRMSG    := V_ERRMSG;
       P_RESP_CODE := V_RESPCODE;
       -- Assign the response code to the out parameter

       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
     EXCEPTION
       WHEN OTHERS THEN
        P_ERRMSG    := 'Problem while selecting data from response master ' ||
                    V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '89';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
     END;



     --Sn create a entry in txn log
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         TRANS_DESC,--Added for transaction detail report on 210812
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MEDAGATEREF_ID,  --Added for MVHOST-382 on 13/06/2013
      --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
      time_stamp,
      cr_dr_flag,
      acct_type,
      error_msg
      --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
      )
       VALUES
        (P_MSG_TYPE,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         V_TRANS_DESC,--Added for transaction detail report on 210812
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(0, '999999999999999990.99')),    --modified by Pankaj S. for logging changes(Mantis ID-13160)
         V_CURRCODE,
         NULL,
         P_PROD_ID,
         P_PROD_CATG,
         P_TERMINALID,
         V_INIL_AUTHID,
         TRIM(TO_CHAR(0, '999999999999999990.99')),  --modified by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00',  --modified by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00',  --modified by Pankaj S. for logging changes(Mantis ID-13160)
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         V_RESPCODE,
       P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
       P_MEDAGATE_REF_ID, --Added for MVHOST-382 on 13/06/2013
       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
       systimestamp,
       v_dr_cr_flag,
       v_acct_type,
       v_errmsg
       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
       );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
     --En create a entry in txn log

     BEGIN

       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_CUSTOMER_CARD_NO,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_INST_CODE,
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_CUST_ACCT_NUMBER)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         P_MSG_TYPE,
         P_TXN_MODE,
         P_TRANDATE,
         P_TRANTIME,
         V_HASH_PAN,
         0,
         V_CURRCODE,
         0,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         'E',
         V_ERRMSG,
         P_RRN,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ACCT_NUMBER);

       P_ERRMSG := V_ERRMSG;
       RETURN;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '22'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;

     P_ERRMSG := V_ERRMSG;
    WHEN OTHERS THEN
     -- insert transactionlog and cms_transactio_log_dtl for exception cases

     BEGIN

       ROLLBACK;
 
       --Sn select response code and insert record into txn log dtl
       BEGIN
        P_ERRMSG    := V_ERRMSG;
        P_RESP_CODE := V_RESPCODE;
        -- Assign the response code to the out parameter

        SELECT CMS_ISO_RESPCDE
          INTO P_RESP_CODE
          FROM CMS_RESPONSE_MAST
         WHERE CMS_INST_CODE = P_INSTCODE AND
              CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
              CMS_RESPONSE_ID = V_RESPCODE;
       EXCEPTION
        WHEN OTHERS THEN
          P_ERRMSG    := 'Problem while selecting data from response master ' ||
                      V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '89';
          ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       END;

        --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_cap_card_stat IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_acct_no
              INTO v_cap_card_stat, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_acctno);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;

        IF v_acct_type IS NULL THEN
        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_balance, v_ledger_balance, v_acct_type
             FROM cms_acct_mast
            WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_acct_balance := 0;
              v_ledger_balance := 0;
        END;
        END IF;

        IF v_dr_cr_flag IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
        END IF;
        --En Added by Pankaj S. for logging changes(Mantis ID-13160)

        --Sn create a entry in txn log
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         TRANS_DESC,--Added for transaction detail report on 210812
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE , -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
       MEDAGATEREF_ID, --Added for MVHOST-382 on 13/06/2013
       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
       time_stamp,
       cr_dr_flag,
       acct_type,
       error_msg
       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
       )
       VALUES
        (P_MSG_TYPE,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         V_TRANS_DESC,--Added for transaction detail report on 210812
         P_RESP_CODE,
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(0, '999999999999999990.99')),   --modified by Pankaj S. for logging changes(Mantis ID-13160)
         V_CURRCODE,
         NULL,
         P_PROD_ID,
         P_PROD_CATG,
         P_TERMINALID,
         V_INIL_AUTHID,
         TRIM(TO_CHAR(0, '999999999999999990.99')),    --modified by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00',   --modified by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00',    --modified by Pankaj S. for logging changes(Mantis ID-13160)
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         V_RESPCODE,
           P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
       P_MEDAGATE_REF_ID, --Added for MVHOST-382 on 13/06/2013
       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
       systimestamp,
       v_dr_cr_flag,
       v_acct_type,
       v_errmsg
       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
       );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
     --En create a entry in txn log

       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_CUSTOMER_CARD_NO,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_INST_CODE,
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_CUST_ACCT_NUMBER)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         P_MSG_TYPE,
         P_TXN_MODE,
         P_TRANDATE,
         P_TRANTIME,
         V_HASH_PAN,
         0,
         V_CURRCODE,
         0,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         'E',
         V_ERRMSG,
         P_RRN,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ACCT_NUMBER);

       P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
     END;
  END;

EXCEPTION
   WHEN OTHERS THEN

    -- insert transactionlog and cms_transactio_log_dtl for exception cases

    ROLLBACK;

    BEGIN
     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

     SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
       INTO V_INIL_AUTHID
       FROM DUAL;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21'; -- Server Declined

    END;

    --Sn select response code and insert record into txn log dtl
    BEGIN
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     -- Assign the response code to the out parameter

     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    END;

   --Sn create a entry in txn log
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         TRANS_DESC,--Added for transaction detail report on 210812
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
           MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
     MEDAGATEREF_ID --Added for MVHOST-382 on 13/06/2013
     )
       VALUES
        (P_MSG_TYPE,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         V_TRANS_DESC,--Added for transaction detail report on 210812
         P_RESP_CODE,
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(0, '99999999999999999.99')),
         V_CURRCODE,
         NULL,
         P_PROD_ID,
         P_PROD_CATG,
         P_TERMINALID,
         V_INIL_AUTHID,
         TRIM(TO_CHAR(0, '99999999999999999.99')),
         NULL,
         NULL,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         V_RESPCODE,
           P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MEDAGATE_REF_ID  --Added for MVHOST-382 on 13/06/2013
      );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
     --En create a entry in txn log

    INSERT INTO CMS_TRANSACTION_LOG_DTL
     (CTD_DELIVERY_CHANNEL,
      CTD_TXN_CODE,
      CTD_MSG_TYPE,
      CTD_TXN_MODE,
      CTD_BUSINESS_DATE,
      CTD_BUSINESS_TIME,
      CTD_CUSTOMER_CARD_NO,
      CTD_TXN_AMOUNT,
      CTD_TXN_CURR,
      CTD_ACTUAL_AMOUNT,
      CTD_FEE_AMOUNT,
      CTD_WAIVER_AMOUNT,
      CTD_SERVICETAX_AMOUNT,
      CTD_CESS_AMOUNT,
      CTD_BILL_AMOUNT,
      CTD_BILL_CURR,
      CTD_PROCESS_FLAG,
      CTD_PROCESS_MSG,
      CTD_RRN,
      CTD_INST_CODE,
      CTD_CUSTOMER_CARD_NO_ENCR,
      CTD_CUST_ACCT_NUMBER)
    VALUES
     (P_DELIVERY_CHANNEL,
      P_TXN_CODE,
      P_MSG_TYPE,
      P_TXN_MODE,
      P_TRANDATE,
      P_TRANTIME,
      V_HASH_PAN,
      0,
      V_CURRCODE,
      0,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'E',
      V_ERRMSG,
      P_RRN,
      P_INSTCODE,
      V_ENCR_PAN,
      V_ACCT_NUMBER);

END;


/
show error;