CREATE TABLE VMSCMS.PREPAID_TABLESPACE_DTL
(
  PTD_TABLESPACE_NAME  VARCHAR2(30 BYTE),
  PTD_SIZE_INGB_1STYR  NUMBER,
  PTD_SIZE_INGB_2NDYR  NUMBER,
  PTD_SIZE_INGB_3RDYR  NUMBER,
  PTD_INST_CODE        NUMBER(10),
  PTD_INS_DATE         DATE
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

