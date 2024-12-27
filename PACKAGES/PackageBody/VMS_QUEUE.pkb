create or replace
PACKAGE BODY VMSCMS.VMS_QUEUE AS

  PROCEDURE ENQUEUE_CARD_STATUS(p_event_type_in 	IN  VARCHAR2,
                               p_hash_pan_in 			IN  VARCHAR2,
                               p_prev_status_in 	IN  VARCHAR2,
                               p_curr_status_in 	IN  VARCHAR2,
                               p_delay_in 				IN  NUMBER,
                               p_error_msg_out  	OUT VARCHAR2) 
  AS
  l_enqueue_options    dbms_aq.enqueue_options_t;
  l_msg_properties 		 dbms_aq.message_properties_t;
  l_message_id         RAW(16);
  l_message            card_status_msg_type;
  
  BEGIN

   IF p_delay_in IS NOT NULL
   THEN
   --Set the delay on a message while enqueueing
   l_msg_properties.delay := p_delay_in;
   END IF;
   l_message := card_status_msg_type(p_event_type_in,p_hash_pan_in,p_prev_status_in,p_curr_status_in);

   dbms_aq.enqueue(queue_name         => 'vmscms.card_status_queue',
                   enqueue_options    => l_enqueue_options,
                   message_properties => l_msg_properties,
                   payload            => l_message,
                   msgid              => l_message_id);
	EXCEPTION
		WHEN OTHERS 
		THEN
			p_error_msg_out := 'Error during enqueue ' || SQLERRM;
  END ENQUEUE_CARD_STATUS;
  
  PROCEDURE DEQUEUE_CARD_STATUS(context 		RAW,
                                reginfo 		sys.aq$_reg_info,
                                descr 			sys.aq$_descriptor,
                                payload 		RAW,
                                payloadl 		NUMBER)
  AS
  l_dequeue_options    dbms_aq.dequeue_options_t;
  l_msg_properties     dbms_aq.message_properties_t;
  l_message_id         raw(16);
  l_message            card_status_msg_type;
  l_encr_pan           vmscms.cms_appl_pan.cap_pan_code_encr%type;
  l_error_msg          transactionlog.error_msg%TYPE;
  l_error_code         transactionlog.response_id%TYPE;
  
  BEGIN
  l_dequeue_options.msgid         := descr.msg_id;
  l_dequeue_options.consumer_name := descr.consumer_name;

--Iterate through all available messages that are ready for dequeue  
    LOOP
      DBMS_AQ.DEQUEUE(queue_name         => descr.queue_name,
                      dequeue_options    => l_dequeue_options,
                      message_properties => l_msg_properties,
                      payload            => l_message,
                      msgid              => l_message_id);
    
        BEGIN
            IF l_message.event_type = 'RISKINVEST'
            THEN
                UPDATE cms_appl_pan
                   SET cap_card_stat = cap_old_cardstat,
                       cap_cardstatus_expiry = NULL
                 WHERE cap_pan_code = l_message.hash_pan
                   AND cap_card_stat = '19'
				   AND cap_cardstatus_expiry <=sysdate
                   AND cap_inst_code = 1
             RETURNING cap_pan_code_encr 
                  INTO l_encr_pan;
        
               IF SQL%ROWCOUNT = 1 THEN
                  SP_LOG_CARDSTAT_CHNGE(1,
                                        l_message.hash_pan,
                                        l_encr_pan,
                                        LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0'),
                                        '99',
                                        null,
                                        null,
                                        null,
                                        l_error_code,
                                        l_error_msg,
                                        'Host initiated rollback of card status from RISK INVESTIGATION to '||l_message.previous_card_status);
               END IF;
            END IF;
            EXCEPTION
                WHEN OTHERS 
                THEN
                    NULL;
        END;
     
        COMMIT;
    END LOOP;
  EXCEPTION
  WHEN OTHERS 
  THEN
    COMMIT;
  END DEQUEUE_CARD_STATUS;
  
END VMS_QUEUE;
/
show error

