  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_PAN" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : Sindhu Selvam
   -- Created : 9/22/2015 10:49:15 AM
   -- Purpose : To fetch the PAN details

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations

   -- Get PAN details
   PROCEDURE get_pan_details
   (
      p_customer_id_in IN VARCHAR2,
      p_hash_pan_out   OUT VARCHAR2,
      p_encr_pan_out   OUT VARCHAR2
   );

   PROCEDURE get_pan_details
   (
      p_customer_id_in IN VARCHAR2,
      p_hash_pan_out   OUT VARCHAR2,
      p_encr_pan_out   OUT VARCHAR2,
      p_acct_no_out    OUT VARCHAR2
   );

  PROCEDURE get_pan_details
  (p_customer_id_in IN VARCHAR2,
      p_hash_pan_out OUT VARCHAR2,
      p_encr_pan_out OUT VARCHAR2,
      p_cust_code_out OUT VARCHAR2,
      p_prod_code_out OUT VARCHAR2,
      p_catg_code_out OUT VARCHAR2,
      p_proxy_out OUT VARCHAR2,
      p_card_stat_out OUT VARCHAR2,
      p_acct_no_out OUT VARCHAR2,
      p_mask_pan_out OUT VARCHAR2,
      p_prfl_code_out OUT VARCHAR2
      );

END gpp_pan;