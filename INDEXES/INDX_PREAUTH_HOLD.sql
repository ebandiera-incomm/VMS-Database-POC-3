CREATE INDEX vmscms.indx_preauth_hold
   ON vmscms.cms_preauth_transaction (cpt_acct_no,
                                      cpt_preauth_validflag)
   TABLESPACE CMS_BIG_IDX
   ONLINE;