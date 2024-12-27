create or replace
PROCEDURE VMSCMS.SP_CHECK_COUNTRY(
    prm_countrygroup_code IN VARCHAR2,
    prm_country_code      IN VARCHAR2,
    prm_auth_type         IN VARCHAR2,
	Prm_acqInstAlphaCntrycode      IN VARCHAR2,
    prm_err_flag OUT VARCHAR2,
    prm_err_msg OUT VARCHAR2
    
    )
IS
  /*************************************************
  * Created By      :  Ramesh A
  * Created Date    :  23/MAR/2015
  * Created Reason  :  FSS-2281
  * Reviewer         :  Pankaj S
  * Reviewed Date    :  23/MAR/2015
  * Build Number     :  3.0

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         :  SARAVANAKUMAR A
     * Release Number   : R08 
  *************************************************/
  v_check_cnt NUMBER (1);
  type type_cntrycode is table of VARCHAR2(50);
  t_cntrycodes type_cntrycode := type_cntrycode (prm_country_code,Prm_acqInstAlphaCntrycode);
BEGIN
  FOR i IN 1..t_cntrycodes.count 
  LOOP
    BEGIN
      SELECT COUNT (*)
      INTO v_check_cnt
      FROM cms_cntrygrp_cntrycode
      WHERE CCC_CNTRY_GRPCODE = prm_countrygroup_code
      AND CCC_CNTRY_CODE      = t_cntrycodes(i);
      IF (v_check_cnt         = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0 ) THEN
        prm_err_flag         := '1';
        prm_err_msg          := 'OK';
      ELSE
      DBMS_OUTPUT.PUT_LINE('PRM_ERR_MSEXIT G = ');
        prm_err_flag := '70';
        prm_err_msg  := 'Invalid Country Code';
        EXIT;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      prm_err_flag := '70';
      prm_err_msg  := 'Invalid Country Code';
      EXIT;
    WHEN OTHERS THEN
      prm_err_flag := '21';
      prm_err_msg  := 'Error while Merchant ID validation '||t_cntrycodes(i) || SUBSTR (SQLERRM, 1, 300);
      EXIT;
    END;
  END LOOP;
END;
/
SHOW ERROR