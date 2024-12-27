CREATE OR REPLACE PROCEDURE VMSCMS.migr_calllog_data_load (
   prm_file_name   IN       VARCHAR2,
   prm_errmsg      OUT      VARCHAR2,
   prm_seqno       IN       NUMBER
)
AS
   v_file_handle               UTL_FILE.file_type;
   --v_filebuffer                VARCHAR2 (32767)   := NULL;
   v_filebuffer                NVARCHAR2 (32767)   := NULL; -- sachin
   v_header                    VARCHAR2 (50);
   v_header_file               VARCHAR2 (30);
   v_header_cnt                NUMBER (20);
   v_record_numb               VARCHAR2 (20);

   v_pan_code                  VARCHAR2 (19);
   v_call_starttime            VARCHAR2 (17);
   v_branch_id                 VARCHAR2 (6);
   --v_call_type                 VARCHAR2 (3);
   v_call_type                 number (3); -- sachin 
   
   v_comment                   VARCHAR2 (1000);
   v_status                    VARCHAR2 (1);
   v_call_endtime              VARCHAR2 (17);
   v_tran_code                 VARCHAR2 (1000);
   v_rrn                       VARCHAR2 (15);
   v_business_date             VARCHAR2 (2000);
   v_business_time             VARCHAR2 (2000);
   v_tran_comments             VARCHAR2 (4000);
   v_start_time_chk            Date;
   v_end_time_chk              Date;
   v_call_type_cnt             number(1);



   v_check                     NUMBER             := 0;
   v_cnt                       NUMBER             := 0;
   exp_file_name               EXCEPTION;
   v_errmsg                    VARCHAR2 (32767);
   v_error_flag                NUMBER (2);
   exp_loop_reject_record      EXCEPTION;
   exp_reject_record           EXCEPTION;
   v_file_chk                  NUMBER (2);
   v_proc_flag                 VARCHAR2 (1);
   v_succ_cnt                  NUMBER (6)         := 0;
   v_err_cnt                   NUMBER (6)         := 0;
   v_commit_param              NUMBER (5);
   PRAGMA EXCEPTION_INIT (exp_file_name, -29283);
   v_dum                       NUMBER (1);
   v_datechk                   DATE;
   v_numchk                    NUMBER;
   v_length_check             NVARCHAR2 (4000); -- Sachin 
   v_sqlerr                    VARCHAR2 (32767)   := NULL;
   v_exist_acct                VARCHAR2 (2);
