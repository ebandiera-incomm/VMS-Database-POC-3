/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_ragged_hier_link_attrs (ragged_hier_link_id,
                                                                 ragged_hier_link_name,
                                                                 ragged_hier_link_ovid,
                                                                 attribute_id,
                                                                 attribute_name,
                                                                 attribute_ovid,
                                                                 design_ovid
                                                                )
AS
   SELECT ragged_hier_link_id, ragged_hier_link_name, ragged_hier_link_ovid,
          attribute_id, attribute_name, attribute_ovid, design_ovid
     FROM dmrs_ragged_hier_link_attrs;


