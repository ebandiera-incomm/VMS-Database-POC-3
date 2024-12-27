CREATE OR REPLACE PROCEDURE VMSCMS.populate_mask_pan (
   p_prodcode_in       VARCHAR2,
   p_loopcounter_in    NUMBER,
   p_rownum_in         NUMBER)
IS
   l_err_msg   VARCHAR2 (500);
BEGIN
   FOR counter IN 1 .. p_loopcounter_in
   LOOP
      BEGIN
         UPDATE vmscms.cms_appl_pan_inv
            SET cap_mask_pan =
                   vmscms.fn_getmaskpan (vmscms.fn_dmaps_main (cap_pan_code_encr))
          WHERE cap_prod_code = p_prodcode_in
                AND cap_mask_pan <>
                       vmscms.fn_getmaskpan (vmscms.fn_dmaps_main (cap_pan_code_encr))
                AND ROWNUM <= p_rownum_in;
				
	     UPDATE vmscms.cms_appl_pan
            SET cap_mask_pan =
                   vmscms.fn_getmaskpan (vmscms.fn_dmaps_main (cap_pan_code_encr))
          WHERE cap_prod_code = p_prodcode_in
                AND cap_mask_pan <>
                       vmscms.fn_getmaskpan (vmscms.fn_dmaps_main (cap_pan_code_encr))
                AND ROWNUM <= p_rownum_in;


         IF SQL%ROWCOUNT = 0
         THEN
            EXIT;
         END IF;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
      END;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      l_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 200);
      DBMS_OUTPUT.put_line (l_err_msg);
END;
/

