  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_UTILS" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin
  -- Created : 9/25/2015 11:19:55 AM
  -- Purpose : Get the response code and transaction code details

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations
  --Get Response Code
  PROCEDURE get_response_code(c_response_code_out OUT SYS_REFCURSOR,
                              p_status_out        OUT VARCHAR2,
                              p_err_msg_out       OUT VARCHAR2);

  --Get Transaction Code
  PROCEDURE get_transaction_code(p_delv_chnl_in  IN VARCHAR2,
                                 c_tran_code_out OUT SYS_REFCURSOR,
                                 p_status_out    OUT VARCHAR2,
                                 p_err_msg_out   OUT VARCHAR2);

  PROCEDURE get_datetime_rrn(p_date_out OUT VARCHAR2,
                             p_time_out OUT VARCHAR2,
                             p_rrn_out  OUT VARCHAR2);

  --Get State and Country Codes
  PROCEDURE get_country_state_codes(c_country_code_out OUT SYS_REFCURSOR,
                                    c_state_code_out   OUT SYS_REFCURSOR,
                                    p_status_out       OUT VARCHAR2,
                                    p_err_msg_out      OUT VARCHAR2);

  -- Validate customer with partner
  FUNCTION validate_cust_partner(p_ccm_cust_id_in    cms_cust_mast.ccm_cust_id%TYPE,
                                 p_ccm_partner_id_in cms_cust_mast.ccm_partner_id%TYPE)
    RETURN VARCHAR2;

  FUNCTION get_prod_code_card_type(p_partner_id_in IN vmscms.vms_groupid_partnerid_map.vgp_partner_id%type,
                                   p_prod_code_in  IN vmscms.cms_cust_mast.ccm_prod_code%TYPE,
                                   p_card_type_in  IN vmscms.cms_cust_mast.ccm_card_type%TYPE)
    RETURN VARCHAR2;
      --Get Occupation Details
  PROCEDURE get_occupation_details(c_occupation_detail_out OUT SYS_REFCURSOR,
                                   p_status_out            OUT VARCHAR2,
                                   p_err_msg_out           OUT VARCHAR2);

   --Get Identifucation types
  PROCEDURE get_identification_types(c_id_types_out OUT SYS_REFCURSOR,
                                     p_status_out            OUT VARCHAR2,
                                     p_err_msg_out           OUT VARCHAR2);

END gpp_utils;