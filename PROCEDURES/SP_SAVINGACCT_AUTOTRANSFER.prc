CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVINGACCT_AUTOTRANSFER (p_inst_code in number)
AS

  /*************************************************
       * Created Date     :  17-08-2012
       * Created By       :  Ramesh.A
       * Purpose          :  Savings Account first of each month transfer(Spending tp Savings)
       * Reviewer         :  B.Besky Anand
       * Reviewed Date    :  24-AUG-12
       * Build Number     :  CMS3.5.1_RI0015_B0004

        * Created Date     :  05-10-2014
       * Created By       :  Sai Prasad
       * Purpose          :  FWR-70 Currency changes
       * Reviewer         :  Spankaj
       * Build Number     :  RI0027.4_B0003
       
       * Modified Date    :    25-08-2015
       * Modified By      :  Saravana Kumar a
       * Purpose          :  Transfer the funds on weekly,biweekly,monthly based on configuration
       * Reviewer         :  Spankaj
       * Build Number     :  VMS_RSJ002
       
           * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
  *************************************************/
V_TYPE_CODE          CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_STATUS_CODE        CMS_ACCT_STAT.CAS_STAT_CODE%TYPE;
V_RESP_CODE          VARCHAR2(4);
V_MSG_TYPE           TRANSACTIONLOG.MSGTYPE%TYPE DEFAULT '0200';
V_RRN1               NUMBER(10) DEFAULT 0;
V_RRN2               VARCHAR2(15);
V_BUSINESS_DATE      VARCHAR2(10);
V_BUSINESS_TIME      VARCHAR2(10);
V_TXN_MODE           CMS_FUNC_MAST.CFM_TXN_MODE%TYPE DEFAULT '0';
V_CURRCODE           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
V_RVSL_CODE          TRANSACTIONLOG.REVERSAL_CODE%TYPE DEFAULT '00';
V_DELIVERY_CHANNEL   CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE DEFAULT '05';
V_TXN_CODE           VARCHAR2(10);
V_SPENDING_ACCTNO    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
V_SWITCH_ACCT_TYPE   CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_SWITCH_ACCT_STATUS CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '8';
V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_PROD_CODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
V_ERR_MSG              VARCHAR2(500);
v_spenacctbal          VARCHAR2(20);
v_spenacctledgbal      VARCHAR2(20);
v_spend_save_tran_date cms_acct_mast.cam_savtospd_tfer_date%type;
v_acct_bal             cms_acct_mast.cam_acct_bal%type;

EXP_REJECT_RECORD EXCEPTION;
exp_auth_reject_record   EXCEPTION;

