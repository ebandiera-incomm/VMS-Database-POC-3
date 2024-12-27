CREATE INDEX vmscms.indx_last4digit_pan
   ON vmscms.cms_appl_pan (SUBSTR (CAP_MASK_PAN, LENGTH (CAP_MASK_PAN) - 3))
   TABLESPACE CMS_BIG_IDX
   ONLINE;