/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_large_text (object_id,
                                                     ovid,
                                                     object_name,
                                                     TYPE,
                                                     text,
                                                     design_ovid
                                                    )
AS
   SELECT object_id, ovid, object_name, TYPE, text, design_ovid
     FROM dmrs_large_text;


