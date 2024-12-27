CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Check_Merchant_BASE
( 
prm_inst_code NUMBER,
prm_merchantgroup_code IN VARCHAR2,
 prm_mcc_code  IN VARCHAR2,
 prm_auth_type 	 IN	 VARCHAR2,
 prm_err_flag  OUT VARCHAR2,
  Prm_err_msg  OUT VARCHAR2
)
IS
V_CHECK_CNT  NUMBER(1);
BEGIN
 SELECT COUNT(*)
 INTO  v_check_cnt
 FROM   MCCODE_GROUP
 WHERE MCC_INST_CODE = prm_inst_code AND MCCODEGROUPID = prm_merchantgroup_code
 AND MCCODE  = prm_mcc_code;

 IF  (v_check_cnt = 1 AND  prm_auth_type = 'A'  ) OR (  v_check_cnt = 0  AND  prm_auth_type = 'D'  ) THEN
 	 			 prm_err_flag := '1';
 				 Prm_err_msg := 'OK';
ELSE
				  prm_err_flag := '20';
 				 Prm_err_msg := 'Invalid merchant code';
END IF;

EXCEPTION
 WHEN NO_DATA_FOUND THEN
 prm_err_flag := '20';
 Prm_err_msg  := 'Invalid merchant code ';
 WHEN OTHERS THEN
 prm_err_flag := '99';
 Prm_err_msg  := 'Error while merchant validation ' || SUBSTR(SQLERRM,1 ,300);
END;
/
SHOW ERROR