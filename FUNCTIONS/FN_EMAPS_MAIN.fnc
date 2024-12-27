CREATE OR REPLACE FUNCTION VMSCMS.FN_EMAPS_MAIN (prm_in_val VARCHAR2)
   RETURN RAW DETERMINISTIC
IS
   encr_out          RAW (2000);
/*************************************************
     * VERSION             :  NAB 3X.
     * Created Date       : 27/July/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Encryption Function Using Tripel DES(Data Encryption Standerd) Algo.
     * Modified By:    : Kaustubh D.
     * Modified Date  : 26/Oct/2009.
     * Reviewed By   : Chinmay B.
	  *************************************************
  
	 * Modified By      :  Mohan Kumar E
     * Modified Date    :  02-May-2023
     * Modified Reason  :  VMS_7147 – Port Java methods used by VMS PL/SQL code
     * Reviewed By   	:  Pankaj S
     * Release Number   :  VMSGPRHOST R80
  *************************************************/
   encrkey           RAW (2000);
   ---------------------Sn total encryption type-----------------------
   encryption_type   PLS_INTEGER
      :=   DBMS_CRYPTO.encrypt_aes256
         + DBMS_CRYPTO.chain_cbc
         + DBMS_CRYPTO.pad_pkcs5;
   errmsg            VARCHAR2 (500);
-----------------Sn Function Is used for Encryption of any Varchar value---------------------
BEGIN
   ------------------------------Sn Call Java function to get the Clear DEK---------------------------
   --encrkey := UTL_I18N.string_to_raw (keyaccess.getaesdekkey, 'AL32UTF8');
   --encrkey := keyaccess.getAesKey;-- Commented for VMS_7147
   --encrkey := fn_getAESDEKKey;
   --dbms_output.put_line('main'||fn_getAESDEKKey);
   --dbms_output.put_line(encrkey);
   
   
    -- SN Added for VMS_7147
	encrkey:=vmscms_history.fn_kek_decr;  
	-- EN Added for VMS_7147
	
   --------------------------Sn Call DBMS_CRYPTO, Used to Create Encrypt input Value--------------------------------
   encr_out :=
      DBMS_CRYPTO.encrypt (UTL_I18N.string_to_raw (prm_in_val, 'AL32UTF8'),
                           encryption_type,
                           encrkey
                   
             );
             dbms_output.put_line('encr_out7777'||encr_out);
   RETURN encr_out;
END;
/
show error;
/