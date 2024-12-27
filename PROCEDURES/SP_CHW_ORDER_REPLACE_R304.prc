create or replace PROCEDURE        vmscms.SP_CHW_ORDER_REPLACE_R304(
                                        P_INST_CODE        IN NUMBER,
                                        P_MSG              IN VARCHAR2,
                                        P_RRN              IN VARCHAR2,
                                        P_DELIVERY_CHANNEL IN VARCHAR2,
                                        P_TERM_ID          IN VARCHAR2,
                                        P_TXN_CODE         IN VARCHAR2,
                                        P_TXN_MODE         IN VARCHAR2,
                                        P_TRAN_DATE        IN VARCHAR2,
                                        P_TRAN_TIME        IN VARCHAR2,
                                        P_CARD_NO          IN VARCHAR2,
                                        P_BANK_CODE        IN VARCHAR2,
                                        P_TXN_AMT          In NUMBER,
                                        P_MCC_CODE         IN VARCHAR2,
                                        P_CURR_CODE        IN VARCHAR2,
                                        P_PROD_ID          IN VARCHAR2,
                                        P_EXPRY_DATE       IN VARCHAR2,
                                        P_STAN             IN VARCHAR2,
                                        P_MBR_NUMB         IN VARCHAR2,
                                        P_RVSL_CODE        IN NUMBER,
                                        P_IPADDRESS        IN VARCHAR2,
                                        P_AUTH_ID          OUT VARCHAR2,
                                        P_RESP_CODE        OUT VARCHAR2,
                                        P_RESP_MSG         OUT VARCHAR2,
                                        P_CAPTURE_DATE     OUT DATE,
                                        P_FEE_FLAG         IN  VARCHAR2 DEFAULT 'Y' 
                                                                                       
                                        ) IS

  /*****************************************************************************
   * modified by          : Saravanakumar
   * modified Date        : 23-Jun-2015
   * Modified For         : Update activity 30.4 
   * Reviewer             : Pankaj Salunkhe
   * Reviewed Date        :23-Jun-2015
   ******************************************************************************/
  V_ACCT_BALANCE     NUMBER;
  V_LEDGER_BAL       NUMBER;
  V_TRAN_AMT         NUMBER;
  V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT        NUMBER;
  V_TRAN_DATE        DATE;
  V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_RESP_CDE         VARCHAR2(5);
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ERR_MSG          VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  V_CARD_CURR          VARCHAR2(5);
  V_BUSINESS_DATE   DATE;
  V_TXN_TYPE        NUMBER(1);
  EXP_REJECT_RECORD EXCEPTION;
  V_CARD_ACCT_NO             VARCHAR2(20);
  V_HOLD_AMOUNT              NUMBER;
  V_HASH_PAN                 CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                 CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT                NUMBER;
  V_TRAN_TYPE                VARCHAR2(2);
  V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CAP_CARD_STAT            VARCHAR2(10);
  CRDSTAT_CNT                VARCHAR2(10);
  V_CRO_OLDCARD_REISSUE_STAT VARCHAR2(10);
  V_MBRNUMB                  VARCHAR2(10);
  NEW_DISPNAME               VARCHAR2(50);
  NEW_CARD_NO                VARCHAR2(100);
  V_CAP_PROD_CATG            VARCHAR2(100);
  V_CUST_CODE                VARCHAR2(100);
  P_REMRK                    VARCHAR2(100);
  V_RESONCODE                CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  v_dup_check                  NUMBER (3); 
  v_cam_lupd_date              cms_addr_mast.cam_lupd_date%TYPE;
  V_NEW_HASH_PAN               CMS_APPL_PAN.CAP_PAN_CODE%TYPE; 
  V_APPL_CODE                  CMS_APPL_PAN.CAP_APPL_CODE%TYPE; 
  v_cam_type_code   cms_acct_mast.cam_type_code%type; 
  v_timestamp       timestamp;                         
  v_card_type       cms_prod_cattype.cpc_card_type%type;
  
  
