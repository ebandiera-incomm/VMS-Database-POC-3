SET DEFINE OFF;
create or replace
PROCEDURE VMSCMS.SP_UPDATE_CONTACT_INFO(P_INSTCODE         IN NUMBER,
                                         P_RRN              IN VARCHAR2,
                                         P_TERMINALID       IN VARCHAR2,
                                         P_STAN             IN VARCHAR2,
                                         P_TRANDATE         IN VARCHAR2,
                                         P_TRANTIME         IN VARCHAR2,
                                         P_ACCTNO           IN VARCHAR2,
                                         P_CURRCODE         IN VARCHAR2,
                                         P_MSG_TYPE         IN VARCHAR2,
                                         P_TXN_CODE         IN VARCHAR2,
                                         P_TXN_MODE         IN VARCHAR2,
                                         P_DELIVERY_CHANNEL IN VARCHAR2,
                                         P_MBR_NUMB         IN VARCHAR2,
                                         P_RVSL_CODE        IN VARCHAR2,
                                         P_ADD_LINE_ONE     IN VARCHAR2,
                                         P_ADD_LINE_TWO     IN VARCHAR2,
                                         P_CITY             IN VARCHAR2,
                                         P_ZIP              IN VARCHAR2,
                                         P_PHONENUM         IN VARCHAR2,
                                         P_OTHERPHONE       IN VARCHAR2,
                                         P_STATE            IN VARCHAR2,
                                         P_COUNTRY_CODE     IN VARCHAR2,
                                         P_EMAIL            IN VARCHAR2,
                                         P_PHY_ADD_LINE_ONE IN VARCHAR2,
                                         P_PHY_ADD_LINE_TWO IN VARCHAR2,
                                         P_PHY_CITY         IN VARCHAR2,
                                         P_PHY_ZIP          IN VARCHAR2,
                                         P_PHY_PHONENUM     IN VARCHAR2,
                                         P_PHY_OTHERPHONE   IN VARCHAR2,
                                         P_PHY_STATE        IN VARCHAR2,
                                         P_PHY_COUNTRY_CODE IN VARCHAR2,
                                         P_IPADDRESS        IN VARCHAR2,
                                         P_COMMENT          IN VARCHAR2,   --Added on 18-02-2014: MVCSD-4121 & FWR 
                                         P_ADDRESS_VERIFIED_FLAG IN VARCHAR2,  --Added on 18-02-2014: MVCSD-4121 & FWR 
                                         P_Device_Id        In Varchar2,--Added on 12-03-2014 for FWR-4
                                         P_occupationtype      In        Varchar2,
                                         P_Occupation          In        Varchar2,
                                         P_RESP_CODE         OUT VARCHAR2,
                                         P_ERRMSG            OUT VARCHAR2,
                                         p_optin_flag_out    OUT    VARCHAR2
                                         ) AS
