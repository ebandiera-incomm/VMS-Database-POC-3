CREATE OR REPLACE PROCEDURE VMSCMS.sp_prodcattypefees_validation (
   l_cpf_inst_code        IN       NUMBER,
   l_cpf_prod_code        IN       VARCHAR2,
   l_cpf_card_type        IN       NUMBER,
   l_cpf_fee_type         IN       NUMBER,
   l_cpf_fee_code         IN       NUMBER,
   l_cpf_valid_from_old   IN       DATE,
   l_cpf_valid_to_old     IN       DATE,
   l_cpf_valid_from_new   IN       DATE,
   l_cpf_valid_to_new     IN       DATE,
   l_cpf_prodcattype_id   IN       NUMBER,
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

   CURSOR cur_prodcattype_fees
   IS
      SELECT cpf_fee_code, cpf_valid_from, cpf_valid_to
        /*Check any fee is attached with the criteria and date range*/
      FROM   cms_prodcattype_fees
       WHERE cpf_inst_code = l_cpf_inst_code
         AND cpf_fee_type = l_cpf_fee_type
         AND cpf_prod_code = l_cpf_prod_code
         AND cpf_card_type = l_cpf_card_type
         -- AND cpf_fee_code = l_cpf_fee_code
         AND cpf_prodcattype_id <> l_cpf_prodcattype_id
         AND (   (cpf_valid_from BETWEEN l_cpf_valid_from_new
                                     AND l_cpf_valid_to_new
                 )
              OR (cpf_valid_to BETWEEN l_cpf_valid_from_new AND l_cpf_valid_to_new
                 )
              OR (l_cpf_valid_from_new BETWEEN cpf_valid_from AND cpf_valid_to
                 )
              OR (l_cpf_valid_to_new BETWEEN cpf_valid_from AND cpf_valid_to
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
          WHERE cft_feetype_code = l_cpf_fee_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_err := 'FEE TYPE NOT DEFINED';
         WHEN OTHERS
         THEN
            l_err := 'Main Exception 1234' || SQLCODE || '---' || SQLERRM;
      /* find the fee type description*/
      END;

      IF v_cft_feetype_desc = 'TRANSACTION FEE'
      THEN
         FOR x IN cur_prodcattype_fees
         LOOP
            IF (l_cpf_fee_code = x.cpf_fee_code)
            THEN
/* check that existing fee code and new fee code is same or not if same then error*/
               v_message := 1;
            ELSE                 /*if fee code is different then go in side */
               BEGIN
                  SELECT COUNT (cpf.cpf_fee_code)
                    INTO v_count_fee
/* check the new fee parameter like CFM_DELIVERY_CHANNEL,CFM_TRAN_TYPE,CFM_TRAN_MODE are same or not  if same then error msg*/
                  FROM   cms_prodcattype_fees cpf,
                         cms_fee_types cft,
                         cms_fee_mast cfm1,                              --old
                         cms_fee_mast cfm2                               --new
                   WHERE cft.cft_feetype_desc = 'TRANSACTION FEE'
                     AND cpf.cpf_fee_type = cft.cft_feetype_code
                     AND cpf.cpf_fee_code = cfm1.cfm_fee_code
                     AND cfm1.cfm_fee_code = x.cpf_fee_code
                     AND cfm2.cfm_fee_code = l_cpf_fee_code
                     AND cpf.cpf_inst_code = cfm1.cfm_inst_code
                     AND cfm1.cfm_inst_code = cfm2.cfm_inst_code
                     AND cpf.cpf_fee_type = cfm2.cfm_feetype_code
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
                           'Same fee is already attached with the Fee Type '
                        || v_cft_feetype_desc
                        || ' between this date range From '
                        || l_cpf_valid_from_new
                        || ' and to '
                        || l_cpf_valid_to_new
                        || SQLERRM;
               END;
            END IF;

            EXIT WHEN cur_prodcattype_fees%NOTFOUND;
         END LOOP;
      ELSIF v_cft_feetype_desc = 'SUPPORT FUNCTION FEE'
      THEN
         FOR x IN cur_prodcattype_fees
         LOOP
            IF (l_cpf_fee_code = x.cpf_fee_code)
            THEN
/* check that existing fee code and new fee code is same or not if same then error*/
               v_message := 1;
            ELSE                 /*if fee code is different then go in side */
               BEGIN
                  SELECT COUNT (cpf.cpf_fee_code)
                    INTO v_count_fee
/* check the new fee parameter like CFM_DELIVERY_CHANNEL,CFM_TRAN_TYPE,CFM_TRAN_MODE are same or not  if same then error msg*/
                  FROM   cms_prodcattype_fees cpf,
                         cms_fee_types cft,
                         cms_fee_mast cfm1,                              --old
                         cms_fee_mast cfm2                               --new
                   WHERE cft.cft_feetype_desc = 'SUPPORT FUNCTION FEE'
                     AND cpf.cpf_fee_type = cft.cft_feetype_code
                     AND cpf.cpf_fee_code = cfm1.cfm_fee_code
                     AND cfm1.cfm_fee_code = x.cpf_fee_code
                     AND cfm2.cfm_fee_code = l_cpf_fee_code
                     AND cpf.cpf_inst_code = cfm1.cfm_inst_code
                     AND cfm1.cfm_inst_code = cfm2.cfm_inst_code
                     AND cpf.cpf_fee_type = cfm2.cfm_feetype_code
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
                           'Same fee is already attached with the Fee Type '
                        || v_cft_feetype_desc
                        || 'between this date range From '
                        || l_cpf_valid_from_new
                        || ' and to '
                        || l_cpf_valid_to_new
                        || SQLERRM;
               END;
            END IF;

            EXIT WHEN cur_prodcattype_fees%NOTFOUND;
         END LOOP;
      ELSE                       /* if fee type is not transaction fee then */
         FOR x IN cur_prodcattype_fees
         LOOP
            IF cur_prodcattype_fees%ROWCOUNT > 0
            THEN
               /* cursor count if greater then 0 that means same fee is already attached*/
               v_message := 1;
            END IF;

            EXIT WHEN cur_prodcattype_fees%NOTFOUND;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err :=
               'Same fee is already attached with the Fee Type '
            || v_cft_feetype_desc
            || 'between this date range From '
            || l_cpf_valid_from_new
            || ' and to '
            || l_cpf_valid_to_new
            || SQLERRM;
   END;
--En check-- there is any same type of fee is attached when we gone  for update
--------------------------------------------------------------------------------------------------------
EXCEPTION
   WHEN OTHERS
   THEN
      l_err := 'Main Exception 1234' || SQLCODE || '---' || SQLERRM;
END;                                                      --En Maibn begin end
/
SHOW ERRORS

