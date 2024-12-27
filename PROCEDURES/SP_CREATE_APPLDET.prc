CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_appldet	(instcode		IN NUMBER	,--just to satisfy the the middle tier common function parameters, not used in this proc
						applcode		IN	NUMBER	,
						acctid		IN	NUMBER	,
						acctposn		IN	NUMBER	,
						lupduser		IN	NUMBER	,
						errmsg		OUT	 VARCHAR2	 )
AS
dum		NUMBER (3);
posn	NUMBER (3);
v_cam_addon_link	NUMBER(14);
v_cam_addon_stat	 CHAR(1);
--cursor added on 15-04-02 to add multiple accounts(if present for addon card)
appl_count NUMBER(3):= 0;  -- for duplicate appl check...jimmy 26th Apr 05


CURSOR c1(c1_applcode IN NUMBER,c1_instcode IN NUMBER) IS
	SELECT cad_acct_id, cad_acct_posn
	FROM	CMS_APPL_DET
	WHERE CAD_INST_CODE = c1_instcode and cad_appl_code = c1_applcode
	AND		cad_acct_posn != 1;

BEGIN		--Main Begin Block Starts Here

	IF applcode IS NOT NULL AND acctid IS NOT NULL AND ACCTPOSN IS NOT NULL AND LUPDUSER IS NOT NULL THEN	--IF Main

	errmsg := 'OK';

		IF	acctposn !=1 THEN	--If 1

			BEGIN		--Begin 1
				SELECT	NVL(MAX(cad_acct_posn),0)+1
				INTO	dum
				FROM	CMS_APPL_DET
				WHERE CAD_INST_CODE = instcode AND 	cad_appl_code	= applcode ;
				posn := dum;
				errmsg := 'OK';
			EXCEPTION	--Exception of Begin 1
				WHEN OTHERS THEN
				errmsg := 'Exception 1 '||SQLCODE||'---'||SQLERRM;
			END;		--End of Begin 1

		END IF;					--End if of If 1

		IF	errmsg = 'OK' THEN	--If 1

			posn := acctposn;
			INSERT INTO CMS_APPL_DET
					(	CAD_APPL_CODE        ,
						CAD_ACCT_ID		,
						CAD_ACCT_POSN	,
						CAD_INS_USER		,
						CAD_LUPD_USER,CAD_INST_CODE )
				VALUES(	applcode		,
						acctid		,
						posn		,
						lupduser		,
						lupduser,instcode		);


			errmsg := 'OK';

		END IF;		--End if of If 2

	ELSE	--Main IF

		errmsg := 'sp_create_appldet expected a not null parameter';

	END IF;	--End of Main IF

	--added on 15-04-02 to add multiple accounts(if present for addon card)
	BEGIN
		SELECT cam_addon_link,cam_addon_stat
		INTO	v_cam_addon_link,v_cam_addon_stat
		FROM	CMS_APPL_MAST
		WHERE CAM_INST_CODE =instcode  and	cam_appl_code = applcode;

		IF v_cam_addon_stat = 'A' THEN

			FOR x IN c1(v_cam_addon_link,instcode)
			LOOP

				INSERT INTO CMS_APPL_DET(	CAD_APPL_CODE        ,
								CAD_ACCT_ID		,
								CAD_ACCT_POSN	,
								CAD_INS_USER		,
								CAD_LUPD_USER,CAD_INST_CODE )
						VALUES(		applcode			,
								x.cad_acct_id		,
								x.cad_acct_posn	,
								lupduser			,
								lupduser,instcode	);

				EXIT WHEN C1%NOTFOUND;

			END LOOP;

		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			errmsg := 'Exception 2 '||SQLCODE||'---'||SQLERRM;
	END;

--added on 15-04-02 to add multiple accounts(if present for addon card)


EXCEPTION	--Main block Exception
	WHEN OTHERS THEN
		errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;		--Main Begin Block Ends Here
/
show error