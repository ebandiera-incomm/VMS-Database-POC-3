CREATE OR REPLACE PACKAGE VMSCMS.VMS_QUEUE AS 

 PROCEDURE ENQUEUE_CARD_STATUS(p_event_type_in 		IN  VARCHAR2,
                               p_hash_pan_in 			IN  VARCHAR2,
                               p_prev_status_in 	IN  VARCHAR2,
                               p_curr_status_in 	IN  VARCHAR2,
                               p_delay_in 				IN  NUMBER,
                               p_error_msg_out  	OUT VARCHAR2);
                               
 PROCEDURE DEQUEUE_CARD_STATUS(context 		RAW,
                                reginfo 		sys.aq$_reg_info,
                                descr 			sys.aq$_descriptor,
                                payload 		RAW,
                                payloadl 	  NUMBER);
                               

END VMS_QUEUE;