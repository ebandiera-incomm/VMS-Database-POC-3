CREATE OR REPLACE TRIGGER VMSCMS.trg_addr_mob_email
   BEFORE UPDATE OF cam_mobl_one, cam_email
   ON VMSCMS.CMS_ADDR_MAST    FOR EACH ROW
 /********************************************************************************
   * Created By       : Sachin P.
   * Modified Date    : 08-Aug-2013
   * Modified for     : MOB-31
   * Modified Reason  : Enable Card to Card Transfer Feature for Mobile API
   * Reviewer         : Dhiraj
   * Reviewed Date    : 08-Aug-2013
   * Build Number     : Ri0024.4_B0003

*********************************************************************************/
DECLARE
   v_cust_code   cms_mob_email_log.cme_cust_code%TYPE;
BEGIN
   IF :OLD.cam_addr_flag = 'P'
   THEN
      IF    :OLD.cam_mobl_one <> :NEW.cam_mobl_one
         OR :OLD.cam_email <> :NEW.cam_email
      THEN
         BEGIN
            SELECT cme_cust_code
              INTO v_cust_code
              FROM cms_mob_email_log
             WHERE cme_inst_code = :OLD.cam_inst_code
               AND cme_cust_code = :OLD.cam_cust_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  INSERT INTO cms_mob_email_log
                              (cme_inst_code, cme_cust_code,
                               cme_old_pmob, cme_old_omob, cme_new_pmob,
                               cme_new_omob, cme_old_pemal, cme_old_oemal,
                               cme_new_pemal, cme_new_oemal, cme_ins_user,
                               cme_ins_date, cme_lupd_user, cme_lupd_date,
                               cme_chng_date
                              )
                       VALUES (:OLD.cam_inst_code, :OLD.cam_cust_code,
                               :OLD.cam_mobl_one, NULL, :NEW.cam_mobl_one,
                               NULL, :OLD.cam_email, NULL,
                               :NEW.cam_email, NULL, :NEW.cam_ins_user,
                               SYSDATE, :NEW.cam_lupd_user, SYSDATE,
                               SYSDATE
                              );

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_application_error
                        (-20002,
                            'Error while inserting record from cms_mob_email_log 1.0 '
                         || SQLERRM
                        );
                     RETURN;
               END;
            WHEN OTHERS
            THEN
               raise_application_error
                  (-20003,
                      'Error while selecting cust code from cms_mob_email_log '
                   || SQLERRM
                  );
               RETURN;
         END;

         IF v_cust_code IS NOT NULL
         THEN
            BEGIN
               DELETE FROM cms_mob_email_log
                     WHERE cme_inst_code = :OLD.cam_inst_code
                       AND cme_cust_code = v_cust_code;

                      IF SQL%ROWCOUNT = 0 THEN
                          raise_application_error
                           (-20007,
                            'No Records deleted from cms_mob_email_log'
                        );
                         RETURN;
                      END IF;

            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_application_error
                     (-20004,
                         'Error while deleting record from cms_mob_email_log '
                      || SQLERRM
                     );
                  RETURN;
            END;

            BEGIN
               INSERT INTO cms_mob_email_log
                           (cme_inst_code, cme_cust_code,
                            cme_old_pmob, cme_old_omob, cme_new_pmob,
                            cme_new_omob, cme_old_pemal, cme_old_oemal,
                            cme_new_pemal, cme_new_oemal, cme_ins_user,
                            cme_ins_date, cme_lupd_user, cme_lupd_date,
                            cme_chng_date
                           )
                    VALUES (:OLD.cam_inst_code, :OLD.cam_cust_code,
                            :OLD.cam_mobl_one, NULL, :NEW.cam_mobl_one,
                            NULL, :OLD.cam_email, NULL,
                            :NEW.cam_email, NULL, :NEW.cam_ins_user,
                            SYSDATE, :NEW.cam_lupd_user, SYSDATE,
                            SYSDATE
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_application_error
                     (-20005,
                         'Error while inserting record from cms_mob_email_log 1.1 --'
                      || SQLERRM
                     );
                  RETURN;
            END;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20006,
                                  'Main exception from trg_cust_mob_email '
                               || SQLERRM
                              );
      RETURN;
END;                                                       --Trigger body ends
/
SHOW ERRORS;


