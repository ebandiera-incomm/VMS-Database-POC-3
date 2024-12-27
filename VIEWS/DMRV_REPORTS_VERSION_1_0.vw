/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_reports_version_1_0 (dmrs_persistence_version,
                                                              dmrs_reports_version,
                                                              created_on
                                                             )
AS
   SELECT 1.6 dmrs_persistence_version, 1.0 dmrs_reports_version,
          TO_TIMESTAMP ('2012/04/19 19:45:34',
                        'YYYY/MM/DD HH24:MI:SS'
                       ) created_on
     FROM DUAL
          WITH READ ONLY;


