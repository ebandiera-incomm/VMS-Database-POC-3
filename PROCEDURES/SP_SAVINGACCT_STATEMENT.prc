set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.sp_savingacct_statement (
   p_inst_code          IN       NUMBER,
   p_pan_code           IN       NUMBER,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2, 
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_msgtype            IN       VARCHAR2,
   p_month_year         IN       VARCHAR2, -- Added by siva kumar m on 16/08/2012
   p_svg_acct_no        IN       VARCHAR2, -- Added by siva kumar m on 20/08/2012.
   p_resp_code          OUT      VARCHAR2,
   p_mini_stat_res      OUT      CLOB, --Order chnaged by Ramesh.A on 22/05/2012
   p_err_msg            OUT      VARCHAR2,
   p_tot_dr_amt         OUT      NUMBER,
   p_tot_cr_amt         OUT      NUMBER,
   p_led_bal_amt        OUT      VARCHAR2,
   p_avail_bal_amt      OUT      VARCHAR2,
   p_savings_avail_bal  OUT      VARCHAR2 ,   -- Added by siva kumar m as on 21/08/2012.
   p_availed_txn        OUT      NUMBER,-- Added on 25.03.2013 for FSS-1106
   p_available_txn      OUT      NUMBER, -- Added on 25.03.2013 for FSS-1106
   p_interest_rate      OUT      VARCHAR2,
   p_interest_paid      OUT      VARCHAR2,
   p_interest_accrued   OUT      VARCHAR2,
   p_percentage_yield   OUT      VARCHAR2,
   P_BEGINING_BAL       OUT      VARCHAR2,
   P_ENDING_BAL         OUT      VARCHAR2

)
AS
/*************************************************
    * Created Date     :  27-Apr-2012
    * Created By       :  Saravanakumar
    * PURPOSE          :  Mini statement for saving account
    * modified by      :  B.Besky
    * modified Date    :  06-NOV-12
    * modified reason  :  Changes in Exception handling
    * Reviewer         :  Saravanakumar
    * Reviewed Date    :  06-NOV-12
    * Build Number     :  CMS3.5.1_RI0021

    * Modified Date     : 25-Mar-2013
    * Modified By       : Sachin P.
    * Modified For      : FSS-1106
    * Purpose           : To pass the available/available transaction as the output.
    * Reviewer          : Dhiraj
    * Reviewed Date     :
    * Build Number      : RI0024_B0009

    * Modified by      :  Pankaj S.
    * Modified Reason  :  10871
    * Modified Date    :  18-Apr-2013
    * Reviewer         :  Dhiraj
    * Reviewed Date    :
    * Build Number     : RI0024.1_B0013

    * Modified by      :  Pankaj S.
    * Modified Reason  :  DFCCSD-70
    * Modified Date    :  21-Aug-2013
    * Reviewer         :  Dhiraj
    * Reviewed Date    :  20-Aug-2013
    * Build Number     :  RI0024.4_B0006

    * Modified By      : Sai Prasad
    * Modified Date    : 11-Sep-2013
    * Modified For     : Mantis ID: 0012275 (JIRA FSS-1144)
    * Modified Reason  : ANI & DNI is not logged in transactionlog table.
    * Reviewer         : Dhiraj
    * Reviewed Date    : 11-Sep-2013
    * Build Number     : RI0024.4_B0010

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

    * Modified By      : Sagar More
    * Modified Date    : 22-OCT-2013
    * Modified For     : Defect 12797
    * Modified Reason  : To uncomment subquery used to fetch saving acct from cms_acct_mast
    * Reviewer         : Dhiraj
    * Reviewed Date    : 23-OCT-2013
    * Build Number     : RI0024.6_B0002

    * Modified By      : Siva Kumar
    * Modified Date    : 02-APR-2014
    * Modified For     : mantis id:14052
    * Modified Reason  : Savings Account Running balance
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.1.2_B0001

     * Modified By      : Ramesh
     * Modified Date    : 15-MAY-2014
     * Modified For     : MVHOST-903
     * Modified Reason  : Added code to get Annual percentage yield from interset detail or hist table
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0027.1.6_B0001

     * Modified By      : Ramesh A
     * Modified Date    : 20-Jun-2014
     * Modified For     : FSS-1723 : APYE changes
     * Reviewer         : spankaj
     * Build Number     : RI0027.1.9_B0002

     * Modified By      : Ramesh A
     * Modified Date    : 24-Jun-2014
     * Modified For     : MantisID_15297
     * Reviewer         : spankaj
     * Build Number     : RI0027.1.9_B0004

     * Modified By      : Ramesh A
     * Modified Date    : 19-July-2014
     * Modified For     : FSS-1743
     * Reviewer         : Spankaj
     * Build Number     : RI0027.1.9.1_B0001

     * Modified By      : Ramesh A
     * Modified Date    : 18-July-2014
     * Modified For     : 2.1.9.2 integration
     * Build Number     : RI0027.2.4_B0001

     * Modified By      : Ramesh A
     * Modified Date    : 23-SEP-2014
     * Modified For     : Integration changes(2.2.6 to 2.3.3)FSS-1830 & NCGPR-1534 and Mantis Id: 15755(Format changes and modified in getting begin and end balance query)
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.3_B0001

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 25-Sep-14
    * Modified For      : MVHOST 987
    * Reviewer          :
    * Build Number      : RI0027.4_B0001

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 01-Oct-14
    * Modified For      : Mantis ID 15779
    * Reviewer          : spankaj
    * Build Number      : RI0027.4_B0002

    * Modified by       : Ramesh A
    * Modified Date     : 22-JAN-15
    * Modified For      : FSS-2077
    * Reviewer          :
    * Build Number      :

    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1

     * Modified by      : Ramesh A
     * Modified Date    : 27-Nov-2015
     * Modified for     : Savings Account statement changes(removed card number in cursor)
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.2.1

     * Modified by      : Siva Kumar m
     * Modified Date    : 18-Aug-2016
     * Modified for     : VP-10
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_4.2

        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
      * Modified By      : MageshKumar S
      * Modified Date    : 18/07/2017
      * Purpose          : FSS-5157
      * Reviewer         : Saravanan/Pankaj S.
      * Release Number   : VMSGPRHOST17.07

    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
*************************************************/
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_acct_type              cms_acct_type.cat_type_code%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_saving_acctno          cms_acct_mast.cam_acct_no%TYPE;
   v_rrn_count              NUMBER;
   v_count                  NUMBER;
   v_capture_date           DATE;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_savepoint              NUMBER := 1;
   exp_reject_record        EXCEPTION;
   v_tran_cnt               NUMBER;
   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
   v_mini_stat_val          CLOB;
   v_tran_amount            cms_statements_log.csl_trans_amount%TYPE;
   v_tran_type              cms_statements_log.csl_trans_type%TYPE;
   exp_auth_reject_record   EXCEPTION;      --Added by Ramesh.A on 22/05/2012

    V_DR_CR_FLAG       VARCHAR2(2);
    V_OUTPUT_TYPE      VARCHAR2(2);
    V_TXN_TYPE          VARCHAR2(2);
   V_MONTH_YEAR      date;   -- Added by siva kumar m on 16/08/2012

   v_spend_acct_type   cms_acct_type.cat_type_code%TYPE;
   V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
   v_max_svg_trns_limt        cms_dfg_param.cdp_param_key%TYPE; --Added on 25.03.2013 for FSS-1106
   v_svgtospd_trans           NUMBER;--Added on 25.03.2013 for FSS-1106
   v_tran_date                DATE;--Added on 25.03.2013 for FSS-1106
   --Sn Added by Pankaj S. for 10871
   v_cardstat      cms_appl_pan.cap_card_stat%TYPE;
   v_card_type     cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde       cms_response_mast.cms_response_id%TYPE;
   --En Added by Pankaj S. for 10871
   --Sn added by Pankaj S. for DFCCSD-70 changes
   v_acct_number  cms_acct_mast.cam_acct_no%TYPE;
   v_avail_bal    cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal   cms_acct_mast.cam_ledger_bal%TYPE;
   --En added by Pankaj S. for DFCCSD-70 changes

   v_date_chk      date;       -- Added as per review observation for LYFEHOST-63
   start_date  varchar2(8);
   v_month     Varchar2(2);
   v_year      Varchar2(4);
   v_firstday_month Date;
   v_lastdate_month Date;
   v_business_date  varchar2(8);
   V_PROFILE_CODE CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991

   CURSOR c_mini_tran_ivr --Updated by Ramesh.A on 22/06/2012
   IS
      SELECT *
        FROM (SELECT /*+rule*/  TRIM (TO_CHAR (csl_trans_amount,
                                      '99999999999999999.99')
                            ),
                       csl_trans_type,
                          TO_CHAR (csl_trans_date, 'MM/DD/YYYY')
                       || ' ~ '
                       || csl_trans_type
                       || ' ~ '
                       || TRIM (TO_CHAR (csl_trans_amount,
                                         '99999999999999999.99'
                                        )
                               )
                       || ' ~ '
                       || csl_trans_narrration
                       || ' ~ '
                       || TRIM (TO_CHAR (csl_closing_balance,
                                         '99999999999999999.99'
                                        )
                               )
                  FROM CMS_STATEMENTS_LOG_VW
                 WHERE --csl_pan_no = v_hash_pan AND --Commented for not required on 27/11/15
                    csl_acct_no = v_saving_acctno
                   AND CSL_INST_CODE=p_inst_code  -- Added by siva kumar m as on Oct-11-12
              ORDER BY CSL_INS_DATE DESC) -- Modified by Ramesh.A on 13/09/12,sort by ins date
       WHERE ROWNUM <= v_tran_cnt;

  CURSOR c_mini_tran_chw  --Added by Ramesh.A on 22/06/2012
   IS
       select * from (
           SELECT /*+rule*/ TRIM (TO_CHAR (csl_trans_amount, '99999999999999999.99')),csl_trans_type,
       TO_CHAR (csl_trans_date, 'MM/DD/YYYY')
       || ' ~ '
       || csl_trans_type
       || ' ~ '
       || sl.csl_delivery_channel
       || ' ~ '
       || (case when sl.csl_delivery_channel = '05' and sl.csl_txn_code='13' then 'Interest Payment' else tm.ctm_tran_desc end) --Modified for FSS-1830 & NCGPR-1534
       || DECODE(SL.TXN_FEE_FLAG,'Y',' - FEE')
       || ' ~ '
       || sl.csl_rrn
       || ' ~ '
      -- || nvl(sl.csl_merchant_name,'System')--Modified for MVHOST 987
       || NVL (
                                      SL.CSL_MERCHANT_NAME,
                                      DECODE (TRIM (DM.CDM_CHANNEL_DESC),
                                                 'ATM', 'ATM',
                                                 'POS', 'Retail Merchant',
                                                 'IVR', 'IVR Transfer',
                                                 'CHW', 'Card Holder website',
                                                 'ACH', 'Direct Deposit',
                                                 'MOB', 'Mobile Transfer',
                                                 'CSR', 'Customer Service',
                                                 'System')) --Modified for 15779
       || ' ~ '
       || sl.csl_merchant_city
       || ' ~ '
       || sl.csl_merchant_state
       || ' ~ '
       || TRIM (TO_CHAR (csl_trans_amount, '99999999999999999.99'))
       || ' ~ '
       || TRIM (TO_CHAR (sl.csl_closing_balance, '99999999999999999.99'))
       || ' ~ '
       || (case when ((sl.csl_delivery_channel = '10' and sl.csl_txn_code in('18','19')) or (sl.csl_delivery_channel = '07' and sl.csl_txn_code='10')  or (sl.csl_delivery_channel = '13' and sl.csl_txn_code='04') or (sl.csl_delivery_channel = '03' and sl.csl_txn_code='45')) then v_acct_number else sl.csl_acct_no end)  --Modified for 15755
       || ' ~ '
       || (case when ((sl.csl_delivery_channel = '10' and sl.csl_txn_code in('18','19')) or (sl.csl_delivery_channel = '07' and sl.csl_txn_code='10')  or (sl.csl_delivery_channel = '13' and sl.csl_txn_code='04') or (sl.csl_delivery_channel = '03' and sl.csl_txn_code='45')) then sl.csl_acct_no else sl.csl_to_acctno end)    --Modified for 15755

       --|| decode(tm.ctm_amnt_transfer_flag,'Y',(nvl2(sl.csl_to_acctno,' ~ ' || sl.csl_to_acctno,'')))  Commented by Ramesh.A on 10/07/2012
       || ' ~ '
       || SL.CSL_PANNO_LAST4DIGIT
  FROM CMS_STATEMENTS_LOG_VW sl, cms_transaction_mast tm,CMS_DELCHANNEL_MAST DM  --Added for 15779
 where --csl_pan_no = v_hash_pan AND -- Commented by siva kumar m as on Oct-11-12
    csl_acct_no =v_saving_acctno
   and TM.CTM_DELIVERY_CHANNEL = SL.CSL_DELIVERY_CHANNEL
   and dm.cdm_channel_code=SL.CSL_DELIVERY_CHANNEL --Added for 15779
   AND tm.ctm_tran_code = sl.csl_txn_code
   AND SL.CSL_INST_CODE = TM.CTM_INST_CODE  -- Added by siva kumar m as on Oct-11-12
   AND CSL_INST_CODE=p_inst_code     -- Added by siva kumar m as on Oct-11-12
    AND CSL_TRANS_DATE is not null AND  --Updated by Ramesh.A on 23/07/2012
                ((P_MONTH_YEAR IS NOT NULL AND                             -- Added by siva kumar m on 16/08/2012
                TO_CHAR(CSL_TRANS_DATE, 'MMYYYY') = P_MONTH_YEAR) OR
                P_MONTH_YEAR IS NULL )
       ORDER BY CSL_INS_DATE DESC)   -- Modified by Ramesh.A on 13/09/12,sort by ins date
   -- WHERE ROWNUM <= v_tran_cnt;
    WHERE (p_month_year IS NULL AND ROWNUM <= v_tran_cnt) OR
         p_month_year IS NOT NULL;

