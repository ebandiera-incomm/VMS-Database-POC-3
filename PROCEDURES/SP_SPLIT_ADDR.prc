CREATE OR REPLACE PROCEDURE VMSCMS.sp_split_addr( finaddr1 IN VARCHAR2,
        finaddr2 IN VARCHAR2,
        b24addr1 OUT VARCHAR2,
        b24addr2 OUT VARCHAR2,
        b24addr3 OUT VARCHAR2,
        errmsg  OUT VARCHAR2) IS

BEGIN
        errmsg := 'OK';
 b24addr1 := SUBSTR(finaddr1 , 1 , 30);
 b24addr2  := SUBSTR(finaddr1 , 31) || SUBSTR(finaddr2 , 1 , 15);
 b24addr3 :=  SUBSTR(finaddr2 , 16);
EXCEPTION
 WHEN OTHERS THEN
    errmsg := 'ERROR:'||SQLERRM;
END;
/


SHOW ERRORS