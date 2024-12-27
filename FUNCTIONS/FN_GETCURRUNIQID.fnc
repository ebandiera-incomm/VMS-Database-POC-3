CREATE OR REPLACE FUNCTION VMSCMS.fn_getCurrUniqId(BinNo in varchar2) return number is
--  Result number;
  curr_uniq_id   number(5);
begin
  begin
    select RBC_CURR_UNIQCODE into curr_uniq_id 
    from rec_bin_curr where rbc_inst_bin = BinNo;
    return(curr_uniq_id);
  exception
    when others then
      return(99);
  end;
end fn_getCurrUniqId;
/


