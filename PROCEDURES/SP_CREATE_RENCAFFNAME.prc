CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Rencaffname(	instcode 	IN  NUMBER  	,
             										lupduser 	IN  NUMBER  	,
             										rencaffname OUT VARCHAR2  	,
             										errmsg 	 	OUT VARCHAR2	)

AS
--variables
v_rencaf_fname CMS_RENCAF_HEADER.crh_rencaf_fname%TYPE;

BEGIN--main begin starts
errmsg := 'OK';
SELECT 'RC'||TO_CHAR(SYSDATE,'DDMMHHMISS')
INTO   v_rencaf_fname
FROM   dual;
--dbms_output.put_line('ckpt1');

	INSERT INTO CMS_RENCAF_HEADER(	crh_inst_code,
									crh_rencaf_fname,
									crh_file_gen,
									crh_ins_user,
									crh_lupd_user)
						VALUES	(	instcode		,
									v_rencaf_fname	,
									'N'				,
									lupduser		,
									lupduser		);
dbms_output.put_line('ckpt2');
rencaffname := v_rencaf_fname;
dbms_output.put_line(rencaffname);

EXCEPTION--excp of main
	WHEN OTHERS THEN
	errmsg := 'Main Excp -- '||SQLERRM;
END;--End main procedure
/


show error