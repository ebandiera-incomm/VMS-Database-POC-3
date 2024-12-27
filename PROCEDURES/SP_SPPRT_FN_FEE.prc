CREATE OR REPLACE PROCEDURE VMSCMS.sp_spprt_fn_fee (
   prm_card_number   IN       VARCHAR2,
   prm_spprt_key     IN       VARCHAR2,
   prm_tran_fee      OUT      NUMBER,
   prm_error         OUT      VARCHAR2,
   prm_fee_code      OUT      NUMBER
)
IS
/**********************************************************************************************************************
     * VERSION               :  1.1
     * DATE OF CREATION      : 27/MAY/2008
     * CREATED BY            : Sachin Nikam
     * PURPOSE               : PROCEDURE TO CALCULATE FEES FOR SUPPORT FUNCTION DONE.
     * MODIFICATION REASON   :
     *
     *
     * LAST MODIFICATION DONE BY :
     * LAST MODIFICATION DATE    :
     *
***********************************************************************************************************************/
   exp_main      EXCEPTION;
   v_fee_code    cms_fee_mast.cfm_fee_code%TYPE;
   v_flat_fee    cms_fee_mast.cfm_fee_amt%TYPE;
   v_prod_code   cms_appl_pan.cap_prod_code%TYPE;
   v_card_type   cms_appl_pan.cap_card_type%TYPE;
   v_card_fee    cms_fee_mast.cfm_fee_amt%TYPE;
   v_prod_fee    cms_fee_mast.cfm_fee_amt%TYPE;
BEGIN
   prm_error := 'OK';

---------------------------------------------
-- SN: TO GET PRO CODE AND TYPE CMS_APPL_PAN
---------------------------------------------
   BEGIN                                                          -- PAN DATE
      SELECT cap_prod_code, cap_card_type
        INTO v_prod_code, v_card_type
        FROM cms_appl_pan
       WHERE cap_pan_code = prm_card_number;
   EXCEPTION                                                       -- PAN DATE
      WHEN OTHERS
      THEN
         prm_error := 'ERROR FROM PAN DATA SECTION =>' || SQLERRM;
         RAISE exp_main;
   END;                                                            -- PAN DATE

---------------------------------------------
-- EN: TO GET PRO CODE AND TYPE CMS_APPL_PAN
---------------------------------------------

   -------------------------------------------------------------------------------------------------------
--SN*************************  TO GET FEE CHARGE FOR SUPPORT FUNCTION  *******************************
-------------------------------------------------------------------------------------------------------
   
   BEGIN                                                           -- CARD FEE
----------------------------------------------------
-- SN: TO CHEK FEE ATTACHED AT CARD LEVEL
----------------------------------------------------
      SELECT cfm_fee_code, cfm_fee_amt
        INTO v_fee_code, v_flat_fee
        FROM cms_fee_mast, cms_card_excpfee
       WHERE cfm_spprt_key = prm_spprt_key
         AND cce_pan_code = prm_card_number
         AND cfm_fee_code = cce_fee_code;
----------------------------------------------------
-- EN: TO CHEK FEE ATTACHED AT CARD LEVEL
----------------------------------------------------
   EXCEPTION                                                      --  CARD FEE
      WHEN NO_DATA_FOUND
      THEN
         BEGIN                                                    -- PROD FEE
-------------------------------------------------------
-- SN: PROCEDURE TO CHEK FEE ATTACHED AT PRODUCT LEVEL
-------------------------------------------------------
            SELECT cfm_fee_code, cfm_fee_amt
              INTO v_fee_code, v_flat_fee
              FROM cms_fee_mast, cms_prodcattype_fees
             WHERE cfm_spprt_key = prm_spprt_key
               AND cpf_prod_code = v_prod_code
               AND cpf_card_type = v_card_type
               AND cfm_fee_code = cpf_fee_code;
-------------------------------------------------------
-- SN: PROCEDURE TO CHEK FEE ATTACHED AT PRODUCT LEVEL
-------------------------------------------------------
         EXCEPTION                                                 -- PROD FEE
            WHEN NO_DATA_FOUND
            THEN
               prm_error := 'NO FEES ATTACHED';
               RAISE exp_main;                  -- NO FEES ATTACHED RETURN -1
            WHEN OTHERS
            THEN
               prm_error := 'ERROR FROM PROD FEE =>' || SQLERRM;
               RAISE exp_main;
         END;                                                      -- PROD FEE
      WHEN OTHERS
      THEN
         prm_error := 'ERROR FROM CARD FEE =>' || SQLERRM;
         RAISE exp_main;
   END;                                                            -- CARD FEE

   prm_fee_code := v_fee_code;                         --Sn To Return FEE_CODE

-------------------------------------------------------------------------------------------------------
--SN*************************  TO GET FEE CHARGE FOR SUPPORT FUNCTION  *******************************
-------------------------------------------------------------------------------------------------------

   -------------------------------------------------------
-- SN: IF % FEE IS NOT NULL OR ZERO THEN CALCULATE FEE
-------------------------------------------------------
   IF v_flat_fee IS NOT NULL AND v_flat_fee <> 0
   THEN
      prm_tran_fee := v_flat_fee;
   ELSE
      prm_error := 'FLAT FEE ERROR';
      RAISE exp_main;
   END IF;

   DBMS_OUTPUT.put_line ('SACHIN');
   DBMS_OUTPUT.put_line (prm_tran_fee);
-------------------------------------------------------
-- EN: IF % FEE IS NOT NULL OR ZERO THEN CALCULATE FEE
-------------------------------------------------------
EXCEPTION                                                              -- MAIN
   WHEN exp_main
   THEN
      prm_error := prm_error;
      prm_tran_fee := -1;
   WHEN OTHERS
   THEN
      prm_error := SQLERRM;
      prm_tran_fee := -1;
END;                                                                   -- MAIN
/


SHOW ERRORS