CREATE OR REPLACE PROCEDURE VMSCMS.sp_dup_acct_inactcrd (
   prm_inst_code   IN       NUMBER,
   prm_errmsg      OUT      VARCHAR2
)
AS
   CURSOR c1
   IS
      SELECT a.*, a.ROWID row_id
        FROM cms_dup_acct_no a
       WHERE cda_process_flag = 'N';

   v_errmsg              VARCHAR2 (300);
   exp_main_reject_rec   EXCEPTION;
   exp_loop_reject_rec   EXCEPTION;
   exp_reject_rec        EXCEPTION;
   v_main_savepoint      NUMBER                             := 0;
   v_savepoint           NUMBER                             := 0;
   v_spil_check          NUMBER;
   v_acct_num            cms_acct_mast.cam_acct_no%TYPE;
   v_acct_check          NUMBER (1);
   v_acct_type           cms_acct_type.cat_type_code%TYPE;
   v_acct_stat           cms_acct_stat.cas_stat_code%TYPE;
   v_acct_id             cms_acct_mast.cam_acct_id%TYPE;
   v_dup_flag            VARCHAR2 (1);
   v_act_card            VARCHAR2 (1);
   v_inact_card          VARCHAR2 (1);
   v_create_flag         VARCHAR2 (1);
   v_close_card_stat     VARCHAR2 (1);
   v_open_card_stat      VARCHAR2 (1);
   v_chek_cnt            NUMBER (10);
   v_commit_cnt          NUMBER                             := 0;

