declare
l_msg varchar2(1000);
l_exp exception;
begin
	for i in (SELECT * FROM vmscms.CMS_PROD_THRESHOLD) loop
			for j in (select cpc_prod_code,cpc_card_type from vmscms.cms_prod_cattype
					  where cpc_prod_code=i.cpt_prod_code)loop
			begin  
				insert into vmscms.VMS_PRODCAT_THRESHOLD(VPT_INST_CODE,VPT_PROD_CODE,VPT_CARD_TYPE,VPT_PROD_THRESHOLD,VPT_INS_USER,VPT_INS_DATE,VPT_LUPD_USER,VPT_LUPD_DATE) values(i.cpt_inst_code,i.cpt_prod_code,j.cpc_card_type,i.cpt_prod_threshold,1,sysdate,1,sysdate);
			exception
				when others then
					l_msg:='Error while inserting into VMS_PRODCAT_THRESHOLD'||substr(sqlerrm,1,200);
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