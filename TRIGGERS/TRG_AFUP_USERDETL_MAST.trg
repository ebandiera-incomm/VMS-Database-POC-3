CREATE OR REPLACE TRIGGER VMSCMS.TRG_AFUP_USERDETL_MAST
AFTER UPDATE
OF CUM_USER_NAME
  ,CUM_VALD_FRDT
  ,CUM_VALD_TODT
  ,CUM_USER_EMAL
ON VMSCMS.CMS_USERDETL_MAST REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
/**********************************************
    * VERSION             :  1.0
    * Created Date        : 10/May/2010..
    * Created By          : Mahesh.P
    * PURPOSE             : User Detail Master Auditing
    * Modified By:        :
    * Modified Date       :
    * Reviewer            :
    ******************************************/
 ------FIELD TYPE 1 FOR CUM_USER_NAME
   IF :NEW.CUM_USER_NAME <> :OLD.CUM_USER_NAME
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_code, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (NULL, :OLD.CUM_USER_CODE, 1,
                   1,:OLD.CUM_USER_NAME, :NEW.CUM_USER_NAME,
                   :NEW.CUM_LUPD_USER, :NEW.CUM_LUPD_DATE
                  );
   END IF;

------FIELD TYPE 2 FOR CUM_VALD_FRDT
   IF :NEW.CUM_VALD_FRDT <> :OLD.CUM_VALD_FRDT
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_code, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (NULL, :OLD.CUM_USER_CODE, 1,
                   2,:OLD.CUM_VALD_FRDT, :NEW.CUM_VALD_FRDT,
                   :NEW.CUM_LUPD_USER, :NEW.CUM_LUPD_DATE
                  );
   END IF;

 ------FIELD TYPE 3 FOR CUM_VALD_FRDT
   IF :NEW.CUM_VALD_TODT <> :OLD.CUM_VALD_TODT
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_code, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (NULL, :OLD.CUM_USER_CODE, 1,
                   3,:OLD.CUM_VALD_TODT, :NEW.CUM_VALD_TODT,
                   :NEW.CUM_LUPD_USER, :NEW.CUM_LUPD_DATE
                  );
   END IF;

------FIELD TYPE 4 FOR CUM_VALD_FRDT
   IF :NEW.CUM_USER_EMAL <> :OLD.CUM_USER_EMAL
   THEN
      INSERT INTO cms_gpdtdetl_audt
                  (cga_INST_code, cga_FILD_UQID,cga_ENTY_TYPE,
                   cga_FILD_TYPE, cga_OLD_VALU, cga_NEW_VALU,
                   cga_INS_USER, cga_INS_DATE
                  )
           VALUES (NULL, :OLD.CUM_USER_CODE, 1,
                   4,:OLD.CUM_USER_EMAL, :NEW.CUM_USER_EMAL,
                   :NEW.CUM_LUPD_USER, :NEW.CUM_LUPD_DATE
                  );
   END IF;
END;
/


