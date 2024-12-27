/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_domain_value_ranges (domain_id,
                                                              domain_ovid,
                                                              SEQUENCE,
                                                              begin_value,
                                                              end_value,
                                                              short_description,
                                                              domain_name,
                                                              design_ovid
                                                             )
AS
   SELECT domain_id, domain_ovid, SEQUENCE, begin_value, end_value,
          short_description, domain_name, design_ovid
     FROM dmrs_domain_value_ranges;


