CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_item (
   instcode    IN       NUMBER,
   itemid      IN       VARCHAR2,
   itemdesc    IN       VARCHAR2,
   reorder     IN       NUMBER,
   itemvalue   IN       NUMBER,
   lupduser    IN       NUMBER,
   errmsg      OUT      VARCHAR2
)
AS
   uniq_excp   EXCEPTION;
   PRAGMA EXCEPTION_INIT (uniq_excp, -00001);
BEGIN                                                  --procedure body starts
   errmsg := 'OK';

   BEGIN                                                            --begin 1
      INSERT INTO cms_item_mast
                  (cim_inst_code, cim_item_id, cim_item_desc,
                   cim_reord_level, cim_gift_value, cim_ins_user,
                   cim_lupd_user
                  )
           VALUES (instcode, itemid, UPPER (itemdesc),
                   reorder, itemvalue, lupduser,
                   lupduser
                  );
   EXCEPTION                                                 --excp of begin 1
      WHEN uniq_excp
      THEN
         errmsg := 'Same Gift Item Present';
      WHEN OTHERS
      THEN
         errmsg := 'Excp 1 -- ' || SQLERRM;
   END;                                                          --end begin 1
EXCEPTION                                                       --excp of main
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;                                                     --procedure body ends
/


