CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACQ_DOMINT_DET(FRDT IN VARCHAR2,TODT IN VARCHAR2,ERRMSG OUT VARCHAR2) AS
FILE_HANDLE UTL_FILE.FILE_TYPE ;
WRT_BUFF VARCHAR2(1000) ;
/*CURSOR C1 IS
SELECT  COUNT(1) CNT , sum(to_number(rmr_ilf_amt)/100  TRAN_AMT
FROM REC_MDS_RECON
WHERE
RMR_TRAN_DAT BETWEEN  FRDT AND TODT  AND
RMR_PROCESSOR = 'A'  AND
RMR_INTL_FLAG = 'INT' ;*/
 D_CNT NUMBER(30) ;
 I_CNT NUMBER(30) ;
 D_TRAN_AMT NUMBER(35) ;
 I_TRAN_AMT NUMBER(35) ;
 fname VARCHAR2(100) ;
  BEGIN
 ERRMSG := 'OK' ;
    BEGIN
        --fname := 'CARD_NOT_USED_'||TO_CHAR(NODYS)||'DAYS' ;
       FILE_HANDLE := UTL_FILE.FOPEN('D:\SBI_REP','CARD_USED_ON_ATM','w') ;
    EXCEPTION
    WHEN OTHERS THEN
    ERRMSG := 'ERROR OPENING FILE'||SQLERRM ;
    END ;
    BEGIN
    --*****************************************************HEADING SECTION*****************************************
     WRT_BUFF := RPAD(' ',25,' ')||'STATE BANK OF INDIA' ;
     UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
      WRT_BUFF := RPAD(' ',25,' ')||'===================' ;
     UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
         WRT_BUFF := RPAD(' ',15,' ') ;
      UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
     WRT_BUFF := RPAD(' ',15,' ')||'MASTER CARD RECONCILED  ATM  ACQUIRER DOMESTIC AND INTERNATIONAL TRANSCATION DETAILS THE PERIOD OF '||TO_CHAR(TO_DATE(FRDT,'yymmdd'),'DD_MON_YYYY')||' to '||TO_CHAR(TO_DATE(TODT,'yymmdd'),'DD_MON_YYYY') ;
     UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
     WRT_BUFF := RPAD(' ',15,' ')||'REPORT RUN DATE : '||TO_CHAR(SYSDATE,'FM DD-MONTH-YYYY FM HH:MI:SS AM') ;
     UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
      WRT_BUFF := RPAD(' ',15,' ') ;
      UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
    --*****************************************************HEADING SECTION*****************************************
    --*****************************************************FIELD HEADING*******************************************
 /*  WRT_BUFF := RPAD('=',30,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
   WRT_BUFF := RPAD(' ',2,' ')||RPAD('CARD NUMBER',25,' ');
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  WRT_BUFF := RPAD('=',30,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ; */
    --*****************************************************FIELD HEADING*******************************************
--*******************************************************DATA SEGMENT*************************************************
--***************************************QUERY PART************************************
--International Acquirer
SELECT  COUNT(1)  , SUM(TO_NUMBER(rmr_ilf_amt)/100) INTO I_CNT , I_TRAN_AMT
FROM REC_MDS_RECON
WHERE
RMR_TRAN_DAT BETWEEN  FRDT AND TODT  AND
RMR_PROCESSOR = 'A'  AND
--RMR_INTL_FLAG = 'INT' ;
TRIM(RMR_PROD_CODE) IN ('MC1','MS1','CI1') ;
--Domestic  Acquirer
SELECT  COUNT(1)  , SUM(TO_NUMBER(rmr_ilf_amt)/100) INTO D_CNT , D_TRAN_AMT
FROM REC_MDS_RECON
WHERE
RMR_TRAN_DAT BETWEEN  FRDT AND TODT  AND
RMR_PROCESSOR = 'A'  AND
--RMR_INTL_FLAG = 'DOM' ;
TRIM(RMR_PROD_CODE) IN ('MC2','MS2','CI2') ;
--***************************************QUERY PART************************************
--***************************************HEADING DOMESTIC PART************************************
   WRT_BUFF := RPAD(' ',25,' ')||RPAD('DOMESTIC ACQUIRER TRANSACTION DETAILS',25,' ');
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  WRT_BUFF := RPAD('-',55,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
   WRT_BUFF := RPAD(' ',2,' ')||RPAD('TRANSCATION COUNT',25,' ')||RPAD('TRANSACTION AMOUNT',25,' ');
   UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  WRT_BUFF := RPAD('=',55,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  --***************************************HEADING DOMESTIC PART************************************
 --*****************************************DATA SEGMENT - DOMESTIC******************************
       WRT_BUFF :=  RPAD(' ',2,' ')||RPAD(TO_CHAR(D_CNT),25,' ')||RPAD(TO_CHAR(D_TRAN_AMT),25,' ');
      -- DBMS_OUTPUT.PUT_LINE('CHK :1 : B4 WRITE'||WRT_BUFF) ;
	UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
	   --DBMS_OUTPUT.PUT_LINE('CHK :1 : AFTER WRITE') ;
       WRT_BUFF := RPAD('-',55,'-') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
--*****************************************DATA SEGMENT - DOMESTIC******************************
  --***************************************HEADING DOMESTIC PART************************************
   WRT_BUFF := RPAD(' ',25,' ')||RPAD('INTERNATIONAL ACQUIRER TRANSACTION DETAILS',25,' ');
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  WRT_BUFF := RPAD('-',55,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
   WRT_BUFF := RPAD(' ',2,' ')||RPAD('TRANSCATION COUNT',25,' ')||RPAD('TRANSACTION AMOUNT',25,' ');
   UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  WRT_BUFF := RPAD('=',55,'=') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
  --***************************************HEADING DOMESTIC PART************************************
  --*****************************************DATA SEGMENT - INTERNATIONAL******************************
       WRT_BUFF :=  RPAD(' ',2,' ')||RPAD(TO_CHAR(I_CNT),25,' ')||RPAD(TO_CHAR(I_TRAN_AMT),25,' ');
      -- DBMS_OUTPUT.PUT_LINE('CHK :1 : B4 WRITE'||WRT_BUFF) ;
	UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
	   --DBMS_OUTPUT.PUT_LINE('CHK :1 : AFTER WRITE') ;
       WRT_BUFF := RPAD('-',55,'-') ;
  UTL_FILE.PUT_LINE(FILE_HANDLE,WRT_BUFF) ;
--*****************************************DATA SEGMENT - INTERNATIONAL******************************
        UTL_FILE.FFLUSH(FILE_HANDLE) ;
   EXCEPTION
   WHEN OTHERS THEN
   ERRMSG := 'ERROR IN WRITING FILE'||SQLERRM ;
   UTL_FILE.FCLOSE(FILE_HANDLE) ;
   END ;
    UTL_FILE.FCLOSE(FILE_HANDLE) ;
  EXCEPTION
  WHEN OTHERS THEN
   ERRMSG := 'ERROR :'||SQLERRM ;
  END ;
/


