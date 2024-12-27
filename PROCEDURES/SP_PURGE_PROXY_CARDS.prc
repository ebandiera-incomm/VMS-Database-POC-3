CREATE OR REPLACE PROCEDURE VMSCMS.sp_purge_proxy_cards (
   prm_instcode    IN     NUMBER,
   prm_dir         IN     VARCHAR2,
   prm_file_name   IN     VARCHAR2,
   prm_succ_cnt    OUT    NUMBER,
   prm_fail_cnt    OUT    NUMBER,
   prm_errmsg      OUT    VARCHAR2)
AS
     /**************************************************************************
     * Created Date              : 02-Sep-2014
     * Created By                  : Pankaj S.
     * Purpose                      : JH-3019(Purge Proxy Cards)
     * Release Number          : RI0027.3.2_B0003
     **************************************************************************/
   v_file_handle            UTL_FILE.file_type;
   v_filebuffer             VARCHAR2 (32767);
   v_errmsg                 VARCHAR2 (500);
   exp_reject_loop_record   EXCEPTION;
   exp_file_name            EXCEPTION;
   v_savepoint              NUMBER :=0;
   v_acct_no                cms_appl_pan.cap_acct_no%TYPE;
   v_pan_code              cms_appl_pan.cap_pan_code%TYPE;
   v_pan_encr              cms_appl_pan.cap_pan_code_encr%TYPE;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_topup_flag            cms_appl_pan.cap_firsttime_topup%TYPE; 
   v_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   v_respcode               VARCHAR2(5);
   v_card_cnt               NUMBER;
   i                        NUMBER := 0;
   j                        NUMBER := 0;
   v_proxy_no               VARCHAR2 (50);

   TYPE r_purge_proxy IS RECORD
   (
      q_proxy_no      VARCHAR2 (50),
      q_process_msg   VARCHAR2 (500)
   );

   TYPE purge_proxy_t IS TABLE OF r_purge_proxy;

   l_purge_succ_result      purge_proxy_t;
   l_purge_fail_result      purge_proxy_t;

   PROCEDURE lp_write_log (l_filename         VARCHAR2,
                           l_dir              VARCHAR2,
                           l_purge_type       purge_proxy_t,
                           l_errormsg     OUT VARCHAR2)
   AS
      l_file   UTL_FILE.file_type;
   BEGIN
      l_errormsg:='OK';
      BEGIN
         l_file :=
            UTL_FILE.fopen (l_dir,l_filename,'W',32767);
      EXCEPTION
         WHEN OTHERS THEN
            l_errormsg := ' Error occured during file open';
            RETURN;
      END;

      UTL_FILE.put (l_file, 'Proxy Number,');
      UTL_FILE.put (l_file, 'Process Message');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      UTL_FILE.fflush (l_file);

      FOR i IN 1 .. l_purge_type.COUNT
      LOOP
         BEGIN
            UTL_FILE.put (l_file, l_purge_type (i).q_proxy_no || ',');
            UTL_FILE.put (l_file, l_purge_type (i).q_process_msg);
            UTL_FILE.put (l_file, CHR (13));
            UTL_FILE.fflush (l_file);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errormsg :=
                  'Error Occured while writting file-'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END LOOP;
      
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS THEN
         l_errormsg := 'Main Excp from LP-' || SUBSTR (SQLERRM, 1, 200);
   END;
