CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHECK_CURRENCY (
   prm_currencygroup_code   IN       VARCHAR2,
   prm_currency_code        IN       VARCHAR2,
   prm_auth_type            IN       VARCHAR2,
   prm_err_flag             OUT      VARCHAR2,
   prm_err_msg              OUT      VARCHAR2
)
IS
/*************************************************
     * Modified By      :  Dhiraj Gaikwad 
     * Modified Date    :  13-Sep-2012
     * Modified Reason  :   Rule is not attached to transaction then transaction will not go for validations .
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  30-Apr-2012
     * Build Number     :  CMS3.4.2_RI0008_B0002
 *************************************************/
   v_check_cnt   NUMBER (1);
BEGIN
   SELECT COUNT (*)
     INTO v_check_cnt
     FROM currencycode_group
    WHERE currencycodegroupid = prm_currencygroup_code
      AND currencycode = prm_currency_code;

   IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
      OR (v_check_cnt = 0-- AND prm_auth_type = 'D' --Commented by Dhiraj on 13092012 
      )
   THEN
      prm_err_flag := '1';
      prm_err_msg := 'OK';
   ELSE
      prm_err_flag := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
      prm_err_msg := 'Invalid transaction currency';
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      prm_err_flag := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
      prm_err_msg := 'Invalid transaction currency ';
   WHEN OTHERS
   THEN
      prm_err_flag := '21';--Modified by Deepa on 30-Apr-2012 to change the Response Code
      prm_err_msg :=
               'Error while currency validation ' || SUBSTR (SQLERRM, 1, 300);
END;
/
SHOW ERROR