CREATE OR REPLACE FUNCTION VMSCMS.SP_SAPERATE_DAYS(IN_string VARCHAR2) RETURN VARCHAR2 
AS v_week_days VARCHAR2(100);

v_len  NUMBER(10) := 0;
tabout gen_cms_pack.plsql_tab_single_column;
errmsg VARCHAR2(100);
v_days  VARCHAR2(100);
user_name VARCHAR2(100);

BEGIN
	SELECT (LENGTH(IN_string) - LENGTH(REPLACE(IN_string,'|',NULL)))/LENGTH('|')  INTO v_len
   	FROM DUAL;

BEGIN
	 tokenise(IN_string,'|',tabout, errmsg);
END;

FOR x in 1..v_len+1
LOOP

--v_dayes_id := tabout(x);

SELECT DECODE(tabout(x),0,'ALL',1,'SUNDAY',2,'MONDAY',3,'TUESDAY',4,'WEDNESDAY',5,'THURSDAY',6,'FRIDAY',7,'SUNDAY') INTO v_days FROM DUAL;

v_week_days := v_week_days||'|'||v_days; 

END LOOP;

RETURN v_week_days;
END;
/


SHOW ERRORS