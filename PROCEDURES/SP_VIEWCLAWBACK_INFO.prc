create or replace
PROCEDURE                      vmscms.SP_VIEWCLAWBACK_INFO (
   p_inst_code            IN       NUMBER,
   p_msg                  IN       VARCHAR2,
   p_rrn                  IN       VARCHAR2,
   p_delivery_channel     IN        VARCHAR2,   
   p_txn_code             IN       VARCHAR2,
   p_txn_mode             IN       VARCHAR2,
   p_tran_date            IN       VARCHAR2,
   p_tran_time            IN       VARCHAR2,
   p_card_no              IN       VARCHAR2,
   p_bank_code            IN       VARCHAR2, 
   p_merchant_name        IN       VARCHAR2,
   p_merchant_city        IN       VARCHAR2,   
   p_curr_code            IN       VARCHAR2, 
   p_resp_code            OUT      VARCHAR2,
   p_resp_msg             OUT      VARCHAR2,
   p_LastChargedDate      OUT      VARCHAR2,
   p_NextChargedDate      OUT      VARCHAR2, 
   p_ClawBackDetails      OUT      CLOB, 
   p_TotalClawBackAmount  OUT      NUMBER, 
   p_dda_number           OUT      VARCHAR2
)
IS
   /****************************************************************************************************
    * Created by       : Ramesh A
    * Created Date     : 04-Apr-14
    * Created reason   : DFCCSD-101 : New API added in MMPOS for VIEW ClawBack Fee Details transaction to retrive monthly fee data and claw back fee details in response.   
    * Reviewer         : Pankaj S
    * Reviewed Date    : 06-April-2014  
    
     * Modified By      : Amudhan S.
     * Modified Date    : 11-Apr-2014
     * Modified Reason  : Review changes DFCCSD-101
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005
     
     * Modified By      : Ramesh
     * Modified Date    : 16-Apr-2014
     * Modified Reason  : Mantis ID : 14237 Date format modified (csl_business_date)in cursor and cap_cafgen_date , cap_next_mb_date
     * Reviewer         : spankaj
     * Reviewed Date    : 18-April-2014
     * Build Number     : RI0027.2_B0006
     
     * Modified By      : Arun
     * Modified Date    : 21-Apr-2014
     * Modified Reason  : Mantis ID : 14318 In View ClawBackFee Details txns the Response for calwback details getting duplicate & amount not proper
     * Reviewer         : spankaj
     * Reviewed Date    : 22-April-2014
     * Build Number     :RI0027.2_B0007
     
     * Modified by     : MageshKumar S.
     * Modified Date   : 25-July-14    
     * Modified For    : FWR-48
     * Modified reason : GL Mapping removal changes
     * Reviewer        : Spankaj
     * Build Number    : RI0027.3.1_B0001
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1	
    *****************************************************************************************************/  
    V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;   --Added for JH-8
    v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
    v_tran_type              VARCHAR2 (2);
    v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;     
    v_tran_amt              NUMBER;
    v_auth_id               transactionlog.auth_id%TYPE;  
    v_tran_date             DATE;
  --  v_func_code             cms_func_mast.cfm_func_code%TYPE; --commented for fwr-48
    v_prod_code             cms_prod_mast.cpm_prod_code%TYPE;
    v_prod_cattype          cms_prod_cattype.cpc_card_type%TYPE;    
    v_txn_type              NUMBER (1); 
    exp_reject_record       EXCEPTION;
    v_hash_pan              cms_appl_pan.cap_pan_code%TYPE;
    v_encr_pan              cms_appl_pan.cap_pan_code_encr%TYPE; 
    v_mini_stat_res         CLOB;
   -- v_acct_number           cms_appl_pan.cap_acct_no%TYPE;
    v_resp_cde              VARCHAR2 (5);  
    v_expry_date            DATE;  
    v_proxunumber           cms_appl_pan.cap_proxy_number%TYPE; 
    v_rrn_count             NUMBER;
    V_CAP_PROD_CATG       VARCHAR2(100);
    V_CAPTURE_DATE    DATE;
    EXP_AUTH_REJECT_TXN  EXCEPTION;
    V_ERR_MSG varchar2(500);
  --  V_MMPOS_USAGEAMNT     CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
 --   V_MMPOS_USAGELIMIT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
    V_BUSINESS_DATE_TRAN  DATE;
    V_ACCT_BALANCE        NUMBER;
    V_LEDGER_BALANCE      NUMBER;
    v_acct_type cms_acct_mast.cam_type_code%type;
    v_timestamp timestamp(3);
    V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
    V_DR_CR_FLAG  VARCHAR2(2);
    v_clawbackdet_det       CLOB;
    v_clawbackdet_val    CLOB;
    v_clawbackamt number;
    V_BASE_CURR          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
    V_CURRCODE        VARCHAR2(3);
    v_clawback_amount   NUMBER;
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
    
   CURSOR c_clawback_details
   is
     select distinct TRIM (TO_CHAR (ccd_clawback_amnt, '99999999999999990.99')),csl_panno_last4digit ||'~'||    --Distinct clause added for mantis id : 14318  
      TO_CHAR (TO_DATE (csl_business_date, 'YYYYMMDD'), 'MM/DD/YYYY') --Date format modified on 16/04/14 Mantis ID : 14237
           ||'~'|| csl_business_time ||'~'|| cdm_channel_desc
           ||'~'|| ctm_tran_desc ||'~'||  cfm_fee_desc
           ||'~'|| cfm_fee_amt ||'~'|| ccd_clawback_amnt
      from cms_acctclawback_dtl,cms_charge_dtl,cms_fee_mast,
      cms_delchannel_mast,cms_transaction_mast,VMSCMS.CMS_STATEMENTS_LOG_VW 	--Added for VMS-5733/FSP-991
      where cad_inst_code=ccd_inst_code
      and cfm_inst_code=ccd_inst_code
      and ccd_inst_code=cdm_inst_code
      and cdm_inst_code=ctm_inst_code
      and ctm_inst_code=csl_inst_code
      and cdm_channel_code=ctm_delivery_channel
      and ctm_delivery_channel=csl_delivery_channel
      and ctm_tran_code=csl_txn_code
      and ctm_tran_code=ccd_txn_code
      and cfm_fee_code=ccd_fee_code
      and ccd_rrn=csl_rrn
      and ccd_pan_code=csl_pan_no
      and cad_acct_no=ccd_acct_no
      and cad_recovery_flag ='N'
      and CCD_CLAWBACK    ='Y'
      AND CCD_FILE_STATUS = 'C'
      and cad_acct_no=p_dda_number
      and cad_inst_code=p_inst_code;
      
BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';  
   p_resp_msg := 'OK';  
    v_err_msg := 'OK';
   v_clawback_amount := 0;
      --SN CREATE HASH PAN
      --Gethash is used to hash the original Pan no
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERR_MSG :=
                    'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      --Fn_Emaps_Main is used for Encrypt the original Pan no
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERR_MSG :=
                    'Error while converting encr pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

     BEGIN      
      SELECT  TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_prfl_flag,           
             ctm_tran_desc    
        INTO  v_txn_type,
             v_tran_type, v_prfl_flag,   
             v_trans_desc     
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code; 
         
     EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '12';                       
         V_ERR_MSG :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';                        
         V_ERR_MSG := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERR_MSG :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;
      --En generate auth id
    
   
      BEGIN
         v_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '32';                    -- Server Declined -220509
            V_ERR_MSG :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En get date


      --Sn find card detail
      BEGIN        
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_proxy_number, cap_acct_no,CAP_PROD_CATG ,
                TO_CHAR (TO_DATE (cap_cafgen_date, 'DD/MM/YYYY'), 'MM/DD/YYYY') , --Date format modified on 16/04/14 Mantis ID : 14237
                TO_CHAR (TO_DATE (cap_next_mb_date, 'DD/MM/YYYY'), 'MM/DD/YYYY') --Date format modified on 16/04/14 Mantis ID : 14237
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                V_CAP_CARD_STAT,v_proxunumber, p_dda_number ,V_CAP_PROD_CATG ,p_LastChargedDate,p_NextChargedDate                
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;     
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            V_ERR_MSG := 'CARD NOT FOUND ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            V_ERR_MSG :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

    --En find card detail

      --Sn Duplicate RRN Check
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
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = p_rrn
            AND  business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
