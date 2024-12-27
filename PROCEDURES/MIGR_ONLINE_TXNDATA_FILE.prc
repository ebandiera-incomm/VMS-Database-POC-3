CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ONLINE_TXNDATA_FILE (PRM_SEQNO in number,P_errmsg OUT VARCHAR2) IS

l_file            UTL_FILE.file_type;
l_file_name       VARCHAR2 (100);
l_total_records   NUMBER   := 0;
v_errmsg          VARCHAR2 (4000);
v_header		  varchar2(100);
v_footer          varchar2(100);
v_prod_code       varchar2(50);

CURSOR CUR_TXN_DATA IS
SELECT
MSGTYPE||'|'||
RRN||'|'||
DELIVERY_CHANNEL||'|'||
TERMINAL_ID||'|'||
TXN_CODE||'|'||
TXN_TYPE||'|'||
TXN_MODE||'|'||
RESPONSE_CODE||'|'||
BUSINESS_DATE||'|'||
BUSINESS_TIME||'|'||
CARD_NUMBER||'|'||
BENEFICIARY_CARD_NUMBER||'|'||
TOTAL_AMOUNT||'|'||
MERCHANT_NAME||'|'||
MERCHANT_CITY||'|'||
MCCODE||'|'||
CURRENCYCODE||'|'||
ATM_NAME_LOCATION||'|'||
AMOUNT||'|'||
PREAUTH_DATE_TIME||'|'||
SYSTEM_TRACE_AUDIT_NO||'|'||
TRANFEE_AMT||'|'||
SERVICETAX_AMT||'|'||
TRAN_REVERSE_FLAG||'|'||
ACCOUNT_NUMBER||'|'||
ORIGINAL_CARD_NUMBER||'|'||
ORGNL_RRN||'|'||
ORGNL_BUSINESS_DATE||'|'||
ORGNL_BUSINESS_TIME||'|'||
ORGNL_TERMINAL_ID||'|'||
REVERSAL_CODE||'|'||
PROXY_NUMBER||'|'||
ACCT_BALANCE||'|'||
LEDGER_BALANCE||'|'||
ACHFILENAME||'|'||
RETURNACHFILENAME||'|'||
ODFI||'|'||
RDFI||'|'||
SECCODES||'|'||
IMPDATE||'|'||
PROCESSDATE||'|'||
EFFECTIVEDATE||'|'||
AUTH_ID||'|'||
BEFORE_TXN_LEDGER_BAL||'|'||
BEFORE_TXN_ACCT_BAL||'|'||
ACHTRANTYPE_ID||'|'||
INCOMING_CRFILEID||'|'||
INDIDNUM||'|'||
INDNAME||'|'||
ACH_ID||'|'||
IPADDRESS||'|'||
ANI||'|'||
DNI||'|'||
CARDSTATUS||'|'||
WAIVER_AMT||'|'||
INTERNATIONAL_INDICATOR||'|'||
CR_DR_FLAG||'|'||
INCREMENTAL_INDICATOR||'|'||
PARTIAL_AUTH_INDICATOR||'|'||
COMPLETION_COUNT||'|'||
LAST_COMPLETION_INDICATOR||'|'||
PREAUTH_EXPIRY_PERIOD||'|'||
MERCHANT_FLR_LIMIT_IND||'|'||
ADDRESS_VERIFICATION_INDICATOR||'|'||
NARRATION||'|'||
DISPUTE_FLAG||'|'||
REASON_CODE||'|'||
REMARK||'|'||
DISPUTE_REASON||'|'||
DISPUTE_REMARK||'|'||
MATCH_COMPLETION_FLAG||'|'||
C2C_TXN_STATUS||'|'||
POSTED_DATE||'|'||
BEF_TXN_TOPUP_CARD_LEDGER_BAL||'|'||
BEF_TXN_TOPUP_CARD_ACCT_BAL||'|'||
TOPUP_CARD_LEDGER_BAL||'|'||
TOPUP_CARD_ACCT_BAL||'|'||
PREAUTH_EXPIRY_DATE||'|'||
TOPUP_ACCT_NO||'|'||
PREAUTH_VALID_FLAG||'|'||
PREAUTH_EXPIRY_FLAG||'|'||
PREAUTH_COMPLETION_FLAG||'|'||
PENDING_HOLD_AMOUNT||'|'||
PREAUTH_TRANSACTION_FLAG||'|'||
ORGNL_DEL_CHNL||'|'||
ORGNL_TXN_CODE||'|'||
REVERSE_FEE_AMT||'|'
--Sn Modified for Galileo changes
||  
TIME_STAMP||'|'||
' |' || ' |' || ' |' || ' |' ||
' |' || ' |' || ' |' || ' |' ||
' |' || ' |' || ' |' || ' |' ||
' |' || ' |' || ' |' || ' |' ||
' |' || ' |'  REC
--En Modified for Galileo changes
FROM MIGR_ONLINE_TXNLOG;



BEGIN

    --l_file_name := 'MIYO_TRAN_0001.txt';
    v_errmsg    := 'OK';

   BEGIN
		--SELECT SUBSTR(MFI_FILE_NAME,1,INSTR(MFI_FILE_NAME,'_TRAN')-1) INTO V_PROD_CODE  --Modified for Galileo changes
    select substr(MFI_FILE_NAME,1,instr(MFI_FILE_NAME,'_')-1) into v_prod_code
		from migr_file_load_info
		WHERE MFI_MIGR_SEQNO =PRM_SEQNO
		--and   MFI_FILE_NAME like '%TRAN%'
		and   MFI_PROCESS_STATUS ='OK'
		and rownum <2;
		l_file_name := v_prod_code||'_TRAN_'||'0001.txt';
   EXCEPTION
      WHEN OTHERS
      THEN
         P_errmsg := ' Error occured during file name select '||SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      l_file :=
         UTL_FILE.fopen (LOCATION          => 'DIR_REP_TRAN_ONLINE',
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

   FOR I IN cur_txn_data
   LOOP
      l_total_records := l_total_records + 1;
   END LOOP;

   v_header := 'FH_'||v_prod_code||'_TRAN_'||lpad(l_total_records,8,0);
   v_footer := 'FF_'||v_prod_code||'_TRAN_'||lpad(l_total_records,8,0);
   utl_file.put (l_file, v_header);
   UTL_FILE.put (l_file, CHR (10));

   FOR I IN cur_txn_data
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
    P_errmsg := 'MAIN EXCEPTION -' ||SUBSTR (SQLERRM, 1, 200);
    
      IF UTL_FILE.is_open (l_file)
      THEN
         UTL_FILE.fclose (l_file);
      END IF;

END;
/
SHOW ERROR;