CREATE OR REPLACE FUNCTION VMSCMS.log_msg (msg VARCHAR2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
-- the following insert does not violate the constraint
-- WNDS because this is an autonomous routine
INSERT INTO debug_output VALUES (msg);
COMMIT;
RETURN msg;
END;
/


