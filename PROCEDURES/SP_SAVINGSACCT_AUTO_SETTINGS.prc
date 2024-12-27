set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVINGSACCT_AUTO_SETTINGS(
                          P_INST_CODE         IN NUMBER ,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN VARCHAR2,
                          P_PAN_CODE          IN VARCHAR2,
                          P_RRN               IN  VARCHAR2,
                          P_CURR_CODE         IN   VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_LoadTimeTransfer  IN   VARCHAR2,
                          P_LoadTimeTransfer_Amt  IN   NUMBER,
                          P_FirstMonthTransfer  IN   VARCHAR2,
                          P_FirstMonthTransfer_Amt  IN   NUMBER,
                          P_FifteenMonthTransfer  IN   VARCHAR2,
                          P_FifteenMonthTransfer_Amt  IN   NUMBER,
                          p_weeklytransfer_flag   IN number,
                          p_weeklytransfer_amount IN number,
                          p_biweeklytransfer_flag IN number,
                          p_biweeklytransfer_amt  IN number,
                          p_dayofmonthtrns_flag   IN number,
                          p_dayofmonth            IN number,
                          p_dayofmonthtrns_amt    IN number,
                          P_MSG               IN  VARCHAR2,
                          P_TXN_MODE          IN  VARCHAR2,
                          P_RVSL_CODE         IN  VARCHAR2,
                          P_BANK_CODE         IN  VARCHAR2,
                          P_ANI               IN  VARCHAR2,
                          P_DNI               IN  VARCHAR2,
                          P_IPADDRESS         IN  VARCHAR2,
                          P_RESP_CODE         OUT VARCHAR2,
                          P_RESMSG            OUT VARCHAR2,
                          P_MINRELOAD_AMT     IN   NUMBER
                          )

AS
/*************************************************
    * Created Date     :  08-Aug-2012
    * Created By       :  Ramesh.A
    * PURPOSE          :  Store the Savings Account Automatic Settings
    * modified by      :  Saravanakumar
    * modified Date    : 13-Feb-2013
    * modified reason  : CR - 40
    * Reviewer         : Sachin
    * Reviewed Date    :  13-Feb-2013
    * Build Number     : CMS3.5.1_RI0023.1.1_B0004

    * Modified by      :  Pankaj S.
    * Modified Reason  :  DFCCSD-70
    * Modified Date    :  22-Aug-2013
    * Reviewer         :  Dhiraj
    * Reviewed Date    :  21-Aug-2013
    * Build Number     :  RI0024.4_B0006

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


     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     :VMSGPRHOAT_3.1.1_B0007

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07

   * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
*************************************************/

V_TRAN_DATE             DATE;
V_AUTH_SAVEPOINT        NUMBER DEFAULT 0;
V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_SPND_ACCT_NO          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_SAVING_ACCTNO         cms_appl_pan.cap_acct_no%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_HASH_PASSWORD         VARCHAR2(100);
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  VARCHAR2(20);
V_CAPTURE_DATE          DATE;
V_MCC_CODE              VARCHAR2(20);
V_TXN_AMT               NUMBER;
V_ACCT_NUMBER           NUMBER;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
V_COUNT                 NUMBER;
v_card_curr             VARCHAR2 (5);
V_TERM_ID               VARCHAR2(20);
V_DR_CR_FLAG            VARCHAR2(2);
V_OUTPUT_TYPE           VARCHAR2(2);
V_TRAN_TYPE             VARCHAR2(2);
V_ACCT_TYPE             CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_SWITCH_ACCT_TYPE      CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
v_trans_desc             VARCHAR2 (50);
v_min_svg_lmt           NUMBER;
v_max_svg_lmt           NUMBER;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_max_spend_amt  cms_dfg_param.cdp_param_key%TYPE; --Added for CR - 40 in release 23.1.1
v_min_spend_amt  cms_dfg_param.cdp_param_key%TYPE;--Added for CR - 40 in release 23.1.1
--Sn Added by Pankaj S. for DFCCSD-70 changes
v_avail_bal      cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal     cms_acct_mast.cam_ledger_bal%TYPE;
--En Added by Pankaj S. for DFCCSD-70 changes
--Sn Added by Pankaj S. during DFCCSD-70(Review) changes
v_prod_code     cms_appl_pan.cap_prod_code%TYPE;
v_card_type     cms_appl_pan.cap_card_type%TYPE;
v_resp_cde      transactionlog.response_id%TYPE;
--Sn Added by Pankaj S. during DFCCSD-70(Review) changes
v_dfg_cnt       NUMBER(10); --added for LYFEHOST-63
v_date_chk      date;       -- Added as per review observation for LYFEHOST-63

   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991
