CREATE TABLE VMSCMS.CMS_ACCTLVL_FEELIMIT_HIST
(
  CAH_ACCT_ID     NUMBER(10)                    NOT NULL,
  CAH_FEE_CODE    NUMBER(4)                     NOT NULL,
  CAH_LIMIT_USED  NUMBER(5)                     NOT NULL,
  CAH_MAX_LIMIT   NUMBER(5)                     NOT NULL,
  CAH_FREQ_TYPE   VARCHAR2(1 BYTE)              NOT NULL,
  CAH_INS_DATE    DATE                          NOT NULL,
  CAH_INST_CODE   NUMBER(3)                     NOT NULL,
  CAH_INS_USER    NUMBER(5)                     DEFAULT 1                     NOT NULL,
  CAH_LUPD_USER   NUMBER(5)                     DEFAULT 1                     NOT NULL
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