BEGIN
    V_ERR_MSG := 'OK';

    BEGIN
        SELECT CAT_TYPE_CODE
        INTO V_TYPE_CODE
        FROM CMS_ACCT_TYPE
        WHERE CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE AND
        CAT_INST_CODE = p_inst_code;
    EXCEPTION
        WHEN OTHERS THEN
            V_ERR_MSG   := 'Error while selecting type code for the institution ' ||
            SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT CAS_STAT_CODE
        INTO V_STATUS_CODE
        FROM CMS_ACCT_STAT
        WHERE CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STATUS AND
        CAS_INST_CODE = p_inst_code;
    EXCEPTION
        WHEN OTHERS THEN
            V_ERR_MSG   := 'Error while selecting status for the institution ' ||
            SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
       
    V_BUSINESS_DATE:=TO_CHAR(SYSDATE, 'YYYYMMDD');
    V_BUSINESS_TIME:=TO_CHAR(SYSDATE, 'HH24MISS');
 
    FOR J IN (SELECT CAM_ACCT_ID,
        CAM_ACCT_NO,
        CAM_FIRSTMONTH_TRANSFER,
        NVL(CAM_FIRSTMONTH_TRANSFERAMT, 0) CAM_FIRSTMONTH_TRANSFERAMT,
        CAM_FIFTEENMONTH_TRANSFER,
        NVL(CAM_FIFTEENMONTH_TRANSFERAMT, 0) CAM_FIFTEENMONTH_TRANSFERAMT,
        CAM_WEEKLYTRANSFER_FLAG,
        NVL(CAM_WEEKLYTRANSFER_AMOUNT,0) CAM_WEEKLYTRANSFER_AMOUNT,
        CAM_BIWEEKLYTRANSFER_FLAG,
        NVL(CAM_BIWEEKLYTRANSFER_AMOUNT,0) CAM_BIWEEKLYTRANSFER_AMOUNT,
        CAM_ANYDAYMONTHTRANSFER_FLAG,
        CAM_DAYOFTRANSFER_MONTH,
        NVL(CAM_MONTLYTRANSFER_AMOUNT,0) CAM_MONTLYTRANSFER_AMOUNT
        FROM CMS_ACCT_MAST
        WHERE CAM_TYPE_CODE = V_TYPE_CODE AND
        CAM_STAT_CODE = V_STATUS_CODE AND
        CAM_INST_CODE = p_inst_code AND (CAM_FIRSTMONTH_TRANSFER = 1 OR CAM_FIFTEENMONTH_TRANSFER = 1
        OR CAM_WEEKLYTRANSFER_FLAG=1 OR CAM_BIWEEKLYTRANSFER_FLAG=1 OR CAM_ANYDAYMONTHTRANSFER_FLAG=1) ) 
    LOOP

        BEGIN
            
            BEGIN
                SELECT CAP_PROD_CODE,CAP_CARD_TYPE,
                CAP_PAN_CODE,
                cap_pan_code_encr,
                CAP_ACCT_NO
                INTO V_PROD_CODE,V_CARD_TYPE,
                V_hash_pan,
                V_ENCR_PAN,
                V_SPENDING_ACCTNO
                FROM( select CAP_PROD_CODE,CAP_CARD_TYPE,
                        CAP_PAN_CODE,
                        cap_pan_code_encr,
                        CAP_ACCT_NO
                        from  CMS_APPL_PAN
                        WHERE CAP_CUST_CODE =(SELECT CCA_CUST_CODE
                                            FROM CMS_CUST_ACCT
                                            WHERE CCA_ACCT_ID = J.CAM_ACCT_ID AND
                                            CCA_INST_CODE = p_inst_code)
                        AND CAP_INST_CODE      = P_INST_CODE
                        AND CAP_ACTIVE_DATE   IS NOT NULL
                        AND cap_card_stat <>'9'
                        ORDER BY CAP_ACTIVE_DATE DESC)
                where rownum=1;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    BEGIN
                        SELECT CAP_PROD_CODE,CAP_CARD_TYPE,
                        CAP_PAN_CODE,
                        cap_pan_code_encr,
                        CAP_ACCT_NO
                        INTO  V_PROD_CODE,V_CARD_TYPE,
                        V_hash_pan,
                        v_encr_pan,
                        V_SPENDING_ACCTNO
                            FROM (SELECT CAP_PROD_CODE,CAP_CARD_TYPE,
                                    CAP_PAN_CODE,
                                    cap_pan_code_encr ,
                                    CAP_ACCT_NO
                                    from CMS_APPL_PAN
                                    WHERE CAP_CUST_CODE =(SELECT CCA_CUST_CODE
                                                            FROM CMS_CUST_ACCT
                                                            WHERE CCA_ACCT_ID = J.CAM_ACCT_ID AND
                                                            CCA_INST_CODE = p_inst_code)
                                    AND CAP_INST_CODE      = P_INST_CODE
                                    ORDER BY CAP_PANGEN_DATE DESC)
                       where rownum=1;
                    exception
                        WHEN OTHERS THEN
                            V_ERR_MSG   := 'Error while selecting spending Card details' ||
                            SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                    end;
                WHEN OTHERS THEN
                    V_ERR_MSG   := 'Error while selecting spending Card details' ||
                    SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;

            V_RRN1      := V_RRN1 + 1;

            BEGIN
                                 
