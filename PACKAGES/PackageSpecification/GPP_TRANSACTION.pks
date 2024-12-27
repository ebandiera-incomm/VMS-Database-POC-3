  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_TRANSACTION" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin
   -- Created : 8/17/2015 1:29:36 PM
   -- Purpose : New package for GPP

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations
FUNCTION get_transaction_token(p_customer_card_no_in IN vmscms.transactionlog.customer_card_no%TYPE,
                                 p_rrn_in              IN vmscms.transactionlog.rrn%TYPE,
                                 p_auth_id_in          IN vmscms.transactionlog.auth_id%TYPE)
    RETURN VARCHAR2;
   --To audit transaction log for each API call
   PROCEDURE audit_transaction_log
   (
      p_api_name_in     IN VARCHAR2,
      p_customer_id_in  IN VARCHAR2,
      p_hash_pan_in     IN VARCHAR2,
      p_encr_pan_in     IN VARCHAR2,
      p_process_flag_in IN VARCHAR2,
      p_process_msg_in  IN VARCHAR2,
      p_response_id_in  IN VARCHAR2,
      p_remarks_in      IN VARCHAR2,
      p_timetaken_in    IN VARCHAR2,
      p_fee_calc_in     IN VARCHAR2 DEFAULT 'N',
      p_auth_id_in      IN VARCHAR2 DEFAULT NULL
   );

   --Get Transaction Detail API
   PROCEDURE get_transaction_detail
   (
      p_customer_id_in      IN VARCHAR2,
      p_txn_id_in           IN VARCHAR2,
      p_txn_date_in         IN VARCHAR2,
      p_delivery_channel_in IN VARCHAR2,
      p_txn_code_in         IN VARCHAR2,
      p_response_code_in    IN VARCHAR2,
      p_status_out          OUT VARCHAR2,
      p_err_msg_out         OUT VARCHAR2,
      c_transaction_out     OUT SYS_REFCURSOR,
      c_fraudrule_out       OUT SYS_REFCURSOR
   );

   --Get Transaction History API
   PROCEDURE get_transaction_history
   (
      p_customer_id_in    IN VARCHAR2,
      p_start_date_in     IN VARCHAR2,
      p_end_date_in       IN VARCHAR2,
      p_acc_type_in       IN VARCHAR2 DEFAULT 'ALL',
      p_txn_filter_in     IN VARCHAR2 DEFAULT 'ALL',
      p_token_in           IN VARCHAR2,
      p_sortorder_in      IN VARCHAR2,
      p_sortelement_in    IN VARCHAR2,
      p_recordsperpage_in IN VARCHAR2,
      p_pagenumber_in     IN VARCHAR2,
      p_status_out        OUT VARCHAR2,
      p_err_msg_out       OUT VARCHAR2,
      c_transaction_out   OUT SYS_REFCURSOR
   );

PROCEDURE UPDATE_TRANSACTION_STATUS(p_customer_id_in       IN VARCHAR2,
                                    p_txn_id_in            IN VARCHAR2,
                                    p_txn_date_in          IN VARCHAR2,
                                    p_delivery_channel_in  IN VARCHAR2,
                                    p_txn_code_in          IN VARCHAR2,
                                    p_response_code_in     IN VARCHAR2,
                                    p_fraudulent_in		     IN VARCHAR2,
                                    p_comment_in		       IN VARCHAR2,
                                    p_status_out           OUT VARCHAR2,
                                    p_err_msg_out          OUT VARCHAR2
                                     ) ;


PROCEDURE get_transaction_audit_log(p_customer_id_in       IN  VARCHAR2,
                                    p_txn_id_in            IN  VARCHAR2,
                                    p_txn_date_in          IN  VARCHAR2,
                                    p_delivery_channel_in  IN  VARCHAR2,
                                    p_txn_code_in          IN  VARCHAR2,
                                    p_status_out           OUT VARCHAR2,
                                    p_err_msg_out          OUT VARCHAR2,
                                    c_transaction_out      OUT SYS_REFCURSOR
                                    );

 END gpp_transaction;
 
 /
 show error