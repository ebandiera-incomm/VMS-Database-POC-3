create or replace PROCEDURE  vmscms.TITANIUM_CALL_LOG_DETAILS_UPD(
    P_PROD_CODE_IN IN VARCHAR,
    P_PID_IN   IN VARCHAR )
IS
    L_ERR_MSG VARCHAR2(500);
    l_start_time   NUMBER;
    L_END_TIME     NUMBER;
    L_TIMETAKEN    NUMBER;
    --531292 records
    --14645 milisec
BEGIN
L_START_TIME := dbms_utility.get_time;
  FOR I_IDX IN
    (
      SELECT CAP_PAN_CODE 
      FROM CMS_APPL_PAN
      WHERE CAP_PROD_CODE = P_PROD_CODE_IN
      AND CAP_INST_CODE = 1
    )
    LOOP
        BEGIN
          UPDATE CMS_CALLLOG_DETAILS
          SET CCD_PARTNER_ID = P_PID_IN
          WHERE CCD_PAN_CODE = I_IDX.CAP_PAN_CODE
          AND CCD_INST_CODE  = 1 ;
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