CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_GEN_DATA_LOAD (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
   v_errmsg          VARCHAR2 (300);
   v_sql_statement   VARCHAR2 (50);
   v_orcl_home       VARCHAR2 (100);
   v_file_path       VARCHAR2 (150);
   v_migr_seqno      number(5);         -- Added on 12-JUL-2013
BEGIN
   --v_sql_statement := 'Truncate table MIGR_DIR_LIST';

   --Sn Commented on 05_Aug_13
   --select mig_seq_no.nextval into v_migr_seqno from dual; -- Added on 12-JUL-2013
   --En Commented on 05_Aug_13
/*
   BEGIN
      SYS.DBMS_SYSTEM.get_env ('VMS_HOME', v_orcl_home);

      IF v_orcl_home IS NULL
      THEN
         prm_errmsg := 'VMS_HOME Not FOUND ';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while getting the oracle home path '
            || SUBSTR (SQLERRM, 1, 200);
   END;
*/
   BEGIN
      SELECT mdp_path
        INTO v_orcl_home
        FROM vmscms.migr_dir_path;

      IF TRIM (v_orcl_home) IS NULL
      THEN
         prm_errmsg := 'VMS_HOME Not FOUND ';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting the vms home path '
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

  --v_orcl_home := '/home/oracle/INCOMM_RELEASE';
-----------------------------------------------Sn Account Data Migration-----------------------------------------------------
   BEGIN
      DBMS_OUTPUT.put_line
           ('--------------------Start Account Data Migration---------------');
      v_orcl_home := TRIM (v_orcl_home);
      v_file_path := v_orcl_home || '/MIGRATION/FILES/ACCO';
      sp_get_dir_list (v_file_path);

      --sp_get_dir_list('/oracle/app/oracle/product/11.2.0/dbhome_1/MIGRATION/FILES/ACCO');

      --Pump all the files present in account directory for processing

      ----Sn to call account data loading-----
      FOR x IN (SELECT filename
                  FROM migr_dir_list)
      LOOP
         v_errmsg := 'OK';

        --Sn Added on 05_Aug_13
        BEGIN
        SELECT mfi_migr_seqno
          INTO v_migr_seqno
          FROM migr_file_load_info
         WHERE SUBSTR (mfi_file_name, 1, INSTR (mfi_file_name, '_', 1)) =
                                 SUBSTR (x.filename, 1, INSTR (x.filename, '_', 1))
           AND ROWNUM < 2;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              select mig_seq_no.nextval into v_migr_seqno from dual;
           WHEN OTHERS THEN
              prm_errmsg := 'Errro while checking acct data file Names for sequence id ' || SUBSTR (SQLERRM, 1, 100); --Error message modified by Pankaj S. on 25-Sep-2013
              RETURN;
        END;
        --En Added on 05_Aug_13

         BEGIN
            migr_acct_data_load (x.filename, v_errmsg,v_migr_seqno); --v_migr_seqno added on 12-JUL-2013
            DBMS_OUTPUT.put_line ('Filename-' || x.filename);
            DBMS_OUTPUT.put_line ('Prcoess Status-' || v_errmsg);
            sp_migr_file_load_info (x.filename, v_errmsg,v_migr_seqno); --v_migr_seqno added on 12-JUL-2013
         END;
      END LOOP;

      ----En to call account data loading-----
      DBMS_OUTPUT.put_line
              ('--------------------End Account Data Migration---------------');
   END;

   ----------------------------------------------------En Account Data Migration----------------------------------------------
   BEGIN
      truncate_tab_ebr ('MIGR_DIR_LIST');      ---Truncate account data files
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Errro while Truncating Account file Names '
            || SUBSTR (SQLERRM, 1, 100);
         RETURN;
   END;

   -------------------------------------------------Sn Customer Data Migration-----------------------------------------------
   BEGIN
      DBMS_OUTPUT.put_line
          ('--------------------Start Customer Data Migration---------------');
      v_file_path := v_orcl_home || '/MIGRATION/FILES/CUST';
      sp_get_dir_list (v_file_path);

      --sp_get_dir_list ('/oracle/app/oracle/product/11.2.0/dbhome_1/MIGRATION/FILES/CUST');

      --Pump all the files present in customer directory for processing

      ----Sn to call Customer data loading-----
      FOR x IN (SELECT filename
                  FROM migr_dir_list)
      LOOP
         v_errmsg := 'OK';

         --Sn Added on 05_Aug_13
        BEGIN
        SELECT mfi_migr_seqno
          INTO v_migr_seqno
          FROM migr_file_load_info
         WHERE SUBSTR (mfi_file_name, 1, INSTR (mfi_file_name, '_', 1)) =
                                 SUBSTR (x.filename, 1, INSTR (x.filename, '_', 1))
           AND ROWNUM < 2;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              select mig_seq_no.nextval into v_migr_seqno from dual;
           WHEN OTHERS THEN
              prm_errmsg := 'Errro while checking cust datat file Names for sequence id ' || SUBSTR (SQLERRM, 1, 100); --Error message modified by Pankaj S. on 25-Sep-2013
              RETURN;
        END;
        --En Added on 05_Aug_13

         BEGIN
            migr_cust_data_load (prm_instcode, x.filename, v_errmsg,v_migr_seqno);   --v_migr_seqno added on 12-JUL-2013
            DBMS_OUTPUT.put_line ('Filename-' || x.filename);
            DBMS_OUTPUT.put_line ('Prcoess Status-' || v_errmsg);
            sp_migr_file_load_info (x.filename, v_errmsg,v_migr_seqno); --v_migr_seqno added on 12-JUL-2013
         END;
      END LOOP;

      IF v_errmsg = 'OK'
      THEN
         BEGIN
            sp_merinv_order_check (prm_instcode, prm_lupduser, v_errmsg);
         END;
      END IF;

      ----Sn to call Customer data loading-----
      DBMS_OUTPUT.put_line
             ('--------------------End Customer Data Migration---------------');
   END;

   ------------------------------------------------En Customer Data Migration-----------------------------------------------------
   BEGIN
      truncate_tab_ebr ('MIGR_DIR_LIST');      ---Truncate customer data files
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Errro while Truncating Customer file Names'
            || SUBSTR (SQLERRM, 1, 100);
         RETURN;
   END;

      ------------------------------------------------------Sn Support Function Data Migration--------------------------------------------
    /*  BEGIN
         DBMS_OUTPUT.put_line
            ('--------------------Start Support function Data Migration---------------'
            );
         v_file_path := v_orcl_home || '/MIGRATION/FILES/SUPP';
         sp_get_dir_list (v_file_path);

         --sp_get_dir_list('/oracle/app/oracle/product/11.2.0/dbhome_1/MIGRATION/FILES/SUPP');

         --Pump all the files present in support function directory for processing

         ----Sn to call support function data loading-----
         FOR x IN (SELECT filename
                     FROM migr_dir_list)
         LOOP
            v_errmsg := 'OK';

            BEGIN
               migr_spprt_func_data_load (x.filename, v_errmsg);
               DBMS_OUTPUT.put_line ('Filename-' || x.filename);
               DBMS_OUTPUT.put_line ('Prcoess Status-' || v_errmsg);
               sp_migr_file_load_info (x.filename, v_errmsg);
            END;
         END LOOP;

         ----Sn to call support function data loading-----
         DBMS_OUTPUT.put_line
            ('--------------------End Support function Data Migration---------------'
            );
      END;

   -------------------------------------------------------En Support Function Data Migration---------------------------------------------
      BEGIN
         truncate_tab_ebr ('MIGR_DIR_LIST');
      ---Truncate support function data files
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Errro while Truncating Support Function file Names '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;
   */
      ------------------------------------------------------Sn Transaction log Data Migration-----------------------------------------------
   BEGIN
      DBMS_OUTPUT.put_line
         ('--------------------Start Transaction log Data Migration---------------'
         );
      v_file_path := v_orcl_home || '/MIGRATION/FILES/TRAN';
      sp_get_dir_list (v_file_path);

      --sp_get_dir_list('/oracle/app/oracle/product/11.2.0/dbhome_1/MIGRATION/FILES/TRAN');

      --Pump all the files present in Transaction directory for processing

      ----Sn to call Transaction  data loading-----
      FOR x IN (SELECT filename
                  FROM migr_dir_list)
      LOOP
         v_errmsg := 'OK';

          --Sn Added on 05_Aug_13
        BEGIN
        SELECT mfi_migr_seqno
          INTO v_migr_seqno
          FROM migr_file_load_info
         WHERE SUBSTR (mfi_file_name, 1, INSTR (mfi_file_name, '_', 1)) =
                                 SUBSTR (x.filename, 1, INSTR (x.filename, '_', 1))
           AND ROWNUM < 2;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              select mig_seq_no.nextval into v_migr_seqno from dual;
           WHEN OTHERS THEN
              prm_errmsg := 'Errro while checking txn data file Names for sequence id ' || SUBSTR (SQLERRM, 1, 100); --Error message modified by Pankaj S. on 25-Sep-2013
              RETURN;
        END;
        --En Added on 05_Aug_13

         BEGIN
            migr_txnlog_data_load (x.filename, v_errmsg,v_migr_seqno);   --v_migr_seqno added on 12-JUL-2013
            DBMS_OUTPUT.put_line ('Filename-' || x.filename);
            DBMS_OUTPUT.put_line ('Prcoess Status-' || v_errmsg);
            sp_migr_file_load_info (x.filename, v_errmsg,v_migr_seqno);   --v_migr_seqno added on 12-JUL-2013
         END;
      END LOOP;

      ----Sn to call Transaction  data loading-----
      DBMS_OUTPUT.put_line
         ('--------------------End Transaction log Data Migration---------------'
         );
   END;

--------------------------------------------------------En Transaction log Data Migration------------------------------------------------
   BEGIN
      truncate_tab_ebr ('MIGR_DIR_LIST'); ---Truncate table to clean all files
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Errro while Truncating Transaction file Names '  --Error message modified by Pankaj S. on 25-Sep-2013
            || SUBSTR (SQLERRM, 1, 100);
         RETURN;
   END;
   
   
   ------------------------------------------------------Sn Call log Data Migration-----------------------------------------------
   BEGIN
      DBMS_OUTPUT.put_line
         ('--------------------Start Call log Data Migration---------------'
         );
      v_file_path := v_orcl_home || '/MIGRATION/FILES/CALL';
      sp_get_dir_list (v_file_path);

      --sp_get_dir_list('/oracle/app/oracle/product/11.2.0/dbhome_1/MIGRATION/FILES/CALLLOG');

      --Pump all the files present in Transaction directory for processing

      ----Sn to call Transaction  data loading-----
      FOR x IN (SELECT filename
                  FROM migr_dir_list)
      LOOP
         v_errmsg := 'OK';

        BEGIN
        SELECT mfi_migr_seqno
          INTO v_migr_seqno
          FROM migr_file_load_info
         WHERE SUBSTR (mfi_file_name, 1, INSTR (mfi_file_name, '_', 1)) =
                                 SUBSTR (x.filename, 1, INSTR (x.filename, '_', 1))
           AND ROWNUM < 2;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              select mig_seq_no.nextval into v_migr_seqno from dual;
           WHEN OTHERS THEN
              prm_errmsg := 'Errro while checking Calllog data file Names for sequence id ' || SUBSTR (SQLERRM, 1, 100); 
              RETURN;
        END;

         BEGIN
            MIGR_CALLLOG_DATA_LOAD (x.filename, v_errmsg,v_migr_seqno);  
            DBMS_OUTPUT.put_line ('Filename-' || x.filename);
            DBMS_OUTPUT.put_line ('Prcoess Status-' || v_errmsg);
            sp_migr_file_load_info (x.filename, v_errmsg,v_migr_seqno);
         END;
      END LOOP;

      ----Sn to call Call log data loading-----
      DBMS_OUTPUT.put_line
         ('--------------------End Call log Data Migration---------------'
         );
   END;
       
--------------------------------------------------------En Call log Data Migration------------------------------------------------
   
   
   BEGIN
      truncate_tab_ebr ('MIGR_DIR_LIST'); ---Truncate table to clean all files
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Errro while Truncating Call Log file Names ' 
            || SUBSTR (SQLERRM, 1, 100);
         RETURN;
   END;   
   
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg :=
             'Main Exception While Data Loading ' || SUBSTR (SQLERRM, 1, 100);
      RETURN;
END;
/
show error;