DECLARE
   v_cnt         NUMBER;
   v_err         VARCHAR2 (1000);
   v_chk_table   NUMBER;
BEGIN
   BEGIN
      SELECT COUNT (1)
        INTO v_chk_table
        FROM all_objects
       WHERE owner = 'VMSCMS'
         AND object_type = 'TABLE'
         AND object_name = 'PCMS_PROCESS_SCHEDULE_R1707B3';
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err := SUBSTR (SQLERRM, 1, 100);
         DBMS_OUTPUT.put_line ('While cheking for bkp object ' || v_err);
         RETURN;
   END;

   IF v_chk_table = 1
   THEN
      SELECT COUNT (*)
        INTO v_cnt
        FROM vmscms.pcms_process_schedule
       WHERE pps_process_id = 61;

      IF v_cnt = 0
      THEN
         Insert into vmscms.PCMS_PROCESS_SCHEDULE_R1707B3(PPS_PROCESS_ID,PPS_PROCESS_NAME,PPS_PROCESS_INTERVAL,PPS_SCHEDULE_DAYS,PPS_INS_USER,PPS_INS_DATE,PPS_START_HOUR,PPS_START_MIN,PPS_START_SEC,PPS_END_HOUR,PPS_END_MIN,PPS_END_SEC,PPS_FILE_ID,PPS_PROCESS_TYPE,PPS_PROCINTERVAL_TYPE,PPS_RETRY_CNT,PPS_DEP_SUBPROCESSID,PPS_SCHEDULER_STAT,PPS_MAIL_SUCCESS,PPS_MAIL_FAIL,PPS_DEP_PROCESSID,PPS_PROC_RUNNING,PPS_PROCRETRY_DATE,PPS_INST_CODE,PPS_PROCESS_CLASS,PPS_PROCESS_JOB,PPS_PROCESS_JOBGROUP,PPS_PROCESS_TRGR,PPS_PROCESS_TRGRGROUP,PPS_PROCCOMPLETE_FLAG,PPS_PROCCOMPLETE_DATE,PPS_EVENT_TYPE,PPS_FRONT_CONFIG,PPS_DAYOF_MONTH,PPS_MULTIRUN_INTERVAL,PPS_MULTIRUN_INTERVAL_TYPE,PPS_MULTIRUN_FLAG) 
			values (61,'PAN INVENTORY GENERATION',1,'*',999,SYSDATE,'18','55','0','18','57','0',1,'E','MM',2,null,'E','1','1',null,'N',SYSDATE,1,'cmsServlets.scheduler.PanInventoryProcess','PanInventoryProcessJob','PanInventoryProcessJobGroup','PanInventoryProcessTrigger','PanInventoryProcessTriggerGroup','N',sysdate,'O','Y',null,null,null,null);
      END IF;
	  
	  

      INSERT INTO vmscms.pcms_process_schedule
         SELECT *
           FROM vmscms.PCMS_PROCESS_SCHEDULE_R1707B3
          WHERE (pps_process_id) NOT IN (SELECT pps_process_id
                                           FROM vmscms.pcms_process_schedule);
          dbms_output.put_line(SQL%ROWCOUNT||' rows inserted');	
		  
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main exception ' || v_err);
END;
/