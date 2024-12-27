Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'CCF_INV_QRY','SELECT NVL (TO_CHAR (cmm_location_id), ''*'') loc,
  fn_dmaps_main (cap_pan_code_encr) pan,
  cap_pan_code_encr encrPan,
  cap_pan_code hashPan,
  TO_CHAR (cap_expry_date, ''YYMM'') expryDate,
  cap_disp_name dispname,
  mm.srvCode,
  cap_acct_no acctNo,
  cap_expry_date expirydate,
  cap_prod_code prodCode,
  mm.cpC_profile_code profCode,
  CPC_CARD_DETAILS AS cardId ,
  cap_proxy_number proxyNumber,
  cap_card_type cardType,
  cap_card_stat cardStat,
  cap_cust_code custCode,
  DECODE (cap_repl_flag, 2, cap_repl_flag, NVL (mm.cpc_del_met, 1) ) deliveryMethod,
  mm.logoId
FROM cms_appl_pan_temp,
  cms_merinv_merpan,
  CMS_MERINV_PRODCAT,
  cms_prod_cardpack cp,
  VMS_PACKAGEID_MAST PACKIDMAST,
  (SELECT cpm_prod_code,
    CPM_PROD_DESC,
    c.CPC_CARD_ID,
    cpc_prod_code,
    cpc_profile_code,
    cpc_card_type,
    cpc_cardtype_desc,
    cpb_inst_bin,
    cpm_inst_code,
    cpc_del_met,
    cbp_param_value srvcode,
    LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId
  FROM cms_prod_mast b,
    cms_prod_cattype c,
    cms_prod_bin r,
    cms_bin_param t
  WHERE b.cpm_inst_code  = c.cpc_inst_code
  AND b.cpm_prod_code    = c.cpc_prod_code
  AND b.cpm_inst_code    = r.cpb_inst_code
  AND B.CPM_PROD_CODE    = R.CPB_PROD_CODE
  AND r.cpb_inst_bin     = ?
  AND t.cbp_inst_code    = b.cpm_inst_code
  AND t.cbp_profile_code = c.cpc_profile_code
  AND t.cbp_param_name   = ''Service Code''
  ) mm
WHERE cap_inst_code          = cmm_inst_code
AND cap_pan_code             = cmm_pan_code
AND cmm_ordr_refrno         IN (MS_STARTER_FILES)
AND cmm_inst_code            = cmp_inst_code
AND cmm_merprodcat_id        = cmp_merprodcat_id
AND cmp_inst_code            = mm.cpm_inst_code
AND cmp_prod_code            = mm.cpc_prod_code
AND cmp_prod_cattype         = mm.cpc_card_type
AND cp.CPC_INST_CODE         = cmp_inst_code
AND cp.CPC_PROD_CODE         = cmp_prod_code
AND cp.CPC_CARD_ID           = CMP_CARD_ID
AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
AND CP.CPC_CARD_ID           =mm.CPC_CARD_ID
AND cp.CPC_PROD_CODE         =mm.CPm_PROD_CODE
AND PACKIDMAST.VPM_VENDOR_ID =?
AND cap_proxy_msg            = ''Success''
ORDER BY cap_proxy_number','loc,pan,encrPan,hashPan,expryDate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,cardStat,custCode,deliveryMethod,logoId',1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'),1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'));
Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'REGEN_CARDSTOCK_QRY','SELECT DISTINCT NVL(TO_CHAR(CML_LOCATION_ID),''*'') locId,
  NVL(TO_CHAR(CML_LOCATION_ID),CCI_STORE_ID) loc,
  FN_DMAPS_MAIN(CAP_PAN_CODE_ENCR) pan,
  TO_CHAR(CAP_EXPRY_DATE,''YYMM'') expryDate,
  CAP_DISP_NAME dispname,
  CBP_PARAM_VALUE srvCode,
  CAM_ACCT_NO acctNo,
  CAP_EXPRY_DATE expirydate,
  CAP_PROD_CODE prodCode,
  CPC_PROFILE_CODE profCode,
  NVL(cci_package_type,cp.cpc_card_details) cardId ,
  CAP_PROXY_NUMBER proxyNumber ,
  CAP_CARD_TYPE cardType,
  DECODE (cap_repl_flag, 0, NVL(cpc_del_met,1),cap_repl_flag) deliveryMethod,
  CAP_IPIN_OFFSET encryptedPinData,
  LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId
