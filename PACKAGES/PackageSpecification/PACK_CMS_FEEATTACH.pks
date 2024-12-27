CREATE OR REPLACE PACKAGE VMSCMS.Pack_Cms_Feeattach
AS

PROCEDURE sp_create_cardexcpfee(instcode  IN NUMBER ,
        feecode  IN NUMBER ,
        pancode  IN VARCHAR2 ,
        mbrnumb  IN VARCHAR2 ,
        validfrom  IN DATE  ,
        validto  IN DATE  ,
        lupduser  IN NUMBER ,
        errmsg  OUT  VARCHAR2 );

PROCEDURE sp_create_prodcccfee( instcode  IN NUMBER ,
        custcatg  IN NUMBER ,
        prodcode  IN VARCHAR2 ,
        cardtype  IN NUMBER ,
        feecode  IN NUMBER ,
        validfrom  IN DATE  ,
        validto  IN DATE  ,
        flowsource IN VARCHAR2 ,
        feeType	IN	VARCHAR2	,
        tranCode	IN	VARCHAR2	,
        lupduser  IN NUMBER ,
        errmsg  OUT  VARCHAR2 );

PROCEDURE sp_create_prodcattypefee( instcode  IN NUMBER ,
         prodcode  IN VARCHAR2 ,
         cardtype  IN NUMBER ,
         feecode  IN NUMBER ,
         validfrom  IN DATE  ,
         validto  IN DATE  ,
         flowsource IN VARCHAR2 ,
         lupduser  IN NUMBER ,
         errmsg  OUT  VARCHAR2 );

PROCEDURE sp_create_prodfee( instcode  IN NUMBER ,
        prodcode  IN VARCHAR2 ,
        feecode  IN NUMBER ,
        validfrom  IN DATE  ,
         validto  IN DATE  ,
        lupduser  IN NUMBER ,
        errmsg  OUT  VARCHAR2);

END;--END PACKAGE HEADER
/


CREATE OR REPLACE PACKAGE BODY VMSCMS.Pack_Cms_Feeattach
IS
-----4
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE sp_create_cardexcpfee        (instcode        IN    NUMBER    ,
                                    feecode        IN    NUMBER    ,
                                    pancode        IN    VARCHAR2    ,
                                    mbrnumb        IN    VARCHAR2    ,
                                    validfrom        IN    DATE        ,
                                    validto        IN    DATE        ,
                                    lupduser        IN    NUMBER    ,
                                    errmsg        OUT     VARCHAR2    )
AS
v_cfm_feetype_code    NUMBER(3);
newdate                DATE        ;
flowsource            CHAR(1)    ;
v_mbrnumb            VARCHAR2(3);
mesg                VARCHAR2(500);

CURSOR c1 IS
SELECT    cce_fee_code,cce_valid_to, cce_valid_from
FROM    CMS_CARD_EXCPFEE a , CMS_FEE_MAST b
WHERE    a.cce_inst_code        =    instcode
AND        a.cce_fee_code        =   feecode
AND        a.cce_fee_code        =    b.cfm_fee_code
AND        b.cfm_feetype_code    =    v_cfm_feetype_code
AND        a.cce_pan_code        =    gethash(pancode)
AND        a.cce_mbr_numb        =    v_mbrnumb
AND        (TRUNC(validfrom)        BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to)
OR        TRUNC(validfrom)        < TRUNC(cce_valid_from));

CURSOR c2(feecode_from_c1 IN NUMBER) IS--picks up rows for waiver change(if any, i.e. if any waiver is attached to the feecode being changed)
SELECT    cce_fee_code, cce_valid_from, cce_valid_to
FROM    CMS_CARD_EXCPWAIV
WHERE    cce_inst_code            =    instcode
AND        cce_fee_code            =    feecode_from_c1
AND        cce_pan_code        =    pancode
AND        cce_mbr_numb        =    v_mbrnumb;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_updoprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE, l_new_valid_fee_to IN DATE, mesg OUT VARCHAR2)
IS
new_waiv_todate    DATE;
BEGIN
    IF        l_valid_waiv_from <= l_new_valid_fee_to AND l_valid_waiv_to >= l_new_valid_fee_to THEN
            new_waiv_todate := l_new_valid_fee_to;
            IF l_valid_waiv_to = l_new_valid_fee_to THEN
                NULL;
                mesg := 'OK';
            ELSE
                UPDATE CMS_CARD_EXCPWAIV
                SET        cce_valid_to        =    new_waiv_todate,
                        cce_lupd_user    =      lupduser
                WHERE    cce_inst_code        =    instcode
                AND        cce_fee_code        =    l_cce_fee_code
                AND        cce_pan_code    =    gethash(pancode)
                AND        cce_mbr_numb    =    mbrnumb
                AND        cce_valid_from    =    l_valid_waiv_from
                AND        cce_valid_to        =    l_valid_waiv_to;
                IF SQL%ROWCOUNT = 1 THEN
                    mesg := 'OK';
                ELSE
                    mesg := 'Problem in updation of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
                END IF;
            END IF;

    ELSIF    l_valid_waiv_from > l_new_valid_fee_to THEN
            DELETE FROM CMS_CARD_EXCPWAIV
            WHERE    cce_inst_code        =    instcode
            AND        cce_fee_code        =    l_cce_fee_code
            AND        cce_pan_code    =    gethash(pancode)
            AND        cce_mbr_numb    =    mbrnumb
            AND        cce_valid_from    =    l_valid_waiv_from
            AND        cce_valid_to        =    l_valid_waiv_to;
            IF SQL%ROWCOUNT = 1 THEN
                mesg := 'OK';
            ELSE
                mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
            END IF;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated-*-*-*-*-*-*-*-*-*-*-

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_deloprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE ,mesg OUT VARCHAR2)
IS

BEGIN
    DELETE FROM CMS_CARD_EXCPWAIV
    WHERE    cce_inst_code        =    instcode
    AND        cce_fee_code        =    l_cce_fee_code
    AND        cce_pan_code    =    gethash(pancode)
    AND        cce_mbr_numb    =    mbrnumb
    AND        cce_valid_from    =    l_valid_waiv_from
    AND        cce_valid_to        =    l_valid_waiv_to;
    IF SQL%ROWCOUNT = 1 THEN
        mesg := 'OK';
    ELSE
        mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted-*-*-*-*-*-*-*-*-*-*-

BEGIN        --main begin starts
flowsource := 'C';--C is hard coded because this procedure is always called explicitly, i.e. when the fee is to be attached to the card level, so no flow source will come from any of the levels above card level
--here change level and change source both are same
IF    mbrnumb IS NULL  THEN
    v_mbrnumb := '000';