/*************************************************
  * modified by          :B.Besky
  * modified Date        : 06-NOV-12
  * modified reason      : Changes in Exception handling
  * Reviewer             : Saravanakumar
  * Reviewed Date        : 06-NOV-12
  * Build Number        :  CMS3.5.1_RI0021

     * Modified By      :  Siva Kumar M
     * Modified Date    :  12-Dec-2013.
     * Modified Reason  :  Changed Phone Number Mandatory to non-mandatory (Defect Id:13039)
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  12-Dec-2013.
     * Build Number     :  RI0027_B0001
     
     * Modified By      : Pankaj S.
     * Modified Date    : 12-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0004
     
     * Modified By      : DINESH B.
     * Modified Date    : 18-Feb-2014
     * Modified Reason  : Logging comments . address verification flag and -MVCSD-4121 and FWR-43
     * Reviewer         : Dhiraj
     * Reviewed Date    : 18-Feb-2014
     * Build Number     : RI0027.2_B0002
     
     * Modified By      : DINESH B.
     * Modified Date    : 25-mar-2014
     * Modified Reason  : Review changes done for  -MVCSD-4121 and FWR-43
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 01-April-2014
     * Build Number     : RI0027.2_B0003
     
     * Modified By      : Amudhan S
     * Modified Date    : 11-Apr-2014
     * Modified Reason  : changes done for  14101
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005
     
     * Modified By      : Ravi N
     * Modified Date    : 17-Apr-2014
     * Modified Reason  : Mantis : 0014216 should update empty value if the “phonenumber” or MobileNO is blank or not received from reqquest
     * Reviewer         : spankaj
     * Build Number     : RI0027.3_B0001
     
     * Modified By      : MageshKumar S
     * Modified Date    : 08-October-2014
     * Modified Reason  : changes done for Mantis : 0015610
     * Reviewer         : Spankaj
     * Build Number     : RI0027.4.3_B0001  
     
     * Modified By      : Ramesh A
     * Modified Date    : 12/DEC/2014
     * Modified Reason  : FSS-1961(Melissa)
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
       
       * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
    
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
	  
  	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01
    
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
	
	 * Modified By      : Saravana Kumar.A
     * Modified Date    : 24-DEC-2021
     * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
     * Reviewer         : Venkat. S
     * Release Number   : VMSGPRHOST_R56 Build 2.
   
    * Modified By      : venkat Singamaneni
    * Modified Date    : 5-02-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

 *************************************************/
  V_CAP_PROD_CATG           CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT           CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG         CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP         CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ERRMSG                  TRANSACTIONLOG.ERROR_MSG%TYPE;
  V_CURRCODE                CMS_TRANSACTION_LOG_DTL.CTD_TXN_CURR%TYPE;
  V_APPL_CODE               CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE                TRANSACTIONLOG.RESPONSE_ID%TYPE;
  V_RESPMSG                 TRANSACTIONLOG.ERROR_MSG%TYPE;
   
  V_CAPTURE_DATE            DATE;
  V_MBRNUMB                 CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  
  V_TXN_TYPE                CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID             TRANSACTIONLOG.AUTH_ID%TYPE;
  
  V_HASH_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT               PLS_INTEGER;
  V_DELCHANNEL_CODE         CMS_DELCHANNEL_MAST.CDM_CHANNEL_CODE%TYPE;
  V_BASE_CURR               CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_TRAN_DATE               DATE;
  V_ACCT_BALANCE            CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_LEDGER_BALANCE          CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_BUSINESS_DATE           TRANSACTIONLOG.BUSINESS_DATE%TYPE;
    
  V_CUST_CODE               CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
    
  V_PROXUNUMBER             CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER             CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_ENCRYPT_ENABLE          CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_OFFADDRCOUNT            PLS_INTEGER;
  
  V_DR_CR_FLAG              CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_OUTPUT_TYPE             CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
  V_TRAN_TYPE               CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;  
  V_TRANS_DESC              CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
  
  --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_prod_code             cms_appl_pan.cap_prod_code%type;
   v_card_type             cms_appl_pan.cap_card_type%type;
   v_acct_type             cms_acct_mast.cam_type_code%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   --Added for FSS-1961(Melissa)
   v_phys_switch_state_code      cms_addr_mast.cam_state_switch%TYPE ;
   v_curr_code                   gen_cntry_mast.gcm_curr_code%TYPE ; 
   v_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE ;
   V_AVQ_STATUS                  PLS_INTEGER;
   V_CUST_ID                    CMS_CUST_MAST.CCM_CUST_ID%TYPE;
   V_FULL_NAME                  CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
   V_MAILADDR_LINEONE           cms_addr_mast.CAM_ADD_ONE%type;
   V_MAILADDR_LINETWO           cms_addr_mast.CAM_ADD_TWO%type;
   V_MAILADDR_CITY              cms_addr_mast.CAM_CITY_NAME%type;
   V_MAILADDR_ZIP               cms_addr_mast.CAM_PIN_CODE%type;
    
   
   v_gprhash_pan                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   v_gprencr_pan                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   V_ZIPCODE                    cms_addr_mast.CAM_PIN_CODE%type;
   
   v_encr_addr_lineone      cms_addr_mast.CAM_ADD_ONE%type;
   v_encr_addr_linetwo      cms_addr_mast.CAM_ADD_TWO%type;
   v_encr_city              cms_addr_mast.CAM_CITY_NAME%type;
   v_encr_email             cms_addr_mast.CAM_EMAIL%type;
   v_encr_phone_no          cms_addr_mast.CAM_PHONE_ONE%type;
   v_encr_mob_one           cms_addr_mast.CAM_MOBL_ONE%type;
   v_profile_code           cms_prod_cattype.cpc_profile_code%type; 
   v_encr_full_name         cms_avq_status.cas_cust_name%type;
   V_Decr_Cellphn           Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One           Cms_Addr_Mast.Cam_Mobl_One%Type;
   L_Alert_Lang_Id          Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
   V_Doptin_Flag            PLS_INTEGER;
   Type CurrentAlert_Collection Is Table Of Varchar2(30);
   CurrentAlert             CurrentAlert_Collection;
   v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag            Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type; 
   v_federal_state_flag     CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
    
   V_Occupation_Desc        Vms_Occupation_Mast.Vom_Occu_Name%Type;
  
   --END Added for FSS-1961(Melissa)
    
   EXP_REJECT_RECORD        EXCEPTION;
   EXP_MAIN_REJECT_RECORD   EXCEPTION;
   EXP_AUTH_REJECT_RECORD   EXCEPTION;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991

