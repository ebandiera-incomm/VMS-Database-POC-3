CREATE TABLE vmscms.cms_blacklist_sources
(
cbs_inst_code NUMBER(3) NOT NULL,
cbs_source_name VARCHAR(100) NOT NULL,
cbs_ins_date DATE,
cbs_ins_user NUMBER(10),
cbs_prod_code VARCHAR(6)
)
TABLESPACE CMS_SML_TXN;