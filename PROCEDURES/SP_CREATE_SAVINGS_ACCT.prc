CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_SAVINGS_ACCT ( P_INST_CODE         IN NUMBER ,
                          P_PAN_CODE          IN NUMBER,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN VARCHAR2, --Updated by siva kumar m on 08/06/2012.
                          P_RRN               IN  VARCHAR2,
                          P_ACCT_FLAG         IN  VARCHAR2,
                          P_TXN_MODE          IN   VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_IPADDRESS         IN  VARCHAR2,
                          P_CURR_CODE         IN   VARCHAR2,  --Added by Ramesh.A on 08/03/2012
                          P_RVSL_CODE         IN VARCHAR2,    --Added by Ramesh.A on 08/03/2012
                          P_BANK_CODE         IN  VARCHAR2,   --Added by Ramesh.A on 08/03/2012
                          P_MSG               IN VARCHAR2,    --Added by Ramesh.A on 08/03/2012
                          p_txn_amt           IN  NUMBER,                -- Added by siva kumar on 08/08/2012
                          P_SAVACCT_CONSENT_FLAG IN VARCHAR2, --Added for CR - 40 in release 23.1.1
                          P_SAVINGS_BAL       OUT VARCHAR2,               -- Added by siva kumar on 08/08/2012
                          P_SPENDING_BAL      OUT VARCHAR2,               -- Added by siva kumar on 08/08/2012
                          P_SPENEINGLEG_BAL   OUT VARCHAR2,               -- Added by siva kumar on 08/08/2012
                          P_RESP_CODE         OUT  VARCHAR2 ,
                          P_RESMSG            OUT VARCHAR2,                             
                          p_optin_list        IN  VARCHAR2,
                          P_SPENDINGACCT_NO   OUT VARCHAR2,
                          P_SVAINGSACCT_NO    OUT VARCHAR2,
                          P_GPRCARD_FLAG      IN VARCHAR2 DEFAULT 'N')


AS
/*************************************************
     * Created Date     :  08-Feb-2012     
     * Created By       :  Ramesh
     * PURPOSE          :  Saving account
     * modified by         Saravanakumar
     * modified Date    : 11-Feb-2013
     * modified reason  : For CR - 40 in release 23.1.1
     * Reviewer         : Sachin
     * Reviewed Date    :  13-Feb-2013
     * Build Number     : CMS3.5.1_RI0023.1.1_B0004  
      
     * modified by      :   Dhinakaran B
     * modified Date    :   17-APR-2013
     * modified reason  :   DFCCHW-193 in release 24.1
     * Reviewer         :  Dhiarj
     * Reviewed Date    :    17-Apr-2013
     * Build Number     :  CMS3.5.1_RI0024.1_B0007
     
     * Modified By      : Sagar M.
     * Modified Date    : 17-Apr-2013
     * Modified for     : Defect 10871
     * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) Acct Type,Timestamp ,DR/CR flag and Amount values logging correction 
     * Reviewer         : Dhiraj
     * Reviewed Date    : 17-Apr-2013
     * Build Number     : RI0024.1_B0013  
     
     * Modified by      :  Pankaj S.
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  21-Aug-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  29-Aug-2013
     * Build Number     :  RI0024.4_B0006  
     
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

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal Phase-II changes
     * Modified Date    : 11-Aug-2015
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1          
     
          
     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007
     
      * Modified by       :Spankaj
      * Modified Date    : 06-Jan-16
      * Modified For     : MVHOST-1249
      * Reviewer            : Saravanankumar
      * Build Number     : VMSGPRHOSTCSD3.3     


    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
	 
	 * Modified by       : John G
     * Modified Date     : 14-Feb-2023
     * Modified For      : VMS-7004:  CPRDVMS1 Sequence Alert -SEQ_ACCT_ID    sequence
     * Reviewer          : 
     * Build Number      : VMSGPRHOST R76

*************************************************/
V_SAVING_ACCTNO    cms_appl_pan.cap_acct_no%TYPE;
V_TRAN_DATE        DATE;
V_CARDSTAT         VARCHAR2(5);
V_CARDEXP          DATE;
--V_AUTH_SAVEPOINT   NUMBER DEFAULT 0;
V_COUNT            NUMBER;
V_ACCTID           CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
V_RRN_COUNT        NUMBER;
V_BRANCH_CODE      VARCHAR2(5);
V_ERRMSG           VARCHAR2(500);
V_HASH_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM     CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE         CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_SPND_ACCT_NO      CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_ACCT_TYPE         CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_ACCT_STAT         CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
V_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
V_PROD_CATTYPE      CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;  -- Added by Ramesh.A on 09/032012
V_TXN_TYPE          TRANSACTIONLOG.TXN_TYPE%TYPE;
V_SWITCH_ACCT_TYPE  CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_SWITCH_ACCT_STAT  CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '8';

V_MIN_TRAN_AMT      NUMBER ;--CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
V_SPND_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;

 v_savings_acct_balance   NUMBER;
 v_max_svg_lmt           NUMBER;
 
-- V_SAVINGS_FLAG           NUMBER;   --Changed For DFCCHW-193 on 160413
 v_trans_desc             VARCHAR2 (50);
 v_narration              VARCHAR2 (300);
 v_spd_ledger_balance     NUMBER;
 v_spd_acct_balance       NUMBER;

--St:Added by Ramesh.A on 08/03/2012
V_CARD_EXPRY           VARCHAR2(20);
V_STAN                 VARCHAR2(20);
V_CAPTURE_DATE         DATE;
V_TERM_ID              VARCHAR2(20);
V_MCC_CODE             VARCHAR2(20);
--V_TXN_AMT              NUMBER;  -- ADDED BY SIVA KUMAR M  Changed For DFCCHW-193 on 160413
V_ACCT_NUMBER           NUMBER;
V_AUTH_ID              TRANSACTIONLOG.AUTH_ID%TYPE;

V_DR_CR_FLAG       VARCHAR2(2);
V_OUTPUT_TYPE      VARCHAR2(2);
V_TRAN_TYPE         VARCHAR2(2);
v_min_spend_amt   CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;--Added for CR - 40 in release 23.1.1
v_max_spend_amt   CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;--Added for CR - 40 in release 23.1.1
EXP_AUTH_REJECT_RECORD EXCEPTION;
--End: Added by Ramesh.A on 08/03/2012
V_RESP_CODE   CMS_RESPONSE_MAST.CMS_ISO_RESPCDE%TYPE; --Added For DFCCHW-193 on 160413
EXP_REJECT_RECORD EXCEPTION;
v_timestamp       timestamp;                         -- Added on 18-Apr-2013 for defect 10871
v_applpan_cardstat CMS_APPL_PAN.CAP_CARD_STAT%TYPE;  -- Added on 18-Apr-2013 for defect 10871
v_spending_acct_type  CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE; -- Added on 18-Apr-2013 for defect 10871

--Sn Added by Pankaj S. for DFCCSD-70 changes
v_savings_ledger_balance   cms_acct_mast.cam_ledger_bal%TYPE;
v_svng_acct_type           cms_acct_mast.cam_type_code%TYPE;
--En Added by Pankaj S. for DFCCSD-70 changes
v_dfg_cnt       NUMBER(10); -- v_dfg_cnt added for LYFEHOST-63

