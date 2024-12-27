CREATE OR REPLACE PROCEDURE FSDELVRYCEP.VMS_PUSH_QUEUE_NOTIFICATION (	P_QUEUE_NAME		IN	VARCHAR2,
															P_RRN 				IN	VARCHAR2,
															P_PAYLOAD			IN	VARCHAR2,
															P_MESSAGE_TYPE		IN	VARCHAR2,
															P_PARTNER_NAME		IN	VARCHAR2,
                                                            P_RESP_OUT          OUT VARCHAR2
														)
AS

/******************************************************************************************************************************
   * MODIFIED BY          : PUVANESH.N
   * MODIFIED DATE        : 22-APR-2021
   * MODIFIED FOR         : VMS-3944 - VMS HOST UI throws SQL Exception upon selecting HOST 
							as delivery channel in Transaction Configuration for OTP/Event Notification screen
*******************************************************************************************************************************/	
					  
L_ENQUEUE_OPTNS     sys.DBMS_AQ.ENQUEUE_OPTIONS_T;
L_MSG_PROPS       	sys.DBMS_AQ.MESSAGE_PROPERTIES_T;
L_MESSAGE           SYS.AQ$_JMS_MESSAGE;
L_MSG_ID          	VARCHAR2(4000);	
L_CORRELATION_ID	VARCHAR2(100);
EXP_REJECT_RECORD	EXCEPTION;

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

P_RESP_OUT := 'OK';

	BEGIN

		SELECT DBMS_RANDOM.STRING ('X', 15) INTO L_CORRELATION_ID FROM DUAL;

	EXCEPTION
		WHEN OTHERS THEN
		P_RESP_OUT := 'ERROR IN SELECTING RANDOM STRING'
                        || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;

	L_MSG_PROPS.correlation := P_RRN;
	L_MSG_PROPS.exception_queue := 'EVENT_EXCEPTION_QUEUE';

	BEGIN

	L_MESSAGE := SYS.AQ$_JMS_MESSAGE(
                    SYS.AQ$_JMS_HEADER(
                            SYS.AQ$_AGENT(' ', NULL, 0), 
                            NULL, 
                            'APP_FSDLVYCEP_USER', 
                            NULL, 
                            NULL, 
                            NULL, 
                            SYS.AQ$_JMS_USERPROPARRAY(SYS.AQ$_JMS_USERPROPERTY('platform', 100, 'VMS', NULL, 27), 
                                                      SYS.AQ$_JMS_USERPROPERTY('isEncrypted', 200, 'False', 0, 20), 
                                                      SYS.AQ$_JMS_USERPROPERTY('JMS_OracleDeliveryMode', 100, '2', NULL, 27), 
                                                      SYS.AQ$_JMS_USERPROPERTY('message_type', 100, P_MESSAGE_TYPE, NULL, 27), 
                                                      SYS.AQ$_JMS_USERPROPERTY('correlation_id', 100, L_CORRELATION_ID, NULL, 27), 
                                                      SYS.AQ$_JMS_USERPROPERTY('partner_id', 100, P_PARTNER_NAME, NULL, 27))), 
                   NULL, 
                   0, 
                   395, 
                   NULL, 
                   NULL, 
                   NULL, 
                   NULL, 
                   NULL);

	EXCEPTION
	WHEN OTHERS THEN
		P_RESP_OUT := 'ERROR IN SETTING HEADER'
                        || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD; 
	END;

	BEGIN

	L_MESSAGE.set_text(P_PAYLOAD);

	EXCEPTION
	WHEN OTHERS THEN
		P_RESP_OUT := 'ERROR IN SETTING TEXT MESSAGE'
                        || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD; 
	END;

	BEGIN
	SYS.DBMS_AQ.ENQUEUE(QUEUE_NAME => P_QUEUE_NAME, 
                ENQUEUE_OPTIONS => L_ENQUEUE_OPTNS, 
                MESSAGE_PROPERTIES => L_MSG_PROPS, 
                PAYLOAD => L_MESSAGE, 
                MSGID => L_MSG_ID);

	COMMIT;	
	EXCEPTION
	WHEN OTHERS THEN
		P_RESP_OUT := 'ERROR IN ENQUEUING MESSAGE'
                        || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD; 
	END;

EXCEPTION
	  WHEN EXP_REJECT_RECORD THEN
         P_RESP_OUT :='PROBLEM WHILE ENQUEUE MSG INTO QUEUE-'|| P_RESP_OUT;         
      WHEN OTHERS THEN
         P_RESP_OUT :='PROBLEM WHILE ENQUEUE MSG INTO QUEUE-'|| SUBSTR (SQLERRM, 1, 300);	
END;
/
SHOW ERROR