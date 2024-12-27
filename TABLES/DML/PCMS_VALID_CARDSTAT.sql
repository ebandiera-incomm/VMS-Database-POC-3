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
      AND object_name = 'PCMS_VALID_CARDSTAT_R1705B1';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.pcms_valid_cardstat
       WHERE pvc_inst_code = 1
         AND pvc_card_stat = '1'
         AND pvc_tran_code = '53'
         AND pvc_delivery_channel = '10';

      IF v_cnt = 0
      THEN
            INSERT INTO vmscms.PCMS_VALID_CARDSTAT_R1705B1 (
            PVC_INST_CODE,PVC_CARD_STAT,PVC_TRAN_CODE,
            PVC_INS_USER,PVC_INS_DATE,PVC_LUPD_DATE,PVC_LUPD_USER,PVC_DELIVERY_CHANNEL) 
            VALUES (1,'1','53',1,SYSDATE,SYSDATE,1,'10');
      END IF;

	  
      INSERT INTO vmscms.pcms_valid_cardstat
         SELECT *
           FROM vmscms.PCMS_VALID_CARDSTAT_R1705B1
          WHERE (pvc_inst_code,
                 pvc_card_stat,
                 pvc_tran_code,
                 pvc_delivery_channel
                ) NOT IN (
                   SELECT pvc_inst_code, pvc_card_stat, pvc_tran_code,
                          pvc_delivery_channel
                     FROM vmscms.pcms_valid_cardstat);

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
      AND object_name = 'PCMS_VALID_CARDSTAT_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.pcms_valid_cardstat
       WHERE pvc_inst_code = 1
         AND pvc_card_stat = '1'
         AND pvc_tran_code = '13'
         AND pvc_delivery_channel = '16';

      IF v_cnt = 0
      THEN
           INSERT INTO VMSCMS.PCMS_VALID_CARDSTAT_R1705B2 
(PVC_INST_CODE,PVC_CARD_STAT,PVC_TRAN_CODE,PVC_INS_USER,PVC_INS_DATE,PVC_LUPD_DATE,PVC_LUPD_USER,PVC_DELIVERY_CHANNEL)
VALUES (1,'1','13',1,SYSDATE,SYSDATE,1,'16'); 
      END IF;
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.pcms_valid_cardstat
       WHERE pvc_inst_code = 1
         AND pvc_card_stat = '1'
         AND pvc_tran_code = '14'
         AND pvc_delivery_channel = '16';

      IF v_cnt = 0
      THEN
            INSERT INTO VMSCMS.PCMS_VALID_CARDSTAT_R1705B2 
(PVC_INST_CODE,PVC_CARD_STAT,PVC_TRAN_CODE,PVC_INS_USER,PVC_INS_DATE,PVC_LUPD_DATE,PVC_LUPD_USER,PVC_DELIVERY_CHANNEL)
VALUES (1,'1','14',1,SYSDATE,SYSDATE,1,'16'); 
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.pcms_valid_cardstat
       WHERE pvc_inst_code = 1
         AND pvc_card_stat = '1'
         AND pvc_tran_code = '15'
         AND pvc_delivery_channel = '16';

      IF v_cnt = 0
      THEN
          INSERT INTO VMSCMS.PCMS_VALID_CARDSTAT_R1705B2 
(PVC_INST_CODE,PVC_CARD_STAT,PVC_TRAN_CODE,PVC_INS_USER,PVC_INS_DATE,PVC_LUPD_DATE,PVC_LUPD_USER,PVC_DELIVERY_CHANNEL)
VALUES (1,'1','15',1,SYSDATE,SYSDATE,1,'16'); 
      END IF;

	  
      INSERT INTO vmscms.pcms_valid_cardstat
         SELECT *
           FROM vmscms.PCMS_VALID_CARDSTAT_R1705B2
          WHERE (pvc_inst_code,
                 pvc_card_stat,
                 pvc_tran_code,
                 pvc_delivery_channel
                ) NOT IN (
                   SELECT pvc_inst_code, pvc_card_stat, pvc_tran_code,
                          pvc_delivery_channel
                     FROM vmscms.pcms_valid_cardstat);

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