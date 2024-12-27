/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.prepaid_prodcattype_info (cpc_inst_code,
                                                              cpc_prod_code,
                                                              cpc_card_type,
                                                              cpc_cardtype_desc,
                                                              cpc_ins_user,
                                                              cpc_ins_date,
                                                              cpc_lupd_user,
                                                              cpc_lupd_date,
                                                              cpc_vendor,
                                                              cpc_stock,
                                                              cpc_cardtype_sname,
                                                              cpc_prod_prefix,
                                                              cpc_rulegroup_code
                                                             )
AS
   SELECT "CPC_INST_CODE", "CPC_PROD_CODE", "CPC_CARD_TYPE",
          "CPC_CARDTYPE_DESC", "CPC_INS_USER", "CPC_INS_DATE",
          "CPC_LUPD_USER", "CPC_LUPD_DATE", "CPC_VENDOR", "CPC_STOCK",
          "CPC_CARDTYPE_SNAME", "CPC_PROD_PREFIX", "CPC_RULEGROUP_CODE"
     FROM cms_prod_cattype;


