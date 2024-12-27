CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_TRAN_SUCCESS_DETAIL_REP 
AS
   l_file            UTL_FILE.file_type;
   l_file_name       VARCHAR2 (1000);
   l_total_records   NUMBER             := 0;
   v_errmsg          VARCHAR2 (4000);
   v_sqlerrmsg       VARCHAR2 (4000);
   prm_file_name     VARCHAR2 (60);

   CURSOR c (prm_file_name VARCHAR2)
   IS
     SELECT mtt_file_name FileName,
       mtt_record_number LineNumber,
       VMSCMS.fn_mask(mtt_card_no, 'X', 7, 6) CardNumber, 
       mtt_rrn RRN,
       mtt_business_date TransactionDate,
       mtt_business_time TransactionTime, 
       mtt_delivery_channel DELIVERYCHANNEL,
       mtt_transaction_code TransactionCode, 
       mtt_response_code RESPONSECODE,
       mtt_errmsg      ERRORMESSAGE
  FROM VMSCMS.migr_transactionlog_temp
 WHERE mtt_flag = 'S'
 and   mtt_file_name = prm_file_name
 order by mtt_file_name,mtt_record_number;
 
   CURSOR cur_file 
   IS
      SELECT  mtt_file_name FileName
                from VMSCMS.migr_transactionlog_temp
                where mtt_flag = 'S'
                group by mtt_file_name
             ORDER BY mtt_file_name ;

   v_succ_cnt        NUMBER (20)        := 0;
   v_err_cnt         NUMBER (20)        := 0;
   
BEGIN
   v_errmsg := 'OK';
   v_sqlerrmsg := 'OK';
   l_file_name :=  'TRAN_SUCCESS_DETAIL_REP.csv';

   --open file
   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_TRAN',
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
       UTL_FILE.put (l_file, 'FILE_NAME,');
       UTL_FILE.put (l_file, 'LINE_NUMBER,');
       UTL_FILE.put (l_file, 'CARD_NUMBER,');
       UTL_FILE.put (l_file, 'RRN,');
       UTL_FILE.put (l_file, 'TRANSACTION_DATE,');
       UTL_FILE.put (l_file, 'TRANSACTION_TIME,');
       UTL_FILE.put (l_file, 'DELIVERY_CHANNEL,');
       UTL_FILE.put (l_file, 'TRANSACTION_CODE,');
       UTL_FILE.put (l_file, 'RESPONSE_CODE,');
       UTL_FILE.put (l_file, 'ERROR_MESSAGE,');
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
   
      FOR cur_data in c (i.filename)
      LOOP
         IF v_errmsg = 'OK'
         THEN
            BEGIN
               l_total_records := l_total_records + 1;
              UTL_FILE.put (l_file, cur_data.FileName || ',');
              UTL_FILE.put (l_file, cur_data.LineNumber || ',');
              UTL_FILE.put (l_file, cur_data.CardNumber || ',');
              UTL_FILE.put (l_file, cur_data.rrn || ',');
              UTL_FILE.put (l_file, cur_data.TransactionDate || ',');
              UTL_FILE.put (l_file, cur_data.TransactionTime || ',');
              UTL_FILE.put (l_file, cur_data.DELIVERYCHANNEL || ',');
              UTL_FILE.put (l_file, cur_data.TransactionCode || ',');
              UTL_FILE.put (l_file, cur_data.RESPONSECODE || ',');
              UTL_FILE.put (l_file, cur_data.ERRORMESSAGE || ',');
               --end of record/carriage return and line feed
               UTL_FILE.put (l_file, CHR (13));
               --flush so that buffer is emptied
           
             UTL_FILE.fflush (l_file);
              v_succ_cnt := v_succ_cnt + 1;
            EXCEPTION
            
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'Error Occured During writting file ';
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
                    VALUES (cur_data.filename, v_errmsg,
                            cur_data.linenumber, v_sqlerrmsg,l_file_name
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'Error Occured During Inserting into migr_rpt_wrt_fail ';
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
                    'Error Occured During writting details ';
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


