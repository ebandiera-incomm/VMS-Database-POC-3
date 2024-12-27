/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_emails (email_id,
                                                 email_ovid,
                                                 email_name,
                                                 business_info_id,
                                                 business_info_ovid,
                                                 business_info_name,
                                                 email_address,
                                                 email_type,
                                                 design_ovid
                                                )
AS
   SELECT email_id, email_ovid, email_name, business_info_id,
          business_info_ovid, business_info_name, email_address, email_type,
          design_ovid
     FROM dmrs_emails;


