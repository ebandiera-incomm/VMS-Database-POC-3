CREATE OR REPLACE FUNCTION VMSCMS.fn_getIssBankCardType(pan in varchar2) return varchar2
is

 /*
  Purpose: To Get Issuer Bank's Card Type
  Created by: M. Saquib Kazi
  Date:  30 July 05
  */

  c_no   varchar2(1);

begin
 begin
  select rpm_card_type
  into c_no
  from rec_partbin_mast
  where rpm_bin_code = substr(pan,1,6);

  return(c_no);
 exception
  when others then
  return('N');
 end;
end fn_getIssBankCardType;
/