BEGIN
  V_RESP_CDE := '1';
  V_ERR_MSG  := 'OK';
  P_RESP_MSG := 'OK';
  P_REMRK    := 'Online Order Replacement Card';
  
  
  
  BEGIN
        --SN CREATE HASH PAN
        --Gethash is used to hash the original Pan no
        BEGIN
         V_HASH_PAN := GETHASH(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into hash value ' ||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
      
        --EN CREATE HASH PAN
      
        --SN create encr pan
        --Fn_Emaps_Main is used for Encrypt the original Pan no
        BEGIN
         V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into encrypted value '||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
      
        --EN create encr pan  
         
        BEGIN
         SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE,
                CAP_APPL_CODE ,CAP_DISP_NAME,cap_prod_code,cap_card_type
           INTO V_CAP_PROD_CATG, V_CAP_CARD_STAT, V_ACCT_NUMBER, V_CUST_CODE,
                V_APPL_CODE ,NEW_DISPNAME,V_PROD_CODE,V_PROD_CATTYPE
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        
        BEGIN
         V_BUSINESS_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                            'yyyymmdd hh24:mi:ss');
        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '32'; 
           V_ERR_MSG  := 'Problem while converting transaction date time ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        
    
        --Sn find debit and credit flag
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG,
               CTM_OUTPUT_TYPE,
               TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
               CTM_TRAN_TYPE
           INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '12'; 
           V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                      ' and delivery channel ' || P_DELIVERY_CHANNEL;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21'; --Ineligible Transaction
           V_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
        END;
      
        --En find debit and credit flag  
       --Sn Added by Pankaj S. on 12-Feb-2013 for Duplicate card Replacement check (FSS-391)
      BEGIN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_inst_code
            AND chr_pan_code = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF v_dup_check > 0
         THEN
            v_resp_cde := '159';
            v_err_msg := 'Card already Replaced';
            RAISE exp_reject_record;
         END IF;
      END;

        
               
        --Sn added for card replacement changes(Fss-391)
    IF P_DELIVERY_CHANNEL <>'03' THEN
        BEGIN
          SELECT CAM_LUPD_DATE
          INTO V_CAM_LUPD_DATE
          FROM CMS_ADDR_MAST
          WHERE CAM_INST_CODE=P_INST_CODE
          AND CAM_CUST_CODE=V_CUST_CODE
          AND CAM_ADDR_FLAG='P';
          
          IF v_cam_lupd_date > sysdate-1 THEN
            V_ERR_MSG  := 'Card replacement is not allowed to customer who changed address in last 24 hr';
           V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
             END IF;
          
        EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting customer address details' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
    END IF;
        --En added for card replacement changes(Fss-391)   

  
  
    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (P_MSG = '0100')) THEN
     IF (P_TXN_AMT >= 0) THEN
       V_TRAN_AMT := P_TXN_AMT;
     
       BEGIN
        SP_CONVERT_CURR(P_INST_CODE,
                     P_CURR_CODE,
                     P_CARD_NO,
                     P_TXN_AMT,
                     V_TRAN_DATE,
                     V_TRAN_AMT,
                     V_CARD_CURR,
                     V_ERR_MSG,
                     V_PROD_CODE,
                     V_PROD_CATTYPE);
       
        IF V_ERR_MSG <> 'OK' THEN
          V_RESP_CDE := '44';
          RAISE EXP_REJECT_RECORD;
        END IF;
       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESP_CDE := '69'; 
          V_ERR_MSG  := 'Error from currency conversion ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;
     ELSE
       V_RESP_CDE := '43';
       V_ERR_MSG  := 'INVALID AMOUNT';
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;
  
       
          BEGIN                                  
             sp_authorize_txn_cms_auth (P_INST_CODE,
                                        P_MSG,
                                        P_RRN,
                                        P_DELIVERY_CHANNEL,
                                        P_TERM_ID,                          
                                        P_TXN_CODE,
                                        P_TXN_MODE,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        P_CARD_NO,
                                        P_INST_CODE,
                                        P_TXN_AMT,                           
                                        NULL,                     
                                        NULL,                      
                                        P_MCC_CODE,                        
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
                                        P_EXPRY_DATE,                     
                                        P_STAN,
                                        P_MBR_NUMB,
                                        P_RVSL_CODE,
                                        P_TXN_AMT,                
                                        P_AUTH_ID,
                                        V_RESP_CDE,
                                        V_ERR_MSG,
                                        P_CAPTURE_DATE,
                                        P_FEE_FLAG
                                       );
                                       
             IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
             THEN
                 
                P_RESP_CODE := V_RESP_CDE; 
                
                P_RESP_MSG := 'Error from auth process' || V_ERR_MSG;
                
                return;
             END IF;
             
          EXCEPTION WHEN OTHERS
             THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                      'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
          END;
        
       
        BEGIN
         SELECT COUNT(*)
           INTO CRDSTAT_CNT
           FROM CMS_REISSUE_VALIDSTAT
          WHERE CRV_INST_CODE = P_INST_CODE AND
               CRV_VALID_CRDSTAT = V_CAP_CARD_STAT AND CRV_PROD_CATG IN ('P');
         IF CRDSTAT_CNT = 0 THEN
           V_ERR_MSG  := 'Not a valid card status. Card cannot be reissued';
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;
                        
        END;
        
        BEGIN
         SELECT CRO_OLDCARD_REISSUE_STAT
           INTO V_CRO_OLDCARD_REISSUE_STAT
           FROM CMS_REISSUE_OLDCARDSTAT
          WHERE CRO_INST_CODE = P_INST_CODE AND
               CRO_OLDCARD_STAT = V_CAP_CARD_STAT AND CRO_SPPRT_KEY = 'R';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Default old card status nor defined for institution ' ||
                      P_INST_CODE;
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while getting default old card status for institution ' ||
                      P_INST_CODE;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        
        BEGIN
          UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT = V_CRO_OLDCARD_REISSUE_STAT,
               CAP_LUPD_USER = P_BANK_CODE
          WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
         IF SQL%ROWCOUNT != 1 THEN
           V_ERR_MSG  := 'Problem in updation of status for pan ' ||
                      V_HASH_PAN;
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while updating CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        --Sn find member number
        
        IF V_CRO_OLDCARD_REISSUE_STAT='9' THEN
        BEGIN
           sp_log_cardstat_chnge (p_inst_code,
                                  v_hash_pan,
                                  v_encr_pan,
                                  p_auth_id,
                                  '02',
                                  p_rrn,
                                  p_tran_date,
                                  p_tran_time,
                                  v_resp_cde,
                                  v_err_msg
                                 );

           IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_resp_cde := '21';
              v_err_msg :=
                    'Error while logging system initiated card status change '
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
          END IF;    
        
        BEGIN
         SELECT CIP_PARAM_VALUE
           INTO V_MBRNUMB
           FROM CMS_INST_PARAM
          WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'MBR_NUMB';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Member number not defined for the institute';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting member number from institute';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         
        END;
        
        
        BEGIN
         SP_ORDER_REISSUEPAN_CMS_R304(P_INST_CODE,
                            P_CARD_NO,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            NEW_DISPNAME,
                            P_BANK_CODE,
                            NEW_CARD_NO,
                            V_ERR_MSG);
         IF V_ERR_MSG != 'OK' THEN
           V_ERR_MSG  := 'From reissue pan generation process-- ' || V_ERR_MSG;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         
         END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN 
            RAISE;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'From reissue pan generation process-- ' || V_ERR_MSG;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         
        END;
        
       
        --Gethash is used to hash the new Pan no
        BEGIN
         V_NEW_HASH_PAN := GETHASH(NEW_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting new pan. into hash value ' ||fn_mask(NEW_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;      
       --EN CREATE HASH PAN
       
       IF (P_TXN_CODE ='22' AND P_DELIVERY_CHANNEL ='03') OR
          (P_TXN_CODE ='11' AND P_DELIVERY_CHANNEL ='10') THEN          
             
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_repl_flag =6
                WHERE cap_inst_code = p_inst_code AND cap_pan_code = V_NEW_HASH_PAN;

               IF SQL%ROWCOUNT = 0 
               THEN
                  v_err_msg :=
                        'Problem in updation of replacement flag for pan '
                     || fn_mask (new_card_no, 'X', 7, 6);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_err_msg :=
                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
       ELSIF  (P_TXN_CODE ='29' AND P_DELIVERY_CHANNEL ='03') OR
          (P_TXN_CODE ='99' AND P_DELIVERY_CHANNEL ='10') THEN
                    
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_repl_flag =7
                WHERE cap_inst_code = p_inst_code AND cap_pan_code = V_NEW_HASH_PAN;

               IF SQL%ROWCOUNT =  0
               THEN
                  v_err_msg :=
                    'Problem in updation of replacement flag for pan '
                     || fn_mask (new_card_no, 'X', 7, 6);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_err_msg :=
                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;       
          
       END IF;        
        
    IF V_ERR_MSG = 'OK' THEN
     
         BEGIN
           INSERT INTO CMS_HTLST_REISU
            (CHR_INST_CODE,
             CHR_PAN_CODE,
             CHR_MBR_NUMB,
             CHR_NEW_PAN,
             CHR_NEW_MBR,
             CHR_REISU_CAUSE,
             CHR_INS_USER,
             CHR_LUPD_USER,
             CHR_PAN_CODE_ENCR,
             CHR_NEW_PAN_ENCR)
           VALUES
            (P_INST_CODE,
             V_HASH_PAN,
             V_MBRNUMB,
             GETHASH(NEW_CARD_NO),
             V_MBRNUMB,
             'R',
             P_BANK_CODE,
             P_BANK_CODE,
             V_ENCR_PAN,
             FN_EMAPS_MAIN(NEW_CARD_NO));
         EXCEPTION
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while creating  reissuue record ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
         
         BEGIN
           INSERT INTO CMS_CARDISSUANCE_STATUS
            (CCS_INST_CODE,
             CCS_PAN_CODE,
             CCS_CARD_STATUS,
             CCS_INS_USER,
             CCS_INS_DATE,
             CCS_PAN_CODE_ENCR,
             CCS_APPL_CODE
             )
           VALUES
            (P_INST_CODE,
             GETHASH(NEW_CARD_NO),
             '2',
             P_BANK_CODE,
             SYSDATE,
             FN_EMAPS_MAIN(NEW_CARD_NO),
             V_APPL_CODE        
             );
         EXCEPTION
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while Inserting CCF table ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
         
         BEGIN
           INSERT INTO CMS_SMSANDEMAIL_ALERT
            (CSA_INST_CODE,
             CSA_PAN_CODE,
             CSA_PAN_CODE_ENCR,
             CSA_CELLPHONECARRIER,
             CSA_LOADORCREDIT_FLAG,
             CSA_LOWBAL_FLAG,
             CSA_LOWBAL_AMT,
             CSA_NEGBAL_FLAG,
             CSA_HIGHAUTHAMT_FLAG,
             CSA_HIGHAUTHAMT,
             CSA_DAILYBAL_FLAG,
             CSA_BEGIN_TIME,
             CSA_END_TIME,
             CSA_INSUFF_FLAG,
             CSA_INCORRPIN_FLAG,
             CSA_FAST50_FLAG, 
             CSA_FEDTAX_REFUND_FLAG, 
             CSA_DEPPENDING_FLAG,  
             CSA_DEPACCEPTED_FLAG,  
             CSA_DEPREJECTED_FLAG,  
             CSA_INS_USER,
             CSA_INS_DATE,
             CSA_LUPD_USER,
             CSA_LUPD_DATE)
            (SELECT P_INST_CODE,
                   GETHASH(NEW_CARD_NO),
                   FN_EMAPS_MAIN(NEW_CARD_NO),
                   NVL(CSA_CELLPHONECARRIER, 0),
                   CSA_LOADORCREDIT_FLAG,
                   CSA_LOWBAL_FLAG,
                   NVL(CSA_LOWBAL_AMT, 0),
                   CSA_NEGBAL_FLAG,
                   CSA_HIGHAUTHAMT_FLAG,
                   NVL(CSA_HIGHAUTHAMT, 0),
                   CSA_DAILYBAL_FLAG,
                   NVL(CSA_BEGIN_TIME, 0),
                   NVL(CSA_END_TIME, 0),
                   CSA_INSUFF_FLAG,
                   CSA_INCORRPIN_FLAG,
                   CSA_FAST50_FLAG, 
                   CSA_FEDTAX_REFUND_FLAG, 
                   CSA_DEPPENDING_FLAG,  
                   CSA_DEPACCEPTED_FLAG,  
                   CSA_DEPREJECTED_FLAG,  
                   P_BANK_CODE,
                   SYSDATE,
                   P_BANK_CODE,
                   SYSDATE
               FROM CMS_SMSANDEMAIL_ALERT
              WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = V_HASH_PAN);
           IF SQL%ROWCOUNT != 1 THEN
            V_ERR_MSG  := 'Error while Entering sms email alert detail ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
           END IF;
         EXCEPTION
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while Entering sms email alert detail ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
    
     BEGIN
         SELECT cap_prod_code,cap_card_type
           INTO V_PROD_CODE,v_card_type
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_NEW_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        
    --AVQ Added for FSS-1961(Melissa)
       BEGIN
              SP_LOGAVQSTATUS(
              P_INST_CODE,
              P_DELIVERY_CHANNEL,
              NEW_CARD_NO,
              V_PROD_CODE,
              V_CUST_CODE,
              V_RESP_CDE,
              V_ERR_MSG,
              v_card_type
              );
            IF V_ERR_MSG != 'OK' THEN
               V_ERR_MSG  := 'Exception while calling LOGAVQSTATUS-- ' || V_ERR_MSG;
               V_RESP_CDE := '21';
              RAISE EXP_REJECT_RECORD;         
             END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           V_ERR_MSG  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;  
    --End  Added for FSS-1961(Melissa)
    END IF;
    P_RESP_MSG := NEW_CARD_NO;
  
     
           
  
    BEGIN
      
         IF V_RESP_CDE = '1' THEN
           BEGIN
            SELECT CAM_ACCT_BAL
              INTO V_ACCT_BALANCE
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO =V_ACCT_NUMBER
               FOR UPDATE NOWAIT;
           EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_RESP_CDE := '14'; 
              V_ERR_MSG  := 'Invalid Card ';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              V_RESP_CDE := '12';
              V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                         SQLERRM;
              RAISE EXP_REJECT_RECORD;
           END;
         
           --En find prod code and card type for the card number
           IF V_OUTPUT_TYPE = 'N' THEN
            NULL;
           END IF;
         END IF;
   
         --Sn Selecting Reason code for Initial Load
         BEGIN
           SELECT CSR_SPPRT_RSNCODE
            INTO V_RESONCODE
            FROM CMS_SPPRT_REASONS
            WHERE CSR_INST_CODE = P_INST_CODE AND CSR_SPPRT_KEY = 'REISSUE' AND
                ROWNUM < 2;
         
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Order Replacement card reason code is present in master';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while selecting reason code from master' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;
    
         BEGIN
           INSERT INTO CMS_PAN_SPPRT
            (CPS_INST_CODE,
             CPS_PAN_CODE,
             CPS_MBR_NUMB,
             CPS_PROD_CATG,
             CPS_SPPRT_KEY,
             CPS_SPPRT_RSNCODE,
             CPS_FUNC_REMARK,
             CPS_INS_USER,
             CPS_LUPD_USER,
             CPS_CMD_MODE,
             CPS_PAN_CODE_ENCR)
           VALUES
            (P_INST_CODE,
             V_HASH_PAN,
             P_MBR_NUMB,
             V_CAP_PROD_CATG,
             'REISSUE',
             V_RESONCODE,
             P_REMRK,
             P_BANK_CODE,
             P_BANK_CODE,
             0,
             V_ENCR_PAN);
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while inserting records into card support master' ||
                        SUBSTR(SQLERRM, 1, 200);
           
            RAISE EXP_REJECT_RECORD;
         END;
         --En create a record in pan spprt
    END;
    
    
    V_RESP_CDE := '1';

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;
    --0010762
    BEGIN
       UPDATE TRANSACTIONLOG
         SET IPADDRESS = P_IPADDRESS
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
            TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
            BUSINESS_TIME = P_TRAN_TIME AND
            DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '69';
        V_ERR_MSG  := 'Problem while inserting data into transaction log' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
    ---
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     P_RESP_MSG := V_ERR_MSG;
     ROLLBACK ;
     
       
         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER 
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =V_ACCT_NUMBER
            AND   CAM_INST_CODE = P_INST_CODE;
         EXCEPTION
           WHEN OTHERS THEN
            V_ACCT_BALANCE := 0;
            V_LEDGER_BAL   := 0;
         END;
     
         
         BEGIN
           UPDATE TRANSACTIONLOG
             SET IPADDRESS = P_IPADDRESS
            WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
                TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
                BUSINESS_TIME = P_TRAN_TIME AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '69';
            V_ERR_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
         END;
         
      
         --Sn select response code and insert record into txn log dtl
         BEGIN
           P_RESP_CODE := V_RESP_CDE;
           P_RESP_MSG  := V_ERR_MSG;
           SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE AND
                CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                CMS_RESPONSE_ID = V_RESP_CDE;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69';
            ROLLBACK;
         END;
       
     
         BEGIN
           INSERT INTO CMS_TRANSACTION_LOG_DTL
            (CTD_DELIVERY_CHANNEL,
             CTD_TXN_CODE,
             CTD_TXN_TYPE,
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
             CTD_SYSTEM_TRACE_AUDIT_NO,
             CTD_INST_CODE,
             CTD_CUSTOMER_CARD_NO_ENCR,
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_TXN_TYPE,
             P_MSG,
             P_TXN_MODE,
             P_TRAN_DATE,
             P_TRAN_TIME,
             V_HASH_PAN,
             P_TXN_AMT,
             P_CURR_CODE,
             V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             V_TOTAL_AMT,
             V_CARD_CURR,
             'E',
             V_ERR_MSG,
             P_RRN,
             P_STAN,
             P_INST_CODE,
             V_ENCR_PAN,
             V_ACCT_NUMBER);
         
           P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; 
            ROLLBACK;
            RETURN;
         END;
        
      
         v_timestamp := systimestamp;         
    

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
          RULE_INDICATOR,
          RULEGROUPID,
          MCCODE,
          CURRENCYCODE,
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
          TIPS,
          DECLINE_RULEID,
          ATM_NAME_LOCATION,
          AUTH_ID,
          TRANS_DESC,
          AMOUNT,
          PREAUTHAMOUNT,
          PARTIALAMOUNT,
          MCCODEGROUPID,
          CURRENCYCODEGROUPID,
          TRANSCODEGROUPID,
          RULES,
          PREAUTH_DATE,
          GL_UPD_FLAG,
          SYSTEM_TRACE_AUDIT_NO,
          INSTCODE,
          FEECODE,
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          IPADDRESS,
          CARDSTATUS, 
          FEE_PLAN, 
          CSR_ACHACTIONTAKEN,
          error_msg,
          PROCESSES_FLAG,
          ACCT_TYPE,        
          TIME_STAMP        
          )
        VALUES
         (P_MSG,
          P_RRN,
          P_DELIVERY_CHANNEL,
          P_TERM_ID,
          V_BUSINESS_DATE,
          P_TXN_CODE,
          V_TXN_TYPE,
          P_TXN_MODE,
          DECODE(P_RESP_CODE, '00', 'C', 'F'),
          P_RESP_CODE,
          P_TRAN_DATE,
          SUBSTR(P_TRAN_TIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL, 
          NULL, 
          P_BANK_CODE,
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),  
          '',
          '',
          P_MCC_CODE,
          P_CURR_CODE,
          NULL, 
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                               
          '',
          '',
          V_AUTH_ID,
          'Card replacement update activity 30.4',
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')),   
          '0.00',   
          '0.00',
          '',
          '',
          '',
          '',
          '',
          null,
          P_STAN,
          P_INST_CODE,
          null,
          NVL(0,0),
          NVL(0,0),
          NVL(0,0),
          V_DR_CR_FLAG,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          V_ENCR_PAN,
          NULL,
          null,
          P_RVSL_CODE,
          V_ACCT_NUMBER,
          NVL(V_ACCT_BALANCE,0),
          NVL(V_LEDGER_BAL,0),
          V_RESP_CDE,
          P_IPADDRESS,
          V_APPLPAN_CARDSTAT, 
          null, 
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
           v_cam_type_code,   
           v_timestamp           
          );
      
        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; 
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;             
      END;

      --En create a entry in txn log         
         
  WHEN OTHERS THEN
  ROLLBACK ;
  

         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER 
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =V_ACCT_NUMBER
            AND CAM_INST_CODE = P_INST_CODE;
         EXCEPTION
           WHEN OTHERS THEN
            V_ACCT_BALANCE := 0;
            V_LEDGER_BAL   := 0;
         END;

       --Sn select response code and insert record into txn log dtl
         BEGIN
           SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE AND
                CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                CMS_RESPONSE_ID = V_RESP_CDE;
         
           P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; 
            ROLLBACK;
         END;
       
    
         BEGIN
           INSERT INTO CMS_TRANSACTION_LOG_DTL
            (CTD_DELIVERY_CHANNEL,
             CTD_TXN_CODE,
             CTD_TXN_TYPE,
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
             CTD_SYSTEM_TRACE_AUDIT_NO,
             CTD_INST_CODE,
             CTD_CUSTOMER_CARD_NO_ENCR,
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_TXN_TYPE,
             P_MSG,
             P_TXN_MODE,
             P_TRAN_DATE,
             P_TRAN_TIME,
             V_HASH_PAN,
             P_TXN_AMT,
             P_CURR_CODE,
             V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             V_TOTAL_AMT,
             V_CARD_CURR,
             'E',
             V_ERR_MSG,
             P_RRN,
             P_STAN,
             P_INST_CODE,
             V_ENCR_PAN,
             V_ACCT_NUMBER);
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; 
            ROLLBACK;
            RETURN;
         END;
     
         v_timestamp := systimestamp;         
      
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
          RULE_INDICATOR,
          RULEGROUPID,
          MCCODE,
          CURRENCYCODE,
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
          TIPS,
          DECLINE_RULEID,
          ATM_NAME_LOCATION,
          AUTH_ID,
          TRANS_DESC,
          AMOUNT,
          PREAUTHAMOUNT,
          PARTIALAMOUNT,
          MCCODEGROUPID,
          CURRENCYCODEGROUPID,
          TRANSCODEGROUPID,
          RULES,
          PREAUTH_DATE,
          GL_UPD_FLAG,
          SYSTEM_TRACE_AUDIT_NO,
          INSTCODE,
          FEECODE,
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          IPADDRESS,
          CARDSTATUS, 
          FEE_PLAN, 
          CSR_ACHACTIONTAKEN,
          ERROR_MSG,
          PROCESSES_FLAG,
          ACCT_TYPE,        
          TIME_STAMP        
          )
        VALUES
         (P_MSG,
          P_RRN,
          P_DELIVERY_CHANNEL,
          P_TERM_ID,
          V_BUSINESS_DATE,
          P_TXN_CODE,
          V_TXN_TYPE,
          P_TXN_MODE,
          DECODE(P_RESP_CODE, '00', 'C', 'F'),
          P_RESP_CODE,
          P_TRAN_DATE,
          SUBSTR(P_TRAN_TIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL, 
          NULL, 
          P_BANK_CODE,
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999999.99')),    
          '',
          '',
          P_MCC_CODE,
          P_CURR_CODE,
          NULL, 
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                
          '',
          '',
          V_AUTH_ID,
          'Card replacement update activity 30.4',
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999999.99')),      
          '0.00', 
          '0.00', 
          '',
          '',
          '',
          '',
          '',
          null,
          P_STAN,
          P_INST_CODE,
          null,
          0,             
          NVL(0,0),   
          NVL(0,0),         
          V_DR_CR_FLAG,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          V_ENCR_PAN,
          NULL,
          null,
          P_RVSL_CODE,
          V_ACCT_NUMBER,
          NVL(V_ACCT_BALANCE,0),    
          NVL(V_LEDGER_BAL,0),      
          V_RESP_CDE,
          P_IPADDRESS,
          V_APPLPAN_CARDSTAT, 
          null, 
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
          v_cam_type_code,   
          v_timestamp        
          );
      
        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; 
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;             
                     
      END;

  END;
   

EXCEPTION

when EXP_REJECT_RECORD then
ROLLBACK;
    P_RESP_CODE := '69'; 
    P_RESP_MSG  := P_RESP_MSG ;

  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; 
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;
/
show error