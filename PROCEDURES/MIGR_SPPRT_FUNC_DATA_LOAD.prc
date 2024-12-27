CREATE OR REPLACE PROCEDURE VMSCMS.migr_spprt_func_data_load (
   prm_file_name   IN       VARCHAR2,
   prm_errmsg      OUT      VARCHAR2
)
AS
   v_file_handle            UTL_FILE.file_type;
   v_filebuffer             VARCHAR2 (32767);
   v_header                 VARCHAR2 (50);
   v_header_file            VARCHAR2 (50);
   v_header_cnt             NUMBER(20);
   v_record_numb            VARCHAR2 (19);
   v_card_number            VARCHAR2 (19);
   v_new_card_number        VARCHAR2 (19);
   v_spprt_key              VARCHAR2 (15);
   v_remark                 VARCHAR2 (100);
   v_processed_date         VARCHAR2 (20);
   v_delivery_channel       VARCHAR2 (2);
   v_transaction_code       VARCHAR2 (15);
   v_spprt_rsncode          VARCHAR2 (3);
   n                        NUMBER             := 0;
   i                        NUMBER             := 0;
   exp_file_name            EXCEPTION;
   v_errmsg                 VARCHAR2 (300);
   v_error_flag             NUMBER (1);
   exp_loop_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;
   v_file_chk               NUMBER (2);
   v_succ_cnt               NUMBER (6)         := 0;
   v_err_cnt                NUMBER (6)         := 0;
   v_commit_param           NUMBER (5);
   PRAGMA EXCEPTION_INIT (exp_file_name, -29283);
BEGIN
   prm_errmsg := 'OK';

   IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1)) <> 'SUPP_'
   THEN
      prm_errmsg := 'Invalid file for support function data.';
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

   v_file_handle := UTL_FILE.fopen ('DIR_SUPP', prm_file_name, 'R');
   UTL_FILE.get_line (v_file_handle, v_filebuffer);            --to get header
   v_header := v_filebuffer;
   v_header_cnt := SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', -1, 1) + 1,8);
                                             ---to get count present in header
