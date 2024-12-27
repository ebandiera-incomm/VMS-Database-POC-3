CREATE OR REPLACE TYPE vmscms.rectype AS OBJECT (
   file_name    VARCHAR2 (35 BYTE),
   file_count   NUMBER (20)
);
/
SHOW ERRORS;