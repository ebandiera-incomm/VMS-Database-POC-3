CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Check_Transaction_BASE
(prm_inst_code IN NUMBER,
prm_transgroup_code IN VARCHAR2,
 prm_transaction_code IN VARCHAR2,
 prm_delivery_channel IN VARCHAR2,
 prm_auth_type		  IN 		  VARCHAR2,
 prm_err_flag  OUT VARCHAR2,
 Prm_err_msg  OUT VARCHAR2
)

IS

 V_CHECK_CNT  NUMBER(1);
BEGIN
 SELECT COUNT(*)
 INTO V_CHECK_CNT
 FROM TRANSCODE_GROUP TG, TRANSCODE T1
 WHERE TG.TRA_INST_CODE =prm_inst_code  AND 
 TG.TRANSCODEGROUPID = prm_transgroup_code
 AND TG.TRANSCODE  = T1.TRANSCODE_ID
 AND T1.TRANSCODE  = prm_transaction_code
 AND T1.DELIVERY_CHNNEL = prm_delivery_channel;

 IF  (v_check_cnt = 1 AND  prm_auth_type = 'A'  ) OR (  v_check_cnt = 0  AND  prm_auth_type = 'D'  ) THEN
 	 			 prm_err_flag := '1';
 				 Prm_err_msg := 'OK';
ELSE
				  prm_err_flag := '20';
 				 Prm_err_msg := 'Invalid transaction code ';
END IF;

EXCEPTION

 WHEN NO_DATA_FOUND THEN
 prm_err_flag := '20';
 Prm_err_msg  := 'Invalid transaction code ';


END;
/


