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
      AND object_name = 'CMS_CARDISSU_STAT_MAST_R1705B4';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_cardissuance_status_mast
       WHERE ccm_inst_code = 1 AND ccm_status_code = '20';

      IF v_cnt = 0
      THEN
         INSERT INTO vmscms.CMS_CARDISSU_STAT_MAST_R1705B4 (ccm_inst_code, ccm_status_code, ccm_status_desc,
                                                 ccm_ins_user, ccm_ins_date, ccm_lupd_user, ccm_lupd_date)
     VALUES (1, '20', 'REPLACED', 1, SYSDATE, 1, SYSDATE);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_cardissuance_status_mast
       WHERE ccm_inst_code = 1 AND ccm_status_code = '21';

      IF v_cnt = 0
      THEN
         INSERT INTO vmscms.CMS_CARDISSU_STAT_MAST_R1705B4 (ccm_inst_code, ccm_status_code, ccm_status_desc,
                                                 ccm_ins_user, ccm_ins_date, ccm_lupd_user, ccm_lupd_date)
     VALUES (1, '21', 'REPLACED SHIPPED', 1, SYSDATE, 1, SYSDATE);
      END IF;

      INSERT INTO vmscms.cms_cardissuance_status_mast
         SELECT *
           FROM vmscms.CMS_CARDISSU_STAT_MAST_R1705B4
          WHERE (ccm_inst_code, ccm_status_code) NOT IN (
                                      SELECT ccm_inst_code, ccm_status_code
                                        FROM vmscms.cms_cardissuance_status_mast);

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