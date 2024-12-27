create or replace
PROCEDURE        VMSCMS.SP_SAVINGACCT_INTEREST_CALC
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
     * Modified Reason  : Logging of compound balance & QTD intrest accured in CMS_INTREST_DETL 
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Mar-2014
     * Build Number     : RI0024.6.8.1_B0001   	 
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

BEGIN

    FOR i IN (SELECT cim_inst_code FROM cms_inst_mast)
    LOOP
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
             
                    IF TO_CHAR(SYSDATE,'DD')='01' THEN
                    
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
                            J.CAM_LEDGER_BAL,
                            SYSDATE,
                            1,
                            SYSDATE,
                            1,
                            SYSDATE                       
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
                    
                            SELECT mm.cap_prod_code
                              INTO v_prod_code
                              FROM (SELECT   cap_prod_code
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
                        and cdp_prod_code = v_prod_code;                        -- Added for LYFEHOST-63
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_err_msg:='Interest rate is not defined for saving account for product code '||v_prod_code||' and instcode '||i.cim_inst_code; --Change in error message for LYFEHOST-63
                            RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                            v_err_msg:='Error while selecting interest rate for saving account '||SUBSTR(SQLERRM,1,200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                    --Calculating interest
                    v_factor:=ROUND((v_interest_rate/365/100),10);
                    v_compound_balance:=TRUNC((j.cam_acct_bal+j.cam_interest_amount),9);
                    v_daily_accrual:=TRUNC((v_factor*v_compound_balance),9);

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
                                    cid_ins_date)
                        VALUES
                                    (i.cim_inst_code,
                                     j.cam_acct_no,
                                     v_interest_rate,
                                     v_daily_accrual,
                                     SYSDATE,
                                     j.cam_acct_bal+v_daily_accrual,
                                     v_compound_balance, --Added for Mantis id :13995
                                     j.cam_interest_amount+v_daily_accrual, --Added for Mantis id :13995
                                     1,
                                     sysdate);

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
                        cam_lupd_date=SYSDATE,cam_lupd_user=1
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
                                        SYSDATE,
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
                                        SYSDATE,
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
                                SYSDATE,
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
                                SYSDATE,
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
SHOW ERROR