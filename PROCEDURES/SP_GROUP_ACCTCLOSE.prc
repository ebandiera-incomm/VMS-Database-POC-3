CREATE OR REPLACE PROCEDURE VMSCMS.SP_GROUP_ACCTCLOSE   (
    												instcode IN  NUMBER,
												lupduser IN  NUMBER,
												errmsg   OUT VARCHAR2)
AS
CURSOR C1 IS
SELECT 	b.cam_acct_id,
	b.cam_acct_no
FROM	CMS_ACCTCLOSE_TEMP a,
	CMS_ACCT_MAST b
WHERE	a.cgt_acct_no = b.cam_acct_no
AND 	b.cam_inst_code = instcode;
v_trunc VARCHAR2(100) := 'TRUNCATE TABLE CMS_ACCTCLOSE_TEMP';
BEGIN--main pocedure begin
errmsg := 'OK';
	--call the account closure procedure in loop
	/*	sp_acct_close
		INSTCODE                       NUMBER                  IN
		ACCTID                         NUMBER                  IN
		RSNCODE                        NUMBER                  IN
		REMARK                         VARCHAR2                IN
		LUPDUSER                       NUMBER                  IN
		ERRMSG                         VARCHAR2                OUT
	*/
	FOR x IN C1
	LOOP
		sp_acct_close(instcode,x.cam_acct_id,1,'ACCTCLOSE UPLOAD',lupduser,errmsg);
		IF errmsg != 'OK' THEN
		--Added by Christopher to remove records in case of errors.
		DELETE FROM CMS_ACCTCLOSE_TEMP ;
		EXIT;
		ELSE
			INSERT INTO CMS_ACCTCLOSE_HIST(cah_acct_no)
									VALUES(x.cam_acct_no);
			--DELETE FROM cms_acctclose_temp
			--WHERE  cat_acct_no = x.cam_acct_no;
		END IF;
	END LOOP;
       --Added by Christopher to improve the performance
                     EXECUTE IMMEDIATE v_trunc;
       --Added by Christopher to improve the performance
EXCEPTION--main exception
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;--main procedure end
/


