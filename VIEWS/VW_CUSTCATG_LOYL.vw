/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.vw_custcatg_loyl (cpl_inst_code,
                                                      vcl_cust_catg,
                                                      vcl_catg_desc,
                                                      vcl_loyl_code,
                                                      vcl_loyl_desc,
                                                      vcl_trans_amt,
                                                      vcl_loyl_point,
                                                      vcl_valid_from,
                                                      vcl_valid_to,
                                                      cum_user_name
                                                     )
AS
   SELECT DISTINCT a.cpl_inst_code, a.cpl_cust_catg vcl_cust_catg,
                   b.ccc_catg_desc vcl_catg_desc,
                   a.cpl_loyl_code vcl_loyl_code,
                   c.clm_loyl_desc vcl_loyl_desc,
                   d.ccl_trans_amt vcl_trans_amt,
                   d.ccl_loyl_point vcl_loyl_point,
                   a.cpl_valid_from vcl_valid_from,
                   a.cpl_valid_to vcl_valid_to, e.cum_user_name
              FROM cms_prodccc_loyl a,
                   cms_cust_catg b,
                   cms_loyl_mast c,
                   cms_custcatg_loyl d,
                   cms_user_mast e
             WHERE a.cpl_inst_code = b.ccc_inst_code
               AND a.cpl_cust_catg = b.ccc_catg_code
               AND a.cpl_inst_code = c.clm_inst_code
               AND a.cpl_loyl_code = c.clm_loyl_code
               AND a.cpl_inst_code = d.ccl_inst_code
               AND a.cpl_loyl_code = d.ccl_loyl_code
               AND c.clm_inst_code = e.cum_inst_code
               AND c.clm_ins_user = e.cum_user_pin
               AND a.cpl_loyl_code IN (
                                 SELECT clm_loyl_code
                                   FROM cms_loyl_mast
                                  WHERE clm_inst_code = 1
                                        AND clm_loyl_catg = 4);


