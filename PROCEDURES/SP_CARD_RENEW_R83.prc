create or replace procedure vmscms.sp_card_renew_r83 (p_prod_code     in  varchar2,
                                        p_new_prod_code in  varchar2,
                                        p_new_card_type in  varchar2,
                                        p_expiry_days   in  number,
                                        p_dir_name      in  varchar2,
                                        p_file_name     out varchar2,
                                        p_err_msg       out varchar2)
is
/*************************************************
     * Created Date     :  10-Apr-2015
     * Created By       :  Saravanakumar A
     * purpose          :  For update activity CMS_3.5.1_RSI0083
*************************************************/
    v_old_pan             number;
    v_hash_pan            cms_appl_pan.cap_pan_code%type;
    v_newpan              cms_appl_pan.cap_pan_code%type;
    v_expry_date          cms_appl_pan.cap_expry_date%type;
    v_exp                 exception;
    v_encr_pan            cms_appl_pan.cap_pan_code_encr%type;
    v_txn_desc            transactionlog.trans_desc%type;
    v_rrn                 varchar2 (20);
    v_card_stat           cms_appl_pan.cap_card_stat%type;
    v_acct_no             cms_appl_pan.cap_acct_no%type;
    v_card_type           cms_appl_pan.cap_card_type%type;
    v_prod_code           cms_appl_pan.cap_prod_code%type;
    v_acct_type           cms_acct_mast.cam_type_code%type;
    v_acct_bal            cms_acct_mast.cam_acct_bal%type;
    v_ledger_bal          cms_acct_mast.cam_ledger_bal%type;
    v_file_handle         utl_file.file_type;
    v_wrt_buff            varchar2(100);
    v_rowid               rowid;
    v_cust_code           cms_appl_pan.cap_cust_code%type;
    v_disp_name           cms_appl_pan.cap_disp_name%type;
    v_appl_code           cms_appl_pan.cap_appl_code%type;
    v_cnt                 number;
    v_process_status      varchar2(2);
    v_process_description varchar2(60);

    cursor cur_card_renew is
    select   a.rowid ri,cap_pan_code, cap_expry_date, cap_pan_code_encr,fn_dmaps_main (cap_pan_code_encr),
    cap_prod_code, cap_card_type, cap_acct_no,cap_card_stat,
    cam_acct_bal, cam_ledger_bal, cam_type_code,
    cap_cust_code,cap_disp_name,cap_appl_code
    from cms_appl_pan_r83 a,cms_acct_mast
    where cap_process_status= 'N'
    and cap_acct_no=cam_acct_no;
    
begin
    
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

    open cur_card_renew;
    loop
        begin
            p_err_msg := 'OK';
            
            fetch cur_card_renew
            into v_rowid,v_hash_pan, v_expry_date, v_encr_pan,v_old_pan,
            v_prod_code, v_card_type, v_acct_no, v_card_stat,
            v_acct_bal, v_ledger_bal, v_acct_type,
            v_cust_code,v_disp_name,v_appl_code;

            exit when cur_card_renew%notfound;
            
            begin

                select count (1)
                into v_cnt
                from vmscms.transactionlog 
                where instcode = 1
                and customer_card_no = v_hash_pan
                and (  (delivery_channel = '11' and txn_code in ('22', '32'))
                    or (delivery_channel = '08' and txn_code in ('22', '26'))
                    or (delivery_channel = '01' and txn_code in ('10', '99'))
                    or (delivery_channel = '02' and txn_code in ('12', '14', '16', '18', '20', '22', '25', '28')))
                and response_code = '00'
                and add_ins_date between sysdate - p_expiry_days and sysdate;

                if v_cnt = 0 then
                    v_process_status:='NE';
                    v_process_description:='No transaction for last '||p_expiry_days||' days';
                else
                    v_process_status:='S';
                    v_process_description:='Success';
                end if;
                
            exception
                when others then
                    p_err_msg :='Error while selecting transactionlog'|| substr (sqlerrm, 1, 200);
                    
                    update cms_appl_pan_r83
                    set cap_process_status='E',
                    cap_process_description=p_err_msg
                    where rowid=v_rowid;
            end;
            
            v_newpan:=null;
            
            begin
                if v_process_status = 'S' then
                    
                                    
                    sp_singlecard_renewal_r83   (v_hash_pan,
                                                v_encr_pan,
                                                v_prod_code, 
                                                v_card_type, 
                                                p_new_prod_code ,
                                                p_new_card_type,
                                                v_cust_code,
                                                v_disp_name, 
                                                v_expry_date, 
                                                v_appl_code, 
                                                v_acct_no, 
                                                v_card_stat, 
                                                v_acct_bal, 
                                                v_ledger_bal, 
                                                v_acct_type,
                                                v_txn_desc,
                                                v_newpan,
                                                p_err_msg
                                              );
                                              

                    if p_err_msg <> 'OK'    then
                        raise v_exp;
                    end if;
                    
                    v_wrt_buff :=v_old_pan||','||v_newpan;
                    utl_file.put_line (v_file_handle, v_wrt_buff);
                end if;
            exception
                when v_exp then
                    raise;
                when others then
                    p_err_msg := 'Main Exception' || substr (sqlerrm, 1, 100);
                    raise v_exp;
            end;
            
            update cms_appl_pan_r83
            set cap_process_status=v_process_status,
            cap_process_description=v_process_description,
            cap_new_pan=v_newpan
            where rowid=v_rowid;
            
            

        exception
            when v_exp then
                rollback ;

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
                                    v_prod_code, v_card_type, 'NA', systimestamp
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
                    
                update cms_appl_pan_r83
                set cap_process_status='E',
                cap_process_description=p_err_msg
                where rowid=v_rowid;

            when others   then
                rollback ;
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
                                    v_prod_code, v_card_type, 'NA', systimestamp
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
                    
                update cms_appl_pan_r83
                set cap_process_status='E',
                cap_process_description=p_err_msg
                where rowid=v_rowid;
                    
        end;
        
        commit;
        
    end loop;
    
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
show error