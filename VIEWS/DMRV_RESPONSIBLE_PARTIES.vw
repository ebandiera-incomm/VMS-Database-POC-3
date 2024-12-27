/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_responsible_parties (responsible_party_id,
                                                              responsible_party_ovid,
                                                              responsible_party_name,
                                                              business_info_id,
                                                              business_info_ovid,
                                                              business_info_name,
                                                              parent_id,
                                                              parent_ovid,
                                                              parent_name,
                                                              responsibility,
                                                              design_ovid
                                                             )
AS
   SELECT responsible_party_id, responsible_party_ovid,
          responsible_party_name, business_info_id, business_info_ovid,
          business_info_name, parent_id, parent_ovid, parent_name,
          responsibility, design_ovid
     FROM dmrs_responsible_parties;


