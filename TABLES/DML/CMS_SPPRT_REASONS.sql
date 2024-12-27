DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND OWNER = 'VMSCMS'
      AND object_name = 'CMS_SPPRT_REASONS_R1704B1';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_SPPRT_REASONS
       WHERE CSR_INST_CODE = 1
         AND CSR_SPPRT_RSNCODE = 222;

      IF v_cnt = 0
      THEN
          INSERT INTO vmscms.cms_spprt_reasons_R1704B1 (csr_inst_code, csr_spprt_rsncode, csr_spprt_key,
                                      csr_reasondesc, csr_ins_user, csr_ins_date, csr_lupd_user, csr_lupd_date)
     VALUES (1, 222, 'MANADJDRCR', 'No Act/Fund Sweeps Account - Debit',
                       1, sysdate, 1, sysdate);
	  
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_SPPRT_REASONS
       WHERE CSR_INST_CODE = 1
         AND CSR_SPPRT_RSNCODE = 223;

      IF v_cnt = 0
      THEN
          INSERT INTO vmscms.cms_spprt_reasons_R1704B1 (csr_inst_code, csr_spprt_rsncode, csr_spprt_key,
                                      csr_reasondesc, csr_ins_user, csr_ins_date, csr_lupd_user, csr_lupd_date)
     VALUES (1, 223, 'MANADJDRCR', 'Expired fund debit',
                       1, sysdate, 1, sysdate);
	  
      END IF;
	 
	 
      INSERT INTO vmscms.CMS_SPPRT_REASONS
         SELECT *
           FROM vmscms.CMS_SPPRT_REASONS_R1704B1
          WHERE (CSR_INST_CODE,CSR_SPPRT_RSNCODE
                ) NOT IN (
                   SELECT CSR_INST_CODE,CSR_SPPRT_RSNCODE
                     FROM vmscms.CMS_SPPRT_REASONS);

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



DELETE FROM vmscms.cms_spprt_reasons
      WHERE csr_inst_code = 1 AND csr_spprt_rsncode IN ('222', '223');
DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND OWNER = 'VMSCMS'
      AND object_name = 'CMS_SPPRT_REASONS_R1704B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_SPPRT_REASONS
       WHERE CSR_INST_CODE = 1
         AND CSR_SPPRT_RSNCODE = 222;

      IF v_cnt = 0
      THEN
          INSERT INTO vmscms.cms_spprt_reasons_R1704B2 (csr_inst_code, csr_spprt_rsncode, csr_spprt_key,
                                      csr_reasondesc, csr_ins_user, csr_ins_date, csr_lupd_user, csr_lupd_date)
     VALUES (1, 222, 'MANADJDRCR', 'No Act/Fund Sweeps Account - Debit',
                       1, sysdate, 1, sysdate);
	  
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_SPPRT_REASONS
       WHERE CSR_INST_CODE = 1
         AND CSR_SPPRT_RSNCODE = 223;

      IF v_cnt = 0
      THEN
          INSERT INTO vmscms.cms_spprt_reasons_R1704B2 (csr_inst_code, csr_spprt_rsncode, csr_spprt_key,
                                      csr_reasondesc, csr_ins_user, csr_ins_date, csr_lupd_user, csr_lupd_date)
     VALUES (1, 223, 'MANADJDRCR', 'Expired fund - debit',
                       1, sysdate, 1, sysdate);
	  
      END IF;
	 
	 
      INSERT INTO vmscms.CMS_SPPRT_REASONS
         SELECT *
           FROM vmscms.CMS_SPPRT_REASONS_R1704B2
          WHERE (CSR_INST_CODE,CSR_SPPRT_RSNCODE
                ) NOT IN (
                   SELECT CSR_INST_CODE,CSR_SPPRT_RSNCODE
                     FROM vmscms.CMS_SPPRT_REASONS);

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

