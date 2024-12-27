CREATE OR REPLACE PROCEDURE VMSCMS.SP_UPDATE_USERID (
   p_instcode        IN       NUMBER,
   p_custcode        IN       NUMBER,
   p_acctlock_flag   IN       VARCHAR2,
   p_countreset_flag  IN       VARCHAR2,
   p_errmsg          OUT      VARCHAR2
)
AS
/*******************************************************************
    * Created Date      :  06-maR-2015
    * Created By        :  SivaKumar M
    * PURPOSE           :  DFCTNM-35     
    * Reviewer          :  SaravanaKumar A
    * Reviewer Date     :  06-Mar-2015
    * Build No          :  VMSGPRHOSTCSD_3.0_B0001

********************************************************************/
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   p_errmsg := 'OK';

   UPDATE cms_cust_mast
      SET ccm_wrong_logincnt = DECODE (p_countreset_flag, 'R',1,nvl(ccm_wrong_logincnt,0) + 1),
          ccm_last_logindate = SYSDATE,
          ccm_acctlock_flag =p_acctlock_flag
    WHERE ccm_cust_code = p_custcode AND ccm_inst_code = p_instcode;

   IF SQL%ROWCOUNT = 0 THEN
      p_errmsg :='Error while updating cust master-' || SUBSTR (SQLERRM, 1, 200);
   END IF;

   COMMIT;
END;
/
SHOW ERRORS;
