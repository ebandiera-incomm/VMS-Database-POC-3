CREATE TABLE vmscms.VMS_DELAYED_LOAD
(
   vdl_acct_no            VARCHAR2 (50) NOT NULL,
   vdl_delivery_channel   VARCHAR2 (20) NOT NULL,
   vdl_txn_code           VARCHAR2 (20) NOT NULL,
   vdl_rrn                VARCHAR2 (50) NOT NULL,
   vdl_tran_amt           NUMBER (20, 3) NOT NULL,
   vdl_expiry_date        DATE NOT NULL,
   VDL_INS_DATE           DATE NOT NULL   
);

CREATE UNIQUE INDEX VMSCMS.INDX_DELAYED_LOAD
   ON vmscms.vms_delayed_load (vdl_acct_no, vdl_expiry_date); 