CREATE OR REPLACE FUNCTION VMSCMS.FN_TAB_SIZE(tab_name IN VARCHAR2,rows IN NUMBER)
RETURN NUMBER AS tab_size NUMBER(9) ;
row_size NUMBER(9);
BEGIN
	tab_size := 0;
	row_size := 0;
	row_size := FN_TAB_ROW_SIZE(tab_name);
	tab_size := row_size * rows;
 RETURN tab_size;
END ;
/


show error