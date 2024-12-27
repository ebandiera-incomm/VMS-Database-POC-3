CREATE OR REPLACE FUNCTION vmscms.fn_emaps_main_b2b (prm_in_val    VARCHAR2,
                                                     prm_key_in    RAW)
   RETURN RAW
   DETERMINISTIC
IS

/************************************************************************************************************

    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 28-April-2021
    * Modified For     : VMS-4192 - Order V2 is failing for Virtual Product.
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0002

************************************************************************************************************/ 


   l_encr_out          RAW (4000);
   l_encryption_type   PLS_INTEGER
      :=   DBMS_CRYPTO.encrypt_aes256
         + DBMS_CRYPTO.chain_ecb
         + DBMS_CRYPTO.pad_pkcs5;
BEGIN
   l_encr_out :=
      DBMS_CRYPTO.encrypt (UTL_I18N.string_to_raw (prm_in_val, 'AL32UTF8'),
                           l_encryption_type,
                           prm_key_in);
   RETURN l_encr_out;
END;
/
SHOW ERROR