END IF;
    BEGIN        --begin 1 starts
    SELECT    cfm_feetype_code
    INTO    v_cfm_feetype_code
    FROM    CMS_FEE_MAST
    WHERE    cfm_inst_code    =    instcode
    AND        cfm_fee_code        =    feecode;
    errmsg := 'OK';

        BEGIN    --begin 2 starts
        FOR x IN c1
            LOOP
            IF errmsg != 'OK' THEN
            EXIT;
            END IF;

                --now perform the reqd operation on the current row of the resultset
            IF    TRUNC(validfrom) <= TRUNC(x.cce_valid_from) THEN
                DBMS_OUTPUT.PUT_LINE('test out 2');
    --                insert into shadow and then delete
                    INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                CAH_FEE_CODE            ,
                                                CAH_OLD_FROMDATE            ,
                                                CAH_OLD_TODATE            ,
                                                CAH_CHANGE_LEVEL        ,
                                                CAH_PAN_CODE            ,
                                                CAH_MBR_NUMB            ,
                                                CAH_CHANGE_SOURCE    ,
                                                CAH_ACTION_TAKEN        ,
                                                CAH_CHANGE_USER        )
                                        VALUES(    instcode        ,
                                                feecode        ,
                                                x.cce_valid_from,
                                                x.cce_valid_to    ,
                                                flowsource    ,
                                                gethash(pancode)        ,
                                                v_mbrnumb        ,
                                                flowsource    ,
                                                'DELETE'    ,
                                                lupduser    );


                    DELETE     FROM    CMS_CARD_EXCPFEE
                    WHERE            cce_inst_code        =    instcode
                    AND                cce_pan_code    =    gethash(pancode)
                    AND                cce_mbr_numb    =    v_mbrnumb
                    AND                cce_fee_code        =    x.cce_fee_code
                    AND                cce_valid_from    =    x.cce_valid_from
                    AND                cce_valid_to        =    x.cce_valid_to;
                    IF SQL%ROWCOUNT = 1 THEN
                        errmsg := 'OK';
                    ELSE
                        errmsg := 'Problem in deletion of fee code '||x.cce_fee_code ||' for this PAN.'    ;
                    END IF;
                    --Now perform the changes for waiver
                    IF errmsg = 'OK' THEN
                        FOR y IN c2(x.cce_fee_code)
                        LOOP
                            lp_waiv_deloprn(y.cce_fee_code, y.cce_valid_from , y.cce_valid_to,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_deloprn for feecode '||y.cce_fee_code||' and valid date to = '||y.cce_valid_to||' .';
                            END IF;
                        EXIT WHEN c2%NOTFOUND;
                        END LOOP;
                    END IF;

                ELSE
                DBMS_OUTPUT.PUT_LINE('test out 3');
    --                insert into shadow and then update
                    INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                CAH_FEE_CODE            ,
                                                CAH_OLD_FROMDATE            ,
                                                CAH_OLD_TODATE            ,
                                                CAH_CHANGE_LEVEL        ,
                                                CAH_PAN_CODE            ,
                                                CAH_MBR_NUMB            ,
                                                CAH_CHANGE_SOURCE    ,
                                                CAH_ACTION_TAKEN        ,
                                                CAH_CHANGE_USER        )
                                        VALUES(    instcode        ,
                                                feecode        ,
                                                x.cce_valid_from,
                                                x.cce_valid_to    ,
                                                flowsource    ,
                                                gethash(pancode)        ,
                                                v_mbrnumb        ,
                                                flowsource    ,
                                                'UPDATE'    ,
                                                lupduser    );
                    newdate    :=    TRUNC(validfrom)-1    ;
                    UPDATE CMS_CARD_EXCPFEE
                    SET        cce_valid_to        =    newdate,
                            cce_lupd_user    =    lupduser
                    WHERE    cce_inst_code        =    instcode
                    AND        cce_pan_code    =    gethash(pancode)
                    AND        cce_mbr_numb    =    v_mbrnumb
                    AND        cce_fee_code        =    x.cce_fee_code
                    AND        cce_valid_from    =    x.cce_valid_from
                    AND        cce_valid_to        =    x.cce_valid_to;
                    IF SQL%ROWCOUNT = 1 THEN
                        errmsg := 'OK';
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('updation count--->'||SQL%rowcount);
                        errmsg := 'Problem in updation of fee code '||x.cce_fee_code ||' for this PAN.'    ;
                        DBMS_OUTPUT.PUT_LINE('test 3.5-->'||errmsg);
                    END IF;
                    --Now perform the changes for waiver
                    IF errmsg = 'OK' THEN
                        FOR y IN c2(x.cce_fee_code)
                        LOOP
                            lp_waiv_updoprn(y.cce_fee_code, y.cce_valid_from , y.cce_valid_to,newdate,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_updoprn for feecode '||y.cce_fee_code||' and valid date to = '||y.cce_valid_to||' .';
                            END IF;
                        EXIT WHEN c2%NOTFOUND;
                        END LOOP;
                    END IF;
                        DBMS_OUTPUT.PUT_LINE('test out 4');
                END IF;

            EXIT WHEN c1%NOTFOUND;
            END LOOP;

            INSERT INTO CMS_CARD_EXCPFEE(    CCE_INST_CODE        ,
                                            CCE_FEE_CODE        ,
                                            CCE_PAN_CODE        ,
                                            CCE_MBR_NUMB        ,
                                            CCE_VALID_FROM    ,
                                            CCE_VALID_TO        ,
                                            CCE_FLOW_SOURCE    ,
                                            CCE_INS_USER        ,
                                            CCE_LUPD_USER    )
                                VALUES(        instcode        ,
                                            feecode        ,
                                            gethash(pancode)        ,
                                            v_mbrnumb        ,
                                            TRUNC(validfrom),
                                            TRUNC(validto)    ,
                                            flowsource    ,
                                            lupduser        ,
                                            lupduser);
            errmsg := 'OK';


        EXCEPTION    --excp of begin 2
            WHEN OTHERS THEN
            errmsg := 'Excp 2 --'||SQLERRM;
        END ;        --begin 2 ends

    EXCEPTION        --excp of begin 1
        WHEN OTHERS THEN
        errmsg := 'Excp 1 -- '||SQLERRM;
    END;            --begin 1 ends

EXCEPTION    ----exception of main begin
    WHEN OTHERS THEN
    errmsg := 'Main Exception -- '||SQLERRM;
END;        --main begin ends
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---4



-----2
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE sp_create_prodcattypefee(    instcode        IN    NUMBER    ,
                                    prodcode        IN    VARCHAR2    ,
                                    cardtype        IN    NUMBER    ,
                                    feecode        IN    NUMBER    ,
                                    validfrom        IN    DATE        ,
                                    validto        IN    DATE        ,
                                    flowsource    IN    VARCHAR2    ,
                                    lupduser        IN    NUMBER    ,
                                    errmsg        OUT     VARCHAR2    )
AS
v_cfm_feetype_code    NUMBER(3);
v_flowsource            VARCHAR2(3);
newdate                DATE;
mesg                VARCHAR2(500);
CURSOR c1 IS
SELECT    cpf_fee_code, cpf_valid_to, cpf_valid_from
FROM    CMS_PRODCATTYPE_FEES a , CMS_FEE_MAST b
WHERE    a.cpf_inst_code        =    instcode
AND        a.cpf_fee_code        =   feecode
AND        a.cpf_fee_code        =    b.cfm_fee_code
AND        b.cfm_feetype_code    =    v_cfm_feetype_code
AND        a.cpf_prod_code        =    prodcode
AND        a.cpf_card_type        =    cardtype
AND        (TRUNC(validfrom)        BETWEEN TRUNC(cpf_valid_from) AND TRUNC(cpf_valid_to)
        OR TRUNC(validfrom)    < TRUNC(cpf_valid_from));

CURSOR c2 IS
SELECT  cpc_cust_catg
FROM    CMS_PROD_CCC
WHERE    cpc_inst_code        =    instcode
AND        cpc_prod_code    =    prodcode
AND        cpc_card_type    =    cardtype;

CURSOR c3(feecode_from_c1 IN NUMBER) IS--picks up rows for waiver change(if any, i.e. if any waiver is attached to the feecode being changed)
SELECT    cpw_fee_code, cpw_valid_from, cpw_valid_to
FROM    CMS_PRODCATTYPE_WAIV
WHERE    cpw_inst_code        =    instcode
AND        cpw_prod_code        =    prodcode
AND        cpw_card_type        =    cardtype
AND        cpw_fee_code            =    feecode_from_c1    ;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prodcattype level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_updoprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE, l_new_valid_fee_to IN DATE, mesg OUT VARCHAR2)
IS
new_waiv_todate    DATE;
BEGIN
    IF        l_valid_waiv_from <= l_new_valid_fee_to AND l_valid_waiv_to >= l_new_valid_fee_to THEN
            new_waiv_todate := l_new_valid_fee_to;
            IF l_valid_waiv_to = l_new_valid_fee_to THEN
                NULL;
                mesg := 'OK';
            ELSE
                UPDATE CMS_PRODCATTYPE_WAIV
                SET        cpw_valid_to        =    new_waiv_todate,
                        cpw_lupd_user    =      lupduser
                WHERE    cpw_inst_code    =    instcode
                AND        cpw_prod_code    =    prodcode
                AND        cpw_card_type    =    cardtype
                AND        cpw_fee_code        =    l_cce_fee_code
                AND        cpw_valid_from    =    l_valid_waiv_from
                AND        cpw_valid_to        =    l_valid_waiv_to;
                IF SQL%ROWCOUNT = 1 THEN
                    mesg := 'OK';
                ELSE
                    mesg := 'Problem in updation of waiver for fee code '||l_cce_fee_code ||' .'    ;
                END IF;
            END IF;

    ELSIF    l_valid_waiv_from > l_new_valid_fee_to THEN
            DELETE FROM CMS_PRODCATTYPE_WAIV
            WHERE    cpw_inst_code    =    instcode
            AND        cpw_prod_code    =    prodcode
            AND        cpw_card_type    =    cardtype
            AND        cpw_fee_code        =    l_cce_fee_code
            AND        cpw_valid_from    =    l_valid_waiv_from
            AND        cpw_valid_to        =    l_valid_waiv_to;
            IF SQL%ROWCOUNT = 1 THEN
                mesg := 'OK';
            ELSE
                mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
            END IF;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prodcattype level)-*-*-*-*-*-*-*-*-*-*-

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prodcattype level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_deloprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE ,mesg OUT VARCHAR2)
IS