--Main Begin Block Starts Here
BEGIN
   V_TXN_TYPE := '1';
   SAVEPOINT V_AUTH_SAVEPOINT;

       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting hash pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE     := '12';
            V_ERRMSG := 'Error while converting encr pan ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;
      --En Create encr pan

      --SN: Added as per review observation for LYFEHOST-63

      BEGIN

       SELECT to_Date(substr(P_TRAN_DATE,1,8),'yyyymmdd')
       INTO v_date_chk
       FROM dual;

      EXCEPTION WHEN others
      THEN
        P_RESP_CODE := '21';
        V_ERRMSG := 'Invalid transaction date '||P_TRAN_DATE; -- updated
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

IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
       ELSE  --Added for VMS-5733/FSP-991
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM  VMSCMS_HISTORY.TRANSACTIONLOG_HIST
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
       END IF;   
          

          IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
        --Sn added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
        EXCEPTION
         WHEN exp_reject_record THEN
          RAISE;
         WHEN OTHERS THEN
          p_resp_code := '21';
          v_errmsg :='Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;
        --En added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
        END;
    --En Duplicate RRN Check

      --Sn Get Tran date
        BEGIN
          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                  'yyyymmdd hh24:mi:ss');
          EXCEPTION
            WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;


        --SN: Moved query up during LYFECYCLE changes

          --Sn Get the card details
           BEGIN
              SELECT cap_card_stat, cap_expry_date,cap_acct_no,CAP_CUST_CODE,
                     cap_prod_code,cap_card_type   --Added by Pankaj S. during DFCCSD-70(Review) changes
                INTO V_CARD_STAT, V_CARD_EXPRY,V_SPND_ACCT_NO,V_CUST_CODE,
                     v_prod_code,v_card_type      --Added by Pankaj S. during DFCCSD-70(Review) changes
                FROM cms_appl_pan
               WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 p_resp_code := '16';
                 v_errmsg := 'Card number not found ';
                 RAISE exp_reject_record;
              WHEN OTHERS
              THEN
                 p_resp_code := '12';
                 v_errmsg :=
                    'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_reject_record;
           END;
          --End Get the card details

          --EN: Moved query up during LYFECYCLE changes

        -----------------------------------------------------------------------------------
        --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
        -----------------------------------------------------------------------------------
        /*--Sn Get the DFG paramers
         BEGIN
                 SELECT  cdp_param_value
                 INTO v_min_svg_lmt
                 FROM cms_dfg_param
                 WHERE cdp_param_key = 'MinSavingParam'
                 AND  cdp_inst_code = p_inst_code;

               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   P_RESP_CODE := '21';
                   V_ERRMSG := 'No data for selecting min Savings amt  '||P_RESP_CODE;
                   RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG := 'Error while selecting min Savings amt ' ||
                      SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
              SELECT  cdp_param_value
              INTO v_max_svg_lmt
              FROM cms_dfg_param
              WHERE cdp_param_key = 'MaxSavingParam'
              AND  cdp_inst_code = p_inst_code;

             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                 P_RESP_CODE := '21';
                 V_ERRMSG := 'No data for selecting max savings acct bal  '||P_RESP_CODE;
                 RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG := 'Error while selecting max savings acc bal ' ||
                    SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

         END;
    --Sn Added for CR - 40 in release 23.1.1
        BEGIN
            SELECT  cdp_param_value
            INTO v_min_spend_amt
            FROM cms_dfg_param
            WHERE cdp_param_key = 'MinSpendingParam'
            AND  cdp_inst_code = p_inst_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '21';
                V_ERRMSG := 'No data for selecting min spending amt  ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG := 'Error while selecting min spending amt ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
            SELECT  cdp_param_value
            INTO v_max_spend_amt
            FROM cms_dfg_param
            WHERE cdp_param_key = 'MaxSpendingParam'
            AND  cdp_inst_code = p_inst_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '21';
                V_ERRMSG := 'No data for selecting max spending amt  ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG := 'Error while selecting max spending amt ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;*/
       v_dfg_cnt:=0;  --added on 04-Oct-2013 for LYFEHOST-63

       FOR i IN (SELECT cdp_param_value, cdp_param_key
                   FROM cms_dfg_param
                  WHERE cdp_param_key IN
                           ('MinSavingParam','MaxSavingParam','MinSpendingParam','MaxSpendingParam')
                    AND cdp_inst_code = p_inst_code
                    AND cdp_prod_code = v_prod_code     -- Added for LYFEHOST-63 changes
                    AND CDP_CARD_TYPE = V_CARD_TYPE)
       LOOP
       BEGIN
          IF i.cdp_param_key = 'MinSavingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_min_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSavingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_max_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MinSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_min_spend_amt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSpendingParam'
          THEN
             v_dfg_cnt:=v_dfg_cnt+1;
             v_max_spend_amt := i.cdp_param_value;
          END IF;
       EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :=
                     'Error while selecting saving account parameters '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
       END LOOP;

      --En Added for CR - 40 in release 23.1.1
      --En Get the DFG paramers

      --Sn Added on 04-Oct-2013 for LYFEHOST-63
       IF v_dfg_cnt=0 THEN
        p_resp_code := '21';
        v_errmsg:='saving account parameters is not defined for product '||v_prod_code;
        RAISE exp_reject_record;
       END IF;
       --En Added on 04-Oct-2013 for LYFEHOST-63

       IF v_min_svg_lmt IS NULL                                -- Added during LYFEHOST-63 same was not done
       THEN

            P_RESP_CODE := '21';
            V_ERRMSG := 'No data for selecting min Savings amt for product code '||v_prod_code ||' and instcode '||p_inst_code||' '||P_RESP_CODE;
            RAISE exp_reject_record;

       ELSIF v_max_svg_lmt IS NULL
       THEN

            P_RESP_CODE := '21';
            V_ERRMSG := 'No data for selecting max savings acct bal for product code '||v_prod_code ||' and instcode '||p_inst_code||' '||P_RESP_CODE;
            RAISE exp_reject_record;

       ELSIF v_min_spend_amt IS NULL
       THEN

            P_RESP_CODE := '21';
            V_ERRMSG := 'No data for selecting min spending amt for product code '||v_prod_code ||' and instcode '||p_inst_code;
            RAISE exp_reject_record;

       ELSIF v_max_spend_amt IS NULL
       THEN

            P_RESP_CODE := '21';
            V_ERRMSG := 'No data for selecting max spending amt for product code '||v_prod_code ||' and instcode '||p_inst_code;
            RAISE exp_reject_record;

       END IF;



      -----------------------------------------------------------------------------------
      --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
      -----------------------------------------------------------------------------------
       --En Get Tran date
    IF P_LoadTimeTransfer = 1 THEN
      IF P_LoadTimeTransfer_Amt IS NULL THEN
        P_RESP_CODE := '49';
        V_ERRMSG  := 'Data Element Name LoadTimeTransferAmount is Invalid. Value is :'||P_LoadTimeTransfer_Amt;
        RAISE EXP_REJECT_RECORD;
      ELSE
         IF P_LoadTimeTransfer_Amt < v_min_svg_lmt  OR P_LoadTimeTransfer_Amt < v_min_spend_amt THEN --Added for CR - 40 in release 23.1.1

           P_RESP_CODE := '103';
           V_ERRMSG := 'Amount should not below the Minimum configured amount';
           RAISE exp_reject_record;

         ELSIF P_LoadTimeTransfer_Amt > v_max_svg_lmt OR P_LoadTimeTransfer_Amt > v_max_spend_amt THEN --Added for CR - 40 in release 23.1.1

          P_RESP_CODE := '104';
          V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
          RAISE exp_reject_record;
         END IF;
      END IF;
    END IF;
    IF P_FirstMonthTransfer = 1 THEN
       IF  P_FirstMonthTransfer_Amt IS NULL THEN
        P_RESP_CODE := '49';
        V_ERRMSG  := 'Data Element Name FirstMonthTransferAmount is Invalid. Value is :'||P_FirstMonthTransfer_Amt;
        RAISE EXP_REJECT_RECORD;
      ELSE
         IF P_FirstMonthTransfer_Amt < v_min_svg_lmt OR P_FirstMonthTransfer_Amt < v_min_spend_amt THEN --Added for CR - 40 in release 23.1.1

           P_RESP_CODE := '103';
           V_ERRMSG := 'Amount should not below the Minimum configured amount';
           RAISE exp_reject_record;

         ELSIF P_FirstMonthTransfer_Amt > v_max_svg_lmt OR  P_FirstMonthTransfer_Amt > v_max_spend_amt THEN --Added for CR - 40 in release 23.1.1

          P_RESP_CODE := '104';
          V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
          RAISE exp_reject_record;
         END IF;
      END IF;
    END IF;
    IF P_FifteenMonthTransfer = 1 THEN
      IF  P_FifteenMonthTransfer_Amt IS NULL THEN
        P_RESP_CODE := '49';
        V_ERRMSG  := 'Data Element Name FifteenMontTransferAmount is Invalid. Value is :'||P_FifteenMonthTransfer_Amt;
        RAISE EXP_REJECT_RECORD;
      ELSE
         IF P_FifteenMonthTransfer_Amt < v_min_svg_lmt OR  P_FifteenMonthTransfer_Amt < v_min_spend_amt THEN --Added for CR - 40 in release 23.1.1

           P_RESP_CODE := '103';
           V_ERRMSG := 'Amount should not below the Minimum configured amount';
           RAISE exp_reject_record;

         ELSIF P_FifteenMonthTransfer_Amt > v_max_svg_lmt OR P_FifteenMonthTransfer_Amt > v_max_spend_amt THEN --Added for CR - 40 in release 23.1.1

          P_RESP_CODE := '104';
          V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
          RAISE exp_reject_record;
         END IF;
      END IF;
    END IF;

       IF  p_weeklytransfer_flag =1  THEN

           IF  p_weeklytransfer_amount IS NULL THEN

            P_RESP_CODE := '49';
            V_ERRMSG  := 'Data Element Name WeeklyTransferAmount is Invalid. Value is :'||p_weeklytransfer_amount;
            RAISE EXP_REJECT_RECORD;
           ELSE

            IF p_weeklytransfer_amount < v_min_svg_lmt OR  p_weeklytransfer_amount < v_min_spend_amt THEN

               P_RESP_CODE := '103';
               V_ERRMSG := 'Amount should not below the Minimum configured amount';
               RAISE exp_reject_record;

            ELSIF p_weeklytransfer_amount > v_max_svg_lmt OR p_weeklytransfer_amount > v_max_spend_amt THEN

              P_RESP_CODE := '104';
              V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
              RAISE exp_reject_record;
             END IF;


           END IF;

       END IF;

       IF p_biweeklytransfer_flag =1  THEN

        IF  p_biweeklytransfer_amt IS NULL THEN


        P_RESP_CODE := '49';
        V_ERRMSG  := 'Data Element Name Bi-WeeklyTransferAmount is Invalid. Value is :'||p_biweeklytransfer_amt;
        RAISE EXP_REJECT_RECORD;

        ELSE

         IF p_biweeklytransfer_amt < v_min_svg_lmt OR  p_biweeklytransfer_amt < v_min_spend_amt THEN

               P_RESP_CODE := '103';
               V_ERRMSG := 'Amount should not below the Minimum configured amount';
               RAISE exp_reject_record;

            ELSIF p_biweeklytransfer_amt > v_max_svg_lmt OR p_biweeklytransfer_amt > v_max_spend_amt THEN

              P_RESP_CODE := '104';
              V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
              RAISE exp_reject_record;
             END IF;


        END IF;

       END IF;

       IF p_dayofmonthtrns_flag = 1 THEN

         IF p_dayofmonth < 1   OR  p_dayofmonth  > 31   THEN


          P_RESP_CODE := '49';
          V_ERRMSG  := 'Data Element Name DayofTransfer is Invalid. Value is :'||p_dayofmonth;
          RAISE EXP_REJECT_RECORD;

         END IF;


        IF  p_dayofmonthtrns_amt IS NULL THEN

        P_RESP_CODE := '49';
        V_ERRMSG  := 'Data Element Name MontlyTransferAmount is Invalid. Value is :'||p_dayofmonthtrns_amt;
        RAISE EXP_REJECT_RECORD;

        ELSE

         IF p_dayofmonthtrns_amt < v_min_svg_lmt OR  p_dayofmonthtrns_amt < v_min_spend_amt THEN

               P_RESP_CODE := '103';
               V_ERRMSG := 'Amount should not below the Minimum configured amount';
               RAISE exp_reject_record;

            ELSIF p_dayofmonthtrns_amt > v_max_svg_lmt OR p_dayofmonthtrns_amt > v_max_spend_amt THEN

              P_RESP_CODE := '104';
              V_ERRMSG := 'Amount should not exceed the Maximum configured amount';
              RAISE exp_reject_record;
             END IF;

        END IF;

       END IF;




     --Sn select acct type
          BEGIN
            SELECT CAT_TYPE_CODE
            INTO V_ACCT_TYPE
            FROM CMS_ACCT_TYPE
            WHERE CAT_INST_CODE = P_INST_CODE AND
            CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               P_RESP_CODE := '21';
               V_ERRMSG := 'Acct type not defined in master';
               RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG := 'Error while selecting accttype ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          END;
        --En select acct type


  --Sn check whether the Saving Account already created or not
         BEGIN
           SELECT cam_acct_no INTO V_SAVING_ACCTNO  FROM CMS_ACCT_MAST
           WHERE cam_acct_id IN( SELECT cca_acct_id FROM CMS_CUST_ACCT
           WHERE cca_cust_code=V_CUST_CODE AND cca_inst_code=P_INST_CODE) AND cam_type_code=V_ACCT_TYPE
           AND CAM_INST_CODE=p_inst_code;

         EXCEPTION
         WHEN NO_DATA_FOUND  THEN
            p_resp_code := '105';
            v_errmsg :='Savings account not created for this card';
            RAISE exp_reject_record;
          WHEN OTHERS  THEN
            p_resp_code := '12';
            v_errmsg :='Problem while selecting account details' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
         END;
      --En check whether the Saving Account already created or not


  --Sn find to card currency
   BEGIN
      --Sn modified by Pankaj S. during DFCCSD-70(Review) changes
      /*SELECT TRIM (cbp_param_value)
        INTO v_card_curr
        FROM cms_appl_pan, cms_bin_param, cms_prod_mast
       WHERE cap_prod_code = cpm_prod_code
         AND cap_pan_code = v_hash_pan
         AND cbp_param_name = 'Currency'
         AND cbp_profile_code = cpm_profile_code
         AND cap_inst_code = p_inst_code;*/

