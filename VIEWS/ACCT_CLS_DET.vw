/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.acct_cls_det (pan_code,
                                                  acct_no,
                                                  process_date
                                                 )
AS
   SELECT a.cps_pan_code, c.cam_acct_no, a.cps_ins_date
     FROM cms_pan_spprt a,
          cms_pan_acct_hist b,
          cms_acct_mast c,
          temp_acct_open e
    WHERE e.acct_no = c.cam_acct_no
      AND b.cpa_acct_id = c.cam_acct_id
      AND b.cpa_pan_code = a.cps_pan_code
      AND a.cps_spprt_key = 'ACCCL1';


