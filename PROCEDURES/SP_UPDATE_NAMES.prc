CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Names (oldname IN VARCHAR2,
                                             newname IN VARCHAR2,
                                             errmsg OUT VARCHAR2)
AS
dum NUMBER(2);
dum1 NUMBER(2);
BEGIN
errmsg:='OK';
SELECT COUNT(1) INTO dum
FROM CMS_USER_MAST
WHERE cum_user_name = oldname
AND cum_user_susp ='D';
IF dum != 0 THEN
 SELECT COUNT(1) INTO dum1 FROM CMS_USER_MAST
        WHERE cum_user_name = newname;
  IF dum1 = 0 THEN
   UPDATE CMS_USER_MAST
                        SET cum_user_name = newname
                        WHERE cum_user_name = oldname
                        AND cum_user_susp = 'D'
                        AND cum_user_code IN (SELECT cum_user_code
           FROM   CMS_USER_MAST
           WHERE cum_user_name = oldname )
   AND ROWNUM < 2;
   errmsg := 'USERNAME '||oldname||' Updated to '||newname;
     ELSE
   errmsg := 'This user name already exists';
  END IF ;
ELSE
 errmsg := 'This user name does not exist';
END IF;
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Problem in updating the user name';
END;
/


SHOW ERRORS