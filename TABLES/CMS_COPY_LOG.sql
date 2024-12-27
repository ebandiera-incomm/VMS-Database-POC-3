CREATE TABLE vmscms.cms_copy_log
(
  ccl_inst_code      NUMBER(10)                 NOT NULL,
  ccl_log_id         NUMBER(10)                 DEFAULT 0                     NOT NULL,
  ccl_copied_to      VARCHAR2(100 BYTE)         NOT NULL,
  ccl_copied_from    VARCHAR2(100 BYTE)         NOT NULL,
  ccl_copied_type    CHAR(1 BYTE)               NOT NULL,
  ccl_ins_date       DATE                       NOT NULL,
  ccl_ins_user       NUMBER(10)                 NOT NULL,
  ccl_fromcard_type  NUMBER(2),
  ccl_tocard_type    NUMBER(2),
  CONSTRAINT pk_cms_copy_log
 PRIMARY KEY
 (ccl_inst_code, ccl_log_id)
)
TABLESPACE cms_hist;