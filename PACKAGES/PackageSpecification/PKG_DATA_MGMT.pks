create or replace 
PACKAGE vmscms.PKG_DATA_MGMT IS
   -- Author  : Prakash Ranade
   -- Created : 08 Feb 2019
   -- Purpose : Package for purging and adding partitions
   --This module is not designed to be executed in parallel

	--Main function. This function will be executed from the scheduled database job
   FUNCTION init
   (
      p_process_name_in vmscms.DATA_MGMT_LOG.PROCESS_NAME%TYPE,
      p_run_date_in     vmscms.data_mgmt_log.process_run_dttm%TYPE DEFAULT SYSDATE
   ) RETURN BOOLEAN;
   g_success        vmscms.data_mgmt_log.step_run_status%type :='SUCCESS';
   g_processing     vmscms.data_mgmt_log.step_run_status%type :='PROCESSING';
   g_failed         vmscms.data_mgmt_log.step_run_status%type :='FAILED';
END PKG_DATA_MGMT;
/
