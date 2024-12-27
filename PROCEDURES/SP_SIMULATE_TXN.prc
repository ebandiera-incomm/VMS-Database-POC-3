CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Simulate_Txn(txn_code IN VARCHAR2, 
	   	  		  							card_number IN VARCHAR2, 
											card_curr	IN VARCHAR2,
											tran_amt IN NUMBER,
											delivery_channel IN VARCHAR2,
											txn_mode IN VARCHAR2, 
											response_code OUT VARCHAR2, 
											response_data OUT VARCHAR2)
AS
V_RRN 					VARCHAR2(12);
V_STAN					VARCHAR2(12);
V_AUTH_ID				VARCHAR2(6);
v_capture_date			DATE;
v_instcode				NUMBER(3) DEFAULT 1;
V_MERCID					VARCHAR2(20);
V_TERMID					VARCHAR2(20);


BEGIN
	 BEGIN
	 	  SELECT LPAD(seq_auth_rrn.NEXTVAL,12,'0')  
		  INTO	 V_RRN
		  FROM   DUAL;
	 
	 EXCEPTION
	 WHEN OTHERS THEN
	 	  response_code := '99';
		  response_data := 'Error while values from sequence ' || SUBSTR(SQLERRM,1,200);
		  RETURN;
	 END;

	 BEGIN
	 	  SELECT LPAD(seq_auth_stan.NEXTVAL,6,'0')  
		  INTO	 V_STAN
		  FROM   DUAL;
	 
	 EXCEPTION
	 WHEN OTHERS THEN
	 	  response_code := '99';
		  response_data := 'Error while values from sequence ' || SUBSTR(SQLERRM,1,200);
		  RETURN;
	 END;
	 
	 BEGIN
	 	  SELECT PMT_MARC_ID, PMT_TERMINAL_ID
		  INTO V_MERCID, V_TERMID
		  FROM PCMS_MCC_TERMINAL,PCMS_TERMINAL_MAST 
		  WHERE PMT_TERMINAL_ID = PTM_TERMINAL_ID
		  AND ROWNUM < 2;
	 
	 EXCEPTION
	 WHEN OTHERS THEN
	 	  response_code := '99';
		  response_data := 'Error While Fetching Value For Merchant Terminal ' || SUBSTR(SQLERRM,1,200);
		  RETURN;
	 END;
	 
	 --Sn select product and card type
	 
	 
	 --En 

Sp_Authorize_Txn (
v_instcode,
'210',
V_RRN,
delivery_channel,
V_TERMID,		  		 -- modified from 'Internet', as it need to be picked from table
txn_code,
--'1',
txn_mode,
TO_CHAR(SYSDATE,'YYYYMMDD'),
TO_CHAR(SYSDATE,'HH24:MI:SS'),
card_number,
NULL,
tran_amt,
NULL,
NULL,
V_MERCID,					  -- Modified from NULL, As It Must be fetched from Table
card_curr,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
v_stan,
1,		  					  	 		  --Ins User
SYSDATE,
v_auth_id,
response_code,
response_data,
v_capture_date
);
IF response_code <> '99' THEN
COMMIT;
--NULL;
ELSE
 ROLLBACK;
 END IF;


EXCEPTION
WHEN OTHERS THEN
	response_code:='99';
END;
/


