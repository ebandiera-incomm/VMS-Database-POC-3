  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_IDENTIFICATION" AS

 PROCEDURE update_identification_info(
                           p_customer_id_in         IN VARCHAR2,
                           p_action_in              IN VARCHAR2,
                           --identification
                           p_id_type_in             IN VARCHAR2,
                           p_number_in              IN VARCHAR2,
                           p_issuedby_in            IN VARCHAR2,
                           p_issuance_date_in       IN VARCHAR2,
                           p_expiration_date_in     IN VARCHAR2,
                           p_province_in            IN VARCHAR2,
                           p_countryin              IN VARCHAR2,
                           p_verification_date_in   IN VARCHAR2,
                           --occupation
                           p_occupation_type_in     IN VARCHAR2,
                           p_occupation_in          IN VARCHAR2,
                           --tax info
                           p_istax_res_can_in       IN VARCHAR2,
                           p_taxpin_in              IN VARCHAR2,
                           p_no_tax_reason_id_in    IN VARCHAR2,
                           p_no_tax_reason_desc_in  IN VARCHAR2,
                           p_tax_juris_resident_in  IN VARCHAR2,
                           -- third party info
                           p_isthird_party_benft_in IN VARCHAR2,
                           p_third_party_type_in    IN VARCHAR2,
                           p_firstname_in           IN VARCHAR2,
                           p_lastname_in            IN VARCHAR2,
                           p_corporationaname_in    IN VARCHAR2,
                           p_dob_in                 IN VARCHAR2,
                           p_addrone_in             IN VARCHAR2,
                           p_addrtwo_in             IN VARCHAR2,
                           p_city_in                IN VARCHAR2,
                           p_state_in               IN VARCHAR2,
                           p_postalcode_in          IN VARCHAR2,
                           p_countrycode_in         IN VARCHAR2,
                           p_occupation_code_in     IN VARCHAR2,
                           p_occupation_desc_in     IN VARCHAR2,
                           p_in_corporation_no_in   IN VARCHAR2,
                           p_nature_of_relation_in  IN VARCHAR2,
                           p_nature_of_business_in  IN VARCHAR2,
                           --common
                           p_status_out             OUT VARCHAR2,
                           p_err_msg_out            OUT VARCHAR2);


END GPP_IDENTIFICATION;