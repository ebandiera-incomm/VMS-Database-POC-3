CREATE OR REPLACE FUNCTION VMSCMS.FN_HEX2DEC(P_HEXVAL IN CHAR) RETURN NUMBER IS

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
      * PURPOSE          :  For GET THE DECIMAL VALUE FROM HEXA
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  20-Apr-2012
      * Build Number     :  CMS3.5.1_RI0008_B00022
  *************************************************/
  V_I                 NUMBER;
  V_DIGITS            NUMBER;
  V_RESULT            NUMBER := 0;
  V_CURRENT_DIGIT     CHAR(1);
  V_CURRENT_DIGIT_DEC NUMBER;
BEGIN
  V_DIGITS := LENGTH(P_HEXVAL);
  FOR I IN 1 .. V_DIGITS LOOP
    V_CURRENT_DIGIT := SUBSTR(P_HEXVAL, I, 1);
    IF V_CURRENT_DIGIT IN ('A', 'B', 'C', 'D', 'E', 'F') THEN
	 V_CURRENT_DIGIT_DEC := ASCII(V_CURRENT_DIGIT) - ASCII('A') + 10;
    ELSE
	 V_CURRENT_DIGIT_DEC := TO_NUMBER(V_CURRENT_DIGIT);
    END IF;
    V_RESULT := (V_RESULT * 16) + V_CURRENT_DIGIT_DEC;
  END LOOP;
  RETURN V_RESULT;
EXCEPTION
	WHEN OTHERS THEN
	    V_RESULT:=0;
          RETURN V_RESULT;
END FN_HEX2DEC;
/


