CREATE OR REPLACE TRIGGER VMSCMS.TRG_SAVACCT_STAT_AUDIT  AFTER UPDATE
OF CAM_STAT_CODE ON  CMS_ACCT_MAST
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   exp_audit     EXCEPTION;
   v_switch_acct_type         cms_acct_type.cat_switch_type%TYPE DEFAULT '22';
   v_acct_type                cms_acct_type.cat_type_code%TYPE;
   v_errmsg                   varchar(500);

/*************************************************
     * Created Date     :  18-Jan-2013
     * Created By       :  Saravanakumar
     * Purpose          :  To maintain history of the saving account status
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  18-Jan-2013
      * Build Number     :  CMS3.5.1_RI0023.1_B0003

 *************************************************/BEGIN

    BEGIN
        SELECT cat_type_code
        INTO v_acct_type
        FROM cms_acct_type
        WHERE cat_inst_code = :OLD.CAM_INST_CODE
        AND cat_switch_type = v_switch_acct_type;
    EXCEPTION
        WHEN NO_DATA_FOUND  THEN
            v_errmsg := 'Acct type not defined in master(Savings)';
            RAISE exp_audit;
        WHEN OTHERS  THEN
            v_errmsg :='Error while selecting saving accttype '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_audit;
    END;

    IF :OLD.CAM_TYPE_CODE=v_acct_type and :OLD.CAM_STAT_CODE <>:NEW.CAM_STAT_CODE THEN
   
        BEGIN
            INSERT INTO CMS_SAVACCT_STAT_HIST
                                        (        
                                        CSH_INST_CODE,
                                        CSH_ACCT_NO ,
                                        CSH_ACCT_ID,
                                        CSH_OLD_STAT_CODE,
                                        CSH_NEW_STAT_CODE,
                                        CSH_INS_USER,
                                        CSH_INS_DATE,
                                        CSH_LUPD_USER,
                                        CSH_LUPD_DATE
                                        )
            VALUES
                                        (
                                        :OLD.CAM_INST_CODE,
                                        :OLD.CAM_ACCT_NO ,
                                        :OLD.CAM_ACCT_ID,
                                        :OLD.CAM_STAT_CODE,
                                        :NEW.CAM_STAT_CODE,
                                        :OLD.CAM_INS_USER,
                                        sysdate,
                                        :NEW.CAM_LUPD_USER,
                                        sysdate
                                        );

        EXCEPTION
            WHEN OTHERS  THEN
                v_errmsg := 'Error while inserting CMS_SAVACCT_STAT_HIST '||substr(SQLERRM,1,200);
                RAISE exp_audit;
        END;

    END IF;

EXCEPTION
    WHEN exp_audit THEN
        raise_application_error (-20001,'Error in Trigger TRG_SAVACCT_STAT_AUDIT '|| v_errmsg );
END;
/
show error
 