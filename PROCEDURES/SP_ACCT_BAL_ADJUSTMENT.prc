create or replace procedure vmscms.sp_acct_bal_adjustment (
                                           p_inst_code   in       number,
                                           p_ins_user    in       number,
                                           p_err         out      varchar2
)as
    v_hash_pan           cms_appl_pan.cap_pan_code%type;
    v_encr_pan           cms_appl_pan.cap_pan_code_encr%type;
    v_business_date      varchar2 (10);
    v_business_time      varchar2 (10);
    v_rrn                transactionlog.rrn%type;
    v_rrn_cnt            number                                  default 0;
    v_errmsg             varchar2 (300);
    v_excep              exception;
    v_panno              varchar2 (30);
    v_delivery_channel   transactionlog.delivery_channel%type;
    v_txn_type           transactionlog.txn_type%type;
    v_txn_code           transactionlog.txn_code%type;
    v_txn_mode           cms_func_mast.cfm_txn_mode%type         default '0';
    v_txn_amount         number (20, 3);
    v_upd_amt            number;
    v_upd_acct_bal       number;
    v_cap_card_stat      cms_appl_pan.cap_card_stat%type;
    v_prod_code          cms_appl_pan.cap_prod_code%type;
    v_card_type          cms_appl_pan.cap_card_type%type;
    v_acct_number        cms_appl_pan.cap_acct_no%type;
    v_acct_type          cms_acct_type.cat_type_code%type;
    v_acct_bal           cms_acct_mast.cam_acct_bal%type;
    v_ledger_bal         cms_acct_mast.cam_ledger_bal%type;
    v_auth_id            transactionlog.auth_id%type;
    v_narration          varchar2 (300);
    v_timestamp          timestamp;
    v_batch_seq          varchar2 (6);
    v_reasondesc         cms_spprt_reasons.csr_reasondesc%type;
    v_active_date  	 cms_appl_pan.cap_active_date%type;
