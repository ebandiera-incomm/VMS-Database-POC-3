create or replace procedure vmscms.sp_singlecard_renewal_r83 (
                                            p_hash_pan           in      varchar2,
                                            p_encr_pan           in      raw,
                                            p_old_product        in      varchar2,
                                            p_old_cardtype       in      number,
                                            p_new_product        in      varchar2,
                                            p_new_cardtype       in      varchar2,
                                            p_cust_code          in      number,
                                            p_disp_name          in      varchar2,
                                            p_expry_date         in      date,
                                            p_appl_code          in      number,
                                            p_acct_no            in      varchar2,
                                            p_card_stat          in      varchar2,
                                            p_acct_bal           in      number,
                                            p_ledger_bal         in      number,
                                            p_acct_type          in      number,
                                            p_txn_desc           in      varchar2,      
                                            p_newpan             out     varchar2,
                                            p_errmsg             out     varchar2
)
as
/**************************************************************************
     * created date     : 10-Apr-2015
     * created by       : Saravanakumar A
     * purpose          : For update activity CMS_3.5.1_RSI0083
/**************************************************************************/

    v_cpm_catg_code           cms_prod_mast.cpm_catg_code%type;
    v_hash_new_pan            cms_appl_pan.cap_pan_code%type;
    v_encr_new_pan            cms_appl_pan.cap_pan_code_encr%type;
    v_rrn                     varchar2 (20);
    exp_reject_record         exception;
    v_addressverify_flag      number;
    v_cardrenewal_check       number;
