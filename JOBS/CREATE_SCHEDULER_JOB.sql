BEGIN
sys.dbms_scheduler.create_job( 
job_name => 'VMSCMS.SWEEP_JOB_YEAREND',
job_type => 'PLSQL_BLOCK',
job_action      => '
BEGIN 
  VMSCMS.VMSAUTOJOBS.SWEEP_ACCT_JOB_YEAREND();
END;
',
repeat_interval => 'FREQ=YEARLY;INTERVAL=1',
start_date => to_timestamp_tz('2021-12-31 23:45:00 America/New_York', 'YYYY-MM-DD HH24:MI:SS TZR'),
job_class => 'DEFAULT_JOB_CLASS',
comments => 'To Sweep the amount once the date is expired for yearend sweep enable products',
auto_drop => FALSE,
enabled => FALSE);
sys.dbms_scheduler.set_attribute( name => 'VMSCMS.SWEEP_JOB_YEAREND', attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_OFF); 
sys.dbms_scheduler.set_attribute( name => 'VMSCMS.SWEEP_JOB_YEAREND', attribute => 'restartable', value => TRUE); 
sys.dbms_scheduler.enable( 'VMSCMS.SWEEP_JOB_YEAREND' ); 
DBMS_OUTPUT.PUT_LINE('SCHEDULER JOB SWEEP_JOB_YEAREND CREATED SUCCESSFULLY');
END;
/

