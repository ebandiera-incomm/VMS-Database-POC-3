CREATE OR REPLACE FUNCTION VMSCMS.FN_MASTER_DATA_NEW (
   PRM_TABLE_NM       IN VARCHAR2,
   PRM_COLUMN_NM      IN VARCHAR2,
   PRM_COMPARE_COL    IN VARCHAR2,
   PRM_COMPARE1_COL   IN VARCHAR2,
   PRM_COMPARE2_COL   IN VARCHAR2,
   PRM_COMPARE3_COL   IN VARCHAR2,
   PRM_COMPARE4_COL   IN VARCHAR2,
   PRM_VALUE             VARCHAR2,
   PRM_OLD_NEW           VARCHAR2,
   PRM_SEQ               NUMBER)
   RETURN VARCHAR2
AS
   V_DISP_VALUE   VARCHAR2 (60);
   V_QRY1         VARCHAR2 (9000);
   V_QRY2         VARCHAR2 (9000);
   V_QRY3         VARCHAR2 (9000);
   V_CMP_VALUE1   VARCHAR2 (100);
   V_CMP_VALUE2   VARCHAR2 (100);
   V_ERROR        VARCHAR2 (700) := 'OK';
BEGIN
   IF PRM_COMPARE1_COL IS NULL
   THEN
      V_QRY1 :=
            'SELECT  '
         || PRM_COLUMN_NM
         || '  FROM '
         || PRM_TABLE_NM
         || '  WHERE to_char('
         || PRM_COMPARE_COL
         || ')  = :1 ';

      EXECUTE IMMEDIATE V_QRY1 INTO V_DISP_VALUE USING PRM_VALUE;

      RETURN V_DISP_VALUE;
   ELSIF PRM_COMPARE3_COL IS NULL
   THEN
      V_QRY2 :=
            ' SELECT '
         || PRM_OLD_NEW
         || ' FROM CMS_AUDIT_INFO WHERE   SEQ = '
         || PRM_SEQ
         || ' AND CAI_FIELD_NAME = :3 ';

      EXECUTE IMMEDIATE V_QRY2 INTO V_CMP_VALUE1 USING PRM_COMPARE2_COL;

      V_QRY1 :=
            'SELECT  '
         || PRM_COLUMN_NM
         || '  FROM '
         || PRM_TABLE_NM
         || '  WHERE to_char('
         || PRM_COMPARE_COL
         || ')  = :1 '
         || ' AND  to_char('
         || PRM_COMPARE1_COL
         || ') =  :2 ';

      EXECUTE IMMEDIATE V_QRY1
         INTO V_DISP_VALUE
         USING PRM_VALUE, V_CMP_VALUE1;

      RETURN V_DISP_VALUE;
   ELSE
      V_QRY2 :=
            ' SELECT '
         || PRM_OLD_NEW
         || ' FROM CMS_AUDIT_INFO WHERE   SEQ = '
         || PRM_SEQ
         || ' AND CAI_FIELD_NAME = :2 ';

      EXECUTE IMMEDIATE V_QRY2 INTO V_CMP_VALUE1 USING PRM_COMPARE2_COL;

      V_QRY3 :=
            ' SELECT '
         || PRM_OLD_NEW
         || ' FROM CMS_AUDIT_INFO WHERE   SEQ = '
         || PRM_SEQ
         || ' AND CAI_FIELD_NAME = :4 ';

      EXECUTE IMMEDIATE V_QRY3 INTO V_CMP_VALUE2 USING PRM_COMPARE4_COL;

      V_QRY1 :=
            'SELECT  '
         || PRM_COLUMN_NM
         || '  FROM '
         || PRM_TABLE_NM
         || '  WHERE to_char('
         || PRM_COMPARE_COL
         || ')  = :1 '
         || ' AND  to_char('
         || PRM_COMPARE1_COL
         || ') = :2 '
         || ' AND  to_char('
         || PRM_COMPARE3_COL
         || ') =  :3 ';

      EXECUTE IMMEDIATE V_QRY1
         INTO V_DISP_VALUE
         USING PRM_VALUE, V_CMP_VALUE1, V_CMP_VALUE2;

      RETURN V_DISP_VALUE;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      V_ERROR := ' From master fun ' || SUBSTR (SQLERRM, 1, 400);
      V_DISP_VALUE := SUBSTR (V_ERROR, 1, 59);
      RETURN V_DISP_VALUE;
END;
/

SHOW ERROR