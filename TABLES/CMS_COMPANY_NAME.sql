CREATE TABLE vmscms.cms_company_name
(
ccn_inst_code NUMBER(3) NOT NULL,
ccn_company_name VARCHAR(100) NOT NULL,
ccn_ins_date DATE,
ccn_ins_user NUMBER(10)
)
TABLESPACE CMS_SML_TXN;