ELSE
		SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = p_rrn
            AND  business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
END IF;			
                                    

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            V_ERR_MSG :=
                  'Duplicate RRN from the Terminal '            
               || ' on '
               || p_tran_date;
            RAISE exp_reject_record;
         END IF;
         EXCEPTION
           WHEN exp_reject_record THEN
           RAISE;   
           WHEN OTHERS THEN
           v_resp_cde := '21';
           V_ERR_MSG   := 'Error while taking count from transactionlog' ||
                  SUBSTR(SQLERRM, 1, 200);
           RAISE exp_reject_record;
      END;
    
      --En Duplicate RRN Check
      
      --Sn commented for fwr-48
      --Sn find function code attached to txn code
   /*   BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_txn_code = p_txn_code
            AND cfm_txn_mode = p_txn_mode
            AND cfm_delivery_channel = p_delivery_channel
            AND cfm_inst_code = p_inst_code;     
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '69';                     
            V_ERR_MSG :=
                      'Function code not defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '69';
            V_ERR_MSG :=
                 'More than one function defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
          WHEN OTHERS THEN
           v_resp_cde := '21';
           V_ERR_MSG   := 'Error while taking function code' ||
                  SUBSTR(SQLERRM, 1, 200);
           RAISE exp_reject_record; 
      END;*/

      --En find function code attached to txn code 
      --En commented for fwr-48
  if p_curr_code is null then
    BEGIN