BEGIN
   SAVEPOINT v_savepoint;
   p_tot_dr_amt := 0;
   p_tot_cr_amt := 0;

   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_err_msg :=
                'Error while converting hashpan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_encr_pan := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_err_msg :=
            'Error while converting encrpyt pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn find debit and credit flag

    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = p_inst_code;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       p_resp_code := '12'; --Ineligible Transaction
       p_err_msg  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE exp_reject_record;
     WHEN OTHERS THEN
       p_resp_code := '21'; --Ineligible Transaction
       p_err_msg  := 'Error while selecting transaction details '||substr(sqlerrm,1,100);
       RAISE exp_reject_record;
    END;
           --En find debit and credit flag


   --SN: Added as per review observation for LYFEHOST-63

   Begin

       select to_Date(substr(p_tran_date,1,8),'yyyymmdd')
       into v_date_chk
       from dual;

   exception when others
   then
        p_resp_code := '21';
        p_err_msg := 'Invalid transaction date '||P_TRAN_DATE; -- updated
        RAISE exp_reject_record;
   End;

     --EN: Added as per review observation for LYFEHOST-63


   --Checking duplicate RRN
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
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND delivery_channel = p_delivery_channel;
    else
           SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND delivery_channel = p_delivery_channel;
     end if;    

      IF v_rrn_count > 0
      THEN
         p_resp_code := '22';
         p_err_msg := 'Duplicate RRN on ' || p_rrn;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record THEN
      RAISE exp_reject_record;
      WHEN OTHERS THEN
        p_resp_code := '22';
         p_err_msg := 'Error in RRN count check '|| p_rrn||SUBSTR(SQLERRM,1,200);
         RAISE exp_reject_record;
   -- Added Exception by Ramesh.A on 21/05/2012 for defect id : 7631 ,7630
   END;


   --St validate Month and year.                       -- Added by siva kumar m on 16/08/2012
     IF P_DELIVERY_CHANNEL ='10'  AND P_TXN_CODE ='36' THEN
     BEGIN
       V_MONTH_YEAR    := TO_DATE(P_MONTH_YEAR, 'MMYYYY');

     EXCEPTION
       WHEN OTHERS THEN
        p_resp_code := '49'; -- Server Declined -220509
        p_err_msg  := 'Invalid Month and Year';
        RAISE EXP_REJECT_RECORD;
     END;


    END IF;

   --Fetching account type for saving account
   BEGIN
      SELECT cat_type_code
        INTO v_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code AND cat_switch_type = '22';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_err_msg := 'Acct type is not defined for saving account';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
            'Error while selecting account type ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;


     --Fetching account type for saving account
   BEGIN
      SELECT cat_type_code
        INTO v_spend_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code AND cat_switch_type = '11';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_err_msg := 'Acct type is not defined ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
            'Error while selecting account type ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Fetching customer code for this card
   BEGIN
      SELECT cap_cust_code,
             cap_prod_code,cap_card_stat,cap_card_type, --added by Pankaj S. for 10871
             cap_acct_no  --Added by Pankaj S. during DFCCSD-70(Review) changes
        INTO v_cust_code,
             v_prod_code,v_cardstat,v_card_type,  --added by Pankaj S. for 10871
             v_acct_number --Added by Pankaj S. during DFCCSD-70(Review) changes
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_err_msg := 'Customer code is not defined for this card';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_err_msg :=
               'Error while getting  cust code from master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
   --Checking saving account is already exist for this customer
   BEGIN
      SELECT cam_acct_no, cam_acct_bal,case when sysdate >CAM_SAVTOSPD_TFER_DATE then 0  else NVL(CAM_SAVTOSPD_TFER_COUNT,0) end --cam_savtospd_tfer_count--COUNT (1)
        INTO v_saving_acctno, p_savings_avail_bal,v_svgtospd_trans  --v_count
        FROM cms_acct_mast
       WHERE --cam_acct_no=p_svg_acct_no            -- Condition commented on 22-oct-2013 defect 12797
       cam_acct_id IN (                             -- Subquery uncommented on 22-oct-2013 defect 12797
                SELECT cca_acct_id
                  FROM cms_cust_acct
                 WHERE cca_cust_code = v_cust_code
                   AND cca_inst_code = p_inst_code)
         AND cam_type_code = v_acct_type
         AND cam_inst_code = p_inst_code;

      --IF v_count = 0
      --THEN
      --   p_err_msg := 'Savings account not created for this card';
      --   p_resp_code := '105';
      --   RAISE exp_reject_record;
      --END IF;
   EXCEPTION
      --WHEN exp_reject_record
      --THEN
      --   RAISE exp_reject_record;
      WHEN NO_DATA_FOUND THEN
      p_err_msg := 'Savings account not created for this card';
      p_resp_code := '105';
      RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
            'Error while selecting cms_acct_mast '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Modified by Pankaj S. during DFCCSD-70(Review) changes

   -- Sn added here by commenting from below 22-oct-2013

   IF v_saving_acctno <> p_svg_acct_no
        THEN
          p_resp_code := '109';
          p_err_msg := 'Invalid Savings Account Number '||p_svg_acct_no; -- appended on 22-oct-2013

          RAISE exp_reject_record;
   END IF;

 -- En added here by commenting from below 22-oct-2013

   --Sn Commented  here & used above by Pankaj S. during DFCCSD-70(Review) changes
   /*--Fetching saving account number
   BEGIN
      SELECT cam_acct_no, cam_acct_bal
        INTO v_saving_acctno, p_savings_avail_bal   -- updated by siva kumar as on 21/08/2012
        FROM cms_acct_mast
       WHERE cam_acct_id IN (
                SELECT cca_acct_id
                  FROM cms_cust_acct
                 WHERE cca_cust_code = v_cust_code
                   AND cca_inst_code = p_inst_code)
         AND cam_type_code = v_acct_type
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
               'Error while selecting cms_acct_mast 1 '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/
   --En Commented  here & used above by Pankaj S. during DFCCSD-70(Review) changes


   --SN Added on 25.03.2013 for FSS-1106
      --Sn Get Tran date
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get Tran date

   --Sn Get Max. No.of Trnasaction configured
   BEGIN
     SELECT  cdp_param_value
        INTO v_max_svg_trns_limt
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code
       and  cdp_prod_code = v_prod_code     --Added for LYFEHOST-63
       and cdp_card_type= v_card_type
       and cdp_param_key = 'MaxNoTrans';

   EXCEPTION WHEN NO_DATA_FOUND             -- Added no_data_found exeception during LYFEHOST-63 chanegs
   THEN
        p_resp_code := '21';
        p_err_msg  := 'Saving acct tran limit not found for product '||v_prod_code||' and instcode '||p_inst_code;
        --|| SUBSTR (SQLERRM, 1, 200); -- change in error messgae for LYFEHOST-63

       RAISE exp_reject_record;

   WHEN OTHERS THEN
        p_resp_code := '21';
        p_err_msg  := 'Error while selecting DFG parameter for MaxNoTrans--'
        || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
       RAISE exp_reject_record;
   END;
   --En Get Max. No.of Trnasaction configured

   --Sn Commented for Transactionlog Functional Removal Phase-II changes
   ---Sn to get transaction availed for month
   /*BEGIN
      SELECT COUNT (*)
        INTO v_svgtospd_trans
        FROM transactionlog
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code = '11')
             )
         AND business_date BETWEEN TO_CHAR (TRUNC (v_tran_date, 'month'),
                                            'yyyymmdd'
                                           )
                               AND TO_CHAR
                                     (LAST_DAY (v_tran_date), 'yyyymmdd')

         AND response_code = '00'
         AND customer_card_no = v_hash_pan
         AND customer_acct_no = v_saving_acctno;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
               'Error while selecting data from TRANSACTIONLOG for getting the number of transactions for  month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/
   ---En to get transaction availed for month
   --En Commented for Transactionlog Functional Removal Phase-II changes

   p_availed_txn :=  v_svgtospd_trans ;
   p_available_txn := v_max_svg_trns_limt - v_svgtospd_trans;
   --EN Added on 25.03.2013 for FSS-1106


--ST getting spending account balance. added by siva kumar m as on 21/08/2012.
BEGIN
      SELECT  cam_acct_bal,cam_ledger_bal
        INTO  p_avail_bal_amt, p_led_bal_amt
        FROM cms_acct_mast
       --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
       WHERE cam_acct_no=v_acct_number
         --cam_acct_id IN (
         --       SELECT cca_acct_id
         --         FROM cms_cust_acct
         --        WHERE cca_cust_code = v_cust_code
         --          AND cca_inst_code = p_inst_code)
         --AND cam_type_code = v_spend_acct_type
       --En Modified by Pankaj S. during DFCCSD-70(Review) changes
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
               'Error while selecting cms_acct_mast 1 '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

  /*  -- Commented and moved up after acct_mast query for saving acct 22-oct-2013
   IF v_saving_acctno <> p_svg_acct_no
        THEN
          p_resp_code := '109';
          p_err_msg := 'Invalid Savings Account Number';

          RAISE exp_reject_record;
   END IF;
  */ -- Commented and moved up after acct_mast query for saving acct 22-oct-2013



   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msgtype,
                                 p_rrn,
                                 p_delivery_channel,
                                 NULL,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_bank_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 p_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 '000',
                                 p_rvsl_code,
                                 NULL,
                                 v_auth_id,
                                 p_resp_code,
                                 p_err_msg,
                                 v_capture_date
                                );



      IF p_resp_code <> '00' AND p_err_msg <> 'OK'
      THEN
         RAISE exp_auth_reject_record;    --Updated by Ramesh.A on 22/05/2012
      END IF;
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN                                   --Added by Ramesh.A on 22/05/2012
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
               'Error while calling SP_AUTHORIZE_TXN_CMS_AUTH'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   BEGIN
        SELECT cpc_profile_code INTO V_PROFILE_CODE FROM cms_prod_cattype
        WHERE  cpc_inst_code = p_inst_code
        AND cpc_prod_code = v_prod_code
        AND cpc_card_type = v_card_type;
        EXCEPTION
        WHEN OTHERS THEN
        p_resp_code := '21';
        p_err_msg :='Profile code not defined for product code '|| v_prod_code|| 'card type '|| v_card_type;
        RAISE EXP_REJECT_RECORD;
        END;

   BEGIN
      --Sn Commented by Pankaj S. during DFCCSD-70(Review) changes
      /*SELECT cap_prod_code
        INTO v_prod_code
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;*/
      --En Commented by Pankaj S. during DFCCSD-70(Review) changes

      SELECT TO_NUMBER (cbp_param_value)
        INTO v_tran_cnt
        FROM cms_bin_param
       WHERE cbp_inst_code = p_inst_code
         AND cbp_param_name = 'TranCount_For_RecentStmt'
         AND cbp_profile_code = V_PROFILE_CODE;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_tran_cnt := 10;
   END;
   --stsrt :Updated by Ramesh.A on 22/06/2012
  IF p_delivery_channel = '07' AND p_txn_code = '15' THEN
   BEGIN
      OPEN c_mini_tran_ivr;

      LOOP
         FETCH c_mini_tran_ivr
          INTO v_tran_amount, v_tran_type, v_mini_stat_val;

         EXIT WHEN c_mini_tran_ivr%NOTFOUND;
         p_mini_stat_res := p_mini_stat_res || ' || ' || v_mini_stat_val;

         IF v_tran_type = 'DR'
         THEN
            p_tot_dr_amt := p_tot_dr_amt + v_tran_amount;
         ELSIF v_tran_type = 'CR'
         THEN
            p_tot_cr_amt := p_tot_cr_amt + v_tran_amount;
         END IF;
      END LOOP;

      CLOSE c_mini_tran_ivr;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_err_msg :=
                    'Error while opening cursor:' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
 END IF;
