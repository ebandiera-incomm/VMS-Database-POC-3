DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE owner = 'VMSCMS'
      AND object_type = 'TABLE'
      AND object_name = 'CMS_TXN_PROPERTIES_R1707B5';

   IF v_chk_tab = 1
   THEN     
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '17'
         AND ctp_txn_code = '02'
         AND ctp_msg_type = '0100'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            INSERT INTO vmscms.CMS_TXN_PROPERTIES_R1707B5 (CTP_TXN_CODE,CTP_INST_CODE,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL)
VALUES('02',1,'00','0100','17');

      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '07'
         AND ctp_txn_code = '35'
         AND ctp_msg_type = '0100'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_MSGBODY_PROP,CTP_HEADER_PROP,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL,CTP_VALIDATION_PROP,CTP_HEADERPROP_VALIDATION,CTP_NONMANDATORY_MSGBODY_PROP,CTP_NONMANDATORY_VALIDATION)
values ('35',1,'','','00','0100','07','','','','');

      END IF;

	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '07'
         AND ctp_txn_code = '36'
         AND ctp_msg_type = '0200'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_MSGBODY_PROP,CTP_HEADER_PROP,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL,CTP_VALIDATION_PROP,CTP_HEADERPROP_VALIDATION,CTP_NONMANDATORY_MSGBODY_PROP,CTP_NONMANDATORY_VALIDATION)
values ('36',1,'','','00','0200','07','','','','');

      END IF;
	  
	   SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '13'
         AND ctp_txn_code = '59'
         AND ctp_msg_type = '0100'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL)
values ('59',1,'00','0100','13');

      END IF;
	  
	  
	   SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '17'
         AND ctp_txn_code = '03'
         AND ctp_msg_type = '0200'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL)
values ('03',1,'00','0200','17');

      END IF;
	  
	  
	   SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '17'
         AND ctp_txn_code = '04'
         AND ctp_msg_type = '0200'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL)
values ('04',1,'00','0200','17');

      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_txn_properties
       WHERE ctp_inst_code = 1
         AND CTP_DELIVERY_CHANNEL = '17'
         AND ctp_txn_code = '01'
         AND ctp_msg_type = '0100'
         AND ctp_reversal_code = '00';

      IF v_cnt = 0
      THEN
            insert into vmscms.CMS_TXN_PROPERTIES_R1707B5(CTP_TXN_CODE,CTP_INST_CODE,CTP_REVERSAL_CODE,CTP_MSG_TYPE,CTP_DELIVERY_CHANNEL)
values ('01',1,'00','0100','17');

      END IF;


     
	  
      INSERT INTO vmscms.cms_txn_properties
         SELECT *
           FROM vmscms.CMS_TXN_PROPERTIES_R1707B5
          WHERE (ctp_inst_code,
                 ctp_delivery_channel,
                 ctp_txn_code,
                 ctp_msg_type,
                 ctp_reversal_code
                ) NOT IN (
                   SELECT ctp_inst_code, ctp_delivery_channel, ctp_txn_code,
                          ctp_msg_type, ctp_reversal_code
                     FROM vmscms.cms_txn_properties);

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

