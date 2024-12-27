CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Prodccc (    instcode        IN    NUMBER    ,
                        custcatg        IN    NUMBER,
                        cardtype        IN    NUMBER    ,--now cattype
                        prodcode        IN    VARCHAR2,
                        --prodccc_code        IN    NUMBER    ,
                        --validation_prd        IN    NUMBER  ,
                        --custtype        IN    NUMBER    ,
--Imran 23 Aug 2003, for genkey
                        vendor  IN VARCHAR2,
                        stock      IN VARCHAR2,
                        prodshortname IN VARCHAR2,
                      --  product_fiid IN VARCHAR2,
                      --  genkey_prefix    IN VARCHAR2,
--Imran 23 Aug 2003, for genkey
                        lupduser        IN    NUMBER    ,
                        errmsg            OUT VARCHAR2)
AS
dum            NUMBER(1);
BEGIN        --Main begin block starts
    errmsg := 'OK';
    BEGIN        --begin 1.1
        SELECT 1
        INTO    dum
        FROM    CMS_PROD_CCC
        WHERE    cpc_inst_code    =    instcode
        AND        cpc_prod_code    =    prodcode
        AND        cpc_card_type    =    cardtype
        AND        cpc_cust_catg    =    custcatg;
        --AND        CPC_CATG_CODE    =    custtype;
        --COMMENTED AND CHANGED BY CHRISTOPHER ON 16JUN04
        --errmsg := 'Product already present in the system !!!';
          errmsg := 'Interchange already present in the system !!!';
    EXCEPTION    --exception of begin 1.1
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CMS_PROD_CCC(CPC_INST_CODE    ,
                        CPC_CUST_CATG ,
                        CPC_CARD_TYPE ,
                        CPC_PROD_CODE,
                    --    CPC_PRODCCC_CODE,
                        --cpc_pan_validity,
                    --    CPC_CATG_CODE,
--Imran 23 Aug 2003, for genkey
                        CPC_VENDOR,
                        CPC_STOCK,
                        CPC_PROD_SNAME,
                      --  CPC_PROD_FIID,
                   --     CPC_GENKEY_PREFIX,
--Imran 23 Aug 2003, for genkey
                        CPC_INS_USER  ,
                        CPC_LUPD_USER)
                    VALUES(     instcode,
                         custcatg,
                         cardtype,
                         prodcode,
                        -- prodccc_code,
                        -- validation_prd,
                        -- custtype,
--Imran 23 Aug 2003, for genkey
                         vendor,
                         stock,
                         prodshortname,
                    --    product_fiid,
                    --     genkey_prefix,
--Imran 23 Aug 2003, for genkey
                         lupduser,
                         lupduser);
            errmsg := 'OK';
        WHEN OTHERS THEN
            errmsg := 'Excp 1 '||SQLCODE||'---'||SQLERRM;
    END;    --end of begin 1
EXCEPTION    --Exception of Main begin block
    WHEN OTHERS THEN
        errmsg := 'Main Exception  '||SQLCODE||'---'||SQLERRM;
END;        --Main begin block ends;
/
show error