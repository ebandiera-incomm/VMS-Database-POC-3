create or replace PROCEDURE        VMSCMS.SP_SAVING_RPT(
                                    p_date       in   date,
                                    p_directory  in   VARCHAR2,
                                    p_err        out  VARCHAR2
                                    )
IS

v_file_handle UTL_FILE.file_type;
v_wrt_buff VARCHAR2 (2000);
v_filename VARCHAR2 (50);
v_cnt  NUMBER :=0;
v_excp EXCEPTION;

BEGIN
    v_filename := 'NEWsavingstransactionsfile'||TO_CHAR(p_date,'MMDDYYYY')||'.txt';

    BEGIN
        IF UTL_FILE.is_open (v_file_handle) THEN
            UTL_FILE.fflush (v_file_handle);
            UTL_FILE.fclose (v_file_handle);
        END IF;
        v_file_handle := UTL_FILE.fopen (p_directory, v_filename, 'w');
    EXCEPTION
        WHEN OTHERS THEN
            p_err := 'ERROR OPENING FILE (W) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excp;
    END;

    v_wrt_buff :='HHEADER'||rpad('InComm',50)||rpad('SAVINGS TRANSACTIONS',50)||rpad(to_char(p_date,'MMDDYYYY'),8)||rpad(to_char(p_date,'MMDDYYYY'),8);
    UTL_FILE.put_line (v_file_handle, v_wrt_buff);

    FOR cur_rep in(SELECT
                    'D' recordtype,
                    (SELECT CDP_PARAM_VALUE
                    FROM CMS_DFG_PARAM
                    WHERE UPPER(CDP_PARAM_KEY) = 'PROGRAMID'
                    AND CDP_INST_CODE          = 1
                    ) progid,
                    cam_acct_no,
                    TO_CHAR (csl_trans_date, 'MMDDYYYY') csl_trans_date,
                    DECODE(csl_delivery_channel
                    ||csl_txn_code,'0513','Int Post',DECODE (csl_trans_type, 'DR', 'Withdrawal', 'CR', 'Deposit')) ctm_tran_desc,
                    TRIM (TO_CHAR (csl_trans_amount, '9999999990.99')) csl_trans_amount,
                    DECODE (csl_trans_type, 'DR', '-', 'CR', '+') csl_trans_type,
                    TO_CHAR (csl_trans_date, 'HH24:MM:SS') csl_trans_time,
                    csl_auth_id,
                    ccm_cust_id,
                    cca_cust_code,
                    csl_delivery_channel,
                    csl_txn_code
                    FROM VMSCMS.cms_statements_log_VW, --- Added FSP-991 cHnages
                    cms_acct_mast,
                    cms_cust_acct,
                    cms_cust_mast
                    WHERE csl_acct_no         = cam_acct_no
                    AND cam_acct_id           = cca_acct_id
                    AND cam_type_code         = 2
                    AND ccm_inst_code         =1
                    AND TRUNC(csl_trans_date) = TRUNC(p_date)
                    AND cca_cust_code         =ccm_cust_code)
    loop
        begin
            v_cnt := v_cnt+1;
            v_wrt_buff:=cur_rep.recordtype||rpad(cur_rep.progid,15)||rpad(cur_rep.cam_acct_no,30)||
            rpad(cur_rep.csl_trans_date,8)||rpad(cur_rep.ctm_tran_desc,15)||rpad(cur_rep.csl_trans_amount,13)||
            rpad(cur_rep.csl_trans_type,1)||rpad(cur_rep.csl_trans_time,50)||rpad(cur_rep.csl_auth_id,50)||
            rpad(cur_rep.ccm_cust_id,50);
            UTL_FILE.put_line (v_file_handle, v_wrt_buff);
        exception
            when others then
                raise v_excp;
        end;
    end loop;

    v_wrt_buff := 'TTRAILER'||rpad(v_cnt,9,0);
    UTL_FILE.put_line (v_file_handle, v_wrt_buff);

    UTL_FILE.fflush (v_file_handle);
    UTL_FILE.fclose (v_file_handle);
EXCEPTION
    WHEN v_excp THEN
        UTL_FILE.fflush (v_file_handle);
        UTL_FILE.fclose (v_file_handle);
    WHEN OTHERS THEN
        p_err := SUBSTR (SQLERRM, 1, 200);
        UTL_FILE.fflush (v_file_handle);
        UTL_FILE.fclose (v_file_handle);
END sp_saving_rpt;
/
SHOW ERROR;