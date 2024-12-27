  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_CUSTOMERS" IS

   -- Author  : Rojalin
   -- Created : 10/27/2015 11:35:30 AM
   -- Purpose :

   -- Public function and procedure declarations
   --get Customers Details
   PROCEDURE get_customers
   (
      p_searchtype_in     IN VARCHAR2,
      p_sortorder_in      IN VARCHAR2,
      p_sortelement_in    IN VARCHAR2,
      p_recordsperpage_in IN VARCHAR2,
      p_pagenumber_in     IN VARCHAR2,
      p_accountnumber_in  IN VARCHAR2,
      p_serialnumber_in   IN VARCHAR2,
      p_proxynumber_in    IN VARCHAR2,
      p_pan_in            IN VARCHAR2,
      p_firstname_in      IN VARCHAR2,
      p_lastname_in       IN VARCHAR2,
      p_identity_id_in    IN VARCHAR2,
      p_identity_type_in  IN VARCHAR2,
      p_dateofbirth_in    IN VARCHAR2,
      p_email_in          IN VARCHAR2,
      p_address_in        IN VARCHAR2,
      p_city_in           IN VARCHAR2,
      p_state_in          IN VARCHAR2,
      p_postalcode_in     IN VARCHAR2,
      p_onlineuserid_in   IN VARCHAR2,
      p_card_id_in        IN VARCHAR2,
      p_transaction_id_in IN VARCHAR2,
      p_from_date_in      IN varchar2,
      p_to_date_in        IN varchar2,
      p_status_out        OUT VARCHAR2,
      p_err_msg_out       OUT VARCHAR2,
      c_customers_out     OUT SYS_REFCURSOR,
      c_cards_out         OUT SYS_REFCURSOR
   );

END gpp_customers;