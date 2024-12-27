CREATE TABLE VMSCMS.CMS_GROUP_LIMIT_HIST
(
   cgl_inst_code        NUMBER (10),
   cgl_LMTPRFL_ID       VARCHAR2 (10),
   cgl_group_code       VARCHAR2 (10),
   Cgl_GRPLMT_HASH      VARCHAR2 (90),
   Cgl_PERTXN_MINAMNT   NUMBER (20),
   Cgl_PERTXN_MAXAMNT   NUMBER (20),
   Cgl_DMAX_TXNCNT      NUMBER (20),
   Cgl_DMAX_TXNAMNT     NUMBER (20),
   Cgl_WMAX_TXNCNT      NUMBER (20),
   Cgl_WMAX_TXNAMNT     NUMBER (20),
   Cgl_MMAX_TXNCNT      NUMBER (20),
   Cgl_MMAX_TXNAMNT     NUMBER (20),
   Cgl_YMAX_TXNCNT      NUMBER (20),
   Cgl_YMAX_TXNAMNT     NUMBER (20),
   cgl_lupd_date        DATE,
   cgl_lupd_user        NUMBER (10),
   cgl_orgins_date      DATE,
   cgl_orgins_user      NUMBER (10),
   cgl_ins_date         DATE
)tablespace cms_hist;