create or replace
FUNCTION        vmscms.FN_DMAPS_MAIN(PRM_IN_VAL_IN varchar2) RETURN VARCHAR2
  DETERMINISTIC IS
  --   output_string     VARCHAR2 (200); T.Narayanan Changed to increase the length
  OUTPUT_STRING VARCHAR2(4000);
  /*************************************************
     * VERSION             :  NAB 3X.
     * Created Date       : 27/July/2009
     * Created By        : Kaustubh.Dave
     * Modified By      :  T.Narayanaswamy
     * Modified Date    :  19-July-12
     * Modified Reason  :  to increase the  length of the output string
     * Reviewed By   : B.Besky Anand.
     * Build Number     :  CMS3.5.1_RI0012_B0005
	 *************************************************
  
	 * Modified By      :  Mohan Kumar E
     * Modified Date    :  02-May-2023
     * Modified Reason  :  VMS_7147 – Port Java methods used by VMS PL/SQL code
     * Reviewed By   	:  Pankaj S
     * Release Number   :  VMSGPRHOST R80
  *************************************************/
  DECRKEY RAW(2000);
  ------------------------------Sn total encryption type-----------------------------------
  ENCRYPTION_TYPE PLS_INTEGER := DBMS_CRYPTO.ENCRYPT_AES256 +
						   DBMS_CRYPTO.CHAIN_CBC +
						   DBMS_CRYPTO.PAD_PKCS5;
  DECR_OUT        RAW(2000);
  ERRMSG          VARCHAR2(500);
  KRANDOM         RAW(2000);
  PRM_IN_VAL    RAW(2000);
  ----------------------Sn This Function Is Used for Decryption Of any Varchar Value------------------------
BEGIN
    PRM_IN_VAL:=PRM_IN_VAL_IN;
  ----------------------------------Sn Call Java function to get the Clear DEK--------------------------
  --decrkey := UTL_I18N.string_to_raw (keyaccess.getaesdekkey, 'AL32UTF8');
  --DECRKEY := KEYACCESS.GETAESKEY;-- Commented for VMS_7147
  --decrkey := fn_getaesdekkey;
  
    -- SN Added for VMS_7147
    decrkey:=vmscms_history.fn_kek_decr;
    -- EN Added for VMS_7147
  
  --------------------------Sn Call DBMS_CRYPTO, Used to Create Decrypted value of the input---------------------
  DECR_OUT := DBMS_CRYPTO.DECRYPT(PRM_IN_VAL, ENCRYPTION_TYPE, DECRKEY);
  --------------------Sn  Fetch The Decrypted Value From the function and convert it from RAW to VARCHAR2-------------
  OUTPUT_STRING := UTL_I18N.RAW_TO_CHAR(DECR_OUT, 'AL32UTF8');
  RETURN OUTPUT_STRING;
EXCEPTION
  when value_error then
      RETURN PRM_IN_VAL_IN;
  WHEN OTHERS THEN
    --ERRMSG := 'Invalid Key Exception' || SQLERRM || SQLCODE;
    RETURN PRM_IN_VAL_IN;
END;
/
SHOW ERROR;
/