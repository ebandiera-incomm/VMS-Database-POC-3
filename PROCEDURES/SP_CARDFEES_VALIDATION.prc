CREATE OR REPLACE PROCEDURE VMSCMS.sp_cardfees_validation (
   l_cce_inst_code        IN       NUMBER,
   l_cce_pan_code         IN       VARCHAR2,
   l_cce_mbr_numb         IN       NUMBER,
   l_cce_fee_type         IN       NUMBER,
   l_cce_fee_code         IN       NUMBER,
   l_cce_valid_from_old   IN       DATE,
   l_cce_valid_to_old     IN       DATE,
   l_cce_valid_from_new   IN       DATE,
   l_cce_valid_to_new     IN       DATE,
   l_cce_cardfee_id       IN       NUMBER,
   l_err                  OUT      VARCHAR2,
   --v_cpw_fee_code_count   OUT      NUMBER,
   v_message              OUT      NUMBER
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 16/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Checking Attached Fee before Update
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_count_fee          NUMBER;
   v_cft_feetype_desc   cms_fee_types.cft_feetype_desc%TYPE;

   CURSOR cur_card_fees
   IS
      SELECT cce_fee_code, cce_valid_from, cce_valid_to
        /*Check any fee is attached with the criteria and date range*/
      FROM   cms_card_excpfee
       WHERE cce_inst_code = l_cce_inst_code
         AND cce_fee_type = l_cce_fee_type
         AND cce_pan_code = l_cce_pan_code
         AND cce_mbr_numb = l_cce_mbr_numb
         -- AND cpf_fee_code = l_cpf_fee_code
         AND cce_cardfee_id <> l_cce_cardfee_id
         AND (   (cce_valid_from BETWEEN l_cce_valid_from_new
                                     AND l_cce_valid_to_new
                 )
              OR (cce_valid_to BETWEEN l_cce_valid_from_new AND l_cce_valid_to_new
                 )
              OR (l_cce_valid_from_new BETWEEN cce_valid_from AND cce_valid_to
                 )
              OR (l_cce_valid_to_new BETWEEN cce_valid_from AND cce_valid_to
                 )
             );
BEGIN                                           --Main Begin Block Starts Here
   l_err := 'OK';
   v_message := 0;

   BEGIN
--Sn check-- there is any same type of fee is attached when we gone  for update
      BEGIN
         SELECT cft_feetype_desc
           INTO v_cft_feetype_desc
           FROM cms_fee_types
          WHERE cft_feetype_code = l_cce_fee_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_err := 'FEE TYPE NOT DEFINED';
         WHEN OTHERS
         THEN
            l_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
      /* find the fee type description*/
      END;

      IF v_cft_feetype_desc = 'TRANSACTION FEE'
      THEN
         FOR x IN cur_card_fees
         LOOP
            IF (l_cce_fee_code = x.cce_fee_code)
            THEN
/* check that existing fee code and new fee code is same or not if same then error*/
               v_message := 1;
            ELSE                 /*if fee code is different then go in side */
               BEGIN
                  SELECT COUNT (cce.cce_fee_code)
                    INTO v_count_fee
/* check the new fee parameter like CFM_DELIVERY_CHANNEL,CFM_TRAN_TYPE,CFM_TRAN_MODE are same or not  if same then error msg*/
                  FROM   cms_card_excpfee cce,
                         cms_fee_types cft,
                         cms_fee_mast cfm1,                              --old
                         cms_fee_mast cfm2                               --new
                   WHERE cft.cft_feetype_desc = 'TRANSACTION FEE'
                     AND cce.cce_fee_type = cft.cft_feetype_code
                     AND cce.cce_fee_code = cfm1.cfm_fee_code
                     AND cfm1.cfm_fee_code = x.cce_fee_code
                     AND cfm2.cfm_fee_code = l_cce_fee_code
                     AND cce.cce_inst_code = cfm1.cfm_inst_code
                     AND cfm1.cfm_inst_code = cfm2.cfm_inst_code
                     AND cce.cce_fee_type = cfm2.cfm_feetype_code
                     AND cfm1.cfm_feetype_code = cfm2.cfm_feetype_code
                     AND NVL (cfm1.cfm_delivery_channel, 0) =
                                            NVL (cfm2.cfm_delivery_channel, 0)
                     AND NVL (cfm1.cfm_tran_type, 0) =
                                                   NVL (cfm2.cfm_tran_type, 0)
                     AND NVL (cfm1.cfm_tran_code, 0) =
                                                   NVL (cfm2.cfm_tran_code, 0)
                     AND NVL (cfm1.cfm_tran_mode, 0) =
                                                   NVL (cfm1.cfm_tran_mode, 0);

                  IF v_count_fee > 0
                  THEN
                     v_message := 1;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_message := 0;
                  WHEN OTHERS
                  THEN
                     l_err :=
                           'Same fee is already attached with the Fee Type'
                        || v_cft_feetype_desc
                        || 'between this date range From'
                        || l_cce_valid_from_new
                        || 'and to'
                        || l_cce_valid_to_new
                        || SQLERRM;
               END;
            END IF;

            EXIT WHEN cur_card_fees%NOTFOUND;
         END LOOP;
      ELSIF v_cft_feetype_desc = 'SUPPORT FUNCTION FEE'
      THEN
         FOR x IN cur_card_fees
         LOOP
            IF (l_cce_fee_code = x.cce_fee_code)
            THEN
/* check that existing fee code and new fee code is same or not if same then error*/
               v_message := 1;
            ELSE                 /*if fee code is different then go in side */
               BEGIN
                  SELECT COUNT (cce.cce_fee_code)
                    INTO v_count_fee
/* check the new fee parameter like CFM_DELIVERY_CHANNEL,CFM_TRAN_TYPE,CFM_TRAN_MODE are same or not  if same then error msg*/
                  FROM   cms_card_excpfee cce,
                         cms_fee_types cft,
                         cms_fee_mast cfm1,                              --old
                         cms_fee_mast cfm2                               --new
                   WHERE cft.cft_feetype_desc = 'SUPPORT FUNCTION FEE'
                     AND cce.cce_fee_type = cft.cft_feetype_code
                     AND cce.cce_fee_code = cfm1.cfm_fee_code
                     AND cfm1.cfm_fee_code = x.cce_fee_code
                     AND cfm2.cfm_fee_code = l_cce_fee_code
                     AND cce.cce_inst_code = cfm1.cfm_inst_code
                     AND cfm1.cfm_inst_code = cfm2.cfm_inst_code
                     AND cce.cce_fee_type = cfm2.cfm_feetype_code
                     AND cfm1.cfm_feetype_code = cfm2.cfm_feetype_code
                     AND NVL (cfm1.cfm_delivery_channel, 0) =
                                            NVL (cfm2.cfm_delivery_channel, 0)
                     AND NVL (cfm1.cfm_tran_type, 0) =
                                                   NVL (cfm2.cfm_tran_type, 0)
                     AND NVL (cfm1.cfm_tran_code, 0) =
                                                   NVL (cfm2.cfm_tran_code, 0)
                     AND NVL (cfm1.cfm_tran_mode, 0) =
                                                   NVL (cfm1.cfm_tran_mode, 0);

                  IF v_count_fee > 0
                  THEN
                     v_message := 1;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_message := 0;
                  WHEN OTHERS
                  THEN
                     l_err :=
                           'Same fee is already attached with the Fee Type'
                        || v_cft_feetype_desc
                        || 'between this date range From'
                        || l_cce_valid_from_new
                        || 'and to'
                        || l_cce_valid_to_new
                        || SQLERRM;
               END;
            END IF;

            EXIT WHEN cur_card_fees%NOTFOUND;
         END LOOP;
      ELSE                       /* if fee type is not transaction fee then */
         FOR x IN cur_card_fees
         LOOP
            IF cur_card_fees%ROWCOUNT > 0
            THEN
               /* cursor count if greater then 0 that means same fee is already attached*/
               v_message := 1;
            END IF;

            EXIT WHEN cur_card_fees%NOTFOUND;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err :=
               'Same fee is already attached with the Fee Type'
            || v_cft_feetype_desc
            || 'between this date range From'
            || l_cce_valid_from_new
            || 'and to'
            || l_cce_valid_to_new
            || SQLERRM;
   END;
--En check-- there is any same type of fee is attached when we gone  for update
--------------------------------------------------------------------------------------------------------
EXCEPTION
   WHEN OTHERS
   THEN
      l_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;                                                      --En Maibn begin end
/


show error