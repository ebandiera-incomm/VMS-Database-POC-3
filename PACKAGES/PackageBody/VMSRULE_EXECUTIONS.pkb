create or replace PACKAGE body                              VMSCMS.VMSRULE_EXECUTIONS
AS
PROCEDURE ADDRESS_VERIFICATION_RULE(
    p_left_term_in       IN VARCHAR2,
    p_right_term_in      IN VARCHAR2,
    p_operator_in        IN VARCHAR2,
    P_inst_code_IN       IN VARCHAR2,
    P_card_number_IN     IN VARCHAR2,
    P_ZIP_CODE_in        IN VARCHAR2,
    P_ADDRVERIFY_FLAG_in IN VARCHAR2,
    P_cust_addr          IN VARCHAR2 DEFAULT NULL,
    p_msg_rsncde_in      IN VARCHAR2,
    p_resp_msg_out       OUT VARCHAR2,
    p_resp_stat_out      OUT VARCHAR2)
AS
  V_ERR_MSG  VARCHAR2(900) := 'OK';
  V_RESP_CDE VARCHAR2(5)   := '1';
  V_CAP_CUST_CODE CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  v_txn_nonnumeric_chk  VARCHAR2 (2);
  v_cust_nonnumeric_chk VARCHAR2 (2);
  V_ADDRVRIFY_FLAG CHARACTER(1);
  V_ZIP_CODE VARCHAR2(20);
  v_first3_custzip cms_addr_mast.cam_pin_code%type;
  v_inputzip_length NUMBER(3);
  v_numeric_zip cms_addr_mast.cam_pin_code%type;
  v_removespace_txn  VARCHAR2 (10);
  v_removespace_cust VARCHAR2 (10);
  v_zip_code_trimmed VARCHAR2(10);
  V_ADDR_ONE CMS_ADDR_MAST.CAM_ADD_ONE%type;
  V_ADDR_TWO CMS_ADDR_MAST.CAM_ADD_TWO%type;
  V_REMOVESPACE_ADDRCUST        VARCHAR2(100);
  V_REMOVESPACE_ADDRTXN         VARCHAR2(20);
  V_REMOVESPACECHAR_ADDRCUST    VARCHAR2(100);
  V_REMOVESPACECHAR_ADDRTXN     VARCHAR2(20);
  V_ADDR_VERFY                  NUMBER;
  V_REMOVESPACECHAR_ADDRONECUST VARCHAR2(100);
  v_removespacenum_txn          VARCHAR2 (10);
  V_REMOVESPACENUM_CUST         VARCHAR2 (10);
  V_REMOVESPACECHAR_TXN         VARCHAR2 (10);
  V_REMOVESPACECHAR_CUST        VARCHAR2 (10);
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ADDR_VERFY_RESPONSE     VARCHAR2 (10);
  v_addrverification_flag   VARCHAR2 (10);
  V_ADDR_VERFY_RESPONSE_out VARCHAR2 (10);
  EXP_REJECT_RECORD         EXCEPTION;
  v_query_str               VARCHAR2(1000);
  V_VISA_TOKEN CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
  v_card_type         cms_appl_pan.cap_card_type%TYPE;
  V_ENCRYPT_ENABLE    CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;

  --V_MASTER_TOKEN CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
