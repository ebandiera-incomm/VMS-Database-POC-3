create or replace
procedure        VMSCMS.SP_CARD_RENEW_ONETIME (
                                        p_prod_code     in  varchar2,
                                        p_card_no       in  number,
                                        p_dir_name      in  varchar2,
                                        p_file_name     out varchar2,
                                        p_err_msg       out varchar2)                                            
is
/*************************************************
     * Created Date     :  08-JAN-2015
     * Created By       :  Saravanakumar A
     * PURPOSE          :  MIO To LYFE MIgration
     
     * Modified by      :  Saravanakumar A
     * Modified Reason  :  Defect id:16004
     * Modified Date    :  22-JAN-2015
     * Build Number     :  RI0027.4.2.4.1_B0005
  *************************************************/
    v_old_pan             number;
    v_hash_pan            cms_appl_pan.cap_pan_code%type;
    v_newpan              cms_appl_pan.cap_pan_code%type;
    v_old_expry_date      cms_appl_pan.cap_expry_date%type;
    v_cardrenewal_check   number;
    v_exp                 exception;
    v_encr_pan            cms_appl_pan.cap_pan_code_encr%type;
    v_txn_desc            transactionlog.trans_desc%type;
    v_rrn                 varchar2 (20);
    v_card_stat           cms_appl_pan.cap_card_stat%type;
    v_acct_no             cms_appl_pan.cap_acct_no%type;
    v_cpm_catg_code       cms_prod_mast.cpm_catg_code%type;
    v_prod_code           cms_appl_pan.cap_prod_code%type;
    v_acct_type           cms_acct_mast.cam_type_code%type;
    v_acct_bal            cms_acct_mast.cam_acct_bal%type;
    v_ledger_bal          cms_acct_mast.cam_ledger_bal%type;
    v_savepoint           number  default 0;
    v_file_handle         utl_file.file_type;
    v_wrt_buff            varchar2(100);

    cursor cur_card_renew(p_prod_code varchar2,p_card_no varchar2) is
    select   cap_pan_code, cap_expry_date, cap_pan_code_encr,fn_dmaps_main (cap_pan_code_encr),
    cap_prod_code, cap_card_type, cap_acct_no,cap_card_stat,
    cam_acct_bal, cam_ledger_bal, cam_type_code
    from cms_appl_pan , cms_acct_mast b
    where cap_inst_code = cam_inst_code
    and cap_card_stat not in ('0','9')
    and cap_inst_code = 1
    and cap_acct_no=cam_acct_no
    and ((p_prod_code is not null and cap_prod_code=p_prod_code) or
    (p_prod_code is null and cap_prod_code in ('MP52','MP53','MP54')) )
    and ((p_card_no is not null and cap_pan_code=gethash(p_card_no)) or p_card_no is null)
    and cap_ins_user=1399
    and cam_ins_user=1399
    and nvl(cam_acct_bal,0) >0;
    
