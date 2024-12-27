CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_custcatg (    instcode        IN        NUMBER    ,
                                                    sname        IN        VARCHAR2    ,
                                                    catgdesc        IN        VARCHAR2    ,
                                                    lupduser        IN        NUMBER    ,
                                                    catgcode        OUT        NUMBER    ,
                                                    errmsg        OUT        VARCHAR2)
AS

BEGIN        --Main Begin Block starts Here
errmsg := 'OK'    ;
    BEGIN    --begin 1
    BEGIN
      SELECT    cct_ctrl_numb
      INTO    catgcode
      FROM    CMS_CTRL_TABLE
      WHERE    cct_ctrl_code    =    instcode
      AND        cct_ctrl_key    =    'CUST CATG';
    EXCEPTION WHEN OTHERS THEN
      errmsg:='error while selecting catg code '|| substr(sqlerrm,1,200);
      Return;
    END;
--        FOR    UPDATE;

        INSERT INTO CMS_CUST_CATG        (    CCC_INST_CODE        ,
                                CCC_CATG_CODE    ,
                                CCC_CATG_SNAME    ,
                                CCC_CATG_DESC    ,
                                CCC_INS_USER        ,
                                CCC_LUPD_USER   )
        VALUES                    (    instcode    ,
                                catgcode    ,
                                sname    ,
                                catgdesc    ,
                                lupduser    ,
                                lupduser);

        UPDATE    CMS_CTRL_TABLE
        SET        cct_ctrl_numb = cct_ctrl_numb+1,
                cct_lupd_user    = lupduser
        WHERE    cct_ctrl_code    =  instcode
        AND        cct_ctrl_key    =  'CUST CATG'    ;

        

    EXCEPTION    --exception of begin 1
        WHEN  NO_DATA_FOUND THEN
            catgcode := 1;
            INSERT INTO CMS_CUST_CATG(    CCC_INST_CODE        ,
                            CCC_CATG_CODE    ,
                            CCC_CATG_SNAME    ,
                            CCC_CATG_DESC    ,
                            CCC_INS_USER        ,
                            CCC_LUPD_USER    )
                VALUES        (    instcode    ,
                            catgcode    ,
                            sname    ,
                            catgdesc    ,
                            lupduser    ,
                            lupduser);

            INSERT INTO CMS_CTRL_TABLE(    CCT_CTRL_CODE    ,
                            CCT_CTRL_KEY        ,
                            CCT_CTRL_NUMB        ,
                            CCT_CTRL_DESC    ,
                            CCT_INS_USER        ,
                            CCT_LUPD_USER)
                    VALUES    (    instcode        ,
                            'CUST CATG'    ,
                            2            ,
                            'Latest customer category code for institution '||instcode|| '.',
                            lupduser,
                            lupduser);

            

        WHEN OTHERS THEN
            errmsg := 'Excp 1 '||SQLCODE||'---'||SQLERRM;
    END;-- end of begin 1
EXCEPTION    --Exception ofMain Begin Block
WHEN OTHERS THEN
    errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;        ----Main Begin Block ends Here
/