BEGIN
  BEGIN
    V_HASH_PAN := GETHASH(P_card_number_IN);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_card_number_IN);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;

  --End Generate HashKEY
      BEGIN
      SELECT cap_prod_code, cap_card_type
        INTO v_prod_code, v_card_type
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = v_hash_pan;
     EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_err_msg := 'PAN details not available in CMS_APPL_PAN';
         v_resp_cde := '21';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Error while fetching data from pan master '
            || SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '21';
         RAISE exp_reject_record;
      END;

      --Sn check if Encrypt Enabled
      BEGIN
       SELECT  CPC_ENCRYPT_ENABLE
         INTO  V_ENCRYPT_ENABLE
         FROM  CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INST_CODE_IN
          AND CPC_PROD_CODE = V_PROD_CODE
          AND CPC_CARD_TYPE = V_CARD_TYPE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_resp_cde := '16';
            v_err_msg   := 'Invalid Prod Code Card Type ' || V_PROD_CODE || ' ' || V_CARD_TYPE;
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_resp_cde := '12';
            v_err_msg   := 'Problem while selecting product category details' || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    --En check if Encrypt Enabled


  IF P_ADDRVERIFY_FLAG_in IN('2','3') THEN
    v_zip_code_trimmed       :=TRIM(P_ZIP_CODE_IN);
   IF trim(P_ZIP_CODE_in)   IS NULL THEN --tag present but value empty or space
      V_ADDR_VERFY_RESPONSE_out := 'U';
    ELSE
      BEGIN
        SELECT CAP_CUST_CODE
        INTO V_CAP_CUST_CODE
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE_in
        AND CAP_PAN_CODE    = V_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERR_MSG := 'No data found in CMS APPL PAN MAST in CUST CODE AVS  ' || V_HASH_PAN;
        RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
        SELECT decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
          trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one)),
          trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two))
        INTO V_ZIP_CODE,
             v_addr_one,
             v_addr_two
        FROM CMS_ADDR_MAST
        WHERE CAM_INST_CODE = P_INST_CODE_in
        AND CAM_CUST_CODE   = V_CAP_CUST_CODE
        AND CAM_ADDR_FLAG   = 'P';
        v_first3_custzip   := SUBSTR(V_ZIP_CODE,1,3);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'No data found in CMS ADDR MAST in AVS  ' || V_HASH_PAN;
        RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error while seelcting CMS ADDR MAST in AVS ' ||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
      END;
      SELECT REGEXP_instr(P_ZIP_CODE_in,'([A-Z,a-z])')
      INTO v_txn_nonnumeric_chk
      FROM dual;
      SELECT REGEXP_instr(V_ZIP_CODE,'([A-Z,a-z])')
      INTO v_cust_nonnumeric_chk
      FROM dual;
      IF v_txn_nonnumeric_chk                = '0' AND v_cust_nonnumeric_chk = '0' THEN -- It Means txn and cust zip code is numeric
        IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) THEN
          V_ADDR_VERFY_RESPONSE_out         := 'W';
        ELSE
          V_ADDR_VERFY_RESPONSE_out := 'N';
        END IF;
      elsif v_txn_nonnumeric_chk    <> '0' AND v_cust_nonnumeric_chk = '0' THEN -- It Means txn zip code is aplhanumeric and cust zip code is numeric
        IF v_zip_code_trimmed        = v_zip_code THEN
          V_ADDR_VERFY_RESPONSE_out := 'W';
        ELSE
          V_ADDR_VERFY_RESPONSE_out := 'N';
        END IF;
      elsif v_txn_nonnumeric_chk = '0' AND v_cust_nonnumeric_chk <> '0' THEN -- It Means txn zip code is numeric and cust zip code is alphanumeric
        SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '')
        INTO v_numeric_zip
        FROM dual;
        IF v_zip_code_trimmed        = v_numeric_zip THEN
          V_ADDR_VERFY_RESPONSE_out := 'W';
        ELSE
          V_ADDR_VERFY_RESPONSE_out := 'N';
        END IF;
      elsif v_txn_nonnumeric_chk      <> '0' AND v_cust_nonnumeric_chk <> '0' THEN -- It Means txn zip code and cust zip code is alphanumeric
        v_inputzip_length             := LENGTH(p_zip_code_in);
        IF v_inputzip_length           = LENGTH(v_zip_code) THEN -- both txn and cust zip length is equal
          IF v_zip_code_trimmed        = v_zip_code THEN
            V_ADDR_VERFY_RESPONSE_out := 'W';
          ELSE
            V_ADDR_VERFY_RESPONSE_out := 'N';
          END IF;
        ELSE
          SELECT REGEXP_REPLACE(p_zip_code_in,'([ ])', '')
          INTO v_removespace_txn
          FROM dual;
          SELECT REGEXP_REPLACE(v_zip_code,'([ ])', '')
          INTO v_removespace_cust
          FROM dual;
          IF v_removespace_txn               = v_removespace_cust THEN
            V_ADDR_VERFY_RESPONSE_out       := 'W';
          elsif LENGTH(v_removespace_txn)   >=3 THEN
            IF SUBSTR(v_removespace_txn,1,3) = SUBSTR(v_removespace_cust,1,3) THEN
              V_ADDR_VERFY_RESPONSE_out     := 'W';
            ELSIF v_inputzip_length         >= 6 THEN
              SELECT REGEXP_REPLACE (P_ZIP_CODE_in, '([0-9 ])', '')
              INTO v_removespacenum_txn
              FROM DUAL;
              SELECT REGEXP_REPLACE (V_ZIP_CODE, '([0-9 ])', '')
              INTO V_REMOVESPACENUM_CUST
              FROM DUAL;
              SELECT REGEXP_REPLACE (P_ZIP_CODE_in, '([a-zA-Z ])', '')
              INTO v_removespacechar_txn
              FROM DUAL;
              SELECT REGEXP_REPLACE (V_ZIP_CODE, '([a-zA-Z ])', '')
              INTO V_REMOVESPACECHAR_CUST
              FROM DUAL;
              IF SUBSTR (v_removespacenum_txn, 1, 3)     = SUBSTR (V_REMOVESPACENUM_CUST, 1, 3) THEN
                V_ADDR_VERFY_RESPONSE_out               := 'W';
              ELSIF SUBSTR (V_REMOVESPACECHAR_TXN, 1, 3) = SUBSTR (V_REMOVESPACECHAR_CUST, 1, 3) THEN
                V_ADDR_VERFY_RESPONSE_out               := 'W';
              ELSE
                V_ADDR_VERFY_RESPONSE_out := 'N';
              END IF;
            ELSE
              V_ADDR_VERFY_RESPONSE_out := 'N';
            END IF;
          ELSE
            V_ADDR_VERFY_RESPONSE_out := 'N';
          END IF;
        END IF;
      ELSE
        V_ADDR_VERFY_RESPONSE_out := 'N';
      END IF;
    END IF;
    IF(V_ADDR_VERFY_RESPONSE_out ='W') AND P_ADDRVERIFY_FLAG_in IN('3') THEN
      SELECT REGEXP_REPLACE (v_addr_one
        ||v_addr_TWO,'[^[:digit:]]')
      INTO v_removespacechar_addrcust
      FROM DUAL;
      SELECT REGEXP_REPLACE (V_ADDR_ONE,'[^[:digit:]]')
      INTO V_REMOVESPACECHAR_ADDRONECUST
      FROM DUAL;
      SELECT REGEXP_REPLACE (P_CUST_ADDR,'[^[:digit:]]')
      INTO V_REMOVESPACECHAR_ADDRTXN
      FROM DUAL;
      SELECT REGEXP_REPLACE (P_CUST_ADDR, '([ ])', '')
      INTO V_REMOVESPACE_addrtxn
      FROM DUAL;
      SELECT REGEXP_REPLACE (v_addr_one
        ||v_addr_TWO, '([ ])', '')
      INTO V_REMOVESPACE_addrcust
      FROM DUAL;
      IF(V_REMOVESPACE_ADDRCUST           IS NOT NULL) THEN
        IF(V_REMOVESPACE_ADDRCUST          =SUBSTR(V_REMOVESPACE_ADDRTXN,1,LENGTH(V_REMOVESPACE_ADDRCUST))) THEN
          V_ADDR_VERFY                    :=1;
        elsif(V_REMOVESPACECHAR_ADDRCUST   =V_REMOVESPACECHAR_ADDRTXN) THEN
          V_ADDR_VERFY                    :=1;
        ELSIF(V_REMOVESPACECHAR_ADDRONECUST=V_REMOVESPACECHAR_ADDRTXN) THEN
          V_ADDR_VERFY                    :=1;
        ELSE
          V_ADDR_VERFY:=-1;
        END IF;
        IF(V_ADDR_VERFY              =1) THEN
          V_ADDR_VERFY_RESPONSE_out := 'Y';
        ELSE
          V_ADDR_VERFY_RESPONSE_out := 'Z';
        END IF;
      ELSE
        V_ADDR_VERFY_RESPONSE_out := 'Z';
      END IF;
    END IF;
  ELSIF P_ADDRVERIFY_FLAG_in IN('1') THEN

     BEGIN
        SELECT CAP_CUST_CODE
        INTO V_CAP_CUST_CODE
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE_in
        AND CAP_PAN_CODE    = V_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERR_MSG := 'No data found in CMS APPL PAN MAST in CUST CODE AVS  ' || V_HASH_PAN;
        RAISE EXP_REJECT_RECORD;
      END;
    BEGIN
      SELECT trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one)),
             trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two))
      INTO v_addr_one,
           v_addr_two
      FROM CMS_ADDR_MAST
      WHERE CAM_INST_CODE = P_INST_CODE_in
      AND CAM_CUST_CODE   = V_CAP_CUST_CODE
      AND CAM_ADDR_FLAG   = 'P';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE := '21';
      V_ERR_MSG  := 'No data found in CMS ADDR MAST in AVS  ' || V_HASH_PAN;
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE := '21';
      V_ERR_MSG  := 'Error while seelcting CMS ADDR MAST in AVS ' ||SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    SELECT REGEXP_REPLACE (v_addr_one
      ||v_addr_TWO,'[^[:digit:]]')
    INTO v_removespacechar_addrcust
    FROM DUAL;
    SELECT REGEXP_REPLACE (V_ADDR_ONE,'[^[:digit:]]')
    INTO V_REMOVESPACECHAR_ADDRONECUST
    FROM DUAL;
    SELECT REGEXP_REPLACE (P_CUST_ADDR,'[^[:digit:]]')
    INTO V_REMOVESPACECHAR_ADDRTXN
    FROM DUAL;
    SELECT REGEXP_REPLACE (P_CUST_ADDR, '([ ])', '')
    INTO V_REMOVESPACE_addrtxn
    FROM DUAL;
    SELECT REGEXP_REPLACE (v_addr_one
      ||v_addr_TWO, '([ ])', '')
    INTO V_REMOVESPACE_addrcust
    FROM DUAL;
    IF(V_REMOVESPACE_ADDRCUST           IS NOT NULL) THEN
      IF(V_REMOVESPACE_ADDRCUST          =SUBSTR(V_REMOVESPACE_ADDRTXN,1,LENGTH(V_REMOVESPACE_ADDRCUST))) THEN
        V_ADDR_VERFY                    :=1;
      elsif(V_REMOVESPACECHAR_ADDRCUST   =V_REMOVESPACECHAR_ADDRTXN) THEN
        V_ADDR_VERFY                    :=1;
      ELSIF(V_REMOVESPACECHAR_ADDRONECUST=V_REMOVESPACECHAR_ADDRTXN) THEN
        V_ADDR_VERFY                    :=1;
      ELSE
        V_ADDR_VERFY:=-1;
      END IF;
      IF(V_ADDR_VERFY              =1) THEN
        V_ADDR_VERFY_RESPONSE_out := 'Y';
      ELSE
        V_ADDR_VERFY_RESPONSE_out := 'Z';
      END IF;
    END IF;
  END IF;
  BEGIN
    v_query_str :='SELECT CASE WHEN :1 '||p_operator_in||' :2  THEN ''TRUE'' ELSE ''FALSE'' END FROM dual';
    EXECUTE IMMEDIATE v_query_str INTO p_resp_stat_out USING TRIM(p_right_term_in) ,
    V_ADDR_VERFY_RESPONSE_out;
    p_resp_msg_out :='OK';
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_stat_out :='FALSE';
    p_resp_msg_out  := 'Problem while CHARGEBACK COUNT RULE :: ' || SUBSTR (SQLERRM, 1, 200);
  END;
  p_resp_msg_out :='OK';
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  p_resp_stat_out :='FALSE';
  p_resp_msg_out  := 'Problem while ADDR VERIFICATION CHECK RULE:: ' || V_ERR_MSG;
