CREATE OR REPLACE TRIGGER VMSCMS.TRG_SUPERUSERINSDET_STD
AFTER INSERT
ON VMSCMS.CMS_BIN_MAST REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
error_excption EXCEPTION;
V_INST_SHORTNAME varchar2(5);
ERRMSG varchar2(300):='OK';
BEGIN --main begin
      BEGIN
      
        select CIM_INST_SHORTNAME into V_INST_SHORTNAME from cms_inst_mast where CIM_INST_CODE=:new.CBM_INST_CODE;
        IF V_INST_SHORTNAME IS NULL THEN 
          ERRMSG  := 'Short Name not fount for the Institution'||:new.CBM_INST_CODE;
          RAISE error_excption;
        END IF;
      END;
        
      if ERRMSG='OK' then
        Insert into cms_instbin_details
                           (CID_INST_CODE,
                           CID_INST_BIN,
                           CID_INST_SHORTNAME,
                           CID_INS_DATE,
                           CID_LUPD_DATE)
                         Values
                           (:new.CBM_INST_CODE,
                           :new.CBM_INST_BIN,
                           V_INST_SHORTNAME,
                           SYSDATE,
                           SYSDATE
                            );
                               
    end if;
Exception
WHEN error_excption THEN
RAISE_APPLICATION_ERROR(-20001, 'Error - '|| ERRMSG);                         
                            
END; --main end
/


