CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ONLINE_TXNDATA_AFTMIG (p_seq_no number,p_resp_msg OUT VARCHAR2) IS

v_preauth_exp_date   varchar2(10);
v_preauth_valid_flag varchar2(1);
v_preauth_expry_flag varchar2(1);
v_preauth_comp_flag  varchar2(1);
v_hold_amount        varchar2(30);
v_preauth_txn_flag   varchar2(1);
v_disp_reason        CMS_DISPUTE_TXNS.CDT_REASON%type;
v_disp_remark        CMS_DISPUTE_TXNS.CDT_REMARK%type;
v_orgnl_del_chnl     transactionlog.delivery_channel%type;
v_orgnl_txn_code     transactionlog.txn_code%type;
v_comp_cnt           number(5);
v_waiver_amount      varchar2(30);
v_orgnl_cardno       varchar2(20);
v_instcode           number(1);
v_flag               varchar2(1);
v_err                varchar2(1000);
vp_preauth_exp_period cms_prod_mast.cpm_pre_auth_exp_date%TYPE ;
vp_preauth_hold        VARCHAR2(1);
vp_preauth_period      NUMBER;
vi_preauth_exp_period  cms_inst_param.cip_param_value%TYPE ;
vi_preauth_hold        VARCHAR2(1);
vi_preauth_period      NUMBER;
v_preauth_exp_period   VARCHAR2(4);
V_PREAUTH_PERIOD      NUMBER;







cursor cur_txndata is
select rowid row_id,a.* from migr_online_txnlog a;