begin
    p_err_msg := 'OK';
    p_file_name := 'BatchFile_PIN_'||to_char(sysdate,'mmddyyyy')||'.csv';
    
    begin
        if  utl_file.is_open(v_file_handle) then
            utl_file.fflush (v_file_handle);
            utl_file.fclose (v_file_handle);
        end if;
        v_file_handle := utl_file.fopen (p_dir_name, p_file_name, 'W');
    exception
        when others then
            p_err_msg := 'Error while opening file ' || substr (sqlerrm, 1, 200);
            raise v_exp;
    end;
    
        
    begin                                                        
        select ctm_tran_desc
        into v_txn_desc
        from cms_transaction_mast
        where ctm_inst_code = 1
        and ctm_tran_code = '39'                         
        and ctm_delivery_channel = '05';
    exception
        when others  then
            v_txn_desc := null;
    end;

    open cur_card_renew(p_prod_code,p_card_no);
    loop
        fetch cur_card_renew
        into v_hash_pan, v_old_expry_date, v_encr_pan,v_old_pan,
        v_prod_code, v_cpm_catg_code, v_acct_no, v_card_stat,
        v_acct_bal, v_ledger_bal, v_acct_type;

        exit when cur_card_renew%notfound;

        begin
            select count (1)
            into v_cardrenewal_check
            from cms_cardrenewal_hist
            where cch_pan_code = v_hash_pan
            and trunc (cch_expry_date) = trunc (v_old_expry_date)
            and cch_inst_code = 1;

            v_savepoint := v_savepoint + 1;
            savepoint v_savepoint;

            sp_singlecard_renewal (1,
                                   v_old_pan,
                                   '39',          
                                   1,              
                                   v_newpan,
                                   p_err_msg
                                  );

            if p_err_msg <> 'OK'    then
                raise v_exp;
            end if;
            
            v_wrt_buff :=v_old_pan||','||v_newpan;
            utl_file.put_line (v_file_handle, v_wrt_buff);
                
        exception
            when v_exp then
            
                rollback to v_savepoint;

                begin
                    select    to_char (systimestamp, 'yymmddhh24miss')|| seq_passivestatupd_rrn.nextval
                    into v_rrn from dual;
                exception
                    when others then
                        null;
                end;

                begin                                                        
                    insert into transactionlog
                                    (msgtype, rrn, delivery_channel, txn_code,
                                    trans_desc, customer_card_no,
                                    customer_card_no_encr, business_date,
                                    business_time, txn_status, response_code,
                                    instcode, add_ins_date, response_id, date_time,
                                    customer_acct_no, acct_balance, ledger_balance,
                                    cardstatus, error_msg, acct_type,
                                    productid, categoryid, cr_dr_flag, time_stamp
                                    )
                    values 
                                    ('0200', v_rrn, '05', '39',
                                    v_txn_desc, v_hash_pan,
                                    v_encr_pan, to_char (sysdate, 'yyyymmdd'),
                                    to_char (sysdate, 'hh24miss'), 'F', '89',
                                    1, sysdate, '89', sysdate,
                                    v_acct_no, v_acct_bal, v_ledger_bal,
                                    v_card_stat, p_err_msg, v_acct_type,
                                    v_prod_code, v_cpm_catg_code, 'NA', systimestamp
                                    );
                exception
                    when others  then
                        null;
                end;

                begin                                                        
                    insert into cms_transaction_log_dtl
                                    (ctd_delivery_channel, ctd_txn_code,
                                    ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                                    ctd_business_date,
                                    ctd_business_time, ctd_customer_card_no,
                                    ctd_process_flag, ctd_process_msg,
                                    ctd_inst_code, ctd_customer_card_no_encr,
                                    ctd_cust_acct_number
                                    )
                    values 
                                    ('05', '39',
                                    '0', '0200', 0,
                                    to_char (sysdate, 'YYYYMMDD'),
                                    to_char (sysdate, 'hh24miss'), v_hash_pan,
                                    'E', p_err_msg,
                                    1, v_encr_pan,
                                    v_acct_no
                                    );
                exception
                    when others   then
                        null;
                end;
            when others   then
                rollback to v_savepoint;
                p_err_msg := 'Main Exception' || substr (sqlerrm, 1, 100);
                begin
                    select    to_char (systimestamp, 'yymmddhh24miss')|| seq_passivestatupd_rrn.nextval
                    into v_rrn from dual;
                exception
                    when others then
                        null;
                end;

                begin                                                        
                    insert into transactionlog
                                    (msgtype, rrn, delivery_channel, txn_code,
                                    trans_desc, customer_card_no,
                                    customer_card_no_encr, business_date,
                                    business_time, txn_status, response_code,
                                    instcode, add_ins_date, response_id, date_time,
                                    customer_acct_no, acct_balance, ledger_balance,
                                    cardstatus, error_msg, acct_type,
                                    productid, categoryid, cr_dr_flag, time_stamp
                                    )
                    values 
                                    ('0200', v_rrn, '05', '39',
                                    v_txn_desc, v_hash_pan,
                                    v_encr_pan, to_char (sysdate, 'yyyymmdd'),
                                    to_char (sysdate, 'hh24miss'), 'F', '89',
                                    1, sysdate, '89', sysdate,
                                    v_acct_no, v_acct_bal, v_ledger_bal,
                                    v_card_stat, p_err_msg, v_acct_type,
                                    v_prod_code, v_cpm_catg_code, 'NA', systimestamp
                                    );
                exception
                    when others  then
                        null;
                end;

                begin                                                        
                    insert into cms_transaction_log_dtl
                                    (ctd_delivery_channel, ctd_txn_code,
                                    ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                                    ctd_business_date,
                                    ctd_business_time, ctd_customer_card_no,
                                    ctd_process_flag, ctd_process_msg,
                                    ctd_inst_code, ctd_customer_card_no_encr,
                                    ctd_cust_acct_number
                                    )
                    values 
                                    ('05', '39',
                                    '0', '0200', 0,
                                    to_char (sysdate, 'YYYYMMDD'),
                                    to_char (sysdate, 'hh24miss'), v_hash_pan,
                                    'E', p_err_msg,
                                    1, v_encr_pan,
                                    v_acct_no
                                    );
                exception
                    when others   then
                        null;
                end;
        end;
    end loop;
    
    commit;
    close cur_card_renew;
    
    utl_file.fflush (v_file_handle);
    utl_file.fclose (v_file_handle);

exception
    when v_exp  then
        null;
    when others then
        null;
end; 
/
SHOW ERROR