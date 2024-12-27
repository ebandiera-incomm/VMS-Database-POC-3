create or replace PROCEDURE vmscms.TITANIUM_TXNLOG_UPD(
    L_DATE_COUNTER IN NUMBER,
    P_PROD_CODE_IN IN VARCHAR,
    P_PID_IN       IN VARCHAR )
IS
  l_num_rec_updated NUMBER :=0;
  l_start_time      NUMBER;
  L_END_TIME        NUMBER;
  L_TIMETAKEN       NUMBER;
  --18674690 records
  -- milisecs
BEGIN
  EXECUTE IMMEDIATE 'alter session set nls_date_format=''YYYY-MM-DD HH24:MI:SS''';
  L_START_TIME := dbms_utility.get_time;
  FOR d IN 1..L_DATE_COUNTER
  LOOP
    FOR I IN
    (SELECT rowid
    FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO IS NOT NULL
    AND add_ins_date BETWEEN TO_CHAR(SYSDATE-D,'YYYY-MM-DD')
      || '00:00:00'
    AND TO_CHAR(SYSDATE-(D-1),'YYYY-MM-DD')
      || '23:59:59'
    AND PRODUCTID = P_PROD_CODE_IN
    )
    LOOP
      UPDATE TRANSACTIONLOG SET partner_id = P_PID_IN WHERE rowid=i.rowid;
      COMMIT;
    END LOOP;
  END LOOP;
  L_END_TIME  := DBMS_UTILITY.GET_TIME;
  L_TIMETAKEN := (L_END_TIME - L_START_TIME);
  dbms_output.put_line('Elapsed Time: ' || l_timetaken || ' milisecs');
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
END;
/
show error	