set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_GET_SAVINGS_ACCT_PARAM (P_INST_CODE         IN NUMBER ,
                                                                  P_DELIVERY_CHANNEL  IN  VARCHAR2,
                                                                  P_TXN_CODE          IN VARCHAR2,
                                                                  P_RRN               IN  VARCHAR2,
                                                                  P_TXN_MODE          IN   VARCHAR2,
                                                                  P_TRAN_DATE         IN  VARCHAR2,
                                                                  P_TRAN_TIME         IN   VARCHAR2,
                                                                  P_CURR_CODE         IN   VARCHAR2,
                                                                  P_RVSL_CODE         IN VARCHAR2,
                                                                  P_MSGTYPE           IN VARCHAR2,
                                                                  P_IPADDRESS         IN VARCHAR2,
                                                                  p_saving_acct       IN VARCHAR2, -- Added for LYFEHOST-63
                                                                  P_RESP_CODE         OUT VARCHAR2,
                                                                  P_RESP_MSG          OUT VARCHAR2,
                                                                  P_SPEN_MINTRAN_AMT  OUT VARCHAR2,
                                                                  P_SPEN_MAXTRAN_AMT  OUT VARCHAR2,
                                                                  P_SAVE_MINTRAN_AMT  OUT VARCHAR2,
                                                                  P_SPEN_MAXTRAN_CNT  OUT VARCHAR2,
                                                                  p_savingsacct_minbal OUT varchar2,
                                                                  p_interest_rate      OUT varchar2,
                                                                  p_minreloadamnt      OUT varchar2

                                                                  )
AS
/*************************************************
     * Created Date     : 11-Feb-2013
     * Created By       : Saravanakumar
     * PURPOSE          : For returning saving account param
     * Modified Date    : 14-Feb-2013
     * Modified By      : Saravanakumar
     * Modified Reason  : Modified the errer message as Success instead of OK
     * Reviewer         : Sachin
     * Reviewed Date    : 14-Feb-2013
     * Build Number     : CMS3.5.1_RI0023.1.1_B0005


     * Modified By      : Sagar More
     * Modified Date    : 26-Sep-2013
     * Modified For     : LYFEHOST-63
     * Modified Reason  : To fetch saving acct parameter based on product code
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : Sagar More
     * Modified Date    : 16-OCT-2013
     * Modified For     : review observation changes for LYFEHOST-63
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-OCT-2013
     * Build Number     : RI0024.6_B0001

     * Modified Date    : 16-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog if applicable
                          Acct_type,product code,cardtype,cardstatus,account_number
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-Dec-2013
     * Release Number   : RI0024.7_B0002


     * Modified Date    : 08-July-2014
     * Modified By      : Siva Kumar M
     * Modified for     : Defect ID 13091
     * Modified reason  : SAVINGS ACCOUNT TRANSFER LIMITS transaction db check failed
     * Reviewer         : Spankaj
     * Release Number   : RI0027.3_B0003



     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007

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
*************************************************/
V_TRAN_DATE        DATE;
V_RRN_COUNT        NUMBER;
V_DR_CR_FLAG  CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_OUTPUT_TYPE CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE   CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_TXN_TYPE    CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;

EXP_REJECT_RECORD EXCEPTION;

v_prod_code   cms_appl_pan.cap_prod_code%TYPE; -- Added for LYFEHOST-63
v_acct_id cms_acct_mast.cam_acct_id%TYPE;      -- Added for LYFEHOST-63
v_cust_code   cms_cust_acct.cca_cust_code%TYPE; -- Added for LYFEHOST-63
v_dfg_cnt       NUMBER(10); -- v_dfg_cnt added for LYFEHOST-63
V_ACCT_STATUS   CMS_ACCT_MAST.CAM_STAT_CODE%TYPE; -- Added for LYFEHOST-63

v_date_chk      date;          -- Added as per review observation for LYFEHOST-63
v_timestamp     TIMESTAMP(3);  -- Added as per review observation for LYFEHOST-63

