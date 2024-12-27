CREATE OR REPLACE PROCEDURE VMSCMS.Prc_Ins (p_arr IN Pack_Gen_Veriable.TYPE_CUST_REC_TAB ,errmsg OUT VARCHAR2)
IS
BEGIN
errmsg:='OK';
FOR i IN p_arr.FIRST..p_arr.LAST
LOOP
errmsg := errmsg || p_arr(i);
END LOOP;
EXCEPTION WHEN OTHERS THEN
errmsg := 'EXCP - ' || SQLERRM; 
END;
/


