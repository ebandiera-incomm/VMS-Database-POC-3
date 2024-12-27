declare
l_main_exp exception;
l_cnt  number;
v_profile_code vmscms.cms_profile_mast.cpm_profile_code%type;
v_prod_profile_code vmscms.cms_profile_mast.cpm_profile_code%type;
L_MSG varchar2(1000);
l_check_flag varchar2(2);
l_param_value vmscms.cms_bin_param.cbp_param_value%type;
begin
	for i in (select cpc_profile_code,cpc_prod_code,cpc_card_type from vmscms.cms_prod_cattype)
	loop
  
   begin
			select cpm_profile_code into 
			v_prod_profile_code 	
			from vmscms.cms_prod_mast
			where cpm_prod_code=i.cpc_prod_code;
		exception
			when others then
					l_msg:='Error while selecting profile code from prod mast'||substr(sqlerrm,1,200);
				RAISE L_MAIN_EXP;
		end;
    
    l_check_flag:='Y';
    
    for j in (select CBP_PARAM_NAME,CBP_PARAM_VALUE
                    from vmscms.CMS_BIN_PARAM where CBP_PROFILE_CODE=I.CPC_PROFILE_CODE and CBP_PARAM_NAME in ('Max Card Balance','Validity','Validity Period') )
      loop
				begin
                    select distinct CBP_PARAM_VALUE into l_param_value
                    from vmscms.CMS_BIN_PARAM where CBP_PROFILE_CODE=V_PROD_PROFILE_CODE
                    and CBP_PARAM_NAME=j.CBP_PARAM_NAME;
			   exception
					when no_data_found then
					    l_check_flag:='N';
						exit;
					when others then
						l_msg:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
						RAISE L_MAIN_EXP;
			   end;
                    
               if nvl(l_PARAM_VALUE,'-1') <>nvl(j.CBP_PARAM_VALUE,'-1') then
                   l_check_flag:='N';
                   EXIT;
               end if;
		end LOOP; 
       
     if l_check_flag='Y' then
       begin
		
			update vmscms.cms_prod_cattype
			set cpc_profile_code=v_prod_profile_code
			where cpc_inst_code=1
			and cpc_prod_code=i.cpc_prod_code
			and cpc_card_type=i.cpc_card_type;
		exception
				when others then
					l_msg:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
					RAISE L_MAIN_EXP;
		end;
	else
  
        begin
		--select 'P'||vmscms.seq_profile.nextval into v_profile_code from dual;
         v_profile_code:='P'||vmscms.seq_profile.nextval;
        exception
          when others then
            l_msg:='Error while forming profile code'||substr(sqlerrm,1,200);
                raise l_main_exp;
          end;
          
        begin
          insert into vmscms.cms_profile_mast(cpm_profile_code,cpm_profile_name,cpm_ins_user,
          cpm_ins_date,cpm_lupd_user,cpm_lupd_date,cpm_inst_code,cpm_profile_level)
          values(v_profile_code,(select cpm_profile_name||'_'||i.cpc_prod_code||'_'||i.cpc_card_type||'_'||v_profile_code from vmscms.cms_profile_mast 
          where cpm_profile_code=i.cpc_profile_code),1,sysdate,1,sysdate,1,'P');
        exception
            when others then
              l_msg:='Error while inserting into profile mast'||substr(sqlerrm,1,200);
              raise l_main_exp;
        end;
		
        for j in (select cbp_param_type,cbp_param_name,cbp_param_value
                  from vmscms.cms_bin_param where cbp_profile_code=I.cpc_profile_code and CBP_PARAM_NAME in ('Max Card Balance','Validity','Validity Period')
                  )
        loop
          begin
            insert into vmscms.cms_bin_param(cbp_profile_code,cbp_param_type,cbp_param_name,cbp_param_value,cbp_ins_user,cbp_ins_date,cbp_lupd_user,cbp_lupd_date,cbp_inst_code) values
            (v_profile_code,j.cbp_param_type,j.cbp_param_name,j.cbp_param_value,1,sysdate,1,sysdate,1);
          exception
            when others then
              l_msg:='Error while inserting into cms_bin_param'||substr(sqlerrm,1,200);
            raise l_main_exp;
          end;
        end loop;
		
 		
          for k in (select cbp_param_type,cbp_param_name,cbp_param_value from vmscms.cms_bin_param where cbp_profile_code=v_prod_profile_code) 
          loop
          begin
              
              select count(1)
              into l_cnt
              from vmscms.cms_bin_param
              where cbp_profile_code=v_profile_code
              and cbp_param_name=k.cbp_param_name;
              
              if l_cnt=0 then
                insert into vmscms.cms_bin_param(cbp_profile_code,cbp_param_type,
                cbp_param_name,cbp_param_value,
                cbp_ins_user,cbp_ins_date,cbp_lupd_user,
                cbp_lupd_date,cbp_inst_code) values(v_profile_code,
                k.cbp_param_type,k.cbp_param_name,k.cbp_param_value,1,sysdate,1,sysdate,1);
              end if;
          exception
              when others then
                  l_msg:='Error while inserting into cms_bin_param for product profile code'||substr(sqlerrm,1,200);
              raise l_main_exp;
          end;
          end loop;
		
          begin
            insert into vmscms.cms_acct_construct(cac_inst_code,cac_profile_code,cac_field_name,cac_start,cac_length,cac_value,cac_tot_length,cac_order_by,cac_start_from,cac_lupd_date,cac_lupd_user,cac_ins_date,cac_ins_user)
            select cac_inst_code,v_profile_code,cac_field_name,cac_start,cac_length,cac_value,cac_tot_length,cac_order_by,cac_start_from,sysdate,1,sysdate,1
            from vmscms.cms_acct_construct where cac_profile_code=v_prod_profile_code;
           exception
              when others then
                l_msg:='Error while inserting into cms_acct_construct'||substr(sqlerrm,1,200);
                raise l_main_exp;
          end;
		
         begin
            insert into vmscms.cms_emboss_file_format(ceff_profile_code,ceff_emboss_line1,ceff_emboss_line2,ceff_emboss_line3,ceff_emboss_line4,ceff_track1_data,ceff_track2_data,ceff_indent_line,ceff_ins_user,ceff_ins_date,ceff_del_flag,cef_lupd_date,cef_inst_code,cef_lupd_user,ceff_ptrack2_data,ceff_format_flag,ceff_track2_pattern,ceff_track1_pattern,ceff_alttrack1_pattern,ceff_alttrack1_data,ceff_alttrack2_pattern,ceff_alttrack2_data)
              select v_profile_code,ceff_emboss_line1,ceff_emboss_line2,ceff_emboss_line3,ceff_emboss_line4,ceff_track1_data,ceff_track2_data,ceff_indent_line,1,sysdate,ceff_del_flag,sysdate,cef_inst_code,1,ceff_ptrack2_data,ceff_format_flag,ceff_track2_pattern,ceff_track1_pattern,ceff_alttrack1_pattern,ceff_alttrack1_data,ceff_alttrack2_pattern,ceff_alttrack2_data
              from vmscms.cms_emboss_file_format where ceff_profile_code=v_prod_profile_code;
        exception
            when others then
              l_msg:='Error while inserting into cms_emboss_file_format'||substr(sqlerrm,1,200);
              raise l_main_exp;
        end;
		
        begin
          insert into vmscms.cms_pan_construct(cpc_inst_code,cpc_profile_code,cpc_field_name,cpc_start,cpc_length,cpc_value,cpc_order_by,cpc_start_from,cpc_lupd_date,cpc_lupd_user,cpc_ins_date,cpc_ins_user)
            select cpc_inst_code,v_profile_code,cpc_field_name,cpc_start,cpc_length,cpc_value,cpc_order_by,cpc_start_from,sysdate,1,sysdate,1 from vmscms.cms_pan_construct where cpc_profile_code=v_prod_profile_code;
          
        exception
            when others then
              l_msg:='Error while inserting into cms_pan_construct'||substr(sqlerrm,1,200);
              raise l_main_exp;
        end;
		
          begin
          insert into vmscms.cms_savingsacct_construct(csc_inst_code,csc_profile_code,csc_field_name,csc_start,csc_length,csc_value,csc_tot_length,csc_order_by,csc_start_from,csc_lupd_date,csc_lupd_user,csc_ins_date,csc_ins_user)
            select csc_inst_code,v_profile_code,csc_field_name,csc_start,csc_length,csc_value,csc_tot_length,csc_order_by,csc_start_from,sysdate,1,sysdate,1 from vmscms.cms_savingsacct_construct
            where csc_profile_code=v_prod_profile_code;
          exception
            when others then
              l_msg:='Error while inserting into cms_savingsacct_construct'||substr(sqlerrm,1,200);
              raise l_main_exp;
        end;
        
        begin
        
          update vmscms.cms_prod_cattype
          set cpc_profile_code=v_profile_code
          where cpc_inst_code=1
          and cpc_prod_code=i.cpc_prod_code
          and cpc_card_type=i.cpc_card_type;
        exception
            when others then
              l_msg:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
              raise l_main_exp;
        end;

   
   end if;
   commit;
  end LOOP;

