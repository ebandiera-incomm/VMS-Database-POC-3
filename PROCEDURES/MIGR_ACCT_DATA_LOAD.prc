CREATE OR REPLACE PROCEDURE VMSCMS.migr_acct_data_load (
   prm_file_name   IN       VARCHAR2,
   prm_errmsg      OUT      VARCHAR2,
   prm_seqno       IN       NUMBER
)
AS
   v_file_handle               UTL_FILE.file_type;
   v_filebuffer                VARCHAR2 (32767)   := NULL;
   v_header                    VARCHAR2 (50);
   v_header_file               VARCHAR2 (30);
   v_header_cnt                NUMBER (20);
   v_record_numb               VARCHAR2 (19);
   v_acct_number               VARCHAR2 (20);
   v_acct_no_already_present   VARCHAR2 (20);
   --v_branch_id               VARCHAR2 (4);
   v_branch_id                 VARCHAR2 (6);
                                       --Commented and modified on 25.06.2013
   --v_acct_type               VARCHAR2 (2);
   v_acct_type                 VARCHAR2 (3);
                                       --Commented and modified on 25.06.2013
   --v_acct_stat               VARCHAR2 (2);
   v_acct_stat                 VARCHAR2 (3);
   --Commented and modified on 25.06.2013
   v_acct_gendate              VARCHAR2 (20);
   --v_avail_bal               VARCHAR2 (25);
   v_avail_bal                 VARCHAR2 (21);
                                       --Commented and modified on 25.06.2013
   --v_ledg_bal                VARCHAR2 (25);
   v_ledg_bal                  VARCHAR2 (21);
   --Commented and modified on 25.06.2013
   v_saving_acct_ropendate     VARCHAR2 (20);
   --v_saving_acct_intrstamt   VARCHAR2 (35);
   --v_saving_acct_intrstamt   VARCHAR2 (31);--Commented and modified on 25.06.2013--Ccommented and modified on 26.06.2013
   v_saving_acct_intrstamt     VARCHAR2 (21);
   v_check                     NUMBER             := 0;
   v_cnt                       NUMBER             := 0;
   exp_file_name               EXCEPTION;
   v_errmsg                    VARCHAR2 (32767);
   v_error_flag                NUMBER (2);
   exp_loop_reject_record      EXCEPTION;
   exp_reject_record           EXCEPTION;
   v_file_chk                  NUMBER (2);
   v_acct_type_cnt             NUMBER (1);
   v_acct_stat_cnt             NUMBER (1);
   v_proc_flag                 VARCHAR2 (1);
   v_succ_cnt                  NUMBER (6)         := 0;
   v_err_cnt                   NUMBER (6)         := 0;
   v_commit_param              NUMBER (5);
   PRAGMA EXCEPTION_INIT (exp_file_name, -29283);
   v_saving_acct_closedate     VARCHAR2 (20);
   --Added by Pankaj S. on 11_Jun_2013
   v_dum                       NUMBER (1);
   v_datechk                   DATE;
   v_numchk                    NUMBER;
   v_length_check              VARCHAR2 (1000);
   v_sqlerr                    VARCHAR2 (32767)   := NULL;
   v_exist_acct                VARCHAR2 (2);           --Added on 02_Aug_2013
