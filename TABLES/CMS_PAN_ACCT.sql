--Disable FK Constraints In CMS_PAN_ACCT Table
ALTER TABLE vmscms.cms_pan_acct DISABLE CONSTRAINT fk_panacct_applpan;
ALTER TABLE vmscms.cms_pan_acct DISABLE CONSTRAINT fk_panacct_custacct;
ALTER TABLE vmscms.cms_pan_acct DISABLE CONSTRAINT fk_panacct_usermast1;
ALTER TABLE vmscms.cms_pan_acct DISABLE CONSTRAINT fk_panacct_usermast2;