-- IF p_delivery_channel = '10' AND p_txn_code = '33' THEN
IF p_delivery_channel = '10' AND p_txn_code in ('33','36') THEN  -- added by siva kumar m  as on 16/08/2012
    BEGIN
      OPEN c_mini_tran_chw;

      LOOP
         FETCH c_mini_tran_chw
          INTO v_tran_amount, v_tran_type, v_mini_stat_val;

         EXIT WHEN c_mini_tran_chw%NOTFOUND;
         p_mini_stat_res := p_mini_stat_res || ' || ' || v_mini_stat_val;

         IF v_tran_type = 'DR'
         THEN
            p_tot_dr_amt := p_tot_dr_amt + v_tran_amount;
         ELSIF v_tran_type = 'CR'
         THEN
            p_tot_cr_amt := p_tot_cr_amt + v_tran_amount;
         END IF;
      END LOOP;

      CLOSE c_mini_tran_chw;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_err_msg :=
                    'Error while opening cursor:' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
 END IF;
 --End

  -- added  Mantis id :14052 for savings account transaction history changes on 01-Apr-2014

      IF P_DELIVERY_CHANNEL ='10'  AND P_TXN_CODE ='36' THEN

         -- annual percentage yield.
   /* Commented for MVHOST-903 on 15/05/14
       BEGIN
             SELECT  cdp_param_value
                INTO p_percentage_yield
                FROM cms_dfg_param
               WHERE cdp_inst_code = p_inst_code
               and  cdp_prod_code = v_prod_code
               and cdp_param_key = 'ANNUALPERCENTAGEYIELD';

               EXCEPTION WHEN NO_DATA_FOUND
               THEN
                    p_resp_code := '21';
                    p_err_msg  := 'Saving acct annual percentage yield not found for product '||v_prod_code||' and instcode '||p_inst_code;
                    RAISE exp_reject_record;

               WHEN OTHERS THEN
                    p_resp_code := '21';
                    p_err_msg  := 'Error while selecting DFG parameter for percentage yield --'|| SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;

       END;
       */
       --Added for FSS-2077
       --ST Added for getting from and last date of the month
        begin

         start_date :='01'||P_month_year;

        exception when others then

           p_resp_code := '21';
           p_err_msg :=
               'Problem while    month_year' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

        end;

         BEGIN

         select to_date(start_date,'DDMMYYYY') ,
           Last_day(to_date( start_date,'DDMMYYYY'))
           into v_firstday_month, v_lastdate_month  from dual;



         EXCEPTION  WHEN OTHERS THEN

           p_resp_code := '21';
           p_err_msg :=
               'Problem while  converting  month year' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

         END;
        --END

       --St Added for MVHOST-903 on 15/05/14
           BEGIN
               SELECT cid_interest_rate into   --Modified for FSS-1722 format changes in statement -- removed p_percentage_yield for FSS-2077
                 p_interest_rate  --Added for FSS-1830 & NCGPR-1534
                FROM CMS_INTEREST_DETL A
                WHERE A.CID_ACCT_NO       =p_svg_acct_no and cid_inst_code=p_inst_code
                AND A.CID_CALC_DATE=
                  (
                SELECT  MAX(B.CID_CALC_DATE)
                  FROM CMS_INTEREST_DETL B
                  WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=p_inst_code
                 AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                 );

                /* Commented for FSS-2077
                 if p_percentage_yield is null then
                   p_percentage_yield := '0.00';
                 end if;
                */

               EXCEPTION
               when no_data_found  then

                  BEGIN
                     SELECT cid_interest_rate into  --Modified for FSS-1722 format changes in statement -- removed p_percentage_yield  for FSS-2077
                      p_interest_rate --Added for FSS-1830 & NCGPR-1534
                    FROM CMS_INTEREST_DETL_HIST A
                    WHERE A.CID_ACCT_NO       =p_svg_acct_no and cid_inst_code=p_inst_code
                    AND A.CID_CALC_DATE=
                      (
                    SELECT  MAX(B.CID_CALC_DATE)
                      FROM CMS_INTEREST_DETL_HIST B  --Modified for defect id :
                      WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=p_inst_code
                     AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                     );

                      /* Commented for FSS-2077
                       if p_percentage_yield is null then
                         p_percentage_yield := '0.00';
                       end if;
                       */

                     EXCEPTION
                     when no_data_found  then
                      --p_percentage_yield := '0.00';
                      p_interest_rate := '0.00'; --Added for FSS-1830 & NCGPR-1534
                     WHEN OTHERS THEN
                      p_resp_code := '21';
                      p_err_msg  := 'Error while selecting interest detl hist ...'|| SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;

                  END;
            WHEN OTHERS THEN

                  p_resp_code := '21';
                  p_err_msg  := 'Error while selecting interest detl ...'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

            END;
           --En Added for MVHOST-903 on 15/05/14

           --ST Get APYE value based on the month --Added for FSS-2077
           begin

             select round((power (1+
             (round
             (sum(cid_interest_amount),2) /
             trunc(avg((cid_close_balance +(select nvl(sum(cid_qtly_interest_accr),0) from CMS_INTEREST_DETL where CID_ACCT_NO=p_svg_acct_no and cid_inst_code=p_inst_code
             and trunc(cid_calc_date) = last_day(v_firstday_month-1)
             ))    -cid_interest_amount) *
             (trunc(max(cid_calc_date)-min(cid_calc_date)+1) /
             to_char(last_day(max(cid_calc_date)),'dd')),2)),
             (365/to_char(last_day(max(cid_calc_date)),'dd')))-1)*100,2) into p_percentage_yield
             FROM CMS_INTEREST_DETL
             WHERE CID_ACCT_NO=p_svg_acct_no and cid_inst_code=p_inst_code
             and trunc(cid_calc_date) between v_firstday_month and v_lastdate_month;

             if p_percentage_yield is null then

                select round((power (1+
               (round
               (sum(cid_interest_amount),2) /
               trunc(avg((cid_close_balance +(select nvl(sum(cid_qtly_interest_accr),0) from CMS_INTEREST_DETL_HIST where CID_ACCT_NO=p_svg_acct_no and cid_inst_code=p_inst_code
               and trunc(cid_calc_date) = last_day(v_firstday_month-1)
               and  TO_CHAR( last_day(v_firstday_month-1),'MMDD')   not in ('0331','0630','0930','1231')
               ))    -cid_interest_amount) *
               (trunc(max(cid_calc_date)-min(cid_calc_date)+1) /
               to_char(last_day(max(cid_calc_date)),'dd')),2)),
               (365/to_char(last_day(max(cid_calc_date)),'dd')))-1)*100,2) into p_percentage_yield
               FROM CMS_INTEREST_DETL_HIST
               WHERE CID_ACCT_NO=p_svg_acct_no and cid_inst_code=p_inst_code
               and trunc(cid_calc_date) between v_firstday_month and v_lastdate_month;

               if p_percentage_yield is null then
                 p_percentage_yield := '0.00';
               end if;

             end if;
           EXCEPTION
           WHEN OTHERS THEN
            p_resp_code := '21';
            p_err_msg  := 'Error while selecting apye interest detl and hist ...'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         end;
          --End --Added for FSS-2077

         --  DBMS_OUTPUT.put_line ('before month');

           begin

             v_month := substr(trim(p_month_year),1,2);
             v_year :=  substr(trim(p_month_year),3,6);

             EXCEPTION     WHEN OTHERS    THEN
             p_resp_code := '21';
             p_err_msg :=
                   'Problem while   substring   month_year ' || SUBSTR (SQLERRM, 1, 200);

             RAISE exp_reject_record;

           end;

      /* Commented for FSS-2077
        begin

         start_date :='01'||P_month_year;

        exception when others then

           p_resp_code := '21';
           p_err_msg :=
               'Problem while    month_year' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

        end;

         BEGIN

         select to_date(start_date,'DDMMYYYY') ,
           Last_day(to_date( start_date,'DDMMYYYY'))
           into v_firstday_month, v_lastdate_month  from dual;



         EXCEPTION  WHEN OTHERS THEN

           p_resp_code := '21';
           p_err_msg :=
               'Problem while  converting  month year' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

         END;
        */
           if v_month  in ('03','12') then

           v_business_date := v_year||v_month||'31';

           elsif v_month in ('06','09') then

           v_business_date := v_year||v_month||'30';

           end if;
           -- interest paid ..

         if v_month  in ('03','06','09','12') then

             begin