begin
    p_errmsg := 'OK';

    begin
        select    to_char (systimestamp, 'yymmddhh24miss') || seq_passivestatupd_rrn.nextval
        into v_rrn
        from dual;
    exception
        when others  then
            p_errmsg := 'Error while getting RRN ' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        select count (*)
        into v_cardrenewal_check
        from cms_cardrenewal_hist
        where cch_pan_code = p_hash_pan
        and trunc (cch_expry_date) = trunc (p_expry_date)
        and cch_inst_code = 1;

        if v_cardrenewal_check > 0   then
            p_errmsg := 'Card has been Renewed already : ' || p_hash_pan;
            raise exp_reject_record;
        end if;
    exception
        when exp_reject_record  then
            raise;
        when others   then
            p_errmsg :=   'Error occured while selecting cms_cardrenewal_hist '|| substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        sp_order_reissuepan_cms (1,
                                fn_dmaps_main (p_encr_pan),
                                p_new_product,
                                p_new_cardtype,
                                p_disp_name,
                                1,
                                p_newpan,
                                p_errmsg
                                );

        if p_errmsg <> 'OK'  then
            p_errmsg := 'Error from sp_order_reissuepan_cms- ' || p_errmsg;
            raise exp_reject_record;
        end if;
            
    exception
        when exp_reject_record then
            raise;
        when others then
            p_errmsg :='Error while calling sp_order_reissuepan_cms- '|| substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        v_hash_new_pan := gethash (p_newpan);
    exception
        when others  then
            p_errmsg := 'Error while converting hash pan code ' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        v_encr_new_pan := fn_emaps_main (p_newpan);
    exception
        when others  then
            p_errmsg := 'Error while converting encrypted pan code '|| substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        insert into cms_cardissuance_status
                    (ccs_inst_code, ccs_pan_code, ccs_card_status,
                    ccs_ins_user, ccs_ins_date, ccs_pan_code_encr,ccs_appl_code )
        values      (1, v_hash_new_pan, '2',
                    1, sysdate, v_encr_new_pan,p_appl_code );
    exception
        when others  then
            p_errmsg := 'Error while Inserting CCF table ' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        insert into cms_smsandemail_alert
                    (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                    csa_cellphonecarrier, csa_loadorcredit_flag,
                    csa_lowbal_flag, csa_lowbal_amt, csa_negbal_flag,
                    csa_highauthamt_flag, csa_highauthamt,
                    csa_dailybal_flag, csa_begin_time, csa_end_time,
                    csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag,
                    csa_fedtax_refund_flag, csa_ins_user, csa_ins_date,
                    csa_lupd_user, csa_lupd_date)
        (select 1, v_hash_new_pan, v_encr_new_pan,
                nvl (csa_cellphonecarrier, 0), csa_loadorcredit_flag,
                csa_lowbal_flag, nvl (csa_lowbal_amt, 0),
                csa_negbal_flag, csa_highauthamt_flag,
                nvl (csa_highauthamt, 0), csa_dailybal_flag,
                nvl (csa_begin_time, 0), nvl (csa_end_time, 0),
                csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag,
                csa_fedtax_refund_flag, 1, sysdate,
                1, sysdate
                from cms_smsandemail_alert
                where csa_inst_code = 1
                and csa_pan_code = p_hash_pan);

        if sql%rowcount != 1   then
            p_errmsg := 'Error while inserting cms_smsandemail_alert ';
            raise exp_reject_record;
        end if;
            
    exception
        when exp_reject_record  then
            raise;
        when others then
            p_errmsg := 'Error while Entering sms email alert detail ' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        select ccm_addrverify_flag
        into v_addressverify_flag
        from cms_cust_mast
        where ccm_inst_code = 1 and ccm_cust_code = p_cust_code;
    exception
        when others then
            p_errmsg := 'Error while fetching address flag from cms_cust_mast ' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        update cms_cardissuance_status
        set ccs_renewal_comments =  decode (v_addressverify_flag,
                                    1,  'Address not Verified:Renewal Card Ordered '|| to_char (sysdate, 'mmddyy'),
                                    2,  'Address Verified.Renewal Card Ordered '|| to_char (sysdate, 'mmddyy') ),
        ccs_renewal_date = sysdate
        where ccs_inst_code = 1 and ccs_pan_code = p_hash_pan;

        if sql%rowcount <> 1   then
            p_errmsg := 'Error while updating address verify flag into cms_cardissuance_status ';
            raise exp_reject_record;
        end if;
    exception
        when exp_reject_record then
            raise;
        when others then
            p_errmsg := 'Error while updating Address Verification flag/DATE' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        update cms_cust_mast
        set ccm_addrverify_flag = 0,
        ccm_addverify_date = null,
        ccm_avfset_channel = null,
        ccm_avfset_txncode = null
        where  ccm_cust_code = p_cust_code and ccm_inst_code = 1;

        if sql%rowcount <> 1  then
            p_errmsg := 'Error while updating cust mast for addr flag ';
            raise exp_reject_record;
        end if;
        
    exception
        when others  then
            p_errmsg := 'Error while updating Address Verification flag'|| substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin
        insert into cms_cardrenewal_hist
                    (cch_inst_code, cch_pan_code, cch_card_stat,
                    cch_renewal_date, cch_expry_date, cch_ins_user, cch_ins_date  )
        values      (1, p_hash_pan, p_card_stat,
                    sysdate, p_expry_date, 1, sysdate );
    exception
        when others  then
            p_errmsg := 'Error in inserting Card Renewal History'|| substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin                                                                 
        insert into transactionlog
                    (msgtype, rrn, delivery_channel, txn_code, trans_desc,
                    customer_card_no, customer_card_no_encr, business_date,
                    business_time, txn_status, response_code, instcode,
                    add_ins_date, response_id, date_time, customer_acct_no,
                    acct_balance, ledger_balance, cardstatus, error_msg,
                    acct_type, productid, categoryid, cr_dr_flag, time_stamp )
        values     ('0200', v_rrn, '05', '39', p_txn_desc,
                    p_hash_pan, p_encr_pan, to_char (sysdate, 'yyyymmdd'),
                    to_char (sysdate, 'hh24miss'), 'C', '00', 1,
                    sysdate, '1', sysdate, p_acct_no,
                    p_acct_bal, p_ledger_bal, p_card_stat, 'Successful',
                    p_acct_type, p_old_product, v_cpm_catg_code, 'NA',systimestamp );
    exception
        when others then
            p_errmsg := 'Error while logging transactionlog' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

    begin                                                                 
        insert into cms_transaction_log_dtl
                    (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                    ctd_msg_type, ctd_txn_mode, ctd_business_date,
                    ctd_business_time, ctd_customer_card_no,
                    ctd_process_flag, ctd_process_msg, ctd_inst_code,
                    ctd_customer_card_no_encr, ctd_cust_acct_number )
        values      ('05', '39', '0',
                    '0200', 0, to_char (sysdate, 'YYYYMMDD'),
                    to_char (sysdate, 'hh24miss'), p_hash_pan,
                    'Y', 'Successful', 1,
                    p_encr_pan, p_acct_no );
    exception
        when others then
            p_errmsg := 'Error while inserting cms_transaction_log_dtl' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
    end;

exception
    when exp_reject_record  then
        rollback;
        p_newpan := p_errmsg;
    when others  then
        rollback;
        p_errmsg := 'Main Exception' || substr (sqlerrm, 1, 100);
        p_newpan := p_errmsg;
end;
/
show error