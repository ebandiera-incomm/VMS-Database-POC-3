CREATE OR REPLACE FUNCTION vmscms_history.fn_kek_decr
    RETURN VARCHAR2
    RESULT_CACHE
    DETERMINISTIC
IS
    /*************************************************
         * Created Date     : 02/May/2023
         * Created By       : Mohan kumar E
         * PURPOSE          : VMS_7147 – Port Java methods used by VMS PL/SQL code
         * Reviewed By    	: Pankaj S
         * Release Number   : VMSGPRHOST R80
      *************************************************/

    l_output_str     VARCHAR2 (4000);
    l_decrkey           RAW (2000);
    l_encr_type   PLS_INTEGER
        :=  DBMS_CRYPTO.ENCRYPT_3DES        
			+ DBMS_CRYPTO.CHAIN_ECB
			+ DBMS_CRYPTO.PAD_PKCS5;
    l_decr_out          RAW (2000);
    l_tmp_val        RAW (2000);
BEGIN
    SELECT SUBSTR (UTL_ENCODE.quoted_printable_decode (vkd_encrypted_kek),6,48)
      INTO l_decrkey
      FROM vmscms_history.vms_kek_details
     WHERE vkd_key_index = 1;

    SELECT CKD_ENCRYPTED_AESKEY
      INTO l_tmp_val
      FROM VMSCMS.cms_key_details
     WHERE ckd_key_index = 1;
     
    l_decr_out := DBMS_CRYPTO.decrypt (l_tmp_val, l_encr_type, l_decrkey);
    
    l_output_str := UTL_RAW.CAST_TO_VARCHAR2(l_decr_out);
    RETURN l_output_str;
EXCEPTION
    WHEN OTHERS
    THEN
        RETURN NULL;
END;
/
