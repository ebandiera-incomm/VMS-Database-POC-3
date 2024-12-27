CREATE OR REPLACE TRIGGER VMSCMS.TRG_FIN_LOG_UPDGLACCT
AFTER INSERT
ON VMSCMS.CMS_FIN_LOG FOR EACH ROW
DECLARE
BEGIN --main begin
  IF :NEW.CFL_DRCR_FLAG = 'DR' THEN
        --Sn debit the correpending GL ACCT
        BEGIN
                UPDATE CMS_GL_ACCT_MAST
                SET    CGA_TRAN_AMT = CGA_TRAN_AMT - :NEW.CFL_TRAN_AMT 
                WHERE  CGA_GLCATG_CODE = :NEW.CFL_CATG_CODE
                AND    CGA_GL_CODE     = :NEW.CFL_GL_CODE
                AND    CGA_SUBGL_CODE  = :NEW.CFL_SUBGL_CODE
                AND    CGA_ACCT_CODE   = :NEW.CFL_ACCT_NO;
                IF SQL%ROWCOUNT = 0 THEN
                RAISE_APPLICATION_ERROR(-20005,
                                        'Problem while debiting Amount from GL ACCT MAST ' || 'Master data may not exist for glcatg ' ||:NEW.CFL_CATG_CODE || ' gl code  ' ||
                                        :NEW.CFL_GL_CODE || ' Sub gl code ' || :NEW.CFL_SUBGL_CODE || 'Acct no ' || :NEW.CFL_ACCT_NO );
                END IF;
        END;
        --En debit the correpending GL ACCT
  ELSE
       IF  :NEW.CFL_DRCR_FLAG = 'CR' THEN 
        --Sn credit the correpending GL ACCT
        BEGIN
                UPDATE CMS_GL_ACCT_MAST
                SET    CGA_TRAN_AMT = CGA_TRAN_AMT + :NEW.CFL_TRAN_AMT 
                WHERE  CGA_GLCATG_CODE = :NEW.CFL_CATG_CODE
                AND    CGA_GL_CODE     = :NEW.CFL_GL_CODE
                AND    CGA_SUBGL_CODE  = :NEW.CFL_SUBGL_CODE
                AND    CGA_ACCT_CODE   = :NEW.CFL_ACCT_NO;
                IF SQL%ROWCOUNT = 0 THEN
                RAISE_APPLICATION_ERROR(-20005,
                                        'Problem while debiting Amount from GL ACCT MAST ' || 'Master data may not exist for glcatg ' ||:NEW.CFL_CATG_CODE || ' gl code  ' ||
                                        :NEW.CFL_GL_CODE || ' Sub gl code ' || :NEW.CFL_SUBGL_CODE || 'Acct no ' || :NEW.CFL_ACCT_NO);
                END IF;
        END;
        --En credit the correpending GL ACCT
       ELSE
           RAISE_APPLICATION_ERROR(-20003,'Transaction Type ' ||:NEW.CFL_DRCR_FLAG ||' is not a valid type ' || ' (value should be DR/CR) ' );
       END IF;
  END IF;
END; --main end
/


