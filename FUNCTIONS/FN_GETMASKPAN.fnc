CREATE OR REPLACE FUNCTION VMSCMS.fn_getmaskpan(p_user_pan VARCHAR2)
RETURN VARCHAR2 deterministic
AS
   v_pan            VARCHAR (40);
/**************************************************
     * Created Date                 : 21/JAN/2010.
     * Created By                    : Bhushan Kotkar.
     * Purpose                       : Pan Masking.
     * Last Modification Done by :
     * Last Modification Date   :
 **************************************************/
   pan              VARCHAR2 (30);
   v_first          VARCHAR (10);
   v_encrypt        VARCHAR (30);
   v_last           VARCHAR (10);
   --v_data_display   VARCHAR (10); -- commented by Yogesh on 1-Feb-2011
   v_length         NUMBER (30);
   v_masking_char   VARCHAR2 (10);
   pan_not_found    EXCEPTION;
   v_no             number(2):=10;  -- Added by Yogesh on

BEGIN
   pan := p_user_pan;

   IF pan IS NULL
   THEN
      RAISE pan_not_found;
   END IF;

       v_masking_char := 'XXXXXXXXXX';


            v_first := SUBSTR (pan, 1, 6);
            v_last := SUBSTR (pan, -4, 4);


            --v_length := (LENGTH (pan) - LENGTH (v_first) - LENGTH (v_last));
            v_length := (LENGTH (pan) - v_no);

            v_encrypt :=
               TRANSLATE (SUBSTR (pan, 7, v_length),
                          '0123456789',
                          v_masking_char
                         );

           v_pan := v_first || v_encrypt || v_last;



   RETURN v_pan;
EXCEPTION
   WHEN pan_not_found
   THEN
      RETURN pan;
   WHEN OTHERS
   THEN
      RETURN v_pan;
END;
/*********************PAN NO.,Acct No Masking Function*****************************
 * Example
 * Clear Pan :-1234567890123456789.
 * Masked Pan:-123456*********6789.
***********************************************************************************/
/
show error

