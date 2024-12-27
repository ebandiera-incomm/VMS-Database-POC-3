  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_TOKENS" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Aparna Sakhalkar
  -- Created : 5/18/2017 9:40:15 AM
  -- Purpose : To manage token data

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations

  -- get the account details
  PROCEDURE get_token_details(p_customer_id_in     IN VARCHAR2,
                              p_status_out         OUT VARCHAR2,
                              p_err_msg_out        OUT VARCHAR2,
                              c_account_detail_out OUT SYS_REFCURSOR,
                              c_cardfee_detail_out OUT SYS_REFCURSOR,
                              c_limits_detail_out  OUT SYS_REFCURSOR,
                              c_doc_detail_out     OUT SYS_REFCURSOR,
                              c_token_detail_out   OUT SYS_REFCURSOR);

  PROCEDURE update_token_cards(p_newcard_no_in     IN VARCHAR2,
                               p_oldcard_no_out    OUT VARCHAR2,
                               p_provisioning_flag OUT VARCHAR2,
                               p_err_msg_out       OUT VARCHAR2);

  PROCEDURE update_token_status(p_customer_id_in    IN VARCHAR2 DEFAULT NULL,
                                p_token_in          IN VARCHAR2,
                                p_status_in         IN VARCHAR2,
                                p_comment_in        IN VARCHAR2,
                                p_cardno_out        OUT VARCHAR2,
                                p_exprydate_out     OUT VARCHAR2,
                                p_token_dtls_out OUT SYS_REFCURSOR,
                                p_status_out        OUT VARCHAR2,
                                p_err_msg_out       OUT VARCHAR2);

  PROCEDURE update_token_status(p_cardno_in      IN VARCHAR2,
                                p_new_cardno_in  IN VARCHAR2,
                                p_action_in      IN VARCHAR2, --'R'~Replace, 'U'~Update Status, 'A'~Activation
                                p_action_out     OUT VARCHAR2, --'R'~Token Replaced, 'D'~Token Deleted
                                p_old_card_out   OUT VARCHAR2,
                                p_old_expry_out  OUT VARCHAR2,
                                p_token_dtls_out OUT SYS_REFCURSOR,
                                p_err_msg_out    OUT VARCHAR2);

  FUNCTION get_wallet_id(p_vti_token_requestor_id_in IN VARCHAR2,
                         p_vti_wallet_identifier_in  IN VARCHAR2)
    RETURN VARCHAR2;
END gpp_tokens;  /* GOLDENGATE_DDL_REPLICATION */