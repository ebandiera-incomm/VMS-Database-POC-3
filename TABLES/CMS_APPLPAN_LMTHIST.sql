CREATE TABLE VMSCMS.CMS_APPLPAN_LMTHIST
(
  CAL_PAN_CODE     VARCHAR2(90 BYTE),
  CAL_MBR_NUMB     VARCHAR2(3 BYTE),
  CAL_PROD_CODE    VARCHAR2(6 BYTE),
  CAL_PROD_CATG    VARCHAR2(2 BYTE),
  CAL_CARD_TYPE    NUMBER(2),
  CAL_PRFL_CODE    VARCHAR2(10 BYTE),
  CAL_PRFL_LEVL    NUMBER(1),
  CAL_ORGINS_USER  NUMBER(10),
  CAL_ORGINS_DATE  DATE,
  CAL_INS_DATE     DATE
)
TABLESPACE CMS_HIST
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