WHEN OTHERS THEN
  p_resp_stat_out :='FALSE';
  p_resp_msg_out  := 'Problem while ADDR VERIFICATION CHECK  RULE :: ' || V_ERR_MSG;
END;
PROCEDURE CHARGEBACK_COUNT_RULE(
    p_left_term_in         IN VARCHAR2,
    p_right_term_in        IN VARCHAR2,
    P_count_identifier_IN  IN VARCHAR2,
    P_chargeback_period_IN IN VARCHAR2,
    p_operator_in          IN VARCHAR2,
    P_inst_code_IN         IN VARCHAR2,
    P_card_number_IN       IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2)
AS
  v_query_str VARCHAR2(1000);
BEGIN
  v_query_str :='SELECT CASE WHEN  COUNT(1)   '||p_operator_in|| ' :1 THEN ''TRUE'' ELSE ''FALSE'' END FROM CMS_DISPUTE_TXNS WHERE CDT_PAN_CODE =GETHASH(:2)
  AND upper(CDT_DISPUTE_STATUS) in (''O'',''A'') AND CDT_INS_DATE between SYSDATE-:3 and sysdate';
  EXECUTE IMMEDIATE v_query_str INTO p_resp_stat_out USING P_count_identifier_IN ,
  P_card_number_IN,
  P_chargeback_period_IN;
  p_resp_msg_out :='OK';