FROM CMS_APPL_PAN,
  CMS_CARDISSUANCE_STATUS,
  CMS_BIN_PARAM,
  CMS_PROD_MAST,
  CMS_ACCT_MAST,
  CMS_PROD_CATTYPE CT,
  cms_merinv_location,
  CMS_MERINV_MERPAN pan,
  CMS_CAF_INFO_ENTRY,
  cms_prod_cardpack cp ,
  CMS_MERINV_PRODCAT PM,
   VMS_PACKAGEID_MAST PACKIDMAST
WHERE CAP_INST_CODE    =CCS_INST_CODE
AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
AND CP.CPC_CARD_ID           =CT.CPC_CARD_ID
AND CP.CPC_PROD_CODE         =Ct.CPC_PROD_CODE
AND CAP_PAN_CODE       =CCS_PAN_CODE
AND cap_mbr_numb       =''000''
AND CBP_PROFILE_CODE   =CPC_PROFILE_CODE
AND CPM_PROD_CODE      =CAP_PROD_CODE
AND CAP_ACCT_ID        =CAM_ACCT_ID
AND CBP_PARAM_NAME     =''Service Code''
AND CCS_CCF_FNAME      =?
AND ct.CPC_PROD_CODE   = CAP_PROD_CODE
AND CPC_CARD_TYPE      = CAP_CARD_TYPE
AND cam_inst_code      =cap_inst_code
AND cpm_inst_code      =cap_inst_code
AND CT.CPC_INST_CODE   =CAP_INST_CODE
AND CBP_INST_CODE      =CAP_INST_CODE
AND cp.CPC_CARD_ID     =ct.CPC_CARD_ID
AND cp.cpc_inst_code   =ct.cpc_inst_code
AND cap_appl_code      =cmm_appl_code(+)
AND cmm_mer_id         = cml_mer_id(+)
AND cmm_location_id    =cml_location_id(+)
AND CAP_APPL_CODE      =CCI_APPL_CODE(+)
AND CAP_PAN_CODE       = CMM_PAN_CODE(+)
AND CAP_CARD_STAT     <> ''9''
AND CAP_PAN_CODE_ENCR IS NOT NULL
ORDER BY CAP_PROXY_NUMBER','locId,loc,pan,expryDate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,deliveryMethod,encryptedPinData,logoId',1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'),1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'));
Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'REGEN_INV_QRY','SELECT DISTINCT NVL(TO_CHAR(CML_LOCATION_ID),''*'') locId,
  NVL(TO_CHAR(CML_LOCATION_ID),CCI_STORE_ID) loc,
  FN_DMAPS_MAIN(CAP_PAN_CODE_ENCR) pan,
  TO_CHAR(CAP_EXPRY_DATE,''YYMM'') expryDate,
  CAP_DISP_NAME dispname,
  CBP_PARAM_VALUE srvCode,
  CAM_ACCT_NO acctNo,
  CAP_EXPRY_DATE expirydate,
  CAP_PROD_CODE prodCode,
  CPc_PROFILE_CODE profCode,
  NVL(cci_package_type,cp.cpc_card_details) cardId ,
  CAP_PROXY_NUMBER proxyNumber ,
  CAP_CARD_TYPE cardType,
  DECODE (cap_repl_flag, 0, NVL(cpc_del_met,1),cap_repl_flag) deliveryMethod,
  CAP_IPIN_OFFSET encryptedPinData,
  LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId
FROM CMS_APPL_PAN,
  CMS_CARDISSUANCE_STATUS,
  CMS_BIN_PARAM,
  CMS_PROD_MAST,
  CMS_ACCT_MAST,
  CMS_PROD_CATTYPE CT,
  cms_merinv_location,
  CMS_MERINV_MERPAN pan,
  CMS_CAF_INFO_ENTRY,
  cms_prod_cardpack cp ,
  CMS_MERINV_PRODCAT PM,
  VMS_PACKAGEID_MAST PACKIDMAST
