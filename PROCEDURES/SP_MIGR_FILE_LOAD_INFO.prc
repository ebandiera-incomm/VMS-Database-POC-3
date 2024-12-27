CREATE OR REPLACE PROCEDURE VMSCMS.SP_MIGR_FILE_LOAD_INFO
(prm_file_name IN VARCHAR2,
 prm_file_status IN VARCHAR2,
 prm_seqno       IN NUMBER      --v_migr_seqno added on 12-JUL-2013
)
AS
PRAGMA autonomous_transaction;
BEGIN
INSERT INTO migr_file_load_info(MFI_FILE_NAME,
                                MFI_PROCESS_STATUS,
                                MFI_PROCESS_DATE,
								mfi_migr_seqno      --added on 12-JUL-2013
                                )
                          VALUES(prm_file_name,
                                 prm_file_status,
                                 SYSDATE,
								 prm_seqno          --added on 12-JUL-2013
                                );
COMMIT;
END;
/
SHOW ERRORS;