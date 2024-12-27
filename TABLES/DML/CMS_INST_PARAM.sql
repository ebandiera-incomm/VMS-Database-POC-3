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
      AND object_name = 'CMS_INST_PARAM_R1707B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_inst_param
       WHERE cip_inst_code = 1 AND cip_param_key = 'POSTBACKURL';

      IF v_cnt = 0
      THEN
	  
        insert into vmscms.CMS_INST_PARAM_R1707B5(CIP_INST_CODE,CIP_PARAM_KEY,CIP_PARAM_DESC,CIP_PARAM_VALUE,CIP_INS_USER,CIP_INS_DATE,CIP_LUPD_USER,CIP_LUPD_DATE,CIP_ALLOWED_VALUES,CIP_MANDATORY_FLAG,CIP_DISPLAY_FLAG,CIP_PARAM_UNIT,CIP_PARAM_DISP_TYPE,CIP_MULTILING_DESC,CIP_VALIDATION_TYPE) 
values (1,'POSTBACKURL','FSAPI PostBack URL','http://fsapi.incomm.com',1,sysdate,1,sysdate,null,'Y','Y',null,'TEXT',null,null);

      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_inst_param
       WHERE cip_inst_code = 1 AND cip_param_key = 'B2B_CARD_COUNT';

      IF v_cnt = 0
      THEN
         insert into vmscms.CMS_INST_PARAM_R1707B5(CIP_INST_CODE,CIP_PARAM_KEY,CIP_PARAM_DESC,CIP_PARAM_VALUE,CIP_INS_USER,CIP_INS_DATE,CIP_LUPD_USER,CIP_LUPD_DATE,CIP_ALLOWED_VALUES,CIP_MANDATORY_FLAG,CIP_DISPLAY_FLAG,CIP_PARAM_UNIT,CIP_PARAM_DISP_TYPE,CIP_MULTILING_DESC,CIP_VALIDATION_TYPE) 
		values (1,'B2B_CARD_COUNT','B2B Allowed card Count','9',1,sysdate,1,sysdate,null,'N','N',null,null,null,null);
      END IF;

      INSERT INTO vmscms.cms_inst_param
         SELECT *
           FROM vmscms.CMS_INST_PARAM_R1707B5
          WHERE (cip_inst_code, cip_param_key) NOT IN (
                                           SELECT cip_inst_code,
                                                  cip_param_key
                                             FROM vmscms.cms_inst_param);

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

