CREATE OR REPLACE PROCEDURE vmscms.sp_fee_plan_migration
AS
/*************************************************
     * Modified By      :  SAI Prasad
     * Modified Date    :  08-AUG-2014
     * Modified Reason  :  Fee changes in FWR-48
*************************************************/
   v_debit_amnt             NUMBER;

   TYPE t_indarray IS VARRAY (2) OF VARCHAR2 (10);

   v_ind                    t_indarray;
   v_pin_sign               t_indarray;
   v_nor_rev                t_indarray;
   total                    INTEGER    := 2;
   v_savepoint              NUMBER     := 0;
   exp_main_reject_record   EXCEPTION;

   CURSOR allfeemat
   IS
      SELECT   *
          FROM cms_fee_feeplan a, cms_fee_mast b
         WHERE a.cff_fee_code = b.cfm_fee_code
           AND cff_fee_freq = 'T'
           AND (   cfm_tran_type IN ('A')
                OR cfm_tran_code = 'A'
                OR cfm_intl_indicator = 'A'
                OR cfm_pin_sign = 'A'
                OR cfm_approve_status = 'A'
               )
      ORDER BY cff_fee_plan;

   CURSOR tranmat ( p_del_chn  IN   VARCHAR2, p_tran_type   IN   VARCHAR2, p_tran_code   IN   VARCHAR2 )
   IS
      SELECT ctm_tran_code,
             DECODE (ctm_tran_type, 'N', '0', 'F', '1', '1') ctm_tran_type,
             ctm_delivery_channel
        FROM cms_transaction_mast
       WHERE ctm_inst_code = '1'
         AND ctm_delivery_channel = p_del_chn
         AND ctm_tran_type LIKE  (DECODE (p_tran_type, 'A', '%', '0', 'N', '1', 'F', p_tran_type ) )
         AND ctm_fee_flag = 'Y'
         AND ctm_tran_code LIKE (DECODE (p_tran_code, 'A', '%', p_tran_code));
