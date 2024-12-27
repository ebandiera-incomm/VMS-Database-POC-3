SET DEFINE OFF;
create or replace
PROCEDURE  VMSCMS.SP_IVR_MOBILE_UPDATE(P_INSTCODE      IN NUMBER,
                                           P_RRN           IN VARCHAR2,
                                           P_PAN           IN VARCHAR2,
                                           P_TXN_CODE      IN VARCHAR2,
                                           P_DELIVERY_CHNL IN VARCHAR2,
                                           P_MSG_TYPE      IN VARCHAR2,
                                           P_REVRSL_CODE   IN VARCHAR2,
                                           P_TXN_MODE      IN VARCHAR2,
                                           P_MBRNUMB       IN VARCHAR2,
                                           P_TRANDATE      IN VARCHAR2,
                                           P_TRANTIME      IN VARCHAR2,
                                           P_ANI           IN VARCHAR2,
                                           P_DNI           IN VARCHAR2,
                                           P_IPADDRESS     IN VARCHAR2,
                                           P_MERCHANT_NAME IN VARCHAR2,
                                           P_MERCHANT_CITY IN VARCHAR2,
                                           P_MOBILENUMBER  IN VARCHAR2,
                                           P_RESP_CODE     OUT VARCHAR2,
                                           P_ERRMSG        OUT VARCHAR2,
                                           p_optin_flag_out OUT VARCHAR2
                                          ) AS 
  /************************************************************************************************
   
   * Modified By      : Siva Arcot.
   * Modified Date    : 23-SEP-2013
   * Modified For     : JH-17
   * Modified Reason  : Mobile Number Updation Throgh IVR
   * Reviewer         : Dhiarj
   * Reviewed Date    : 23-SEP-2013
   * Build Number     : RI0024.5_B0001 
   
   * Modified Date    : 16-Dec-2013
   * Modified By      : Sagar More
   * Modified for     : Defect ID 13160
   * Modified reason  : To log below details in transactinlog if applicable
                        Acct_type,dr_cr_flag
   * Reviewer         : Dhiraj
   * Reviewed Date    : 16-Dec-2013
   * Release Number   : RI0024.7_B0001

   * Modified by      :Spankaj
   * Modified Date    : 07-Sep-15
   * Modified For     : FSS-2321
   * Reviewer         : Saravanankumar
   * Build Number     : VMSGPRHOSTCSD3.2       

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
	 
	 
	 	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01


    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
  ********************************************************************************************/

  V_CAP_PROD_CATG CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_PROD_CODE     CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE     CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_CAP_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_REQ_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_RESONCODE     CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_TOPUP_AUTH_ID TRANSACTIONLOG.AUTH_ID%TYPE;
  V_SPPRT_KEY     CMS_SPPRT_REASONS.CSR_SPPRT_KEY%TYPE;
  V_ERRMSG        VARCHAR2(300);
  V_RESPCODE      VARCHAR2(5);
  V_RESPMSG       VARCHAR2(500);
  V_CAPTURE_DATE  DATE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BASE_CURR          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_REMRK              VARCHAR2(100);
  V_ISPREPAID          BOOLEAN DEFAULT FALSE;
  V_CAP_CAFGEN_FLAG    CHAR(1);
  V_RRN_COUNT          NUMBER;
 -- V_MMPOS_USAGEAMNT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
 -- V_MMPOS_USAGELIMIT   CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN DATE;
  V_TRAN_DATE          DATE;
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BALANCE     NUMBER;
  V_AUTHID_DATE        VARCHAR2(8);

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);
  V_TXN_TYPE    VARCHAR2(2);
  V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
  V_KYC_FLAG CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;  
   V_CAP_CUST_CODE          cms_appl_pan.cap_cust_code%TYPE;
   v_ccount                 NUMBER (3);
   v_savngledgr_bal         cms_acct_mast.cam_ledger_bal%TYPE;


  v_dup_check              NUMBER (3);
  v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;

  
  V_PROD_ID  CMS_PROD_CATTYPE.CPC_PROD_ID%TYPE;
  V_NEW_PAN_CODE        cms_appl_pan.cap_pan_code_encr%type;    
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;     
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;               
   v_hash_pan_temp      CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
   V_ENCR_PAN_temp           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   V_HASH_PAN_CODE           CMS_APPL_PAN.CAP_PAN_CODE%TYPE; 
   v_pin_offset              CMS_APPL_PAN.cap_pin_off%TYPE; 
   v_timestamp       timestamp;     
   v_appl_code       CMS_APPL_PAN.CAP_APPL_CODE%type;
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
   v_update_excp EXCEPTION;
   V_OFFADDRCOUNT NUMBER;

   --SN : Added for 13160
    v_cr_dr_flag  cms_transaction_mast.ctm_credit_debit_flag%type;
    v_acct_type   cms_acct_mast.cam_type_code%type;   
    --EN : Added for 13160   
   v_encrypt_enable             cms_prod_cattype.cpc_encrypt_enable%type;
   v_profile_code               cms_prod_cattype.cpc_profile_code%type;
   V_ENCR_MOBILENUMB            CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE; 
   V_Decr_Cellphn       Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One       Cms_Addr_Mast.Cam_Mobl_One%Type;
    L_Alert_Lang_Id     Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
     V_Doptin_Flag Number;
