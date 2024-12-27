CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Renpan
AS

CURSOR c1 IS
SELECT cci_pan_code
FROM CMS_CAF_INFO
WHERE cci_inst_code = 1
AND cci_file_gen = 'R'
AND ROWNUM < 100000;


pan VARCHAR2(20);
errmsg VARCHAR2(500);

BEGIN
errmsg:='OK';

	FOR x IN c1
	LOOP
	BEGIN
	pan:=SUBSTR(x.cci_pan_code,1,16);
	UPDATE CMS_APPL_PAN
	SET cap_expry_date = TO_DATE('01-10-05','dd-mm-yy')
	WHERE cap_pan_code = pan
	AND cap_mbr_numb = '000';
	IF(SQL%rowcount=1) THEN
		DELETE FROM CMS_CAF_INFO
		WHERE cci_inst_code = 1
		AND cci_pan_code = x.cci_pan_code
		AND cci_mbr_numb = '000';
	END IF;
	EXCEPTION
	WHEN OTHERS THEN
	errmsg:='Error for ' || x.cci_pan_code || SQLERRM;
	INSERT INTO CMS_CARDRENEWAL_ERRLOG (cce_pan_code, cce_error_mesg, cce_ins_date)
	VALUES(x.cci_pan_code,errmsg,SYSDATE);
	END;
	END LOOP;
END;
/


SHOW ERRORS