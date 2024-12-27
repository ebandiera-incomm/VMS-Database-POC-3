CREATE OR REPLACE PACKAGE VMSCMS.KEYACCESS AS

FUNCTION get3DESDEKKey
  return VARCHAR2
AS
  LANGUAGE java
    NAME 'javasp.KeyAccess.get3DESDEKKey() return java.lang.String';

FUNCTION getAESDEKKey
  return VARCHAR2
AS
  LANGUAGE java
    NAME 'javasp.KeyAccess.getAESDEKKey() return java.lang.String';

FUNCTION decryptKEY3DES(Param1 VARCHAR2, Param2 VARCHAR2, Param3 RAW)
  return VARCHAR2
AS
  LANGUAGE java
    NAME 'javasp.KeyAccess.decryptKEY3DES(java.lang.String, java.lang.String, byte[]) return java.lang.String';

FUNCTION getAesKey
  return VARCHAR2
AS
  LANGUAGE java
    NAME 'javasp.KeyAccess.getAesKey() return java.lang.String';
end;
/
show error