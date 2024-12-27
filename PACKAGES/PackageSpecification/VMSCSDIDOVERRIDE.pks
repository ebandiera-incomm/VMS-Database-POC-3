CREATE OR REPLACE PACKAGE VMSCMS.VMSCSDIDOVERRIDE
AS
   PROCEDURE OVERRIDE_IDCHECK_FAIL (p_instcode_in       IN     NUMBER,
                                    p_msg_type_in       IN     VARCHAR2,
                                    p_rowid_in          IN     VARCHAR2,
                                    p_rrn_in            IN     VARCHAR2,
                                    p_stan_in           IN     VARCHAR2,
                                    p_txn_code_in       IN     VARCHAR2,
                                    p_tran_mode_in      IN     VARCHAR2,
                                    p_delv_chnl_in      IN     VARCHAR2,
                                    p_curr_code_in      IN     VARCHAR2,
                                    p_kyc_flag_in       IN     VARCHAR2,
                                    p_starter_card_in   IN     VARCHAR2,
                                    p_tran_date_in      IN     VARCHAR2,
                                    p_tran_time_in      IN     VARCHAR2,
                                    p_lupduser_in       IN     NUMBER,
                                    p_comment_in        IN     VARCHAR2,
                                    p_reason_in         IN     VARCHAR2,
                                    p_ipaddress_in      IN     VARCHAR2,
                                    p_gpr_card_out         OUT VARCHAR2,
                                    p_acct_no_out          OUT VARCHAR2,
                                    p_cust_id_out          OUT VARCHAR2,
                                    p_resp_code_out        OUT VARCHAR2,
                                    p_errmsg_out           OUT VARCHAR2,
                                    p_pin_flag_out       OUT      VARCHAR2,
   				    p_gpr_pan_out       OUT      VARCHAR2
);
END VMSCSDIDOVERRIDE;
/

SHOW ERROR