declare
l_msg varchar2(1000);
l_exp exception;
begin
		for i in (SELECT * FROM vmscms.CMS_SCORECARD_PRODMAPPING) loop
				for j in (select cpc_prod_code,cpc_card_type from vmscms.cms_prod_cattype
						  where cpc_prod_code=i.csp_prod_code)loop
					begin	  
						insert into vmscms.VMS_SCORECARD_PRODCAT_MAPPING(VSP_INST_CODE,VSP_DELIVERY_CHANNEL,VSP_PROD_CODE,VSP_CARD_TYPE,VSP_SCORECARD_ID,VSP_CIPCARD_STAT,VSP_AVQ_FLAG,VSP_INS_USER,VSP_INS_DATE,VSP_LUPD_USER,VSP_LUPD_DATE) values(i.csp_inst_code,i.csp_delivery_channel,i.csp_prod_code,j.cpc_card_type,i.csp_scorecard_id,i.csp_cipcard_stat,i.csp_avq_flag,1,sysdate,1,sysdate);
					exception
						when others then
							l_msg:='Error while inserting into VMS_SCORECARD_PRODCAT_MAPPING'||substr(sqlerrm,1,200);
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