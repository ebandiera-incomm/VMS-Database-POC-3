CREATE OR REPLACE PROCEDURE VMSCMS.sp_prodcattype_waiver_update (
   p_cpw_inst_code        IN       NUMBER,
   p_cpw_prod_code        IN       VARCHAR2,
   p_cpw_card_type        IN       NUMBER,
   p_cpw_fee_code         IN       NUMBER,
   p_cpw_waiv_prcnt       IN       NUMBER,
   p_cpw_valid_from_new   IN       DATE,
   p_cpw_valid_to_new     IN       DATE,
   p_cpw_valid_from_old   IN       DATE,
   p_cpw_valid_to_old     IN       DATE,
   p_cpw_waiv_desc        IN       VARCHAR2,
   p_cpw_flow_source      IN       VARCHAR2,
   p_cpw_ins_user         IN       NUMBER,
   p_cpw_ins_date         IN       DATE,
   p_cpw_lupd_user        IN       NUMBER,
   p_cpw_lupd_date        IN       DATE,
   p_cpw_fee_type         IN       NUMBER,
   p_cpw_waiv_id          IN       NUMBER,
   p_cpf_prodcattype_id   IN       NUMBER,
   p_err                  OUT      VARCHAR2
)
AS
   v_error                VARCHAR2 (100);
   v_count                NUMBER;
   v_message              NUMBER;
   v_cpw_valid_from_old   DATE;
   v_cpw_valid_to_old     DATE;
   v_cpw_valid_from_new   DATE;
   v_cpw_valid_to_new     DATE;
   v_cpf_valid_from       DATE;
   v_cpf_valid_to         DATE;
 /*************************************************
  * VERSION             :  1.0
  * Created Date       : 2/APR/2009
  * Created By        : Kaustubh.Dave
  * PURPOSE          : Validate all condition before update and update
  * Modified By:    :
  * Modified Date  :
***************************************************/
BEGIN                                                                      --1
   p_err := 'OK';
   --v_error := 'OK';
   --this procedure is used for validation, all type of validation is check in this procedure
   v_cpw_valid_from_old := p_cpw_valid_from_old;
   v_cpw_valid_to_old := p_cpw_valid_to_old;
   v_cpw_valid_from_new := p_cpw_valid_from_new;
   v_cpw_valid_to_new := p_cpw_valid_to_new;

   IF (v_cpw_valid_from_new <= v_cpw_valid_to_new)
   THEN
      BEGIN
         SELECT cpf_valid_from, cpf_valid_to
           INTO v_cpf_valid_from, v_cpf_valid_to
           FROM cms_prodcattype_fees
          WHERE cpf_inst_code = p_cpw_inst_code
            AND cpf_fee_code = p_cpw_fee_code
            AND cpf_prod_code = p_cpw_prod_code
            AND cpf_card_type = p_cpw_card_type
            AND cpf_fee_type = p_cpw_fee_type
            AND cpf_prodcattype_id = p_cpf_prodcattype_id
            AND TRUNC (v_cpw_valid_from_new) >= TRUNC (cpf_valid_from)
            AND TRUNC (v_cpw_valid_from_new) <= TRUNC (cpf_valid_to)
            AND TRUNC (v_cpw_valid_to_new) >= TRUNC (cpf_valid_from)
            AND TRUNC (v_cpw_valid_to_new) <= TRUNC (cpf_valid_to);

         IF SQL%FOUND
         THEN
            BEGIN
               --3
               SELECT COUNT (cpw_fee_code)
                 INTO v_count
                 FROM cms_prodcattype_waiv
                WHERE cpw_inst_code = p_cpw_inst_code
                  AND cpw_fee_code = p_cpw_fee_code
                  AND cpw_prod_code = p_cpw_prod_code
                  AND cpw_card_type = p_cpw_card_type
                  AND cpw_waiv_id <> p_cpw_waiv_id
                  AND (   (cpw_valid_from BETWEEN v_cpw_valid_from_new
                                              AND v_cpw_valid_to_new
                          )
                       OR (cpw_valid_to BETWEEN v_cpw_valid_from_new
                                            AND v_cpw_valid_to_new
                          )
                       OR (v_cpw_valid_from_new BETWEEN cpw_valid_from
                                                    AND cpw_valid_to
                          )
                       OR (v_cpw_valid_to_new BETWEEN cpw_valid_from
                                                  AND cpw_valid_to
                          )
                      );
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_count := 0;
               WHEN OTHERS
               THEN
                  p_err := 'Same waiver is attached' || v_count;
            END;                                                           --3

