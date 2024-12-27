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
      AND object_name = 'VMS_RULE_PARAMETERS_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_ID_ADDRESS';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
	VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('DEVICE_ID_ADDRESS',
	'Device IP Address','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='ADDR_VERIFI_ADDR';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('ADDR_VERIFI_ADDR',
'Address Verification Address','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='ADDR_VERIFI_ZIP';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('ADDR_VERIFI_ZIP',
'Address Verification Zip','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='ADDR_VERIFI_BOTH';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('ADDR_VERIFI_BOTH',
'Address Verification','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='LAST_ACTIVE_PERIOD';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('LAST_ACTIVE_PERIOD',
'Last Active Period','2',null);
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_ID';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('DEVICE_ID','Device Id','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='CHARGE_BACK_COUNT';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('CHARGE_BACK_COUNT',
'Charge Back Count','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='WALLET_ID';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('WALLET_ID','Wallet Id'
,'2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='RISK_ASSESMENT';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('RISK_ASSESMENT',
'Risk Assesment','1',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_SCORE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('DEVICE_SCORE',
'Device Score','1',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='ACCOUNT_SCORE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('ACCOUNT_SCORE',
'Account Score','1',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='TOKEN_SCORE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('TOKEN_SCORE',
'Token Score','1',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='NETWORK_TOKEN_DECISION';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('NETWORK_TOKEN_DECISION',
'Network Provision Desision','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_LOCATION';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('DEVICE_LOCATION',
'Device Location','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='PAN_SOURCE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('PAN_SOURCE',
'PAN Source','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_TYPE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('DEVICE_TYPE',
'Device Type','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='TOKEN_STORAGE_TECHNOLOGY';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('TOKEN_STORAGE_TECHNOLOGY',
'Token Storage Technology','2',null);
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='TOKEN_TYPE';

      IF v_cnt = 0
      THEN
         Insert into vmscms.VMS_RULE_PARAMETERS_r1705b2 (VRP_PARAM_ID,VRP_PARAM_NAME,
VRP_PARAM_TYPE,VRP_PARAM_VALIDATION) values ('TOKEN_TYPE','Token Type',
'2',null);
      END IF;	  

      INSERT INTO vmscms.VMS_RULE_PARAMETERS
         SELECT *
           FROM vmscms.VMS_RULE_PARAMETERS_R1705B2
          WHERE (vrp_param_id
                ) NOT IN (
                   SELECT vrp_param_id
                     FROM vmscms.VMS_RULE_PARAMETERS);

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


DELETE from  vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING where vrt_param_id='DEVICE_LOCATION';

update vmscms.VMS_RULE_PARAM_TRANOBJ_MAPPING set vrt_tran_obj_name='***'
WHERE vrt_param_id in ('ADDR_VERIFI_ADDR','ADDR_VERIFI_BOTH','ADDR_VERIFI_ZIP','CHARGE_BACK_COUNT','LAST_ACTIVE_PERIOD');

DELETE from vmscms.VMS_RULE_PARAMETERS where vrp_param_id='DEVICE_LOCATION';

UPDATE  vmscms.VMS_RULE_PARAMETERS set vrp_param_type='5'
WHERE vrp_param_id IN ('ADDR_VERIFI_ADDR','ADDR_VERIFI_ZIP','ADDR_VERIFI_BOTH','LAST_ACTIVE_PERIOD','DEVICE_ID','CHARGE_BACK_COUNT');

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
      AND object_name = 'VMS_RULE_PARAMETERS_R1705B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_LOCATION_DISTANCE';

      IF v_cnt = 0
      THEN
         INSERT
			INTO vmscms.VMS_RULE_PARAMETERS_R1705B5
			  (
				VRP_PARAM_ID,
				VRP_PARAM_NAME,
				VRP_PARAM_TYPE,
				VRP_PARAM_VALIDATION
			  )
			  VALUES
			  (
				'DEVICE_LOCATION_DISTANCE',
				'Device Location Distance',
				'5',
				NULL
			  );
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.VMS_RULE_PARAMETERS
        WHERE vrp_param_id='DEVICE_LOCATION_COUNTRY';

      IF v_cnt = 0
      THEN
         INSERT
			INTO vmscms.VMS_RULE_PARAMETERS_R1705B5
			  (
				VRP_PARAM_ID,
				VRP_PARAM_NAME,
				VRP_PARAM_TYPE,
				VRP_PARAM_VALIDATION
			  )
			  VALUES
			  (
				'DEVICE_LOCATION_COUNTRY',
				'Device Location Country',
				'5',
				NULL
			  );
      END IF;
	  
      INSERT INTO vmscms.VMS_RULE_PARAMETERS
         SELECT *
           FROM vmscms.VMS_RULE_PARAMETERS_R1705B5
          WHERE (vrp_param_id
                ) NOT IN (
                   SELECT vrp_param_id
                     FROM vmscms.VMS_RULE_PARAMETERS);

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