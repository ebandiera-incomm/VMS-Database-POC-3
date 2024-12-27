CREATE TABLE vmscms.vms_shfl_serl_inv
(
   vss_inst_code     NUMBER (10) NOT NULL,
   vss_prod_code     VARCHAR2 (6) NOT NULL,
   vss_prod_catg     NUMBER (2) NOT NULL,
   vss_prod_prefix   VARCHAR2 (20) NOT NULL,
   vss_shfl_cntrl    NUMBER (9) NOT NULL,
   vss_serl_numb     NUMBER (9) NOT NULL,
   vss_serl_flag     NUMBER (1) DEFAULT 0,
   vss_lupd_date     DATE,
   vss_lupd_user     NUMBER (10),
   vss_ins_date      DATE,
   vss_ins_user      NUMBER (10)
);


CREATE INDEX vmscms.indx_shfl_serl
   ON vmscms.vms_shfl_serl_inv (vss_inst_code,
                                vss_prod_code,
                                vss_prod_catg,
                                vss_prod_prefix,
                                vss_shfl_cntrl,
                                vss_serl_flag);