CREATE OR REPLACE PROCEDURE VMSCMS.SP_GRP_DEBLOCK_OLD
    (	instcode    IN NUMBER,
	lupduser  IN	NUMBER,
	 errmsg    OUT VARCHAR2
	)
AS
v_mbrnumb VARCHAR2(3);
v_remark  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_spprtrsn CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;
 dum  NUMBER;
CURSOR c1 IS
SELECT	TRIM(cgd_pan_code) cgd_pan_code ,cgd_remark, ROWID
FROM	CMS_GROUP_DEBLOCK WHERE cgd_pin_deblock = 'N';
BEGIN
errmsg := 'OK';
v_remark := 'Group DeBlock';
v_spprtrsn := 1;
	FOR x IN c1
	LOOP
		BEGIN
			SELECT  1 INTO dum
			FROM CMS_APPL_PAN
			WHERE  cap_pan_code = x.cgd_pan_code;
					IF  dum = 1 THEN
									SP_DEBLOCK_PAN(instcode,x.cgd_pan_code,v_mbrnumb,v_spprtrsn,X.cgd_remark,lupduser,errmsg);
										IF ERRMSG = 'OK' THEN
													UPDATE CMS_GROUP_DEBLOCK SET CGD_PIN_DEblock = 'Y'   ,  cgd_result  =   'SUCCESSFULL'    WHERE ROWID = X.ROWID;
										ELSE
										-- this will rollback the updation on appl_pan and the deletion on caf_info
										-- and will update the group_deblock table after this...jimmy 16th June 2005
													ROLLBACK;
													UPDATE CMS_GROUP_DEBLOCK SET CGD_PIN_DEblock = 'E'   ,   cgd_result  =  errmsg     WHERE ROWID = X.ROWID;
										sp_auton(	NULL,
													x.cgd_pan_code,
													ERRMSG)  		;
										END IF;
					END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				errmsg:='The Given Pan not found in Master';
			    	UPDATE CMS_GROUP_DEBLOCK SET CGD_PIN_DEblock = 'E'   ,   cgd_result  =  errmsg     WHERE ROWID = X.ROWID;
										sp_auton(	NULL,
													x.cgd_pan_code,
													ERRMSG)  		;
		 WHEN OTHERS THEN
									errmsg :=SQLERRM;
									UPDATE CMS_GROUP_DEBLOCK SET CGD_PIN_DEblock = 'E'   ,   cgd_result  =  errmsg     WHERE ROWID = X.ROWID;
										sp_auton(	NULL,
													x.cgd_pan_code,
													ERRMSG)  		;
		END;
		COMMIT; -- this will commit whatever transactions have happened so far...
	END LOOP;
	ERRMSG := 'OK';
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;
/


