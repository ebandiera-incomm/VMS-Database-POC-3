CREATE OR REPLACE PROCEDURE vmscms.sp_create_branreg (
   instcode   IN       NUMBER,
   brancode   IN       VARCHAR2,
   regcode    IN       VARCHAR2,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
BEGIN
   INSERT INTO cms_branch_region
               (cbr_inst_code, cbr_region_id, cbr_bran_code, cbr_ins_user,
                cbr_lupd_user
               )
        VALUES (instcode, UPPER (regcode), brancode, lupduser,
                lupduser
               );

   errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;
/

SHOW ERROR