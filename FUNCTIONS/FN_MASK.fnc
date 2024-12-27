create or replace FUNCTION vmscms.fn_mask (
   PINPUT      IN   VARCHAR2,
   PMASK       IN   VARCHAR2,
   PFROM       IN   NUMBER,
   PNOOFCHRS   IN   NUMBER
)
   RETURN VARCHAR2
AS
   I         NUMBER (10);
   POUTPUT   VARCHAR2 (100);
BEGIN
   I := 0;
   POUTPUT := '';

   FOR I IN 1 .. LENGTH (PINPUT)
   LOOP
      IF I >= PFROM AND I <= (PFROM + PNOOFCHRS - 1)
      THEN
         POUTPUT := POUTPUT || PMASK;
      ELSE
         POUTPUT := POUTPUT || SUBSTR (PINPUT, I, 1);
      END IF;
   END LOOP;

   RETURN POUTPUT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN PINPUT;
END;
/
show error