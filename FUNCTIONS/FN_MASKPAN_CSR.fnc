CREATE OR REPLACE FUNCTION VMSCMS.Fn_MaskPan_csr (
   p_inst_code     IN   NUMBER,
   p_user_pan      IN   VARCHAR2,
   p_user_pin      IN   NUMBER
 )
   RETURN VARCHAR2
AS

/***************************************************************************
     * Created Date                : 07/Feb/2012.
     * Created By                  : Sagar More
     * Purpose                     : to mask pan depending upon sensitative
                                     data display flag defined for user.
     * Last Modification Done by   : Dhiraj M.G.
     * Last Modification Date      : 13-Feb-2012
     * Modification Reason         : to display mask pan code for users
                                     which are not in master table
     * Build Number                : RI0001B
 ****************************************************************************/


/*********************PAN NO. Masking Function********************************
 * Example
 * Clear Pan :-1234567890123456789.
 * Masked Pan:-123456*********6789.
******************************************************************************/

   v_pan            VARCHAR (40);
   errmsg VARCHAR2(100);
   pan              VARCHAR2 (30);
   v_first          VARCHAR (10);
   v_encrypt        VARCHAR (30);
   v_last           VARCHAR (10);
   v_data_display   VARCHAR (10);
   v_length         NUMBER (30);
   v_masking_char   VARCHAR2 (10);
   pan_not_found    EXCEPTION;
BEGIN

   Begin
    pan := Fn_Dmaps_Main(p_user_pan);

   exception when
   others
   then
   errmsg := 'Decryption error '||substr(sqlerrm,1,100);
   raise  pan_not_found;
   End;


   IF pan IS NULL or LENGTH (pan) < 10
   THEN
      errmsg := 'Invalid pan '||pan;
      RAISE pan_not_found;
   END IF;

  --Sn Get the Masking Access value from user mast for the perticular userpin---
   BEGIN

      SELECT cum_usermask_flag
        INTO v_data_display
        FROM CMS_USERDETL_MAST,CMS_USER_INST
       WHERE cui_inst_code = p_inst_code
       and   cum_user_code = cui_user_code
       and   cum_user_code = p_user_pin;


   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
      --commented on 13022012 Dhiraj G
        -- errmsg := 'No Data for the user pin' || p_user_pin;
         --RETURN errmsg;
          v_data_display :='N'; --added on 13022012 Dhiraj G

      WHEN OTHERS
      THEN
        --commented on 13022012 Dhiraj G
         --errmsg := 'Error' || p_user_pin || SUBSTR (SQLERRM, 1, 30);
         --RETURN errmsg;
          v_data_display :='N'; --added on 13022012 Dhiraj G
   END;

 --Sn Get the Masking Char from Inst param--
   BEGIN
      SELECT LPAD (cip_param_value, 10, cip_param_value)
        INTO v_masking_char
        FROM CMS_INST_PARAM
       WHERE cip_param_key = 'MASKINGCHAR' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_masking_char := '**********';
      WHEN OTHERS
      THEN
         errmsg := 'Error' || SUBSTR (SQLERRM, 1, 35);
         RETURN errmsg;
   END;

  --Sn Check the Masking Access value is N or Y--
   IF v_data_display = 'Y'

   THEN

         v_pan := pan;

   ELSIF v_data_display = 'N'
   THEN

            v_first := SUBSTR (pan, 1, 6);
            v_last := SUBSTR (pan, -4, 4);
            v_length := (LENGTH (pan) - LENGTH (v_first) - LENGTH (v_last));
            v_encrypt :=
               TRANSLATE (SUBSTR (pan, 7, v_length),
                          '0123456789',
                          v_masking_char
                         );
            v_pan := v_first || v_encrypt || v_last;


   ELSE

     errmsg := 'Invalid flag value '||v_data_display||' for pan '||pan;

     return errmsg;

   END IF;

   RETURN v_pan;
EXCEPTION
   WHEN pan_not_found
   THEN
     Return errmsg;
   WHEN OTHERS
   THEN
   errmsg:='Main exception '||substr(SQLERRM,1,100);
   Return errmsg;
END;
/


