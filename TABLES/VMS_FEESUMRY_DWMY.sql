CREATE TABLE vmscms.vms_feesumry_dwmy
(
   vfd_acct_no       VARCHAR2 (20),
   vfd_fee_code      NUMBER(4),
   vfd_daly_cnt      NUMBER (20) NOT NULL,
   vfd_wkly_cnt      NUMBER (20) NOT NULL,
   vfd_biwkly_cnt    NUMBER (20) NOT NULL,
   vfd_mntly_cnt     NUMBER (20) NOT NULL,
   vfd_bimntly_cnt   NUMBER (20) NOT NULL,
   vfd_yerly_cnt     NUMBER (20) NOT NULL,
   vfd_lupd_date     DATE NOT NULL,
   vfd_ins_date      DATE NOT NULL,
   CONSTRAINT pk_feesumry_dwmy PRIMARY KEY (vfd_acct_no,vfd_fee_code)
);