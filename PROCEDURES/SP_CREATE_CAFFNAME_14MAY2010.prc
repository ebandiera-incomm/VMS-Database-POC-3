CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_caffname_14MAY2010 IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       sp_create_caffname_14MAY2010
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/14/2010          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     sp_create_caffname_14MAY2010
      Sysdate:         5/14/2010
      Date and Time:   5/14/2010, 5:16:39 PM, and 5/14/2010 5:16:39 PM
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END sp_create_caffname_14MAY2010;
/


