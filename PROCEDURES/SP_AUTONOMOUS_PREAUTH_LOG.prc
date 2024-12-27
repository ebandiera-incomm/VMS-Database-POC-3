CREATE OR REPLACE PROCEDURE VMSCMS.sp_autonomous_preauth_log
 (P_AUTHID  IN VARCHAR2,
 P_STAN  IN VARCHAR2,
 P_BUSDATE  IN VARCHAR2,
 P_PAN_NO IN VARCHAR2,
 P_DELIVERY_CHANNEL  IN VARCHAR2,
 P_INST_CODE  IN VARCHAR2,
 P_ERROR_MSG_OUT OUT VARCHAR2
 )
IS
/*****************************************************************************************************************
     * Created by       : Sai Prasad
     * Created Date     : 05-Feb-2014
     * Created For      : DB time logging
     * Reviewed By      : Pankaj S

     * Modified by       : John Gingrich
     * Modified Date     : 28-Aug-2023
     * Modified For      : VMS-5551:  Concurrent Pre-Auth Reversals
     * Reviewed By       : 
     *****************************************************************************************************************/
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
P_ERROR_MSG_OUT := 'OK';

   insert into cms_current_revtransaction (Auth_id , system_trace_audit_no
,BUSINESS_DATE  ,CUSTOMER_CARD_NO , INSTCODE , DELIVERY_CHANNEL) values
(P_AUTHID,P_STAN,P_BUSDATE,P_PAN_NO,P_INST_CODE,P_DELIVERY_CHANNEL );
   commit;
   Exception
When 
  DUP_VAL_ON_INDEX
THEN P_ERROR_MSG_OUT := 'Concurrent Trxn in Progress';
ROLLBACK;
WHEN
others then
rollback;
END sp_autonomous_preauth_log;
/