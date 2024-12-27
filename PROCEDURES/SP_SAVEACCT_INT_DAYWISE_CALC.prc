CREATE OR REPLACE procedure VMSCMS.sp_saveacct_int_daywise_calc
                                                            (p_inst_code in number,
                                                            p_date       in date)
as

v_interest_rate        number(6,3); 
v_factor               number(30,10);
v_compound_balance     cms_interest_detl.cid_interest_amount%type;
v_daily_accrual        cms_interest_detl.cid_interest_amount%type;
v_type_code            cms_acct_type.cat_type_code%type;
v_status_code          cms_acct_stat.cas_stat_code%type;
v_delivery_channel     varchar2(2)  default '05';
v_switch_acct_type     cms_acct_type.cat_switch_type%type default '22';
v_switch_acct_status   cms_acct_stat.cas_switch_statcode%type default '8';
v_err_msg              varchar2(500);
exp_reject_record      exception;
v_prod_code            cms_appl_pan.cap_prod_code%type;
v_apye                 number(30,9);
v_no_days              number;
v_average_balance      number(30,9);
v_balance_dtl          cms_interest_detl.cid_interest_amount%type;
v_sysdate              date;
v_cam_interest_amount  cms_acct_mast.cam_interest_amount%type;
v_cam_acct_bal         cms_acct_mast.cam_acct_bal%type;
v_cam_ledger_bal       cms_acct_mast.cam_ledger_bal%type;
v_cid_compound_balance cms_interest_detl.cid_compound_balance%type;
v_cid_close_balance    cms_interest_detl.cid_close_balance%type;
v_cid_interest_amount  cms_interest_detl.cid_interest_amount%type;
v_card_type            cms_appl_pan.cap_card_type%type;
v_Retperiod  date; --Added for VMS-5733/FSP-991
/*******************************************************************************
        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
        
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
   * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
        
*******************************************************************************/