BEGIN
  P_ERRMSG := 'OK';
  p_optin_flag_out :='N';
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_ACCTNO);
    --DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG' || V_HASH_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting hash pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_ACCTNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while converting encryption pan  ' ||
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
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '21'; --Ineligible Transaction
       V_RESPCODE  := 'Error while selecting transaction details';
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
          --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
         cap_prod_code,
         cap_card_type
         --En Added by Pankaj S. for logging changes(Mantis ID-13160)
     INTO V_CAP_CARD_STAT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_CUST_CODE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
          --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
         v_prod_code,
         v_card_type
         --En Added by Pankaj S. for logging changes(Mantis ID-13160)
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN; 
  
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Invalid Card number ';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting card number ' || SUBSTR(SQLERRM ,1,200);
     RAISE EXP_MAIN_REJECT_RECORD;
    
  END;

  BEGIN
      SELECT upper(cpc_encrypt_enable),cpc_profile_code
        INTO v_encrypt_enable,v_profile_code
        FROM cms_prod_cattype
       WHERE cpc_inst_code = P_INSTCODE
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
      WHEN OTHERS
      THEN
         V_RESPCODE := '21';
         v_errmsg :=
               'Error while selecting the encrypt enable flag and profile code'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;


  BEGIN
  
    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'MMPOS' AND CDM_INST_CODE = P_INSTCODE;
  
    IF V_DELCHANNEL_CODE = P_DELIVERY_CHANNEL THEN
    
     BEGIN
       SELECT trim (CBP_PARAM_VALUE)
        INTO V_BASE_CURR
        FROM CMS_BIN_PARAM
        WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PARAM_NAME = 'Currency'
        and cbp_profile_code = v_profile_code;
     
       IF V_BASE_CURR IS NULL THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency cannot be null ';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       when EXP_MAIN_REJECT_RECORD then
      raise;
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the institution ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting bese currecy  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    
     V_CURRCODE := V_BASE_CURR;
    
    ELSE
     V_CURRCODE := P_CURRCODE;
    END IF;
  
  EXCEPTION
  when EXP_MAIN_REJECT_RECORD then
  raise;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting the Delivery Channel of MMPOS  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
    
  END;
  
  


  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return

  BEGIN
  
    ---SELECT TO_CHAR(SYSDATE, 'yyyymmdd') INTO V_BUSINESS_DATE FROM DUAL;
    
    V_BUSINESS_DATE := TO_CHAR(SYSDATE, 'yyyymmdd');
    
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = V_BUSINESS_DATE 
             and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;--Added by ramkumar.Mk on 25 march 2012
  
    IF V_RRN_COUNT > 0 THEN
     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN from the Terminal  on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
    
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD 
    THEN RAISE;    
    WHEN OTHERS THEN      
    	V_RESPCODE := '21'; 
       V_ERRMSG  := 'Error while selecting FROM TRANSACTIONLOG' || SUBSTR(SQLERRM ,1,200);
       RAISE EXP_MAIN_REJECT_RECORD;
      
  END;

 --En Duplicate RRN Check

  
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
                        NULL,
                        NULL,
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
       P_ERRMSG    := ' ';
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
    --Added for FSS-1961(Melissa)
     IF P_PHY_COUNTRY_CODE IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013
     -- Sn Added on 25-Apr-2013 by MageshKumar.S for Defect Id:DFCHOST-310
      BEGIN
                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = P_PHY_COUNTRY_CODE
                AND GCM_INST_CODE = P_INSTCODE;
      EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
             v_respcode := '168';
             v_errmsg := 'Invalid Data for Country Code' || P_PHY_COUNTRY_CODE;
             RAISE exp_main_reject_record;
       WHEN OTHERS THEN
        v_respcode := '21';
         v_errmsg := 'Error while selecting currency code ' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
      END;
  
        IF P_PHY_STATE IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013
    
           BEGIN
               SELECT GSM_SWITCH_STATE_CODE
               INTO v_phys_switch_state_code
               FROM  GEN_STATE_MAST
               WHERE  GSM_STATE_CODE = P_PHY_STATE
               AND GSM_CNTRY_CODE = P_PHY_COUNTRY_CODE
               AND GSM_INST_CODE = p_instcode;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_respcode := '167';
                 v_errmsg := 'Invalid Data for Physical Address State' || P_PHY_STATE;
                 RAISE exp_main_reject_record;
            WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting switch state code ' || SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_MAIN_REJECT_RECORD;
          END;
      END IF;  --Added for MVHOST-382 on 13/06/2013
   END IF;   --Added for MVHOST-382 on 13/06/2013
 --END Added for FSS-1961(Melissa)
 
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
              V_ZIPCODE := fn_emaps_main(P_PHY_ZIP);
              v_encr_addr_lineone := fn_emaps_main(P_PHY_ADD_LINE_ONE);
              v_encr_addr_linetwo := fn_emaps_main(P_PHY_ADD_LINE_TWO);
              v_encr_city := fn_emaps_main(P_PHY_CITY);
              v_encr_email := fn_emaps_main(p_email);
              v_encr_phone_no := fn_emaps_main(p_phonenum);
              v_encr_mob_one  := fn_emaps_main(p_otherphone);
        
        ELSE
              V_ZIPCODE :=P_PHY_ZIP;
              v_encr_addr_lineone := P_PHY_ADD_LINE_ONE;
              v_encr_addr_linetwo := P_PHY_ADD_LINE_TWO;
              v_encr_city := P_PHY_CITY;
              v_encr_email := p_email;
              v_encr_phone_no := p_phonenum;
              v_encr_mob_one  := p_otherphone;
         
    END IF;         
     
    -- Sn Sivapragasam M to update Contact Info on June 14 2012
 BEGIN
    Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into L_Alert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=V_Hash_Pan  and CSA_INST_CODE=P_Instcode;
    
     EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
    BEGIN
  select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    WHERE nvl(dbms_lob.substr( cps_alert_msg,1,1),0) <> 0  
    And Cps_Prod_Code = V_Prod_Code
    AND CPS_CARD_TYPE = v_card_type
    And Cps_Inst_Code= P_Instcode
    and cps_alert_id=33
      And ( Cps_Alert_Lang_Id = l_alert_lang_id or (l_alert_lang_id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
      Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
        If(p_optin_flag_out = 'N' and ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then
           Select Cam_Mobl_One into V_Cam_Mobl_One From Cms_Addr_Mast
           where cam_cust_code=v_cust_code 
           and cam_addr_flag='P' 
           and cam_inst_code=p_instcode;
            If(V_Encrypt_Enable = 'Y') Then 
              V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
              Else
              V_Decr_Cellphn := V_Cam_Mobl_One;
            End If;
            If(V_Decr_Cellphn <> p_otherphone)
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
    UPDATE CMS_ADDR_MAST
       SET CAM_ADD_ONE    = v_encr_addr_lineone,
           CAM_ADD_TWO    = v_encr_addr_linetwo,
           CAM_CITY_NAME  = v_encr_city,
           CAM_PIN_CODE   = V_ZIPCODE,
          --Commented on 17/04/14 for Mantis:0014216--should update empty value if the “phonenumber” is blank or not received from website
--         CAM_PHONE_ONE  = NVL(P_PHONENUM,CAM_PHONE_ONE),--Modified by Srinivasu .k cheaged phyaddress phone and phy other phone  -- Modified for defect id:13039 on 12/12/2013
--         CAM_MOBL_ONE   = NVL(P_OTHERPHONE,CAM_MOBL_ONE),----Modified by Srinivasu .k  Changed phyaddress phone and phy other phone  -- Modified for defect id:13039 on 12/12/2013
      --Modifed on 17/04/14 for Mantis:0014216--should update empty value if the “phonenumber” is blank or not received from website
           CAM_PHONE_ONE  = v_encr_phone_no,
           CAM_MOBL_ONE   = v_encr_mob_one,
      --End
           CAM_STATE_CODE = P_PHY_STATE,
           CAM_CNTRY_CODE = P_PHY_COUNTRY_CODE,
           CAM_EMAIL      = v_encr_email,
           cam_state_switch = NVL(v_phys_switch_state_code,cam_state_switch), --Added for FSS-1961(Melissa)
           CAM_ADD_ONE_ENCR = fn_emaps_main(P_PHY_ADD_LINE_ONE),
           CAM_ADD_TWO_ENCR = fn_emaps_main(P_PHY_ADD_LINE_TWO),
           CAM_CITY_NAME_ENCR = fn_emaps_main(P_PHY_CITY),
           CAM_PIN_CODE_ENCR = fn_emaps_main(P_PHY_ZIP),
           CAM_EMAIL_ENCR = fn_emaps_main(p_email)
     WHERE CAM_INST_CODE = P_INSTCODE AND CAM_CUST_CODE = V_CUST_CODE AND
           CAM_ADDR_FLAG = 'P';
         
         
         IF SQL%ROWCOUNT = 0 THEN
         v_respcode := '21'; --corrected for Mantis ID : 0015610
         v_errmsg := 'ERROR WHILE UPDATING CMS_ADDR_MAST '; --corrected for Mantis ID : 0015610    
         RAISE EXP_MAIN_REJECT_RECORD;
         END IF;   
         
         EXCEPTION
         WHEN EXP_MAIN_REJECT_RECORD THEN        
         RAISE EXP_MAIN_REJECT_RECORD;
         WHEN OTHERS THEN 
         v_respcode := '21'; --corrected for Mantis ID : 0015610
         v_errmsg := 'Problem on updated CMS_ADDR_MAST ' || SUBSTR (SQLERRM, 1, 200); --corrected for Mantis ID : 0015610      
        RAISE EXP_MAIN_REJECT_RECORD;         
 END;
 
					BEGIN
						UPDATE CMS_CUST_MAST
							SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
						WHERE CCM_INST_CODE = P_INSTCODE
						AND CCM_CUST_CODE = V_CUST_CODE;
						
					EXCEPTION
						WHEN OTHERS THEN
						 V_ERRMSG := 'Exception While Updating Customer Mast ' || SUBSTR (SQLERRM, 1, 200);
						  RAISE EXP_MAIN_REJECT_RECORD;
					END;		
    --Added for FSS-1961(Melissa)
      IF P_COUNTRY_CODE IS NOT NULL THEN  
        BEGIN

                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = P_COUNTRY_CODE
                AND GCM_INST_CODE = p_instcode;

             EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
             v_respcode := '6';
             v_errmsg := 'Invalid Data for Mailing Address Country Code' || P_COUNTRY_CODE;
             RAISE exp_main_reject_record;
              WHEN OTHERS THEN
              v_respcode := '21';
              V_ERRMSG := 'Error while selecting mailing country code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
             END;

         IF  P_STATE IS NOT NULL THEN  

            BEGIN

            SELECT GSM_SWITCH_STATE_CODE
            INTO v_mailing_switch_state_code
            FROM  GEN_STATE_MAST
            WHERE  GSM_STATE_CODE = P_STATE
            AND GSM_CNTRY_CODE = P_COUNTRY_CODE
            AND GSM_INST_CODE = p_instcode;

            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             v_respcode := '169';
             v_errmsg := 'Invalid Data for Mailing Address State' || P_STATE;
             RAISE exp_main_reject_record;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting mailing switch state code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
            END;
        END IF; 
      END IF; 
      --END Added for FSS-1961(Melissa)
    BEGIN
     SELECT COUNT(*)
       INTO V_OFFADDRCOUNT
       FROM CMS_ADDR_MAST
      WHERE CAM_INST_CODE = P_INSTCODE AND CAM_CUST_CODE = V_CUST_CODE AND
           CAM_ADDR_FLAG = 'O';
    
      EXCEPTION
         WHEN OTHERS THEN
         v_respcode := '21';
         V_ERRMSG := 'Error while selecting mailing address count ' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
     END;
        
     IF V_OFFADDRCOUNT > 0 THEN
     
     IF V_ENCRYPT_ENABLE = 'Y' THEN
        V_ZIPCODE := fn_emaps_main(P_ZIP);
        v_encr_addr_lineone := fn_emaps_main(P_ADD_LINE_ONE);
        v_encr_addr_linetwo := fn_emaps_main(p_add_line_two);
        v_encr_city := fn_emaps_main(p_city);
      --  v_encr_email := fn_emaps_main(p_email);
        v_encr_phone_no := fn_emaps_main(p_phonenum);
        v_encr_mob_one  := fn_emaps_main(p_otherphone);
        
     ELSE
        V_ZIPCODE :=P_ZIP;
        v_encr_addr_lineone := P_ADD_LINE_ONE;
        v_encr_addr_linetwo := p_add_line_two;
        v_encr_city := p_city;
      --  v_encr_email := p_email;
        v_encr_phone_no := p_phonenum;
        v_encr_mob_one  := p_otherphone;
         
     END IF;
               
       BEGIN
              UPDATE cms_addr_mast
                 SET cam_add_one = NVL(v_encr_addr_lineone,cam_add_one), --Modified for mantis:0015610
                     cam_add_two = v_encr_addr_linetwo,
                     cam_city_name = NVL(v_encr_city,cam_city_name), --Modified for mantis:0015610
                     cam_pin_code = NVL(V_ZIPCODE,cam_pin_code), --Modified for mantis:0015610
                   --Commented on 17/04/14 for Mantis:0014216--should update empty value if the “phonenumber” is blank or not received from website
                        -- CAM_PHONE_ONE  = NVL(P_PHONENUM,CAM_PHONE_ONE),--P_PHONENUM,  -- Modified for defect id:13039  on 12/12/2013
                       --  CAM_MOBL_ONE   = NVL(P_OTHERPHONE,CAM_MOBL_ONE), --P_OTHERPHONE, -- Modified for defect id:13039  on 12/12/2013
                   --Modifed on 17/04/14 for Mantis:0014216--should update empty value if the “phonenumber” is blank or not received from website
                     cam_phone_one = v_encr_phone_no,
                     cam_mobl_one = v_encr_mob_one, 
                   --End
                     cam_state_code = NVL(P_STATE,cam_state_code), --Modified for mantis:0015610
                     cam_cntry_code = NVL(P_COUNTRY_CODE,cam_cntry_code), --Modified for mantis:0015610
                     cam_state_switch = NVL(v_mailing_switch_state_code,cam_state_switch), --Added for FSS-1961(Melissa)
                     CAM_ADD_ONE_ENCR = NVL(fn_emaps_main(P_ADD_LINE_ONE),CAM_ADD_ONE_ENCR),
                     CAM_ADD_TWO_ENCR = fn_emaps_main(p_add_line_two), 
                     CAM_CITY_NAME_ENCR = NVL(fn_emaps_main(p_city),CAM_CITY_NAME_ENCR),
                     CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_ZIP),CAM_PIN_CODE_ENCR)                     
               WHERE cam_inst_code = p_instcode
                 AND cam_cust_code = v_cust_code
                 AND cam_addr_flag = 'O';
           EXCEPTION
            WHEN OTHERS THEN
            V_RESPCODE := '21';
            V_ERRMSG   := 'ERROR IN  UPDATE MAIL CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
            RAISE EXP_MAIN_REJECT_RECORD;
        END; 
               
     ELSE
     
        IF P_ADD_LINE_ONE IS NOT NULL AND P_COUNTRY_CODE IS NOT NULL AND P_CITY IS NOT NULL  THEN  --Added for mantis:0015610

            BEGIN
                   INSERT INTO CMS_ADDR_MAST
                    (CAM_INST_CODE,
                     CAM_CUST_CODE,
                     CAM_ADDR_CODE,
                     CAM_ADD_ONE,
                     CAM_ADD_TWO,
                     CAM_PIN_CODE,
                     CAM_PHONE_ONE,
                     CAM_MOBL_ONE,
                     CAM_CNTRY_CODE,
                     CAM_CITY_NAME,
                     CAM_ADDR_FLAG,
                     CAM_STATE_CODE,
                     CAM_COMM_TYPE,
                     CAM_INS_USER,
                     CAM_INS_DATE,
                     CAM_LUPD_USER,
                     CAM_LUPD_DATE,
                     cam_state_switch,
                     CAM_ADD_ONE_ENCR,
                     CAM_ADD_TWO_ENCR,
                     CAM_CITY_NAME_ENCR,
                     CAM_PIN_CODE_ENCR)
                   VALUES
                    (P_INSTCODE,
                     V_CUST_CODE,
                     SEQ_ADDR_CODE.NEXTVAL,
                     v_encr_addr_lineone,
                     v_encr_addr_linetwo,
                     V_ZIPCODE,
                     v_encr_phone_no,
                     v_encr_mob_one,
                     P_COUNTRY_CODE,
                     v_encr_city,
                     'O',
                     P_STATE,
                     'R',
                     1,
                     SYSDATE,
                     1,
                     SYSDATE,
                     v_mailing_switch_state_code,
                     fn_emaps_main(P_ADD_LINE_ONE),
                     fn_emaps_main(P_ADD_LINE_TWO),
                     fn_emaps_main(p_city),
                     fn_emaps_main(P_ZIP));
                EXCEPTION
                WHEN OTHERS THEN
                 V_RESPCODE := '21';
                 V_ERRMSG   := 'ERROR IN  INSERTING MAIL CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
                 RAISE EXP_MAIN_REJECT_RECORD;
              END;   
              
         else --Added for FSS-1961(Melissa)
         
          IF V_ENCRYPT_ENABLE = 'Y' THEN
              V_ZIPCODE := fn_emaps_main(P_PHY_ZIP);
              v_encr_addr_lineone := fn_emaps_main(P_PHY_ADD_LINE_ONE);
              v_encr_addr_linetwo := fn_emaps_main(P_PHY_ADD_LINE_TWO);
              v_encr_city := fn_emaps_main(P_PHY_CITY);
            --  v_encr_email := fn_emaps_main(p_email);
              v_encr_phone_no := fn_emaps_main(p_phonenum);
              v_encr_mob_one  := fn_emaps_main(p_otherphone);
        
        ELSE
              V_ZIPCODE :=P_PHY_ZIP;
              v_encr_addr_lineone := P_PHY_ADD_LINE_ONE;
              v_encr_addr_linetwo := P_PHY_ADD_LINE_TWO;
              v_encr_city := P_PHY_CITY;
             -- v_encr_email := p_email;
              v_encr_phone_no := p_phonenum;
              v_encr_mob_one  := p_otherphone;
         
         END IF;    
         
          BEGIN
                   INSERT INTO CMS_ADDR_MAST
                    (CAM_INST_CODE,
                     CAM_CUST_CODE,
                     CAM_ADDR_CODE,
                     CAM_ADD_ONE,
                     CAM_ADD_TWO,
                     CAM_PIN_CODE,
                     CAM_PHONE_ONE,
                     CAM_MOBL_ONE,
                     CAM_CNTRY_CODE,
                     CAM_CITY_NAME,
                     CAM_ADDR_FLAG,
                     CAM_STATE_CODE,
                     CAM_COMM_TYPE,
                     CAM_INS_USER,
                     CAM_INS_DATE,
                     CAM_LUPD_USER,
                     CAM_LUPD_DATE,
                     cam_state_switch,
                     CAM_ADD_ONE_ENCR,
                     CAM_ADD_TWO_ENCR,
                     CAM_CITY_NAME_ENCR,
                     CAM_PIN_CODE_ENCR)
                   VALUES
                    (P_INSTCODE,
                     V_CUST_CODE,
                     SEQ_ADDR_CODE.NEXTVAL,
                     v_encr_addr_lineone,
                     v_encr_addr_linetwo,
                     V_ZIPCODE,
                     v_encr_phone_no,
                     v_encr_mob_one,
                     P_PHY_COUNTRY_CODE,
                     v_encr_city,
                     'O',
                     P_PHY_STATE,
                     'O',
                     1,
                     SYSDATE,
                     1,
                     SYSDATE,
                     v_phys_switch_state_code,
                      fn_emaps_main(P_PHY_ADD_LINE_ONE),
                      fn_emaps_main(P_PHY_ADD_LINE_TWO),
                      fn_emaps_main(P_PHY_CITY),
                      fn_emaps_main(P_PHY_ZIP));
                EXCEPTION
                WHEN OTHERS THEN
                 V_RESPCODE := '21';
                 V_ERRMSG   := 'ERROR IN  INSERTING MAIL CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
                 RAISE EXP_MAIN_REJECT_RECORD;
              END;   
              
         END IF;
  END IF; --Added for mantis:0015610
      --Added for FSS-1961(Melissa)
      BEGIN
        
        
        
          SELECT cust.ccm_cust_id,decode(v_encrypt_enable,'Y',fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)||' '||
          decode(v_encrypt_enable,'Y',fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
                    decode(v_encrypt_enable,'Y',fn_dmaps_main( addr.cam_add_one), addr.cam_add_one),
                    decode(v_encrypt_enable,'Y',fn_dmaps_main( addr.cam_add_two), addr.cam_add_two),
                    decode(v_encrypt_enable,'Y',fn_dmaps_main( addr.cam_city_name), addr.cam_city_name),
                     addr.cam_state_switch,
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main( addr.cam_pin_code), addr.cam_pin_code)                   
           INTO V_CUST_ID,V_FULL_NAME,V_MAILADDR_LINEONE,V_MAILADDR_LINETWO,
           V_MAILADDR_CITY,v_mailing_switch_state_code,V_MAILADDR_ZIP
           FROM CMS_CUST_MAST CUST,cms_addr_mast ADDR
           WHERE addr.cam_inst_code = cust.ccm_inst_code
           AND  addr.cam_cust_code = cust.ccm_cust_code
           AND cust.CCM_INST_CODE = P_INSTCODE 
           AND cust.CCM_CUST_CODE = V_CUST_CODE
           and  addr.cam_addr_flag='O';
                                  
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
      
      BEGIN
      
          SELECT COUNT(1) INTO V_AVQ_STATUS
          FROM CMS_AVQ_STATUS 
          WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='P';
          IF V_ENCRYPT_ENABLE = 'Y' THEN
              V_ZIPCODE := fn_emaps_main(V_MAILADDR_ZIP);
              v_encr_addr_lineone := fn_emaps_main(V_MAILADDR_LINEONE);
              v_encr_addr_linetwo := fn_emaps_main(V_MAILADDR_LINETWO);
              v_encr_city := fn_emaps_main(V_MAILADDR_CITY);
			  v_encr_full_name:= fn_emaps_main(V_FULL_NAME);
          ELSE
              V_ZIPCODE := V_MAILADDR_ZIP;
              v_encr_addr_lineone := V_MAILADDR_LINEONE;
              v_encr_addr_linetwo := V_MAILADDR_LINETWO;
              v_encr_city := V_MAILADDR_CITY;
			  v_encr_full_name := V_FULL_NAME;
		  END IF;
		  
            IF V_AVQ_STATUS = 1 THEN
            
                UPDATE CMS_AVQ_STATUS
                      SET CAS_ADDR_ONE=NVL(v_encr_addr_lineone,CAS_ADDR_ONE),
                          CAS_ADDR_TWO=NVL(v_encr_addr_linetwo,CAS_ADDR_TWO),
                          CAS_CITY_NAME =NVL(v_encr_city,CAS_CITY_NAME),
                          CAS_STATE_NAME=NVL(v_mailing_switch_state_code,CAS_STATE_NAME),
                          CAS_POSTAL_CODE =NVL(V_ZIPCODE,CAS_POSTAL_CODE),                        
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
                           FROM cms_appl_pan pan , cms_cardissuance_status issu_stat 
                          WHERE pan.cap_appl_code = issu_stat.ccs_appl_code
                            AND pan.cap_pan_code = issu_stat.ccs_pan_code
                            AND pan.cap_inst_code = issu_stat.ccs_inst_code
                            AND pan.cap_inst_code = P_INSTCODE
                            AND issu_stat.ccs_card_status='17'
                            and pan.cap_card_stat <> '9'
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
                       v_gprhash_pan,
                       v_gprencr_pan,
                       v_encr_full_name,
                       v_encr_addr_lineone,
                       v_encr_addr_linetwo,
                       v_encr_city,
                       v_mailing_switch_state_code,
                       V_ZIPCODE,                                     
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
    --END Added for FSS-1961(Melissa)

  SELECT TO_CHAR(SYSDATE, 'yyyymmdd') INTO V_BUSINESS_DATE FROM DUAL;
  
  -- Sivapragasam M end to update Contact Info on June 14 2012
  
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
     UPDATE TRANSACTIONLOG
        SET IPADDRESS = P_IPADDRESS
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
           TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG_TYPE AND
           BUSINESS_TIME = P_TRANTIME AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
ELSE
UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET IPADDRESS = P_IPADDRESS
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
           TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG_TYPE AND
           BUSINESS_TIME = P_TRANTIME AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
END IF;
           
           IF SQL%ROWCOUNT = 0 THEN
               v_errmsg :=
                     'Problem while inserting data into transaction log  dt '; --corrected for Mantis ID : 0015610
            v_respcode := '69'; --corrected for Mantis ID : 0015610
              RAISE EXP_MAIN_REJECT_RECORD;
             END IF;    
             EXCEPTION
             WHEN EXP_MAIN_REJECT_RECORD THEN        
             RAISE EXP_MAIN_REJECT_RECORD;
             WHEN OTHERS THEN
                 v_respcode := '69'; --corrected for Mantis ID : 0015610
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300); --corrected for Mantis ID : 0015610
               RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En select response code and insert record into txn log dtl
 
  
    --IF errmsg is OK then balance amount will be returned
  
    IF P_ERRMSG = 'OK' THEN
    
