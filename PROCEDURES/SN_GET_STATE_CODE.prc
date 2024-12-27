CREATE OR REPLACE PROCEDURE VMSCMS.Sn_Get_State_Code
    (
     prm_inst_code   IN NUMBER,
     prm_state_data   IN VARCHAR2,
	 prm_cntry_code   IN VARCHAR2,
     prm_state_code   OUT NUMBER,
     prm_swich_state_code  OUT VARCHAR2,
     prm_err_msg   OUT VARCHAR2
    )
IS
 -- Specific to bank in icici in file switch state is coming in file
v_state_code GEN_STATE_MAST.gsm_state_code%TYPE;
v_switch_code GEN_STATE_MAST.gsm_switch_state_code%TYPE;
BEGIN
  prm_err_msg  := 'OK';
  --dbms_output.put_line('Matching Switch State Code :----->');
  --dbms_output.put_line('prm_state_data :----->('|| prm_state_data||')');
  --dbms_output.put_line('prm_inst_code :----->('||prm_inst_code||')');
 SELECT gsm_state_code
 INTO v_state_code
 FROM GEN_STATE_MAST
 WHERE gsm_switch_state_code = prm_state_data
 AND gsm_inst_code       = prm_inst_code
 AND gsm_cntry_code      = prm_cntry_code;
 prm_state_code := v_state_code;
 prm_swich_state_code := prm_state_data;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 BEGIN
  --dbms_output.put_line('Matching State Code :----->');
  --dbms_output.put_line('prm_state_data :----->('|| prm_state_data||')');
  --dbms_output.put_line('prm_inst_code :----->('||prm_inst_code||')');

  SELECT gsm_switch_state_code
  INTO v_switch_code
  FROM GEN_STATE_MAST
  WHERE gsm_state_code = prm_state_data
  AND gsm_inst_code    = prm_inst_code
  AND gsm_cntry_code   = prm_cntry_code;

  prm_state_code := prm_state_data;
  prm_swich_state_code := v_switch_code;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   prm_err_msg  :=' State data not defined in master' ;
  WHEN INVALID_NUMBER THEN
  prm_err_msg  := 'Not a valid state data';
  WHEN OTHERS THEN
  --prm_err_msg := 'Error while selecting state detail data' || substr(sqlerrm,1,200);
  prm_err_msg := 'Error while selecting state detail data' ||'prm_state_data='||prm_state_data||'prm_state_code='||prm_state_code||'prm_swich_state_code'||prm_swich_state_code
                 || SUBSTR(SQLERRM,1,200);
 END;
 WHEN OTHERS THEN
 prm_err_msg := 'Error while selecting state detail data' || SUBSTR(SQLERRM,1,200);
END;
/