Type CurrentAlert_Collection Is Table Of Varchar2(30);
 CurrentAlert CurrentAlert_Collection;
 v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag  Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type; 
   v_federal_state_flag  CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
   v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
   
BEGIN
  P_ERRMSG   := 'OK';
  V_RESPCODE := '00';
  V_REMRK    := 'Mobile Number Updation Through IVR';
p_optin_flag_out :='N';
  SAVEPOINT v_auth_savepoint;
   v_timestamp := systimestamp;
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21'; -- added by chinmaya
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
    BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21'; 
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
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC 
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC 
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
     V_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHNL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_ERRMSG := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  --Sn Duplicate RRN Check

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
   SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
         INSTCODE = P_INSTCODE AND DELIVERY_CHANNEL = P_DELIVERY_CHNL; 
ELSE
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
         INSTCODE = P_INSTCODE AND DELIVERY_CHANNEL = P_DELIVERY_CHNL; 
END IF;

  
    IF V_RRN_COUNT > 0 THEN
    
     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN ON ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
    
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;    
    WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG  := 'Error while checking duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;  
  
  END;

  --En Duplicate RRN Check
   BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHNL||P_TXN_CODE||P_PAN||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_respcode := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
     END;
     
  BEGIN
  
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');
  
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32';
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn select Pan detail
  BEGIN
    SELECT CAP_PROD_CATG,
         CAP_CARD_STAT,
         CAP_PROD_CODE,
         CAP_CARD_TYPE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_CUST_CODE, 
         cap_pin_off ,
         CAP_APPL_CODE          
     INTO V_CAP_PROD_CATG,
         V_CAP_CARD_STAT,
         V_PROD_CODE,
         V_CARD_TYPE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         V_CAP_CUST_CODE, 
         v_pin_offset,  
         v_appl_code      
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE AND
         CAP_MBR_NUMB = P_MBRNUMB;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  BEGIN
      SELECT upper(cpc_encrypt_enable),cpc_profile_code
        INTO v_encrypt_enable,v_profile_code
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_instcode
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
      V_RESPCODE := '21'; 
      V_ERRMSG   := 'no profile found for Cardtype'|| v_card_type ||'and prod code'
                         ||v_prod_code;
     RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_RESPCODE := '21';
         v_errmsg :=
               'Error from selecting the profile,encrypt enable flag details'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
      
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
     INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
     FROM CMS_ACCT_MAST
    WHERE 
           CAM_INST_CODE = P_INSTCODE
        AND CAM_ACCT_NO =  V_ACCT_NUMBER 
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
 
 
  BEGIN
