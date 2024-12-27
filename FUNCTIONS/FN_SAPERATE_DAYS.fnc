CREATE OR REPLACE FUNCTION VMSCMS.FN_SAPERATE_DAYS (IN_STRING VARCHAR2)
   RETURN VARCHAR2
AS
   V_WEEK_DAYS   VARCHAR2 (100);
   V_LEN         NUMBER (10);
   TABOUT        GEN_CMS_PACK.PLSQL_TAB_SINGLE_COLUMN;
   ERRMSG        VARCHAR2 (100) := 'OK';
   V_DAYS        VARCHAR2 (100);
BEGIN
   SELECT (LENGTH (TRIM (IN_STRING))
           - LENGTH (REPLACE (TRIM (IN_STRING), '|', NULL)))
          / LENGTH ('|')
     INTO V_LEN
     FROM DUAL;

   IF V_LEN IS NOT NULL
   THEN
      TOKENISE (TRIM (IN_STRING),
                '|',
                TABOUT,
                ERRMSG);

      IF ERRMSG = 'OK'
      THEN
         FOR X IN 1 .. V_LEN + 1
         LOOP
            BEGIN
               SELECT DECODE (TRIM (TABOUT (X)),
                              '', 'ALL',
                              0, 'ALL',
                              1, 'SUNDAY',
                              2, 'MONDAY',
                              3, 'TUESDAY',
                              4, 'WEDNESDAY',
                              5, 'THURSDAY',
                              6, 'FRIDAY',
                              7, 'SATURDAY')
                 INTO V_DAYS
                 FROM DUAL;

               V_WEEK_DAYS := V_WEEK_DAYS || '|' || V_DAYS;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ERRMSG := 'No DAta Found ' || SQLERRM;
            END;
         END LOOP;
      END IF;
   END IF;

   IF ERRMSG = 'OK'
   THEN
      RETURN V_WEEK_DAYS;
   ELSE
      V_WEEK_DAYS := ERRMSG;
      RETURN V_WEEK_DAYS;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      V_WEEK_DAYS := 'main Exception ' || SQLERRM;
      RETURN V_WEEK_DAYS;
END;
/

SHOW ERROR