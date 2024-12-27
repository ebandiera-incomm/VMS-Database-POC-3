CREATE OR REPLACE PROCEDURE VMSCMS.sp_card_waiver_update (
   p_cce_inst_code        IN       NUMBER,
   p_cce_pan_code         IN       VARCHAR2,
   --p_cce_mbr_numb         IN       NUMBER,
   p_cce_fee_code         IN       NUMBER,
   p_cce_waiv_prcnt       IN       NUMBER,
   p_cce_valid_from_new   IN       DATE,
   p_cce_valid_to_new     IN       DATE,
   p_cce_valid_from_old   IN       DATE,
   p_cce_valid_to_old     IN       DATE,
   p_cce_waiv_desc        IN       VARCHAR2,
   p_cce_flow_source      IN       VARCHAR2,
   p_cce_ins_user         IN       NUMBER,
   p_cce_ins_date         IN       DATE,
   p_cce_lupd_user        IN       NUMBER,
   p_cce_lupd_date        IN       DATE,
   p_cce_card_waiv_id     IN       NUMBER,
   p_cce_cardfee_id       IN       NUMBER,
   p_err                  OUT      VARCHAR2
)
AS
   v_error                VARCHAR2 (100);
   v_count                NUMBER;
   v_message              NUMBER;
   v_cce_valid_from_old   DATE;
   v_cce_valid_to_old     DATE;
   v_cce_valid_from_new   DATE;
   v_cce_valid_to_new     DATE;
   v_cce_valid_from       DATE;
   v_cce_valid_to         DATE;
 /*************************************************
  * VERSION             :  1.0
  * Created Date       : 05/APR/2009
  * Created By        : Kaustubh.Dave
  * PURPOSE          : Validate all condition before update and update
  * Modified By:    :
  * Modified Date  :
***************************************************/
BEGIN                                                                      --1
   p_err := 'OK';
   --this procedure is used for validation, all type of validation is check in this procedure
   v_cce_valid_from_old := p_cce_valid_from_old;
   v_cce_valid_to_old := p_cce_valid_to_old;
   v_cce_valid_from_new := p_cce_valid_from_new;
   v_cce_valid_to_new := p_cce_valid_to_new;
   DBMS_OUTPUT.put_line (   'outside if condition of update'
                         || v_cce_valid_from_old
                         || v_cce_valid_to_old
                         || v_cce_valid_from_new
                         || v_cce_valid_to_new
                         || SYSDATE
                        );

   BEGIN
      SELECT cce_valid_from, cce_valid_to
        INTO v_cce_valid_from, v_cce_valid_to
        FROM cms_card_excpfee
       WHERE cce_inst_code = p_cce_inst_code
         AND cce_fee_code = p_cce_fee_code
         AND cce_pan_code = p_cce_pan_code
         AND cce_cardfee_id = p_cce_cardfee_id
         AND TRUNC (v_cce_valid_from_new) >= TRUNC (cce_valid_from)
         AND TRUNC (v_cce_valid_from_new) <= TRUNC (cce_valid_to)
         AND TRUNC (v_cce_valid_to_new) >= TRUNC (cce_valid_from)
         AND TRUNC (v_cce_valid_to_new) <= TRUNC (cce_valid_to);

      IF SQL%FOUND
      THEN
         BEGIN                                                            --3
            SELECT COUNT (cce_fee_code)
              INTO v_count
              FROM cms_card_excpwaiv
             WHERE cce_inst_code = p_cce_inst_code
               AND cce_fee_code = p_cce_fee_code
               AND cce_pan_code = p_cce_pan_code
               -- AND cce_mbr_numb = p_cce_mbr_numb
               AND cce_card_waiv_id <> p_cce_card_waiv_id
               AND (   (cce_valid_from BETWEEN v_cce_valid_from_new
                                           AND v_cce_valid_to_new
                       )
                    OR (cce_valid_to BETWEEN v_cce_valid_from_new
                                         AND v_cce_valid_to_new
                       )
                    OR (v_cce_valid_from_new BETWEEN cce_valid_from
                                                 AND cce_valid_to
                       )
                    OR (v_cce_valid_to_new BETWEEN cce_valid_from AND cce_valid_to
                       )
                   );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_count := 0;
            WHEN OTHERS
            THEN
               p_err := 'Same waiver is attached' || v_count;
         END;                                                              --3

------------------------------------------------
         IF v_count = 0 AND p_err = 'OK'
-- if fee is attached with the waiver, No same waiver attached between the date range and No error, then only we will allowed to update
         THEN
            IF (    TRUNC (v_cce_valid_from_old) <= TRUNC (SYSDATE)
                AND TRUNC (v_cce_valid_to_old) >= TRUNC (SYSDATE)
                AND TRUNC (v_cce_valid_to_new) >= TRUNC (SYSDATE)
               )
            THEN
               UPDATE cms_card_excpwaiv
                  SET cce_valid_to = v_cce_valid_to_new
                WHERE cce_card_waiv_id = p_cce_card_waiv_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_err := 'Update is not Done Record Not Found';
               END IF;
            ELSIF (    TRUNC (v_cce_valid_from_old) > TRUNC (SYSDATE)
                   AND TRUNC (v_cce_valid_to_old) > TRUNC (SYSDATE)
                   AND TRUNC (v_cce_valid_from_new) >= TRUNC (SYSDATE)
                   AND TRUNC (v_cce_valid_to_new) >= TRUNC (SYSDATE)
                  )
            THEN
               DBMS_OUTPUT.put_line (   'inside if condition of update'
                                     || v_cce_valid_from_old
                                     || v_cce_valid_to_old
                                     || v_cce_valid_from_new
                                     || v_cce_valid_to_new
                                     || SYSDATE
                                    );

               UPDATE cms_card_excpwaiv
                  SET cce_waiv_prcnt = p_cce_waiv_prcnt,
                      cce_valid_from = p_cce_valid_from_new,
                      cce_valid_to = p_cce_valid_to_new,
                      cce_waiv_desc = p_cce_waiv_desc,
                      cce_lupd_user = p_cce_lupd_user,
                      cce_flow_source = p_cce_flow_source,
                      cce_lupd_date = p_cce_lupd_date
                WHERE cce_card_waiv_id = p_cce_card_waiv_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_err := 'Update is not Done Record Not Found';
               END IF;
            ELSE
               p_err := 'Date range Is not Proper';
            END IF;
------------------------------------------------------------------------------------------------------------
         ELSIF v_count > 0 AND p_err = 'OK'
         THEN             -- else for, same date range condition checking fail
            p_err :=
                  'Same fee is already attached with the Fee Type'
               ---|| p_cce_fee_type
               || 'between this date range From'
               || v_cce_valid_from_new
               || 'and to'
               || v_cce_valid_to_new;
         /*ELSIF p_err <> 'OK'
         THEN
            p_err := v_error;*/
         END IF;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_err := 'Waiver dates have to be within or equal to Fee daterange.';
      WHEN OTHERS
      THEN
         p_err :=
               'Waiver dates have to be within or equal to Fee daterange.'
            || SQLCODE
            || '---'
            || SQLERRM;
   END;
EXCEPTION                                               --Main block Exception
   WHEN OTHERS
   THEN
      p_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;                                              --Main Begin Block Ends Here
/


show error