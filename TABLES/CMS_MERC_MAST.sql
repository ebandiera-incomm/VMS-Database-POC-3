CREATE TABLE VMSCMS.CMS_MERC_MAST
(
  CMM_INST_CODE       NUMBER(3)                 NOT NULL,
  CMM_MERC_CODE       VARCHAR2(8 BYTE)          NOT NULL,
  CMM_MERC_CATG       VARCHAR2(4 BYTE)          NOT NULL,
  CMM_MERC_NAME       VARCHAR2(75 BYTE)         NOT NULL,
  CMM_INS_USER        NUMBER(5)                 NOT NULL,
  CMM_INS_DATE        DATE                      NOT NULL,
  CMM_LUPD_USER       NUMBER(5)                 NOT NULL,
  CMM_LUPD_DATE       DATE                      NOT NULL,
  CMM_MERC_PROD_TYPE  VARCHAR2(1 BYTE)
)
TABLESPACE CMS_MAST
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


ALTER TABLE VMSCMS.CMS_MERC_MAST ADD (
  CONSTRAINT PK_MERC_MAST
 PRIMARY KEY
 (CMM_INST_CODE, CMM_MERC_CODE))
/

ALTER TABLE VMSCMS.CMS_MERC_MAST ADD (
  CONSTRAINT FK_MERCMAST_USERMAST1 
 FOREIGN KEY (CMM_INS_USER) 
 REFERENCES VMSCMS.CMS_USER_MAST (CUM_USER_PIN),
  CONSTRAINT FK_MERCMAST_USERMAST2 
 FOREIGN KEY (CMM_LUPD_USER) 
 REFERENCES VMSCMS.CMS_USER_MAST (CUM_USER_PIN))
/
