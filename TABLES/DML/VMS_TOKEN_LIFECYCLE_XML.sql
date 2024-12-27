DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE owner = 'VMSCMS'
      AND OBJECT_TYPE = 'TABLE'
      AND object_name = 'VMS_TKEN_LIFECYCLE_XML_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_TOKEN_LIFECYCLE_XML
       WHERE VTL_INST_CODE=1
	   and VTL_MSG_REASON_CODE=3721;

      IF v_cnt = 0
      THEN
                  Insert into vmscms.VMS_TKEN_LIFECYCLE_XML_R1705B2 (VTL_INST_CODE,VTL_MSG_REASON_CODE,VTL_HEADER_PARAM,VTL_REQUEST_JSON)
 values (1,3721,
'x-incfs-date~x-incfs-ip~x-incfs-channel~x-incfs-channel-identifier~x-incfs-username~x-incfs-correlationid~apikey'
 ,'submitLifeCycleCommandReq~MTI,MTI~PAN,PAN~newPAN,NewPAN~transmissionDateTime,TransmissionDateTime~stan,Stan~expiryDate,EncryptedExpiryDate~newExpiryDate,NewExpiryDate~messageReasonCode,messageReasonCode~requestReason,requestReason~forwardInstIDCode,ForwardInstIDCode~RRN,RRN~activationCode,activationCode~panReferenceID,PanReferenceID');

      END IF;
	 
      INSERT INTO vmscms.VMS_TOKEN_LIFECYCLE_XML
         SELECT *
           from VMSCMS.VMS_TKEN_LIFECYCLE_XML_R1705B2
          WHERE (VTL_INST_CODE,VTL_MSG_REASON_CODE) NOT IN (
                     SELECT VTL_INST_CODE,VTL_MSG_REASON_CODE
                       FROM vmscms.VMS_TOKEN_LIFECYCLE_XML);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/

update vmscms.vms_token_lifecycle_xml set vtl_request_reason='Token deleted due to card closure/suspended status for long period' where vtl_msg_reason_code='3701';
update vmscms.vms_token_lifecycle_xml set vtl_request_reason='Token suspended by Admin' where vtl_msg_reason_code='3702';
update vmscms.vms_token_lifecycle_xml set vtl_request_reason='Token resumed by Admin' where vtl_msg_reason_code='3703';
update vmscms.vms_token_lifecycle_xml set vtl_request_reason='New PAN is updated due to card replacement' where vtl_msg_reason_code='3721';



DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE owner = 'VMSCMS'
      AND OBJECT_TYPE = 'TABLE'
      AND object_name = 'VMS_TKEN_LIFECYCLE_XML_R1705B4';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_TOKEN_LIFECYCLE_XML
       WHERE VTL_INST_CODE=1
	   and VTL_MSG_REASON_CODE=3720;

      IF v_cnt = 0
      THEN
                 Insert into vmscms.VMS_TKEN_LIFECYCLE_XML_R1705B4 (VTL_INST_CODE,VTL_MSG_REASON_CODE,VTL_HEADER_PARAM,VTL_REQUEST_JSON,vtl_request_reason)
 values (1,3720,
'x-incfs-date~x-incfs-ip~x-incfs-channel~x-incfs-channel-identifier~x-incfs-username~x-incfs-correlationid~apikey'
 ,'submitLifeCycleCommandReq~MTI,MTI~PAN,PAN~newPAN,NewPAN~transmissionDateTime,TransmissionDateTime~stan,Stan~expiryDate,EncryptedExpiryDate~newExpiryDate,NewExpiryDate~messageReasonCode,messageReasonCode~requestReason,requestReason~forwardInstIDCode,ForwardInstIDCode~RRN,RRN~activationCode,activationCode~panReferenceID,PanReferenceID','New Expiry Date is updated due to card renewal');

      END IF;
	 
      INSERT INTO vmscms.VMS_TOKEN_LIFECYCLE_XML
         SELECT *
           from VMSCMS.VMS_TKEN_LIFECYCLE_XML_R1705B4
          WHERE (VTL_INST_CODE,VTL_MSG_REASON_CODE) NOT IN (
                     SELECT VTL_INST_CODE,VTL_MSG_REASON_CODE
                       FROM vmscms.VMS_TOKEN_LIFECYCLE_XML);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/