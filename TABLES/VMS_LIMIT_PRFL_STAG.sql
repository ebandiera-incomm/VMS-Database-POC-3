CREATE TABLE vmscms.vms_limit_prfl_stag
(
   vlp_inst_code        NUMBER (10) NOT NULL,
   vlp_lmtprfl_id       VARCHAR2 (10) NOT NULL,
   vlp_dlvr_chnl        VARCHAR2 (2) NOT NULL,
   vlp_tran_code        VARCHAR2 (2) NOT NULL,
   vlp_tran_type        VARCHAR2 (1) NOT NULL,
   vlp_intl_flag        VARCHAR2 (2) NOT NULL,
   vlp_pnsign_flag      VARCHAR2 (2) NOT NULL,
   vlp_mcc_code         VARCHAR2 (4) NOT NULL,
   vlp_trfr_crdacnt     VARCHAR2 (2) NOT NULL,
   vlp_pertxn_minamnt   NUMBER (20) NOT NULL,
   vlp_pertxn_maxamnt   NUMBER (20) NOT NULL,
   vlp_dmax_txncnt      NUMBER (20),
   vlp_dmax_txnamnt     NUMBER (20),
   vlp_wmax_txncnt      NUMBER (20),
   vlp_wmax_txnamnt     NUMBER (20),
   vlp_mmax_txncnt      NUMBER (20),
   vlp_mmax_txnamnt     NUMBER (20),
   vlp_ymax_txncnt      NUMBER (20),
   vlp_ymax_txnamnt     NUMBER (20),
   vlp_payment_type     VARCHAR2 (4) NOT NULL
);