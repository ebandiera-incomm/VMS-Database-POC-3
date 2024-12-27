CREATE OR REPLACE PROCEDURE vmscms.sp_define_slabs (
   instcode    IN       NUMBER,
   slabcode    IN       NUMBER,
   fromamt     IN       NUMBER,
   toamt       IN       NUMBER,
   transamt    IN       NUMBER,
   loylpoint   IN       NUMBER,
   lupduser    IN       NUMBER,
   errmsg      OUT      VARCHAR2
)
AS
BEGIN
   errmsg := 'OK';

   INSERT INTO cms_slabloyl_dtl
               (csd_inst_code, csd_slab_code, csd_from_amt, csd_to_amt,
                csd_trans_amt, csd_loyl_point, csd_ins_user, csd_lupd_user
               )
        VALUES (instcode, slabcode, fromamt, toamt,
                transamt, loylpoint, lupduser, lupduser
               );
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp --' || SQLERRM || '.';
END;
/

SHOW ERROR