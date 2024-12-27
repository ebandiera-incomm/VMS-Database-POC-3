create or replace
PACKAGE BODY        VMSCMS.VMSPRM
AS
   --FUNCTION return the clear PAN associated with input card id
   FUNCTION get_clr_pan (p_card_id_in IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_result   VARCHAR2 (20);
   BEGIN
      SELECT fn_dmaps_main (cap_pan_code_encr)
        INTO l_result
        FROM cms_appl_pan
       WHERE cap_card_id = SUBSTR (p_card_id_in, -12);

      RETURN l_result;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_result := NULL;
         RETURN l_result;
      WHEN OTHERS THEN
         l_result := NULL;
         RETURN l_result;
   END get_clr_pan;
END VMSPRM;
/
show error