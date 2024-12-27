CREATE OR REPLACE FUNCTION VMSCMS.FN_CURR_TAB_SIZE(tab_name IN VARCHAR2)
RETURN NUMBER AS curr_size NUMBER(9) ;
row_size NUMBER(9);
rows NUMBER(9);
BEGIN
	curr_size := 0;
	row_size := 0;
	rows := 0;
	row_size := FN_TAB_ROW_SIZE(tab_name);
	execute immediate 'SELECT COUNT(1) INTO rows from '||tab_name;
	curr_size := row_size * rows;
 RETURN curr_size;
END ;
/


show error