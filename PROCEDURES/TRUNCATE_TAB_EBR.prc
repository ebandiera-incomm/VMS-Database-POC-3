CREATE OR REPLACE PROCEDURE VMSCMS.TRUNCATE_TAB_EBR (
    tab_name IN VARCHAR2
)
---------------------------------------------------------------------------------
-- Name        : truncate_tab_ebr (Public procedure)
-- Description : This procdure will remove data from the EBR tables
-- Notes       : none
-- Parameters  : INPUT
--              - Table Name
--             : OUTPUT
--                 None
-- Example: 1. EXECUTE truncate_tab_ebr ('CMS_ACCT_GIFT');
-- Returns     : none
-- Created On  : 08/20/2021
-- Created By  : Pavel Yankouski
---------------------------------------------------------------------------------
 AS
    ob_type                 VARCHAR2(20);
    e_no_data_found         EXCEPTION;
BEGIN
    SELECT
        object_type
    INTO ob_type
    FROM
        user_objects 
    WHERE
        object_name = upper(tab_name)
        AND ROWNUM <= 1;

    IF ob_type = 'TABLE' THEN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || upper(tab_name);
        dbms_output.put_line('TABLE '
                             || upper(tab_name)
                             || ' IS EMPTY');
    END IF;

    IF ob_type = 'VIEW' THEN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE '
                          || upper(tab_name)
                          || '_EBR';
        dbms_output.put_line('TABLE '|| upper(tab_name)
                             || '_EBR IS EMPTY');
 end IF;
 EXCEPTION
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('Object does not exist - '||sqlerrm);
            
        WHEN OTHERS THEN
            dbms_output.put_line('Unexpected error - '||sqlerrm);    
            RAISE;
END;
/

SHOW ERRORS;