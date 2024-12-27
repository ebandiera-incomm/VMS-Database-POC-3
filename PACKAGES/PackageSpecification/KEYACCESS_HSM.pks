CREATE OR REPLACE PACKAGE VMSCMS.KEYACCESS_HSM AS

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
      * PURPOSE          :  To get the key values
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  20-Apr-2012
      * Build Number     :  CMS3.5.1_RI0008_B00022
  *************************************************/

  FUNCTION GETPANKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessHSM.getPANKey() return java.lang.String';

  FUNCTION GETSSNKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessHSM.getSSNKey() return java.lang.String';

  FUNCTION GETMMNKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessHSM.getMMNKey() return java.lang.String';

  FUNCTION GETACCKEY RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.KeyAccessHSM.getACCKey() return java.lang.String';

  FUNCTION ENCRYPTDEK(PARAM1 VARCHAR2,
				  PARAM2 VARCHAR2,
				  PARAM3 VARCHAR2,
				  PARAM4 VARCHAR2) RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.HSMResponse.hsmRequest(java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String';

  FUNCTION DECRYPTDEK(PARAM1 VARCHAR2,
				  PARAM2 VARCHAR2,
				  PARAM3 VARCHAR2,
				  PARAM4 VARCHAR2) RETURN VARCHAR2 AS
    LANGUAGE JAVA NAME 'javasp.HSMResponse.hsmRequest(java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String';

END;
/


