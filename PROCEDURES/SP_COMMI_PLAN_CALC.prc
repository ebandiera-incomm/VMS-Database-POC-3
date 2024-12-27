CREATE OR REPLACE PROCEDURE VMSCMS.sp_commi_plan_calc (
   prm_inst_code      IN       NUMBER,
   prm_branch_code    IN       VARCHAR2,
   prm_sales_flag     IN       VARCHAR2,
   prm_initial_flag   IN       VARCHAR2,
   prm_topup_flag     IN       VARCHAR2,
   prm_lupd_user      IN       NUMBER,
   prm_errmsg         OUT      VARCHAR2
)
AS
   v_plan_id             cms_commission_plan.ccp_plan_id%TYPE;
   v_plan_type           cms_commission_plan.ccp_plan_type%TYPE;
   v_plan_amt            cms_tieredplan_commission.ctc_plan_amt%TYPE;
   v_plan_percent        cms_tieredplan_commission.ctc_plan_percent%TYPE;
   v_commission_add      cms_tieredplan_commission.ctc_plan_amt%TYPE;
   v_plan_amt_flat       cms_flatplan_commission.cft_plan_amt%TYPE;
   v_plan_percent_flat   cms_flatplan_commission.cft_plan_percent%TYPE;
   v_sales_count         NUMBER (10);
   v_errmsg              VARCHAR2 (300) DEFAULT 'OK';
   v_wallet_acct_id      cms_acct_mast.cam_acct_id%TYPE;
   v_wallet_pan_no       cms_appl_pan.cap_pan_code%TYPE;
   v_wallet_bran_code    cms_bran_mast.cbm_bran_code%TYPE;
   exc_reject_record     EXCEPTION;

   CURSOR cur_1 (c_plan_id IN VARCHAR2)
   IS
      SELECT ctc_plan_id, ctc_tiered_id, ctc_tired_type, ctc_from, ctc_to
        FROM cms_tieredplan_commission
       WHERE ctc_plan_id = c_plan_id;

   CURSOR cur_2 (c_plan_id IN VARCHAR2)
   IS
      SELECT cap_pan_code, total_amount
        FROM cms_appl_pan, transactionlog, cms_bran_mast,
             cms_commission_plan
       WHERE cbm_bran_code = prm_branch_code
         AND cap_appl_bran = cbm_bran_code
         AND customer_card_no = cap_pan_code
         AND txn_code = 'IL'
         AND delivery_channel = '05'
         AND txn_type = 1
         AND response_code = '00'
         AND ccp_plan_id = cbm_commission_plan
         AND cbm_define_commplan = 'Y'
         AND cap_issue_flag = 'Y'
         AND ccp_plan_id = c_plan_id
         AND cap_ins_date BETWEEN TO_DATE (TO_CHAR (SYSDATE, 'MMYYYY'),
                                           'MMYYYY'
                                          )
                              AND LAST_DAY (SYSDATE);
