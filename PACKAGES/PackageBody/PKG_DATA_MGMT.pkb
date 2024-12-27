CREATE OR REPLACE PACKAGE BODY vmscms.pkg_data_mgmt IS
  FUNCTION log_purge_status(p_object_owner_in IN data_mgmt_ctl.object_owner%TYPE,
                            p_object_name_in  IN data_mgmt_ctl.object_name%TYPE,
                            p_process_name_in IN data_mgmt_log.process_name%TYPE,
                            p_run_date_in     IN data_mgmt_log.process_run_dttm%TYPE,
                            p_step_name_in    IN data_mgmt_log.step_name%TYPE,
                            p_status_in       IN data_mgmt_log.step_run_status%TYPE,
                            p_err_num_in_out  IN OUT NOCOPY NUMBER,
                            p_err_msg_in_out  IN OUT NOCOPY VARCHAR2,
                            p_comment_in      IN data_mgmt_log.comments%TYPE)
    RETURN BOOLEAN IS
    -- this is an autonomous transaction. logging should not fail due to commit boundary
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- insert log entry
    INSERT INTO data_mgmt_log
      (object_owner,
       object_name,
       process_name,
       process_run_dttm,
       step_number,
       step_name,
       step_start_dttm,
       step_end_dttm,
       step_run_status,
       error_number,
       error_msg,
       comments,
       inserted_by,
       insert_date_time)
    VALUES
      (p_object_owner_in,
       p_object_name_in,
       p_process_name_in,
       p_run_date_in,
       data_mgmt_seq.nextval,
       p_step_name_in,
       systimestamp,
       systimestamp,
       p_status_in,
       p_err_num_in_out,
       p_err_msg_in_out,
       p_comment_in,
       USER,
       systimestamp);
    --specifically committing as this is an autonomous transaction
    COMMIT;
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_err_num_in_out := SQLCODE;
      p_err_msg_in_out := SQLERRM;
      --specifically rollingback as this is an autonomous transaction
      ROLLBACK;
      RETURN FALSE;
  END log_purge_status;

  PROCEDURE sp_send_mail_data_mgmt(p_failed_reason IN VARCHAR2,
                                   p_errmsg        IN OUT VARCHAR2) AS
    v_mailhost    VARCHAR2(30);
    v_mail_conn   utl_smtp.connection;
    v_contents    VARCHAR2(3000);
    crlf          VARCHAR2(2) := chr(13) || chr(10);
    v_sender      VARCHAR2(50);
    v_recipient   VARCHAR2(500);
    v_subjct      VARCHAR2(100);
    v_date        VARCHAR2(30) := to_char(SYSDATE, 'MON DD YYYY HH:MI:SSAM');
    v_autogen_msg VARCHAR2(1000) := '*** This is an automatically generated email, please do not reply ***';
    v_msg         VARCHAR2(3000);
    v_msg_part1   VARCHAR2(1000);
    v_msg_part2   VARCHAR2(1000);
    v_datetime    VARCHAR2(30);
    v_err_cards   INTEGER;
    l_err_num     INTEGER;
    l_log_status  BOOLEAN;
  BEGIN
    SELECT dme_host_ip, dme_host_addr
      INTO v_mailhost, v_sender
      FROM data_mgmt_email;
  
    v_msg_part1 := 'Date: ' || v_date || crlf || 'From:  <' || v_sender || '>' || crlf ||
                   'To: None' || crlf;
    v_msg_part2 := crlf || crlf || 'Thanks,' || crlf ||
                   'Incomm Support Team' || crlf || crlf || v_autogen_msg;
  
    v_subjct   := 'Purge Process Report Dated-' ||
                  to_char(SYSDATE, 'DD-MM-YYYY');
    v_datetime := SYSDATE;
    v_msg      := v_msg_part1 || 'Subject: ' || v_subjct || crlf || '' || crlf ||
                  'Hi,' || crlf || crlf ||
                  'The Purge Process Failed for following reason:' || crlf || crlf ||
                  p_errmsg || crlf || crlf || v_msg_part2;
  
    v_mail_conn := utl_smtp.open_connection(v_mailhost, 25);
    utl_smtp.helo(v_mail_conn, v_mailhost);
    utl_smtp.mail(v_mail_conn, v_sender);
  
    FOR i IN (SELECT dmm_mail_id FROM data_mgmt_mail_ids) LOOP
      utl_smtp.rcpt(v_mail_conn, i.dmm_mail_id);
    END LOOP;
    utl_smtp.data(v_mail_conn, v_msg);
    utl_smtp.quit(v_mail_conn);
    p_errmsg := 'OK';
  EXCEPTION
    WHEN no_data_found THEN
      l_err_num    := -1;
      p_errmsg     := p_errmsg || ' ~~ ' || ' No mails configured';
      l_log_status := log_purge_status(NULL,
                                       'EMAIL',
                                       'EMAIL',
                                       SYSDATE,
                                       NULL,
                                       g_failed,
                                       l_err_num,
                                       p_errmsg,
                                       'Email functionality failed ');
    WHEN OTHERS THEN
      l_err_num    := -1;
      p_errmsg     := p_errmsg || ' ~~ ' ||
                      ' Main Exception While sending mail-' ||
                      substr(SQLERRM, 1, 100);
      l_log_status := log_purge_status(NULL,
                                       'EMAIL',
                                       'EMAIL',
                                       SYSDATE,
                                       NULL,
                                       g_failed,
                                       l_err_num,
                                       p_errmsg,
                                       'Email functionality failed ');
  END sp_send_mail_data_mgmt;

  PROCEDURE truncate_table(p_object_owner_in IN all_tables.owner%TYPE,
                           p_object_name_in  IN data_mgmt_ctl.object_name%TYPE,
                           p_run_date_in     IN data_mgmt_log.process_run_dttm%TYPE) IS
    l_ddl           VARCHAR2(2000);
    l_step_name     VARCHAR2(500);
    l_err_num       PLS_INTEGER := 0;
    l_err_msg       VARCHAR2(1000);
    l_email_err_msg VARCHAR2(500);
  
  BEGIN
  
    -- Set DDL timeout lock to 60 in order to avoid 'Resource busy' error.
    l_step_name := 'Set DDL timeout lock to 120 in order to avoid Resource busy error.';
  
    EXECUTE IMMEDIATE 'alter session set ddl_lock_timeout= 120';
  
    l_step_name := 'Execute the truncate table command';
  
    l_ddl := 'TRUNCATE TABLE ' || p_object_owner_in || '.' ||
             p_object_name_in;
    BEGIN
      EXECUTE IMMEDIATE l_ddl;
      l_step_name := 'TRUNCATE Table ' || p_object_name_in ||
                     ' -Successful';
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'TRUNCATE',
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              l_err_num,
                              l_err_msg,
                              'The table ' || p_object_owner_in || '.' ||
                              p_object_name_in || ' is truncated. ') THEN
        RETURN;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        l_step_name := 'Error while truncating table ' || p_object_owner_in || '.' ||
                       p_object_name_in;
        l_err_msg   := 'Error while truncating table ' || p_object_owner_in || '.' ||
                       p_object_name_in || ' - ' || substr(SQLERRM, 1, 500);
        l_err_num   := -1;
        IF NOT log_purge_status(p_object_owner_in,
                                p_object_name_in,
                                'TRUNCATE',
                                p_run_date_in,
                                l_step_name,
                                g_failed,
                                l_err_num,
                                l_err_msg,
                                'The table ' || p_object_owner_in || '.' ||
                                p_object_name_in || ' is not truncated.') THEN
          -- send email
          sp_send_mail_data_mgmt(l_err_msg, l_email_err_msg);
        END IF;
        sp_send_mail_data_mgmt(l_step_name, l_err_msg);
    END;
  
  EXCEPTION
    WHEN OTHERS THEN
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'TRUNCATE',
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              l_err_num,
                              l_err_msg,
                              'The table ' || p_object_owner_in || '.' ||
                              p_object_name_in || ' is not truncated.') THEN
        l_email_err_msg := 'Error while sending email ' ||
                           substr(SQLERRM, 1, 300);
        -- send email
        sp_send_mail_data_mgmt(l_err_msg, l_email_err_msg);
      END IF;
      sp_send_mail_data_mgmt(l_step_name, l_err_msg);
  END truncate_table;

  PROCEDURE drop_table(p_object_owner_in IN all_tables.owner%TYPE,
                       p_object_name_in  IN data_mgmt_ctl.object_name%TYPE,
                       p_run_date_in     IN data_mgmt_log.process_run_dttm%TYPE) IS
    l_ddl           VARCHAR2(2000);
    l_step_name     VARCHAR2(500);
    l_err_num       PLS_INTEGER := 0;
    l_err_msg       VARCHAR2(1000);
    l_email_err_msg VARCHAR2(500);
  
  BEGIN
  
    -- Set DDL timeout lock to 60 in order to avoid 'Resource busy' error.
    l_step_name := 'Set DDL timeout lock to 120 in order to avoid Resource busy error.';
  
    EXECUTE IMMEDIATE 'alter session set ddl_lock_timeout= 120';
  
    l_step_name := 'Execute the drop table command';
  
    l_ddl := 'DROP TABLE ' || p_object_owner_in || '.' || p_object_name_in;
    BEGIN
      EXECUTE IMMEDIATE l_ddl;
      l_step_name := 'DROP Table ' || p_object_name_in || ' -Successful';
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'DROP',
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              l_err_num,
                              l_err_msg,
                              'The table ' || p_object_owner_in || '.' ||
                              p_object_name_in || ' is dropped. ') THEN
        -- send email
        sp_send_mail_data_mgmt(l_err_msg, l_email_err_msg);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        l_step_name := 'Error while dropping table ' || p_object_owner_in || '.' ||
                       p_object_name_in;
        l_err_msg   := 'Error while dropping table ' || p_object_owner_in || '.' ||
                       p_object_name_in || ' - ' || substr(SQLERRM, 1, 500);
        l_err_num   := -1;
        IF NOT log_purge_status(p_object_owner_in,
                                p_object_name_in,
                                'DROP',
                                p_run_date_in,
                                l_step_name,
                                g_failed,
                                l_err_num,
                                l_err_msg,
                                'The table ' || p_object_owner_in || '.' ||
                                p_object_name_in || ' is not dropped.') THEN
          l_email_err_msg := 'Error while sending email ' ||
                             substr(SQLERRM, 1, 300);
          -- send email
          sp_send_mail_data_mgmt(l_err_msg, l_email_err_msg);
        END IF;
        sp_send_mail_data_mgmt(l_step_name, l_err_msg);
    END;
  
  EXCEPTION
    WHEN OTHERS THEN
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'TRUNCATE',
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              l_err_num,
                              l_err_msg,
                              'The table ' || p_object_owner_in || '.' ||
                              p_object_name_in || ' is not dropped.') THEN
        NULL;
      END IF;
      sp_send_mail_data_mgmt(l_step_name, l_err_msg);
  END drop_table;
  --PURGE_table

  FUNCTION process_table_purge(p_run_date_in                 IN data_mgmt_log.process_run_dttm%TYPE,
                               p_process_name_in             IN data_mgmt_log.process_name%TYPE,
                               p_object_owner_in             IN all_tables.owner%TYPE,
                               p_object_name_in              IN data_mgmt_ctl.object_name%TYPE,
                               p_retention_period_unit_in    IN data_mgmt_ctl.retention_period_unit%TYPE,
                               p_retention_period_in         IN data_mgmt_ctl.retention_period%TYPE,
                               p_special_purge_processing_in IN data_mgmt_ctl.special_purge_processing%TYPE,
                               p_is_partitioned_in           IN data_mgmt_ctl.is_partitioned%TYPE,
                               p_retention_compare_col_in    IN data_mgmt_ctl.retention_compare_col%TYPE,
                               p_retention_compare_sql_in    IN data_mgmt_ctl.retention_compare_sql%TYPE,
                               p_operation_type_in           IN data_mgmt_ctl.operation_type%TYPE,
                               p_err_num_in_out              IN OUT NOCOPY NUMBER,
                               p_err_msg_in_out              IN OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
    l_step_name data_mgmt_log.step_name%TYPE;
    l_name_str  data_mgmt_ctl.object_name%TYPE;
    --l_compare_str     data_mgmt_ctl.retention_compare_sql%TYPE;
    l_run_date        data_mgmt_log.process_run_dttm%TYPE; -- to store the run date in case of non-daily partitions
    l_date_str        VARCHAR2(20); --to store the date as string to be used in calculating age of data
    l_where_clause    VARCHAR2(4000);
    l_ddl             VARCHAR2(4000);
    l_part_flag       data_mgmt_ctl.is_partitioned%TYPE := NULL;
    l_cnt             NUMBER;
    l_sub_cnt         NUMBER;
    l_long            LONG;
    l_high_value_date VARCHAR2(32767);
    l_boolean         BOOLEAN;
    l_out_errmsg      VARCHAR2(100) := '';
  BEGIN
  
    l_step_name := 'PURGE Table Initiate - Generate strings for comparison';
    IF NOT log_purge_status(p_object_owner_in,
                            p_object_name_in,
                            p_process_name_in,
                            p_run_date_in,
                            l_step_name,
                            g_processing,
                            p_err_num_in_out,
                            p_err_msg_in_out,
                            'Generating comparison strings for object ' ||
                            p_object_owner_in || '.' || p_object_name_in ||
                            ' retention period unit:-' ||
                            p_retention_period_unit_in) THEN
      RETURN FALSE;
    END IF;
  
    -- check if table needss to be truncated
    IF p_operation_type_in = 'TRUNCATE' THEN
      -- code to truncate the table.
      l_step_name := 'TRUNCATE Table ' || p_object_name_in || ' -Initiated';
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'TRUNCATE',
                              p_run_date_in,
                              l_step_name,
                              g_processing,
                              p_err_num_in_out,
                              p_err_msg_in_out,
                              'Generating truncate table statement for object ' ||
                              p_object_owner_in || '.' || p_object_name_in ||
                              'Operation_type column value:-' ||
                              p_operation_type_in) THEN
        RETURN FALSE;
      END IF;
      -- call a procedure to truncate the table
      truncate_table(p_object_owner_in, p_object_name_in, p_run_date_in);
      RETURN TRUE;
    ELSIF p_operation_type_in = 'DROP' THEN
      -- code to drop the table.
      l_step_name := 'DROP Table ' || p_object_name_in || ' -Initiated';
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              'DROP',
                              p_run_date_in,
                              l_step_name,
                              g_processing,
                              p_err_num_in_out,
                              p_err_msg_in_out,
                              'Generating drop table statement for object ' ||
                              p_object_owner_in || '.' || p_object_name_in ||
                              'Operation_type column value:-' ||
                              p_operation_type_in) THEN
        RETURN FALSE;
      END IF;
      -- call a procedure to drop the table
      drop_table(p_object_owner_in, p_object_name_in, p_run_date_in);
      RETURN TRUE;
      ----------
    ELSIF p_operation_type_in = 'PURGE' THEN
    
      IF p_retention_period_unit_in = 'D' THEN
        --when retention period is set to Daily
      
        l_date_str     := to_char(p_run_date_in - p_retention_period_in,
                                  'YYYYMMDD');
        l_where_clause := p_retention_compare_col_in || ' < to_date(''' ||
                          l_date_str || ''',''YYYYMMDD'')';
      ELSIF p_retention_period_unit_in = 'M' THEN
        ------when retention period is set to Monthly
        --add month logic here
        -- monthly partitions start from 1-1-2019
        -- Go to the first day of the current month
        l_run_date := to_date(extract(YEAR FROM p_run_date_in) ||
                              lpad(extract(MONTH FROM p_run_date_in),
                                   2,
                                   '0') || '01',
                              'YYYYMMDD');
      
        -- calculate date string based on the retention period (in months)
        l_date_str     := to_char(add_months(p_run_date_in,
                                             -p_retention_period_in),
                                  'YYYYMMDD');
        l_where_clause := p_retention_compare_col_in || ' < to_date(''' ||
                          l_date_str || ''',''YYYYMMDD'')';
      
      ELSE
        RETURN FALSE; --Return false if not Daily, Monthly or Yearly
      END IF;
    
      l_step_name := 'PURGE - Compare string generation successful';
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              p_process_name_in,
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              p_err_num_in_out,
                              p_err_msg_in_out,
                              'l_date_str:-' || l_date_str ||
                              '***l_where_clause:-' || l_where_clause) THEN
        RETURN FALSE; --return false and stop processing if error as we need to log every step
      END IF;
    
      IF p_is_partitioned_in = 'Y' THEN
        --if table is partitioned
      
        --loop through all the partitions
      
        FOR l_cur_part IN (SELECT partition_name, high_value
                             FROM all_tab_partitions
                            WHERE table_name = p_object_name_in
                              AND partition_position != 1
                            ORDER BY partition_position)
        
         LOOP
          l_long := l_cur_part.high_value;
          --calculate the high value for the partition
          --needs special processing as the column is defined as LONG
          l_high_value_date := REPLACE(TRIM(substr(l_long,
                                                   instr(l_long, '''', 1, 1) + 1,
                                                   instr(l_long, ' ', 1, 2) -
                                                   instr(l_long, '''', 1, 1))),
                                       '-',
                                       '');
          --convert to date before checking
          IF to_date(l_high_value_date, 'YYYYMMDD') <
             to_date(l_date_str, 'YYYYMMDD') THEN
            --generate DDL statement
            --update global indexes otherwise indexes would be marked unusable -
            --and we will have to rebuild the entire index
            --this will also provide high availability
            l_ddl := 'alter table ' || p_object_owner_in || '.' ||
                     p_object_name_in || ' drop partition ' ||
                     l_cur_part.partition_name || ' update global indexes';
            --dbms_output.put_line(l_ddl);
            l_step_name := 'Dropping partition - ' ||
                           l_cur_part.partition_name;
            IF NOT log_purge_status(p_object_owner_in,
                                    p_object_name_in,
                                    p_process_name_in,
                                    p_run_date_in,
                                    l_step_name,
                                    g_processing,
                                    p_err_num_in_out,
                                    p_err_msg_in_out,
                                    l_ddl) THEN
              RETURN FALSE; --return false and stop processing if error as we need to log every step
            END IF;
            EXECUTE IMMEDIATE l_ddl;
          
            l_step_name := 'Dropped partition - ' ||
                           l_cur_part.partition_name;
            IF NOT log_purge_status(p_object_owner_in,
                                    p_object_name_in,
                                    p_process_name_in,
                                    p_run_date_in,
                                    l_step_name,
                                    g_success,
                                    p_err_num_in_out,
                                    p_err_msg_in_out,
                                    l_ddl) THEN
              RETURN FALSE; --return false and stop processing if error as we need to log every step
              -- raise an alert
              -- send an email to ...
            END IF;
          END IF;
        END LOOP; --end partition loop
      
      ELSE
        --if its a regular heap table
      
        IF p_retention_compare_sql_in IS NOT NULL THEN
          --if special processing is needed
          --replace ~ with the where clause
          --I added it just in case we need it in future. we may not need it now
          IF p_special_purge_processing_in = 'Y' THEN
            l_ddl := REPLACE(p_retention_compare_sql_in,
                             '~',
                             l_where_clause);
            --dont think we need this
            --ELSE
            --l_ddl := 'DELETE FROM (' || p_retention_compare_sql_in ||' AND ' || l_where_clause || ')';
          END IF;
        ELSE
          l_ddl := 'DELETE FROM ' || p_object_owner_in || '.' ||
                   p_object_name_in || ' WHERE ' || l_where_clause;
        END IF;
      
        l_step_name := 'Deleting Rows';
        --l_step_name := NVL(p_retention_compare_sql_in,'p_retention_compare_sql_in IS NULL') ;
        --l_step_name := l_step_name || NVL(l_where_clause,'l_where_clause IS NULL');
        IF NOT log_purge_status(p_object_owner_in,
                                p_object_name_in,
                                p_process_name_in,
                                p_run_date_in,
                                l_step_name,
                                g_processing,
                                p_err_num_in_out,
                                p_err_msg_in_out,
                                l_ddl) THEN
          RETURN FALSE; --return false and stop processing if error as we need to log every step
        END IF;
        EXECUTE IMMEDIATE l_ddl;
      
        l_step_name := 'Deleted Rows:-' || SQL%ROWCOUNT;
        IF NOT log_purge_status(p_object_owner_in,
                                p_object_name_in,
                                p_process_name_in,
                                p_run_date_in,
                                l_step_name,
                                g_success,
                                p_err_num_in_out,
                                p_err_msg_in_out,
                                l_ddl) THEN
          RETURN FALSE; --return false and stop processing if error as we need to log every step
        END IF;
        COMMIT;
      END IF;
      l_step_name      := 'Purge table successful';
      p_err_num_in_out := NULL;
      p_err_msg_in_out := NULL;
      IF NOT log_purge_status(p_object_owner_in,
                              p_object_name_in,
                              p_process_name_in,
                              p_run_date_in,
                              l_step_name,
                              g_success,
                              p_err_num_in_out,
                              p_err_msg_in_out,
                              NULL) THEN
        RETURN FALSE; --return false and stop processing if error as we need to log every step
      END IF;
      RETURN TRUE;
    END IF; -- IF p_Operation_type_in = 'TRUNCATE' THEN
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_err_num_in_out := SQLCODE;
      p_err_msg_in_out := SQLERRM;
    
      l_step_name := 'Purge table Failed - ERROR TRAPPED IN EXCEPTION OTHER';
      --try to log information if possible
      --logging is an autonomous transaction
      --assigning value to a variable that way i dont have to add an if statement
      l_boolean   := log_purge_status(p_object_owner_in,
                                      p_object_name_in,
                                      p_process_name_in,
                                      p_run_date_in,
                                      l_step_name,
                                      g_failed,
                                      p_err_num_in_out,
                                      p_err_msg_in_out,
                                      l_ddl);
      l_step_name := 'Sending an ALERT EMAIL to distribution list';
      --try to log information if possible
      --logging is an autonomous transaction
      --assigning value to a variable that way i dont have to add an if statement
      l_boolean := log_purge_status(p_object_owner_in,
                                    p_object_name_in,
                                    p_process_name_in,
                                    p_run_date_in,
                                    l_step_name,
                                    g_failed,
                                    p_err_num_in_out,
                                    p_err_msg_in_out,
                                    l_ddl);
    
      sp_send_mail_data_mgmt(p_err_msg_in_out, l_out_errmsg);
    
      l_step_name := 'ALERT EMAIL Sent successfully to distribution list';
      --try to log information if possible
      --logging is an autonomous transaction
      --assigning value to a variable that way i dont have to add an if statement
      l_boolean := log_purge_status(p_object_owner_in,
                                    p_object_name_in,
                                    p_process_name_in,
                                    p_run_date_in,
                                    l_step_name,
                                    g_failed,
                                    p_err_num_in_out,
                                    p_err_msg_in_out,
                                    l_ddl);
      RETURN FALSE; --return false and stop processing if error as we need to log every step
  END process_table_purge;

  --function init
  --this function will be called from the database scheduler
  --accepts process name PURGE and calles Purge_Table function
  FUNCTION init(p_process_name_in data_mgmt_log.process_name%TYPE,
                p_run_date_in     data_mgmt_log.process_run_dttm%TYPE DEFAULT SYSDATE)
    RETURN BOOLEAN IS
  
    l_run_date  data_mgmt_log.process_run_dttm%TYPE;
    l_err_num   NUMBER;
    l_err_msg   data_mgmt_log.error_msg%TYPE;
    l_part_date DATE;
    l_boolean   BOOLEAN;
    l_step_name data_mgmt_log.step_name%TYPE;
  
  BEGIN
  
    l_run_date := nvl(l_run_date, SYSDATE);
    --select all the tables to be purged
    --IF p_process_name_in = 'PURGE' THEN
    l_step_name := 'open a loop to process the archival';
    FOR l_cur_ctl IN (SELECT object_owner,
                             object_name,
                             is_partitioned,
                             special_purge_processing,
                             retention_period,
                             retention_period_unit,
                             retention_compare_col,
                             retention_compare_sql,
                             exclude_indicator,
                             operation_type
                        FROM data_mgmt_ctl
                       WHERE exclude_indicator = 'N'
                         AND operation_type = p_process_name_in
                       ORDER BY process_order_number DESC,
                                object_owner,
                                object_name) LOOP
    
      l_step_name := 'call process_table_purge for ' ||
                     l_cur_ctl.object_owner || '.' || l_cur_ctl.object_name;
      IF NOT
          process_table_purge(p_run_date_in                 => l_run_date,
                              p_process_name_in             => p_process_name_in,
                              p_object_owner_in             => l_cur_ctl.object_owner,
                              p_object_name_in              => l_cur_ctl.object_name,
                              p_retention_period_unit_in    => l_cur_ctl.retention_period_unit,
                              p_retention_period_in         => l_cur_ctl.retention_period,
                              p_special_purge_processing_in => l_cur_ctl.special_purge_processing,
                              p_is_partitioned_in           => l_cur_ctl.is_partitioned,
                              p_retention_compare_col_in    => l_cur_ctl.retention_compare_col,
                              p_retention_compare_sql_in    => l_cur_ctl.retention_compare_sql,
                              p_operation_type_in           => l_cur_ctl.operation_type,
                              p_err_num_in_out              => l_err_num,
                              p_err_msg_in_out              => l_err_msg) THEN
        RETURN FALSE; --return false and stop processing if error as we need to log every step
      END IF;
    END LOOP;
    --END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      l_err_num := SQLCODE;
      l_err_msg := SQLERRM;
      l_boolean := log_purge_status(NULL,
                                    NULL,
                                    p_process_name_in,
                                    p_run_date_in,
                                    l_step_name,
                                    g_failed,
                                    l_err_num,
                                    l_err_msg,
                                    NULL);
      dbms_output.put_line('ERROR:' || to_char(l_err_num) || ' ' ||
                           substr(l_err_msg, 1, 200));
      ROLLBACK;
      RETURN FALSE;
  END;
END pkg_data_mgmt;
/
SHOW ERROR