v_cam_acct_bal   cms_acct_mast.cam_acct_bal%TYPE;   -- Added during review observation for LYFEHOST-63
v_cam_ledger_bal cms_acct_mast.cam_ledger_bal%TYPE; -- Added during review observation for LYFEHOST-63

   --Sn Added for 13160
   v_card_type  cms_appl_pan.cap_card_type%TYPE;
   v_card_stat  cms_appl_pan.cap_card_stat%TYPE;
   v_acct_type  cms_acct_mast.cam_type_code%TYPE;
   --En Added for 13160
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN

    P_RESP_CODE:='1';
    P_RESP_MSG:='Success';

    BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG,
        CTM_OUTPUT_TYPE,
        TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
        CTM_TRAN_TYPE,
        CTM_TRAN_DESC
        INTO V_DR_CR_FLAG,
        V_OUTPUT_TYPE,
        V_TXN_TYPE,
        V_TRAN_TYPE,
        V_TRANS_DESC
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
        CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
        CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESP_CODE := '21';
            P_RESP_MSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
            ' and delivery channel ' || P_DELIVERY_CHANNEL;
            RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG   := 'Error while selecting transaction details';
            RAISE EXP_REJECT_RECORD;
    END;

      --SN: Added as per review observation for LYFEHOST-63

      BEGIN

       SELECT to_Date(substr(P_TRAN_DATE,1,8),'yyyymmdd')
       INTO v_date_chk
       FROM dual;

      EXCEPTION WHEN others
      THEN
        P_RESP_CODE := '21';
        P_RESP_MSG := 'Invalid transaction date '||P_TRAN_DATE; -- updated
        RAISE EXP_REJECT_RECORD;
      END;

     --EN: Added as per review observation for LYFEHOST-63



    --Sn Duplicate RRN Check
    BEGIN
    
    --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
        SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM TRANSACTIONLOG
        WHERE RRN         = P_RRN
        AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
        AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
      else--Added for VMS-5733/FSP-991
        SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
        WHERE RRN         = P_RRN
        AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
        AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
       end if; 

        IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            P_RESP_MSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
            RAISE;
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG  := 'Error while checking duplicate rrn ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
    --En Duplicate RRN Check

    --Sn Get Tran date
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
        SUBSTR(TRIM(P_TRAN_TIME), 1, 8), 'yyyymmdd hh24:mi:ss');
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG  := 'Problem while converting transaction date ' ||  SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
    --En Get Tran date

   /*                           -- Commented during LYFEHOST-63 changes
    --Sn Get the DFG paramers
    BEGIN
        SELECT  cdp_param_value
        INTO P_SPEN_MINTRAN_AMT
        FROM cms_dfg_param
        WHERE cdp_param_key = 'MinSpendingParam'
        AND  cdp_inst_code = p_inst_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_SPEN_MINTRAN_AMT:=' ';
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG := 'Error while selecting max Initial Tran amt ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT  cdp_param_value
        INTO P_SAVE_MINTRAN_AMT
        FROM cms_dfg_param
        WHERE cdp_param_key = 'MinSavingParam'
        AND  cdp_inst_code = p_inst_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_SAVE_MINTRAN_AMT:=' ';
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG := 'Error while selecting max Initial Tran amt ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT  cdp_param_value
        INTO P_SPEN_MAXTRAN_AMT
        FROM cms_dfg_param
        WHERE cdp_param_key = 'MaxSpendingParam'
        AND  cdp_inst_code = p_inst_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_SPEN_MAXTRAN_AMT:=' ';
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG := 'Error while selecting max Initial Tran amt ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT  cdp_param_value
        INTO P_SPEN_MAXTRAN_CNT
        FROM cms_dfg_param
        WHERE cdp_param_key = 'MaxNoTrans'
        AND  cdp_inst_code = p_inst_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_SPEN_MAXTRAN_CNT:=' ';
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG := 'Error while selecting max Initial Tran amt ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

   --En Get the DFG paramers
   */

   --SN Added during LYFEHOST-63 changes


      IF trim(p_saving_acct) IS NULL
      THEN

        P_RESP_CODE := '49';
        P_RESP_MSG   := 'Invalid saving acct value';
        RAISE EXP_REJECT_RECORD;

      END IF;



    ---------------------------------
    --SN: Query added for LYFEHOST-63
    ---------------------------------

      BEGIN

            SELECT cam_acct_id,cam_stat_code,cam_acct_bal,cam_ledger_bal,
                   cam_type_code,nvl(CAM_MINRELOAD_AMOUNT,0)                                          --Added for 13160
            INTO   v_acct_id,v_acct_status,v_cam_acct_bal,v_cam_ledger_bal,
                   v_acct_type,p_minreloadamnt                                              --Added for 13160
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code
            AND    cam_acct_no = p_saving_acct
            AND    cam_type_code = '2';

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '49';
         P_RESP_MSG   := 'Invalid saving account number '||p_saving_acct;
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
         P_RESP_CODE := '21';
         P_RESP_MSG   := 'While fetching Saving acct id '||substr(SQLERRM,1,100);
         RAISE EXP_REJECT_RECORD;

      END;

      IF v_acct_status = '2'
      THEN

         P_RESP_CODE := '21';
         P_RESP_MSG   := 'Input Saving Account Is Already Closed '||p_saving_acct;
         RAISE EXP_REJECT_RECORD;

      END IF;

      BEGIN


         SELECT cca_cust_code
         INTO   v_cust_code
         FROM   cms_cust_acct
         WHERE cca_acct_id = v_acct_id
         AND cca_inst_code = p_inst_code;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '49';
         P_RESP_MSG   := 'customer code not found for saving acct '||p_saving_acct;
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
         P_RESP_CODE := '21';
         P_RESP_MSG   := 'While fetching custcode for saving acct '||substr(SQLERRM,1,100);
         RAISE EXP_REJECT_RECORD;

      END;


      BEGIN

            SELECT mm.cap_prod_code,
                   mm.cap_card_type,           -- Added for 13160
                   mm.cap_card_stat            -- Added for 13160
              INTO v_prod_code,
                   v_card_type,             -- Added for 13160
                   v_card_stat              -- Added for 13160
              FROM (SELECT   cap_prod_code,cap_card_type,cap_card_stat
                        FROM cms_appl_pan
                       WHERE cap_cust_code = v_cust_code
                         AND cap_card_stat NOT IN ('9')
                         AND cap_addon_stat = 'P'
                         AND cap_inst_code = p_inst_code
                    ORDER BY cap_pangen_date DESC)mm
             WHERE ROWNUM = 1;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '49';
         P_RESP_MSG   := 'Prod code not found for cust code '||v_cust_code;
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         P_RESP_MSG   := 'Error while selecting prod code ' ||SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;

    ---------------------------------
    --EN: Query added for LYFEHOST-63
    ---------------------------------

       v_dfg_cnt:=0;  --Added on 04-Oct-2013 for LYFEHOST-63
       FOR i IN (SELECT cdp_param_value, cdp_param_key
                   FROM cms_dfg_param
                  WHERE cdp_param_key IN
                           ('MaxNoTrans', 'MaxSpendingParam',
                            'MinSavingParam', 'MinSpendingParam','Saving account Interest rate','InitialTransferAmount')
                    AND cdp_inst_code = p_inst_code
                    AND cdp_prod_code = v_prod_code                 --Added for LYFEHOST-63
                    and  cdp_card_type= v_card_type
                    )
       LOOP
          IF i.cdp_param_key = 'MaxNoTrans'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             P_SPEN_MAXTRAN_CNT := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'MaxSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             P_SPEN_MAXTRAN_AMT := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'MinSavingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             P_SAVE_MINTRAN_AMT := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'MinSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             P_SPEN_MINTRAN_AMT := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'Saving account Interest rate'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             p_interest_rate := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'InitialTransferAmount'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             p_savingsacct_minbal:= i.cdp_param_value;
          END IF;
       END LOOP;

       --Sn Added on 04-Oct-2013 for LYFEHOST-63
       IF v_dfg_cnt=0 THEN
        p_resp_code := '21';
        p_resp_msg:='Saving account parameters is not defined for product '||v_prod_code;
        RAISE exp_reject_record;
       END IF;
       --En Added on 04-Oct-2013 for LYFEHOST-63


      IF P_SPEN_MAXTRAN_CNT IS NULL                                -- Added during LYFEHOST-63 same was not done
       THEN

           P_SPEN_MAXTRAN_CNT:=' ';

      END IF;

      IF P_SPEN_MAXTRAN_AMT IS NULL
      THEN

           P_SPEN_MAXTRAN_AMT:=' ';

      END IF;

      IF P_SAVE_MINTRAN_AMT IS NULL
      THEN

         P_SAVE_MINTRAN_AMT:=' ';

      END IF;

      IF P_SPEN_MINTRAN_AMT IS NULL
      THEN

       P_SPEN_MINTRAN_AMT:=' ';

      END IF;

   --EN Added during LYFEHOST-63 changes


    --ST Get responce code fomr master
    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESP_MSG := 'Responce code not found '||P_RESP_CODE;
            RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG  := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
    --En Get responce code fomr master

    v_timestamp := systimestamp;   -- Added as per review observation for LYFEHOST-63

    --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(RRN,
                                    MSGTYPE,
                                    IPADDRESS,
                                    DELIVERY_CHANNEL,
                                    DATE_TIME,
                                    TXN_CODE,
                                    TXN_TYPE,
                                    TXN_MODE,
                                    TXN_STATUS,
                                    RESPONSE_CODE,
                                    BUSINESS_DATE,
                                    BUSINESS_TIME,
                                    INSTCODE,
                                    ERROR_MSG,
                                    ADD_INS_DATE,
                                    ADD_INS_USER,
                                    TRANS_DESC,
                                    response_id,
                                    time_stamp,      -- Added as per review observation for LYFEHOST-63
                                    cr_dr_flag,      -- Added during review observation for LYFEHOST-63
                                    ACCT_BALANCE,    -- Added during review observation for LYFEHOST-63
                                    LEDGER_BALANCE,   -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    acct_type,
                                    productid,
                                    categoryid,
                                    cardstatus,
                                    customer_acct_no
                                    --EN Added for 13160
                                    )
    VALUES                          ( P_RRN,
                                    P_MSGTYPE,
                                    P_IPADDRESS,
                                    P_DELIVERY_CHANNEL,
                                    SYSDATE,
                                    P_TXN_CODE,
                                    V_TXN_TYPE,
                                    P_TXN_MODE,
                                    'C',        -- 'Y',  Modified for defect id:13091 on july/08/2014
                                    P_RESP_CODE,
                                    P_TRAN_DATE,
                                    P_TRAN_TIME,
                                    P_INST_CODE,
                                    'Successful',
                                    SYSDATE,
                                    1,
                                    V_TRANS_DESC ,
                                    P_RESP_CODE,
                                    v_timestamp,    -- Added as per review observation for LYFEHOST-63
                                    v_dr_cr_flag,    -- Added during review observation for LYFEHOST-63
                                    round(v_cam_acct_bal,2),  -- Added during review observation for LYFEHOST-63
                                    round(v_cam_ledger_bal,2), -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    v_acct_type,
                                    v_prod_code,
                                    v_card_type,
                                    v_card_stat,
                                    p_saving_acct
                                    --EN Added for 13160
                                   );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE := '89';
            P_RESP_MSG := 'Exception while inserting to transaction log '||substr(SQLERRM,200);
    END;
  --En Inserting data in transactionlog

    --Sn Inserting data in transactionlog dtl
    BEGIN

        INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_MSG_TYPE,
                                            CTD_DELIVERY_CHANNEL,
                                            CTD_TXN_CODE,
                                            CTD_TXN_TYPE,
                                            CTD_TXN_MODE,
                                            CTD_BUSINESS_DATE,
                                            CTD_BUSINESS_TIME,
                                            CTD_PROCESS_FLAG,
                                            CTD_PROCESS_MSG,
                                            CTD_RRN,
                                            CTD_INST_CODE,
                                            CTD_INS_DATE,
                                            CTD_INS_USER)
    VALUES                                  (P_MSGTYPE,
                                            P_DELIVERY_CHANNEL,
                                            P_TXN_CODE,
                                            V_TXN_TYPE,
                                            P_TXN_MODE,
                                            P_TRAN_DATE,
                                            P_TRAN_TIME,
                                            'Y',
                                            'Successful',
                                            P_RRN,
                                            P_INST_CODE,
                                            SYSDATE,
                                            1  );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 200) ;
            P_RESP_CODE := '89';
    END;

