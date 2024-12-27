CREATE OR REPLACE PROCEDURE VMSCMS.SP_DUPCHECK_MULTIPAGE(instcode IN NUMBER,
applcode IN NUMBER,
acctid IN NUMBER,
errmsg OUT VARCHAR2)
AS
dum NUMBER(3) := 0 ;
dum1 NUMBER(3):= 0 ;
dup_flag VARCHAR2(2):= 'A';
BEGIN -- main begin
errmsg := 'OK';
	BEGIN  --** begin no.1
	-- check for an application on the same day...
	-- check for indexes
	SELECT COUNT(1) INTO dum
	FROM CMS_APPL_DET
	WHERE cad_acct_id = acctid
	AND cad_inst_code = instcode
	AND cad_ins_date > (SYSDATE - 1);
	IF dum > 1 THEN -- if #1
 	 dup_flag := 'D';
	ELSE -- check for an existing card on that account
	 BEGIN --### begin no.2
 	  SELECT  DISTINCT 1
  	  INTO	dum1
  	  FROM	CMS_PAN_ACCT,CMS_APPL_PAN
  	  WHERE	cpa_inst_code	=	instcode
  	  AND	cpa_acct_id	=	acctid
  	  AND	cap_pan_code	=	cpa_pan_code
  	  AND	cap_mbr_numb	=	cpa_mbr_numb
  	  AND	cap_card_stat	=	'1'; -- only if existing card is open

	  IF dum1 > 0 THEN 	  -- if #2
	   dup_flag := 'D';
	  END IF; -- end of if #2
--	  else  dup_flag := 'A';
	 EXCEPTION -- exception no.2
	  WHEN NO_DATA_FOUND THEN
	  dup_flag := 'A';
	  errmsg := 'OK'; -- its ok if no card is found on that account or account not present
	  WHEN OTHERS THEN
	  errmsg := 'Exception 2 '||SQLCODE||'---'||SQLERRM;
	 END;  --### end of begin no.2
	END IF; -- end of if #1
	EXCEPTION -- end of begin #1
	  WHEN NO_DATA_FOUND THEN
	  errmsg := 'No such application';
	  WHEN OTHERS THEN
	  errmsg := 'Exception 1 '||SQLCODE||'---'||SQLERRM;
	END; --** end of begin no.1

	IF dup_flag = 'D' THEN
	  dbms_output.put_line('Updating the duplication flag');
     BEGIN --## begin no.3
	  -- update the application to duplicate
	  UPDATE CMS_APPL_MAST
	  SET cam_appl_stat = dup_flag
	  WHERE cam_appl_code = applcode;
	  errmsg := 'OK';
 	 EXCEPTION -- for begin #3
	  WHEN NO_DATA_FOUND THEN
	  errmsg := 'No such application';
	  WHEN OTHERS THEN
	  errmsg := 'Exception 3 '||SQLCODE||'---'||SQLERRM;
	 END;   --## end of begin no.3
	END IF;
EXCEPTION
	WHEN OTHERS THEN
	errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;
/
SHOW ERRORS

