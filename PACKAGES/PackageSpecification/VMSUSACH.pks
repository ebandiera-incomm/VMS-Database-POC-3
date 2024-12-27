CREATE OR REPLACE PACKAGE VMSCMS.VMSUSACH
IS
   -- Author  : Pankaj S.
   -- Created : 7/22/2015
   -- Purpose : Provides functionality for US Direct Deposit transaction in VMS
   -- Reviewer: Sarvanan
   -- Build No: VMSGPRHOST3.0.4

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   
 /* 
   * Modified by          :Siva Kumar M
   * Modified Date        : 05-JAN-16
   * Modified For         : MVHOST-1255
   * Modified reason      : reason code logging
   * Reviewer             : Saravans kumar 
   * Build Number         : RI0027.3.3_B0002*/
   FUNCTION check_achbypass (p_acct_no_in         VARCHAR2,
                             p_company_name_in    VARCHAR2,
                             p_resp_code_in       VARCHAR2)
      RETURN VARCHAR2;
      
      
      PROCEDURE        REJECT_ACHTXN_CSR (
 p_inst_code_in                 IN       NUMBER,
   p_revrsl_code_in               IN       VARCHAR2,
   p_msg_type_in                  IN       VARCHAR2,
   p_rrn_in                       IN       VARCHAR2,
   p_stan_in                      IN       VARCHAR2,
   p_tran_date_in                 IN       VARCHAR2,
   p_tran_time_in                 IN       VARCHAR2,
   p_txn_amt_in                   IN       VARCHAR2,
   p_txn_code_in                  IN       VARCHAR2,
   p_delivery_chnl_in             IN       VARCHAR2,
   p_txn_mode_in                  IN       VARCHAR2,
   p_mbr_numb_in                  IN       VARCHAR2,
   p_orgnl_rrn_in                 IN       VARCHAR2,
   p_orgnl_card_no_in             IN       VARCHAR2,
   p_orgnl_stan_in                IN       VARCHAR2,
   p_orgnl_tran_date_in           IN       VARCHAR2,
   p_orgnl_tran_time_in           IN       VARCHAR2,
   p_orgnl_txn_amt_in             IN       VARCHAR2,
   p_orgnl_txn_code_in            IN       VARCHAR2,
   p_orgnl_delivery_chnl_in       IN       VARCHAR2,
   p_orgnl_auth_id_in             IN       VARCHAR2,
   p_curr_code_in               IN       VARCHAR2,
   p_remark_in                    IN       VARCHAR2,
   -- p_reason_desc_in               IN       VARCHAR2,
   p_reason_code_in                IN       VARCHAR2,
   p_ins_user_in                  IN       NUMBER,
   p_r17_response_in              IN       VARCHAR2,
   p_resp_code_out                 OUT      VARCHAR2,
   p_errmsg_out                    OUT      VARCHAR2,
   p_ach_startledgerbal_out        OUT      VARCHAR2,
   p_ach_startaccountbalance_out   OUT      VARCHAR2,
   p_ach_endledgerbal_out          OUT      VARCHAR2,
   p_ach_endaccountbalance_out     OUT      VARCHAR2,
   p_ach_auth_id_out               OUT      VARCHAR2
);

END VMSUSACH;
/
SHOW ERROR