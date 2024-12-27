CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_pinfname(	instcode		IN	NUMBER	,
						bin		IN	VARCHAR2,
						hni		IN	VARCHAR2	,
						vendor  IN  VARCHAR2,
						stock   IN  VARCHAR2,
						lupduser	IN	NUMBER	,
						pinfname	OUT	 VARCHAR2	,
						errmsg		OUT	 VARCHAR2)
AS
curr_date		VARCHAR2(8);
file_num		NUMBER(3);
file_cnt		VARCHAR2(3);

BEGIN		--Main Begin Block Starts Here
		SELECT	TO_CHAR(SYSDATE,'ddmmyy')
		INTO	curr_date
		FROM dual;


			SELECT	LPAD(NVL(MAX(TO_NUMBER(SUBSTR(cpc_pin_fname,17))+1),0),3,0)
			INTO	file_cnt
			FROM	CMS_PIN_CTRL
			WHERE	CPC_inst_code		= instcode
			AND		SUBSTR(cpc_pin_fname,1,6)=bin
			AND		SUBSTR(cpc_pin_fname,7,1)=hni
			AND		SUBSTR(cpc_pin_fname,8,1)=vendor
			AND		SUBSTR(cpc_pin_fname,9,1)=stock
			AND		TO_DATE(SUBSTR(cpc_pin_fname,10,6),'dd-mm-yy') = TRUNC(SYSDATE)  ;



			pinfname := bin||hni||vendor||stock||curr_date||'.'||file_cnt;


				BEGIN	--Begin 2 starts here
				INSERT INTO CMS_PIN_CTRL(	  CPC_INST_CODE		,
											cpc_pin_FNAME	,
											CPC_INS_USER	,
											CPC_LUPD_USER   )
									VALUES(	instcode	,
											pinfname	,
											lupduser	,
											lupduser);
				errmsg := 'OK';
				EXCEPTION	--Exception of Begin 2
					WHEN OTHERS THEN
						errmsg := 'Exception 2 --'||SQLCODE||'--'||SQLERRM;
				END;	--Begin 2 ends here

EXCEPTION	--Exception of Main Begin
	WHEN OTHERS THEN
		errmsg := 'Exeption Main -- '||SQLCODE||'--'||SQLERRM;
END	;		--Main Begin Block Ends Here
/


show error