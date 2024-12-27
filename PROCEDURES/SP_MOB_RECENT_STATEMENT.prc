CREATE OR REPLACE PROCEDURE VMSCMS.SP_MOB_RECENT_STATEMENT (
   p_inst_code           IN       NUMBER,
   p_msg                 IN       VARCHAR2,
   p_rrn                          VARCHAR2,
   p_delivery_channel             VARCHAR2,
   p_term_id                      VARCHAR2,
   p_txn_code                     VARCHAR2,
   p_txn_mode                     VARCHAR2,
   p_tran_date                    VARCHAR2,
   p_tran_time                    VARCHAR2,
   p_pan_code                     VARCHAR2,
   p_bank_code                    VARCHAR2,
   p_txn_amt                      NUMBER,
   p_mcc_code                     VARCHAR2,
   p_curr_code                    VARCHAR2,
   p_consodium_code      IN       VARCHAR2,
   p_partner_code        IN       VARCHAR2,
   p_mbr_numb            IN       VARCHAR2,
   p_preauth_expperiod   IN       VARCHAR2,
   p_rvsl_code           IN       NUMBER,
   p_tran_cnt            IN       NUMBER,
   p_month_year          IN       VARCHAR2,
   p_acct_no             IN       VARCHAR2,
   -- Added on 21-Jan-2013 for Mobile API changes Defect 10014
   P_MOB_NO             IN        VARCHAR2, -- Added by RAVI N on 12-aug-2013 For FSS-1144
   P_DEVICE_ID          IN        VARCHAR2, -- Added by RAVI N on 12-aug-2013 For FSS-1144
   P_Trans_Type         IN        VARCHAR2, --added for fer-67
   P_FROMDATE           IN        VARCHAR2, --added for fer-67
   P_TODATE             IN        VARCHAR2, --added for fer-67
   P_FROMAMNT           IN        VARCHAR2, --added for fer-67
   P_TOAMNT             IN        VARCHAR2,  --added for fer-67
   p_txn_cnt            IN        NUMBER,  --added by Pankaj S. for FSS-1959
   p_auth_id             OUT      VARCHAR2,
   p_resp_code           OUT      VARCHAR2,
   p_resmsg              OUT      CLOB,
   p_pre_auth_hold_amt   OUT      VARCHAR2,
   p_avail_bal_amt       OUT      VARCHAR2,
   p_pre_auth_det        OUT      CLOB,
--   p_posting_cnt         OUT      NUMBER , --Added for FWR-42
--   p_tot_dr_amt          OUT      VARCHAR2, --Added for FWR-42
--   p_tot_cr_amt          OUT      VARCHAR2,--Added for FWR-42
   p_pending_txn_count   OUT      VARCHAR2
)
IS
/*************************************************************************************************
      * Created Date     :  22-Aug-2012
      * Created By       :  B.Dhinakaran
      * PURPOSE          :  Transaction detail report
      * Modified By      :  Pankaj S.
      * Modified Date    :  28-JAN-13
      * Modified For     :  Defect ID 0010163
      * Modified Reason  :  To return time in exact format in statement generation
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  28-JAN-13
      * Build Number     :  CMS3.5.1_RI0023.1_B0007

      * Modified By      :  Sagar m.
      * Modified Date    :  12-Mar-13
      * Modified For     :  MOB-23
      * Modified Reason  :  Records are displayed using business date instead of transaction date
                            also same are ordered by ins_date instead of transaction date
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  12-Mar-13
      * Build Number     :  CMS3.5.1_RI0024_B0001

      * Modified By      : Sagar M.
      * Modified Date    : 25-Mar-2013
      * Modified For     : 1) Defect 0010613
                           2) Defect 10657
                           3) MOB-24
      * Modified Reason  : 1) Validating input card number with input Account number
                           2) Time format value change from hhmiss to hh24miss
                           3) DR/CR Flag (CSL_TRANS_TYPE) added in reponse message
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Mar-2013
      * Build Number     : RI0024_B0008

      * Modified by      :  Pankaj S.
      * Modified Reason  :  10871
      * Modified Date    :  16-Apr-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :  RI0024.1_B0013

      * Modified by      :  Sivakumar A.
      * Modified For     :  JIRA MOB-33
      * Modified Reason  :  To show last 30 transactions instead of current month transactions
      * Modified Date    :  6-Aug-2013.
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  6-Aug-2013
      * Build Number     :  RI0024.4_B0001

     * modified by       :  RAVI N
     * modified Date     :  12-AUG-13
     * modified reason   :  Adding new Input [P_MOB_NO,P_DEVICE_ID] parameters and logging cms_transaction_log_dtl
     * modified reason   :  FSS-1144
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  29-AUG-13
     * Build Number      :  RI0024.4_B0006

     * modified by       :  RAVI N
     * modified Date     :  21-NOV-13
     * modified reason   :  Fee amount format changing 0.00 instead .00
     * modified reason   :  0127445
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  05/DEC/2013
     * Build Number      :  RI0024.7_B0001

     * modified by       :  Pankaj S.
     * modified Date     :  10-Jan-2014
     * modified reason   :  FWR-42
     * modified reason   :  Enhancements in CHW, IVR null Statements to include Pending and Decline Transactions
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  10-Jan-2014
     * Build Number      :  RI0024.7_B0003

     * modified by       :  Pankaj S.
     * modified Date     :  22-Jan-14
     * modified reason   :  Performance Issue in Mobile View Account Details(02) transaction
     * modified reason   :  FSS-1412
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  22-Jan-2014
     * Build Number      :  RI0027_B0004 (RI0024.6.2.3_B0001 Changes merged)

     * modified by       :  Sai Prasad
     * modified Date     :  27-Jan-14
     * modified reason   :  Non-Financical Transactions with fee is not shown in statement
     * modified reason   :  Mantis ID:0013572
     * Reviewer          :  Dhiraj
     * Reviewed Date     :
     * Build Number      :  RI0027_B0005

     * modified by       :  MageshKumar S
     * modified Date     :  31-Jan-14
     * modified reason   :  FWR-42 Removal
     * modified reason   :  FWR-42
     * Reviewer          :  Dhiraj
     * Reviewed Date     :
     * Build Number      :  RI0027_B0005

     * modified by       :  MageshKumar S
     * modified Date     :  06-Feb-14
     * modified reason   :  0013611
     * modified reason   :  Mobile View account details doesn't display OLS pre auth transactions
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  06-Feb-14
     * Build Number      :  RI0027.1_B0001


    * modified by       : RAVI N
    * modified Date     : 14-02-14
    * modified reason   : MVHOST-848
    * modified reason   : Merchant name changes [if merchane name null display Delchannel_Desc]
    * Reviewer          : Dhiraj
    * Reviewed Date     : 14-02-2014
    * Build Number      : RI0027.1_B0002

     * modified by       : MageshKumar S
     * modified Date     : 20-May-14
     * modified for         : FSS-1621
     * modified reason   : integrated changes of RI0027.0.1.1:Performance Issue in Mobile View Account Details(02) transaction
     * Reviewer          : spankaj
     * Reviewed Date     : 21-May-2013
     * Build Number      : RI0027.2.1_B0001

       * Modified by       : Abdul Hameed M.A
    * Modified Date     : 10-July-14
    * Modified for      : FSS 837
    * Modified reason   : To return the sum of completion fee and hold amt in the preauth hold amount
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0003

    * Modified by       : Siva Kumar M
    * Modified Date     : 08-Aug-14
    * Modified for      : FWr-67
    * Modified reason   : Transaction history filter
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.1_B0002

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 25-Sep-14
    * Modified For      : MVHOST 987
    * Reviewer          :
    * Build Number      : RI0027.4_B0001

    * Modified by       : Pankaj S.
    * Modified Date     : 25-Nov-2014
    * Modified For      : FSS-1959
    * Reviewer          :
    * Build Number      : RI0027.4.2.2_B0005

    * Modified by       : Pankaj S.
    * Modified Date     : 27-Nov-2014
    * Modified For      : Mantis-15915
    * Reviewer          :
    * Build Number      : RI0027.4.2.2_B0006

    * Modified by       : MAGESHKUMAR S.
    * Modified Date     : 25-FEB-2015
    * Modified For      : FSS-2086 (Integration of Fee Desc Change from 2.4.3.3)
    * Reviewer          : PANKAJ
    * Build Number      : RI0027.5_B0009

    * Modified by       : Sai Prasad
    * Modified Date     : 01-Mar-15
    * Modified For      : DFCTNM-3
    * Reviewer          : PANKAJ
    * Build Number      : RI0027.5_B0011

    * Modified by       : A.Sivakaminathan
    * Modified Date     : 15-Sep-2015
    * Modified For      : 3.2 Person to Person (P2P) ACH Correction
    * Reviewer          : Saravanankumar
    * Build Number      : VMSGPRHOST_3.2

    * Modified by       : Abdul Hameed M.A.
    * Modified Date     : 21-Sep-2015
    * Modified For      : Display Transaction Flex  Descriptions in statements
    * Reviewer          : Saravanankumar
    * Build Number      : VMSGPRHOST_3.2

    * Modified by      : Ramesh A
    * Modified Date    : 08-Feb-2016
    * PURPOSE          : DFCTNM-108
    * Review           : Saravana
    * Build Number     : 3.2.4

    * Modified by      : Sai Prasad
    * Modified Date    : 23-Mar-2016
    * PURPOSE          : Mantis - 0016327
    * Review           : Saravana
    * Build Number     : VMSGPRHOST_4.0

    * Modified by      : Pankaj S.
    * Modified Date    : 12/Sep/2016
    * Purpose          : MVHOST-1345
    * Review           : Saravana
    * Build Number     : VMSGPRHOST_4.9

    * Modified by       : Ramesh A
    * Modified Date     : 20-Sep-2016
    * Modified For      : FSS-4353 NACHA Compliance Issue for ACH Description
    * Reviewer          : Saravanankumar
    * Build Number      : VMSGPRHOSTCSD_4.9
    
      * Modified by      : Saravana
    * Modified Date    : 27/Feb/2017
    * PURPOSE          : FSS-4366
    * Review            : Pankaj S 
    * Build Number     : VMSGPRHOST_17.02 
	
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
     
     * Modified by       : UBaidur Rahman.H
     * Modified Date     : 26-Oct-21
     * Modified For      : VMS-4379- Remove Account Statement Txn log logging into Transactionlog
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R53B3
	 
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
******************************************************************************************************/

   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_rrn_count              NUMBER;
   v_errmsg                 VARCHAR2 (500);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_txn_type               transactionlog.txn_type%TYPE;
   v_cust_name              cms_cust_mast.ccm_user_name%TYPE;
   v_hash_password          VARCHAR2 (100);
   v_auth_id                transactionlog.auth_id%TYPE;
   v_cardstat               VARCHAR2 (5);
   exp_auth_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_capture_date           DATE;
   v_first                  VARCHAR (10);
   v_encrypt                VARCHAR (30);
   v_last                   VARCHAR (10);
   v_length                 NUMBER (30);
   v_masked_pan             VARCHAR (40);
   v_saving_acct_dtl        VARCHAR2 (40);
   v_spending_acct_dtl      VARCHAR2 (40);
   v_spending_type_code     VARCHAR2 (1)                          DEFAULT '1';
   v_saving_type_code       VARCHAR2 (1)                          DEFAULT '2';
   v_date                   DATE;
   v_resp_cde               VARCHAR2 (5);
  -- v_mon_year_temp          VARCHAR2 (6);       --commented on 6-Aug-2013 for MOB-33
   v_acct_balance           NUMBER;
   v_mini_stat_val          CLOB;
   v_mini_stat_res          CLOB;
   v_pre_auth_det_val       CLOB;
   v_pre_auth_det           CLOB;
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   --Added for transaction detail report on 210812
   v_spending               VARCHAR2 (1);
   -- Added on 21-Jan-2013 for mobile API changes Defect 10014
   v_saving                 VARCHAR2 (1);
   -- Added on 21-Jan-2013 for mobile API changes Defect 10014
   v_cat_type_code          cms_acct_type.cat_type_code%TYPE;

   v_cap_acct_no            cms_appl_pan.cap_acct_no%type;   -- Added for Defect 0010613 on 19-Mar-2013
   v_cap_cust_code          cms_appl_pan.cap_cust_code%type; -- Added for Defect 0010613 on 19-Mar-2013
   v_cap_acct_id            cms_appl_pan.cap_acct_id%type;   -- Added for Defect 0010613 on 19-Mar-2013
   v_cam_acct_no            cms_acct_mast.cam_acct_no%type;  -- Added for Defect 0010613 on 19-Mar-2013
   --Sn added by Pankaj S. for 10871
   v_prod_code              cms_appl_pan.cap_prod_code%type;
   v_card_type              cms_appl_pan.cap_card_type%type;
   --En added by Pankaj S. for 10871
  V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  for regarding FSS-1144
  v_timestamp  timestamp;
  v_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;

  --Sn Added for FWR-42
