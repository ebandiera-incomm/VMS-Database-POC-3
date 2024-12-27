/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.cms_user_license (cmu_inst_code,
                                                      cmu_max_users
                                                     )
AS
   SELECT "CMU_INST_CODE", "CMU_MAX_USERS"
     FROM cms_max_users;