begin

    begin
        select lpad (seq_batchupload_id.nextval, 6, '0')
        into v_batch_seq
        from dual;

        insert into cms_batchupload_details
                            (cbd_inst_code, cbd_file_type, cbd_file_path,
                            cbd_file_name, cbd_batch_id, cbd_file_status,
                            cbd_upload_user, cbd_ins_user, cbd_ins_date )
        values              (1, 3, 'Incomm' || v_batch_seq,
                            'Incomm' || v_batch_seq, 'Batch' || v_batch_seq, 3,
                            p_ins_user, p_ins_user, sysdate );
    exception
        when others  then
            p_err :=  'Error while generating Batch id:'  || substr (sqlerrm, 1, 200);
            raise v_excep;
    end;

    commit;

    for x in (  select rowid row_id, a.*
                from cms_acct_batch_adjustment a
                where a.cab_process_status = 'N')
    loop
        begin
            v_rrn_cnt := v_rrn_cnt + 1;
            v_errmsg := 'OK';

            begin
                select * into  v_cap_card_stat, v_prod_code, v_card_type, v_acct_number,
                                v_panno,v_encr_pan,v_hash_pan,v_active_date
                from  (select cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                       fn_dmaps_main (cap_pan_code_encr),cap_pan_code_encr,cap_pan_code,
		       cap_active_date
                       from cms_appl_pan
                        where cap_acct_no = x.cab_acct_no and cap_inst_code = p_inst_code
                        and cap_card_stat not in ('9','11') order by cap_ins_date ) 
                where rownum=1;
            exception
                when no_data_found  then
                    begin
                        select * into  v_cap_card_stat, v_prod_code, v_card_type, v_acct_number,
                                        v_panno,v_encr_pan,v_hash_pan,v_active_date
                        from  (select cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                               fn_dmaps_main (cap_pan_code_encr),cap_pan_code_encr,cap_pan_code,
			       cap_active_date
                               from cms_appl_pan
                                where cap_acct_no = x.cab_acct_no and cap_inst_code = p_inst_code
                                order by cap_ins_date ) 
                        where rownum=1;
                    exception
                        when no_data_found  then
                            v_errmsg := 'Card Not Found In CMS';
                            raise v_excep;
                        when others   then
                            v_errmsg := 'Error while selecting card number-'|| substr (sqlerrm, 1, 200);
                            raise v_excep;
                    end;
                when others   then
                    v_errmsg := 'Error while selecting card number-'|| substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;
         
            begin
                select to_char (sysdate, 'yyyymmdd'),
                        to_char (sysdate, 'hh24miss'),
                        to_char (sysdate, 'ddhh24miss') || lpad (v_rrn_cnt, 5, 0)
                into v_business_date,
                     v_business_time,
                     v_rrn
                from dual;
            exception
                when others then
                    v_errmsg := 'Error while selecting txn dtls-' || substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;

            if x.cab_trans_amount = 0   then
                v_errmsg := 'Transaction rejected for txn amount is zero';
                raise v_excep;
            else
                v_delivery_channel := '05';
                v_txn_type := '1';

                if x.cab_trans_type = 'CR' then
                    v_txn_code := 20;
                    v_txn_amount := round (x.cab_trans_amount, 2);
                elsif x.cab_trans_type = 'DR'  then
                    v_txn_code := 19;
                    v_txn_amount := round (x.cab_trans_amount, 2);
                end if;
            end if;

            begin
                select csr_reasondesc
                into v_reasondesc
                from cms_spprt_reasons
                where csr_inst_code = p_inst_code
                and csr_spprt_key = 'MANADJDRCR'
                and csr_spprt_rsncode = x.cab_reason_code;
            exception
                when no_data_found then
                    v_errmsg := 'Inavlid Reason code ';
                    raise v_excep;
                when others then
                    v_errmsg := 'Error while selecting reason code '|| substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;

            begin
                select cam_acct_bal, cam_ledger_bal, cam_type_code
                into v_acct_bal, v_ledger_bal, v_acct_type
                from cms_acct_mast
                where cam_inst_code = p_inst_code and cam_acct_no = v_acct_number 
                for update;
            exception
                when others  then
                    v_errmsg :='Error while selecting acct dtls-'|| substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;
			
			
			IF X.CAB_DEFUND_FLAG ='Y'
			THEN 
			
				IF v_cap_card_stat <> 0 OR v_active_date IS NOT NULL
				THEN 
				v_errmsg :='Only inactive cards can be defunded.';
                    raise v_excep; 
				
				END IF; 
				
				IF x.cab_trans_type <> 'DR' 
				THEN 
				v_errmsg :='Only  Debit of fund is allowed for Defund account.';
                    raise v_excep; 				
				END IF;  
				
				IF v_acct_bal <> v_txn_amount			
				THEN 
				
				v_txn_amount := v_acct_bal ;
				
				END IF;
				 
			
			END IF; 

            if x.cab_trans_type = 'CR'  then
                v_upd_amt := v_ledger_bal + v_txn_amount;
                v_upd_acct_bal := v_acct_bal + v_txn_amount;
            elsif x.cab_trans_type = 'DR'  then
                v_upd_amt := v_ledger_bal - v_txn_amount;
                v_upd_acct_bal := v_acct_bal - v_txn_amount;
            end if;

            begin
                select lpad (seq_auth_id.nextval, 6, '0')
                into v_auth_id
                from dual;
            exception
                when others then
                    v_errmsg := 'Error while generating authid-'|| substr (sqlerrm, 1, 100);
                    raise v_excep;
            end;

            begin
                v_timestamp := systimestamp;
                
                if trim (x.cab_trans_narration) is not null  then
                    v_narration := x.cab_trans_narration || '/';
                end if;

                if trim (v_auth_id) is not null then
                    v_narration := v_narration || v_auth_id || '/';
                end if;

                if trim (v_acct_number) is not null   then
                    v_narration := v_narration || v_acct_number || '/';
                end if;

                if trim (v_business_date) is not null then
                    v_narration := v_narration || v_business_date;
                end if;

                if x.cab_trans_type = 'CR'   then
                    begin
                        update cms_acct_mast
                        set cam_acct_bal = cam_acct_bal + v_txn_amount,
                        cam_ledger_bal = cam_ledger_bal + v_txn_amount,
						cam_defund_flag = X.CAB_DEFUND_FLAG
                        where cam_inst_code = p_inst_code
                        and cam_acct_no = v_acct_number;

                        if sql%rowcount = 0 then
                            v_errmsg :=  'No records updated in account master for CR';
                            RAISE v_excep;
                        end if;
                    exception
                        when v_excep then
                            raise;
                        when others then
                            v_errmsg := 'Error occurred while updating acct mast for CR-' || substr (sqlerrm, 1, 100);
                            raise v_excep;
                    end;
                elsif x.cab_trans_type = 'DR' then
                    begin
                        update cms_acct_mast
                        set cam_acct_bal = cam_acct_bal - v_txn_amount,
                        cam_ledger_bal = cam_ledger_bal - v_txn_amount,
			            cam_defund_flag = X.CAB_DEFUND_FLAG
                        where cam_inst_code = p_inst_code
                        and cam_acct_no = v_acct_number;

                        if sql%rowcount = 0 then
                            v_errmsg :=  'No records updated in account master for DR';
                            raise v_excep;
                        end if;
                    exception
                        when v_excep then
                            raise;
                        when others then
                            v_errmsg :='Error occurred while updating acct mast for DR-'|| substr (sqlerrm, 1, 200);
                            raise v_excep;
                    end;
                elsif nvl (x.cab_trans_type, '0') not in ('DR', 'CR') then
                    v_errmsg := 'invalid debit/credit flag ';
                    raise v_excep;
                end if;
            end;
            
            
            begin
                insert into cms_statements_log
                            (csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date,
                            csl_closing_balance, csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_business_date, csl_business_time,
                            csl_delivery_channel, csl_txn_code,
                            csl_auth_id, csl_ins_date, csl_ins_user,
                            csl_acct_no,
                            csl_panno_last4digit,
                            csl_acct_type, csl_time_stamp,
                            csl_prod_code,csl_card_type
                            )
                values      (v_hash_pan, v_ledger_bal,
                            v_txn_amount, x.cab_trans_type,
                            to_date (v_business_date, 'yyyymmdd'),
                            v_upd_amt, v_narration,
                            p_inst_code, v_encr_pan, v_rrn,
                            v_business_date, v_business_time,
                            v_delivery_channel, v_txn_code,
                            v_auth_id, sysdate, 1,
                            v_acct_number,
                            substr (v_panno,-4),
                            v_acct_type, v_timestamp,
                            v_prod_code,v_card_type
                            );

                if sql%rowcount = 0 then
                    v_errmsg :='No records inserted in statements log for DR';
                    raise v_excep;
                end if;
            exception
                when v_excep then
                    raise;
                when others then
                    v_errmsg := 'Error while inserting into statement log for DR-'|| substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;

            begin
                insert into transactionlog
                            (msgtype, rrn, delivery_channel, date_time,
                            txn_code, txn_type, txn_mode, txn_status,
                            response_code, business_date, business_time,
                            customer_card_no, instcode, customer_card_no_encr,
                            customer_acct_no, error_msg, cardstatus,
                            amount,
                            bank_code,
                            total_amount,
                            currencycode, auth_id,
                            trans_desc, gl_upd_flag,
                            acct_balance,
                            ledger_balance,
                            response_id, add_ins_date, add_ins_user, productid,
                            categoryid, acct_type, time_stamp,
                            cr_dr_flag, reason,reason_code,
			    remark
                            )
                values     ('0200', v_rrn, v_delivery_channel, sysdate,
                            v_txn_code, v_txn_type, v_txn_mode, 'C',
                            '00', v_business_date, v_business_time,
                            v_hash_pan, p_inst_code, v_encr_pan,
                            v_acct_number, v_errmsg, v_cap_card_stat,
                            trim (to_char (v_txn_amount, '99999999999999990.99')),
                            p_inst_code,
                            trim (to_char (v_txn_amount, '99999999999999990.99')),
                            '840', v_auth_id,
                            substr (x.cab_trans_narration, 1, 50), 'N',
                            trim (to_char (v_upd_acct_bal,'99999999999999990.99')),
                            trim (to_char (v_upd_amt, '99999999999999990.99')),
                            '1', sysdate, 1, v_prod_code,
                            v_card_type, v_acct_type, v_timestamp,
                            x.cab_trans_type,v_reasondesc,x.cab_reason_code,
			    x.cab_remark
                            );
            exception
                when others then
                v_errmsg := 'Exception while inserting to transaction log-'|| substr (sqlerrm, 1, 200);
                raise v_excep;
            end;

            begin
                insert into cms_transaction_log_dtl
                            (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                            ctd_txn_mode, ctd_business_date, ctd_business_time,
                            ctd_customer_card_no, ctd_txn_curr, ctd_process_flag, ctd_process_msg,
                            ctd_rrn, ctd_inst_code, ctd_ins_date,
                            ctd_customer_card_no_encr, ctd_msg_type,
                            ctd_cust_acct_number,
                            ctd_actual_amount,
                            ctd_txn_amount
                            )
                values      (v_delivery_channel, v_txn_code, v_txn_type,
                            v_txn_mode, v_business_date, v_business_time,
                            v_hash_pan, '840', 'Y', v_errmsg,
                            v_rrn, p_inst_code, sysdate,
                            v_encr_pan, '0200',
                            v_acct_number,
                            v_txn_amount,
                            v_txn_amount
                            );
            exception
                when others then
                    v_errmsg :='Error while inserting data into transaction log  dtl'|| substr (sqlerrm, 1, 200);
                    raise v_excep;
            end;

            if v_errmsg = 'OK' then
                begin
                    insert into cms_bal_adj_batch
                                (cbb_batch_id, cbb_pan_code,
                                cbb_pan_code_encr, cbb_txn_amt, cbb_forse_post,
                                cbb_reason_code, cbb_txn_desc,
                                cbb_before_ledg_bal, cbb_after_ledg_bal,
                                cbb_process_flag, cbb_process_msg, cbb_ins_user,
                                cbb_ins_date
                                )
                    values      ('Batch' || v_batch_seq, v_hash_pan,
                                v_encr_pan, v_txn_amount, 'Yes',
                                x.cab_reason_code, v_narration,
                                v_ledger_bal, v_upd_amt,
                                'S', 'Success', 1,
                                SYSDATE   
                                );
                exception
                    when others then
                        v_errmsg :=  'Error while inserting bal adj batch process Detail '|| substr (sqlerrm, 1, 200);
                        raise v_excep;
                end;


                begin
                    update cms_acct_batch_adjustment
                    set cab_process_status = 'Y',
                    cab_process_description = 'Sucessful',
		            cab_trans_amount = v_txn_amount,
                    cab_process_date = sysdate,
                    cab_batch_id = 'Batch' || v_batch_seq
                    where rowid = x.row_id;
                exception
                    when others then
                        v_errmsg :='Error while updating Sucessful record'|| substr (sqlerrm, 1, 200);
                        raise v_excep;
                end;
            end if;
      exception
         when v_excep then
            rollback ;

            update cms_acct_batch_adjustment
            set cab_process_status = 'E',
            cab_process_description = v_errmsg,
            cab_process_date = sysdate,
            cab_batch_id = 'Batch' || v_batch_seq
            where rowid = x.row_id;
         when others  then
            rollback ;
            v_errmsg := 'Main Excp-' || substr (sqlerrm, 1, 200);

            update cms_acct_batch_adjustment
            set cab_process_status = 'E',
            cab_process_description = v_errmsg,
            cab_process_date = sysdate,
            cab_batch_id = 'Batch' || v_batch_seq
            where rowid = x.row_id;
        end;

        commit;
    end loop;

exception
    when v_excep then
        null;
    when others then
        p_err := ' Main Excp-' || sqlerrm;
end;
/

show error;