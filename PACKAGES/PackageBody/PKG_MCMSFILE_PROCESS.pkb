CREATE OR REPLACE PACKAGE BODY vmscms.pkg_mcmsfile_process
IS
    /**************************************************************************
   * Created Date              : 18-Nov-2014
   * Created By                : Pankaj S.
   * Purpose                   : MCMS Return File
   * Release Number            :
   **************************************************************************/
   PROCEDURE sp_mcmsfile_process (
      prm_instcode   IN       NUMBER,
      prm_src_dir    IN       VARCHAR2,
      prm_dest_dir   IN       VARCHAR2,
      prm_errmsg     OUT      VARCHAR2
   )
   AS
      v_file_handle            UTL_FILE.file_type;
      v_filebuffer             VARCHAR2 (32767);
      v_errmsg                 VARCHAR2 (500);
      exp_reject_loop_record   EXCEPTION;
      v_cust_id                cms_cust_mast.ccm_cust_id%TYPE;
      v_acct_no                cms_acct_mast.cam_acct_no%TYPE;
      v_optouttime             VARCHAR2 (50);
      v_savepoint              NUMBER;
      v_frmdir_path            VARCHAR2 (1000);

      PROCEDURE lp_move_files (
         l_src_dir    IN   VARCHAR2,
         l_dest_dir   IN   VARCHAR2,
         l_filename   IN   VARCHAR2
      )
      AS
      BEGIN
         UTL_FILE.fcopy (l_src_dir, l_filename, l_dest_dir, l_filename);
         UTL_FILE.fremove (l_src_dir, l_filename);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   BEGIN
      prm_errmsg := 'OK';

      BEGIN
         SELECT TRIM (directory_path)
           INTO v_frmdir_path
           FROM all_directories
          WHERE directory_name = UPPER (prm_src_dir);

         IF v_frmdir_path IS NULL THEN
            prm_errmsg := 'Oracle directory Not Found-';
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error while getting the Oracle directory path-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         sp_get_mcmsfile_list (v_frmdir_path);
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error while getting file lists-' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      IF UTL_FILE.is_open (v_file_handle) THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      FOR i IN (SELECT cmf_file_name FROM cms_mcmsret_filename)
      LOOP
         BEGIN
            v_file_handle :=UTL_FILE.fopen (prm_src_dir, i.cmf_file_name, 'R', 32767);
         EXCEPTION
            WHEN OTHERS THEN
               prm_errmsg :='Error occured during file open-'|| SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         LOOP
            v_savepoint := v_savepoint + 1;
            SAVEPOINT v_savepoint;

            BEGIN
               v_errmsg := 'OK';
               v_cust_id := NULL;
               v_acct_no := NULL;
               v_optouttime := NULL;
               UTL_FILE.get_line (v_file_handle, v_filebuffer);
               v_acct_no := TRIM (SUBSTR (v_filebuffer,1,INSTR (v_filebuffer, '|', 1, 1) - 1));
               v_optouttime :=TRIM (SUBSTR (v_filebuffer,INSTR (v_filebuffer, '|', 1, 3) + 1));

               BEGIN
                  SELECT ccm_cust_id
                    INTO v_cust_id
                    FROM cms_cust_acct, cms_acct_mast, cms_cust_mast
                   WHERE cca_inst_code = cam_inst_code
                     AND cca_acct_id = cam_acct_id
                     AND ccm_inst_code = cca_inst_code
                     AND ccm_cust_code = cca_cust_code
                     AND cam_inst_code = prm_instcode
                     AND cam_acct_no = v_acct_no;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_errmsg :='No customer found in CMS for account-' || v_acct_no;
                     RAISE exp_reject_loop_record;
                  WHEN OTHERS THEN
                     v_errmsg :='Error while getting account dtls -'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_loop_record;
               END;

               BEGIN
                  UPDATE cms_optin_status
                     SET cos_markmsg_optinflag = 0,
                         cos_markmsg_optouttime =TO_TIMESTAMP (v_optouttime,'yyyy-mm-dd hh24:mi:ss.ff3')
                   WHERE cos_inst_code = prm_instcode
                     AND cos_cust_id = v_cust_id;

                  IF SQL%ROWCOUNT = 0 THEN
                     BEGIN
                        INSERT INTO cms_optin_status
                                    (cos_inst_code, cos_cust_id,
                                     cos_markmsg_optinflag,
                                     cos_markmsg_optouttime
                                    )
                             VALUES (prm_instcode, v_cust_id,
                                     0,
                                     TO_TIMESTAMP (v_optouttime,'yyyy-mm-dd hh24:mi:ss.ff3')
                                    );
                     EXCEPTION
                        WHEN OTHERS THEN
                           v_errmsg :='Error while inserting into CMS_PTIN_STATUS -'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_loop_record;
                     END;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_loop_record THEN
                     RAISE;
                  WHEN OTHERS THEN
                     v_errmsg :='Error while updating into CMS_PTIN_STATUS -'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_loop_record;
               END;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  EXIT;
               WHEN exp_reject_loop_record THEN
                  ROLLBACK TO v_savepoint;
                  sp_log_mcmserr (i.cmf_file_name,v_acct_no, v_errmsg);
               WHEN OTHERS THEN
                  v_errmsg :='Error while processing data-'|| SUBSTR (SQLERRM, 1, 200);
                  ROLLBACK TO v_savepoint;
                  sp_log_mcmserr (i.cmf_file_name,v_acct_no, v_errmsg);
            END;
         END LOOP;

         UTL_FILE.fclose (v_file_handle);
         lp_move_files (prm_src_dir, prm_dest_dir, i.cmf_file_name);        
      END LOOP;
	    commit; 
   EXCEPTION
      WHEN OTHERS THEN
         prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);

         IF UTL_FILE.is_open (v_file_handle) THEN
            UTL_FILE.fclose (v_file_handle);
         END IF;
   END;

   PROCEDURE sp_log_mcmserr (prm_acctno IN VARCHAR2, prm_filename IN VARCHAR2, prm_errmsg IN VARCHAR2)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO cms_mcmsret_errlog
           VALUES (prm_filename,prm_acctno, prm_errmsg);

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   PROCEDURE sp_get_mcmsfile_list (prm_directory IN VARCHAR2)
   AS
      LANGUAGE JAVA
      NAME 'McmsFileList.getList( java.lang.String )';
END;
/
SHOW ERROR