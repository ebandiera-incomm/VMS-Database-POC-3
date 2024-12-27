CREATE TABLE vmscms.cms_jhprod_mast
(
cjm_inst_code NUMBER(3) ,
cjm_prod_code VARCHAR(6),
cjm_ins_date DATE,
cjm_ins_user NUMBER(10),
CONSTRAINT "UK_JHPRODMAST_PRODCODE" UNIQUE ("CJM_PROD_CODE")
) TABLESPACE CMS_SML_TXN;

INSERT INTO vmscms.cms_jhprod_mast
            (cjm_inst_code, cjm_prod_code, cjm_ins_date, cjm_ins_user)
     VALUES (1, 'VP75', SYSDATE, 1);