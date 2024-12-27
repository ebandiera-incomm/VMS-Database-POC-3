CREATE OR REPLACE FUNCTION VMSCMS.encryption (input_string VARCHAR2)
   RETURN VARCHAR2
AS
   replace_string     VARCHAR2 (16);
   key_string         VARCHAR2 (16) := 'scottscottscotts';
   encrypted_string   VARCHAR2 (50) := '';
BEGIN
   IF input_string IS NOT NULL
   THEN
      IF LENGTH (input_string) <= 16
      THEN
         replace_string := RPAD (input_string, 16, ' ');
         DBMS_OBFUSCATION_TOOLKIT.des3encrypt
                                        (input_string          => replace_string,
                                         key_string            => key_string,
                                         encrypted_string      => encrypted_string
                                        );
      END IF;
   END IF;

   RETURN encrypted_string;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN input_string;
      DBMS_OUTPUT.put_line (SQLCODE);
      DBMS_OUTPUT.put_line (SQLERRM);
END;
/
show error


