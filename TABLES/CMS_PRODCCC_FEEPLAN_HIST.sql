CREATE TABLE VMSCMS.CMS_PRODCCC_FEEPLAN_HIST
(
  CPF_INST_CODE    NUMBER(3),
  CPF_CUST_CATG    NUMBER(2),
  CPF_CARD_TYPE    NUMBER(2),
  CPF_PROD_CODE    VARCHAR2(6 BYTE),
  CPF_PLAN_CODE    VARCHAR2(4 BYTE),
  CPF_CITY_CATG    VARCHAR2(2 BYTE),
  CPF_CARD_POSN    NUMBER(2),
  CPF_VALID_FROM   DATE,
  CPF_VALID_TO     DATE,
  CPF_FLOW_SOURCE  VARCHAR2(3 BYTE),
  CPF_INS_USER     NUMBER(5),
  CPF_INS_DATE     DATE,
  CPF_LUPD_USER    NUMBER(5),
  CPF_LUPD_DATE    DATE,
  CPF_SEQ_ID       NUMBER(10),
  CPF_RECORD_DATE  DATE,
  CPF_CUST_TYPE    NUMBER(3)                    NOT NULL
)
TABLESPACE CMS_HIST
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING
/

