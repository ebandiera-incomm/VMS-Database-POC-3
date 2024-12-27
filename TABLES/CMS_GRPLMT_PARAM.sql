CREATE TABLE VMSCMS.CMS_GRPLMT_PARAM
(
   cgp_inst_code      NUMBER (10) NOT NULL,
   cgp_group_code     VARCHAR2 (10) NOT NULL,
   cgp_limit_prfl     VARCHAR2 (10)  NULL,
   CgP_DLVR_CHNL      VARCHAR2 (2) NOT NULL,
   cgp_tran_code      VARCHAR2 (2) NOT NULL,
   CgP_INTL_FLAG      VARCHAR2 (2) NOT NULL,
   CgP_PNSIGN_FLAG    VARCHAR2 (2) NOT NULL,
   CgP_MCC_CODE       VARCHAR2 (4) NOT NULL,
   CgP_TRFR_CRDACNT   VARCHAR2 (2) NOT NULL,
   CGP_GRPCOMB_HASH   VARCHAR2 (90) NOT NULL,
   cgp_lupd_date      DATE NULL,
   cgp_lupd_user      NUMBER (10) NULL,
   cgp_ins_date       DATE NOT NULL,
   cgp_ins_user       NUMBER (10) NOT NULL
)tablespace cms_mast;

ALTER TABLE VMSCMS.CMS_GRPLMT_PARAM ADD   CONSTRAINT PK_CMS_GRPLMT_PARAM
 PRIMARY KEY (cgp_inst_code, CGP_GRPCOMB_HASH );

 ALTER TABLE VMSCMS.CMS_GRPLMT_PARAM  ADD CONSTRAINT FK_CMS_GRPLMT_PARAM
FOREIGN KEY (cgp_inst_code, cgp_group_code)
REFERENCES VMSCMS.CMS_GRPLMT_MAST(cgm_inst_code,cgm_limitgl_code);

