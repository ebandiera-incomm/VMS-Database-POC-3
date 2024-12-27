CREATE TABLE vmscms.VMS_REDEMPTION_DELAY_CONFIG
(
   vrd_prod_code               VARCHAR2 (20) NOT NULL,
   vrd_prodcat_code            NUMBER (5) NOT NULL,
   vrd_merchant_id             VARCHAR2 (50) NOT NULL,
   vrd_start_time_display      VARCHAR2 (50) NOT NULL,
   vrd_end_time_display        VARCHAR2 (50) NOT NULL,
   vrd_redemption_delay_time   NUMBER (5) NOT NULL,
   vrd_ins_user                NUMBER (5) NOT NULL,
   vrd_ins_date                DATE NOT NULL,
   vrd_lupd_user               NUMBER (5) NOT NULL,
   VRD_LUPD_DATE               DATE NOT NULL
);

CREATE UNIQUE INDEX vmscms.indx_redemption_delay_config
   ON vmscms.vms_redemption_delay_config (vrd_prod_code,
                                   vrd_prodcat_code,
                                   vrd_merchant_id,
                                   VRD_START_TIME_DISPLAY,
                                   vrd_end_time_display);  