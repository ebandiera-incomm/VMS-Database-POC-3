create or replace
package vmscms.vmsfileprocess
as
  procedure PRINTER_RETURNFILE_PROCESS(P_INST_CODE_IN in number,P_FILE_NAME_IN in varchar2,
  p_resp_msg_out out varchar2,p_child_partner_id_out out CLOB,
  p_success_count_out out number,p_failure_count_out out number);

  procedure PRINTER_SHIPMENTFILE_PROCESS(P_INST_CODE_IN in number,
  P_FILE_NAME_IN in varchar2,P_RESP_MSG_OUT OUT varchar2,
  p_child_partner_id_out out CLOB,p_success_count_out out number,p_failure_count_out out number);

  procedure PRINTER_CONFIRMFILE_PROCESS(P_INST_CODE_IN in number,
  P_FILE_NAME_IN in varchar2, P_RESP_MSG_OUT OUT varchar2,
  p_child_partner_id_out out CLOB,p_success_count_out out number,p_failure_count_out out number);

 procedure SERIAL_NUMBER_FILE_PROCESS(P_INST_CODE_IN in number,
  P_FILE_NAME_IN in varchar2, P_RESP_MSG_OUT OUT varchar2);
 
end;
/
show error