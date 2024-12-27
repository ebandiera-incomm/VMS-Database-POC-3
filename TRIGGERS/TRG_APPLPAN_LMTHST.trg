CREATE OR REPLACE TRIGGER vmscms.trg_applpan_lmthst
   BEFORE UPDATE OF cap_prfl_code, cap_prfl_levl
   ON vmscms.cms_appl_pan
   FOR EACH ROW
   
/*************************************************
    * Modified By       : Sachin Patil
    * Modified Date     : 12-Jul-2013
    * Modified Reason   : NextCala - Sum of C2C transfers per month exceeds 2000.00 and should not
    * Modified For      : NCGPR-434    
	* Reviewer          : Dhiraj
    * Reviewed Date     : 19.07.2013
    * Build Number      : RI0024.3_B0005

    * Modified By       : A.Sivakaminathan
    * Modified Date     : 24-Apr-2019
    * Modified Reason   : VMS-852 - ATM withdrawals did not allow to retrieve configured daily limit on the current day,
                          in case existing limit profile updated to new limit profile
	* Reviewer          : Saravanakumar A
    * Release Number    : VMSGPRHOST_R15	
*************************************************/
DECLARE
   --SN Added on 12.07.2013 for NCGPR-434
   v_new_hash_combination   VARCHAR2 (90);
   v_prfl_code              cms_limit_prfl.clp_lmtprfl_id%TYPE;
   v_divr_chnl              cms_limit_prfl.clp_dlvr_chnl%TYPE;
   v_tran_code              cms_limit_prfl.clp_tran_code%TYPE;
   v_tran_type              cms_limit_prfl.clp_tran_type%TYPE;
   v_intl_flag              cms_limit_prfl.clp_intl_flag%TYPE;
   v_pnsign_flag            cms_limit_prfl.clp_pnsign_flag%TYPE;
   v_mcc_code               cms_limit_prfl.clp_mcc_code%TYPE;
   v_trfr_crdacnt           cms_limit_prfl.clp_trfr_crdacnt%TYPE;
   v_data_found             NUMBER                                 := 1;
   v_cnt                    NUMBER;
   v_errmsg                 VARCHAR2 (4000);
   exp_reject_record        EXCEPTION;

