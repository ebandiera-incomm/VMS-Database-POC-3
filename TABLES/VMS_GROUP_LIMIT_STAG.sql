CREATE TABLE vmscms.vms_group_limit_stag
(
   vgl_inst_code        NUMBER (10) NOT NULL,
   vgl_lmtprfl_id       VARCHAR2 (10) NOT NULL,
   vgl_group_code       VARCHAR2 (10) NOT NULL,
   vgl_group_name     VARCHAR2(50)  NOT NULL,
   vgl_pertxn_minamnt   NUMBER (20) NOT NULL,
   vgl_pertxn_maxamnt   NUMBER (20) NOT NULL,
   vgl_dmax_txncnt      NUMBER (20),
   vgl_dmax_txnamnt     NUMBER (20),
   vgl_wmax_txncnt      NUMBER (20),
   vgl_wmax_txnamnt     NUMBER (20),
   vgl_mmax_txncnt      NUMBER (20),
   vgl_mmax_txnamnt     NUMBER (20),
   vgl_ymax_txncnt      NUMBER (20),
   vgl_ymax_txnamnt     NUMBER (20)
);