--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              select csl_trans_amount
                into  p_interest_paid
                 from  CMS_STATEMENTS_LOG
                 where  CSL_BUSINESS_DATE =v_business_date
                 AND csl_trans_type = 'CR'
                 AND csl_delivery_channel = '05'
                 AND csl_txn_code = '13'
                 AND csl_acct_no = p_svg_acct_no
                 AND csl_inst_code = p_inst_code;
ELSE

				select csl_trans_amount
                into  p_interest_paid
                 from  VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST
                 where  CSL_BUSINESS_DATE =v_business_date
                 AND csl_trans_type = 'CR'
                 AND csl_delivery_channel = '05'
                 AND csl_txn_code = '13'
                 AND csl_acct_no = p_svg_acct_no
                 AND csl_inst_code = p_inst_code;

END IF;				 


             exception when  NO_DATA_FOUND then

             p_interest_paid :='0.00';

             WHEN OTHERS THEN
              p_resp_code := '21';
              p_err_msg  := 'Error while selecting interest amount from statements...'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;


             end;

         else

          p_interest_paid :='0.00';

         end if;
        --- interest accrued for the period.

           BEGIN



             select to_char(nvl(sum(CID_INTEREST_AMOUNT),'0'), '99999999999999990.99')
              into  p_interest_accrued
              from  cms_interest_detl
              where to_date(cid_calc_date) between  v_firstday_month  and v_lastdate_month
              and cid_acct_no=p_svg_acct_no
              and cid_inst_code=p_inst_code;





              if p_interest_accrued = 0.00 then

                 BEGIN
                select to_char(nvl(sum(CID_INTEREST_AMOUNT),'0'), '99999999999999990.99')
                  into  p_interest_accrued
                  from  cms_interest_detl_HIST
                  where  to_date(cid_calc_date) between  v_firstday_month  and v_lastdate_month
                  and cid_acct_no=p_svg_acct_no
                  and cid_inst_code=p_inst_code;


               EXCEPTION WHEN OTHERS THEN

              p_resp_code := '21';
              p_err_msg  := 'Error while selecting interest amount hist ...'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;

              END;


             end if;


          EXCEPTION WHEN OTHERS THEN

              p_resp_code := '21';
              p_err_msg  := 'Error while selecting interest interest detl amount ...'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;


          END;

          --benging balance for the period

          begin
          /* Commented for FSS-1723
            select TO_CHAR (nvl(CSS_ACCT_BAL,'0'), '99999999999999990.99')
             into P_BEGINING_BAL
             from CMS_STMTPRD_SVGACTBAL
             where TO_DATE(CSS_STATMENT_PERIOD) = v_firstday_month
             and CSS_ACCT_NO=p_svg_acct_no
             and CSS_INST_CODE=P_INST_CODE;
             */
         -- Added for FSS-1723
         --Modified for FSS-1830 & NCGPR-1534
              select decode(s1.CSL_OPENING_BAL,0,to_char(s1.CSL_CLOSING_BALANCE,'99999999999999990.99'),to_char(s1.CSL_OPENING_BAL,'99999999999999990.99'))
              INTO P_BEGINING_BAL --Modified for MantisID_15297
                from  CMS_STATEMENTS_LOG_VW s1
                where  s1.csl_acct_no = p_svg_acct_no AND s1.csl_inst_code = p_inst_code
                and s1.csl_ins_date =
                (select min(s2.csl_ins_date) from CMS_STATEMENTS_LOG_VW s2
                where  s2.csl_acct_no = p_svg_acct_no AND s2.csl_inst_code = p_inst_code
                and to_char(s2.csl_trans_date,'MMYYYY') = P_month_year
                ) and rownum=1;

        exception  when no_data_found then

                   Begin
                       /*   Commented for FSS-1723
                      select  TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')
                      INTO P_BEGINING_BAL
                      from  cms_interest_detl
                      where cid_calc_date = (select cam_ins_date from cms_acct_mast where Cam_ACCT_NO=p_svg_acct_no and cam_inst_code=p_inst_code)
                      and cid_acct_no=p_svg_acct_no
                      and cid_inst_code=p_inst_code;
                      */
              -- Added for FSS-1723
                       SELECT TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')  into P_BEGINING_BAL
                      FROM CMS_INTEREST_DETL A
                      WHERE A.CID_ACCT_NO       =p_svg_acct_no and cid_inst_code=P_INST_CODE
                      AND A.CID_CALC_DATE=
                      (
                      SELECT  min(B.CID_CALC_DATE)
                      FROM CMS_INTEREST_DETL B
                      WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=P_INST_CODE
                      AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                      );

                   exception when no_data_found  then

                       Begin
                         /*  Commented for FSS-1723
                         select  TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')
                          INTO   P_BEGINING_BAL
                          from  cms_interest_detl_hist
                          where cid_calc_date = (select cam_ins_date from cms_acct_mast where Cam_ACCT_NO=p_svg_acct_no and cam_inst_code=p_inst_code)
                          and cid_acct_no=p_svg_acct_no
                          and cid_inst_code=p_inst_code;
                          */
              -- Added for FSS-1723
                          SELECT TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')  into P_BEGINING_BAL
                          FROM CMS_INTEREST_DETL_HIST A
                          WHERE A.CID_ACCT_NO =p_svg_acct_no and cid_inst_code=P_INST_CODE
                          AND A.CID_CALC_DATE=
                          (
                          SELECT  min(B.CID_CALC_DATE)
                          FROM CMS_INTEREST_DETL_HIST B
                          WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=P_INST_CODE
                          AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                          );

                       exception
               when no_data_found then

                       P_BEGINING_BAL :='0.00';

                       when others then

                       p_resp_code := '21';
                       p_err_msg  := 'Error while selecting begining from hist amount ...'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;

                       end;


                    when others then

                       p_resp_code := '21';
                       p_err_msg  := 'Error while selecting begining from interest detl  amount ...'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;


                   end;

         when others then

           p_resp_code := '21';
           p_err_msg  := 'Error while selecting begining from stmt sav  amount ...'|| SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;


        end;

       -- ending balance for the period..
             BEGIN
               /* Commented for FSS-1723
                 select  TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')
                 INTO P_ENDING_BAL
                  from  cms_interest_detl
                  where to_date(cid_calc_date) = v_lastdate_month
                  and cid_acct_no=p_svg_acct_no
                  and cid_inst_code=p_inst_code;
                 */
         -- Added for FSS-1723
         --Modified for FSS-1830 & NCGPR-1534
                select to_char(s1.CSL_CLOSING_BALANCE,'99999999999999990.99') INTO P_ENDING_BAL
                from  CMS_STATEMENTS_LOG_VW s1
                where  s1.csl_acct_no = p_svg_acct_no AND s1.csl_inst_code = p_inst_code
                and s1.csl_ins_date =
                (select max(s2.csl_ins_date) from CMS_STATEMENTS_LOG_VW s2
                where  s2.csl_acct_no = p_svg_acct_no AND s2.csl_inst_code = p_inst_code
                and to_char(s2.csl_trans_date,'MMYYYY') = P_month_year
                ) and rownum=1;
         EXCEPTION WHEN NO_DATA_FOUND THEN

               BEGIN
                     /* Commented for FSS-1723
                     select TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')
                     INTO P_ENDING_BAL
                     from  cms_interest_detl_HIST
                     where to_date(cid_calc_date) = v_lastdate_month
                     and cid_acct_no=p_svg_acct_no
                     and cid_inst_code=p_inst_code;
                     */
             -- Added for FSS-1723
                      SELECT TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')  into P_ENDING_BAL
                      FROM CMS_INTEREST_DETL A
                      WHERE A.CID_ACCT_NO       =p_svg_acct_no and cid_inst_code=P_INST_CODE
                      AND A.CID_CALC_DATE=
                      (
                      SELECT  max(B.CID_CALC_DATE)
                      FROM CMS_INTEREST_DETL B
                      WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=P_INST_CODE
                      AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                      );

               EXCEPTION WHEN NO_DATA_FOUND THEN

                            BEGIN
                            /* commented for FSS-1723
                                  SELECT to_char(CAM_ACCT_BAL,'99999999999999990.99')
                                     INTO P_ENDING_BAL
                                     FROM cms_acct_mast
                                     WHERE cam_inst_code = p_inst_code
                                     AND cam_acct_no =p_svg_acct_no;
                                     */
                     -- Added for FSS-1723
                                      SELECT TO_CHAR (CID_CLOSE_BALANCE - CID_INTEREST_AMOUNT,'99999999999999990.99')  into P_ENDING_BAL
                                      FROM CMS_INTEREST_DETL_HIST A
                                      WHERE A.CID_ACCT_NO       =p_svg_acct_no and cid_inst_code=P_INST_CODE
                                      AND A.CID_CALC_DATE=
                                      (
                                      SELECT  max(B.CID_CALC_DATE)
                                      FROM CMS_INTEREST_DETL_HIST B
                                      WHERE B.CID_ACCT_NO = p_svg_acct_no and cid_inst_code=P_INST_CODE
                                      AND to_char(CID_CALC_DATE,'MMYYYY') = P_month_year
                                      );

                             EXCEPTION
                              when no_data_found then

                             P_ENDING_BAL :='0.00';

                 WHEN OTHERS THEN

                              p_resp_code := '21';
                              p_err_msg  := 'Error while selecting from acct mast ...'|| SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;

                           END;

              WHEN OTHERS THEN

              p_resp_code := '21';
              p_err_msg  := 'Error while selecting ending bal  amount from hist  ...'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;


              END;

         WHEN OTHERS THEN
              p_resp_code := '21';
              p_err_msg  := 'Error while selecting ending bal  amount from interest detl '|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;


         END;

      -- Interest rate
   /* Commented for FSS-1830 & NCGPR-1534
        BEGIN
             SELECT  cdp_param_value
                INTO p_interest_rate
                FROM cms_dfg_param
               WHERE cdp_inst_code = p_inst_code
               and  cdp_prod_code = v_prod_code
               and cdp_param_key = 'Saving account Interest rate';

           EXCEPTION WHEN NO_DATA_FOUND   THEN

                        p_resp_code := '21';
                        p_err_msg  := 'Saving acct Interest rate not found for product '||v_prod_code||' and instcode '||p_inst_code;
                        RAISE exp_reject_record;

           WHEN OTHERS THEN
                        p_resp_code := '21';
                        p_err_msg  := 'Error while selecting DFG parameter for Interest rate--'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;

           END;
           */

      end if;



   IF p_mini_stat_res IS NOT NULL
   THEN
      p_mini_stat_res := SUBSTR (p_mini_stat_res, 5);
   ELSE
      p_mini_stat_res := ' ';
   END IF;

   p_resp_code := '1';

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = p_resp_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';
         p_err_msg := 'Responce code is not found ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         p_err_msg :=
               'Error while selecting cms_response_mast '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

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
      UPDATE transactionlog
         SET --response_id = p_resp_code,  --Commented by Pankaj S. during DFCCSD-70(Review) chnages
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             error_msg = p_err_msg,
             ANI=P_ANI, --Added for mantis id 0012275(FSS-1144)
             DNI=P_DNI --Added for mantis id 0012275(FSS-1144)
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msgtype
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
    else
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET --response_id = p_resp_code,  --Commented by Pankaj S. during DFCCSD-70(Review) chnages
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             error_msg = p_err_msg,
             ANI=P_ANI, --Added for mantis id 0012275(FSS-1144)
             DNI=P_DNI --Added for mantis id 0012275(FSS-1144)
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msgtype
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;     
end if;
      --Sn Uncommented by Pankaj S. during DFCCSD-70(Review) changes
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         p_err_msg := 'transactionlog is not updated ';
         RAISE exp_reject_record;
      END IF;
      --En Uncommented by Pankaj S. during DFCCSD-70(Review) changes
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_err_msg :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   v_savepoint := v_savepoint + 1;


