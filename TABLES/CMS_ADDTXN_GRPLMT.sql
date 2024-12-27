CREATE TABLE VMSCMS.CMS_ADDTXN_GRPLMT
(
   cag_inst_code         NUMBER (10) NOT NULL,
   cag_DLVR_CHNL         VARCHAR2 (2) NOT NULL,
   cag_tran_code         VARCHAR2 (2) NOT NULL,
   cag_tran_desc         VARCHAR2 (50),
   cag_other_param       VARCHAR2 (100),
   cag_other_param_Key   VARCHAR2 (100),
   cag_lupd_date         DATE,
   cag_lupd_user         NUMBER (10),
   cag_ins_date          DATE NOT NULL,
   cag_ins_user          NUMBER (10) NOT NULL
)tablespace cms_mast;
