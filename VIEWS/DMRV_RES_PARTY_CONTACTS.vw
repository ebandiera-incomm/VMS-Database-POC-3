/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_res_party_contacts (responsible_party_id,
                                                             responsible_party_ovid,
                                                             responsible_party_name,
                                                             contact_id,
                                                             contact_ovid,
                                                             contact_name,
                                                             design_ovid
                                                            )
AS
   SELECT responsible_party_id, responsible_party_ovid,
          responsible_party_name, contact_id, contact_ovid, contact_name,
          design_ovid
     FROM dmrs_res_party_contacts;


