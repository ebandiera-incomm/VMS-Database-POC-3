CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Ctf_Update
    (errmsg	OUT		 VARCHAR2)
AS
	CURSOR c1 IS
	SELECT	 rcr_pan_numb,ROWID
	FROM	 REC_CTF_RECO
	WHERE	 rcr_from_acct IS NULL;
v_acctNo CMS_APPL_PAN.cap_acct_no%TYPE;
excp_no_data_found  EXCEPTION ;
BEGIN
errmsg := 'OK';
	FOR X IN C1 LOOP
	BEGIN
		SELECT cap_acct_no INTO v_acctNo
		FROM CMS_APPL_PAN
		WHERE cap_pan_code=x.rcr_pan_numb;
	UPDATE REC_CTF_RECO
	SET rcr_from_acct=v_acctNo
	WHERE ROWID=x.ROWID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		NULL;
	END;
	END LOOP;
EXCEPTION	--excp of main
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END		-- end main
;
/


