CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ONLINE_ACCTDATA_FILE (PRM_SEQNO in number,P_errmsg OUT VARCHAR2) IS

l_file            UTL_FILE.file_type;
l_file_name       VARCHAR2 (100);
l_total_records   NUMBER   := 0;
v_errmsg          VARCHAR2 (4000);
v_header          varchar2(100);
v_footer          varchar2(100);
v_prod_code       varchar2(50);

CURSOR CUR_ACCT_DATA IS
SELECT cam_acct_no
       ||'|'||
       cam_curr_bran
       ||'|'||
       cam_type_code
       ||'|'||
       cam_stat_code
       ||'|'||
       TO_CHAR (cam_ins_date,'yyyymmdd hh24:mi:ss')
       ||'|'||
       cam_acct_bal
       ||'|'||
       cam_ledger_bal
       ||'|'||
        (SELECT TO_CHAR (MAX (add_ins_date),
                                'yyyymmdd hh24:mi:ss'
                               ) reopen_date
                  FROM VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
                 WHERE delivery_channel = '10'
                   AND txn_code = '32'
                   AND response_code = '00'
                   AND customer_acct_no = cam_acct_no
          )
        ||'|'||
          CASE
            WHEN cam_type_code = 2
            THEN cam_interest_amount
            ELSE 0.00
          END
         ||'|'||
          (SELECT TO_CHAR (MAX (cia_closing_date),'yyyymmdd hh24:mi:ss')
           FROM cms_inactivesavings_acct
           WHERE cam_acct_no = cia_savingsacct_no
           )||'|' rec
          FROM cms_acct_mast,cms_cust_acct,cms_appl_pan
          WHERE CAM_INST_CODE = cca_inst_code
            and CAM_ACCT_ID   = cca_acct_id
            and CCA_CUST_CODE = cap_cust_code
            and cap_pan_code in (select gethash(MCI_PAN_CODE) from migr_caf_info_entry where MCI_PROC_FLAG ='S' and MCI_MIGR_SEQNO =PRM_SEQNO)
            and cam_ins_user <> (select CUM_USER_CODE from cms_userdetl_mast where CUM_LGIN_CODE ='MIGR_USER');

BEGIN

    v_errmsg    := 'OK';

   BEGIN
        select substr(MFI_FILE_NAME,1,instr(MFI_FILE_NAME,'_ACCO')-1) into v_prod_code
        from migr_file_load_info
        where MFI_MIGR_SEQNO =PRM_SEQNO
        and   MFI_FILE_NAME like '%ACCO%'
        and   MFI_PROCESS_STATUS ='OK'
        and rownum <2;
        l_file_name := v_prod_code||'_ACCO_'||'0001.txt';
   EXCEPTION
      WHEN OTHERS
      THEN
         P_errmsg := ' Error occured during selecting file name '||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
         RETURN;
   END;

   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_ACCO_ONLINE',
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 32767
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         P_errmsg := ' Error occured during opening file '||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
         RETURN;
   END;

   FOR I IN CUR_ACCT_DATA
   LOOP
      l_total_records := l_total_records + 1;
   END LOOP;

   v_header := 'FH_'||v_prod_code||'_ACCT_'||lpad(l_total_records,8,0);
   v_footer := 'FF_'||v_prod_code||'_ACCT_'||lpad(l_total_records,8,0);
   utl_file.put (l_file, v_header);
   UTL_FILE.put (l_file, CHR (10));
   FOR I IN CUR_ACCT_DATA
   LOOP
        BEGIN
            utl_file.put (l_file, i.rec );
            UTL_FILE.put (l_file, CHR (10));
            UTL_FILE.fflush (l_file);

        EXCEPTION
           WHEN OTHERS
           THEN
              P_errmsg := ' Error Occured while writting file '||SUBSTR (SQLERRM, 1, 200);
              RETURN;
        END;
   END LOOP;
   utl_file.put (l_file, v_footer);
   UTL_FILE.fflush (l_file);
   UTL_FILE.fclose (l_file);

   P_errmsg := v_errmsg;

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
show error;