--      SELECT TRIM (cbp_param_value)
--       INTO V_CARD_CURR
--       FROM cms_bin_param, cms_prod_CATTYPE
--      WHERE cbp_param_name = 'Currency'
--        AND CBP_PROFILE_CODE = CPC_PROFILE_CODE
--        AND cpC_prod_code = v_prod_code AND CPC_CARD_TYPE=V_CARD_TYPE
--        AND cpC_inst_code = p_inst_code;
--     --En modified by Pankaj S. during DFCCSD-70(Review) changes

      vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_inst_code,v_card_curr,v_errmsg);

      if v_errmsg<>'OK' then
           raise exp_reject_record;
      end if;

      IF v_card_curr IS NULL --TRIM (v_card_curr) IS NULL   --modified by Pankaj S. during DFCCSD-70(Review) changes
      THEN
         p_resp_code := '21';
         v_errmsg := 'Card currency cannot be null ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting card currecy  '
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RAISE exp_reject_record;
   END;
  --En find to card currency

   --Sn check card currency with txn currency
   IF P_CURR_CODE <> v_card_curr
   THEN
      v_errmsg :=
            'Both from card currency and txn currency are not same  '
         || SUBSTR (SQLERRM, 1, 200);
      p_resp_code := '21';
      RAISE exp_reject_record;
   END IF;

   --En check card currency with txn currency --------

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,ctm_tran_desc
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,v_trans_desc
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '12';
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error while selecting transaction details '||substr(SQLERRM,1,100); -- Change in error message as per review observation for LYFEHOST-63
       RAISE EXP_REJECT_RECORD;
    END;
  --En find debit and credit flag

      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                V_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                V_TXN_AMT,
                NULL,
                NULL,
                V_MCC_CODE,
                P_CURR_CODE,
                NULL,
                NULL,
                NULL,
                V_ACCT_NUMBER,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                V_CARD_EXPRY,
                V_STAN,
                '000',
                P_RVSL_CODE,
                V_TXN_AMT,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          P_RESP_CODE := '21';
          V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure

    --St Update the savings acct automatic settings in acct mast
      BEGIN

        UPDATE CMS_ACCT_MAST SET
        CAM_LOADTIME_TRANSFER= p_loadtimetransfer,
        CAM_LOADTIME_TRANSFERAMT= decode(p_loadtimetransfer,1,p_loadtimetransfer_amt,CAM_LOADTIME_TRANSFERAMT),
        CAM_FIRSTMONTH_TRANSFER= p_firstmonthtransfer,
        CAM_FIRSTMONTH_TRANSFERAMT= decode(p_firstmonthtransfer,1,p_firstmonthtransfer_amt,CAM_FIRSTMONTH_TRANSFERAMT),
        CAM_FIFTEENMONTH_TRANSFER= p_fifteenmonthtransfer,
        CAM_FIFTEENMONTH_TRANSFERAMT= decode(p_fifteenmonthtransfer,1,p_fifteenmonthtransfer_amt,CAM_FIFTEENMONTH_TRANSFERAMT),
        CAM_WEEKLYTRANSFER_FLAG = p_weeklytransfer_flag,
        CAM_WEEKLYTRANSFER_AMOUNT= decode(p_weeklytransfer_flag,1,p_weeklytransfer_amount,CAM_WEEKLYTRANSFER_AMOUNT),
        CAM_BIWEEKLYTRANSFER_FLAG=p_biweeklytransfer_flag,
        CAM_BIWEEKLYTRANSFER_AMOUNT= decode(p_biweeklytransfer_flag,1,p_biweeklytransfer_amt,CAM_BIWEEKLYTRANSFER_AMOUNT),
        CAM_ANYDAYMONTHTRANSFER_FLAG=p_dayofmonthtrns_flag,
        CAM_DAYOFTRANSFER_MONTH=p_dayofmonth,
        CAM_MONTLYTRANSFER_AMOUNT= decode(p_dayofmonthtrns_flag,1,p_dayofmonthtrns_amt,CAM_MONTLYTRANSFER_AMOUNT),
        CAM_MINRELOAD_AMOUNT = P_MINRELOAD_AMT
       WHERE CAM_INST_CODE=P_INST_CODE
        AND CAM_ACCT_NO=V_SAVING_ACCTNO;

      IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG  := 'Problem while updating data in ACCT MAST ' ||
                   SUBSTR(SQLERRM, 1, 200);
        P_RESP_CODE := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;

      EXCEPTION
        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        --En Added by Pankaj S. during DFCCSD-70(Review) changes
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while updating savings acct settings ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
   --En Update the savings acct automatic settings in acct mast


      P_RESP_CODE := 1;
      V_ERRMSG := 'SUCCESSFUL';

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
             P_RESP_CODE := '21';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          RAISE EXP_REJECT_RECORD;  --Added by Pankaj S. during DFCCSD-70(Review) changes
        END;
      --En Get responce code fomr master

       --Sn update topup card number details in translog
        BEGIN

