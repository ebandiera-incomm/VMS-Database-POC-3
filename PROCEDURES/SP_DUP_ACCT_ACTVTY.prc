CREATE OR REPLACE PROCEDURE VMSCMS.sp_dup_acct_actvty (
   prm_inst_code   IN       NUMBER,
   prm_errmsg      OUT      VARCHAR2
)
AS
V_errmsg  varchar2(500) := 'OK' ;

BEGIN
   prm_errmsg := 'OK';


            -- SN : Execute procedure to update Inactive card having no spill transaction

            sp_dup_acct_inactcrd (1, V_errmsg) ;

            DBMS_OUTPUT.PUT_LINE(V_errmsg) ;

            -- EN : Execute procedure to update Inactive card having no spill transaction

            IF V_errmsg = 'OK' THEN
            -- SN : Execute procedure to update active -  Inactive card having no spill transaction

            sp_dup_acct_activcrd (1, V_errmsg) ;

            DBMS_OUTPUT.PUT_LINE(V_errmsg) ;

            -- EN : Execute procedure to update active -  Inactive card having no spill transaction

            END IF;


            IF V_errmsg = 'OK' THEN
            -- SN : Execute procedure to update iactive card having spill transaction

            sp_dup_acct_inact_spill (1, V_errmsg) ;

            DBMS_OUTPUT.PUT_LINE(V_errmsg) ;

            -- EN : Execute procedure to update iactive card having spill transaction

            END IF;


END;
/

SHOW ERRORS;