------------------------------------------------
            IF v_count = 0 AND p_err = 'OK'
-- if there is no fee attached with the waiver, No same fee attached between the date range and No error, then only we will allowed to update
            THEN
               IF (    TRUNC (v_cpw_valid_from_old) <= TRUNC (SYSDATE)
--if valid date from is less or equal to currdate and to date is grater then curr date then only ewe will update, if to date is equal to currdate then we can not update
                   AND TRUNC (v_cpw_valid_to_old) >= TRUNC (SYSDATE)
                   --AND TRUNC (v_cpw_valid_from_new) > TRUNC (SYSDATE)
                   AND TRUNC (v_cpw_valid_to_new) >= TRUNC (SYSDATE)
                  )
               THEN
                  UPDATE cms_prodcattype_waiv
                     SET cpw_valid_to = v_cpw_valid_to_new,
                         cpw_waiv_desc = p_cpw_waiv_desc
                   WHERE cpw_waiv_id = p_cpw_waiv_id;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_err := 'Update is not Done Record Not Found';
                  END IF;
               ELSIF (    TRUNC (v_cpw_valid_from_old) > TRUNC (SYSDATE)
                      AND TRUNC (v_cpw_valid_to_old) > TRUNC (SYSDATE)
                      AND TRUNC (v_cpw_valid_from_new) > TRUNC (SYSDATE)
                      AND TRUNC (v_cpw_valid_to_new) > TRUNC (SYSDATE)
                     )
               THEN
                  UPDATE cms_prodcattype_waiv
                     SET cpw_waiv_prcnt = p_cpw_waiv_prcnt,
                         cpw_valid_from = p_cpw_valid_from_new,
                         cpw_valid_to = p_cpw_valid_to_new,
                         cpw_waiv_desc = p_cpw_waiv_desc,
                         cpw_flow_source = p_cpw_flow_source,
                         cpw_lupd_user = p_cpw_lupd_user,
                         cpw_lupd_date = p_cpw_lupd_date
                   WHERE cpw_waiv_id = p_cpw_waiv_id;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_err := 'Update is not Done Record Not Found';
                  END IF;
               ELSE
                  p_err :=
                         'Date range Is not Proper or less then current date';
               END IF;
------------------------------------------------------------------------------------------------------------
            ELSIF v_count > 0 AND p_err = 'OK'
            THEN          -- else for, same date range condition checking fail
               p_err :=
                     'Same fee is already attached with the Fee Type'
                  || p_cpw_fee_type
                  || 'between this date range From'
                  || v_cpw_valid_from_new
                  || 'and to'
                  || v_cpw_valid_to_new;
            ELSIF p_err <> 'OK'
            THEN
               p_err := p_err;
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_err :=
                  'Waiver dates have to be within or equal to Fee daterange.';
         WHEN OTHERS
         THEN
            p_err :=
                  'Waiver dates have to be within or equal to Fee daterange.'
               || SQLCODE
               || '---'
               || SQLERRM;
      END;
   ELSE
      p_err :=
              'From Date is grater then to date which is not valid condition';
   END IF;
EXCEPTION                                               --Main block Exception
   WHEN OTHERS
   THEN
      p_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;                                              --Main Begin Block Ends Here
/


SHOW ERRORS