--Added on 18-02-2014: MVCSD-4121 & FWR starts
BEGIN
  IF V_RESPCODE ='00' AND V_RESPMSG ='OK' THEN
 
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    UPDATE CMS_TRANSACTION_LOG_DTL
    SET CTD_CHW_COMMENT      = P_COMMENT , CTD_ADDRVERIFY_FLAG = P_ADDRESS_VERIFIED_FLAG , CTD_DEVICE_ID=P_DEVICE_ID , CTD_MOBILE_NUMBER=P_OTHERPHONE
    WHERE CTD_INST_CODE      = P_INSTCODE
    AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
    AND CTD_RRN              = P_RRN
    AND CTD_BUSINESS_DATE    = P_TRANDATE
    AND CTD_BUSINESS_TIME    = P_TRANTIME
    AND CTD_DELIVERY_CHANNEL =P_DELIVERY_CHANNEL
    AND CTD_TXN_CODE = P_TXN_CODE 
    AND CTD_MSG_TYPE = P_MSG_TYPE;
ELSE
    UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST --Added for VMS-5733/FSP-991
    SET CTD_CHW_COMMENT      = P_COMMENT , CTD_ADDRVERIFY_FLAG = P_ADDRESS_VERIFIED_FLAG , CTD_DEVICE_ID=P_DEVICE_ID , CTD_MOBILE_NUMBER=P_OTHERPHONE
    WHERE CTD_INST_CODE      = P_INSTCODE
    AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
    AND CTD_RRN              = P_RRN
    AND CTD_BUSINESS_DATE    = P_TRANDATE
    AND CTD_BUSINESS_TIME    = P_TRANTIME
    AND CTD_DELIVERY_CHANNEL =P_DELIVERY_CHANNEL
    AND CTD_TXN_CODE = P_TXN_CODE 
    AND CTD_MSG_TYPE = P_MSG_TYPE;
