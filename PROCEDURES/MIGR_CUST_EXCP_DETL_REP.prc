CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_CUST_EXCP_DETL_REP 
AS
   l_file            UTL_FILE.file_type;
   l_file_name       VARCHAR2 (1000);
   l_total_records   NUMBER             := 0;
   v_errmsg          VARCHAR2 (4000);
   v_sqlerrmsg       VARCHAR2 (4000);
   prm_file_name     VARCHAR2 (60);

   CURSOR c (prm_file_name VARCHAR2)
   IS
    SELECT mci_file_name FileName, 
           mci_rec_num LineNumber, 
           VMSCMS.FN_MASK(mci_pan_code,'X',7,6) CardNumber, 
           mci_process_msg ErrorMessage
      FROM VMSCMS.migr_caf_info_entry
     WHERE mci_proc_flag = 'E'
	 and  mci_file_name = prm_file_name
     order by mci_file_name,mci_rec_num;

   CURSOR cur_file 
   IS
      SELECT  MCI_FILE_NAME filename
                 FROM vmscms.migr_caf_info_entry
                 WHERE mci_proc_flag = 'E'
                group by MCI_FILE_NAME
             ORDER BY MCI_FILE_NAME ;

   v_succ_cnt        NUMBER (20)        := 0;
   v_err_cnt         NUMBER (20)        := 0;
   
  
   
BEGIN
   v_errmsg := 'OK';
   v_sqlerrmsg := 'OK';
   l_file_name := 'CUST_EXCP_DETL_REP.csv';

   --open file
   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_CUST',
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 32767
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := ' Error occured during opening file';
         v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
   END;

   --write header information
   IF v_errmsg = 'OK'
   THEN
      UTL_FILE.put (l_file, 'FILE NAME,');
      UTL_FILE.put (l_file, 'LINE NUMBER,');
      UTL_FILE.put (l_file, 'CARD NUMBER,');
      UTL_FILE.put (l_file, 'ERROR STATUS,');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);
   END IF;

   --write records
   FOR i IN cur_file
   LOOP
   
   v_succ_cnt      := 0;
   v_err_cnt   := 0;
   v_errmsg := 'OK' ;
   
      FOR cur_data IN c (i.filename)
      LOOP
         IF v_errmsg = 'OK'
         THEN
            BEGIN
               l_total_records := l_total_records + 1;
               UTL_FILE.put (l_file, cur_data.FileName || ',');
               UTL_FILE.put (l_file, cur_data.LineNumber || ',');
               UTL_FILE.put (l_file, cur_data.CardNumber || ',');
               UTL_FILE.put (l_file, cur_data.ErrorMessage || ',');
               --end of record/carriage return and line feed
               UTL_FILE.put (l_file, CHR (13));
               --flush so that buffer is emptied
               UTL_FILE.fflush (l_file);
               
                v_succ_cnt := v_succ_cnt + 1;
               
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     ' Error Occured while writting file ';
                  v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
            END;
         END IF;

        

         IF v_errmsg <> 'OK'
         THEN
            v_err_cnt := v_err_cnt + 1;

            BEGIN
               INSERT INTO migr_rpt_wrt_fail
                           (mrw_file_name, mrw_errmsg,
                            mrw_line_number, mrw_sqlerrmsg,MRW_RPT_FILE
                           )
                    VALUES (cur_data.FileName, v_errmsg,
                            cur_data.LineNumber, v_sqlerrmsg,l_file_name
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     ' Error Occured During Inserting into migr_rpt_wrt_fail ';
                  v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
            END;
         END IF;
      END LOOP;

       DBMS_OUTPUT.PUT_LINE( v_succ_cnt);
       DBMS_OUTPUT.PUT_LINE( v_err_cnt);

      BEGIN
         INSERT INTO migr_rpt_wrt_succ
                     (mrw_file_name, mrw_errmsg, mrw_succ_cnt, mrw_err_cnt,
                      mrw_sqlerrmsg,MRW_RPT_FILE
                     )
              VALUES (i.filename, v_errmsg, v_succ_cnt, v_err_cnt,
                      v_sqlerrmsg,l_file_name
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    ' Error Occured During writting success details '; --Error message modified by Pankaj S. on 25-Sep-2013
            v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
      END;
      UTL_FILE.put (l_file, CHR (10));
   END LOOP;

   --flush file to disk
   UTL_FILE.fflush (l_file);
   --close file
   UTL_FILE.fclose (l_file);
--dbms_output.put_line(l_total_records);
EXCEPTION
   WHEN OTHERS
   THEN
      IF UTL_FILE.is_open (l_file)
      THEN
         UTL_FILE.fclose (l_file);
      END IF;

      DBMS_OUTPUT.put_line (SQLERRM);
END;
/

SHOW ERRORS;