EXCEPTION
   WHEN exp_auth_reject_record
   THEN                                      --Added by Ramesh.A on 22/05/2012
      --ROLLBACK TO v_savepoint;      Commented by Besky on 06-nov-12
    NULL;

   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_savepoint;
      v_resp_cde:=p_resp_code; --added by Pankaj S. for 10871 (to logging proper response_id in txnlog)
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_err_msg :=
                  'Error while selecting cms_response_mast 1'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
      END;

        --Sn Added by Pankaj S. for DFCCSD-70 changes
        BEGIN
           SELECT cam_acct_no,cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_number,v_avail_bal, v_ledger_bal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code
              AND cam_acct_no =
                     (SELECT cap_acct_no
                        FROM cms_appl_pan
                       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code);
        EXCEPTION
           WHEN OTHERS THEN
              v_avail_bal := 0;
              v_ledger_bal := 0;
        END;
        --En Added by Pankaj S. for DFCCSD-70 changes

     --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc
           INTO v_dr_cr_flag,  v_txn_type,v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat
          INTO v_prod_code, v_card_type, v_cardstat
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      --Below block commented by Pankaj S. during DFCCSD-70 changes
      /*BEGIN
        SELECT cam_type_code
          INTO v_acct_type
          FROM cms_acct_mast
         WHERE cam_inst_code = p_inst_code AND cam_acct_no=p_svg_acct_no;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;*/
      --En added by Pankaj S. for 10871

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type, txn_mode, txn_status,
                      response_code, business_date, business_time,
                      customer_card_no, instcode, customer_card_no_encr,
                      error_msg, ipaddress, ani, dni,TRANS_DESC,response_id,
                      --Sn added by Pankaj S. for 10871
                      cr_dr_flag,customer_acct_no,acct_type,productid,categoryid,cardstatus,time_stamp,
                      --En added by Pankaj S. for 10871
                      acct_balance,ledger_balance  --Added by Pankaj S. for DFCCSD-70 changes
                     )
              VALUES (p_msgtype, p_rrn, p_delivery_channel, SYSDATE,
                      p_txn_code, V_TXN_TYPE, p_txn_mode, 'F',
                      p_resp_code, p_tran_date, p_tran_time,
                      v_hash_pan, p_inst_code, v_encr_pan,
                      p_err_msg, p_ipaddress, p_ani, p_dni,V_TRANS_DESC,v_resp_cde, -- p_resp_code, --modified by Pankaj S. for 10871(to logging proper resp id)
                      --Sn added by Pankaj S. for 10871
                      v_dr_cr_flag,v_acct_number,--p_svg_acct_no,  --modified by Pankaj S. for DFCCSD-70 changes
                      v_acct_type,v_prod_code,v_card_type,v_cardstat,systimestamp,
                      --En added by Pankaj S. for 10871
                      v_avail_bal, v_ledger_bal --Added by Pankaj S. for DFCCSD-70 changes
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            p_err_msg := 'Error while inserting TRANSACTIONLOG 1' || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type,
                      ctd_cust_acct_number --Added by Pankaj S. for DFCCSD-70
                     )
              VALUES (p_delivery_channel, p_txn_code, V_TXN_TYPE,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, 'E',
                      p_err_msg, p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan, p_msgtype,
                      v_acct_number--Added by Pankaj S. for DFCCSD-70
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_err_msg :=
                  'Error while inserting cms_transaction_log_dt l'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
            RETURN;
      END;
   WHEN OTHERS
   THEN
      p_resp_code := '21';
      p_err_msg := 'Main Exception ' || SUBSTR (SQLERRM, 1, 200);
      ROLLBACK TO v_savepoint;
      v_resp_cde:=p_resp_code; --added by Pankaj S. for 10871 (to logging proper response_id in txnlog)
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_err_msg :=
                  'Error while selecting cms_response_mast 1'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
      END;

      --Sn Added by Pankaj S. for DFCCSD-70 changes
        BEGIN
           SELECT cam_acct_no,cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_number,v_avail_bal, v_ledger_bal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code
              AND cam_acct_no =
                     (SELECT cap_acct_no
                        FROM cms_appl_pan
                       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code);
        EXCEPTION
           WHEN OTHERS THEN
              v_avail_bal := 0;
              v_ledger_bal := 0;
        END;
        --En Added by Pankaj S. for DFCCSD-70 changes


      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc
           INTO v_dr_cr_flag,  v_txn_type,v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat
          INTO v_prod_code, v_card_type, v_cardstat
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      --Below block commented by Pankaj S. during DFCCSD-70
      /*BEGIN
        SELECT cam_type_code
          INTO v_acct_type
          FROM cms_acct_mast
         WHERE cam_inst_code = p_inst_code AND cam_acct_no=p_svg_acct_no;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;*/
      --En added by Pankaj S. for 10871

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type, txn_mode, txn_status,
                      response_code, business_date, business_time,
                      customer_card_no, instcode, customer_card_no_encr,
                      error_msg, ipaddress, ani, dni,trans_desc,response_id,
                      --Sn added by Pankaj S. for 10871
                      cr_dr_flag,customer_acct_no,acct_type,productid,categoryid,cardstatus,time_stamp,
                      --En added by Pankaj S. for 10871
                      acct_balance,ledger_balance  --Added by Pankaj S. for DFCCSD-70 changes
                     )
              VALUES (p_msgtype, p_rrn, p_delivery_channel, SYSDATE,
                      p_txn_code, V_TXN_TYPE, p_txn_mode, 'F',
                      p_resp_code, p_tran_date, p_tran_time,
                      v_hash_pan, p_inst_code, v_encr_pan,
                      p_err_msg, p_ipaddress, p_ani, p_dni,V_TRANS_DESC,v_resp_cde, -- p_resp_code, --modified by Pankaj S. for 10871(to logging proper resp id)
                      --Sn added by Pankaj S. for 10871
                      v_dr_cr_flag,v_acct_number,--p_svg_acct_no,  --modified by Pankaj S. for DFCCSD-70 changes
                      v_acct_type,v_prod_code,v_card_type,v_cardstat,systimestamp,
                      --En added by Pankaj S. for 10871
                      v_avail_bal, v_ledger_bal --Added by Pankaj S. for DFCCSD-70 changes
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            p_err_msg :=
                  'Error while inserting TRANSACTIONLOG 2'
               || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type,
                      ctd_cust_acct_number--Added by Pankaj S. for DFCCSD-70
                     )
              VALUES (p_delivery_channel, p_txn_code, V_TXN_TYPE,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, 'E',
                      p_err_msg, p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan, p_msgtype,
                      v_acct_number--Added by Pankaj S. for DFCCSD-70
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_err_msg :=
                  'Error while inserting cms_transaction_log_dt 2'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
            RETURN;
      END;
END;
/
show error