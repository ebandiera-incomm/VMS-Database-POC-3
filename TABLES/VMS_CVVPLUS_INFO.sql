CREATE TABLE vmscms.VMS_CVVPLUS_INFO
(
   vci_cvvplus_token              NUMBER (15),
   VCI_CVVPLUS_ACCT_NO                 VARCHAR2 (100) NOT NULL,
   vci_cvvplus_accountid          VARCHAR2 (100),
   vci_cvvplus_registration_id    VARCHAR2 (100),
   vci_cvvplus_email_contactid    VARCHAR2 (100),
   vci_cvvplus_mobile_contactid   VARCHAR2 (100),
   vci_cvvplus_codeprofile_id     VARCHAR2 (100),
   CONSTRAINT pk_cvvplus_token PRIMARY KEY (vci_cvvplus_token)
);

CREATE INDEX vmscms.indx_cvvplus_accountid ON vmscms.vms_cvvplus_info (vci_cvvplus_accountid);

CREATE UNIQUE INDEX vmscms.indx_cvvplus_acctno ON vmscms.vms_cvvplus_info (VCI_CVVPLUS_ACCT_NO);