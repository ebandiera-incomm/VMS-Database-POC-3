CREATE OR REPLACE FUNCTION VMSCMS.FN_DMAPS_MAIN_PAN(PRM_IN_VAL RAW)
  RETURN VARCHAR2 DETERMINISTIC IS
  --OUTPUT_STRING VARCHAR2(200); --T.Narayanan changed to increase the length of the output string
  OUTPUT_STRING VARCHAR2(4000);

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
     * PURPOSE          :  For Key Decryption with new logic
      * Modified By      :  T.Narayanaswamy
     * Modified Date    :  19-July-12
     * Modified Reason  :  to increase the  length of the output string
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  20-July-2012
      * Build Number     :  CMS3.5.1_RI0012_B0005
  *************************************************/

  DECRKEY RAW(2000);
  ------------------------------Sn total encryption type-----------------------------------
  ENCRYPTION_TYPE PLS_INTEGER := DBMS_CRYPTO.ENCRYPT_AES256 +
						   DBMS_CRYPTO.CHAIN_CBC +
						   DBMS_CRYPTO.PAD_PKCS5;
  DECR_OUT        RAW(2000);
  ERRMSG          VARCHAR2(500);
  V_EXCEPTION EXCEPTION;
  ----------------------Sn This Function Is Used for Decryption Of any Varchar Value------------------------
BEGIN
  ----------------------------------Sn Call Java function to get the Clear DEK--------------------------

  DECRKEY := KEYACCESS_HSM.GETPANKEY();

  --------------------------Sn Call DBMS_CRYPTO, Used to Create Decrypted value of the input---------------------
  DECR_OUT := DBMS_CRYPTO.DECRYPT(PRM_IN_VAL, ENCRYPTION_TYPE, DECRKEY);
  --------------------Sn  Fetch The Decrypted Value From the function and convert it from RAW to VARCHAR2-------------
  OUTPUT_STRING := UTL_I18N.RAW_TO_CHAR(DECR_OUT, 'AL32UTF8');
  IF INSTR(OUTPUT_STRING, 'INCOMM') > 0 THEN
    OUTPUT_STRING := REPLACE(OUTPUT_STRING, 'INCOMM', '');
    RETURN OUTPUT_STRING;
  ELSE
    ERRMSG := 'DATA VERIFICATION FAILED';
    RAISE V_EXCEPTION;
  END IF;

EXCEPTION
  WHEN V_EXCEPTION THEN
    ERRMSG := 'Exception when checking the data ' || ERRMSG;
    RETURN ERRMSG;
  WHEN OTHERS THEN
    ERRMSG := 'Invalid Key Exception' || SQLERRM || SQLCODE;
    RETURN ERRMSG;
END;
/
SHOW ERROR;