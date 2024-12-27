CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_TRAN_DETL_EXCP_REP 
AS
   l_file            UTL_FILE.file_type;
   l_file_name       VARCHAR2 (1000);
   l_total_records   NUMBER             := 0;
   v_errmsg          VARCHAR2 (4000);
   v_sqlerrmsg       VARCHAR2 (4000);
   prm_file_name     VARCHAR2 (60);

   CURSOR c (prm_file_name VARCHAR2)
   IS
      SELECT   mtt_file_name filename, mtt_record_number linenumber,
               vmscms.fn_mask (mtt_card_no, 'X', 7, 6) cardnumber,
               mtt_rrn rrn, mtt_business_date transactiondate,
               mtt_business_time transactiontime,
               mtt_delivery_channel deliverychannel,
               mtt_transaction_code transactioncode,
               mtt_response_code responsecode, mtt_errmsg errormessage
          FROM vmscms.migr_transactionlog_temp
         WHERE mtt_flag = 'F' AND mtt_file_name = prm_file_name
      ORDER BY mtt_file_name, mtt_record_number;

   CURSOR cur_file 
   IS
      SELECT  mtt_file_name filename
                 FROM vmscms.migr_transactionlog_temp
                WHERE mtt_flag = 'F' 
                group by mtt_file_name
             ORDER BY mtt_file_name ;

   v_succ_cnt        NUMBER (20)        := 0;
   v_err_cnt         NUMBER (20)        := 0;
   
  
   
BEGIN
   v_errmsg := 'OK';
   v_sqlerrmsg := 'OK';
   l_file_name := 'TRAN_DETL_EXCP_REP.csv';

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
   
      FOR cur_data IN c (i.filename)
      LOOP
         IF v_errmsg = 'OK'
         THEN
            BEGIN
               l_total_records := l_total_records + 1;
               UTL_FILE.put (l_file, cur_data.filename || ',');
               UTL_FILE.put (l_file, cur_data.linenumber || ',');
               UTL_FILE.put (l_file, cur_data.cardnumber || ',');
               UTL_FILE.put (l_file, cur_data.rrn || ',');
               UTL_FILE.put (l_file, cur_data.transactiondate || ',');
               UTL_FILE.put (l_file, cur_data.transactiontime || ',');
               UTL_FILE.put (l_file, cur_data.deliverychannel || ',');
               UTL_FILE.put (l_file, cur_data.transactioncode || ',');
               UTL_FILE.put (l_file, cur_data.responsecode || ',');
               UTL_FILE.put (l_file, cur_data.errormessage || ',');
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
                    VALUES (cur_data.filename, v_errmsg,
                            cur_data.linenumber, v_sqlerrmsg,l_file_name
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


