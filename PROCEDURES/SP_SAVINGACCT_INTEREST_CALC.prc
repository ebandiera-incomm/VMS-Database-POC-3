create or replace
PROCEDURE        vmscms.SP_SAVINGACCT_INTEREST_CALC(p_sysdate in date)
AS
/*************************************************
     * Created Date     :  19-Apr-2012
     * Created By       :  Saravanakumar
     * Purpose          :  For calculating interest for saving account.
     * Modified BY      :  B.Besky Anand
     * Modified Date    :  04/01/2013
     * Modified Reason  : CR-40 -> To maintain the opening balance of saving account for statement period
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  18-Jan-2013
     * Build Number     :  CMS3.5.1_RI0023.1_B0003

     * Modified By      : Sagar More
     * Modified Date    : 26-Sep-2013
     * Modified For     : LYFEHOST-63
     * Modified Reason  : To fetch saving acct parameter based on product code
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : Arun
     * Modified Date    : 28-Mar-2014
     * Modified For     : Mantis ID-13995
     * Modified Reason  : Logging of compound balance null intrest accured in CMS_INTREST_DETL
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Mar-2014
     * Build Number     : RI0024.6.8.1_B0001

     * Modified By     : Siva Kumar M
     * Modified Date    : 15-May-2014
     * Modified For     :  MVHOST 903
     * Modified Reason  : Calculating the APYE value
     * Build Number     : RI0027.1.6_B0001

     * Modified By     : ARUN VIJAY
     * Modified Date    : 20-May-2014
     * Modified For     :  MVHOST 903
     * Modified Reason  : Calculating the APYE value
     * Reviewer         : RI0027.1.6_B0002

     * Modified By      : Siva Kumar M
     * Modified Date    : 21-May-2014
     * Modified For     : Mantis ID:0014715
     * Modified Reason  : Same Timestamp in details getting update for CMS_Interest_detl table.
     * Build Number     : RI0027.1.6_B0003

     * Modified By      : Ramesh A
     * Modified Date    : 20-Jun-2014
     * Modified For     : FSS-1722 : APYE changes
     * Reviewer         : spankaj
     * Build Number     : RI0027.1.9_B0002

	 * Modified By      : Ramesh A
     * Modified Date    : 23-Jun-2014
     * Modified For     : FSS-1722 : APYE changes
     * Reviewer         : spankaj
     * Build Number     : RI0027.1.9_B0003

     * Modified By      : Ramesh A
     * Modified Date    : 14-July-2014
     * Modified For     : FSS-1722 : APYE changes based on quarterly
     * Reviewer         : Saravanakumar
     * Build Number     : RI0027.1.9.2_B0001(Integration)

	 * Modified By      : Ramesh A
     * Modified Date    : 18-July-2014
     * Modified For     : 2.1.9.2 integration
     * Build Number     : RI0027.2.4_B0001

        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07

*************************************************/
v_interest_rate        NUMBER(6,3);
v_factor               NUMBER(30,10);
v_compound_balance     cms_interest_detl.cid_interest_amount%TYPE;
v_daily_accrual        cms_interest_detl.cid_interest_amount%TYPE;
v_type_code            cms_acct_type.cat_type_code%TYPE;
v_status_code          cms_acct_stat.cas_stat_code%TYPE;
v_delivery_channel     VARCHAR2(2)  DEFAULT '05';
v_savepoint            NUMBER DEFAULT 0;
v_switch_acct_type     cms_acct_type.cat_switch_type%TYPE DEFAULT '22';
v_switch_acct_status   cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '8';
v_err_msg              VARCHAR2(500);
EXP_REJECT_RECORD      EXCEPTION;

v_prod_code            cms_appl_pan.cap_prod_code%type; -- Added for LYFEHOST-63
v_card_type            cms_appl_pan.CAP_CARD_TYPE%type;
v_apye    number(30,9);
v_no_days number;
v_average_balance number(30,9);
v_balance_hist  cms_interest_detl_hist.cid_interest_amount%TYPE;
v_balance_dtl   cms_interest_detl.cid_interest_amount%TYPE;
v_sysdate      date;

