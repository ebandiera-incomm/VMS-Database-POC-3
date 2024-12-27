/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_foreignkeys (fk_name,
                                                      model_id,
                                                      model_ovid,
                                                      object_id,
                                                      ovid,
                                                      import_id,
                                                      child_table_name,
                                                      referred_table_name,
                                                      engineer,
                                                      delete_rule,
                                                      child_table_id,
                                                      child_table_ovid,
                                                      referred_table_id,
                                                      referred_table_ovid,
                                                      referred_key_id,
                                                      referred_key_ovid,
                                                      number_of_columns,
                                                      mandatory,
                                                      transferable,
                                                      in_arc,
                                                      arc_id,
                                                      model_name,
                                                      referred_key_name,
                                                      design_ovid
                                                     )
AS
   SELECT fk_name, model_id, model_ovid, object_id, ovid, import_id,
          child_table_name, referred_table_name, engineer, delete_rule,
          child_table_id, child_table_ovid, referred_table_id,
          referred_table_ovid, referred_key_id, referred_key_ovid,
          number_of_columns, mandatory, transferable, in_arc, arc_id,
          model_name, referred_key_name, design_ovid
     FROM dmrs_foreignkeys;


