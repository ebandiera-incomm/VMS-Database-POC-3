CREATE TABLE vmscms.vms_line_item_dtl
(
   vli_pan_code         VARCHAR2 (100),
   vli_order_id         VARCHAR2 (50),
   Vli_PARTNER_ID       VARCHAR2 (50),
   vli_lineitem_id       VARCHAR2 (100),
   vli_pin              VARCHAR2 (10),
   VLI_PROXY_PIN_ENCR   raw (500),
   vli_proxy_pin_hash  VARCHAR2(1000),
   vli_tracking_no      VARCHAR2(50),
   vli_shipping_datetime   DATE,
   CONSTRAINT pk_line_item_dtl  PRIMARY KEY  (vli_order_id, vli_partner_id,vli_lineitem_id,vli_pan_code)
);

CREATE INDEX vmscms.indx_proxy_pin_hash
  ON vmscms.vms_line_item_dtl (vli_proxy_pin_hash);

UPDATE vmscms.vms_line_item_dtl
   SET vli_proxy_pin_hash = vmscms.gethash (vli_proxy_pin_encr);
   
