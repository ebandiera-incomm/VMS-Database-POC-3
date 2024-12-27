CREATE OR REPLACE FUNCTION VMSCMS.FN_DEC2HEX(P_N IN NUMBER) RETURN VARCHAR2 IS

  /*************************************************
      * Created Date     :  20/03/2012
      * Created By       :  T.Narayanaswamy
      * PURPOSE          :  For GET THE HEXA VALUE
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  20-Apr-2012
      * Build Number     :  CMS3.5.1_RI0008_B00022
*************************************************/

  V_HEXVAL   VARCHAR2(64);
  V_N2       NUMBER := P_N;
  V_DIGIT    NUMBER;
  V_HEXDIGIT CHAR;
BEGIN
  WHILE (V_N2 > 0) LOOP
    V_DIGIT := MOD(V_N2, 16);
    IF V_DIGIT > 9 THEN
	 V_HEXDIGIT := CHR(ASCII('A') + V_DIGIT - 10);
    ELSE
	 V_HEXDIGIT := TO_CHAR(V_DIGIT);
    END IF;
    V_HEXVAL := V_HEXDIGIT || V_HEXVAL;
    V_N2     := TRUNC(V_N2 / 16);
  END LOOP;
  RETURN V_HEXVAL;
END FN_DEC2HEX;
/


