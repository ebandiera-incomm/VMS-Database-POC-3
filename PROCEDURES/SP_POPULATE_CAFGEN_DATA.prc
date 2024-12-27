CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Populate_Cafgen_Data ( instcode  IN  NUMBER
						                             ,rectype   IN  VARCHAR2
						                             ,emvtype   IN  VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   v_rectype   CHAR (1);

BEGIN

   IF rectype IS NULL OR rectype = '' THEN
      v_rectype := '%';
   ELSE
      v_rectype := rectype;
   END IF;

   DBMS_OUTPUT.put_line (v_rectype || '- rectype');
   DBMS_OUTPUT.put_line (emvtype || '- emvtype');

   IF emvtype = 'N' THEN

      INSERT INTO CMS_CAFGEN_DATA_TEMP(SELECT /*+ RULE */ caf.*
									   FROM cms_caf_info caf
									   ,cms_appl_pan pan
									   ,cms_bin_mast bin
									   ,cms_bin_param parm
									   ,cms_prod_mast prod
									   ,cms_prod_bin pbin 
									    WHERE caf.CCI_INST_CODE = pan.CAP_INST_CODE  
										AND caf.cci_pan_code = pan.cap_pan_code
										AND caf.cci_mbr_numb = pan.cap_mbr_numb
										AND caf.cci_inst_code = instcode-- put instcode
										AND caf.cci_file_gen = 'N'
										AND caf.cci_rec_typ LIKE v_rectype -- Put v_rectype
										AND pan.cap_pin_flag = 'N'
										AND pan.cap_embos_flag = 'N'
										AND SUBSTR(fn_dmaps_main(CCI_PAN_CODE_ENCR),0,6) = bin.cbm_inst_bin
										AND bin.CBM_INST_CODE = pbin.CPB_INST_CODE
										AND bin.CBM_INST_BIN  = pbin.CPB_INST_BIN
										AND pbin.CPB_INST_CODE = prod.CPM_INST_CODE
										AND pbin.CPB_PROD_CODE = prod.CPM_PROD_CODE
										AND prod.CPM_INST_CODE = parm.CBP_INST_CODE
										AND prod.CPM_PROFILE_CODE = parm.CBP_PROFILE_CODE
										AND parm.cbp_param_value = 'N'
										AND parm.cbp_param_name = 'EMV');

   ELSIF emvtype = 'Y' THEN

	  INSERT INTO CMS_CAFGEN_DATA_TEMP(SELECT /*+ RULE */ caf.*
									   FROM cms_caf_info caf
									   ,cms_appl_pan pan
									   ,cms_bin_mast bin
									   ,cms_bin_param parm
									   ,cms_prod_mast prod
									   ,cms_prod_bin pbin 
										WHERE caf.CCI_INST_CODE = pan.CAP_INST_CODE  
										AND caf.cci_pan_code = DECODE(LENGTH(pan.cap_pan_code), 16,pan.cap_pan_code || '   ',19,pan.cap_pan_code)
										AND caf.cci_mbr_numb = pan.cap_mbr_numb
										AND caf.cci_inst_code = instcode-- put instcode
										AND caf.cci_file_gen = 'N'
										AND caf.cci_rec_typ LIKE v_rectype -- Put v_rectype
										AND pan.cap_pin_flag = 'N'
										AND pan.cap_embos_flag = 'N'
										AND SUBSTR(caf.cci_pan_code,0,6) = bin.cbm_inst_bin
										AND bin.CBM_INST_CODE = pbin.CPB_INST_CODE
										AND bin.CBM_INST_BIN  = pbin.CPB_INST_BIN
										AND pbin.CPB_INST_CODE = prod.CPM_INST_CODE
										AND pbin.CPB_PROD_CODE = prod.CPM_PROD_CODE
										AND prod.CPM_INST_CODE = parm.CBP_INST_CODE
										AND prod.CPM_PROFILE_CODE = parm.CBP_PROFILE_CODE
										AND parm.cbp_param_value IN ('S','I','P')
										AND parm.cbp_param_name = 'EMV');

   END IF;
   
   DBMS_OUTPUT.put_line (SQL%ROWCOUNT);
   COMMIT;
END;
/


SHOW ERRORS