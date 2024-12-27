CREATE OR REPLACE TRIGGER VMSCMS.TRG_GROUPDETL_MAST
AFTER UPDATE
OF CGM_GRUP_NAME,
   CGM_LGPW_CHIN,
   CGM_TXPW_CHIN,
   CGM_GRUP_STUS
ON VMSCMS.CMS_GROUPDETL_MAST REFERENCING NEW AS NEW OLD AS OLD
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
 ------FIELD TYPE 1 FOR cga_GRUP_NAME
   IF :NEW.CGM_GRUP_NAME <> :OLD.CGM_GRUP_NAME
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_CODE, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (:OLD.CGM_INST_CODE, :OLD.CGM_GRUP_CODE, 2,
                   1,:OLD.CGM_GRUP_NAME, :NEW.CGM_GRUP_NAME,
                   :NEW.CGM_LUPD_USER, :NEW.CGM_LUPD_DATE
                  );
   END IF;

------FIELD TYPE 2 FOR cga_GRUP_NAME
   IF :NEW.CGM_LGPW_CHIN <> :OLD.CGM_LGPW_CHIN
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_CODE, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (:OLD.CGM_INST_CODE, :OLD.CGM_GRUP_CODE, 2,
                   2,:OLD.CGM_LGPW_CHIN, :NEW.CGM_LGPW_CHIN,
                   :NEW.CGM_LUPD_USER, :NEW.CGM_LUPD_DATE
                  );
   END IF;

------FIELD TYPE 3 FOR cga_TXPW_CHIN
   IF :NEW.CGM_TXPW_CHIN <> :OLD.CGM_TXPW_CHIN
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_CODE, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (:OLD.CGM_INST_CODE, :OLD.CGM_GRUP_CODE, 2,
                   3,:OLD.CGM_TXPW_CHIN, :NEW.CGM_TXPW_CHIN,
                   :NEW.CGM_LUPD_USER, :NEW.CGM_LUPD_DATE
                  );
   END IF;

------FIELD TYPE 4 FOR cga_GRUP_STUS
   IF :NEW.CGM_GRUP_STUS <> :OLD.CGM_GRUP_STUS
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_CODE, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (:OLD.CGM_INST_CODE, :OLD.CGM_GRUP_CODE, 2,
                   4,:OLD.CGM_GRUP_STUS, :NEW.CGM_GRUP_STUS,
                   :NEW.CGM_LUPD_USER, :NEW.CGM_LUPD_DATE
                  );
   END IF;

END;
/