WHERE CAP_INST_CODE      =CCS_INST_CODE
AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
AND CP.CPC_CARD_ID           =CT.CPC_CARD_ID
AND CP.CPC_PROD_CODE         =Ct.CPC_PROD_CODE
AND CAP_PAN_CODE         =CCS_PAN_CODE
AND cap_mbr_numb         =''000''
AND CBP_PROFILE_CODE     =CPC_PROFILE_CODE
AND CPM_PROD_CODE        =CAP_PROD_CODE
AND CAP_ACCT_ID          =CAM_ACCT_ID
AND CBP_PARAM_NAME       =''Service Code''
AND CCS_CCF_FNAME        =?
AND ct.CPC_PROD_CODE     = CAP_PROD_CODE
AND CPC_CARD_TYPE        = CAP_CARD_TYPE
AND cam_inst_code        =cap_inst_code
AND cpm_inst_code        =cap_inst_code
AND ct.cpc_inst_code     =cap_inst_code
AND cbp_inst_code        =cap_inst_code
AND pm.cmp_card_id       =cp.cpc_card_id
AND pan.cmm_merprodcat_id=pm.cmp_merprodcat_id
AND cap_appl_code        =cmm_appl_code(+)
AND cmm_mer_id           = cml_mer_id(+)
AND cmm_location_id      =cml_location_id(+)
AND CAP_APPL_CODE        =CCI_APPL_CODE(+)
AND CAP_PAN_CODE         = CMM_PAN_CODE(+)
AND CAP_CARD_STAT       <> ''9''
AND CAP_PAN_CODE_ENCR   IS NOT NULL
ORDER BY CAP_PROXY_NUMBER','locId,loc,pan,expryDate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,deliveryMethod,encryptedPinData,logoId',1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'),1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'));
Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'CCF_REISU_DTL_QUERY','SELECT cci_store_id loc,
  fn_dmaps_main (cap_pan_code_encr) pan,
  cap_pan_code_encr encrPan,
  cap_pan_code hashPan,
  NVL(TO_CHAR(CAP_REPLACE_EXPRYDT,''YYMM''),TO_CHAR (cap_expry_date, ''YYMM'')) exprydate,
  cap_disp_name dispname,
  cbp_param_value srvCode,
  cam_acct_no acctNo,
  NVL(CAP_REPLACE_EXPRYDT, cap_expry_date) expirydate,
  cap_prod_code prodCode,
  cpc_profile_code profCode,
  cp.CPC_CARD_DETAILS AS cardId ,
  cap_proxy_number proxyNumber,
  cap_card_type cardType,
  cap_card_stat cardStat,
  cap_cust_code custCode,
  cci_package_type packType,
  DECODE (cap_repl_flag, 0, NVL(c.cpc_del_met,1),cap_repl_flag) deliveryMethod,
  LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId,
  ccs_card_status cardStatus
FROM cms_appl_pan,
  cms_cardissuance_status,
  cms_bin_param,
  cms_prod_mast,
  cms_prod_bin,
  cms_acct_mast,
  cms_prod_cattype c,
  cms_caf_info_entry ,
  cms_prod_cardpack cp,
  VMS_PACKAGEID_MAST PACKIDMAST
WHERE cap_inst_code     = ccs_inst_code
AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
AND CP.CPC_CARD_ID     =C.CPC_CARD_ID
AND cp.CPC_PROD_CODE   =c.CPC_PROD_CODE
AND PACKIDMAST.VPM_VENDOR_ID=?
AND cap_pan_code        = ccs_pan_code
AND cpm_inst_code       = cap_inst_code
AND cpm_prod_code       = cap_prod_code
AND cpb_inst_code       = cpm_inst_code
AND cpb_prod_code       =cpm_prod_code
AND cbp_inst_code       =cpm_inst_code
AND cbp_profile_code    = cpC_profile_code
AND cam_inst_code       =cap_inst_code
AND cam_acct_id         =cap_acct_id
AND c.cpc_inst_code     = cap_inst_code
AND c.cpc_prod_code     = cap_prod_code
AND c.cpc_card_type     = cap_card_type
AND cp.CPC_INST_CODE    = c.cpc_inst_code
AND cp.CPC_PROD_CODE    = c.cpc_prod_code
AND cp.CPC_CARD_ID      = c.CPC_CARD_ID
AND cap_pan_code_encr  IS NOT NULL
AND cci_appl_code(+)    =TO_CHAR(cap_appl_code)
AND cap_pan_code       IN
  (SELECT chr_new_pan
  FROM CMS_HTLST_REISU
  WHERE chr_inst_code=cap_inst_code
  AND chr_new_pan    =cap_pan_code
  AND CHR_REISU_CAUSE=''R''
  )
