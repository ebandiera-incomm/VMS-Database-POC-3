CREATE OR REPLACE FUNCTION VMSCMS.FN_EMAPS_MAIN_KEY_ROTATION(PRM_IN_VAL VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC IS
  ENCR_OUT RAW(2000);

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
      * PURPOSE          :  For Key Rotation
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  20-Apr-2012
      * Build Number     : CMS3.5.1_RI0008_B00022
  *************************************************/

  ENCRKEY RAW(2000);
  ---------------------Sn total encryption type-----------------------
  ENCRYPTION_TYPE PLS_INTEGER := DBMS_CRYPTO.ENCRYPT_AES256 +
						   DBMS_CRYPTO.CHAIN_CBC +
						   DBMS_CRYPTO.PAD_PKCS5;
  ERRMSG          VARCHAR2(500);
  -----------------Sn Function Is used for Encryption of any Varchar value---------------------
BEGIN
  ------------------------------Sn Call Java function to get the Clear DEK---------------------------

  ENCRKEY := KEYACCESS_KEY_ROTATION.GETPANKEY();

  --------------------------Sn Call DBMS_CRYPTO, Used to Create Encrypt input Value--------------------------------
  ENCR_OUT := DBMS_CRYPTO.ENCRYPT(UTL_I18N.STRING_TO_RAW(PRM_IN_VAL ||
											  'INCOMM',
											  'AL32UTF8'),
						    ENCRYPTION_TYPE,
						    ENCRKEY);
  RETURN ENCR_OUT;
EXCEPTION
  WHEN OTHERS THEN
    ERRMSG := 'Exception when Encrption :' || SQLERRM;
    RETURN ERRMSG;
END;
/


