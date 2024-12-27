create or replace
PACKAGE          "GPP_ORDERS" AUTHID CURRENT_USER IS

  -- PL/SQL Package using FS Framework
  -- Author  : Ubaidur Rahman H
  -- Created : 29/04/2019 
  -- Purpose : To fetch the order details

  -- Global public type declarations should be located in the FSFW.FSTYPE package

  -- Global public constant declarations should be located in the FSFW.FSCONST package

  -- Public variable declarations

  -- Public function and procedure declarations

  -- get the order status
  PROCEDURE get_order_status(p_order_id_in                IN  VARCHAR2,
                             p_fulfillment_orderid_in     IN  VARCHAR2,
                             p_serial_number_in           IN  VARCHAR2,
                             p_order_channel_in           IN  VARCHAR2,
                             p_order_id_out               OUT VARCHAR2,
                             p_isprintorder_out           OUT VARCHAR2,
                             p_order_status_out           OUT VARCHAR2,
                             p_shipping_method_out        OUT VARCHAR2,
                             c_cards_out                  OUT SYS_REFCURSOR,
                             p_status_out                 OUT VARCHAR2,
                             p_err_msg_out                OUT VARCHAR2
                            );
 
END gpp_orders;