--Added for VMS-5733/FSP-991
IF (v_Retdate>v_Retperiod)
THEN
          UPDATE TRANSACTIONLOG
          SET  --RESPONSE_ID=P_RESP_CODE,  --commented by Pankaj S. during DFCCSD-70(Review) changes
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               txn_status = 'C',
               ani = p_ani,
               dni = p_dni
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
       ELSE
           UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
          SET  --RESPONSE_ID=P_RESP_CODE,  --commented by Pankaj S. during DFCCSD-70(Review) changes
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               txn_status = 'C',
               ani = p_ani,
               dni = p_dni
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
       END IF;    

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update topup card number details in translog

    -- TransactionLog & cms_transaction_log_dtl has been removed by ramesh on 12/03/2012

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN exp_auth_reject_record THEN
--ROLLBACK; Commented by Besky on 06-nov-12
P_RESMSG:=V_ERRMSG;-- Added by Besky on 06-nov-12

WHEN EXP_REJECT_RECORD THEN
 ROLLBACK TO V_AUTH_SAVEPOINT;

      v_resp_cde:=P_RESP_CODE;  --Added by Pankaj S. during DFCCSD-70(Review) changes

     --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
     --En Get responce code fomr master
    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_desc
         INTO v_dr_cr_flag,
              v_txn_type,
              v_trans_desc
         FROM cms_transaction_mast
        WHERE ctm_tran_code = p_txn_code
          AND ctm_delivery_channel = p_delivery_channel
          AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF;

    IF v_prod_code IS NULL THEN
    BEGIN
       SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
         INTO v_card_stat, v_spnd_acct_no, v_prod_code, v_card_type
         FROM cms_appl_pan
        WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF;
    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes

    --Sn Added by Pankaj S. for DFCCSD-70 changes
    BEGIN
       SELECT cam_acct_no,cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_spnd_acct_no,v_avail_bal, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =v_spnd_acct_no;
    EXCEPTION
       WHEN OTHERS THEN
          v_avail_bal := 0;
          v_ledger_bal := 0;
    END;
    --En Added by Pankaj S. for DFCCSD-70 changes


    --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     ANI,
                     DNI,
                     trans_desc,
                     response_ID,
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     acct_balance,
                     ledger_balance,
                     acct_type,
                     --En added by Pankaj S. for DFCCSD-70 changes
                     --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                     cr_dr_flag,
                     productid,
                     categoryid,
                     time_stamp
                     --En Added by Pankaj S. during DFCCSD-70(Review) changes
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARD_STAT,
                     P_ANI,
                     P_DNI,
                     v_trans_desc,
                     v_resp_cde,--P_RESP_CODE, --Modified by Pankaj S. during DFCCSD-70(Review) changes
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     v_avail_bal,
                     v_ledger_bal,
                     v_acct_type,
                     --En added by Pankaj S. for DFCCSD-70 changes
                     --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                     v_dr_cr_flag,
                     v_prod_code,
                     v_card_type,
                     systimestamp
                     --En Added by Pankaj S. during DFCCSD-70(Review) changes
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '12';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
        --RAISE EXP_REJECT_RECORD;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
     END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              V_SPND_ACCT_NO,
              ''
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          --RETURN; --Commented by Pankaj S. during DFCCSD-70(Review) changes
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
      P_RESMSG:=V_ERRMSG; --Added by Pankaj S. during DFCCSD-70(Review) changes
