CREATE TABLE vmscms.VMS_PRODCAT_RULE_MAPPING
    (
      VPR_PROD_CODE     VARCHAR2(4),
      VPR_MAPPING_LEVEL VARCHAR2(2) ,
      VPR_PROD_CATTYPE  NUMBER(3),
      VPR_RULE_ID       NUMBER(9),
      VPR_PRIORITY      NUMBER(2),
      vpr_ins_user NUMBER(5) NOT NULL,
      vpr_ins_date DATE NOT NULL,
      vpr_lupd_user NUMBER(5),
      vpr_lupd_date date,
      CONSTRAINT pk_prod_rule_id PRIMARY KEY(VPR_PROD_CODE, VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,VPR_RULE_ID),
      CONSTRAINT check_mapping_level CHECK( VPR_MAPPING_LEVEL IN ('P','PC'))
    );
	
create index ind_prod_cattype on VMSCMS.VMS_PRODCAT_RULE_MAPPING(VPR_PROD_CODE, VPR_PROD_CATTYPE);


