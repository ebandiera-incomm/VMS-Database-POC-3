CREATE TABLE VMSCMS.CMS_GPR_CARDSTAT
(
  CGS_STAT_CODE  VARCHAR2(2 BYTE)               NOT NULL,
  CGS_STAT_DESC  VARCHAR2(90 BYTE)              NOT NULL,
  CGS_LUPD_DATE  DATE,
  CGS_INST_CODE  NUMBER(3),
  CGS_LUPD_USER  NUMBER(5),
  CGS_INS_DATE   DATE,
  CGS_INS_USER   NUMBER(5),
  CGC_STAT_FLAG  VARCHAR2(1 BYTE)
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


ALTER TABLE VMSCMS.CMS_GPR_CARDSTAT ADD (
  CONSTRAINT PK_CARD_STAT
 PRIMARY KEY
 (CGS_STAT_CODE, CGS_INST_CODE))
/
