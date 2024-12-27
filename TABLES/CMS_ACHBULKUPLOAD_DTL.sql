CREATE TABLE vmscms.cms_achbulkupload_dtl
(
  cad_inst_code      NUMBER(3)                  NOT NULL,
  cad_source_name    VARCHAR2(200 BYTE),
  cad_ins_date       DATE,
  cad_ins_user       NUMBER(10),
  cad_prod_code      VARCHAR2(6 BYTE),
  cad_resp_msg       VARCHAR2(200 BYTE),
  cad_file_name      VARCHAR2(50 BYTE)          NOT NULL,
  cad_row_id         NUMBER(10)                 NOT NULL,
  cad_attach_type    VARCHAR2(20 BYTE),
  cad_business_date  VARCHAR2(8 BYTE),
  cad_business_time  VARCHAR2(6 BYTE)
) TABLESPACE CMS_SML_TXN;