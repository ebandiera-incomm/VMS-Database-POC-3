CREATE OR REPLACE PROCEDURE VMSCMS.SP_PRECHECK_TXN(PRM_INST_CODE        IN NUMBER,
                                    PRM_CARD_NUMBER      IN VARCHAR2,
                                    PRM_DELIVERY_CHANNEL IN VARCHAR2,
                                    PRM_EXPRY_DATE       IN DATE,
                                    PRM_CARD_STAT        IN VARCHAR2,
                                    PRM_TRAN_CODE        IN VARCHAR2,
                                    PRM_TRAN_MODE        IN VARCHAR2,
                                    PRM_TRAN_DATE        IN VARCHAR2,
                                    PRM_TRAN_TIME        IN VARCHAR2,
                                    PRM_TXN_AMT          IN NUMBER,
                                    PRM_ATMONLINE_LIMIT  IN NUMBER,
                                    PRM_POSONLINE_LIMIT  IN NUMBER,
                                    PRM_RESP_CODE        OUT VARCHAR2,
                                    PRM_RESP_MSG         OUT varchar2) is
                                    
/*************************************************************************************************************

       * modified by       :  Santosh K
       * modified Date     :  13-Nov-13
       * modified reason   :  PROD FIX for Replacement of MIO Expired Card
       * Reviewer          :  Dhiraj
       * Reviewed Date     :  13-Nov-13
       * Build Number      :  RI0024.3.10_B0002

       * Modified By      : Dnyaneshwar J
       * Modified Date    : 14-Jan-2014
       * Modified Reason  : MVCSD-4637
       * Reviewer         : Dhiraj
       * Reviewed Date    : 14-Jan-2014
       * Build Number     : RI0027_B0003

       * Modified By      : Dnyaneshwar J
       * Modified Date    : 11-Feb-2014
       * Modified Reason  : Mantis-13655
       * Build Number     : RI0027_B0007
       
       * Modified by      : MageshKumar S.
       * Modified Date    : 25-July-14    
       * Modified For     : FWR-48
       * Modified reason  : GL Mapping removal changes
       * Reviewer         : Spankaj
       * Build Number     : Ri0027.3.1_B0001
       
       * Modified by      : Pankaj S.
       * Modified For     : ACH canada changes
       * Build Number     : Ri0027.4.3
       
       * Modified by       : A.Sivakaminathan
       * Modified Date     : 28-Aug-2015
       * Modified For      : FSS-3615 VMS should allow address changes even after the card expired
       * Reviewer          : Pankaj S
       * Build Number      : VMSGPRHOSTCSD_3.1   
       
       * Modified by      : MageshKumar S
       * Modified for     : GPR Card Status Check Moved to Java
       * Modified Date    : 27-JAN-2016
       * Reviewer         : Saravanankumar/SPankaj
       * Build Number     : VMSGPRHOST_4.0_B0001
       
       * Modified by      : MageshKumar S
       * Modified for     : Mantis:16291
       * Modified Date    : 10-Mar-2016
       * Reviewer         : Saravanankumar/SPankaj
       * Build Number     : VMSGPRHOST_4.0_B0002

*************************************************************************************************************/
  V_TRAN_DATE        DATE;
  V_CHECK_STATCNT    NUMBER;
  V_LIMIT_CHECK      VARCHAR2(1);
  V_ATMPOS_FLAG      VARCHAR2(1);
  V_LIMIT_TYPE       VARCHAR2(1);
  V_DAILYTRAN_CNT    NUMBER(2);
  V_DAILYTRAN_LIMIT  NUMBER(6);
  V_WEEKLYTRAN_CNT   NUMBER(2);
  V_WEEKLYTRAN_LIMIT NUMBER(6);
 -- V_TXN_CODE         CMS_FUNC_MAST.CFM_TXN_CODE%TYPE; --commented for fwr - 48
  V_TXN_CODE         VARCHAR2(2) default 'RN'; -- Added for fwr - 48
  V_HASH_PAN         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;

BEGIN
  --<< MAIN BEGIN >>  
  --SN CREATE HASH PAN 
