CREATE OR REPLACE PROCEDURE VMSCMS.SP_TRAN_REVERSAL_FEES (
p_inst_code             IN NUMBER,
P_CARD_NUMBER           IN VARCHAR2,
P_DEL_CHANNEL           IN VARCHAR2,
P_TRAN_MODE             IN VARCHAR2,    
P_TRAN_CODE             IN VARCHAR2,
P_CURRENCY_CODE         IN VARCHAR2,
P_CONSODIUM_CODE        IN VARCHAR2,
P_PARTNER_CODE          IN VARCHAR2,
P_TRN_AMT               IN NUMBER,
P_TRAN_DATE             IN VARCHAR2,
P_TRAN_TIME             IN VARCHAR2,
P_INTERNATIONAL_IND     IN VARCHAR2,
p_pos_verification      IN VARCHAR2,
p_response_code         IN VARCHAR2,
p_msg_type              IN VARCHAR2,
P_MBR_NUMB              IN VARCHAR2,
P_RRN                   IN VARCHAR2,
P_TERMINAL_ID           IN VARCHAR2,
P_MERCHANT_NAME         IN VARCHAR2,
P_MERCHANT_CITY         IN VARCHAR2,
P_AUTH_ID               IN VARCHAR2,
P_ATMNAME_LOC           IN VARCHAR2,
P_RVSL_CODE             IN NUMBER,
P_NARRATION             IN VARCHAR2,
P_TRAN_TYPE             IN VARCHAR2,
P_TXN_DATE             IN DATE,
P_ERROR                 OUT   VARCHAR2,
P_RESP_CODE             OUT   VARCHAR2,
P_FEE_AMOUNT            OUT   NUMBER,    --position swapped on 07Jan13
P_FEE_PLAN              OUT   VARCHAR2 ,  --position swapped on 07Jan13
P_FEE_CODE              OUT   NUMBER  , --Added on 29.07.2013 for 11695
P_FEEATTACH_TYPE        OUT   VARCHAR2 --Added on 29.07.2013 for 11695
)
AS
 
 EXP_REJECT_RECORD    EXCEPTION;
 V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE; 
 V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  V_FEE_AMT            NUMBER;
  V_FEEAMNT_TYPE          CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES              CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES             CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK              CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN              CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_ACCT_BALANCE          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_LEDGER_BAL            CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_CARD_ACCT_NO          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_NARRATION             VARCHAR2(300);  
  V_ENCR_PAN              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_WAIV_PERCNT      CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV         VARCHAR2(300);
  V_LOG_WAIVER_AMT   NUMBER;
  V_LOG_ACTUAL_FEE   NUMBER;
  V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   v_type_code CMS_ACCT_MAST.CAM_TYPE_CODE%type; --Added for FSS-1586
