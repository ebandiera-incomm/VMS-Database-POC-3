CREATE TABLE VMSCMS.CMS_VELOCITY1000_TXN24HRS
(
  CHR_ACCOUNT_NO               VARCHAR2(30 BYTE),
  CHR_PRIMARY_CARD_NUMBER      VARCHAR2(90 BYTE),
  CHR_EXPIRY_DATE              VARCHAR2(10 BYTE),
  CHR_CARD_HOLDER_NAME         VARCHAR2(90 BYTE),
  CHR_ADDRESS                  VARCHAR2(200 BYTE),
  CHR_PHONE_NUMBER             VARCHAR2(40 BYTE),
  CHR_TXN_DATE                 VARCHAR2(100 BYTE),
  CHR_BALANCE                  VARCHAR2(100 BYTE),
  CHR_LOAD_AMOUNT              VARCHAR2(30 BYTE),
  CHR_RESPONSE_CODE            VARCHAR2(50 BYTE),
  CHR_TERM_ID                  VARCHAR2(20 BYTE),
  CHR_TERM_OWNER               VARCHAR2(30 BYTE),
  CHR_TERM_CITY_STATE_COUNTRY  VARCHAR2(100 BYTE)
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

