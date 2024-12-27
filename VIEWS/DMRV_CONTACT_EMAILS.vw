/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_contact_emails (contact_id,
                                                         contact_ovid,
                                                         contact_name,
                                                         email_id,
                                                         email_ovid,
                                                         email_name,
                                                         design_ovid
                                                        )
AS
   SELECT contact_id, contact_ovid, contact_name, email_id, email_ovid,
          email_name, design_ovid
     FROM dmrs_contact_emails;


