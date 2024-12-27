CREATE OR REPLACE PROCEDURE VMSCMS.tokenise(	 in_string		IN	VARCHAR2	,
								 sep			IN	CHAR		,
								 tabout		OUT	 gen_cms_pack.plsql_tab_single_column,
								 errmsg		OUT	 VARCHAR2)

AS

--sep		char(1):= '^';

TT varchar2(100);
string_in 		VARCHAR2(100) ;
v_len		NUMBER;
dum_string	VARCHAR2(100)	;
sep_count	NUMBER := 0;
sep_instance 	NUMBER;
tabvar		gen_cms_pack.plsql_tab_single_column ;---variable of plsqltable type defined in gen_cms_pack
BEGIN
tabvar.DELETE;
dum_string := string_in;
string_in		:= in_string;

SELECT 	LENGTH(string_in)
INTO	v_len
FROM 	dual;
--dbms_output.put_line('string length-->'||v_len);

FOR x IN 1..v_len
LOOP
	SELECT 	INSTR(string_in,sep)
	INTO	sep_instance
	FROM	dual;
	--dbms_output.put_line('instance of '||sep||' is --->'||sep_instance);
		IF sep_instance != 0 THEN
			sep_count := sep_count+1;
			--dbms_output.put_line('String status--->'||string_in);
			tabvar(sep_count) := SUBSTR(string_in,1,sep_instance-1);
			--dbms_output.put_line('---'||dum_string||'---');
			string_in := SUBSTR(string_in,sep_instance+1);
		END IF;
END LOOP;
tabvar(sep_count+1) := string_in;
--dbms_output.put_line('---'||string_in||'---');
--dbms_output.put_line('tabvar(sep_count+1)'||tabvar(sep_count+1)||'---');
/*for x in 1..sep_count
string_out := substr(dum_string,x)
loop
select
end loop;*/
--dbms_output.put_line('count in plsql table--->'||tabvar.count);

/*FOR x in 1..sep_count+1
LOOP
dbms_output.put_line(tabvar(x));
END LOOP;*/

tabout := tabvar;

errmsg := 'OK';
EXCEPTION
	WHEN OTHERS THEN
	errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;
/
SHOW ERROR

