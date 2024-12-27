CREATE TABLE vmscms.cms_appl_pan_inv
(
   cap_appl_code       NUMBER (14),
   cap_prod_code       VARCHAR2 (6 BYTE) NOT NULL,
   cap_prod_catg       VARCHAR2 (2 BYTE) NOT NULL,
   cap_card_type       NUMBER (2) NOT NULL,
   cap_cust_catg       NUMBER (5),
   cap_pan_code        VARCHAR2 (90 BYTE) NOT NULL,
   cap_cust_code       NUMBER (10)NOT NULL,
   cap_acct_id         NUMBER (10) NOT NULL,
   cap_acct_no         VARCHAR2 (20 BYTE),
   cap_bill_addr       NUMBER (10) NOT NULL,
   cap_appl_bran       VARCHAR2(6 BYTE)NOT NULL,  
   cap_ins_user        NUMBER (5) NOT NULL,
   cap_ins_date        DATE NOT NULL,
   cap_pan_code_encr   RAW (100)NOT NULL,
   cap_mask_pan        VARCHAR2 (21 BYTE)NOT NULL,
   cap_prod_prefix     VARCHAR2 (20 BYTE)NOT NULL,
   cap_card_seq        NUMBER (28),
   cap_issue_stat      VARCHAR2 (1 BYTE)
);

CREATE INDEX vmscms.indx_prodcatg_inv
   ON vmscms.cms_appl_pan_inv (cap_prod_code, cap_card_type);
   
ALTER TABLE vmscms.cms_appl_pan_inv ADD (
  CONSTRAINT pk_appl_pan_inv
  PRIMARY KEY
  (cap_pan_code));