EXCEPTION
WHEN OTHERS THEN
  p_resp_stat_out :='FALSE';
  p_resp_msg_out  := 'Problem while CHARGEBACK COUNT RULE :: ' || SUBSTR (SQLERRM, 1, 200);
END;
PROCEDURE DEVICEID_COUNT_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in         IN VARCHAR2,
    P_count_identifier_IN IN VARCHAR2,
    P_inst_code_IN        IN VARCHAR2,
    P_card_number_IN      IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2)
AS
  v_query_str VARCHAR2(1000);
BEGIN
  BEGIN
    v_query_str := 'SELECT  CASE WHEN COUNT(DISTINCT(NVL(VTI_TOKEN_DEVICE_ID,VTI_PAYMENTAPPLN_INSTANCEID)))  '||p_operator_in|| ' :1 THEN ''TRUE'' ELSE ''FALSE''  END
    FROM VMS_TOKEN_INFO  WHERE
    INSTR('',''||(select cip_param_value  FROM cms_inst_param where cip_param_key=''TOKEN_TYPE'')||'','', '',''||VTI_TOKEN_TYPE||'','') = 0
    AND VTI_TOKEN_STAT      <> ''D''
    AND (((TRIM(VTI_TOKEN_DEVICE_ID) IS NOT NULL) OR (TRIM(VTI_PAYMENTAPPLN_INSTANCEID) IS NOT NULL))) AND VTI_TOKEN_PAN=GETHASH(:2)';
    EXECUTE IMMEDIATE v_query_str INTO p_resp_stat_out USING p_right_term_in,
    P_card_number_IN;
    p_resp_msg_out :='OK';
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_stat_out :='FALSE';
    p_resp_msg_out  := 'Problem while DEVICE ID COUNT RULE :: ' || SUBSTR (SQLERRM, 1, 200);
  END;
END;
PROCEDURE WALLETIDENTIFIER_COUNT_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in         IN VARCHAR2,
    p_interchange_name_in IN VARCHAR2,
    P_inst_code_IN        IN VARCHAR2,
    P_card_number_IN      IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2)
AS
  v_query_str VARCHAR2(1000);
BEGIN
  IF p_interchange_name_in    ='VISA_INCHGE_ID' THEN
    v_query_str              := 'SELECT CASE WHEN COUNT(DISTINCT(VTI_TOKEN_REQUESTOR_ID)) '||p_operator_in|| ' :1 THEN ''TRUE''  ELSE ''FALSE''   END  FROM VMS_TOKEN_INFO
    WHERE
    INSTR('',''||(select cip_param_value  FROM cms_inst_param where cip_param_key=''TOKEN_TYPE'')||'','', '',''||VTI_TOKEN_TYPE||'','') = 0
    AND VTI_TOKEN_STAT         <> ''D''
    AND TRIM(VTI_TOKEN_REQUESTOR_ID) IS NOT NULL       AND VTI_TOKEN_PAN           =GETHASH(:2)';
  ELSIF p_interchange_name_in ='MASTER_INCHGE_ID' THEN
    v_query_str              := 'SELECT CASE WHEN COUNT(DISTINCT(VTI_WALLET_IDENTIFIER)) '||p_operator_in|| ' :1 THEN ''TRUE'' ELSE ''FALSE''   END  FROM VMS_TOKEN_INFO WHERE
    INSTR('',''||(select cip_param_value  FROM cms_inst_param where cip_param_key=''TOKEN_TYPE'')||'','', '',''||VTI_TOKEN_TYPE||'','') = 0
    AND VTI_TOKEN_STAT         <> ''D''  AND TRIM(VTI_WALLET_IDENTIFIER) IS NOT NULL
    AND VTI_TOKEN_PAN    =GETHASH(:2)' ;
  END IF;
  IF v_query_str IS NOT NULL THEN
    EXECUTE IMMEDIATE v_query_str INTO p_resp_stat_out USING p_right_term_in,
    P_card_number_IN;
    p_resp_msg_out :='OK';
  ELSE
    p_resp_stat_out :='FALSE';
    p_resp_msg_out  := 'TOKEN NOT BELONGS ON VISA or MASTER';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  p_resp_stat_out :='FALSE';
  p_resp_msg_out  := 'Problem while WALLETI DENTIFIER COUNT RULE :: ' || SUBSTR (SQLERRM, 1, 200);
