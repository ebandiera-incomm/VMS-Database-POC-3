create or replace
PACKAGE        VMSB2BAPIV1
AS
   -- Author  : Siva Kumar 
   -- Created : 21-Sep-2017
   -- Purpose : B2B APIS
   -- Mofidifed by   : Siva Kumar 
   -- Mofidifed date : 05-oct-2017
   -- Purpose : B2B APIS
PROCEDURE  card_replacerenewal( p_inst_code_in          IN  NUMBER,
                                 P_CARD_NO_in           IN  VARCHAR2,
                                 P_MSG_in               IN  VARCHAR2,
                                 P_TXN_MODE_in          in varchar2,
                                 P_CURR_CODE_in         IN  VARCHAR2,
                                 p_first_name_in        IN  varchar2,
                                 p_middleinitial_in     IN  varchar2,
                                 p_last_name_in         IN  varchar2,
                                 p_email_in             in  varchar2,
                                 p_phone_in             IN  varchar2,
                                 p_addressLine_one_in   IN  varchar2,
                                 p_addressLine_two_in   IN  varchar2,
                                 p_addressLine_three_in IN  varchar2,
                                 p_state_in             IN 	varchar2,
                                 p_city_in              IN  varchar2,
                                 p_country_in           IN  varchar2,
                                 p_postal_code_in       in  varchar2,
                                  --p_action_in_in         in  varchar2,
                                 p_comments_in         in  varchar2,
                                 p_request_reason_in    IN  varchar2,
                                 P_shippingMethod_in    in  varchar2,
                                 p_isFeeWaived_in       in  varchar2,
                                 P_fsapi_channel_in     in  varchar2,
                                 P_STAN_IN              IN VARCHAR2,
                                 P_MBR_NUMB_IN          IN VARCHAR2,
                                 P_RVSL_CODE_IN         IN NUMBER,
                                 p_ship_CompanyName_in  in varchar2,
                                 p_card_expirty_date_out out varchar2,
                                 p_available_balance_out out varchar2,
                                 p_last4digits_pan_out   out varchar2,
                                 p_card_fee_out          out varchar2,
                                 p_resp_code_out        out varchar2,
                                 p_resp_messge_out      out varchar2);

 
END VMSB2BAPIV1;