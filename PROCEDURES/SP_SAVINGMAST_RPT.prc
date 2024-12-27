CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVINGMAST_RPT(
                                        P_DATE       IN  DATE,
                                        P_DIRECTORY  IN  VARCHAR2,
                                        P_ERR        OUT VARCHAR2 )
IS
v_prm_val cms_dfg_param.cdp_param_value%type;
v_int_amt   varchar2(50):='0.000000000';
v_qtd_int_accrued   varchar2(50):='0.000000000'; -- Included for qtd_interest_accrued - arun
v_close_bal varchar2(50):='0.00';
v_comp_bal  varchar2(50):='0.000000000';
v_acct_no cms_acct_mast.cam_acct_no%type :='' ;
v_interest_rate cms_inactivesavings_acct.cia_interest_rate%type :='0.000000000' ;
v_interest_factor varchar2(50);
v_prog_id         varchar2(50);
v_savinterest_rate   varchar2(50);
v_file_handle utl_file.file_type;
v_wrt_buff varchar2 (2000);
v_filename varchar2 (50);
v_cnt      number :=0;
v_excp     exception;
BEGIN
    v_filename := 'NEWsavingsmasterfile'||TO_CHAR(P_DATE,'MMDDYYYY')||'.txt';

    BEGIN
        IF UTL_FILE.is_open (v_file_handle) THEN
            UTL_FILE.fflush (v_file_handle);
            UTL_FILE.fclose (v_file_handle);
        END IF;
        v_file_handle := UTL_FILE.fopen (p_directory, v_filename, 'w');
    EXCEPTION
        WHEN OTHERS THEN
            P_ERR := 'ERROR OPENING FILE (W) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excp;
    END;

    v_wrt_buff :='HHEADER'||rpad('InComm',50)||rpad('SAVINGS MASTER',50)||rpad(TO_CHAR(sysdate,'mmddyyyy'),8)||rpad(TO_CHAR(sysdate,'mmddyyyy'),8);
    UTL_FILE.put_line (v_file_handle, v_wrt_buff);

    BEGIN
        SELECT  CDP_PARAM_VALUE
        INTO v_savinterest_rate
        FROM CMS_DFG_PARAM
        WHERE UPPER(CDP_PARAM_KEY) = 'SAVING ACCOUNT INTEREST RATE'
        AND CDP_INST_CODE          = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    begin
       -- select trim(to_char(cdp_param_value, '999D9999999999'))
        select ROUND((v_savinterest_rate/365/100),10) --Interest factor to be calculated -arun
        into v_interest_factor
        from dual;
       -- WHERE UPPER(CDP_PARAM_KEY)='INTERESTFACTOR'
      --  AND CDP_INST_CODE         = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        SELECT CDP_PARAM_VALUE
        INTO v_prog_id
        FROM CMS_DFG_PARAM
        WHERE UPPER(CDP_PARAM_KEY) = 'PROGRAMID'
        AND CDP_INST_CODE          = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    FOR cur_rep IN  (SELECT 'D' RECORDTYPE,
                    CCA_CUST_CODE,
                    CAM_ACCT_NO,
                    CAM_ACCT_ID,
                    DECODE(CAM_STAT_CODE, '2', 'Closed', '8', 'Open') CAM_STAT_CODE,
                    TO_CHAR(CAM_CREATION_DATE, 'mmddyyyy') CAM_CREATION_DATE,
                    '+' AS SIGN,
                    'Y' AS ESIGN,
                    to_char(cam_accpt_date, 'mmddyyyy') cam_accpt_date
                   -- TRIM(TO_CHAR(CAM_INTEREST_AMOUNT, '999999G99G99G990D999999999')) CAM_INS_AMT - arun -Commenetd since this column will not used anymore for qtd_interest_accrued
                    FROM CMS_ACCT_MAST ,
                    CMS_CUST_ACCT
                    WHERE CAM_ACCT_ID = CCA_ACCT_ID
                    AND CAM_TYPE_CODE = 2
                    ORDER BY CAM_ACCPT_DATE ASC  )
    LOOP

        BEGIN
            select trim(to_char(cid_interest_amount, '999999G99G99G990D999999999')),
            trim(to_char(cid_close_balance - cid_interest_amount, '9999999990.99')), --arun -Modified to fetch the current balance
            trim(to_char(cid_compound_balance, '9999999990.999999999')),  -- arun -Modified to fetch the compound balance
            TRIM(TO_CHAR(cid_qtly_interest_accr, '999999G99G99G990D999999999')) -- arun -Included to fetch qtd_interest_accrued from cms_interest_accrued instead of cms_acct_mast
            INTO V_INT_AMT,
            v_close_bal,
            v_comp_bal,
            v_qtd_int_accrued
            FROM CMS_INTEREST_DETL
            WHERE CID_ACCT_NO        = cur_rep.CAM_ACCT_NO
            AND TRUNC(CID_CALC_DATE) =TRUNC(P_DATE);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                P_ERR := 'ERROR WHILE SELECTING DATA FROM INTEREST DETL ' || SUBSTR(SQLERRM, 1, 200);
                RAISE v_excp;
        END;

        BEGIN
            SELECT CAM_ACCT_NO
            INTO V_ACCT_NO
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_ID IN
            (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
            WHERE CCA_CUST_CODE = cur_rep.CCA_CUST_CODE
            AND CAM_TYPE_CODE   = 1 );
        EXCEPTION
            WHEN TOO_MANY_ROWS THEN
                NULL;
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                P_ERR := 'ERROR WHILE SELECTING ACCOUNT NUMBER ' || SUBSTR(SQLERRM, 1, 200);
                RAISE v_excp;
        END;

        BEGIN
            SELECT TRIM(TO_CHAR(CIA_INTEREST_RATE,'999999G99G99G990D999999999'))
            INTO v_interest_rate
            FROM CMS_INACTIVESAVINGS_ACCT
            WHERE CIA_SAVINGSACCT_NO    = cur_rep.CAM_ACCT_NO
            AND TRUNC(CIA_CLOSING_DATE) = TRUNC(
            (SELECT MAX(CIA_CLOSING_DATE)
            FROM CMS_INACTIVESAVINGS_ACCT
            WHERE CIA_SAVINGSACCT_NO    = cur_rep.CAM_ACCT_NO
            AND TRUNC(CIA_CLOSING_DATE) = TRUNC(P_DATE)));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                P_ERR := 'ERROR WHILE SELECTING INACTIVE ACCT ' || SUBSTR(SQLERRM, 1, 200);
                RAISE V_EXCP;
        END;

        v_cnt     := v_cnt+1;

        V_WRT_BUFF:=CUR_REP.RECORDTYPE||
        RPAD(V_PROG_ID,15)|| -- (Unique Program Id)
        RPAD(CUR_REP.CAM_ACCT_NO,30)|| -- (Savings Account Number)
        RPAD(CUR_REP.CAM_ACCPT_DATE,8)|| -- (Open Date)
        RPAD(CUR_REP.CAM_STAT_CODE,50)|| -- (Account Status)
        rpad(cur_rep.cam_creation_date,8)|| -- (Account Status Date)
        RPAD(V_CLOSE_BAL,13)|| -- (Curr Savings Balance) --arun -Modified . Current balance will be fetched by subtracting cid_interest_amount from cid_close_balance
        RPAD(CUR_REP.SIGN,1)|| -- (Curr balance Sign)
        RPAD(CUR_REP.ESIGN,1)|| -- (ESign)
        RPAD(CUR_REP.CAM_ACCPT_DATE,8)||  -- (ESign optout Date)
        RPAD(V_ACCT_NO,30)||   -- (GPR Account Number)
        rpad(v_savinterest_rate,7)|| -- (Interest Rate)
        RPAD(V_INTEREST_FACTOR,11)|| -- (Interest Factor ) -- arun-Modified. It should be calculated as ROUND((V_SAVINTEREST_RATE/365/100),10);
        rpad(v_int_amt,20)||    -- (Daily Interest Accrued)
       -- RPAD(CUR_REP.CAM_INS_AMT,20)||
        RPAD(v_qtd_int_accrued,20)|| -- (QTD Interest Accrued)--arun-Modified - QTD interest accrued will be fetched from cms_interest_detl instead of cms_acct_mast
        rpad(v_interest_rate,20)|| --(QTD Interest Forfeited)
        rpad(V_COMP_BAL,20); -- (Compount Balance) -- arun-Modified. -Compound balance fetched from cid_compound_balance column of cms_interest_detl table

        utl_file.put_line (v_file_handle, v_wrt_buff);


    END LOOP;

    v_wrt_buff := 'TTRAILER'||lpad(v_cnt,9,0);
    UTL_FILE.put_line (v_file_handle, v_wrt_buff);
    UTL_FILE.fflush (v_file_handle);
    UTL_FILE.fclose (v_file_handle);
EXCEPTION
    WHEN v_excp THEN
        UTL_FILE.fflush (v_file_handle);
        UTL_FILE.fclose (v_file_handle);
    WHEN OTHERS THEN
        UTL_FILE.fflush (v_file_handle);
        UTL_FILE.fclose (v_file_handle);
END SP_SAVINGMAST_RPT;
/

SHOW ERRORS