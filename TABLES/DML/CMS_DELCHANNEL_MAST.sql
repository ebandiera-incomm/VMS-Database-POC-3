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
      AND object_name = 'CMS_DELCHANNEL_MAST_R1707B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_delchannel_mast
       WHERE cdm_inst_code = 1 AND cdm_channel_code = '17';

      IF v_cnt = 0
      THEN
        INSERT INTO vmscms.CMS_DELCHANNEL_MAST_R1707B5 (CDM_INST_CODE,CDM_CHANNEL_CODE,CDM_CHANNEL_DESC,CDM_TRANSACTION_FLAG,CDM_LUPD_DATE,CDM_LUPD_USER,CDM_INS_DATE,CDM_INS_USER,CDM_PASSIVEPERIOD_FLAG,CDM_GPRCONFIG_FLAG,CDM_PRFL_FLAG,CDM_DEPLOYMENT_FLAG) 
			VALUES(1,'17','WEB','1',SYSDATE,1,SYSDATE,1,'Y','Y','Y',0);
			
      END IF;

      INSERT INTO vmscms.cms_delchannel_mast
         SELECT *
           FROM vmscms.CMS_DELCHANNEL_MAST_R1707B5
          WHERE (cdm_inst_code, cdm_channel_code) NOT IN (
                                        SELECT cdm_inst_code,
                                               cdm_channel_code
                                          FROM vmscms.cms_delchannel_mast);

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