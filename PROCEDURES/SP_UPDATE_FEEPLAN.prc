CREATE OR REPLACE PROCEDURE VMSCMS.SP_UPDATE_FEEPLAN(PRM_INST_CODE     IN NUMBER,
                                     PRM_RRN           IN VARCHAR2,
                                     PRM_STAN          IN VARCHAR2,
                                     PRM_CARD_NUMBER   IN VARCHAR2,
                                     PRM_MBR_NUMB      IN VARCHAR2,
                                     PRM_DEL_CHANNEL   IN VARCHAR2,
                                     PRM_TRAN_TYPE     IN VARCHAR2,
                                     PRM_TRAN_MODE     IN VARCHAR2,
                                     PRM_TRAN_CODE     IN VARCHAR2,
                                     PRM_CURRENCY_CODE IN VARCHAR2,
                                     PRM_TRAN_DATE     IN VARCHAR2,
                                     PRM_TRAN_TIME     IN VARCHAR2,
                                     PRM_MSG_TYPE      IN VARCHAR2,
                                     PRM_REVERSAL_CODE IN VARCHAR2,
                                     PRM_FEE_PLAN      IN NUMBER,
                                     PRM_VALID_FROM    IN VARCHAR2,
                                     PRM_REMARK        IN VARCHAR2,
                                     PRM_REASON_CODE   IN NUMBER,
                                     PRM_CALL_ID       IN NUMBER, -- Added on 09Oct2012
                                     PRM_INS_USER      IN NUMBER,
                                     PRM_IP_ADDR       IN VARCHAR2, 
                                     PRM_ERRMSG        OUT VARCHAR2,
                                     PRM_RESP_CODE     OUT VARCHAR2) IS

/**********************************************************************************************
  * VERSION              :  1.0
  * DATE OF CREATION     : 11/Jul/2012
  * PURPOSE              : To update fee plan of customer 
  * CREATED BY           : Sagar More
  * modified for         : Internal Enhancement
  * modified Date        : 09-OCT-12
  * modified reason      : Response id changed from 49 to 10
                           To show invalid card status msg in popup query 
  * Reviewer             : Saravanakumar
  * Reviewed Date        : 09-OCT-12
  * Build Number         : CMS3.5.1_RI0021
  
  * modified by          : Santosh K     
  * modified for         : Defect MVHOST-346 
  * modified Date        : 06-May-13
  * modified reason      : The VMS host shall have the ability to configure Claw Back for fees on Non Financial TXN.
  * Reviewer             : 
  * Reviewed Date        : 
  * Build Number         : CMS3.5.1_RI0024.1_B0014
  
  * Modified by          :  Dnyaneshwar J
  * Modified for         :  Mantis - 0011399
  * Modification Reason  :  Update Fee Plan transaction's are not displaying in comments tab.
  * Modified Date        :  25-June-13
  * Reviewer             : 
  * Reviewed Date        :  
  * Build Number         :  RI0024.2_B0010
  
  * Modified By      : Abdul Hameed M.A
  * Modified Date    : 04-May-2016
  * Modified for     : DFCTNM-107
  * Reviewer         : Spankaj
  * Release Number   : VMSGPRHOSTCSD_4.0.2_B0001
  
  
  * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1	 
  **************************************************************************************************/


  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  EXP_REJECT_RECORD EXCEPTION;
  EXP_NOPLAN_FOUND EXCEPTION;
  V_PROD_CODE      CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE      CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_FEEATTACH_FLAG NUMBER;
  V_FEEATTACH_TYPE VARCHAR2(2);
  V_TRAN_MODE      VARCHAR2(10);
  V_TRAN_FEE       NUMBER(1);
  V_TRAN_CODE      CMS_TRANSACTION_MAST.CTM_TRAN_CODE%TYPE;
  EXP_MAIN EXCEPTION;
  EXP_NOFEES EXCEPTION;
  V_ENCR_PAN        CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_AUTH_ID         TRANSACTIONLOG.AUTH_ID%TYPE;
  V_ERRMSG          VARCHAR2(500);
  V_RESP_CDE        VARCHAR2(3);
  V_TRAN_TYPE       CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  V_TXN_TYPE        VARCHAR2(1);
  V_DR_CR_FLAG      CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_TRAN_DESC       CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_CFM_FUNC_CODE   CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_CAP_PROXYNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_CAP_ACCT_NO     CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_EXPRY_DATE      CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_CARD_STAT       CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CHECK_STATCNT   NUMBER(1);
  V_STATUS_CHK      NUMBER;
  V_FOUND_FLAG      VARCHAR2(1);
  V_REASON          CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
  V_RESONCODE       CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_ACCT_BALANCE    CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_LEDGER_BAL      CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_RRN_COUNT       NUMBER;
  V_FEECODE         CMS_FEE_MAST.CFM_FEE_CODE%TYPE;

  V_TABLE_LIST VARCHAR2(2000);
  V_COLM_LIST  VARCHAR2(2000);
  V_COLM_QURY  VARCHAR2(2000);
  V_OLD_VALUE  VARCHAR2(2000);
  V_NEW_VALUE  VARCHAR2(2000);
  V_CALL_SEQ   NUMBER(3);
  
  --SN : Added for Defect MVHOST-346 
  
  V_CAM_TYPE_CODE     CMS_ACCT_MAST.CAM_TYPE_CODE%type; 
  V_TIMESTAMP         timestamp;                          
  V_APPLPAN_CARDSTAT  CMS_APPL_PAN.CAP_CARD_STAT%type;   
  V_ACCT_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%type;
  V_TOTAL_FEE         number;
  V_CAPTURE_DATE      date;
  v_base_curr         cms_bin_param.cbp_param_value%TYPE;
  
  --EN : Added for Defect MVHOST-346
  v_from_feeplan  cms_card_excpfee.cce_fee_plan%TYPE;
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN

  BEGIN

    PRM_ERRMSG := 'OK';

    V_ERRMSG := 'OK';

    BEGIN

     V_HASH_PAN := GETHASH(PRM_CARD_NUMBER);

    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(PRM_CARD_NUMBER);
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 100);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN

     --             SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 100);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    /*  call log info   start */
    BEGIN

     SELECT CUT_TABLE_LIST, CUT_COLM_LIST, CUT_COLM_QURY
       INTO V_TABLE_LIST, V_COLM_LIST, V_COLM_QURY
       FROM CMS_CALLLOGQUERY_MAST
      WHERE CUT_INST_CODE = PRM_INST_CODE AND
           CUT_DEVL_CHNL = PRM_DEL_CHANNEL AND
           CUT_TXN_CODE = PRM_TRAN_CODE;

     DBMS_OUTPUT.PUT_LINE(V_COLM_QURY);

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '49';
       V_ERRMSG   := 'Column list not found in cms_calllogquery_mast ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while finding Column list ' ||
                  SUBSTR(SQLERRM, 1, 100);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;

    END;

    BEGIN

     EXECUTE IMMEDIATE V_COLM_QURY
       INTO V_OLD_VALUE
       USING PRM_INST_CODE, PRM_CARD_NUMBER; -- prm_card_number is used by sagar on 14Aug2012 as per jira defect 377

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting old values -- ' || '---' ||
                  SUBSTR(SQLERRM, 1, 100);
       V_RESP_CDE := '89';
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE INSTCODE = PRM_INST_CODE AND CUSTOMER_CARD_NO = V_HASH_PAN AND
           RRN = PRM_RRN AND DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
           TXN_CODE = PRM_TRAN_CODE AND BUSINESS_DATE = PRM_TRAN_DATE AND
           BUSINESS_TIME = PRM_TRAN_TIME;
