create or replace
PACKAGE VMSCMS.vms_ivr
AS
  -- Author  : NARAYANAST
  -- Created : 03/05/2016
  -- Purpose : To migrate the existing startercard account to new startercard
  -- for closed loop changes
PROCEDURE startercard_replacement(
    p_instcode_in         IN NUMBER,
    p_msg_type_in         IN VARCHAR2,
    p_rrn_in              IN VARCHAR2,
    p_delivery_channel_in IN VARCHAR2,
    p_terminalid_in       IN VARCHAR2,
    p_txn_code_in         IN VARCHAR2,
    p_txn_mode_in         IN VARCHAR2,
    p_trandate_in         IN VARCHAR2,
    p_trantime_in         IN VARCHAR2,
    p_card_no_in          IN VARCHAR2,
    p_tocard_no_in        IN VARCHAR2,
    p_currcode_in         IN VARCHAR2,
    p_mbr_numb_in         IN VARCHAR2,
    p_rvsl_code_in        in varchar2,
    p_ani_in              in varchar2,
    p_dni_in              in varchar2,
     p_resp_code_out OUT VARCHAR2,
    p_errmsg_out out varchar2,
    p_card_status_out  out varchar2,
    p_card_status_desc_out   out varchar2);
END vms_ivr;
/
show error