CREATE TABLE VMSCMS.CMS_SPPRT_FEE
(
  CSF_PAN_CODE       VARCHAR2(90 BYTE)          NOT NULL,
  CSF_ACCT_NO        VARCHAR2(20 BYTE)          NOT NULL,
  CSF_FEE_AMT        NUMBER                     NOT NULL,
  CSF_FEE_NARRATION  VARCHAR2(40 BYTE),
  CSF_SPPRT_KEY      VARCHAR2(6 BYTE)           NOT NULL,
  CSF_INS_USER       NUMBER                     NOT NULL,
  CSF_INS_DATE       DATE                       NOT NULL,
  CSF_LUPD_DATE      DATE,
  CSF_INST_CODE      NUMBER(10),
  CSF_LUPD_USER      NUMBER(10),
  CSF_PAN_CODE_ENCR  RAW(100)
)
TABLESPACE CMS_SML_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

