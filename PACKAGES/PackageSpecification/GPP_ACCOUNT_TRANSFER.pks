  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_ACCOUNT_TRANSFER" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Aparna Sakhalkar
  -- Created : 1/16/2015 8:49:15 PM
  -- Purpose : To facilitate transfer of funds between saving and spending accounts

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations

  -- Main public procedure to perform account transfer
  PROCEDURE account_transfer(p_customer_id_in              IN VARCHAR2,
                             p_from_account_type_in        IN VARCHAR2,
                             p_amount_in                   IN VARCHAR2,
                             p_close_flag_in               IN VARCHAR2,
                             p_comment_in                  IN VARCHAR2,
                             p_spending_ledger_balance     OUT VARCHAR2,
                             p_spending_available_balance  OUT VARCHAR2,
                             p_savings_ledger_balance      OUT VARCHAR2,
                             p_savings_completed_transfers OUT VARCHAR2,
                             p_savings_remaining_transfers OUT VARCHAR2,
                             p_status_out                  OUT VARCHAR2,
                             p_err_msg_out                 OUT VARCHAR2);
END GPP_ACCOUNT_TRANSFER;