--  v_tran_amount        cms_statements_log.csl_trans_amount%TYPE;
--  v_trantype          cms_statements_log.csl_trans_type%TYPE;
--  v_response_code      transactionlog.response_code%TYPE;
  --En Added for FWR-42
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991

   CURSOR c_mob_mini_tran (
      p_acct_no      cms_acct_mast.cam_acct_no%TYPE,
      P_FROMDATE     varchar2,
      P_TODATE       varchar2,
      P_FROMAMNT     varchar2,
      P_TOAMNT       varchar2
      -- p_month_year   VARCHAR2     --commented on 6-Aug-2013 for MOB-33
   )
   IS
      --------------------------------------------------------------------------------
   --Sn Modified by Pankaj S. for FSS-1959
   --------------------------------------------------------------------------------
  --SN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
   SELECT data1||NVL(TRIM(txnamt),0)||data2 --*
  FROM (SELECT      TRIM(CASE WHEN INSTR(upper(sl.csl_trans_narrration),'FIXED')>0 THEN
                      TO_CHAR ((SELECT SUM(csl_trans_amount) FROM VMSCMS.CMS_STATEMENTS_LOG_VW            --Added for VMS-5739/FSP-991
                                 WHERE csl_rrn = sl.csl_rrn AND csl_auth_id = sl.csl_auth_id
                                   AND csl_acct_no = sl.csl_acct_no AND csl_inst_code = sl.csl_inst_code
                                   AND txn_fee_flag='Y'),'99999999999999990.99')
                         ELSE TO_CHAR (sl.csl_trans_amount, '99999999999999990.99') END)txnamt,
                    CASE WHEN INSTR(upper(sl.csl_trans_narrration),'PERCENTAGE')>0 THEN 1 ELSE 0 END rnum,
                    TO_CHAR (TO_DATE (sl.csl_business_date, 'YYYYMMDD'),'MMDDYYYY')
                 || ' ~ '
                 || TO_CHAR (TO_DATE (sl.csl_business_time, 'HH24MISS'),'HH24MISS')
                 || ' ~ '
                 || (CASE
                        WHEN ( csl_delivery_channel = '11' )
                        THEN
                           REGEXP_REPLACE(NVL((DECODE(NVL(COMPANYNAME,''),'','','/'||COMPANYNAME) || DECODE(NVL(COMPENTRYDESC,''),'','','/'||COMPENTRYDESC) || DECODE(NVL(INDNAME,''),'','','/'||INDIDNUM||' to '||INDNAME)),'Direct Deposit'),'/','',1,1)
                        ELSE
                        NVL (sl.csl_merchant_name,
                         DECODE (TRIM (dm.cdm_channel_desc),
                                 'ATM', 'ATM',
                                 'POS', 'Retail Merchant',
                                 'IVR', 'IVR Transfer',
                                 'CHW', 'Card Holder website',
                                 'ACH', 'Direct Deposit',
                                 'MOB', 'Mobile Transfer',
                                 'CSR', 'Customer Service',
                                 'System'
                                )
                        )
                     END)
                 || ' ~ ' data1,
                 --|| TRIM (TO_CHAR (sl.csl_trans_amount, '999999999999999990.99'))
                 --||
                 ' ~ '
                 || sl.csl_trans_type
                 || ' ~ '
                 || 'Posted'
                 -- SN - Added for FSS-2086
                 || ' ~ '
                 ||
		 CASE 
		 WHEN csl_delivery_channel IN ('01','02') AND TXN_FEE_FLAG = 'N' 
			   THEN DECODE(nvl(regexp_instr(csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,TRANS_DESC,
                          'RVSL-'||TRANS_DESC)
			  ||'/'||DECODE(nvl(merchant_name,CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(merchant_name,CSL_MERCHANT_NAME)
                                                                                                             || '/'
                                                                                                             || terminal_id
                                                                                                             || '/'
                                                                                                             || merchant_street
                                                                                                             || '/'
                                                                                                             || merchant_city
                                                                                                             || '/'
                                                                                                             || merchant_state
                                                                                                             || '/'
                                                                                                             || preauthamount
                                                                                                             || '/'
                                                                                                             ||business_date
                                                                                                             ||'/'
                                                                                                             ||auth_id)
		  ELSE											     
                   DECODE (
                        NVL (REVERSAL_CODE, '0'),
                        '0', DECODE (
                                   sl.TXN_FEE_FLAG,
                                   'Y',
                                  -- TRIM (UPPER (SL.CSL_TRANS_NARRRATION)), --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                                   replace(TRIM(UPPER(substr(SL.CSL_TRANS_NARRRATION,0,decode(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,length(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), --Added for DFCTNM-108 on 08/02/16 (3.2.4)
                                  -- TM.ctm_tran_desc)
                                /*  case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_tran_desc end*/  decode(upper(trim(nvl(trans_desc,tm.CTM_TRAN_DESC))),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc))
                                                          ,
                        DECODE (
                            SL.TXN_FEE_FLAG,
                            'Y', replace(TRIM(UPPER(substr(SL.CSL_TRANS_NARRRATION,0,decode(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,length(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''),
                            'RVSL-' || --TM.CTM_TRAN_DESC
                           /* case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_tran_desc end*/  decode(upper(trim(nvl(trans_desc,tm.CTM_TRAN_DESC))),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc)))
                || (CASE
                          when CLAWBACK_INDICATOR = 'Y'
                          then
                             -- ' - CLAWBACK FEE' --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                           (select UPPER(DECODE(CPC_CLAWBACK_DESC,null,'',' - '|| CPC_CLAWBACK_DESC))||rtrim(substr(SL.CSL_TRANS_NARRRATION,instr(SL.CSL_TRANS_NARRRATION,' - ',-1))) from cms_prod_cattype where CPC_PROD_CODE=V_PROD_CODE AND cpc_card_type = v_card_type and CPC_INST_CODE=p_inst_code) --Added for DFCTNM-108 on 08/02/16 (3.2.4)
                          ELSE
                              DECODE (sl.TXN_FEE_FLAG, 'Y', ' - FEE')
                      END) END data2
                  -- EN - Added for FSS-2086   --Added for VMS-5739/FSP-991
            FROM VMSCMS.CMS_STATEMENTS_LOG_VW sl, cms_delchannel_mast dm,CMS_TRANSACTION_MAST TM,VMSCMS.TRANSACTIONLOG_VW -- Added for FSS-2086         --Added for VMS-5739/FSP-991
           WHERE sl.csl_acct_no = p_acct_no
             AND sl.csl_inst_code = p_inst_code
             --AND dm.cdm_inst_code = sl.csl_inst_code
             AND dm.cdm_channel_code = sl.csl_delivery_channel
             -- SN - Added for FSS-2086
             AND dm.CDM_INST_CODE = sl.CSL_INST_CODE
             AND TM.CTM_DELIVERY_CHANNEL = sl.CSL_DELIVERY_CHANNEL
             AND TM.CTM_TRAN_CODE = sl.CSL_TXN_CODE
             AND CSL_TRANS_DATE IS NOT NULL
             AND TM.CTM_INST_CODE = sl.CSL_INST_CODE
             AND sl.CSL_INST_CODE = 1
             AND sl.CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL(+)
             AND sl.CSL_TXN_CODE = TXN_CODE(+)
             AND sl.CSL_RRN = RRN(+)
             AND sl.CSL_PAN_NO = CUSTOMER_CARD_NO(+)
             AND sl.CSL_AUTH_ID = AUTH_ID(+)
             AND sl.CSL_INST_CODE = INSTCODE(+)
             -- EN - Added for FSS-2086
             AND ((p_trans_type = 'B' AND sl.csl_trans_type IN ('CR', 'DR')) OR sl.csl_trans_type = p_trans_type)
             --AND ((p_fromdate IS NOT NULL AND sl.csl_business_date BETWEEN p_fromdate AND p_todate) OR p_fromdate IS NULL)
			 AND ((p_fromdate IS NOT NULL AND sl.csl_business_date BETWEEN TO_CHAR (TO_DATE (p_fromdate, 'MMDDYYYY'),'YYYYMMDD') AND TO_CHAR (TO_DATE (p_todate, 'MMDDYYYY'),'YYYYMMDD')) OR p_fromdate IS NULL)-- MODIFIED FOR MANTIS:16046
             AND ((p_fromamnt IS NOT NULL AND sl.csl_trans_amount BETWEEN p_fromamnt AND p_toamnt) OR p_fromamnt IS NULL)
             AND ((p_txn_cnt = 2 AND sl.csl_ins_date BETWEEN trunc(sysdate-30) AND sysdate) OR p_txn_cnt <> 2)
        ORDER BY csl_ins_date DESC)WHERE rnum=0;
  --EN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.

   CURSOR c_mob_mini_tran_1 (
      p_acct_no      cms_acct_mast.cam_acct_no%TYPE,
      P_FROMDATE     varchar2,
      P_TODATE       varchar2,
      P_FROMAMNT     varchar2,
      P_TOAMNT       varchar2
      --p_month_year   VARCHAR2
   )IS
    WITH stmt_dtls AS
         (select * from (SELECT sl.csl_inst_code,dm.cdm_channel_desc,sl.csl_acct_no,sl.csl_rrn,sl.csl_txn_code,sl.csl_delivery_channel,
                                sl.csl_auth_id,sl.csl_business_date,sl.csl_business_time,sl.csl_ins_date,sl.CSL_PAN_NO -- Added for FSS-2086
              FROM VMSCMS.CMS_STATEMENTS_LOG_VW sl, cms_delchannel_mast dm          --Added for VMS-5739/FSP-991    
             WHERE sl.csl_acct_no = p_acct_no
               AND sl.csl_inst_code = p_inst_code
               --AND dm.cdm_inst_code = sl.csl_inst_code
               AND dm.cdm_channel_code=sl.csl_delivery_channel
               AND (sl.txn_fee_flag = 'N' OR (sl.txn_fee_flag = 'Y' AND 1=(select count(*) from VMSCMS.CMS_STATEMENTS_LOG_VW sl2    --Added for VMS-5739/FSP-991
                                                                               where sl2.csl_acct_no = sl.csl_acct_no AND sl2.csl_inst_code = sl.csl_inst_code
                                                                                AND sl2.csl_rrn = sl.csl_rrn  AND sl2.csl_txn_code = sl.csl_txn_code
                                                                               AND sl2.csl_delivery_channel = sl.csl_delivery_channel --AND sl2.csl_auth_id = sl.csl_auth_id
                                                                              AND sl2.csl_business_date = sl.csl_business_date AND sl2.csl_business_time = sl.csl_business_time )))
               AND ((p_trans_type = 'B' AND sl.csl_trans_type IN ('CR', 'DR')) OR sl.csl_trans_type = p_trans_type)
               --AND ((p_fromdate IS NOT NULL AND sl.csl_business_date BETWEEN p_fromdate AND p_todate) OR p_fromdate IS NULL)
               AND ((p_fromdate IS NOT NULL AND sl.csl_business_date BETWEEN TO_CHAR (TO_DATE (p_fromdate, 'MMDDYYYY'),'YYYYMMDD') AND TO_CHAR (TO_DATE (p_todate, 'MMDDYYYY'),'YYYYMMDD')) OR p_fromdate IS NULL) -- MODIFIED FOR MANTIS:16046
               AND ((p_fromamnt IS NOT NULL AND sl.csl_trans_amount BETWEEN p_fromamnt AND p_toamnt) OR p_fromamnt IS NULL)
          ORDER BY sl.csl_ins_date DESC)WHERE ROWNUM <= 30)
    --SN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
    SELECT data1||NVL(TRIM(txnamt),0)||data2
    FROM
    (SELECT TRIM(CASE WHEN INSTR(upper(sl1.csl_trans_narrration),'FIXED')>0 THEN
                      TO_CHAR ((SELECT SUM(csl_trans_amount) FROM VMSCMS.CMS_STATEMENTS_LOG_VW        --Added for VMS-5739/FSP-991
                                 WHERE csl_rrn = sl1.csl_rrn AND csl_auth_id = sl1.csl_auth_id
                                   AND csl_acct_no = sl1.csl_acct_no AND csl_inst_code = sl1.csl_inst_code
                                   AND txn_fee_flag='Y'),'99999999999999990.99')
                         ELSE TO_CHAR (sl1.csl_trans_amount, '99999999999999990.99') END)txnamt,
                    CASE WHEN INSTR(upper(sl1.csl_trans_narrration),'PERCENTAGE')>0 THEN 1 ELSE 0 END rnum,
              TO_CHAR (TO_DATE (sl1.csl_business_date, 'YYYYMMDD'), 'MMDDYYYY')
           || ' ~ '
           || TO_CHAR (TO_DATE (sl1.csl_business_time, 'HH24MISS'), 'HH24MISS')
           || ' ~ '
           || (CASE
                WHEN ( sl1.csl_delivery_channel = '11' )
                  THEN
                      REGEXP_REPLACE(NVL((DECODE(NVL(COMPANYNAME,''),'','','/'||COMPANYNAME) || DECODE(NVL(COMPENTRYDESC,''),'','','/'||COMPENTRYDESC) || DECODE(NVL(INDNAME,''),'','','/'||INDIDNUM||' to '||INDNAME)),'Direct Deposit'),'/','',1,1)
                  ELSE
                  NVL (sl1.csl_merchant_name,
                  DECODE (TRIM (stmt_dtls.cdm_channel_desc),
                           'ATM', 'ATM',
                           'POS', 'Retail Merchant',
                           'IVR', 'IVR Transfer',
                           'CHW', 'Card Holder website',
                           'ACH', 'Direct Deposit',
                           'MOB', 'Mobile Transfer',
                           'CSR', 'Customer Service',
                           'System'
                          )
                  )
               END)
           || ' ~ 'data1,
           --|| TRIM (TO_CHAR (sl1.csl_trans_amount, '999999999999999990.99'))
           --||
           ' ~ '
           || sl1.csl_trans_type
           || ' ~ '
           || 'Posted'
           -- SN - Added for FSS-2086
           || ' ~ '
           || 
	   CASE 
	   WHEN SL1.csl_delivery_channel IN ('01','02') AND SL1.TXN_FEE_FLAG = 'N' 
			   THEN DECODE(nvl(regexp_instr(SL1.csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,TRANS_DESC,
                          'RVSL-'||TRANS_DESC)
			  ||'/'||DECODE(nvl(merchant_name,SL1.CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(merchant_name,SL1.CSL_MERCHANT_NAME)
                                                                                                             || '/'
                                                                                                             || terminal_id
                                                                                                             || '/'
                                                                                                             || merchant_street
                                                                                                             || '/'
                                                                                                             || merchant_city
                                                                                                             || '/'
                                                                                                             || merchant_state
                                                                                                             || '/'
                                                                                                             || preauthamount
                                                                                                             || '/'
                                                                                                             ||business_date
                                                                                                             ||'/'
                                                                                                             ||auth_id)
	     ELSE
                   DECODE (
                        NVL (REVERSAL_CODE, '0'),
                        '0', DECODE (
                                   sl1.TXN_FEE_FLAG,
                                   'Y',
                                  -- TRIM ( UPPER (SL1.CSL_TRANS_NARRRATION)), --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                                   replace(TRIM(UPPER(substr(SL1.CSL_TRANS_NARRRATION,0,decode(instr(SL1.CSL_TRANS_NARRRATION,' - ',-1),0,length(SL1.CSL_TRANS_NARRRATION),instr(SL1.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), --Added for DFCTNM-108 on 08/02/16 (3.2.4)
                                   --TM.ctm_tran_desc)
                                 /*  case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_tran_desc end*/  decode(upper(trim(trans_desc)),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc))
                                                          ,
                        DECODE (
                            SL1.TXN_FEE_FLAG,
                            'Y', replace(TRIM(UPPER(substr(SL1.CSL_TRANS_NARRRATION,0,decode(instr(SL1.CSL_TRANS_NARRRATION,' - ',-1),0,length(SL1.CSL_TRANS_NARRRATION),instr(SL1.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''),
                            'RVSL-' || --TM.CTM_TRAN_DESC))
                          /*  case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_tran_desc end*/  decode(upper(trim(trans_desc)),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc)))
                || (CASE
                          WHEN clawback_indicator = 'Y'
                          then
                             -- ' - CLAWBACK FEE'  --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                              (select  UPPER(DECODE(CPC_CLAWBACK_DESC,null,'',' - '|| CPC_CLAWBACK_DESC))||rtrim(substr(SL1.CSL_TRANS_NARRRATION,instr(SL1.CSL_TRANS_NARRRATION,' - ',-1))) from cms_prod_cattype where cpc_prod_code=V_PROD_CODE AND  cpc_card_type = v_card_type and CPC_INST_CODE=p_inst_code) --Added for DFCTNM-108 on 08/02/16 (3.2.4)
                          ELSE
                              DECODE (sl1.TXN_FEE_FLAG, 'Y', ' - FEE')
                      END) END data2
          -- EN - Added for FSS-2086
      FROM VMSCMS.CMS_STATEMENTS_LOG_VW sl1, stmt_dtls,CMS_TRANSACTION_MAST TM,VMSCMS.TRANSACTIONLOG_VW -- Added for FSS-2086  --Added for VMS-5739/FSP-991
     WHERE sl1.csl_acct_no = stmt_dtls.csl_acct_no
       AND sl1.csl_inst_code = stmt_dtls.csl_inst_code
       AND sl1.csl_rrn = stmt_dtls.csl_rrn
       AND sl1.csl_txn_code = stmt_dtls.csl_txn_code
       AND sl1.csl_delivery_channel = stmt_dtls.csl_delivery_channel
       --AND sl1.csl_auth_id = stmt_dtls.csl_auth_id
       AND sl1.csl_business_date = stmt_dtls.csl_business_date
       AND sl1.csl_business_time = stmt_dtls.csl_business_time
       -- SN -Added for FSS-2086
       AND stmt_dtls.csl_delivery_channel = TM.CTM_DELIVERY_CHANNEL
       AND stmt_dtls.csl_txn_code = TM.CTM_TRAN_CODE
       AND stmt_dtls.csl_inst_code = TM.CTM_INST_CODE
       AND stmt_dtls.CSL_PAN_NO = CUSTOMER_CARD_NO(+)
       AND stmt_dtls.CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL(+)
       AND stmt_dtls.CSL_TXN_CODE = TXN_CODE(+)
       AND stmt_dtls.csl_rrn = RRN(+)
       AND stmt_dtls.CSL_AUTH_ID = AUTH_ID(+)
       AND stmt_dtls.CSL_INST_CODE = INSTCODE(+)
       -- EN -Added for FSS-2086
       order by sl1.csl_ins_date desc) WHERE rnum=0;
   --EN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
   /*--Sn Modified for FWR-42
   SELECT * FROM(                 -- added on 6-Aug-2013 for MOB-33
    SELECT TO_CHAR (to_date(csl_business_date,'YYYYMMDD'),'MMDDYYYY')  -- New query replaced on 12-Mar-2013 for MOB-23
    || ' ~ '
    || TO_CHAR (to_date(csl_business_time,'HH24MISS'), 'HH24MISS')     -- HHMISS to HH24MISS Chanegs made on 21-Mar-2013 for Defect 10657
    || ' ~ '
    || NVL(SL.CSL_MERCHANT_NAME,DECODE(TRIM(DM.CDM_CHANNEL_DESC),'ATM','ATM','POS','Retail Merchant','IVR','IVR Transfer',
           'CHW','Card Holder website','ACH','Direct Deposit','MOB','Mobile Transfer',
           'CSR','Customer Service','System'))  --Added on 14/02/14 for regarding  MVHOST-848 --Modified for MVHOST 987
    || ' ~ '
    || TRIM (TO_CHAR (csl_trans_amount, '999999999999999990.99'))    --Modified fee amount format for regarding Mantis:00127445
    || '~ '
    || csl_trans_type                                                  -- Added on 25-Mar-2013 for Defect MOB-24
    || '~ '
    || 'Posted'
    FROM cms_statements_log sl,CMS_DELCHANNEL_MAST DM
    WHERE csl_acct_no = p_acct_no
   -- AND TO_CHAR (csl_trans_date, 'MMYYYY') = p_month_year       -- Commented on 6-Aug-2013 for MOB-33
    AND csl_inst_code = p_inst_code
    AND DM.CDM_INST_CODE=sl.CSL_INST_CODE AND
    DM.CDM_CHANNEL_CODE=sl.CSL_DELIVERY_CHANNEL
     and ((P_Trans_Type='B' and  sl.CSL_TRANS_TYPE in ('CR','DR')) or sl.CSL_TRANS_TYPE = P_Trans_Type)
      and ((P_FROMDATE is not null and sl.CSL_BUSINESS_DATE between P_FROMDATE and P_TODATE) or P_FROMDATE is null )
     and ((P_FROMAMNT is not null and sl.csl_trans_amount between P_FROMAMNT and P_TOAMNT) or P_FROMAMNT is null )
     ORDER BY csl_ins_date DESC)

   WHERE ROWNUM <= 30;   */        --added on 6-Aug-2013 for MOB-33
   --------------------------------------------------------------------------------
   --Sn Modified by Pankaj S. for FSS-1959
   --------------------------------------------------------------------------------
    /*WITH txnlog AS
         (SELECT *
            FROM (SELECT   rrn, add_ins_date, response_code,
                           TRIM (TO_CHAR (NVL (amount, 0), '99999999999999990.99') ) amount,
                           txn_code, delivery_channel, customer_card_no, auth_id,
                           cr_dr_flag, instcode, mccode, trans_desc,
                           clawback_indicator, reversal_code,
                           cms_resp_desc error_msg
                      FROM transactionlog, cms_response_mast
                     WHERE instcode = p_inst_code
                       AND cms_inst_code = instcode
                       AND cms_delivery_channel = delivery_channel
                       AND cms_response_id = TO_NUMBER (response_id)
                       AND response_code NOT IN ('22', '43', '49', '89', '102')
                       AND ((cr_dr_flag <> 'NA')  OR ( (response_code ='00' and tranfee_amt > 0)  -- Added for Mantis ID:0013572
                                                  OR (delivery_channel = '03' AND txn_code IN ('38', '40'))
                                                  OR (delivery_channel = '07' AND txn_code = '12')
                                                  OR (delivery_channel = '10' AND txn_code = '21')))
                       AND customer_acct_no = p_acct_no
                  ORDER BY add_ins_date DESC)
           WHERE ROWNUM <= 30)
    SELECT t.response_code,
           CASE
              WHEN t.response_code <> '00' THEN
                   t.amount
              ELSE
                   TRIM (TO_CHAR (csl_trans_amount, '99999999999999990.99'))
           END amt,
           CASE
              WHEN t.response_code <> '00' THEN
                   t.cr_dr_flag
              ELSE
                   csl_trans_type
           END crdr_flag,
           CASE
              WHEN t.response_code <> '00'
                 THEN    TO_CHAR (t.add_ins_date, 'MM/DD/YYYY')
                      || ' ~ '
                      || t.cr_dr_flag
                      || ' ~ '
                      || t.amount
                      || ' ~ '
                      || t.trans_desc
                      || ' ~ '
                      || t.error_msg
                      || ' ~ '
                      || t.mccode
                      || ' ~ '
                      || t.delivery_channel
              ELSE    TO_CHAR (nvl(csl_trans_date,t.add_ins_date), 'MM/DD/YYYY')
                   || ' ~ '
                   || nvl(csl_trans_type,t.cr_dr_flag)
                   || ' ~ '
                   || TRIM (TO_CHAR (nvl(csl_trans_amount,t.amount), '99999999999999990.99'))
                   || ' ~ '
                   || DECODE (NVL (reversal_code, '0'),'0',  DECODE (TRIM (UPPER(t.trans_desc)),'WAIVED ' || tm.ctm_tran_desc ,TRIM (UPPER(t.trans_desc)),tm.ctm_tran_desc),'RVSL-' || tm.ctm_tran_desc)
                   || (CASE
                          WHEN clawback_indicator = 'Y'
                             THEN ' - CLAWBACK FEE'
                          ELSE DECODE (sl.txn_fee_flag,'Y', ' - FEE')
                       END
                      )
                   || ' ~ '
                   || ' '
                   || ' ~ '
                   || t.mccode
                   || ' ~ '
                   || nvl(sl.csl_delivery_channel, t.delivery_channel)
           END
      FROM cms_statements_log sl, cms_transaction_mast tm, txnlog t
     WHERE tm.ctm_delivery_channel = t.delivery_channel
       AND tm.ctm_tran_code = t.txn_code
       AND tm.ctm_inst_code = t.instcode
       AND instcode = p_inst_code
       AND sl.csl_delivery_channel(+) = t.delivery_channel
       AND sl.csl_txn_code(+) = t.txn_code
       AND sl.csl_rrn(+) = t.rrn
       AND sl.csl_pan_no(+) = t.customer_card_no
       AND sl.csl_auth_id(+) = t.auth_id
       AND sl.csl_inst_code(+) = t.instcode;   */
    --En Modified for FWR-42

   CURSOR c_mob_pre_auth_det (p_acct_no cms_acct_mast.cam_acct_no%TYPE)
   IS
      --  SELECT X.* --commented as per review observation on 23-Jan-2013
      --  FROM (     --commented as per review observation on 23-Jan-2013
      --Sn modified for FWR-42
      --SELECT   /*+rule*/ Rule hint removed from below qeury for performance changes(FSS-1412)
     /*   SELECT     TO_CHAR (TO_DATE (cph_txn_date, 'YYYY/MM/DD'), 'MM/DD/YYYY')
                 || ' ~ '
                 || 'DR'
                 || ' ~ '
                 || TRIM (TO_CHAR (ph.cph_txn_amnt, '99999999999999990.99'))
                 || ' ~ '
                 || tm.ctm_tran_desc
                 || ' ~ '
                 || pt.cpt_mcc_code
                 || ' ~ '
                 || ph.cph_delivery_channel
            FROM cms_preauth_trans_hist ph, cms_preauth_transaction pt,cms_transaction_mast tm
           WHERE cpt_acct_no = p_acct_no
             AND pt.cpt_sequence_no = ph.cph_sequence_no
             AND ph.cph_inst_code=tm.ctm_inst_code
             AND tm.ctm_delivery_channel = ph.cph_delivery_channel
             AND tm.ctm_tran_code = ph.cph_tran_code
             AND cpt_totalhold_amt > 0
             AND cph_inst_code = p_inst_code
        ORDER BY cph_txn_date DESC; */

--      SELECT   /*+rule*/
      SELECT   TO_CHAR (TO_DATE (cpt_txn_date, 'YYYY/MM/DD'), 'MMDDYYYY')
               || ' ~ '
               || TO_CHAR (TO_DATE (cpt_txn_time, 'HH24:MI:SS'), 'HH24MISS')
               || ' ~ '
             --  || ph.cph_merchant_name --Comment on 14/02/13 for regarding  MVHOST-848
               --|| NVL(ph.cph_merchant_name,DM.CDM_CHANNEL_DESC) --Modified on 14/02/13 for regarding  MVHOST-848
               || NVL(ph.cph_merchant_name,DECODE(TRIM(DM.CDM_CHANNEL_DESC),'ATM','ATM','POS','Retail Merchant','IVR','IVR Transfer',
           'CHW','Card Holder website','ACH','Direct Deposit','MOB','Mobile Transfer',
           'CSR','Customer Service','System'))--Added on 14/02/14 for regarding MVHOST-848 --Modified for MVHOST 987
               || ' ~ '
               || TRIM (TO_CHAR (ph.cph_txn_amnt, '99999999999999999.99'))
               || ' ~ '
               || 'Pending'
          FROM cms_preauth_trans_hist ph, VMSCMS.CMS_PREAUTH_TRANSACTION_VW pt,CMS_DELCHANNEL_MAST DM       --Added for VMS-5739/FSP-991
          WHERE cpt_acct_no = p_acct_no
           /*CPH_CARD_NO in (SELECT CAP_PAN_CODE
                                 FROM cms_appl_pan
                                 WHERE CAP_ACCT_NO =    --Modified by  Besky on 20/12/12 for 9736
                                                    (SELECT CAP_ACCT_NO
                                                     FROM CMS_APPL_PAN
                                                     WHERE CAP_PAN_CODE = GETHASH(P_PAN_CODE)
                                                     AND CAP_MBR_NUMB = P_MBR_NUMB
                                                     AND CAP_INST_CODE=P_INST_CODE
                                                     )
                                )
           */
         --  AND pt.cpt_sequence_no = ph.cph_sequence_no
         AND ph.cph_card_no = pt.cpt_card_no -- Added for Performance issues FSS-1621
          AND pt.cpt_expiry_flag='N' and pt.cpt_preauth_validflag='Y' AND ph.cph_rrn=pt.cpt_rrn   --Added for 0013611
          AND cpt_totalhold_amt > 0
           AND cph_inst_code = p_inst_code
           AND CDM_INST_CODE=p_inst_code --Added on 14/02/13 for regarding  MVHOST-848
           AND CDM_CHANNEL_CODE= ph.CPH_DELIVERY_CHANNEL --Added on 14/02/13 for regarding  MVHOST-848
      ORDER BY cph_txn_date DESC;
       --En modified for FWR-42
--) X;     --Modified by  Besky on 20/12/12 for 9736  --commented as per review observation on 23-Jan-2013
BEGIN
   SAVEPOINT v_auth_savepoint;
   v_timestamp := systimestamp;
--   p_posting_cnt :=0; --Added for FWR-42
--   p_tot_dr_amt :=0; --Added for FWR-42
--   p_tot_cr_amt :=0; --Added for FWR-42



   --Sn Get the HashPan
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the HashPan

   --Sn Create encr pan
   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Start Generate HashKEY value for regarding FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    --End Generate HashKEY value for regarding FSS-1144

   BEGIN
      SELECT cat_type_code, cam_acct_bal
        INTO v_cat_type_code, v_acct_balance
        FROM cms_acct_mast, cms_acct_type
       WHERE cam_inst_code = cat_inst_code
         AND cam_type_code = cat_type_code
         AND cam_acct_no = p_acct_no;

      IF v_cat_type_code = 1
      THEN
         v_spending := 'Y';
      ELSIF v_cat_type_code = 2
      THEN
         v_saving := 'Y';
      ELSE
         v_resp_cde := '49';
         v_errmsg := 'Invalid Account type ' || p_acct_no;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '163'; -- Modified from 134 to 163 for defect 10613 on 19-Mar-2013
         v_errmsg := 'Invalid Account Number' || p_acct_no; -- Error message changed as per discussion with ramesh for defect 10613 on 19-Mar-2013
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
             'Error while fetching account type ' || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc,nvl(ctm_txn_log_flag,'T')
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc,v_audit_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '12';                         --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';                        --Ineligible Transaction
         v_errmsg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag

  IF v_audit_flag = 'T'		--- Added for VMS-4379- Remove Account Statement Txn log logging into Transactionlog
  THEN
   --Sn Duplicate RRN Check
   BEGIN
   
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');
	   
	IF (v_Retdate>v_Retperiod) THEN                             --Added for VMS-5739/FSP-991
	   
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;
		 
	ELSE
	
	    SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST             --Added for VMS-5739/FSP-991
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;
	
	END IF;

      IF v_rrn_count > 0
      THEN
         v_resp_cde := '22';
         v_errmsg := 'Duplicate RRN on ' || p_tran_date;
         RAISE exp_reject_record;
      END IF;
      EXCEPTION
   WHEN OTHERS        --Added on 12-Aug-2013 for Review on MOB-33
      THEN
         p_resp_code := '21';                        --Ineligible Transaction
         v_errmsg := 'Error while selecting Duplicate RRN details';
         RAISE exp_reject_record;
   END;
   --En Duplicate RRN Check
   END IF;

   --Sn Get the card details
   BEGIN

      SELECT cap_card_stat,
             cap_acct_no,
             cap_cust_code,
             cap_acct_id,
             --Sn added by Pankaj S. for 10871
             cap_prod_code,
             cap_card_type
             --En added by Pankaj S. for 10871
        INTO v_cardstat,
             v_cap_acct_no,     --Added for Defect 0010613 on 19-Mar-2013
             v_cap_cust_code,   --Added for Defect 0010613 on 19-Mar-2013
             v_cap_acct_id,      --Added for Defect 0010613 on 19-Mar-2013
             --Sn added by Pankaj S. for 10871
             v_prod_code,
             v_card_type
             --En added by Pankaj S. for 10871
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                        --Ineligible Transaction
         v_errmsg := 'Card number not found ' || p_pan_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ------------------------------------------------------------------------------------
   --SN : Added for Defect 10613 Validating input card number with input Account number
   ------------------------------------------------------------------------------------

   if v_cat_type_code = 2
   then

       BEGIN

           select cam_acct_no
           into   v_cam_acct_no
           from  cms_acct_mast,cms_cust_acct
           where cca_inst_code = cam_inst_code
           and   cca_acct_id   = cam_acct_id
           and   cca_inst_code = p_inst_code
           and   cca_cust_code = v_cap_cust_code
           and   cam_type_code = 2;

       Exception when no_data_found
       then

         v_resp_cde := '163';
         v_errmsg := 'Invalid Account Number';
         RAISE exp_reject_record;

       when others
       then

         v_resp_cde := '12';
         v_errmsg := 'Problem while fetching saving accunt number' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;

       END;

   end if;

   If  v_cat_type_code = 1
   then

       IF p_acct_no <> v_cap_acct_no
       THEN

         v_resp_cde := '163';
         v_errmsg := 'Invalid Account Number';
         RAISE exp_reject_record;


       END IF;

   elsif v_cat_type_code = 2
   then

       IF p_acct_no <> v_cam_acct_no
       THEN

         v_resp_cde := '163';
         v_errmsg := 'Invalid Account Number';
         RAISE exp_reject_record;


       END IF;

   End if;

   ------------------------------------------------------------------------------------
   --EN : Added for Defect 10613 Validating input card number with input Account number
   ------------------------------------------------------------------------------------


   --End Get the card details
   -- commented on 6-Aug-2013 for MOB-33
  /* BEGIN
      SELECT TO_CHAR (TO_DATE (p_tran_date, 'YYYY/MM/DD'), 'MMYYYY')
        INTO v_mon_year_temp
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '89';                ---ISO MESSAGE FOR DATABASE ERROR
         v_errmsg :=
               'Problem while getting V_MON_YEAR_TEMP'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/

   --Sn call to authorize procedure
   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg,
                                 p_rrn,
                                 p_delivery_channel,
                                 NULL,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_inst_code,
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
                                 v_errmsg,
                                 v_capture_date
                                );

      IF p_resp_code <> '00' AND v_errmsg <> 'OK'
      THEN
         --P_RESP_CODE := '21';
         --V_ERRMSG :=  V_ERRMSG;
         RAISE exp_auth_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En call to authorize procedure

           --Sn Updtated transactionlog For regarding FSS-1144
           
           IF v_audit_flag = 'T'		--- Modified for VMS-4379 
           THEN

            BEGIN
			
			--Added for VMS-5739/FSP-991
		       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
               v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
			   
			IF (v_Retdate>v_Retperiod) THEN                                         --Added for VMS-5739/FSP-991
			
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
			ELSE
			  
			  UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST               --Added for VMS-5739/FSP-991
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			
			END IF;

             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;
            
            END IF;

   --End Updated transaction log  for regarding  FSS-1144


   /* -- Commented on 21-jan-2013 as same is already derived from above query using same table
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_ACCT_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERRMSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERRMSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;



    END;
   */
   p_avail_bal_amt := NVL (v_acct_balance, '0');

   IF v_output_type = 'M'
   THEN
      --  If Txn Code 02
            --Sn Added by Pankaj S. for FSS-1959
      IF p_txn_cnt=3 THEN

          BEGIN
             OPEN c_mob_mini_tran_1 (p_acct_no, p_fromdate, p_todate, p_fromamnt, p_toamnt);
             LOOP
                FETCH c_mob_mini_tran_1
                INTO v_mini_stat_val;
                EXIT WHEN c_mob_mini_tran_1%NOTFOUND;
                v_mini_stat_res := v_mini_stat_res || ' || ' || v_mini_stat_val;
             END LOOP;
             CLOSE c_mob_mini_tran_1;
          EXCEPTION
             WHEN OTHERS THEN
              v_errmsg :='Problem while selecting data from c_mob_mini_tran_1 cursor'|| SUBSTR (SQLERRM, 1, 300);
              v_resp_cde := '21';
              RAISE exp_reject_record;
          END;
      ELSE
      --En Added by Pankaj S. for FSS-1959
      BEGIN
    -- OPEN c_mob_mini_tran (p_acct_no, v_mon_year_temp); -- Commented for MOB-33
         OPEN c_mob_mini_tran (p_acct_no,P_FROMDATE,P_TODATE,P_FROMAMNT,P_TOAMNT);    ---- Modified on 6-Aug-2013 for MOB-33

         LOOP
            FETCH c_mob_mini_tran
                    INTO v_mini_stat_val;
   --INTO v_response_code,v_tran_amount, v_trantype, v_mini_stat_val;  --Modified for FWR-42

            EXIT WHEN c_mob_mini_tran%NOTFOUND;
            v_mini_stat_res := v_mini_stat_res || ' || ' || v_mini_stat_val;

             --Sn Added for FWR-42
             /*IF v_trantype = 'DR' AND v_response_code='00'
             THEN
                   p_tot_dr_amt := p_tot_dr_amt + v_tran_amount;
                   p_posting_cnt :=p_posting_cnt+1;
             ELSIF v_trantype = 'CR' AND v_response_code='00'
             THEN
                   p_tot_cr_amt := p_tot_cr_amt + v_tran_amount;
                   p_posting_cnt :=p_posting_cnt+1;
             END IF; */
             --En Added for FWR-42
         END LOOP;

         CLOSE c_mob_mini_tran;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from C_MOB_MINI_TRAN cursor'
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
     END IF;
      IF (v_mini_stat_res IS NULL)
      THEN
         v_mini_stat_res := ' ';
      ELSE
         v_mini_stat_res :=
                        SUBSTR (v_mini_stat_res, 5, LENGTH (v_mini_stat_res));
      END IF;

      IF v_spending = 'Y'
      -- Added on 21-Jan-2013 for mobile API changes Defect 10014
      THEN
         --IF txn code 02
         BEGIN
            OPEN c_mob_pre_auth_det (p_acct_no);

            LOOP
               FETCH c_mob_pre_auth_det
                INTO v_pre_auth_det_val;

               EXIT WHEN c_mob_pre_auth_det%NOTFOUND;
               v_pre_auth_det :=v_pre_auth_det || ' || ' || v_pre_auth_det_val;
            END LOOP;

            CLOSE c_mob_pre_auth_det;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting data from C_MOB_PRE_AUTH_DET cursor'
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      END IF;      -- Added on 21-Jan-2013 for mobile API changes Defect 10014

      IF (v_pre_auth_det IS NULL)
      THEN
         v_pre_auth_det := '  ';
      ELSE
         v_pre_auth_det :=
                          SUBSTR (v_pre_auth_det, 5, LENGTH (v_pre_auth_det));
      END IF;

      p_pre_auth_det := NVL (v_pre_auth_det, ' ');

      IF v_spending = 'Y'
      -- Added on 21-Jan-2013 for mobile API changes Defect 10014
      THEN
         begin
            select-- NVL (SUM (cpt_totalhold_amt), '0')
             NVL (SUM (CPT_TOTALHOLD_AMT+CPT_COMPLETION_FEE), '0') ,COUNT (*) --Modified for FSS 837
              INTO p_pre_auth_hold_amt, p_pending_txn_count
              FROM cms_preauth_trans_hist ph,
                   cms_transaction_mast tm,
                   VMSCMS.CMS_PREAUTH_TRANSACTION pm                             --Added for VMS-5739/FSP-991
             WHERE cpt_acct_no = p_acct_no
               -- Added on 21-Jan-2013 for Mobile API changes  Defect 10014
               AND cpt_acct_no = cph_acct_no
                  -- Added on 21-Jan-2013 for Mobile API changes  Defect 10014
               --CPH_CARD_NO = GETHASH(P_PAN_CODE)        -- Commented on 21-Jan-2013 for Mobile API changes
               AND tm.ctm_delivery_channel = ph.cph_delivery_channel
               AND tm.ctm_tran_code = ph.cph_tran_code
               AND ph.cph_card_no = pm.cpt_card_no
               AND pm.cpt_totalhold_amt > 0
               AND pm.cpt_expiry_flag = 'N'
               AND pm.cpt_preauth_validflag = 'Y'
               AND ph.cph_rrn = pm.cpt_rrn;
			   IF SQL%ROWCOUNT = 0 THEN
			    select-- NVL (SUM (cpt_totalhold_amt), '0')
             NVL (SUM (CPT_TOTALHOLD_AMT+CPT_COMPLETION_FEE), '0') ,COUNT (*) --Modified for FSS 837
              INTO p_pre_auth_hold_amt, p_pending_txn_count
              FROM cms_preauth_trans_hist ph,
                   cms_transaction_mast tm,
                   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST pm                             --Added for VMS-5739/FSP-991
             WHERE cpt_acct_no = p_acct_no
               -- Added on 21-Jan-2013 for Mobile API changes  Defect 10014
               AND cpt_acct_no = cph_acct_no
                  -- Added on 21-Jan-2013 for Mobile API changes  Defect 10014
               --CPH_CARD_NO = GETHASH(P_PAN_CODE)        -- Commented on 21-Jan-2013 for Mobile API changes
               AND tm.ctm_delivery_channel = ph.cph_delivery_channel
               AND tm.ctm_tran_code = ph.cph_tran_code
               AND ph.cph_card_no = pm.cpt_card_no
               AND pm.cpt_totalhold_amt > 0
               AND pm.cpt_expiry_flag = 'N'
               AND pm.cpt_preauth_validflag = 'Y'
               AND ph.cph_rrn = pm.cpt_rrn;
			   END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '89';          ---ISO MESSAGE FOR DATABASE ERROR
               v_errmsg :=
                     'Problem while selecting data from CMS_PREAUTH_TRANS_HIST PH, CMS_TRANSACTION_MAST TM , CMS_PREAUTH_TRANSACTION PM '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      IF p_pre_auth_hold_amt IS NULL AND p_pending_txn_count IS NULL
      --if condition added on 22-Jan-2013 for Mobile API changes Defect 10014
      THEN
         p_pre_auth_hold_amt := NVL (p_pre_auth_hold_amt, 0);
         p_pending_txn_count := NVL (p_pending_txn_count, 0);
      END IF;
   END IF;

   v_resp_cde := 1;

   --ST Get responce code from master
   BEGIN
      SELECT cms_iso_respcde
        INTO v_resp_cde
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '89';
         v_errmsg := 'Responce code not found ' || p_resp_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '89';                ---ISO MESSAGE FOR DATABASE ERROR
         v_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 200);
   END;

   --En Get responce code fomr master
   p_resp_code := v_resp_cde;

   IF v_mini_stat_res IS NOT NULL
   THEN
      p_resmsg := v_mini_stat_res;
   END IF;

   -- P_RESMSG    := V_ERRMSG;
   p_auth_id := v_auth_id;
--Sn Handle EXP_REJECT_RECORD execption

EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_auth_savepoint;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      END;

      --En Get responce code fomr master

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
          SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc,nvl(ctm_txn_log_flag,'T')
        INTO v_dr_cr_flag,v_txn_type,v_trans_desc,v_audit_flag
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
          WHERE cap_pan_code = gethash (p_pan_code) AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_cat_type_code IS NULL THEN
      BEGIN
         SELECT cam_type_code
           INTO v_cat_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_acct_no AND cam_inst_code = p_inst_code
          FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871

      --Sn Inserting data in transactionlog
      
      IF v_audit_flag = 'T'			--- Modified for VMS-4379 
        THEN
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr,--  CUSTOMER_ACCT_NO,
                      error_msg,--  IPADDRESS,
                      add_ins_date, add_ins_user, cardstatus,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc,response_id,
                      --Sn added by Pankaj S. for 10871
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                      --En added by Pankaj S. for 10871

                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,-- V_SPND_ACCT_NO,
                      v_errmsg,--  P_IPADDRESS,
                      SYSDATE, 1, v_cardstat,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc, v_resp_cde,--p_resp_code,  --modified by Pankaj S. for 10871
                      --Sn added by Pankaj S. for 10871
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;        -- Added as per internal review obseravation
            --V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM; -- commneted as per internal review obseravation
            --RAISE EXP_REJECT_RECORD; -- commneted as per internal review obseravation
            RETURN;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      -- CTD_CUST_ACCT_NUMBER,
                      ctd_addr_verify_response,
                      CTD_MOBILE_NUMBER,CTD_DEVICE_ID,ctd_hashkey_id --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',

                      --  V_SPND_ACCT_NO,
                      '',
                      P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 200);
                                 -- Added  as per internal review obseravation
            --V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 200); -- commneted as per internal review obseravation
            p_resp_code := '89';
            RETURN;
      END;
      
      ELSIF v_audit_flag = 'A'
        THEN
        

      BEGIN

         INSERT INTO transactionlog_audit
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, 
                      error_msg, 
                      add_ins_date, add_ins_user, cardstatus, 
                      trans_desc,response_id,                      
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                      )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, 
                      v_errmsg, 
                      SYSDATE, 1, v_cardstat, 
                      v_trans_desc, v_resp_cde, 
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                     );
                     DBMS_OUTPUT.PUT_LINE('Check Here3');
      EXCEPTION
         WHEN OTHERS
         THEN
         DBMS_OUTPUT.PUT_LINE('Check Here execption in ');
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log AUDIT 1 '
               || SQLCODE
               || '---'
               || SQLERRM;     
            RETURN;
      END; 
      
      END IF;

    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
      p_resmsg := v_errmsg;
--Sn Handle OTHERS Execption
   WHEN exp_auth_reject_record
   THEN
      ROLLBACK;

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
          SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc,nvl(ctm_txn_log_flag,'T')
        INTO v_dr_cr_flag,v_txn_type,v_trans_desc,v_audit_flag
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
          WHERE cap_pan_code = gethash (p_pan_code) AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_cat_type_code IS NULL THEN
      BEGIN
         SELECT cam_type_code
           INTO v_cat_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_acct_no AND cam_inst_code = p_inst_code
          FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871

      IF v_audit_flag = 'T'			--- Modified for VMS-4379 
        THEN
--Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr,-- CUSTOMER_ACCT_NO,
                      error_msg, -- IPADDRESS,
                      add_ins_date, add_ins_user, cardstatus,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc,response_id,
                      --Sn added by Pankaj S. for 10871
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                      --En added by Pankaj S. for 10871
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,-- V_SPND_ACCT_NO,
                      v_errmsg,--  P_IPADDRESS,
                      SYSDATE, 1, v_cardstat,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc,p_resp_code,
                      --Sn added by Pankaj S. for 10871
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            --V_ERRMSG := 'Exception while inserting to transaction log '||SUBSTR(SQLERRM, 1, 200); -- commneted as per internal review obseravation
            p_resmsg :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 200);
            -- Added as per internal review obseravation
            RETURN;               -- Added as per internal review obseravation
      --RAISE EXP_REJECT_RECORD; -- commneted as per internal review obseravation
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      -- CTD_CUST_ACCT_NUMBER,
                      ctd_addr_verify_response,
                      CTD_MOBILE_NUMBER,CTD_DEVICE_ID,ctd_hashkey_id --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',

                      --  V_SPND_ACCT_NO,
                      '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID  --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144

                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 200); -- commneted as per internal review obseravation
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 200);
            -- Added as per internal review obseravation
            p_resp_code := '89';
            RETURN;
      END;
      
      ELSIF v_audit_flag = 'A'
        THEN
      BEGIN
         INSERT INTO  transactionlog_audit
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, 
                      error_msg, 
                      add_ins_date, add_ins_user, cardstatus,
                      trans_desc,response_id,
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,
                      v_errmsg,
                      SYSDATE, 1, v_cardstat,
                      v_trans_desc,p_resp_code,
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log AUDIT 2'
               || SUBSTR (SQLERRM, 1, 200);            
            RETURN;           
      END;
      
      END IF;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
--P_RESMSG    := V_ERRMSG; -- commneted as per internal review obseravation
   WHEN OTHERS
   THEN
      v_resp_cde := '21';
      v_errmsg :=
            'Main Exception ' || SQLCODE || '---' || SUBSTR (SQLERRM, 1, 200);
      ROLLBACK TO v_auth_savepoint;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '89';
      END;

      --En Get responce code fomr master

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc,nvl(ctm_txn_log_flag,'T')
        INTO v_dr_cr_flag,v_txn_type,v_trans_desc,v_audit_flag
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
          WHERE cap_pan_code = gethash (p_pan_code) AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_cat_type_code IS NULL THEN
      BEGIN
         SELECT cam_type_code
           INTO v_cat_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_acct_no AND cam_inst_code = p_inst_code
          FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871

      --Sn Inserting data in transactionlog
      
      IF v_audit_flag = 'T'		--- Modified for VMS-4379 
        THEN
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr,--CUSTOMER_ACCT_NO,
                      error_msg,--  IPADDRESS,
                      add_ins_date, add_ins_user, cardstatus, trans_desc,
                      response_id,
                      --Sn added by Pankaj S. for 10871
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                      --En added by Pankaj S. for 10871
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,-- V_SPND_ACCT_NO,
                      v_errmsg,--  P_IPADDRESS,
                      SYSDATE, 1, v_cardstat, v_trans_desc,v_resp_cde,--p_resp_code,  --modified by Pankaj S. for 10871
                      --Sn added by Pankaj S. for 10871
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SUBSTR (SQLERRM, 1, 200);
                                  -- Added as per internal review obseravation
            --V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200); -- commneted as per internal review obseravation
            --RAISE EXP_REJECT_RECORD; -- commneted as per internal review obseravation
            RETURN;               -- Added as per internal review obseravation
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      -- CTD_CUST_ACCT_NUMBER,
                      ctd_addr_verify_response,
                      CTD_MOBILE_NUMBER,CTD_DEVICE_ID,ctd_hashkey_id --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      null, null,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',

                      --  V_SPND_ACCT_NO,
                      '',
                      P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID  --Added on 12-Aug-2013 by Ravi N for regarding Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 200); -- commneted as per internal review obseravation
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 200);
            -- Added as per internal review obseravation
            p_resp_code := '89';
            RETURN;
      END;
      
      ELSIF v_audit_flag = 'A'
        THEN
        
        BEGIN
        
        INSERT INTO transactionlog_audit
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr,
                      error_msg, 
                      add_ins_date, add_ins_user, cardstatus, trans_desc,
                      response_id,
                      customer_acct_no,productid,categoryid,acct_type,cr_dr_flag,time_stamp
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,
                      v_errmsg, 
                      SYSDATE, 1, v_cardstat, v_trans_desc,v_resp_cde,                       
                      p_acct_no,v_prod_code,v_card_type,v_cat_type_code,v_dr_cr_flag,v_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log AUDIT 3'
               || SQLCODE
               || '---'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;               
      END; 
      
      END IF;

      p_resmsg := v_errmsg;
   --En Inserting data in transactionlog dtl
--En Handle OTHERS Execption
END;

/

show error;