BEGIN
   v_ind := t_indarray ('0', '1');
   v_pin_sign := t_indarray ('P', 'S');
   v_nor_rev := t_indarray ('P', 'D');

   DECLARE
      r_testrec     allfeemat%ROWTYPE;
      v_error_msg   VARCHAR2 (300 BYTE);

      PROCEDURE lp_insert_fee_code (
         fee_cursor         IN       allfeemat%ROWTYPE,
         p_tran_type        IN       cms_fee_mast.cfm_tran_type%TYPE,
         p_tran_code        IN       cms_fee_mast.cfm_tran_code%TYPE,
         p_intl_indicator   IN       cms_fee_mast.cfm_intl_indicator%TYPE,
         p_pin_sign         IN       cms_fee_mast.cfm_pin_sign%TYPE,
         p_approve_status   IN       cms_fee_mast.cfm_approve_status%TYPE,
         p_error_msg        OUT      VARCHAR2
      )
      AS
         v_feecode      NUMBER;
         lp_error_msg   VARCHAR2 (300) := 'OK';
         v_cmd          VARCHAR (100);
      BEGIN
         BEGIN
            DELETE FROM cms_fee_feeplan
                  WHERE cff_fee_plan = fee_cursor.cff_fee_plan
                    AND cff_fee_code = fee_cursor.cff_fee_code
                    AND cff_inst_code = fee_cursor.cfm_inst_code;
         EXCEPTION
            WHEN OTHERS THEN
               lp_error_msg :='FEE PLAN detach failed ' || SUBSTR (SQLERRM, 1, 200);
         END;

         BEGIN
            sp_create_fee (fee_cursor.cfm_inst_code,
                           fee_cursor.cfm_feetype_code,
                           fee_cursor.cfm_fee_amt,
                           fee_cursor.cfm_fee_desc,
                           fee_cursor.cfm_delivery_channel,
                           -- fee_cursor.CFM_INTL_INDICATOR,
                           p_intl_indicator,
                           --fee_cursor.CFM_APPROVE_STATUS,
                           p_approve_status,
                           --fee_cursor.CFM_PIN_SIGN,
                           p_pin_sign,
                           --  fee_cursor.CFM_tran_type,
                           p_tran_type,
                           --fee_cursor.CFM_TRAN_CODE,
                           p_tran_code,
                           fee_cursor.cfm_tran_mode,
                           fee_cursor.cfm_consodium_code,
                           fee_cursor.cfm_partner_code,
                           fee_cursor.cfm_currency_code,
                           fee_cursor.cfm_per_fees,
                           fee_cursor.cfm_min_fees,
                           fee_cursor.cfm_spprt_key,
                           fee_cursor.cfm_merc_code,
                           fee_cursor.cfm_date_assessment,
                           fee_cursor.cfm_proration_flag,
                           fee_cursor.cfm_clawback_flag,
                           fee_cursor.cfm_free_txncnt,
                           fee_cursor.cfm_duration,
                           fee_cursor.cfm_feeamnt_type,
                           fee_cursor.cfm_normal_rvsl,
                           fee_cursor.cfm_max_limit,
                           fee_cursor.cfm_maxlmt_freq,
                           fee_cursor.cfm_date_start,
                           fee_cursor.cfm_feecap_flag,
                           fee_cursor.cfm_crfree_txncnt,
                           fee_cursor.cfm_cap_amt,
                           fee_cursor.cfm_txnfree_amt,
                           fee_cursor.cfm_lupd_user,
                           fee_cursor.cfm_clawback_count,
                           v_feecode,
                           lp_error_msg
                          );
         EXCEPTION
            WHEN OTHERS THEN
               lp_error_msg := 'FEE creation failed ' || SUBSTR (SQLERRM, 1, 200);
         END;

         IF (lp_error_msg = 'OK') THEN
            BEGIN
               sp_fee_feeplan_attach (fee_cursor.cfm_inst_code,
                                      fee_cursor.cff_fee_plan,
                                      v_feecode,
                                      lp_error_msg
                                     );
            EXCEPTION
               WHEN OTHERS THEN
                  lp_error_msg :='FEE attach failed' || SUBSTR (SQLERRM, 1, 200);
            END;
         END IF;

         p_error_msg := lp_error_msg;
      END;
   BEGIN
      FOR c IN allfeemat
      LOOP
         v_error_msg := 'OK';

         FOR c1 IN tranmat (c.cfm_delivery_channel,c.cfm_tran_type,c.cfm_tran_code)
         LOOP
            DBMS_OUTPUT.put_line (c1.ctm_tran_code);

            BEGIN
               v_savepoint := v_savepoint + 1;
               SAVEPOINT v_savepoint;
               v_error_msg := 'OK';

               IF (c.cfm_intl_indicator = 'A') THEN
                  FOR i IN 1 .. 2
                  LOOP
                     IF (c.cfm_pin_sign = 'A') THEN
                        FOR j IN 1 .. 2
                        LOOP
                           IF (c.cfm_approve_status = 'A') THEN
                              FOR k IN 1 .. 2
                              LOOP
                                 lp_insert_fee_code (c,
                                                     c1.ctm_tran_type,
                                                     c1.ctm_tran_code,
                                                     v_ind (i),
                                                     v_pin_sign (j),
                                                     v_nor_rev (k),
                                                     v_error_msg
                                                    );

                                 IF (v_error_msg <> 'OK') THEN
                                    DBMS_OUTPUT.put_line (' Fee Plan 1 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                                    RAISE exp_main_reject_record;
                                 END IF;
                              END LOOP;
                           ELSE
                              lp_insert_fee_code (c,
                                                  c1.ctm_tran_type,
                                                  c1.ctm_tran_code,
                                                  v_ind (i),
                                                  v_pin_sign (j),
                                                  c.cfm_approve_status,
                                                  v_error_msg
                                                 );

                              IF (v_error_msg <> 'OK') THEN
                                 DBMS_OUTPUT.put_line (   ' Fee Plan 2 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                                 RAISE exp_main_reject_record;
                              END IF;
                           END IF;
                        END LOOP;
                     ELSIF (c.cfm_approve_status = 'A') THEN
                        FOR k IN 1 .. 2
                        LOOP
                           lp_insert_fee_code (c,
                                               c1.ctm_tran_type,
                                               c1.ctm_tran_code,
                                               v_ind (i),
                                               c.cfm_pin_sign,
                                               v_nor_rev (k),
                                               v_error_msg
                                              );

                           IF (v_error_msg <> 'OK') THEN
                              DBMS_OUTPUT.put_line ( ' Fee Plan 3 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                              RAISE exp_main_reject_record;
                           END IF;
                        END LOOP;
                     ELSE
                        lp_insert_fee_code (c,
                                            c1.ctm_tran_type,
                                            c1.ctm_tran_code,
                                            v_ind (i),
                                            c.cfm_pin_sign,
                                            c.cfm_approve_status,
                                            v_error_msg
                                           );

                        IF (v_error_msg <> 'OK') THEN
                           DBMS_OUTPUT.put_line ( ' Fee Plan 4 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                           RAISE exp_main_reject_record;
                        END IF;
                     END IF;
                  END LOOP;
               ELSIF (c.cfm_pin_sign = 'A') THEN
                  FOR j IN 1 .. 2
                  LOOP
                     IF (c.cfm_approve_status = 'A') THEN
                        FOR k IN 1 .. 2
                        LOOP
                           lp_insert_fee_code (c,
                                               c1.ctm_tran_type,
                                               c1.ctm_tran_code,
                                               c.cfm_intl_indicator,
                                               v_pin_sign (j),
                                               v_nor_rev (k),
                                               v_error_msg
                                              );

                           IF (v_error_msg <> 'OK') THEN
                              DBMS_OUTPUT.put_line (   ' Fee Plan 5 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                              RAISE exp_main_reject_record;
                           END IF;
                        END LOOP;
                     ELSE
                        lp_insert_fee_code (c,
                                            c1.ctm_tran_type,
                                            c1.ctm_tran_code,
                                            c.cfm_intl_indicator,
                                            v_pin_sign (j),
                                            c.cfm_approve_status,
                                            v_error_msg
                                           );

                        IF (v_error_msg <> 'OK') THEN
                           DBMS_OUTPUT.put_line (   ' Fee Plan 6 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                           RAISE exp_main_reject_record;
                        END IF;
                     END IF;
                  END LOOP;
               ELSIF (c.cfm_approve_status = 'A') THEN
                  FOR k IN 1 .. 2
                  LOOP
                     lp_insert_fee_code (c,
                                         c1.ctm_tran_type,
                                         c1.ctm_tran_code,
                                         c.cfm_intl_indicator,
                                         c.cfm_pin_sign,
                                         v_nor_rev (k),
                                         v_error_msg
                                        );

                     IF (v_error_msg <> 'OK') THEN
                        DBMS_OUTPUT.put_line (' Fee Plan 7 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                        RAISE exp_main_reject_record;
                     END IF;
                  END LOOP;
               ELSE
                  lp_insert_fee_code (c,
                                      c1.ctm_tran_type,
                                      c1.ctm_tran_code,
                                      c.cfm_intl_indicator,
                                      c.cfm_pin_sign,
                                      c.cfm_approve_status,
                                      v_error_msg
                                     );

                  IF (v_error_msg <> 'OK') THEN
                     DBMS_OUTPUT.put_line (' Fee Plan 8 : '|| c.cff_fee_plan|| ' '|| c.cff_fee_code|| v_error_msg);
                     RAISE exp_main_reject_record;
                  END IF;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record THEN
                  ROLLBACK TO v_savepoint;
               WHEN OTHERS THEN
                  ROLLBACK TO v_savepoint;
                  DBMS_OUTPUT.put_line ('Error while processing delivery channel-'||c.cfm_delivery_channel ||' & txn code-'||c1.ctm_tran_code||'is ' || SUBSTR (SQLERRM, 1, 200));
            END;
         END LOOP;
      END LOOP;
   END;
END;
/
SHOW ERROR