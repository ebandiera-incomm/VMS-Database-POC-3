CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Trunc_Tab(tname IN VARCHAR2,errmsg OUT VARCHAR2) AS
stmt VARCHAR2(100);
BEGIN
-- checking
   errmsg:='OK';
   truncate_tab_ebr (tname);

EXCEPTION

  WHEN OTHERS THEN

    errmsg:='Message'||SQLERRM;

END;
/
SHOW ERRORS

