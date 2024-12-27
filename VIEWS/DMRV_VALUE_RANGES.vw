/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_value_ranges (dataelement_id,
                                                       dataelement_ovid,
                                                       TYPE,
                                                       SEQUENCE,
                                                       begin_value,
                                                       end_value,
                                                       short_description,
                                                       container_id,
                                                       container_ovid,
                                                       container_name,
                                                       dataelement_name,
                                                       design_ovid
                                                      )
AS
   SELECT dataelement_id, dataelement_ovid, TYPE, SEQUENCE, begin_value,
          end_value, short_description, container_id, container_ovid,
          container_name, dataelement_name, design_ovid
     FROM dmrs_value_ranges;


