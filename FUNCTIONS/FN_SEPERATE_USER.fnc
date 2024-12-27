CREATE OR REPLACE FUNCTION VMSCMS.FN_SEPERATE_USER (IN_STRING VARCHAR2)
   RETURN VARCHAR2
AS
   V_USER_NAME   VARCHAR2 (100);
   V_LEN         NUMBER (10);
   TABOUT        GEN_CMS_PACK.PLSQL_TAB_SINGLE_COLUMN;
   ERRMSG        VARCHAR2 (100) := 'OK';
   USER_ID       VARCHAR2 (100);
   USER_NAME     VARCHAR2 (100);
BEGIN
   SELECT (LENGTH (IN_STRING) - LENGTH (REPLACE (IN_STRING, '|', NULL)))
          / LENGTH ('|')
     INTO V_LEN
     FROM DUAL;

   IF V_LEN IS NOT NULL
   THEN
      TOKENISE (IN_STRING,
                '|',
                TABOUT,
                ERRMSG);

      IF ERRMSG = 'OK'
      THEN
         BEGIN
            FOR X IN 1 .. V_LEN + 1
            LOOP
               USER_ID := TABOUT (X);

               BEGIN
                  SELECT CUM_USER_CODE
                    INTO USER_NAME
                    FROM CMS_USER_MAST
                   WHERE CUM_USER_PIN = USER_ID;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     ERRMSG := 'No Data Found';
               END;

               V_USER_NAME := V_USER_NAME || '|' || USER_NAME;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               ERRMSG := 'No Data Found' || SQLERRM;
         END;
      END IF;
   END IF;

   IF ERRMSG = 'OK'
   THEN
      RETURN V_USER_NAME;
   ELSE
      V_USER_NAME := ERRMSG;
      RETURN V_USER_NAME;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      V_USER_NAME := 'MAIN EXCEPTION ' || SQLERRM;
      RETURN V_USER_NAME;
END;
/

SHOW ERROR