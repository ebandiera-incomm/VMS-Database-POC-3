CREATE TABLE vmscms.cms_mrlimitbreach_merchantname
(
  cpt_inst_code      NUMBER(5)                  NOT NULL,
  cmm_merchant_name  VARCHAR2(50 BYTE),
  cmm_lupd_date      DATE                       NOT NULL,
  cmm_ins_date       DATE                       NOT NULL,
   PRIMARY KEY (cpt_inst_code, cmm_merchant_name)
) tablespace cms_mast;
 