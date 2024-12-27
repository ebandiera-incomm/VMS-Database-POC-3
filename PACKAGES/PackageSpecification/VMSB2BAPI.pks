create or replace PACKAGE        vmscms.VMSB2BAPI
AS
   -- Author  : MageshKumar
   -- Created : 27-July-2017
   -- Purpose : B2B APIS

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations

 PROCEDURE get_inventory_control_number(p_prod_code_in in varchar2,
                                      p_card_type_in in number,
                                      p_quantity_in  in number,
                                      p_start_control_number_out out number,
                                      p_end_control_number_out out number,
                                      p_error_out out varchar2);
                                      
    PROCEDURE UPDATE_PANGEN_SUMMARY
                                    (p_prod_code_in in varchar2,
                                    p_card_type_in in number,
                                    p_start_control_number in number,
                                    p_end_control_number in number,
                                    p_error_out out varchar2);

   PROCEDURE process_order_request (p_inst_code_in    IN     NUMBER,
                                    p_order_id_in     IN     VARCHAR2,
                                    p_partner_id_in   IN     VARCHAR2,
                                    P_USER_CODE_IN    IN     NUMBER,
                                    p_resp_msg_out       OUT VARCHAR2);

   PROCEDURE get_serials (p_productid_in   IN     VARCHAR2,
                          p_quantity_in    IN     NUMBER,
                          p_serials_out       OUT shuffle_array_typ,
                          p_respmsg_out       OUT VARCHAR2
                          );

   PROCEDURE delete_cards (p_card_nos_in    IN     shuffle_array_typ,
                           p_resp_msg_out      OUT VARCHAR2);
PROCEDURE cancel_order_request(
    p_inst_code_in  IN NUMBER,
    p_order_id_in   IN VARCHAR2,
    p_partner_id_in IN VARCHAR2,
    p_resp_Code_out OUT VARCHAR2,
    p_resp_msg_out OUT VARCHAR2)  ;  
	
    PROCEDURE cancel_order_process(
    p_inst_code_in  IN NUMBER,
    p_order_id_in   IN VARCHAR2,
    p_partner_id_in IN VARCHAR2,
    p_resp_Code_out OUT VARCHAR2,
    p_resp_msg_out OUT VARCHAR2,
    P_postback_URL_OUT OUT VARCHAR2);
	
    PROCEDURE replace_card_b2b_v2 
		(p_customer_id_in IN NUMBER,
                 p_isexpedited_in IN VARCHAR2,
                 p_isfeewaived_in IN VARCHAR2,
                 p_comment_in     IN VARCHAR2,                         
                 p_createnewcard_in IN VARCHAR2 DEFAULT 'FALSE',                         
                 p_loadamounttype_in   IN VARCHAR2,
                 p_loadamount_in          IN VARCHAR2,
                 p_merchantid_in          IN VARCHAR2,
                 p_terminalid_in          IN VARCHAR2,
                 p_locationid_in          IN VARCHAR2,
                 p_merchantbillable_in    IN VARCHAR2,
                 p_activationcode_in      IN VARCHAR2,
                 p_firstname_in           IN VARCHAR2,
                 p_middlename_in          IN VARCHAR2,
                 p_lastname_in            IN VARCHAR2,
                 p_addrone_in             IN VARCHAR2,
                 p_addrtwo_in             IN VARCHAR2,
                 p_city_in                IN VARCHAR2,
                 p_state_in               IN VARCHAR2,
                 p_postalcode_in          IN VARCHAR2,
                 p_countrycode_in         IN VARCHAR2,
				 p_delivery_chnl_in	  	  IN VARCHAR2,
				 p_email_in			  IN VARCHAR2,
                 p_istoken_eligible_out   OUT VARCHAR2,
                 p_iscvvplus_eligible_out OUT VARCHAR2,
                 p_cardno_out             OUT VARCHAR2,
                 p_exprydate_out          OUT VARCHAR2,
                 p_new_cardno_out         OUT VARCHAR2,
                 p_new_exprydate_out      OUT VARCHAR2,
                 p_stan_out               OUT VARCHAR2,
                 p_rrn_out                OUT VARCHAR2,
                 p_activationcode_out     OUT VARCHAR2,
                 p_req_reason_out         OUT VARCHAR2,
                 p_forward_instcode_out   OUT VARCHAR2,
                 p_message_reasoncode_out OUT VARCHAR2,
                 p_new_maskcardno_out     OUT VARCHAR2,
                 p_token_dtls_out         OUT SYS_REFCURSOR,
                 p_status_out             OUT VARCHAR2,
                 p_err_msg_out            OUT VARCHAR2);
	
	
END VMSB2BAPI;

/
show error;