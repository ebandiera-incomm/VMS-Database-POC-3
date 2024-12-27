CREATE OR REPLACE PROCEDURE vmscms.sp_feeplan_copy (
   prm_inst_code      IN       NUMBER,
   prm_fromfee_code   IN       VARCHAR2,
   prm_tofee_code     IN       VARCHAR2,
   prm_user           IN       NUMBER,
   p_resp_msg         OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date      :  08-Aug-2014
   * Created By        :  Abdul Hameed M.A
   * PURPOSE           :  For FWR-48
   * Review            :  Spankaj
   * Build No          :  RI0027.3.1_B0003
   
   * Modified By      : A.Sivakaminathan
   * Modified Date    : 25-Mar-2015
   * Modified Reason  : DFCTNM-32 Monthly Fee Assessment - First Fee in First Month / Clawback MaxAmt Limit
   * Reviewer         : 
   * Build Number     : VMSGPRHOSTCSD_3.0        
   *************************************************/
   p_error_msg           VARCHAR2 (900);
   v_savepoint           NUMBER                              DEFAULT 1;
   exp_reject_record     EXCEPTION;
   total_product_cat     NUMBER (10);
   total_toproduct_cat   NUMBER (10);
   v_fee_code            cms_fee_feeplan.cff_fee_code%TYPE;
   v_fee_type            cms_fee_types.cft_fee_type%TYPE;
   v_tofee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
   v_fee_freq            cms_fee_feeplan.cff_fee_freq%TYPE;
   v_inst_code           NUMBER;
   v_ins_user            cms_fee_mast.cfm_ins_user%TYPE;
   v_ins_date            cms_fee_mast.cfm_ins_date%TYPE;
   v_lupd_date           cms_fee_mast.cfm_lupd_date%TYPE;
   v_lupd_user           cms_fee_mast.cfm_lupd_user%TYPE;
   v_count               NUMBER;

   CURSOR c1
   IS
      SELECT cff_fee_code, prm_tofee_code, cff_inst_code, prm_user, SYSDATE,
             prm_user, SYSDATE, cff_fee_freq
        FROM cms_fee_feeplan
       WHERE cff_fee_plan = prm_fromfee_code
             AND cff_inst_code = prm_inst_code;

   CURSOR c2 (p_feecode IN VARCHAR2)
   IS
      SELECT cfm_inst_code, cfm_feetype_code, cfm_fee_code, cfm_fee_amt,
             cfm_fee_desc, cfm_ins_user, cfm_ins_date, cfm_lupd_user,
             cfm_lupd_date, cfm_delivery_channel, cfm_tran_type,
             cfm_tran_code, cfm_tran_mode, cfm_consodium_code,
             cfm_partner_code, cfm_currency_code, cfm_per_fees, cfm_min_fees,
             cfm_spprt_key, cfm_merc_code, cfm_date_assessment,
             cfm_proration_flag, cfm_clawback_flag, cfm_duration,
             cfm_free_txncnt, cfm_feeamnt_type, cfm_intl_indicator,
             cfm_approve_status, cfm_pin_sign, cfm_normal_rvsl,
             cfm_date_start, cfm_feecap_flag, cfm_max_limit, cfm_maxlmt_freq,
             cfm_txnfree_amt, cfm_crfree_txncnt, cfm_cap_amt,
             cfm_clawback_count,
             --DFCTNM-32
             cfm_clawback_type,cfm_clawback_maxamt,cfm_assessed_days                              			 
        FROM cms_fee_mast
       WHERE cfm_fee_code = p_feecode AND cfm_inst_code = prm_inst_code;
BEGIN
   p_error_msg := 'OK';
   SAVEPOINT v_savepoint;

   OPEN c1;

   LOOP
      FETCH c1
       INTO v_fee_code, v_tofee_plan, v_inst_code, v_ins_user, v_ins_date,
            v_lupd_user, v_lupd_date, v_fee_freq;

      EXIT WHEN c1%NOTFOUND;

      BEGIN
         SELECT cft_fee_type
           INTO v_fee_type
           FROM cms_fee_types
          WHERE cft_feetype_code = (SELECT cfm_feetype_code
                                      FROM cms_fee_mast
                                     WHERE cfm_fee_code = v_fee_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_error_msg := 'Data not available in cms_fee_types for feecode-'||v_fee_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_error_msg := 'Error while selecting from cms_fee_types '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      FOR i IN c2 (v_fee_code)
      LOOP
         IF (v_fee_freq = 'T')
         THEN
            SELECT COUNT (1)
              INTO v_count
              FROM cms_fee_mast
             WHERE (NVL (cfm_delivery_channel, ' ') =NVL (i.cfm_delivery_channel, ' ')
                    OR NVL (cfm_delivery_channel, ' ') = 'A' OR NVL (i.cfm_delivery_channel, ' ') = 'A')
               AND (NVL (cfm_tran_type, ' ') = NVL (i.cfm_tran_type, ' ') 
                    OR NVL (cfm_tran_type, ' ') = 'A' OR NVL (i.cfm_tran_type, ' ') = 'A')
               AND (NVL (cfm_tran_code, ' ') = NVL (i.cfm_tran_code, ' ')
                    OR NVL (cfm_tran_code, ' ') = 'A' OR NVL (i.cfm_tran_code, ' ') = 'A')
               AND (NVL (cfm_intl_indicator, ' ') =NVL (i.cfm_intl_indicator, ' ')
                    OR NVL (cfm_intl_indicator, ' ') = 'A' OR NVL (i.cfm_intl_indicator, ' ') = 'A')
               AND (NVL (cfm_approve_status, ' ') =NVL (i.cfm_approve_status, ' ')
                    OR NVL (cfm_approve_status, ' ') = 'A' OR NVL (i.cfm_approve_status, ' ') = 'A')
               AND (NVL (cfm_pin_sign, ' ') = NVL (i.cfm_pin_sign, ' ') 
                    OR NVL (cfm_pin_sign, ' ') = 'A' OR NVL (i.cfm_pin_sign, ' ') = 'A')
               AND (cfm_normal_rvsl = i.cfm_normal_rvsl OR cfm_normal_rvsl IS NULL)
               AND (cfm_normal_rvsl = 'R' OR ((cfm_normal_rvsl = 'N' OR cfm_normal_rvsl IS NULL)
                        AND (NVL (cfm_tran_mode, ' ') =NVL (i.cfm_tran_mode, ' ')
                             OR NVL (cfm_tran_mode, ' ') = 'A'
                             OR NVL (i.cfm_tran_mode, ' ') = 'A'
                            )
                       )
                   )
               AND NVL (cfm_merc_code, ' ') = NVL (i.cfm_merc_code, ' ')
               AND cfm_fee_code IN (SELECT cff_fee_code
                                      FROM cms_fee_feeplan
                                     WHERE cff_fee_plan = prm_tofee_code);
         ELSE
            SELECT COUNT (1)
              INTO v_count
              FROM cms_fee_types
             WHERE cft_feetype_code IN (
                      SELECT cfm_feetype_code
                        FROM cms_fee_mast
                       WHERE cfm_fee_code IN (
                                           SELECT cff_fee_code
                                             FROM cms_fee_feeplan
                                            WHERE cff_fee_plan =
                                                                prm_tofee_code))
               AND DECODE (v_fee_freq,
                           'M', DECODE (cft_fee_type, v_fee_type, 'OK'),
                           'OK'
                          ) = 'OK'
               AND cft_fee_freq = v_fee_freq;
         END IF;

         BEGIN
            IF (v_count = 0)
            THEN
               BEGIN
                  SELECT     cct_ctrl_numb
                        INTO v_fee_code
                        FROM cms_ctrl_table
                       WHERE cct_ctrl_code =
                                     TO_CHAR (v_inst_code)
                                                          -- datatype mismatch
                         AND cct_ctrl_key = 'FEE CODE'
                  FOR UPDATE;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                  p_error_msg := 'control number not defined for Fee code';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     p_error_msg := 'Error while Selecting control number '|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  INSERT INTO cms_fee_mast
                              (cfm_inst_code, cfm_feetype_code,
                               cfm_fee_code, cfm_fee_amt, cfm_fee_desc,
                               cfm_ins_user, cfm_ins_date, cfm_lupd_user,
                               cfm_lupd_date, cfm_delivery_channel,
                               cfm_tran_type, cfm_tran_code,
                               cfm_tran_mode, cfm_consodium_code,
                               cfm_partner_code, cfm_currency_code,
                               cfm_per_fees, cfm_min_fees,
                               cfm_spprt_key, cfm_merc_code,
                               cfm_date_assessment, cfm_proration_flag,
                               cfm_clawback_flag, cfm_duration,
                               cfm_free_txncnt, cfm_feeamnt_type,
                               cfm_intl_indicator, cfm_approve_status,
                               cfm_pin_sign, cfm_normal_rvsl,
                               cfm_date_start, cfm_feecap_flag,
                               cfm_max_limit, cfm_maxlmt_freq,
                               cfm_txnfree_amt, cfm_crfree_txncnt,
                               cfm_cap_amt, cfm_clawback_count,
                               --DFCTNM-32
                               cfm_clawback_type,cfm_clawback_maxamt,cfm_assessed_days                                   							   
                              )
                       VALUES (i.cfm_inst_code, i.cfm_feetype_code,
                               v_fee_code, i.cfm_fee_amt, i.cfm_fee_desc,
                               v_ins_user, v_ins_date, v_lupd_user,
                               v_lupd_date, i.cfm_delivery_channel,
                               i.cfm_tran_type, i.cfm_tran_code,
                               i.cfm_tran_mode, i.cfm_consodium_code,
                               i.cfm_partner_code, i.cfm_currency_code,
                               i.cfm_per_fees, i.cfm_min_fees,
                               i.cfm_spprt_key, i.cfm_merc_code,
                               i.cfm_date_assessment, i.cfm_proration_flag,
                               i.cfm_clawback_flag, i.cfm_duration,
                               i.cfm_free_txncnt, i.cfm_feeamnt_type,
                               i.cfm_intl_indicator, i.cfm_approve_status,
                               i.cfm_pin_sign, i.cfm_normal_rvsl,
                               i.cfm_date_start, i.cfm_feecap_flag,
                               i.cfm_max_limit, i.cfm_maxlmt_freq,
                               i.cfm_txnfree_amt, i.cfm_crfree_txncnt,
                               i.cfm_cap_amt, i.cfm_clawback_count,
                               --DFCTNM-32
                               i.cfm_clawback_type,i.cfm_clawback_maxamt,i.cfm_assessed_days                                   							   
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_error_msg := 'Error while inserting data in fee mast'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  INSERT INTO cms_fee_feeplan
                              (cff_fee_code, cff_fee_plan, cff_inst_code,
                               cff_ins_user, cff_ins_date, cff_lupd_user,
                               cff_lupd_date, cff_fee_freq
                              )
                       VALUES (v_fee_code, prm_tofee_code, v_inst_code,
                               v_ins_user, v_ins_date, v_lupd_user,
                               v_lupd_date, v_fee_freq
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_error_msg := 'Error while inserting  data in fee plan'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

            BEGIN
               UPDATE cms_ctrl_table
                  SET cct_ctrl_numb = cct_ctrl_numb + 1,
                      cct_lupd_user = v_lupd_user
                WHERE cct_ctrl_code = TO_CHAR (v_inst_code)
                  AND cct_ctrl_key = 'FEE CODE';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_error_msg := 'Error while updaing control number '|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         EXCEPTION
            WHEN exp_reject_record THEN 
             RAISE;
            WHEN OTHERS
            THEN
               p_error_msg :=
                      'Error on copy card status from Fee plan to  ToFeePlan'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END LOOP;
   END LOOP;

   IF p_error_msg = 'OK'
   THEN
      BEGIN
         INSERT INTO cms_copy_log
                     (ccl_inst_code, ccl_log_id, ccl_copied_to,
                      ccl_copied_from, ccl_fromcard_type, ccl_tocard_type,
                      ccl_copied_type, ccl_ins_date, ccl_ins_user
                     )
              VALUES (prm_inst_code, ccl_log_id.NEXTVAL, prm_tofee_code,
                      prm_fromfee_code, NULL, NULL,
                      '2', SYSDATE, prm_user
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error_msg := 'Error on inserting details into CMS_COPY_LOG'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   p_resp_msg := p_error_msg;
EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      p_resp_msg := p_error_msg;
      ROLLBACK TO v_savepoint;
   WHEN OTHERS THEN
     p_error_msg := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);      
END;
/
SHOW ERROR