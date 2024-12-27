CREATE OR REPLACE TRIGGER VMSCMS.TRG_AFUP_USGPDETL_MAST
AFTER UPDATE
OF CUM_GRUP_CODE
ON VMSCMS.CMS_USGPDETL_MAST REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
/**********************************************
    * VERSION             :  1.0
    * Created Date        : 10/May/2010..
    * Created By          : Mahesh.P
    * PURPOSE             : User Group Master Auditing
    * Modified By:        :
    * Modified Date       :
    * Reviewer            :
    ******************************************/
 ------FIELD TYPE 5 FOR cga_GRUP_NAME
   IF :NEW.CUM_GRUP_CODE <> :OLD.CUM_GRUP_CODE
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_CODE, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_ins_date
                  )
           VALUES (:OLD.CUM_INST_CODE, :OLD.CUM_USER_CODE, 1,
                   5,:OLD.CUM_GRUP_CODE, :NEW.CUM_GRUP_CODE,
                   :NEW.CUM_LUPD_USER, :NEW.CUM_LUPD_DATE
                  );
   END IF;
END;
/


