CREATE TABLE vmscms.vms_pangen_summary
(
   vps_prod_code        VARCHAR2 (6) NOT NULL,
   vps_card_type        NUMBER (2) NOT NULL,
   vps_subbin_from      VARCHAR2 (20) NOT NULL,
   vps_subbin_to        VARCHAR2 (20) NOT NULL,
   vps_start_range      VARCHAR2 (20) NOT NULL,
   vps_end_range        VARCHAR2 (20) NOT NULL,
   vps_total_cards      NUMBER (20) NOT NULL,
   vps_pending_cards    NUMBER (20),
   vps_process_status   VARCHAR2 (10),
   vps_process_msg      VARCHAR2 (1000),
   vps_avail_cards      NUMBER(20)
);

 CREATE INDEX vmscms.indx_pangen_summ
   ON vms_pangen_summary (vps_prod_code, vps_card_type);
