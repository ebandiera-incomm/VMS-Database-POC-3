CREATE OR REPLACE PROCEDURE vmscms.sp_check_bin (
   prm_inst_code      IN       NUMBER,
   prm_product_code   IN       VARCHAR2,
   prm_err_msg        OUT      VARCHAR2
)
IS
   v_check_flag   VARCHAR2 (1);
BEGIN
   SELECT cpm_prodmast_param1
     INTO v_check_flag
     FROM cms_prod_mast, cms_prod_bin
    WHERE cpm_inst_code = prm_inst_code
      AND cpm_prod_code = prm_product_code
      AND cpm_inst_code = cpb_inst_code
      AND cpm_prod_code = cpb_prod_code;

   IF v_check_flag IS NULL OR v_check_flag = 'N'
   THEN
      prm_err_msg := 'OK';
   ELSE
      prm_err_msg := 'Not a valid Bin ';
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      prm_err_msg := 'Product not found in master';
   WHEN OTHERS
   THEN
      prm_err_msg :=
              'Error while checking BIN details ' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR