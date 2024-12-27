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
      AND object_name = 'CMS_ISO_REQMAPPING_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1620'
         AND cir_tran_cde = '13'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0250';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B2 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1620','13','16',SYSDATE, '1', SYSDATE,'1','*','00','0250');
                
       END IF;

SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1620'
         AND cir_tran_cde = '14'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0251';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B2 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1620','14','16',SYSDATE, '1', SYSDATE,'1','*','00','0251');
                
       END IF;
       
       SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1620'
         AND cir_tran_cde = '15'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0252';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B2 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1620','15','16',SYSDATE, '1', SYSDATE,'1','*','00','0252');
                
       END IF;
       
       SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1100'
         AND cir_tran_cde = '11'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and cir_iso_mrc='0259';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO vmscms.CMS_ISO_REQMAPPING_R1705B2 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1100','11','16',SYSDATE, '1', SYSDATE,'1','*','00','0259');
                
       END IF;
       
      INSERT INTO vmscms.cms_iso_reqmapping
         SELECT *
           FROM vmscms.CMS_ISO_REQMAPPING_R1705B2
          WHERE (cir_inst_code, cir_msg_type, cir_tran_cde, cir_delivery_channel,cir_iso_func_cde, cir_iso_tran_cde) NOT IN (
                   SELECT cir_inst_code, cir_msg_type, cir_tran_cde, cir_delivery_channel,cir_iso_func_cde, cir_iso_tran_cde
                     FROM vmscms.cms_iso_reqmapping);

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
      AND object_name = 'CMS_ISO_REQMAPPING_R1705B3';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1621'
         AND cir_tran_cde = '13'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0250';

      IF v_cnt = 0
      THEN
      
      
         INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B3 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1621','13','16',SYSDATE, '1', SYSDATE,'1','*','00','0250');
                
       END IF;

SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1621'
         AND cir_tran_cde = '15'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0252';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B3 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1621','15','16',SYSDATE, '1', SYSDATE,'1','*','00','0252');
                
       END IF;
       
       SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_iso_reqmapping
       WHERE cir_inst_code=1
         AND cir_msg_type = '1621'
         AND cir_tran_cde = '14'
         AND cir_delivery_channel = '16'
         AND cir_iso_func_cde='*'
         AND  cir_iso_tran_cde='00'
		 and  cir_iso_mrc='0251';

      IF v_cnt = 0
      THEN
      
      
          INSERT INTO VMSCMS.CMS_ISO_REQMAPPING_R1705B3 (CIR_INST_CODE,CIR_MSG_TYPE,CIR_TRAN_CDE,CIR_DELIVERY_CHANNEL,CIR_INS_DATE,CIR_INS_USER,CIR_LUPD_DATE, 
CIR_LUPD_USER,CIR_ISO_FUNC_CDE,CIR_ISO_TRAN_CDE,CIR_ISO_MRC)
VALUES ('1','1621','14','16',SYSDATE, '1', SYSDATE,'1','*','00','0251');
                
       END IF;
        
      INSERT INTO vmscms.cms_iso_reqmapping
         SELECT *
           FROM vmscms.CMS_ISO_REQMAPPING_R1705B3
          WHERE (cir_inst_code, cir_msg_type, cir_tran_cde, cir_delivery_channel,cir_iso_func_cde, cir_iso_tran_cde) NOT IN (
                   SELECT cir_inst_code, cir_msg_type, cir_tran_cde, cir_delivery_channel,cir_iso_func_cde, cir_iso_tran_cde
                     FROM vmscms.cms_iso_reqmapping);

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


            

            