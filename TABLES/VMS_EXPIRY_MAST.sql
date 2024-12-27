alter table vmscms.vms_expiry_mast add(vem_prod_code varchar2(20),vem_prod_cattype number(20));

alter table vmscms.vms_expiry_mast drop constraint pk_month_id;


declare
  v_cnt number;
begin
    select count(1) into v_cnt
    from all_indexes
    where owner='VMSCMS'
    and index_name='PK_MONTH_ID';
    
    if v_cnt=1 then
       
        execute immediate 'drop index vmscms.PK_MONTH_ID';
    end if;
exception
    when others then
        dbms_output.put_line('Error while dropping index'||sqlerrm);
end;
/

update vmscms.vms_expiry_mast
set vem_prod_code='0',vem_prod_cattype=0;

alter table vmscms.vms_expiry_mast add 
constraint pk_prod_cattype_month_id primary key(vem_prod_code,vem_prod_cattype,vem_month_id);