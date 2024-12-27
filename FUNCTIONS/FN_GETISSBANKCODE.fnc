CREATE OR REPLACE FUNCTION VMSCMS.fn_getIssBankCode(pan in varchar2) return number
is
 /*
  Purpose: To Get Issuer Bank Code
  Created by: M. Saquib Kazi
  Date:  30 July 05
  */

  c_no   number(3);

begin
 begin
  select rpm_part_code
  into c_no
  from rec_partbin_mast
  where rpm_bin_code = substr(pan,1,6);

  return(c_no);
 Exception
  when others then
   return(99);
 End;
end fn_getIssBankCode;
/