BEGIN



    FOR i IN (SELECT cim_inst_code FROM cms_inst_mast)
    LOOP
                -- added for mvhost-903
               begin
                v_sysdate := p_sysdate;
               --  select SYSDATE  into v_sysdate from dual;              
               exception
                 when others then
                    v_err_msg:='Error while selecting date from dual '||SUBSTR(SQLERRM,1,200);
                    RAISE EXP_REJECT_RECORD;

               end;

                     -- calculating the day from the quater starting to sysdate.
               IF  v_sysdate < LAST_DAY(ADD_MONTHS(TRUNC(v_sysdate, 'Q'),2))
               THEN

                    begin
                         SELECT  TRUNC( LAST_DAY (ADD_MONTHS (TRUNC (v_sysdate, 'Q'), 2)) - TRUNC (v_sysdate, 'Q') + 1 - ( to_date(LAST_DAY (ADD_MONTHS (TRUNC (v_sysdate, 'Q'), 2)),'dd-MM-yy') - v_sysdate ))
                            into v_no_days FROM dual;
                    exception
                         when others then
                        v_err_msg:='Error while selecting date from dual '||SUBSTR(SQLERRM,1,200);
                        RAISE EXP_REJECT_RECORD;
                     end;
               ELSE

                      begin
                              SELECT  TRUNC( LAST_DAY (ADD_MONTHS (TRUNC (v_sysdate, 'Q'), 2)) - TRUNC (v_sysdate, 'Q') + 1) into  v_no_days
                              from dual;

                      exception
                                 when others then
                              v_err_msg:='Error while selecting date from dual '||SUBSTR(SQLERRM,1,200);
                              RAISE EXP_REJECT_RECORD;
                      end;

               END IF;

        BEGIN
           -- v_savepoint:= v_savepoint+1;
           -- SAVEPOINT v_savepoint;

            --Fetching type code for saving account
            BEGIN
                SELECT cat_type_code INTO v_type_code FROM cms_acct_type
                WHERE cat_switch_type=v_switch_acct_type and cat_inst_code=i.cim_inst_code;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_err_msg:='Type code is not defined for the institution';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                    v_err_msg:='Error while selecting type code for the institution '||SUBSTR(SQLERRM,1,200);
                    RAISE EXP_REJECT_RECORD;
            END;

            --Fetching status code for saving account
            BEGIN
                SELECT cas_stat_code INTO v_status_code FROM cms_acct_stat
                WHERE cas_switch_statcode=v_switch_acct_status  and cas_inst_code=i.cim_inst_code;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_err_msg:='Status code is not defined for the institution';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                    v_err_msg:='Error while selecting status for the institution '||SUBSTR(SQLERRM,1,200);
                    RAISE EXP_REJECT_RECORD;
            END;

            --Fetching saving account with account status is open
            FOR j IN (SELECT cam_acct_id,cam_acct_no,cam_acct_bal,CAM_LEDGER_BAL,NVL(cam_interest_amount,0) cam_interest_amount                 -- Added by Besky on 04/01/2013 for CR-40 -> To maintain the opening balance of saving account for statement period
                      FROM cms_acct_mast WHERE cam_type_code=v_type_code AND cam_stat_code=v_status_code AND cam_inst_code= i.cim_inst_code)
            LOOP
                BEGIN
                    v_savepoint:= v_savepoint+1;
                    SAVEPOINT v_savepoint;
                   --Sn  Added by Besky on 04/01/2013 for CR-40 -> To maintain the opening balance of saving account for statement period

                    IF TO_CHAR(sysdate,'DD')='01' THEN

                        BEGIN

                            INSERT INTO CMS_STMTPRD_SVGACTBAL
                            (
                            CSS_INST_CODE,
                            CSS_ACCT_NO,
                            CSS_ACCT_ID,
                            CSS_STAT_CODE,
                            CSS_ACCT_BAL,
                            CSS_LEDGER_BAL,
                            CSS_STATMENT_PERIOD,
                            CSS_INS_USER,
                            CSS_INS_DATE,
                            CSS_LUPD_USER,
                            CSS_LUPD_DATE
                            )
                            VALUES
                            (
                            i.cim_inst_code,
                            J.cam_acct_no,
                            J.cam_acct_id,
                            v_status_code,
                            J.cam_acct_bal,
                            j.cam_ledger_bal,
                            v_sysdate,--sysdate -- Modified for FSS-1722
                            1,
                            v_sysdate,--sysdate  -- Modified for FSS-1722
                            1,
                            v_sysdate--sysdate  -- Modified for FSS-1722
                            );
                            EXCEPTION
                                WHEN OTHERS THEN
                                v_err_msg:='Error while inserting in to CMS_STMTPRD_SVGACTBAL  '||SUBSTR(SQLERRM,1,200);
                                RAISE EXP_REJECT_RECORD;
                        END;

                    END IF;

                --End    for CR-40

                    ---------------------------------
                    --SN: Query added for LYFEHOST-63
                    ---------------------------------

                      BEGIN

                            SELECT mm.cap_prod_code,mm.CAP_CARD_TYPE
                              INTO v_prod_code,v_card_type
                              FROM (SELECT   cap_prod_code,CAP_CARD_TYPE
                                        FROM cms_appl_pan
                                       WHERE cap_cust_code =
                                                (SELECT cca_cust_code
                                                   FROM cms_cust_acct
                                                  WHERE cca_acct_id = j.cam_acct_id
                                                    AND cca_inst_code = i.cim_inst_code)
                                         AND cap_card_stat NOT IN ('9')
                                         AND cap_addon_stat = 'P'
                                         AND cap_inst_code = i.cim_inst_code
                                    ORDER BY cap_pangen_date DESC)mm
                             WHERE ROWNUM = 1;

                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         V_ERR_MSG   := 'Prod code not found for account id '||j.cam_acct_id;
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_ERR_MSG   := 'Error while selecting prod code ' ||SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;
                    ---------------------------------
                    --EN: Query added for LYFEHOST-63
                    ---------------------------------


                    --Fetching interest rate for saving account
                    BEGIN

                        SELECT cdp_param_value INTO v_interest_rate FROM cms_dfg_param
                        WHERE cdp_param_key='Saving account Interest rate'
                        and cdp_inst_code=i.cim_inst_code
                        and cdp_prod_code = v_prod_code                        -- Added for LYFEHOST-63
                        and cdp_card_type = v_card_type;


                    EXCEPTION
                        WHEN OTHERS THEN
                            v_err_msg:='Error while selecting interest rate for saving account '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;
                    END;



                    --Calculating interest
                    v_factor:=ROUND((v_interest_rate/365/100),10);
                    v_compound_balance:=TRUNC((j.cam_acct_bal+j.cam_interest_amount),9);
                    v_daily_accrual:=TRUNC((v_factor*v_compound_balance),9);

                    --ST APYE Calculation

                      /* -- Commented for FSS-1722
                      begin

                            select nvl( sum (CID_CLOSE_BALANCE-CID_INTEREST_AMOUNT),0)
                              into v_balance_hist
                              from cms_interest_detl_hist
                              where cid_inst_code=i.cim_inst_code
                              and cid_acct_no = j.cam_acct_no
                              and trunc(cid_calc_date) between TRUNC(v_sysdate , 'Year') and trunc(v_sysdate);

                      exception
                        when others then

                            v_err_msg:='Error while selecting details from interest hist for saving account '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;
                      end;
                      */
                       begin

                           select nvl( sum (CID_CLOSE_BALANCE-CID_INTEREST_AMOUNT),0)
                              into v_balance_dtl
                              from cms_interest_detl
                              where cid_inst_code=i.cim_inst_code
                              and cid_acct_no = j.cam_acct_no
                             -- and to_char(CID_CALC_DATE,'MMYYYY') = to_char(v_sysdate,'MMYYYY');  -- Added for FSS-1722
                              AND cid_calc_date BETWEEN TRUNC(v_sysdate,   'q') AND v_sysdate; --Added for FSS-1722 : APYE changes based on quarterly

                       exception
                        when others then
                           v_err_msg:='Error while selecting interest detl for saving account '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;

                      end;


                      --if v_balance_dtl+v_balance_hist > 0 -- Commented for FSS-1722
                      if v_balance_dtl > 0 -- Added for FSS-1722
                      then

                       v_average_balance := trunc( ((v_balance_dtl+j.cam_acct_bal)/ (trunc(v_sysdate - trunc(v_sysdate , 'q'))+1)) ,9);  --Added for FSS-1722 : APYE changes based on quarterly

                      else
                         v_average_balance := trunc( (j.cam_acct_bal/ (trunc(v_sysdate - trunc(v_sysdate , 'q'))+1)) ,9);  --Added for FSS-1722 : APYE changes based on quarterly
                      end if;


                     v_apye:=round( 100*((power(TRUNC((1+( round((j.cam_interest_amount+v_daily_accrual),2) /v_average_balance)),9),(365/v_no_days)))-1),2 );  -- Modified for FSS-1722

                    -- EN APYE Calculation



                    --Inserting interest details
                    BEGIN
                        INSERT INTO cms_interest_detl
                                    (cid_inst_code ,
                                    cid_acct_no ,
                                    cid_interest_rate ,
                                    cid_interest_amount ,
                                    cid_calc_date ,
                                    cid_close_balance ,
                                    cid_compound_balance, --Added for Mantis id :13995
                                    cid_qtly_interest_accr, --Added for Mantis id :13995
                                    cid_ins_user,
                                    cid_ins_date,
                                    cid_apye_amount)
                        VALUES
                                    (i.cim_inst_code,
                                     j.cam_acct_no,
                                     v_interest_rate,
                                     v_daily_accrual,
                                     v_sysdate,--sysdate,  -- Modified for FSS-1722
                                     j.cam_acct_bal+v_daily_accrual,
                                     v_compound_balance, --Added for Mantis id :13995
                                     j.cam_interest_amount+v_daily_accrual, --Added for Mantis id :13995
                                     1,
                                     v_sysdate,--sysdate,  -- Modified for FSS-1722
                                     v_apye);

                        /*IF SQL%ROWCOUNT =0 THEN
                            v_err_msg:='Interest detail is not inserted';
                            RAISE EXP_REJECT_RECORD;
                        END IF;*/

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_err_msg:='Error while inserting interest detail '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                    --Updating interest amount
                    BEGIN
                        UPDATE cms_acct_mast SET cam_interest_amount=v_daily_accrual+j.cam_interest_amount,
                        cam_lupd_date=sysdate,cam_lupd_user=1
                        WHERE cam_acct_no=j.cam_acct_no and cam_inst_code=i.cim_inst_code;

                        IF SQL%ROWCOUNT =0 THEN
                            v_err_msg:='Interest amount is not updated';
                            RAISE EXP_REJECT_RECORD;
                        END IF;
                    EXCEPTION
                        WHEN EXP_REJECT_RECORD THEN
                            RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                            v_err_msg:='Error while updating interest amount '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                EXCEPTION
                    WHEN EXP_REJECT_RECORD THEN
                        ROLLBACK TO v_savepoint;
                        --Loging error
                        BEGIN
                            INSERT INTO cms_transaction_log_dtl
                                        ( ctd_delivery_channel,
                                        ctd_process_flag,
                                        ctd_process_msg,
                                        ctd_inst_code,
                                        ctd_ins_date,
                                        ctd_ins_user,
                                        ctd_cust_acct_number )
                            VALUES      ( v_delivery_channel,
                                        'E',
                                        'Interest_Calculation_'||v_err_msg,
                                        i.cim_inst_code,
                                        v_sysdate,--sysdate,  -- Modified for FSS-1722
                                        1,
                                        j.cam_acct_no );
                        EXCEPTION
                            WHEN OTHERS THEN
                                ROLLBACK TO v_savepoint;
                        END;
                    WHEN OTHERS THEN
                        v_err_msg := 'Main Exception 1'||SUBSTR(SQLERRM,1,200);
                        ROLLBACK TO v_savepoint;
                        --Loging error
                        BEGIN
                            INSERT INTO cms_transaction_log_dtl
                                        ( ctd_delivery_channel,
                                        ctd_process_flag,
                                        ctd_process_msg,
                                        ctd_inst_code,
                                        ctd_ins_date,
                                        ctd_ins_user,
                                        ctd_cust_acct_number )
                            VALUES      ( v_delivery_channel,
                                        'E',
                                        'Interest_Calculation_'||v_err_msg,
                                        i.cim_inst_code,
                                        v_sysdate,--sysdate,  -- Modified for FSS-1722
                                        1,
                                        j.cam_acct_no );
                        EXCEPTION
                            WHEN OTHERS THEN
                                ROLLBACK TO v_savepoint;
                        END;
                END;
            END LOOP;
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                ROLLBACK TO v_savepoint;
                --Loging error
                BEGIN
                    INSERT INTO cms_transaction_log_dtl
                                ( ctd_delivery_channel,
                                ctd_process_flag,
                                ctd_process_msg,
                                ctd_inst_code,
                                ctd_ins_date,
                                ctd_ins_user)
                    VALUES      ( v_delivery_channel,
                                'E',
                                'Interest_Calculation_'||v_err_msg,
                                i.cim_inst_code,
                                v_sysdate,--sysdate, -- Modified for FSS-1722
                                1);
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO v_savepoint;
                END;
            WHEN OTHERS THEN
                v_err_msg := 'Main Exception 1'||SUBSTR(SQLERRM,1,200);
                ROLLBACK TO v_savepoint;
                --Loging error
                BEGIN
                    INSERT INTO cms_transaction_log_dtl
                                ( ctd_delivery_channel,
                                ctd_process_flag,
                                ctd_process_msg,
                                ctd_inst_code,
                                ctd_ins_date,
                                ctd_ins_user)
                     VALUES      ( v_delivery_channel,
                                'E',
                                'Interest_Calculation_'||v_err_msg,
                                i.cim_inst_code,
                                 v_sysdate,--sysdate, -- Modified for FSS-1722
                                1);
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO v_savepoint;
                 END;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO v_savepoint;
END;
/
show error