CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_prodbin (instcode	IN	NUMBER	,
					 prodcode	IN	VARCHAR2	,
					 bin		IN	NUMBER		,
					 interchange	IN	VARCHAR2	,
					 lupduser	IN	NUMBER		,
					 errmsg		OUT	VARCHAR2)
AS

BEGIN		--Main begin starts
	errmsg := 'OK';

	BEGIN

		INSERT INTO CMS_PROD_BIN(	CPB_INST_CODE			,
					CPB_PROD_CODE		,
					CPB_INTERCHANGE_CODE,
					CPB_INST_BIN			,
					CPB_ACTIVE_BIN	,
					CPB_INS_USER			,
					CPB_LUPD_USER
					     )
				VALUES(	instcode		,
					prodcode		,
					interchange	,
					bin			,
					'Y'	,
					lupduser		,
					lupduser
						);

	EXCEPTION
	WHEN OTHERS THEN
		errmsg := 'Excp 1 -- '||SQLERRM;

	END;

	/*	commented on 06-09-02...to be uncommented for other than icici ...for icici this part of code is shifted to sp_create_bin procedure

	IF errmsg = 'OK' THEN

		sp_create_panctrl_data(instcode,prodcode,bin,null,'PROD',lupduser,errmsg);

		IF errmsg != 'OK' THEN

			errmsg := 'From sp_create_panctrl_data -- '||errmsg;

		END IF;

	END IF;*/

EXCEPTION	--Excp of main begin
	WHEN OTHERS THEN
		errmsg := 'Main Exception -- '||SQLERRM;
END;		--Main begin ends
/
show error