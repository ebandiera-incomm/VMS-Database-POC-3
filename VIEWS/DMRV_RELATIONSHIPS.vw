/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_relationships (relationship_name,
                                                        model_id,
                                                        model_ovid,
                                                        object_id,
                                                        ovid,
                                                        import_id,
                                                        source_entity_name,
                                                        target_entity_name,
                                                        source_label,
                                                        target_label,
                                                        sourceto_target_cardinality,
                                                        targetto_source_cardinality,
                                                        source_optional,
                                                        target_optional,
                                                        dominant_role,
                                                        identifying,
                                                        source_id,
                                                        source_ovid,
                                                        target_id,
                                                        target_ovid,
                                                        number_of_attributes,
                                                        transferable,
                                                        in_arc,
                                                        arc_id,
                                                        model_name,
                                                        design_ovid
                                                       )
AS
   SELECT relationship_name, model_id, model_ovid, object_id, ovid, import_id,
          source_entity_name, target_entity_name, source_label, target_label,
          sourceto_target_cardinality, targetto_source_cardinality,
          source_optional, target_optional, dominant_role, identifying,
          source_id, source_ovid, target_id, target_ovid,
          number_of_attributes, transferable, in_arc, arc_id, model_name,
          design_ovid
     FROM dmrs_relationships;


