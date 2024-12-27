CREATE TABLE vmscms.vms_pan_ctrl_inv
(
   vpc_inst_code     NUMBER (3),
   vpc_prod_code     VARCHAR2 (6) NOT NULL,
   vpc_prod_catg     NUMBER (2) NOT NULL,
   vpc_prod_prefix   VARCHAR2 (20) NOT NULL,
   vpc_ctrl_numb     VARCHAR2 (10),
   vpc_min_serlno    NUMBER (12),
   vpc_max_serlno    NUMBER (12),
   vpc_ins_date      DATE,
   vpc_ins_user      NUMBER (10)
);

ALTER TABLE vmscms.vms_pan_ctrl_inv ADD (
  CONSTRAINT pk_pan_ctrl_inv
  PRIMARY KEY
  (vpc_inst_code, vpc_prod_code, vpc_prod_catg, vpc_prod_prefix));