BEGIN
    DELETE FROM CMS_PRODCATTYPE_WAIV
    WHERE    cpw_inst_code    =    instcode
    AND        cpw_prod_code    =    prodcode
    AND        cpw_card_type    =    cardtype
    AND        cpw_fee_code        =    l_cce_fee_code
    AND        cpw_valid_from    =    l_valid_waiv_from
    AND        cpw_valid_to        =    l_valid_waiv_to;
    IF SQL%ROWCOUNT = 1 THEN
        mesg := 'OK';
    ELSE
        mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prodcattype level)-*-*-*-*-*-*-*-*-*-*-


BEGIN        --Main begin
IF flowsource = 'EXP' THEN--this means that the procedure is explicitly called
    v_flowsource := 'PCT';
ELSE    --this means that the procedure is called from some level above PCT. i.e. from product level(P)
    v_flowsource := flowsource;
END IF;

    BEGIN    --begin 1
        SELECT    cfm_feetype_code
        INTO    v_cfm_feetype_code
        FROM    CMS_FEE_MAST
        WHERE    cfm_inst_code =  instcode
        AND        cfm_fee_code  =  feecode;
        errmsg := 'OK';
    EXCEPTION    --excp of begin 1
        WHEN NO_DATA_FOUND THEN
        errmsg    := 'No fee type found for this fee code';
        WHEN OTHERS THEN
        errmsg := 'Excp 1  -- '||SQLERRM;
    END;    --end of begin 1

    IF errmsg = 'OK' THEN    --if 1
        BEGIN        --begin 2
        FOR x IN c1
        LOOP        --loop of cursor c1
            IF errmsg != 'OK' THEN    --if 2
                EXIT;
            END IF;                --if 2
            IF    TRUNC(validfrom) <= TRUNC(x.cpf_valid_from) THEN    --if 3
                        --insert into shadow and then delete
                        INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CAT_TYPE            ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'PCT'        ,
                                                    prodcode        ,
                                                    cardtype        ,
                                                    v_flowsource    ,
                                                    'DELETE'    ,
                                                    lupduser    );
                        DELETE     FROM    CMS_PRODCATTYPE_FEES
                        WHERE            cpf_inst_code        =    instcode
                        AND                cpf_prod_code    =    prodcode
                        AND                cpf_card_type        =    cardtype
                        AND                cpf_fee_code        =    x.cpf_fee_code
                        AND                TRUNC(cpf_valid_from) =     TRUNC(x.cpf_valid_from)
                        AND                TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 4
                                errmsg := 'OK';
                        ELSE                        --else 4
                            IF v_flowsource = 'PCT' THEN--tells us from which level this proc is called so thet the error message can be customised        --if 5
                                errmsg    := 'Problem in deletion of fee code '||x.cpf_fee_code ||' and valid from date is '||x.cpf_valid_from||' .'    ;
                            ELSE                                                                                            --else 5
                                errmsg    := 'From sp_create_prodcattypefee -- Problem in deletion of fee code '||x.cpf_fee_code ||'and valid from date is '||x.cpf_valid_from||'  .'    ;
                            END IF;                                                                                            --if 5
                        END IF;                        --if 4
                            --Now perform the changes for waiver
                            IF errmsg = 'OK' THEN
                                FOR z IN c3(x.cpf_fee_code)
                                LOOP
                                lp_waiv_deloprn(z.cpw_fee_code, z.cpw_valid_from , z.cpw_valid_to,mesg) ;
                                IF mesg != 'OK' THEN
                                    errmsg := 'From local proc lp_waiv_deloprn for feecode '||z.cpw_fee_code||' and valid date to = '||z.cpw_valid_to||' .';
                                END IF;
                                EXIT WHEN c3%NOTFOUND;
                                END LOOP;
                            END IF;
                    ELSE                                            --else 3
                        --insert into shadow and then update
                        INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CAT_TYPE            ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'PCT'        ,
                                                    prodcode        ,
                                                    cardtype        ,
                                                    v_flowsource    ,
                                                    'UPDATE'    ,
                                                    lupduser    );
                        newdate                    :=    TRUNC(validfrom)-1;
                        UPDATE CMS_PRODCATTYPE_FEES
                        SET        cpf_valid_to        =    newdate,
                                cpf_lupd_user        =    lupduser
                        WHERE    cpf_inst_code        =    instcode
                        AND        cpf_prod_code    =    prodcode
                        AND        cpf_card_type        =    cardtype
                        AND        cpf_fee_code        =    x.cpf_fee_code
                        AND        TRUNC(cpf_valid_from)=    TRUNC(x.cpf_valid_from)
                        AND        TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 6
                            errmsg := 'OK';
                        ELSE                        --else 6
                            IF v_flowsource = 'PCT' THEN--tells us from which level this proc is called so thet the error message can be customised    --if 7
                                errmsg    := 'Problem in  updation of fee code '||x.cpf_fee_code ||'  and valid from date is '||x.cpf_valid_from||' .'    ;                                --else 7
                            ELSE
                                errmsg    := 'From sp_create_prodcattypefee -- Problem in updation of fee code '||x.cpf_fee_code ||' and valid from date is '||x.cpf_valid_from||' .'    ;    --if 7
                            END IF;
                        END IF;                        --if 6
                            --Now perform the changes for waiver
                            IF errmsg = 'OK' THEN
                                FOR z IN c3(x.cpf_fee_code)
                                LOOP
                                lp_waiv_updoprn(z.cpw_fee_code, z.cpw_valid_from , z.cpw_valid_to,newdate,mesg) ;
                                IF mesg != 'OK' THEN
                                    errmsg := 'From local proc lp_waiv_updoprn for feecode '||z.cpw_fee_code||' and valid date to = '||z.cpw_valid_to||' .';
                                END IF;
                                EXIT WHEN c3%NOTFOUND;
                                END LOOP;
                            END IF;
                    END IF;                            --if 3
        EXIT WHEN c1%NOTFOUND;
        END LOOP;    --loop of cursor c1
        EXCEPTION    --excp of begin 2
            WHEN OTHERS THEN
            errmsg := 'Excp 2 -- '||SQLERRM;
        END;        --end of begin 2
    END IF;                --if 1

        IF errmsg = 'OK' THEN    --if 8
        BEGIN --begin 3
        INSERT INTO CMS_PRODCATTYPE_FEES    (    CPF_INST_CODE        ,
                                            CPF_PROD_CODE    ,
                                            CPF_CARD_TYPE        ,
                                            CPF_FEE_CODE        ,
                                            CPF_VALID_FROM    ,
                                            CPF_VALID_TO        ,
                                            CPF_FLOW_SOURCE    ,
                                            CPF_INS_USER        ,
                                            CPF_LUPD_USER        )
                                VALUES    (    instcode            ,
                                            prodcode            ,
                                            cardtype            ,
                                            feecode            ,
                                            TRUNC(validfrom)    ,
                                            TRUNC(validto)        ,
                                            v_flowsource        ,
                                            lupduser            ,
                                            lupduser    );
        EXCEPTION    --excp of begin 3
            WHEN OTHERS THEN
            errmsg := 'Excp 3 -- '||SQLERRM;
        END;        --end begin 3
        END IF;                --if 8

                          /*  ------------------------------------------------Flowdown logic------------------------------------------------
                            IF errmsg = 'OK' THEN
                            FOR y IN c2
                            LOOP
                                BEGIN        --Begin 4--flowdown logic , flowdown is upto the card excp fee level
                                    IF    errmsg = 'OK' THEN
                                        Pack_Cms_Feeattach.sp_create_prodcccfee(instcode,y.cpc_cust_catg,prodcode,cardtype,feecode,validfrom,validto,v_flowsource,lupduser,tranCode,feeType,mesg);
                                            IF mesg != 'OK' THEN
                                                errmsg := 'From sp_create_prodcccfee for cust catg '||y.cpc_cust_catg||'  '||mesg;
                                            ELSE
                                                errmsg := mesg;
                                            END IF;
                                    END IF;
                                EXCEPTION    --excp of begin 4
                                WHEN OTHERS THEN
                                errmsg := 'Excp 4 -- '||SQLERRM;
                                END;        --Begin 4 ends
                            EXIT WHEN c2%NOTFOUND;
                            END LOOP;
                            END IF;

                            ------------------------------------------------Flowdown logic------------------------------------------------*/
