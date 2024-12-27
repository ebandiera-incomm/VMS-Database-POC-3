create or replace
PACKAGE VMSCMS.VMSCSD AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
  
  
 PROCEDURE        rollback_card_status (
   p_instcode_in        IN       NUMBER,
   p_rrn_in             IN       VARCHAR2,
   p_pan_code_in        IN       VARCHAR2,                               
   p_lupduser_in        IN       NUMBER,
   p_txn_code_in        IN       VARCHAR2,
   p_delivery_chnl_in   IN       VARCHAR2,
   p_msg_type_in        IN       VARCHAR2,
   p_revrsl_code_in     IN       VARCHAR2,
   p_txn_mode_in        IN       VARCHAR2,
   p_mbrnumb_in         IN       VARCHAR2,
   p_trandate_in        IN       VARCHAR2,
   p_trantime_in        IN       VARCHAR2, 
   p_remark_in          IN       VARCHAR2,  
   p_call_id_in         IN       VARCHAR2,
   p_ip_addr_in         IN       VARCHAR2,     
   P_SCHD_FLAG_in       IN       varchar2,      
   p_curr_code_in          IN       VARCHAR2,
   p_resp_code_out       OUT      VARCHAR2,
   p_errmsg_out          OUT      VARCHAR2
); 
  

END VMSCSD;
/
show error