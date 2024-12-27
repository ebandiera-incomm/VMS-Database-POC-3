create or replace Procedure                        vmscms.SP_MOB_ALERTS(
                          P_Inst_Code         In  Number ,
                          P_MSG               IN  VARCHAR2, 
                          P_RRN               IN  VARCHAR2,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN  VARCHAR2,
                          P_TXN_MODE          IN  VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN  VARCHAR2,
                          P_PAN_CODE          IN  VARCHAR2, 
                          P_MBR_NUMB          IN  VARCHAR2,                         
                          P_RVSL_CODE         IN  VARCHAR2,
                          P_CUSTOMERID        IN  NUMBER,                                     
                          P_CUST_CODE         IN  VARCHAR2,
                          P_Curr_Code         In  Varchar2,
                          P_Alert_Name        In  Varchar2,
                          P_Alert_Stat        In  Varchar2,
                          P_Notify_Type       In  Varchar2,
                          P_ALERT_TRAN_TYPE   IN  VARCHAR2,                          
                          P_TRAN_AMOUNT       IN  VARCHAR2,
                          P_IPADDRESS         IN  VARCHAR2,   --Added by Ramesh.A on 19/09/2012
                          P_MOB_NO            IN  VARCHAR2,   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                          P_Device_Id         In  Varchar2,   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                          P_Ani               In  Varchar2,  --Added For JH-18
                          P_DNI               IN  VARCHAR2,  --Added For JH-18
                          P_OPTIN_LANG          IN       VARCHAR2,
                          P_AUTH_ID           OUT VARCHAR2, 
                          P_CUST_ID           OUT  NUMBER,                          
                          P_RESP_CODE         OUT VARCHAR2 ,
                          P_RESMSG            OUT VARCHAR2,
                          P_OPTED_LANG        OUT VARCHAR2,
                          p_optin_flag_out    OUT VARCHAR2)

AS
/*************************************************
     * Created Date     :  16-July-2012
     * Created By       :  Deepa T
     * PURPOSE          :  Alert transactions of MOB.         
     * Modified By      : Saravanakumar
      * Modified Date    :  09/01/2013
      * Modified Reason  :To remove the account number logging changes.
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  09/01/2013
     * Release Number     :  CMS3.5.1_RI0023_B0011
     
     * modified by       :  RAVI N
     * modified Date     :  09-AUG-13
     * modified reason   :  Adding new Input [P_MOB_NO,P_DEVICE_ID] parameters and logging cms_transaction_log_dtl
     * modified reason   :  FSS-1144
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  29-AUG-13
     * Build Number      :  RI0024.4_B0006
     
     * modified by       :  MageshKumar.S
     * modified Date     :  19-SEP-13
     * modified reason   :  JH-6(Internal testing Defect)
     * Reviewer          :  Dhiarj
     * Reviewed Date     :  19-Sep-2013
     * Build Number      :  RI0024.5_B0001
     
     * modified by       :  Anil Kumar.D
     * modified Date     :  01-Oct-13
     * modified reason   :  JH-18
     * Reviewer          :  Dhiarj
     * Reviewed Date     :  19-Sep-2013
     * Build Number      :  RI0024.5_B0001
     
     * modified by       :  Ramesh.A
     * modified Date     :  04-Dec-13
     * modified reason   :  DFCCHW-370
     * Reviewer          :  Dhiraj            
     * Reviewed Date     :  
     * Build Number      :  RI0024.6.2_B0001
     
     * Modified By      : Pankaj S.
     * Modified Date    : 19-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0001    

     * Modified By      : Amudhan S.
     * Modified Date    : 07-May-2014
     * Modified Reason  : Set Alerts txn is displaying under Financial tab (Mantis ID-14334)
     * Reviewer         : spankaj
     * Reviewed Date    : 27-May-2014
     * Build Number     : RI0027.1.7_B0001
     
     * Modified By      : Raja Gopal G
     * Modified Date    : 05-Aug-2014
     * Modified Reason  : Modfied the Condition For View Alerts
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0002
     
     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 29-April-15    
     * Modified For     : FSS-3369
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0.1_B0002
     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 30-April-15    
     * Modified For     : FSS-3369(Logic Change)
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0.1_B0003
     
     * Modified by      : Pankaj S.
     * Modified for     : To audit SMS and Email Alerts changes
     * Modified Date  : 21-Mar-2016
     * Reviewer          : Saravanan
     * Build Number  : VMSGPRHOST_4.0
     
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
	
	   * Modified By      : Karthick/Jey
       * Modified Date    : 05-17-2022
       * Purpose          : Archival changes.
       * Reviewer         : Venkat Singamaneni
       * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991

*************************************************/

V_TRAN_DATE             DATE;
V_AUTH_SAVEPOINT        NUMBER DEFAULT 0;
V_COUNT                 NUMBER;
V_COUNT1                NUMBER;
V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CUST_NAME             CMS_CUST_MAST.CCM_USER_NAME%TYPE;
V_HASH_PASSWORD         VARCHAR2(100);
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CARDSTAT              VARCHAR2(5); --Added by ramesh.a on 10/04/2012
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;

