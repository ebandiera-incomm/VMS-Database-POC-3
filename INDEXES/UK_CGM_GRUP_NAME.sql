CREATE UNIQUE INDEX VMSCMS.UK_CGM_GRUP_NAME ON VMSCMS.CMS_GROUPDETL_MAST
(CGM_INST_CODE, CGM_GRUP_NAME)
LOGGING
TABLESPACE INCOMM
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

