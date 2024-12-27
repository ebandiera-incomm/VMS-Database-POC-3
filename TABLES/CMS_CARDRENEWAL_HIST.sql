CREATE TABLE vmscms.cms_cardrenewal_hist
(
cch_pan_code VARCHAR2(90) NOT NULL,
cch_card_stat VARCHAR2(2)NOT NULL,
cch_renewal_date  DATE NOT NULL,
cch_expry_date  DATE NOT NULL,
cch_inst_code  NUMBER(3) NOT NULL,
cch_ins_user  NUMBER(5) NOT NULL,
cch_ins_date DATE NOT NULL,
CONSTRAINT fk_crdrenew_instmast FOREIGN KEY (cch_inst_code) REFERENCES vmscms.cms_inst_mast (cim_inst_code),
CONSTRAINT fk_crdrenew_usermast FOREIGN KEY (cch_ins_user) REFERENCES vmscms.cms_user_mast (cum_user_pin)
) TABLESPACE cms_big_txn;