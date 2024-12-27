/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_document_elements (document_id,
                                                            document_ovid,
                                                            document_name,
                                                            element_id,
                                                            element_ovid,
                                                            element_name,
                                                            element_type,
                                                            design_ovid
                                                           )
AS
   SELECT document_id, document_ovid, document_name, element_id, element_ovid,
          element_name, element_type, design_ovid
     FROM dmrs_document_elements;


