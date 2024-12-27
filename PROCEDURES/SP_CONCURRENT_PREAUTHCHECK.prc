create or replace PROCEDURE vmscms.sp_concurrent_preauthcheck 
 ( P_STAN  IN VARCHAR2,
 P_BUSDATE  IN VARCHAR2,
 P_PAN_NO IN VARCHAR2,
 P_DELIVERY_CHANNEL  IN VARCHAR2,
 P_INST_CODE  IN VARCHAR2,
 P_RESULT_CODE OUT NUMBER
 )
IS
/*****************************************************************************************************************
     * Created by       : Sai Prasad
     * Created Date     : 05-Feb-2014    
     * Created For      : DB time logging
	 * Reviewed By      : Pankaj S 
     *****************************************************************************************************************/
BEGIN
Select count(1) into P_RESULT_CODE from  cms_current_revtransaction where system_trace_audit_no =  P_STAN
and BUSINESS_DATE  =P_BUSDATE 
and CUSTOMER_CARD_NO = P_PAN_NO 
and INSTCODE = P_INST_CODE 
and DELIVERY_CHANNEL =P_DELIVERY_CHANNEL;
Exception
When others then 
P_RESULT_CODE :=0;
   
END sp_concurrent_preauthcheck;
/
SHOW ERROR