--  dbms_output.put_line(v_header_cnt);
   v_header_file :=
      SUBSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
              1,
                INSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
                       '_',
                       -1
                      )
              - 1
             );                             --to extract file name from header

   IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '.', 1) - 1) <>
                                                                 v_header_file
   THEN
      prm_errmsg := 'filename and header not matched';
      RAISE exp_reject_record;
   END IF;

   ---Sn to count number lines in file excluding header and footer
   LOOP
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      n := n + 1;

      IF   LENGTH (v_filebuffer)
         - LENGTH (TRIM (REPLACE (v_filebuffer, '|', ''))) <> 8
      THEN
         prm_errmsg := 'Invalid number of columns at record no ' || n;
         RAISE exp_reject_record;
      END IF;
   END LOOP;

   ---En to count number lines in file excluding header and footer
   IF n <> v_header_cnt
   THEN
      prm_errmsg := 'Record count not matched';
      RAISE exp_reject_record;
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_SUPP', prm_file_name, 'R');
   UTL_FILE.get_line (v_file_handle, v_filebuffer);

   ---Sn to create records in migration table
   LOOP
      v_errmsg := 'OK';
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      v_card_number := NULL;
      v_new_card_number := NULL;
      v_spprt_key := NULL;
      v_remark := NULL;
      v_processed_date := NULL;
      v_delivery_channel := NULL;
      v_transaction_code := NULL;
      i := i + 1;

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_record_numb
           FROM migr_ctrl_table
          WHERE mct_ctrl_key = 'SUPPORT_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_errmsg := 'Control number not defined for support function data.'; --Error message modified by Pankaj S. on 25-Sep-2013
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while getting control number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         --dbms_output.put_line(i);
         --dbms_output.put_line(v_filebuffer);
         v_error_flag := 1;
         v_card_number :=
             TRIM (SUBSTR (v_filebuffer, 1, INSTR (v_filebuffer, '|', 1) - 1));

         IF v_card_number IS NULL
         THEN
            v_errmsg := 'Card number is not present in file.';
            RAISE exp_loop_reject_record;
         ELSE
            IF LENGTH (v_card_number) NOT IN (16, 19)
            THEN
               v_errmsg := 'Invalid length of PAN.';
               RAISE exp_loop_reject_record;
            END IF;
         END IF;

         v_error_flag := 2;
         v_new_card_number :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1) + 1,
                            (INSTR (v_filebuffer, '|', 1, 2) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1)
                         )
                 );
         v_error_flag := 3;
         v_spprt_key :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 2) + 1,
                            (INSTR (v_filebuffer, '|', 1, 3) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 2)
                         )
                 );

         IF v_spprt_key IS NULL
         THEN
            v_errmsg := 'Spprt key is not present.';
            RAISE exp_loop_reject_record;
         ELSE
            IF v_spprt_key NOT IN
                  ('CARDCLOSE', 'HTLST', 'REISU', 'ADDR ', 'REPIN', 'DEHOT',
                   'DBLOK', 'LINK', 'ACCCL', 'DLINK1', 'DLINK2', 'BLOCK',
                   'RENEW', 'TOP', 'ACCREF', 'PIN_CHANGE', 'INLOAD',
                   'ACTVTCARD', 'HTLST_REISU', 'UPDATELIMITS', 'MANADJDRCR','RESTRICT',
                   'CARDACTIVE','HOTCARDED','PROFILE','PROFUPD','REISSUE','MONITORED')
            THEN
               v_errmsg := 'Not a valid support key.';
               RAISE exp_loop_reject_record;
            END IF;
         END IF;

         IF v_spprt_key IN ('REISU', 'HTLST_REISU')
         THEN
            IF v_new_card_number IS NULL
            THEN
               v_errmsg := 'New Card number is not present.';  --Error message modified by Pankaj S. on 25-Sep-2013
               RAISE exp_loop_reject_record;
            END IF;
         END IF;

         v_error_flag := 4;
         v_remark :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 3) + 1,
                            (INSTR (v_filebuffer, '|', 1, 4) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 3)
                         )
                 );
         v_error_flag := 5;
         v_processed_date :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 4) + 1,
                            (INSTR (v_filebuffer, '|', 1, 5) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 4)
                         )
                 );

         IF v_processed_date IS NULL
         THEN
            v_errmsg := 'Process date is not present.';
            RAISE exp_loop_reject_record;
         END IF;

         v_error_flag := 6;
         v_delivery_channel :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 5) + 1,
                            (INSTR (v_filebuffer, '|', 1, 6) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 5)
                         )
                 );

         IF v_delivery_channel IS NULL
         THEN
            v_errmsg := 'Delivery channel is not present.';
            RAISE exp_loop_reject_record;
         END IF;

         v_error_flag := 7;
         v_transaction_code :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 6) + 1,
                            (INSTR (v_filebuffer, '|', 1, 7) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 6)
                         )
                 );

         IF v_transaction_code IS NULL
         THEN
            v_errmsg := 'Transaction code is not present.';
            RAISE exp_loop_reject_record;
         END IF;

         v_error_flag := 8;
         v_spprt_rsncode :=
            TRIM (SUBSTR (v_filebuffer,
                          INSTR (v_filebuffer, '|', 1, 7) + 1,
                            (INSTR (v_filebuffer, '|', 1, 8) - 1
                            )
                          - INSTR (v_filebuffer, '|', 1, 7)
                         )
                 );

         IF v_spprt_rsncode IS NULL
         THEN
            v_errmsg := 'Support reason code is not present.';
            RAISE exp_loop_reject_record;
         END IF;

         BEGIN
            INSERT INTO migr_spprt_func_data
                        (msf_file_name, msf_record_numb, msf_card_number,
                         msf_new_card_number, msf_spprt_key, msf_remark,
                         msf_processed_date, msf_delivery_channel,
                         msf_transaction_code, msf_spprt_rsncde
                        )
                 VALUES (prm_file_name, v_record_numb, v_card_number,
                         v_new_card_number, v_spprt_key, v_remark,
                         v_processed_date, v_delivery_channel,
                         v_transaction_code, v_spprt_rsncode
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting into support function segment '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;

         v_succ_cnt := v_succ_cnt + 1;

         IF MOD (i, v_commit_param) = 0
         THEN         --commit after number of records defined at master level
            COMMIT;
         END IF;
      EXCEPTION
         WHEN exp_loop_reject_record
         THEN
            v_err_cnt := v_err_cnt + 1;
            sp_migr_log_excp_spprtfunc (prm_file_name,
                                        v_record_numb,
                                        v_card_number,
                                        v_new_card_number,
                                        v_spprt_key,
                                        v_transaction_code,
                                        'E',
                                        v_errmsg
                                       );
         WHEN OTHERS
         THEN
            v_err_cnt := v_err_cnt + 1;
            v_errmsg :=
                  'Error while fetching data at posn '
               || v_error_flag
               || '-'
               || SUBSTR (SQLERRM, 1, 200);
            sp_migr_log_excp_spprtfunc (prm_file_name,
                                        v_record_numb,
                                        v_card_number,
                                        v_new_card_number,
                                        v_spprt_key,
                                        v_transaction_code,
                                        'E',
                                        v_errmsg
                                       );
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_key = 'SUPPORT_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while updating cotrol number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END LOOP;
   COMMIT;  --added by Pankaj S. on 11_Jun_2013
   ---En to create records in migration table
   UTL_FILE.fclose (v_file_handle);

   BEGIN                                                 --reset contrl number
      UPDATE migr_ctrl_table
         SET mct_ctrl_numb = 1
       WHERE mct_ctrl_key = 'SUPPORT_DATA' AND mct_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error while resetting cotrol number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn to create log for files
   BEGIN
      sp_migr_file_detl ('SPPRTFUNC_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         i,
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
      sp_migr_file_detl ('SPPRTFUNC_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         n,
                         v_succ_cnt,
                         v_err_cnt,
                         'E',
                         prm_errmsg
                        );
   WHEN exp_file_name
   THEN
      prm_errmsg :=
         'An attempt was made to read from a file or directory that does not exist, or file or directory access was denied by the operating system.';
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERRORS;