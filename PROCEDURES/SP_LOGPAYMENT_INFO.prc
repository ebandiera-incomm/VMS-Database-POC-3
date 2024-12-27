CREATE OR REPLACE
PROCEDURE VMSCMS.SP_LOGPAYMENT_INFO(
    p_inst_code     IN NUMBER,
    p_auth_id       IN NUMBER,
    p_pan_code      IN VARCHAR2,
    p_rrn           IN VARCHAR,
    p_payment_type  IN VARCHAR2,
    p_unique_rn     IN VARCHAR2,
    p_spu_id        IN VARCHAR2,
    p_sp_add        IN VARCHAR2,
    p_add_si        IN VARCHAR2,
    p_payer_id      IN VARCHAR2,
    p_payer_add     IN VARCHAR2,
    p_payer_city    IN VARCHAR2,
    p_payer_state   IN VARCHAR2,
    p_payer_coun    IN VARCHAR2,
    p_payer_zip     IN VARCHAR2,
    P_PAYER_DOB     IN VARCHAR2,
    P_REQ_DATE      IN VARCHAR2,
    P_REP_NAME      IN VARCHAR2,
    P_ADDIT_TRACNUM IN VARCHAR2,
    P_RESP_MSG OUT VARCHAR2 )
IS
  /*************************************************************************************
  * Created by         : Abdul Hameed M.A
  * Created Date       : 11-Feb-15
  * Purpose            : To log the payment info for Money Send transaction
  * Reviewer           :
  * Reviewed Date      :
  * BuildIN  number    :
  **************************************************************************************/
  EXP_REJECT_RECORD EXCEPTION;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%type;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%type;
  v_RESP_MSG VARCHAR2 (300);
BEGIN
  P_RESP_MSG :='OK';
  V_RESP_MSG := 'OK';
  BEGIN
    V_HASH_PAN := GETHASH(p_pan_code);
  EXCEPTION
  WHEN OTHERS THEN
    v_RESP_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(p_pan_code);
  EXCEPTION
  WHEN OTHERS THEN
    v_RESP_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
  BEGIN
    INSERT
    INTO cms_payment_info
      (
        cpi_inst_code,
        cpi_auth_id,
        cpi_pan_code,
        cpi_pan_encr,
        cpi_rrn,
        cpi_payment_type,
        cpi_unique_rn,
        cpi_spu_id,
        cpi_sp_add,
        cpi_add_si,
        cpi_payer_id,
        cpi_payer_add,
        cpi_payer_city,
        cpi_payer_state,
        cpi_payer_coun,
        cpi_payer_zip,
        cpi_payer_dob,
        cpi_req_date,
        cpi_rep_name,
        cpi_addit_tracnum
      )
      VALUES
      (
        p_inst_code,
        p_auth_id,
        V_HASH_PAN,
        V_ENCR_PAN,
        p_rrn,
        p_payment_type,
        p_unique_rn,
        p_spu_id,
        p_sp_add,
        p_add_si,
        p_payer_id,
        p_payer_add,
        p_payer_city,
        p_payer_state,
        p_payer_coun,
        p_payer_zip,
        p_payer_dob,
        p_req_date,
        p_rep_name,
        P_ADDIT_TRACNUM
      );
    IF sql%ROWCOUNT = 0 THEN
      v_RESP_MSG   := 'Error While Inserting into payment info table';
      RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    v_RESP_MSG := 'Error While Inserting into payment info table ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  P_RESP_MSG :=v_RESP_MSG;
WHEN OTHERS THEN
  P_RESP_MSG := 'Error from main' || SUBSTR(SQLERRM, 1, 200);
END ; 
/
ERROR