exception
		when l_main_exp then
				dbms_output.put_line(l_msg);
				rollback;
	     when others then
				dbms_output.put_line('Error in main'||substr(sqlerrm,1,200));
				rollback;
end;
/



declare
l_exp exception;
l_msg varchar2(1000);
begin

		for i in (SELECT DISTINCT CBP_PROFILE_CODE FROM vmscms.CMS_BIN_PARAM,vmscms.CMS_PROFILE_MAST WHERE 	CPM_PROFILE_CODE=CBP_PROFILE_CODE
				AND CPM_PROFILE_LEVEL='P') loop
		begin
				INSERT INTO vmscms.CMS_BIN_PARAM(CBP_INST_CODE,CBP_INS_DATE,CBP_INS_USER,
				CBP_LUPD_DATE,CBP_LUPD_USER,CBP_PARAM_NAME,CBP_PARAM_TYPE,CBP_PARAM_VALUE,CBP_PROFILE_CODE)
				VALUES(1,SYSDATE,1,SYSDATE,1,'ExpiryDate Regeneration Activation','','N',i.CBP_PROFILE_CODE);
				
				INSERT INTO vmscms.CMS_BIN_PARAM(CBP_INST_CODE,CBP_INS_DATE,CBP_INS_USER,
				CBP_LUPD_DATE,CBP_LUPD_USER,CBP_PARAM_NAME,CBP_PARAM_TYPE,CBP_PARAM_VALUE,CBP_PROFILE_CODE)
				VALUES(1,SYSDATE,1,SYSDATE,1,'MonthEnd CardExpiry Date','','N',i.CBP_PROFILE_CODE);
				
				INSERT INTO vmscms.CMS_BIN_PARAM(CBP_INST_CODE,CBP_INS_DATE,CBP_INS_USER,
				CBP_LUPD_DATE,CBP_LUPD_USER,CBP_PARAM_NAME,CBP_PARAM_TYPE,CBP_PARAM_VALUE,CBP_PROFILE_CODE)
				VALUES(1,SYSDATE,1,SYSDATE,1,'Virtual Card EncrKey','','N',i.CBP_PROFILE_CODE);
		exception
			when others then
					l_msg:='Error while insering into cms_bin_param'||substr(sqlerrm,1,200);
					raise l_exp;
		end;
		end loop;
		
		commit;
exception
		when l_exp then
			 rollback;
			 dbms_output.put_line(l_msg);
		when others then
			rollback;
			dbms_output.put_line('Error in main'||sqlerrm);
end;
/

