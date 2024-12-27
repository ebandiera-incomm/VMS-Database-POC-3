CREATE TABLE VMSCMS.CMS_ACCT_GIFT
(
  CAG_INST_CODE   NUMBER(3)                     NOT NULL,
  CAG_ACCT_ID     NUMBER(10)                    NOT NULL,
  CAG_GIFT_ORDER  NUMBER(14)                    NOT NULL,
  CAG_INS_USER    NUMBER(5)                     NOT NULL,
  CAG_INS_DATE    DATE                          NOT NULL,
  CAG_LUPD_USER   NUMBER(5)                     NOT NULL,
  CAG_LUPD_DATE   DATE                          NOT NULL
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