--EN Added on 12.07.2013 for NCGPR-434
   PROCEDURE lp_err_log (
      p_inst_code              IN   NUMBER,
      p_pan_code               IN   VARCHAR2,
      p_old_comb_hash          IN   VARCHAR2,
      p_new_hash_combination   IN   VARCHAR2,
      p_errmsg                 IN   VARCHAR2,
      p_lupd_user              IN   NUMBER
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO cms_limit_errlog
                  (cle_inst_code, cle_pan_code, cle_old_comb_hash,
                   cle_new_comb_hash, cle_err_msg, cle_ins_user, cle_ins_date
                  )
           VALUES (p_inst_code, p_pan_code, p_old_comb_hash,
                   p_new_hash_combination, p_errmsg, p_lupd_user, SYSDATE
                  );

      COMMIT;
   END;
BEGIN
   --Trigger body begins
   INSERT INTO cms_applpan_lmthist
               (cal_pan_code, cal_mbr_numb, cal_prod_code,
                cal_prod_catg, cal_card_type, cal_prfl_code,
                cal_prfl_levl, cal_orgins_user, cal_orgins_date,
                cal_ins_date
               )
        VALUES (:OLD.cap_pan_code, :OLD.cap_mbr_numb, :OLD.cap_prod_code,
                :OLD.cap_prod_catg, :OLD.cap_card_type, :OLD.cap_prfl_code,
                :OLD.cap_prfl_levl, :OLD.cap_ins_user, :OLD.cap_ins_date,
                SYSDATE
               );

   --SN Added on 12.07.2013 for NCGPR-434
   IF     :OLD.cap_prfl_code IS NOT NULL
      AND :OLD.cap_prfl_code <> :NEW.cap_prfl_code
   THEN
      FOR i IN (SELECT ccd_comb_hash, ccd_daly_txncnt, ccd_daly_txnamnt,
                       ccd_wkly_txncnt, ccd_wkly_txnamnt, ccd_mntly_txncnt,
                       ccd_mntly_txnamnt, ccd_yerly_txncnt,
                       ccd_yerly_txnamnt, ccd_lifetime_txncnt, ccd_lifetime_txnamnt,ccd_lupd_date
                  FROM cms_cardsumry_dwmy
                 WHERE ccd_inst_code = :OLD.cap_inst_code
                   AND ccd_pan_code = :OLD.cap_pan_code)
      LOOP
         BEGIN
            v_data_found := 1;

            BEGIN
               SELECT clp_lmtprfl_id, clp_dlvr_chnl, clp_tran_code,
                      clp_tran_type, clp_intl_flag, clp_pnsign_flag,
                      clp_mcc_code, clp_trfr_crdacnt
                 INTO v_prfl_code, v_divr_chnl, v_tran_code,
                      v_tran_type, v_intl_flag, v_pnsign_flag,
                      v_mcc_code, v_trfr_crdacnt
                 FROM cms_limit_prfl
                WHERE clp_inst_code = :OLD.cap_inst_code
                  AND clp_lmtprfl_id = :OLD.cap_prfl_code
                  AND clp_comb_hash = i.ccd_comb_hash;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   v_data_found := 0;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting Limit Profile Parameters for profile code ='
                     || :OLD.cap_prfl_code
                     || 'comb hash ='
                     || i.ccd_comb_hash
                     || '--'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            BEGIN
               DELETE FROM cms_cardsumry_dwmy
                     WHERE ccd_inst_code = :OLD.cap_inst_code
                       AND ccd_pan_code = :OLD.cap_pan_code
                       AND ccd_comb_hash = i.ccd_comb_hash;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                        'Records not present for pan code='
                     || :OLD.cap_pan_code
                     || ' and comb hash ='
                     || i.ccd_comb_hash;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while Deleting INTO CMS_CARDSUMRY_DWMY For Delivery Channel for pan code  ='
                     || :OLD.cap_pan_code
                     || 'comb hash ='
                     || i.ccd_comb_hash
                     || '--'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            IF v_data_found = 1
            THEN
               BEGIN
                  v_new_hash_combination :=
                     gethash (   TRIM (:NEW.cap_prfl_code)
                              || TRIM (v_divr_chnl)
                              || TRIM (v_tran_code)
                              || TRIM (v_tran_type)
                              || TRIM (v_intl_flag)
                              || TRIM (v_pnsign_flag)
                              || TRIM (v_mcc_code)
                              || TRIM (v_trfr_crdacnt)
                             );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error While Generating Hash Value for new profile code ='
                        || :NEW.cap_prfl_code
                        || 'comb hash ='
                        || i.ccd_comb_hash
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT COUNT (1)
                    INTO v_cnt
                    FROM cms_limit_prfl
                   WHERE clp_inst_code = :OLD.cap_inst_code
                     AND clp_comb_hash = v_new_hash_combination;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while taking count from Limit Profile for new comb. hash ='
                        || v_new_hash_combination
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               IF v_data_found = 1 AND v_cnt > 0
               THEN
                  BEGIN
                     INSERT INTO cms_cardsumry_dwmy
                                 (ccd_inst_code, ccd_pan_code,ccd_comb_hash,
                                  ccd_daly_txncnt,
                                  ccd_daly_txnamnt,
								  ccd_wkly_txncnt,
                                  ccd_wkly_txnamnt,
								  ccd_mntly_txncnt,
                                  ccd_mntly_txnamnt,
								  ccd_yerly_txncnt,
                                  ccd_yerly_txnamnt,
								  ccd_lifetime_txncnt,
                                  ccd_lifetime_txnamnt,								  
								  ccd_lupd_date,ccd_lupd_user,ccd_ins_date, ccd_ins_user
                                 )
                          VALUES (:OLD.cap_inst_code, :OLD.cap_pan_code,v_new_hash_combination,
							      case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) then 0 else i.ccd_daly_txncnt  END,
                                  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) then 0 else i.ccd_daly_txnamnt END,
								  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DAY'))  = 'SUNDAY' OR SYSDATE > NEXT_DAY (i.ccd_lupd_date, 'SUNDAY')) then 0 else i.ccd_wkly_txncnt   END,
                                  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DAY'))  = 'SUNDAY' OR SYSDATE > NEXT_DAY (i.ccd_lupd_date, 'SUNDAY')) then 0 else i.ccd_wkly_txnamnt  END,
								  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DD'))   = '01'     OR TRUNC (SYSDATE, 'MM') > i.ccd_lupd_date)        then 0 else i.ccd_mntly_txncnt  END,
                                  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DD'))   = '01'     OR TRUNC (SYSDATE, 'MM') > i.ccd_lupd_date)        then 0 else i.ccd_mntly_txnamnt END,
								  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101'   OR TRUNC (SYSDATE, 'YY') > i.ccd_lupd_date)        then 0 else i.ccd_yerly_txncnt  END,
                                  case when trunc( i.ccd_lupd_date) < trunc(SYSDATE) AND (TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101'   OR TRUNC (SYSDATE, 'YY') > i.ccd_lupd_date)        then 0 else i.ccd_yerly_txnamnt END,
								  NVL(i.ccd_lifetime_txncnt,0),
                                  NVL(i.ccd_lifetime_txnamnt,0),									  
								  SYSDATE,1, SYSDATE, 1
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while Inserting INTO CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                           || :OLD.cap_pan_code
                           || ' -- '
                           || '-----Hash Combination---'
                           || v_new_hash_combination
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               lp_err_log (:OLD.cap_inst_code,
                           :OLD.cap_pan_code,
                           i.ccd_comb_hash,
                           v_new_hash_combination,
                           v_errmsg,
                           :NEW.cap_lupd_user
                          );
               raise_application_error (-20001, v_errmsg);
               RETURN;
            WHEN OTHERS
            THEN
               lp_err_log (:OLD.cap_inst_code,
                           :OLD.cap_pan_code,
                           i.ccd_comb_hash,
                           v_new_hash_combination,
                           v_errmsg,
                           :NEW.cap_lupd_user
                          );
               raise_application_error (-20002, v_errmsg);
               RETURN;
         END;
      END LOOP;
   END IF;
--EN Added on 12.07.2013 for NCGPR-434
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20003,
                                  'Main exception from trg_applpan_lmthst '
                               || SQLERRM
                              );
      RETURN;
END;                                                       --Trigger body ends
/

SHOW ERROR