END IF;
    
    IF SQL%ROWCOUNT         <> 1 THEN
      V_RESPMSG             := 'Problem while updating into CMS_TRANSACTION_LOG_DTL';
      V_RESPCODE            := '89';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
    IF P_ADDRESS_VERIFIED_FLAG  IS NOT NULL THEN
      IF P_ADDRESS_VERIFIED_FLAG = 'Y' THEN
        UPDATE CMS_CUST_MAST
        SET CCM_ADDRVERIFY_FLAG =2 , CCM_ADDVERIFY_DATE=SYSDATE,
        ccm_avfset_channel=P_DELIVERY_CHANNEL,  -- added for mantis id 14101 amudhan 
        ccm_avfset_txncode=P_TXN_CODE -- added for mantis id 14101 amudhan
        WHERE CCM_INST_CODE     = P_INSTCODE
        AND CCM_CUST_CODE       =V_CUST_CODE;
        IF SQL%ROWCOUNT        <> 1 THEN
          V_ERRMSG             := 'Problem while updating into CMS_CUST_MAST';
          V_RESPCODE           := '89';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
      ELSE
        V_ERRMSG   := 'Problem while selecting address verified flag';
        V_RESPCODE := '89';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
    END IF;
    
    
if  P_occupationtype is not null and P_occupationtype <> '00' then
Begin
 select vom_occu_name into v_occupation_desc  from vms_occupation_mast where vom_occu_code =P_occupationtype;
       
         exception
          when others then
           V_Respcode := '89';
           V_Errmsg   := 'Error while selecting Vms_Occupation_Mast ' || substr(sqlerrm, 1, 300);
           raise Exp_Main_Reject_Record;