EXCEPTION

WHEN EXP_REJECT_RECORD THEN

    --ST Get responce code fomr master
    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESP_MSG := 'Responce code not found '||P_RESP_CODE;
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG  := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM, 1, 200);
    END;
    --En Get responce code fomr master

     IF v_timestamp IS NULL
     THEN
         v_timestamp := systimestamp;              -- Added as per review observation for LYFEHOST-63

     END IF;


     IF v_dr_cr_flag IS NULL                        -- Added during review observation for LYFEHOST-63
     THEN

        BEGIN
            SELECT CTM_CREDIT_DEBIT_FLAG,
            CTM_TRAN_DESC
            INTO V_DR_CR_FLAG,
            V_TRANS_DESC
            FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE AND
            CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN OTHERS THEN
            NULL;
        END;

     END IF;

     --SN Added for 13160

   IF v_acct_id IS NULL OR v_prod_code IS NULL
   THEN

      BEGIN

            SELECT cam_acct_id,cam_stat_code,cam_acct_bal,cam_ledger_bal,
                   cam_type_code                                            --Added for 13160
            INTO   v_acct_id,v_acct_status,v_cam_acct_bal,v_cam_ledger_bal,
                   v_acct_type                                              --Added for 13160
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code
            AND    cam_acct_no = p_saving_acct
            AND    cam_type_code = '2';

      EXCEPTION
        WHEN OTHERS THEN
            NULL;

      END;


      BEGIN


         SELECT cca_cust_code
         INTO   v_cust_code
         FROM   cms_cust_acct
         WHERE cca_acct_id = v_acct_id
         AND cca_inst_code = p_inst_code;

      EXCEPTION
        WHEN  OTHERS THEN
            NULL;
      END;

      BEGIN

            SELECT mm.cap_prod_code,
                   mm.cap_card_type,           -- Added for 13160
                   mm.cap_card_stat            -- Added for 13160
              INTO v_prod_code,
                   v_card_type,             -- Added for 13160
                   v_card_stat              -- Added for 13160
              FROM (SELECT   cap_prod_code,cap_card_type,cap_card_stat
                        FROM cms_appl_pan
                       WHERE cap_cust_code = v_cust_code
                         AND cap_card_stat NOT IN ('9')
                         AND cap_addon_stat = 'P'
                         AND cap_inst_code = p_inst_code
                    ORDER BY cap_pangen_date DESC)mm
             WHERE ROWNUM = 1;

      EXCEPTION
        WHEN OTHERS THEN
        NULL;
      END;
   END IF;

   --EN Added for 13160

    --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(RRN,
                                    MSGTYPE,
                                    IPADDRESS,
                                    DELIVERY_CHANNEL,
                                    DATE_TIME,
                                    TXN_CODE,
                                    TXN_TYPE,
                                    TXN_MODE,
                                    TXN_STATUS,
                                    RESPONSE_CODE,
                                    BUSINESS_DATE,
                                    BUSINESS_TIME,
                                    INSTCODE,
                                    ERROR_MSG,
                                    ADD_INS_DATE,
                                    ADD_INS_USER,
                                    TRANS_DESC,
                                    response_id,
                                    time_stamp,       -- Added as per review observation for LYFEHOST-63
                                    cr_dr_flag,       -- Added during review observation for LYFEHOST-63
                                    customer_acct_no,  -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    acct_type,
                                    productid,
                                    categoryid,
                                    cardstatus,
                                    acct_balance,
                                    ledger_balance
                                    --EN Added for 13160
                                   )
    VALUES                          ( P_RRN,
                                    P_MSGTYPE,
                                    P_IPADDRESS,
                                    P_DELIVERY_CHANNEL,
                                    SYSDATE,
                                    P_TXN_CODE,
                                    V_TXN_TYPE,
                                    P_TXN_MODE,
                                    'F',
                                    P_RESP_CODE,
                                    P_TRAN_DATE,
                                    P_TRAN_TIME,
                                    P_INST_CODE,
                                    P_RESP_MSG,
                                    SYSDATE,
                                    1,
                                    V_TRANS_DESC ,
                                    P_RESP_CODE,
                                    v_timestamp,    -- Added as per review observation for LYFEHOST-63
                                    V_DR_CR_FLAG,   -- Added during review observation for LYFEHOST-63
                                    p_saving_acct,   -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    v_acct_type,
                                    v_prod_code,
                                    v_card_type,
                                    v_card_stat,
                                    v_cam_acct_bal,
                                    v_cam_ledger_bal
                                    --EN Added for 13160
                                   );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE := '89';
            P_RESP_MSG := 'Exception while inserting to transaction log '||substr(SQLERRM,200);
    END;
  --En Inserting data in transactionlog

    --Sn Inserting data in transactionlog dtl
    BEGIN

        INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_MSG_TYPE,
                                            CTD_DELIVERY_CHANNEL,
                                            CTD_TXN_CODE,
                                            CTD_TXN_TYPE,
                                            CTD_TXN_MODE,
                                            CTD_BUSINESS_DATE,
                                            CTD_BUSINESS_TIME,
                                            CTD_PROCESS_FLAG,
                                            CTD_PROCESS_MSG,
                                            CTD_RRN,
                                            CTD_INST_CODE,
                                            CTD_INS_DATE,
                                            CTD_INS_USER)
    VALUES                                  (P_MSGTYPE,
                                            P_DELIVERY_CHANNEL,
                                            P_TXN_CODE,
                                            V_TXN_TYPE,
                                            P_TXN_MODE,
                                            P_TRAN_DATE,
                                            P_TRAN_TIME,
                                            'E',
                                            P_RESP_MSG,
                                            P_RRN,
                                            P_INST_CODE,
                                            SYSDATE,
                                            1  );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 200) ;
            P_RESP_CODE := '89';
    END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption

