CREATE OR REPLACE PROCEDURE VMSCMS.sp_process_monitor (
   p_desc     IN   VARCHAR2,
   p_rownum   IN   VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO cms_process_monitor
        VALUES (p_desc, p_rownum);

   COMMIT;
END;
/

SHOW ERRORS;