/*  BEGIN
    V_HASH_PAN := GETHASH(PRM_CARD_NUMBER);
  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_MSG := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;*/
  --EN CREATE HASH PAN

  --Sn convert tran date
  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(PRM_TRAN_TIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '22';
     PRM_RESP_MSG  := 'Problem while converting transaction date ' ||
                   SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  --En convert tran date
  --if PRM_DELIVERY_CHANNEL <> '11' then 
 -- if PRM_DELIVERY_CHANNEL NOT IN ('11','15') then   --Added by Pankaj S. for ACH canada changes
 
  if PRM_DELIVERY_CHANNEL = '03' then
  
  -- SN:Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
  if PRM_DELIVERY_CHANNEL = '03' and PRM_TRAN_CODE in ('22','29','75','13','14','38','39','83','17','27','37','35','21','79','18','74','98','78') then--Modified by Dnyaneshwar J on 14 Jan 2014 for MVCSD-4637--Modified by Dnyaneshwar J on 11 Feb 2014 For Mantis-13655
    PRM_RESP_CODE := '1';
  else
   -- EN:Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
  --Sn check expry date
  IF LAST_DAY(PRM_EXPRY_DATE) < TO_CHAR(V_TRAN_DATE, 'DD-MON-YY') THEN
  
  --SN - commented for fwr - 48
    --Sn check tran code for renew
  /*  BEGIN
     SELECT CFM_TXN_CODE
       INTO V_TXN_CODE
       FROM CMS_FUNC_MAST
      WHERE CFM_INST_CODE = PRM_INST_CODE AND CFM_FUNC_CODE = 'RENEW';
    
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       PRM_RESP_CODE := '69';
       PRM_RESP_MSG  := 'Support function renew not defined in master ';
       RETURN;
     WHEN OTHERS THEN
       PRM_RESP_CODE := '69';
       PRM_RESP_MSG  := 'Problem while getting renew support func' ||
                    SUBSTR(SQLERRM, 1, 200);
       RETURN;
    END; */
    
    --SN - commented for fwr - 48
  
    IF V_TXN_CODE = PRM_TRAN_CODE THEN
     --En check tran code for renew
     NULL;
    ELSE
     PRM_RESP_CODE := '13'; --Ineligible Transaction
     PRM_RESP_MSG  := 'EXPIRED CARD';
     RETURN;
    END IF;
  
  end if;
  
  end if;  -- Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
  
  end if;
  --En check expry date
  --Sn check card stat
  if PRM_DELIVERY_CHANNEL NOT IN ('01','02') then  
  BEGIN
    SELECT COUNT(1)
     INTO V_CHECK_STATCNT
     FROM PCMS_VALID_CARDSTAT
    WHERE PVC_INST_CODE = PRM_INST_CODE AND PVC_CARD_STAT =  trim(PRM_CARD_STAT)  AND
         PVC_TRAN_CODE = PRM_TRAN_CODE AND
         PVC_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL;
    IF V_CHECK_STATCNT = 0 THEN
     PRM_RESP_CODE := '10'; --Ineligible Transaction
     PRM_RESP_MSG  := 'Invalid Card Status';
     RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '21';
     PRM_RESP_MSG  := 'Problem while selecting card stat ' ||
                   SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  end if; --ols changes for mantis-16291
  --En check card stat
  --Sn check transaction limit
/*  BEGIN
    SELECT PTLP_LIMICHECK_FLAG, PTLP_ONLINELIMIT_ATMPOS_FLAG
     INTO V_LIMIT_CHECK, V_ATMPOS_FLAG
     FROM PCMS_TRAN_LIMITCHECK_PARAM --ISO TRANSACTION CODE
    WHERE PTLP_INST_CODE = PRM_INST_CODE AND
         PTLP_TRAN_CODE = PRM_TRAN_CODE AND
         PTLP_TRAN_MODE = PRM_TRAN_MODE AND
         PTLP_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL;
    IF V_LIMIT_CHECK = '1' AND V_ATMPOS_FLAG = '1' THEN
     IF PRM_TXN_AMT > PRM_ATMONLINE_LIMIT THEN
       PRM_RESP_CODE := '17';
       PRM_RESP_MSG  := 'Exceed ATM withdrawal limit';
       RETURN;
     END IF;
    ELSE
     IF V_LIMIT_CHECK = '1' AND V_ATMPOS_FLAG = '0' THEN
       IF PRM_TXN_AMT > PRM_POSONLINE_LIMIT THEN
        PRM_RESP_CODE := '17';
        PRM_RESP_MSG  := 'Exceed POS withdrawal limit';
        RETURN;
       END IF;
     END IF;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;
     --- atm and pos limit is not defined for this transaction  so no check...
  
    WHEN OTHERS THEN
     PRM_RESP_CODE := '21';
     PRM_RESP_MSG  := 'Error while selecting atm and pos withdrawal limit ' ||
                   SUBSTR(SQLERRM, 1, 300);
     RETURN;
  END;
  --En check transaction limit
  -- Sn daily or weekly transaction limit and amount limit
  --Sn find limit check flag
  BEGIN
    SELECT PTP_PARAM_VALUE
     INTO V_LIMIT_TYPE
     FROM PCMS_TRANAUTH_PARAM
    WHERE PTP_INST_CODE = PRM_INST_CODE AND PTP_PARAM_NAME = 'LIMIT CHECK';
    IF V_LIMIT_TYPE = 'D' THEN
     --Sn check daily limit
     BEGIN
       SELECT CAT_MAXDAILY_TRANCNT, CAT_MAXDAILY_TRANAMT
        INTO V_DAILYTRAN_CNT, V_DAILYTRAN_LIMIT
        FROM CMS_AVAIL_TRANS --ISO TRANSACTION CODE
        WHERE CAT_INST_CODE = PRM_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN --prm_card_number
            AND CAT_TRAN_CODE = PRM_TRAN_CODE AND
            CAT_TRAN_MODE = PRM_TRAN_MODE;
       IF V_DAILYTRAN_CNT <= 0 THEN
        PRM_RESP_CODE := '18';
        PRM_RESP_MSG  := 'Daily limit check counter exceeded';
        RETURN;
       END IF;
       IF PRM_TXN_AMT > V_DAILYTRAN_LIMIT THEN
        PRM_RESP_CODE := '19';
        PRM_RESP_MSG  := 'Daily limit check limit exceeded';
        RETURN;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        NULL; --LIMIT is not defined for this card so no check
       WHEN OTHERS THEN
        PRM_RESP_CODE := '21';
        PRM_RESP_MSG  := 'Error while selecting daily limit check ' ||
                      SUBSTR(SQLERRM, 1, 300);
        RETURN;
     END;
     --Sn check daily limit
    ELSE
     IF V_LIMIT_TYPE = 'W' THEN
       --Sn check weekly limit
       BEGIN
        SELECT CAT_MAXDAILY_TRANCNT, CAT_MAXDAILY_TRANAMT
          INTO V_WEEKLYTRAN_CNT, V_WEEKLYTRAN_LIMIT
          FROM CMS_AVAIL_TRANS --ISO TRANSACTION CODE
         WHERE CAT_INST_CODE = PRM_INST_CODE AND
              CAT_INST_CODE = PRM_INST_CODE AND
              CAT_PAN_CODE = V_HASH_PAN -- prm_card_number
              AND CAT_TRAN_CODE = PRM_TRAN_CODE AND
              CAT_TRAN_MODE = PRM_TRAN_MODE;
        IF V_DAILYTRAN_CNT <= 0 THEN
          PRM_RESP_CODE := '18';
          PRM_RESP_MSG  := 'Weekly limit check counter exceeded';
          RETURN;
        END IF;
        IF PRM_TXN_AMT > V_WEEKLYTRAN_LIMIT THEN
          PRM_RESP_CODE := '19';
          PRM_RESP_MSG  := 'Weekly limit check limit exceeded';
          RETURN;
        END IF;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; --LIMIT is not defined for this card so no check
        WHEN OTHERS THEN
          PRM_RESP_CODE := '21';
          PRM_RESP_MSG  := 'Error while selecting weekly limit check ' ||
                        SUBSTR(SQLERRM, 1, 300);
          RETURN;
       END;
       --Sn check weekly limit
     END IF;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL; --Limit type is not defined for this institute
    WHEN TOO_MANY_ROWS THEN
     PRM_RESP_CODE := '21';
     PRM_RESP_MSG  := 'More than one limit check type is defined for this Institute ';
  END; */
  --En find limit check flag
  -- En daily or weekly transaction limit and amount limit
  PRM_RESP_CODE := '1';
  PRM_RESP_MSG  := 'OK';
EXCEPTION
  --<< MAIN EXCEPTION>>
  WHEN OTHERS THEN
    PRM_RESP_CODE := '21';
    PRM_RESP_MSG  := 'Error while processing precheck - expiry period-' ||
                 V_TRAN_DATE || ' ' || SUBSTR(SQLERRM, 1, 300);
END; --<< MAIN END >>
/
SHOW ERROR;