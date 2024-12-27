CREATE OR REPLACE PROCEDURE VMSCMS.sp_roll_dupacct_activity (
   prm_error_code   OUT   NUMBER,
   prm_error        OUT   VARCHAR2
)
IS
   CURSOR cur_audit_rec
   IS
      SELECT ROWID row_id, cda_acct_no, cda_acct_id, cda_pan_code,
             cda_new_acct_no, cda_new_acct_id, cda_cust_code, cda_card_stat,
             cda_mask_pan, cda_process_flag, cda_process_msg, cda_ins_date
        FROM cms_dup_acct_pan
       WHERE cda_process_flag = 'S';

   TYPE cur_audit_rec_type IS TABLE OF cur_audit_rec%ROWTYPE;

   cur_audit_rec_data   cur_audit_rec_type;
BEGIN
   prm_error := 'OK';

   BEGIN
      OPEN cur_audit_rec;

      LOOP
         FETCH cur_audit_rec
         BULK COLLECT INTO cur_audit_rec_data LIMIT 1000;

         EXIT WHEN cur_audit_rec_data.COUNT () = 0;

         FOR i IN 1 .. cur_audit_rec_data.COUNT ()
         LOOP
            BEGIN
               UPDATE cms_pan_acct
                  SET cpa_acct_id = cur_audit_rec_data (i).cda_acct_id
                WHERE cpa_inst_code = 1
                  AND cpa_acct_id = cur_audit_rec_data (i).cda_new_acct_id
                  AND cpa_pan_code = cur_audit_rec_data (i).cda_pan_code
                  AND cpa_mbr_numb = '000';
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_error :=
                        'WHILE UPDATE Account id/ no  in  cms_pan_acct :'
                     || SUBSTR (SQLERRM, 1, 100);
                  prm_error_code := SQLCODE;
                  RETURN;
            END;

            /*  BEGIN
                 UPDATE cms_cust_acct
                    SET cca_hold_posn = 1
                  WHERE cca_inst_code = 1
                    AND cca_cust_code = cur_audit_rec_data (i).cda_cust_code
                    AND cca_acct_id = cur_audit_rec_data (i).cda_acct_id;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    prm_error :=
                          'WHILE UPDATE OLD Account id/ no  in  cms_cust_acct :'
                       || SUBSTR (SQLERRM, 1, 100);
                    prm_error_code := SQLCODE;
                    RETURN;
              END; */
            BEGIN
               UPDATE cms_cust_acct
                  SET cca_acct_id = cur_audit_rec_data (i).cda_acct_id
                WHERE cca_inst_code = 1
                  AND cca_cust_code = cur_audit_rec_data (i).cda_cust_code
                  AND cca_acct_id = cur_audit_rec_data (i).cda_new_acct_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_error :=
                        'WHILE UPDATE NEW Account id/ no  in  cms_cust_acct :'
                     || SUBSTR (SQLERRM, 1, 100);
                  prm_error_code := SQLCODE;
                  RETURN;
            END;

            BEGIN
               UPDATE cms_appl_pan
                   SET cap_acct_id = cur_audit_rec_data (i).cda_acct_id,
                      cap_acct_no = cur_audit_rec_data (i).cda_acct_no
                WHERE cap_pan_code = cur_audit_rec_data (i).cda_pan_code
                  AND cap_acct_id = cur_audit_rec_data (i).cda_new_acct_id
                  AND cap_acct_no = cur_audit_rec_data (i).cda_new_acct_no;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_error :=
                        'WHILE UPDATE Account id/ no  in  cms_appl_pan :'
                     || SUBSTR (SQLERRM, 1, 100);
                  prm_error_code := SQLCODE;
                  RETURN;
            END;

            BEGIN
               DELETE      cms_acct_mast
                     WHERE cam_inst_code = 1
                       AND cam_acct_id =
                                        cur_audit_rec_data (i).cda_new_acct_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_error :=
                        'WHILE UPDATE Account id/ no  in  cms_pan_acct :'
                     || SUBSTR (SQLERRM, 1, 100);
                  prm_error_code := SQLCODE;
                  RETURN;
            END;

            IF prm_error = 'OK'
            THEN
               BEGIN
                  UPDATE cms_dup_acct_pan
                     SET cda_process_flag = 'R'
                   WHERE ROWID = cur_audit_rec_data (i).row_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     prm_error :=
                           'Error while updating rollback flag-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RETURN;
               END;
            END IF;
         END LOOP;
      END LOOP;

      CLOSE cur_audit_rec;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_error :=
                'Main Exception from procedure :' || SUBSTR (SQLERRM, 1, 100);
      prm_error_code := SQLCODE;
      RETURN;
END;
/

SHOW ERRORS;


