create or replace
PACKAGE vmscms.VMSRULE_EXECUTIONS
AS

   -- Author  : DHIANKARAN B
   -- Created : 18/05/2017
   -- Purpose : VMS TOKEN PROVISIONING RULE CHECK 
   -- Reviewer:  
   -- Build No:  
PROCEDURE ADDRESS_VERIFICATION_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in IN VARCHAR2,
    P_inst_code_IN        IN VARCHAR2,
    P_card_number_IN      IN VARCHAR2,
    P_ZIP_CODE_in         IN VARCHAR2,
    P_ADDRVERIFY_FLAG_in  IN VARCHAR2,
    P_cust_addr           IN VARCHAR2 DEFAULT NULL,
    p_msg_rsncde_in IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2);
PROCEDURE CHARGEBACK_COUNT_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    P_count_identifier_IN IN VARCHAR2,
    P_chargeback_period_IN IN VARCHAR2,
    p_operator_in IN VARCHAR2,
    P_inst_code_IN        IN VARCHAR2,
    P_card_number_IN      IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2);
PROCEDURE DEVICEID_COUNT_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in IN VARCHAR2,
    P_count_identifier_IN IN VARCHAR2,
    P_inst_code_IN        IN VARCHAR2,
    P_card_number_IN      IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2);
PROCEDURE WALLETIDENTIFIER_COUNT_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in IN VARCHAR2,
    p_interchange_name_in IN VARCHAR2,
    P_inst_code_IN         IN VARCHAR2,
    P_card_number_IN       IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_resp_stat_out OUT VARCHAR2);
PROCEDURE LASTACTIVE_PERIOD_RULE(
    p_left_term_in        IN VARCHAR2,
    p_right_term_in       IN VARCHAR2,
    p_operator_in  IN VARCHAR2,
    P_inst_code_IN   IN VARCHAR2,
    P_card_number_IN IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    P_RESP_STAT_OUT OUT VARCHAR2);
PROCEDURE AMEX_RAN_MATCH(
    p_program_id_in  IN VARCHAR2,
    p_merchant_id_in IN VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    p_result_out OUT VARCHAR2,
	p_ran_matched_merchant_id_out  OUT VARCHAR2);
PROCEDURE MERCHANT_RULE(
    p_merchant_id_in  IN VARCHAR2,
    p_merchant_name_in IN VARCHAR2,
    p_prod_code_in IN VARCHAR2,  -- added for vms-6337 on 14-Sep-2022 By Bhavani 
	p_prod_catg_in IN NUMBER,  -- added for vms-6337 on 14-Sep-2022 By Bhavani 
    p_resp_msg_out OUT VARCHAR2,
    p_result_out OUT VARCHAR2,
    p_rule_id_out OUT VARCHAR2,
    p_rule_name_out OUT VARCHAR2);
END;
/
show error