--Added On 24.06.2013
BEGIN
   prm_errmsg := 'OK';

   --Sn Modified on 02_Aug_2013
   --IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1)) <> 'ACCO_'
   IF SUBSTR (prm_file_name,INSTR (prm_file_name, '_', 1) + 1,(INSTR (prm_file_name, '_', 1, 2)- INSTR (prm_file_name, '_', 1))) <> 'ACCO_'
   --En Modified on 02_Aug_2013
   THEN
      prm_errmsg := 'Invalid file for account data.';
      RAISE exp_reject_record;
   END IF;

   BEGIN
      SELECT COUNT (1)
        INTO v_file_chk
        FROM migr_file_detl
       WHERE mfd_file_name = prm_file_name AND mfd_file_load_flag = 'S';

      IF v_file_chk != 0
      THEN
         prm_errmsg := 'File already processed.';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while selecting file name ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT mct_ctrl_numb
        INTO v_commit_param
        FROM migr_ctrl_table
       WHERE mct_ctrl_key = 'COMMIT_PARAM';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Commit Paramter not defined in master.';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting commit parameter '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF UTL_FILE.is_open (v_file_handle)
   THEN
      UTL_FILE.fclose (v_file_handle);
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_ACCO', prm_file_name, 'R', 32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);            --to get header
   v_header := v_filebuffer;
   v_header_cnt :=
                  SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', -1, 1) + 1,
                          8);                ---to get count present in header
