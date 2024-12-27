/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.prepaid_prod_info (cpm_inst_code,
                                                       cpm_prod_code,
                                                       cpm_asso_code,
                                                       cpm_inst_type,
                                                       cpm_interchange_code,
                                                       cpm_catg_code,
                                                       cpm_prod_desc,
                                                       cpm_switch_prod,
                                                       cpm_from_date,
                                                       cpm_to_date,
                                                       cpm_ins_user,
                                                       cpm_ins_date,
                                                       cpm_lupd_user,
                                                       cpm_lupd_date,
                                                       cpm_validity_period,
                                                       cpm_var_flag,
                                                       cpm_rulegroup_code
                                                      )
AS
   SELECT "CPM_INST_CODE", "CPM_PROD_CODE", "CPM_ASSO_CODE", "CPM_INST_TYPE",
          "CPM_INTERCHANGE_CODE", "CPM_CATG_CODE", "CPM_PROD_DESC",
          "CPM_SWITCH_PROD", "CPM_FROM_DATE", "CPM_TO_DATE", "CPM_INS_USER",
          "CPM_INS_DATE", "CPM_LUPD_USER", "CPM_LUPD_DATE",
          "CPM_VALIDITY_PERIOD", "CPM_VAR_FLAG", "CPM_RULEGROUP_CODE"
     FROM cms_prod_mast;


