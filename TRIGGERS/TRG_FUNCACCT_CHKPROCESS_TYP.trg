CREATE OR REPLACE TRIGGER VMSCMS.trg_funcacct_chkprocess_typ
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_FUNC_ACCT 		FOR EACH ROW
DECLARE
        v_rec_cnt NUMBER(3);
BEGIN
        IF :NEW.cfa_processes_typ = 'V' THEN
        --Sn find any record of type 'V'
        BEGIN
                SELECT count(1)
                INTO   v_rec_cnt
                FROM   CMS_FUNC_ACCT
                WHERE  cfa_func_code = :NEW.cfa_func_code;

                IF v_rec_cnt <> 0 THEN
                RAISE_APPLICATION_ERROR(-20003,'Only one account of type V can be attached to Function code ' || :NEW.cfa_func_code);
                END IF;

        END;
        --Sn find any record of type 'V'
        END IF;

END;
/


