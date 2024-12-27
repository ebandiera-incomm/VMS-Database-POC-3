CREATE TABLE vmscms.vms_product_serial_cntrl
(
   vps_product_id   VARCHAR2 (20),
   vps_start_serl   NUMBER (10),
   vps_end_serl     NUMBER (10),
   vps_serl_numb    NUMBER (10),
   CONSTRAINT pk_product_serial_cntrl PRIMARY KEY (vps_product_id)
)
/