create or replace
PROCEDURE        vmscms.SP_ACCTLVL_FEELIMIT(
   P_INST_CODE             IN       NUMBER,
   P_CARD_NO               IN       VARCHAR2,
   P_TRAN_DATE             IN       DATE,
   P_FEE_CODE              IN       NUMBER,
   P_MAX_LIMIT             IN       NUMBER,
   P_MAXLIMIT_FREQ         IN       VARCHAR2,
   P_MAXLIMIT_EXCEEDED     OUT      VARCHAR2,
   P_ERROR_MSG             OUT      VARCHAR2 )
IS 
v_hash_pan         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
v_tran_date        DATE;
v_acct_id         CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
v_reset_date        DATE;
v_count           NUMBER;
v_count_r           NUMBER;
v_maxlimit          NUMBER;
EXP_MAIN            EXCEPTION;
V_FIRST_TIME_SETUP   CHAR(1) DEFAULT 'N';
/*************************************************
     * Created  By      : NAILA UZMA S.N
     * Created  Date    : 14-08-2013
     * REASON           : NCGPR-438: This procedure will check whether the maximium limit which was configured for fee code has been reached.
                          Maximum limit: maximum number of times the fee to be debited for a particular account based on the frequncy configuration for maximum limit.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 14-08-2013
     * Release Number   : RI0024.4_B0004
	 
	 * Modified BY      : Arun
     * Modified Date    : 18-09-2013    
	 * Modified Reason	: mantis id:12340
	 * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Release Number   : RI0024.4_B0016
 *************************************************/