v_date_chk      date;       -- Added as per review observation for LYFEHOST-63      


   v_sms_optinflag            cms_optin_status.cos_sms_optinflag%TYPE;
   v_email_optinflag          cms_optin_status.cos_email_optinflag%TYPE;
   v_markmsg_optinflag        cms_optin_status.cos_markmsg_optinflag%TYPE;
   v_gpresign_optinflag       cms_optin_status.cos_gpresign_optinflag%TYPE;
   
   v_optin_type               cms_optin_status.cos_sms_optinflag%TYPE; 
   v_optin                    cms_optin_status.cos_sms_optinflag%TYPE;
   v_optin_list               VARCHAR2(1000); 
   v_comma_pos                NUMBER; 
   v_comma_pos1               NUMBER; 
   i                          NUMBER:=1;
    v_tandc_version            CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
    
   
     v_cust_id                  cms_cust_mast.CCM_CUST_ID%TYPE;
     v_txn_amt                 number;
     
     V_OPTIN_FLAG          VARCHAR2(10) DEFAULT 'N';
	 v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

--Main Begin Block Starts Here
BEGIN
   V_TXN_TYPE := '1';
   --SAVEPOINT V_AUTH_SAVEPOINT ;
   
   
     v_txn_amt := p_txn_amt;

       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting into hash pan ' || SUBSTR(SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE     := '12';
            V_ERRMSG := 'Error while converting into encrypt pan ' || SUBSTR(SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
            RAISE EXP_REJECT_RECORD;
        END;
        
        
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
       P_RESP_CODE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; --Ineligible Transaction
       V_ERRMSG  := 'Error while selecting transaction details' || SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
      
    --En find debit and credit flag
    
    
      --St Get product code from master
          BEGIN
            SELECT CAP_PROD_CODE,CAP_CUST_CODE,CAP_CARD_TYPE,CAP_ACCT_NO,    
                   CAP_CARD_STAT ,CAP_EXPRY_DATE       --CAP_EXPRY_DATE added by Pankaj S. during DFCCSD-70(Review) changes                                        -- Added by siva kumar on 08/08/2012.  
            INTO  V_PROD_CODE , V_CUST_CODE , V_PROD_CATTYPE,V_SPND_ACCT_NO,  
                  V_CARDSTAT, V_CARDEXP --V_APPLPAN_CARDSTAT     --V_CARDSTAT, V_CARDEXP added by Pankaj S. during DFCCSD-70(Review) changes    -- Added by Ramesh.A on 09/032012  
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE=V_HASH_PAN  AND CAP_INST_CODE=P_INST_CODE;
            
            P_SPENDINGACCT_NO:=V_SPND_ACCT_NO;
            
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '21';
                V_ERRMSG := 'Product code,Cust code,Prod cattype Not Found'; -- updated
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG :='Error while getting product code,cust code from master '|| SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;--Added for CR - 40 in release 23.1.1
          END;
        --En Get product code from master


      --St Get product code from master
          BEGIN
            SELECT  CCM_CUST_ID 
            INTO  V_CUST_ID 
            FROM CMS_CUST_MAST
            WHERE CCM_INST_CODE=P_INST_CODE
            AND CCM_CUST_CODE= V_CUST_CODE;
            
                
            EXCEPTION
             
              WHEN OTHERS THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG :='Error while getting CUSTOMER ID from CUST master '|| SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;--Added for CR - 40 in release 23.1.1
          END;
        --En Get product code from master
  

      --SN: Added as per review observation for LYFEHOST-63
        
      Begin  
       
       select to_Date(substr(P_TRAN_DATE,1,8),'yyyymmdd') 
       into v_date_chk 
       from dual;

      exception when others
      then
        P_RESP_CODE := '21';
        V_ERRMSG := 'Invalid transaction date '||P_TRAN_DATE; -- updated
        RAISE EXP_REJECT_RECORD;     
      End;  
        
     --EN: Added as per review observation for LYFEHOST-63      

   --Sn Duplicate RRN Check
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN


      SELECT COUNT(1)
      INTO V_RRN_COUNT
      FROM TRANSACTIONLOG
      WHERE RRN         = P_RRN
      AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;--Added by ramkumar.Mk on 25 march 2012
ELSE
	SELECT COUNT(1)
      INTO V_RRN_COUNT
      FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      WHERE RRN         = P_RRN
      AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;--Added by ramkumar.Mk on 25 march 2012
END IF;
		  

      IF V_RRN_COUNT    > 0 THEN
        P_RESP_CODE     := '22';
        V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
        RAISE EXP_REJECT_RECORD;
      END IF;
    --Sn added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
    EXCEPTION
     WHEN exp_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
      p_resp_code := '21';
      v_errmsg :='Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
      RAISE exp_reject_record;    
   --En added by Pankaj S. during DFCCSD-70(Review) changes to handled exception   
    END;
   --En Duplicate RRN Check

      --Sn Get Tran date
        BEGIN
          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                  'yyyymmdd hh24:mi:ss');
          EXCEPTION
            WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --En Get Tran date
    --Comented for CR - 40 in release 23.1.1
         --Sn Check Delivery Channel
          /*IF P_DELIVERY_CHANNEL NOT IN ('10') THEN
            V_ERRMSG  := 'Not a valid delivery channel  for ' ||
                 ' Savings Account creation';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;*/
        --En Check Delivery Channel
    --Comented for CR - 40 in release 23.1.1
          --Sn Check transaction code
          /*IF P_TXN_CODE NOT IN ('18') THEN
            V_ERRMSG  := 'Not a valid transaction code for ' ||
                 ' Savings account creation';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;*/
        --En check transaction code

     /*   --St Check Saving Account Creation Flag                            commented  P_ACCT_FLAG ,P_SAVACCT_CONSENT_FLAG as part of Savings account changes(FSS-2279)
         IF (LOWER(nvl(trim(P_ACCT_FLAG),'no')) <> 'yes')THEN   -- updated by ramesh on 05/03/12
           P_RESP_CODE     := '64';
           V_ERRMSG := 'Savings Account creation Flag is not enabled';
           RAISE EXP_REJECT_RECORD;
         END IF;
       --En Check Saving Account Creation Flag

       --Sn Added for CR - 40 in release 23.1.1
       --To  allow the consent flag whether Y (or) y on 170413
        IF UPPER(P_SAVACCT_CONSENT_FLAG) <> 'Y' THEN
            P_RESP_CODE := '148';
            V_ERRMSG :='Consent not accepted for the savings account creation';
            RAISE EXP_REJECT_RECORD;
        END IF;
        --En Added for CR - 40 in release 23.1.1   */

        --Sn commented by Pankaj S. during DFCCSD-70(Review) changes
        /*--Sn Get the card details
         BEGIN
              SELECT CAP_CARD_STAT, CAP_EXPRY_DATE
              INTO V_CARDSTAT, V_CARDEXP
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

         EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'Card number not found ' || P_PAN_CODE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
         END;
        --End Get the card details*/
        --En commented by Pankaj S. during DFCCSD-70(Review) changes
       
         --St Get Branch code from pan code
         BEGIN
           SELECT SUBSTR(P_PAN_CODE,7,4) INTO V_BRANCH_CODE FROM DUAL;

            EXCEPTION
              WHEN OTHERS THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG :='Error while getting branch code from pan code '|| SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;
       --En Get Branch code from pan code

        --Sn select acct type
          BEGIN
            SELECT CAT_TYPE_CODE
            INTO V_ACCT_TYPE
            FROM CMS_ACCT_TYPE
            WHERE CAT_INST_CODE = P_INST_CODE AND
            CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               P_RESP_CODE := '21';
               V_ERRMSG := 'Acct type not defined in master';
               RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG := 'Error while selecting accttype ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          END;
        --En select acct type

        --Sn select acct stat
          BEGIN
           SELECT CAS_STAT_CODE
           INTO V_ACCT_STAT
           FROM CMS_ACCT_STAT
           WHERE CAS_INST_CODE = P_INST_CODE AND
           CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STAT;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Acct stat not defined for  master';
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             P_RESP_CODE := '12';
             V_ERRMSG := 'Error while selecting accttype ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;
        --En select acct stat

        --Sn check whether the Saving Account already created or not
         BEGIN
           SELECT COUNT(1) INTO V_COUNT FROM CMS_ACCT_MAST
           WHERE cam_acct_id in( SELECT cca_acct_id FROM CMS_CUST_ACCT
           where cca_cust_code=V_CUST_CODE and cca_inst_code=P_INST_CODE) and cam_type_code=V_ACCT_TYPE
           AND CAM_INST_CODE=P_INST_CODE;

           IF V_COUNT = 1 THEN
           V_ERRMSG := 'Savings Account already created';
           P_RESP_CODE := '63';
           RAISE EXP_REJECT_RECORD;
           END IF;
         --Sn Added for CR - 40 in release 23.1.1
           EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
                  RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             P_RESP_CODE := '12';
             V_ERRMSG := 'Error while selecting Savings Account count ' || SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         --En Added for CR - 40 in release 23.1.1
         END;
      --En check whether the Saving Account already created or not
                                                                                                 
     -- ST   ADDED BY SIVA KUMAR M
    
         --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes 
         /*--Sn Get the DFG paramers         
         BEGIN
                 SELECT  cdp_param_value
                 INTO V_MIN_TRAN_AMT
                 FROM cms_dfg_param
                 WHERE cdp_param_key = 'InitialTransferAmount'
                 AND  cdp_inst_code = p_inst_code;
                                          
                   EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                       P_RESP_CODE := '21';
                       V_ERRMSG := 'No data for selecting min Initial Tran amt  '||P_RESP_CODE;
                       RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG := 'Error while selecting min Initial Tran amt ' ||
                          SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                        
         END;
         
           BEGIN
                  SELECT  cdp_param_value
                  INTO v_max_svg_lmt
                  FROM cms_dfg_param
                  WHERE cdp_param_key = 'MaxSavingParam'
                  AND  cdp_inst_code = p_inst_code;
                                      
                   EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                       P_RESP_CODE := '21';
                       V_ERRMSG := 'No data for selecting max savings acct bal  '||P_RESP_CODE;
                       RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG := 'Error while selecting max Initial Tran amt ' ||
                          SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                     
         END;
  --Sn Added for CR - 40 in release 23.1.1
          BEGIN
                  SELECT  cdp_param_value
                  INTO v_max_spend_amt
                  FROM cms_dfg_param
                  WHERE cdp_param_key = 'MaxSpendingParam'
                  AND  cdp_inst_code = p_inst_code;
                                      
                   EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                       P_RESP_CODE := '21';
                       V_ERRMSG := 'No data for selecting max spending acct bal  ';
                       RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG := 'Error while selecting max spending acct bal ' ||SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                     
         END;

          BEGIN
                  SELECT  cdp_param_value
                  INTO v_min_spend_amt
                  FROM cms_dfg_param
                  WHERE cdp_param_key = 'MinSpendingParam'
                  AND  cdp_inst_code = p_inst_code;
                                      
                   EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                       P_RESP_CODE := '21';
                       V_ERRMSG := 'No data for selecting min spending acct bal  ';
                       RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG := 'Error while selecting min spending acct bal' || SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                     
         END;
     --En Added for CR - 40 in release 23.1.1
     --En Get the DFG paramers*/
     IF P_GPRCARD_FLAG <> 'Y' THEN
     
     v_dfg_cnt:=0; -- added on 04-Oct-2013 for LYFEHOST-63
       FOR i IN (SELECT cdp_param_value, cdp_param_key
                   FROM cms_dfg_param
                  WHERE cdp_param_key IN
                           ('InitialTransferAmount', 'MaxSavingParam',
                            'MaxSpendingParam', 'MinSpendingParam')
                    AND cdp_inst_code = p_inst_code
                    and cdp_prod_code = v_prod_code                 --Added for LYFEHOST-63 
                    and CDP_CARD_TYPE = V_PROD_CATTYPE
                    )
       LOOP
        IF i.cdp_param_key = 'InitialTransferAmount'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_min_tran_amt := i.cdp_param_value;
             
          ELSIF i.cdp_param_key = 'MaxSavingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_max_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_max_spend_amt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MinSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_min_spend_amt := i.cdp_param_value;
          END IF;        
       END LOOP;
     --En Modified by Pankaj S. during DFCCSD-70(Review) changes
     
       --Sn Added on 04-Oct-2013 for LYFEHOST-63
       IF v_dfg_cnt=0 THEN
        p_resp_code := '21';
        v_errmsg:='Saving account parameters is not defined for product '||v_prod_code;
        RAISE exp_reject_record;
       END IF;        
       --En Added on 04-Oct-2013 for LYFEHOST-63
       
     
       if v_min_tran_amt is null                                -- Added during LYFEHOST-63 same was not done
       then
       
            P_RESP_CODE := '21';       
            V_ERRMSG := 'No data for selecting min Initial Tran amt for product code '||v_prod_code ||' and instcode '||p_inst_code||' '||P_RESP_CODE;       
            raise exp_reject_record;       
            
       elsif v_max_svg_lmt is null
       then
                   
            P_RESP_CODE := '21';       
            V_ERRMSG := 'No data for selecting max savings acct bal for product code '||v_prod_code ||' and instcode '||p_inst_code||' '||P_RESP_CODE;    
            raise exp_reject_record;       
       
       elsif v_max_spend_amt is null
       then
       
            P_RESP_CODE := '21';
            V_ERRMSG := 'No data for selecting max spending acct bal for product code '||v_prod_code ||' and instcode '||p_inst_code;
            raise exp_reject_record;       
       
       elsif v_min_spend_amt is null
       then
       
            P_RESP_CODE := '21';       
            V_ERRMSG := 'No data for selecting min spending acct bal for product code '||v_prod_code ||' and instcode '||p_inst_code;      
            raise exp_reject_record;
                   
       end if; 
  
    -- En get the dfg level initial transafer amount  param 
    
     BEGIN
     
      SELECT CAM_ACCT_BAL 
      INTO V_SPND_BAL 
      FROM CMS_ACCT_MAST 
      WHERE CAM_ACCT_NO = V_SPND_ACCT_NO
      AND CAM_INST_CODE=P_INST_CODE;
      
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '21';
       V_ERRMSG := 'No data for selecting spending  acc bal   '||P_RESP_CODE;
       RAISE EXP_REJECT_RECORD;
       WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting spending  acc bal '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
     
     END;

    /* Commented for For DFCCHW-193 on 160413
    --Modified for CR - 40 in release 23.1.1
    IF p_txn_amt >= V_MIN_TRAN_AMT  and  V_SPND_BAL >= p_txn_amt and p_txn_amt <= v_max_svg_lmt
        and p_txn_amt >= v_min_spend_amt and  p_txn_amt <= v_max_spend_amt THEN
        V_TXN_AMT :=  p_txn_amt;
        V_SAVINGS_FLAG := 1;
    ELSE
        V_TXN_AMT := 0;
    END IF;
    
    */
    -- ED   ADDED BY SIVA KUMAR M
  --Commented for CR - 40 in release 23.1.1
   /* IF V_TXN_AMT IS NULL THEN  -- Added by Ramesh.A on 10/08/2012
      V_TXN_AMT := 0;
    END IF;*/
    
  

 --  IF v_min_tran_amt > 0 THEN
   
       
   --      IF v_txn_amt < v_min_tran_amt  THEN
        if v_txn_amt = 0 then 
           v_txn_amt :=v_min_tran_amt;
          
        END IF;
        

    --Changes Started For DFCCHW-193 on 160413
    BEGIN
       IF v_txn_amt < v_min_tran_amt
       THEN
          v_errmsg :=
                    'Transaction amount is less than the Initial Transfer Amount';
          p_resp_code := '151';
          RAISE exp_reject_record;
       ELSIF v_txn_amt < v_min_spend_amt
       THEN
          v_errmsg := 'Amount should not below the Minimum configured amount';
          p_resp_code := '103';
          RAISE exp_reject_record;
       ELSIF v_txn_amt > v_max_spend_amt
       THEN
          v_errmsg := 'Amount should not exceed the Maximum Transfer amount';
          p_resp_code := '150';
          RAISE exp_reject_record;
       ELSIF v_txn_amt > v_max_svg_lmt
       THEN
          v_errmsg :=
                   'Amount should not exceed the Maximum Savings Account Balance';
          p_resp_code := '104';
          RAISE exp_reject_record;
       ELSIF v_txn_amt > v_spnd_bal
       THEN
          v_errmsg := 'Insufficient funds to create savings account';
          p_resp_code := '152';
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record
       THEN
          RAISE;
       WHEN OTHERS
       THEN
          p_resp_code := '12';
          v_errmsg :=
                'Error while Checking the transaction amount matched with the configured values '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    --Changes Ended For DFCCHW-193 on 160413
    
  /* ELSE
  
    v_txn_amt:=0;
   
   END IF;*/
    
  END IF;
