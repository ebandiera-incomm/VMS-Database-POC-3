CREATE OR REPLACE FUNCTION VMSCMS.Gethash (clearData VARCHAR2)
   RETURN VARCHAR2  AS LANGUAGE JAVA
   NAME 'GetSHA256Hash.encrypt(java.lang.String) return java.lang.String';
/
show error