END;
PROCEDURE LASTACTIVE_PERIOD_RULE(
    p_left_term_in   IN VARCHAR2,
    p_right_term_in  IN VARCHAR2,
    p_operator_in    IN VARCHAR2,
    P_inst_code_IN   IN VARCHAR2,
    P_card_number_IN IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2)
AS
  v_query_str VARCHAR2(1000);
BEGIN
  v_query_str := 'SELECT  CASE  WHEN SYSDATE-CAP_LAST_TXNDATE   '|| p_operator_in || '  TO_NUMBER(:1)   THEN ''TRUE'' ELSE ''FALSE'' END
  FROM  CMS_APPL_PAN WHERE  CAP_PAN_CODE=GETHASH(:2) AND CAP_INST_CODE=:3 ';
  EXECUTE IMMEDIATE v_query_str INTO p_resp_stat_out USING p_right_term_in,
  P_card_number_IN,
  P_inst_code_IN;
  p_resp_msg_out :='OK';
EXCEPTION
WHEN OTHERS THEN
  p_resp_msg_out  := 'Problem while LASTACTIVE PERIOD RULE ::' || SUBSTR (SQLERRM, 1, 200);
  p_resp_stat_out :='FALSE';
END;
PROCEDURE AMEX_RAN_MATCH(
    p_program_id_in  IN VARCHAR2,
    p_merchant_id_in IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_result_out OUT VARCHAR2,
    p_ran_matched_merchant_id_out  OUT VARCHAR2)
AS

