create or replace
PROCEDURE        VMSCMS.SP_CHECK_MERCHANTID (
   prm_merchantgroup_code   IN       VARCHAR2,
   prm_merchant_id             IN       VARCHAR2,
   prm_auth_type            IN       VARCHAR2,
   prm_err_flag             OUT      VARCHAR2,
   prm_err_msg              OUT      VARCHAR2
)
IS
/*************************************************
     * Created By      :  Ramesh A
     * Created Date    :  23/MAR/2015
     * Created Reason  :  FSS-2281
     * Reviewer         :  Pankaj S
     * Reviewed Date    :  23/MAR/2015
     * Build Number     :  3.0
 *************************************************/
   v_check_cnt   NUMBER (1);
BEGIN
   SELECT COUNT (*)
     INTO v_check_cnt
     FROM CMS_MERCIDGRP_MERCID
    WHERE CMM_MERC_GRPCODE = prm_merchantgroup_code AND CMM_MERC_ID = prm_merchant_id;
    

   IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
      OR (v_check_cnt = 0 
      )
   THEN
      prm_err_flag := '1';
      prm_err_msg := 'OK';
   ELSE
      prm_err_flag := '70';
      prm_err_msg := 'Invalid Merchant ID';
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      prm_err_flag := '70';
      prm_err_msg := 'Invalid Merchant ID';
   WHEN OTHERS
   THEN
      prm_err_flag := '21';
      prm_err_msg :=
               'Error while Merchant ID validation ' || SUBSTR (SQLERRM, 1, 300);
END;