V_DR_CR_FLAG       VARCHAR2(2);
V_OUTPUT_TYPE      VARCHAR2(2);
V_TRAN_TYPE         VARCHAR2(2);
V_CAPTURE_DATE          DATE;
V_ALERT_COLUMN      VARCHAR2(50);
V_ALERT_COUNT       NUMBER(2);
v_query             varchar2(500);
v_col_name          CMS_SMSEMAIL_ALERT_DET.CAD_COLUMN_NAME%TYPE;
v_alert_amnt_column         CMS_SMSEMAIL_ALERT_DET.CAD_alert_amnt_column%TYPE;  -- Added by siva kumar m as on 20/09/2012
v_alert_value       NUMBER(1);
V_CRAD_ALERT_VALUE  NUMBER(1);
v_flag              NUMBER(1);
v_upd_query         varchar2(500);
V_ALERT_ID          CMS_SMSEMAIL_ALERT_DET.CAD_ALERT_ID%TYPE;
V_AMNT_COLUMN       CMS_SMSEMAIL_ALERT_DET.CAD_ALERT_AMNT_COLUMN%TYPE;
V_PROD_COLUMN       CMS_SMSEMAIL_ALERT_DET.CAD_PRODCC_COLUMN%TYPE;
v_alert_name        CMS_SMSEMAIL_ALERT_DET.CAD_ALERT_NAME%TYPE;
V_TRAN_AMT           NUMBER(9,3);
V_ALERT_AMOUNT       NUMBER;
V_PROD_CODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
V_PROD_ALERT_VALUE  NUMBER(1);
/*V_MOBILE_NO         CMS_CUST_MAST.CCM_MOBL_ONE%TYPE;  Commented by Besky on 12-dec-12
V_EMAIL_ID          CMS_CUST_MAST.CCM_EMAIL_ONE%TYPE; */
V_MOBILE_NO         CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;  
V_EMAIL_ID          CMS_ADDR_MAST.CAM_EMAIL%TYPE;      
V_DATE                DATE;
V_CARD_CURR         VARCHAR2(5);
v_cardconfig_query  varchar2(500);
v_prodconfig_query  varchar2(500);
V_CONFIG_FLAG       VARCHAR2(1);
v_sel_query         varchar2(500);
V_ALERT_DET         varchar2(3000); -- Modified by Raja Gopal
v_enabled_alertcnt  NUMBER;
V_RESP_CDE           VARCHAR2(5);
V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  for regarding FSS-1144
V_TIME_STAMP   TIMESTAMP;                                   -- Added  for regarding FSS-1144
v_cust_id                  cms_cust_mast.ccm_cust_id%TYPE;
v_optout_time_stamp varchar2(30); 
 
   --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_acct_number           cms_acct_mast.cam_acct_no%TYPE;
   v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type             cms_acct_mast.cam_type_code%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_sms_on_cnt number;
   v_email_on_cnt number;
   v_opted_lang VARCHAR2(1);
     v_alert_lang_id     VMS_ALERTS_SUPPORTLANG.VAS_ALERT_LANG_ID%TYPE;
     v_encrypt_enable  CMS_PROD_CATTYPE.cpc_encrypt_enable%TYPE;
     V_Decr_Cellphn       Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One       Cms_Addr_Mast.Cam_Mobl_One%Type;
    L_OptinAlert_Lang_Id     Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
     V_Doptin_Flag Number;
 Type Previousalert_Collection Is Table Of Varchar2(30);
 Previousalert Previousalert_Collection;
 v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag  Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type; 
   V_Federal_State_Flag  Cms_Smsandemail_Alert.Csa_Fedtax_Refund_Flag%Type;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991

  CURSOR ALERTDET IS
    select CAD_ALERT_NAME,CAD_COLUMN_NAME,CAD_PRODCC_COLUMN,cad_alert_id from CMS_SMSEMAIL_ALERT_DET;

