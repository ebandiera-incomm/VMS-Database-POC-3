CREATE OR REPLACE PROCEDURE VMSCMS.sp_upd_wdl_limit(errmsg OUT VARCHAR2) AS

CURSOR cur_wdl_limit IS
SELECT	*
FROM	CMS_UPDATE_LIMITS
WHERE   cup_processed = 'N'
FOR UPDATE;

BEGIN

errmsg := 'OK';

	FOR x IN cur_wdl_limit
	LOOP

		DELETE FROM CMS_CAF_INFO
		WHERE CCI_INST_CODE = 1 AND
		CCI_PAN_CODE = RPAD(X.CUL_PAN_CODE,19,' ') AND
		CCI_MBR_NUMB = '000' ;

		sp_wdl_temp_proc(x.CUL_INST_CODE,x.CUL_PAN_CODE,x.CUL_MBR_NUMB,SYSDATE,'C','NR','WDLLMT',1,errmsg);

		IF (errmsg = 'OK') THEN

			UPDATE	CMS_UPDATE_LIMITS
			SET	cup_processed = 'Y'
			WHERE CURRENT OF cur_wdl_limit;

		ELSE

			ROLLBACK;
			EXIT;

		END IF;


	END LOOP;

EXCEPTION
WHEN OTHERS THEN

	errmsg := 'Main excp -- '||SQLERRM;

END;
/