--       SELECT CIP_PARAM_VALUE
--        INTO V_BASE_CURR
--        FROM CMS_INST_PARAM
--        WHERE CIP_INST_CODE = p_inst_code AND CIP_PARAM_KEY = 'CURRENCY';
     
             SELECT TRIM (cbp_param_value)  
	     INTO v_base_curr FROM cms_bin_param 
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_inst_code
             AND cbp_profile_code =(select  cpc_profile_code from 
             cms_prod_cattype where cpc_prod_code = v_prod_code and 
	        cpc_card_type = v_prod_cattype and cpc_inst_code=p_inst_code);
			 

       IF V_BASE_CURR IS NULL THEN
        v_resp_cde := '21';
        V_ERR_MSG   := 'Base currency cannot be null ';
        RAISE exp_reject_record;
       END IF;
       
       
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        v_resp_cde := '21';
        V_ERR_MSG   := 'Base currency is not defined for the BIN PROFILE ';
        RAISE exp_reject_record;
      WHEN exp_reject_record THEN
      RAISE;   
       WHEN OTHERS THEN
        v_resp_cde := '21';
        V_ERR_MSG   := 'Error while selecting base currency for bin ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;
     
      V_CURRCODE := V_BASE_CURR;
    else
     V_CURRCODE := p_curr_code;
     
    END IF;
     
  
  
  --  IF V_CAP_PROD_CATG = 'P' THEN

    --Sn call to authorize txn
    BEGIN
    
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                          '0200',
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          '0',
                          P_TXN_CODE,
                          0,
                          p_tran_date,
                          p_tran_time,
                          p_card_no,
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
                          '0', -- P_stan
                          '000', --Ins User
                          '00', --INS Date
                          0,
                          v_auth_id,
                          v_resp_cde,
                          V_ERR_MSG,
                          V_CAPTURE_DATE);
     IF v_resp_cde <> '00' AND V_ERR_MSG <> 'OK' THEN   
      
       RAISE EXP_AUTH_REJECT_TXN;
    else
     v_resp_cde:='1';
    
     END IF;
    
    EXCEPTION
     WHEN EXP_AUTH_REJECT_TXN THEN
      RAISE;   
     WHEN OTHERS THEN
       v_resp_cde := '21';
       V_ERR_MSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE exp_reject_record;
    END;
    --En call to authorize txn
  --END IF;
         
       BEGIN
             OPEN c_clawback_details;

             LOOP
                FETCH c_clawback_details
                 INTO v_clawbackamt,v_clawbackdet_val;                            
  
                EXIT WHEN c_clawback_details%NOTFOUND;
                v_clawbackdet_det := v_clawbackdet_det || ' || ' || v_clawbackdet_val;
            
                v_clawback_amount:= v_clawback_amount +  v_clawbackamt;
               
             END LOOP;

             CLOSE c_clawback_details;
          EXCEPTION
             WHEN OTHERS
             THEN
                v_err_msg :='Problem while selecting data from c_clawback_details cursor'|| SUBSTR (SQLERRM, 1, 300);
                v_resp_cde := '21';
                RAISE exp_reject_record;
          END;
   
      if v_clawbackdet_det is null then
      
        p_ClawBackDetails :=' ';
       
      else
        p_ClawBackDetails := SUBSTR(v_clawbackdet_det, 5, LENGTH(v_clawbackdet_det));
        
      end if;
                 
       p_TotalClawBackAmount := v_clawback_amount;
          
      
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERR_MSG :=
                  'Problem while selecting data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
        
    
   EXCEPTION
      --<< MAIN EXCEPTION >>
       WHEN EXP_AUTH_REJECT_TXN THEN
    p_resp_msg    := V_ERR_MSG;
    p_resp_code := v_resp_cde;
      
      WHEN exp_reject_record
      THEN
      
      rollback;      
      
     BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code                      
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type                           
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;   

    --Sn select response code and insert record into txn log dtl
    BEGIN
     p_resp_msg    := V_ERR_MSG;
     P_RESP_CODE := v_resp_cde;
     -- Assign the response code to the out parameter

     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = v_resp_cde;
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg    := 'Problem while selecting data from response master ' ||
                   v_resp_cde || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89';      
    END;
    
              
      if V_DR_CR_FLAG is null
      then
       
          BEGIN
          
            SELECT CTM_CREDIT_DEBIT_FLAG,
                 CTM_TRAN_DESC
             INTO V_DR_CR_FLAG,
                 V_TRANS_DESC
             FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE AND
                 CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                 CTM_INST_CODE = P_INST_CODE;
          EXCEPTION
            WHEN OTHERS THEN
            
            null;

          END;
     
      end if;

      if V_PROD_CODE is null
      then
         
          BEGIN
          
            SELECT CAP_PROD_CODE,
                   CAP_CARD_TYPE,
                   CAP_CARD_STAT,
                   CAP_ACCT_NO
             INTO  V_PROD_CODE,
                   V_PROD_CATTYPE,
                   V_CAP_CARD_STAT,
                   p_dda_number
             FROM CMS_APPL_PAN
            WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
          EXCEPTION
            WHEN OTHERS THEN
            
            null;

          END;
        
      end if; 
      
      v_timestamp := systimestamp;
    
    

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
        ANI,
        DNI,
        CARDSTATUS, 
        TRANS_DESC,       
        acct_type,
        Time_stamp,
        cr_dr_flag,
        error_msg       
        )
     VALUES
       ('0200',
        P_RRN,
        P_DELIVERY_CHANNEL,
        0,
        v_tran_date,
        P_TXN_CODE,
        V_TXN_TYPE,
        0,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRAN_DATE,
        SUBSTR(P_TRAN_TIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INST_CODE,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),   
        p_curr_code,
        NULL,
        V_PROD_CODE,
        v_prod_cattype,--NULL,                     
        0,
        v_auth_id,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),  
        '0.00',                                        
        '0.00',                                       
        P_INST_CODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        '',
        0,
        p_dda_number,
        nvl(V_ACCT_BALANCE,0),
        nvl(V_LEDGER_BALANCE,0),
        v_resp_cde,
        null,
        null,
        V_CAP_CARD_STAT, 
        V_TRANS_DESC,       
        v_acct_type,
        v_timestamp,
        V_DR_CR_FLAG,
        p_resp_msg      
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CODE := '89';
       p_resp_msg    := 'Problem while inserting data into transaction log ' ||
                   SUBSTR(SQLERRM, 1, 300);
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
        CTD_TXN_TYPE)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        '0200',
        0,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        0,
        p_curr_code,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        p_resp_msg,
        P_RRN,
        P_INST_CODE,
        V_ENCR_PAN,
        '',
        V_TXN_TYPE);
    
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; 
       ROLLBACK;
       RETURN;
    END;
   
  WHEN OTHERS THEN
  rollback;
    p_resp_msg := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
   
 END;
/
SHOW ERROR;