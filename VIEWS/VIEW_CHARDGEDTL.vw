/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.view_chardgedtl (ccd_pan_code,
                                                     ccd_acct_no)
AS
   SELECT ccd_pan_code, ccd_acct_no
     FROM cms_charge_dtl;


