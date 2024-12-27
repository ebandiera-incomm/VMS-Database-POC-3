CREATE TABLE VMSCMS.CMS_CORPORATE_WAIV
(
  CCW_INST_CODE    NUMBER(3)                    NOT NULL,
  CCW_PROD_CODE    VARCHAR2(6 BYTE)             NOT NULL,
  CCW_CARD_TYPE    NUMBER(2)                    NOT NULL,
  CCW_FEE_CODE     NUMBER(3)                    NOT NULL,
  CCW_CORP_CODE    NUMBER(3)                    NOT NULL,
  CCW_WAIV_PRCNT   NUMBER(5,2)                  NOT NULL,
  CCW_VALID_FROM   DATE                         NOT NULL,
  CCW_VALID_TO     DATE                         NOT NULL,
  CCW_WAIV_DESC    VARCHAR2(50 BYTE)            NOT NULL,
  CCW_FLOW_SOURCE  VARCHAR2(3 BYTE)             NOT NULL,
  CCW_INS_USER     NUMBER(5)                    NOT NULL,
  CCW_INS_DATE     DATE                         NOT NULL,
  CCW_LUPD_USER    NUMBER(5)                    NOT NULL,
  CCW_LUPD_DATE    DATE                         NOT NULL
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