EXCEPTION    --Excp of main begin
    WHEN OTHERS THEN
    errmsg := 'Main Exception -- '||SQLERRM;
END;        --End main begin

-----2
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-----1
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE sp_create_prodfee    (    instcode        IN    NUMBER    ,
                                prodcode        IN    VARCHAR2    ,
                                feecode        IN    NUMBER    ,
                                validfrom        IN    DATE        ,
                                validto        IN    DATE        ,
                                lupduser        IN    NUMBER    ,
                                errmsg        OUT     VARCHAR2    )
AS
v_cfm_feetype_code    NUMBER(3);
newdate                DATE;
mesg                VARCHAR2(500);

CURSOR c1 IS
SELECT    cpf_fee_code, cpf_valid_to, cpf_valid_from
FROM    CMS_PROD_FEES a , CMS_FEE_MAST b
WHERE    a.cpf_inst_code        =    instcode
AND        a.cpf_fee_code        =   feecode
AND        a.cpf_fee_code        =    b.cfm_fee_code
AND        b.cfm_feetype_code    =    v_cfm_feetype_code
AND        a.cpf_prod_code        =    prodcode
AND        (TRUNC(validfrom)        BETWEEN TRUNC(cpf_valid_from) AND TRUNC(cpf_valid_to)
        OR TRUNC(validfrom)    <TRUNC(cpf_valid_from));

CURSOR c2 IS
SELECT  cpc_card_type
FROM    CMS_PROD_CATTYPE
WHERE    cpc_inst_code        =    instcode
AND        cpc_prod_code    =    prodcode;

CURSOR c3(feecode_from_c1 IN NUMBER) IS--picks up rows for waiver change(if any, i.e. if any waiver is attached to the feecode being changed)
SELECT    cpw_fee_code, cpw_valid_from, cpw_valid_to
FROM    CMS_PROD_WAIV
WHERE    cpw_inst_code        =    instcode
AND        cpw_prod_code        =    prodcode
AND        cpw_fee_code            =    feecode_from_c1    ;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prod level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_updoprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE, l_new_valid_fee_to IN DATE, mesg OUT VARCHAR2)
IS
new_waiv_todate    DATE;
BEGIN
    IF        l_valid_waiv_from <= l_new_valid_fee_to AND l_valid_waiv_to >= l_new_valid_fee_to THEN
            new_waiv_todate := l_new_valid_fee_to;
            IF l_valid_waiv_to = l_new_valid_fee_to THEN
                NULL;
                mesg := 'OK';
            ELSE
                UPDATE CMS_PROD_WAIV
                SET        cpw_valid_to        =    new_waiv_todate,
                        cpw_lupd_user    =      lupduser
                WHERE    cpw_inst_code    =    instcode
                AND        cpw_prod_code    =    prodcode
                AND        cpw_fee_code        =    l_cce_fee_code
                AND        cpw_valid_from    =    l_valid_waiv_from
                AND        cpw_valid_to        =    l_valid_waiv_to;
                IF SQL%ROWCOUNT = 1 THEN
                    mesg := 'OK';
                ELSE
                    mesg := 'Problem in updation of waiver for fee code '||l_cce_fee_code ||' .'    ;
                END IF;
            END IF;

    ELSIF    l_valid_waiv_from > l_new_valid_fee_to THEN
            DELETE FROM CMS_PROD_WAIV
            WHERE    cpw_inst_code    =    instcode
            AND        cpw_prod_code    =    prodcode
            AND        cpw_fee_code        =    l_cce_fee_code
            AND        cpw_valid_from    =    l_valid_waiv_from
            AND        cpw_valid_to        =    l_valid_waiv_to;
            IF SQL%ROWCOUNT = 1 THEN
                mesg := 'OK';
            ELSE
                mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
            END IF;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prod level)-*-*-*-*-*-*-*-*-*-*-

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prod level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_deloprn(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE ,mesg OUT VARCHAR2)
IS

BEGIN
    DELETE FROM CMS_PROD_WAIV
    WHERE    cpw_inst_code    =    instcode
    AND        cpw_prod_code    =    prodcode
    AND        cpw_fee_code        =    l_cce_fee_code
    AND        cpw_valid_from    =    l_valid_waiv_from
    AND        cpw_valid_to        =    l_valid_waiv_to;
    IF SQL%ROWCOUNT = 1 THEN
        mesg := 'OK';
    ELSE
        mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prod level)-*-*-*-*-*-*-*-*-*-*-


