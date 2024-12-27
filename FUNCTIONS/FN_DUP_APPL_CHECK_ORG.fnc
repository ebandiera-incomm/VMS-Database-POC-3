CREATE OR REPLACE FUNCTION VMSCMS.FN_DUP_APPL_CHECK_ORG(acc_no IN VARCHAR2)
RETURN VARCHAR2 AS dup_check VARCHAR(1) ;
dup_count NUMBER(1) := 0;
BEGIN -- main begin 
--if appl_mode = 'U' then -- upload mode, perform check for single page entry
  begin -- 
	-- first check the caf_info_temp table.... 
dbms_output.put_line('Account number in function :' ||acc_no);
	select count(1) into dup_count 
	from   cms_caf_info_temp 
	where cci_seg31_num = rpad(acc_no,19,' ')
	and    cci_ins_date > (sysdate - 1);
--	where  trim(cci_seg31_num) = trim(acc_no)  -- trim() will result in full table scan...
--	and    trunc(cci_ins_date) = trunc(sysdate);
   -- need to optimize the above query..this will go for full table..	
	if dup_count > 0 then  -- upload already done on this day...application is duplicate..  
	   dup_check := 'T';
--	   return dup_check;
	else -- check the other table for duplicate...  
		select count(1) into dup_count 
		from   cms_caf_info_entry 
		where cci_seg31_num = rpad(acc_no,19,' ')  
  		and    cci_approved != 'E'		     
 		and    cci_ins_date > (sysdate - 1);
--		where  trim(cci_seg31_num) = trim(acc_no)
--		and    trunc(cci_ins_date) = trunc(sysdate);  -- trunc() will result in full table scan..
--   	dbms_output.put_line('Upload' || dup_count);
 		if dup_count > 0 then 
		  dup_check := 'T';
  		else 	  
	 	  dup_check := 'F';
    	end if;
	end if;	 
    return dup_check;	
  exception
  when others then
    dup_check := 'F'; -- ??..
    return dup_check; 	
  end; -- 
END ; -- main end
/


show error