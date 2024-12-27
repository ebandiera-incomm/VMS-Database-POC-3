create or replace
PROCEDURE      VMSCMS.SP_PREAUTHORIZE_TXN(PRM_CARD_NO          IN VARCHAR2,
                                       PRM_MCC_CODE         IN VARCHAR2,
                                       PRM_CURR_CODE        IN VARCHAR2,
                                       PRM_TRAN_DATETIME    IN DATE,
                                       PRM_TRAN_CODE        IN VARCHAR2,
                                       PRM_INST_CODE        IN NUMBER,
                                       PRM_TRAN_DATE        IN VARCHAR2,
                                       PRM_TXN_AMT          IN VARCHAR2,
                                       PRM_DELIVERY_CHANNEL IN VARCHAR2,  --prm_delivery_channel variable Datatype changed from Number to varchar2  22092012 Dhiraj Gaikwad
                                       PRM_ERR_CODE         OUT VARCHAR2,
                                       PRM_ERR_MSG          OUT VARCHAR2,
                                       PRM_MERCHANT_ID      IN   VARCHAR2   DEFAULT NULL, --Added for FSS-2281
                                       PRM_CNTRYCODE IN   VARCHAR2   DEFAULT NULL --Added for FSS-2281
                                       ,PRM_acqinstcntrycode_in IN   VARCHAR2   DEFAULT NULL
                                       ) IS
   /*************************************************
     * Modified By      :  Dhiraj Gaikwad
     * Modified Date    :  26-SEP-2012
     * Modified Reason  :  Changes for Allowing Active first rule group ruleids Validations only
      * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  26-SEP-2012
     * Build Number     :  CMS3.5.1_RI0017.1

	 * Modified By      :  Ramesh
     * Modified Date    :  20-JUN-2013
     * Modified Reason  :  MVHOST(392)
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  21-JUN-2013
     * Build Number     :  RI0024.2_B0006
	 
     * Modified By      :  Ramesh
     * Modified Date    :  04-JULY-2013
     * Modified Reason  :  11471
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0024.3_B0003
     
     * Modified Date    : 23-Mar-2015
     * Modified By      : Ramesh A
     * Modified for     : FSS-2281 and mantis id:15901
     * Reviewer         : Spankaj
     * Release Number   : 3.0

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R08 

 *************************************************/
  V_RULECNT_CARD     NUMBER(3);
  V_RULECNT_PRODUCT  NUMBER(3);
  V_RULECNT_CARDTYPE NUMBER(3);
  V_PROD_CODE        CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_ERR_FLAG         VARCHAR2(3);
  V_ERR_MSG          VARCHAR2(900);
  V_AUTH_TYPE        VARCHAR2(1);
  V_USAGE_TYPE       VARCHAR2(1);
  V_FROM_TIME        VARCHAR2(5);
  V_TO_TIME          VARCHAR2(5);
  V_FROM_DATE        DATE;
  V_TO_DATE          DATE;
  V_TRAN_TIME        DATE;
  V_NOOF_TXN_ALLOWED NUMBER;
  V_TOTAL_AMT_LIMIT  VARCHAR2(12);
 PRM_1ST_GRPVRFED number (2):=0 ; -- added by Dhiraj Gaikwad on 26092012
  TYPE T_RULECODETYPE IS REF CURSOR;

  CUR_RULECODE    T_RULECODETYPE;
  V_SQL_STMT      VARCHAR2(500);
  V_RULEGROUPCODE PCMS_CARD_EXCP_RULEGROUP.PCER_RULEGROUP_ID%TYPE;
  V_GROUPCODE     RULE.MCCGROUPID%TYPE;
  V_HASH_PAN      CMS_APPL_PAN.CAP_PAN_CODE%TYPE;

 --Added for MVHOST-392 on 18/06/2013
   v_active_flag          varchar2(1) default 'Y';
   v_rulegroup_code       pcms_prodcattype_rulegroup.PPR_RULEGROUP_CODE%type;
   v_check_mcc_cnt        NUMBER (1);

 /*
 Commented by Dhiraj G on 25092012

 CURSOR C(P_RULGROUP IN VARCHAR2) IS
    SELECT RULEID FROM RULECODE_GROUP WHERE RULEGROUPID = P_RULGROUP;
*/
CURSOR C(P_RULGROUP IN VARCHAR2) IS
SELECT a.ruleid
  FROM rulecode_group a, rulegrouping b
 WHERE a.rulegroupid = P_RULGROUP
   AND a.rulegroupid = b.rulegroupid
   AND b.activationstatus = 'Y' ;


  CURSOR C1(P_RULEID IN VARCHAR2) IS
    SELECT * FROM RULE WHERE RULEID = P_RULEID AND activationstatus = 'Y';-- Added by Dhiraj Gaikwad on 12062012 as we need to apply only the rule which are active;
