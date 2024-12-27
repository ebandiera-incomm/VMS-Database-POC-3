CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ROLL_CALL_DATA_SUMRY_REP 
AS
   l_file            UTL_FILE.file_type;
   l_file_name       VARCHAR2 (1000);
   l_total_records   NUMBER             := 0;
   v_errmsg          VARCHAR2 (4000);
   v_sqlerrmsg       VARCHAR2 (4000);
   prm_file_name     VARCHAR2 (60);

   CURSOR c (PRM_SEQNO VARCHAR2)
   IS
     select (select substr(MFI_FILE_NAME,1,instr(MFI_FILE_NAME,'_ACCO')-1) 
         from migr_file_load_info
         where MFI_MIGR_SEQNO =PRM_SEQNO
         and   MFI_FILE_NAME like '%ACCO%'
         and   MFI_PROCESS_STATUS ='OK'
         and rownum <2) PRODUCT,
    (select count(*) from VMSCMS.MIGR_CSR_CALLLOG_TEMP
    where MCC_proc_flag='S' and MCC_MIGR_SEQNO = PRM_SEQNO) RECORDS_MIGRATED,
    (select MRC_DEL_CNT from vmscms.MIGR_ROLL_COUNT 
     where MRC_TABLE_NAME = 'CMS_CALLLOG_MAST' and MRC_MIGR_SEQNO =PRM_SEQNO
     ) TOTAL_RECORDS_DELETED,
    (
    (select MRC_DEL_CNT from vmscms.MIGR_ROLL_COUNT 
     where MRC_TABLE_NAME = 'CMS_CALLLOG_MAST' and MRC_MIGR_SEQNO =PRM_SEQNO
     ) -
     (
      (select MRC_DEL_CNT from vmscms.MIGR_ROLL_COUNT 
      where MRC_TABLE_NAME = 'CMS_CALLLOG_MAST' and MRC_MIGR_SEQNO =PRM_SEQNO) - 
      (select count(*) from VMSCMS.MIGR_CSR_CALLLOG_TEMP
      where MCC_proc_flag='S' and MCC_MIGR_SEQNO = PRM_SEQNO
      ) 
     )
     ) TOTAL_MIGRATED_RECORDS_DELETED
     ,
    (
     (select MRC_DEL_CNT from vmscms.MIGR_ROLL_COUNT 
     where MRC_TABLE_NAME = 'CMS_CALLLOG_MAST' and MRC_MIGR_SEQNO =PRM_SEQNO) - 
     (select count(*) from VMSCMS.MIGR_CSR_CALLLOG_TEMP
    where MCC_proc_flag='S' and MCC_MIGR_SEQNO = PRM_SEQNO) 
    ) TOTAL_ONLINE_RECORDS_DELETED,
    (
    select count(*) from migr_det_roll_excp where MDR_MIGR_SEQNO = prm_seqno
    ) EXCEPTION_COUNT        
    From dual;

   CURSOR cur_file 
   IS
      SELECT  distinct MRC_MIGR_SEQNO seqno
                 FROM vmscms.MIGR_ROLL_COUNT
             ORDER BY MRC_MIGR_SEQNO ;

   v_succ_cnt        NUMBER (20)        := 0;
   v_err_cnt         NUMBER (20)        := 0;
   
  
   
BEGIN
   v_errmsg := 'OK';
   v_sqlerrmsg := 'OK';
   l_file_name := 'ROLL_CALL_DATA_SUMRY_REP.csv';

   --open file
   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_CALL',
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 32767
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := ' Error occured during file open';
         v_sqlerrmsg := SUBSTR (SQLERRM, 1, 200);
   END;

   --write header information
   IF v_errmsg = 'OK'
   THEN
      UTL_FILE.put (l_file, 'PRODUCT NAME,');
      UTL_FILE.put (l_file, 'TOTAL  MIGRATED RECORDS,');
      UTL_FILE.put (l_file, 'TOTAL RECORDS DELETED,');
      UTL_FILE.put (l_file, 'TOTAL MIGRATED RECORDS DELETED,');
      UTL_FILE.put (l_file, 'TOTAL ONLINE RECORDS DELETED,');
      UTL_FILE.put (l_file, 'EXCEPTION COUNT,');
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
   
      FOR cur_data IN c (i.seqno)
      LOOP
         IF v_errmsg = 'OK'
         THEN
            BEGIN
               l_total_records := l_total_records + 1;
               
               
                IF cur_data.EXCEPTION_COUNT =0
                THEN                   
                   UTL_FILE.put (l_file, cur_data.PRODUCT || ',');
                   UTL_FILE.put (l_file, cur_data.RECORDS_MIGRATED || ',');
                   UTL_FILE.put (l_file, cur_data.TOTAL_RECORDS_DELETED || ',');
                   UTL_FILE.put (l_file, cur_data.TOTAL_MIGRATED_RECORDS_DELETED || ',');
                   UTL_FILE.put (l_file, cur_data.TOTAL_ONLINE_RECORDS_DELETED || ',');
                   UTL_FILE.put (l_file, cur_data.EXCEPTION_COUNT || ',');
                ELSE

                   UTL_FILE.put (l_file, cur_data.PRODUCT || ',');
                   UTL_FILE.put (l_file, cur_data.RECORDS_MIGRATED || ',');
                   UTL_FILE.put (l_file, '0' || ',');
                   UTL_FILE.put (l_file, '0' || ',');
                   UTL_FILE.put (l_file, '0' || ',');
                   UTL_FILE.put (l_file, cur_data.EXCEPTION_COUNT || ',');
                END IF;   
               
               --end of record/carriage return and line feed
               --UTL_FILE.put (l_file, CHR (13));
               UTL_FILE.put (l_file, CHR (13) || CHR (10));
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
                    VALUES (i.seqno, v_errmsg,
                            null, v_sqlerrmsg,l_file_name
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
              VALUES (i.seqno, v_errmsg, v_succ_cnt, v_err_cnt,
                      v_sqlerrmsg,l_file_name
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    ' Error Occured During writting details ';
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