/***************************************************************************************
         * Modified By        : UBAIDUR RAHMAN H.
         * Modified Date      : 19-Sep-2019.
         * Modified Reason    : AMEX RAN PERFORMANCE ISSUES.
         * Reviewer           : Saravana Kumar A
         * Reviewed Date      : 20-Sep-2019.
         * Build Number       : VMS_RSI0210

		 * Modified By        : UBAIDUR RAHMAN H.
         * Modified Date      : 15-Apr-2020.
         * Modified Reason    : RAN analysis to mitigate system overhead for Giftcard RAN programs.
         * Reviewer           : Saravana Kumar A
         * Reviewed Date      : 17-Apr-2020.
         * Build Number       : VMS_R29_B2

		 * Modified By        : UBAIDUR RAHMAN.H
         * Modified Date      : 20-Oct-2020.
         * Modified Reason    : VMS-3132 - Redemption Transactions processed more than 6 seconds
														due to Amex Ran Merchant Id validation.
         * Reviewer           : Puvanesh.
         * Reviewed Date      : 20-Oct-2020.
         * Build Number       : VMS_R37_B2

	 * Modified By       : Rajan Devakotta
  * Modified Date     : 11-NOV-2020
  * Purpose           : VMS-3178 - Ran report original merchant ID support
  * Reviewer          : Saravanakumar
  * Build Number      : VMSGPRHOST_R39_B0001

***************************************************************************************/


BEGIN
  p_resp_msg_out:='OK';
  BEGIN


   SELECT MERCH_ID_OUT
   INTO p_ran_matched_merchant_id_out
   FROM
   (SELECT
   var_merchant_id MERCH_ID_OUT,
   row_number() OVER(order by length(var_merchant_id) asc) AS RN
    FROM
        vms_amex_ran_program_merchant
    WHERE
        var_program_id = p_program_id_in
    AND var_merchant_id IN (
        TRIM(p_merchant_id_in),
        substr(TRIM(p_merchant_id_in), 1, length(var_merchant_id)),
        substr(TRIM(p_merchant_id_in), - length(var_merchant_id))
    )
    AND upper(var_status) = 'ACTIVE')
    WHERE RN = 1;

    p_result_out :='true';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN

    p_result_out := 'false';
    p_ran_matched_merchant_id_out := NULL;
  WHEN OTHERS THEN
    p_resp_msg_out:='Error while selecting from AMEX_RAN_MATCH_PROGRAM_MERCHANT'||sqlerrm;
    p_result_out  :='false';
    p_ran_matched_merchant_id_out := NULL;
END;
EXCEPTION
WHEN OTHERS THEN
  p_resp_msg_out:='Error in Main'||sqlerrm;
  p_result_out  :='false';
END;
PROCEDURE MERCHANT_RULE(
    p_merchant_id_in  IN VARCHAR2,
    p_merchant_name_in IN VARCHAR2,
    p_prod_code_in IN VARCHAR2,  -- added for vms-6337 on 14-Sep-2022 By Bhavani
	p_prod_catg_in IN NUMBER,  -- added for vms-6337 on 14-Sep-2022 By Bhavani
    p_resp_msg_out OUT VARCHAR2,
    p_result_out OUT VARCHAR2,
    p_rule_id_out OUT VARCHAR2,
    p_rule_name_out OUT VARCHAR2)