--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
       P_RESP_MSG := 'Main Exception '||substr(SQLERRM,1,200);
    --ST Get responce code fomr master
    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESP_MSG := 'Responce code not found '||P_RESP_CODE;
        WHEN OTHERS THEN
            P_RESP_CODE := '21';
            P_RESP_MSG  := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM, 1, 200);
    END;
    --En Get responce code fomr master


     IF v_timestamp IS NULL
     THEN
         v_timestamp := systimestamp;              -- Added as per review observation for LYFEHOST-63

     END IF;



     IF v_dr_cr_flag IS NULL                        -- Added during review observation for LYFEHOST-63
     THEN

        BEGIN
            SELECT CTM_CREDIT_DEBIT_FLAG,
            CTM_TRAN_DESC
            INTO V_DR_CR_FLAG,
            V_TRANS_DESC
            FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE AND
            CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '21';
                P_RESP_MSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHANNEL;
                --RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
                P_RESP_CODE := '21';
                P_RESP_MSG   := 'Error while selecting transaction details';
                --RAISE EXP_REJECT_RECORD;
        END;

     END IF;

 --SN Added for 13160



   IF v_acct_id IS NULL OR v_prod_code IS NULL
   THEN

      BEGIN

            SELECT cam_acct_id,cam_stat_code,cam_acct_bal,cam_ledger_bal,
                   cam_type_code                                            --Added for 13160
            INTO   v_acct_id,v_acct_status,v_cam_acct_bal,v_cam_ledger_bal,
                   v_acct_type                                              --Added for 13160
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code
            AND    cam_acct_no = p_saving_acct
            AND    cam_type_code = '2';

      EXCEPTION
        WHEN OTHERS THEN
            NULL;

      END;


      BEGIN


         SELECT cca_cust_code
         INTO   v_cust_code
         FROM   cms_cust_acct
         WHERE cca_acct_id = v_acct_id
         AND cca_inst_code = p_inst_code;

      EXCEPTION
        WHEN  OTHERS THEN
            NULL;
      END;


      BEGIN

            SELECT mm.cap_prod_code,
                   mm.cap_card_type,           -- Added for 13160
                   mm.cap_card_stat            -- Added for 13160
              INTO v_prod_code,
                   v_card_type,             -- Added for 13160
                   v_card_stat              -- Added for 13160
              FROM (SELECT   cap_prod_code,cap_card_type,cap_card_stat
                        FROM cms_appl_pan
                       WHERE cap_cust_code = v_cust_code
                         AND cap_card_stat NOT IN ('9')
                         AND cap_addon_stat = 'P'
                         AND cap_inst_code = p_inst_code
                    ORDER BY cap_pangen_date DESC)mm
             WHERE ROWNUM = 1;

      EXCEPTION
        WHEN OTHERS THEN
        NULL;
      END;
   END IF;

  --EN Added for 13160

    --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(RRN,
                                    MSGTYPE,
                                    IPADDRESS,
                                    DELIVERY_CHANNEL,
                                    DATE_TIME,
                                    TXN_CODE,
                                    TXN_TYPE,
                                    TXN_MODE,
                                    TXN_STATUS,
                                    RESPONSE_CODE,
                                    BUSINESS_DATE,
                                    BUSINESS_TIME,
                                    INSTCODE,
                                    ERROR_MSG,
                                    ADD_INS_DATE,
                                    ADD_INS_USER,
                                    TRANS_DESC,
                                    response_id,
                                    time_stamp,       -- Added as per review observation for LYFEHOST-63
                                    cr_dr_flag,       -- Added during review observation for LYFEHOST-63
                                    customer_acct_no,  -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    acct_type,
                                    productid,
                                    categoryid,
                                    cardstatus,
                                    acct_balance,
                                    ledger_balance
                                    --EN Added for 13160
                                    )
    VALUES                          ( P_RRN,
                                    P_MSGTYPE,
                                    P_IPADDRESS,
                                    P_DELIVERY_CHANNEL,
                                    SYSDATE,
                                    P_TXN_CODE,
                                    V_TXN_TYPE,
                                    P_TXN_MODE,
                                    'F',
                                    P_RESP_CODE,
                                    P_TRAN_DATE,
                                    P_TRAN_TIME,
                                    P_INST_CODE,
                                    P_RESP_MSG,
                                    SYSDATE,
                                    1,
                                    V_TRANS_DESC ,
                                    P_RESP_CODE,
                                    v_timestamp,    -- Added as per review observation for LYFEHOST-63
                                    V_DR_CR_FLAG,   -- Added during review observation for LYFEHOST-63
                                    p_saving_acct,   -- Added during review observation for LYFEHOST-63
                                    --SN Added for 13160
                                    v_acct_type,
                                    v_prod_code,
                                    v_card_type,
                                    v_card_stat,
                                    v_cam_acct_bal,
                                    v_cam_ledger_bal
                                    --EN Added for 13160
                                    );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE := '89';
            P_RESP_MSG := 'Exception while inserting to transaction log '||substr(SQLERRM,200);
    END;
  --En Inserting data in transactionlog

    --Sn Inserting data in transactionlog dtl
    BEGIN

        INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_MSG_TYPE,
                                            CTD_DELIVERY_CHANNEL,
                                            CTD_TXN_CODE,
                                            CTD_TXN_TYPE,
                                            CTD_TXN_MODE,
                                            CTD_BUSINESS_DATE,
                                            CTD_BUSINESS_TIME,
                                            CTD_PROCESS_FLAG,
                                            CTD_PROCESS_MSG,
                                            CTD_RRN,
                                            CTD_INST_CODE,
                                            CTD_INS_DATE,
                                            CTD_INS_USER)
    VALUES                                  (P_MSGTYPE,
                                            P_DELIVERY_CHANNEL,
                                            P_TXN_CODE,
                                            V_TXN_TYPE,
                                            P_TXN_MODE,
                                            P_TRAN_DATE,
                                            P_TRAN_TIME,
                                            'E',
                                            P_RESP_MSG,
                                            P_RRN,
                                            P_INST_CODE,
                                            SYSDATE,
                                            1  );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 200) ;
            P_RESP_CODE := '89';
    END;

END;
/
show error