--    SELECT CIP_PARAM_VALUE
--     INTO V_BASE_CURR
--     FROM CMS_INST_PARAM
--    WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';
  
           SELECT TRIM (cbp_param_value)  
		   INTO v_base_curr 
		   FROM cms_bin_param 
           WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
           AND cbp_profile_code = v_profile_code;
			 
			 
	 
  
    IF V_BASE_CURR IS NULL THEN
     V_ERRMSG := 'Base currency cannot be null ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD 
    THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Base currency is not defined for the BIN PROFILE ';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting base currency for bin ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  
  --Sn Authorize procedure call 
     BEGIN
         
         sp_authorize_txn_cms_auth (p_instcode,
                                    p_msg_type,
                                    p_rrn,
                                    P_DELIVERY_CHNL,
                                    0,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    P_PAN,
                                    NULL,
                                    NULL,--p_amount,
                                    NULL,--p_merchant_name,
                                    NULL,--p_merchant_city,
                                    NULL,
                                    V_BASE_CURR,
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
                                    NULL,--p_stan, 
                                    P_MBRNUMB,
                                    P_REVRSL_CODE,   
                                    NULL, --v_tran_amt,
                                   V_TOPUP_AUTH_ID,
                                    V_RESPCODE,
                                    V_RESPMSG,
                                  V_CAPTURE_DATE);

         IF v_respcode <> '00' AND V_RESPMSG <> 'OK'
         THEN
          p_errmsg := 'Error from auth process' || p_errmsg;
            RAISE exp_auth_reject_record;
         ELSE
         v_respcode := '1';
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '12';
            p_errmsg :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Authorize procedure call 

    --Sn Added for FSS-2321
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_chnl, p_txn_code, v_cap_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          v_respcode := '21';
          v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;   
    --En Added for FSS-2321
    
     IF V_ENCRYPT_ENABLE = 'Y' THEN
            V_ENCR_MOBILENUMB := FN_EMAPS_MAIN(P_MOBILENUMBER);
      ELSE
            V_ENCR_MOBILENUMB := P_MOBILENUMBER; 
      END IF;
    
  BEGIN
     
   Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into L_Alert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=V_Hash_Pan   and CSA_INST_CODE=P_Instcode;
    
    EXCEPTION
			WHEN OTHERS THEN
			  v_respcode := '21';
			  v_errmsg        := 'Error while selecting data from CMS_SMAANDEMAIL_ALERT' || SUBSTR (SQLERRM, 1, 200);
			  Raise exp_main_reject_record;
			END;
  BEGIN
   select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    Where Nvl(Dbms_Lob.Substr( Cps_Alert_Msg,1,1),0) !=0  
    And Cps_Prod_Code = V_Prod_Code
    And Cps_Card_Type = V_Card_Type
    and cps_alert_id=33
    And Cps_Inst_Code= P_Instcode
    And ( Cps_Alert_Lang_Id = l_alert_lang_id or (l_alert_lang_id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
         Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
         If(p_optin_flag_out = 'N' and ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then
          Select Cam_Mobl_One Into V_Cam_Mobl_One From Cms_Addr_Mast
          where cam_cust_code=V_CAP_CUST_CODE and cam_addr_flag='P' and cam_inst_code=P_Instcode;
          If(V_Encrypt_Enable = 'Y') Then 
            V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
            Else
            V_Decr_Cellphn := V_Cam_Mobl_One;
          End If;
            If(V_Decr_Cellphn <> P_Mobilenumber)
            Then
                P_Optin_Flag_Out :='Y';
                End If;
     End If;
 End If;
	EXCEPTION
			WHEN OTHERS THEN
			  v_respcode := '21';
			  v_errmsg        := 'Error while selecting data from CMS_PRODCATG_SMSEMAIL_ALERTS' || SUBSTR (SQLERRM, 1, 200);
			  Raise exp_main_reject_record;
			END;
  BEGIN
    UPDATE CMS_ADDR_MAST
      SET CAM_MOBL_ONE   = NVL(V_ENCR_MOBILENUMB,CAM_MOBL_ONE)         
    WHERE CAM_CUST_CODE = V_CAP_CUST_CODE AND CAM_INST_CODE = P_INSTCODE AND
         CAM_ADDR_FLAG = 'P';
     
         IF SQL%ROWCOUNT =0
                 THEN
                    RAISE v_update_excp;
                  END IF;   
    EXCEPTION
         WHEN v_update_excp THEN
         v_respcode := '21';
         V_ERRMSG := 'ERROR IN MOBILE NUMBER UPDATE' || V_CAP_CUST_CODE;
          RAISE EXP_MAIN_REJECT_RECORD;
            
   
    WHEN OTHERS
            THEN
         v_respcode := '21';
         v_errmsg := 'ERROR WHILE UPDATING MOBILE NUMBER' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
  END;
 
 BEGIN
      SELECT COUNT(*)
       INTO V_OFFADDRCOUNT
       FROM CMS_ADDR_MAST
      WHERE CAM_INST_CODE = P_INSTCODE AND CAM_CUST_CODE = V_CAP_CUST_CODE AND
           CAM_ADDR_FLAG = 'O';
     IF V_OFFADDRCOUNT > 0 THEN
       UPDATE CMS_ADDR_MAST
         SET CAM_MOBL_ONE   = NVL(V_ENCR_MOBILENUMB,CAM_MOBL_ONE)
        WHERE CAM_INST_CODE = P_INSTCODE AND CAM_CUST_CODE = V_CAP_CUST_CODE AND
            CAM_ADDR_FLAG = 'O';
            
            IF SQL%ROWCOUNT =0
                 THEN
                    RAISE v_update_excp;
                  END IF;
       END IF;   
        EXCEPTION
            WHEN v_update_excp THEN
              v_respcode := '21';
              V_ERRMSG := 'ERROR IN MOBILE NUMBER UPDATE' || V_CAP_CUST_CODE;
            RAISE EXP_MAIN_REJECT_RECORD;
            
            WHEN OTHERS
            THEN
         v_respcode := '21';
         v_errmsg := 'ERROR WHILE UPDATING MOBILE NUMBER for O' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
    END;
     BEGIN
         SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INSTCODE AND
        CMS_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
        CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG    := 'Problem while selecting data from response master ' ||
            V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89';
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
     
     BEGIN

IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET 
             ANI=P_ANI, 
             DNI=P_DNI       
       WHERE rrn = p_rrn
         AND delivery_channel = P_DELIVERY_CHNL
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
ELSE
        UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET 
             ANI=P_ANI, 
             DNI=P_DNI       
       WHERE rrn = p_rrn
         AND delivery_channel = P_DELIVERY_CHNL
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;

END IF;

      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transactionlog is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
   
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
        UPDATE CMS_TRANSACTION_LOG_DTL
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHNL
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_MSG_TYPE = P_MSG_TYPE
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
ELSE

         UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHNL
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_MSG_TYPE = P_MSG_TYPE
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
END IF;

      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transaction_log_dtl is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
       
   
EXCEPTION
   --<<Main Exception>>
    WHEN exp_auth_reject_record
   THEN
   -- ROLLBACK;
      p_resp_code := v_respcode;
      P_ERRMSG := V_RESPMSG;
      
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
         SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         AND delivery_channel = P_DELIVERY_CHNL
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
ELSE

      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         AND delivery_channel = P_DELIVERY_CHNL
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;

END IF;


      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transactionlog is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
   
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
        UPDATE CMS_TRANSACTION_LOG_DTL
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER,                           
             ctd_hashkey_id=V_HASHKEY_ID       
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHNL
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_MSG_TYPE = P_MSG_TYPE
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
ELSE
 UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER,                           
             ctd_hashkey_id=V_HASHKEY_ID       
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHNL
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_MSG_TYPE = P_MSG_TYPE
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
 
END IF;

      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transaction_log_dtl is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
   
    WHEN EXP_MAIN_REJECT_RECORD THEN
    
      ROLLBACK;
      
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                   cam_type_code                        --Added for 13160
                INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
                   v_acct_type                          --Added for 13160   
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
            CAP_INST_CODE = P_INSTCODE) AND
            CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BALANCE   := 0;
        END;

        
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
        
        --SN Added for 13160
        
        v_timestamp := systimestamp;
        
        if V_DR_CR_FLAG is null
        then
            
          BEGIN
          
            SELECT CTM_CREDIT_DEBIT_FLAG
             INTO V_DR_CR_FLAG
             FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE AND
                 CTM_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
                 CTM_INST_CODE = P_INSTCODE;
          EXCEPTION
            WHEN  OTHERS THEN
                null;
          END;
        
        end if; 
        
       if V_PROD_CODE is null
        then 
            
          BEGIN
            SELECT CAP_PROD_CATG,
                 CAP_CARD_STAT,
                 CAP_PROD_CODE,
                 CAP_CARD_TYPE,
                 CAP_PROXY_NUMBER,
                 CAP_ACCT_NO,
                 CAP_CUST_CODE, 
                 cap_pin_off ,
                 CAP_APPL_CODE          
             INTO V_CAP_PROD_CATG,
                 V_CAP_CARD_STAT,
                 V_PROD_CODE,
                 V_CARD_TYPE,
                 V_PROXUNUMBER,
                 V_ACCT_NUMBER,
                 V_CAP_CUST_CODE, 
                 v_pin_offset,  
                 v_appl_code      
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE AND
                 CAP_MBR_NUMB = P_MBRNUMB;
          EXCEPTION
            WHEN  OTHERS THEN
                    null;
          END;
          
       end if;              
        
        --EN Added for 13160
        
        
        

        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        time_stamp,
                        --SN Added for 13160
                        acct_type,
                        CR_DR_FLAG,
                        error_msg
                        --EN Added for 13160                        
                        )
            VALUES
                        (P_MSG_TYPE,
                        P_RRN,
                        P_DELIVERY_CHNL,
                        0,
                        P_TXN_CODE,
                        V_TXN_TYPE,
                        0,
                        DECODE(P_RESP_CODE, '00', 'C', 'F'),
                        P_RESP_CODE,
                        P_TRANDATE,
                        SUBSTR(P_TRANTIME, 1, 10),
                        V_HASH_PAN,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        '0.00',--NULL,                      --Modified for 13160
                        V_BASE_CURR,
                        NULL,
                        v_prod_code,--SUBSTR(P_PAN, 1, 4),  --Modified for 13160
                        v_card_type,--NULL,                 --Modified for 13160    
                        0,
                        NULL,
                        '0.00',--NULL,                          --Modified for 13160
                        '0.00',--NULL,                          --Modified for 13160
                        '0.00',--NULL,                          --Modified for 13160
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        nvl(V_ACCT_BALANCE,0),
                        nvl(V_LEDGER_BALANCE,0),
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        V_CAP_CARD_STAT, 
                        V_TRANS_DESC, 
                        v_timestamp,
                        --SN Added for 13160
                        v_acct_type,
                        V_DR_CR_FLAG,
                        V_ERRMSG
                        --EN Added for 13160                        
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;

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
                            CTD_TXN_TYPE,
                            CTD_MOBILE_NUMBER,
                            ctd_hashkey_id)
            VALUES
                            (P_DELIVERY_CHNL,
                            P_TXN_CODE,
                            '0200',
                            0,
                            P_TRANDATE,
                            P_TRANTIME,
                            V_HASH_PAN,
                            0,
                            V_BASE_CURR,
                            0,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            'E',
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE,
                            P_MOBILENUMBER,
                            V_HASHKEY_ID);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;

    WHEN OTHERS THEN
        ROLLBACK;  
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
            INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
            CAP_INST_CODE = P_INSTCODE) AND
            CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BALANCE   := 0;
        END;

        --Sn select response code and insert record into txn log dtl
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
        
        --SN Added for 13160
        
        v_timestamp := systimestamp;
        
        if V_DR_CR_FLAG is null
        then
            
          BEGIN
          
            SELECT CTM_CREDIT_DEBIT_FLAG
             INTO V_DR_CR_FLAG
             FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE AND
                 CTM_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
                 CTM_INST_CODE = P_INSTCODE;
          EXCEPTION
            WHEN  OTHERS THEN
                null;
          END;
        
        end if; 
        
       if V_PROD_CODE is null
        then 
            
          BEGIN
            SELECT CAP_PROD_CATG,
                 CAP_CARD_STAT,
                 CAP_PROD_CODE,
                 CAP_CARD_TYPE,
                 CAP_PROXY_NUMBER,
                 CAP_ACCT_NO,
                 CAP_CUST_CODE, 
                 cap_pin_off ,
                 CAP_APPL_CODE          
             INTO V_CAP_PROD_CATG,
                 V_CAP_CARD_STAT,
                 V_PROD_CODE,
                 V_CARD_TYPE,
                 V_PROXUNUMBER,
                 V_ACCT_NUMBER,
                 V_CAP_CUST_CODE, 
                 v_pin_offset,  
                 v_appl_code      
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE AND
                 CAP_MBR_NUMB = P_MBRNUMB;
          EXCEPTION
            WHEN  OTHERS THEN
                    null;
          END;
          
       end if;              
        
        --EN Added for 13160
                

        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        time_stamp,
                        --SN Added for 13160
                        acct_type,
                        CR_DR_FLAG,
                        error_msg
                        --EN Added for 13160
                        )
            VALUES
                        ('0200',
                        P_RRN,
                        P_DELIVERY_CHNL,
                        0,
                        P_TXN_CODE,
                        V_TXN_TYPE,
                        0,
                        DECODE(P_RESP_CODE, '00', 'C', 'F'),
                        P_RESP_CODE,
                        P_TRANDATE,
                        SUBSTR(P_TRANTIME, 1, 10),
                        V_HASH_PAN,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        '0.00',--NULL,                          --Modified for 13160    
                        V_BASE_CURR,
                        NULL,
                        v_prod_code,--SUBSTR(P_PAN, 1, 4),      --Modified for 13160
                        v_card_type,--NULL,                     --Modified for 13160
                        0,
                        NULL,
                        '0.00',--NULL,                          --Modified for 13160
                        '0.00',--NULL,                          --Modified for 13160
                        '0.00',--NULL,                          --Modified for 13160
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        nvl(V_ACCT_BALANCE,0),
                        nvl(V_LEDGER_BALANCE,0),
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        V_CAP_CARD_STAT, 
                        V_TRANS_DESC, 
                        v_timestamp,
                        --SN Added for 13160
                        v_acct_type,
                        V_DR_CR_FLAG,
                        V_ERRMSG
                        --EN Added for 13160                        
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;

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
                            CTD_TXN_TYPE,CTD_MOBILE_NUMBER,
                            ctd_hashkey_id)
            VALUES
                            (P_DELIVERY_CHNL,
                            P_TXN_CODE,
                            P_MSG_TYPE,
                            0,
                            P_TRANDATE,
                            P_TRANTIME,
                            V_HASH_PAN,
                            0,
                            V_BASE_CURR,
                            0,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            'E',
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE,
                            P_MOBILENUMBER,
                            V_HASHKEY_ID);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;

END;
/
show error