BEGIN
   prm_errmsg := 'OK';
   v_errmsg := 'OK';
   -----------Sn check codition for card issuance, commission on ccard issuance----------------
   IF prm_sales_flag = 'Y'
   THEN
      BEGIN
         SELECT ccp_plan_id, ccp_plan_type
           INTO v_plan_id, v_plan_type
           FROM cms_bran_mast, cms_commission_plan
          WHERE cbm_bran_code = prm_branch_code
            AND ccp_plan_id = cbm_commission_plan
            AND cbm_define_commplan = 'Y';
			
         IF v_plan_type = 1
         THEN                                        --tiered plan commission.
            FOR i IN cur_1 (v_plan_id)
            LOOP
               IF i.ctc_tired_type = 0
               THEN                                 --commission on No. card.
                  BEGIN
                     SELECT COUNT (1)
                       INTO v_sales_count
                       FROM cms_appl_pan, cms_bran_mast, cms_commission_plan
                      WHERE cbm_bran_code = prm_branch_code
                        AND cap_appl_bran = cbm_bran_code
                        AND cap_inst_code = cbm_inst_code
                        AND cbm_inst_code = ccp_inst_code
                        AND ccp_plan_id = cbm_commission_plan
                        AND cbm_define_commplan = 'Y'
                        AND cap_issue_flag = 'Y'
                        AND cap_ins_date
                               BETWEEN TO_CHAR (TO_DATE (TO_CHAR (SYSDATE,
                                                                  'MMYYYY'
                                                                 ),
                                                         'MMYYYY'
                                                        ),
                                                'DD-MON-YYYY'
                                               )
                                   AND LAST_DAY (SYSDATE);
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'No issued cards found for the merchant';
                        RAISE exc_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'No issued cards found for the merchant'
                           || SQLERRM;
                        RAISE exc_reject_record;
                  END;

                  SELECT ctc_plan_amt, ctc_plan_percent
                    INTO v_plan_amt, v_plan_percent
                    FROM cms_tieredplan_commission
                   WHERE v_sales_count BETWEEN ctc_from AND ctc_to
                     AND ctc_plan_id = v_plan_id;

                  IF v_plan_amt IS NOT NULL AND v_plan_percent IS NOT NULL
                  THEN
                     FOR x IN cur_2 (v_plan_id)
                     LOOP
                        v_commission_add :=
                             v_plan_amt
                           + ROUND((to_number(x.total_amount) * v_plan_percent/100),0);

                        BEGIN
                           INSERT INTO cms_tiredcommission_hist
                                VALUES (prm_inst_code, v_plan_amt,
                                        v_plan_percent, x.cap_pan_code,
                                        v_plan_id, prm_branch_code,
                                        v_commission_add,prm_lupd_user,sysdate,prm_lupd_user,sysdate);

                           IF SQL%ROWCOUNT = 0
                           THEN
                              v_errmsg :=
                                 'Error while inserting record in tired hist';
                              RAISE exc_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exc_reject_record
                           THEN
                              v_errmsg :=
                                 'error while inserting record tired commition hist No. of cards';
                              RAISE;
                           WHEN OTHERS
                           THEN
                              RAISE exc_reject_record;
                        END;

                        BEGIN
                           SELECT cmw_acct_id, cmw_pan_no,
                                  cmw_bran_code
                             INTO v_wallet_acct_id, v_wallet_pan_no,
                                  v_wallet_bran_code
                             FROM cms_merc_wallet
                            WHERE cmw_bran_code = prm_branch_code;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_errmsg :=
                                 'No Data fond in merc_wallet for the perticular branch';
                              RAISE exc_reject_record;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'No Data fond in merc_wallet for the perticular branch'
                                 || SQLERRM;
                              RAISE exc_reject_record;
                        END;

                        BEGIN
                           UPDATE cms_acct_mast
                              SET cam_acct_bal =
                                               cam_acct_bal + v_commission_add
                            WHERE cam_acct_id = v_wallet_acct_id
                              AND cam_curr_bran = v_wallet_bran_code
                              AND cam_acct_no = v_wallet_pan_no;

                           IF SQL%ROWCOUNT = 0
                           THEN
                              v_errmsg := 'Error while updating acct balance';
                              RAISE exc_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exc_reject_record
                           THEN
                              v_errmsg := v_errmsg;
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while updating acct balance'
                                 || SQLERRM;
                              RAISE exc_reject_record;
                        END;
                     END LOOP;
                  END IF;
               END IF;                               --commission on No. card.

               IF i.ctc_tired_type = 1
               THEN                                --commission on card amount
                  FOR y IN cur_2 (v_plan_id)
                  LOOP
                     SELECT ctc_plan_amt, ctc_plan_percent
                       INTO v_plan_amt, v_plan_percent
                       FROM cms_tieredplan_commission
                      WHERE y.total_amount BETWEEN ctc_from AND ctc_to
                        AND ctc_plan_id = v_plan_id;

                     IF v_plan_amt IS NOT NULL AND v_plan_percent IS NOT NULL
                     THEN
                        v_commission_add :=
                             v_plan_amt
                           + ROUND((to_number(y.total_amount) * v_plan_percent/100),0);

                        BEGIN
                           INSERT INTO cms_tiredcommission_hist
                                VALUES (prm_inst_code, v_plan_amt,
                                        v_plan_percent, y.cap_pan_code,
                                        v_plan_id, prm_branch_code,
                                        v_commission_add,prm_lupd_user,sysdate,prm_lupd_user,sysdate);

                           IF SQL%ROWCOUNT = 0
                           THEN
                              v_errmsg :=
                                 'Error while inserting record in tired commission hist for Card amt';
                              RAISE exc_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exc_reject_record
                           THEN
                              v_errmsg :=
                                 'Error while inserting record in tired commission hist for Card amt';
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting record in tired commission hist for Card amt'
                                 || SQLERRM;
                              RAISE exc_reject_record;
                        END;

                        BEGIN
                           SELECT cmw_acct_id, cmw_pan_no,
                                  cmw_bran_code
                             INTO v_wallet_acct_id, v_wallet_pan_no,
                                  v_wallet_bran_code
                             FROM cms_merc_wallet
                            WHERE cmw_bran_code = prm_branch_code;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_errmsg :=
                                 'No Data fond in merc_wallet for the perticular branch';
                              RAISE exc_reject_record;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'No Data fond in merc_wallet for the perticular branch'
                                 || SQLERRM;
                              RAISE exc_reject_record;
                        END;

                        BEGIN
                           UPDATE cms_acct_mast
                              SET cam_acct_bal =
                                               cam_acct_bal + v_commission_add
                            WHERE cam_acct_id = v_wallet_acct_id
                              AND cam_curr_bran = v_wallet_bran_code
                              AND cam_acct_no = v_wallet_pan_no;

                           IF SQL%ROWCOUNT = 0
                           THEN
                              v_errmsg := 'Error while updating acct balance';
                              RAISE exc_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exc_reject_record
                           THEN
                              v_errmsg := v_errmsg;
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while updating acct balance'
                                 || SQLERRM;
                              RAISE exc_reject_record;
                        END;
                     END IF;
                  END LOOP;
               END IF;                             --commission on card amount
            END LOOP;
         ELSIF v_plan_type = 0
         THEN                                            -- for flat commition
            FOR z IN cur_2 (v_plan_id)
            LOOP
               SELECT cft_plan_amt, cft_plan_percent
                 INTO v_plan_amt_flat, v_plan_percent_flat
                 FROM cms_flatplan_commission
                WHERE cft_plan_id = v_plan_id;

               v_commission_add :=
                          v_plan_amt
                          + ROUND((to_number(z.total_amount) * v_plan_percent/100),0);

               BEGIN
                  INSERT INTO cms_flatcommission_hist
                       VALUES (prm_inst_code, v_plan_amt, v_plan_percent,
                               z.cap_pan_code, v_plan_id, prm_branch_code,
                               v_commission_add,prm_lupd_user,sysdate,prm_lupd_user,sysdate);

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                        'Error while inserting record in flat commission hist for Card amt';
                     RAISE exc_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exc_reject_record
                  THEN
                     v_errmsg :=
                        'Error while inserting record in flat commission hist for Card amt';
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while inserting record in flat commission hist for Card amt'
                        || SUBSTR (SQLERRM, 50, 10);
                     RAISE exc_reject_record;
               END;

               BEGIN
                  SELECT cmw_acct_id, cmw_pan_no,
                         cmw_bran_code
                    INTO v_wallet_acct_id, v_wallet_pan_no,
                         v_wallet_bran_code
                    FROM cms_merc_wallet
                   WHERE cmw_bran_code = prm_branch_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'No Data fond in merc_wallet for the perticular branch';
                     RAISE exc_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'No Data fond in merc_wallet for the perticular branch'
                        || SQLERRM;
                     RAISE exc_reject_record;
               END;

               BEGIN
                  UPDATE cms_acct_mast
                     SET cam_acct_bal = cam_acct_bal + v_commission_add
                   WHERE cam_acct_id = v_wallet_acct_id
                     AND cam_curr_bran = v_wallet_bran_code
                     AND cam_acct_no = v_wallet_pan_no;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg := 'Error while updating acct balance';
                     RAISE exc_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exc_reject_record
                  THEN
                     v_errmsg := v_errmsg;
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                               'Error while updating acct balance' || SQLERRM;
                     RAISE exc_reject_record;
               END;
            END LOOP;
         END IF;
      EXCEPTION
	  WHEN exc_reject_record then
	  v_errmsg :=v_errmsg;
	  RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'No commission found for the merchant';
            RAISE exc_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg := 'No commission found for the merchant' || SQLERRM;
            RAISE exc_reject_record;
      END;
   END IF;
EXCEPTION
   WHEN exc_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Error' || v_errmsg;
END;
/


