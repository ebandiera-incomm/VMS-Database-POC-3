  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_ACCOUNTS" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin Beura
  -- Created : 8/17/2015 10:49:15 AM
  -- Purpose : To fetch the account details

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations

  -- get the account details
  PROCEDURE get_account_details(p_customer_id_in              IN  VARCHAR2,
                                p_status_out                  OUT VARCHAR2,
                                p_err_msg_out                 OUT VARCHAR2,
                                c_account_detail_out          OUT SYS_REFCURSOR,
                                c_cardfee_detail_out          OUT SYS_REFCURSOR,
                                c_limits_detail_out           OUT SYS_REFCURSOR,
                                c_doc_detail_out              OUT SYS_REFCURSOR,
                                c_multipack_card_out          OUT SYS_REFCURSOR,
                                c_relative_account_detail_out OUT SYS_REFCURSOR
                                --p_upgrade_eligible_flag                  OUT VARCHAR2        --Commented by FSS
                                --c_token_detail_out   OUT SYS_REFCURSOR                    --Commented by FSS
                                );
  -- get the account limits
  PROCEDURE get_account_limits(p_customer_id_in     IN VARCHAR2,
                               p_status_out         OUT VARCHAR2,
                               p_err_msg_out        OUT VARCHAR2,
                               c_account_limits_out OUT SYS_REFCURSOR

                               );
  --get direct deposit form
  PROCEDURE get_directdeposit_form(p_customer_id_in    IN VARCHAR2,
                                   p_status_out        OUT VARCHAR2,
                                   p_err_msg_out       OUT VARCHAR2,
                                   c_directdeposit_out OUT SYS_REFCURSOR);
  --Get Send Account Statement API
  PROCEDURE get_account_statement(p_customer_id_in       IN VARCHAR2,
                                  p_acc_type_in          IN OUT VARCHAR2,
                                  p_stmt_type_in         IN VARCHAR2,
                                  p_start_date_in        IN VARCHAR2,
                                  p_end_date_in          IN VARCHAR2,
                                  p_fee_waiver_in        IN VARCHAR2,
                                  p_sortorder_in         IN VARCHAR2,
                                  p_sortelement_in       IN VARCHAR2,
                                  p_recordsperpage_in    IN VARCHAR2,
                                  p_pagenumber_in        IN VARCHAR2,
                                  p_status_out           OUT VARCHAR2,
                                  p_err_msg_out          OUT VARCHAR2,
                                  p_int_accrued_out      OUT VARCHAR2,
                                  p_int_paid_out         OUT VARCHAR2,
                                  p_percent_yield_out    OUT VARCHAR2,
                                  p_int_rate_out         OUT VARCHAR2,
                                  p_open_bal_out         OUT VARCHAR2,
                                  p_close_bal_out        OUT VARCHAR2,
                                  p_total_fee_out        OUT NUMBER,
                                  p_ytd_out              OUT NUMBER,
                                  p_statement_footer_out OUT VARCHAR2,
                                  c_txn_det_out          OUT SYS_REFCURSOR,
                                  c_acc_det_out          OUT SYS_REFCURSOR);

  -- Unmask pan
  PROCEDURE get_umaskpan(p_customer_id_in IN VARCHAR2,
                         p_mask_pan_in    IN VARCHAR2,
                         p_unmask_pan_out OUT VARCHAR2,
                         p_status_out     OUT VARCHAR2,
                         p_err_msg_out    OUT VARCHAR2);

  --Submit Document
  PROCEDURE submit_document(p_customer_id_in   IN VARCHAR2,
                            p_file_type_in     IN VARCHAR2,
                            p_file_path_in     IN VARCHAR2,
                            p_file_size_in     IN VARCHAR2,
                            p_business_date_in IN VARCHAR2,
                            p_business_time_in IN VARCHAR2,
                            p_txn_code_in      IN VARCHAR2,
                            p_txn_id_in        IN VARCHAR2,
                            p_status_out       OUT VARCHAR2,
                            p_err_msg_out      OUT VARCHAR2);

  --Adjust Balance
  PROCEDURE adjust_balance(p_action_in           IN VARCHAR2,
                           p_customer_id_in      IN VARCHAR2,
                           p_txn_id_in           IN VARCHAR2,
                           p_txn_date_in         IN VARCHAR2,
                           p_delivery_channel_in IN VARCHAR2,
                           p_txn_code_in         IN VARCHAR2,
                           p_response_code_in    IN VARCHAR2,
                           p_amount_in           IN VARCHAR2,
                           p_crdr_flag_in        IN VARCHAR2,
                           p_acct_type_in        IN VARCHAR2,
                           p_reason_in           IN VARCHAR2,
                           p_comment_in          IN VARCHAR2,
                           c_adj_bal_out         OUT SYS_REFCURSOR,
                           p_status_out          OUT VARCHAR2,
                           p_err_msg_out         OUT VARCHAR2

                           );

  /*
     --Savings Transfer and Account Closure   API
     PROCEDURE transfer_account_closure
     (
        p_customer_nbr_in     IN VARCHAR2,
        p_from_acct_type_in   IN VARCHAR2,
        p_ammount_in          IN NUMBER,
        p_close_flag_in       IN VARCHAR2,
        p_comment_in          IN VARCHAR2,
        p_spnd_ledger_bal_out OUT vmscms.cms_acct_mast.cam_ledger_bal%TYPE,
        p_spnd_aval_bal_out   OUT vmscms.cms_acct_mast.cam_acct_bal%TYPE,
        p_sav_ledger_bal_out  OUT vmscms.cms_acct_mast.cam_ledger_bal%TYPE,
        p_sav_remain_trns_out OUT NUMBER,
        p_sav_comple_trns_out OUT NUMBER,
        p_status_out          OUT VARCHAR2,
        p_err_msg_out         OUT VARCHAR2
     );
  */

  FUNCTION get_wallet_id(p_vti_token_requestor_id_in IN VARCHAR2,
                         p_vti_wallet_identifier_in  IN VARCHAR2)
    RETURN VARCHAR2;
END gpp_accounts;
/
show error