BEGIN        --main begin starts
    BEGIN    --begin 1
        SELECT    cfm_feetype_code
        INTO    v_cfm_feetype_code
        FROM    CMS_FEE_MAST
        WHERE    cfm_inst_code =  instcode
        AND        cfm_fee_code  =  feecode;
        errmsg := 'OK';
    EXCEPTION    --excp of begin 1
        WHEN NO_DATA_FOUND THEN
        errmsg    := 'No fee type found for this fee code';
        WHEN OTHERS THEN
        errmsg := 'Excp 1 -- '||SQLERRM;
    END;    --end of begin 1

        IF errmsg = 'OK' THEN    --if 1
        BEGIN        --begin 2
        FOR x IN c1
        LOOP        --loop of cursor c1
            IF errmsg != 'OK' THEN    --if 2
                EXIT;
            END IF;                --if 2
            IF    TRUNC(validfrom) <= TRUNC(x.cpf_valid_from) THEN    --if 3
                        --insert into shadow and then delete
                        INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'P'            ,
                                                    prodcode        ,
                                                    'P'            ,
                                                    'DELETE'    ,
                                                    lupduser    );
                        DELETE     FROM    CMS_PROD_FEES
                        WHERE            cpf_inst_code        =    instcode
                        AND                cpf_prod_code    =    prodcode
                        AND                cpf_fee_code        =    x.cpf_fee_code
                        AND                TRUNC(cpf_valid_from) =     TRUNC(x.cpf_valid_from)
                        AND                TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 4
                            errmsg := 'OK';
                        ELSE                        --else 4
                            errmsg    := 'Problem in deletion of fee code '||x.cpf_fee_code ||' and valid from date is '||x.cpf_valid_from||' .'    ;
                        END IF;                        --if 4
                            --Now perform the changes for waiver
                            IF errmsg = 'OK' THEN
                                FOR z IN c3(x.cpf_fee_code)
                                LOOP
                                lp_waiv_deloprn(z.cpw_fee_code, z.cpw_valid_from , z.cpw_valid_to,mesg) ;
                                IF mesg != 'OK' THEN
                                    errmsg := 'From local proc lp_waiv_deloprn for feecode '||z.cpw_fee_code||' and valid date to = '||z.cpw_valid_to||' .';
                                END IF;
                                EXIT WHEN c3%NOTFOUND;
                                END LOOP;
                            END IF;
                    ELSE                                            --else 3
                        --insert into shadow and then update
                        INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'P'        ,
                                                    prodcode        ,
                                                    'P'    ,
                                                    'UPDATE'    ,
                                                    lupduser    );
                        newdate                    :=    TRUNC(validfrom)-1;
                        UPDATE CMS_PROD_FEES
                        SET        cpf_valid_to        =    newdate,
                                cpf_lupd_user        =    lupduser
                        WHERE    cpf_inst_code        =    instcode
                        AND        cpf_prod_code    =    prodcode
                        AND        cpf_fee_code        =    x.cpf_fee_code
                        AND        TRUNC(cpf_valid_from)=    TRUNC(x.cpf_valid_from)
                        AND        TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 5
                            errmsg := 'OK';
                        ELSE                        --else 5
                            errmsg    := 'Problem in  updation of fee code '||x.cpf_fee_code ||'  and valid from date is '||x.cpf_valid_from||' .'    ;                                --else 7
                        END IF;                        --if 5
                            --Now perform the changes for waiver
                            IF errmsg = 'OK' THEN
                                FOR z IN c3(x.cpf_fee_code)
                                LOOP
                                lp_waiv_updoprn(z.cpw_fee_code, z.cpw_valid_from , z.cpw_valid_to,newdate,mesg) ;
                                IF mesg != 'OK' THEN
                                    errmsg := 'From local proc lp_waiv_updoprn for feecode '||z.cpw_fee_code||' and valid date to = '||z.cpw_valid_to||' .';
                                END IF;
                                EXIT WHEN c3%NOTFOUND;
                                END LOOP;
                            END IF;
                    END IF;                            --if 3
        EXIT WHEN c1%NOTFOUND;
        END LOOP;    --loop of cursor c1
        EXCEPTION    --excp of begin 2
            WHEN OTHERS THEN
            errmsg := 'Excp 2 -- '||SQLERRM;
        END;        --end of begin 2
        END IF;                --if 1

            IF errmsg = 'OK' THEN    --if 6
            BEGIN --begin 3
            INSERT INTO CMS_PROD_FEES    (CPF_INST_CODE        ,
                                        CPF_PROD_CODE    ,
                                        CPF_FEE_CODE        ,
                                        CPF_VALID_FROM    ,
                                        CPF_VALID_TO        ,
                                        CPF_INS_USER        ,
                                        CPF_LUPD_USER        )
                            VALUES    (    instcode    ,
                                        prodcode    ,
                                        feecode    ,
                                        TRUNC(validfrom),
                                        TRUNC(validto),
                                        lupduser    ,
                                        lupduser    );

            EXCEPTION    --Excp of begin 3
            WHEN OTHERS THEN
            errmsg := 'Excp 3 -- '||SQLERRM;
            END;        --end begin 3
            END IF;                --if 6

                   /* IF errmsg = 'OK' THEN    --if 7     --flowdown logic
                    FOR y IN c2
                    LOOP
                        BEGIN        --Begin 4--flowdown logic
                            IF    errmsg = 'OK' THEN    --if 8
                                Pack_Cms_Feeattach.sp_create_prodcattypefee(instcode,prodcode,y.cpc_card_type,feecode,validfrom,validto,'P',lupduser,mesg);
                                IF mesg != 'OK' THEN    --if 9
                                    errmsg := 'From sp_prodcattypefee for cat type  '||y.cpc_card_type||'  '||mesg;
                                ELSE
                                    errmsg := mesg;
                                END IF;                --if 9
                            END IF;                --if 8
                        EXCEPTION    --excp of begin 4
                            WHEN OTHERS THEN
                            errmsg := 'Excp 4 -- '||SQLERRM;
                        END;        --Begin 4 ends
                        EXIT WHEN c2%NOTFOUND;
                    END LOOP;
                    END IF;                --if 7*/


EXCEPTION    --Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Exception -- '||SQLERRM;
END;        --End main begin

-----1
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----3
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE sp_create_prodcccfee    (instcode        IN    NUMBER    ,
                                custcatg        IN    NUMBER    ,
                                prodcode        IN    VARCHAR2    ,
                                cardtype        IN    NUMBER    ,
                                feecode        IN    NUMBER    ,
                                validfrom        IN    DATE        ,
                                validto        IN    DATE        ,
                                flowsource    IN    VARCHAR2    ,
                                feeType    IN    VARCHAR2    ,
                                tranCode    IN    VARCHAR2    ,
                                lupduser        IN    NUMBER    ,
                                errmsg        OUT     VARCHAR2    )
AS
v_cfm_feetype_code    NUMBER(3);
newdate                DATE;
v_flowsource            VARCHAR2(3);
mesg                VARCHAR2(500);

CURSOR c1 IS
SELECT    cpf_fee_code, cpf_tran_code,cpf_fee_type, cpf_func_code, cpf_valid_to, cpf_valid_from
FROM    CMS_PRODCCC_FEES a , CMS_FEE_MAST b
WHERE    a.cpf_inst_code        =    instcode
AND     a.cpf_fee_code      =   feecode
AND        a.cpf_fee_code        =    b.cfm_fee_code
AND        b.cfm_feetype_code    =    v_cfm_feetype_code
AND        a.cpf_prod_code        =    prodcode
AND        a.cpf_card_type        =    cardtype
AND        a.cpf_cust_catg        =    custcatg
AND        (TRUNC(validfrom)        BETWEEN TRUNC(cpf_valid_from) AND TRUNC(cpf_valid_to)
        OR TRUNC(validfrom)    < TRUNC(cpf_valid_from));

CURSOR c2 IS
SELECT  DISTINCT cce_pan_code, cce_mbr_numb
FROM    CMS_CARD_EXCPFEE, CMS_APPL_PAN
WHERE    cce_pan_code        = cap_pan_code
AND        cce_inst_code            = instcode;


CURSOR c3(c_cce_pan_code IN VARCHAR2, c_cce_mbr_numb IN VARCHAR2) IS
SELECT    cce_fee_code, cce_valid_to, cce_valid_from
FROM    CMS_CARD_EXCPFEE a , CMS_FEE_MAST b
WHERE    a.cce_inst_code        =    instcode
AND        a.cce_fee_code        =    b.cfm_fee_code
AND        b.cfm_feetype_code    =    v_cfm_feetype_code
AND        a.cce_pan_code        =    c_cce_pan_code
AND        a.cce_mbr_numb        =    c_cce_mbr_numb
AND        (TRUNC(validfrom)        BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to)
        OR TRUNC(validfrom)    < TRUNC(cce_valid_from));

