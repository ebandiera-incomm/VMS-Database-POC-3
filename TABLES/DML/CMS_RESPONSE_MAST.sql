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
      AND object_name = 'CMS_RESPONSE_MAST_R1707B5';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '01';

      IF v_cnt = 0
      THEN
         
       insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','01','00','00','Success',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '03';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','03','03','03','Invalid Order ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '04';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','04','04','04','Invalid Line Item ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '05';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','05','05','05','Invalid Partner ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '06';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','06','06','06','Duplicate Order',1,sysdate,1,sysdate);
         
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '07';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','07','07','07','Invalid ProductID and Package ID Combination',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '08';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','08','08','08','Invalid Order ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '09';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','09','09','09','Invalid Product Type',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '10';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','10','10','10','Invalid Card Status',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '11';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','11','11','11','Invalid Card Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '12';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','12','12','12','Invalid Proxy Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '13';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','13','13','13','Invalid Serial Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '14';

      IF v_cnt = 0
      THEN
         
       insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','14','14','14','Activation Codes Not Matched',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '15';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','15','15','15','Invalid Field',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '18';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','18','16','16','Required Message Elements Not Present',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '17';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','17','17','17','Card Activation Already Done',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '17'
         AND cms_response_id = '89';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'17','89','89','89','Transaction Declined Due to System Error',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '277';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','277','05','05','Invalid Partner ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '278';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','278','08','08','Invalid Order ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '279';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','279','11','11','Invalid Card Number',1,sysdate,1,sysdate); 
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '280';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','280','12','12','Invalid Proxy Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '281';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','281','13','13','Invalid Serial Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '282';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'07','282','14','14','Activation Codes Not Matched',1,sysdate,1,sysdate); 
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '283';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','283','05','05','Invalid Partner ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '284';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','284','08','08','Invalid Order ID',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '285';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','285','11','11','Invalid Card Number',1,sysdate,1,sysdate); 
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '286';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','286','12','12','Invalid Proxy Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '287';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','287','13','13','Invalid Serial Number',1,sysdate,1,sysdate);
         
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '13'
         AND cms_response_id = '288';

      IF v_cnt = 0
      THEN
         
        insert into vmscms.cms_response_mast_r1707b5 (cms_inst_code,CMS_DELIVERY_CHANNEL,cms_response_id,cms_iso_respcde,cms_b24_respcde,cms_resp_desc,cms_ins_user,cms_ins_date,cms_lupd_user,cms_lupd_date)
values(1,'13','288','14','14','Activation Codes Not Matched',1,sysdate,1,sysdate); 
         
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_response_mast
       WHERE cms_inst_code = 1
         AND cms_delivery_channel = '07'
         AND cms_response_id = '283';

      IF v_cnt = 0
      THEN
         
        INSERT INTO vmscms.CMS_RESPONSE_MAST_r1707b5 (CMS_INST_CODE,CMS_DELIVERY_CHANNEL,CMS_RESPONSE_ID,
		CMS_ISO_RESPCDE,CMS_B24_RESPCDE,CMS_RESP_DESC,
		CMS_INS_USER,CMS_INS_DATE,CMS_LUPD_USER,CMS_LUPD_DATE)
		values (1,'07','283','17','17','Card Activation Already Done',1,SYSDATE,1,SYSDATE);

         
      END IF;
	  
	  
	  

       
      INSERT INTO vmscms.cms_response_mast
         SELECT *
           FROM vmscms.CMS_RESPONSE_MAST_R1707B5
          WHERE (cms_inst_code, cms_delivery_channel, cms_response_id) NOT IN (
                   SELECT cms_inst_code, cms_delivery_channel,
                          cms_response_id
                     FROM vmscms.cms_response_mast);

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
