CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Populate_Cafgen_Data_140610 (
   instcode   IN   NUMBER,
   --locncode   IN   VARCHAR2, commeted by Kirti 17May10
   rectype    IN   VARCHAR2,
   emvtype    IN   VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   v_rectype   CHAR (1);
BEGIN
   IF rectype IS NULL OR rectype = ''
   THEN
      v_rectype := '%';
   ELSE
      v_rectype := rectype;
   END IF;

   DBMS_OUTPUT.put_line (v_rectype || '-rectype');
 --  DBMS_OUTPUT.put_line (locncode || '-locncode');
   DBMS_OUTPUT.put_line (emvtype || '-emvtype');

   IF emvtype = 'N'
   THEN
      INSERT INTO CMS_CAFGEN_DATA_TEMP
       (SELECT /*+ RULE */ CMS_CAF_INFO.*
		FROM CMS_CAF_INFO, CMS_APPL_PAN, CMS_BRAN_MAST b,CMS_BIN_MAST a, cms_bin_param bp, cms_prod_mast p, cms_prod_bin pb
		WHERE cap_pan_code = TRIM (cci_pan_code)
		AND cap_mbr_numb = cci_mbr_numb
		AND cci_inst_code = instcode -- put instcode
		AND cci_file_gen = 'N'
		AND cci_rec_typ LIKE v_rectype -- Put v_rectype
		AND b.cbm_inst_code = instcode -- Put instcode
		AND cap_appl_bran = cbm_bran_code
		AND cap_pin_flag = 'N'
		AND cap_embos_flag = 'N'
		AND SUBSTR(cci_pan_code,0,6)= a.cbm_inst_bin
		AND cci_inst_code= a.cbm_inst_code
		AND bp.cbp_inst_code = p.cpm_inst_code
		AND bp.cbp_profile_code = p.cpm_profile_code
		AND p.cpm_inst_code = pb.cpb_inst_code
		AND p.cpm_prod_code = pb.cpb_prod_code
		AND p.cpm_prod_code = cap_prod_code
		AND p.cpm_inst_code = cap_inst_code
		and a.cbm_inst_bin  = pb.CPB_INST_BIN
		AND bp.cbp_param_value = 'N'
		AND bp.cbp_param_name = 'EMV'
		);
   ELSIF emvtype = 'Y'
   THEN
      INSERT INTO CMS_CAFGEN_DATA_TEMP
         (SELECT /*+ RULE */ CMS_CAF_INFO.*
		FROM CMS_CAF_INFO, CMS_APPL_PAN, CMS_BRAN_MAST b,CMS_BIN_MAST a, cms_bin_param bp, cms_prod_mast p, cms_prod_bin pb
		WHERE cap_pan_code = TRIM (cci_pan_code)
		AND cap_mbr_numb = cci_mbr_numb
		AND cci_inst_code = instcode
		AND cci_file_gen = 'N'
		AND cci_rec_typ LIKE v_rectype
		AND b.cbm_inst_code = instcode
		AND cap_appl_bran = cbm_bran_code
		AND cap_pin_flag = 'N'
		AND cap_embos_flag = 'N'
		AND SUBSTR(cci_pan_code,0,6)= a.cbm_inst_bin
		AND cci_inst_code= a.cbm_inst_code
		AND bp.cbp_inst_code = p.cpm_inst_code
		AND bp.cbp_profile_code = p.cpm_profile_code
		AND p.cpm_inst_code = pb.cpb_inst_code
		AND p.cpm_prod_code = pb.cpb_prod_code
		AND p.cpm_prod_code = cap_prod_code
		AND p.cpm_inst_code = cap_inst_code
		and a.cbm_inst_bin  = pb.CPB_INST_BIN
		AND bp.cbp_param_value IN ('S','I','P')
		AND bp.cbp_param_name = 'EMV');--Modified by SOniya for CR=251 to include 'P'
   END IF;

   DBMS_OUTPUT.put_line (SQL%ROWCOUNT);
   COMMIT;

END;
/


