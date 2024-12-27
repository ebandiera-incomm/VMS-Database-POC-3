DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND owner = 'VMSCMS'
      AND object_name = 'VMS_RULE_PM_TNOBJ_MAPG_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='ACCOUNT_SCORE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='WpAccountScore';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('ACCOUNT_SCORE','16','NA','WpAccountScore');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='ADDR_VERIFI_ADDR'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='***';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('ADDR_VERIFI_ADDR','16','NA','***');
      END IF;
	  
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='ADDR_VERIFI_BOTH'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='***';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('ADDR_VERIFI_BOTH','16','NA','***');
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='ADDR_VERIFI_ZIP'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='***';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('ADDR_VERIFI_ZIP','16','NA','***');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='CHARGE_BACK_COUNT'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='WalletID';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('CHARGE_BACK_COUNT','16','NA','WalletID');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_ID'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='DeviceID';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('DEVICE_ID','16','NA','DeviceID');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_ID_ADDRESS'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='IPAddress';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('DEVICE_ID_ADDRESS','16','NA','IPAddress');
      END IF;
	  
	 
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_SCORE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='WpDeviceScore';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('DEVICE_SCORE','16','NA','WpDeviceScore');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_TYPE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='DeviceType';

      IF v_cnt = 0
      THEN
          
Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('DEVICE_TYPE','16','NA','DeviceType');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='LAST_ACTIVE_PERIOD'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='CardExpiryDate_DDMMYYYY';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('LAST_ACTIVE_PERIOD','16','NA','CardExpiryDate_DDMMYYYY');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='NETWORK_TOKEN_DECISION'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='VisaTokenDecisioning';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('NETWORK_TOKEN_DECISION','16','NA','VisaTokenDecisioning');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='PAN_SOURCE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='PanSource';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('PAN_SOURCE','16','NA','PanSource');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='RISK_ASSESMENT'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='WpRiskAssessment';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('RISK_ASSESMENT','16','NA','WpRiskAssessment');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='TOKEN_SCORE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='VisaTokenScore';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('TOKEN_SCORE','16','NA','VisaTokenScore');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='TOKEN_STORAGE_TECHNOLOGY'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='StorageTechnology';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('TOKEN_STORAGE_TECHNOLOGY','16','NA','StorageTechnology');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='TOKEN_TYPE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='TokenType';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('TOKEN_TYPE','16','NA','TokenType');
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='WALLET_ID'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='WalletID';

      IF v_cnt = 0
      THEN
          Insert into vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2 (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,
VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME) values ('WALLET_ID','16','NA','WalletID');
      END IF;
	  	  
      INSERT INTO vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
         SELECT *
           FROM vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B2
          WHERE (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME
                ) NOT IN (
                   SELECT VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME
                     FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING);

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
    WHERE object_type = 'TABLE'
      AND owner = 'VMSCMS'
      AND object_name = 'VMS_RULE_PM_TNOBJ_MAPG_R1705B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_LOCATION_COUNTRY'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='***';

      IF v_cnt = 0
      THEN
          INSERT
			INTO VMSCMS.VMS_RULE_PM_TNOBJ_MAPG_R1705B5
			  (
				VRT_PARAM_ID,
				VRT_DELIVERY_CHANNEL,
				VRT_TRAN_CODE,
				VRT_TRAN_OBJ_NAME
			  )
			  VALUES
			  (
				'DEVICE_LOCATION_COUNTRY',
				'16',
				'NA',
				'***'
			  );
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
        WHERE VRT_PARAM_ID='DEVICE_LOCATION_DISTANCE'
		and	  VRT_DELIVERY_CHANNEL='16'
		and   VRT_TRAN_CODE='NA'
		and   VRT_TRAN_OBJ_NAME='***';

      IF v_cnt = 0
      THEN
          INSERT
			INTO VMSCMS.VMS_RULE_PM_TNOBJ_MAPG_R1705B5
			  (
				VRT_PARAM_ID,
				VRT_DELIVERY_CHANNEL,
				VRT_TRAN_CODE,
				VRT_TRAN_OBJ_NAME
			  )
			  VALUES
			  (
				'DEVICE_LOCATION_DISTANCE',
				'16',
				'NA',
				'***'
			  );
      END IF;
	 
	 
      INSERT INTO vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING
         SELECT *
           FROM vmscms.VMS_RULE_PM_TNOBJ_MAPG_R1705B5
          WHERE (VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME
                ) NOT IN (
                   SELECT VRT_PARAM_ID,VRT_DELIVERY_CHANNEL,VRT_TRAN_CODE,VRT_TRAN_OBJ_NAME
                     FROM vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING);

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