CURSOR c4(feecode_from_c3 IN NUMBER, pan_from_c2 IN VARCHAR2, mbr_from_c2 IN VARCHAR2) IS--picks up rows for waiver change(if any, i.e. if any waiver is attached to the feecode being changed)
SELECT    cce_fee_code, cce_valid_from, cce_valid_to
FROM    CMS_CARD_EXCPWAIV
WHERE    cce_inst_code            =    instcode
AND        cce_fee_code            =    feecode_from_c3
AND        cce_pan_code        =    pan_from_c2
AND        cce_mbr_numb        =    mbr_from_c2;

CURSOR c5(feecode_from_c1 IN NUMBER) IS--picks up rows for waiver change(if any, i.e. if any waiver is attached to the feecode being changed)
SELECT    cpw_fee_code, cpw_valid_from, cpw_valid_to
FROM    CMS_PRODCCC_WAIV
WHERE    cpw_inst_code        =    instcode
AND        cpw_prod_code        =    prodcode
AND        cpw_cust_catg        =    custcatg
AND        cpw_card_type        =    cardtype
AND        cpw_fee_code            =    feecode_from_c1    ;


--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prod CCC level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_updoprn_pcc(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE, l_new_valid_fee_to IN DATE, mesg OUT VARCHAR2)
IS
new_waiv_todate    DATE;
BEGIN
    IF        l_valid_waiv_from <= l_new_valid_fee_to AND l_valid_waiv_to >= l_new_valid_fee_to THEN
            new_waiv_todate := l_new_valid_fee_to;
            IF l_valid_waiv_to = l_new_valid_fee_to THEN
                NULL;
                mesg := 'OK';
            ELSE
                UPDATE CMS_PRODCCC_WAIV
                SET        cpw_valid_to        =    new_waiv_todate,
                        cpw_lupd_user    =      lupduser
                WHERE    cpw_inst_code    =    instcode
                AND        cpw_prod_code    =    prodcode
                AND        cpw_card_type    =    cardtype
                AND        cpw_cust_catg    =    custcatg
                AND        cpw_fee_code        =    l_cce_fee_code
                AND        cpw_valid_from    =    l_valid_waiv_from
                AND        cpw_valid_to        =    l_valid_waiv_to;
                IF SQL%ROWCOUNT = 1 THEN
                    mesg := 'OK';
                ELSE
                    mesg := 'Problem in updation of waiver for fee code '||l_cce_fee_code ||' .'    ;
                END IF;
            END IF;

    ELSIF    l_valid_waiv_from > l_new_valid_fee_to THEN
            DELETE FROM CMS_PRODCCC_WAIV
            WHERE    cpw_inst_code    =    instcode
            AND        cpw_prod_code    =    prodcode
            AND        cpw_card_type    =    cardtype
            AND        cpw_cust_catg    =    custcatg
            AND        cpw_fee_code        =    l_cce_fee_code
            AND        cpw_valid_from    =    l_valid_waiv_from
            AND        cpw_valid_to        =    l_valid_waiv_to;
            IF SQL%ROWCOUNT = 1 THEN
                mesg := 'OK';
            ELSE
                mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
            END IF;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for Prod CCC level)-*-*-*-*-*-*-*-*-*-*-

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prod CCC level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_deloprn_pcc(l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE ,mesg OUT VARCHAR2)
IS

BEGIN
    DELETE FROM CMS_PRODCCC_WAIV
    WHERE    cpw_inst_code    =    instcode
    AND        cpw_prod_code    =    prodcode
    AND        cpw_card_type    =    cardtype
    AND        cpw_cust_catg    =    custcatg
    AND        cpw_fee_code        =    l_cce_fee_code
    AND        cpw_valid_from    =    l_valid_waiv_from
    AND        cpw_valid_to        =    l_valid_waiv_to;
    IF SQL%ROWCOUNT = 1 THEN
        mesg := 'OK';
    ELSE
        mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' .'    ;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for Prod CCC level)-*-*-*-*-*-*-*-*-*-*-


--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for card excp level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_updoprn_excp(l_pancode IN VARCHAR2, l_mbrnumb IN VARCHAR2, l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE, l_new_valid_fee_to IN DATE, mesg OUT VARCHAR2)
IS
new_waiv_todate    DATE;
BEGIN
    IF        l_valid_waiv_from <= l_new_valid_fee_to AND l_valid_waiv_to >= l_new_valid_fee_to THEN
            new_waiv_todate := l_new_valid_fee_to;
            IF l_valid_waiv_to = l_new_valid_fee_to THEN
                NULL;
                mesg := 'OK';
            ELSE
                UPDATE CMS_CARD_EXCPWAIV
                SET        cce_valid_to        =    new_waiv_todate,
                        cce_lupd_user    =      lupduser
                WHERE    cce_inst_code        =    instcode
                AND        cce_fee_code        =    l_cce_fee_code
                AND        cce_pan_code    =    l_pancode
                AND        cce_mbr_numb    =    l_mbrnumb
                AND        cce_valid_from    =    l_valid_waiv_from
                AND        cce_valid_to        =    l_valid_waiv_to;
                IF SQL%ROWCOUNT = 1 THEN
                    mesg := 'OK';
                ELSE
                    mesg := 'Problem in updation of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
                END IF;
            END IF;

    ELSIF    l_valid_waiv_from > l_new_valid_fee_to THEN
            DELETE FROM CMS_CARD_EXCPWAIV
            WHERE    cce_inst_code        =    instcode
            AND        cce_fee_code        =    l_cce_fee_code
            AND        cce_pan_code    =    l_pancode
            AND        cce_mbr_numb    =    l_mbrnumb
            AND        cce_valid_from    =    l_valid_waiv_from
            AND        cce_valid_to        =    l_valid_waiv_to;
            IF SQL%ROWCOUNT = 1 THEN
                mesg := 'OK';
            ELSE
                mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
            END IF;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is updated(for card excp level)-*-*-*-*-*-*-*-*-*-*-

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for card excp level)-*-*-*-*-*-*-*-*-*-*-
PROCEDURE    lp_waiv_deloprn_excp(l_pancode IN VARCHAR2, l_mbrnumb IN VARCHAR2, l_cce_fee_code IN NUMBER, l_valid_waiv_from IN DATE, l_valid_waiv_to IN DATE ,mesg OUT VARCHAR2)
IS

BEGIN
    DELETE FROM CMS_CARD_EXCPWAIV
    WHERE    cce_inst_code        =    instcode
    AND        cce_fee_code        =    l_cce_fee_code
    AND        cce_pan_code    =    l_pancode
    AND        cce_mbr_numb    =    l_mbrnumb
    AND        cce_valid_from    =    l_valid_waiv_from
    AND        cce_valid_to        =    l_valid_waiv_to;
    IF SQL%ROWCOUNT = 1 THEN
        mesg := 'OK';
    ELSE
        mesg := 'Problem in deletion of waiver for fee code '||l_cce_fee_code ||' for this PAN.'    ;
    END IF;
END;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure to do the changes for waiver when a fee is deleted(for card excp level)-*-*-*-*-*-*-*-*-*-*-

BEGIN        --Main begin starts
IF flowsource = 'EXP' THEN--this means that the procedure is explicitly called
    v_flowsource := 'PCC';
ELSE    --this means that the procedure is called from some level above PCC. i.e. either from product level(P) or from product cattype level(PCT)
    v_flowsource := flowsource;
