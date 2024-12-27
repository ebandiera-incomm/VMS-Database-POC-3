CREATE TABLE VMSCMS.CMS_ITEM_MAST
(
  CIM_INST_CODE      NUMBER(3)                  NOT NULL,
  CIM_ITEM_ID        VARCHAR2(6 BYTE)           NOT NULL,
  CIM_ITEM_DESC      VARCHAR2(50 BYTE)          NOT NULL,
  CIM_TOT_UNITS      NUMBER(5)                  DEFAULT 0                     NOT NULL,
  CIM_FREE_UNITS     NUMBER(5)                  DEFAULT 0                     NOT NULL,
  CIM_BOOKED_UNITS   NUMBER(5)                  DEFAULT 0                     NOT NULL,
  CIM_SHIPPED_UNITS  NUMBER(5)                  DEFAULT 0                     NOT NULL,
  CIM_REORD_LEVEL    NUMBER(5)                  DEFAULT 0                     NOT NULL,
  CIM_INS_USER       NUMBER(5)                  NOT NULL,
  CIM_INS_DATE       DATE                       NOT NULL,
  CIM_LUPD_USER      NUMBER(5)                  NOT NULL,
  CIM_LUPD_DATE      DATE                       NOT NULL,
  CIM_GIFT_VALUE     NUMBER(5)
)
TABLESPACE CMS_MAST
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


ALTER TABLE VMSCMS.CMS_ITEM_MAST ADD (
  CONSTRAINT CMS_ITEM_MAST_PK
 PRIMARY KEY
 (CIM_ITEM_ID),
  CONSTRAINT CIM_ITEM_DESC_UK
 UNIQUE (CIM_ITEM_DESC))
/

