CREATE TABLE vmscms.vms_autoreplacement_prod
(
   vap_prod_code     VARCHAR2 (20),
   vap_repl_period    NUMBER (5),
   vap_ins_date      DATE DEFAULT SYSDATE,
   CONSTRAINT pk_autoreplacement_prod PRIMARY KEY (vap_prod_code)
);