UPDATE vmscms.CMS_ISO_REQMAPPING SET CIR_ISO_MRC='*' WHERE CIR_ISO_MRC IS NULL;

ALTER TABLE vmscms.CMS_ISO_REQMAPPING DROP CONSTRAINT PK_ISO_REQMAPPING;

declare
  v_cnt number;
begin
  select count(1)
  into v_cnt
  from all_indexes
  where owner='VMSCMS'
  and index_name='PK_ISO_REQMAPPING';
  
  if v_cnt=1 then
      execute immediate 'drop index vmscms.pk_iso_reqmapping';
  end if;
exception
    when others then  
        dbms_output.put_line(sqlerrm);
end;
/
 
ALTER TABLE VMSCMS.CMS_ISO_REQMAPPING ADD CONSTRAINT PK_ISO_REQMAPPING 
PRIMARY KEY (CIR_INST_CODE, CIR_MSG_TYPE, CIR_TRAN_CDE, CIR_DELIVERY_CHANNEL,
CIR_ISO_FUNC_CDE, CIR_ISO_TRAN_CDE,CIR_ISO_MRC);