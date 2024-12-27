CREATE OR REPLACE TRIGGER VMSCMS.trg_acctclosehist_std
before insert
on cms_acctclose_hist
for each row
begin
:new.cah_ins_date := sysdate;
end;
/


