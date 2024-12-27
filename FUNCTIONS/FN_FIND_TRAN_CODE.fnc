CREATE OR REPLACE FUNCTION VMSCMS.fn_find_tran_code (lp_msg_type IN varchar2) return varchar2
IS
BEGIN		--begin lp1
  if ( lp_msg_type='0220' or substr(lp_msg_type,1,2)='04' ) then
    return('27');
  else
    return('07');
  end if;
EXCEPTION	--excp of lp1
	WHEN OTHERS THEN
    return('07');
END;		--end lp1
/


show error