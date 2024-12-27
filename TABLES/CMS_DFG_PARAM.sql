alter table vmscms.CMS_DFG_PARAM add cdp_card_type number(2,0);
update vmscms.cms_dfg_param set cdp_card_type=-1 ;
alter table vmscms.cms_dfg_param drop constraint PK_PARAM_KEY;
declare
  v_cnt number;
begin
  select count(1)
  into v_cnt
  from all_indexes
  where owner='VMSCMS'
  and index_name='PK_PARAM_KEY';
  
  if v_cnt=1 then
      execute immediate 'drop index vmscms.PK_PARAM_KEY';
  end if;
exception
    when others then  
        dbms_output.put_line(sqlerrm);
end;
/

alter table vmscms.cms_dfg_param add constraint PK_PARAM_KEY primary key(CDP_INST_CODE,
CDP_PARAM_KEY,
CDP_PROD_CODE,cdp_card_type);