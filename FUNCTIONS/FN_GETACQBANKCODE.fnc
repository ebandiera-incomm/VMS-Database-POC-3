CREATE OR REPLACE FUNCTION VMSCMS.fn_getAcqBankCode(AcqId in varchar2) return number
is
 /*
  Purpose: To Get Acquirer Bank Code
  Created by: M. Saquib Kazi
  Date:  30 July 05
  */

  c_no   number(3);

begin
 begin
  select ram_part_code
  into c_no
  from rec_partacq_mast
  where to_number(RAM_ACQ_CODE) = to_number(AcqId);

  return(c_no);
 exception
  when no_data_found then
   begin
    select ram_part_code
    into c_no
    from rec_partacq_mast
    where to_number(RAM_ACQ_CODE) = substr(to_number(AcqId),1,6);

    return(c_no);
   exception
    when others then
     return(99);
   end;
  when others then
   return(99);
 end;
end fn_getAcqBankCode;
/