BEGIN
P_MAXLIMIT_EXCEEDED :='N';
P_ERROR_MSG :='OK';

        --SN CREATE HASH PAN
      BEGIN
           v_hash_pan := gethash(P_CARD_NO);
      
      EXCEPTION
          WHEN OTHERS THEN
          P_ERROR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
          RAISE EXP_MAIN;
      
      END;
    
    --  V_TRAN_DATE:= TRUNC(P_TRAN_DATE); --Commented for mantis Id : 12340
       V_TRAN_DATE:= TRUNC(sysdate); --Added for mantis Id : 12340
    
       IF P_MAXLIMIT_FREQ = 'D'  THEN
             V_RESET_DATE := V_TRAN_DATE+1;
       
          ELSIF P_MAXLIMIT_FREQ='W'  THEN
               BEGIN 
                SELECT trunc(next_day(V_TRAN_DATE,'MONDAY')) INTO V_RESET_DATE  FROM DUAL;
                EXCEPTION
                WHEN OTHERS THEN
                P_ERROR_MSG := 'ERROR WHILE FETCHING WEEK DATE '|| SUBSTR (SQLERRM, 1, 200);
               END;  
               
          ELSIF P_MAXLIMIT_FREQ='M' THEN
               BEGIN     
                SELECT trunc(last_day(V_TRAN_DATE)+1,'Month') INTO V_RESET_DATE  FROM DUAL;
                EXCEPTION
                  WHEN OTHERS THEN
                  P_ERROR_MSG := 'ERROR WHILE FETCHING MONTH DATE '|| SUBSTR (SQLERRM, 1, 200);
               END;  
          ELSIF P_MAXLIMIT_FREQ ='Y' THEN
                BEGIN       
                  SELECT ADD_MONTHS(TRUNC(V_TRAN_DATE,'Year'),12) INTO V_RESET_DATE  FROM DUAL;  
                  EXCEPTION
                    WHEN OTHERS THEN
                    P_ERROR_MSG := 'ERROR WHILE FETCHING YEAR DATE '|| SUBSTR (SQLERRM, 1, 200);
               END;          
        END IF;
              
   --START OF FETCHING ACCOUNT ID FROM APPL PAN ,ACCT MAST           
      BEGIN
      
            SELECT CAM_ACCT_ID
            INTO v_acct_id
            FROM CMS_ACCT_MAST      
            WHERE  CAM_INST_CODE=P_INST_CODE AND CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO FROM CMS_APPL_PAN 
            WHERE CAP_PAN_CODE=v_hash_pan 
            AND CAP_INST_CODE=P_INST_CODE)
            AND CAM_TYPE_CODE='1';
        
      
      EXCEPTION
          WHEN OTHERS THEN
          P_ERROR_MSG := 'ERROR WHILE FETCHING ACCOUNT NUMBER ' || SUBSTR(SQLERRM,1,200);
      END;    
   --END OF FETCHING  ACCT ID   
  
      BEGIN
    
              SELECT CAF_MAX_LIMIT 
              INTO v_maxlimit
              FROM CMS_ACCTLVL_FEELIMIT
              WHERE CAF_ACCT_ID=v_acct_id 
              AND CAF_FEE_CODE=P_FEE_CODE
              AND CAF_INST_CODE=P_INST_CODE;
              
              EXCEPTION
              
              WHEN NO_DATA_FOUND THEN
                                     
                            BEGIN
                            
                                INSERT INTO CMS_ACCTLVL_FEELIMIT(
                                CAF_ACCT_ID,
                                CAF_FEE_CODE,
                                CAF_MAX_LIMIT,
                                CAF_LMT_RESETDATE,
                                CAF_INS_DATE,
                                CAF_LUPD_DATE,
                                CAF_INST_CODE)
                                VALUES(v_acct_id,P_FEE_CODE,1,V_RESET_DATE,SYSDATE,SYSDATE,P_INST_CODE);
                                  IF SQL%ROWCOUNT = 0
                                    THEN
                                    P_ERROR_MSG := 'Error while inserting in CMS_ACCTLVL_FEELIMIT '|| SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_MAIN;
                                   END IF;
                                
                                V_FIRST_TIME_SETUP := 'Y' ;
                                
                            EXCEPTION
                            WHEN EXP_MAIN THEN
                            RAISE;
                            WHEN OTHERS THEN
                               
                                P_ERROR_MSG  := 'Error while inserting records in CMS_ACCTLVL_FEELIMIT'||SUBSTR(SQLERRM,1,200);
                            
                            END;
              WHEN EXP_MAIN THEN
              RAISE;
              WHEN OTHERS THEN
              P_ERROR_MSG := 'ERROR  WHILE  FETCHING DATA FROM  CMS_ACCTLVL_FEELIMIT' || SUBSTR(SQLERRM,1,200);
              RAISE exp_main;
        END;
    
    IF V_FIRST_TIME_SETUP = 'N' THEN

    ---START OF RESETING MAX-LIMIT
          BEGIN
              SELECT COUNT(*) INTO v_count 
              FROM CMS_ACCTLVL_FEELIMIT
              WHERE CAF_ACCT_ID=v_acct_id
              AND CAF_FEE_CODE=P_FEE_CODE
              AND CAF_INST_CODE=P_INST_CODE
            --  AND CAF_LMT_RESETDATE<=P_TRAN_DATE --Commented for mantis Id : 12340
              AND CAF_LMT_RESETDATE <= sysdate; --Added for mantis Id : 12340
             EXCEPTION
                WHEN OTHERS THEN
                P_ERROR_MSG := 'ERROR  WHILE  FETCHING DATA FROM  CMS_ACCTLVL_FEELIMIT' || SUBSTR(SQLERRM,1,200);
                RAISE EXP_MAIN;
          END;
           
           IF v_count>0 THEN
              BEGIN
                   UPDATE CMS_ACCTLVL_FEELIMIT 
                   SET CAF_MAX_LIMIT=0,CAF_LUPD_DATE=SYSDATE,CAF_LMT_RESETDATE=V_RESET_DATE
                   WHERE CAF_ACCT_ID=v_acct_id
                   AND CAF_FEE_CODE=P_FEE_CODE
                   AND CAF_INST_CODE=P_INST_CODE;
                   IF SQL%ROWCOUNT = 0
                           THEN
                              P_ERROR_MSG := 'Error while updating CMS_ACCTLVL_FEELIMIT '|| SUBSTR (SQLERRM, 1, 200);
                               RAISE EXP_MAIN;
                    END IF;
                  v_maxlimit:=0;
                 EXCEPTION
                    WHEN EXP_MAIN THEN
                            RAISE;
                    WHEN OTHERS THEN
                    P_ERROR_MSG := 'ERROR  WHILE  RESETTING MAXLIMIT  IN CMS_ACCTLVL_FEELIMIT ' || SUBSTR(SQLERRM,1,200);
                    RAISE EXP_MAIN; 
               END;
           END IF; 
      --- END OF RESETTING OF MAXLIMIT    
 
          IF ( (v_maxlimit IS NOT NULL) AND (v_maxlimit < P_MAX_LIMIT))  THEN
         
               BEGIN
                  UPDATE CMS_ACCTLVL_FEELIMIT 
                  SET CAF_MAX_LIMIT=CAF_MAX_LIMIT+1
                  WHERE CAF_ACCT_ID=v_acct_id
                  AND CAF_FEE_CODE=P_FEE_CODE
                  AND CAF_INST_CODE=P_INST_CODE;
                   IF SQL%ROWCOUNT = 0
                       THEN
                          P_ERROR_MSG := 'Error while updating maxlimit in CMS_ACCTLVL_FEELIMIT '|| SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_main;
                    END IF;
                  P_MAXLIMIT_EXCEEDED :='N';
                EXCEPTION
                    WHEN EXP_MAIN THEN
                            RAISE;
                    WHEN OTHERS THEN
                    P_ERROR_MSG := 'ERROR  WHILE  UPDATING MAXLIMIT IN  CMS_ACCTLVL_FEELIMIT' || SUBSTR(SQLERRM,1,200);
                    RAISE EXP_MAIN;
                END;
                 
          
              ELSE 
                P_MAXLIMIT_EXCEEDED :='Y';
           
            END IF;
  
    END IF;
      
EXCEPTION -- MAIN
      WHEN EXP_MAIN THEN
          NULL;
      
      WHEN OTHERS THEN
        P_ERROR_MSG := SUBSTR(SQLERRM,1,200);
 
END;
/
SHOW ERRORS;