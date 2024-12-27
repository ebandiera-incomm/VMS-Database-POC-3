CREATE TABLE VMSCMS.CMS_FEECAP_DTL
(
  CFD_INST_CODE    NUMBER(3)                    NOT NULL,
  CFD_ACCT_NO      VARCHAR2(20 BYTE)            NOT NULL,
  CFD_FEE_CODE     NUMBER(4)                    NOT NULL,
  CFD_FEE_PERIOD   DATE                         NOT NULL,
  CFD_FEE_CAP      NUMBER(15,2)                 NOT NULL,
  CFD_FEE_ACCRUED  NUMBER(15,2)                 NOT NULL,
  CFD_FEE_WAIVED   NUMBER(15,2)                 NOT NULL,
  CFD_INS_USER     NUMBER(5)                    NOT NULL,
  CFD_INS_DATE     DATE                         NOT NULL,
  CFD_LUPD_USER    NUMBER(5)                    NOT NULL,
  CFD_LUPD_DATE    DATE                         NOT NULL
)
TABLESPACE CMS_BIG_TXN
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/


