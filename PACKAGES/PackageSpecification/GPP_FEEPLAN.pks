  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_FEEPLAN" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin Beura
   -- Created : 8/12/2015 4:04:29 PM
   -- Purpose : Package for getting the fee plan details

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations
   --Get feeplan details
   PROCEDURE get_feeplan_details
   (
      p_feeplan_id_in      IN VARCHAR2,
      p_status_out         OUT VARCHAR2,
      p_err_msg_out        OUT VARCHAR2,
      p_feeplan_desc_out   OUT VARCHAR2,
      c_feeplan_detail_out OUT SYS_REFCURSOR
   );

   --Get customer fee plan details API
   PROCEDURE get_customer_feeplan_details
   (
      p_customer_id_in       IN VARCHAR2,
      p_status_out           OUT VARCHAR2,
      p_err_msg_out          OUT VARCHAR2,
      c_cust_feeplan_out     OUT SYS_REFCURSOR,
      c_cust_feeplan_det_out OUT SYS_REFCURSOR
   );
   --update fee plan
   PROCEDURE update_fee_plan
   (
      p_customer_id_in IN VARCHAR2,
      p_feeplan_id_in  IN VARCHAR2,
      p_eff_date_in    IN VARCHAR2,
      p_comment_in     IN VARCHAR2,
      p_status_out     OUT VARCHAR2,
      p_err_msg_out    OUT VARCHAR2
   );


   FUNCTION get_fee_plan
   ( p_hash_pan_in IN VARCHAR2,
     p_prod_code_in IN VARCHAR2,
     p_catg_code_in IN VARCHAR2
   ) RETURN NUMBER;


END gpp_feeplan;