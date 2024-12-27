CREATE TABLE VMSCMS.CMS_SUMMARY_MERINV
(
  CSM_INST_CODE        NUMBER(3)                NOT NULL,
  CSM_FILE_NAME        VARCHAR2(50 BYTE)        NOT NULL,
  CSM_SUCCESS_RECORDS  NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSM_ERROR_RECORDS    NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSM_TOT_RECORDS      NUMBER(10)               DEFAULT 0                     NOT NULL,
  CSM_INS_USER         NUMBER                   NOT NULL,
  CSM_INS_DATE         DATE                     NOT NULL,
  CSM_LUPD_USER        NUMBER(10)               NOT NULL,
  CSM_LUPD_DATE        DATE                     NOT NULL,
  CSM_FILE_TYPE        VARCHAR2(1 BYTE)
)
TABLESPACE CMS_SML_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


