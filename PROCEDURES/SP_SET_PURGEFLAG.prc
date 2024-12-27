CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Set_Purgeflag (PRM_PAN VARCHAR2,
                                   PRM_CARD_STAT VARCHAR2,
                                   PRM_FLAG     VARCHAR2,
                                   PRM_ERRMSG OUT  VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
       PRM_ERRMSG := 'OK';
        INSERT
        INTO CMS_PURGECARD_STAT
        VALUES
        (PRM_PAN,
         PRM_CARD_STAT,
         PRM_FLAG);
COMMIT;
EXCEPTION
   WHEN OTHERS THEN
   PRM_ERRMSG := 'ERROR while inserting records into purgecard_stat' || SUBSTR(SQLERRM,1,300);
END;
/