End;
End If;
    
Begin
  Update Cms_Cust_Mast set CCM_OCCUPATION=upper(P_occupationtype) , CCM_OCCUPATION_OTHERS= upper(Decode(P_occupationtype,'00',P_Occupation,V_Occupation_Desc)) 
                Where Ccm_Cust_Code = V_Cust_Code And Ccm_Inst_Code = P_Instcode;

 EXCEPTION
        When Others Then
         V_Respcode := '89';
         V_Errmsg   := 'Error while updateing  Cms_Cust_Mast ' || Substr(Sqlerrm, 1, 300);
         Raise Exp_Main_Reject_Record;
end;    
  END IF;
EXCEPTION
WHEN EXP_MAIN_REJECT_RECORD THEN
  RAISE;
WHEN OTHERS THEN
  V_RESPCODE := '21';
  V_ERRMSG   := 'Problem while updating contact information' || SUBSTR(SQLERRM, 1, 200);
  RAISE EXP_MAIN_REJECT_RECORD;
END;
--Added on 18-02-2014: MVCSD-4121 & FWR ends
     --Sn of Getting  the Acct Balannce
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO = v_acct_number
         AND CAM_INST_CODE = P_INSTCODE
         FOR UPDATE NOWAIT;
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
    
     P_ERRMSG := ' ';
    END IF;
  
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_AUTH_REJECT_RECORD THEN
     --ROLLBACK;
    --Commented by Besky on 06-nov-12
 
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
 
    WHEN EXP_MAIN_REJECT_RECORD THEN
    
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
        ROLLBACK;
     END;
    
    --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)     
    IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_cap_card_stat, v_prod_code, v_card_type, v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_acctno);
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF;

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
         IPADDRESS,
         TRANS_DESC,
          --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
         error_msg,
         cr_dr_flag,
         cardstatus,
         acct_type,
         time_stamp
         --En Added by Pankaj S. for logging changes(Mantis ID-13160)
         )
       VALUES
        (P_MSG_TYPE,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         TO_DATE(V_BUSINESS_DATE, 'YYYY/MM/DD'),
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
         '0.00',--TRIM(TO_CHAR(0, '99999999999999999.99')),  --Modified by Pankaj S. for logging changes(Mantis ID-13160)
         V_CURRCODE,
         NULL,
         v_prod_code, --Added by Pankaj S. for logging changes(Mantis ID-13160)
         v_card_type, --Added by Pankaj S. for logging changes(Mantis ID-13160)
         P_TERMINALID,
         V_INIL_AUTHID,
         '0.00',--TRIM(TO_CHAR(0, '99999999999999999.99')), --Modified by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00', --Added by Pankaj S. for logging changes(Mantis ID-13160)
         '0.00', --Added by Pankaj S. for logging changes(Mantis ID-13160)
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         V_RESPCODE,
         P_IPADDRESS,
         V_TRANS_DESC,
          --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
         v_errmsg,
         v_dr_cr_flag,
         v_cap_card_stat,
         v_acct_type,
         systimestamp
         --En Added by Pankaj S. for logging changes(Mantis ID-13160)
         );
     
     EXCEPTION
       WHEN OTHERS THEN
       
        P_RESP_CODE := '89';
        P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
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
         CTD_CUST_ACCT_NUMBER,
         CTD_CHW_COMMENT,  --Added on 18-02-2014: MVCSD-4121 & FWR-43
         CTD_ADDRVERIFY_FLAG, --Added on 18-02-2014: MVCSD-4121 & FWR-43 
         CTD_DEVICE_ID, --Added FWR -43 
         CTD_MOBILE_NUMBER --Added FWR -43 
         )
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
         V_ACCT_NUMBER,
         P_COMMENT, --Added on 18-02-2014: MVCSD-4121 & FWR-43 
         P_ADDRESS_VERIFIED_FLAG, --Added on 18-02-2014: MVCSD-4121 & FWR-43
         P_DEVICE_ID, --Added FWR -43 
         P_OTHERPHONE --Added FWR -43 
         );
     
       P_ERRMSG := V_ERRMSG;
       RETURN;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG      := 'Problem while inserting data into transaction log  dtl' ||
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
         CTD_CUST_ACCT_NUMBER,
         CTD_CHW_COMMENT,  --Added on 18-02-2014: MVCSD-4121 & FWR-43
         CTD_ADDRVERIFY_FLAG, --Added on 18-02-2014: MVCSD-4121 & FWR-43
         CTD_DEVICE_ID, --Added FWR -43 
         CTD_MOBILE_NUMBER --Added FWR -43 
         )
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
         V_ACCT_NUMBER,
         P_COMMENT,  --Added on 18-02-2014: MVCSD-4121 & FWR 
         P_ADDRESS_VERIFIED_FLAG,
         P_DEVICE_ID, --Added FWR -43 
         P_OTHERPHONE --Added FWR -43 
         );
     
       P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
     END;
  END;
   
