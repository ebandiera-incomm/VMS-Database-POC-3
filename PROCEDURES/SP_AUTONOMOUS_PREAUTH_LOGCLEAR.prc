create or replace PROCEDURE vmscms.sp_autonomous_preauth_logclear 
 (P_AUTHID  IN VARCHAR2)
IS
/*****************************************************************************************************************
     * Created by       : Sai Prasad
     * Created Date     : 05-Feb-2014    
     * Created For      : DB time logging
	 * Reviewed By      : Pankaj S 
     *****************************************************************************************************************/
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  delete cms_current_revtransaction  where Auth_id = P_AUTHID;
   commit;
Exception
When others then 
rollback;
END sp_autonomous_preauth_logclear;
/
SHOW ERROR