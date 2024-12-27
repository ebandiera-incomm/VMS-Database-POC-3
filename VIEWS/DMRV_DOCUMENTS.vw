/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_documents (document_id,
                                                    document_ovid,
                                                    document_name,
                                                    business_info_id,
                                                    business_info_ovid,
                                                    business_info_name,
                                                    parent_id,
                                                    parent_ovid,
                                                    parent_name,
                                                    doc_reference,
                                                    doc_type,
                                                    design_ovid
                                                   )
AS
   SELECT document_id, document_ovid, document_name, business_info_id,
          business_info_ovid, business_info_name, parent_id, parent_ovid,
          parent_name, doc_reference, doc_type, design_ovid
     FROM dmrs_documents;


