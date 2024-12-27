CREATE OR REPLACE FUNCTION VMSCMS.FN_CONV_CHAR_TO_DATE_PTLF
    ( dateinchar IN varchar2,
              timeinchar IN varchar2)
RETURN DATE
IS
dat   varchar2(8) ;
tim   varchar2(8) ;
dum  number;
chartim varchar2(8);
BEGIN
dat := dateinchar;
/*tim := timeinchar;
dum := substr(tim,-4);
dbms_output.put_line('substring result milli seconds--->'||dum);
dum := round(dum/1000);
dbms_output.put_line('Division by 1000 result--->'||dum);

chartim := substr(tim,1,4)||dum;
dbms_output.put_line('Substr result hrs and min--->'||chartim);

chartim := chartim||dum;
dbms_output.put_line('Character time--->'||chartim);*/
chartim := substr(timeinchar,1,6);

--return to_date(dat||chartim,'YYMMDDhh24:mi:ss');
return to_date(dat||chartim,'YYMMDDhh24miss');
--return to_date(dat||chartim,'YYMMDDhh-24-mi-ss');
END;
/


show error