BEGIN
   prm_errmsg := 'OK';
   l_purge_succ_result := purge_proxy_t ();
   l_purge_fail_result := purge_proxy_t ();

   IF UTL_FILE.is_open (v_file_handle) THEN
      UTL_FILE.fclose (v_file_handle);
   END IF;

   BEGIN
      v_file_handle :=UTL_FILE.fopen (prm_dir,prm_file_name,'R',32767);
   EXCEPTION
      WHEN OTHERS THEN
         prm_errmsg :='Error occured during file open-' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   LOOP
       v_savepoint:=v_savepoint+1;
       SAVEPOINT v_savepoint;
      BEGIN
         v_errmsg := 'OK';
         v_proxy_no := NULL;
         UTL_FILE.get_line (v_file_handle, v_filebuffer);
         v_proxy_no := TRIM (SUBSTR (v_filebuffer,1,INSTR (v_filebuffer,',',1,1)- 1));

         BEGIN
            SELECT cap_acct_no, cap_pan_code, cap_card_stat,cap_pan_code_encr,cap_firsttime_topup
              INTO v_acct_no, v_pan_code, v_card_stat,v_pan_encr,v_topup_flag
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode
               AND cap_proxy_number = v_proxy_no;

            IF v_card_stat IN ('1', '9')  THEN
               v_errmsg :='Failed to purge card since proxy in Active/Closed status';
               RAISE exp_reject_loop_record;
            ELSIF v_topup_flag='Y'  THEN
               v_errmsg :='Failed to purge card since proxy is issued';
               RAISE exp_reject_loop_record;   
            END IF;
         EXCEPTION
            WHEN exp_reject_loop_record THEN
               RAISE;
            WHEN NO_DATA_FOUND THEN
               v_errmsg := 'No instant card found for proxy no ';
               RAISE exp_reject_loop_record;
            WHEN TOO_MANY_ROWS THEN
               v_errmsg := 'More than 1 card exist for this proxy';
               RAISE exp_reject_loop_record;   
            WHEN OTHERS THEN
               v_errmsg :='Error while getting issue proxy dtls -'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_loop_record;
         END;

         BEGIN
               SELECT cam_acct_bal, cam_ledger_bal
                 INTO v_acct_bal, v_ledger_bal
                 FROM cms_acct_mast
                WHERE cam_inst_code = prm_instcode
                  AND cam_acct_no = v_acct_no;

               IF v_acct_bal <> 0 AND v_ledger_bal <> 0 THEN
                  v_errmsg := 'Account balances need to be Zero';
                  RAISE exp_reject_loop_record;
               END IF;
         EXCEPTION
            WHEN exp_reject_loop_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_errmsg :='Error while getting account dtls -'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_loop_record;
         END;
         
         BEGIN
            sp_log_cardstat_chnge (prm_instcode,
                                   v_pan_code,
                                   v_pan_encr,
                                   'PRGE',             --auth_id
                                   '02',
                                   NULL,             --orgnl_rrn
                                   NULL,             --orgnl_trandate
                                   NULL,             --orgnl_trantime
                                   v_respcode,
                                   v_errmsg
                                  );

            IF v_respcode <> '00' AND v_errmsg <> 'OK' THEN
               v_errmsg :='Error from log_cardstat_chnge proc-'||v_errmsg;
               RAISE exp_reject_loop_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_loop_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_errmsg :='Error while logging system initiated card status change '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_loop_record;
         END;

         BEGIN
            UPDATE cms_appl_pan
               SET cap_card_stat = '9'
             WHERE cap_inst_code = prm_instcode 
               AND cap_pan_code = v_pan_code;

            IF SQL%ROWCOUNT = 0 THEN
               v_errmsg := 'Card not updated as purged';
               RAISE exp_reject_loop_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_loop_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_errmsg :='Error while updating card as purged -'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_loop_record;
         END;

         l_purge_succ_result.EXTEND;
         i := i + 1;
         l_purge_succ_result (i).q_proxy_no := v_proxy_no;
         l_purge_succ_result (i).q_process_msg := 'OK';
         commit;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            EXIT;
         WHEN exp_reject_loop_record THEN
            ROLLBACK TO v_savepoint;
            l_purge_fail_result.EXTEND;
            j:=j+1;
            l_purge_fail_result (j).q_proxy_no := v_proxy_no;
            l_purge_fail_result (j).q_process_msg := v_errmsg;
         WHEN OTHERS THEN
            v_errmsg :='Error while fetching data at posn -'|| SUBSTR (SQLERRM, 1, 200);
            ROLLBACK TO v_savepoint;            
            l_purge_fail_result.EXTEND;
            j:=j+1;
            l_purge_fail_result (j).q_proxy_no := v_proxy_no;
            l_purge_fail_result (j).q_process_msg := v_errmsg;
      END;
   END LOOP;

   UTL_FILE.fclose (v_file_handle);

   prm_succ_cnt := l_purge_succ_result.COUNT;
   prm_fail_cnt := l_purge_fail_result.COUNT;

   IF prm_succ_cnt > 0 THEN
      lp_write_log (SUBSTR (prm_file_name,1,INSTR (prm_file_name,'.csv',1,1)- 1)|| '_Sucess.txt',prm_dir, l_purge_succ_result, v_errmsg);
   END IF;

   IF prm_fail_cnt > 0 THEN
      lp_write_log (SUBSTR (prm_file_name,1,INSTR (prm_file_name,'.csv',1,1)- 1)|| '_Fail.txt', prm_dir,l_purge_fail_result, v_errmsg);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);

      IF UTL_FILE.is_open (v_file_handle) THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
END;
/
SHOW ERROR