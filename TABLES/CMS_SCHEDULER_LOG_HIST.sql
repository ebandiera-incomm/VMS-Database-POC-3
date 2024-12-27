ALTER TABLE vmscms.cms_scheduler_log_hist ADD CSL_PROCESS_MSG1 CLOB;

UPDATE vmscms.cms_scheduler_log_hist SET CSL_PROCESS_MSG1=CSL_PROCESS_MSG;

ALTER TABLE vmscms.cms_scheduler_log_hist drop (CSL_PROCESS_MSG);

ALTER TABLE vmscms.cms_scheduler_log_hist rename column CSL_PROCESS_MSG1 to CSL_PROCESS_MSG;