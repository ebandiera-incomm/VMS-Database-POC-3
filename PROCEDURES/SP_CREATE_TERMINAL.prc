CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_terminal (instcode IN    NUMBER    ,
                        merccode IN    VARCHAR2,
                        bankid    IN    VARCHAR2,--added on 9/7/2002 to get the bank to which the terminal belongs to
                        termid     IN    VARCHAR2,
                        cntrycode IN    NUMBER    ,
                        citycode IN    NUMBER    ,
                        lupduser IN    NUMBER    ,
                        errmsg     OUT    VARCHAR2)
AS
BEGIN        --main begin
errmsg := 'OK';
    BEGIN        --begin 1
    INSERT INTO CMS_TERM_MAST(    CTM_INST_CODE    ,
                    CTM_BANK_ID    ,
                    CTM_MERC_CODE    ,
                    CTM_TERM_ID    ,
                    CTM_CNTRY_CODE    ,
                    CTM_CITY_CODE    ,
                    CTM_REL_STAT    ,
                    CTM_INS_USER    ,
                    CTM_LUPD_USER    )
                VALUES(    instcode    ,
                    bankid        ,--added on 9/7/2002
                    merccode    ,
                    termid        ,
                    cntrycode    ,
                    citycode    ,
                    'Y'        ,--added on 9/7/2002
                    lupduser    ,
                    lupduser    );

    EXCEPTION    --excp of begin 1
    WHEN OTHERS THEN
    errmsg := 'Excp 1 -- '||SQLERRM;
    END;        --end begin 1
EXCEPTION    --main excp
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;        --end main
/


show error