AS
v_merchant_id VMS_MERCHANT_RULE.VMR_RULE_NAME%type;
v_merchant_name VMS_MERCHANT_RULE.VMR_RULE_NAME%type;
BEGIN
  p_resp_msg_out:='OK';
  p_result_out := 'true';
  v_merchant_id := TRIM(p_merchant_id_in);
  v_merchant_name := TRIM(p_merchant_name_in);
  BEGIN
    SELECT
    VMR_RULE_ID,VMR_RULE_NAME
    INTO p_rule_id_out,p_rule_name_out
    FROM VMS_MERCHANT_RULE
    WHERE ((VMR_RULE_VALUE = v_merchant_id
    and VMR_RULE_TYPE  = '1') or
    (UPPER(VMR_RULE_VALUE) =UPPER(v_merchant_name)
    and VMR_RULE_TYPE   = '2') or
    (UPPER(VMR_RULE_VALUE) = UPPER(v_merchant_id||'|'||v_merchant_name)
    and VMR_RULE_TYPE   ='3') )
    AND (vmr_prod_code = p_prod_code_in AND vmr_card_type = p_prod_catg_in) -- added for vms-6337 on 14-Sep-2022 By Bhavani
    and VMR_RULE_STATUS = 'A' and rownum = 1 order by VMR_RULE_TYPE;
  EXCEPTION
   WHEN NO_DATA_FOUND
     THEN
      BEGIN
        SELECT
        VMR_RULE_ID,VMR_RULE_NAME
        INTO p_rule_id_out,p_rule_name_out
        FROM VMS_MERCHANT_RULE
        WHERE ((VMR_RULE_VALUE = v_merchant_id
        and VMR_RULE_TYPE  = '1') or
        (UPPER(VMR_RULE_VALUE) =UPPER(v_merchant_name)
        and VMR_RULE_TYPE   = '2') or
        (UPPER(VMR_RULE_VALUE) = UPPER(v_merchant_id||'|'||v_merchant_name)
        and VMR_RULE_TYPE   ='3') )
        AND (vmr_prod_code = p_prod_code_in AND vmr_card_type IS NULL)
        and VMR_RULE_STATUS = 'A' and rownum = 1 order by VMR_RULE_TYPE;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
            BEGIN
            SELECT
            VMR_RULE_ID,VMR_RULE_NAME
            INTO p_rule_id_out,p_rule_name_out
            FROM VMS_MERCHANT_RULE
            WHERE ((VMR_RULE_VALUE = v_merchant_id
            and VMR_RULE_TYPE  = '1') or
            (UPPER(VMR_RULE_VALUE) =UPPER(v_merchant_name)
            and VMR_RULE_TYPE   = '2') or
            (UPPER(VMR_RULE_VALUE) = UPPER(v_merchant_id||'|'||v_merchant_name)
            and VMR_RULE_TYPE   ='3') )
            AND (vmr_prod_code IS NULL AND vmr_card_type IS NULL)
            and VMR_RULE_STATUS = 'A' and rownum = 1 order by VMR_RULE_TYPE;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
           p_result_out  :='false';
           WHEN OTHERS THEN
            p_resp_msg_out:='Error while selecting from vms_merchant_rule'||sqlerrm;
            p_result_out  :='false';
          END;
        WHEN OTHERS THEN
            p_resp_msg_out:='Error while selecting from vms_merchant_rule'||sqlerrm;
            p_result_out  :='false';
      END;
  WHEN OTHERS THEN
    p_resp_msg_out:='Error while selecting from vms_merchant_blocked_dtls'||sqlerrm;
    p_result_out  :='false';
END;

BEGIN
 if p_result_out = 'true' then
    Begin
    update VMS_MERCHANT_RULE
    set VMR_ENFORCED_COUNT = VMR_ENFORCED_COUNT+1 ,VMR_LUPD_AT = sysdate
    where VMR_RULE_ID = p_rule_id_out;
    IF SQL%ROWCOUNT = 0 THEN
            p_resp_msg_out  := 'Problem while updating data in vms_merchant_blocked_dtls ' ||
                          SUBSTR(SQLERRM, 1, 300);
     END IF;
        EXCEPTION
           WHEN OTHERS
            THEN
                p_resp_msg_out :=
                    'Problem while updating data in vms_merchant_blocked_dtls '
                    || SUBSTR (SQLERRM, 1, 300);
        END;
        END IF;
    end;
EXCEPTION
WHEN OTHERS THEN
  p_resp_msg_out:='Error in Main'||sqlerrm;
  p_result_out  :='false';
END;
END;
/
show error