--  dbms_output.put_line(v_header_cnt);
   v_header_file :=
      SUBSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
              1,
                INSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
                       '_',
                       -1
                      )
              - 1
             );

   --to extract file name from header
   IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1, 2) - 1) <>
                                                     --modified on 02_Aug_2013
                                                                 v_header_file
   THEN
      prm_errmsg := 'filename and header not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record;
   END IF;

   ---Sn to count number lines in file excluding header and footer
   LOOP
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      v_check := v_check + 1;
--      IF   LENGTH (TRIM(v_filebuffer))
--         - LENGTH (TRIM (REPLACE (v_filebuffer, '|', ''))) <> 10
   END LOOP;

   ---En to count number lines in file excluding header and footer
   IF v_check <> v_header_cnt
   THEN
      prm_errmsg := 'Record count in file and in header not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record;
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_ACCO', prm_file_name, 'R', 32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);

   ---Sn to create records in migration table
   LOOP
      v_acct_number := NULL;
      v_branch_id := NULL;
      v_acct_type := NULL;
      v_acct_stat := NULL;
      v_acct_gendate := NULL;
      v_avail_bal := NULL;
      v_ledg_bal := NULL;
      v_saving_acct_ropendate := NULL;
      v_saving_acct_intrstamt := NULL;
      v_saving_acct_closedate := NULL;    --Added by Pankaj S. on 11_Jun_2013
      v_length_check := NULL;
      v_errmsg := 'OK';
      v_proc_flag := 'N';
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      v_cnt := v_cnt + 1;
      v_exist_acct := 'N';                             --Added on 02_Aug_2013

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_record_numb
           FROM migr_ctrl_table
          WHERE mct_ctrl_key = 'ACCOUNT_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_errmsg := 'Control number not defined for account data.';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while getting control number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         IF LENGTH (TRIM (v_filebuffer)) = 0
         THEN
            v_errmsg := '-No Record Found At Line no' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         IF regexp_count (v_filebuffer, '[|]', 1) <> 10
         THEN
            v_errmsg :=
                   '-Invalid number of columns at record no ' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         BEGIN
            v_error_flag := 1;
            v_length_check :=
                 (SUBSTR (v_filebuffer, 1, INSTR (v_filebuffer, '|', 1) - 1)
                 );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Account number length is invalid.';
               ELSE
                  BEGIN
                     v_dum := 0;

                     --SELECT 1  --Commented and modified on 24.06.2013
                     SELECT COUNT (1)
                       INTO v_dum
                       FROM cms_acct_mast
                      WHERE cam_inst_code = 1 AND cam_acct_no = v_length_check;

                     --IF v_dum = 1 --Commented and modified on 24.06.2013
                     IF v_dum > 0
                     THEN
                        v_exist_acct := 'Y';           --Added on 02_Aug_2013
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Account Already Present in CMS ';
                        v_acct_no_already_present := v_length_check;
                     ELSE
                        /*-----Account Number ---*/
                        v_acct_number := v_length_check;
                     /*-----Account Number ---*/
                     END IF;

                     --SN Added on 24.06.2013 for i/p parameter check (Character/Number)
                     BEGIN
                        v_numchk := TO_NUMBER (v_length_check);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 v_errmsg
                              || '--'
                              || 'Account number should be Numeric.';
                     END;
                  --EN Added on 24.06.2013 for i/p parameter check (Character/Number)
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'OK';
                     /*WHEN exp_loop_reject_record
                      THEN
                         RAISE exp_loop_reject_record; */
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while Searching For Account '
                           || v_acct_number
                           || ' as -'
                           || SUBSTR (SQLERRM, 1, 100);
                  END;
               END IF;
            ELSE
               v_errmsg :=
                         v_errmsg || '--' || 'Account number is not present.';
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Account number Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 2;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1) + 1,
                               (INSTR (v_filebuffer, '|', 1, 2) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1)
                            )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 6
            THEN
               v_errmsg := v_errmsg || '--' || 'Branch ID length is invalid.';
            ELSE
               /*-----Branch ID ---*/
               v_branch_id := v_length_check;
            /*-----Branch ID ---*/
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Branch Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning

         /*
                  IF v_branch_id IS NULL
                  THEN
                     v_errmsg := v_errmsg || '--' || 'Branch id is not present.';
                  ELSIF LENGTH (v_branch_id) > 6
                  THEN
                     v_errmsg := v_errmsg || '--' || 'Branch id length is invalid.';
                   END IF;
         */
         BEGIN
            v_error_flag := 3;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 2) + 1,
                               (INSTR (v_filebuffer, '|', 1, 3) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 2)
                            )
                    );                         

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 3
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'Account type length is invalid.';
               ELSE
                  BEGIN
                     SELECT 1
                       INTO v_acct_type_cnt
                       FROM cms_acct_type
                      WHERE cat_inst_code = 1
                      and   cat_type_code = v_length_check;

                     /*-----Account Type--*/
                     v_acct_type := v_length_check;
                  /*-----Account Type--*/
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Acct type not defined in master for acct number ';
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while selecting acct type for account number '
                           || SUBSTR (SQLERRM, 1, 200);
                  END;

                  IF v_acct_type = 2
                  THEN
                     v_proc_flag := 'P';
                  END IF;
               END IF;
            ELSE
              --SN: Modified for Galileo Changes //Account type marked as optional and use default as '01'
               v_acct_type := '01';
               --v_errmsg := v_errmsg || '--' || 'Account type is not present.';
              --EN: Modified for Galileo Changes //Account type marked as optional and use default as '01'
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Account Type Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 4;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 3) + 1,
                               (INSTR (v_filebuffer, '|', 1, 4) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 3)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Account status code is not present.';
            ELSE
               IF LENGTH (v_length_check) > 3
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Account status length is invalid.';
               ELSE
                  BEGIN
                     SELECT 1
                       INTO v_acct_stat_cnt
                       FROM cms_acct_stat
                      WHERE CAS_INST_CODE = 1
                      and   cas_stat_code = v_length_check;

                     /*-----Account Status--*/
                     v_acct_stat := v_length_check;
                  /*-----Account Status--*/
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Acct status not defined in master for acct number ';
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while selecting stat for acct number '
                           || SUBSTR (SQLERRM, 1, 200);
                  END;
               END IF;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Account Status Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 5;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 4) + 1,
                               (INSTR (v_filebuffer, '|', 1, 5) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 4)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Account creation date is not present.';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Account creation Date length is invalid.'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*-----Account Gen Date--*/
                  v_acct_gendate := v_length_check;
               /*-----Account Gen Date--*/
               END IF;

               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account creation date is in invalid format.';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Account Creation date  Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 6;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 5) + 1,
                               (INSTR (v_filebuffer, '|', 1, 6) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 5)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Account available balance is NULL ';--Error message modified by Pankaj S. on 25-Sep-2013
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Account balance length is invalid.';
               ELSE
                  /*-----Account Available Balance--*/
                  v_avail_bal := v_length_check;
               /*-----Account Available Balance--*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Available Account balance should be Numeric.';
               END;

               BEGIN
                  v_numchk :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Available Account balance precision exceeded';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Available Account balance Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 7;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 6) + 1,
                               (INSTR (v_filebuffer, '|', 1, 7) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 6)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Account ledger balance is NULL.'; --Error message modified by Pankaj S. on 25-Sep-2013
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Ledger balance length is invalid.';
               ELSE
                  /*-----Account Ledger Balance--*/
                  v_ledg_bal := v_length_check;
               /*-----Account Ledger Balance--*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account Ledger balance should be Numeric.';
               END;

               BEGIN
                  v_numchk :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Available Ledger balance precision exceeded';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Available Ledger balance Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning

         --Sn Added on 02_Aug_2013
         IF v_exist_acct = 'Y'
         THEN
            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = v_avail_bal,
                      cam_ledger_bal = v_ledg_bal
                WHERE cam_inst_code = 1 AND cam_acct_no = v_acct_number;

                IF SQL%ROWCOUNT=0 THEN
                v_errmsg :=v_errmsg|| '--'|| 'Available & Ledger balance updation failed.';
                END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                   v_errmsg :=v_errmsg|| '--'|| 'Available & Ledger balance updation failed.';
               v_sqlerr :=v_sqlerr|| ' -- '|| 'Balance updation failed for acct no '|| v_acct_number|| ' with tech error '|| SUBSTR (SQLERRM, 1, 100);
            END;
         END IF;
         --En Added on 02_Aug_2013

         BEGIN
            v_error_flag := 8;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 7) + 1,
                               (INSTR (v_filebuffer, '|', 1, 8) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 7)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Saving Account Reopen Date length is invalid.';
               ELSE
                  /*-----Savings Account Reopen Date--*/
                  v_saving_acct_ropendate := v_length_check;
               /*-----Savings Account Reopen Date--*/
               END IF;

               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Saving Account reopen date is in invalid format.';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Saving Account reopen date Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            v_error_flag := 9;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 8) + 1,
                               (INSTR (v_filebuffer, '|', 1, 9) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 8)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               --  IF LENGTH (v_length_check) > 31
               IF LENGTH (v_length_check) > 21
               --Modified on 25.06.2013 for maintaining amount in (20,2) format
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Saving Account Interest Amount length is invalid.';
               ELSE
                  /*-----Savings Account Intrest Amount--*/
                  v_saving_acct_intrstamt := v_length_check;
               /*-----Savings Account Intrest Amount--*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Saving Account interest amount should be Numeric.';
               END;

               BEGIN
                  v_numchk :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Saving Account interest amount precision exceeded';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Saving Account interest amount Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning
         BEGIN
            --Sn added new feilds by Pankaj S. on 11_Jun_2013
            v_error_flag := 10;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 9) + 1,
                               (INSTR (v_filebuffer, '|', 1, 10) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 9)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Saving Account Closing Date length is invalid.';
               ELSE
                  /*-----Savings Account Closing Date--*/
                  v_saving_acct_closedate := v_length_check;
               /*-----Savings Account Closing Date--*/
               END IF;

               BEGIN
                  v_datechk :=
                     TO_DATE (v_saving_acct_closedate, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Saving Account Closing date is in invalid format.';
               END;
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Saving Account Closing date Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN Added on 24.06.2013 for exception handling for each field while assigning

         --En added new feilds by Pankaj S. on 11_Jun_2013
         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_loop_reject_record;
         END IF;

         BEGIN
            INSERT INTO migr_acct_data_temp
                        (mad_file_name, mad_record_numb, mad_acct_numb,
                         mad_branch_id, mad_acct_type, mad_acct_stat,
                         mad_acctgen_date, mad_avail_bal, mad_ledg_bal,
                         mad_savng_acctreopen_date,
                         mad_savng_acct_interest_amt, mad_proc_flag,
                         mad_savngacct_closing_date,
                         --Added by Pankaj S. on 11_Jun_2013
                         mad_migr_seqno                 --Added on 12-JUL-2013
                        )
                 VALUES (prm_file_name, v_record_numb, v_acct_number,
                         --SN:Modified for Galileo Migr changes //1.Default value of 0001 to be used for branch id
                         NVL(v_branch_id,'0001'), v_acct_type, v_acct_stat,  
                         --EN:Modified for Galileo Migr changes 
                         v_acct_gendate, v_avail_bal, v_ledg_bal,
                         v_saving_acct_ropendate,
                         v_saving_acct_intrstamt, v_proc_flag,
                         v_saving_acct_closedate,
                         --Added by Pankaj S. on 11_Jun_2013
                         prm_seqno                      --Added on 12-JUL-2013
                        );
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Duplicate Account Found While Loading Files';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Error while inserting into account data segment '
                  || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         END;

         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_loop_reject_record;
         END IF;

         v_succ_cnt := v_succ_cnt + 1;

         IF MOD (v_cnt, v_commit_param) = 0
         THEN         --commit after number of records defined at master level
            COMMIT;
         END IF;
      EXCEPTION
         WHEN exp_loop_reject_record
         THEN
            SELECT DECODE (SUBSTR (v_errmsg, 1, 2),
                           'OK', SUBSTR (v_errmsg, 5),
                           SUBSTR (v_errmsg, 2)
                          )
              INTO v_errmsg
              FROM DUAL;

            v_err_cnt := v_err_cnt + 1;

            IF v_dum > 0
            THEN
               v_acct_number := v_acct_no_already_present;
            END IF;

            sp_migr_log_excp_accountdata (prm_file_name,
                                          v_record_numb,
                                          v_acct_number,
                                          'E',
                                          v_errmsg,
                                          v_sqlerr       --Added On 24.06.2013
                                         );
         WHEN OTHERS
         THEN
            v_err_cnt := v_err_cnt + 1;
            v_errmsg :=
                  v_errmsg
               || 'Error while fetching data at posn '
               || v_error_flag
               || '-'
               || SUBSTR (SQLERRM, 1, 200);

            SELECT DECODE (SUBSTR (v_errmsg, 1, 2),
                           'OK', SUBSTR (v_errmsg, 5),
                           SUBSTR (v_errmsg, 2)
                          )
              INTO v_errmsg
              FROM DUAL;

            IF v_dum > 0
            THEN
               v_acct_number := v_acct_no_already_present;
            END IF;

            sp_migr_log_excp_accountdata (prm_file_name,
                                          v_record_numb,
                                          v_acct_number,
                                          'E',
                                          v_errmsg,
                                          v_sqlerr       --Added On 24.06.2013
                                         );
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_key = 'ACCOUNT_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while updating control number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END LOOP;

   COMMIT;                                 --Added by Pankaj S. on 11_Jun_2013
   ---En to create records in migration table
   UTL_FILE.fclose (v_file_handle);

   BEGIN                                           ---resetting control number
      UPDATE migr_ctrl_table
         SET mct_ctrl_numb = 1
       WHERE mct_ctrl_key = 'ACCOUNT_DATA' AND mct_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error while updating control number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn to create successful log for files
   BEGIN
      sp_migr_file_detl ('ACCOUNT_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         v_check,
                         v_succ_cnt,
                         v_err_cnt,
                         'S',
                         'Successful'
                        );
   END;
--En to create log for files
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK;
      sp_migr_file_detl ('ACCOUNT_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         v_check,
                         v_succ_cnt,
                         v_err_cnt,
                         'E',
                         prm_errmsg
                        );

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
   WHEN exp_file_name
   THEN
      prm_errmsg :=
         'An attempt was made to read from a file or directory that does not exist, or file or directory access was denied by the operating system.';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
END;
/
SHOW ERROR