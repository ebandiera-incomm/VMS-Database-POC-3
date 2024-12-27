CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Pre_Pswd_Change( instcode		IN	NUMBER	,
													userpin		IN	NUMBER	,
													oldpswd		IN	VARCHAR2	,--this password will be compared with the current password in the user master
                                                    --hmacpswd    IN	VARCHAR2	,--this password is  Hmac password of current password in the user master
													newpswd		IN	VARCHAR2	,--this password is the new password which the user is setting
													lupduser		IN	NUMBER	,---just to satisfy the function call from the middle tier
													flagint		OUT	 NUMBER	,--set to 1 if the error message from backend is to be displayed at the front end, else set to 0;
													errmsg		OUT	 VARCHAR2	)
AS
v_cip_new_pswd	NUMBER(3)	;
v_cum_encr_pswd	VARCHAR2(100)	;
v_newpswd		VARCHAR2 (100)	;

--picks up the previous passwords for that user
CURSOR c1 IS
SELECT  cpp_prev_pswd
FROM	CMS_PREV_PSWDS
WHERE	cpp_inst_code		=	instcode
AND		cpp_user_pin		=	userpin
ORDER  BY cpp_pswd_date	 DESC;

BEGIN	--main begin
errmsg	:= 'OK';
flagint	:= 0;

SELECT cum_encr_pswd
INTO v_cum_encr_pswd
FROM cms_user_mast
WHERE cum_inst_code = instcode
AND  cum_user_pin  = userpin;

IF v_cum_encr_pswd  != oldpswd THEN	--if 1 --removed fn_encr(oldpswd) - kirti 10Sep08
errmsg := 'Wrong old password given';
flagint := 1;
ELSE
flagint := 0;
--now select the parameter value for the previous passwords
/*SELECT  cip_new_pswd
INTO	v_cip_new_pswd
FROM	cms_inst_param
WHERE	cip_inst_code		=	instcode	;*/

SELECT cip_param_value
INTO	v_cip_new_pswd
FROM	CMS_INST_PARAM
WHERE	cip_inst_code		=	instcode
AND		cip_param_key	=	'NEW PSWD';

FOR x IN c1
LOOP
IF x.cpp_prev_pswd = newpswd THEN  --removed fn_encr(newpswd) - kirti 10Sep08
errmsg	:= 'Password previously used.Please choose a password not used for last '||v_cip_new_pswd|| ' time(s).'	;
flagint	:= 1;
EXIT;
END IF;
EXIT WHEN c1%ROWCOUNT = v_cip_new_pswd OR c1%NOTFOUND;
END LOOP;

	IF errmsg = 'OK' THEN
	v_newpswd := newpswd;   --removed fn_encr(newpswd) - kirti 10Sep08
	UPDATE	CMS_USER_MAST
	SET	cum_encr_pswd		=	v_newpswd,
		cum_pswd_date		=	SYSDATE,
		cum_lupd_user		=	lupduser,
		cum_user_susp  = 'N',
		CUM_FORCE_PSWD 	 =	 'Y',
		CUM_LUPD_DATE	 =	 SYSDATE
	WHERE	cum_inst_code		=	instcode
	AND	cum_user_pin		=	userpin	;

	
	 --removed fn_encr(newpswd) - kirti 10Sep08
	INSERT INTO	CMS_PREV_PSWDS	(	CPP_INST_CODE		,
						CPP_USER_PIN		,
						CPP_PREV_PSWD	,
						CPP_PSWD_DATE,
						CPP_INS_USER,
						CPP_INS_DATE	)
				VALUES	(	instcode		,
						userpin			, 
						newpswd	,
						SYSDATE	,
						lupduser,
						SYSDATE		)	;
	END IF;

END IF;	--if 1
EXCEPTION	--exception main
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;	--end main
/
SHOW ERRORS