--                SELECT TRIM (cbp_param_value)  INTO V_CURRCODE FROM cms_bin_param 
--                WHERE CBP_PARAM_NAME = 'Currency' AND CBP_INST_CODE= P_INST_CODE 
--                AND CBP_PROFILE_CODE =  (SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE
--                WHERE cpC_prod_code = V_PROD_CODE AND CPC_CARD_TYPE=V_CARD_TYPE AND cpC_inst_code = p_inst_code);

  vmsfunutilities.get_currency_code(v_prod_code,v_card_type,P_INST_CODE,V_CURRCODE,V_ERR_MSG);
      
      if V_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;
                IF TRIM(V_CURRCODE) IS NULL THEN
                    V_ERR_MSG   := 'Base currency cannot be null ';
                    RAISE EXP_REJECT_RECORD;
                END IF;
                            
            EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                    raise;
                WHEN OTHERS THEN
                    V_ERR_MSG   := 'Error while selecting base currecy  ' ||
                    SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
         
            BEGIN
                    SELECT CAM_SAVTOSPD_TFER_DATE ,cam_acct_bal
                    into v_spend_save_tran_date,v_acct_bal
                    FROM cms_acct_mast
                    WHERE cam_acct_no=V_SPENDING_ACCTNO
                    AND cam_inst_code=P_inst_code;
                EXCEPTION
                    WHEN others THEN
                        V_ERR_MSG   := 'Error while selecting the date  ' ||SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
            END;
            
            IF v_acct_bal = 0 THEN
                V_ERR_MSG   := 'Spending account balance is zero ';
                RAISE EXP_REJECT_RECORD;
            END IF;
                
            IF J.CAM_FIRSTMONTH_TRANSFER = 1 AND to_char(SYSDATE,'dd')='01' THEN
            
                V_TXN_CODE := '21';
                V_RRN2      := 'ATFTM'||to_char(sysdate,'ss') || V_RRN1;
                
                begin
                    sp_spendingtosavingstransfer(p_inst_code,
                                                fn_dmaps_main (v_encr_pan),
                                                V_MSG_TYPE,
                                                V_SPENDING_ACCTNO,
                                                J.CAM_ACCT_NO,
                                                V_DELIVERY_CHANNEL,
                                                V_TXN_CODE,
                                                V_RRN2,
                                                J.CAM_FIRSTMONTH_TRANSFERAMT,
                                                V_TXN_MODE,
                                                p_inst_code,
                                                V_CURRCODE,
                                                V_RVSL_CODE,
                                                V_BUSINESS_DATE,
                                                V_BUSINESS_TIME,
                                                NULL,
                                                NULL,
                                                NULL,
                                                V_RESP_CODE,
                                                V_ERR_MSG,
                                                v_spenacctbal,
                                                v_spenacctledgbal);
                          
                    IF V_RESP_CODE <> '00'
                    THEN
                        RAISE exp_auth_reject_record;
                    END IF;
               
                EXCEPTION
                    WHEN exp_auth_reject_record  THEN
                        RAISE;
                    WHEN OTHERS  THEN
                        V_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                END;
            END IF;
           
            IF  J.CAM_FIFTEENMONTH_TRANSFER=1 AND to_char(SYSDATE,'dd')='15' THEN
            
                V_TXN_CODE := '22';
                V_RRN2      := 'ATFNM'||to_char(sysdate,'ss') || V_RRN1;
                
                begin
                    sp_spendingtosavingstransfer(p_inst_code,
                                                fn_dmaps_main (v_encr_pan),
                                                V_MSG_TYPE,
                                                V_SPENDING_ACCTNO,
                                                J.CAM_ACCT_NO,
                                                V_DELIVERY_CHANNEL,
                                                V_TXN_CODE,
                                                V_RRN2,
                                                J.CAM_FIFTEENMONTH_TRANSFERAMT,
                                                V_TXN_MODE,
                                                p_inst_code,
                                                V_CURRCODE,
                                                V_RVSL_CODE,
                                                V_BUSINESS_DATE,
                                                V_BUSINESS_TIME,
                                                NULL,
                                                NULL,
                                                NULL,
                                                V_RESP_CODE,
                                                V_ERR_MSG,
                                                v_spenacctbal,
                                                v_spenacctledgbal);
                          
                    IF V_RESP_CODE <> '00'
                    THEN
                        RAISE exp_auth_reject_record;
                    END IF;
               
                EXCEPTION
                    WHEN exp_auth_reject_record  THEN
                        RAISE;
                    WHEN OTHERS  THEN
                        V_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                END;
                        
            END IF;
          
            IF  J.CAM_WEEKLYTRANSFER_FLAG=1 AND trim(to_char(SYSDATE,'DAY'))='SUNDAY' THEN
            
                 V_TXN_CODE := '43';
                 V_RRN2      := 'ATW'||to_char(sysdate,'ss') || V_RRN1;
                 
                begin
                    sp_spendingtosavingstransfer(p_inst_code,
                                                fn_dmaps_main (v_encr_pan),
                                                V_MSG_TYPE,
                                                V_SPENDING_ACCTNO,
                                                J.CAM_ACCT_NO,
                                                V_DELIVERY_CHANNEL,
                                                V_TXN_CODE,
                                                V_RRN2,
                                                J.CAM_WEEKLYTRANSFER_AMOUNT,
                                                V_TXN_MODE,
                                                p_inst_code,
                                                V_CURRCODE,
                                                V_RVSL_CODE,
                                                V_BUSINESS_DATE,
                                                V_BUSINESS_TIME,
                                                NULL,
                                                NULL,
                                                NULL,
                                                V_RESP_CODE,
                                                V_ERR_MSG,
                                                v_spenacctbal,
                                                v_spenacctledgbal);
                          
                    IF V_RESP_CODE <> '00'
                    THEN
                        RAISE exp_auth_reject_record;
                    END IF;
               
                EXCEPTION
                    WHEN exp_auth_reject_record  THEN
                        RAISE;
                    WHEN OTHERS  THEN
                        V_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                END;
            END IF;
                        
            IF J.CAM_BIWEEKLYTRANSFER_FLAG=1 AND trim(to_char(SYSDATE,'DAY'))='SUNDAY' THEN
                                                        
                IF v_spend_save_tran_date IS NULL OR 
                (v_spend_save_tran_date IS NOT NULL AND SYSDATE-v_spend_save_tran_date > 10)
                THEN 
                
                    V_TXN_CODE := '44';
                    V_RRN2      := 'ATBW'||to_char(sysdate,'ss') || V_RRN1;
                    
                    begin
                        sp_spendingtosavingstransfer(p_inst_code,
                                                    fn_dmaps_main (v_encr_pan),
                                                    V_MSG_TYPE,
                                                    V_SPENDING_ACCTNO,
                                                    J.CAM_ACCT_NO,
                                                    V_DELIVERY_CHANNEL,
                                                    V_TXN_CODE,
                                                    V_RRN2,
                                                    J.CAM_BIWEEKLYTRANSFER_AMOUNT,
                                                    V_TXN_MODE,
                                                    p_inst_code,
                                                    V_CURRCODE,
                                                    V_RVSL_CODE,
                                                    V_BUSINESS_DATE,
                                                    V_BUSINESS_TIME,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    V_RESP_CODE,
                                                    V_ERR_MSG,
                                                    v_spenacctbal,
                                                    v_spenacctledgbal);
                              
                        IF V_RESP_CODE <> '00'
                        THEN
                            RAISE exp_auth_reject_record;
                        END IF;
                        
                        BEGIN
                            UPDATE cms_acct_mast SET CAM_SAVTOSPD_TFER_DATE=SYSDATE
                            WHERE CAM_ACCT_NO = V_SPENDING_ACCTNO AND
                            CAM_INST_CODE = p_inst_code;
                        EXCEPTION
                            WHEN others THEN
                                V_ERR_MSG :='Error while updating cms_acct_mast' || SUBSTR (SQLERRM, 1, 200);
                                RAISE exp_reject_record;
                        END;

               
                    EXCEPTION
                        WHEN exp_auth_reject_record  THEN
                            RAISE;
                        WHEN OTHERS  THEN
                            V_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_record;
                    END;
                    
                END IF;
            END IF;
            
            IF J.CAM_ANYDAYMONTHTRANSFER_FLAG=1 AND 
                (to_char(SYSDATE,'dd')=J.CAM_DAYOFTRANSFER_MONTH OR
                ( to_char(SYSDATE,'dd')=to_char(last_day(SYSDATE),'dd') 
                and to_char(last_day(SYSDATE),'dd')<j.CAM_DAYOFTRANSFER_MONTH)) THEN
                
                V_TXN_CODE := '45';
                V_RRN2      := 'ATM'||to_char(sysdate,'ss') || V_RRN1;
                
                begin
                    sp_spendingtosavingstransfer(p_inst_code,
                                                fn_dmaps_main (v_encr_pan),
                                                V_MSG_TYPE,
                                                V_SPENDING_ACCTNO,
                                                J.CAM_ACCT_NO,
                                                V_DELIVERY_CHANNEL,
                                                V_TXN_CODE,
                                                V_RRN2,
                                                J.CAM_MONTLYTRANSFER_AMOUNT,
                                                V_TXN_MODE,
                                                p_inst_code,
                                                V_CURRCODE,
                                                V_RVSL_CODE,
                                                V_BUSINESS_DATE,
                                                V_BUSINESS_TIME,
                                                NULL,
                                                NULL,
                                                NULL,
                                                V_RESP_CODE,
                                                V_ERR_MSG,
                                                v_spenacctbal,
                                                v_spenacctledgbal);
                          
                    IF V_RESP_CODE <> '00'
                    THEN
                        RAISE exp_auth_reject_record;
                    END IF;
               
                EXCEPTION
                    WHEN exp_auth_reject_record  THEN
                        RAISE;
                    WHEN OTHERS  THEN
                        V_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                END;
            END IF;
        
        EXCEPTION
            WHEN exp_auth_reject_record THEN
                V_ERR_MSG :='Error from spending to savings transfer';
            WHEN exp_reject_record  THEN
                rollback;
                BEGIN
                    INSERT INTO CMS_TRANSACTION_LOG_DTL
                                (CTD_DELIVERY_CHANNEL,
                                CTD_TXN_CODE,
                                CTD_TXN_TYPE,
                                CTD_TXN_MODE,
                                CTD_BUSINESS_DATE,
                                CTD_BUSINESS_TIME,
                                CTD_CUSTOMER_CARD_NO,
                                CTD_PROCESS_FLAG,
                                CTD_PROCESS_MSG,
                                CTD_RRN,
                                CTD_INST_CODE,
                                CTD_INS_DATE,
                                CTD_INS_USER,
                                CTD_CUSTOMER_CARD_NO_ENCR,
                                CTD_MSG_TYPE,
                                CTD_CUST_ACCT_NUMBER)
                    VALUES
                                (V_DELIVERY_CHANNEL,
                                V_TXN_CODE,
                                1,
                                V_TXN_MODE,
                                V_BUSINESS_DATE,
                                V_BUSINESS_TIME,
                                V_HASH_PAN,
                                'E',
                                V_ERR_MSG,
                                V_RRN2,
                                p_inst_code,
                                SYSDATE,
                                1,
                                V_ENCR_PAN,
                                '000',
                                J.CAM_ACCT_NO);
                EXCEPTION
                    WHEN OTHERS THEN
                        V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl' ||
                        SUBSTR(SQLERRM, 1, 200);
                END;
        end;
                
        commit;
                 
    END LOOP;
exception
when others then
    V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl' ||  SUBSTR(SQLERRM, 1, 200);
    dbms_output.put_line(V_ERR_MSG);

END;

/

show error