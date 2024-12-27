  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_CARDS" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin Beura
  -- Created : 09/11/2015 10:49:15 AM
  -- Purpose : To update card status

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations

  PROCEDURE get_cvvplus_info(p_customer_id_in               IN VARCHAR2,
                             p_cvvplus_token_out            OUT vmscms.vms_cvvplus_info.vci_cvvplus_token%TYPE,
                             p_cvvplus_accountid_out        OUT vmscms.vms_cvvplus_info.vci_cvvplus_accountid%TYPE,
                             p_cvvplus_registration_id_out  OUT vmscms.vms_cvvplus_info.vci_cvvplus_registration_id%TYPE,
                             p_cvvplus_email_contactid_out  OUT vmscms.vms_cvvplus_info.vci_cvvplus_email_contactid%TYPE,
                             p_cvvplus_mobile_contactid_out OUT vmscms.vms_cvvplus_info.vci_cvvplus_mobile_contactid%TYPE,
                             p_cvvplus_codeprofile_id_out   OUT vmscms.vms_cvvplus_info.vci_cvvplus_codeprofile_id%TYPE,
                             p_status_out                   OUT VARCHAR2,
                             p_err_msg_out                  OUT VARCHAR2);
  -- update card status

  PROCEDURE update_card_status(p_customer_id_in IN VARCHAR2,
                               p_type_in        IN VARCHAR2,
                               p_value_in       IN VARCHAR2,
                               p_pan_in         IN VARCHAR2,
                               p_postalcode_in  IN VARCHAR2,
                               p_eff_date_in    IN VARCHAR2,
                               p_comment_in     IN VARCHAR2,
							   --CFIP-416 starts
                               p_istoken_eligible_out   OUT VARCHAR2,
                               p_iscvvplus_eligible_out OUT VARCHAR2,
                               p_cardno_out             OUT VARCHAR2,
                               p_exprydate_out          OUT VARCHAR2,
                               p_token_dtls_out         OUT SYS_REFCURSOR,
                               --CFIP-416 ends
                               p_status_out  OUT VARCHAR2,
                               p_err_msg_out OUT VARCHAR2,
							   p_reason_code_in IN VARCHAR2 default null);

  -- Replace card
  PROCEDURE replace_card(p_customer_id_in IN VARCHAR2,
                         p_isexpedited_in IN VARCHAR2,
                         p_isfeewaived_in IN VARCHAR2,
                         p_comment_in     IN VARCHAR2,
                         --Sn:Added for VMS-104
                         p_createnewcard_in IN VARCHAR2 DEFAULT 'FALSE',
                         --En:Added for VMS-104
                         --CFIP starts
                         p_loadamounttype_in   IN VARCHAR2,
                         p_loadamount_in          IN VARCHAR2,
                         p_merchantid_in          IN VARCHAR2,
                         p_terminalid_in          IN VARCHAR2,
						             p_locationid_in          IN VARCHAR2,
                         p_merchantbillable_in    IN VARCHAR2,
                         p_activationcode_in      IN VARCHAR2,
                         p_firstname_in           IN VARCHAR2,
                         p_middlename_in          IN VARCHAR2,
                         p_lastname_in            IN VARCHAR2,
                         p_addrone_in             IN VARCHAR2,
                         p_addrtwo_in             IN VARCHAR2,
                         p_city_in                IN VARCHAR2,
                         p_state_in               IN VARCHAR2,
                         p_postalcode_in          IN VARCHAR2,
                         p_countrycode_in         IN VARCHAR2,
                         p_email_in 		      IN VARCHAR2,
                         p_istoken_eligible_out   OUT VARCHAR2,
                         p_iscvvplus_eligible_out OUT VARCHAR2,
                         p_cardno_out             OUT VARCHAR2,
                         p_exprydate_out          OUT VARCHAR2,
                         p_new_cardno_out         OUT VARCHAR2,
                         p_new_exprydate_out      OUT VARCHAR2,
                         p_stan_out               OUT VARCHAR2,
                         p_rrn_out                OUT VARCHAR2,
                         p_activationcode_out     OUT VARCHAR2,
                         p_req_reason_out         OUT VARCHAR2,
                         p_forward_instcode_out   OUT VARCHAR2,
                         p_message_reasoncode_out OUT VARCHAR2,
                         p_new_maskcardno_out     OUT VARCHAR2,
                         p_token_dtls_out         OUT SYS_REFCURSOR,
                         p_status_out             OUT VARCHAR2,
                         p_err_msg_out            OUT VARCHAR2);

  PROCEDURE release_preauth(p_customer_id_in   IN VARCHAR2,
                            p_tran_id_in       IN VARCHAR2,
                            p_tran_date_in     IN VARCHAR2,
                            p_delv_chnl_in     IN VARCHAR2,
                            p_tran_code_in     IN VARCHAR2,
                            p_response_code_in IN VARCHAR2,
                            p_reason_in        IN VARCHAR2,
                            p_comment_in       IN VARCHAR2,
                            p_status_out       OUT VARCHAR2,
                            p_err_msg_out      OUT VARCHAR2);

  PROCEDURE reset_online_password(p_customer_id_in  IN VARCHAR2,
                                  p_comment_in      IN VARCHAR2,
                                  p_firstname_out   OUT VARCHAR2,
                                  p_lastname_out    OUT VARCHAR2,
                                  p_email_out       OUT VARCHAR2,
                                  p_panlastfour_out OUT VARCHAR2,
                                  p_prod_out        OUT VARCHAR2,
                                  p_password_out    OUT VARCHAR2,
                                  p_lang_out        OUT VARCHAR2,
                                  p_status_out      OUT VARCHAR2,
                                  p_err_msg_out     OUT VARCHAR2);

  PROCEDURE cardtocard_transfer(p_customer_id_in IN VARCHAR2,
                                p_pan_in         IN VARCHAR2,
                                p_amount_in      IN VARCHAR2,
                                p_approved_in    IN VARCHAR2,
                                p_reason_in      IN VARCHAR2,
                                p_comment_in     IN VARCHAR2,
                                p_isfeewaived_in IN VARCHAR2,
                                p_status_out     OUT VARCHAR2,
                                p_err_msg_out    OUT VARCHAR2);

  PROCEDURE decrypt_pan(p_card_id_in  IN VARCHAR2,
                        p_pan_out     OUT VARCHAR2,
                        p_status_out  OUT VARCHAR2,
                        p_err_msg_out OUT VARCHAR2);

  PROCEDURE upgrade_to_personalized_card(p_customer_id_in     IN  VARCHAR2,
                                         p_fee_waiver_flag_in IN  VARCHAR2,
                                         p_isexpedited_in     IN  VARCHAR2,
                                         p_addrone_in         IN  VARCHAR2,
                                         p_addrtwo_in         IN  VARCHAR2,
                                         p_city_in            IN  VARCHAR2,
                                         p_state_in           IN  VARCHAR2,
                                         p_postalcode_in      IN  VARCHAR2,
                                         p_countrycode_in     IN  VARCHAR2,
                                         p_new_maskcardno_out OUT VARCHAR2,
                                         p_status_out         OUT VARCHAR2,
                                         p_err_msg_out        OUT VARCHAR2
                                         );
  PROCEDURE get_card_status(p_pan_in                    IN VARCHAR2,
                            p_serialnumber_in           IN VARCHAR2,
                            p_card_id_in                IN VARCHAR2,
                            p_card_status_out           OUT VARCHAR2,
                            p_available_balance_out     OUT NUMBER,
                            p_initial_load_amount_out   OUT NUMBER,
                            p_status_out                OUT VARCHAR2,
                            p_err_msg_out               OUT VARCHAR2);
                            
PROCEDURE log_transactionlog     (p_api_name_in     IN VARCHAR2,
                                  p_customer_id_in  IN VARCHAR2,
                                  p_hash_pan_in     IN VARCHAR2,
                                  p_encr_pan_in     IN VARCHAR2,
								  p_txn_code_in 	IN VARCHAR2,
                                  p_process_flag_in IN VARCHAR2,
                                  p_process_msg_in  IN VARCHAR2,
                                  p_response_id_in  IN VARCHAR2,
                                  p_remarks_in      IN VARCHAR2,
                                  p_timetaken_in    IN VARCHAR2,
                                  p_audit_flag		IN VARCHAR2 DEFAULT 'T',
                                  p_fee_calc_in     IN VARCHAR2 DEFAULT 'N',
                                  p_auth_id_in      IN VARCHAR2 DEFAULT NULL);
								  
								  
PROCEDURE resend_email (
      p_customer_id_in   IN VARCHAR2,      
      p_email_in         IN VARCHAR2,
	  p_comment_in       IN VARCHAR2,
      p_status_out       OUT VARCHAR2,
      p_err_msg_out      OUT VARCHAR2
    );                                                

END gpp_cards;

/
SHOW ERRORS;