CREATE OR REPLACE FUNCTION VMSCMS.FN_TRNAMT_CONV (trnamt IN varchar2) return varchar2
IS
retval varchar2(20) ;
BEGIN
    IF LENGTH(trnamt) < 12 THEN
       return(trnamt) ;
    ELSE
    SELECT DECODE(SUBSTR(trnamt,12),'{','0','A','1','B','2','C','3','D','4','E','5','F','6','G','7','H','8','I','9','0') INTO
           retval
	   FROM DUAL ;
       return (SUBSTR(trnamt,1,11)||retval) ;
    END IF ;
EXCEPTION
	WHEN OTHERS THEN
    return('0');
END;
/


show error