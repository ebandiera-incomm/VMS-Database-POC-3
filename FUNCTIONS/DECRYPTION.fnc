CREATE OR REPLACE FUNCTION VMSCMS.decryption (encrypted_string VARCHAR2)
   RETURN VARCHAR2 DETERMINISTIC
AS
   key_string         VARCHAR2 (16)   := 'scottscottscotts';
   decrypted_string   VARCHAR2 (2048) := '';
BEGIN
   IF encrypted_string IS NOT NULL
   THEN
      DBMS_OBFUSCATION_TOOLKIT.des3decrypt
                                        (input_string          => encrypted_string,
                                         key_string            => key_string,
                                         decrypted_string      => decrypted_string
                                        );
   END IF;

   RETURN decrypted_string;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN encrypted_string;
      DBMS_OUTPUT.put_line (SQLCODE);
      DBMS_OUTPUT.put_line (SQLERRM);
END;
/
show error


