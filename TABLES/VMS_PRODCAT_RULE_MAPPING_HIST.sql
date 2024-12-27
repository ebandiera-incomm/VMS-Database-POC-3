CREATE TABLE vmscms.VMS_PRODCAT_RULE_MAPPING_HIST
    (
      VPH_PROD_CODE     VARCHAR2(4),
      VPH_MAPPING_LEVEL VARCHAR2(2) ,
      VPH_PROD_CATTYPE  NUMBER(3),
      VPH_RULE_ID       NUMBER(9),
      VPH_PRIORITY      NUMBER(2),
	  vph_rule_set_id  number(9,0),
      vph_ins_user NUMBER(5) NOT NULL,
      vph_ins_date DATE NOT NULL,
      vph_lupd_user NUMBER(5),
      vph_lupd_date date
    );