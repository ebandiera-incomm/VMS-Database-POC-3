create or replace
PROCEDURE               vmscms.sp_upload_feeplan_card (
   p_inst_code    IN       NUMBER,
   p_valid_from   IN       VARCHAR2,
   p_file_name    IN       VARCHAR2,
   p_ins_user     IN       NUMBER,
   p_resp_msg     OUT      VARCHAR2
)
AS
   v_ex_feeplan_from_date   DATE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_from_date              DATE;
   v_to_date                DATE;
   v_feeplan_count          NUMBER;
   v_activefeeplan_count    NUMBER;
   v_samefeeplan_count      NUMBER;
   v_samedate_count         NUMBER;
   v_ex_feeplan             cms_card_excpfee.cce_fee_plan%TYPE;
   v_mbr_numb               cms_appl_pan.cap_mbr_numb%TYPE;
   v_feeplan_id             cms_feeplimitprfl_dtl.cfd_feelimit_code%TYPE;
   v_row_id                 cms_feeplimitprfl_dtl.cfd_row_id%TYPE;
   v_savepoint              NUMBER                                       := 0;
   exp_main_reject_record   EXCEPTION;

   V_FEEPLAN_PROD_COUNT     NUMBER; -- added for Mantis:15695

   /*************************************************
        * Created By       :  MageshKumar S.
        * Created Date     :  31-July-2014
        * Purpose          :  To attach fee plan to card
		* Reviwer          :  Spankaj
		* Build Number     :  RI0027.3.1_B0001

		* Modified By      : MageshKumar S.
        * Modified Date    : 20-August-2014
        * Modified Reason  : Mantis:15695,15697
        * Reviewer         : Spankaj
        * Build Number     : RI0027.3.1_B0005
	
        * Modified By      : Ramesh
	    * Modified Date    : 25-August-2014
        * Modified Reason  : Mantis:15695
        * Reviewer         : Spankaj
        * Build Number     : RI0027.3.1_B0006
    *************************************************/
   CURSOR c_feeplandel_det
   IS
      SELECT cap_pan_code, cap_pan_code_encr, cap_mbr_numb,
             cfd_feelimit_code, cfd_row_id,cap_prod_code --Added for defect id 15695
        FROM cms_appl_pan, cms_feeplimitprfl_dtl
       WHERE cap_inst_code = cfd_inst_code
         AND cap_acct_no = cfd_acct_no
         AND cap_card_stat <> '9'
         AND cfd_file_name = p_file_name
         AND cfd_attch_type = 'F'
         AND cfd_resp_msg IS NULL;

   CURSOR c_waivdel_det (pancode VARCHAR2, feeplan NUMBER, validdate DATE)
   IS
      SELECT cce_card_waiv_id
        FROM cms_card_excpwaiv
       WHERE cce_inst_code = p_inst_code
         AND cce_pan_code = pancode
         AND cce_mbr_numb = v_mbr_numb
         AND cce_fee_plan = feeplan
         AND TRUNC (cce_valid_from) > validdate;

   CURSOR c_waivupd_det (pancode VARCHAR2, feeplan NUMBER, validdate DATE)
   IS
      SELECT cce_card_waiv_id
        FROM cms_card_excpwaiv
       WHERE cce_inst_code = p_inst_code
         AND cce_pan_code = pancode
         AND cce_mbr_numb = v_mbr_numb
         AND cce_fee_plan = feeplan
         AND (v_from_date - 1) BETWEEN TRUNC (cce_valid_from)
                                   AND TRUNC (cce_valid_to);
