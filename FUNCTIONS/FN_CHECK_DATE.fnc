CREATE OR REPLACE FUNCTION VMSCMS.FN_CHECK_DATE (p_date IN VARCHAR2)
   RETURN DATE
/****************************************************
  * CREATED  by        : Ganesh
  * PURPOSE            : To validate the date format
                         Function will return the date 
                         if the input is in proper date 
                         format, else it will return NULL  
  * modified Date      : 15-OCT-12
  * modified reason    : To include the time part while 
                         converting to date format.
  * Reviewer           : Saravanan
  * Reviewed Date      : 12-OCT-12
  * Build Number       : CMS3.5.1_RI0019.1  

  * modified Date      : 04-Jul-2013
  * modified reason    : Included - between date and time
  * modified by        : Saravanakumar
  * Reviewed Date      : 
  * Build Number       : RI0024.3_B0002  
*****************************************************/
IS
   v_output_date   DATE;
   v_mesg          VARCHAR2 (150) := 'OK';
BEGIN
   SELECT TO_DATE (p_date, 'YYYYMMDD-HH24:MI:SS')--Maodified by saravanakumar on 04-Jul-2013
     INTO v_output_date
     FROM DUAL;

   RETURN  v_output_date;
EXCEPTION
   WHEN OTHERS
   THEN
      v_mesg := 'Error ' || SUBSTR (SQLERRM, 1, 100);
      RETURN NULL;
END;
/
show error;