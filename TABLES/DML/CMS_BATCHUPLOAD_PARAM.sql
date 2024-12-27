DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND owner = 'VMSCMS'
      AND object_name = 'CMS_BATCHUPLOAD_PARAM_R1707B3';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_BATCHUPLOAD_PARAM
        WHERE CBP_INST_CODE=1
        AND CBP_PARAM_KEY='PAN_INVENTORY_GENERATION'
        AND CBP_PARAM_VALUE='Y';

      IF v_cnt = 0
      THEN
          Insert into vmscms.CMS_BATCHUPLOAD_PARAM_R1707B3(CBP_INST_CODE,CBP_PARAM_KEY,CBP_PARAM_VALUE,CBP_PARAM_DESC,CBP_LUPD_DATE,CBP_LUPD_USER,CBP_INS_DATE,CBP_INS_USER) 
			values (1,'PAN_INVENTORY_GENERATION','N','MULTI PROCESS CHECK FOR PAN INVENTORY GENERATION',SYSDATE,1,SYSDATE,1);
      END IF;
	 
      INSERT INTO vmscms.CMS_BATCHUPLOAD_PARAM
         SELECT *
           FROM vmscms.CMS_BATCHUPLOAD_PARAM_R1707B3
          WHERE (CBP_INST_CODE,CBP_PARAM_KEY,CBP_PARAM_VALUE
                ) NOT IN (
                   SELECT CBP_INST_CODE,CBP_PARAM_KEY,CBP_PARAM_VALUE
                     FROM vmscms.CMS_BATCHUPLOAD_PARAM);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/