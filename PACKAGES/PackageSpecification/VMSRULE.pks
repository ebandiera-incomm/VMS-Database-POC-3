create or replace
PACKAGE VMSCMS.VMSRULE
AS
    PROCEDURE INSERT_RULE(p_rule_id_in in number,
                          P_RULE_NAME_IN IN VARCHAR2,
                          P_RULE_EXP_IN IN VARCHAR2,
                          P_TRANS_TYPE_IN IN VARCHAR2,
                          P_ACTION_TYPE_IN IN VARCHAR2,
                          p_json_req_in in clob,
                          P_RULE_DETAIL_IN IN RULE_TYPE_TAB,
                          p_user_in in number,
                          p_resp_msg_out out varchar2);
   PROCEDURE insert_rule_set(p_rule_set_id_in IN NUMBER,
                             P_RULE_SET_NAME_IN in varchar2,
                             p_added_rule_ids_in IN VARCHAR2,
                             P_DELETE_RULE_IDS_IN in varchar2,
                             P_USER_IN in number,
                             p_resp_msg_out out VARCHAR2);
  PROCEDURE attach_detach_rule(p_attach_detach_type_in in varchar2,
                        p_prod_code_in IN cms_prod_mast.cpm_prod_code%TYPE,
                        p_prod_category_in IN CMS_PROD_CATTYPE.cpc_card_type%TYPE,
                        p_mapping_level_in in varchar2,
                        p_rule_set_id_in in number,
                        p_rule_details_in IN rule_set_type_tab,
                        P_USER_IN IN NUMBER,
                        p_resp_msg_out out VARCHAR2); 
   PROCEDURE VIEW_ATTACHRULESET(TAB_RULE_SET_OUT OUT TAB_RULE_SET,
                                p_resp_msg_out out varchar2);
   PROCEDURE di_ran_match(p_program_id_in in varchar2,
                          p_merchant_id_in in varchar2,
                          p_resp_msg_out out varchar2,
                          p_result_out out varchar2);
  PROCEDURE VIEW_GLOBALRULESET(TAB_RULE_SET_OUT OUT GLOBAL_TAB_RULE_SET,
                                 p_resp_msg_out out VARCHAR2);  
END;
/
SHOW ERROR