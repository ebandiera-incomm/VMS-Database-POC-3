CREATE TABLE VMSCMS.CMS_UNBLOCK_DETAIL
(
  CUD_INST_CODE     NUMBER(3),
  CUD_CARD_NO       VARCHAR2(90 BYTE),
  CUD_FILE_NAME     VARCHAR2(30 BYTE),
  CUD_REMARKS       VARCHAR2(100 BYTE),
  CUD_MSG24_FLAG    CHAR(1 BYTE)                DEFAULT 'N',
  CUD_PROCESS_FLAG  VARCHAR2(1 BYTE),
  CUD_PROCESS_MSG   VARCHAR2(300 BYTE),
  CUD_PROCESS_MODE  VARCHAR2(1 BYTE),
  CUD_INS_USER      NUMBER(5),
  CUD_INS_DATE      DATE,
  CUD_LUPD_USER     NUMBER(5),
  CUD_LUPD_DATE     DATE,
  CUD_CARD_NO_ENCR  RAW(100)
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

