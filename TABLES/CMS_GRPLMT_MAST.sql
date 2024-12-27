CREATE TABLE VMSCMS.CMS_GRPLMT_MAST
(
   cgm_inst_code      NUMBER (10) NOT NULL,
   cgm_limitgl_code   VARCHAR2 (10) NOT NULL,
   cgm_limitgl_name   VARCHAR2 (50) NOT NULL,
   cgm_ins_date       DATE NOT NULL,
   cgm_ins_user       NUMBER (10) NOT NULL
)tablespace cms_mast;


ALTER TABLE VMSCMS.CMS_GRPLMT_MAST ADD   CONSTRAINT PK_CMS_GRPLMT_MAST
 PRIMARY KEY (cgm_inst_code, cgm_limitgl_code );

 ALTER TABLE  VMSCMS.CMS_GRPLMT_MAST  ADD   CONSTRAINT UK_CMS_GRPLMT_MAST
 UNIQUE  (cgm_limitgl_name );

