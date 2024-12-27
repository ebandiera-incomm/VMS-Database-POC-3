/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_rollup_link_attrs (rollup_link_id,
                                                            rollup_link_name,
                                                            rollup_link_ovid,
                                                            attribute_id,
                                                            attribute_name,
                                                            attribute_ovid,
                                                            design_ovid
                                                           )
AS
   SELECT rollup_link_id, rollup_link_name, rollup_link_ovid, attribute_id,
          attribute_name, attribute_ovid, design_ovid
     FROM dmrs_rollup_link_attrs;