BEGIN
     V_RESP_CDE := '1';
     p_optin_flag_out :='Y';
   SAVEPOINT V_AUTH_SAVEPOINT;
   V_TIME_STAMP:=SYSTIMESTAMP;   -- Added  for regarding FSS-1144

       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         V_RESP_CDE     := '12';
         V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE     := '12';
            V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;
        
    --Start Generate HashKEY value for regarding FSS-1144   
      BEGIN
        V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
     END;
   
   --End Generate HashKEY value for regarding FSS-1144        
                
  
        
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
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERRMSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;
        
      
    --En find debit and credit flag

       --Sn Duplicate RRN Check
        BEGIN
		
		--Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
	   
	   IF (v_Retdate>v_Retperiod) THEN                                                          --Added for VMS-5739/FSP-991
	   
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE                
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
		  
		ELSE
		
		  SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                      --Added for VMS-5739/FSP-991
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE                
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
		  
		END IF;

          IF V_RRN_COUNT    > 0 THEN
            V_RESP_CDE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;         
        END;
       --En Duplicate RRN Check

        
        --Sn Get the card details
         BEGIN
              SELECT CAP_CARD_STAT,CAP_PROD_CODE,CAP_CARD_TYPE,
                     cap_acct_no,ccm_cust_id  --Added by Pankaj S. for logging changes(Mantis ID-13160)
              INTO V_CARDSTAT,V_PROD_CODE,V_CARD_TYPE,
                     v_acct_number, --Added by Pankaj S. for logging changes(Mantis ID-13160)
                     v_cust_id
              FROM CMS_APPL_PAN,cms_cust_mast
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN AND cap_cust_code = ccm_cust_code
              AND cap_inst_code = CCM_INST_CODE;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                V_RESP_CDE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'Card number not found ' || P_PAN_CODE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
          END;
      --End Get the card details     
      
  BEGIN
      SELECT upper(cpc_encrypt_enable)
        INTO v_encrypt_enable
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Error while selecting the encrypt enable flag for 
	       prod code and card type' ||v_prod_code ||v_card_type
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
      
      
  
    IF P_TRAN_AMOUNT IS NOT NULL THEN
     IF (P_TRAN_AMOUNT >= 0) THEN
    V_TRAN_AMT := P_TRAN_AMOUNT;
     BEGIN
       SP_CONVERT_CURR(P_INST_CODE,
                    P_CURR_CODE,
                    P_PAN_CODE,
                    P_TRAN_AMOUNT,
                    V_TRAN_DATE,
                    V_TRAN_AMT,
                    V_CARD_CURR,
                    V_ERRMSG,
                    V_PROD_CODE,
                    V_CARD_TYPE);
     
       IF V_ERRMSG <> 'OK' THEN
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21'; -- Server Declined -220509
        V_ERRMSG   := 'Error from currency conversion ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
     ELSE
     V_RESP_CDE := '43';
       v_errmsg  := 'INVALID AMOUNT';
       RAISE EXP_REJECT_RECORD;
    END IF;
    END IF;
 

   --Sn To audit SMS and Email Alerts changes
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_channel, p_txn_code, p_cust_code, 1);
    EXCEPTION
       WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg :='Error while inserting audit dtls- ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    --En To audit SMS and Email Alerts changes
      
      
     IF P_ALERT_TRAN_TYPE='V' THEN
    
     BEGIN
      
      select CSA_ALERT_LANG_ID INTO v_opted_lang from cms_smsandemail_alert 
      where csa_pan_code=V_HASH_PAN;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card ';  
                         
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
      
      END;

   /*  BEGIN
       
        SELECT CAD_ALERT_ID
          INTO V_ALERT_ID
          FROM cms_smsemail_alert_det
         WHERE cad_alert_name = P_Alert_Name;
         
           EXCEPTION 
         WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '132';
                V_ERRMSG  := 'Invalid Alert Name';               
              RAISE EXP_REJECT_RECORD;
               
               WHEN OTHERS THEN
                
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
      
        END;  
    */
    
        BEGIN
        
        
             IF v_opted_lang IS NULL THEN
      
            SELECT cps_config_flag,cps_alert_lang_id
                   INTO V_CONFIG_FLAG,v_opted_lang
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND CPS_DEFALERT_LANG_FLAG='Y'
               and rownum=1;
            --   and cps_alert_id=V_ALERT_ID;
        ELSE
               SELECT cps_config_flag
                   INTO V_CONFIG_FLAG
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND cps_alert_lang_id=v_opted_lang
                 and rownum=1;
            --   and cps_alert_id=V_ALERT_ID;
            
            
        END IF;    
                   EXCEPTION 
                      WHEN NO_DATA_FOUND THEN
                      V_RESP_CDE := '21';
                      V_ERRMSG := 'Details Not Found For the product code ' || V_PROD_CODE ||
                           ' and card type' || V_CARD_TYPE;
                             RAISE EXP_REJECT_RECORD;
                      WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERRMSG := 'Error while selecting alerts for ' || V_PROD_CODE ||
                           ' and ' || V_CARD_TYPE;
                        RAISE EXP_REJECT_RECORD;
                     
                     END;
           
                     
       IF V_CONFIG_FLAG='N' THEN
       
        V_RESP_CDE := '61';
        V_ERRMSG   := 'ALERT CONFIGURATION NOT DONE FOR THIS PRODUCT CATEGORY ' ;
        RAISE EXP_REJECT_RECORD;
        
       
       ELSE
       
         FOR I1 IN ALERTDET LOOP
         
        BEGIN
        --    v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where '||I1.CAD_PRODCC_COLUMN ||' !=0 
           v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where DBMS_LOB.substr(cps_alert_msg,1,1) !=0 
            and CPS_PROD_CODE =:1 AND CPS_CARD_TYPE =:2 AND CPS_INST_CODE=:3 AND cps_alert_lang_id=:4 and cps_alert_id=:5' ;
            execute immediate v_query into v_enabled_alertcnt using V_PROD_CODE,V_CARD_TYPE,P_INST_CODE,v_opted_lang,I1.cad_alert_id;
         
         if v_enabled_alertcnt=1 then
         
            BEGIN
            SELECT cad_alert_name, cad_column_name
              INTO v_alert_name, v_col_name
              FROM cms_smsemail_alert_det
             WHERE --cad_prodcc_column = I1.cad_prodcc_column;
              cad_alert_id=I1.cad_alert_id;
              
             v_cardconfig_query:= 'select '|| v_col_name||' from CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE=:1';               
             execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE using V_HASH_PAN;
             
              EXCEPTION
               
                WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card '||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
             END;
              
            IF V_ALERT_DET IS NOT NULL THEN
            
            V_ALERT_DET:=V_ALERT_DET||'||';
            
            END IF;  
             
             
             
            IF V_CRAD_ALERT_VALUE is null or V_CRAD_ALERT_VALUE=0 THEN   --Added NULL check for DFCCHW-370 on 04/DEC/2013
                   
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~'||'BOTH'||'~'||'OFF';
             
             ELSIF V_CRAD_ALERT_VALUE=1 THEN
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~SMS~ON||'||v_alert_name||'~EMAIL~OFF';
             
             ELSIF V_CRAD_ALERT_VALUE=2 THEN
             
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~EMAIL~ON||'||v_alert_name||'~SMS~OFF';
             ELSIF V_CRAD_ALERT_VALUE=3 THEN
             
             
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~'||'BOTH'||'~'||'ON';                        
         
            END IF;
    
     END IF;
        
        EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG  := 'Error while Selecting Producat Catg Alert Details'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
        END;
        
        END LOOP;
       
       END IF;
    
       
    
    ELSIF P_ALERT_TRAN_TYPE='S' THEN  
    
     BEGIN
     IF P_OPTIN_LANG IS NOT NULL THEN
   SELECT VAS_ALERT_LANG_ID INTO
   v_alert_lang_id
   FROM VMS_ALERTS_SUPPORTLANG
   WHERE UPPER(VAS_ALERT_LANG)=TRIM(UPPER(P_OPTIN_LANG));
   ELSE
   SELECT cps_alert_lang_id INTO v_alert_lang_id  FROM 
   cms_prodcatg_smsemail_alerts
     WHERE cps_inst_code = P_INST_CODE
         AND cps_prod_code = V_prod_code
         AND cps_card_type = V_card_type
         AND cps_defalert_lang_flag='Y'
         AND ROWNUM=1;
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
         V_RESP_CDE := '21';
         v_errmsg :='Unsupported Language ';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         v_errmsg :=
               'Error while selecting language id for '
            || P_OPTIN_LANG;
           
         RAISE EXP_REJECT_RECORD;
   END;
    
        BEGIN
       
        SELECT CAD_ALERT_ID,cad_column_name,CAD_ALERT_AMNT_COLUMN,CAD_PRODCC_COLUMN
          INTO V_ALERT_ID,v_col_name,V_AMNT_COLUMN,V_PROD_COLUMN
          FROM cms_smsemail_alert_det
         WHERE cad_alert_name = P_Alert_Name;
         
           EXCEPTION 
         WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '132';
                V_ERRMSG  := 'Invalid Alert Name';               
              RAISE EXP_REJECT_RECORD;
        END;  
        
                     
         BEGIN
         
       --  v_prodconfig_query:= 'select CPS_CONFIG_FLAG,)'||V_PROD_COLUMN ||' 
          v_prodconfig_query:= 'select CPS_CONFIG_FLAG,DBMS_LOB.substr(cps_alert_msg,1,1)
                 FROM CMS_PRODCATG_SMSEMAIL_ALERTS where CPS_INST_CODE =:1 
                AND CPS_PROD_CODE=:2 AND CPS_CARD_TYPE=:3  AND cps_alert_lang_id=:4 and cps_alert_id=:5'; 
          execute immediate v_prodconfig_query INTO V_CONFIG_FLAG,V_PROD_ALERT_VALUE using P_INST_CODE,V_PROD_CODE,V_CARD_TYPE,v_alert_lang_id,V_ALERT_ID;
          
          EXCEPTION 
          WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '21';
          V_ERRMSG := 'Invalid product code ' || V_PROD_CODE ||
               ' and card type' || V_CARD_TYPE;
                 RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG := 'Error while selecting alerts for ' || V_PROD_CODE ||
               ' and ' || V_CARD_TYPE||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         
         END;
         
          BEGIN 
        v_cardconfig_query:= 'select '|| v_col_name|| ' from CMS_SMSANDEMAIL_ALERT  WHERE CSA_PAN_CODE=:1';               
        execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE  using V_HASH_PAN;
          
          EXCEPTION 
          WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '21';
          V_ERRMSG := 'Alert Details of Card Not Found';
                 RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG := 'Error while selecting alerts for the Card'||SUBSTR(SQLERRM, 1, 200); 
            RAISE EXP_REJECT_RECORD;
         
         END;
             
       --Commented by Besky on 12-dec-12  
         /*BEGIN
         SELECT CCM_MOBL_ONE,CCM_EMAIL_ONE INTO V_MOBILE_NO,V_EMAIL_ID 
         FROM CMS_CUST_MAST WHERE CCM_CUST_CODE=P_CUST_CODE AND CCM_INST_CODE=P_INST_CODE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '21';
         V_ERRMSG   := 'Customer Details Not Found';
         RAISE EXP_REJECT_RECORD;
             
         END;*/
         
     --Added  by Besky on 12-dec-12      
     
         BEGIN
         SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
                decode(v_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
         INTO V_MOBILE_NO,V_EMAIL_ID 
         FROM CMS_ADDR_MAST WHERE CAM_CUST_CODE=P_CUST_CODE 
         AND CAM_INST_CODE=P_INST_CODE
         AND cam_addr_flag = 'P';
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '21';
         V_ERRMSG   := 'Customer Details Not Found';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG   := 'Error while selecting CMS_ADDR_MAST '||substr(sqlerrm,1,200);
         RAISE EXP_REJECT_RECORD;
        
         END;
         
         
        BEGIN
        
        IF V_CONFIG_FLAG='N' THEN
        
             V_RESP_CDE := '61';
             V_ERRMSG   := 'ALERT CONFIGURATION NOT DONE FOR THIS PRODUCT CATEGORY ' ||
                V_PROD_CODE || ' and ' || V_CARD_TYPE;
            RAISE EXP_REJECT_RECORD;
        
        ELSE 
        
        IF V_PROD_ALERT_VALUE=0 THEN
        
            V_RESP_CDE := '61';
             V_ERRMSG   := p_alert_name||' CONFIGURATION NOT DONE FOR THIS PRODUCT CATEGORY ' ||
                V_PROD_CODE || ' and ' || V_CARD_TYPE;
            RAISE EXP_REJECT_RECORD;
        
        END IF;
        
        IF  P_ALERT_STAT='ON' AND P_NOTIFY_TYPE='BOTH' THEN
        
            v_alert_value:=3;            
             
             IF V_MOBILE_NO IS NULL THEN
             
             V_RESP_CDE := '124'; -- Modified by MageshKumar.S on 19-09-2013 for JH-6(Internal Testing Defect)
             V_ERRMSG   := 'For Enabling SMS alert Mobile Number should be Mandatory';
             RAISE EXP_REJECT_RECORD;
             
             END IF;
             
            IF V_EMAIL_ID IS NULL THEN
             
             V_RESP_CDE := '125';
             V_ERRMSG   := 'For Enabling EMail alert EMail ID should be Mandatory';
                RAISE EXP_REJECT_RECORD;
             END IF;
            
        ELSIF ((P_ALERT_STAT='ON' AND P_NOTIFY_TYPE='SMS') OR 
                ((V_CRAD_ALERT_VALUE='3' OR V_CRAD_ALERT_VALUE='1') AND 
                (P_ALERT_STAT='OFF' AND P_NOTIFY_TYPE='EMAIL'))) THEN
        
             v_alert_value:=1;
             
             IF V_MOBILE_NO IS NULL THEN
             
             V_RESP_CDE := '124'; -- Modified by MageshKumar.S on 19-09-2013 for JH-6(Internal Testing Defect)
             V_ERRMSG   := 'For Enabling SMS alert Mobile Number should be Mandatory';
             RAISE EXP_REJECT_RECORD;
             
             END IF;
                          
        ELSIF ((P_ALERT_STAT='ON' AND P_NOTIFY_TYPE='EMAIL') OR 
               ( (V_CRAD_ALERT_VALUE='3' OR V_CRAD_ALERT_VALUE='2') AND (P_ALERT_STAT='OFF' AND P_NOTIFY_TYPE='SMS'))) THEN
        
             v_alert_value:=2;
             
             IF V_EMAIL_ID IS NULL THEN
             
             V_RESP_CDE := '125';
             V_ERRMSG   := 'For Enabling EMail alert EMail ID should be Mandatory';
                RAISE EXP_REJECT_RECORD;
             END IF;
             
        ELSE
            v_alert_value:=0;
        END IF; 
        
        END IF;
        EXCEPTION 
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
        V_RESP_CDE:='21';
        V_ERRMSG  := SUBSTR(SQLERRM, 1, 200);               
        RAISE EXP_REJECT_RECORD;
        END;
                     
       
            BEGIN
            
  Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into L_Optinalert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=V_HASH_PAN  and CSA_INST_CODE=P_INST_CODE;
      EXCEPTION
        WHEN OTHERS THEN
            V_RESP_CDE := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
     select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    Where Nvl(Dbms_Lob.Substr( Cps_Alert_Msg,1,1),0) !=0  
    And Cps_Prod_Code = v_Prod_Code
    And Cps_Card_Type = v_card_type
    and cps_alert_id=33
    And Cps_Inst_Code= P_INST_CODE
       And ( Cps_Alert_Lang_Id = L_Optinalert_Lang_Id or (L_Optinalert_Lang_Id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
          Previousalert := Previousalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
             
              If (1 Member Of Previousalert Or 3 Member Of Previousalert )  
               Then
              p_optin_flag_out:='N';
            Else
                if(v_alert_value = 1  or v_alert_value = 3)
                Then
                p_optin_flag_out:='Y';
                 Else
               p_optin_flag_out:='N';
            End If; 
        End If; 
      Else
       P_Optin_Flag_Out:='N';
     End If; 
      EXCEPTION
        WHEN OTHERS THEN
            V_RESP_CDE := '21';
            v_errmsg :='Error while selecting product category alerts(double optin) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END; 
      BEGIN
        --        IF V_ALERT_ID IN(2,5) THEN
         IF V_ALERT_ID IN(10,16) THEN
                
                    IF P_TRAN_AMOUNT IS NULL THEN
                    
                    V_RESP_CDE := '21';
                     V_ERRMSG   := 'Amount should be Mandatory for'|| p_alert_name;
                        RAISE EXP_REJECT_RECORD;
                        
                    END IF;
                
                v_upd_query:= 'update CMS_SMSANDEMAIL_ALERT set '||v_col_name ||'=:1 ,'|| V_AMNT_COLUMN||'=:2,CSA_ALERT_LANG_ID=:3 where CSA_PAN_CODE =:4'; 
                execute immediate v_upd_query using v_alert_value,V_TRAN_AMT,v_alert_lang_id,V_HASH_PAN;
                           
                
                ELSE
                
                    v_upd_query:= 'update CMS_SMSANDEMAIL_ALERT set '||v_col_name ||'=:1,CSA_ALERT_LANG_ID=:2  where CSA_PAN_CODE =:3'; 
                    execute immediate v_upd_query using v_alert_value,v_alert_lang_id,V_HASH_PAN;
                    V_TRAN_AMT:=NULL;
                
                END IF;
            EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
            RAISE;
            WHEN OTHERS THEN
            V_RESP_CDE:='21';
            V_ERRMSG  := SUBSTR(SQLERRM, 1, 200);               
              RAISE EXP_REJECT_RECORD;
            END; 
     
              
       IF v_alert_value=3 THEN
              
        V_ALERT_DET:=P_ALERT_NAME||'~ON~BOTH~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'));
        
        ELSIF v_alert_value=2 THEN
        
        V_ALERT_DET:=P_ALERT_NAME||'~ON~EMAIL~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'))||'||'||P_ALERT_NAME||'~OFF~SMS~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'));
        
        ELSIF v_alert_value=1 THEN
        
        V_ALERT_DET:=P_ALERT_NAME||'~ON~SMS~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'))||'||'||P_ALERT_NAME||'~OFF~EMAIL~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'));
        
        ELSE
        
        V_ALERT_DET:=P_ALERT_NAME||'~OFF~BOTH~'||trim(to_char(V_TRAN_AMT,'99999999999990.00'));

        END IF;
        
        
       v_optout_time_stamp:=to_char(SYSTIMESTAMP,'DD-Mon-RR HH24:MI:SS.FF');
       v_sms_on_cnt :=0;
       v_email_on_cnt :=0;
       
       
          FOR I1 IN ALERTDET LOOP
         
        BEGIN
        --    v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where '||I1.CAD_PRODCC_COLUMN ||' !=0 
         v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where DBMS_LOB.substr(cps_alert_msg,1,1) !=0 
            and CPS_PROD_CODE =:1 AND CPS_CARD_TYPE =:2 AND CPS_INST_CODE=:3 AND cps_alert_lang_id=:4 and cps_alert_id=:5' ;
            execute immediate v_query into v_enabled_alertcnt using V_PROD_CODE,V_CARD_TYPE,P_INST_CODE,v_alert_lang_id,I1.cad_alert_id;
         
         if v_enabled_alertcnt=1 then
         
            BEGIN
            SELECT cad_alert_name, cad_column_name
              INTO v_alert_name, v_col_name
              FROM cms_smsemail_alert_det
             WHERE --cad_prodcc_column = I1.cad_prodcc_column;
             cad_alert_id=I1.cad_alert_id;
             
             v_cardconfig_query:= 'select '|| v_col_name||' from CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE=:1';               
             execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE using V_HASH_PAN;
             
              EXCEPTION
               
                WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card '||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
             END;
              
          --  IF V_ALERT_DET IS NOT NULL THEN
            
          --  V_ALERT_DET:=V_ALERT_DET||'||';
            
          --  END IF;  
             
             
            IF V_CRAD_ALERT_VALUE=1 THEN
              v_sms_on_cnt:=v_sms_on_cnt+1;
             ELSIF V_CRAD_ALERT_VALUE=2 THEN
                v_email_on_cnt:=v_email_on_cnt+1;
             ELSIF V_CRAD_ALERT_VALUE=3 THEN
             v_sms_on_cnt:=v_sms_on_cnt+1;
             v_email_on_cnt:=v_email_on_cnt+1;
            END IF;
    
     END IF;
        
        EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG  := 'Error while Selecting Producat Catg Alert Details'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
        END;
        
        END LOOP;
        
         BEGIN
      
         SELECT COUNT (*)
           INTO v_count
           FROM cms_optin_status
          WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;

         IF v_count > 0
         THEN
            UPDATE cms_optin_status
               SET cos_sms_optinflag = decode(v_sms_on_cnt,0,0,1),
                   cos_sms_optintime =to_timestamp(decode(v_sms_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_sms_optouttime =to_timestamp(decode(v_sms_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_email_optinflag = decode(v_email_on_cnt,0,0,1),
                   cos_email_optintime =to_timestamp(decode(v_email_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_email_optouttime = to_timestamp(decode(v_email_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF')
             WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;
         ELSE
            INSERT INTO cms_optin_status
                        (cos_inst_code, 
                        cos_cust_id, 
                        cos_sms_optinflag,
                         cos_sms_optintime,
                         cos_sms_optouttime,
                         cos_email_optinflag,
                         cos_email_optintime,
                         cos_email_optouttime
                        )
                 VALUES (p_inst_code, 
                 v_cust_id, 
                 decode(v_sms_on_cnt,0,0,1),
                 to_timestamp(decode(v_sms_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                 to_timestamp(decode(v_sms_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF'),
                 decode(v_email_on_cnt,0,0,1),
                 to_timestamp(decode(v_email_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                 to_timestamp(decode(v_email_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF')
                );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            V_RESP_CDE := '21';
            V_ERRMSG :=
                  'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

    ELSIF P_ALERT_TRAN_TYPE='A' THEN
    
        BEGIN
       
          SELECT CAD_ALERT_ID,cad_column_name,CAD_ALERT_AMNT_COLUMN
          INTO V_ALERT_ID,v_col_name,V_AMNT_COLUMN
          FROM cms_smsemail_alert_det
         WHERE cad_alert_name = p_alert_name;
        EXCEPTION 
         WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '132';
                V_ERRMSG  := 'Invalid Alert Name';               
              RAISE EXP_REJECT_RECORD;
        END;
        
         BEGIN
      
      select CSA_ALERT_LANG_ID INTO v_opted_lang from cms_smsandemail_alert 
      where csa_pan_code=V_HASH_PAN;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card ';  
                         
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
      
      END;
        
        BEGIN
        
        
          IF v_opted_lang IS NULL THEN
      
            SELECT cps_config_flag,cps_alert_lang_id
                   INTO V_CONFIG_FLAG,v_opted_lang
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND CPS_DEFALERT_LANG_FLAG='Y'
               and cps_alert_id=V_ALERT_ID;
        ELSE
               SELECT cps_config_flag
                   INTO V_CONFIG_FLAG
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND cps_alert_lang_id=v_opted_lang
                and cps_alert_id=V_ALERT_ID;
            
            
        END IF;   
      EXCEPTION 
                      WHEN NO_DATA_FOUND THEN
                      V_RESP_CDE := '21';
                      V_ERRMSG := 'Details Not Found For the product code ' || V_PROD_CODE ||
                           ' and card type' || V_CARD_TYPE;
                             RAISE EXP_REJECT_RECORD;
                      WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERRMSG := 'Error while selecting alerts for ' || V_PROD_CODE ||
                           ' and ' || V_CARD_TYPE;
                        RAISE EXP_REJECT_RECORD;
                     
                     END;
                     
       IF V_CONFIG_FLAG='N' THEN
       
        V_RESP_CDE := '61';
        V_ERRMSG   := 'ALERT CONFIGURATION NOT DONE FOR THIS PRODUCT CATEGORY ' ;
        RAISE EXP_REJECT_RECORD;
        
        END IF;
          
        BEGIN            
                 
     --    IF V_ALERT_ID IN(2,5) THEN
      IF V_ALERT_ID IN(10,16) THEN
         
         v_sel_query:='select '||v_col_name||','||V_AMNT_COLUMN||' FROM CMS_SMSANDEMAIL_ALERT
         WHERE CSA_PAN_CODE=:1';
         
         execute immediate v_sel_query INTO v_alert_value, V_ALERT_AMOUNT using V_HASH_PAN;
                  
         ELSE
         
         v_sel_query:='select '||v_col_name||'  FROM CMS_SMSANDEMAIL_ALERT
         WHERE CSA_PAN_CODE=:1';
         
         execute immediate v_sel_query INTO v_alert_value using V_HASH_PAN;
         V_ALERT_AMOUNT:=NULL;
         
         END IF;
         EXCEPTION 
         WHEN OTHERS THEN
         V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Status of Alerts For Card'||SUBSTR(SQLERRM, 1, 200);               
              RAISE EXP_REJECT_RECORD;
         
       END ; 
         
         
        IF v_alert_value=3 THEN
              
        V_ALERT_DET:='ON~BOTH~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
        
        ELSIF v_alert_value=2 THEN
        
        V_ALERT_DET:='ON~EMAIL~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'))||'||OFF~SMS~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
        
        ELSIF v_alert_value=1 THEN
        
        V_ALERT_DET:='ON~SMS~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'))||'||OFF~EMAIL~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
        
        ELSE
        
        V_ALERT_DET:='OFF~BOTH~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
        
        END IF;    
        
                                        --Added by Ramesh.A on 19/09/2012  for CHW veiw sms&email alerts 
    ELSIF P_ALERT_TRAN_TYPE='VA' THEN
      
      
      BEGIN
      
      select CSA_ALERT_LANG_ID INTO v_opted_lang from cms_smsandemail_alert 
      where csa_pan_code=V_HASH_PAN;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card ';  
                         
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
      
      END;

        BEGIN
        
        IF v_opted_lang IS NULL THEN
      
            SELECT cps_config_flag,cps_alert_lang_id
                   INTO V_CONFIG_FLAG,v_opted_lang
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND CPS_DEFALERT_LANG_FLAG='Y'
               and rownum=1;
        ELSE
               SELECT cps_config_flag
                   INTO V_CONFIG_FLAG
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = P_INST_CODE
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
               AND cps_alert_lang_id=v_opted_lang
                and rownum=1;
            
            
        END IF;    
                   EXCEPTION 
                      WHEN NO_DATA_FOUND THEN
                    
                      V_RESP_CDE := '21';
                      V_ERRMSG := 'Details Not Found For the product code ' || V_PROD_CODE ||
                           ' and card type' || V_CARD_TYPE;
                             RAISE EXP_REJECT_RECORD;
                      WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERRMSG := 'Error while selecting alerts for ' || V_PROD_CODE ||
                           ' and ' || V_CARD_TYPE;
                        RAISE EXP_REJECT_RECORD;
                     
                     END;
                     
       IF V_CONFIG_FLAG='N' THEN
       
        V_RESP_CDE := '61';
        V_ERRMSG   := 'ALERT CONFIGURATION NOT DONE FOR THIS PRODUCT CATEGORY ' ;
        RAISE EXP_REJECT_RECORD;
        
       
       ELSE
       
         FOR I1 IN ALERTDET LOOP
         -- Modifed by Raja Gopal G for View Alerts
        BEGIN
        --    v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where '||I1.CAD_PRODCC_COLUMN ||' !=0  
         v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where DBMS_LOB.substr(cps_alert_msg,1,1) !=0 
            and CPS_PROD_CODE =:1 AND CPS_CARD_TYPE =:2 AND CPS_INST_CODE=:3 AND cps_alert_lang_id=:4  and cps_alert_id=:5'  ;
            execute immediate v_query into v_enabled_alertcnt using V_PROD_CODE,V_CARD_TYPE,P_INST_CODE,v_opted_lang,I1.cad_alert_id;
         
         if v_enabled_alertcnt=1 then
        
            BEGIN
            SELECT  CAD_ALERT_ID, cad_alert_name, cad_column_name,cad_alert_amnt_column
              INTO V_ALERT_ID,v_alert_name, v_col_name,v_alert_amnt_column
              FROM cms_smsemail_alert_det
             WHERE --cad_prodcc_column = I1.cad_prodcc_column;
             cad_alert_id=I1.cad_alert_id;
             
             
         --   if V_ALERT_ID in (2,5) then
          IF V_ALERT_ID IN(10,16) THEN
             v_cardconfig_query:= 'select '|| v_col_name||','||v_alert_amnt_column || '  from CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE=:1';   
                  
                                     
             execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE,V_ALERT_AMOUNT using V_HASH_PAN;
             
             else
               V_ALERT_AMOUNT :='';
              v_cardconfig_query:= 'select '|| v_col_name||'   from CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE=:1';   
                                                               
             execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE using V_HASH_PAN;
             
             
             end if;
             
             
              EXCEPTION
               
                WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'No Alert Details found for the card '||SUBSTR(SQLERRM, 1, 200);  
                         
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
             END;
             
            IF V_ALERT_DET IS NOT NULL THEN
            
            V_ALERT_DET:=V_ALERT_DET||'||';
            
            END IF;  
             
            IF V_CRAD_ALERT_VALUE is null or V_CRAD_ALERT_VALUE=0 THEN  --Added NULL check for DFCCHW-370 on 04/DEC/2013
                          
                   
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~'||'BOTH'||'~'||'OFF'||'~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
             
             ELSIF V_CRAD_ALERT_VALUE=1 THEN
            V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~SMS~ON~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'))||'||'||v_alert_name||'~EMAIL~OFF'||'~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
      
             ELSIF V_CRAD_ALERT_VALUE=2 THEN
             
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~EMAIL~ON'||'~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'))||'||'||v_alert_name||'~SMS~OFF'||'~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
           
             ELSIF V_CRAD_ALERT_VALUE=3 THEN
                         
             V_ALERT_DET:=V_ALERT_DET||v_alert_name||'~'||'BOTH'||'~'||'ON'||'~'||trim(to_char(V_ALERT_AMOUNT,'99999999999990.00'));
             
         
            END IF;
        
        END IF;
        
        EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG  := 'Error while Selecting Producat Catg Alert Details by 1'||SUBSTR(SQLERRM, 1, 200);              
              RAISE EXP_REJECT_RECORD;
        END;
        
        END LOOP;
       
       END IF;
       
        
    END IF; 

IF P_ALERT_TRAN_TYPE <> 'S' THEN
 BEGIN
   SELECT UPPER(VAS_ALERT_LANG) INTO
   P_OPTED_LANG
   FROM VMS_ALERTS_SUPPORTLANG
   WHERE VAS_ALERT_LANG_ID=v_opted_lang;
    EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
         V_RESP_CDE := '21';
         v_errmsg :='Unsupported Language ';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         v_errmsg :=
               'Error while selecting language id for '
            || v_opted_lang || SUBSTR(SQLERRM, 1, 200);
           
         RAISE EXP_REJECT_RECORD;
   END;

END IF;
      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                NULL,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_INST_CODE,
                NULL,
                NULL,
                NULL,
                NULL,
                P_CURR_CODE,             
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
                NULL,
                '000',
                P_RVSL_CODE,
                '0.00',   --  Added for defect id :0014334 
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
                
                
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
         --P_RESP_CODE := '21';
         --V_ERRMSG :=  V_ERRMSG;
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure      
     
   
    V_RESP_CDE := 1;
  
   --ST Get responce code from master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO V_RESP_CDE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             V_RESP_CDE := '89';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '89'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
        END;
      --En Get responce code fomr master
      
            P_RESP_CODE:=  V_RESP_CDE;    
               --Sn update the alert details in transaction log dtl
        BEGIN
             

            --Added for VMS-5739/FSP-991
           select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
           INTO   v_Retperiod 
           FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
           WHERE  OPERATION_TYPE='ARCHIVE' 
           AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
           v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');  

          IF (v_Retdate>v_Retperiod) THEN                                                                --Added for VMS-5739/FSP-991
           
          
            UPDATE cms_transaction_log_dtl
               SET ctd_mobalert_name = p_alert_name,
                   ctd_mobalert_stat = p_alert_stat,
                   ctd_mobalert_notify = p_notify_type,
                   CTD_MOBILE_NUMBER=P_MOB_NO, ----Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                   CTD_DEVICE_ID=P_DEVICE_ID,   ----Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                   CTD_TXN_AMOUNT=V_TRAN_AMT    --  Added for defect id :0014334 
             WHERE ctd_rrn = p_rrn
               AND ctd_customer_card_no = v_hash_pan
               AND ctd_business_time = p_tran_time
               AND ctd_business_date = p_tran_date
               AND ctd_delivery_channel = p_delivery_channel
               AND ctd_txn_code = p_txn_code
               AND ctd_inst_code = p_inst_code;
			   
		  ELSE
		  
		       UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                                     --Added for VMS-5739/FSP-991
               SET ctd_mobalert_name = p_alert_name,
                   ctd_mobalert_stat = p_alert_stat,
                   ctd_mobalert_notify = p_notify_type,
                   CTD_MOBILE_NUMBER=P_MOB_NO, ----Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                   CTD_DEVICE_ID=P_DEVICE_ID,   ----Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                   CTD_TXN_AMOUNT=V_TRAN_AMT    --  Added for defect id :0014334 
             WHERE ctd_rrn = p_rrn
               AND ctd_customer_card_no = v_hash_pan
               AND ctd_business_time = p_tran_time
               AND ctd_business_date = p_tran_date
               AND ctd_delivery_channel = p_delivery_channel
               AND ctd_txn_code = p_txn_code
               AND ctd_inst_code = p_inst_code;
		  
		  END IF;

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '89';
           V_ERRMSG  := 'Error while updating alert dets in transactionlog_dtl ' ||
                'no valid records ';
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN 
               RAISE EXP_REJECT_RECORD;    
          WHEN OTHERS THEN
           P_RESP_CODE := '89';
           V_ERRMSG  := 'Error while updating alert dets in transactionlog_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
        
     --En update the alert details in transaction log dtl
     
     --St Added by Ramesh.A on 19/09/2012
     if P_IPADDRESS is not null then
      BEGIN
	  
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
	   
	  IF (v_Retdate>v_Retperiod) THEN                                           --Added for VMS-5739/FSP-991
	   
         UPDATE TRANSACTIONLOG
         SET IPADDRESS = P_IPADDRESS
         WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_TRAN_TIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
		 
	  ELSE
	  
	     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                          --Added for VMS-5739/FSP-991
         SET IPADDRESS = P_IPADDRESS
         WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_TRAN_TIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	  
	  
	  END IF;
	  
       EXCEPTION
       WHEN OTHERS THEN
       P_RESP_CODE := '69';
       V_ERRMSG    := 'Problem while inserting data into transaction log ' ||
                 SUBSTR(SQLERRM, 1, 200);
      END;
    end if;
    --End

--Added For JH-18
  If P_Ani Is Not Null And P_Dni Is Not Null Then
    Begin
	
   IF (v_Retdate>v_Retperiod) THEN                                           --Added for VMS-5739/FSP-991
   
      Update Transactionlog 
          Set Ani = P_Ani,
              Dni = P_Dni
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
            Txn_Code = P_Txn_Code And Business_Time = P_Tran_Time And
            Delivery_Channel = P_Delivery_Channel And 
            Msgtype = P_Msg And Instcode = P_Inst_Code;
		
	ELSE
	
	      Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST                         --Added for VMS-5739/FSP-991
          Set Ani = P_Ani,
              Dni = P_Dni
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
            Txn_Code = P_Txn_Code And Business_Time = P_Tran_Time And
            Delivery_Channel = P_Delivery_Channel And 
            Msgtype = P_Msg And Instcode = P_Inst_Code;
	
	
	END IF;
      IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG  := 'ERROR WHILE UPDATING Trasnsaction log ';
        P_RESP_CODE := '21';
        Raise Exp_Reject_Record;
      END IF;
      Exception
        When Exp_Reject_Record Then 
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69';
          V_ERRMSG    := 'Problem while inserting data into transaction log ' ||
              Substr(Sqlerrm, 1, 200);
          RAISE EXP_REJECT_RECORD;
    End;
  End If;
--End for JH-18
    
   P_RESMSG    := V_ALERT_DET;   
   P_AUTH_ID    := V_AUTH_ID;
--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION

WHEN EXP_REJECT_RECORD THEN
ROLLBACK TO V_AUTH_SAVEPOINT;
    
   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 200);
          P_RESP_CODE := '89';
     END;
  --En Get responce code fomr master
  
      --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;      
      

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
          SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
                 ctm_credit_debit_flag
            INTO v_txn_type, v_trans_desc,
                 v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_inst_code; 
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)

  --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                   --  CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC,
                     Response_Id,
                     Time_Stamp, --Added for regading FSS_1144,
                     Ani,  --Added for JH-18
                     Dni,   --Added for JH-18
                     --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     customer_acct_no,
                     productid,
                     categoryid,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance,
                     acct_type
                     --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                    -- V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                     V_TRANS_DESC,
                     v_resp_cde,--P_Resp_Code, --Modified by Pankaj S. for Logging changes(Mantis ID-13160)
                     V_Time_Stamp, --Added for regading FSS_1144
                     P_Ani, --Added for JH-18
                     P_Dni,  --Added for JH-18
                     --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type
                     --En Added by Pankaj S. for Logging changes(Mantis ID-13160) 
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '89';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,             
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_MOBALERT_NAME,
              CTD_MOBALERT_STAT,
              CTD_MOBALERT_NOTIFY,
                    CTD_MOBILE_NUMBER, --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                      CTD_DEVICE_ID,      --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              CTD_HASHKEY_ID    --Added  for regarding Fss-1144 
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',           
              '',
              P_ALERT_NAME,
              P_ALERT_STAT,
              P_NOTIFY_TYPE,
                        P_MOB_NO,    --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              P_DEVICE_ID,  --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
              V_HASHKEY_ID  --Added  for regarding Fss-1144 
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          P_RESP_CODE := '89';
          RETURN;
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
P_RESMSG    := V_ERRMSG;
--Sn Handle OTHERS Execption
WHEN EXP_AUTH_REJECT_RECORD THEN
ROLLBACK;

     --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;      
      

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
          SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
                 ctm_credit_debit_flag
            INTO v_txn_type, v_trans_desc,
                 v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_inst_code; 
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      
--Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                    -- CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     Response_Id,
                     Time_Stamp,  --Added for regarding FSS-1144
                     Ani,  --Added for JH-18
                     Dni,   --Added for JH-18
                     --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     customer_acct_no,
                     productid,
                     categoryid,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance,
                     acct_type
                     --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     --V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARDSTAT ,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     V_TRANS_DESC,
                     P_Resp_Code,
                     V_Time_Stamp,   --Added for regarding FSS-1144
                     P_Ani, --Added for JH-18
                     P_Dni,  --Added for JH-18
                     --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type
                     --En Added by Pankaj S. for Logging changes(Mantis ID-13160)                   
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '89';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
             -- CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,              
              CTD_MOBALERT_NAME,
              CTD_MOBALERT_STAT,
              CTD_MOBALERT_NOTIFY,
                      CTD_MOBILE_NUMBER, --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                      CTD_DEVICE_ID,      --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              CTD_HASHKEY_ID     --Added  by Ravi N for regarding Fss-1144
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',           
              '',
              P_ALERT_NAME,
              P_ALERT_STAT,
              P_NOTIFY_TYPE,
                        P_MOB_NO,    --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              P_DEVICE_ID,  --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
              V_HASHKEY_ID  --Added  by Ravi N for regarding Fss-1144          
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
P_RESMSG    := V_ERRMSG;
 WHEN OTHERS THEN
      V_RESP_CDE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK TO V_AUTH_SAVEPOINT;

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION       
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '89';
     END;
   --En Get responce code fomr master
   
    --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;      
      

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
          SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
                 ctm_credit_debit_flag
            INTO v_txn_type, v_trans_desc,
                 v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_inst_code; 
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)

   --Sn Inserting data in transactionlog
      BEGIN
          INSERT INTO TRANSACTIONLOG(MSGTYPE,
                       RRN,
                       DELIVERY_CHANNEL,
                       DATE_TIME,
                       TXN_CODE,
                       TXN_TYPE,
                       TXN_MODE,
                       TXN_STATUS,
                       RESPONSE_CODE,
                       BUSINESS_DATE,
                       BUSINESS_TIME,
                       CUSTOMER_CARD_NO,
                       INSTCODE,
                       CUSTOMER_CARD_NO_ENCR,
                       --CUSTOMER_ACCT_NO,
                       ERROR_MSG,
                       IPADDRESS,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       TRANS_DESC,
                       Response_Id,
                       Time_Stamp,   --Added for regarding FSS-1144
                       Ani, --Added for JH-18
                       Dni,  --Added for JH-18
                       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                       customer_acct_no,
                       productid,
                       categoryid,
                       cr_dr_flag,
                       acct_balance,
                       ledger_balance,
                       acct_type
                       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
                       )
                VALUES(P_MSG,
                       P_RRN,
                       P_DELIVERY_CHANNEL,
                       SYSDATE,
                       P_TXN_CODE,
                       V_TXN_TYPE,
                       P_TXN_MODE,
                       'F',
                       P_RESP_CODE,
                       P_TRAN_DATE,
                       P_TRAN_TIME,
                       V_HASH_PAN,
                       P_INST_CODE,
                       V_ENCR_PAN_FROM,
                      -- V_SPND_ACCT_NO,
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       V_CARDSTAT,
                      V_TRANS_DESC,
                      P_Resp_Code,
                      V_Time_Stamp,    --Added for regarding FSS-1144
                      P_Ani,  --Added for JH-18
                      P_Dni,   --Added for JH-18
                      --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                      v_acct_number,
                      v_prod_code,
                      v_card_type,
                      v_dr_cr_flag,
                      v_acct_balance,
                      v_ledger_bal,
                      v_acct_type
                      --En Added by Pankaj S. for Logging changes(Mantis ID-13160) 
                       );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '89';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
            RAISE EXP_REJECT_RECORD;
         END;
     --En Inserting data in transactionlog

     --Sn Inserting data in transactionlog dtl
       BEGIN
          INSERT  INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
             -- CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_MOBALERT_NAME,
              CTD_MOBALERT_STAT,
              CTD_MOBALERT_NOTIFY,
                      CTD_MOBILE_NUMBER, --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
                      CTD_DEVICE_ID,      --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              CTD_HASHKEY_ID     --Added  by Ravi N for regarding Fss-1144
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
             'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',           
              '',
              P_ALERT_NAME,
              P_ALERT_STAT,
              P_NOTIFY_TYPE,
                        P_MOB_NO,    --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              P_DEVICE_ID,  --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
              V_HASHKEY_ID  --Added  by Ravi N for regarding Fss-1144    
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '89';
          RETURN;
      END;
      P_RESMSG    := V_ERRMSG;
    --En Inserting data in transactionlog dtl
 End;
 /
 show error