EXCEPTION
  WHEN OTHERS THEN
  
    -- insert transactionlog and cms_transactio_log_dtl for exception cases
  
    ROLLBACK;
    
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code  --Added by Pankaj S. for logging changes(Mantis ID-13160)
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type --Added by Pankaj S. for logging changes(Mantis ID-13160)
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INSTCODE) AND
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
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
    
     --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)     
    IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_cap_card_stat, v_prod_code, v_card_type, v_acct_number
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
        IPADDRESS,
        TRANS_DESC,
         --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        error_msg,
        cr_dr_flag,
        cardstatus,
        acct_type,
        time_stamp
        --En Added by Pankaj S. for logging changes(Mantis ID-13160)
        )
     VALUES
       (P_MSG_TYPE,
        P_RRN,
        P_DELIVERY_CHANNEL,
        P_TERMINALID,
        TO_DATE(V_BUSINESS_DATE, 'YYYY/MM/DD'),
        P_TXN_CODE,
        '',
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
        '0.00',--TRIM(TO_CHAR(0, '99999999999999999.99')), --Modified by Pankaj S. for logging changes(Mantis ID-13160)
        V_CURRCODE,
        NULL,
        v_prod_code, --Added by Pankaj S. for logging changes(Mantis ID-13160) 
        v_card_type, --Added by Pankaj S. for logging changes(Mantis ID-13160)
        P_TERMINALID,
        V_INIL_AUTHID,
        '0.00',--TRIM(TO_CHAR(0, '999999999999999990.99')),  --Modified by Pankaj S. for logging changes(Mantis ID-13160)
        '0.00', --Added by Pankaj S. for logging changes(Mantis ID-13160) 
        '0.00', --Added by Pankaj S. for logging changes(Mantis ID-13160)
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        P_IPADDRESS,
        V_TRANS_DESC,
        --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        v_errmsg,
        v_dr_cr_flag,
        v_cap_card_stat,
        v_acct_type,
        systimestamp
        --En Added by Pankaj S. for logging changes(Mantis ID-13160)
        );
    
    EXCEPTION
     WHEN OTHERS THEN
     
       P_RESP_CODE := '89';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
    END;
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
      CTD_CUST_ACCT_NUMBER,
      CTD_CHW_COMMENT,  --Added on 18-02-2014: MVCSD-4121 & FWR -43 
      CTD_ADDRVERIFY_FLAG, --Added on 18-02-2014: MVCSD-4121 & FWR -43 
      CTD_DEVICE_ID, --Added FWR -43 
      CTD_MOBILE_NUMBER --Added FWR -43 
      )
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
      V_ACCT_NUMBER,
      P_COMMENT ,--Added on 18-02-2014: MVCSD-4121 & FWR -43 
      P_ADDRESS_VERIFIED_FLAG, --Added on 18-02-2014: MVCSD-4121 & FWR -43 
      P_DEVICE_ID, --Added FWR -43 
      P_OTHERPHONE --Added FWR -43 
      );
  
END;
/
show error