/*************************************************************************
     * Created By        :  Deepa
     * Created Date      :  26-June-2012
     * Purpose           :  Fees changes
     * Modified By       :  Sagar M
     * Modified Date     :  07-Jan-2013
     * Modified Reason   :  To swap the order of outparameters fee_amount and
                            fee plan  
     * Reviewer          : Dhiraj
     * Reviewed Date     : 07-Jan-2013
     * Build Number      : RI0023_B00011
     
     * Modified by      : Ravi N
     * Modified for     : Mantis ID 0011282
     * Modified Reason  : Correction of Insufficient balance spelling mistake 
     * Modified Date    : 20-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 20-Jun-2013
     * Build Number     : RI0024.2_B0006

    * Modified by      : Sankar S
    * Modified for     : Mantis ID 11326
    * Modified Reason  : To Insert Ledger Balanace For Fee Transaction 
    * Modified Date    : 26-Jun-2013
    * Reviewer         : Sagar M
    * Reviewed Date    : 
    * Build Number     : RI0024.2
    
    * Modified by      : Sachin P.
    * Modified for     : Mantis Id:11695
    * Modified Reason  : Reversal Fee details(FeePlan id,FeeCode,Fee amount 
                         and FeeAttach Type) are not logged in transactionlog 
                         table. 
    * Modified Date    : 29.07.2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 19-aug-2013
    * Build Number     : RI0024.4_B0002 
    
    * Modified By      : MageshKumar S
    * Modified Date    : 28-Jan-2014
    * Modified for     : MVCSD-4471
    * Modified Reason  : Narration change for FEE amount
    * Reviewer         : Dhiraj
    * Reviewed Date    : 28-Jan-2014
    * Build Number     : RI0027.1_B0001
    
    * Modified by       : Ramesh.A
    * Modified for      : FSS-1586
    * Modified Reason   : Logging account type in csl_acct_type
    * Modified Date     : 11-June-2013
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001
	
    * Modified by       : Ramesh.A
    * Modified for      : FWR-48
    * Modified Reason   : GL removal
    * Modified Date     : 21-Aug-2014
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.1_B0005    
    
    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 21-Nov-14    
    * Modified For      : Mantis ID 15715 
    * Modified reason   : Logging csl_prod_code in statments log
    * Reviewer          : spankaj
    * Build Number      : RI0027.4.3_B0005
    
    
        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
 *************************************************************************/
 BEGIN
    p_error := 'OK'    ;       
   

      --SN CREATE HASH PAN 
        BEGIN
                v_hash_pan := Gethash(p_card_number);
            EXCEPTION
            WHEN OTHERS THEN
            p_error := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE    EXP_REJECT_RECORD;
        END;
            --EN CREATE HASH PAN
         BEGIN
         
         V_ENCR_PAN := FN_EMAPS_MAIN(p_card_number);
        EXCEPTION
         WHEN OTHERS THEN
           p_error := 'Error while converting pan ' ||
                     SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;       
        
        BEGIN
    
         SELECT CAP_PROD_CODE, CAP_CARD_TYPE
          INTO V_PROD_CODE, V_PROD_CATTYPE
         FROM CMS_APPL_PAN WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE =P_INST_CODE;
    
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           P_RESP_CODE := '14';
           P_ERROR  := 'CARD NOT FOUND ' || V_HASH_PAN;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           P_RESP_CODE := '21';
           P_ERROR  := 'Problem while selecting card detail' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        
    
        BEGIN
         SP_TRAN_FEES_CMSAUTH(P_INST_CODE,
                          P_CARD_NUMBER,
                          P_DEL_CHANNEL,
                          P_TRAN_TYPE,
                          P_TRAN_MODE,
                          P_TRAN_CODE,
                          P_CURRENCY_CODE,
                          P_CONSODIUM_CODE,
                          P_PARTNER_CODE,
                          P_TRN_AMT,
                          P_TXN_DATE,
                          P_INTERNATIONAL_IND,
                          p_pos_verification,
                          p_response_code,
                          p_msg_type,
                          P_RVSL_CODE,--Added by Deepa on June 26 2012 for Reversal Fees
                          NULL, --P_MCC_CoDe Added by Trivinkram on 05-sep-2012
                          V_FEE_AMT,                                         
                          P_ERROR,
                          V_FEE_CODE,
                          V_FEE_CRGL_CATG,
                          V_FEE_CRGL_CODE,
                          V_FEE_CRSUBGL_CODE,
                          V_FEE_CRACCT_NO,
                          V_FEE_DRGL_CATG,
                          V_FEE_DRGL_CODE,
                          V_FEE_DRSUBGL_CODE,
                          V_FEE_DRACCT_NO,
                          V_ST_CALC_FLAG,
                          V_CESS_CALC_FLAG,
                          V_ST_CRACCT_NO,
                          V_ST_DRACCT_NO,
                          V_CESS_CRACCT_NO,
                          V_CESS_DRACCT_NO,
                          V_FEEAMNT_TYPE,
                          V_CLAWBACK,
                          V_FEE_PLAN,
                          V_PER_FEES, 
                          V_FLAT_FEES,
                          V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                          V_DURATION, -- Added by Trivikram for logging fee of free transaction
                          V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                          V_FEE_DESC --Added for MVCSD-4471
                          );
         P_FEE_AMOUNT:=V_FEE_AMT;
         P_FEE_PLAN:=V_FEE_PLAN;
         P_FEE_CODE := V_FEE_CODE;             --Added on 29.07.2013 for 11695
         P_FEEATTACH_TYPE := V_FEEATTACH_TYPE; --Added on 29.07.2013 for 11695
         
         IF P_ERROR <> 'OK' THEN
               
           RAISE EXP_REJECT_RECORD;
           
         END IF;
        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           
           P_ERROR  := 'Error from decline fee calc process ' ||
                      SUBSTR(SQLERRM, 1, 200);
           P_RESP_CODE:='21';
           RAISE EXP_REJECT_RECORD;
        END;
        
    
    -- Added by Trivikram for calculate waiver in case fee reversal    
        --Sn calculate waiver on the fee
    BEGIN
     SP_CALCULATE_WAIVER(P_INST_CODE,
                     P_CARD_NUMBER,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN, -- Added by Trivikram on 21/aug/2012
                     P_TXN_DATE,--Added Trivikram on Aug-23-2012 to calculate the waiver based on tran date
                     V_WAIV_PERCNT,
                     V_ERR_WAIV);
    
     IF V_ERR_WAIV <> 'OK' THEN
       P_RESP_CODE := '21';
       P_ERROR  := V_ERR_WAIV;
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       P_ERROR  := 'Error from waiver calc process ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
  
    --En calculate waiver on the fee
  
    --Sn apply waiver on fee amount
    V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
    V_FEE_AMT        := ROUND(V_FEE_AMT -
                        ((V_FEE_AMT * V_WAIV_PERCNT) / 100),
                        2);
    V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;
  
    --only used to log in log table
  
    --En apply waiver on fee amount
    
           BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,CAM_TYPE_CODE  --Added for FSS-1586
           INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,v_type_code  --Added for FSS-1586
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =
               (SELECT CAP_ACCT_NO
                 FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN
                     AND CAP_MBR_NUMB = P_MBR_NUMB AND
                     CAP_INST_CODE = P_INST_CODE) AND
               CAM_INST_CODE = P_INST_CODE
            FOR UPDATE NOWAIT;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
          P_RESP_CODE:='21';
           P_ERROR  := 'Invalid Card ';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           P_RESP_CODE:='21';
           P_ERROR  := 'Error while selecting data from card Master for card number ' ||
                      SQLERRM;
           RAISE EXP_REJECT_RECORD;
        END;
        
        
    
    BEGIN
    
    IF  V_FEE_AMT > 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
    
        IF V_ACCT_BALANCE < V_FEE_AMT  AND p_msg_type NOT IN ('9220','9221','1220','1221') THEN
    
             P_RESP_CODE := '15';
             P_ERROR  := 'Insufficient Balance ' ; -- modified by Ravi N for Mantis ID 0011282
             RAISE EXP_REJECT_RECORD;
          
    
        END IF;
    
    
    	  --Commened for GL not required for FWR-48
          /*IF TRIM(V_FEE_CRACCT_NO) IS NULL AND TRIM(V_FEE_DRACCT_NO) IS NULL THEN
           
           P_ERROR  := 'Both credit and debit account cannot be null for a fee ' ||
                        V_FEE_CODE ;
           P_RESP_CODE := '21';
           RAISE EXP_REJECT_RECORD;
         END IF;

         IF TRIM(V_FEE_CRACCT_NO) IS NULL THEN
           V_FEE_CRACCT_NO := V_CARD_ACCT_NO;
         END IF;*/

         IF TRIM(V_FEE_DRACCT_NO) IS NULL THEN
           V_FEE_DRACCT_NO := V_CARD_ACCT_NO;
         END IF;

	--Commened for GL not required for FWR-48
        /* IF TRIM(V_FEE_CRACCT_NO) = TRIM(V_FEE_DRACCT_NO) THEN
         
           P_RESP_CODE := '21';
           P_ERROR  := 'Both debit and credit fee account cannot be same';
           RAISE EXP_REJECT_RECORD;
         END IF;*/

      IF V_FEE_DRACCT_NO = V_CARD_ACCT_NO THEN
           --SN DEBIT THE  CONCERN FEE  ACCOUNT
           BEGIN

              UPDATE CMS_ACCT_MAST
                SET CAM_ACCT_BAL   = CAM_ACCT_BAL - V_FEE_AMT,
                    CAM_LEDGER_BAL = CAM_LEDGER_BAL - V_FEE_AMT
               WHERE CAM_INST_CODE = P_INST_CODE AND
                    CAM_ACCT_NO = V_FEE_DRACCT_NO;


            IF SQL%ROWCOUNT = 0 THEN
              
              P_ERROR  := 'Problem while updating the FEE ';
              P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
            END IF;
            
            EXCEPTION
            WHEN OTHERS THEN
              
              P_ERROR  := 'Error while updating CMS_ACCT_MAST1 ' ||SUBSTR(SQLERRM,1,200);
                          
              RETURN;
           END;
           
           -- Added by Trivikram on 27-July-2012 for logging complementary transaction
     IF V_FREETXN_EXCEED = 'N' THEN
        BEGIN
     
            INSERT INTO CMS_STATEMENTS_LOG
              (CSL_PAN_NO,
               CSL_OPENING_BAL,
               CSL_TRANS_AMOUNT,
               CSL_TRANS_TYPE,
               CSL_TRANS_DATE,
               CSL_CLOSING_BALANCE,
               CSL_TRANS_NARRRATION,
               CSL_INST_CODE,
               CSL_PAN_NO_ENCR,
               CSL_RRN,
               CSL_AUTH_ID,
               CSL_BUSINESS_DATE,
               CSL_BUSINESS_TIME,
               TXN_FEE_FLAG,
               CSL_DELIVERY_CHANNEL,
               CSL_TXN_CODE,
               CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
               CSL_INS_USER,
               CSL_INS_DATE,
               CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
               CSL_MERCHANT_CITY,
               CSL_MERCHANT_STATE,
               CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               CSL_ACCT_TYPE,csl_prod_code,csl_card_type,csl_time_stamp) --Added for FSS-1586 --Added for 15715 
            VALUES
              (V_HASH_PAN,
               V_LEDGER_BAL,        --Modified by Sankar S  for Mantis ID 11326
               V_FEE_AMT,
               'DR',
               P_TXN_DATE,
               V_LEDGER_BAL - V_FEE_AMT,        --Modified by Sankar S  for Mantis ID 11326
              -- 'Complimentary ' || V_DURATION ||' '|| V_NARRATION, --Commented for MVCSD-4471
               V_FEE_DESC, --Added for MVCSD-4471
               P_INST_CODE,
               V_ENCR_PAN,
               P_RRN,
               P_AUTH_ID,
               P_TRAN_DATE,
               P_TRAN_TIME,
               'Y',
               P_DEL_CHANNEL,
               P_TRAN_CODE,
               V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
               1,
               SYSDATE,
               P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
               P_MERCHANT_CITY,
               P_ATMNAME_LOC,
               (SUBSTR(P_CARD_NUMBER, length(P_CARD_NUMBER) - 3, length(P_CARD_NUMBER))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               v_type_code,v_prod_code,V_PROD_CATTYPE,systimestamp); --Added for FSS-1586 --Added for 15715 
           EXCEPTION
            WHEN OTHERS THEN
              P_RESP_CODE := '21';
              P_ERROR  := 'Problem while inserting into statement log for tran fee ' ||
                         SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
         END; 
      
     ELSE 
     
                       
            BEGIN
            
                 IF V_FEEAMNT_TYPE='A' THEN
                 
                 V_FLAT_FEES := ROUND(V_FLAT_FEES -
                            ((V_FLAT_FEES * V_WAIV_PERCNT) / 100),2);
                        
                        
                 V_PER_FEES  := ROUND(V_PER_FEES -
                        ((V_PER_FEES * V_WAIV_PERCNT) / 100),2);
        
             --Sn Entry for Fixed Fee
             INSERT INTO CMS_STATEMENTS_LOG
                (CSL_PAN_NO,
                 CSL_OPENING_BAL,
                 CSL_TRANS_AMOUNT,
                 CSL_TRANS_TYPE,
                 CSL_TRANS_DATE,
                 CSL_CLOSING_BALANCE,
                 CSL_TRANS_NARRRATION,
                 CSL_INST_CODE,
                 CSL_PAN_NO_ENCR,
                 CSL_RRN,
                 CSL_AUTH_ID,
                 CSL_BUSINESS_DATE,
                 CSL_BUSINESS_TIME,
                 TXN_FEE_FLAG,
                 CSL_DELIVERY_CHANNEL,
                 CSL_TXN_CODE,
                 CSL_ACCT_NO,
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 CSL_ACCT_TYPE,csl_prod_code,csl_card_type,csl_time_stamp) --Added for FSS-1586 --Added for 15715 
               VALUES
                (                     
                 V_HASH_PAN,
                 V_LEDGER_BAL,        --Modified by Sankar S  for Mantis ID 11326
                 V_FLAT_FEES,
                 'DR',
                 P_TXN_DATE,
                 V_LEDGER_BAL - V_FLAT_FEES,        --Modified by Sankar S  for Mantis ID 11326
                -- 'Fixed Fee debited for RVSL of ' || P_NARRATION, --Commented for MVCSD-4471
                 'Fixed Fee debited for RVSL of ' || V_FEE_DESC, --Added for MVCSD-4471
                 P_INST_CODE,
                 V_ENCR_PAN,
                 P_RRN,
                 P_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DEL_CHANNEL,
                 P_TRAN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (SUBSTR(P_CARD_NUMBER, length(P_CARD_NUMBER) -3,length(P_CARD_NUMBER))),
                 v_type_code,v_prod_code,V_PROD_CATTYPE,systimestamp); --Added for FSS-1586 --Added for 15715 
                 --En Entry for Fixed Fee
                 
                 V_ACCT_BALANCE:=V_ACCT_BALANCE - V_FLAT_FEES;
                 --Sn Entry for Percentage Fee
                 INSERT INTO CMS_STATEMENTS_LOG
                (CSL_PAN_NO,
                 CSL_OPENING_BAL,
                 CSL_TRANS_AMOUNT,
                 CSL_TRANS_TYPE,
                 CSL_TRANS_DATE,
                 CSL_CLOSING_BALANCE,
                 CSL_TRANS_NARRRATION,
                 CSL_INST_CODE,
                 CSL_PAN_NO_ENCR,
                 CSL_RRN,
                 CSL_AUTH_ID,
                 CSL_BUSINESS_DATE,
                 CSL_BUSINESS_TIME,
                 TXN_FEE_FLAG,
                 CSL_DELIVERY_CHANNEL,
                 CSL_TXN_CODE,
                 CSL_ACCT_NO,
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 CSL_ACCT_TYPE,csl_prod_code,csl_card_type,csl_time_stamp) --Added for FSS-1586 --Added for 15715 
               VALUES
                (
                 V_HASH_PAN,
                 V_LEDGER_BAL,        --Modified by Sankar S  for Mantis ID 11326
                 V_PER_FEES,
                 'DR',
                 P_TXN_DATE,
                 V_LEDGER_BAL - V_PER_FEES,        --Modified by Sankar S  for Mantis ID 11326
                -- 'Percetage Fee debited for RVSL of ' || P_NARRATION, --Commented for MVCSD-4471
                'Percentage Fee debited for RVSL of ' || V_FEE_DESC, --Added for MVCSD-4471
                 P_INST_CODE,
                 V_ENCR_PAN,
                 P_RRN,
                 P_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DEL_CHANNEL,
                 P_TRAN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (SUBSTR(P_CARD_NUMBER, length(P_CARD_NUMBER) -3,length(P_CARD_NUMBER))),
                 v_type_code,v_prod_code,V_PROD_CATTYPE,systimestamp); --Added for FSS-1586 --Added for 15715 
                 
                 --En Entry for Percentage Fee
            
        ELSE
         --Sn create entries for FEES attached
         
             BEGIN
               INSERT INTO CMS_STATEMENTS_LOG
                (CSL_PAN_NO,
                 CSL_OPENING_BAL,
                 CSL_TRANS_AMOUNT,
                 CSL_TRANS_TYPE,
                 CSL_TRANS_DATE,
                 CSL_CLOSING_BALANCE,
                 CSL_TRANS_NARRRATION,
                 CSL_INST_CODE,
                 CSL_PAN_NO_ENCR,
                 CSL_RRN,
                 CSL_AUTH_ID,
                 CSL_BUSINESS_DATE,
                 CSL_BUSINESS_TIME,
                 TXN_FEE_FLAG,
                 CSL_DELIVERY_CHANNEL,
                 CSL_TXN_CODE,
                 CSL_ACCT_NO,
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 CSL_ACCT_TYPE,csl_prod_code,csl_card_type,csl_time_stamp) --Added for FSS-1586 --Added for 15715 
               VALUES
                (
                 V_HASH_PAN,
                 V_LEDGER_BAL,        --Modified by Sankar S  for Mantis ID 11326
                 V_FEE_AMT,
                 'DR',
                 P_TXN_DATE,
                 V_LEDGER_BAL - V_FEE_AMT,        --Modified by Sankar S  for Mantis ID 11326
                -- 'Fee debited for RVSL of ' || P_NARRATION, --Commented for MVCSD-4471
                 V_FEE_DESC, --Added for MVCSD-4471
                 P_INST_CODE,
                 V_ENCR_PAN,
                 P_RRN,
                 P_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DEL_CHANNEL,
                 P_TRAN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (SUBSTR(P_CARD_NUMBER, length(P_CARD_NUMBER) -3,length(P_CARD_NUMBER))),
                 v_type_code,v_prod_code,V_PROD_CATTYPE,systimestamp); --Added for FSS-1586 --Added for 15715 
             EXCEPTION
               WHEN OTHERS THEN
                P_RESP_CODE := '21';
                P_ERROR  := 'Problem while inserting into statement log for tran fee ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;
         END IF;
     
            END ;
            
       end if;
    
       --Sn insert a record into EODUPDATE_ACCT
       --Commened for GL not required for FWR-48
       /*BEGIN
        SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                P_TERMINAL_ID,
                                P_DEL_CHANNEL,
                                P_TRAN_CODE,
                                P_TRAN_MODE,
                                P_TXN_DATE,
                                V_CARD_ACCT_NO,
                                V_FEE_CRACCT_NO,
                                V_FEE_AMT,
                                'C',
                                P_INST_CODE,
                                P_ERROR);

        IF P_ERROR <> 'OK' THEN
          
          RAISE EXP_REJECT_RECORD;
        END IF;
        EXCEPTION
        WHEN OTHERS THEN
          P_RESP_CODE := '21';
          P_ERROR  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH3 ' ||SUBSTR(SQLERRM,1,200);
                      
          RAISE EXP_REJECT_RECORD;
       END;*/
       --En insert a record into EODUPDATE_ACCT
     END IF;
    
    END IF;
    
    END ;    
 P_RESP_CODE:='1';
  
EXCEPTION WHEN
    EXP_REJECT_RECORD THEN     
    RETURN;
    WHEN OTHERS THEN
     P_ERROR  := 'Error from main others'|| P_ERROR ||SUBSTR(SQLERRM,1,200);
    RETURN;   
END ;

/

show error