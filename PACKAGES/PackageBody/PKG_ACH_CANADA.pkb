create or replace PACKAGE BODY                      vmscms.pkg_ach_canada
IS
   /**********************************************************************************************
      * Created By       : Spankaj
      * Created Date     : 05-Nov-2014
      * Purpose          : Canadian ACH processing
      * Created For      : MVHOST-984
      * Reviewer         :
      * Build Number     :

      * Created By       : Spankaj
      * Created Date     : 19-May-2015
      * Purpose          : Canadian ACH processing
      * Created For      : MVCAN-677
      * Reviewer         : Saravanan kumar
      * Build Number     : VMSGPRHOST_3.0.3

      * Modified By       : Saravanakumar
      * Modified Date     : 23-Sep-2015
      * Purpose          : Debit transaction logged as credit transction
      * Reviewer         : Spankaj
      * Build Number     : VMS_RSJ004

      * Modified By      : Spankaj
      * Modified Date    : 09-Sep-2016
      * Purpose          : FSS-4570
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_4.9

       * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1

   *************************************************************************************************/
   PROCEDURE sp_achcanda_data_load (
      prm_directory        IN       VARCHAR2,
      prm_dest_directory   IN       VARCHAR2,
      prm_rej_directory    IN       VARCHAR2,
      prm_autoschedule     IN       VARCHAR2,
      prm_files            OUT      c_ach_type,
      prm_errmsg           OUT      VARCHAR2
   )
   AS
      v_errmsg                VARCHAR2 (3000);
      v_file_errmsg           VARCHAR2 (3000);
      v_file_path             VARCHAR2 (150);
      v_file_handle           UTL_FILE.file_type;
      v_filebuffer            VARCHAR2 (32767);
      v_dup_check             NUMBER;
      v_succ_row              NUMBER (10);
      v_tabvar                c_ach_type;
      v_file_present          NUMBER;
      v_total_damt            NUMBER (20, 2);
      v_total_camt            NUMBER (20, 2);
      exp_reject_row          EXCEPTION;
      exp_reject_file         EXCEPTION;
      exp_reject_invalidrow   EXCEPTION;
      v_rec_type              VARCHAR2 (2);
      v_seg_data              VARCHAR2 (4000);
      v_rec_data              VARCHAR2 (100);
      v_indx                  NUMBER             := 0;
      v_crcheck               NUMBER             := 0;
      v_drcheck               NUMBER             := 0;
   BEGIN
      prm_errmsg := 'OK';
      prm_files := c_ach_type ();

      BEGIN
         SELECT TRIM (directory_path)
           INTO v_file_path
           FROM all_directories
          WHERE directory_name = UPPER (prm_directory);

         IF v_file_path IS NULL THEN
            prm_errmsg := 'Oracle directory Not Found-';
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error while getting the Oracle directory path-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         BEGIN
            sp_get_file_list (v_file_path);
            commit;
         EXCEPTION
            WHEN OTHERS THEN
               prm_errmsg :='Error while getting file lists-'|| SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         IF prm_autoschedule = 'A' THEN
            BEGIN
               SELECT COUNT (*)
                 INTO v_file_present
                 FROM cms_achfile_dtls
                WHERE cad_upd_stat = 'N';

               IF v_file_present = 0 THEN
                  prm_errmsg :='Files not available in the shared location for processing..!';
                  sp_send_mail (NULL, prm_errmsg);
                  RETURN;
               END IF;
            EXCEPTION
               WHEN OTHERS THEN
                  prm_errmsg :='Error while getting ACH file count-'|| SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         END IF;

         FOR x IN (SELECT ROWID rd, cad_batch_no, cad_file_name
                     FROM cms_achfile_dtls
                    WHERE cad_upd_stat = 'N')
         LOOP
            BEGIN
               v_file_errmsg := 'OK';
               v_drcheck := 0;
               v_crcheck := 0;
               v_total_camt := 0;
               v_total_damt := 0;
               v_succ_row := 0;

               IF SUBSTR (x.cad_file_name,1,4) <>'CPA-' THEN
                  v_file_errmsg :='Invalid file(name mismatch) for Canada ACH processing';
                  RAISE exp_reject_file;
               END IF;

               BEGIN
                  SELECT COUNT (1)
                    INTO v_dup_check
                    FROM cms_achfile_dtls
                   WHERE cad_upd_stat IN ('R', 'Y')
                     AND cad_file_name = x.cad_file_name;

                  IF v_dup_check > 0 THEN
                     v_file_errmsg := 'File already processed.';
                     RAISE exp_reject_file;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_file THEN
                     RAISE exp_reject_file;
                  WHEN OTHERS THEN
                     v_file_errmsg :='Error while dup file check-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_file;
               END;

               IF UTL_FILE.is_open (v_file_handle) THEN
                 UTL_FILE.fclose (v_file_handle);
               END IF;

               BEGIN
                  v_file_handle :=UTL_FILE.fopen(prm_directory,x.cad_file_name,'R',32767);
               EXCEPTION
                  WHEN OTHERS THEN
                     v_file_errmsg :='Error occured during opening file -'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_file;
               END;

               LOOP
                  BEGIN
                     UTL_FILE.get_line (v_file_handle, v_filebuffer);
                     v_rec_type := UPPER(SUBSTR (v_filebuffer, 1, 1));
                     EXIT WHEN v_rec_type = 'Z';

                     v_seg_data := SUBSTR (v_filebuffer, 25);
                      IF v_rec_type IN ('C','D') THEN
                       FOR i IN 1 .. CEIL ((LENGTH (v_seg_data)-1) / 240)
                       LOOP
                          IF i=7 THEN
                            EXIT;
                          END IF;

                         IF length(v_seg_data)<240 then
                             v_seg_data:=substr(v_seg_data,1,length(v_seg_data)-1);
                         END IF;

                        IF TRIM(substr(v_seg_data,1,240)) IS NOT NULL AND v_rec_type ='C' THEN
                             v_crcheck := v_crcheck + 1;
                        ELSIF TRIM(substr(v_seg_data,1,240)) IS NOT NULL AND v_rec_type ='D' THEN
                             v_drcheck :=v_drcheck + 1;
                        END IF;
                         v_seg_data:=substr(v_seg_data,241);
                       END LOOP;
                      END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        v_file_errmsg := 'Invalid file ';
                        RAISE exp_reject_file;
                  END;
               END LOOP;

               IF v_drcheck <> to_number(TRIM (SUBSTR (v_filebuffer, 39, 8))) OR  v_crcheck <> to_number(TRIM (SUBSTR (v_filebuffer, 61, 8)))
               THEN
                  v_file_errmsg :='Record count in file and in footer not matched';

                  IF UTL_FILE.is_open (v_file_handle) THEN
                     UTL_FILE.fclose (v_file_handle);
                  END IF;

                  RAISE exp_reject_file;
               END IF;

               IF UTL_FILE.is_open (v_file_handle) THEN
                  UTL_FILE.fclose (v_file_handle);
               END IF;

               v_total_damt :=TO_NUMBER (TRIM (SUBSTR (v_filebuffer, 25, 14)))/ 100;
               v_total_camt :=TO_NUMBER (TRIM (SUBSTR (v_filebuffer, 47, 14)))/ 100;

               BEGIN
                  v_file_handle :=UTL_FILE.fopen (prm_directory,x.cad_file_name,'R',32767);
               EXCEPTION
                  WHEN OTHERS THEN
                     v_file_errmsg :='Error occured during file open_1-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_file;
               END;

               UTL_FILE.get_line (v_file_handle, v_filebuffer);
               IF UPPER (SUBSTR (v_filebuffer, 1, 1)) <> 'A' THEN
                  v_file_errmsg := 'Invalid file header';
                  RAISE exp_reject_file;
               END IF;

               LOOP

                 BEGIN
                  UTL_FILE.get_line (v_file_handle, v_filebuffer);
                  v_rec_type := UPPER (SUBSTR (v_filebuffer, 1, 1));
                  EXIT WHEN v_rec_type = 'Z';

                  v_rec_data := SUBSTR (v_filebuffer, 1, 24);
                  v_seg_data := SUBSTR (v_filebuffer, 25);

                  FOR i IN 1 .. CEIL ((LENGTH (v_seg_data)-1) / 240)
                  LOOP
                    v_errmsg := 'OK';
                     BEGIN
                        IF i = 1 THEN
                           /*IF v_rec_type ='D' THEN
                              v_errmsg := 'Debit transaction not allowed';
                              RAISE exp_reject_invalidrow;
                           ELSIF v_rec_type ='C' THEN*/
                           IF v_rec_type IN ('C','D') THEN
                              IF LENGTH (v_filebuffer) > 1465 THEN
                                 v_errmsg := 'Invalid deposite data';
                                 RAISE exp_reject_invalidrow;
                              END IF;
                           ELSE
                              v_errmsg := 'Invalid deposite data';
                              RAISE exp_reject_invalidrow;
                           END IF;
                        END IF;

                       IF trim(substr(v_seg_data,1,240)) IS NOT NULL THEN

                         IF length(substr(v_seg_data,1,240)) <240 THEN
                              v_errmsg := 'Invalid Segment data';
                              RAISE exp_reject_row;
                         END IF;

                        BEGIN
                           v_tabvar := c_ach_type ();
                           sp_tokenise_ach (v_rec_data||v_seg_data, v_tabvar, v_errmsg);

                           IF v_errmsg <> 'OK' THEN
                              v_errmsg :='Error while tokenise data is-' || v_errmsg;
                              RAISE exp_reject_row;
                           END IF;
                        EXCEPTION
                           WHEN exp_reject_row THEN
                              RAISE;
                           WHEN OTHERS THEN
                              v_errmsg :='Error while tokenise data-' || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_row;
                        END;

                        BEGIN
                           INSERT INTO cms_achcanda_temp
                                       (cat_batch_no, cat_file_name,
                                        cat_rec_no, cat_seg_no,
                                        cat_ach_rec, cat_ach_data,
                                        cat_txn_type
                                       )
                                VALUES (x.cad_batch_no, x.cad_file_name,
                                        SUBSTR (v_filebuffer, 2, 9), i,
                                        v_seg_data, v_tabvar,
                                        v_rec_type
                                       );

                           v_succ_row := v_succ_row + 1;
                        EXCEPTION
                           WHEN OTHERS THEN
                              v_errmsg :='Error while inserting into temp table is-'|| SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_row;
                        END;
                       END IF;
                        v_seg_data := SUBSTR (v_seg_data, 241);
                     EXCEPTION
                        WHEN exp_reject_invalidrow THEN

                           INSERT INTO cms_achfile_upd_errlog
                                       (cau_batch_no, cau_file_name,
                                        cau_rec_no,
                                        cau_process_msg, cau_process_date
                                       )
                                VALUES (x.cad_batch_no, x.cad_file_name,
                                        SUBSTR (v_filebuffer, 2, 9),
                                        v_errmsg, SYSDATE
                                       );
                            EXIT;
                        WHEN exp_reject_row THEN

                           INSERT INTO cms_achfile_upd_errlog
                                       (cau_batch_no, cau_file_name,
                                        cau_rec_no, cau_seg_no,
                                        cau_process_msg, cau_process_date
                                       )
                                VALUES (x.cad_batch_no, x.cad_file_name,
                                        SUBSTR (v_filebuffer, 2, 9), i,
                                        v_errmsg, SYSDATE
                                       );
                        WHEN OTHERS THEN
                           v_errmsg :='Error while extracting data is-'|| SUBSTR (SQLERRM, 1, 200);

                           INSERT INTO cms_achfile_upd_errlog
                                       (cau_batch_no, cau_file_name,
                                        cau_rec_no, cau_seg_no,
                                        cau_process_msg, cau_process_date
                                       )
                                VALUES (x.cad_batch_no, x.cad_file_name,
                                        SUBSTR (v_filebuffer, 2, 9), i,
                                        v_errmsg, SYSDATE
                                       );
                     END;
                  END LOOP;
                 EXCEPTION
                  WHEN OTHERS THEN
                   v_errmsg :='Error while reading data is-'|| SUBSTR (SQLERRM, 1, 200);
                   INSERT INTO cms_achfile_upd_errlog
                                       (cau_batch_no, cau_file_name,
                                        cau_rec_no, cau_seg_no,
                                        cau_process_msg, cau_process_date
                                       )
                                VALUES (x.cad_batch_no, x.cad_file_name,
                                        SUBSTR (v_filebuffer, 2, 9), NULL,
                                        v_errmsg, SYSDATE
                                       );
                 END;
               END LOOP;

               UTL_FILE.fclose (v_file_handle);
               UTL_FILE.frename (prm_directory,
                                 x.cad_file_name,
                                 prm_dest_directory,
                                 x.cad_file_name,
                                 TRUE
                                );

               BEGIN
                  UPDATE cms_achfile_dtls
                     SET cad_upd_stat = 'Y',
                         cad_tot_rows = v_crcheck + v_drcheck,
                         cad_succ_rows = v_succ_row,
                         cad_err_rows = (v_crcheck + v_drcheck)-v_succ_row,
                         cad_tot_amt = v_total_damt + v_total_camt,
                         cat_schedr_flag = prm_autoschedule,
                         cad_process_msg = v_file_errmsg,
                         cad_process_date = SYSDATE
                   WHERE ROWID = x.rd;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_file_errmsg :='Error while updating File process dtls-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_file;
               END;

               sp_send_mail (x.cad_file_name, v_file_errmsg);

               IF v_file_errmsg <> 'OK' THEN
                  UPDATE cms_achfile_dtls
                     SET cad_process_msg = v_file_errmsg
                   WHERE ROWID = x.rd;
               END IF;

               prm_files.EXTEND;
               v_indx := v_indx + 1;
               prm_files (v_indx) := x.cad_file_name;
            EXCEPTION
               WHEN exp_reject_file THEN

                  UTL_FILE.frename (prm_directory,
                                    x.cad_file_name,
                                    prm_rej_directory,
                                    x.cad_file_name,
                                    TRUE
                                   );

                  sp_send_mail (x.cad_file_name, v_file_errmsg);

                  UPDATE cms_achfile_dtls
                     SET cad_upd_stat = 'R',
                         cad_process_msg = v_file_errmsg,
                         cad_process_date = SYSDATE
                   WHERE ROWID = x.rd;
               WHEN OTHERS THEN
                  v_file_errmsg :='Error while file extraction-'|| SUBSTR (SQLERRM, 1, 200);

                  UTL_FILE.frename (prm_directory,
                                    x.cad_file_name,
                                    prm_rej_directory,
                                    x.cad_file_name,
                                    TRUE
                                   );

                  sp_send_mail (x.cad_file_name, v_file_errmsg);

                  UPDATE cms_achfile_dtls
                     SET cad_upd_stat = 'R',
                         cad_process_msg = v_file_errmsg,
                         cad_process_date = SYSDATE
                   WHERE ROWID = x.rd;
            END;

            COMMIT;
         END LOOP;
      END;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         v_file_errmsg :='Main Exception While Data Loading-' || SUBSTR (SQLERRM, 1, 100);

         sp_send_mail (NULL, v_file_errmsg);

         UPDATE cms_achfile_dtls
          SET cad_upd_stat='R',
          cad_process_msg=v_file_errmsg
         WHERE cad_upd_stat = 'N';

         prm_errmsg:=v_file_errmsg;
         RETURN;
   END;

   PROCEDURE sp_achcanda_process (
      prm_instcode         IN       NUMBER,
      prm_autoschedule     IN       VARCHAR2,
      prm_directory        IN       VARCHAR2,
      prm_dest_directory   IN       VARCHAR2,
      prm_rep_directory    IN       VARCHAR2,
      prm_rej_directory    IN       VARCHAR2,
      prm_errmsg           OUT      VARCHAR2
   )
   AS
      v_proxy_no        cms_appl_pan.cap_proxy_number%TYPE;
      v_tracenumber     transactionlog.tracenumber%TYPE;
      v_trandate        DATE;
      v_amount          NUMBER (20, 2);
      v_source_sname    cms_transaction_log_dtl.ctd_source_name%TYPE;
      v_source_fname    cms_transaction_log_dtl.ctd_source_name%TYPE;
      v_resp_code       transactionlog.response_code%TYPE;
      v_cust_name       cms_achfile_txn_errlog.cat_cust_name%TYPE; --Added for FSS-4570
      v_dup_recno       NUMBER;
      v_files           c_ach_type;
      v_errmsg          VARCHAR2 (3000)                               := 'OK';
      v_proc_stat       VARCHAR2 (2);
      v_duprec_check    NUMBER                                         := 0;
      excp_rep          EXCEPTION;
      excp_record_err   EXCEPTION;

      CURSOR c1 (p_filename VARCHAR2)
      IS
         SELECT ROWID rd, cat_batch_no, cat_file_name filename, cat_rec_no, cat_ach_data achdata,
                cat_seg_no, cat_txn_type
           FROM cms_achcanda_temp
          WHERE cat_file_name = p_filename AND cat_proc_stat = 'P'
          order by cat_ins_date;
   BEGIN
      prm_errmsg := 'OK';
      v_files := c_ach_type ();

      BEGIN
         sp_achcanda_data_load (prm_directory,
                                prm_dest_directory,
                                prm_rej_directory,
                                prm_autoschedule,
                                v_files,
                                v_errmsg
                               );
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg :='Error while calling file extraction process-'|| SUBSTR (SQLERRM, 1, 100);
      END;

      IF v_errmsg = 'OK' THEN
         FOR x IN 1 .. v_files.COUNT
         LOOP
            FOR i IN c1 (v_files (x))
            LOOP
               v_errmsg := 'OK';
               v_resp_code := '00';
               v_proc_stat := 'S';

               BEGIN

                  BEGIN
                     v_amount := TO_NUMBER (i.achdata (5)) / 100;
                  EXCEPTION
                     WHEN OTHERS THEN
                        v_errmsg := 'Invalid amount';
                        v_amount := 0;
                        v_resp_code := '21';
                        RAISE excp_record_err;
                  END;

                  v_trandate :=TO_DATE ('01-Jan-20' || SUBSTR (i.achdata (6), 2, 2), 'DD-MON-YYYY') + (SUBSTR (i.achdata (6), 4) - 1);
                  v_proxy_no := i.achdata (8);
                  v_tracenumber := i.achdata (9);
                  v_source_sname := i.achdata (10);
                  v_source_fname := i.achdata (12);
                  v_cust_name := i.achdata (11); --Added for FSS-4570

                  IF v_trandate < SYSDATE - 100 THEN
                     v_errmsg :='Txn date exceed 100 days from file creation date.';
                     v_resp_code := '21';
                     RAISE excp_record_err;
                  END IF;

                 IF i.cat_seg_no=1 THEN
                  BEGIN
                     SELECT COUNT (1)
                       INTO v_duprec_check
                       FROM cms_achcanda_temp
                      WHERE cat_batch_no = i.cat_batch_no
                        AND cat_file_name = i.filename
                        AND cat_rec_no = i.cat_rec_no
                        AND cat_proc_stat IN ('S', 'R');

                     IF v_duprec_check > 0 THEN
                        v_dup_recno := i.cat_rec_no;
                     END IF;
                  EXCEPTION
                     WHEN excp_record_err THEN
                        RAISE;
                     WHEN OTHERS THEN
                        v_errmsg :='Error while Duplicate logical record no check-'|| SUBSTR (SQLERRM, 1, 200);
                        v_resp_code := '21';
                        RAISE excp_record_err;
                  END;
                 END IF;

                  IF i.cat_rec_no = v_dup_recno THEN
                     v_errmsg := 'Duplicate logical record no';
                     v_resp_code := '21';
                     RAISE excp_record_err;
                  END IF;

                  sp_achcanda_txn_process (prm_instcode,
                                           v_proxy_no,
                                           v_tracenumber,
                                           TO_CHAR (v_trandate, 'YYYYMMDD'),
                                           TO_CHAR (SYSDATE, 'HH24MISS'),
                                           i.cat_txn_type,
                                           v_amount,
                                           i.filename,
                                           'Y',
                                           v_source_sname,
                                           v_source_fname,
                                           v_cust_name,  --Added for FSS-4570
                                           v_resp_code,
                                           v_errmsg
                                          );

                  IF v_errmsg <> 'OK' THEN
                     RAISE excp_record_err;
                  END IF;
               EXCEPTION
                  WHEN excp_record_err THEN
                     v_proc_stat := 'R';

                     INSERT INTO cms_achfile_txn_errlog
                                 (cat_batch_no, cat_file_name, cat_rec_no,
                                  cat_proxy_no, cat_cust_name, cat_txn_type,
                                  cat_txn_amt, cat_source_sname, cat_seg_no,
                                  cat_source_fname, cat_process_date,
                                  cat_err_code, cat_err_desc,cat_trace_no
                                 )
                          VALUES (i.cat_batch_no, i.filename, i.cat_rec_no,
                                  v_proxy_no, v_cust_name,--i.achdata (11), --Modified for FSS-4570
                                  i.cat_txn_type,--'CR',
                                  v_amount, v_source_sname, i.cat_seg_no,
                                  v_source_fname, SYSDATE,
                                  v_resp_code, v_errmsg,v_tracenumber
                                 );
                  WHEN OTHERS THEN
                     v_proc_stat := 'R';
                     v_errmsg :='Error while txn processing-'|| SUBSTR (SQLERRM, 1, 100);

                     INSERT INTO cms_achfile_txn_errlog
                                 (cat_batch_no, cat_file_name, cat_rec_no,
                                  cat_proxy_no, cat_cust_name, cat_txn_type,
                                  cat_txn_amt, cat_source_sname, cat_seg_no,
                                  cat_source_fname, cat_process_date,
                                  cat_err_code, cat_err_desc,cat_trace_no
                                 )
                          VALUES (i.cat_batch_no, i.filename, i.cat_rec_no,
                                  v_proxy_no, v_cust_name,--i.achdata (11), --Modified for FSS-4570
                                  i.cat_txn_type, --'CR',
                                  v_amount, v_source_sname, i.cat_seg_no,
                                  v_source_fname, SYSDATE,
                                  v_resp_code, v_errmsg,v_tracenumber
                                 );
               END;

               UPDATE cms_achcanda_temp
                  SET cat_proc_stat = v_proc_stat,
                      cat_process_date = SYSDATE
                WHERE cat_file_name = v_files (x) AND ROWID = i.rd;

               COMMIT;
            END LOOP;

            BEGIN
               sp_batch_load_rep (v_files (x), prm_rep_directory, v_errmsg);

               IF v_errmsg <> 'OK' THEN
                  v_errmsg := 'Error from batch load rep-' || v_errmsg;
                  RAISE excp_rep;
               END IF;

               sp_batch_excp_rep (v_files (x), prm_rep_directory, v_errmsg);

               IF v_errmsg <> 'OK' THEN
                  v_errmsg := 'Error from batch summ rep-' || v_errmsg;
                  RAISE excp_rep;
               END IF;
            EXCEPTION
               WHEN excp_rep THEN
                  UPDATE cms_achfile_dtls
                     SET cad_rep_stat = v_errmsg
                   WHERE cad_file_name = v_files (x);
               WHEN OTHERS THEN
                  v_errmsg :='Error while rep gen-' || SUBSTR (SQLERRM, 1, 100);

                  UPDATE cms_achfile_dtls
                     SET cad_rep_stat = v_errmsg
                   WHERE cad_file_name = v_files (x);
            END;

            COMMIT;
         END LOOP;
      ELSE
         prm_errmsg := 'Error from file extraction-' || v_errmsg;
      END IF;

      INSERT INTO cms_cpaschedul_dtl
           VALUES (SYSDATE, prm_errmsg);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'Main Exception-' || SUBSTR (SQLERRM, 1, 100);
   END;

   PROCEDURE sp_achcanda_txn_process (
      p_instcode       IN       NUMBER,
      p_proxy_no       IN       VARCHAR2,
      p_tracenumber    IN       VARCHAR2,
      p_trandate       IN       VARCHAR2,
      p_trantime       IN       VARCHAR2,
      p_txntype         IN       VARCHAR2,
      p_amount         IN       NUMBER,
      p_achfilename    IN       VARCHAR2,
      p_processtype    IN       VARCHAR2,
      p_source_sname   IN       VARCHAR2,
      p_source_fname   IN       VARCHAR2,
      p_cust_name      IN       VARCHAR2, --Added for FSS-4570
      p_resp_code      OUT      VARCHAR2,
      p_errmsg         OUT      VARCHAR2
   )
   AS
      v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
      v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
      v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
      v_card_type              cms_appl_pan.cap_card_type%TYPE;
      v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
      v_errmsg                 VARCHAR2 (300);
      v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
      v_respcode               VARCHAR2 (5);
      v_capture_date           DATE;
      v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
      v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
      v_auth_id                transactionlog.auth_id%TYPE;
      v_traceno_count          NUMBER;
      v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      v_tran_date              DATE;
      v_topupremrk             VARCHAR2 (100);
      v_acct_balance           NUMBER;
      v_ledger_balance         NUMBER;
      v_tran_amt               NUMBER;
      v_card_curr              VARCHAR2 (5);
      v_date                   DATE;
      v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
      v_file_count             NUMBER;
      v_start_acct_balance     VARCHAR2 (15);
      v_start_ledger_balance   VARCHAR2 (15);
      v_cust_card_no           VARCHAR2 (19);
      v_dr_cr_flag             VARCHAR2 (2);
      v_output_type            VARCHAR2 (2);
      v_tran_type              VARCHAR2 (2);
      v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
      v_ach_exp_flag           transactionlog.ach_exception_queue_flag%TYPE;
      v_comb_hash              pkg_limits_check.type_hash;
      v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
      v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
      v_blcklist_cnt           NUMBER;
      v_queue_flag             VARCHAR2 (1);
      v_acct_type              cms_acct_mast.cam_type_code%TYPE;
      v_rrn                    transactionlog.rrn%TYPE;
      v_del_channel            cms_transaction_mast.ctm_delivery_channel%TYPE
                                                                      := '15';
      v_txn_code               cms_transaction_mast.ctm_tran_code%TYPE ;
      v_txn_mode               transactionlog.txn_mode%TYPE            := '0';
      v_msg                    transactionlog.msgtype%TYPE          := '0200';
      v_rvsl_code              transactionlog.reversal_code%TYPE      := '00';
      exp_main_reject_record   EXCEPTION;
      exp_auth_reject_record   EXCEPTION;
      v_gpr_check_flag         cms_product_param.cpp_gprflag_achtxn%TYPE;
      v_gpr_cnt                NUMBER;
      --Sn Added for FSS-4570 changes
      v_custlastname           cms_cust_mast.ccm_last_name%TYPE;
      v_custfirstname          cms_cust_mast.ccm_first_name%TYPE;
      v_cust_name              VARCHAR2(40);
      v_cust_init              VARCHAR2(40);
      v_cust_code              cms_appl_pan.cap_cust_code%TYPE;
      v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;
      --En Added for FSS-4570 changes
   BEGIN
      --p_errmsg := 'OK';
      v_errmsg := 'OK';
      v_topupremrk := 'ACH Credit Transaction';
      v_tran_amt := p_amount;

      --Sn Generate RRN
      BEGIN
         SELECT    TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                || LPAD (seq_canadaach_rrn.NEXTVAL, 3, 0)
           INTO v_rrn
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg :='Error while generating RRN- ' || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      --En Generate RRN

      --Sn Generate AuthId
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg :='Error while generating authid-' || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      --En Generate AuthId

      --Added for log the correct flag by Saravanakumar on 23-Sep-2015
      IF p_txntype = 'C' THEN
        v_txn_code:='1';
      ELSIF p_txntype = 'D' THEN
        v_txn_code:='2';
      END IF;

      --Sn Get txn details
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = v_txn_code
            AND ctm_delivery_channel = v_del_channel
            AND ctm_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            v_respcode := '12';
            v_errmsg :='txn not defined for txn code-'|| v_txn_code || ' DELIVERY channel-'|| v_del_channel;
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting transaction details-'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_main_reject_record;
      END;
      --En Get txn details

      --Sn Get PAN details
      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_card_stat,
                cap_prod_catg, cap_mbr_numb, cap_prod_code, cap_card_type,
                cap_acct_no, cap_prfl_code, cap_cust_code
           INTO v_hash_pan, v_encr_pan, v_cap_card_stat,
                v_cap_prod_catg, v_mbrnumb, v_prod_code, v_card_type,
                v_acct_number, v_prfl_code, v_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_instcode
            AND cap_proxy_number = p_proxy_no       --AND cap_card_stat = '1';
            AND cap_card_stat NOT IN ('0', '9');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            --v_respcode := '16';
            --v_errmsg := 'Invalid proxy number';
            --RAISE exp_main_reject_record;
            BEGIN
               SELECT cap_pan_code, cap_pan_code_encr, cap_card_stat,
                      cap_prod_catg, cap_mbr_numb, cap_prod_code,
                      cap_card_type, cap_acct_no, cap_prfl_code, cap_cust_code
                 INTO v_hash_pan, v_encr_pan, v_cap_card_stat,
                      v_cap_prod_catg, v_mbrnumb, v_prod_code,
                      v_card_type, v_acct_number, v_prfl_code, v_cust_code
                 FROM (SELECT   cap_pan_code, cap_pan_code_encr,
                                cap_card_stat, cap_prod_catg, cap_mbr_numb,
                                cap_prod_code, cap_card_type, cap_acct_no,
                                cap_prfl_code, cap_cust_code
                           FROM cms_appl_pan
                          WHERE cap_inst_code = p_instcode
                            AND cap_proxy_number = p_proxy_no
                            AND cap_card_stat = '0'
                       ORDER BY cap_ins_date DESC)
                WHERE ROWNUM = 1;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  BEGIN
                     SELECT cap_pan_code, cap_pan_code_encr, cap_card_stat,
                            cap_prod_catg, cap_mbr_numb, cap_prod_code,
                            cap_card_type, cap_acct_no, cap_prfl_code, cap_cust_code
                       INTO v_hash_pan, v_encr_pan, v_cap_card_stat,
                            v_cap_prod_catg, v_mbrnumb, v_prod_code,
                            v_card_type, v_acct_number, v_prfl_code, v_cust_code
                       FROM (SELECT   cap_pan_code, cap_pan_code_encr,
                                      cap_card_stat, cap_prod_catg,
                                      cap_mbr_numb, cap_prod_code,
                                      cap_card_type, cap_acct_no,
                                      cap_prfl_code, cap_cust_code
                                 FROM cms_appl_pan
                                WHERE cap_inst_code = p_instcode
                                  AND cap_proxy_number = p_proxy_no
                                  AND cap_card_stat = '9'
                             ORDER BY cap_ins_date DESC)
                      WHERE ROWNUM = 1;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        v_respcode := '16';
                        v_errmsg := 'Invalid proxy number';
                        RAISE exp_main_reject_record;
                     WHEN OTHERS THEN
                        v_respcode := '21';
                        v_errmsg :='Error while selecting closecard dtls-'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
               WHEN OTHERS THEN
                  v_respcode := '21';
                  v_errmsg :='Error while selecting inactive card dtls-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting card dtls-' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Get PAN details

      v_cust_card_no := fn_dmaps_main (v_encr_pan);

      --Sn Duplicate check using the trace number of the transaction
      /*BEGIN
         SELECT COUNT (1)
           INTO v_traceno_count
           FROM transactionlog
          WHERE tracenumber = p_tracenumber
            AND txn_code = v_txn_code
            AND business_date = p_trandate;

         IF v_traceno_count > 0 THEN
            v_respcode := '22';
            v_errmsg := 'Duplicate tracenumber ' || 'on ' || p_trandate;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while tracenumber validation-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;*/
      --En Duplicate check using the trace number of the transaction

      --Sn Card currency validation
      BEGIN