BEGIN

     v_err := 'OK';

     truncate_tab_ebr ('MIGR_ONLINE_TXNLOG');

      BEGIN

        INSERT INTO MIGR_ONLINE_TXNLOG
        select  MSGTYPE                                                                 --MESSAGE TYPE
                ,
                RRN                                                                     --RRN
                ,
                DELIVERY_CHANNEL                                                        --DELIVERY CHANNEL
                ,
                TERMINAL_ID                                                             --TERMINAL ID
                ,
                TXN_CODE                                                                --TRANSACTION CODE
                ,
                TXN_TYPE                                                                --TRANSACTION TYPE
                ,
                TXN_MODE                                                                --TRANSACTION MODE
                ,
                RESPONSE_CODE                                                           --RESPONSE CODE
                ,
                BUSINESS_DATE                                                           --BUSINESS DATE
                ,
                BUSINESS_TIME                                                           --BUSINESS TIME
                ,
                fn_dmaps_main(customer_card_no_encr) CARD_NUMBER                        --CARD NUMBER
                ,
                fn_dmaps_main(topup_card_no_encr) BENEFICIARY_CARD_NUMBER               --BENEFICIARY  CARD NUMBER
                ,
                trim(to_char(nvl(TOTAL_AMOUNT,0.00),'999999999990.99'))TOTAL_AMOUNT     --TOTAL AMOUNT
                ,
                MERCHANT_NAME                                                           --MERCHANT NAME
                ,
                MERCHANT_CITY                                                           --MERCHANT CITY
                ,
                MCCODE                                                                  --MCC CODE
                ,
                CURRENCYCODE                                                            --CURRENCY  CODE
                ,
                ATM_NAME_LOCATION                                                       --ATM NAME LOCATION
                ,
                trim(to_char(nvl(AMOUNT,'0.00'),'999999999990.99')) AMOUNT              --AMOUNT
                ,
                case when DELIVERY_CHANNEL = '02' AND TXN_CODE ='11' then
                to_char(add_ins_Date,'yyyymmdd hh24:mi:ss')                             --PRE AUTH DATE TIME
                end PREAUTH_DATE_TIME
                ,
                SYSTEM_TRACE_AUDIT_NO                                                   --STAN
                ,
                trim(to_char(nvl(TRANFEE_AMT,'0.00'),'999999999990.99')) TRANFEE_AMT    --TRANSACTION FEE AMOUNT
                ,
                trim(to_char(nvl(SERVICETAX_AMT,'0.00'),'999999999990.99'))             --SERVICE TAX AMOUNT
                SERVICETAX_AMT
                ,
                decode(tran_reverse_flag,null,'1','N','1','Y','0')                      --TRANSACTION REVERSE FLAG
                tran_reverse_flag
                ,
                CUSTOMER_ACCT_NO ACCOUNT_NUMBER                                         --ACCOUNT NUMBER
                ,
                /*(select fn_dmaps_main(cap_pan_code_encr)                              --ORIGINAL CARD NUMBER
                from cms_appl_pan
                where cap_inst_code = instcode
                AND   cap_pan_code = orgnl_card_no
                )*/ orgnl_card_no ORIGINAL_CARD_NUMBER --Modified for Galileo changes
                ,
                ORGNL_RRN                                                               --ORIGINAL RRN
                ,
                ORGNL_BUSINESS_DATE                                                     --ORIGINAL BUSINESS DATE
                ,
                ORGNL_BUSINESS_TIME                                                     --ORIGINAL BUSINESS TIME
                ,
                ORGNL_TERMINAL_ID                                                       --ORIGINAL TERMINAL ID
                ,
                DECODE(nvl(tran_reverse_flag,'N'),'N',nvl(REVERSAL_CODE,'00'),'0400')   --REVERSAL CODE
                REVERSAL_CODE
                ,
                PROXY_NUMBER                                                            --PROXY NUMBER
                ,
                trim(to_char(nvl(ACCT_BALANCE,'0.00'),'999999999990.99'))                --ACCOUNT BALANCE
                ACCT_BALANCE
                ,
                trim(to_char(nvl(LEDGER_BALANCE,'0.00'),'999999999990.99'))             --LEDGER BALANCE
                LEDGER_BALANCE
                ,
                ACHFILENAME                                                             --ACH FILE NAME
                ,
                RETURNACHFILENAME                                                       --RETURN ACH FILE NAME
                ,
                ODFI                                                                    --ODFI
                ,
                RDFI                                                                    --RDFI
                ,
                SECCODES                                                                --SEC CODES
                ,
                substr(IMPDATE,1,8)                                                     --IMP DATE
                IMPDATE
                ,
                substr(PROCESSDATE,1,8)                                                 --PROCESS DATE
                PROCESSDATE
                ,
                substr(EFFECTIVEDATE,1,8)                                               --EFFECTIVE DATE
                EFFECTIVEDATE
                ,
                AUTH_ID                                                                 --AUTH ID
                ,
                case when delivery_channel ='02' and txn_code ='11'
                then trim(to_char(nvl(LEDGER_BALANCE,'0.00'),'999999999990.99'))
                else
                decode
                (nvl(REVERSAL_CODE,0),0,                                                --BEFORE TXN LEDGER BAL
                trim(to_char(nvl((nvl(LEDGER_BALANCE,0) +
                                  nvl(total_amount,0)),'0.00'),'999999999990.99')),
                trim(to_char(nvl((nvl(LEDGER_BALANCE,0) -
                                  nvl(total_amount,0)),'0.00'),'999999999990.99'))
                )
                end BEFORE_TXN_LEDGER_BAL
                ,
                decode(nvl(REVERSAL_CODE,0),0,                                          --Before txn acct bal
                trim(to_char(nvl(nvl(ACCT_BALANCE,0) +
                                  nvl(total_amount,0),'0.00'),'999999999990.99')),
                trim(to_char(nvl(nvl(ACCT_BALANCE,0) -
                                  nvl(total_amount,0),'0.00'),'999999999990.99'))
                ) BEFORE_TXN_ACCT_BAL
                ,
                ACHTRANTYPE_ID                                                          --ACH TRANSACTION TYPE ID
                ,
                INCOMING_CRFILEID                                                       --INCOMING CR FILE ID
                ,
                INDIDNUM                                                                --IND ID NUM
                ,
                INDNAME                                                                 --IND NAME
                ,
                ACH_ID                                                                  --ACH ID
                ,
                IPADDRESS                                                               --IPADDRESS
                ,
                ANI                                                                     --ANI
                ,
                DNI                                                                     --DNI
                ,
                cardstatus                                                              --CARD STATUS
                ,
                '0.00' WAIVER_AMT                                                                 -- Waiver Amt
                ,
                INTERNATION_IND_RESPONSE INTERNATIONAL_INDICATOR                        -- INTERNATIONAL INDICATOR
                ,
                CASE WHEN CR_DR_FLAG ='DR' AND REVERSAL_CODE = '0' THEN '0'
                WHEN CR_DR_FLAG ='CR'                         THEN '1'
                WHEN CR_DR_FLAG ='NA'                              THEN '2'
                WHEN CR_DR_FLAG ='DR' AND REVERSAL_CODE <> '0'     THEN '1'
                end CR_DR_FLAG                                                          --CR_DR_FLAG
                ,
                0 INCREMENTAL_INDICATOR                                                 -- Incremental Indicator
                ,
                PARTIAL_PREAUTH_IND PARTIAL_AUTH_INDICATOR                              --PARTIAL AUTH INDICATOR
                ,
                /*case when delivery_channel = '02' and txn_code = '12'
                     and response_code = '00'
                then (select CPH_COMP_COUNT
                     from cms_preauth_trans_hist
                     where cph_rrn=rrn
                     and   cph_card_no=customer_card_no
                     AND   CPH_TXN_DATE = business_date
                     and   CPH_TXN_time = business_time
                     )
                else '0' end */ '' COMPLETION_COUNT                                          -- Completion Count
                ,
                case when delivery_channel = '02' and txn_code = '12'
                     and response_code = '00'
                then nvl(PREAUTH_LASTCOMP_IND,'N')                                      --LAST COMPLETION INDICATOR
                else ''
                end LAST_COMPLETION_INDICATOR
                ,
                '000'  PREAUTH_EXPIRY_PERIOD                                            -- Preauth expiry period
                ,
                'F'   MERCHANT_FLR_LIMIT_IND                                            --Merchant Flr Limit Ind
                ,
                ADDR_VERIFY_RESPONSE ADDRESS_VERIFICATION_INDICATOR                     --ADDRESS VERIFICATION INDICATOR
                ,
                trans_desc||'/'||merchant_name||'/'||merchant_city                       --NARRATION
                ||'/'||business_date||'/'||rrn NARRATION
                ,
                decode(DISPUTE_FLAG,'N','0','Y','1') DISPUTE_FLAG                       --DISPUTE FLAG
                ,
                case when delivery_channel = '11'                                       --Reason code
                AND txn_code IN ('22', '23', '32', '33')
                THEN '31'
                when delivery_channel = '04' AND txn_code IN ('68', '69')
                THEN '49'
                when delivery_channel = '04' AND txn_code = '75'
                THEN '2'
                when delivery_channel = '04' AND txn_code = '76'
                THEN '43'
                when delivery_channel = '04' AND txn_code = '77'
                THEN '54'
                when delivery_channel = '04' AND txn_code = '83'
                THEN '9'
                when delivery_channel = '10' AND txn_code = '06'
                THEN '54'
                when delivery_channel = '10' AND txn_code = '05'
                THEN  '61'
                when delivery_channel = '07' AND txn_code = '05'
                THEN  '43'
                when delivery_channel = '07' AND txn_code = '06'
                THEN '54'
                when delivery_channel = '10' AND txn_code = '02'
                THEN '55'
                when delivery_channel = '10'
                AND txn_code IN ('99', '11')
                THEN  '10'
                when delivery_channel = '07'
                AND txn_code IN ('02', '09')
                THEN '55'
                when delivery_channel = '08'
                AND txn_code IN ('25', '26', '28', '21', '22')
                THEN '31'
                when delivery_channel = '04'
                AND txn_code IN ('80', '82', '85', '88')
                THEN '31'
                when delivery_channel = '07' AND txn_code ='08'
                THEN '31'
                when delivery_channel = '03'
                AND txn_code IN ('13', '14')
                THEN '80'
                when delivery_channel = '03' AND txn_code = '11'
                THEN '69'
                when delivery_channel = '03' AND txn_code = '20'
                THEN '82'
                when delivery_channel = '03' AND txn_code = '19'
                THEN '13'
                when delivery_channel = '03' AND txn_code = '12'
                THEN '67'
                when delivery_channel = '03' AND txn_code = '37'
                THEN '101'
                when delivery_channel = '03' AND txn_code = '86'
                THEN '12'
                when delivery_channel = '03' AND txn_code = '75'
                THEN '2'
                when delivery_channel = '03' AND txn_code = '74'
                THEN '55'
                when delivery_channel = '03' AND txn_code = '76'
                THEN '62'
                when delivery_channel = '03' AND txn_code = '84'
                THEN '5'
                when delivery_channel = '03' AND txn_code = '85'
                THEN '6'
                when delivery_channel = '03' AND txn_code = '83'
                THEN '9'
                when delivery_channel = '03' AND txn_code = '78'
                THEN '3'
                when delivery_channel = '03' AND txn_code = '87'
                THEN '4'
                when delivery_channel = '03' AND txn_code in ('22', '29')
                THEN '10'
                else ''
                END REASON_CODE
                ,
                case when delivery_channel = '11'                                       --Remark
                AND txn_code IN ('22', '23', '32', '33')
                THEN 'ACH Credit Transaction'
                when delivery_channel = '04' AND txn_code IN ('68', '69')
                THEN 'CARD ACTIVATION WITH PROFILE'
                when ((delivery_channel = '04' AND txn_code in('75','76','77','83')) or
                      (delivery_channel = '10' AND txn_code in('06','05')) or
                      (delivery_channel = '07' AND txn_code in('06','05'))
                     )
                THEN 'Online Card Status Change'
                when delivery_channel = '10' AND txn_code = '02'
                THEN 'CHW Card Activation'
                when delivery_channel = '07' AND txn_code IN ('02', '09')
                THEN 'IVR Card Activation'
                when ((delivery_channel = '08'
                      AND txn_code IN ('25', '26', '28', '21', '22')) or
                     (delivery_channel = '04'
                      AND txn_code IN ('80', '82', '85', '88')) or
                     (delivery_channel = '07' AND txn_code ='08')
                     )
                THEN 'Online Card Topup'
                when delivery_channel = '03' AND txn_code IN ('13', '14')
                THEN 'Misc Fee Adjustment'
                when delivery_channel = '03' AND txn_code = '11'
                THEN 'Duplicate Auth'
                when delivery_channel = '03' AND txn_code = '20'
                THEN 'Live Agent Customer Support Fee'
                when delivery_channel = '03' AND txn_code = '19'
                THEN 'DD Exception'
                when delivery_channel = '03' AND txn_code = '12'
                THEN 'Incorrect Fee'
                when delivery_channel = '03' AND txn_code = '37'
                THEN 'Divorced'
                when delivery_channel = '03' AND txn_code = '86'
                THEN 'FRAUD TEAM RETURNED MAIL'
                when delivery_channel = '03' AND txn_code = '75'
                THEN 'Card Lost'
                when delivery_channel = '03' AND txn_code = '74'
                THEN 'ACTIVATE CARD'
                when delivery_channel = '03' AND txn_code = '76'
                THEN 'Fraud Investigation'
                when delivery_channel = '03' AND txn_code = '84'
                THEN 'FRAUD TEAM MONITORED'
                when delivery_channel = '03' AND txn_code = '85'
                THEN 'FRAUD TEAM HOT CARDED'
                when delivery_channel = '03' AND txn_code = '83'
                THEN 'Card Close'
                when delivery_channel = '03' AND txn_code = '78'
                THEN 'Card Stolen'
                when delivery_channel = '03' AND txn_code = '87'
                THEN 'CARD RESTRICT'
                when ((delivery_channel = '03' AND txn_code in ('22', '29')) or
                     (delivery_channel = '10' AND txn_code IN ('99', '11'))
                     )
                THEN 'Online Order Replacement Card'
                else ''
                END REMARK
                ,
                /*case when delivery_channel ='03' and txn_code ='25'                     -- DISPUTE REASON
                          and response_code ='00'
                then
                (select cdt_reason
                from cms_dispute_txns
                where cdt_pan_code = customer_card_no
                and   cdt_rrn = orgnl_rrn
                and   CDT_TXN_DATE = orgnl_business_date
                and   CDT_TXN_TIME = orgnl_business_time
                )
                else ''
                end */ '' DISPUTE_REASON
                ,
                /*case when delivery_channel ='03' and txn_code ='25'                     -- DISPUTE REMARK
                          and response_code ='00'
                then
                   (select cdt_remark
                    from cms_dispute_txns
                    where cdt_pan_code = customer_card_no
                    and   cdt_rrn = rrn
                    and   CDT_TXN_DATE = business_date
                    and   CDT_TXN_TIME = business_time
                    )
                else ''
                end */ '' DISPUTE_REMARK
                ,
                decode (MATCH_RULE,null,'N','Y') MATCH_COMPLETION_FLAG              -- Match completion flag
                ,
                case when delivery_channel = '03' and txn_code = '38'               --CARD TO CARD TRANSFER TRANSACTION STATUS
                     then 'N'
                     when delivery_channel = '03' and txn_code = '39'
                     then  'A'
                     when delivery_channel = '03' and txn_code = '40'
                     then 'R'
                end
                C2C_TXN_STATUS
                ,
                to_char(add_ins_date,'yyyymmdd hh24miss') POSTED_DATE                   --POSTED DATE
                ,
                trim(to_char(nvl(nvl(topup_ledger_balance,0) -
                             nvl(total_amount,0),'0.00'),'999999999990.99'))            --BEFORE TRANSACTION BENEFICIARY CARD LEDGER BALANCE
                BEF_TXN_TOPUP_CARD_LEDGER_BAL
                ,
                trim(to_char(nvl(nvl(topup_acct_balance,0)-
                                 nvl(total_amount,0),'0.00'),'999999999990.99'))        --BEFORE TRANSACTION BENEFICIARY CARD AVAILABLE BALANCE
                BEF_TXN_TOPUP_CARD_ACCT_BAL
                ,
                trim(to_char(nvl((TOPUP_LEDGER_BALANCE),'0.00'),'999999999990.99'))     --BENEFICIARY CARD LEDGER BALANCE
                TOPUP_CARD_LEDGER_BAL
                ,
                trim(to_char(nvl((TOPUP_ACCT_BALANCE),'0.00'),'999999999990.99'))       --BENEFICIARY CARD AVAILABLE BALANCE
                TOPUP_CARD_ACCT_BAL
                ,
                /*case when delivery_channel = '02' and txn_code = '11'                   -- Preauth expiry date
                     and response_code ='00'
                then (select to_char(cpt_expiry_date,'yyyymmdd hh24miss')
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
                else null end*/
                '' PREAUTH_EXPIRY_DATE
               ,
               TOPUP_ACCT_NO                                                           -- Topup account number
                ,
                /*case when delivery_channel = '02' and txn_code = '11'                   --Preauth valid flag
                     and response_code ='00'
                then (select CPT_PREAUTH_VALIDFLAG
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
                else null end*/
                '' PREAUTH_VALID_FLAG
                ,
                /*case when delivery_channel = '02' and txn_code = '11'                   --Preauth Expiry flag
                     and response_code ='00'
                then (select CPT_EXPIRY_FLAG
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
                else null end */
                '' PREAUTH_EXPIRY_FLAG
                ,
                /*case when delivery_channel = '02' and txn_code = '11'                   --Preauth completion flag
                     and response_code ='00'
                then (select cpt_completion_flag
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
                else null end*/
                '' PREAUTH_COMPLETION_FLAG
                ,
                /*case when delivery_channel = '02' and txn_code = '11'                    --Pending hold amount
                    and response_code ='00'
                then (select trim(to_char(nvl((CPT_TOTALHOLD_AMT),'0.00'),'999999999990.99'))
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
                else null end */
                '' PENDING_HOLD_AMOUNT
               ,
               /*case when delivery_channel = '02' and txn_code = '11'                    --Preauth transaction flag
                    and response_code ='00'
                then (select CPT_TRANSACTION_FLAG
                     from cms_preauth_transaction
                     where rrn=cpt_rrn
                     and   cpt_card_no=customer_card_no
                     and   CPT_TXN_DATE=business_date
                     and   CPT_TXN_TIME=business_time
                     )
               else null end */
               '' PREAUTH_TRANSACTION_FLAG
              ,
               /*case when delivery_channel ='03' and txn_code ='25'                       --Original delivery channel
                   and response_code ='00'
               then
                   (select CDT_DELIVERY_CHANNEL
                    from cms_dispute_txns
                    where cdt_pan_code = customer_card_no
                    and   cdt_rrn = rrn
                    and   CDT_TXN_DATE = business_date
                    and   CDT_TXN_TIME = business_time
                    )
               end */
               '' ORGNL_DEL_CHNL
               ,
               /*case when delivery_channel ='03' and txn_code ='25'                       --Original txn channel
                   and response_code ='00'
               then
                   (select CDT_txn_code
                    from cms_dispute_txns
                    where cdt_pan_code = customer_card_no
                    and   cdt_rrn = rrn
                    and   CDT_TXN_DATE = business_date
                    and   CDT_TXN_TIME = business_time
                    )
               end  */ '' ORGNL_TXN_CODE
              ,
              decode (reversal_code,0,'0.00',                                           --Reversal fee amount
                     TRIM(TO_CHAR(NVL(TRANFEE_AMT,'0.00'),'999999999990.99')) ) REVERSE_FEE_AMT,
                     TO_CHAR (time_stamp, 'YYYYMMDDHH24MISSFF5') TIME_STAMP  --Added for galileo changes
              from VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
              where customer_card_no in (select gethash(mtt_card_no) from MIGR_TRANSACTIONLOG_TEMP where mtt_flag ='S' and mtt_migr_seqno=p_seq_no)
              and   add_ins_user <> (select CUM_USER_CODE from cms_userdetl_mast where CUM_LGIN_CODE ='MIGR_USER');

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                     'ERROR WHILE INSERTION INTO MIGR_ONLINE_TXNLOG TABLE ' || SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
            RETURN;
      END;

    v_instcode := 1;

    for i in cur_txndata
    loop

        Begin
		

           select trim(to_char(nvl(ctd_waiver_amount,'0.00'),'999999999990.99'))
           into   v_waiver_amount
           from  VMSCMS.CMS_TRANSACTION_LOG_DTL_VW		--Added for VMS-5733/FSP-991
           where ctd_inst_code = v_instcode
           and   ctd_customer_card_no = i.card_number
           and   ctd_delivery_channel = i.delivery_channel
           and   ctd_txn_code = i.txn_code
           and   ctd_business_date = i.business_date
           and   ctd_business_time = i.business_time
           and   ctd_rrn = i.rrn;

        exception when no_data_found
        then
             v_waiver_amount := '0.00';
        when others
        then
            p_resp_msg := 'ERROR WHILE SELECTING WAIVER AMOUNT -' ||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
            RETURN;
        End;



       if i.reversal_code <> 0 or
          (i.delivery_channel ='03' and i.txn_code ='25') or
          (i.delivery_channel ='02' and i.txn_code ='12')
       then
            BEGIN

                select fn_dmaps_main(cap_pan_code_encr)
                into   v_orgnl_cardno
                from cms_appl_pan
                WHERE CAP_INST_CODE = V_INSTCODE
                AND cap_pan_code = i.ORIGINAL_CARD_NUMBER /*(select ORGNL_CARD_NO
                                      from transactionlog
                                      where instcode = v_instcode
                                      and customer_card_no = gethash(i.card_number)
                                      and business_date = i.business_date
                                      and business_time=i.business_time
                                      AND delivery_channel = i.delivery_channel
                                      and txn_code = i.txn_code
                                      and rrn=i.rrn
                                     )*/;  --Modified for galileo changes

                  v_flag := 'Y';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   v_orgnl_cardno := null;
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING ORGNL CARD -' ||SUBSTR (SQLERRM, 1, 200);
              RETURN;
            END;

       end if;


        if i.DELIVERY_CHANNEL = '02' and i.txn_code = '12' and i.RESPONSE_CODE = '00'
        then

           BEGIN

             select cph_comp_count
             into   v_comp_cnt
             from cms_preauth_trans_hist
             where cph_inst_code = v_instcode
             and   cph_card_no=gethash(i.card_number)
             AND   cph_txn_date = i.business_date
             and   cph_txn_time = i.business_time
             and   cph_rrn=i.rrn;


             v_flag := 'Y';

           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   v_comp_cnt := 0;
           WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING COMPLETION COUNT -' ||SUBSTR (SQLERRM, 1, 200);
              RETURN;
           END;

        end if;

        if i.delivery_channel ='03' and i.txn_code ='25' and i.response_code ='00'
        then

           BEGIN
                select cdt_reason,
                       cdt_remark,
                       cdt_delivery_channel,
                       cdt_txn_code
                into   v_disp_reason,
                       v_disp_remark,
                       v_orgnl_del_chnl,
                       v_orgnl_txn_code
                from cms_dispute_txns
                where cdt_inst_code = v_instcode
                and   cdt_pan_code = gethash(i.card_number)
                and   CDT_TXN_DATE = i.orgnl_business_date
                and   CDT_TXN_TIME = i.orgnl_business_time
                and   cdt_rrn = i.orgnl_rrn;


                v_flag := 'Y';

           EXCEPTION
                WHEN NO_DATA_FOUND THEN

                v_disp_reason := null;
                v_disp_remark := null;
                v_orgnl_del_chnl := null;
                v_orgnl_txn_code := null;

           WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING DISPUTE DETAILS -' ||SUBSTR (SQLERRM, 1, 200);--Error message modified by Pankaj S. on 25-Sep-2013
              RETURN;
           END;

        end if;


          BEGIN
          
             SELECT NVL (cpm_pre_auth_exp_date, '000')
               INTO vp_preauth_exp_period
               FROM cms_prod_mast
              WHERE cpm_prod_code = (select cap_prod_code from cms_appl_pan where cap_pan_code = i.card_number);
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                vp_preauth_exp_period := '000';
             WHEN OTHERS
             THEN
                vp_preauth_exp_period := '000';
          END;
          
          BEGIN
             SELECT NVL (cip_param_value, '000')
               INTO vi_preauth_exp_period
               FROM cms_inst_param
              WHERE cip_inst_code = v_instcode
                AND cip_param_key = 'PRE-AUTH EXP PERIOD';
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                vi_preauth_exp_period := '000';
             WHEN OTHERS
             THEN
                vi_preauth_exp_period := '000';
          END; 
          
          
          BEGIN
          
              vp_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 1, 1));
              vp_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 2, 2));
              
              vi_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 1, 1));--
              vi_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 2, 2));

                IF vp_preauth_hold = vi_preauth_hold
                  THEN
                  
                     SELECT GREATEST (vp_preauth_period, vi_preauth_period)
                       INTO v_preauth_period
                       FROM DUAL;
                       
                     IF v_preauth_period = vp_preauth_period
                     THEN
                      v_preauth_exp_period :=  vp_preauth_exp_period;
                     ELSE
                     v_preauth_exp_period :=  vi_preauth_exp_period;
                     
                     END IF; 
                       
                ELSE
                
                     IF vp_preauth_hold > vi_preauth_hold
                     THEN
                        v_preauth_exp_period :=  vp_preauth_exp_period;
                        
                     ELSIF vp_preauth_hold < vi_preauth_hold
                     THEN
                        v_preauth_exp_period :=  vi_preauth_exp_period;
                        
                     END IF;
                     
                     
                END IF;  
                
          EXCEPTION WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE EXPIRY PERIOD CALCULATION -' ||SUBSTR (SQLERRM, 1, 200);
              RETURN;
          END;
                                 
          
          

        if i.delivery_channel = '02' and i.txn_code = '11' and i.response_code ='00'
        then

           BEGIN
                 select to_char(cpt_expiry_date,'yyyymmdd hh24miss'),
                        CPT_PREAUTH_VALIDFLAG,
                        CPT_EXPIRY_FLAG,
                        cpt_completion_flag,
                        trim(to_char(nvl((CPT_TOTALHOLD_AMT),'0.00'),'999999999990.99')),
                        CPT_TRANSACTION_FLAG
                 into   v_preauth_exp_date,
                        v_preauth_valid_flag,
                        v_preauth_expry_flag,
                        v_preauth_comp_flag,
                        v_hold_amount,
                        v_preauth_txn_flag
                 from VMSCMS.CMS_PREAUTH_TRANSACTION_VW		--Added for VMS-5733/FSP-991
                 where cpt_inst_code = v_instcode
                 and   cpt_card_no=gethash(i.card_number)
                 and   CPT_TXN_DATE=i.business_date
                 and   CPT_TXN_TIME=i.business_time
                 and   cpt_rrn=i.rrn;


                 v_flag := 'Y';

           EXCEPTION
                WHEN NO_DATA_FOUND THEN

                v_preauth_exp_date := null;
                v_preauth_valid_flag := null;
                v_preauth_expry_flag := null;
                v_preauth_comp_flag := null;
                v_hold_amount := '0.00';
                v_preauth_txn_flag := null;

           WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING PREAUTH DETAILS -' ||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
              RETURN;
           END;

        end if;


       if v_flag = 'Y'
       then

            BEGIN
                update MIGR_ONLINE_TXNLOG
                set   ORIGINAL_CARD_NUMBER = v_orgnl_cardno,
                      COMPLETION_COUNT     = v_comp_cnt,
                      DISPUTE_REASON       = v_disp_reason,
                      DISPUTE_REMARK       = v_disp_remark,
                      ORGNL_DEL_CHNL       = v_orgnl_del_chnl,
                      ORGNL_TXN_CODE       = v_orgnl_txn_code,
                      PREAUTH_EXPIRY_DATE  = v_preauth_exp_date,
                      PREAUTH_VALID_FLAG   = v_preauth_valid_flag,
                      PREAUTH_EXPIRY_FLAG  = v_preauth_expry_flag,
                      PREAUTH_COMPLETION_FLAG  = v_preauth_comp_flag,
                      PENDING_HOLD_AMOUNT      = v_hold_amount,
                      PREAUTH_TRANSACTION_FLAG = v_preauth_txn_flag,
                      WAIVER_AMT               = v_waiver_amount,
                      PREAUTH_EXPIRY_PERIOD    = v_preauth_exp_period
                 where rowid = i.row_id;

            EXCEPTION WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE UPDATING TXN DETAILS -' ||SUBSTR (SQLERRM, 1, 200);
              RETURN;
            END;

        end if;

    end loop;

    BEGIN

     MIGR_ONLINE_TXNDATA_FILE(p_seq_no,p_resp_msg);

         if p_resp_msg <> 'OK'
         then
         ROLLBACK;
         p_resp_msg := 'Error while file tran writting '||p_resp_msg;--substr(sqlerrm,1,100);
         return;

         end if;
         
    EXCEPTION WHEN OTHERS
    THEN
    ROLLBACK;
     p_resp_msg := 'Error While calling file writting method for txndata '||substr(sqlerrm,1,100); --Error message modified by Pankaj S. on 25-Sep-2013
     return;
    END;

    p_resp_msg := v_err;


EXCEPTION WHEN OTHERS
THEN
ROLLBACK;
p_resp_msg := 'MAIN EXCEPTION -' ||SUBSTR (SQLERRM, 1, 200);
RETURN;

end;
/
SHOW ERROR;