BEGIN
   prm_errmsg := 'OK';

   IF SUBSTR (prm_file_name,INSTR (prm_file_name, '_', 1) + 1,(INSTR (prm_file_name, '_', 1, 2)- INSTR (prm_file_name, '_', 1))) <> 'CALL_'
   --En Modified on 02_Aug_2013
   THEN
      prm_errmsg := 'Invalid file for Calllog data.';
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

   v_file_handle := UTL_FILE.fopen ('DIR_CALL', prm_file_name, 'R', 32767);
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

   v_file_handle := UTL_FILE.fopen ('DIR_CALL', prm_file_name, 'R', 32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);

   ---Sn to create records in migration table
   LOOP
      v_pan_code        := NULL;
      v_call_starttime      := NULL;
      v_branch_id       := NULL;
      v_call_type       := NULL;
      v_comment         := NULL;
      v_status          := NULL;
      v_call_endtime    := NULL;
      v_tran_code       := NULL;
      v_rrn             := NULL;
      v_business_date   := NULL;
      v_business_time   := NULL;
      v_tran_comments   := NULL;

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
          WHERE mct_ctrl_key = 'CALL_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_errmsg := 'Control number not defined for Calllog data.';
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
            v_errmsg := 'No Record Found At Line no' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         IF regexp_count (v_filebuffer, '[|]', 1) <> 11
         THEN
            v_errmsg :=
                   'Invalid number of columns at record no ' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         BEGIN
            v_error_flag := 1;
            v_length_check :=
                 (SUBSTR (v_filebuffer, 1, INSTR (v_filebuffer, '|', 1) - 1)
                 );

            IF v_length_check IS NOT NULL
            THEN

               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Card number length is invalid.';
               ELSE
                  BEGIN

                      /*-----card Number ---*/
                        v_pan_code := v_length_check;
                     /*-----card Number ---*/


                     BEGIN
                        v_numchk := TO_NUMBER (v_length_check);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 v_errmsg
                              || '--'
                              || 'Card number should be Numeric.';
                     END;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'OK';
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while Searching For card number '
                           || v_pan_code
                           || ' as -'
                           || SUBSTR (SQLERRM, 1, 100);
                  END;
               END IF;
            ELSE
               v_errmsg :=
                         v_errmsg || '--' || 'Card number is not present.';
            END IF;
         --SN Added on 24.06.2013 for exception handling for each field while assigning
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Card number Validation failed.';
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

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 17
            THEN
               v_errmsg := v_errmsg || '--' || 'start time length is invalid.';
            ELSE

              if v_length_check is null
              then

                v_errmsg := v_errmsg || '--' || 'start time is null';

              else

               /*-----Start Time---*/
               v_call_starttime := v_length_check;
              /*-----Start Time---*/

              end if;

            END IF;

           BEGIN
              v_start_time_chk :=
                          TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_errmsg :=
                       v_errmsg
                    || '--'
                    || 'Start Time is in invalid format.';
           END;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'start time Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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
                        v_errmsg || '--' || 'Call type length is invalid.';
               ELSE
                  BEGIN
                     SELECT 1
                       INTO v_call_type_cnt
                       FROM CMS_CALLCATG_MAST
                      WHERE ccm_inst_code = 1
                      and   CCM_CATG_ID = v_length_check;

                     /*-----Call Type--*/
                     v_call_type := v_length_check;
                     /*-----Call Type--*/

                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Call type not defined in master for card number '||v_pan_code;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while selecting Call type for card number '||v_pan_code||' '
                           || SUBSTR (SQLERRM, 1, 200);
                  END;


               END IF;
            ELSE
               v_errmsg := v_errmsg || '--' || 'Call type is not present.';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Call Type Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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

            --SN:Modified for Galileo changes //To marked comments as optional
            --IF v_length_check IS NULL
            --THEN
               --v_errmsg := v_errmsg || '--' || 'Call comment is not present.';
            --ELSE
            --EN:Modified for Galileo changes //To marked comments as optional
               IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1000 --Modified for Galileo changes //To marked comments as optional
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Call comment length is invalid.';
               ELSE

                   /*-----Call comment--*/
                     v_comment := v_length_check;
                  /*-----Call comment--*/

               END IF;

            --END IF; --Modified for Galileo changes //To marked comments as optional
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Call comment Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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
               --SN:Modified for Galileo changes //By Default call staus can be considered as closed
               --v_errmsg :=  v_errmsg || '--' || 'Call Status is not present.';
               v_length_check:='1';
               --EN:Modified for Galileo changes //By Default call staus can be considered as closed
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=  v_errmsg || '--'|| 'Call Status length is invalid.';
               ELSE
                  /*-----Call Status--*/
                  v_status := v_length_check;
               /*-----Call Status--*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for Call Status ';
               END;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Call Status Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 17
            THEN
               v_errmsg := v_errmsg || '--' || 'End time length is invalid.';
            ELSE

              if v_length_check is null
              then

                v_errmsg := v_errmsg || '--' || 'End time is null';

              else

               /*-----Start Time---*/
               v_call_endtime := v_length_check;
              /*-----Start Time---*/

              end if;

            END IF;

           BEGIN
              v_end_time_chk :=  TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_errmsg :=
                       v_errmsg
                    || '--'
                    || 'End Time is in invalid format.';
           END;


         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'End Time Validation failed.';
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
                  || 'Tran code list is NULL.'; --Error message modified by Pankaj S. on 25-Sep-2013
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1000
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Tran code list length is invalid.';
               ELSE
                  /*-----Tran code list--*/
                  v_tran_code := v_length_check;
               /*-----Tran code list--*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Tran code list Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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
               IF LENGTH (v_length_check) > 15
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'rrn length is invalid.';
               ELSE
                  /*-----rrn--*/
                  v_rrn := v_length_check;
                 /*-----rrn--*/
               END IF;

            END IF;

            --SN:Modified for Galileo changes //To marked RRN as optional
            /*IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'rrn is NULL.';
            END IF;*/
            --EN:Modified for Galileo changes //To marked RRN as optional

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'rrn Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

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
               IF LENGTH (v_business_date) > 2000
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'business_date length is invalid.';
               ELSE
                  /*-----business_date--*/
                  v_business_date := v_length_check;
               /*-----business_date--*/
               END IF;

              /*
               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Business_Date is in invalid format.';
               END;
              */

            END IF;

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Business Date is NULL.';
            END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Business_Date Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
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
               IF LENGTH (v_length_check) > 2000
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Business time length is invalid.';
               ELSE
                  /*-----Business time--*/
                  v_business_time := v_length_check;
               /*-----Business time--*/
               END IF;

              /*
               BEGIN
                  v_datechk :=
                     TO_DATE (v_length_check, 'HH24MISS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Business time is in invalid format.';
               END;
              */
            END IF;

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Business time is NULL.';
            END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Business time Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;




         BEGIN
            v_error_flag := 11;
            
            dbms_output.put_line('after select 1 ' )  ;
             dbms_output.put_line(v_errmsg )  ;
            
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 10) + 1,
                               (INSTR (v_filebuffer, '|', 1, 11) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 10)
                            )
                    );
            dbms_output.put_line('after select 3 ' )  ;
            
            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 4000
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Transaction comments length is invalid.';
               ELSE
                  /*-----Tran comments--*/
                  v_tran_comments := v_length_check;
                 /*-----Tran comments--*/
               END IF;

            END IF;
            
            
            dbms_output.put_line('after select 2 ' )  ;


            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Transaction comment is NULL.';
            END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Tran comments Validation failed.';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_loop_reject_record;
         END IF;

         BEGIN
            INSERT INTO MIGR_CSR_CALLLOG_TEMP
                        (
                        mcc_pan_code,
                        mcc_start_time,
                        mcc_call_type,
                        mcc_comment,
                        mcc_status,
                        mcc_call_endtime,
                        mcc_tran_code,
                        mcc_rrn,
                        mcc_business_date,
                        mcc_business_time,
                        mcc_tran_comments,
                        mcc_hash_pan,
                        MCC_MIGR_SEQNO,
                        MCC_ERRMSG,
                        MCC_RECORD_NUMB,
                        MCC_FILE_NAME
                        )
                 VALUES (
                        v_pan_code,
                        v_call_starttime,
                        v_call_type,
                        v_comment,
                        v_status,
                        v_call_endtime,
                        v_tran_code,
                        v_rrn,
                        v_business_date,
                        v_business_time,
                        v_tran_comments,
                        gethash(v_pan_code),
                        prm_seqno,
                        v_errmsg,
                        v_record_numb,
                        prm_file_name
                        );
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Duplicate Call ID While Loading Files';
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
                  || 'Error while inserting into calllog data segment '
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


            SP_MIGR_LOG_EXCP_CALLOGDATA  (prm_file_name,
                                          v_record_numb,
                                          v_pan_code,
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

            SP_MIGR_LOG_EXCP_CALLOGDATA (prm_file_name,
                                          v_record_numb,
                                          v_pan_code,
                                          'E',
                                          v_errmsg,
                                          v_sqlerr       --Added On 24.06.2013
                                         );
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_key = 'CALL_DATA' AND mct_inst_code = 1;
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
       WHERE mct_ctrl_key = 'CALL_DATA' AND mct_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error while updating control number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn to create successful log for files
   BEGIN
      sp_migr_file_detl ('CALL_DATA_MIGR',
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
      sp_migr_file_detl ('CALL_DATA_MIGR',
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