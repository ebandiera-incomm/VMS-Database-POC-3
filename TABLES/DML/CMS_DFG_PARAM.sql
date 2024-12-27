declare
l_msg varchar2(1000);
l_exp exception;
BEGIN

	for  pc in (select cdp_prod_code,cdp_inst_code,cdp_param_key,cdp_param_value,
			  cdp_inst_user,cdp_mandarory_flag from vmscms.cms_dfg_param)
	loop
	 for cattype in (select cpc_card_type from vmscms.cms_prod_cattype where cpc_prod_code=pc.cdp_prod_code) 
	  loop
		begin
		 insert into vmscms.cms_dfg_param(cdp_inst_code,cdp_param_key,cdp_param_value,cdp_inst_user,CDP_INS_DATE,cdp_mandarory_flag,CDP_PROD_CODE,cdp_card_type,CDP_LUPD_DATE,CDP_LUPD_USER)
		  values(pc.cdp_inst_code,pc.cdp_param_key,pc.cdp_param_value,pc.cdp_inst_user,sysdate,pc.cdp_mandarory_flag,pc.cdp_prod_code,cattype.cpc_card_type,sysdate,pc.cdp_inst_user);
		exception
			 when others then
				l_msg:='Error while inserting into vmscms.cms_dfg_param'||substr(sqlerrm,1,200);
				raise l_exp;
		end;
		   
	  end loop;
	 end loop;
 
	 begin
	 delete from vmscms.cms_dfg_param where cdp_card_type=-1;
	 exception
	   when others then
		l_msg:='Error while deleting from vmscms.cms_dfg_param'||substr(sqlerrm,1,200);
		raise l_exp;
	  end;
  
  commit;
exception
    when l_exp then
        dbms_output.put_line(l_msg);
        rollback;
    when others then
        rollback;
        dbms_output.put_line('Error in main'||substr(sqlerrm,1,200));
end;
/