END IF;
    BEGIN    --begin 1
        SELECT    cfm_feetype_code
        INTO    v_cfm_feetype_code
        FROM    CMS_FEE_MAST
        WHERE    cfm_inst_code =  instcode
        AND        cfm_fee_code  =  feecode;
        errmsg := 'OK';
    EXCEPTION    --excp of begin 1
        WHEN NO_DATA_FOUND THEN
        errmsg    := 'No fee type found for this fee code';
        WHEN OTHERS THEN
        errmsg := 'Excp 1 -- '||SQLERRM;
    END;    --end of begin 1

    IF errmsg = 'OK' THEN    --if 1
        BEGIN        --begin 2
        FOR x IN c1
        LOOP        --loop of cursor c1
            IF errmsg != 'OK' THEN    --if 2
                EXIT;
            END IF;                --if 2

                IF   (TRUNC(validfrom) BETWEEN TRUNC(x.cpf_valid_from) AND TRUNC(x.cpf_valid_to) OR TRUNC(validfrom)    < TRUNC(x.cpf_valid_from))  THEN    --if 3

             --added on 081111
                  --IF c1%ROWCOUNT > 0
                 -- THEN
                     raise_application_error
                                        (-20001,
                                            ' Fee is already attached  '
                                         || ' between this date range From '
                                         || x.cpf_valid_from
                                         || ' and to '
                                         || x.cpf_valid_to
                                        );
                  --END IF;
                  --ended on 081111
                   --commented on 081111
                        --insert into shadow and then delete
                      /*  INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CAT_TYPE            ,
                                                    CAH_CUST_CATG            ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'PCC'        ,
                                                    prodcode        ,
                                                    cardtype        ,
                                                    custcatg        ,
                                                    v_flowsource    ,
                                                    'DELETE'    ,
                                                    lupduser    );
                        DELETE     FROM    CMS_PRODCCC_FEES
                        WHERE            cpf_inst_code        =    instcode
                        AND                cpf_prod_code    =    prodcode
                        AND                cpf_card_type        =    cardtype
                        AND                cpf_cust_catg        =    custcatg
                        AND                cpf_fee_code        =    x.cpf_fee_code
                        AND                cpf_fee_type        =    x.cpf_fee_type
                        AND                cpf_tran_code        =    x.cpf_tran_code
                        AND                cpf_func_code        =    x.cpf_func_code
                        AND                TRUNC(cpf_valid_from) =     TRUNC(x.cpf_valid_from)
                        AND                TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 4
                                errmsg := 'OK';
                        ELSE                        --else 4
                            IF v_flowsource = 'PCC' THEN--tells us from which level this proc is called so thet the error message can be customised        --if 5
                                errmsg    := 'Problem in deletion of fee code '||x.cpf_fee_code ||' and valid from date is '||x.cpf_valid_from||' .'    ;
                            ELSE                                                                                            --else 5
                                errmsg    := 'From sp_create_prodcccfee -- Problem in deletion of fee code '||x.cpf_fee_code ||'and valid from date is '||x.cpf_valid_from||'  .'    ;
                            END IF;                                                                                            --if 5
                        END IF;                        --if 4
                        --Now perform the changes for waiver
                        IF errmsg = 'OK' THEN
                            FOR b IN c5(x.cpf_fee_code)
                            LOOP
                            lp_waiv_deloprn_pcc(b.cpw_fee_code, b.cpw_valid_from , b.cpw_valid_to,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_deloprn_pcc for feecode '||b.cpw_fee_code||' and valid date to = '||b.cpw_valid_to||' .';
                            END IF;
                            EXIT WHEN c5%NOTFOUND;
                            END LOOP;
                        END IF;*/
               /* ELSE                                            --else 3
                        --insert into shadow and then update
                        INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CAT_TYPE            ,
                                                    CAH_CUST_CATG            ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                            VALUES(    instcode        ,
                                                    feecode        ,
                                                    x.cpf_valid_from,
                                                    x.cpf_valid_to    ,
                                                    'PCC'        ,
                                                    prodcode        ,
                                                    cardtype        ,
                                                    custcatg        ,
                                                    v_flowsource    ,
                                                    'INSERT'    ,
                                                    lupduser    );
                       newdate                    :=    TRUNC(validfrom)-1;
                        UPDATE CMS_PRODCCC_FEES
                        SET        cpf_valid_to        =    newdate,
                                cpf_lupd_user        =    lupduser
                        WHERE    cpf_inst_code        =    instcode
                        AND        cpf_prod_code    =    prodcode
                        AND        cpf_card_type        =    cardtype
                        AND        cpf_cust_catg        =    custcatg
                        AND        cpf_fee_code        =    x.cpf_fee_code
                        AND        cpf_fee_type        =    x.cpf_fee_type
                        --AND        cpf_tran_code        =    x.cpf_tran_code
                        AND        cpf_func_code        =    x.cpf_func_code
                        AND        TRUNC(cpf_valid_from)=    TRUNC(x.cpf_valid_from)
                        AND        TRUNC(cpf_valid_to)    =    TRUNC(x.cpf_valid_to);
                        IF SQL%ROWCOUNT = 1 THEN    --if 6
                            errmsg := 'OK';
                        ELSE                        --else 6
                            IF v_flowsource = 'PCC' THEN--tells us from which level this proc is called so thet the error message can be customised    --if 7
                                errmsg    := 'Problem in  updation of fee code. '||x.cpf_fee_code ||'  and valid from date is '||x.cpf_valid_from||' .'    ;                                --else 7
                            ELSE
                                errmsg    := 'From sp_create_prodcccfee -- Problem in updation of fee code '||x.cpf_fee_code ||' and valid from date is '||x.cpf_valid_from||' .'    ;    --if 7
                            END IF;
                        END IF;                        --if 6
                    --Now perform the changes for waiver
                    IF errmsg = 'OK' THEN
                        FOR b IN c5(x.cpf_fee_code)
                        LOOP
                            lp_waiv_updoprn_pcc(b.cpw_fee_code, b.cpw_valid_from , b.cpw_valid_to,newdate,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_updoprn_pcc for feecode '||b.cpw_fee_code||' and valid date to = '||b.cpw_valid_to||' .';
                            END IF;
                        EXIT WHEN c5%NOTFOUND;
                        END LOOP;
                    END IF;*/

                END IF;                            --if 3
        EXIT WHEN c1%NOTFOUND;
        END LOOP;    --loop of cursor c1
        EXCEPTION    --excp of begin 2
            WHEN OTHERS THEN
            errmsg := 'Excp 2 -- '||SQLERRM;
        END;        --end of begin 2
    END IF;                --if 1

        IF errmsg = 'OK' THEN    --if 8
        BEGIN --begin 3
           INSERT INTO CMS_ATTCHFEE_HIST(    CAH_INST_CODE            ,
                                                    CAH_FEE_CODE            ,
                                                    CAH_OLD_FROMDATE        ,
                                                    CAH_OLD_TODATE        ,
                                                    CAH_CHANGE_LEVEL        ,
                                                    CAH_PROD_CODE        ,
                                                    CAH_CAT_TYPE            ,
                                                    CAH_CUST_CATG            ,
                                                    CAH_CHANGE_SOURCE    ,
                                                    CAH_ACTION_TAKEN        ,
                                                    CAH_CHANGE_USER        )
                                                     VALUES(    instcode        ,
                                                    feecode        ,
                                                     TRUNC(validfrom),
                                        TRUNC(validto)    ,
                                                    'PCC'        ,
                                                    prodcode        ,
                                                    cardtype        ,
                                                    custcatg        ,
                                                    v_flowsource    ,
                                                    'INSERT'    ,
                                                    lupduser    );
        INSERT INTO CMS_PRODCCC_FEES(    CPF_INST_CODE        ,
                                        CPF_CUST_CATG        ,
                                        CPF_CARD_TYPE        ,
                                        CPF_PROD_CODE      ,
                                        CPF_FEE_CODE        ,
                                        CPF_VALID_FROM    ,
                                        CPF_VALID_TO        ,
                                        CPF_FLOW_SOURCE    ,
                                        CPF_INS_USER        ,
                                        CPF_LUPD_USER ,
                                        CPF_TRAN_CODE ,
                                        CPF_FEE_TYPE           )
                            VALUES    (    instcode        ,
                                        custcatg        ,
                                        cardtype        ,
                                        prodcode        ,
                                        feecode        ,
                                        TRUNC(validfrom),
                                        TRUNC(validto)    ,
                                        v_flowsource    ,
                                        lupduser        ,
                                        lupduser        ,
                                        tranCode        ,
                                        feeType             );
        EXCEPTION    --Excp of begin 3
        WHEN OTHERS THEN
        errmsg := 'Excp 3 -- '||SQLERRM;
        END;        --end begin 3
        END IF;                --if 8

        --commented on 22-03-02 because its not yet decided whether to flow down the fees to the card excp level
        --therefore we are temporarily deciding that we will not flow(insert, update or delete) the fees to card excp level.
        --to assign fees to the card excp level, use the procedure to attach the fees exceptionally to a card
        /*    IF errmsg = 'OK' THEN
            FOR y IN c2
            LOOP
            ----------------------------------------Flow down logic
            BEGIN    --begin 4 starts
            FOR z IN c3(y.cce_pan_code,y.cce_mbr_numb)
            LOOP
            IF errmsg != 'OK' THEN
            EXIT;
            END IF;

                --now perform the reqd operation on the current row of the resultset
                IF    trunc(validfrom) <= trunc(z.cce_valid_from) THEN
                dbms_output.put_line('test out 2');
    --                insert into shadow and then delete
                    INSERT INTO cms_attchfee_hist(    CAH_INST_CODE            ,
                                                CAH_FEE_CODE            ,
                                                CAH_OLD_FROMDATE            ,
                                                CAH_OLD_TODATE            ,
                                                CAH_CHANGE_LEVEL        ,
                                                CAH_PAN_CODE            ,
                                                CAH_MBR_NUMB            ,
                                                CAH_CHANGE_SOURCE    ,
                                                CAH_ACTION_TAKEN        ,
                                                CAH_CHANGE_USER        )
                                        VALUES(    instcode        ,
                                                z.cce_fee_code    ,
                                                z.cce_valid_from,
                                                z.cce_valid_to    ,
                                                'C'            ,
                                                y.cce_pan_code    ,
                                                y.cce_mbr_numb    ,
                                                v_flowsource    ,
                                                'DELETE'    ,
                                                lupduser    );


                    DELETE     FROM    cms_card_excpfee
                    WHERE            cce_inst_code        =    instcode
                    AND                cce_pan_code    =    y.cce_pan_code
                    AND                cce_mbr_numb    =    y.cce_mbr_numb
                    AND                cce_fee_code        =    z.cce_fee_code
                    AND                cce_valid_from    =    z.cce_valid_from
                    AND                cce_valid_to        =    z.cce_valid_to;
                    IF SQL%ROWCOUNT = 1 THEN
                        errmsg := 'OK';
                    ELSE
                        errmsg := 'Problem in deletion of fee code '||z.cce_fee_code ||' for this PAN.'    ;
                    END IF;
                        --Now perform the changes for waiver
                        IF errmsg = 'OK' THEN
                            FOR a IN c4(z.cce_fee_code, y.cce_pan_code, y.cce_mbr_numb)
                            LOOP
                            lp_waiv_deloprn_excp(y.cce_pan_code, y.cce_mbr_numb, a.cce_fee_code, a.cce_valid_from , a.cce_valid_to,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_deloprn_excp for feecode '||a.cce_fee_code||' and valid date to = '||a.cce_valid_to||' .';
                            END IF;
                            EXIT WHEN c4%NOTFOUND;
                            END LOOP;
                        END IF;

                ELSE
                dbms_output.put_line('test out 3');
    --                insert into shadow and then update
                    INSERT INTO cms_attchfee_hist(    CAH_INST_CODE            ,
                                                CAH_FEE_CODE            ,
                                                CAH_OLD_FROMDATE            ,
                                                CAH_OLD_TODATE            ,
                                                CAH_CHANGE_LEVEL        ,
                                                CAH_PAN_CODE            ,
                                                CAH_MBR_NUMB            ,
                                                CAH_CHANGE_SOURCE    ,
                                                CAH_ACTION_TAKEN        ,
                                                CAH_CHANGE_USER        )
                                        VALUES(    instcode        ,
                                                z.cce_fee_code        ,
                                                z.cce_valid_from,
                                                z.cce_valid_to    ,
                                                'C'            ,
                                                y.cce_pan_code        ,
                                                y.cce_mbr_numb        ,
                                                v_flowsource    ,
                                                'UPDATE'    ,
                                                lupduser    );
                    newdate    :=    trunc(validfrom)-1    ;
                    UPDATE cms_card_excpfee
                    SET        cce_valid_to        =    newdate,
                            cce_lupd_user    =    lupduser
                    WHERE    cce_inst_code        =    instcode
                    AND        cce_pan_code    =    y.cce_pan_code
                    AND        cce_mbr_numb    =    y.cce_mbr_numb
                    AND        cce_fee_code        =    z.cce_fee_code
                    AND        cce_valid_from    =    z.cce_valid_from
                    AND        cce_valid_to        =    z.cce_valid_to;
                    IF SQL%ROWCOUNT = 1 THEN
                        errmsg := 'OK';
                    ELSE
                        dbms_output.put_line('updation count--->'||sql%rowcount);
                        errmsg := 'Problem in updation of fee code '||z.cce_fee_code ||' for this PAN.'    ;
                        dbms_output.put_line('test 3.5-->'||errmsg);
                    END IF;
                        --Now perform the changes for waiver
                    IF errmsg = 'OK' THEN
                        FOR a IN c4(z.cce_fee_code,y.cce_pan_code,y.cce_mbr_numb)
                        LOOP
                            lp_waiv_updoprn_excp(y.cce_pan_code, y.cce_mbr_numb, a.cce_fee_code, a.cce_valid_from , a.cce_valid_to,newdate,mesg) ;
                            IF mesg != 'OK' THEN
                                errmsg := 'From local proc lp_waiv_updoprn_excp for feecode '||a.cce_fee_code||' and valid date to = '||a.cce_valid_to||' .';
                            END IF;
                        EXIT WHEN c4%NOTFOUND;
                        END LOOP;
                    END IF;
                END IF;
            EXIT WHEN c3%NOTFOUND;
            END LOOP;--end of loop for c3

                    IF errmsg = 'OK' THEN
                    BEGIN--begin 5
                    INSERT INTO cms_card_excpfee(CCE_INST_CODE        ,
                                            CCE_FEE_CODE        ,
                                            CCE_PAN_CODE        ,
                                            CCE_MBR_NUMB        ,
                                            CCE_VALID_FROM    ,
                                            CCE_VALID_TO        ,
                                            CCE_FLOW_SOURCE    ,
                                            CCE_INS_USER        ,
                                            CCE_LUPD_USER    )
                                VALUES(        instcode        ,
                                            feecode        ,
                                            y.cce_pan_code        ,
                                            y.cce_mbr_numb        ,
                                            trunc(validfrom),
                                            trunc(validto)    ,
                                            v_flowsource    ,
                                            lupduser        ,
                                            lupduser);
                    EXCEPTION    --excp of begin 5
                    WHEN OTHERS THEN
                    errmsg := 'Excp 5 --'||SQLERRM;
                    END;        --end of begin 5
                    END IF;

        EXCEPTION    --excp of begin 4
        WHEN OTHERS THEN
        errmsg := 'Excp 4 --'||SQLERRM;
        END ;        --begin 4 ends
            -----------------------------------------Flow down logic
            EXIT WHEN c2%NOTFOUND;
            END LOOP;--loop for c2 ends
            END IF;*/

EXCEPTION    --Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Exception -- '||SQLERRM;
END;        --End main begin
-----3
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
END;----End Package Body
/


