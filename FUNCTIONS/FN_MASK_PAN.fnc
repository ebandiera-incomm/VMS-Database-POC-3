CREATE OR REPLACE FUNCTION VMSCMS.FN_MASK_PAN (P_INST_CODE       IN NUMBER,
                                               P_USER_PAN        IN VARCHAR2,
                                               P_USER_PIN        IN NUMBER,
                                               P_USER_GRP_CODE   IN NUMBER)
   RETURN VARCHAR2
AS
   V_PAN                VARCHAR (40);
   ERRMSG               VARCHAR2 (100);
   PAN                  VARCHAR2 (30);
   V_FIRST              VARCHAR (10);
   V_ENCRYPT            VARCHAR (30);
   V_LAST               VARCHAR (10);
   V_DATA_DISPLAY       VARCHAR (10);
   V_GRP_DISPLAY_FLAG   VARCHAR (10);
   V_LENGTH             NUMBER (30);
   V_MASKING_CHAR       VARCHAR2 (10);
   PAN_NOT_FOUND        EXCEPTION;
BEGIN
   PAN := FN_DMAPS_MAIN (P_USER_PAN);

   IF PAN IS NULL
   THEN
      RAISE PAN_NOT_FOUND;
   END IF;

   BEGIN
      SELECT CUM_ACCESS_FLAG
        INTO V_DATA_DISPLAY
        FROM CMS_USER_MAST
       WHERE CUM_INST_CODE = P_INST_CODE AND CUM_USER_PIN = P_USER_PIN;

      SELECT CUG_ACCESS_FLAG
        INTO V_GRP_DISPLAY_FLAG
        FROM CMS_USER_GROUP
       WHERE CUG_INST_CODE = P_INST_CODE AND CUG_GROUP_CODE = P_USER_GRP_CODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_PAN := 'No Data for the user pin' || P_USER_PIN;
         RETURN V_PAN;
      WHEN OTHERS
      THEN
         V_PAN := 'Error' || P_USER_PIN || SUBSTR (SQLERRM, 1, 30);
         RETURN V_PAN;
   END;

   BEGIN
      SELECT LPAD (CIP_PARAM_VALUE, 10, CIP_PARAM_VALUE)
        INTO V_MASKING_CHAR
        FROM CMS_INST_PARAM
       WHERE CIP_PARAM_KEY = 'MASKINGCHAR' AND CIP_INST_CODE = P_INST_CODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_MASKING_CHAR := '**********';
      WHEN OTHERS
      THEN
         V_PAN := 'Error' || SUBSTR (SQLERRM, 1, 35);
         RETURN V_PAN;
   END;

   IF V_DATA_DISPLAY = 'N' AND V_GRP_DISPLAY_FLAG = 'N'
   THEN
      IF LENGTH (PAN) > 10
      THEN
         V_PAN := PAN;
      ELSE
         RAISE PAN_NOT_FOUND;
      END IF;
   ELSE
      IF LENGTH (PAN) > 10
      THEN
         V_FIRST := SUBSTR (PAN, 1, 6);
         V_LAST := SUBSTR (PAN, -4, 4);
         V_LENGTH := (LENGTH (PAN) - LENGTH (V_FIRST) - LENGTH (V_LAST));
         V_ENCRYPT :=
            TRANSLATE (SUBSTR (PAN, 7, V_LENGTH),
                       '0123456789',
                       V_MASKING_CHAR);
         V_PAN := V_FIRST || V_ENCRYPT || V_LAST;
      ELSE
         RAISE PAN_NOT_FOUND;
      END IF;
   END IF;

   RETURN V_PAN;
EXCEPTION
   WHEN PAN_NOT_FOUND
   THEN
      ERRMSG := SQLERRM;
      RETURN PAN;
   WHEN OTHERS
   THEN
      ERRMSG := SQLERRM;
      RETURN V_PAN;
END;
/

SHOW ERROR