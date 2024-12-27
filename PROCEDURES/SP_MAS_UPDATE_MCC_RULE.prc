CREATE OR REPLACE PROCEDURE VMSCMS.SP_MAS_UPDATE_MCC_RULE(
                                          P_INSTCODE         IN NUMBER,
                                          P_USER_ID          IN NUMBER,
                                          P_RRN              IN VARCHAR2,
                                          P_TRANDATE         IN VARCHAR2,
                                          P_TRANTIME         IN VARCHAR2,
                                          P_TXN_CODE         IN VARCHAR2,
                                          P_DELIVERY_CHANNEL IN VARCHAR2,
                                          P_ARRAY            IN ARRAY_TABLE,
                                          P_PROD_CODE        IN VARCHAR2,
                                          P_PRODUCT_CATEGORY IN VARCHAR2,
                                          P_ADDORDELETE_FLAG IN VARCHAR2,
                                          P_MEDAGATE_REF_ID  IN VARCHAR2, 
                                          P_RESP_CODE        OUT VARCHAR2,
                                          P_ERRMSG           OUT VARCHAR2,
                                          P_MCC_OUT          OUT ARRAY_TABLE_OUT, -- added mvhost -386
                                          P_LIST_MCC         OUT CLOB  -- Added for List of Mcc's 
                                          ) AS

  /*************************************************
  * Created Date      :  15-JUNE-2013
  * Created By        :  ARUNVIJAY
  * PURPOSE           :  TO CONFIGURE PERMISSIVE MCC RULE FOR MEDAGATE PRODUCT
  
  * Modified reason   :  CREATED FOR MVHOST-386
  * Modified by       : Siva Kumar M
  * Modified date     : 22/06/13
  * Modified reason   :  mvhost-386.
  * Reviewer          :  Dhiraj
  * Reviewed Date     :  25-06-2013
  * Release Number    :  RI0024.2_B0008
  
  * Modified by       :  Siva Kumar M
  * Modified date     :  26/06/13
  * Modified reason   :  Defect Id's-11404,11405
  * Reviewer          : Dhiraj
  * Reviewed Date     : 27-06-2013
  * Build Number      : RI0024.2_B0009 
  
  * Modified by       : Siva Kumar M
  * Modified date     : 28/06/13
  * Modified reason   : Changes done for Obeservation.
  * Reviewer          : 
  * Reviewed Date     : 
  * Build Number      : RI0024.2_B0011 
  
  * Modified by       : Arunvijay
  * Modified date     : 04-July-2013
  * Modified reason   : Mantis Id 11471,11403,11451
  * Modified reason   : 
  * Reviewer          : 
  * Reviewed Date     : RI0024.3_B0003

  * Modified By      : Pankaj S.
  * Modified Date    : 19-Dec-2013
  * Modified Reason  : Logging issue changes(Mantis ID-13160)
  * Reviewer         : Dhiraj
  * Reviewed Date    : 
  * Build Number     : RI0027_B0003
  
  
  * Modified By      : Siva Kumar M.
  * Modified Date    : 13-Mar-2014
  * Modified Reason  : Medagate ListMcc rules.
  * Reviewer         : Dhiraj
  * Reviewed Date    : 13-Mar-2014
  * Build Number     : RI0027.2_B0002
     
  *************************************************/
    
    EXP_MAIN_REJECT_RECORD   EXCEPTION;
    V_TXN_TYPE               CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
    V_TRANS_DESC             CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
    V_TRAN_DATE              DATE;
    V_RRN_COUNT              NUMBER;
    V_MCC_COUNT              NUMBER;
    V_BUSINESS_DATE          DATE;
    V_RESPCODE               VARCHAR2(5);
    V_MCCODEGROUPID          MCCODEGROUPING.MCCODEGROUPID%TYPE;
    V_MCCRULEID              RULE.RULEID%TYPE;
    V_RULEGROUPID            RULEGROUPING.RULEGROUPID%TYPE;
    V_RULECARDTYPE_STATUS    PCMS_PRODCATTYPE_RULEGROUP.PPR_ACTIVE_FLAG%TYPE;
    V_MCCGRP_ID              MCCODE_GROUP.MCCODEGROUPID%TYPE;
    V_RULEGRP_ID             PCMS_PRODCATTYPE_RULEGROUP.PPR_RULEGROUP_CODE%TYPE; -- added for Defect Id's-11404,11405
    V_RULECNT_CARDTYPE       NUMBER(3);
    V_MCCDEL_COUNT           NUMBER(3);
    V_FLAG                   VARCHAR2(1);
    V_CRDR_FLAG              VARCHAR2(2);
    V_MCCGRP_COUNT           NUMBER(3);
    V_INCR_CMT               NUMBER(3);
	
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
 
 -- attached for  ListMCC rule API