--------------Sn Local procedure to log PAN wise records------------
   PROCEDURE lp_log_pan_rec (
      prm_acct_no        IN   VARCHAR2,
      prm_acct_id        IN   NUMBER,
      prm_pan_code       IN   VARCHAR2,
      prm_new_acct_no    IN   VARCHAR2,
      prm_new_acct_id    IN   NUMBER,
      prm_cust_code      IN   VARCHAR2,
      prm_card_stat      IN   VARCHAR2,
      prm_mask_pan       IN   VARCHAR2,
      prm_process_flag   IN   VARCHAR2,
      prm_process_msg    IN   VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO cms_dup_acct_pan
                  (cda_acct_no, cda_acct_id, cda_pan_code, cda_new_acct_no,
                   cda_new_acct_id, cda_cust_code, cda_card_stat,
                   cda_mask_pan, cda_process_flag, cda_process_msg,
                   cda_ins_date
                  )
           VALUES (prm_acct_no, prm_acct_id, prm_pan_code, prm_new_acct_no,
                   prm_new_acct_id, prm_cust_code, prm_card_stat,
                   prm_mask_pan, prm_process_flag, prm_process_msg,
                   SYSDATE
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;
--------------En Local procedure to log PAN wise records------------
BEGIN
   prm_errmsg := 'OK';

   FOR x IN c1
   LOOP
      v_chek_cnt := 0;
      v_errmsg := 'OK';
      v_main_savepoint := v_main_savepoint + 1;
      SAVEPOINT v_main_savepoint;

      BEGIN
         FOR z IN (SELECT cap_pan_code, cap_prod_code, cap_card_type,
                          cap_appl_bran, cap_cust_code, cap_bill_addr,
                          cap_mask_pan, cap_card_stat, cap_acct_id,
                          cap_acct_no, ROWID row_id
                     FROM cms_appl_pan
                    WHERE cap_inst_code = 1
                      AND cap_acct_no = x.cap_acct_no
                      AND cap_startercard_flag = 'Y')
         LOOP
            BEGIN
               v_chek_cnt := v_chek_cnt + 1;

               IF v_chek_cnt > 1
               THEN
                  --------------------Sn to create new acct----------------
                  sp_account_construct (1,
                                        z.cap_appl_bran,
                                        z.cap_prod_code,
                                        1,                        -- Lupd user
                                        z.cap_card_type,
                                        v_acct_num,
                                        v_errmsg
                                       );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg :=
                           'error from account construct process' || v_errmsg;
                     RAISE exp_loop_reject_rec;
                  END IF;

                  --------------------En to create new acct----------------

                  ----------------Sn to Fetch Account type-----------
                  BEGIN
                     SELECT cat_type_code
                       INTO v_acct_type
                       FROM cms_acct_type
                      WHERE cat_inst_code = prm_inst_code
                        AND cat_switch_type = 11;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'Acct type not defined in master';
                        RAISE exp_loop_reject_rec;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting accttype '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  ----------------En to Fetch Account type-----------

                  ----------------Sn Fetching Account status description------------------
                  BEGIN
                     SELECT cas_stat_code
                       INTO v_acct_stat
                       FROM cms_acct_stat
                      WHERE cas_inst_code = prm_inst_code
                        AND cas_switch_statcode = 3;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'Acct stat not defined for  master';
                        RAISE exp_loop_reject_rec;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting accttype '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  ----------------En Fetching Account status description------------------

                  ---------Sn to insert new account number in Account Master--------------
                  sp_create_acct_pcms (prm_inst_code,
                                       v_acct_num,
                                       0,
                                       z.cap_appl_bran,
                                       z.cap_bill_addr,
                                       v_acct_type,
                                       v_acct_stat,
                                       1,
                                       v_dup_flag,
                                       v_acct_id,
                                       v_errmsg
                                      );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from create acct ' || v_errmsg;
                     RAISE exp_loop_reject_rec;
                  END IF;

                  ---------En to insert new account number in Account Master--------------
                         -----------------Sn to update cust acct with newly generated account id---------
                  BEGIN
                     INSERT INTO cms_cust_acct
                                 (cca_inst_code, cca_cust_code, cca_acct_id,
                                  cca_acct_name, cca_hold_posn, cca_rel_stat,
                                  cca_ins_user, cca_ins_date, cca_lupd_user,
                                  cca_lupd_date, cca_threshold_limit,
                                  cca_threshold_amt, cca_threshold_acctno,
                                  cca_threshold_bank, cca_threshold_branch,
                                  cca_threshold_ifcs, cca_threshold_rtg,
                                  cca_threshold_micr, cca_fundtrans_amt,
                                  cca_fundtrans_acctno, cca_fundtrans_bank,
                                  cca_fundtrans_branch, cca_fundtrans_ifcs,
                                  cca_fundtrans_rtg, cca_fundtrans_micr,
                                  cca_threshold_filegen_flag,
                                  cca_fundtrans_filegen_flag)
                        SELECT cca_inst_code, cca_cust_code, v_acct_id,
                               cca_acct_name, cca_hold_posn, cca_rel_stat,
                               cca_ins_user, cca_ins_date, cca_lupd_user,
                               cca_lupd_date, cca_threshold_limit,
                               cca_threshold_amt, cca_threshold_acctno,
                               cca_threshold_bank, cca_threshold_branch,
                               cca_threshold_ifcs, cca_threshold_rtg,
                               cca_threshold_micr, cca_fundtrans_amt,
                               cca_fundtrans_acctno, cca_fundtrans_bank,
                               cca_fundtrans_branch, cca_fundtrans_ifcs,
                               cca_fundtrans_rtg, cca_fundtrans_micr,
                               cca_threshold_filegen_flag,
                               cca_fundtrans_filegen_flag
                          FROM cms_cust_acct
                         WHERE cca_cust_code = z.cap_cust_code
                           AND cca_acct_id = z.cap_acct_id;
                  EXCEPTION
                     WHEN exp_loop_reject_rec
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error Fetching  Custacct master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  IF SQL%ROWCOUNT = 1
                  THEN
                     BEGIN
                        UPDATE cms_cust_acct
                           SET cca_hold_posn = 9
                         WHERE cca_cust_code = z.cap_cust_code
                           AND cca_acct_id = z.cap_acct_id;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg := 'Custacct master not updated';
                           RAISE exp_loop_reject_rec;
                        END IF;
                     EXCEPTION
                        WHEN exp_loop_reject_rec
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while updating Custacct master '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_loop_reject_rec;
                     END;
                  ELSE
                     v_errmsg :=
                           'No rows inserted into  Custacct master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_rec;
                  END IF;

                  /*  BEGIN

                  DELETE FROM cms_cust_acct WHERE cca_hold_posn = 9 and cca_cust_code = z.cap_cust_code
                            AND cca_acct_id = z.cap_acct_id;

                       IF SQL%ROWCOUNT = 0
                       THEN
                          v_errmsg := 'Custacct master not updated';
                          RAISE exp_loop_reject_rec;
                       END IF;
                    EXCEPTION
                       WHEN exp_loop_reject_rec
                       THEN
                          RAISE;
                       WHEN OTHERS
                       THEN
                          v_errmsg :=
                                'Error while updating Custacct master '
                             || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_loop_reject_rec;
                    END;
                     */-----------------En to update cust acct with newly generated account id---------

                  ------------------Sn to Update Pan Master with newly generated account id----------
                  BEGIN
                     UPDATE cms_appl_pan
                        SET cap_acct_no = v_acct_num,
                            cap_acct_id = v_acct_id
                      WHERE ROWID = z.row_id;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_errmsg := 'Pan master not updated';
                        RAISE exp_loop_reject_rec;
                     END IF;
                  EXCEPTION
                     WHEN exp_loop_reject_rec
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while updating pan master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  ------------------Sn to Update Pan Master with newly generated account id----------

                  -----------------Sn to update pan acct with newly generated account id----------
                  BEGIN
                     UPDATE cms_pan_acct
                        SET cpa_acct_id = v_acct_id
                      WHERE cpa_inst_code = prm_inst_code
                        AND cpa_pan_code = z.cap_pan_code
                        AND cpa_cust_code = z.cap_cust_code
                        AND cpa_acct_id = z.cap_acct_id;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_errmsg := 'Panacct master not updated';
                        RAISE exp_loop_reject_rec;
                     END IF;
                  EXCEPTION
                     WHEN exp_loop_reject_rec
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while updating panacct master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  -----------------En to update pan acct with newly generated account id----------
                  BEGIN
                     DELETE  cms_cust_acct
                           WHERE cca_hold_posn = 9
                             AND cca_cust_code = z.cap_cust_code
                             AND cca_acct_id = z.cap_acct_id;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_errmsg := 'Custacct master not Deleteted';
                        RAISE exp_loop_reject_rec;
                     END IF;
                  EXCEPTION
                     WHEN exp_loop_reject_rec
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while Deleting Custacct master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_loop_reject_rec;
                  END;

                  ---------Sn to log successful records-------------
                  lp_log_pan_rec (x.cap_acct_no,
                                  z.cap_acct_id,
                                  z.cap_pan_code,
                                  v_acct_num,
                                  v_acct_id,
                                  z.cap_cust_code,
                                  z.cap_card_stat,
                                  z.cap_mask_pan,
                                  'S',
                                  'Successful'
                                 );
               ---------Sn to log successful records-------------
               END IF;
            EXCEPTION
               WHEN exp_loop_reject_rec
               THEN
                  /*UPDATE CMS_DUP_ACCT_NO
                  SET CDA_PROCESS_FLAG='E',
                      CDA_PROCESS_MSG=V_ERRMSG
                  WHERE ROWID=X.ROW_ID;*/
                  ---------Sn to log successful records-------------
                  lp_log_pan_rec (x.cap_acct_no,
                                  z.cap_acct_id,
                                  z.cap_pan_code,
                                  v_acct_num,
                                  v_acct_id,
                                  z.cap_cust_code,
                                  z.cap_card_stat,
                                  z.cap_mask_pan,
                                  'E',
                                  v_errmsg
                                 );
                  ---------Sn to log successful records-------------
                  RAISE exp_main_reject_rec;
            END;

            IF v_errmsg = 'OK'
            THEN
               BEGIN
                  UPDATE cms_dup_acct_no
                     SET cda_process_flag = 'Y',
                         cda_process_msg = v_errmsg
                   WHERE ROWID = x.row_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating success flag-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_rec;
               END;
            END IF;
         END LOOP;

         IF MOD (v_commit_cnt, 100) = 0       --commit every after 100 records
         THEN
            COMMIT;
         END IF;
      EXCEPTION
         WHEN exp_reject_rec
         THEN
            RAISE;
         WHEN exp_main_reject_rec
         THEN
            ROLLBACK TO v_main_savepoint;

            BEGIN
               UPDATE cms_dup_acct_no
                  SET cda_process_flag = 'E',
                      cda_process_msg = v_errmsg
                WHERE ROWID = x.row_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  v_errmsg :=
                        'Error while updating success flag-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
      END;
   END LOOP;
EXCEPTION
   WHEN exp_reject_rec
   THEN
      prm_errmsg := v_errmsg;
END;
/

SHOW ERRORS;


