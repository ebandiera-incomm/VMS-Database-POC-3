CREATE UNIQUE INDEX VMSCMS.UN_CFM_TTD ON VMSCMS.CMS_FUNC_MAST
(CFM_INST_CODE, CFM_TXN_CODE, CFM_TXN_MODE, CFM_DELIVERY_CHANNEL)
LOGGING
TABLESPACE USERS
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

