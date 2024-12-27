CREATE OR REPLACE TRIGGER VMSCMS.TRG_MONITOR_ACCOUNT_BALANCE 
BEFORE INSERT OR UPDATE OF CAM_ACCT_BAL,CAM_LEDGER_BAL ON vmscms.CMS_ACCT_MAST
FOR EACH ROW
declare
  --v_pan raw;
BEGIN

--if ledger balance gets updated to more than 10K log account information and change card status to hotcard
--do not monitor Brooks Smith boat captains cards
--hard coaded account numbers for Brooks boat captains cards per Dave Wilki and Peter Kerin
--14 Apr 2013 added Brook's account

  if nvl(:old.cam_acct_no,:new.cam_acct_no) not in ('0001019220092','0001019220043','0001019220050','0001026161941','0001035252913','0001005866866','0001019220043','0001035262839','0001035262847','0001035262821','0001031328303')
    then
    --first check if the balance is more than 10K
    --most transactions it is not more than 10K and it will help with the performance
    if (:new.cam_acct_bal>10005 or :new.cam_ledger_bal>10005) then
    --07 Feb 2014
    --for JH accounts the limit should be 20000
    if substr(nvl(:old.cam_acct_no,:new.cam_acct_no),1,3)='224' and (:new.cam_acct_bal>20000 or :new.cam_ledger_bal>20000) then
      insert into vmscms.monitor_account_balance
        ( cam_acct_id,
          cam_acct_no,
          old_cam_acct_bal,
          new_cam_acct_bal,
          old_cam_ledger_bal,
          new_cam_ledger_bal,
          insert_date )
      values
        ( nvl(:old.cam_acct_id,:new.cam_acct_id),
          nvl(:old.cam_acct_no,:new.cam_acct_no),
          :old.cam_acct_bal,
          :new.cam_acct_bal,
          :old.cam_ledger_bal,
          :new.cam_ledger_bal,
          sysdate);

      update vmscms.cms_appl_pan set cap_card_stat=case when cap_card_stat NOT IN ('0','9') THEN  '11'  else cap_card_stat END where cap_acct_no= nvl(:old.cam_acct_no,:new.cam_acct_no);
      elsif substr(nvl(:old.cam_acct_no,:new.cam_acct_no),1,3)='862' and (:new.cam_acct_bal>15000 or :new.cam_ledger_bal>15000) then
      insert into vmscms.monitor_account_balance
      ( cam_acct_id,
        cam_acct_no,
        old_cam_acct_bal,
        new_cam_acct_bal,
        old_cam_ledger_bal,
        new_cam_ledger_bal,
        insert_date )
      values
      ( nvl(:old.cam_acct_id,:new.cam_acct_id),
        nvl(:old.cam_acct_no,:new.cam_acct_no),
        :old.cam_acct_bal,
        :new.cam_acct_bal,
        :old.cam_ledger_bal,
        :new.cam_ledger_bal,
        sysdate);
      update vmscms.cms_appl_pan set cap_card_stat=case when cap_card_stat NOT IN ('0','9') THEN  '11'  else cap_card_stat END where cap_acct_no= nvl(:old.cam_acct_no,:new.cam_acct_no);
    --07 Feb 2014
    --for everything other than JH accounts the limit should be 10005
    elsif substr(nvl(:old.cam_acct_no,:new.cam_acct_no),1,3) not in('224','862') and (:new.cam_acct_bal>10005 or :new.cam_ledger_bal>10005) then
      insert into vmscms.monitor_account_balance
      ( cam_acct_id,
        cam_acct_no,
        old_cam_acct_bal,
        new_cam_acct_bal,
        old_cam_ledger_bal,
        new_cam_ledger_bal,
        insert_date )
      values
      ( nvl(:old.cam_acct_id,:new.cam_acct_id),
        nvl(:old.cam_acct_no,:new.cam_acct_no),
        :old.cam_acct_bal,
        :new.cam_acct_bal,
        :old.cam_ledger_bal,
        :new.cam_ledger_bal,
        sysdate);
      update vmscms.cms_appl_pan set cap_card_stat=case when cap_card_stat NOT IN ('0','9') THEN  '11'  else cap_card_stat END where cap_acct_no= nvl(:old.cam_acct_no,:new.cam_acct_no);
   end if;
  end if;
 end if;
END;
/
show error