AND cap_inst_code       =1
AND cap_mbr_numb        = ''000''
AND cap_startercard_flag=''N''
AND cap_card_stat      <> ''9''
AND cap_proxy_msg       = ''Success''
AND cpb_inst_bin        = ?
AND cbp_param_name      = ''Service Code''
AND (ccs_card_status    = ''2''
OR ccs_card_status      =''20'')
ORDER BY cap_proxy_number','loc,pan,encrPan,hashPan,exprydate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,cardStat,custCode,packType,deliveryMethod,logoId,cardStatus',1,to_date('11-07-17 07:35:37','DD-MM-RR HH12:MI:SS'),1,to_date('11-07-17 07:35:37','DD-MM-RR HH12:MI:SS'));
Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'CCF_DTL_QUERY','SELECT cci_store_id loc,
  fn_dmaps_main (cap_pan_code_encr) pan,
  cap_pan_code_encr encrPan,
  cap_pan_code hashPan,
  NVL(TO_CHAR(CAP_REPLACE_EXPRYDT,''YYMM''),TO_CHAR (cap_expry_date, ''YYMM'')) expryDate,
  cap_disp_name dispname,
  cbp_param_value srvCode,
  cam_acct_no acctNo,
  NVL(CAP_REPLACE_EXPRYDT, cap_expry_date) expirydate,
  cap_prod_code prodCode,
  cpc_profile_code profCode,
  cp.CPC_CARD_DETAILS AS cardId ,
  cap_proxy_number proxyNumber,
  cap_card_type cardType,
  cap_card_stat cardStat,
  cap_cust_code custCode,
  cci_package_type packType,
  DECODE (cap_repl_flag, 0, NVL(c.cpc_del_met,1),cap_repl_flag) deliveryMethod,
  LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId,
  ccs_card_status  cardStatus
FROM cms_appl_pan,
  cms_cardissuance_status,
  cms_bin_param,
  cms_prod_mast,
  cms_prod_bin,
  cms_acct_mast,
  cms_prod_cattype c,
  cms_caf_info_entry ,
  cms_prod_cardpack cp,  VMS_PACKAGEID_MAST PACKIDMAST
WHERE cap_inst_code     = ccs_inst_code
AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
AND CP.CPC_CARD_ID     =C.CPC_CARD_ID
AND cp.CPC_PROD_CODE   =c.CPC_PROD_CODE
AND PACKIDMAST.VPM_VENDOR_ID=?
AND cap_pan_code        = ccs_pan_code
AND cpm_inst_code       = cap_inst_code
AND cpm_prod_code       = cap_prod_code
AND cpb_inst_code       = cpm_inst_code
AND cpb_prod_code       =cpm_prod_code
AND cbp_inst_code       =cpm_inst_code
AND cbp_profile_code    = cpc_profile_code
AND cam_inst_code       =cap_inst_code
AND cam_acct_id         =cap_acct_id
AND c.cpc_inst_code     = cap_inst_code
AND c.cpc_prod_code     = cap_prod_code
AND c.cpc_card_type     = cap_card_type
AND cp.CPC_INST_CODE    = c.cpc_inst_code
AND cp.CPC_PROD_CODE    = c.cpc_prod_code
AND cp.CPC_CARD_ID      = c.CPC_CARD_ID
AND cap_pan_code_encr  IS NOT NULL
AND cci_appl_code(+)    =TO_CHAR(cap_appl_code)
AND cap_pan_code NOT   IN
  (SELECT chr_new_pan
  FROM CMS_HTLST_REISU
  WHERE chr_inst_code=cap_inst_code
  AND chr_new_pan    =cap_pan_code
  AND CHR_REISU_CAUSE=''R''
  )