BEGIN
   BEGIN
      v_from_date := TO_DATE (SUBSTR (TRIM (p_valid_from), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS THEN
         p_resp_msg :='Problem while converting From date:' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   FOR i2 IN c_feeplandel_det
   LOOP
      v_savepoint := v_savepoint + 1;
      SAVEPOINT v_savepoint;
      p_resp_msg := 'Success';

      BEGIN
         v_hash_pan := i2.cap_pan_code;
         v_encr_pan := i2.cap_pan_code_encr;
         v_mbr_numb := i2.cap_mbr_numb;
         v_feeplan_id := i2.cfd_feelimit_code;
         v_row_id := i2.cfd_row_id;

         BEGIN

        --Sn -  added for Mantis:15695
        --Added for defect id 15695
        select count(1) INTO V_FEEPLAN_PROD_COUNT 
        from cms_feeplan_prod_mapg 
        where CFM_INST_CODE=p_inst_code
        and CFM_PROD_CODE=i2.cap_prod_code
        and CFM_PLAN_ID=v_feeplan_id;
        
        /* Commented for defectd 15695
        select count(*) 
         INTO V_FEEPLAN_PROD_COUNT
         from cms_fee_plan 
         where cfp_plan_id in 
         (select cfm_plan_id from cms_feeplan_prod_mapg a, cms_appl_pan b 
         where 
         a.CFM_PROD_CODE=b.CAP_PROD_CODE 
         and b.cap_pan_code=v_hash_pan 
         and a.cfm_inst_code=p_inst_code )
         and CFP_INST_CODE=p_inst_code;
         */
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg :='Error while getting the Count for feeplan PROD MAPG-'|| v_feeplan_id|| ' '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
          END;

         IF V_FEEPLAN_PROD_COUNT = 0 THEN
               p_resp_msg := 'FeePlan Not Mapped To Product';
               RAISE exp_main_reject_record;
         END IF;

         --En -  added for Mantis:15695


         BEGIN
            SELECT COUNT (*)
              INTO v_samefeeplan_count
              FROM cms_card_excpfee
             WHERE cce_inst_code = p_inst_code
               AND cce_pan_code = v_hash_pan
               AND cce_fee_plan = v_feeplan_id;
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg :='Error while getting the Count for feeplan-'|| v_feeplan_id|| ' '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         IF v_samefeeplan_count = 0 THEN
            BEGIN
               SELECT COUNT (*)
                 INTO v_samedate_count
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_inst_code
                  AND cce_pan_code = v_hash_pan
                  AND ((v_from_date >= TRUNC (SYSDATE)) AND (v_from_date = TRUNC (cce_valid_from)));
            EXCEPTION
               WHEN OTHERS THEN
                  p_resp_msg :='Error while getting the FeePlan Count in same date range:'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            IF v_samedate_count > 0 THEN
               p_resp_msg := 'Already FeePlan exist in the same date range';
               RAISE exp_main_reject_record;
            END IF;

            BEGIN
               SELECT COUNT (*)
                 INTO v_feeplan_count
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_inst_code
                  AND cce_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS THEN
                  p_resp_msg :='Error while getting the FeePlan Count :'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;

            IF v_feeplan_count >= 2 THEN
               SELECT COUNT (*)
                 INTO v_activefeeplan_count
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_inst_code
                  AND cce_pan_code = v_hash_pan
                  AND ((cce_valid_to IS NULL AND TRUNC (cce_valid_from) >= TRUNC (SYSDATE))
                       OR (cce_valid_to IS NOT NULL AND TRUNC (cce_valid_to) >= TRUNC (SYSDATE)));

               IF v_activefeeplan_count >= 2 THEN
                  p_resp_msg :='More than two Active FeePlan Cannot be attached';
                  RAISE exp_main_reject_record;
               ELSE
                  BEGIN
                     SELECT TRUNC (cce_valid_from), cce_fee_plan
                       INTO v_ex_feeplan_from_date, v_ex_feeplan
                       FROM cms_card_excpfee
                      WHERE cce_inst_code = p_inst_code
                        AND cce_pan_code = v_hash_pan
                        AND (((TRUNC (cce_valid_from) > TRUNC (SYSDATE)) OR (cce_valid_to IS NOT NULL AND TRUNC (cce_valid_to) >TRUNC (SYSDATE)))
                             OR (TRUNC (cce_valid_from) < TRUNC (SYSDATE) AND cce_valid_to IS NULL));
                  EXCEPTION
                     WHEN OTHERS THEN
                        p_resp_msg :='Error while Selecting the Existing FeePlan Date in date range :'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
               END IF;
            ELSIF v_feeplan_count = 1 THEN
               BEGIN
                  SELECT TRUNC (cce_valid_from), cce_fee_plan
                    INTO v_ex_feeplan_from_date, v_ex_feeplan
                    FROM cms_card_excpfee
                   WHERE cce_pan_code = v_hash_pan
                     AND cce_mbr_numb = v_mbr_numb
                     AND cce_inst_code = p_inst_code;
               EXCEPTION
                  WHEN OTHERS THEN
                     p_resp_msg :='Error while Selecting the Existing FeePlan Date :'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;

            IF ((v_ex_feeplan_from_date < v_from_date)) THEN
               BEGIN
                  UPDATE cms_card_excpfee
                     SET cce_valid_to = v_from_date - 1
                   WHERE cce_pan_code = v_hash_pan
                     AND cce_mbr_numb = v_mbr_numb
                     AND cce_inst_code = p_inst_code
                     AND cce_fee_plan = v_ex_feeplan;

                  IF SQL%ROWCOUNT = 0 THEN
                     p_resp_msg := 'Problem in updation of Ex-Feeplan.';
                     RAISE exp_main_reject_record;
                  END IF;

                  FOR i IN c_waivdel_det (v_hash_pan,v_ex_feeplan,v_from_date - 1)
                  LOOP
                     --EXIT WHEN c_waivdel_det%NOTFOUND;
                     DELETE FROM cms_card_excpwaiv
                           WHERE cce_inst_code = p_inst_code
                             AND cce_pan_code = v_hash_pan
                             AND cce_mbr_numb = v_mbr_numb
                             AND cce_fee_plan = v_ex_feeplan
                             AND cce_valid_from > v_from_date - 1
                             AND cce_card_waiv_id = i.cce_card_waiv_id;

                     IF SQL%ROWCOUNT = 0 THEN
                        p_resp_msg := 'Problem in deletion of Ex waiver.';
                        RAISE exp_main_reject_record;
                     END IF;

                     UPDATE cms_card_excpwaiv_hist
                        SET cce_chng_reason = 'Fee Plan Date Modified'
                      WHERE cce_inst_code = p_inst_code
                        AND cce_pan_code = v_hash_pan
                        AND cce_mbr_numb = v_mbr_numb
                        AND cce_fee_plan = v_ex_feeplan
                        AND cce_valid_from > v_from_date - 1
                        AND cce_card_waiv_id = i.cce_card_waiv_id
                        AND cce_act_type = 'D';

                     IF SQL%ROWCOUNT = 0 THEN
                        p_resp_msg :='Problem in updation of Ex-waiver hist.';
                        RAISE exp_main_reject_record;
                     END IF;
                  END LOOP;

                  FOR i1 IN c_waivupd_det (v_hash_pan, v_ex_feeplan, v_from_date - 1 )
                  LOOP
                     --EXIT WHEN c_waivupd_det%NOTFOUND;
                     UPDATE cms_card_excpwaiv
                        SET cce_valid_to = v_from_date - 1
                      WHERE cce_inst_code = p_inst_code
                        AND cce_pan_code = v_hash_pan
                        AND cce_mbr_numb = v_mbr_numb
                        AND cce_fee_plan = v_ex_feeplan
                        AND ((v_from_date - 1) BETWEEN TRUNC (cce_valid_from) AND TRUNC (cce_valid_to))
                        AND cce_card_waiv_id = i1.cce_card_waiv_id;

                     IF SQL%ROWCOUNT = 0 THEN
                        p_resp_msg := 'Problem in deletion of Ex waiver 1.0.';
                        RAISE exp_main_reject_record;
                     END IF;

                     UPDATE cms_card_excpwaiv_hist
                        SET cce_chng_reason = 'Fee Plan Date Modified'
                      WHERE cce_inst_code = p_inst_code
                        AND cce_pan_code = v_hash_pan
                        AND cce_mbr_numb = v_mbr_numb
                        AND cce_fee_plan = v_ex_feeplan
                        AND (v_from_date - 1) BETWEEN TRUNC (cce_valid_from) AND TRUNC (cce_valid_to)
                        AND cce_card_waiv_id = i1.cce_card_waiv_id
                        AND cce_act_type = 'U';

                     IF SQL%ROWCOUNT = 0 THEN
                        p_resp_msg :='Problem in updation of Ex-waiver hist 1.0';
                        RAISE exp_main_reject_record;
                     END IF;
                  END LOOP;
               EXCEPTION
                  WHEN exp_main_reject_record THEN
                     RAISE;
                  WHEN OTHERS THEN
                     p_resp_msg := 'Error while updating the To Date of Existing FeePlan :' || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            ELSE
               v_to_date := v_ex_feeplan_from_date - 1;
            END IF;

            BEGIN
               INSERT INTO cms_card_excpfee
                           (cce_inst_code, cce_pan_code, cce_mbr_numb,
                            cce_valid_from, cce_valid_to, cce_flow_source,
                            cce_ins_user, cce_lupd_user, cce_fee_plan,
                            cce_pan_code_encr
                           )
                    VALUES (p_inst_code, v_hash_pan, v_mbr_numb,
                            v_from_date, v_to_date, 'C',
                            p_ins_user, p_ins_user, v_feeplan_id,
                            v_encr_pan
                           );
            EXCEPTION
               WHEN OTHERS THEN
                  p_resp_msg := 'Error while inserting the FeePlan Details :' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         ELSE
            p_resp_msg := 'Same FeePlan has already attached'; --  Modified for Mantis:15697
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            ROLLBACK TO v_savepoint;
         WHEN OTHERS THEN
            ROLLBACK TO v_savepoint;
            p_resp_msg := 'Error while processing rowid-' || v_row_id || '-' || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         UPDATE cms_feeplimitprfl_dtl
            SET cfd_resp_msg = p_resp_msg
          WHERE cfd_inst_code = p_inst_code
            AND cfd_file_name = p_file_name
            AND cfd_row_id = v_row_id;
         --AND cfd_resp_msg IS NULL;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
            /*p_resp_msg := 'Error while updating process msg for rowid-' || v_row_id || ':' || SUBSTR (SQLERRM, 1, 200);
            ROLLBACK;
            RETURN;*/
      END;
   END LOOP;

   p_resp_msg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg := 'Main Excp--' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR