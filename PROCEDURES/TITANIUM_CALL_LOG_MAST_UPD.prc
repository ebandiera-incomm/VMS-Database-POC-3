create or replace PROCEDURE  vmscms.TITANIUM_CALL_LOG_MAST_UPD(
    P_PROD_CODE_IN IN VARCHAR,
    P_PID_IN   IN VARCHAR,
    P_CALLID_START_IN IN NUMBER,
    P_CALLID_END_IN IN NUMBER)
IS
    L_ERR_MSG VARCHAR2(500);
    l_start_time   NUMBER;
    L_END_TIME     NUMBER;
    L_TIMETAKEN    NUMBER;
    --214366 records
    --6108 milisec
    --5582497 max call id
    --3862478 min call id
BEGIN
L_START_TIME := dbms_utility.get_time;
  FOR I_IDX IN
    (
      SELECT CCM_CALL_ID
      FROM CMS_CALLLOG_MAST
      WHERE  CCM_CALL_ID BETWEEN P_CALLID_START_IN  AND P_CALLID_END_IN
      AND CCM_PAN_CODE IN (
                            SELECT CAP_PAN_CODE 
                            FROM CMS_APPL_PAN
                            WHERE CAP_PROD_CODE = P_PROD_CODE_IN
                            AND CAP_INST_CODE = 1)
      AND CCM_PARTNER_ID = '1'
    )
    LOOP
        BEGIN
          UPDATE CMS_CALLLOG_MAST
          SET CCM_PARTNER_ID = P_PID_IN
          WHERE CCM_CALL_ID = I_IDX.CCM_CALL_ID
          AND CCM_INST_CODE  =1;
        EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
          NULL;
        END;
        COMMIT;
     
    END LOOP;
L_END_TIME := DBMS_UTILITY.GET_TIME; 
L_TIMETAKEN := (L_END_TIME - L_START_TIME);
dbms_output.put_line('Elapsed Time: ' || l_timetaken || ' milisecs');
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  l_err_msg := 'Error from main'||SUBSTR(SQLERRM,1,200);
  DBMS_OUTPUT.PUT_LINE(L_ERR_MSG);
END;
/
show error
