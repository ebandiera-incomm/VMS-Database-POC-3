CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ACCO_FILEWISE_LOAD_SUMRY
AS
   l_file            UTL_FILE.file_type;
   l_file_name       VARCHAR2 (1000);
   l_total_records   NUMBER             := 0;
   v_errmsg          VARCHAR2 (4000);
   v_sqlerrmsg       VARCHAR2 (4000);
   prm_file_name     VARCHAR2 (60);

   CURSOR c (prm_file_name VARCHAR2)
   IS
    SELECT mfd_file_name FileName, mfd_file_rec_cnt TotalRecords, mfd_succ_rec_cnt LoadedRecords, mfd_err_rec_cnt ErrorRecords
    FROM vmscms.migr_file_detl
    WHERE mfd_migr_type = 'ACCOUNT_DATA_MIGR' 
    AND mfd_file_load_flag = 'S'
    and  mfd_file_name = prm_file_name
    ORDER BY mfd_file_name;

   CURSOR cur_file 
   IS
      SELECT  mfd_file_name FileName
                  FROM vmscms.migr_file_detl
                  WHERE mfd_migr_type = 'ACCOUNT_DATA_MIGR' 
                  AND mfd_file_load_flag = 'S'
                group by mfd_file_name
             ORDER BY mfd_file_name ;

   v_succ_cnt        NUMBER (20)        := 0;
   v_err_cnt         NUMBER (20)        := 0;
   
BEGIN
   v_errmsg := 'OK';
   v_sqlerrmsg := 'OK';
   l_file_name := 'FILEWISE_LOAD_SUMRY.csv';

   --open file
   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_ACCO',
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 32767
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := ' Error occured during opening file'; --Error message modified by Pankaj S. on 25-Sep-2013
         v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
   END;

   --write header information
   IF v_errmsg = 'OK'
   THEN
      UTL_FILE.put (l_file, 'FILE_NAME,');
      UTL_FILE.put (l_file, 'TOTAL_RECORDS,');
      UTL_FILE.put (l_file, 'LOADED_RECORDS,');
      UTL_FILE.put (l_file, 'ERROR_RECORDS,');
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
               UTL_FILE.put (l_file, cur_data.filename || ',');
               UTL_FILE.put (l_file, cur_data.TotalRecords || ',');
               UTL_FILE.put (l_file, cur_data.LoadedRecords || ',');
               UTL_FILE.put (l_file, cur_data.ErrorRecords || ',');
               
               
               --end of record/carriage return and line feed
               UTL_FILE.put (l_file, CHR (13));
               --flush so that buffer is emptied
           
             UTL_FILE.fflush (l_file);
              v_succ_cnt := v_succ_cnt + 1;
            EXCEPTION
            
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     ' Error Occured During writting file  ';
                  v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
            END;
            
         END IF;

        

         IF v_errmsg <> 'OK'
         THEN
            v_err_cnt := v_err_cnt + 1;

            BEGIN
               INSERT INTO migr_rpt_wrt_fail
                           (mrw_file_name, mrw_errmsg, mrw_sqlerrmsg,MRW_RPT_FILE
                           )
                    VALUES (cur_data.filename, v_errmsg,
                             v_sqlerrmsg,l_file_name
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
                    ' Error Occured During writting details for Card number ';
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


