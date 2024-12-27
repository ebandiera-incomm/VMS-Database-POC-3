  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_RULES" AS

  PROCEDURE create_rule
   (
      p_rulename_in           IN VARCHAR2,
      p_ruletype_in           IN VARCHAR2,
      p_id_in                 IN VARCHAR2,
      p_name_in               IN VARCHAR2,
      p_reason_in             IN VARCHAR2,
      p_description_in        IN VARCHAR2,      
      p_status_out            OUT VARCHAR2,
      p_err_msg_out           OUT VARCHAR2,
      c_ruleinfo_out          OUT SYS_REFCURSOR,
      c_relatedrules_out      OUT SYS_REFCURSOR
   );

   

   PROCEDURE update_merchant_rule
   (
      p_ruleid_in             IN VARCHAR2,
      p_action_in             IN VARCHAR2,
      p_status_out            OUT VARCHAR2,
      p_err_msg_out           OUT VARCHAR2
   );

   PROCEDURE get_rule
   (
      p_ruleid_in   	    IN VARCHAR2,
      p_status_in   	    IN VARCHAR2,
      p_status_out  	    OUT VARCHAR2,
      p_err_msg_out 	    OUT VARCHAR2,
      c_rules_out    	    OUT SYS_REFCURSOR,
      c_relatedrules_out    OUT SYS_REFCURSOR
   );
   
   PROCEDURE get_fraud_rule
   (
    p_customer_id_in   IN  VARCHAR2,	
    p_token_value_in   IN  VARCHAR2,
    p_status_out       OUT VARCHAR2,
    p_err_msg_out      OUT VARCHAR2,
    c_fraud_rule_out   OUT SYS_REFCURSOR
	);
    
    

END GPP_RULES;
/
show error