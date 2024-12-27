create or replace 
TRIGGER vmscms.trg_monitor_account_balance
  BEFORE INSERT OR UPDATE OF cam_acct_bal, cam_ledger_bal ON "VMSCMS"."CMS_ACCT_MAST_EBR"
  FOR EACH ROW
DECLARE
  --v_pan raw;
BEGIN

  --if ledger balance gets updated to more than 10K log account information and change card status to hotcard
  --do not monitor Brooks Smith boat captains cards
  --hard coaded account numbers for Brooks boat captains cards per Dave Wilki and Peter Kerin
  --14 Apr 2013 added Brook's account

  IF nvl(:old.cam_acct_no, :new.cam_acct_no) NOT IN
     ('0001019220092',
      '0001019220043',
      '0001019220050',
      '0001026161941',
      '0001035252913',
      '0001005866866',
      '0001019220043',
      '0001035262839',
      '0001035262847',
      '0001035262821',
      '0001031328303') THEN
    --first check if the balance is more than 10K
    --most transactions it is not more than 10K and it will help with the performance
    IF (:new.cam_acct_bal > 10005 OR :new.cam_ledger_bal > 10005) THEN
      --07 Feb 2014
      --for JH accounts the limit should be 20000
      IF substr(nvl(:old.cam_acct_no, :new.cam_acct_no), 1, 3) = '224' AND
         (:new.cam_acct_bal > 20000 OR :new.cam_ledger_bal > 20000) THEN
        INSERT INTO vmscms.monitor_account_balance
          (cam_acct_id,
           cam_acct_no,
           old_cam_acct_bal,
           new_cam_acct_bal,
           old_cam_ledger_bal,
           new_cam_ledger_bal,
           insert_date)
        VALUES
          (nvl(:old.cam_acct_id, :new.cam_acct_id),
           nvl(:old.cam_acct_no, :new.cam_acct_no),
           :old.cam_acct_bal,
           :new.cam_acct_bal,
           :old.cam_ledger_bal,
           :new.cam_ledger_bal,
           SYSDATE);

        UPDATE vmscms.cms_appl_pan
           SET cap_card_stat = CASE
                                 WHEN cap_card_stat NOT IN ('0', '9') THEN
                                  '11'
                                 ELSE
                                  cap_card_stat
                               END
         WHERE cap_acct_no = nvl(:old.cam_acct_no, :new.cam_acct_no);
      ELSIF substr(nvl(:old.cam_acct_no, :new.cam_acct_no), 1, 3) IN
            ('862', '821', '002', '004', '921') AND
            (:new.cam_acct_bal > 15000 OR :new.cam_ledger_bal > 15000) THEN
        INSERT INTO vmscms.monitor_account_balance
          (cam_acct_id,
           cam_acct_no,
           old_cam_acct_bal,
           new_cam_acct_bal,
           old_cam_ledger_bal,
           new_cam_ledger_bal,
           insert_date)
        VALUES
          (nvl(:old.cam_acct_id, :new.cam_acct_id),
           nvl(:old.cam_acct_no, :new.cam_acct_no),
           :old.cam_acct_bal,
           :new.cam_acct_bal,
           :old.cam_ledger_bal,
           :new.cam_ledger_bal,
           SYSDATE);
        UPDATE vmscms.cms_appl_pan
           SET cap_card_stat = CASE
                                 WHEN cap_card_stat NOT IN ('0', '9') THEN
                                  '11'
                                 ELSE
                                  cap_card_stat
                               END
         WHERE cap_acct_no = nvl(:old.cam_acct_no, :new.cam_acct_no);
        --07 Feb 2014
        --- Added for meridian products Sn
      ELSIF substr(nvl(:old.cam_acct_no, :new.cam_acct_no), 1, 3) IN ('162','340') AND	--'162' Added for kyck prod change VMS-7188 
            (:new.cam_acct_bal > 99999 OR :new.cam_ledger_bal > 99999) THEN
        INSERT INTO vmscms.monitor_account_balance
          (cam_acct_id,
           cam_acct_no,
           old_cam_acct_bal,
           new_cam_acct_bal,
           old_cam_ledger_bal,
           new_cam_ledger_bal,
           insert_date)
        VALUES
          (nvl(:old.cam_acct_id, :new.cam_acct_id),
           nvl(:old.cam_acct_no, :new.cam_acct_no),
           :old.cam_acct_bal,
           :new.cam_acct_bal,
           :old.cam_ledger_bal,
           :new.cam_ledger_bal,
           SYSDATE);
        UPDATE vmscms.cms_appl_pan
           SET cap_card_stat = CASE
                                 WHEN cap_card_stat NOT IN ('0', '9') THEN
                                  '11'
                                 ELSE
                                  cap_card_stat
                               END
         WHERE cap_acct_no = nvl(:old.cam_acct_no, :new.cam_acct_no);
      ELSIF substr(nvl(:old.cam_acct_no, :new.cam_acct_no), 1, 3) = '276' AND
            (:new.cam_acct_bal > 25000 OR :new.cam_ledger_bal > 25000) THEN
        INSERT INTO vmscms.monitor_account_balance
          (cam_acct_id,
           cam_acct_no,
           old_cam_acct_bal,
           new_cam_acct_bal,
           old_cam_ledger_bal,
           new_cam_ledger_bal,
           insert_date)
        VALUES
          (nvl(:old.cam_acct_id, :new.cam_acct_id),
           nvl(:old.cam_acct_no, :new.cam_acct_no),
           :old.cam_acct_bal,
           :new.cam_acct_bal,
           :old.cam_ledger_bal,
           :new.cam_ledger_bal,
           SYSDATE);
        UPDATE vmscms.cms_appl_pan
           SET cap_card_stat = CASE
                                 WHEN cap_card_stat NOT IN ('0', '9') THEN
                                  '11'
                                 ELSE
                                  cap_card_stat
                               END
         WHERE cap_acct_no = nvl(:old.cam_acct_no, :new.cam_acct_no);

        --- Added for meridian products En
        --for everything other than JH accounts the limit should be 10005
      ELSIF substr(nvl(:old.cam_acct_no, :new.cam_acct_no), 1, 3) NOT IN
            ('276', '340', '162', '224', '862', '821', '002', '004', '921', '040') AND    --'162' Added for kyck prod change VMS-7188 
            (:new.cam_acct_bal > 10005 OR :new.cam_ledger_bal > 10005) THEN
        INSERT INTO vmscms.monitor_account_balance
          (cam_acct_id,
           cam_acct_no,
           old_cam_acct_bal,
           new_cam_acct_bal,
           old_cam_ledger_bal,
           new_cam_ledger_bal,
           insert_date)
        VALUES
          (nvl(:old.cam_acct_id, :new.cam_acct_id),
           nvl(:old.cam_acct_no, :new.cam_acct_no),
           :old.cam_acct_bal,
           :new.cam_acct_bal,
           :old.cam_ledger_bal,
           :new.cam_ledger_bal,
           SYSDATE);
        UPDATE vmscms.cms_appl_pan
           SET cap_card_stat = CASE
                                 WHEN cap_card_stat NOT IN ('0', '9') THEN
                                  '11'
                                 ELSE
                                  cap_card_stat
                               END
         WHERE cap_acct_no = nvl(:old.cam_acct_no, :new.cam_acct_no);
      END IF;
    END IF;
  END IF;
END;
/
SHOW ERROR