-- opt in values.........



     IF p_optin_list IS NOT NULL THEN 
      BEGIN 
         
         LOOP
         
            
            v_comma_pos:= instr(p_optin_list,',',1,i);
      
            IF i=1 AND v_comma_pos=0 THEN
                v_optin_list:=p_optin_list;
            ELSIF i<>1 AND v_comma_pos=0 THEN
                v_comma_pos1:= instr(p_optin_list,',',1,i-1);
                v_optin_list:=substr(p_optin_list,v_comma_pos1+1);
             ELSIF i<>1 AND v_comma_pos<>0 THEN
                v_comma_pos1:= instr(p_optin_list,',',1,i-1);
                v_optin_list:=substr(p_optin_list,v_comma_pos1+1,v_comma_pos-v_comma_pos1-1);
            ELSIF i=1 AND v_comma_pos<>0 THEN
                v_optin_list:=substr(p_optin_list,1,v_comma_pos-1);
            END IF;
            
            i:=i+1;
            
            v_optin_type:=substr(v_optin_list,1,instr(v_optin_list,':',1,1)-1);
            v_optin:=substr(v_optin_list,instr(v_optin_list,':',1,1)+1);
       
          
          BEGIN
             IF v_optin_type IS NOT NULL AND v_optin_type = '1'
             THEN
                v_sms_optinflag := v_optin;
                 V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '2'
             THEN
                v_email_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '3'
             THEN
                v_markmsg_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '4'
             THEN
                v_gpresign_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
              IF v_gpresign_optinflag='1' THEN  --Added for MVHOST-1249
                BEGIN
                
                    SELECT nvl(CPC_TANDC_VERSION,'') 
                   INTO v_tandc_version
                   FROM CMS_PROD_CATTYPE
					WHERE CPC_PROD_CODE=v_prod_code
					AND CPC_CARD_TYPE= V_PROD_CATTYPE
					AND CPC_INST_CODE=p_inst_code;
                
                EXCEPTION 
                WHEN others THEN
                
                  p_resp_code := '21';
                  v_errmsg :='Error from  featching the t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
                
                END;
                
                BEGIN
                
                        UPDATE cms_cust_mast
                        set ccm_tandc_version=v_tandc_version
                        WHERE ccm_cust_code=V_CUST_CODE;
                        
                        IF  SQL%ROWCOUNT =0 THEN
                           p_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                             RAISE exp_reject_record;
                        
                        END IF;
                
                
                EXCEPTION 
                
                 WHEN exp_reject_record THEN
                  RAISE ;
                 WHEN others THEN
                  
                   p_resp_code := '21';
                   v_errmsg :='Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
                END;
              END IF;  
          
                 
           
             --ELSIF v_optin_type IS NOT NULL AND v_optin_type = '5'
              -- THEN
               -- v_savingsesign_optinflag := v_optin;
             END IF;
          END;
          
         IF V_OPTIN_FLAG = 'Y' THEN
              BEGIN
                 SELECT COUNT (*)
                   INTO v_count
                   FROM cms_optin_status
                  WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;

                 IF v_count > 0
                 THEN
                    UPDATE cms_optin_status
                       SET cos_sms_optinflag =
                                              NVL (v_sms_optinflag, cos_sms_optinflag),
                           cos_sms_optintime =
                              NVL (DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                   cos_sms_optintime
                                  ),
                           cos_sms_optouttime =
                              NVL (DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                   cos_sms_optouttime
                                  ),
                           cos_email_optinflag =
                                          NVL (v_email_optinflag, cos_email_optinflag),
                           cos_email_optintime =
                              NVL (DECODE (v_email_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optintime
                                  ),
                           cos_email_optouttime =
                              NVL (DECODE (v_email_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optouttime
                                  ),
                           cos_markmsg_optinflag =
                                      NVL (v_markmsg_optinflag, cos_markmsg_optinflag),
                           cos_markmsg_optintime =
                              NVL (DECODE (v_markmsg_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optintime
                                  ),
                           cos_markmsg_optouttime =
                              NVL (DECODE (v_markmsg_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optouttime
                                  ),
                           cos_gpresign_optinflag =
                                    NVL (v_gpresign_optinflag, cos_gpresign_optinflag),
                           cos_gpresign_optintime =
                              NVL (DECODE (v_gpresign_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optintime
                                  ),
                           cos_gpresign_optouttime =
                              NVL (DECODE (v_gpresign_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optouttime
                                  )
                                  
                     WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;
                 ELSE
                    INSERT INTO cms_optin_status
                                (cos_inst_code, cos_cust_id, cos_sms_optinflag,
                                 cos_sms_optintime,
                                 cos_sms_optouttime,
                                 cos_email_optinflag,
                                 cos_email_optintime,
                                 cos_email_optouttime,
                                 cos_markmsg_optinflag,
                                 cos_markmsg_optintime,
                                 cos_markmsg_optouttime,
                                 cos_gpresign_optinflag,
                                 cos_gpresign_optintime,
                                 cos_gpresign_optouttime                         
                                )
                         VALUES (p_inst_code, v_cust_id, v_sms_optinflag,
                                 DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                 v_email_optinflag,
                                 DECODE (v_email_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (v_email_optinflag, '0', SYSTIMESTAMP, NULL),
                                 v_markmsg_optinflag,
                                 DECODE (v_markmsg_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (v_markmsg_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 v_gpresign_optinflag,
                                 DECODE (v_gpresign_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (v_gpresign_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        )
                                );
                 END IF;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    p_resp_code := '21';
                    v_errmsg  :='ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' || SUBSTR (SQLERRM, 1, 300);
                    RAISE exp_reject_record;
              END;
         END IF;
             
              IF v_comma_pos=0 THEN
                    exit;
                END IF;
         
             
        END LOOP;   
        END;

     END IF;


      --ST :  Added by Ramesh.A on 08/03/2012
      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                V_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                v_txn_amt,--p_txn_amt,--Changed For DFCCHW-193 on 160413
                NULL,
                NULL,
                V_MCC_CODE,
                P_CURR_CODE,
                NULL,
                NULL,
                NULL,
                V_ACCT_NUMBER,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                V_CARD_EXPRY,
                V_STAN,
                '000',
                P_RVSL_CODE,
                v_txn_amt, --p_txn_amt, --Changed For DFCCHW-193 on 160413,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN    --Modified by Ramesh.A on 10/09/2012      
        RAISE EXP_AUTH_REJECT_RECORD;  
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure
    --End :  Added by Ramesh.A on 08/03/2012
      --Sn Get Account Number
        BEGIN

          SP_SAVINGS_ACCOUNT_CONSTRUCT(P_INST_CODE,
                      V_BRANCH_CODE,
                      V_PROD_CODE,
                      V_PROD_CATTYPE,  -- Added by Ramesh.A on 09/032012
                      V_SAVING_ACCTNO,
                      V_ERRMSG);
             IF V_ERRMSG <> 'OK' THEN
             P_RESP_CODE := '12';
             V_ERRMSG := 'Error from create savings acct construct ' || V_ERRMSG;
             RAISE EXP_REJECT_RECORD;
             END IF;
              EXCEPTION
              WHEN EXP_REJECT_RECORD THEN  --Added by Ramesh.A on 08/03/2012
                RAISE EXP_REJECT_RECORD;   --Added by Ramesh.A on 08/03/2012
                WHEN OTHERS THEN
                   P_RESP_CODE := '12';
                   V_ERRMSG :='Error while creating account construct '|| SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

        END;
       --En Get Account Number

      --Sn Get Accout Id
         BEGIN
              SELECT SEQ_ACCT_ID.NEXTVAL
                INTO V_ACCTID
                FROM DUAL;
           EXCEPTION
              WHEN OTHERS  THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG :='Error while getting acctId from master'|| SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
           END;
      --End Get Account Id

      --Sn Inserting Saving Account Number in Acct Mast
        BEGIN
        V_SAVING_ACCTNO := TRIM(V_SAVING_ACCTNO);
        
        P_SVAINGSACCT_NO :=V_SAVING_ACCTNO;

         INSERT INTO CMS_ACCT_MAST(CAM_INST_CODE,
                      CAM_ACCT_ID,
                      CAM_ACCT_NO,
                      CAM_HOLD_COUNT,
                      CAM_CURR_BRAN,
                      CAM_TYPE_CODE,
                      CAM_STAT_CODE,
                      CAM_CURR_LOYL,
                      CAM_UNCLAIMED_LOYL,
                      CAM_INS_DATE,
                      CAM_INS_USER,
                      CAM_LUPD_USER,
                      CAM_ACCT_BAL,
                      CAM_LEDGER_BAL,
                      CAM_ACCPT_DATE,
                      CAM_CREATION_DATE,
                      cam_savacct_consent_flag,--Added for CR - 40 in release 23.1.1
                      cam_acct_crea_tnfr_date,  --Added  for Transactionlog Functional Removal Phase-II changes
                      cam_prod_code,
                      cam_card_type
                      )
              VALUES( P_INST_CODE,
                      V_ACCTID,
                      V_SAVING_ACCTNO,
                      1,
                      V_BRANCH_CODE,
                      V_ACCT_TYPE,
                      V_ACCT_STAT,
                      0,
                      0,
                      SYSDATE,
                      1,
                      1,                     
                  --    V_TXN_AMT,  -- ADDED BY  SIVA KUMAR  M ON 08/08/2012
                      v_txn_amt,--p_txn_amt,--Changed For DFCCHW-193 on 160413
                  --    V_TXN_AMT,  -- ADDED BY  SIVA KUMAR  M ON 08/08/2012
                      v_txn_amt,--p_txn_amt,--Changed For DFCCHW-193 on 160413
                      V_TRAN_DATE,
                      V_TRAN_DATE,
                      UPPER(P_SAVACCT_CONSENT_FLAG), --Added for CR - 40 in release 23.1.1
                      sysdate,  --Added  for Transactionlog Functional Removal Phase-II changes
                      v_prod_code,
                      v_prod_cattype
                      );

          EXCEPTION
          WHEN OTHERS THEN
          P_RESP_CODE := '12';
          V_ERRMSG := 'Exception in Acct mast for inserting Saving Account Number '||SQLCODE||'---'||SQLERRM;
          RAISE EXP_REJECT_RECORD;          
        END;
      --En Inserting Saving Account Number in Acct Mast

      --Sn Inserting Saving Account Id in Cust Acct
        BEGIN

          INSERT INTO CMS_CUST_ACCT(CCA_INST_CODE,
                      CCA_ACCT_ID,
                      CCA_CUST_CODE,
                      CCA_HOLD_POSN,
                      CCA_REL_STAT,
                      CCA_INS_DATE,
                      CCA_INS_USER,
                      CCA_LUPD_USER,
                      CCA_LUPD_DATE)
                VALUES(P_INST_CODE,
                      V_ACCTID,
                      V_CUST_CODE,
                      1,
                      'Y',
                      SYSDATE,
                      1,
                      1,
                      SYSDATE);
                P_RESP_CODE := '1';
                P_RESMSG := V_SAVING_ACCTNO;
                V_ERRMSG := 'Saving Account Created';
            EXCEPTION
            WHEN OTHERS THEN
              P_RESP_CODE := '12';
              V_ERRMSG := 'Exception in Cust Acct mast for inserting  Account Id '||SQLCODE||'---'||SQLERRM;
              RAISE EXP_REJECT_RECORD;

          END;
     --En Inserting Saving Account Id in Cust Acct
    
     --Sn Get Savings Acc Balance
                BEGIN
                      SELECT cam_acct_bal,
                             cam_ledger_bal,cam_type_code  --Added by Pankaj S. for DFCCSD-70 changes
                        INTO v_savings_acct_balance,
                             v_savings_ledger_balance,v_svng_acct_type --Added by Pankaj S. for DFCCSD-70 changes
                        FROM cms_acct_mast
                       WHERE cam_acct_no = V_SAVING_ACCTNO
                       AND cam_inst_code = p_inst_code;
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_resp_code := '12';
                         v_errmsg :=
                               'No data for selecting savings acct balance '
                            || V_SAVING_ACCTNO;
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code := '12';
                         v_errmsg :=
                               'Error while selecting savings acct balance '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;

          --En Get Savings Acc Balance
          
            -- ST ADDED BY SIVA KUMAR M  
                                                                                                       
          --   IF   V_SAVINGS_FLAG = 1 THEN  Changed For DFCCHW-193 on 160413                                                                                                        
                                                                                              
                  ---Sn  Add a record in statements  for TO ACCT (Savings)
                  
                IF v_txn_amt > 0 THEN
                   BEGIN
                      -- Changed For DFCCHW-193 on 160413  
                      /*SELECT ctm_tran_desc    
                        INTO v_trans_desc
                        FROM cms_transaction_mast
                       WHERE ctm_tran_code = p_txn_code
                         AND ctm_delivery_channel = p_delivery_channel
                         AND ctm_inst_code = p_inst_code;*/

                      IF TRIM (v_trans_desc) IS NOT NULL
                      THEN
                         v_narration := v_trans_desc || '/';
                      END IF;

                      IF TRIM (v_auth_id) IS NOT NULL
                      THEN
                         v_narration := v_narration || v_auth_id || '/';
                      END IF;

                      IF TRIM (v_acct_number) IS NOT NULL
                      THEN
                         v_narration := v_narration || v_acct_number || '/';
                      END IF;

                      IF TRIM (p_tran_date) IS NOT NULL
                      THEN
                         v_narration := v_narration || p_tran_date;
                      END IF;
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_resp_code := '21';
                         v_errmsg :=
                               'No records founds while getting narration '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code := '21';
                         v_errmsg :=
                                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;

                   BEGIN
                      v_dr_cr_flag := 'CR';
                      
                      v_timestamp := systimestamp;              -- Added on 18-Apr-2013 for defect 10871

                      INSERT INTO cms_statements_log
                                  (csl_pan_no, csl_acct_no, -- Added by Ramesh.A on 27/03/2012
                                                           csl_opening_bal,
                                   csl_trans_amount, csl_trans_type, csl_trans_date,
                                   csl_closing_balance,
                                   csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                                   csl_auth_id, csl_business_date, csl_business_time,
                                   txn_fee_flag, csl_delivery_channel, csl_inst_code,
                                   csl_txn_code, csl_ins_date, csl_ins_user,
                                   csl_panno_last4digit,
                                   csl_acct_type,               -- Added on 18-Apr-2013 for defect 10871
                                   csl_time_stamp,              -- Added on 18-Apr-2013 for defect 10871
                                   csl_prod_code,csl_card_type                -- Added on 18-Apr-2013 for defect 10871    
                                  )
                           --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                      VALUES      (v_hash_pan, V_SAVING_ACCTNO,
                                                                    -- Added by Ramesh.A on 27/03/2012
                                                                    0,
                                   v_txn_amt,--p_txn_amt, 
                                   'CR', v_tran_date,
                                   v_txn_amt,--p_txn_amt,
                                   v_narration, v_encr_pan_from, p_rrn,
                                   v_auth_id, p_tran_date, p_tran_time,
                                   'N', p_delivery_channel, p_inst_code,
                                   p_txn_code, SYSDATE,1,
                                   (SUBSTR (p_pan_code,
                                            LENGTH (p_pan_code) - 3,
                                            LENGTH (p_pan_code)
                                           )
                                   ),
                                   v_acct_type,                 -- Added on 18-Apr-2013 for defect 10871
                                   v_timestamp,                 -- Added on 18-Apr-2013 for defect 10871
                                   v_prod_code,v_prod_cattype                  -- Added on 18-Apr-2013 for defect 10871    
                                  );
                   --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         p_resp_code := '21';
                         v_errmsg := 'Error creating entry in statement log '|| SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;

                   BEGIN
                      sp_daily_bin_bal (p_pan_code,
                                        v_tran_date,
                                        v_txn_amt,--p_txn_amt,
                                        v_dr_cr_flag,
                                        p_inst_code,
                                        p_bank_code,
                                        v_errmsg
                                       );

                      IF v_errmsg <> 'OK'
                      THEN
                         p_resp_code := '21';
                         v_errmsg := 'Error while executing daily_bin log ';
                         RAISE exp_reject_record;
                      END IF;
                   EXCEPTION
                      WHEN exp_reject_record
                      THEN
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code := '21';
                         v_errmsg := 'Error creating entry in daily_bin log '|| SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;
                END IF;
                   --En  Add a record in statements for TO ACCT(Savings) -----------------
               
          --    END IF;
             
            -- EN ADDED BY SIVA KUMAR M                                                                                                                      
             
                                                                                                          
             --Sn Get Spending Acc Balance
                   BEGIN
                      SELECT cam_acct_bal, cam_ledger_bal
                        INTO v_spd_acct_balance, v_spd_ledger_balance
                        FROM cms_acct_mast
                       WHERE cam_acct_no = V_SPND_ACCT_NO
                        AND cam_inst_code = p_inst_code;
                         
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_resp_code := '12';
                         v_errmsg :=
                                'No data for selecting spending acct balance ' || v_acct_number;
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code := '12';
                         v_errmsg :=
                               'Error while selecting spending acct balance '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END; 
                                                                                                                                
                                                                                                                                            
               P_SAVINGS_BAL      :=  v_savings_acct_balance;
               P_SPENDING_BAL     :=  v_spd_acct_balance;
               P_SPENEINGLEG_BAL  :=  v_spd_ledger_balance ;                                                                                                    
    
       --Sn update topup card number details in translog
        BEGIN
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE TRANSACTIONLOG
          SET  --RESPONSE_ID=P_RESP_CODE,  --Commented by Pankaj S. during DFCCSD-70(Review) changes  
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               TIME_STAMP = v_timestamp,  --Added for defect 10871
               --Sn added by Pankaj S. for DFCCSD-70 changes
               topup_card_no = v_hash_pan,
               topup_card_no_encr = v_encr_pan_from,
               topup_acct_no = v_saving_acctno,
               topup_acct_balance=v_savings_acct_balance,
               topup_ledger_balance=v_savings_ledger_balance,
               topup_acct_type=v_svng_acct_type
               --En added by Pankaj S. for DFCCSD-70 changes              
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
ELSE
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET  --RESPONSE_ID=P_RESP_CODE,  --Commented by Pankaj S. during DFCCSD-70(Review) changes  
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               TIME_STAMP = v_timestamp,  --Added for defect 10871
               --Sn added by Pankaj S. for DFCCSD-70 changes
               topup_card_no = v_hash_pan,
               topup_card_no_encr = v_encr_pan_from,
               topup_acct_no = v_saving_acctno,
               topup_acct_balance=v_savings_acct_balance,
               topup_ledger_balance=v_savings_ledger_balance,
               topup_acct_type=v_svng_acct_type
               --En added by Pankaj S. for DFCCSD-70 changes              
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
END IF;		   

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN --UPDATED
               RAISE EXP_REJECT_RECORD;     -- UPDATED
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update topup card number details in translog
     
     ----------------------------------------------------- 
    --SN:updating latest timestamp value for defect 10871
    -----------------------------------------------------          

        Begin
          --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

          update cms_statements_log
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=P_DELIVERY_CHANNEL
          and   csl_txn_code = P_TXN_CODE
          and   csl_business_date = P_TRAN_DATE
          and   csl_business_time = P_TRAN_TIME;
ELSE
		update VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=P_DELIVERY_CHANNEL
          and   csl_txn_code = P_TXN_CODE
          and   csl_business_date = P_TRAN_DATE
          and   csl_business_time = P_TRAN_TIME;
END IF;		  
          
          --Sn Commented by Pankaj S. during DFCCSD-70(Review) changes
          --if sql%rowcount = 0
          --then 
          --  null;
          --end if;
          --En Commented by Pankaj S. during DFCCSD-70(Review) changes
        
        exception when others
        then
          --Sn added by Pankaj S, during DFCCSD-70(Review) changes
          p_resp_code := '21';
          v_errmsg :=
               'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
          --En added by Pankaj S, during DFCCSD-70(Review) changes
        end;  
          
      ----------------------------------------------------- 
      --EN:updating latest timestamp value for defect 10871
      -----------------------------------------------------   
     
      --ST Get responce code fomr master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO P_RESP_CODE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          RAISE exp_reject_record;  --Added by Pankaj S. during DFCCSD-70(Review) changes
        END;
      --En Get responce code fomr master

    -- TransactionLog & cms_transaction_log_dtl has been removed by ramesh on 12/03/2012

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN EXP_AUTH_REJECT_RECORD THEN
P_RESMSG:=V_ERRMSG; --Added by Besky on 06-nov-12

--Sn Added by Pankaj S. for DFCCSD-70 changes
BEGIN
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
   UPDATE transactionlog
      SET topup_card_no = v_hash_pan,
          topup_card_no_encr = v_encr_pan_from,
          topup_acct_no = v_saving_acctno,
          topup_acct_balance = v_savings_acct_balance,
          topup_ledger_balance = v_savings_ledger_balance,
          topup_acct_type = v_svng_acct_type
    WHERE rrn = p_rrn
      AND delivery_channel = p_delivery_channel
      AND txn_code = p_txn_code
      AND business_date = p_tran_date
      AND business_time = p_tran_time
      AND msgtype = p_msg
      AND customer_card_no = v_hash_pan
      AND instcode = p_inst_code;
ELSE
	UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      SET topup_card_no = v_hash_pan,
          topup_card_no_encr = v_encr_pan_from,
          topup_acct_no = v_saving_acctno,
          topup_acct_balance = v_savings_acct_balance,
          topup_ledger_balance = v_savings_ledger_balance,
          topup_acct_type = v_svng_acct_type
    WHERE rrn = p_rrn
      AND delivery_channel = p_delivery_channel
      AND txn_code = p_txn_code
      AND business_date = p_tran_date
      AND business_time = p_tran_time
      AND msgtype = p_msg
      AND customer_card_no = v_hash_pan
      AND instcode = p_inst_code;
END IF;	  

   IF SQL%ROWCOUNT <> 1 THEN
      p_resp_code := '21';
      p_resmsg := 'Error while updating transactionlog ';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      p_resp_code := '21';
      p_resmsg :='Error while updating transactionlog ' || SUBSTR (SQLERRM, 1, 200);
END;
--En Added by Pankaj S. for DFCCSD-70 changes

--ROLLBACK; Commented by Besky on 06-nov-12
WHEN EXP_REJECT_RECORD THEN
 ROLLBACK;-- TO V_AUTH_SAVEPOINT;
    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
       --INTO P_RESP_CODE
        INTO V_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
      --En Get responce code fomr master
     --Sn Get Spending Acc Balance
    
    IF v_spd_acct_balance IS NULL THEN --Added by Pankaj S. during DFCCSD-70(Review) changes
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal,
              CAM_TYPE_CODE                     -- Added on 18-Apr-2013 for defect 10871
         INTO v_spd_acct_balance, v_spd_ledger_balance,
              v_spending_acct_type             -- Added on 18-Apr-2013 for defect 10871 
         FROM cms_acct_mast
        WHERE cam_acct_no = v_spnd_acct_no AND cam_inst_code = p_inst_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          p_resp_code := '12';
          v_errmsg :=
                   'No data for selecting spending acct balance ' || v_spnd_acct_no;
       WHEN OTHERS
       THEN
          p_resp_code := '12';
          v_errmsg :=
                'Error while selecting spending acct balance '
             || SUBSTR (SQLERRM, 1, 200);
    END;
    END IF;
    
    -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------     
     
     if V_PROD_CODE is null
     then
     
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_CARDSTAT,
                    V_SPND_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;     
     
     end if;
     
     
     if V_DR_CR_FLAG is null
     then
     
        BEGIN
        
             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE 
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
              AND   CTM_INST_CODE = P_INST_CODE;
              
        EXCEPTION
         WHEN OTHERS THEN
         
         NULL;

        END;
        
     end if;
          
     if v_timestamp is null
     then
     
     v_timestamp := systimestamp;              -- Added on 18-Apr-2013 for defect 10871
     
     end if;
     
     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------       
    --Sn Added by Pankaj S. for DFCCSD-70 changes
    IF v_saving_acctno IS NOT NULL THEN
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_savings_acct_balance, v_savings_ledger_balance, v_svng_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_saving_acctno;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
    END IF;
    --En Added by Pankaj S. for DFCCSD-70 changes  
    
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
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC,
                     response_id,
                     ACCT_BALANCE,
                     LEDGER_BALANCE,
                     AMOUNT,
                     AUTH_ID,
                     CURRENCYCODE,
                     BANK_CODE,
                     PRODUCTID,
                     CATEGORYID,
                     ACCT_TYPE,     --Added for defect 10871
                     TIME_STAMP,    --Added for defect 10871
                     CR_DR_FLAG,     --Added for defect 10871
                     --Sn Added by Pankaj S. for DFCCSD-70
                     topup_card_no,
                     topup_card_no_encr,
                     topup_acct_no,
                     topup_acct_balance,
                     topup_ledger_balance,
                     topup_acct_type
                     --En Added by Pankaj S. for DFCCSD-70
                     )
              VALUES(P_MSG, --Added by Ramesh.A on 08/03/2012
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     V_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                    V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                    V_TRANS_DESC ,
                    P_RESP_CODE,
                    v_spd_acct_balance,   
                    v_spd_ledger_balance,
                    --TRIM(TO_CHAR(nvl(p_txn_amt,0), '99999999999999990.99')), --TRIM(TO_CHAR(NVL( Added for defect 10871
                    TRIM(TO_CHAR(nvl(v_txn_amt,0), '99999999999999990.99')),
                    v_auth_id,
                    P_CURR_CODE,
                    P_BANK_CODE,
                    V_PROD_CODE,
                    V_PROD_CATTYPE,
                    v_spending_acct_type,   --Added for defect 10871
                    v_timestamp,            --Added for defect 10871
                    V_DR_CR_FLAG,            --Added for defect 10871
                    --Sn Added by Pankaj S. for DFCCSD-70
                    v_hash_pan,
                    v_encr_pan_from,
                    v_saving_acctno,
                    v_savings_acct_balance,
                    v_savings_ledger_balance,
                    v_svng_acct_type
                    --En Added by Pankaj S. for DFCCSD-70
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '12';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
       -- RAISE;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_TXN_CURR,
              CTD_TXN_AMOUNT
            
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
              P_MSG, --Added by Ramesh.A on 08/03/2012
              '',
              V_SPND_ACCT_NO,
              '',
              P_CURR_CODE,
              v_txn_amt--p_txn_amt
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
         -- RAISE; --Commented by Pankaj S. during DFCCSD-70(Review) changes
        END;
    --En Inserting data in transactionlog dtl
    P_RESP_CODE :=V_RESP_CODE;
    P_RESMSG:=V_ERRMSG;  --Added by Pankaj S. during DFCCSD-70(Review) changes
--En Handle EXP_REJECT_RECORD execption

--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;
   
    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        --INTO P_RESP_CODE
        INTO V_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
   --En Get responce code fomr master
                 --Sn Get Spending Acc Balance
    IF v_spd_acct_balance IS NULL THEN  --Added by Pankaj S. during DFCCSD-70(Review) changes
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal,
              cam_type_code                     -- added on 18-apr-2013 for defect 10871
         INTO v_spd_acct_balance, v_spd_ledger_balance,
              v_spending_acct_type             -- Added on 18-Apr-2013 for defect 10871
         FROM cms_acct_mast
        WHERE cam_acct_no = v_spnd_acct_no AND cam_inst_code = p_inst_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          p_resp_code := '12';
          v_errmsg :=
                   'No data for selecting spending acct balance ' || v_acct_number;
          RAISE exp_reject_record;
       WHEN OTHERS
       THEN
          p_resp_code := '12';
          v_errmsg :=
                'Error while selecting spending acct balance '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    END IF;       
    
    
    -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------     
     
     if V_PROD_CODE is null
     then
     
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_CARDSTAT,
                    V_SPND_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;     
     
     end if;
     
     
     if V_DR_CR_FLAG is null
     then
     
        BEGIN
        
             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE 
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
              AND   CTM_INST_CODE = P_INST_CODE;
              
        EXCEPTION
         WHEN OTHERS THEN
         
         NULL;

        END;
        
     end if;
          
     if v_timestamp is null
     then
     
     v_timestamp := systimestamp;              -- Added on 18-Apr-2013 for defect 10871
     
     end if;
     
     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------        
     
    --Sn Added by Pankaj S. for DFCCSD-70 changes
    IF v_saving_acctno IS NOT NULL THEN
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_savings_acct_balance, v_savings_ledger_balance, v_svng_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_saving_acctno;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
    END IF;
    --En Added by Pankaj S. for DFCCSD-70 changes                 

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
                       CUSTOMER_ACCT_NO,
                       ERROR_MSG,
                       IPADDRESS,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                       TRANS_DESC,
                       response_id,
                       ACCT_BALANCE,
                       LEDGER_BALANCE,
                       AMOUNT,
                       AUTH_ID,
                       CURRENCYCODE,
                       BANK_CODE,
                       PRODUCTID,
                       CATEGORYID,
                       ACCT_TYPE,     --Added for defect 10871
                       TIME_STAMP,    --Added for defect 10871
                       CR_DR_FLAG,     --Added for defect 10871
                       --Sn Added by Pankaj S. for DFCCSD-70
                       topup_card_no,
                       topup_card_no_encr,
                       topup_acct_no,
                       topup_acct_balance,
                       topup_ledger_balance,
                       topup_acct_type
                       --En Added by Pankaj S. for DFCCSD-70                       
                       )
                VALUES(P_MSG, --Added by Ramesh.A on 08/03/2012
                       P_RRN,
                       P_DELIVERY_CHANNEL,
                       SYSDATE,
                       P_TXN_CODE,
                       V_TXN_TYPE,
                       P_TXN_MODE,
                       'F',
                       V_RESP_CODE,
                       P_TRAN_DATE,
                       P_TRAN_TIME,
                       V_HASH_PAN,
                       P_INST_CODE,
                       V_ENCR_PAN_FROM,
                       V_SPND_ACCT_NO,
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                       V_TRANS_DESC,
                       P_RESP_CODE,
                       v_spd_acct_balance,   
                       v_spd_ledger_balance,
                      -- TRIM(TO_CHAR(nvl(p_txn_amt,0), '99999999999999990.99')), --TRIM(TO_CHAR(NVL( Added for defect 10871
                       TRIM(TO_CHAR(nvl(v_txn_amt,0), '99999999999999990.99')), 
                       v_auth_id,
                       P_CURR_CODE,
                       P_BANK_CODE,
                       V_PROD_CODE,
                       V_PROD_CATTYPE,
                       v_spending_acct_type,   --Added for defect 10871
                       v_timestamp,            --Added for defect 10871
                       V_DR_CR_FLAG,            --Added for defect 10871
                       --Sn Added by Pankaj S. for DFCCSD-70
                       v_hash_pan,
                       v_encr_pan_from,
                       v_saving_acctno,
                       v_savings_acct_balance,
                       v_savings_ledger_balance,
                       v_svng_acct_type
                       --En Added by Pankaj S. for DFCCSD-70                                          
                      );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;           
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_TXN_CURR,
              CTD_TXN_AMOUNT
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
              P_MSG, --Added by Ramesh.A on 08/03/2012
              '',
              V_SPND_ACCT_NO,
              '',
              P_CURR_CODE,
              v_txn_amt--p_txn_amt
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';          
      END;
      P_RESP_CODE :=V_RESP_CODE;
      P_RESMSG:=V_ERRMSG;  --Added by Pankaj S. during DFCCSD-70(Review) changes
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption

END;--Main Begin Block Ends Here

/

show error;