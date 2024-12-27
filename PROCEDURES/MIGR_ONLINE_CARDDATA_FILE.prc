CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ONLINE_CARDDATA_FILE (PRM_SEQNO in number,P_errmsg OUT VARCHAR2) IS

l_file            UTL_FILE.file_type;
l_file_name       VARCHAR2 (100);
l_total_records   NUMBER  := 0;
v_errmsg          VARCHAR2 (4000);
v_header          varchar2(100);
v_footer          varchar2(100);
v_prod_code       varchar2(50);

CURSOR CUR_CARD_DATA IS
SELECT
TITLE||'|'||
FIRST_NAME||'|'||
LAST_NAME||'|'||
ID_NUMBER||'|'||
INITIAL_TOPUP_AMT||'|'||
BIRTH_DATE||'|'||
PERM_ADDR_LINE1||'|'||
PERM_ADDR_LINE2||'|'||
PERM_ADDR_CITY||'|'||
PERM_ADDR_STATE||'|'||
PERM_ADDR_CNTRY||'|'||
PERM_ADDR_ZIP||'|'||
PERM_ADDR_PHONE||'|'||
PERM_ADDR_MOBILE||'|'||
MAIL_ADDR_LINE1||'|'||
MAIL_ADDR_LINE2||'|'||
MAIL_ADDR_CITY||'|'||
MAIL_ADDR_STATE||'|'||
MAIL_ADDR_CNTRY||'|'||
MAIL_ADDR_ZIP||'|'||
MAIL_ADDR_PHONE||'|'||
MAIL_ADDR_MOBILE||'|'||
EMAIL_ADDRESS||'|'||
PRODUCT_CODE||'|'||
PROD_CATG_CODE||'|'||
BRANCH_ID||'|'||
MERCHANT_ID||'|'||
CARD_NUMBER||'|'||
CARD_STAT||'|'||
PROXY_NUMBER||'|'||
STARTER_CARD_FLAG||'|'||
ACTIVE_DATE_TIME||'|'||
EXPIRY_DATE||'|'||
PANGEN_DATE_TIME||'|'||
ATM_OFFLINE_LIMIT||'|'||
ATM_ONLINE_LIMIT||'|'||
POS_OFFLINE_LIMIT||'|'||
POS_ONLINE_LIMIT||'|'||
OFFLINE_AGGR_LIMIT||'|'||
ONLINE_AGGR_LIMIT||'|'||
MMPOS_ONLINE_LIMIT||'|'||
MMPOS_OFFLINE_LIMIT||'|'||
PIN_OFFSET||'|'||
NEXT_BILL_DATE||'|'||
NEXT_MON_BILL_DATE||'|'||
EMBOSS_DATE||'|'||
EMBOSS_FLAG||'|'||
PINGEN_DATE||'|'||
PIN_FLAG||'|'||
CCF_FILE_NAME||'|'||
KYC_FLAG||'|'||
TOTAL_ACCTS||'|'||
ACCT_NUMB1||'|'||
ACCT_NUMB2||'|'||
ACCT_NUMB3||'|'||
ACCT_NUMB4||'|'||
ACCT_NUMB5||'|'||
SAVING_ACCT||'|'||
SERIAL_NUMBER||'|'||
INITIAL_LOAD_FLAG||'|'||
SEC_QUES_ONE||'|'||
SEC_ANS_ONE||'|'||
SEC_QUES_TWO||'|'||
SEC_ANS_TWO||'|'||
SEC_QUES_THREE||'|'||
SEC_ANS_THREE||'|'||
CUST_USERNAME||'|'||
CUST_PASSWORD||'|'||
SMS_ALERT_FLAG||'|'||
EMAIL_ALERT_FLAG||'|'||
STORE_ID||'|'||
ID_TYPE||'|'||
ID_ISSUER||'|'||
ID_ISSUE_DATE||'|'||
ID_EXPRY_DATE||'|'  REC
FROM MIGR_ONLINE_CARDLOG;


BEGIN

    --l_file_name := 'MIYO_CUST_0001.txt';
    v_errmsg    := 'OK';

   BEGIN
        select substr(MFI_FILE_NAME,1,instr(MFI_FILE_NAME,'_CUST')-1) into v_prod_code
        from migr_file_load_info
        where MFI_MIGR_SEQNO =PRM_SEQNO
        and   MFI_FILE_NAME like '%CUST%'
        and   MFI_PROCESS_STATUS ='OK'
        and rownum <2;
        l_file_name := v_prod_code||'_CUST_'||'0001.txt';
   EXCEPTION
      WHEN OTHERS
      THEN
         P_errmsg := ' Error occured during file name select '||SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_CUST_ONLINE',
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 32767
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         P_errmsg := ' Error occured during file open'||SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   FOR I IN CUR_CARD_DATA
   LOOP
      l_total_records := l_total_records + 1;
   END LOOP;

   v_header := 'FH_'||v_prod_code||'_CUST_'||lpad(l_total_records,8,0);
   v_footer := 'FF_'||v_prod_code||'_CUST_'||lpad(l_total_records,8,0);
   utl_file.put (l_file, v_header);
   UTL_FILE.put (l_file, CHR (10));
   FOR I IN CUR_CARD_DATA
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