CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHECK_TRANSACTION(PRM_INST_CODE        IN NUMBER,
                                        PRM_TXNRULEGRP_CODE  IN VARCHAR2,
                                        PRM_TRANSACTION_CODE IN VARCHAR2,
                                        PRM_CARD_NO          IN VARCHAR2,
                                        PRM_TRAN_DATE        IN DATE,
                                        PRM_AUTH_TYPE        IN VARCHAR2,
                                        PRM_ERR_FLAG         OUT VARCHAR2,
                                        PRM_1ST_GRPVRFED     OUT NUMBER ,
                                        PRM_DELIVERY_CHANNEL IN VARCHAR2,
                                        PRM_ERR_MSG          OUT VARCHAR2) IS
 /*************************************************
     * Modified By      :  Dhiraj Gaikwad 
     * Modified Date    :  26-Sep-2012
     * Modified Reason  :  First Rule Group Ruleid Only needs to Verify 
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  27-Apr-2012
     * Build Number     :  CMS3.4.2_RI0008_B0001
 *************************************************/
  V_CHECK_CNT       NUMBER(1);
  V_TOT_TRANSACTION NUMBER;
  V_TOT_TXN_ALLOWED NUMBER;

  
BEGIN
 /*
 Commented on 04062012 Dhiraj G  for using new tables cms_txncode_rule , cms_txncodegrp_txncode
 SELECT COUNT(*)
    INTO V_CHECK_CNT
    FROM TRANSCODE_GROUP
   WHERE TRANSCODEGROUPID = PRM_TRANSGROUP_CODE AND
        TRANSCODE = PRM_TRANSACTION_CODE;
*/
 /* Start  Added by Dhiraj G on 04062012 for Pre - Auth Parameter changes  */
 

         SELECT COUNT (*)
              INTO v_check_cnt
              FROM cms_txncode_rule b, cms_txncodegrp_txncode a
             WHERE a.ctt_txnrule_grpcode = PRM_TXNRULEGRP_CODE
               AND a.ctt_txnrule_id = b.ctr_txnrule_id
               AND b.ctr_inst_code = PRM_INST_CODE
               AND b.ctr_txn_code = PRM_TRANSACTION_CODE
               AND b.ctr_delv_chnl = PRM_DELIVERY_CHANNEL;


          IF (V_CHECK_CNT = 1 AND PRM_AUTH_TYPE = 'A') OR
            (V_CHECK_CNT = 0 --AND PRM_AUTH_TYPE = 'D'  --Commented by Dhiraj on 13092012 
            ) THEN
            PRM_ERR_FLAG := '1';
            PRM_ERR_MSG  := 'OK';
            PRM_1ST_GRPVRFED:=1 ; -- added by Dhiraj Gaikwad on 26092012 
          ELSE
            PRM_ERR_FLAG := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
            PRM_ERR_MSG  := 'Invalid transaction code ';
            PRM_1ST_GRPVRFED:=1 ; -- added by Dhiraj Gaikwad on 26092012 
          END IF;
 
 /* Start  Added by Dhiraj G on 04062012 for Pre - Auth Parameter changes  */
  /*
  Commented on 04062012 Dhiraj G as we are not having ONUSFREETRANS value in CMS_TXNCODE_RULE table
  IF (V_CHECK_CNT = 1 AND PRM_AUTH_TYPE = 'A') OR
    (V_CHECK_CNT = 0 AND PRM_AUTH_TYPE = 'D') THEN
    PRM_ERR_FLAG := '1';
    PRM_ERR_MSG  := 'OK';
  ELSIF (V_CHECK_CNT = 1 AND PRM_AUTH_TYPE = 'D') THEN
    -- CHANGES DONE FOR CHECKING...
    -- TOTAL TXN DONE ON THE DAY
    SELECT COUNT(1)
     INTO V_TOT_TRANSACTION
     FROM CMS_TRANSACTION_LOG_DTL
    WHERE CTD_PROCESS_FLAG = 'Y' AND CTD_TXN_CODE = PRM_TRANSACTION_CODE AND
         CTD_CUSTOMER_CARD_NO = PRM_CARD_NO AND
         TO_DATE(SUBSTR(TRIM(CTD_BUSINESS_DATE), 1, 8), 'yyyymmdd') =
         TRUNC(PRM_TRAN_DATE) AND CTD_MSG_TYPE = '0200';

    -- MAX TRAN ALLOWED
    SELECT NVL(ONUSFREETRANS, 0)
     INTO V_TOT_TXN_ALLOWED
     FROM PCMS_PROD_RULEGROUP A,
         CMS_APPL_PAN        B,
         TRANSCODE           C,
         TRANSCODE_GROUP     D
    WHERE TO_DATE(PRM_TRAN_DATE, 'DD-MON-YY') BETWEEN
         TO_DATE(A.PPR_VALID_FROM, 'DD-MON-YY') AND
         TO_DATE(A.PPR_VALID_TO, 'DD-MON-YY') AND
         A.PPR_PROD_CODE = B.CAP_PROD_CODE AND CAP_INST_CODE = 1 AND
         TRANSCODEGROUPID = PRM_TRANSGROUP_CODE AND
         C.TRANSCODE = D.TRANSCODE AND C.TRANSCODE = PRM_TRANSACTION_CODE AND
         CAP_PAN_CODE = PRM_CARD_NO AND
         C.DELIVERY_CHNNEL = PRM_DELIVERY_CHANNEL;
    IF V_TOT_TRANSACTION >= V_TOT_TXN_ALLOWED THEN
     PRM_ERR_FLAG := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
     PRM_ERR_MSG  := 'Exceeds Usage limit';
    END IF;
  ELSE
    PRM_ERR_FLAG := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
    PRM_ERR_MSG  := 'Invalid transaction code ';
  END IF; */
EXCEPTION
  WHEN OTHERS THEN
    PRM_ERR_FLAG := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
    PRM_ERR_MSG  := 'Invalid transaction code ';
END;
/
show error