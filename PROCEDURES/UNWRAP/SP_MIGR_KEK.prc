create or replace PROCEDURE  vmscms_history.sp_migr_kek (
    p_option_in         VARCHAR2 DEFAULT 'M',    --'M'- Migration of kek , 'U'- update kek
    p_old_kek_in        RAW, --in case 'M' pass existing kek from keystore file, in case of 'U' pass old kek from vms_kek_details
    p_new_kek_in        RAW DEFAULT null, --in case 'M' pass null if want to use same kek from keystore else pass new kek, in case of 'U' pass new kek to update
    p_err_msg_out   OUT VARCHAR2)
IS   

 /*************************************************
         * Created Date     : 02/May/2023
         * Created By       : Mohan kumar E
         * PURPOSE          : VMS_7147 – Port Java methods used by VMS PL/SQL code
         * Reviewed By    	: Pankaj S
         * Release Number   : VMSGPRHOST R80
      *************************************************/
	  
    l_enc_kek     RAW (2000);
    l_kek         RAW (2000);
    l_encr_type   PLS_INTEGER
        :=   DBMS_CRYPTO.encrypt_aes256
           + DBMS_CRYPTO.chain_cbc
           + DBMS_CRYPTO.pad_pkcs5;
    l_encrkey     RAW (2000);
    l_dek         RAW (2000);
	l_cnt		  number;
	l_excp        EXCEPTION;
BEGIN
    p_err_msg_out := 'OK';

    IF p_old_kek_in IS NULL
    THEN
        p_err_msg_out := 'Input old_kek is NULL';
		RAISE l_excp;
    END IF;

    IF p_option_in = 'M' THEN
        l_kek := p_old_kek_in;
		
		
    ELSE
        IF p_new_kek_in IS NULL THEN
            p_err_msg_out := 'Input new_kek is NULL';
			RAISE l_excp;
        END IF;

        SELECT CKD_ENCRYPTED_AESKEY
          INTO l_dek
          FROM vmscms.cms_key_details
         WHERE ckd_key_index = 1;		

        l_kek :=SUBSTR (UTL_ENCODE.quoted_printable_decode (p_old_kek_in), 6, 64);
			
		IF l_kek != p_new_kek_in THEN
			l_dek := DBMS_CRYPTO.decrypt (l_dek, l_encr_type, l_kek);
			l_dek := UTL_I18N.RAW_TO_CHAR(l_dek, 'AL32UTF8');
			l_kek := p_new_kek_in;
			l_encrkey := DBMS_CRYPTO.encrypt (UTL_I18N.string_to_raw (l_dek, 'AL32UTF8'),l_encr_type, l_kek);
		ELSE
			p_err_msg_out := 'Old ad New KEK is same';
			RAISE l_excp;
		END IF;	
    END IF;
	
	
		SELECT UTL_ENCODE.quoted_printable_encode (
               (   SUBSTR (DBMS_CRYPTO.randombytes (5), 1, 5)
                || l_kek
                || SUBSTR (DBMS_CRYPTO.randombytes (5), 6, 5)))
		INTO l_enc_kek
		FROM DUAL;
    
	  
    IF p_option_in = 'M' THEN		
        SELECT COUNT(*)
		INTO l_cnt
		FROM vmscms_history.vms_kek_details;
		
        IF l_cnt=0 then
			INSERT INTO vmscms_history.vms_kek_details
				 VALUES (1, l_enc_kek);
		ELSE
			p_err_msg_out := 'KEK migr is already done';
			RAISE l_excp;
        END IF;
		
    ELSE
        UPDATE vmscms.cms_key_details
           SET CKD_ENCRYPTED_AESKEY = l_encrkey
         WHERE ckd_key_index = 1;

        UPDATE vmscms_history.vms_kek_details
           SET vkd_encrypted_kek = l_enc_kek
         WHERE vkd_key_index = 1;
    END IF;

    COMMIT;
EXCEPTION
    WHEN l_excp THEN
		ROLLBACK;
	WHEN OTHERS THEN
	    ROLLBACK;
        p_err_msg_out := 'Err in kek migr-' || SUBSTR (SQLERRM, 1, 200);
END;
/