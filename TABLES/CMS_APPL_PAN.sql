drop index vmscms.indx_last4digit_pan;
ALTER TABLE vmscms.CMS_APPL_PAN MODIFY CAP_MASK_PAN VARCHAR2(50);

CREATE INDEX vmscms.indx_last4digit_pan
   ON vmscms.cms_appl_pan (SUBSTR (CAP_MASK_PAN, LENGTH (CAP_MASK_PAN) - 3)) online ;