ELSE
	SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      WHERE INSTCODE = PRM_INST_CODE AND CUSTOMER_CARD_NO = V_HASH_PAN AND
           RRN = PRM_RRN AND DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
           TXN_CODE = PRM_TRAN_CODE AND BUSINESS_DATE = PRM_TRAN_DATE AND
           BUSINESS_TIME = PRM_TRAN_TIME;
END IF;
		   

     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERRMSG   := 'Duplicate RRN found' || PRM_RRN;
       RAISE EXP_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'While checking for duplicate ' || PRM_RRN ||
                  SUBSTR(SQLERRM, 1, 100);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN

     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_TRAN_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_TRAN_TYPE, V_TXN_TYPE, V_TRAN_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = PRM_TRAN_CODE AND
           CTM_DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
           CTM_INST_CODE = PRM_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12';
       V_ERRMSG   := 'Transflag  not defined for txn code ' ||
                  PRM_TRAN_CODE || ' and delivery channel ' ||
                  PRM_DEL_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while selecting transaction details' ||
                  SUBSTR(SQLERRM, 1, 100);
       RAISE EXP_REJECT_RECORD;
    END;

    /*
     BEGIN

         SELECT cfm_func_code
           INTO v_cfm_func_code
           FROM cms_func_mast
          WHERE cfm_inst_code = prm_inst_code
            AND cfm_txn_code = prm_tran_code
            AND cfm_delivery_channel = prm_del_channel;

     EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_errmsg :=
                  'Function not defined for txn code '
               || prm_tran_code
               || ' and delivery channel '
               || prm_del_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'error while fetching function code '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
     END;
    */

    BEGIN

     SELECT CAP_PROD_CODE,
           CAP_CARD_TYPE,
           CAP_ACCT_NO,
           CAP_PROXY_NUMBER,
           CAP_EXPRY_DATE,
           CAP_CARD_STAT,
           CAP_ACCT_NO
       INTO V_PROD_CODE,
           V_CARD_TYPE,
           V_CAP_ACCT_NO,
           V_CAP_PROXYNUMBER,
           V_EXPRY_DATE,
           V_CARD_STAT,
           V_CAP_ACCT_NO
       FROM CMS_APPL_PAN
      WHERE CAP_INST_CODE = PRM_INST_CODE AND CAP_MBR_NUMB = PRM_MBR_NUMB AND
           CAP_PAN_CODE = V_HASH_PAN;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERRMSG   := 'Card not found';
       RAISE EXP_REJECT_RECORD;

     WHEN OTHERS THEN
       V_ERRMSG   := 'ERROR FROM PAN DATA SECTION =>' || SQLERRM;
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = PRM_INST_CODE AND CAM_ACCT_NO = V_CAP_ACCT_NO;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '07';
       V_ERRMSG   := 'Account not found in master' || V_CAP_ACCT_NO;
     WHEN OTHERS THEN
       V_RESP_CDE := '49';
       V_ERRMSG   := 'error while validating account number ' ||
                  SUBSTR(SQLERRM, 1, 100);
       RAISE EXP_REJECT_RECORD;
    END;
    
    
    --SN: Added for Defect MVHOST-346
    
    BEGIN
	
	       SELECT TRIM (cbp_param_value) 
	        INTO v_base_curr 
	        FROM cms_bin_param WHERE cbp_param_name = 'Currency'
	       AND cbp_inst_code= prm_inst_code AND 
	       cbp_profile_code = (select  cpc_profile_code from 
               cms_prod_cattype where cpc_prod_code = v_prod_code 
               and cpc_card_type =  v_card_type and 
	       cpc_inst_code= prm_inst_code);
	
	
         IF v_base_curr IS NULL
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Base currency cannot be null ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record                
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Base currency is not defined for the bin profile ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while selecting bese currency for BIN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;
    
    
    BEGIN
         SP_AUTHORIZE_TXN_CMS_AUTH (PRM_INST_CODE,
                                    PRM_MSG_TYPE,
                                    PRM_RRN,
                                    prm_del_channel,
                                    null,                          --P_TERM_ID
                                    PRM_TRAN_CODE,
                                    PRM_TRAN_MODE,
                                    PRM_TRAN_DATE,
                                    PRM_TRAN_TIME,
                                    PRM_CARD_NUMBER,
                                    prm_inst_code,
                                    0,                                   --AMT
                                    NULL,                    --P_MERCHANT_NAME
                                    NULL,                    --P_MERCHANT_CITY
                                    null,                         --P_MCC_CODE
                                    PRM_CURRENCY_CODE,
                                    NULL,                          --P_PROD_ID
                                    NULL,                          --P_CATG_ID
                                    NULL,                          --P_TIP_AMT
                                    NULL,                       --P_TO_ACCT_NO
                                    NULL,                      --P_ATMNAME_LOC
                                    NULL,                  --P_MCCCODE_GROUPID
                                    NULL,                 --P_CURRCODE_GROUPID
                                    NULL,                --P_TRANSCODE_GROUPID
                                    NULL,                            --P_RULES
                                    NULL,                     --P_PREAUTH_DATE
                                    NULL,                   --P_CONSODIUM_CODE
                                    NULL,                     --P_PARTNER_CODE
                                    null,                       --P_EXPRY_DATE
                                    PRM_STAN,
                                    prm_mbr_numb,
                                    PRM_REVERSAL_CODE,
                                    NULL,                --P_CURR_CONVERT_AMNT
                                    v_auth_id,
                                    v_resp_cde,
                                    v_errmsg,
                                    v_capture_date
                                   );

         IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
         THEN
            PRM_RESP_CODE := v_resp_cde;
            v_errmsg := 'Error from auth process' || v_errmsg;
            PRM_ERRMSG := v_errmsg;
            return;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
    
    --EN: Added for Defect MVHOST-346

    BEGIN
     SP_STATUS_CHECK_GPR(PRM_INST_CODE,
                     PRM_CARD_NUMBER,
                     PRM_DEL_CHANNEL,
                     V_EXPRY_DATE,
                     V_CARD_STAT,
                     PRM_TRAN_CODE,
                     PRM_TRAN_MODE,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     PRM_MSG_TYPE,
                     PRM_TRAN_DATE,
                     PRM_TRAN_TIME,
                     NULL, --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                     NULL,
                     NULL,
                     V_RESP_CDE,
                     V_ERRMSG);

     IF ((V_RESP_CDE <> '1' AND V_ERRMSG <> 'OK') OR
        (V_RESP_CDE <> '0' AND V_ERRMSG <> 'OK')) THEN
       RAISE EXP_REJECT_RECORD;
     ELSE
       V_STATUS_CHK := V_RESP_CDE;
       V_RESP_CDE   := '1';
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error from GPR Card Status Check ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    IF V_STATUS_CHK = '1' THEN
     -- IF condition checked for GPR changes on 27-FEB-2012
     --Sn check card stat
     BEGIN
       SELECT COUNT(1)
        INTO V_CHECK_STATCNT
        FROM PCMS_VALID_CARDSTAT
        WHERE PVC_INST_CODE = PRM_INST_CODE AND
            PVC_CARD_STAT = V_CARD_STAT AND
            PVC_TRAN_CODE = PRM_TRAN_CODE AND
            PVC_DELIVERY_CHANNEL = PRM_DEL_CHANNEL;

       IF V_CHECK_STATCNT = 0 THEN
        V_RESP_CDE := '10'; -- response id changed from 49 to 10 on 09-Oct-2012
        V_ERRMSG   := 'Invalid Card Status';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'Problem while selecting card stat ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
     --En check card stat
    END IF;

    IF PRM_REASON_CODE IS NULL THEN

     V_REASON := 'Fee plan update';

    ELSE
     V_RESONCODE := PRM_REASON_CODE;

     BEGIN
       --added by sagar on 19-Jun-2012 for reasioin desc logging in txnlog table
       SELECT CSR_REASONDESC
        INTO V_REASON
        FROM CMS_SPPRT_REASONS
        WHERE CSR_SPPRT_RSNCODE = V_RESONCODE AND
            CSR_INST_CODE = PRM_INST_CODE;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '21'; --added
        V_ERRMSG   := 'reason code not found in master for reason code ' ||
                    V_RESONCODE;
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '21'; --added
        V_ERRMSG   := 'Error while selecting reason description' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    END IF;

    V_FOUND_FLAG := 'N';

    -----------------------------------------
    --SN : Check fees attached at card level
    -----------------------------------------

    BEGIN

     SELECT CCE_FEE_CODE,cce_fee_plan
       INTO V_FEECODE,v_from_feeplan
        FROM cms_card_excpfee a,
             cms_appl_pan b,
             cms_fee_plan f
       WHERE cce_inst_code = prm_inst_code
         AND a.cce_pan_code = v_hash_pan
         AND a.cce_inst_code = b.cap_inst_code
         AND a.cce_pan_code = b.cap_pan_code
         AND a.cce_inst_code = f.cfp_inst_code
         AND a.cce_fee_plan  = f.cfp_plan_id
         AND ((CCE_VALID_TO IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
               OR (CCE_VALID_TO IS NULL AND trunc(sysdate) >= cce_valid_from));-- added by sagar to fetch active plan on 22Aug2012         
        --ORDER BY a.cce_valid_from;


     V_FOUND_FLAG := 'Y';

   /*  BEGIN

       UPDATE CMS_CARD_EXCPFEE
         SET CCE_FEE_PLAN   = PRM_FEE_PLAN,
            CCE_VALID_FROM = TO_DATE(PRM_VALID_FROM, 'mm/dd/yyyy')
        WHERE CCE_INST_CODE = PRM_INST_CODE AND CCE_PAN_CODE = V_HASH_PAN;

       IF SQL%ROWCOUNT = 0 THEN

        V_ERRMSG   := 'Fee plan not updated in master';
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;

       END IF;

     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;

       WHEN OTHERS THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'error while updating fee plan ' ||
                    SUBSTR(SQLERRM, 1, 100);
        RAISE EXP_REJECT_RECORD;
     END;
     */
     


     BEGIN

       UPDATE CMS_CARD_EXCPFEE
         SET CCE_VALID_TO = TO_DATE(PRM_VALID_FROM, 'mm/dd/yyyy')-1
        WHERE CCE_INST_CODE = PRM_INST_CODE AND CCE_PAN_CODE = V_HASH_PAN
        and cce_fee_plan=v_from_feeplan;
        
       IF SQL%ROWCOUNT = 0 THEN

        V_ERRMSG   := 'Fee plan not updated in master';
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;

       END IF;
       
     EXCEPTION
     
     WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;
        
       WHEN OTHERS THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'error while updating fee plan ' ||
                    SUBSTR(SQLERRM, 1, 100);
        RAISE EXP_REJECT_RECORD;
     END;
     
      BEGIN
 
          INSERT INTO cms_card_excpfee
            (cce_inst_code, cce_pan_code, cce_mbr_numb, cce_valid_from,
             cce_valid_to, cce_flow_source, cce_ins_user, cce_lupd_user,
             cce_fee_plan, cce_pan_code_encr
            )
     VALUES (prm_inst_code, v_hash_pan, PRM_MBR_NUMB,TO_DATE(PRM_VALID_FROM, 'mm/dd/yyyy'),
             NULL, 'C', 1, 1,
             PRM_FEE_PLAN, v_encr_pan
            );
       IF SQL%ROWCOUNT = 0 THEN

        V_ERRMSG   := 'Fee plan is not inserted in master';
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;

       END IF;

     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;
       
       WHEN OTHERS THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'error while inserting fee plan ' ||
                    SUBSTR(SQLERRM, 1, 100);
        RAISE EXP_REJECT_RECORD;
     END;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_FOUND_FLAG := 'N';

     WHEN EXP_REJECT_RECORD THEN
       RAISE;

     WHEN OTHERS THEN
       V_ERRMSG := 'ERROR FROM MAIN 1 =>' || SQLERRM;
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;

    END;

    -----------------------------------------
    --EN : Check fees attached at card level
    -----------------------------------------

    IF V_FOUND_FLAG = 'N' THEN

     ---------------------------------------------------
     --SN : Check fees attached at product catagory level
     ---------------------------------------------------

     BEGIN

       SELECT CPF_FEE_CODE,cpf_fee_plan
        INTO V_FEECODE,v_from_feeplan
        FROM cms_prodcattype_fees a,
             cms_prod_cattype g,
             cms_prod_mast p,
             cms_fee_plan h
       WHERE cpf_inst_code = prm_inst_code
         AND a.cpf_prod_code = v_prod_code
         AND a.cpf_card_type = v_card_type
         AND a.cpf_inst_code = g.cpc_inst_code
         AND a.cpf_prod_code = g.cpc_prod_code
         AND a.cpf_card_type = g.cpc_card_type
         AND p.cpm_prod_code = a.cpf_prod_code
         AND p.cpm_inst_code = a.cpf_inst_code
         AND a.cpf_inst_code = h.cfp_inst_code
         AND a.cpf_fee_plan  = h.cfp_plan_id
         AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
              OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from)); -- added by sagar to fetch active plan on 22Aug2012
        --ORDER BY a.cpf_valid_from;     
         


       V_FOUND_FLAG := 'Y';

       INSERT INTO CMS_CARD_EXCPFEE
        (CCE_INST_CODE,
         CCE_FEE_CODE,
         CCE_PAN_CODE,
         CCE_MBR_NUMB,
         CCE_VALID_FROM,
         CCE_VALID_TO,
         CCE_FLOW_SOURCE,
         CCE_INS_USER,
         CCE_INS_DATE,
         CCE_LUPD_USER,
         CCE_LUPD_DATE,
         CCE_CRGL_CODE,
         CCE_CRSUBGL_CODE,
         CCE_CRACCT_NO,
         CCE_DRGL_CATG,
         CCE_DRGL_CODE,
         CCE_DRSUBGL_CODE,
         CCE_DRACCT_NO,
         CCE_CRGL_CATG,
         CCE_ST_CRGL_CATG,
         CCE_ST_CRGL_CODE,
         CCE_ST_CRSUBGL_CODE,
         CCE_ST_CRACCT_NO,
         CCE_ST_DRGL_CATG,
         CCE_ST_DRGL_CODE,
         CCE_ST_DRSUBGL_CODE,
         CCE_ST_DRACCT_NO,
         CCE_CESS_CRGL_CATG,
         CCE_CESS_CRGL_CODE,
         CCE_CESS_CRSUBGL_CODE,
         CCE_CESS_CRACCT_NO,
         CCE_CESS_DRGL_CATG,
         CCE_CESS_DRGL_CODE,
         CCE_CESS_DRSUBGL_CODE,
         CCE_CESS_DRACCT_NO,
         CCE_ST_CALC_FLAG,
         CCE_CESS_CALC_FLAG,
         CCE_CARDFEE_ID,
         CCE_PAN_CODE_ENCR,
         CCE_TRAN_CODE,
         CCE_FEE_PLAN)
        SELECT CPF_INST_CODE,
              CPF_FEE_CODE,
              V_HASH_PAN,
              PRM_MBR_NUMB,
              to_date(PRM_VALID_FROM,'mm/dd/yyyy'), -- changed as per jira defect 377
              NULL,--CPF_VALID_TO,
              CPF_FLOW_SOURCE,
              --PRM_INS_USER,    -- Commented by sagar on 23Aug2012 as discussed with tejas 
              1,                 -- Added by sagar on 23Aug2012 as discussed with tejas           
              SYSDATE,
              --PRM_INS_USER,    -- Commented by sagar on 23Aug2012 as discussed with tejas  
              1,                  -- Added by sagar on 23Aug2012 as discussed with tejas   
              SYSDATE,
              CPF_CRGL_CODE,
              CPF_CRSUBGL_CODE,
              CPF_CRACCT_NO,
              CPF_DRGL_CATG,
              CPF_DRGL_CODE,
              CPF_DRSUBGL_CODE,
              CPF_DRACCT_NO,
              CPF_CRGL_CATG,
              CPF_ST_CRGL_CATG,
              CPF_ST_CRGL_CODE,
              CPF_ST_CRSUBGL_CODE,
              CPF_ST_CRACCT_NO,
              CPF_ST_DRGL_CATG,
              CPF_ST_DRGL_CODE,
              CPF_ST_DRSUBGL_CODE,
              CPF_ST_DRACCT_NO,
              CPF_CESS_CRGL_CATG,
              CPF_CESS_CRGL_CODE,
              CPF_CESS_CRSUBGL_CODE,
              CPF_CESS_CRACCT_NO,
              CPF_CESS_DRGL_CATG,
              CPF_CESS_DRGL_CODE,
              CPF_CESS_DRSUBGL_CODE,
              CPF_CESS_DRACCT_NO,
              CPF_ST_CALC_FLAG,
              CPF_CESS_CALC_FLAG,
              1,
              V_ENCR_PAN,
              PRM_TRAN_CODE,
              PRM_FEE_PLAN
        FROM cms_prodcattype_fees --a,
          /*   cms_prod_cattype g,
             cms_prod_mast p,
             cms_fee_plan h*/
       WHERE cpf_inst_code = prm_inst_code
         AND cpf_prod_code = v_prod_code
         AND cpf_card_type = v_card_type
      /*   AND a.cpf_inst_code = g.cpc_inst_code
         AND a.cpf_prod_code = g.cpc_prod_code
         AND a.cpf_card_type = g.cpc_card_type
         AND p.cpm_prod_code = a.cpf_prod_code
         AND p.cpm_inst_code = a.cpf_inst_code
         AND a.cpf_inst_code = h.cfp_inst_code */
         AND cpf_fee_plan  = v_from_feeplan; --h.cfp_plan_id
    --  ORDER BY a.cpf_valid_from;

       IF SQL%ROWCOUNT = 0 THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'record not inserted from product catogary';
        RAISE EXP_REJECT_RECORD;

       END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN

        V_FOUND_FLAG := 'N';

       WHEN EXP_REJECT_RECORD THEN
        RAISE;

       WHEN OTHERS THEN
        V_ERRMSG := 'ERROR FROM MAIN 2 =>' || SQLERRM;
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;

     END;

     ---------------------------------------------------
     --EN : Check fees attached at product catagory level
     ---------------------------------------------------
    END IF;

    IF V_FOUND_FLAG = 'N' THEN

     ---------------------------------------------------
     --SN : Check fees attached at product level
     ---------------------------------------------------

     BEGIN

      SELECT CPF_FEE_CODE,cpf_fee_plan
      INTO V_FEECODE,v_from_feeplan
      from cms_prod_fees a,
          cms_prod_mast b,
          cms_fee_plan e
       where cpf_inst_code = prm_inst_code
       and a.cpf_prod_code = v_prod_code
       and a.cpf_inst_code = b.cpm_inst_code
       and a.cpf_prod_code = b.cpm_prod_code
       and a.cpf_inst_code = e.cfp_inst_code
       and a.cpf_fee_plan   = e.cfp_plan_id
       and upper(CPM_MARC_PROD_FLAG)='N'
       AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
       OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from)); -- added by sagar to fetch active plan on 22Aug2012
         --order by a.cpf_valid_from ;

       V_FOUND_FLAG := 'Y';

       INSERT INTO CMS_CARD_EXCPFEE
        (CCE_INST_CODE,
         CCE_FEE_CODE,
         CCE_PAN_CODE,
         CCE_MBR_NUMB,
         CCE_VALID_FROM,
         CCE_VALID_TO,
         CCE_FLOW_SOURCE,
         CCE_INS_USER,
         CCE_INS_DATE,
         CCE_LUPD_USER,
         CCE_LUPD_DATE,
         CCE_CRGL_CODE,
         CCE_CRSUBGL_CODE,
         CCE_CRACCT_NO,
         CCE_DRGL_CATG,
         CCE_DRGL_CODE,
         CCE_DRSUBGL_CODE,
         CCE_DRACCT_NO,
         CCE_CRGL_CATG,
         CCE_ST_CRGL_CATG,
         CCE_ST_CRGL_CODE,
         CCE_ST_CRSUBGL_CODE,
         CCE_ST_CRACCT_NO,
         CCE_ST_DRGL_CATG,
         CCE_ST_DRGL_CODE,
         CCE_ST_DRSUBGL_CODE,
         CCE_ST_DRACCT_NO,
         CCE_CESS_CRGL_CATG,
         CCE_CESS_CRGL_CODE,
         CCE_CESS_CRSUBGL_CODE,
         CCE_CESS_CRACCT_NO,
         CCE_CESS_DRGL_CATG,
         CCE_CESS_DRGL_CODE,
         CCE_CESS_DRSUBGL_CODE,
         CCE_CESS_DRACCT_NO,
         CCE_ST_CALC_FLAG,
         CCE_CESS_CALC_FLAG,
         CCE_CARDFEE_ID,
         CCE_PAN_CODE_ENCR,
         CCE_TRAN_CODE,
         CCE_FEE_PLAN)
        SELECT CPF_INST_CODE,
              CPF_FEE_CODE,
              V_HASH_PAN,
              PRM_MBR_NUMB,
              to_date(PRM_VALID_FROM,'mm/dd/yyyy'), -- changed as per jira defect 377
             --- CPF_VALID_TO,
              NULL,
              CPF_FLOW_SOURCE,
              --PRM_INS_USER,    -- Commented by sagar on 23Aug2012 as discussed with tejas 
              1,                 -- Added by sagar on 23Aug2012 as discussed with tejas           
              SYSDATE,
              --PRM_INS_USER,    -- Commented by sagar on 23Aug2012 as discussed with tejas  
              1,                  -- Added by sagar on 23Aug2012 as discussed with tejas   
              SYSDATE,
              CPF_CRGL_CODE,
              CPF_CRSUBGL_CODE,
              CPF_CRACCT_NO,
              CPF_DRGL_CATG,
              CPF_DRGL_CODE,
              CPF_DRSUBGL_CODE,
              CPF_DRACCT_NO,
              CPF_CRGL_CATG,
              CPF_ST_CRGL_CATG,
              CPF_ST_CRGL_CODE,
              CPF_ST_CRSUBGL_CODE,
              CPF_ST_CRACCT_NO,
              CPF_ST_DRGL_CATG,
              CPF_ST_DRGL_CODE,
              CPF_ST_DRSUBGL_CODE,
              CPF_ST_DRACCT_NO,
              CPF_CESS_CRGL_CATG,
              CPF_CESS_CRGL_CODE,
              CPF_CESS_CRSUBGL_CODE,
              CPF_CESS_CRACCT_NO,
              CPF_CESS_DRGL_CATG,
              CPF_CESS_DRGL_CODE,
              CPF_CESS_DRSUBGL_CODE,
              CPF_CESS_DRACCT_NO,
              CPF_ST_CALC_FLAG,
              CPF_CESS_CALC_FLAG,
              1,
              V_ENCR_PAN,
              PRM_TRAN_CODE,
              PRM_FEE_PLAN
      from cms_prod_fees a,
          cms_prod_mast b--,
       --   cms_fee_plan e 
       where cpf_inst_code = prm_inst_code
       and cpf_prod_code = v_prod_code
       and a.cpf_inst_code = b.cpm_inst_code
       and a.cpf_prod_code = b.cpm_prod_code
     --  and a.cpf_inst_code = e.cfp_inst_code 
       and cpf_fee_plan   = v_from_feeplan -- e.cfp_plan_id
       and upper(CPM_MARC_PROD_FLAG)='N';
     --  order by a.cpf_valid_from ;


       IF SQL%ROWCOUNT = 0 THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'record not inserted from product master';
        RAISE EXP_REJECT_RECORD;

       END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN

        PRM_ERRMSG := 'No Fee Plan attached to this Card';
        RAISE EXP_REJECT_RECORD;

       WHEN EXP_REJECT_RECORD THEN
        RAISE;

       WHEN OTHERS THEN
        V_ERRMSG := 'ERROR FROM MAIN 3 =>' || SQLERRM;
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;

     END;

     ---------------------------------------------------
     --EN : Check fees attached at product level
     ---------------------------------------------------

    END IF;

 BEGIN
      
     DELETE FROM cms_card_excpfee 
       WHERE cce_inst_code = prm_inst_code
         AND cce_pan_code = v_hash_pan
         AND  cce_valid_from >trunc(SYSDATE);        
         
         
       EXCEPTION
       
       WHEN OTHERS THEN

        V_RESP_CDE := '21';
        V_ERRMSG   := 'error while deleting fee plan ' ||
                    SUBSTR(SQLERRM, 1, 100);
        RAISE EXP_REJECT_RECORD;
     END;

    V_RESP_CDE := '1';

    BEGIN

     EXECUTE IMMEDIATE V_COLM_QURY
       INTO V_NEW_VALUE
       USING PRM_INST_CODE, PRM_CARD_NUMBER; -- prm_card_number is used by sagar on 14Aug2012 as per jira defect 377

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting new values -- ' || '---' ||
                  SUBSTR(SQLERRM, 1, 100);
       V_RESP_CDE := '89';
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN

     BEGIN

       SELECT NVL(MAX(CCD_CALL_SEQ), 0) + 1
        INTO V_CALL_SEQ
        FROM CMS_CALLLOG_DETAILS
        WHERE CCD_INST_CODE = CCD_INST_CODE AND CCD_CALL_ID = PRM_CALL_ID AND
            CCD_PAN_CODE = V_HASH_PAN;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG   := 'record is not present in cms_calllog_details  ';
        V_RESP_CDE := '49';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while selecting frmo cms_calllog_details ' ||
                    SUBSTR(SQLERRM, 1, 100);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     INSERT INTO CMS_CALLLOG_DETAILS
       (CCD_INST_CODE,
        CCD_CALL_ID,
        CCD_PAN_CODE,
        CCD_CALL_SEQ,
        CCD_RRN,
        CCD_DEVL_CHNL,
        CCD_TXN_CODE,
        CCD_TRAN_DATE,
        CCD_TRAN_TIME,
        CCD_TBL_NAMES,
        CCD_COLM_NAME,
        CCD_OLD_VALUE,
        CCD_NEW_VALUE,
        CCD_COMMENTS,
        CCD_INS_USER,
        CCD_INS_DATE,
        CCD_LUPD_USER,
        CCD_LUPD_DATE,
        ccd_acct_no)--Added by Dnyaneshwar J on 25 June 2013 for Mantis Id 0011399
     VALUES
       (PRM_INST_CODE,
        PRM_CALL_ID,
        V_HASH_PAN,
        V_CALL_SEQ,
        PRM_RRN,
        PRM_DEL_CHANNEL,
        PRM_TRAN_CODE,
        PRM_TRAN_DATE,
        PRM_TRAN_TIME,
        V_TABLE_LIST,
        V_COLM_LIST,
        V_OLD_VALUE,
        V_NEW_VALUE,
        PRM_REMARK,
        PRM_INS_USER,
        SYSDATE,
        PRM_INS_USER,
        SYSDATE,
        V_CAP_ACCT_NO);--Added by Dnyaneshwar J on 25 June 2013 for Mantis Id 0011399

    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;

     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := ' Error while inserting into cms_calllog_details ' ||
                  SUBSTR(SQLERRM, 1, 100);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO PRM_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = PRM_INST_CODE AND
           CMS_DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
           CMS_RESPONSE_ID = V_RESP_CDE;

     PRM_ERRMSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       PRM_ERRMSG    := 'Problem while selecting data from response master1 ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 100);
       PRM_RESP_CODE := '89';
       ROLLBACK;
       RETURN;
    END;

  EXCEPTION
  
    when EXP_REJECT_RECORD then
    ROLLBACK;             --SN : Added for Defect MVHOST-346 

     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = PRM_INST_CODE AND
            CAM_ACCT_NO = V_CAP_ACCT_NO;

     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;

     END;

     BEGIN

       SELECT CMS_ISO_RESPCDE
        INTO PRM_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = PRM_INST_CODE AND
            CMS_DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       PRM_ERRMSG := V_ERRMSG;
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERRMSG    := 'Problem while selecting data from response master2 ' ||
                      V_RESP_CDE || ' ' || SUBSTR(SQLERRM, 1, 100);
        PRM_RESP_CODE := '89';
        RETURN;
     END;
     
     --SN : Added for Defect MVHOST-346 
     
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
      CTD_FEE_AMOUNT,
      CTD_TXN_CURR,
      CTD_ACTUAL_AMOUNT,
      CTD_BILL_AMOUNT,
      CTD_BILL_CURR,
      CTD_PROCESS_FLAG,
      CTD_PROCESS_MSG,
      CTD_RRN,
      CTD_SYSTEM_TRACE_AUDIT_NO,
      CTD_INST_CODE,
      CTD_CUSTOMER_CARD_NO_ENCR,
      CTD_CUST_ACCT_NUMBER,
      CTD_INS_DATE,
      CTD_INS_USER)
    VALUES
     (PRM_DEL_CHANNEL,
      PRM_TRAN_CODE,
      V_DR_CR_FLAG,
      PRM_MSG_TYPE,
      PRM_TRAN_MODE,
      PRM_TRAN_DATE,
      PRM_TRAN_TIME,
      V_HASH_PAN,
      '0.00',
      '0.00',
      PRM_CURRENCY_CODE,
      '0.00',
      '0.00',
      PRM_CURRENCY_CODE,
      DECODE(PRM_RESP_CODE, '00', 'Y', 'E'),
      PRM_ERRMSG,
      PRM_RRN,
      PRM_STAN,
      PRM_INST_CODE,
      V_ENCR_PAN,
      V_CAP_ACCT_NO,
      SYSDATE,
      PRM_INS_USER);

  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '89';
     PRM_ERRMSG    := 'Error while inserting in transactionlog detail ' ||
                   SUBSTR(SQLERRM, 1, 100);

  END;

  -- Sn create a entry in txnlog
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
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
      BANK_CODE,
      TOTAL_AMOUNT,
      CURRENCYCODE,
      PRODUCTID,
      CATEGORYID,
      TIPS,
      AUTH_ID,
      TRANS_DESC,
      TRANFEE_AMT,
      AMOUNT,
      SYSTEM_TRACE_AUDIT_NO,
      INSTCODE,
      FEECODE,
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      ERROR_MSG,
      ADD_INS_DATE,
      ADD_INS_USER,
      RESPONSE_ID,
      REMARK,
      REASON,
      PROCESSES_FLAG,
      CR_DR_FLAG,     -- Added on 09OCT2012
      IPADDRESS,       -- Added on 09OCT2012
      ADD_LUPD_USER  
      )
    VALUES
     (PRM_MSG_TYPE,
      PRM_RRN,
      PRM_DEL_CHANNEL,
      SYSDATE,
      PRM_TRAN_CODE,
      1,
      PRM_TRAN_MODE,
      DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
      PRM_RESP_CODE,
      PRM_TRAN_DATE,
      PRM_TRAN_TIME,
      V_HASH_PAN,
      PRM_INST_CODE,
      '0.00',
      PRM_CURRENCY_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      0,
      V_AUTH_ID,
      SUBSTR('Update Feeplan - ' || V_REASON, 1, 40),
      '0.00',
      '0.00',
      PRM_STAN,
      PRM_INST_CODE,
      V_FEECODE,
      'N',
      V_ENCR_PAN,
      V_CAP_PROXYNUMBER,
      PRM_REVERSAL_CODE,
      V_CAP_ACCT_NO,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      PRM_ERRMSG,
      SYSDATE,
      PRM_INS_USER,
      V_RESP_CDE,
      PRM_REMARK,
      V_REASON,
      DECODE(PRM_RESP_CODE, '00', 'Y', 'E'),
      V_DR_CR_FLAG, -- Added on 09OCT2012
      PRM_IP_ADDR,  -- Added on 09OCT2012
      PRM_INS_USER  -- Added on 09OCT2012 
      );
  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '21';
     PRM_ERRMSG    := 'Error while inserting in transactionlog ' ||
                   SUBSTR(SQLERRM, 1, 100);

  END;
  
  --EN : Added for Defect MVHOST-346 

    -- Sn create a entry in txnlog
    WHEN OTHERS THEN
     ROLLBACK;

     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = PRM_INST_CODE AND
            CAM_ACCT_NO = V_CAP_ACCT_NO;

     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;

     END;

     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO PRM_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = PRM_INST_CODE AND
            CMS_DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
            CMS_RESPONSE_ID = '21';

       PRM_ERRMSG := 'Error from others exception ' ||
                  SUBSTR(SQLERRM, 1, 100);
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERRMSG    := 'Problem while selecting data from response master3 ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 100);
        PRM_RESP_CODE := '89';
        RETURN;
     END;
     
     --SN : Added for Defect MVHOST-346 
     
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
      CTD_FEE_AMOUNT,
      CTD_TXN_CURR,
      CTD_ACTUAL_AMOUNT,
      CTD_BILL_AMOUNT,
      CTD_BILL_CURR,
      CTD_PROCESS_FLAG,
      CTD_PROCESS_MSG,
      CTD_RRN,
      CTD_SYSTEM_TRACE_AUDIT_NO,
      CTD_INST_CODE,
      CTD_CUSTOMER_CARD_NO_ENCR,
      CTD_CUST_ACCT_NUMBER,
      CTD_INS_DATE,
      CTD_INS_USER)
    VALUES
     (PRM_DEL_CHANNEL,
      PRM_TRAN_CODE,
      V_DR_CR_FLAG,
      PRM_MSG_TYPE,
      PRM_TRAN_MODE,
      PRM_TRAN_DATE,
      PRM_TRAN_TIME,
      V_HASH_PAN,
      '0.00',
      '0.00',
      PRM_CURRENCY_CODE,
      '0.00',
      '0.00',
      PRM_CURRENCY_CODE,
      DECODE(PRM_RESP_CODE, '00', 'Y', 'E'),
      PRM_ERRMSG,
      PRM_RRN,
      PRM_STAN,
      PRM_INST_CODE,
      V_ENCR_PAN,
      V_CAP_ACCT_NO,
      SYSDATE,
      PRM_INS_USER);

  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '89';
     PRM_ERRMSG    := 'Error while inserting in transactionlog detail ' ||
                   SUBSTR(SQLERRM, 1, 100);

  END;

  -- Sn create a entry in txnlog
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
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
      BANK_CODE,
      TOTAL_AMOUNT,
      CURRENCYCODE,
      PRODUCTID,
      CATEGORYID,
      TIPS,
      AUTH_ID,
      TRANS_DESC,
      TRANFEE_AMT,
      AMOUNT,
      SYSTEM_TRACE_AUDIT_NO,
      INSTCODE,
      FEECODE,
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      ERROR_MSG,
      ADD_INS_DATE,
      ADD_INS_USER,
      RESPONSE_ID,
      REMARK,
      REASON,
      PROCESSES_FLAG,
      CR_DR_FLAG,     -- Added on 09OCT2012
      IPADDRESS,       -- Added on 09OCT2012
      ADD_LUPD_USER  
      )
    VALUES
     (PRM_MSG_TYPE,
      PRM_RRN,
      PRM_DEL_CHANNEL,
      SYSDATE,
      PRM_TRAN_CODE,
      1,
      PRM_TRAN_MODE,
      DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
      PRM_RESP_CODE,
      PRM_TRAN_DATE,
      PRM_TRAN_TIME,
      V_HASH_PAN,
      PRM_INST_CODE,
      '0.00',
      PRM_CURRENCY_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      0,
      V_AUTH_ID,
      SUBSTR('Update Feeplan - ' || V_REASON, 1, 40),
      '0.00',
      '0.00',
      PRM_STAN,
      PRM_INST_CODE,
      V_FEECODE,
      'N',
      V_ENCR_PAN,
      V_CAP_PROXYNUMBER,
      PRM_REVERSAL_CODE,
      V_CAP_ACCT_NO,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      PRM_ERRMSG,
      SYSDATE,
      PRM_INS_USER,
      V_RESP_CDE,
      PRM_REMARK,
      V_REASON,
      DECODE(PRM_RESP_CODE, '00', 'Y', 'E'),
      V_DR_CR_FLAG, -- Added on 09OCT2012
      PRM_IP_ADDR,  -- Added on 09OCT2012
      PRM_INS_USER  -- Added on 09OCT2012 
      );
  EXCEPTION
    WHEN OTHERS THEN
     PRM_RESP_CODE := '21';
     PRM_ERRMSG    := 'Error while inserting in transactionlog ' ||
                   SUBSTR(SQLERRM, 1, 100);

  END;
  
  --EN : Added for Defect MVHOST-346 

  END;
  
END;
/
SHOW ERROR;