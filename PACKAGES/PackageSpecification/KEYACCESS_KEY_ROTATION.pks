CREATE OR REPLACE PACKAGE VMSCMS.KEYACCESS_KEY_ROTATION AS

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
      * PURPOSE          :  To get the key values
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  20-Apr-2012
      * Build Number     :  CMS3.5.1_RI0008_B00022
  *************************************************/

  FUNCTION GETPANKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessRotation.getPANKey() return java.lang.String';

  FUNCTION GETSSNKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessRotation.getSSNKey() return java.lang.String';

  FUNCTION GETMMNKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessRotation.getMMNKey() return java.lang.String';

  FUNCTION GETACCKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessRotation.getACCKey() return java.lang.String';

END;
/


