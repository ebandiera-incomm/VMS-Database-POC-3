DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE owner = 'VMSCMS'
      AND object_type = 'TABLE'
      AND object_name = 'CMS_KYCSTATUS_MAST_R1707B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_KYCSTATUS_MAST
       WHERE ckm_inst_code = 1
         AND ckm_flag = 'A';

      IF v_cnt = 0
      THEN
				 INSERT INTO vmscms.CMS_KYCSTATUS_MAST_R1707B5(
					CKM_INST_CODE,CKM_FLAG,CKM_FLAG_DESC,
					CKM_INS_USER,CKM_INS_DATE,CKM_LUPD_USER,CKM_LUPD_DATE)
			VALUES(1,'A','NOT REQUIRED',1,SYSDATE,1,SYSDATE);
	  END IF;

        INSERT INTO vmscms.CMS_KYCSTATUS_MAST
         SELECT *
           FROM vmscms.CMS_KYCSTATUS_MAST_R1707B5
          WHERE (ckm_inst_code,
                 ckm_flag
                ) NOT IN (
                   SELECT ckm_inst_code,
                          ckm_flag
                     FROM vmscms.CMS_KYCSTATUS_MAST);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/

