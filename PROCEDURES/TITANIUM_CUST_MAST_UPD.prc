create or replace PROCEDURE  vmscms.TITANIUM_CUST_MAST_UPD(
    P_PROD_CODE_IN IN VARCHAR,
    P_PID_IN   IN VARCHAR )
IS
    L_ERR_MSG VARCHAR2(500);
    l_start_time   NUMBER;
    L_END_TIME     NUMBER;
    L_TIMETAKEN    NUMBER;
    --348505 records
    --18318 milisecs
BEGIN
L_START_TIME := dbms_utility.get_time;
  FOR I_IDX IN
    (
    SELECT CAP_CUST_CODE
    FROM CMS_APPL_PAN
    WHERE CAP_PROD_CODE = P_PROD_CODE_IN
    AND CAP_INST_CODE = 1
    )
    LOOP
        BEGIN
          UPDATE CMS_CUST_MAST
          SET CCM_PARTNER_ID = P_PID_IN
          WHERE CCM_CUST_CODE=i_idx.CAP_CUST_CODE
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
  dbms_output.put_line(l_err_msg);
END;
/
show error