BEGIN
  PRM_ERR_CODE := '1';
  PRM_ERR_MSG  := 'OK';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  --EN CREATE HASH PAN

 --ST: Added for MVHOST-392 on 18/06/2013
    BEGIN
            SELECT cap_prod_code, cap_card_type
              INTO V_PROD_CODE, V_PROD_CATTYPE
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_err_code := '21';
               prm_err_msg := ' No record found for the card number ';
               RETURN;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                     ' Error while selecting CMS_APPL_PAN  '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
     IF PRM_DELIVERY_CHANNEL = '02' THEN
      BEGIN
            SELECT PPR_RULEGROUP_CODE
              INTO v_rulegroup_code
              FROM pcms_prodcattype_rulegroup
             WHERE ppr_prod_code = V_PROD_CODE
               AND ppr_card_type = V_PROD_CATTYPE and PPR_ACTIVE_FLAG='Y' 
               and PPR_PERMRULE_FLAG='Y'; --Added for defect id: 11471 on 04/07/2013
             
         EXCEPTION
         WHEN NO_DATA_FOUND
          THEN
             NULL;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                           'Error while selecting rulcnt from cardtype level'||SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

      IF v_rulegroup_code is not null then

            BEGIN
               --Sn select rule from cardtype
              select count(*) into v_check_mcc_cnt from rulecode_group a, rulegrouping b,rule c, mccode_group d
              where  a.rulegroupid = b.rulegroupid AND b.activationstatus = 'Y'
              and a.ruleid =c.ruleid and c.mccgroupid= d.mccodegroupid and c.authtype='A'
              and a.rulegroupid=v_rulegroup_code  AND d.mccode = prm_mcc_code;


            IF v_check_mcc_cnt = 1  THEN
                prm_err_code := '1';
                prm_err_msg := 'OK';
            ELSE
                prm_err_code := '70';
                prm_err_msg := 'Invalid merchant code';
                RETURN;
            END IF;

            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                            'Error while selecting rulegroup  at  card level'||SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         END IF;
      END IF;
   --END: Added for MVHOST-392 on 18/06/2013

  --Sn find rules attached at card level or prodcattype level
  BEGIN
    SELECT COUNT(1)
     INTO V_RULECNT_CARD
     FROM PCMS_CARD_EXCP_RULEGROUP
    WHERE PCER_PAN_CODE = V_HASH_PAN
         AND TRUNC(PRM_TRAN_DATETIME) BETWEEN TRUNC(PCER_VALID_FROM) AND
         TRUNC(PCER_VALID_TO);

    IF V_RULECNT_CARD = 0 THEN
    /* Commented for MVHOST-391 on 18/06/2013
     --Sn rule may be attached at cardtype level
     BEGIN
       SELECT CAP_PROD_CODE, CAP_CARD_TYPE
        INTO V_PROD_CODE, V_PROD_CATTYPE
        FROM CMS_APPL_PAN
        WHERE CAP_PAN_CODE = V_HASH_PAN;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        PRM_ERR_CODE := '21';--Modified by Deepa on Apr-30-2012 for the response code change
        PRM_ERR_MSG  := ' No record found for the card number ';
        RETURN;
       WHEN OTHERS THEN
        PRM_ERR_CODE := '21';--Modified by Deepa on Apr-30-2012 for the response code change
        PRM_ERR_MSG  := ' Error while selecting CMS_APPL_PAN  '||SUBSTR(SQLERRM,1,200);
        RETURN;
     END;
  */
     BEGIN
       SELECT COUNT(1)
        INTO V_RULECNT_CARDTYPE
        FROM PCMS_PRODCATTYPE_RULEGROUP
        WHERE PPR_PROD_CODE = V_PROD_CODE AND
            PPR_CARD_TYPE = V_PROD_CATTYPE AND
            TRUNC(PRM_TRAN_DATETIME) BETWEEN TRUNC(PPR_VALID_FROM) AND
            TRUNC(PPR_VALID_TO);
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERR_CODE := '21';
        PRM_ERR_MSG  := 'Error while selecting rulcnt from cardtype level';
        RETURN;
     END;
     --En rule may be attached at cardtype level

     IF V_RULECNT_CARDTYPE = 0 THEN

       --Sn rule may be attached at product

       BEGIN
        SELECT COUNT(1)
          INTO V_RULECNT_PRODUCT
          FROM PCMS_PROD_RULEGROUP
         WHERE PPR_PROD_CODE = V_PROD_CODE AND
              TRUNC(PRM_TRAN_DATETIME) BETWEEN TRUNC(PPR_VALID_FROM) AND
              TRUNC(PPR_VALID_TO);
       EXCEPTION
        WHEN OTHERS THEN
          PRM_ERR_CODE := '21';
          PRM_ERR_MSG  := 'Error while selecting rulcnt from product';
          RETURN;
       END;
       --En rule may be attached at product

     END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERR_MSG := 'Error while selecting rulcnt from card level';
     RETURN;
  END;

  --En find rules attached at card level or prodcattype level
  IF V_RULECNT_CARD = 0 AND V_RULECNT_CARDTYPE = 0 AND
    V_RULECNT_PRODUCT = 0 THEN
    --No rules attached at Card or product or Cardtype level
    PRM_ERR_MSG := 'OK';
    RETURN;
  END IF;

  IF V_RULECNT_CARD <> 0 THEN
    --Sn select rule from card
    BEGIN

    --Order by clause added by Dhiraj Gaikwad on 26092012
     V_SQL_STMT := 'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
            WHERE PCER_PAN_CODE = :j AND TRUNC(:M) BETWEEN TRUNC(PCER_VALID_FROM) AND
         TRUNC(PCER_VALID_TO) ORDER BY PCER_INS_DATE ' ;--Modified by Deepa on 02-May-2012 to check the validity

     OPEN CUR_RULECODE FOR V_SQL_STMT
       USING V_HASH_PAN,PRM_TRAN_DATETIME;
    EXCEPTION
     WHEN OTHERS THEN
       PRM_ERR_CODE := '21';
       PRM_ERR_MSG  := 'Error while selecting rulegroup  at  card level';
       RETURN;
    END;
  ELSIF V_RULECNT_CARDTYPE <> 0 THEN--Modified by Deepa on 02-May-2012 to validate the Product category rule before product

     BEGIN
        --Sn select rule from cardtype
         --Order by clause added by Dhiraj Gaikwad on 26092012
        V_SQL_STMT := 'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
                   WHERE PPR_PROD_CODE = :j
                   AND   PPR_CARD_TYPE = :M AND
            TRUNC(:N) BETWEEN TRUNC(PPR_VALID_FROM) AND
            TRUNC(PPR_VALID_TO) ORDER BY PPR_INS_DATE';--Modified by Deepa on 02-May-2012 to check the validity

        OPEN CUR_RULECODE FOR V_SQL_STMT
          USING V_PROD_CODE, V_PROD_CATTYPE,PRM_TRAN_DATETIME;
       EXCEPTION
        WHEN OTHERS THEN
          PRM_ERR_CODE := '21';
          PRM_ERR_MSG  := 'Error while selecting rulegroup  at  card level';
          RETURN;
       END;

  ELSIF V_RULECNT_PRODUCT <> 0 THEN

     BEGIN
       --Sn select rule from cardtype
        --Order by clause added by Dhiraj Gaikwad on 26092012
       V_SQL_STMT := 'SELECT PPR_RULEGROUP_CODE FROM PCMS_PROD_RULEGROUP
                  WHERE PPR_PROD_CODE = :j AND
              TRUNC(:M) BETWEEN TRUNC(PPR_VALID_FROM) AND
              TRUNC(PPR_VALID_TO) ORDER BY PPR_INS_DATE ';--Modified by Deepa on 02-May-2012 to check the validity

       OPEN CUR_RULECODE FOR V_SQL_STMT
        USING V_PROD_CODE,PRM_TRAN_DATETIME;
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERR_CODE := '21';
        PRM_ERR_MSG  := 'Error while selecting rulegroup for product ';
        RETURN;
     END;

     END IF;

  --Sn open cursor and fetch records
  LOOP
    FETCH CUR_RULECODE
     INTO V_RULEGROUPCODE;

    EXIT WHEN CUR_RULECODE%NOTFOUND;

    --Sn find the rules attached to rulegroup
    BEGIN
     FOR I IN C(V_RULEGROUPCODE) LOOP
       --Sn find the rule detail
       FOR I1 IN C1(I.RULEID) LOOP
       
        --ST:Added for MerchantID check for FSS-2281 and mantis id:15901
      IF I1.RULETYPE = 1 and PRM_MERCHANT_ID is not null THEN   
      
         BEGIN
             SELECT merchantgroupid, AUTHTYPE
               INTO V_GROUPCODE, V_AUTH_TYPE
               FROM RULE
              WHERE RULEID = I.RULEID;              

             SP_CHECK_MERCHANTID(V_GROUPCODE,
                            PRM_MERCHANT_ID,
                            V_AUTH_TYPE,
                            V_ERR_FLAG,
                            V_ERR_MSG);

             IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
               PRM_ERR_CODE := V_ERR_FLAG;
               PRM_ERR_MSG  := V_ERR_MSG;
               RETURN;
             END IF;
            EXCEPTION
             WHEN OTHERS THEN
               PRM_ERR_CODE := '21';
               PRM_ERR_MSG  := 'Error while selecting merchant id:' ||
                            SUBSTR(SQLERRM, 1, 300);
               RETURN;
            END;
            
       --END:Added for MerchantID check for FSS-2281 and mantis id:15901
       
        ELSIF I1.RULETYPE = 2 THEN --Modifeid for FSS-2281 and mantis id:15901
          --Sn merchant based
          --Sn find merchant group
          IF PRM_DELIVERY_CHANNEL = '02' THEN -- Added as '02' instead of '2' on 25092012 Dhiraj Gaikwad

            BEGIN
             SELECT MCCGROUPID, AUTHTYPE
               INTO V_GROUPCODE, V_AUTH_TYPE
               FROM RULE
              WHERE RULEID = I.RULEID;

             SP_CHECK_MERCHANT(V_GROUPCODE,
                            PRM_MCC_CODE,
                            V_AUTH_TYPE,
                            V_ERR_FLAG,
                            V_ERR_MSG);

             IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
               PRM_ERR_CODE := V_ERR_FLAG;
               PRM_ERR_MSG  := V_ERR_MSG;
               RETURN;
             END IF;
            EXCEPTION
             WHEN OTHERS THEN
               PRM_ERR_CODE := '21';
               PRM_ERR_MSG  := 'Error while selecting rulcnt from cardtype level' ||
                            SUBSTR(SQLERRM, 1, 300);
               RETURN;
            END;
          END IF;
          --En find merchant group
          --En merchant based
          
        --ST:Added for Country code check for FSS-2281 and mantis id:15901
        ELSIF I1.RULETYPE = 3 and (PRM_CNTRYCODE is not null OR PRM_acqinstcntrycode_in IS NOT NULL) THEN
        
         BEGIN
             SELECT countrygrpoupid, AUTHTYPE
               INTO V_GROUPCODE, V_AUTH_TYPE
               FROM RULE
              WHERE RULEID = I.RULEID;

             SP_CHECK_COUNTRY(V_GROUPCODE,
                            PRM_CNTRYCODE,  
                            V_AUTH_TYPE,
							PRM_acqinstcntrycode_in,
                            V_ERR_FLAG,
                            V_ERR_MSG);

             IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
               PRM_ERR_CODE := V_ERR_FLAG;
               PRM_ERR_MSG  := V_ERR_MSG;
               RETURN;
             END IF;
            EXCEPTION
             WHEN OTHERS THEN
               PRM_ERR_CODE := '21';
               PRM_ERR_MSG  := 'Error while selecting country code:' ||
                            SUBSTR(SQLERRM, 1, 300);
               RETURN;
            END;
       --END:Added for Country code check for FSS-2281 and mantis id:15901
       
        ELSIF I1.RULETYPE = 4 THEN
          --Sn time basedbased
          /**Changed the sysdate to transaction date since for foreign transactions
               Transaction date and server date will be different.The transaction date
               is appended with the Time Based Rule's Time limit and the Transaction Date
               is checked wtith this limits
            **/
          BEGIN
            SELECT AUTHTYPE, FROMTIME, TOTIME
             INTO V_AUTH_TYPE, V_FROM_TIME, V_TO_TIME
             FROM RULE
            WHERE RULEID = I.RULEID;

            SELECT TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8) || ' ' ||
                        V_FROM_TIME,
                        'yyyymmdd hh24:mi')
             INTO V_FROM_DATE
             FROM DUAL;

            SELECT TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8) || ' ' ||
                        V_TO_TIME,
                        'yyyymmdd hh24:mi')
             INTO V_TO_DATE
             FROM DUAL;

            IF V_AUTH_TYPE = 'A' THEN
             IF (PRM_TRAN_DATETIME BETWEEN V_FROM_DATE AND V_TO_DATE) THEN
               PRM_ERR_CODE := '1';
               PRM_ERR_MSG  := 'OK';
             ELSE
               PRM_ERR_CODE := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code(27 used for Card Activation)
               PRM_ERR_MSG  := 'Invalid Transaction time ';
               RETURN;
             END IF;
            END IF;

            IF V_AUTH_TYPE = 'D' THEN
             IF (PRM_TRAN_DATETIME BETWEEN V_FROM_DATE AND V_TO_DATE) THEN

               PRM_ERR_CODE := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code(27 used for Card Activation)
               PRM_ERR_MSG  := 'Invalid Transaction time ';
               RETURN;
             ELSE
               PRM_ERR_CODE := '1';
               PRM_ERR_MSG  := 'OK';
             END IF;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
             PRM_ERR_CODE := '21';
             PRM_ERR_MSG  := SUBSTR(SQLERRM, 1, 300);
             RETURN;
          END;
          --En  time based
        ELSIF I1.RULETYPE = 5 THEN
          --En  transaction  based
          IF PRM_1ST_GRPVRFED <> 1 THEN -- added by Dhiraj Gaikwad on 26092012

           BEGIN
           /*SELECT  TRANSCODEGROUPID, AUTHTYPE
             INTO V_GROUPCODE, V_AUTH_TYPE
             FROM RULE
            WHERE RULEID = I.RULEID;*/

           /* Start  Added by Dhiraj G on 04062012 for Pre - Auth Parameter changes  */


             SELECT transactiongroupid, authtype
                 INTO V_GROUPCODE, V_AUTH_TYPE
                 FROM RULE
                WHERE RULEID = I.RULEID;

           SP_CHECK_TRANSACTION(PRM_INST_CODE ,
                                V_GROUPCODE,
                                PRM_TRAN_CODE,
                                V_HASH_PAN,
                                TO_DATE(PRM_TRAN_DATE, 'yyyymmdd'),
                                V_AUTH_TYPE,
                                V_ERR_FLAG,
                                PRM_1ST_GRPVRFED  ,-- added by Dhiraj Gaikwad on 26092012
                                PRM_DELIVERY_CHANNEL,
                                V_ERR_MSG);
            /* End Added by Dhiraj G on 04062012 for Pre - Auth Parameter changes  */
                IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
                 PRM_ERR_CODE := V_ERR_FLAG;
                 PRM_ERR_MSG  := V_ERR_MSG;
                 RETURN;

                END IF;
           EXCEPTION
            WHEN OTHERS THEN
             PRM_ERR_CODE := '21';
             PRM_ERR_MSG  := 'Error while selecting validating transaction rule' ||
                          SUBSTR(SQLERRM, 1, 300);
             RETURN;
           END;
          END IF ;-- added by Dhiraj Gaikwad on 26092012
          --En  transaction  based
        ELSIF I1.RULETYPE = 6 THEN
          --Sn currency  based
          BEGIN
            SELECT CCGROUPID, AUTHTYPE
             INTO V_GROUPCODE, V_AUTH_TYPE
             FROM RULE
            WHERE RULEID = I.RULEID;

            SP_CHECK_CURRENCY(V_GROUPCODE,
                          PRM_CURR_CODE,
                          V_AUTH_TYPE,
                          V_ERR_FLAG,
                          V_ERR_MSG);

            IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
             PRM_ERR_CODE := V_ERR_FLAG;
             PRM_ERR_MSG  := V_ERR_MSG;
             RETURN;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
             PRM_ERR_CODE := '21';
             PRM_ERR_MSG  := 'Error while selecting for currency group' ||
                          SUBSTR(SQLERRM, 1, 300);
             RETURN;
          END;
          --En currency  based
        ELSIF I1.RULETYPE = 7 THEN
          --Sn usage based
          BEGIN
            SELECT USAGETYPE, NOTRANSALLOWED, TOTALAMOUNTLIMIT, AUTHTYPE
             INTO V_USAGE_TYPE,
                 V_NOOF_TXN_ALLOWED,
                 V_TOTAL_AMT_LIMIT,
                 V_AUTH_TYPE
             FROM RULE
            WHERE RULEID = I.RULEID;

            SP_CHECK_USAGE(PRM_INST_CODE,
                        V_USAGE_TYPE,
                        PRM_CARD_NO,
                        TO_DATE(PRM_TRAN_DATE, 'yyyymmdd'),
                        V_NOOF_TXN_ALLOWED,
                        V_TOTAL_AMT_LIMIT,
                        PRM_TXN_AMT,
                        V_AUTH_TYPE,
                        V_ERR_FLAG,
                        V_ERR_MSG);

            IF V_ERR_FLAG <> '1' AND V_ERR_MSG <> 'OK' THEN
             PRM_ERR_CODE := V_ERR_FLAG;
             PRM_ERR_MSG  := V_ERR_MSG;
             RETURN;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
             PRM_ERR_CODE := '21';
             PRM_ERR_MSG  := 'Error while selecting usage type rule' ||
                          SUBSTR(SQLERRM, 1, 300);
             RETURN;
          END;
          --En  usage based
        END IF;
       END LOOP;
       --En find the rule detail
     END LOOP;
    END;

    --En find the rules attached to rulegroup
  END LOOP;
  --En open cursor and fetch records
EXCEPTION
  WHEN OTHERS THEN
    PRM_ERR_CODE := '21';
    PRM_ERR_MSG  := 'Error from main' || SUBSTR(SQLERRM, 1, 300);
END;
/
SHOW ERROR;