CREATE TABLE vmscms.vms_grplmt_param_stag
(
  vgp_inst_code     number(10)                  not null,
  vgp_group_code    varchar2(10 byte)           not null,
  vgp_limit_prfl    varchar2(10 byte),
  vgp_dlvr_chnl     varchar2(2 byte)            not null,
  vgp_tran_code     varchar2(2 byte)            not null,
  vgp_intl_flag     varchar2(2 byte)            not null,
  vgp_pnsign_flag   varchar2(2 byte)            not null,
  vgp_mcc_code      varchar2(4 byte)            not null,
  vgp_trfr_crdacnt  varchar2(2 byte)            not null,
  vgp_payment_type  varchar2(4 byte)            not null
);