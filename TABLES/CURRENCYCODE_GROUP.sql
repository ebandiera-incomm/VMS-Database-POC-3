CREATE TABLE VMSCMS.CURRENCYCODE_GROUP
(
  CURRENCYCODE         VARCHAR2(4 BYTE)         NOT NULL,
  CURRENCYCODEGROUPID  VARCHAR2(4 BYTE)         NOT NULL,
  CUR_LUPD_DATE        DATE,
  CUR_INST_CODE        NUMBER(10),
  CUR_LUPD_USER        NUMBER(10),
  CUR_INS_DATE         DATE,
  CUR_INS_USER         NUMBER(10)
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


ALTER TABLE VMSCMS.CURRENCYCODE_GROUP ADD (
  CONSTRAINT CURRENCYCODEGROUP
 PRIMARY KEY
 (CURRENCYCODE, CURRENCYCODEGROUPID))
/

ALTER TABLE VMSCMS.CURRENCYCODE_GROUP ADD (
  CONSTRAINT CURRGROUP_PK 
 FOREIGN KEY (CURRENCYCODEGROUPID) 
 REFERENCES VMSCMS.CURRENCYCODEGROUPING (CURRENCYCODEGROUPID),
  CONSTRAINT CURR_PK 
 FOREIGN KEY (CURRENCYCODE) 
 REFERENCES VMSCMS.CURRENCYCODE (CURRENCYCODE))
/
