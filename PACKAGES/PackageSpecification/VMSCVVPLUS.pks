create or replace
PACKAGE vmscms.VMSCVVPLUS AS 

    -- Author  : MageshKumar
    -- Created : 19-Apr-2017
    -- Purpose : CVV PLUS

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations 
   
   
   PROCEDURE registration (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_ip_address_in               in    varchar2,
          p_mobile_no_in                in    varchar2,
          p_device_id_in                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
        --  p_cell_no_out                 out   varchar2,
        --  p_email_id_out                out   varchar2,
          p_processor_card_token_out    out   varchar2);
          
          
          PROCEDURE optout (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_processor_card_token_in   	in  	varchar2,
          p_accountId_in   	            in  	varchar2,
          p_ip_address_in               in    varchar2,
          p_mobile_no_in                in    varchar2,
          p_device_id_in                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2);
          
         

END VMSCVVPLUS;
/
show error