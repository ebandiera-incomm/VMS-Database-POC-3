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
      AND object_name = 'CMS_VERIFICATION_CLASS_R1705B1';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.IVRUpdateZipDataValidation'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.IVRUpdateZipDataValidationDaoProcess'
         AND CVC_DELIVERY_CHANEL = '10'
         AND cvc_txn_code = '53'
         AND cvc_msg_type = '0200'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
                 INSERT INTO vmscms.CMS_VERIFICATION_CLASS_R1705B1 (
          CVC_INST_CODE,CVC_VERIFY_CNAME,CVC_DAO_CNAME,
          CVC_DELIVERY_CHANEL,CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,
          CVC_INS_USER,CVC_INS_DATE,CVC_LUPD_USER,CVC_LUPD_DATE) 
          values (1,'com.fss.cmsauth.preauthverification.IVRUpdateZipDataValidation','com.fss.cmsauth.dao.IVRUpdateZipDataValidationDaoProcess',
          '10','53','0200',0,
          1,SYSDATE,1,SYSDATE);
      END IF;

      INSERT INTO vmscms.cms_verification_classes
         SELECT *
           FROM vmscms.CMS_VERIFICATION_CLASS_R1705B1
          WHERE (cvc_inst_code,
                 cvc_verify_cname,
                 cvc_dao_cname,
                 cvc_delivery_chanel,
                 cvc_txn_code,
                 cvc_msg_type,
                 cvc_reversal_code
                ) NOT IN (
                   SELECT cvc_inst_code, cvc_verify_cname, cvc_dao_cname,
                          cvc_delivery_chanel, cvc_txn_code, cvc_msg_type,
                          cvc_reversal_code
                     FROM vmscms.cms_verification_classes);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/

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
      AND object_name = 'CMS_VERIFICATION_CLASS_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenActivationCodeNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenActivationCodeNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '13'
         AND cvc_msg_type = '1620'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
         INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B2 (CVC_INST_CODE,
		 CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
		CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,CVC_INS_DATE,
		CVC_LUPD_USER,CVC_LUPD_DATE)
		VALUES 
		(1,'com.fss.cmsauth.preauthverification.ISO93TokenActivationCodeNotificationVerification',
		'com.fss.cmsauth.dao.ISO93TokenActivationCodeNotificationDBProcess',
		'16','13','1620',0,1,SYSDATE,1,SYSDATE);
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenCompleteNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenCompleteNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '14'
         AND cvc_msg_type = '1620'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
         INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B2 (CVC_INST_CODE, 
		 CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
		CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,
		CVC_INS_DATE,CVC_LUPD_USER,CVC_LUPD_DATE)
		VALUES 
		(1,'com.fss.cmsauth.preauthverification.ISO93TokenCompleteNotificationVerification',
		'com.fss.cmsauth.dao.ISO93TokenCompleteNotificationDBProcess',
		'16','14','1620',0,1,SYSDATE,1,SYSDATE);
      END IF;
	  
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenEventNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenEventNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '15'
         AND cvc_msg_type = '1620'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
          INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B2 (CVC_INST_CODE, 
		  CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
		CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,CVC_INS_DATE,
		CVC_LUPD_USER,CVC_LUPD_DATE)
		VALUES 
		(1,'com.fss.cmsauth.preauthverification.ISO93TokenEventNotificationVerification',
		'com.fss.cmsauth.dao.ISO93TokenEventNotificationDBProcess',
		'16','15','1620',0,1,SYSDATE,1,SYSDATE);
      END IF;

      INSERT INTO vmscms.cms_verification_classes
         SELECT *
           FROM vmscms.CMS_VERIFICATION_CLASS_R1705B2
          WHERE (cvc_inst_code,
                 cvc_verify_cname,
                 cvc_dao_cname,
                 cvc_delivery_chanel,
                 cvc_txn_code,
                 cvc_msg_type,
                 cvc_reversal_code
                ) NOT IN (
                   SELECT cvc_inst_code, cvc_verify_cname, cvc_dao_cname,
                          cvc_delivery_chanel, cvc_txn_code, cvc_msg_type,
                          cvc_reversal_code
                     FROM vmscms.cms_verification_classes);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/

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
      AND object_name = 'CMS_VERIFICATION_CLASS_R1705B3';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenActivationCodeNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenActivationCodeNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '13'
         AND cvc_msg_type = '1621'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
         INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B3 (CVC_INST_CODE, CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,CVC_INS_DATE,CVC_LUPD_USER,CVC_LUPD_DATE)
VALUES 
(1,'com.fss.cmsauth.preauthverification.ISO93TokenActivationCodeNotificationVerification','com.fss.cmsauth.dao.ISO93TokenActivationCodeNotificationDBProcess','16','13','1621',0,1,SYSDATE,1,SYSDATE);
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenCompleteNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenCompleteNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '14'
         AND cvc_msg_type = '1621'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
         INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B3 (CVC_INST_CODE, CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,CVC_INS_DATE,CVC_LUPD_USER,CVC_LUPD_DATE)
VALUES 
(1,'com.fss.cmsauth.preauthverification.ISO93TokenCompleteNotificationVerification','com.fss.cmsauth.dao.ISO93TokenCompleteNotificationDBProcess','16','14','1621',0,1,SYSDATE,1,SYSDATE);
      END IF;
	  
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_verification_classes
       WHERE cvc_inst_code = 1
         AND cvc_verify_cname = 'com.fss.cmsauth.preauthverification.ISO93TokenEventNotificationVerification'
         AND cvc_dao_cname = 'com.fss.cmsauth.dao.ISO93TokenEventNotificationDBProcess'
         AND CVC_DELIVERY_CHANEL = '16'
         AND cvc_txn_code = '15'
         AND cvc_msg_type = '1621'
         AND cvc_reversal_code = 0;

      IF v_cnt = 0
      THEN
          INSERT INTO VMSCMS.CMS_VERIFICATION_CLASS_R1705B3 (CVC_INST_CODE, CVC_VERIFY_CNAME, CVC_DAO_CNAME, CVC_DELIVERY_CHANEL, 
CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE,CVC_INS_USER,CVC_INS_DATE,CVC_LUPD_USER,CVC_LUPD_DATE)
VALUES 
(1,'com.fss.cmsauth.preauthverification.ISO93TokenEventNotificationVerification','com.fss.cmsauth.dao.ISO93TokenEventNotificationDBProcess','16','15','1621',0,1,SYSDATE,1,SYSDATE);
      END IF;

      INSERT INTO vmscms.cms_verification_classes
         SELECT *
           FROM vmscms.CMS_VERIFICATION_CLASS_R1705B3
          WHERE (cvc_inst_code,
                 cvc_verify_cname,
                 cvc_dao_cname,
                 cvc_delivery_chanel,
                 cvc_txn_code,
                 cvc_msg_type,
                 cvc_reversal_code
                ) NOT IN (
                   SELECT cvc_inst_code, cvc_verify_cname, cvc_dao_cname,
                          cvc_delivery_chanel, cvc_txn_code, cvc_msg_type,
                          cvc_reversal_code
                     FROM vmscms.cms_verification_classes);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/