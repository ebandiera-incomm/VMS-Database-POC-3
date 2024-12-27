/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_res_party_elements (responsible_party_id,
                                                             responsible_party_ovid,
                                                             responsible_party_name,
                                                             element_id,
                                                             element_ovid,
                                                             element_name,
                                                             element_type,
                                                             design_ovid
                                                            )
AS
   SELECT responsible_party_id, responsible_party_ovid,
          responsible_party_name, element_id, element_ovid, element_name,
          element_type, design_ovid
     FROM dmrs_res_party_elements;


