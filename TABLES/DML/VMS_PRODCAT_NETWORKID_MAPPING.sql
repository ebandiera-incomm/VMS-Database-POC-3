declare
l_msg varchar2(1000);
l_exp exception;
begin
	for i in (SELECT * FROM vmscms.CMS_PRODNETWORKID_MAPPING) loop
			for j in (select cpc_prod_code,cpc_card_type from vmscms.cms_prod_cattype
					  where cpc_prod_code=i.cpm_prod_code)loop
				begin	  
					insert into vmscms.VMS_PRODCAT_NETWORKID_MAPPING(VPN_INST_CODE,VPN_PROD_CODE,VPN_CARD_TYPE,VPN_NETWORK_ID,VPN_INS_USER,VPN_INS_DATE,VPN_LUPD_USER,VPN_LUPD_DATE) values(i.cpm_inst_code,i.cpm_prod_code,j.cpc_card_type,i.cpm_network_id,1,sysdate,1,sysdate);
				exception
					when others then
						l_msg:='Error while inserting into VMS_PRODCAT_NETWORKID_MAPPING'||substr(sqlerrm,1,200);
					raise l_exp;
				 end;
			end loop;
	end loop;
	commit;
exception
	when l_exp then
		rollback;
		dbms_output.put_line(l_msg);
	when others then
		rollback;
		dbms_output.put_line('Error in main '||substr(sqlerrm,1,200));
end;
/