CREATE TABLE VMSCMS.CMS_SUMMARY_STOCK_HIST
(
  CSS_INST_CODE        NUMBER(3)                NOT NULL,
  CSS_FILE_NAME        VARCHAR2(50 BYTE)        NOT NULL,
  CSS_TOT_RECORDS      NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSS_SUCCESS_RECORDS  NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSS_ERROR_RECORDS    NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSS_PROCESS_FLAG     VARCHAR2(1 BYTE)         DEFAULT 'N'                   NOT NULL,
  CSS_ERR_MSG          VARCHAR2(1000 BYTE),
  CSS_INS_USER         NUMBER                   NOT NULL,
  CSS_INS_DATE         DATE                     NOT NULL,
  CSS_LUPD_USER        NUMBER(10)               NOT NULL,
  CSS_LUPD_DATE        DATE                     NOT NULL
)
TABLESPACE CMS_SML_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


