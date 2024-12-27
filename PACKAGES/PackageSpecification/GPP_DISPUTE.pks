  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_DISPUTE" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin Beura
   -- Created : 11/18/2015 11:32:16 AM
   -- Purpose : To check for dispute transaction and update dispute transaction

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE get_dispute_trans_info
   (
      p_customer_id_in      IN VARCHAR2,
      p_txn_id_in           IN VARCHAR2,
      p_txn_date_in         IN VARCHAR2,
      p_delivery_channel_in IN VARCHAR2,
      p_txn_code_in         IN VARCHAR2,
      p_response_code_in    IN VARCHAR2,
      p_status_out          OUT VARCHAR2,
      p_err_msg_out         OUT VARCHAR2,
      c_dispute_trans_out   OUT SYS_REFCURSOR,
      c_dispute_trans_doc_out OUT SYS_REFCURSOR -- Added new cursor to get document array
   );

   PROCEDURE dispute_transaction
   (
      p_customer_id_in    IN VARCHAR2,
      p_deliverymethod_in IN VARCHAR2,
      p_dispute_array_in  IN VARCHAR2,
      p_comment_in        IN VARCHAR2,
      p_status_out        OUT VARCHAR2,
      p_err_msg_out       OUT VARCHAR2
   );
   PROCEDURE update_dispute
   (
      p_customer_id_in      IN VARCHAR2,
      p_txn_id_in           IN VARCHAR2,
      p_txn_date_in         IN VARCHAR2,
      p_delivery_channel_in IN VARCHAR2,
      p_txn_code_in         IN VARCHAR2,
      p_response_code_in    IN VARCHAR2,
      p_isapproved_in       IN VARCHAR2,
      p_refund_type_in      IN VARCHAR2,
      p_comment_in          IN VARCHAR2,
      p_status_out          OUT VARCHAR2,
      p_err_msg_out         OUT VARCHAR2
   );

END gpp_dispute;