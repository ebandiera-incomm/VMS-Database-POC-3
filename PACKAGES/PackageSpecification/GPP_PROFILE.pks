create or replace PACKAGE        VMSCMS.GPP_PROFILE AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin
  -- Created : 10/8/2015 3:50:02 PM
  -- Purpose :

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations
  --PROCEDURE get_phone_details();
  PROCEDURE unlock_account(p_customer_id_in IN VARCHAR2,
                           p_comment_in     IN VARCHAR2,
                           p_status_out     OUT VARCHAR2,
                           p_err_msg_out    OUT VARCHAR2);
  PROCEDURE update_profile(
                           --name
                           p_action_in            IN VARCHAR2,
                           p_customer_id_in       IN VARCHAR2,
                           p_firstname_in         IN VARCHAR2,
                           p_middlename_in        IN VARCHAR2,
                           p_lastname_in          IN VARCHAR2,
                           p_mothermaiden_name_in IN VARCHAR2,
                           p_dateofbirth_in       IN VARCHAR2,
                           --identification
                           p_id_type_in         IN VARCHAR2,
                           p_number_in          IN VARCHAR2,
                           p_issuedby_in        IN VARCHAR2,
                           p_issuance_date_in   IN VARCHAR2,
                           p_expiration_date_in IN VARCHAR2,
                           --phone
                           p_landline_in IN VARCHAR2,
                           p_mobile_in   IN VARCHAR2,
                           p_email_in    IN VARCHAR2,
                           --address
                           p_physical_address_in IN VARCHAR2,
                           p_mailing_address_in  IN VARCHAR2,
                           --common
                           p_reason_in   IN VARCHAR2,
                           p_comment_in  IN VARCHAR2,
                           p_status_out  OUT VARCHAR2,
                           p_err_msg_out OUT VARCHAR2,
						               p_optinflag_out OUT VARCHAR2);

  PROCEDURE unlock_accttoken_provisioning(p_customer_id_in IN VARCHAR2,
                                          p_comment_in     IN VARCHAR2,
                                          p_status_out     OUT VARCHAR2,
                                          p_err_msg_out    OUT VARCHAR2);

  PROCEDURE enable_fraud_override(p_customer_id_in IN VARCHAR2,
                                  p_comment_in     IN VARCHAR2,
                                  p_status_out     OUT VARCHAR2,
                                  p_err_msg_out    OUT VARCHAR2);

  PROCEDURE enable_fraud_override(p_customer_id_in IN VARCHAR2,
                                  p_comment_in     IN VARCHAR2,
                                  p_action_in      IN VARCHAR2,
                                  p_status_out     OUT VARCHAR2,
                                  p_err_msg_out    OUT VARCHAR2);
								  
  PROCEDURE  get_customer_alerttypes(p_customer_id_in       IN  VARCHAR2,
                                     p_status_out           OUT VARCHAR2,
                                     p_err_msg_out          OUT VARCHAR2,
                                     p_alert_type_out       OUT VARCHAR2);	

  PROCEDURE get_customer_alertlog(p_customer_id_in       IN  VARCHAR2,
                                  p_start_date_in        IN  VARCHAR2,
                                  p_end_date_in          IN  VARCHAR2,
                                  p_alert_mode_in        IN  VARCHAR2, 
                                  p_alert_type_in        IN  VARCHAR2,
                                  p_recordsperpage_in    IN  VARCHAR2,
                                  p_pagenumber_in        IN  VARCHAR2,
                                  p_status_out           OUT VARCHAR2,
                                  p_err_msg_out          OUT VARCHAR2,
                                  c_alert_log_out        OUT SYS_REFCURSOR);									
 
END gpp_profile;
/
SHOW ERROR;