--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK TO V_AUTH_SAVEPOINT;

     v_resp_cde:=P_RESP_CODE;  --Added by Pankaj S. during DFCCSD-70(Review) changes

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
   --En Get responce code fomr master

    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_desc
         INTO v_dr_cr_flag,
              v_txn_type,
              v_trans_desc
         FROM cms_transaction_mast
        WHERE ctm_tran_code = p_txn_code
          AND ctm_delivery_channel = p_delivery_channel
          AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF;

    IF v_prod_code IS NULL THEN
    BEGIN
       SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
         INTO v_card_stat, v_spnd_acct_no, v_prod_code, v_card_type
         FROM cms_appl_pan
        WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF;
    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes

   --Sn Added by Pankaj S. for DFCCSD-70 changes
    BEGIN
       SELECT cam_acct_no,cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_spnd_acct_no,v_avail_bal, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =v_spnd_acct_no;
    EXCEPTION
       WHEN OTHERS THEN
          v_avail_bal := 0;
          v_ledger_bal := 0;
    END;
    --En Added by Pankaj S. for DFCCSD-70 changes

   --Sn Inserting data in transactionlog
      BEGIN
          INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     ANI,
                     DNI,
                     trans_desc,
                     response_ID,
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     acct_balance,
                     ledger_balance,
                     acct_type,
                     --En added by Pankaj S. for DFCCSD-70 changes
                     --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                     cr_dr_flag,
                     productid,
                     categoryid,
                     time_stamp
                     --En Added by Pankaj S. during DFCCSD-70(Review) changes
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARD_STAT,
                     P_ANI,
                     P_DNI,
                     v_trans_desc,
                     v_resp_cde,--P_RESP_CODE, --Modified by Pankaj S. during DFCCSD-70(Review) changes
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     v_avail_bal,
                     v_ledger_bal,
                     v_acct_type,
                     --En added by Pankaj S. for DFCCSD-70 changes
                     --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                     v_dr_cr_flag,
                     v_prod_code,
                     v_card_type,
                     systimestamp
                     --En Added by Pankaj S. during DFCCSD-70(Review) changes
                     );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
            --RETURN; --Commented by Pankaj S. during DFCCSD-70(Review) changes
         END;
     --En Inserting data in transactionlog

     --Sn Inserting data in transactionlog dtl
       BEGIN
          INSERT  INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
             'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              V_SPND_ACCT_NO,
              ''
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          --RETURN;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption
    P_RESMSG:=V_ERRMSG; --Added by Pankaj S. during DFCCSD-70(Review) changes
END;
/
show error