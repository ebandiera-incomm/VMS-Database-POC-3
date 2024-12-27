CREATE TABLE VMSCMS.CMS_GRPLMT_PARAM_HIST
(
   cgp_inst_code      NUMBER (10),
   cgp_group_code     VARCHAR2 (10),
   CgP_DLVR_CHNL      VARCHAR2 (2),
   cgp_tran_code      VARCHAR2 (2),
   CgP_INTL_FLAG      VARCHAR2 (2),
   CgP_PNSIGN_FLAG    VARCHAR2 (2),
   CgP_MCC_CODE       VARCHAR2 (4),
   CgP_TRFR_CRDACNT   VARCHAR2 (2),
   CGP_GRPCOMB_HASH   VARCHAR2 (90),
   cgp_lupd_date      DATE,
   cgp_lupd_user      NUMBER (10),
   cgp_orgins_date    DATE,
   cgp_orgins_user    NUMBER (10),
   cgp_ins_date       DATE
)tablespace cms_hist;