AND cap_inst_code       =1
AND cap_mbr_numb        = ''000''
AND cap_startercard_flag=''N''
AND cap_card_stat      <> ''9''
AND cap_proxy_msg       = ''Success''
AND cpb_inst_bin        = ?
AND cbp_param_name      = ''Service Code''
AND (ccs_card_status    = ''2''
OR ccs_card_status      =''20'')
ORDER BY cap_proxy_number','loc,pan,encrPan,hashPan,expryDate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,cardStat,custCode,packType,deliveryMethod,logoId,cardStatus',1,to_date('11-07-17 07:35:37','DD-MM-RR HH12:MI:SS'),1,to_date('11-07-17 07:35:37','DD-MM-RR HH12:MI:SS'));
Insert into VMSCMS.VMS_CONFIG_QUERY (VCQ_INST_CODE,VCQ_QUERY_ID,VCQ_QUERY_VALUE,VCQ_QUERY_SELECTVALUE,VCQ_INS_USER,VCQ_INS_DATE,VCQ_LUPD_USER,VCQ_LUPD_DATE) values (1,'CCF_CARDSTOCK_QRY','SELECT cci_store_id loc,
  fn_dmaps_main (cap_pan_code_encr) pan,
  cap_pan_code_encr encrPan,
  cap_pan_code hashPan,
  TO_CHAR (cap_expry_date, ''YYMM'') expryDate,
  cap_disp_name dispname,
  mm.srvCode,
  cap_acct_no acctNo,
  cap_expry_date expirydate,
  cap_prod_code prodCode,
  mm.cpc_profile_code profCode,
  mm.CPC_CARD_DETAILS AS cardId ,
  cap_proxy_number proxyNumber,
  cap_card_type cardType,
  cap_card_stat cardStat,
  cap_cust_code custCode,
  DECODE (cap_repl_flag, 2, cap_repl_flag, NVL (mm.cpc_del_met, 1) ) deliveryMethod,
  mm.logoId logoId
FROM
  (SELECT cpm_prod_code,
    cpm_prod_desc,
    c.cpc_prod_code,
    csr_file_name,
    cpc_profile_code,
    c.cpc_card_type,
    cp.CPC_CARD_DETAILS,
    c.cpc_cardtype_desc,
    cpb_inst_bin,
    cpm_inst_code,
    c.cpc_del_met,
    c.cpc_inst_code,
    csr_bran_fiid,
    cbp_param_value srvcode,
    LPAD(NVL(cpc_logo_id,''0''),6,''0'') logoId
  FROM cms_prod_mast b,
    cms_prod_cattype c,
    cms_prod_bin r,
    cms_stock_report g,
    cms_bin_param t ,
    CMS_PROD_CARDPACK CP,
    VMS_PACKAGEID_MAST PACKIDMAST
  WHERE b.cpm_inst_code        = c.cpc_inst_code
  AND b.cpm_prod_code          = c.cpc_prod_code
  AND b.cpm_inst_code          = r.cpb_inst_code
  AND b.cpm_prod_code          = r.cpb_prod_code
  AND cp.CPC_INST_CODE         = c.cpc_inst_code
  AND cp.CPC_PROD_CODE         = c.cpc_prod_code
  AND cp.CPC_CARD_ID           = c.CPC_CARD_ID
  AND r.cpb_inst_bin           = ?
  AND PACKIDMAST.VPM_PACKAGE_ID=CP.CPC_CARD_DETAILS
  AND CP.CPC_CARD_ID           =C.CPC_CARD_ID
  AND CP.CPC_PROD_CODE         =C.CPC_PROD_CODE
  AND PACKIDMAST.VPM_VENDOR_ID =?
  AND g.csr_file_name          = MS_STARTER_FILES
  AND c.cpc_inst_code          = g.csr_inst_code
  AND c.cpc_prod_code          = g.csr_prod_code
  AND c.cpc_card_type          = g.csr_card_type
  AND t.cbp_inst_code          = b.cpm_inst_code
  AND t.cbp_profile_code       = c.cpc_profile_code
  AND t.cbp_param_name         = ''Service Code''
  ) mm,
  cms_appl_pan_temp,
  cms_caf_info_entry
WHERE cap_file_name  =MS_STARTER_FILES
AND mm.cpm_inst_code = cap_inst_code
AND mm.cpm_prod_code = cap_prod_code
AND mm.cpc_inst_code = cap_inst_code
AND mm.cpc_prod_code = cap_prod_code
AND mm.cpc_card_type = cap_card_type
AND cci_inst_code    =cap_inst_code
AND cci_appl_code    =TO_CHAR(cap_appl_code)
AND cci_inst_code    = mm.cpm_inst_code
AND cci_file_name    = mm.csr_file_name
AND cap_proxy_msg    = ''Success''
ORDER BY cap_proxy_number ','loc,pan,encrPan,hashPan,expryDate,dispname,srvCode,acctNo,expirydate,prodCode,profCode,cardId,proxyNumber,cardType,cardStat,custCode,deliveryMethod,logoId',1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'),1,to_date('14-07-17 12:42:18','DD-MM-RR HH12:MI:SS'));