--         SELECT TRIM (cbp_param_value)
--           INTO v_card_curr
--           FROM cms_bin_param, cms_prod_mast
--          WHERE cbp_param_name = 'Currency'
--            AND cbp_profile_code = cpm_profile_code
--            AND cpm_prod_code = v_prod_code
--            AND cpm_inst_code = p_instcode;
            vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_instcode,v_card_curr,v_errmsg);
      if v_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;

         IF v_card_curr <> '124' THEN
            v_respcode := '22';
            v_errmsg := 'Not a valid canada ACH';
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            RAISE;
         WHEN NO_DATA_FOUND THEN
            v_errmsg :='card currency is not defined for product-' || v_prod_code;
            v_respcode := '21';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            v_errmsg :='Error while selecting card currecy-'|| SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      --En Card currency validation

      IF p_txntype='D' THEN
        v_errmsg :='Debit transaction not allowed';
         v_respcode := '14';
        RAISE exp_main_reject_record;
      END IF;

      --Sn Black list sourecs validation
      BEGIN
         SELECT COUNT (1)
           INTO v_blcklist_cnt
           FROM cms_blacklist_sources
          WHERE cbs_inst_code = p_instcode
            AND (   UPPER (cbs_source_name) = UPPER (TRIM (p_source_sname))
                 OR UPPER (cbs_source_name) = UPPER (TRIM (p_source_fname))
                )
            AND cbs_prod_code = v_prod_code;

         IF (v_blcklist_cnt > 0) THEN
            v_respcode := '73';
            v_errmsg := 'Blacklisted Source';
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting blacklist sources-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Black list sourecs validation

      --Sn Added for FSS-4570 changes
    BEGIN
        SELECT cpc_encrypt_enable
          INTO v_encrypt_enable
          FROM cms_prod_cattype
         WHERE cpc_inst_code=p_instcode
         and cpc_prod_code=v_prod_code
         and cpc_card_type=v_card_type;
     EXCEPTION
        WHEN OTHERS THEN
           v_respcode := '21';
           v_errmsg :='Error while selecting from prod cattype' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;
     BEGIN
        SELECT decode(v_encrypt_enable,'Y',TRIM (UPPER (fn_dmaps_main(ccm_last_name))),TRIM (UPPER (ccm_last_name))),
        decode(v_encrypt_enable,'Y',trim(upper(fn_dmaps_main(ccm_first_name))),TRIM (UPPER (ccm_first_name)))
          INTO v_custlastname, v_custfirstname
          FROM cms_cust_mast
         WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;
     EXCEPTION
        WHEN OTHERS THEN
           v_respcode := '21';
           v_errmsg :='Error while selecting customer dtls-' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;


    SELECT TRIM (REGEXP_REPLACE (UPPER (p_cust_name), '( ){2,}', ' '))
      INTO v_cust_name
      FROM DUAL;

    SELECT TRIM (SUBSTR (v_cust_name,
                         INSTR (v_cust_name, ' ', 1, 1) + 1,
                         INSTR (v_cust_name, ' ', 1, 2)
                         - INSTR (v_cust_name, ' ', 1, 1) - 1))
      INTO v_cust_init
      FROM DUAL;

      IF (v_cust_name IS NULL) THEN
        v_respcode  := '74';
        v_errmsg    := 'Name is not matched ';
        RAISE exp_main_reject_record;
      ELSIF ( (v_cust_name <> v_custlastname || ' ' || v_custfirstname ) AND (v_cust_name <> v_custfirstname || ' ' || v_custlastname )
      AND (v_cust_name <> v_custlastname || ',' || v_custfirstname )  AND (v_cust_name <> v_custfirstname || ',' || v_custlastname ) ) THEN
        IF ( INSTR (v_cust_name, (v_custlastname || ',' || v_custfirstname || ' ' ) ) <> 1 AND INSTR (v_cust_name, (v_custfirstname || ',' || v_custlastname || ' ' ) ) <> 1
        AND INSTR (v_cust_name, (v_custlastname || ' ' || v_custfirstname || ' ' ) ) <> 1 AND INSTR (v_cust_name, (v_custfirstname || ' ' || v_custlastname || ' ' ) ) <> 1 ) THEN
          IF ( INSTR (v_cust_name, ( v_custlastname || ' ' || v_cust_init || ' ' || v_custfirstname ) ) <> 1
          AND INSTR (v_cust_name, ( v_custfirstname || ' ' || v_cust_init || ' ' || v_custlastname ) ) <> 1 ) THEN
            IF ( INSTR (v_cust_name, (v_custlastname || ', ' || v_custfirstname ) )<> 1 AND INSTR (v_cust_name, (v_custfirstname || ', ' || v_custlastname ) ) <> 1
            AND INSTR (v_cust_name, (v_custlastname || ' ,' || v_custfirstname ) ) <> 1  AND INSTR (v_cust_name, (v_custfirstname || ' ,' || v_custlastname ) ) <> 1 ) THEN
              IF (LENGTH (v_cust_name) = 22) THEN
                IF ( INSTR (( v_custlastname || ',' || v_custfirstname || ' ' ), v_cust_name )<> 1 AND INSTR (( v_custfirstname || ',' || v_custlastname || ' ' ), v_cust_name ) <> 1
                AND INSTR (( v_custlastname || ' ' || v_custfirstname || ' ' ), v_cust_name ) <> 1 AND INSTR (( v_custfirstname || ' ' || v_custlastname || ' ' ), v_cust_name ) <> 1
                AND INSTR ( (v_custlastname || ', ' || v_custfirstname ),v_cust_name ) <> 1 AND INSTR ( (v_custfirstname || ', ' || v_custlastname ),v_cust_name ) <> 1
                AND INSTR ( (v_custlastname || ' ,' || v_custfirstname ),v_cust_name ) <> 1 AND INSTR ( (v_custfirstname || ' ,' || v_custlastname ),v_cust_name ) <> 1 ) THEN
                  v_respcode := '74';
                  v_errmsg := 'Name is not matched ';
                  RAISE exp_main_reject_record;
                END IF;
              ELSE
                v_respcode := '74';
                v_errmsg   := 'Name is not matched ';
                RAISE exp_main_reject_record;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
      --En Added for FSS-4570 changes

      --Sn GPRFLAG_ACHTXN Check
      BEGIN
         SELECT cpp_gprflag_achtxn
           INTO v_gpr_check_flag
           FROM cms_product_param
          WHERE cpp_inst_code = p_instcode AND cpp_prod_code = v_prod_code;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            v_respcode := '21';
            v_errmsg := 'Product Details not Found in product param table';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting GPRFLAG_ACHTXN-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF v_gpr_check_flag = 'Y' THEN
         BEGIN
            SELECT COUNT (1)
              INTO v_gpr_cnt
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode
               AND cap_acct_no = v_acct_number
               AND cap_startercard_flag = 'N';
         EXCEPTION
            WHEN OTHERS THEN
               v_respcode := '21';
               v_errmsg :='Error while selecting gpr_cnt '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         IF v_gpr_cnt = 0 THEN
            v_respcode := '39';
            v_errmsg := 'GPR card is not generated for this account';
            RAISE exp_main_reject_record;
         END IF;
      END IF;
      --En GPRFLAG_ACHTXN Check

      --Sn Get before txn balances
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
               INTO v_start_acct_balance, v_start_ledger_balance, v_acct_type
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode
         FOR UPDATE;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            v_respcode := '16';
            v_errmsg := 'Invalid Account';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            v_respcode := '12';
            v_errmsg :='Error while selecting acct details-'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_main_reject_record;
      END;
      --En Get before txn balances

      --Sn Txn Date Validation
      BEGIN
         v_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '45';
            v_errmsg :='Problem while converting transaction date-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      BEGIN
         v_tran_date :=TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8)|| ' '|| SUBSTR (TRIM (p_trantime), 1, 10),'yyyymmdd hh24:mi:ss');
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '32';
            v_errmsg :='Problem while converting transaction time-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Txn Date Validation

      --Sn Currency Convert
      BEGIN
         sp_convert_curr (p_instcode,
                          v_card_curr,
                          v_cust_card_no,
                          p_amount,
                          v_tran_date,
                          v_tran_amt,
                          v_card_curr,
                          v_errmsg,
                          v_prod_code,
                          v_card_type
                         );

         IF v_errmsg <> 'OK' THEN
            v_respcode := '21';
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '89';
            v_errmsg :='Error from currency conversion-' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Currency Convert

      --Sn Txn limits check
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
         BEGIN
            pkg_limits_check.sp_limits_check (v_hash_pan,
                                              NULL,
                                              NULL,
                                              NULL,
                                              v_txn_code,
                                              v_tran_type,
                                              NULL,
                                              NULL,
                                              p_instcode,
                                              NULL,
                                              v_prfl_code,
                                              v_tran_amt,
                                              v_del_channel,
                                              v_comb_hash,
                                              v_respcode,
                                              v_errmsg
                                             );

            IF v_errmsg <> 'OK' THEN
               IF v_respcode = '79' THEN
                  v_respcode := '20';
               ELSIF v_respcode = '80' THEN
                  v_respcode := '23';
               END IF;

               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_respcode := '21';
               v_errmsg :='Error from Limit Check Process-'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;
      --En Txn limits check

      --Sn Authorization
      IF v_cap_prod_catg = 'P' THEN
         BEGIN
            sp_authorize_txn_cms_auth_ach (p_instcode,
                                           v_msg,
                                           v_rrn,
                                           v_del_channel,
                                           NULL,
                                           v_txn_code,
                                           v_txn_mode,
                                           p_trandate,
                                           p_trantime,
                                           v_cust_card_no,
                                           NULL,
                                           p_amount,
                                           NULL,
                                           NULL,
                                           NULL,
                                           v_card_curr,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           v_mbrnumb,
                                           v_rvsl_code,
                                           v_tran_amt,
                                           p_achfilename,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           p_tracenumber,
                                           NULL,
                                           NULL,
                                           v_start_ledger_balance,
                                           v_start_acct_balance,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           v_cap_card_stat,
                                           p_processtype,
                                           v_auth_id,
                                           NULL,
                                           v_ach_exp_flag,
                                           v_respcode,
                                           v_respcode,
                                           v_errmsg,
                                           v_capture_date
                                          );

            IF v_respcode <> '00' AND v_errmsg <> 'OK' THEN
               RAISE exp_auth_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_auth_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_respcode := '21';
               v_errmsg :='Error from Card authorization-'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;
      --En Authorization

      --Sn create a record in pan spprt
      BEGIN
         SELECT csr_spprt_rsncode
           INTO v_resoncode
           FROM cms_spprt_reasons
          WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Reason code code for TOPUP not present in master';
            v_respcode := '21';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            v_errmsg :='Error while selecting TOPUP reason code from master-'|| SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      BEGIN
         INSERT INTO cms_pan_spprt
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                      cps_func_remark, cps_ins_user, cps_lupd_user,
                      cps_cmd_mode, cps_pan_code_encr
                     )
              VALUES (p_instcode, v_hash_pan, v_mbrnumb,
                      v_cap_prod_catg, 'TOP', v_resoncode,
                      v_topupremrk, 1, 1,
                      0, v_encr_pan
                     );
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg :='Error while inserting into spprt table-'|| SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      --En create a record in pan spprt

      --Sn Limit reset
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
         BEGIN
            pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                                v_hash_pan,
                                                v_tran_amt,
                                                v_comb_hash,
                                                v_respcode,
                                                v_errmsg
                                               );

            IF v_errmsg <> 'OK' THEN
               v_errmsg := 'From Procedure sp_limitcnt_reset' || p_errmsg;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_respcode := '21';
               v_errmsg :='Error from Limit Reset Count Process-'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;
      --En Limit reset

      --Sn Get response code
      BEGIN
         v_respcode := 1;
         p_errmsg := v_errmsg;

         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = v_del_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            p_errmsg :='Data not available in response master for ' || v_respcode;
            p_resp_code := 'R20';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            p_errmsg :='Problem while selecting data from response master-'|| v_respcode ||'-'|| SUBSTR (SQLERRM, 1, 300);
            p_resp_code := 'R20';
            RAISE exp_main_reject_record;
      END;
      --En Get response code
   EXCEPTION
      --<< MAIN EXCEPTION >>
      WHEN exp_auth_reject_record THEN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         BEGIN
            UPDATE cms_transaction_log_dtl
               SET ctd_source_name = p_source_sname
             WHERE ctd_rrn = v_rrn
               AND ctd_business_date = p_trandate
               AND ctd_business_time = p_trantime
               AND ctd_delivery_channel = v_del_channel
               AND ctd_txn_code = v_txn_code
               AND ctd_msg_type = v_msg
               AND ctd_inst_code = p_instcode
               AND ctd_customer_card_no = v_hash_pan;
         EXCEPTION
            WHEN OTHERS THEN
               v_errmsg :='Problem on updated cms_Transaction_log_dtl-'|| SUBSTR (SQLERRM, 1, 200);
         END;
      WHEN exp_main_reject_record THEN
         ROLLBACK;

         IF v_prod_code IS NULL THEN
            BEGIN
               SELECT cap_pan_code, cap_pan_code_encr, cap_card_stat,
                      cap_prod_code, cap_card_type, cap_acct_no
                 INTO v_hash_pan, v_encr_pan, v_cap_card_stat,
                      v_prod_code, v_card_type, v_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_instcode
                  AND cap_proxy_number = p_proxy_no
                  AND cap_card_stat = '1';
            EXCEPTION
               WHEN OTHERS THEN
                  NULL;
            END;
         END IF;

         IF v_dr_cr_flag IS NULL THEN
            BEGIN
               SELECT ctm_credit_debit_flag,
                      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                      ctm_tran_desc
                 INTO v_dr_cr_flag,
                      v_txn_type,
                      v_trans_desc
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = v_txn_code
                  AND ctm_delivery_channel = v_del_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS THEN
                  NULL;
            END;
         END IF;

         IF v_start_acct_balance IS NULL THEN
            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                 INTO v_acct_balance, v_ledger_balance, v_acct_type
                 FROM cms_acct_mast
                WHERE cam_acct_no = v_acct_number
                  AND cam_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS THEN
                  v_acct_balance := 0;
                  v_ledger_balance := 0;
            END;
         ELSE
            v_acct_balance := v_start_acct_balance;
            v_ledger_balance := v_start_ledger_balance;
         END IF;

         BEGIN
            p_errmsg := v_errmsg;

            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode
               AND cms_delivery_channel = v_del_channel
               AND cms_response_id = v_respcode;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               p_errmsg :='Response code not available in response master '|| v_respcode;
               p_resp_code := 'R20';
            WHEN OTHERS THEN
               p_errmsg :='Problem while selecting data from response master-'|| v_respcode|| '-'|| SUBSTR (SQLERRM, 1, 300);
               p_resp_code := 'R20';
         END;

         --Sn create a entry in txn log
         IF v_respcode NOT IN ('45', '32') THEN
            IF p_processtype <> 'N' THEN
               BEGIN
                  INSERT INTO transactionlog
                              (msgtype, rrn, delivery_channel, txn_code,
                               txn_type, txn_mode,
                               txn_status,
                               response_code, business_date,
                               business_time, customer_card_no,
                               bank_code,
                               total_amount,
                               currencycode, productid, categoryid,
                               auth_id,
                               amount,
                               tranfee_amt, preauthamount, partialamount,
                               instcode, customer_card_no_encr,
                               topup_card_no_encr, proxy_number,
                               reversal_code, customer_acct_no,
                               acct_balance, ledger_balance,
                               achfilename, tracenumber, response_id,
                               cardstatus, processtype, trans_desc,
                               ach_exception_queue_flag, cr_dr_flag,
                               error_msg, acct_type, time_stamp
                              )
                       VALUES (v_msg, v_rrn, v_del_channel, v_txn_code,
                               v_txn_type, v_txn_mode,
                               DECODE (p_resp_code, '00', 'C', 'F'),
                               p_resp_code, p_trandate,
                               SUBSTR (p_trantime, 1, 10), v_hash_pan,
                               p_instcode,
                               TRIM (TO_CHAR (v_tran_amt,'999999999999999990.99')),
                               v_card_curr, v_prod_code, v_card_type,
                               v_auth_id,
                               TRIM (TO_CHAR (v_tran_amt,'99999999999999990.99')),
                               '0.00', '0.00', '0.00',
                               p_instcode, v_encr_pan,
                               v_encr_pan, p_proxy_no,
                               v_rvsl_code, v_acct_number,
                               v_acct_balance, v_ledger_balance,
                               p_achfilename, p_tracenumber, v_respcode,
                               v_cap_card_stat, p_processtype, v_trans_desc,
                               v_ach_exp_flag, decode(p_txntype,'D','DR',v_dr_cr_flag),
                               p_errmsg, v_acct_type, SYSTIMESTAMP
                              );
               EXCEPTION
                  WHEN OTHERS THEN
                     p_resp_code := '89';
                     p_errmsg :='Problem while inserting into txnlog-'|| SUBSTR (SQLERRM, 1, 300);
               END;
            END IF;
         END IF;
         --En create a entry in txn log

         --Sn create a entry in cms_transaction_log_dtl
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_process_flag,
                         ctd_process_msg, ctd_rrn, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_txn_type, ctd_source_name
                        )
                 VALUES (v_del_channel, v_txn_code, v_msg,
                         v_txn_mode, p_trandate, p_trantime,
                         v_hash_pan, p_amount, v_card_curr,
                         p_amount, 'E',
                         p_errmsg, v_rrn, p_instcode,
                         v_encr_pan, v_acct_number,
                         v_txn_type, p_source_sname
                        );
         EXCEPTION
            WHEN OTHERS THEN
               p_errmsg :='Problem while inserting into txnlog dtl-'|| SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
         END;
      WHEN OTHERS THEN
         p_errmsg :='Main Exception While ACH txn processing-'|| SUBSTR (SQLERRM, 1, 200);
   END;

   PROCEDURE sp_tokenise_ach (
      prm_instr    IN       VARCHAR2,
      prm_tabout   OUT      c_ach_type,
      prm_errmsg   OUT      VARCHAR2
   )
   AS
      v_tab_var   c_ach_type := c_ach_type ();
   BEGIN
      prm_errmsg := 'OK';

      FOR x IN (SELECT   cac_field_seq, cac_field_pos, cac_field_size
                    FROM cms_achfield_config
                   WHERE cac_ind = 1
                ORDER BY cac_field_seq)
      LOOP
            v_tab_var.EXTEND;
            v_tab_var (x.cac_field_seq) := TRIM (SUBSTR (prm_instr, x.cac_field_pos, x.cac_field_size));
      END LOOP;

      prm_tabout := v_tab_var;
   EXCEPTION
      WHEN OTHERS THEN
         prm_errmsg :='Main Exception While tokanise data-' || SUBSTR (SQLERRM, 1, 100);
   END;

   PROCEDURE sp_send_mail (prm_filename IN VARCHAR2, prm_errmsg IN OUT VARCHAR2)
   AS
      v_mailhost      VARCHAR2 (30);
      v_mail_conn     UTL_SMTP.connection;
      v_contents      VARCHAR2 (3000);
      crlf            VARCHAR2 (2)                     := CHR (13)|| CHR (10);
      v_sender        VARCHAR2 (50);
      v_recipient     VARCHAR2 (500);
      v_subjct        VARCHAR2 (100);
      v_date          VARCHAR2 (30):= TO_CHAR (SYSDATE, 'MON DD YYYY HH:MI:SSAM');
      v_autogen_msg   VARCHAR2 (1000):= '*** This is an automatically generated email, please do not reply ***';
      v_msg           VARCHAR2 (3000);
      v_msg_part1     VARCHAR2 (1000);
      v_msg_part2     VARCHAR2 (1000);
      v_batch_no      cms_achfile_dtls.cad_batch_no%TYPE;
      v_datetime      VARCHAR2 (30);
      v_amt           cms_achfile_dtls.cad_tot_amt%TYPE;
      v_total_cards   cms_achfile_dtls.cad_tot_rows%TYPE;
      v_succ_cards    cms_achfile_dtls.cad_succ_rows%TYPE;
      v_err_cards     cms_achfile_dtls.cad_err_rows%TYPE;
   BEGIN
      SELECT cms_host_ip, cms_host_addr
        INTO v_mailhost, v_sender
        FROM cms_mail_setup;

      v_msg_part1 :=
            'Date: '
         || v_date
         || crlf
         || 'From:  <'
         || v_sender
         || '>'
         || crlf
         || 'To: None'
         || crlf;
      v_msg_part2 :=
            crlf
         || crlf
         || 'Thanks,'
         || crlf
         || 'Incomm Support Team'
         || crlf
         || crlf
         || v_autogen_msg;

      IF prm_filename IS NOT NULL THEN
         IF prm_errmsg = 'OK' THEN
            v_subjct :='Canadian ACH Batch Process Report Dated-'|| TO_CHAR (SYSDATE, 'DD-MM-YYYY');

            SELECT cad_batch_no,
                   TO_CHAR (cad_process_date, 'MON dd yyyy hh:mi:ssam'),
                   cad_tot_amt, cad_tot_rows, cad_succ_rows, cad_err_rows
              INTO v_batch_no,
                   v_datetime,
                   v_amt, v_total_cards, v_succ_cards, v_err_cards
              FROM cms_achfile_dtls
             WHERE cad_file_name = prm_filename AND cad_upd_stat = 'Y';

            v_msg :=
                  v_msg_part1
               || 'Subject: '
               || v_subjct
               || crlf
               || ''
               || crlf
               || 'Hi,'
               || crlf
               || crlf
               || 'Batch Process Report'
               || crlf
               || 'Batch No: '
               || v_batch_no
               || crlf
               || 'Batch Name: '
               || prm_filename
               || crlf
               || 'Location: DIRECT CREDIT LOC'
               || crlf
               || 'Create Date/Time: '
               || v_datetime
               || crlf
               || 'Scheduled Date/Time: '
               || v_datetime
               || crlf
               || 'Amount: '
               || TRIM (TO_CHAR (v_amt, '9999999990.99'))
               || crlf
               || 'Process Date/Time: '
               || v_datetime
               || crlf
               || 'Cards Processed: '
               || v_total_cards
               || crlf
               || 'Successes: '
               || v_succ_cards
               || crlf
               || 'Errors: '
               || v_err_cards
               || crlf
               || 'Timeouts: NA'
               || v_msg_part2;
         ELSIF prm_errmsg <> 'OK' THEN
            v_subjct :='CPA File Rejection Notification Dated-'|| TO_CHAR (SYSDATE, 'DD-MM-YYYY');
            v_msg :=
                  v_msg_part1
               || 'Subject: '
               || v_subjct
               || crlf
               || ''
               || crlf
               || 'Hi,'
               || crlf
               || crlf
               || 'Filename: '
               || prm_filename
               || crlf
               || 'Process Date: '
               || v_date
               || crlf
               || 'Rejection Reason: '
               || prm_errmsg
               || v_msg_part2;
         END IF;
      ELSE
         v_subjct :='Canadian ACH Scheduler No-Files Alert Dated-'|| TO_CHAR (SYSDATE, 'DD-MM-YYYY');
         v_msg :=
               v_msg_part1
            || 'Subject: '
            || v_subjct
            || crlf
            || ''
            || crlf
            || 'Hi,'
            || crlf
            || crlf
            || 'Filename: '
            || 'NA'
            || crlf
            || 'Process Date: '
            || v_date
            || crlf
            || 'Files not available in the shared location for processing..!'
            || v_msg_part2;
      END IF;

      v_mail_conn := UTL_SMTP.open_connection (v_mailhost, 25);
      UTL_SMTP.helo (v_mail_conn, v_mailhost);
      UTL_SMTP.mail (v_mail_conn, v_sender);

      FOR i IN (SELECT cms_mail_id FROM cms_mail_ids)
      LOOP
         UTL_SMTP.rcpt (v_mail_conn, i.cms_mail_id);
      END LOOP;

      UTL_SMTP.DATA (v_mail_conn, v_msg);
      UTL_SMTP.quit (v_mail_conn);
   --prm_errmsg := 'OK';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         prm_errmsg := prm_errmsg || ' ~~ ' || ' No mails configured';
      WHEN OTHERS THEN
         prm_errmsg :=prm_errmsg|| ' ~~ '|| ' Main Exception While sending mail-'|| SUBSTR (SQLERRM, 1, 100);
   END;

   PROCEDURE sp_batch_load_rep (
      prm_filename    IN       VARCHAR2,
      prm_directory   IN       VARCHAR2,
      prm_errmsg      OUT      VARCHAR2
   )
   AS
      l_file           UTL_FILE.file_type;
      v_amount_depo    VARCHAR2 (100);                       --NUMBER (20,2);
      v_batch_no       cms_achfile_dtls.cad_batch_no%TYPE;
      v_schedr_flag    VARCHAR2 (5);
      v_process_date   cms_achfile_dtls.cad_process_date%TYPE;
      v_tot_rows       cms_achfile_dtls.cad_tot_rows%TYPE;
      v_succ_rows      cms_achfile_dtls.cad_succ_rows%TYPE;
      v_succ_cnt       NUMBER (10);
      v_err_rows       cms_achfile_dtls.cad_err_rows%TYPE;
      i                NUMBER                                   := 0;

      CURSOR c
      IS
         WITH temp_dtl AS
              (SELECT '1' err_code
                 FROM DUAL
               UNION
               SELECT '2' err_code
                 FROM DUAL
               UNION
               SELECT '3' err_code
                 FROM DUAL)
         SELECT   DECODE (NVL (a.err_code, temp_dtl.err_code),
                          '1', 'Invalid Account',
                          '2', 'Velocity Check',
                          '3', 'Other Checks',
                          NULL, 'Total'
                         ) stat,
                  NVL (COUNT (a.err_code), 0) qty, NVL (SUM (amt), 0) total
             FROM (SELECT DECODE (b.cat_err_code,'R03', 1,'R23', 2,3) err_code,b.cat_txn_amt amt
                     FROM cms_achfile_txn_errlog b
                    WHERE b.cat_batch_no = v_batch_no
                      AND b.cat_file_name = prm_filename) a,temp_dtl
            WHERE a.err_code(+) = temp_dtl.err_code
         GROUP BY ROLLUP (NVL (a.err_code, temp_dtl.err_code))
         ORDER BY NVL (a.err_code, temp_dtl.err_code);
   BEGIN
      prm_errmsg := 'OK';

      BEGIN
         SELECT cad_batch_no, DECODE (cat_schedr_flag, 'A', 'Yes', 'N0'),
                cad_process_date, cad_tot_rows, cad_succ_rows, cad_err_rows
           INTO v_batch_no, v_schedr_flag,
                v_process_date, v_tot_rows, v_succ_rows, v_err_rows
           FROM cms_achfile_dtls
          WHERE cad_file_name = prm_filename AND cad_upd_stat = 'Y';
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error while selecting file dtls-' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         SELECT COUNT (*), TRIM(TO_CHAR(NVL (SUM ((pkg_ach_canada.fn_get_tabdata(cat_rec_no,cat_seg_no,cat_file_name,'S',5)/ 100)),0),'9999999990.99')) amt
           INTO v_succ_cnt,
                v_amount_depo
           FROM cms_achcanda_temp
          WHERE cat_batch_no = v_batch_no
            AND cat_file_name = prm_filename
            AND cat_proc_stat = 'S';
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error while getting sucess rec dtls-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --open file
      BEGIN
         l_file :=UTL_FILE.fopen (prm_directory, 'Batch_Load_Summ_Rep_'|| SUBSTR (prm_filename,1,INSTR (prm_filename, '.'))|| 'txt','W',32767);
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error occured during file open-' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --Sn write header information
       UTL_FILE.put_line (l_file, CHR (9)|| '---------------------------------------------------------------------');
       UTL_FILE.put_line (l_file, CHR (9) || CHR (9) || CHR (9) || 'Batch Load Summary Report');
       UTL_FILE.put_line (l_file, CHR (9)|| '---------------------------------------------------------------------');
       --En write header information
       UTL_FILE.put_line (l_file, CHR (9) || 'Customer          :' || CHR (9) || 'DIRECTCR');
       UTL_FILE.put_line (l_file, CHR (9) || 'Load Type         :' || CHR (9) || 'CR');
       UTL_FILE.put_line (l_file, CHR (9) || 'Filename          :' || CHR (9) || prm_filename);
       UTL_FILE.put_line (l_file, CHR (9) || 'Status            :' || CHR (9) || 'Completed');
       UTL_FILE.put_line (l_file, CHR (9) || 'Process Date      :' || CHR (9) || v_process_date);
       UTL_FILE.put_line (l_file, CHR (13) || CHR (10));
       UTL_FILE.put_line (l_file, CHR (9) || 'File Format Validations :');
       UTL_FILE.put_line (l_file, CHR (9) || '-------------------------');
       UTL_FILE.put_line (l_file, CHR (9) || 'No. Of Records    :' || CHR (9) || v_tot_rows);
       UTL_FILE.put_line (l_file, CHR (9) || 'Valid Records     :' || CHR (9) || v_succ_rows);
       UTL_FILE.put_line (l_file, CHR (9) || 'Invalid Records   :' || CHR (9) || v_err_rows);
       UTL_FILE.put (l_file, CHR (13) || CHR (10));
       UTL_FILE.put_line (l_file, CHR (9) || 'Records Details :');
       UTL_FILE.put_line (l_file, CHR (9) || '-----------------');
       UTL_FILE.put_line (l_file, CHR (9) || CHR (9) || CHR (9) || CHR (9) ||CHR (9) || 'Qty' || CHR (9) || CHR (9) || 'Total' );
       UTL_FILE.put_line (l_file, CHR (9) || RPAD('Validated Records',17,' ')||CHR (9)||':'|| CHR (9) || v_succ_cnt||CHR (9) || CHR (9) ||v_amount_depo);
       --flush so that buffer is emptied
       UTL_FILE.fflush (l_file);

       FOR x IN c
       LOOP
            BEGIN
               IF x.stat = 'Total' THEN
                  x.qty := x.qty + v_succ_cnt;
                  x.total := x.total + v_amount_depo;
               END IF;
               UTL_FILE.put_line (l_file, CHR (9)|| RPAD (x.stat, 17, ' ')|| CHR (9)|| ':'|| CHR (9)|| x.qty|| CHR (9)|| CHR (9)|| TRIM (TO_CHAR (x.total, '9999999990.99')));
               --flush so that buffer is emptied
               UTL_FILE.fflush (l_file);
            EXCEPTION
               WHEN OTHERS THEN
                  prm_errmsg :='Error Occured while writting file-' || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
       END LOOP;

       UTL_FILE.put (l_file, CHR (13) || CHR (10));
       UTL_FILE.put_line (l_file, CHR (9) || 'Batch           '||CHR (9) ||':'|| CHR (9) || v_batch_no);
       UTL_FILE.put_line (l_file, CHR (9) || 'Deposited       '||CHR (9) ||':'|| CHR (9) || v_amount_depo);
       UTL_FILE.put_line (l_file, CHR (9) || 'Auto scheduled   '||CHR (9) ||':'|| CHR (9) || v_schedr_flag);
       UTL_FILE.put_line (l_file, CHR (9) || 'Auto Deposit     '||CHR (9) ||':'|| CHR (9) || 'Yes');
       UTL_FILE.put (l_file, CHR (10));
       --flush file to disk
       UTL_FILE.fflush (l_file);
       --close file
       UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS THEN
         prm_errmsg:='Main Excp Summ rep-' || SUBSTR (SQLERRM, 1, 200);
         IF UTL_FILE.is_open (l_file) THEN
            UTL_FILE.fclose (l_file);
         END IF;
   END;

   PROCEDURE sp_batch_excp_rep (
      prm_filename    IN       VARCHAR2,
      prm_directory   IN       VARCHAR2,
      prm_errmsg      OUT      VARCHAR2
   )
   AS
      v_str       VARCHAR2 (4000);
      l_file      UTL_FILE.file_type;
      v_v_val     VARCHAR2 (4000);
      v_n_val     NUMBER;
      v_d_val     DATE;
      v_ret       NUMBER;
      v_cur       NUMBER;
      v_exe       NUMBER;
      v_col_cnt   INTEGER;
      v_col_num   NUMBER;
      v_rec_tab   DBMS_SQL.desc_tab;
   BEGIN
      prm_errmsg := 'OK';
      v_str :=
            'SELECT to_char(cat_process_date,''DD-MON-YYYY HH24:MI:SS'') as PostDate , decode(cat_txn_type,''D'',''DR'',''C'',''CR'') as RecType , trim(to_char(cat_txn_amt,''9999999990.99''))  Amount,
                    cat_cust_name as CustName , cat_proxy_no as ProxyNo , cat_trace_no as TraceNo, cat_source_sname as PayerShortName ,
                    cat_source_fname as PayerLongName , cat_err_code as ErrorCode , cat_err_desc As ErrorDesc,''  '' as NextwaveAccountingsNote
               FROM cms_achfile_txn_errlog
              WHERE cat_file_name ='''
         || prm_filename
         || '''';

      BEGIN
         l_file :=UTL_FILE.fopen (UPPER (prm_directory), 'Batch_Excp_Rep_'|| SUBSTR (prm_filename,1,INSTR (prm_filename, '.'))|| 'xls', 'w', 32767);
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error occured during opening file -'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --Sn Start for Workbook
       UTL_FILE.put_line (l_file, '<?xml version="1.0"?>');
       UTL_FILE.put_line (l_file, '<ss:Workbook xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');
       --En Start for Workbook

       --Sn Start for Worksheet
       UTL_FILE.put_line (l_file, '<ss:Worksheet ss:Name="'|| SUBSTR (prm_filename, 1,INSTR (prm_filename, '.') - 1)|| '">');
       UTL_FILE.put_line (l_file, '<ss:Table>');
       --En Start for Worksheet

       --------------------------------------------------
       --Sn Query2Sheet
       --------------------------------------------------
       v_cur := DBMS_SQL.open_cursor;
       DBMS_SQL.parse (v_cur, v_str, DBMS_SQL.native);
       v_exe := DBMS_SQL.EXECUTE (v_cur);
       DBMS_SQL.describe_columns (v_cur, v_col_cnt, v_rec_tab);

       FOR j IN 1 .. v_col_cnt
       LOOP
          CASE v_rec_tab (j).col_type
             WHEN 1 THEN
                DBMS_SQL.define_column (v_cur, j, v_v_val, 4000);
             WHEN 2 THEN
                DBMS_SQL.define_column (v_cur, j, v_n_val);
             WHEN 12 THEN
                DBMS_SQL.define_column (v_cur, j, v_d_val);
             ELSE
                DBMS_SQL.define_column (v_cur, j, v_v_val, 4000);
          END CASE;
       END LOOP;

       UTL_FILE.put_line (l_file, '<ss:Row>');

       FOR j IN 1 .. v_col_cnt
       LOOP
          UTL_FILE.put_line (l_file, '<ss:Cell>');
          UTL_FILE.put_line (l_file, '<ss:Data ss:Type="String">'|| v_rec_tab (j).col_name|| '</ss:Data>');
          UTL_FILE.put_line (l_file, '</ss:Cell>');
       END LOOP;

       UTL_FILE.put_line (l_file, '</ss:Row>');

       --Sn write into excel
       LOOP
          v_ret := DBMS_SQL.fetch_rows (v_cur);
          EXIT WHEN v_ret = 0;
          UTL_FILE.put_line (l_file, '<ss:Row>');

          FOR j IN 1 .. v_col_cnt
          LOOP
             CASE v_rec_tab (j).col_type
                WHEN 1 THEN
                   DBMS_SQL.COLUMN_VALUE (v_cur, j, v_v_val);
                   UTL_FILE.put_line (l_file, '<ss:Cell>');
                   UTL_FILE.put_line (l_file, '<ss:Data ss:Type="String">'|| v_v_val|| '</ss:Data>');
                   UTL_FILE.put_line (l_file, '</ss:Cell>');
                WHEN 2 THEN
                   DBMS_SQL.COLUMN_VALUE (v_cur, j, v_n_val);
                   UTL_FILE.put_line (l_file, '<ss:Cell>');
                   UTL_FILE.put_line (l_file, '<ss:Data ss:Type="Number">'|| TO_CHAR (v_n_val)|| '</ss:Data>'
                                     );
                   UTL_FILE.put_line (l_file, '</ss:Cell>');
                WHEN 12 THEN
                   DBMS_SQL.COLUMN_VALUE (v_cur, j, v_d_val);
                   UTL_FILE.put_line (l_file, '<ss:Cell ss:StyleID="OracleDate">');
                   UTL_FILE.put_line (l_file, '<ss:Data ss:Type="DateTime">'|| TO_CHAR (v_d_val,'YYYY-MM-DD"T"HH24:MI:SS')|| '</ss:Data>');
                   UTL_FILE.put_line (l_file, '</ss:Cell>');
                ELSE
                   DBMS_SQL.COLUMN_VALUE (v_cur, j, v_v_val);
                   UTL_FILE.put_line (l_file, '<ss:Cell>');
                   UTL_FILE.put_line (l_file, '<ss:Data ss:Type="String">'|| v_v_val|| '</ss:Data>');
                   UTL_FILE.put_line (l_file, '</ss:Cell>');
             END CASE;
          END LOOP;

          UTL_FILE.put_line (l_file, '</ss:Row>');
       END LOOP;

       --En write into excel
       DBMS_SQL.close_cursor (v_cur);
       --------------------------------------------------------------------------
       --En Query2Sheet
       --------------------------------------------------------------------------

       --Sn End of Worksheet
       UTL_FILE.put_line (l_file, '</ss:Table>');
       UTL_FILE.put_line (l_file, '</ss:Worksheet>');
       --En End of Worksheet

       --Sn End of Workbook
       UTL_FILE.put_line (l_file, '</ss:Workbook>');
       --En End of Workbook

       --flush file to disk
       UTL_FILE.fflush (l_file);

       --Close the file
       UTL_FILE.fclose (l_file);
   EXCEPTION
     WHEN OTHERS THEN
        IF UTL_FILE.is_open (l_file) THEN
           UTL_FILE.fclose (l_file);
        END IF;
        prm_errmsg := 'Main Excp from Query2excel-' || SUBSTR (SQLERRM, 1, 200);
   END;

   FUNCTION fn_get_tabdata (
      prm_rec        IN   NUMBER,
      prm_seg        IN   NUMBER,
      prm_file         IN   VARCHAR2,
      prm_rectype   IN   VARCHAR2,
      prm_data        IN   NUMBER
   )
      RETURN VARCHAR2
   AS
      v_tab   c_ach_type := c_ach_type ();
   BEGIN
      SELECT cat_ach_data
        INTO v_tab
        FROM cms_achcanda_temp
       WHERE cat_file_name = prm_file
           AND cat_rec_no = prm_rec
             and cat_seg_no=prm_seg
             and cat_proc_stat=prm_rectype;

      RETURN TRIM (v_tab (prm_data));
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END;

   PROCEDURE sp_get_file_list (prm_directory IN VARCHAR2)
   AS
      LANGUAGE JAVA
      NAME 'FileList.getList( java.lang.String )';
END;
/
show error