CURSOR MCCCODE  IS
           SELECT MCCODE||','  AS MCC
                        FROM MCCODE_GROUP
                        WHERE MCCODEGROUPID = V_MCCGRP_ID
                        AND MCC_INST_CODE = P_INSTCODE;
  

BEGIN
  P_ERRMSG   := 'OK';
  V_RESPCODE := '1';
  V_INCR_CMT := 0;
  P_MCC_OUT := NEW ARRAY_TABLE_OUT (); -- added mvhost -386
  P_MCC_OUT.EXTEND (10); -- added mvhost -386

    -- SN1 Find Credit/Debit flag
    BEGIN
        SELECT  TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
        CTM_TRAN_DESC,CTM_CREDIT_DEBIT_FLAG
        INTO    V_TXN_TYPE,
        V_TRANS_DESC ,V_CRDR_FLAG
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
        CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
        CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '12'; 
        P_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE || ' and delivery channel ' || P_DELIVERY_CHANNEL;
    RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
        V_RESPCODE := '12'; 
        P_ERRMSG := 'Error while selecting CMS_TRANSACTION_MAST' ||SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN1
    
    --SN2 Validate transaction date
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '45'; 
        P_ERRMSG   := 'Problem while converting transaction date ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN2
    

    --SN3 Business date formation
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' || SUBSTR(TRIM(P_TRANTIME), 1, 10),'yyyymmdd hh24:mi:ss');
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '32'; 
        P_ERRMSG   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN3
     
     
    --SN4 Check for duplicate RRN 
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
        SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM TRANSACTIONLOG
        WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
        BUSINESS_DATE = P_TRANDATE AND
        DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
ELSE
		SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
        BUSINESS_DATE = P_TRANDATE AND
        DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
END IF;		
    
    IF V_RRN_COUNT > 0 THEN
        V_RESPCODE := '22';
        P_ERRMSG   := 'Duplicate RRN ' || ' on ' || P_TRANDATE;
    RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
    RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
        V_RESPCODE := '12';
        P_ERRMSG := 'Error while selecting rrn count  ' ||  SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN4
    
   --SN5 Check whether a permissive rule is attached at product category level
    BEGIN
        SELECT COUNT(1)
        INTO V_RULECNT_CARDTYPE
        FROM PCMS_PRODCATTYPE_RULEGROUP
        WHERE PPR_PROD_CODE = P_PROD_CODE AND
        PPR_CARD_TYPE = P_PRODUCT_CATEGORY 
        AND PPR_PERMRULE_FLAG = 'Y';
  
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG  := 'Error while fetching rule group count attached at card type level'||SUBSTR(SQLERRM,1,200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN5
   -- Modified for ListMCC rule
  IF P_TXN_CODE <> '17' THEN
  
    --SN6 Fetch the max value of mcc gorup id 
    BEGIN
        SELECT nvl(max(to_number(MCCODEGROUPID)),'0') + 1
        INTO V_MCCODEGROUPID
        FROM MCCODEGROUPING;
        
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG  := 'Error while fetching the max MCCodeGroupID'||SUBSTR(SQLERRM,1,200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --END6
            
    --SN7 Fetch the max value of ruleid        
    BEGIN
        SELECT nvl(max(to_number(RULEID)),'0') + 1
        INTO V_MCCRULEID
        FROM RULE;
    
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG  := 'Error while fetching the max RULEID'||SUBSTR(SQLERRM,1,200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN7
        
    --SN8 Fetch the max value of rulegroupid    
    BEGIN
        SELECT nvl(max(to_number(RULEGROUPID)),'0') + 1
        INTO V_RULEGROUPID
        FROM RULEGROUPING;
    
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG  := 'Error while fetching the max RULEGROUPID'||SUBSTR(SQLERRM,1,200);
    RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN8
      
    --SN11 Validate MCC recieved in the request
    FOR i IN 1 .. p_array.COUNT
      LOOP
       
        BEGIN
            SELECT COUNT(1)
            INTO V_MCC_COUNT
            FROM MCCODE
            WHERE ACT_INST_CODE = P_INSTCODE AND MCCODE = P_ARRAY (I) ; 
            
        
        IF V_MCC_COUNT = 0 THEN
            V_RESPCODE := '175';
            P_ERRMSG   := 'Invalid MCC'|| ':' || P_ARRAY (I);
            V_MCCODEGROUPID :=null; --added for Defect Id's-11404,11405
        RAISE EXP_MAIN_REJECT_RECORD;
        
        END IF;
        
        EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG := 'Error while validating mcc ' ||  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
        END;
        
    END LOOP;
    --EN11
   END IF;  
    --SN 12 Check whether a rule group with MCC is attached to incoming PAN's product category
    IF V_RULECNT_CARDTYPE = 0  AND P_TXN_CODE <> '17' THEN -- modified for ListMCC rule
    
         --SN13 If no rules are attached at product category level , create a new rule and AddOrDelete flag should be "A"
         IF P_ADDORDELETE_FLAG ='A' THEN
         
           BEGIN
            
              INSERT INTO MCCODEGROUPING(MCCODEGROUPID,MCCODEGROUPDESC,ACTIVATIONSTATUS,ACT_INST_CODE,ACT_INS_DATE,ACT_INS_USER,permrule_flag)
              VALUES(V_MCCODEGROUPID,'MCC-PERMRULE-GROUP-DESC-'||P_PRODUCT_CATEGORY,'Y', P_INSTCODE,SYSDATE,P_USER_ID,'Y'); -- removed P_PRODUCT_CATEGORY
              
            EXCEPTION
            WHEN OTHERS THEN
              V_RESPCODE := '21';
              P_ERRMSG  := 'Error while inserting records in MCCODEGROUPING'||SUBSTR(SQLERRM,1,200);
              
              RAISE EXP_MAIN_REJECT_RECORD;
            END;
            
       
           FOR i IN 1 .. p_array.COUNT
              LOOP
                     
                BEGIN
                
                 
                
                  INSERT INTO MCCODE_GROUP(MCCODE,MCCODEGROUPID,MCC_INST_CODE,MCC_INS_DATE,MCC_INS_USER)
                  VALUES(p_array (i),V_MCCODEGROUPID,P_INSTCODE,SYSDATE,P_USER_ID);
                  
                      
                    IF (SQL%ROWCOUNT =1)  THEN -- added mvhost -386
                                            
                     P_MCC_OUT (i) := p_array (i);
                                             
                    END IF;
                  
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESPCODE := '21';
                  P_ERRMSG  := 'Error while inserting records in MCCODE_GROUP'||SUBSTR(SQLERRM,1,200);
              
                 RAISE EXP_MAIN_REJECT_RECORD;
                END;
            
              END LOOP;
              
              BEGIN
        
              INSERT INTO  RULE(RULEID,RULEDESC,RULETYPE,AUTHTYPE,MCCGROUPID,CCGROUPID,ACTIVATIONSTATUS,ACT_INST_CODE,ACT_INS_DATE,ACT_INS_USER,permrule_flag)
              VALUES(V_MCCRULEID,'MCC-PERMRULE-DESC-'||P_PRODUCT_CATEGORY,'2','A',V_MCCODEGROUPID,NULL,'Y',P_INSTCODE,SYSDATE,P_USER_ID,'Y'); -- removed P_PRODUCT_CATEGORY
              
               EXCEPTION
                WHEN OTHERS THEN
                  V_RESPCODE := '21';
                  P_ERRMSG  := 'Error while inserting records in RULE'||SUBSTR(SQLERRM,1,200);
              
                 RAISE EXP_MAIN_REJECT_RECORD;
                END;
            
              
                BEGIN
                
                  INSERT INTO RULEGROUPING(RULEGROUPID,RULEGROUPDESC,ACTIVATIONSTATUS,ACT_INST_CODE,ACT_INS_DATE,ACT_INS_USER,permrule_flag)
                  VALUES(V_RULEGROUPID,'MCC-PERMRULEGROUP-DESC-'||P_PRODUCT_CATEGORY,'Y',P_INSTCODE,SYSDATE,P_USER_ID,'Y'); -- removed P_PRODUCT_CATEGORY
                  
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESPCODE := '21';
                  P_ERRMSG  := 'Error while inserting records in RULEGROUPING'||SUBSTR(SQLERRM,1,200);
              
                 RAISE EXP_MAIN_REJECT_RECORD;
                END;
              
                BEGIN
              
                  INSERT INTO RULECODE_GROUP(RULEID,RULEGROUPID,RUL_INST_CODE,RUL_INS_DATE,RUL_INS_USER)
                  VALUES(V_MCCRULEID,V_RULEGROUPID,P_INSTCODE,SYSDATE,P_USER_ID);
                
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESPCODE := '21';
                  P_ERRMSG  := 'Error while inserting records in RULECODE_GROUP'||SUBSTR(SQLERRM,1,200);
             
                  RAISE EXP_MAIN_REJECT_RECORD;
                END;
                
                BEGIN
             
                  INSERT INTO PCMS_PRODCATTYPE_RULEGROUP
                  VALUES(P_INSTCODE,P_PROD_CODE,P_PRODUCT_CATEGORY,V_RULEGROUPID,SYSDATE-1,SYSDATE-1,'PCT',P_USER_ID,SYSDATE,P_USER_ID,SYSDATE,'Y','Y');
              
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESPCODE := '21';
                  P_ERRMSG  := 'Error while inserting records in PCMS_PRODCATTYPE_RULEGROUP'||SUBSTR(SQLERRM,1,200);
            
                 RAISE EXP_MAIN_REJECT_RECORD;
                END;
        -- added for Defect Id's-11404,11405
                
         ELSE
            
            V_MCCODEGROUPID :=null;
             V_RULEGROUPID := null;
            P_ERRMSG := 'AddOrDelete flag should be A for first time Rule Creation';
            V_RESPCODE:= '188';
            RAISE EXP_MAIN_REJECT_RECORD;
         
         --END IF; 
         
         END IF;     
         --EN13
      --EN12      
      ELSE    
         --SN14 If a rule is already attached and if AddOrDelete flag is "A" , then attach the MCC recieved to the existing rule
         IF P_ADDORDELETE_FLAG ='A' THEN
         
          BEGIN
          
              SELECT e.mccodegroupid ,A.ppr_rulegroup_code  -- Added for Defect Id:11405
              INTO V_MCCGRP_ID,V_RULEGRP_ID
              FROM PCMS_PRODCATTYPE_RULEGROUP A, RULECODE_GROUP B  , RULE D , MCCODEGROUPING E 
              WHERE A.ppr_rulegroup_code = B.rulegroupid
              AND b.ruleid = D.ruleid
              AND D.MCCGROUPID = E.MCCODEGROUPID
              AND a.ppr_prod_code =P_PROD_CODE
              AND A.PPR_CARD_TYPE =P_PRODUCT_CATEGORY
              AND A.PPR_PERMRULE_FLAG = 'Y' -- Condition included for defect id 11471
              AND ROWNUM <2;
              
               V_MCCODEGROUPID := V_MCCGRP_ID; -- Added for Defect Id:11404
               V_RULEGROUPID := V_RULEGRP_ID;
          
          EXCEPTION
          WHEN OTHERS THEN
              V_RESPCODE := '21';
              P_ERRMSG  := 'Error while fetching mccodegroupid during mcc deletion'|| SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
          END;
         
          BEGIN
              
               FOR i IN 1 .. p_array.COUNT
                  LOOP
                       
                   BEGIN
                        
                        SELECT COUNT(MCCODE) 
                        INTO V_MCCGRP_COUNT
                        FROM MCCODE_GROUP
                        WHERE MCCODEGROUPID = V_MCCGRP_ID
                        AND MCCODE =  p_array (i);
                        
                        IF V_MCCGRP_COUNT = 1 THEN
                        
                        V_INCR_CMT := V_INCR_CMT + 1;
                        
                        END IF;
                        
                    EXCEPTION
                    WHEN OTHERS THEN
                        V_RESPCODE := '21';
                        P_ERRMSG  := 'Error while fetching the existing mcc'||SUBSTR(SQLERRM,1,200);
                    RAISE EXP_MAIN_REJECT_RECORD;
                    END;
                                      
                            BEGIN
                            
                                  SELECT  A.PPR_ACTIVE_FLAG
                                  INTO V_RULECARDTYPE_STATUS
                                  FROM PCMS_PRODCATTYPE_RULEGROUP A, RULECODE_GROUP B ,RULEGROUPING C , RULE D , MCCODE_GROUP E , MCCODEGROUPING F
                                  WHERE A.ppr_rulegroup_code = B.rulegroupid
                                  AND b.rulegroupid = c.rulegroupid
                                  AND D.ruleid = b.ruleid
                                  AND D.MCCGROUPID = E.MCCODEGROUPID
                                  AND E.MCCODEGROUPID = F.MCCODEGROUPID
                                  AND a.ppr_prod_code = P_PROD_CODE
                                  AND A.PPR_CARD_TYPE = P_PRODUCT_CATEGORY
                                  AND A.PPR_PERMRULE_FLAG = 'Y' -- Condition included for defect id 11471
                                  AND E.MCCODE = P_ARRAY (I);
                                 
                                  
                                  BEGIN
                                  IF (V_RULECARDTYPE_STATUS = 'Y' AND P_ARRAY.COUNT = 1   ) THEN
                                 
                                    P_ERRMSG := 'MCC already attached to the Rule';
                                    V_RESPCODE:= '176';
                                    RAISE EXP_MAIN_REJECT_RECORD;
                                  ELSE IF( V_RULECARDTYPE_STATUS = 'Y' AND V_INCR_CMT = P_ARRAY.COUNT) THEN
                                    P_ERRMSG := 'MCC''s already attached to the Rule';
                                    V_RESPCODE:= '178';
                                    RAISE EXP_MAIN_REJECT_RECORD;
                                  END IF;
                                  END IF;
                                  EXCEPTION
                                  WHEN EXP_MAIN_REJECT_RECORD THEN
                                  RAISE EXP_MAIN_REJECT_RECORD;
                                  END;
                                  
          
                    
                                  IF V_RULECARDTYPE_STATUS = 'N' THEN 
                                  
                                     V_FLAG := 'Y';
                                       
                                    BEGIN
                                     
                                     
                                    
                                      INSERT INTO MCCODE_GROUP(MCCODE,MCCODEGROUPID,MCC_INST_CODE,MCC_INS_DATE,MCC_INS_USER)
                                      VALUES(p_array (i),V_MCCGRP_ID,P_INSTCODE,SYSDATE,P_USER_ID);
                                    
                                        
                                            IF (SQL%ROWCOUNT =1)  THEN -- added mvhost -386
                                            
                                             P_MCC_OUT (i) := p_array (i);
                                             
                                            END IF;
                                    
                                    EXCEPTION
                                    WHEN OTHERS THEN
                                    V_RESPCODE := '21';
                                    P_ERRMSG  := 'Error while inserting records in MCCODE_GROUP-1'||SUBSTR(SQLERRM,1,200);
                                      RAISE EXP_MAIN_REJECT_RECORD;
                                    END;
  
                                END IF;
                                  
                                           
                            EXCEPTION
                          
                                  WHEN NO_DATA_FOUND THEN
                                 
                                      BEGIN
                                      
                                            -- P_MCC_OUT (i) := p_array (i);
                                            
                                            INSERT INTO MCCODE_GROUP(MCCODE,MCCODEGROUPID,MCC_INST_CODE,MCC_INS_DATE,MCC_INS_USER)
                                            VALUES(P_ARRAY (I),V_MCCGRP_ID,P_INSTCODE,SYSDATE,P_USER_ID);
                                            V_FLAG := 'Y';
                                            
                                            IF (SQL%ROWCOUNT =1)  THEN -- added mvhost -386
                                            
                                             P_MCC_OUT (i) := p_array (i);
                                             
                                            END IF;
                                      
                                      EXCEPTION
                                      WHEN OTHERS THEN
                                          V_RESPCODE := '21';
                                          P_ERRMSG  := 'Error while inserting records in MCCODE_GROUP-2'||SUBSTR(SQLERRM,1,200);
                                      
                                      END;
                                
                                  --CONTINUE; // commented for Defect Id's-11404,11405
                                  WHEN EXP_MAIN_REJECT_RECORD THEN
                                  RAISE EXP_MAIN_REJECT_RECORD;
                                  WHEN OTHERS THEN
                                  V_RESPCODE := '21';
                                  P_ERRMSG  := ' Error: '||SUBSTR(SQLERRM,1,200);
                                  END;
         
                  
                                        
                  END LOOP;
                  
                  IF V_FLAG = 'Y' THEN
                    
                        BEGIN
                            UPDATE PCMS_PRODCATTYPE_RULEGROUP
                            SET PPR_ACTIVE_FLAG =V_FLAG
                            WHERE ppr_prod_code = P_PROD_CODE
                            AND PPR_CARD_TYPE = P_PRODUCT_CATEGORY
                            AND PPR_PERMRULE_FLAG = 'Y' ;-- Condition included for defect id 11471

                        EXCEPTION
                       
                        WHEN OTHERS THEN
                            V_RESPCODE := '12';
                            P_ERRMSG   := 'Error ' || SUBSTR(SQLERRM, 1, 200);
                    
                        END;
                  
                  END IF;
                  
             
            EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD THEN
              RAISE EXP_MAIN_REJECT_RECORD;
            WHEN OTHERS THEN
              V_RESPCODE := '21';
              P_ERRMSG  := 'Error while selecting rulcnt from product'|| SUBSTR(SQLERRM, 1, 200);
           
          END;
          --EN14
          
          --SN 15 If a rule is already attached and if AddOrDelete flag is "D" , then delete the MCC recicved from the existing rule
          ELSE IF P_ADDORDELETE_FLAG ='D' 
               THEN
               
                  BEGIN
                  
                  
                      SELECT e.mccodegroupid,A.ppr_rulegroup_code  -- Added for Defect Id:11405
                      INTO V_MCCGRP_ID,V_RULEGRP_ID
                      FROM PCMS_PRODCATTYPE_RULEGROUP A, RULECODE_GROUP B  , RULE D , MCCODEGROUPING E 
                      WHERE A.ppr_rulegroup_code = B.rulegroupid
                      AND b.ruleid = D.ruleid
                      AND D.MCCGROUPID = E.MCCODEGROUPID
                      AND a.ppr_prod_code =P_PROD_CODE
                      AND A.PPR_CARD_TYPE =P_PRODUCT_CATEGORY
                      AND A.PPR_PERMRULE_FLAG = 'Y' -- Condition included for defect id 11471
                      AND ROWNUM <2;
                      
                      V_MCCODEGROUPID := V_MCCGRP_ID; -- Added for Defect Id:11404
                      V_RULEGROUPID := V_RULEGRP_ID;
                  
                  EXCEPTION
                  WHEN OTHERS THEN
                      V_RESPCODE := '21';
                      P_ERRMSG  := 'Error while fetching mccodegroupid during mcc deletion'|| SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_MAIN_REJECT_RECORD;
                  END;
               
                 BEGIN
                  FOR i IN 1 .. p_array.COUNT
                  LOOP
                          
                    BEGIN
                        
                        SELECT COUNT(MCCODE) 
                        INTO V_MCCGRP_COUNT
                        FROM MCCODE_GROUP
                        WHERE MCCODEGROUPID = V_MCCGRP_ID
                        AND MCCODE =  p_array (i);
                        
                        IF V_MCCGRP_COUNT = 0 THEN
                        
                        V_INCR_CMT := V_INCR_CMT + 1;
                        
                        END IF;
                        
                    EXCEPTION
                    WHEN OTHERS THEN
                        V_RESPCODE := '21';
                        P_ERRMSG  := 'Error while fetching the existing mcc'||SUBSTR(SQLERRM,1,200);
                    RAISE EXP_MAIN_REJECT_RECORD;
                    END;
                    
                     BEGIN
                           
                            DELETE FROM MCCODE_GROUP
                            WHERE  MCCODEGROUPID=V_MCCGRP_ID  --Added for the defect id :11403,11451 on 04/07/13
                            AND mccode = p_array (i);

                        IF (SQL%ROWCOUNT =1)  THEN

                             P_MCC_OUT (i) := p_array (i); -- added mvhost -386
                             
                        ELSE IF (SQL%ROWCOUNT =0 AND p_array.COUNT = 1  ) THEN
                            P_ERRMSG := 'MCC not attached to the Rule';
                            V_RESPCODE:= '177';
                              RAISE EXP_MAIN_REJECT_RECORD;
                        ELSE IF( V_INCR_CMT = P_ARRAY.COUNT) THEN
                            P_ERRMSG := 'MCC''s not attached to the Rule';
                            V_RESPCODE:= '179';
                              RAISE EXP_MAIN_REJECT_RECORD;
                        
                        --ELSE // commented for Defect Id's-11404,11405
                           -- CONTINUE; // commented for Defect Id's-11404,11405
                        END IF;
                        END IF;
                        END IF;
                        EXCEPTION
                        WHEN EXP_MAIN_REJECT_RECORD THEN
                            RAISE EXP_MAIN_REJECT_RECORD;
                        WHEN OTHERS THEN
                            V_RESPCODE := '12';
                            V_RESPCODE   := 'Error ' || SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_MAIN_REJECT_RECORD;
                        END;
                    
                   END LOOP;
                   
                   BEGIN
                   
                   SELECT COUNT(1)
                   INTO V_MCCDEL_COUNT
                   FROM MCCODE_GROUP
                   WHERE mccodegroupid = V_MCCGRP_ID;
                   
                   EXCEPTION
                        WHEN EXP_MAIN_REJECT_RECORD THEN
                            RAISE EXP_MAIN_REJECT_RECORD;
                        WHEN OTHERS THEN
                            V_RESPCODE := '12';
                            P_ERRMSG   := 'Error ' || SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_MAIN_REJECT_RECORD;
                   END;
                   
                   IF V_MCCDEL_COUNT = 0 THEN
                   
                              BEGIN
                                    UPDATE PCMS_PRODCATTYPE_RULEGROUP
                                    SET PPR_ACTIVE_FLAG ='N'
                                    WHERE ppr_prod_code = P_PROD_CODE
                                    AND PPR_CARD_TYPE = P_PRODUCT_CATEGORY
                                    AND PPR_PERMRULE_FLAG = 'Y'; -- Condition included for defect id 11471


                              EXCEPTION
                              WHEN OTHERS THEN
                                    V_RESPCODE := '12';
                                    P_ERRMSG   := 'Error ' || SUBSTR(SQLERRM, 1, 200);
                               RAISE EXP_MAIN_REJECT_RECORD;
                              END;
                   
                     END IF;
                 
                  END;
                      -- added for ListMCC rules.                                  
          ELSE IF  P_ADDORDELETE_FLAG ='V'  THEN
          
                        BEGIN
                                  SELECT e.mccodegroupid
                                  INTO V_MCCGRP_ID
                                  FROM PCMS_PRODCATTYPE_RULEGROUP A, RULECODE_GROUP B  , RULE D , MCCODEGROUPING E 
                                  WHERE A.ppr_rulegroup_code = B.rulegroupid
                                  AND b.ruleid = D.ruleid
                                  AND D.MCCGROUPID = E.MCCODEGROUPID
                                  AND a.ppr_prod_code =P_PROD_CODE
                                  AND A.PPR_CARD_TYPE =P_PRODUCT_CATEGORY
                                  AND A.PPR_PERMRULE_FLAG = 'Y' 
                                  AND ROWNUM <2;
                                                             
                        EXCEPTION 
                              WHEN NO_DATA_FOUND THEN -- not required to decline the transaction in case of permissive rule not attached at product category.
                                  P_ERRMSG  := 'Permissive MCC rules are not attached';
                                                             
                              WHEN OTHERS THEN
                                  V_RESPCODE := '21';
                                  P_ERRMSG  := 'Error while fetching mccodegroupid during mcc deletion'|| SUBSTR(SQLERRM, 1, 200);
                              RAISE EXP_MAIN_REJECT_RECORD;
                         END;
                  
                       IF V_MCCGRP_ID IS NULL THEN
                         
                          P_ERRMSG  := 'Permissive MCC rules are not attached';
                         
                       
                       ELSE
                       
                       FOR V IN MCCCODE 
                       loop
                         
                         P_LIST_MCC :=P_LIST_MCC ||V.MCC;
                           
                       END LOOP;
                                             
                       END IF;
          
          END IF;
                           
              END IF;
         
         END IF;
      
    END IF;
    --EN15
    
       BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
    
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
                                    BANK_CODE,
                                    PRODUCTID,
                                    CATEGORYID,
                                    INSTCODE,
                                    ACCT_BALANCE,
                                    LEDGER_BALANCE,
                                    RESPONSE_ID,
                                    TRANS_DESC,
                                    CR_DR_FLAG,
                                    MEDAGATEREF_ID,
                                    ERROR_MSG,
                                    MCCODEGROUPID,
                                    MCC_ADDORDEL_FLAG,
                                    RULEGROUPID, -- added for Defect Id:11405
                                    time_stamp  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                                   )
                            VALUES
                                  ('0200',
                                  P_RRN,
                                  P_DELIVERY_CHANNEL,
                                  0,
                                  P_TXN_CODE,
                                  V_TXN_TYPE,
                                  0,
                                  DECODE(P_RESP_CODE, '00', 'C', 'F'),
                                  P_RESP_CODE,
                                  P_TRANDATE,
                                  SUBSTR(P_TRANTIME, 1, 10),
                                  P_INSTCODE,
                                  P_PROD_CODE,
                                  P_PRODUCT_CATEGORY,
                                  P_INSTCODE,
                                  0,
                                  0,
                                  V_RESPCODE,
                                  V_TRANS_DESC ,
                                  V_CRDR_FLAG,
                                  P_MEDAGATE_REF_ID,
                                  P_ERRMSG,
                                  V_MCCODEGROUPID,
                                  P_ADDORDELETE_FLAG,
                                  V_RULEGROUPID,  -- added for Defect Id:11405
                                  systimestamp  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                                  );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;
       -- added for Defect Id's-11404,11405
    BEGIN
      INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, 
                      ctd_txn_code, 
                      ctd_msg_type,
                      ctd_txn_mode,
                      ctd_business_date,
                      ctd_business_time,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn, 
                      ctd_inst_code                   
                     )
              VALUES (p_delivery_channel,
                      p_txn_code,
                      '0200',
                      0,
                      p_trandate,
                      p_trantime,
                     'Y',
                      'Successful',
                      P_RRN,
                      p_instcode
                     );
     EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG DTL' || SUBSTR(SQLERRM, 1, 200);
    END;
        
    
    
EXCEPTION    
     WHEN EXP_MAIN_REJECT_RECORD THEN
       ROLLBACK;
         BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
        
        --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_crdr_flag IS NULL THEN
        BEGIN
        SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
               ctm_credit_debit_flag
          INTO v_txn_type, v_trans_desc,
               v_crdr_flag
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS
           THEN
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
                                    TXN_CODE,
                                    TXN_TYPE,
                                    TXN_MODE,
                                    TXN_STATUS,
                                    RESPONSE_CODE,
                                    BUSINESS_DATE,
                                    BUSINESS_TIME,
                                    BANK_CODE,
                                    PRODUCTID,
                                    CATEGORYID,
                                    INSTCODE,
                                    ACCT_BALANCE,
                                    LEDGER_BALANCE,
                                    RESPONSE_ID,
                                    TRANS_DESC,
                                    CR_DR_FLAG,
                                    MEDAGATEREF_ID,
                                    ERROR_MSG,
                                    MCCODEGROUPID,
                                    MCC_ADDORDEL_FLAG,
                                    time_stamp  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                                    )
                            VALUES
                                  ('0200',
                                  P_RRN,
                                  P_DELIVERY_CHANNEL,
                                  0,
                                  P_TXN_CODE,
                                  V_TXN_TYPE,
                                  0,
                                  DECODE(P_RESP_CODE, '00', 'C', 'F'),
                                  P_RESP_CODE,
                                  P_TRANDATE,
                                  SUBSTR(P_TRANTIME, 1, 10),
                                  P_INSTCODE,
                                  P_PROD_CODE,
                                  P_PRODUCT_CATEGORY,
                                  P_INSTCODE,
                                  0,
                                  0,
                                  V_RESPCODE,
                                  V_TRANS_DESC ,
                                  V_CRDR_FLAG,
                                  P_MEDAGATE_REF_ID,
                                  P_ERRMSG,
                                  V_MCCODEGROUPID,
                                  P_ADDORDELETE_FLAG,
                                  systimestamp  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                                  );
                            
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;
        
                -- added for Defect Id's-11404,11405
        BEGIN
          INSERT INTO cms_transaction_log_dtl
                         (ctd_delivery_channel, 
                          ctd_txn_code, 
                          ctd_msg_type,
                          ctd_txn_mode,
                          ctd_business_date,
                          ctd_business_time,
                          ctd_process_flag,
                          ctd_process_msg,
                          ctd_rrn, 
                          ctd_inst_code                       
                         )
                  VALUES (p_delivery_channel,
                          p_txn_code,
                          '0200',
                          0,
                          p_trandate,
                          p_trantime,
                         'E',
                          P_ERRMSG,
                          P_RRN,
                          p_instcode
                         );
         EXCEPTION
                WHEN OTHERS THEN
                    P_RESP_CODE := '89';
                    P_ERRMSG    := 'Error while inserting TRANSACTIONLOG DTL' || SUBSTR(SQLERRM, 1, 200);
        END;
    
     WHEN OTHERS THEN
       ROLLBACK;
       
       BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
        
        --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_crdr_flag IS NULL THEN
        BEGIN
        SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
               ctm_credit_debit_flag
          INTO v_txn_type, v_trans_desc,
               v_crdr_flag
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS
           THEN
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
                                    TXN_CODE,
                                    TXN_TYPE,
                                    TXN_MODE,
                                    TXN_STATUS,
                                    RESPONSE_CODE,
                                    BUSINESS_DATE,
                                    BUSINESS_TIME,
                                    BANK_CODE,
                                    PRODUCTID,
                                    CATEGORYID,
                                    INSTCODE,
                                    ACCT_BALANCE,
                                    LEDGER_BALANCE,
                                    RESPONSE_ID,
                                    TRANS_DESC,
                                    CR_DR_FLAG,
                                    MEDAGATEREF_ID,
                                    ERROR_MSG,
                                    MCCODEGROUPID,
                                    MCC_ADDORDEL_FLAG,
                                    time_stamp  --Added by Pankaj S. for logging changes(Mantis ID-13160) 
                                    )
                            VALUES
                                  ('0200',
                                  P_RRN,
                                  P_DELIVERY_CHANNEL,
                                  0,
                                  P_TXN_CODE,
                                  V_TXN_TYPE,
                                  0,
                                  DECODE(P_RESP_CODE, '00', 'C', 'F'),
                                  P_RESP_CODE,
                                  P_TRANDATE,
                                  SUBSTR(P_TRANTIME, 1, 10),
                                  P_INSTCODE,
                                  P_PROD_CODE,
                                  P_PRODUCT_CATEGORY,
                                  P_INSTCODE,
                                  0,
                                  0,
                                  V_RESPCODE,
                                  V_TRANS_DESC ,
                                  V_CRDR_FLAG,
                                  P_MEDAGATE_REF_ID,
                                  P_ERRMSG,
                                  V_MCCODEGROUPID,
                                  P_ADDORDELETE_FLAG,
                                  systimestamp  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                                  );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;
                  -- added for Defect Id's-11404,11405
        BEGIN
          INSERT INTO cms_transaction_log_dtl
                         (ctd_delivery_channel, 
                          ctd_txn_code, 
                          ctd_msg_type,
                          ctd_txn_mode,
                          ctd_business_date,
                          ctd_business_time,
                          ctd_process_flag,
                          ctd_process_msg,
                          ctd_rrn, 
                          ctd_inst_code                           
                         )
                  VALUES (p_delivery_channel,
                          p_txn_code,
                          '0200',
                          0,
                          p_trandate,
                          p_trantime,
                         'E',
                          P_ERRMSG,
                          P_RRN,
                          p_instcode
                         );
         EXCEPTION
                WHEN OTHERS THEN
                    P_RESP_CODE := '89';
                    P_ERRMSG    := 'Error while inserting TRANSACTIONLOG DTL' || SUBSTR(SQLERRM, 1, 200);
        END;
END;
/
SHOW ERROR;