begin
    v_sysdate:=p_date;
  

    -- calculating the day from the quater starting to sysdate.
    if  v_sysdate < last_day(add_months(trunc(v_sysdate, 'q'),2))  then
        begin
            select  trunc( last_day (add_months (trunc (v_sysdate, 'q'), 2)) -
            trunc (v_sysdate, 'Q') + 1 - ( to_date(last_day (add_months (trunc (v_sysdate, 'Q'), 2)),'dd-mm-yy') - v_sysdate ))
            into v_no_days from dual;
        exception
            when others then
                v_err_msg:='Error while selecting v_no_days '||substr(sqlerrm,1,200);
                raise exp_reject_record;
        end;
    else
        begin
            select  trunc( last_day (add_months (trunc (v_sysdate, 'Q'), 2)) -
            trunc (v_sysdate, 'Q') + 1) into  v_no_days
            from dual;
        exception
            when others then
                v_err_msg:='Error while selecting v_no_days '||substr(sqlerrm,1,200);
                raise exp_reject_record;
        end;
    end if;


    --Fetching type code for saving account
    begin
        select cat_type_code
        into v_type_code
        from cms_acct_type
        where cat_switch_type=v_switch_acct_type
        and cat_inst_code=p_inst_code;
    exception
        when no_data_found then
            v_err_msg:='Type code is not defined for the institution';
            raise exp_reject_record;
        when others then
            v_err_msg:='Error while selecting type code for the institution '||substr(sqlerrm,1,200);
            raise exp_reject_record;
    end;

    --Fetching status code for saving account
    begin
        select cas_stat_code
        into v_status_code
        from cms_acct_stat
        where cas_switch_statcode=v_switch_acct_status
        and cas_inst_code=p_inst_code;
    exception
        when no_data_found then
            v_err_msg:='Status code is not defined for the institution';
            raise exp_reject_record;
        when others then
            v_err_msg:='Error while selecting status for the institution '||substr(sqlerrm,1,200);
            raise exp_reject_record;
    end;

    --Fetching saving account with account status is open
    for j in    (select cam_acct_id,
                cam_acct_no
                from cms_acct_mast
                where cam_type_code=v_type_code
                and cam_stat_code=v_status_code
                and cam_inst_code= p_inst_code)
    loop
        begin

            begin
                select cid_qtly_interest_accr,
                cid_compound_balance,
                cid_close_balance,
                cid_interest_amount
                into v_cam_interest_amount,
                v_cid_compound_balance,
                v_cid_close_balance,
                v_cid_interest_amount
                from(select cid_qtly_interest_accr ,
                    cid_compound_balance,
                    cid_close_balance,
                    cid_interest_amount
                    from cms_interest_detl
                    where cid_inst_code=p_inst_code
                    and cid_acct_no=j.cam_acct_no
                    and cid_ins_date < p_date
                    order by cid_ins_date desc)
                where rownum=1;
            exception
                when no_data_found then
                    begin
                        select cid_qtly_interest_accr,
                        cid_compound_balance,
                        cid_close_balance,
                        cid_interest_amount
                        into v_cam_interest_amount,
                        v_cid_compound_balance,
                        v_cid_close_balance,
                        v_cid_interest_amount
                        from(select cid_qtly_interest_accr ,
                            cid_compound_balance,
                            cid_close_balance,
                            cid_interest_amount
                            from cms_interest_detl_hist
                            where cid_inst_code=p_inst_code
                            and cid_acct_no=j.cam_acct_no
                            and cid_ins_date < p_date
                            order by cid_ins_date desc)
                        where rownum=1;
                    exception
                        when no_data_found then
                            v_cam_interest_amount:=0;
                            v_cid_compound_balance:=0;
                            v_cid_close_balance:=0;
                            v_cid_interest_amount:=0;
                        when others then
                            v_err_msg:='Error while selecting cms_interest_detl_hist '||substr(sqlerrm,1,200);
                            raise exp_reject_record;
                    end;
                when others then
                    v_err_msg:='Error while selecting cms_interest_detl  '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;

            begin
            
			
           
             --Added for VMS-5733/FSP-991
                   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
       WHERE  OPERATION_TYPE='ARCHIVE'
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (p_date>v_Retperiod)
    THEN
              select acct_balance,
                ledger_balance
                into v_cam_acct_bal,
                v_cam_ledger_bal
                from(select acct_balance,
                    ledger_balance
                    from transactionlog
                    where instcode=1
                    and customer_acct_no=j.cam_acct_no
                    and add_ins_date between to_date(to_char(p_date,'dd-mon-yyyy')||' 00:00:00','dd-mon-yyyy hh24:mi:ss')
                    and to_date(to_char(p_date,'dd-mon-yyyy')||' 23:59:59','dd-mon-yyyy hh24:mi:ss')
                    order by add_ins_date desc)
                where rownum=1;
     ELSE
                select acct_balance,
                ledger_balance
                into v_cam_acct_bal,
                v_cam_ledger_bal
                from(select acct_balance,
                    ledger_balance
                    from VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
                    where instcode=1
                    and customer_acct_no=j.cam_acct_no
                    and add_ins_date between to_date(to_char(p_date,'dd-mon-yyyy')||' 00:00:00','dd-mon-yyyy hh24:mi:ss')
                    and to_date(to_char(p_date,'dd-mon-yyyy')||' 23:59:59','dd-mon-yyyy hh24:mi:ss')
                    order by add_ins_date desc)
                where rownum=1;
         END IF;

          
                
            exception
                when no_data_found then
                    v_cam_acct_bal:=v_cid_close_balance-v_cid_interest_amount;
                    v_cam_ledger_bal:=v_cid_close_balance-v_cid_interest_amount;
                when others then
                    v_err_msg:='Error while selecting transactionlog  '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;

        if to_char(sysdate,'dd')='01' then
            begin
                insert into cms_stmtprd_svgactbal
                                                (
                                                css_inst_code,
                                                css_acct_no,
                                                css_acct_id,
                                                css_stat_code,
                                                css_acct_bal,
                                                css_ledger_bal,
                                                css_statment_period,
                                                css_ins_user,
                                                css_ins_date,
                                                css_lupd_user,
                                                css_lupd_date
                                                )
                values
                                                (
                                                p_inst_code,
                                                j.cam_acct_no,
                                                j.cam_acct_id,
                                                v_status_code,
                                                v_cam_acct_bal,
                                                v_cam_ledger_bal,
                                                v_sysdate,
                                                1,
                                                v_sysdate,
                                                1,
                                                v_sysdate
                                                );
            exception
                when others then
                    v_err_msg:='Error while inserting in to cms_stmtprd_svgactbal  '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;
        end if;

        begin
            select mm.cap_prod_code,mm.cap_card_type
            into v_prod_code,v_card_type
            from    (select   cap_prod_code,cap_card_type
                    from cms_appl_pan
                    where cap_cust_code =
                                    (select cca_cust_code
                                    from cms_cust_acct
                                    where cca_acct_id = j.cam_acct_id
                                    and cca_inst_code = p_inst_code)
                    and cap_card_stat not in ('9')
                    and cap_addon_stat = 'P'
                    and cap_inst_code = p_inst_code
                    order by cap_pangen_date desc)mm
            where rownum = 1;
        exception
            when no_data_found then
                v_err_msg   := 'Prod code not found for account id '||j.cam_acct_id;
                raise exp_reject_record;
            when others then
                v_err_msg   := 'Error while selecting prod code ' ||substr(sqlerrm, 1, 200);
                raise exp_reject_record;
        end;

        --Fetching interest rate for saving account
        begin
            select cdp_param_value
            into v_interest_rate
            from cms_dfg_param
            where cdp_param_key='Saving account Interest rate'
            and cdp_inst_code=p_inst_code
            and cdp_prod_code = v_prod_code
            and cdp_card_type = v_card_type;
        exception
            when others then
                v_err_msg:='Error while selecting interest rate for saving account '||substr(sqlerrm,1,200);
                raise exp_reject_record;
        end;

            --Calculating interest
            v_factor:=round((v_interest_rate/365/100),10);
            v_compound_balance:=trunc((v_cam_acct_bal+v_cam_interest_amount),9);
            v_daily_accrual:=trunc((v_factor*v_compound_balance),9);

            --Calculating apye
            begin
                select nvl( sum (cid_close_balance-cid_interest_amount),0)
                into v_balance_dtl
                from cms_interest_detl
                where cid_inst_code=p_inst_code
                and cid_acct_no = j.cam_acct_no
                and cid_calc_date between trunc(v_sysdate,   'q') and v_sysdate;
            exception
                when others then
                    v_err_msg:='Error while selecting interest detl for saving account '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;

            if v_balance_dtl > 0  then
                v_average_balance := trunc( ((v_balance_dtl+v_cam_acct_bal)/ (trunc(v_sysdate - trunc(v_sysdate , 'q'))+1)) ,9);
            else
                v_average_balance := trunc( (v_cam_acct_bal/ (trunc(v_sysdate - trunc(v_sysdate , 'q'))+1)) ,9);
            end if;


            v_apye:=round( 100*((power(trunc((1+( round((v_cam_interest_amount+v_daily_accrual),2) /v_average_balance)),9),(365/v_no_days)))-1),2 );

            --Inserting interest details
            begin
                insert into cms_interest_detl
                                    (cid_inst_code ,
                                    cid_acct_no ,
                                    cid_interest_rate ,
                                    cid_interest_amount ,
                                    cid_calc_date ,
                                    cid_close_balance ,
                                    cid_compound_balance,
                                    cid_qtly_interest_accr,
                                    cid_ins_user,
                                    cid_ins_date,
                                    cid_apye_amount)
                values
                                    (p_inst_code,
                                    j.cam_acct_no,
                                    v_interest_rate,
                                    v_daily_accrual,
                                    v_sysdate,
                                    v_cam_acct_bal+v_daily_accrual,
                                    v_compound_balance,
                                    v_cam_interest_amount+v_daily_accrual,
                                    1,
                                    v_sysdate,
                                    v_apye);
            exception
                when others then
                    v_err_msg:='Error while inserting interest detail '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;

            --Updating interest amount
            begin
                update cms_acct_mast
                set cam_interest_amount=v_daily_accrual+v_cam_interest_amount,
                cam_lupd_date=sysdate,
                cam_lupd_user=1
                where cam_acct_no=j.cam_acct_no
                and cam_inst_code=p_inst_code;

                if sql%rowcount =0 then
                    v_err_msg:='Interest amount is not updated';
                    raise exp_reject_record;
                end if;

            exception
                when exp_reject_record then
                    raise exp_reject_record;
                when others then
                    v_err_msg:='Error while updating interest amount '||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;

        exception
            when exp_reject_record then
                rollback ;
                --loging error
                begin
                    insert into cms_transaction_log_dtl
                                            ( ctd_delivery_channel,
                                            ctd_process_flag,
                                            ctd_process_msg,
                                            ctd_inst_code,
                                            ctd_ins_date,
                                            ctd_ins_user,
                                            ctd_cust_acct_number )
                    values
                                            ( v_delivery_channel,
                                            'E',
                                            'Interest_Calculation_'||v_err_msg,
                                            p_inst_code,
                                            v_sysdate,
                                            1,
                                            j.cam_acct_no );
                exception
                    when others then
                        null;
                end;
            when others then
                v_err_msg := 'Main Exception 1'||substr(sqlerrm,1,200);
                rollback ;
                --loging error
                begin
                    insert into cms_transaction_log_dtl
                                            ( ctd_delivery_channel,
                                            ctd_process_flag,
                                            ctd_process_msg,
                                            ctd_inst_code,
                                            ctd_ins_date,
                                            ctd_ins_user,
                                            ctd_cust_acct_number )
                    values
                                            ( v_delivery_channel,
                                            'E',
                                            'Interest_Calculation_'||v_err_msg,
                                            p_inst_code,
                                            v_sysdate,
                                            1,
                                            j.cam_acct_no );
                exception
                    when others then
                        null;
                end;
        end;
        commit;
    end loop;
exception
    when others then
        rollback ;
end;
/
show error