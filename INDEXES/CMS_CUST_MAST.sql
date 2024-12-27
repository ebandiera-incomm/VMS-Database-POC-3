SET TIME ON TIMING ON

create index vmscms.indx_ccm_ssn_func on vmscms.cms_cust_mast(SUBSTR (ccm_ssn, LENGTH (ccm_ssn) - 3)) tablespace CMS_BIG_IDX ONLINE;

SET TIME OFF TIMING OFF;