CREATE INDEX VMSCMS.IND_CHD_CARD_NO ON VMSCMS.CMS_HOTLIST_DETAIL
(CHD_CARD_NO)
LOGGING
TABLESPACE CMS_BIG_IDX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          10M
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

