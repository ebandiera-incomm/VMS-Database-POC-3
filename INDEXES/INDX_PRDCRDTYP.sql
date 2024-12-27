CREATE TABLE vmscms.drop_cms_appl_pan TABLESPACE CMS_BIG_TXN AS SELECT cap_pan_code , cap_proxy_number FROM vmscms.CMS_APPL_PAN;


CREATE INDEX vmscms.INDX_PRDCRDTYP ON vmscms.CMS_APPL_PAN
(CAP_PROD_CODE,CAP_CARD_TYPE, cap_pbfgen_flag, CAP_PROXY_NUMBER) TABLESPACE CMS_BIG_IDX
;

CREATE INDEX VMSCMS.INDX_CAFINFOTEMP_APPR ON VMSCMS.CMS_CAF_INFO_TEMP
(cci_upld_stat,         
cci_prod_code,
cci_card_type,
cci_cust_catg)TABLESPACE CMS_BIG_IDX
;
