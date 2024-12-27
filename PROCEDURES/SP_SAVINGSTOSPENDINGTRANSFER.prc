set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.sp_savingstospendingtransfer (

   p_inst_code          IN       NUMBER,
   p_pan_code           IN       VARCHAR2,
   p_msg                IN       VARCHAR2,
   p_spd_acct_no        IN       VARCHAR2,
   p_svg_acct_no        IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   --Modified by Ramesh.A on 03/05/2012
   p_rrn                IN       VARCHAR2,
   p_txn_amt            IN       NUMBER, 
   p_txn_mode           IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2,
   p_spenacctbal        OUT      VARCHAR2,
                                    -- Added by siva kumar m as on 06/Aug/2012
   p_spenacctledgbal    OUT      VARCHAR2,
                                    -- Added by siva kumar m as on 06/Aug/2012
   p_availed_txn        OUT      NUMBER,
-- Added by B.Besky  on 04/01/2013 for CR->40 To give the availed transaction as the output.
   p_available_txn      OUT      NUMBER,
   p_svgacct_closrflag      IN      VARCHAR2 DEFAULT 'N'
--  Added by B.Besky  on 04/01/2013 for CR->40 To give the available transaction as the output.
)
AS
/*************************************************
     * Created Date     :  12-Feb-2012
     * Created By       :  Ramesh.A
     * PURPOSE          :  Funds Transfer(Savings / Spending Acc)
     * modified by       :siva kumar M
     * modified Date        :17-Apr-2013
     * modified reason      :For defect id 10869
     * Reviewer         :  Dhiarj
     * Reviewed Date    :  17-Apr-2013
     * Build Number     :  CMS3.5.1_RI0024.1_B0007

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  18-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0013

     * Modified by      :  Sagar m.
     * Modified Reason  :  MOB-26
     * Modified Date    :  13-May-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0021

     * Modified by      :  Shweta
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  05-Jun-2013
     * Reviewer         :  Sachin P.
     * Reviewed Date    :  18-Jun-2013
     * Build Number     :  RI0024.2_B0004

     * Modified by      :  Pankaj S.
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  20-Aug-2013
     * Reviewer         :  Dhiraj G.
     * modified by      :  MageshKumar.S
     * modified Date    :  29-AUG-13
     * modified reason  :  FSS-1144
     * Reviewer         :  Dhiraj
     * Reviewed Date    :   30-AUG-13
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

     * Modified By      : Sagar More
     * Modified Date    : 22-OCT-2013
     * Modified For     : Defect 12797
     * Modified Reason  : To uncomment subquery used to fetch saving acct from cms_acct_mast
     * Reviewer         : Dhiraj
     * Reviewed Date    : 23-OCT-2013
     * Build Number     : RI0024.6_B0002

     * Modified by      :  Pankaj S.
     * Modified Reason  :  FWR-44
     * Modified Date    :  15-Jan-2014
     * Reviewer         :  Dhiraj G.
     * Reviewed Date    :
     * Build Number     : RI0027_B0004

      * Modified By      : Dayanand Kesarkar
      * Modified Date    : 29-JAN-2014
      * Modified For     : MANTIS:12326
      * Modified Reason  : Spelling changed
      * Reviewer         : dhiraj
      * Reviewed Date    :
      * Build Number     : RI0027_B0005

     * Modified By      : Dayanand Kesarkar
     * Modified Date    : 07-Feb-2014
     * Modified For     : MANTIS:12326
     * Modified Reason  : Spelling changed
     * Reviewer         : dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0027_B0006

     * Modified By      : MageshKumar S
     * Modified Date    : 19-02-2014
     * Modified For     : MVCSD-4479
     * Reviewer         : Dhiraj
     * Reviewed Date    : 7-03-2014
     * Build Number     : RI0027.2_B0001

     * Modified by      : MageshKumar S.
     * Modified Date    : 25-July-14
     * Modified For     : FWR-48
     * Modified reason  : GL Mapping removal changes
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0001

    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1

    * Modified by        : Spankaj
    * Modified Date     : 28-Dec-15
    * Modified For      : MVHOST-1249
    * Reviewer             : Saravanankumar
    * Build Number      : VMSGPRHOSTCSD3.3


           * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

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
   v_tran_date                DATE;
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991
   v_cardstat                 VARCHAR2 (5);
   v_cardexp                  DATE;
   -- v_auth_savepoint           NUMBER                                DEFAULT 0;
   v_rrn_count                NUMBER;
   v_branch_code              VARCHAR2 (5);
   v_errmsg                   VARCHAR2 (500);
   v_count                    NUMBER;
   v_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code                cms_pan_acct.cpa_cust_code%TYPE;
   v_acct_type                cms_acct_type.cat_type_code%TYPE;
   v_spd_acct_type            cms_acct_type.cat_type_code%TYPE;
   v_acct_stat                cms_acct_mast.cam_stat_code%TYPE;
   v_svg_acct_stat            cms_acct_mast.cam_stat_code%TYPE;
   v_prod_code                cms_appl_pan.cap_prod_code%TYPE;
   v_txn_type                 transactionlog.txn_type%TYPE;
   v_switch_acct_type         cms_acct_type.cat_switch_type%TYPE DEFAULT '22';
   v_switch_acct_stat         cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '8';
   v_switch_spd_acct_type     cms_acct_type.cat_switch_type%TYPE DEFAULT '11';
  -- v_func_code                cms_func_mast.cfm_func_code%TYPE; --commented for fwr-48
   v_prodcode                 cms_appl_pan.cap_prod_code%TYPE;
   v_cardtype                 cms_appl_pan.cap_card_type%TYPE;
   v_acct_number              cms_appl_pan.cap_acct_no%TYPE;
   v_saving_acct_number       cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance             NUMBER;
   v_savings_acct_balance     NUMBER;
   v_savings_ledger_balance   NUMBER;
 --  v_cracct_no                cms_func_prod.cfp_cracct_no%TYPE; --commented for fwr-48
 --  v_dracct_no                cms_func_prod.cfp_dracct_no%TYPE; --commented for fwr-48
   v_gl_upd_flag              VARCHAR2 (1);
  -- v_min_spd_amt              cms_dfg_param.cdp_param_key%TYPE;
   v_min_svg_amt              cms_dfg_param.cdp_param_key%TYPE;
   --v_max_svg_lmt              cms_dfg_param.cdp_param_key%TYPE;
   v_max_svg_trns_limt        cms_dfg_param.cdp_param_key%TYPE;
   v_auth_id                  transactionlog.auth_id%TYPE;
   v_curr_code                transactionlog.currencycode%TYPE;
   v_spd_acct_id              cms_appl_pan.cap_acct_id%TYPE;
   v_svg_acct_id              cms_appl_pan.cap_acct_id%TYPE;
   v_term_id                  VARCHAR2 (20);
   v_mcc_code                 VARCHAR2 (20);
   v_card_expry               VARCHAR2 (20);
   v_stan                     VARCHAR2 (20);
   v_capture_date             DATE;
   v_dr_cr_flag               VARCHAR2 (2);
   v_trans_desc               VARCHAR2 (50);
   v_narration                VARCHAR2 (300);
   v_ledger_balance           NUMBER;
   v_card_curr                VARCHAR2 (5);
   v_svgtospd_trans           NUMBER;
   v_output_type              VARCHAR2 (2);
   v_tran_type                VARCHAR2 (2);
   exp_reject_record          EXCEPTION;
   exp_auth_reject_record     EXCEPTION;
   --Sn added by Pankaj S. for 10871
   v_resp_cde                 cms_response_mast.cms_response_id%TYPE;
   v_timestamp                TIMESTAMP ( 3 );

   --En added by Pankaj S. for 10871
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  on 29-08-2013 for  FSS-1144
   v_dfg_cnt       NUMBER(10); -- v_dfg_cnt added for LYFEHOST-63

   v_date_chk      date;       -- Added as per review observation for LYFEHOST-63
   v_svgtospd_Rev_trans   NUMBER(10); --Added for FWR-44
   v_svgacctclosr               VARCHAR2(1):='N';
   
   --Sn Getting DFG Parameters
   CURSOR c (p_prod_code cms_prod_mast.cpm_prod_code%type,p_card_type cms_appl_pan.cap_card_type%type) -- p_prod_code added for LYFEHOST-63
   IS
      SELECT cdp_param_key, cdp_param_value
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code
       and   cdp_prod_code = p_prod_code
      and  cdp_card_type = p_card_type
       and   cdp_param_key in ('MinSavingParam','MaxNoTrans'); -- Condition added as per review observation for LYFEHOST-63

--En Getting DFG Parameters

--Main Begin Block Starts Here
BEGIN
   v_txn_type := '1';
   v_curr_code := p_curr_code;
   p_resp_code := '00';                                     --Added for CR-40
   v_timestamp :=SYSTIMESTAMP; -- Added on 29-08-2013 for FSS-1144
   -- SAVEPOINT v_auth_savepoint;
   --Sn Get the HashPan
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting into hash pan ' || SUBSTR (SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_reject_record;
   END;

   --En Get the HashPan

   --Sn Create encr pan
   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting into encrypt pan ' || SUBSTR (SQLERRM, 1, 200); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_reject_record;
   END;

   --En Create encr pan
   -- Start Generate HashKEY value for FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '12';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    --End Generate HashKEY value for FSS-1144

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';                        --Ineligible Transaction
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

   --Sn select acct type(Savings)
   BEGIN
      SELECT cat_type_code
        INTO v_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code
         AND cat_switch_type = v_switch_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Acct type not defined in master(Savings)';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting accttype(Savings) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select acct type(Savings)

   --Sn select acct type(Spending)
   BEGIN
      SELECT cat_type_code
        INTO v_spd_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_inst_code
         AND cat_switch_type = v_switch_spd_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Acct type not defined in master(Spending)';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting accttype(Spending) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select acct type(Spending)

   --Sn Check the Savings Account Number
   BEGIN
      SELECT COUNT (1)
        INTO v_count
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no = p_svg_acct_no
         AND cam_type_code = v_acct_type;

      IF v_count = 0
      THEN
         p_resp_code := '109';
         v_errmsg := 'Invalid Savings Account Number '||p_svg_acct_no; -- p_svg_acct_no appended on 22-oct-2013
         --Updated by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Problem while selecting Savings Account Number Card Detail'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Check the Savings Account Number

      --SN: Added as per review observation for LYFEHOST-63

      Begin

       select to_Date(substr(p_tran_date,1,8),'yyyymmdd')
       into v_date_chk
       from dual;

      exception when others
      then
        p_resp_code := '21';
        v_errmsg := 'Invalid transaction date '||P_TRAN_DATE; -- updated
        RAISE exp_reject_record;

      End;

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
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;
      else   --Added for VMS-5733/FSP-991
       SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;   
       END IF;  

      --Added by ramkumar.Mk on 25 march 2012
      IF v_rrn_count > 0
      THEN
         p_resp_code := '22';
         v_errmsg := 'Duplicate RRN on ' || p_tran_date;
         RAISE exp_reject_record;
      END IF;
   --Sn added by Pankaj S. during DFCCSD-70(Review) changes
   EXCEPTION
   WHEN exp_reject_record THEN
     RAISE;
   WHEN OTHERS THEN
     p_resp_code := '21';
     v_errmsg :='Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
     RAISE exp_reject_record;
   --En added by Pankaj S. during DFCCSD-70(Review) changes
   END;

   --En Duplicate RRN Check

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
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Tran date

   --Sn Check Delivery Channel  --Commented by Besky on 10/01/2013 for CR-40
   /* IF p_delivery_channel NOT IN ('10', '07','13')
    THEN
       v_errmsg :=
             'Not a valid delivery channel  for '
          || ' Savings To Spending Acc Transfer';
       p_resp_code := '21';                   ---ISO MESSAGE FOR DATABASE ERROR
       RAISE exp_reject_record;
    END IF;

    --En Check Delivery Channel

    --Sn Check transaction code
    IF p_txn_code NOT IN ('20', '11','04')
    THEN
       v_errmsg :=
             'Not a valid transaction code for '
          || ' Savings To Spending Acc Transfer';
       p_resp_code := '21';                   ---ISO MESSAGE FOR DATABASE ERROR
       RAISE exp_reject_record;
    END IF;*/

   --En check transaction code

   --Sn Used here & commented down by Pankaj S. during DFCCSD-70(Review) changes
   --Sn check card details
   BEGIN
      SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_cust_code,
             cap_card_stat, cap_expry_date
        INTO v_prodcode, v_cardtype, v_acct_number, v_cust_code,
             v_cardstat, v_cardexp
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';
         v_errmsg := 'Card number not found ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En check card details
   --En Used here & commented down by Pankaj S. during DFCCSD-70(Review) changes

   --Sn commented by Pankaj S. during DFCCSD-70(Review) changes and get same details using above query
   /*--Sn Get the card details
   BEGIN
      SELECT cap_card_stat, cap_expry_date
        INTO v_cardstat, v_cardexp
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                        --Ineligible Transaction
         v_errmsg := 'Card number not found ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --End Get the card details*/
   --En commented by Pankaj S. during DFCCSD-70(Review) changes and get same details using above query

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

--     SELECT TRIM (cbp_param_value)
--       INTO v_card_curr
--       FROM cms_bin_param, cms_prod_CATTYPE
--      WHERE cbp_param_name = 'Currency'
--        AND CBP_PROFILE_CODE = CPC_PROFILE_CODE
--        AND cpC_prod_code = v_prodcode AND CPC_CARD_TYPE=V_CARDTYPE
--        AND cpC_inst_code = p_inst_code;
--     --En modified by Pankaj S. during DFCCSD-70(Review) changes

vmsfunutilities.get_currency_code(v_prodcode,V_CARDTYPE,p_inst_code,v_card_curr,v_errmsg);

      if v_errmsg<>'OK' then
           raise exp_reject_record;
      end if;

      IF TRIM (v_card_curr) IS NULL
      THEN
         p_resp_code := '21';
         v_errmsg := 'To Card currency cannot be null ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'card currency is not defined for to card ';
         p_resp_code := '21';
         RAISE exp_reject_record;
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
   IF v_curr_code <> v_card_curr
   THEN
      v_errmsg :=
            'Both from card currency and txn currency are not same  '
         || SUBSTR (SQLERRM, 1, 200);
      p_resp_code := '21';
      RAISE exp_reject_record;
   END IF;

   --En check card currency with txn currency --------

   --Sn Move below block up by Pankaj S. during DFCCSD-70(Review) changes
   /*--Sn check card details
   BEGIN
      SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_cust_code
        INTO v_prodcode, v_cardtype, v_acct_number, v_cust_code
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';
         v_errmsg := 'Card number not found ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En check card details*/
   --En Move below block up by Pankaj S. during DFCCSD-70(Review) changes

   --Sn check valid account number
   IF v_acct_number <> p_spd_acct_no
   THEN
      p_resp_code := '110';
      v_errmsg := 'Invalid Spending Account Number';
      --Updated by Ramesh.A on 08/03/2012
      RAISE exp_reject_record;
   END IF;

   --En check valid account number

   --Sn Get Savings Acc number
   BEGIN

    --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes

    -- Query uncommented on 22-oct-2013 defect 12797
        SELECT cam_acct_no, cam_acct_bal,
             cam_ledger_bal, cam_stat_code
        INTO v_saving_acct_number, v_savings_acct_balance,
             v_savings_ledger_balance, v_svg_acct_stat
        FROM cms_acct_mast
       WHERE cam_acct_id IN (
                SELECT cca_acct_id
                  FROM cms_cust_acct
                 WHERE cca_cust_code = v_cust_code
                   AND cca_inst_code = p_inst_code)
         AND cam_type_code = v_acct_type
         AND cam_inst_code = p_inst_code;

    -- Query uncommented on 22-oct-2013 defect 12797

        /*      -- Query commented on 22-oct-2013
         SELECT cam_acct_no, cam_acct_bal, cam_ledger_bal, cam_stat_code
           INTO v_saving_acct_number, v_savings_acct_balance,v_savings_ledger_balance, v_svg_acct_stat
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code
            AND cam_acct_no = p_svg_acct_no;

        */    -- Query commented on 22-oct-2013

      --En Modified by Pankaj S. during DFCCSD-70(Review) changes
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '105';
         v_errmsg := 'Savings Acc not created for this card';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting savings acc number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Savings Acc number

   --Sn check valid Savings acc number
   IF v_saving_acct_number <> p_svg_acct_no
   THEN
      p_resp_code := '109';
      v_errmsg := 'Invalid Savings Account Number '||p_svg_acct_no; -- p_svg_acct_no appended on 22-oct-2013
      --Updated by Ramesh.A on 08/03/2012;
      RAISE exp_reject_record;
   END IF;

   --En check valid Savings acc number

   --Sn Get Account Status(Savings)
   BEGIN
      SELECT cas_stat_code
        INTO v_acct_stat
        FROM cms_acct_stat
       WHERE cas_inst_code = p_inst_code
         AND cas_switch_statcode = v_switch_acct_stat;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Account Status not defind for Savings acc';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting savings acc status '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Account Status(Savings)

   --Sn checks valid acc status
   IF v_acct_stat <> v_svg_acct_stat
   THEN
      p_resp_code := '106';
      v_errmsg := 'Savings account already closed';
      --Updated by Ramesh.A on 08/03/2012
      RAISE exp_reject_record;
   END IF;

   --En checks valid acc status

   --Sn - commented for fwr-48

   --Sn select the function CODE
 /*  BEGIN
      SELECT cfm_func_code
        INTO v_func_code
        FROM cms_func_mast
       WHERE cfm_txn_code = p_txn_code
         AND cfm_txn_mode = p_txn_mode
         AND cfm_delivery_channel = p_delivery_channel
         AND cfm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '69';
         v_errmsg := 'Function code not defined for txn code ';
         RAISE exp_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         p_resp_code := '69';
         v_errmsg := 'More than one function defined for txn code ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '69';
         v_errmsg :=
             'Error while calling CMS_FUNC_MAST ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select the function code

   --Sn select the debit and credit gl
   BEGIN
      SELECT cfp_cracct_no, cfp_dracct_no
        INTO v_cracct_no, v_dracct_no
        FROM cms_func_prod
       WHERE cfp_func_code = v_func_code
         AND cfp_prod_code = v_prodcode
         AND cfp_prod_cattype = v_cardtype
         AND cfp_inst_code = p_inst_code;

      IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Both credit and debit account cannot be null for a transaction code '
            || p_txn_code
            || ' Function code '
            || v_func_code;
         v_gl_upd_flag := 'N';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';                        --Ineligible Transaction
         v_errmsg := v_func_code || '  function is not attached to card ';
         RAISE exp_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         p_resp_code := '21';
         v_errmsg := 'More than one function defined for card number ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error while selecting Gl detasil for card numer '||substr(sqlerrm,1,100); -- Change in error message as per review observation for LYFEHOST-63
         RAISE exp_reject_record;
   END;*/

   --En select the debit and credit gl

   --En - commented for fwr-48

   --Sn Get the Spending Acc Balance
   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal
            INTO v_acct_balance, v_ledger_balance
            FROM cms_acct_mast
           WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number
      FOR UPDATE NOWAIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '17';                        --Ineligible Transaction
         v_errmsg := 'Invalid Account ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from card Master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the Spending Acc Balance
/*
    --Sn commented for MVCSD-4479
    --Sn Added for FWR-44
   BEGIN
      SELECT COUNT (*)
        INTO v_svgtospd_Rev_trans
        FROM transactionlog
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code = '11')
             )
         AND business_date BETWEEN TO_CHAR (TRUNC (v_tran_date, 'month'),'yyyymmdd')
                               AND TO_CHAR (LAST_DAY (v_tran_date), 'yyyymmdd')
         AND response_code = '00'
         AND tran_reverse_flag='Y'
         AND customer_card_no = v_hash_pan
         AND customer_acct_no = v_saving_acct_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from TRANSACTIONLOG for getting the number of transactions for s month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Added for FWR-44

   --Sn Get the number of transactions for a month(Saving to Spending)
   BEGIN
      SELECT COUNT (*) -v_svgtospd_Rev_trans  --Modified for FWR-44
        INTO v_svgtospd_trans
        FROM transactionlog
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code = '11')
             )                    -- Modified by Besky on 04/01/2013 for CR-40
         --AND business_date BETWEEN TO_CHAR (TRUNC (SYSDATE, 'month'), 'yyyymmdd') AND TO_CHAR (LAST_DAY (SYSDATE), 'yyyymmdd')
         AND business_date BETWEEN TO_CHAR (TRUNC (v_tran_date, 'month'),
                                            'yyyymmdd'
                                           )
                               AND TO_CHAR
                                     (LAST_DAY (v_tran_date), 'yyyymmdd')
                                                   --Modified for defect 10044
         AND response_code = '00'
         AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N')  --Added for FWR-44
         AND customer_card_no = v_hash_pan
         AND customer_acct_no = v_saving_acct_number;
   --AND txn_code IN ('20', '11');       -- single qoute added in TXN_CODE
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from TRANSACTIONLOG for getting the number of transactions for s month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the number of transaction for a month(Saving to Spending)

   --En commented for MVCSD-4479

*/

  --Sn call to SP_SAVTOSPD_LIMIT_CHECK procedure added for MVCSD-4479

  BEGIN
      SP_SAVTOSPD_LIMIT_CHECK (p_inst_code,
                               p_delivery_channel,
                               p_txn_code,
                               v_hash_pan,
                               v_saving_acct_number,
                               v_acct_type,
                               v_tran_date,
                               p_tran_time,
                               p_resp_code,
                               v_errmsg,
                               v_svgtospd_trans
                                );

      IF p_resp_code <> '00' AND v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error from Saving account limit check' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En call to SP_SAVTOSPD_LIMIT_CHECK procedure added for MVCSD-4479



   --Sn Get the DFG paramers
   v_dfg_cnt:=0;  --added on 04-Oct-2013 for LYFEHOST-63
   BEGIN
      FOR i IN c (v_prodcode,v_cardtype)  -- v_prodcode added for LYFEHOST-63
      LOOP
         BEGIN
           IF i.cdp_param_key = 'MinSavingParam'
            THEN
               v_dfg_cnt:=v_dfg_cnt+1;
               v_min_svg_amt := i.cdp_param_value;
            ELSIF i.cdp_param_key = 'MaxNoTrans'
            THEN
               v_dfg_cnt:=v_dfg_cnt+1;
               v_max_svg_trns_limt := i.cdp_param_value;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :=
                     'Error while selecting Saving account parameters '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END LOOP;

       --Sn Added on 04-Oct-2013 for LYFEHOST-63
       IF v_dfg_cnt=0 THEN
        p_resp_code := '21';
        v_errmsg:='Saving account parameters is not defined for product '||v_prodcode;
        RAISE exp_reject_record;
       END IF;
       --En Added on 04-Oct-2013 for LYFEHOST-63
   EXCEPTION
      --Sn added by Pankaj S. during DFCCSD-70(Review) changes
      WHEN exp_reject_record THEN
        RAISE;
      --En added by Pankaj S. during DFCCSD-70(Review) changes
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error while opening cursor C ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get the DFG paramers

   --Sn Added on 04-Oct-2013 for LYFEHOST-63
   IF v_min_svg_amt IS NULL
   THEN
      p_resp_code := '21';
      v_errmsg :=
            'No data for selecting min Savings amt for product code '
         || v_prodcode
         || ' and instcode '
         || p_inst_code;
      RAISE exp_reject_record;
   ELSIF v_max_svg_trns_limt IS NULL
   THEN
      p_resp_code := '21';
      v_errmsg :=
            'No data for selecting max savings tran limit for product code '
         || v_prodcode
         || ' and instcode '
         || p_inst_code;
      RAISE exp_reject_record;
   END IF;
  --En Added on 04-Oct-2013 for LYFEHOST-63

   --Sn Checks validation
   IF p_txn_amt = 0
   THEN
      p_resp_code := '25';                           --Ineligible Transaction
      v_errmsg := 'INVALID AMOUNT ';
      RAISE exp_reject_record;
   END IF;

   IF v_savings_acct_balance < p_txn_amt
   THEN
      p_resp_code := '15';                           --Ineligible Transaction
      v_errmsg := 'Insufficient Balance';
      RAISE exp_reject_record;
   END IF;

--    IF  NOT (( P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40'))  THEN --Added by B.Besky  on 04/01/2013 for CR->40 not require this check for close saving account with balance. -- Commented for MOB-26
   IF NOT (   (p_delivery_channel = '07' AND p_txn_code = '21')
           OR (p_delivery_channel = '10' AND p_txn_code = '40')
           OR (p_delivery_channel = '13' AND p_txn_code = '12')
           OR (p_delivery_channel = '05' AND p_txn_code = '47')
          )                                             -- Modified for MOB-26
   THEN
      IF p_txn_amt < v_min_svg_amt
      THEN
         p_resp_code := '103';                       --Ineligible Transaction
         v_errmsg := 'Amount should not below the Minimum configured amount';
         RAISE exp_reject_record;
      END IF;

      IF p_delivery_channel IN ('10','13') AND (v_svgtospd_trans+1=v_max_svg_trns_limt) THEN
           IF p_svgacct_closrflag='Y' THEN
               v_svgacctclosr:='Y';
           ELSE
               p_resp_code := '260';
               v_errmsg := 'Saving Account Closure Confirmation required';
               RAISE exp_reject_record;
           END IF;
      END IF;

      IF v_svgtospd_trans >= v_max_svg_trns_limt
      THEN
         p_resp_code := '111';                       --Ineligible Transaction
         v_errmsg := 'Maximum number of transactions exceeded for a month';
         RAISE exp_reject_record;
      END IF;
   END IF;

   --En Checks validation

   --Sn call to authorize procedure
   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg,
                                 p_rrn,
                                 p_delivery_channel,
                                 v_term_id,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_bank_code,
                                 p_txn_amt,
                                 NULL,
                                 NULL,
                                 v_mcc_code,
                                 p_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                  /*Commented by Deepa as the Saving account number must be there in there narration
                                 of Spending account number's statements log entry*/
                                 v_saving_acct_number,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 v_card_expry,
                                 v_stan,
                                 '000',
                                 p_rvsl_code,
                                 p_txn_amt,
                                 v_auth_id,
                                 p_resp_code,
                                 v_errmsg,
                                 v_capture_date
                                );

      IF p_resp_code <> '00' AND v_errmsg <> 'OK'
      THEN
         RAISE exp_auth_reject_record;    --Updated by Ramesh.A on 25/05/2012
      END IF;
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN
         RAISE;                           --Updated by Ramesh.A on 25/05/2012
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En call to authorize procedure

   --Sn Update the Amount To acct no(Savings)
   BEGIN
      UPDATE cms_acct_mast
         SET cam_acct_bal = cam_acct_bal - p_txn_amt,
             cam_ledger_bal = cam_ledger_bal - p_txn_amt,
             cam_lupd_date = SYSDATE,
             cam_lupd_user = 1,
             CAM_SAVTOSPD_TFER_COUNT=DECODE(p_delivery_channel||p_txn_code,'0547',v_svgtospd_trans,v_svgtospd_trans+1), --Added for MVCSD-4479
             cam_acct_crea_tnfr_date=sysdate  --Added for Transactionlog Functional Removal Phase-II changes
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no = v_saving_acct_number
         AND cam_type_code = v_acct_type;

      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error while updating amount in to acct no(Savings) ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while updating amount in to acct no(Savings) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Update the Amount To acct no(Savings)

   ---Sn  Add a record in statements for TO ACCT (Savings)
   BEGIN


     /*                     -- Query commented as per review observation for LYFEHOST-63
      SELECT ctm_tran_desc
        INTO v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;

      */                   -- Query commented as per review observation for LYFEHOST-63


      IF TRIM (v_trans_desc) IS NOT NULL
      THEN
         v_narration := v_trans_desc || '/';
      END IF;

      IF TRIM (v_auth_id) IS NOT NULL
      THEN
         v_narration := v_narration || v_auth_id || '/';
      END IF;

      IF TRIM (v_acct_number) IS NOT NULL
      THEN
         v_narration := v_narration || v_acct_number || '/';
      END IF;

      IF TRIM (p_tran_date) IS NOT NULL
      THEN
         v_narration := v_narration || p_tran_date;
      END IF;


   EXCEPTION

    /*                              --SN:commented as per review observation for LYFEHOST-63
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'No records founds while getting narration '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      */                           --EN:Commented as per review observation for LYFEHOST-63

      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

  -- v_timestamp := SYSTIMESTAMP;                 --added by Pankaj S. fro 10871 -- commented on 29-08-2013 for FSS-1144

   BEGIN
      v_dr_cr_flag := 'DR';

      INSERT INTO cms_statements_log
                  (csl_pan_no, csl_acct_no, -- Added by Ramesh.A on 27/03/2012
                   csl_opening_bal, csl_trans_amount, csl_trans_type,
                   csl_trans_date,
                   csl_closing_balance,
                   csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                   csl_auth_id, csl_business_date, csl_business_time,
                   txn_fee_flag, csl_delivery_channel, csl_inst_code,
                   csl_txn_code, csl_ins_date, csl_ins_user,
                   csl_panno_last4digit,
                   csl_to_acctno,
--Added by Deepa on July 20-2012 to include to account number for Debit transaction
                                 --Sn added by Pankaj S. fro 10871
                                 csl_acct_type, csl_prod_code,csl_card_type,
                   csl_time_stamp
                  --En added by Pankaj S. fro 10871
                  )
           --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
      VALUES      (v_hash_pan, v_saving_acct_number,
                   -- Added by Ramesh.A on 27/03/2012
                   v_savings_ledger_balance,
--v_savings_acct_balance, replaced by pankaj s. with v_savings_ledger_balance for 10871
                                            p_txn_amt, 'DR',
                   v_tran_date,
                   DECODE
                      (v_dr_cr_flag,
                       'DR', v_savings_ledger_balance - p_txn_amt,
--v_savings_acct_balance, replaced by pankaj s. with v_savings_ledger_balance for 10871
                       'CR', v_savings_ledger_balance + p_txn_amt,
--v_savings_acct_balance, replaced by pankaj s. with v_savings_ledger_balance for 10871
                       'NA', v_savings_ledger_balance
--v_savings_acct_balance, replaced by pankaj s. with v_savings_ledger_balance for 10871
                      ),
                   v_narration, v_encr_pan_from, p_rrn,
                   v_auth_id, p_tran_date, p_tran_time,
                   'N', p_delivery_channel, p_inst_code,
                   p_txn_code, SYSDATE, 1,
                   (SUBSTR (p_pan_code,
                            LENGTH (p_pan_code) - 3,
                            LENGTH (p_pan_code)
                           )
                   ),                     -- Updated by Ramesh.A on 18/06/2012
                   p_spd_acct_no,
--Added by Deepa on July 20-2012 to include to account number for Debit transaction
                                 --Sn added by Pankaj S. fro 10871
                                 v_acct_type, v_prodcode,v_cardtype,
                   v_timestamp
                  --En added by Pankaj S. fro 10871
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error creating entry in statement log ';
         RAISE exp_reject_record;
   END;

   --Sn added by Pankaj S. for 10871
   BEGIN
   --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
	   
	    v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');
       
IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE cms_statements_log
         SET csl_time_stamp = v_timestamp
       WHERE csl_inst_code = p_inst_code
         AND csl_pan_no = v_hash_pan
         AND csl_rrn = p_rrn
         AND csl_txn_code = p_txn_code
         AND csl_delivery_channel = p_delivery_channel
         AND csl_business_date = p_tran_date
         AND csl_business_time = p_tran_time;
       else
         UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
         SET csl_time_stamp = v_timestamp
       WHERE csl_inst_code = p_inst_code
         AND csl_pan_no = v_hash_pan
         AND csl_rrn = p_rrn
         AND csl_txn_code = p_txn_code
         AND csl_delivery_channel = p_delivery_channel
         AND csl_business_date = p_tran_date
         AND csl_business_time = p_tran_time;
       end if;    

    --Sn Commented by Pankaj S. during DFCCSD-70(Review) changes
     -- IF SQL%ROWCOUNT = 0
     -- THEN
     --    NULL;
     --    RAISE exp_reject_record;
     -- END IF;

   EXCEPTION
      --WHEN exp_reject_record
      --THEN
      --   RAISE exp_reject_record;
      --En Commented by Pankaj S. during DFCCSD-70(Review) changes
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while updating timestamp in statementlog-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En added by Pankaj S. for 10871
   BEGIN
      sp_daily_bin_bal (p_pan_code,
                        v_tran_date,
                        p_txn_amt,
                        v_dr_cr_flag,
                        p_inst_code,
                        p_bank_code,
                        v_errmsg
                       );

      IF v_errmsg <> 'OK'
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error while executing daily_bin log ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error creating entry in daily_bin log ';
         RAISE exp_reject_record;
   END;

   --En  Add a record in statements lof for TO ACCT(Savings) -----------------

   --Sn Get Savings Acc number
   BEGIN
      SELECT cam_acct_bal,
             cam_ledger_bal
 -- Added cam_ledger_bal by siva kumar m on 17/04/2013 for the defect id:10869
        INTO v_savings_acct_balance,
             v_savings_ledger_balance
        FROM cms_acct_mast
       WHERE cam_acct_no = v_saving_acct_number
         AND cam_type_code = v_acct_type
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Data not available for savings acc number 1'
            || v_saving_acct_number;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting savings acc number 1'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Savings Acc number
     --Sn Get Spending Acc Balance
   BEGIN
      SELECT cam_acct_bal,
             cam_ledger_bal
        INTO v_acct_balance,
             v_ledger_balance       --v_spd_acct_balance, v_spd_ledger_balance
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number
         AND cam_type_code = v_spd_acct_type
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';
         v_errmsg :=
                'No data for selecting spending acc number ' || v_acct_number;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting spending acc number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Spending Acc Balance

   --Sn Append respcode 2
   v_svgtospd_trans := v_svgtospd_trans + 1;
   p_availed_txn := v_svgtospd_trans;
-- Added by B.Besky  on 04/01/2013 for CR->40 To give the availed transaction as the output.
   p_available_txn := v_max_svg_trns_limt - v_svgtospd_trans;
--Added by B.Besky  on 04/01/2013 for CR->40 To give the available transaction as the output.
   p_resp_code := '1';
   p_resmsg := TRIM (TO_CHAR (v_savings_acct_balance, '99999999999999990.99'));
   --Updated by Ramesh.A on 08/03/2012
   v_errmsg := 'Funds Transferred Successfully'; --Spelling changed by Dayanand for MANTIS:12326
   p_spenacctbal := TRIM (TO_CHAR (v_acct_balance, '99999999999999990.99'));
                                    -- Added by siva kumar m as on 06/Aug/2012
   p_spenacctledgbal :=
                     TRIM (TO_CHAR (v_ledger_balance, '99999999999999990.99'));
                                   -- Added by siva kumar m as on 06/Aug/2012;

   IF v_max_svg_trns_limt = v_svgtospd_trans
   THEN
      p_resmsg :=
             p_resmsg || '~This is the last transaction for a calendar month';
   -- updated by ramesh on 08/03/12
   END IF;

   --En Append respcode 2

   --ST Get responce code fomr master
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
         p_resp_code := '21';
         v_errmsg := 'Responce code not found ' || p_resp_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '69';               ---ISO MESSAGE FOR DATABASE ERROR
         v_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;  --Added by Pankaj S. during DFCCSD-70(Review) changes
   END;

   --En Get responce code fomr master

   --Sn update topup card number details in translog
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
         SET topup_card_no = v_hash_pan,
             topup_card_no_encr = v_encr_pan_from,
             topup_acct_no = v_acct_number,
             --Sn added by Pankaj S. for DFCCSD-70 changes
             topup_acct_balance=v_acct_balance,
             topup_ledger_balance=v_ledger_balance,
             --En added by Pankaj S. for DFCCSD-70 changes
             txn_status = 'C',
             ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress,
             topup_acct_type = v_spd_acct_type,
             total_amount = TRIM (TO_CHAR (p_txn_amt, '99999999999999990.99')),
             acct_balance = v_savings_acct_balance,
             ledger_balance = v_savings_ledger_balance,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no = v_saving_acct_number,
             --response_id = p_resp_code,  --Commented by Pankaj S. during DFCCSD-70(Review) changes
             error_msg = v_errmsg,  -- Added by siva kumar m as on 06/Aug/2012
            -- time_stamp = v_timestamp,          --added by Pankaj S. for 10871 -- commented for FSS-1144
             acct_type = v_acct_type                      --shweta on 03June13
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
       ELSE
             UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET topup_card_no = v_hash_pan,
             topup_card_no_encr = v_encr_pan_from,
             topup_acct_no = v_acct_number,
             --Sn added by Pankaj S. for DFCCSD-70 changes
             topup_acct_balance=v_acct_balance,
             topup_ledger_balance=v_ledger_balance,
             --En added by Pankaj S. for DFCCSD-70 changes
             txn_status = 'C',
             ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress,
             topup_acct_type = v_spd_acct_type,
             total_amount = TRIM (TO_CHAR (p_txn_amt, '99999999999999990.99')),
             acct_balance = v_savings_acct_balance,
             ledger_balance = v_savings_ledger_balance,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no = v_saving_acct_number,
             --response_id = p_resp_code,  --Commented by Pankaj S. during DFCCSD-70(Review) changes
             error_msg = v_errmsg,  -- Added by siva kumar m as on 06/Aug/2012
            -- time_stamp = v_timestamp,          --added by Pankaj S. for 10871 -- commented for FSS-1144
             acct_type = v_acct_type                      --shweta on 03June13
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;  
     END IF;
      IF SQL%ROWCOUNT <> 1
      THEN
         p_resp_code := '21';
         v_errmsg :=
                'Error while updating transactionlog ' || 'no valid records ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

--En update topup card number details in translog

   --Sn Shweta on 05June13 for defect ID DFCCSD-70
   BEGIN
   
--Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
	   
	   	    v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE cms_transaction_log_dtl
         SET ctd_cust_acct_number = v_saving_acct_number  --shweta on 03June13
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_msg_type = p_msg
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_inst_code;
      else
      UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST --Added for VMS-5733/FSP-991
         SET ctd_cust_acct_number = v_saving_acct_number  --shweta on 03June13
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_msg_type = p_msg
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_inst_code;
      end if;   

      IF SQL%ROWCOUNT <> 1
      THEN
         p_resp_code := '21';
                  --need 2 confirm (TRANSACTION DECLINED DUE TO SYSTEM ERROR)
         v_errmsg :=
               'Error while updating cms_transaction_log_dtl '
            || 'no valid records ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN                                   --Added by Ramesh.A on 08/03/2012
         RAISE exp_reject_record;           --Added by Ramesh.A on 08/03/2012
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while updating cms_transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
--En Shweta on 05June13 for defect ID DFCCSD-70

  IF v_svgacctclosr='Y' THEN
       p_resmsg:='C';
  END IF;

  IF (p_delivery_channel ='05' and p_txn_code='47') THEN
       p_resmsg:='OK';
  END IF;

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
   WHEN exp_auth_reject_record THEN                                      --Added by Ramesh.A on 25/05/2012
--ROLLBACK ;  Commented by Besky on 06-nov-12

     --Sn Added by Pankaj S. for DFCCSD-70 changes
   BEGIN
   IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET customer_acct_no=v_saving_acct_number,
             acct_type=v_acct_type,
             acct_balance = v_savings_acct_balance,
             ledger_balance = v_savings_ledger_balance,
             topup_card_no = v_hash_pan,
             topup_card_no_encr = v_encr_pan_from,
             topup_acct_no = v_acct_number,
             topup_acct_type = v_spd_acct_type,
             topup_acct_balance=v_acct_balance,
             topup_ledger_balance=v_ledger_balance
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
  else
  UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET customer_acct_no=v_saving_acct_number,
             acct_type=v_acct_type,
             acct_balance = v_savings_acct_balance,
             ledger_balance = v_savings_ledger_balance,
             topup_card_no = v_hash_pan,
             topup_card_no_encr = v_encr_pan_from,
             topup_acct_no = v_acct_number,
             topup_acct_type = v_spd_acct_type,
             topup_acct_balance=v_acct_balance,
             topup_ledger_balance=v_ledger_balance
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
     end if;    
      IF SQL%ROWCOUNT <> 1 THEN
         p_resp_code := '21';
         v_errmsg :='Error while updating transactionlog ';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_resp_code := '21';
         v_errmsg :='Error while updating transactionlog '|| SUBSTR (SQLERRM, 1, 200);
   END;
   BEGIN
   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
	   
	   	    v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE cms_transaction_log_dtl
         SET ctd_cust_acct_number = v_saving_acct_number
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_msg_type = p_msg
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_inst_code;
     else
        UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST --Added for VMS-5733/FSP-991
         SET ctd_cust_acct_number = v_saving_acct_number
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_msg_type = p_msg
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_inst_code;       
  end if; 
      IF SQL%ROWCOUNT <> 1 THEN
         p_resp_code := '21';
         v_errmsg :='Error while updating transaction details ';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_resp_code := '21';
         v_errmsg :='Error while updating transaction log dtl '|| SUBSTR (SQLERRM, 1, 200);
   END;
   --En Added by Pankaj S for DFCCSD-70 changes
      p_resmsg := v_errmsg;                     --Added by Besky on 06-nov-12
--TO v_auth_savepoint;
   WHEN exp_reject_record THEN
      ROLLBACK;                                        --TO v_auth_savepoint;
      p_resmsg := v_errmsg;
      v_resp_cde := p_resp_code;
     --added by Pankaj S. for 10871 (to logging proper response_id in txnlog)

      --Sn Get responce code fomr master
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
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;

      --En Get responce code fomr master

      --Sn Added by Pankaj S. for DFCCSD-70 changes(Get Savings Acc number)
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_savings_ledger_balance,v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_svg_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_savings_ledger_balance:=0;
       END;
       --En Added by Pankaj S. for DFCCSD-70 changes(Get Savings Acc number)

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL
      THEN
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
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prodcode IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_cust_code,cap_acct_no
              INTO v_prodcode, v_cardtype, v_cardstat,v_cust_code, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = gethash (p_pan_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      --En added by Pankaj S. for 10871

      --Sn Added by Pankaj S. for DFCCSD-70 changes
      IF v_acct_balance IS NULL THEN
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
           INTO v_acct_balance, v_ledger_balance,v_spd_acct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
     --En Added by Pankaj S. for DFCCSD-70 changes

      --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, cardstatus, trans_desc,
                      response_id,--Added cardstatus insert in transactionlog by srinivasu.k
                      --Sn added by Pankaj S. for 10871
                      productid, categoryid, cr_dr_flag,acct_type,time_stamp,
                      --En added by Pankaj S. for 10871
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      acct_balance,ledger_balance,topup_card_no,
                      topup_card_no_encr,topup_acct_no,topup_acct_type,
                      topup_acct_balance,topup_ledger_balance
                      --En Added by Pankaj S. for DFCCSD-70 changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      --shweta on 2ndJune13    p_inst_code, v_encr_pan_from, v_acct_number,
                      p_inst_code, v_encr_pan_from, p_svg_acct_no,
                                                         --shweta on 2ndJune13
                      v_errmsg, p_ipaddress, v_cardstat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                                                        v_trans_desc,
                      v_resp_cde,-- p_resp_code, --modified by Pankaj S. for 10871(to logging proper resp id)
                      --Sn added by Pankaj S. for 10871
                      v_prodcode, v_cardtype, v_dr_cr_flag,v_acct_type,v_timestamp,--Modified on 29-08-2013 for FSS-1144
                      --En added by Pankaj S. for 10871
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      v_savings_acct_balance,v_savings_ledger_balance,v_hash_pan,
                      v_encr_pan_from,v_acct_number,v_spd_acct_type,
                      v_acct_balance, v_ledger_balance
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :='Exception while inserting to transaction log '|| SUBSTR (SQLERRM, 1, 300);--|| SQLCODE|| '---'|| SQLERRM;  modified by Pankaj S. during DFCCSD-70(Review) changes
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, p_curr_code, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan_from, p_msg,
                                              -- Added by Ramesh.A on 27/03/2012
                      '',
                      --Shweta on 03June13 for defect ID DFCCSD-70  v_acct_number, ''
                      p_svg_acct_no, '',                   --Shweta on 03June13
                      V_HASHKEY_ID  --Added  on 29-08-2013 for Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
           -- RETURN;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
    p_resmsg := v_errmsg;  --Added by Pankaj S. during DFCCSD-70(Review) changes
   --Sn Handle OTHERS Execption
   WHEN OTHERS
   THEN
      p_resp_code := '21';
      v_errmsg := 'Main Exception ' || SUBSTR (SQLERRM, 1, 300);--|| SQLCODE|| '---'|| SQLERRM;  modified by Pankaj S. during DFCCSD-70(Review) changes
      ROLLBACK;                                       -- TO v_auth_savepoint;
      p_resmsg := v_errmsg;
      v_resp_cde := p_resp_code;
     --added by Pankaj S. for 10871 (to logging proper response_id in txnlog)

      --Sn Get responce code fomr master
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
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;
      --En Get responce code fomr master


      --Sn Added by Pankaj S. for DFCCSD-70 changes(Get Savings Acc number)
       BEGIN
       SELECT cam_acct_bal,cam_ledger_bal,cam_type_code
        INTO  v_savings_acct_balance,v_savings_ledger_balance,v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no=p_svg_acct_no;
       EXCEPTION
          WHEN OTHERS THEN
          v_savings_acct_balance:=0;
          v_savings_ledger_balance:=0;
       END;
       --En Added by Pankaj S. for DFCCSD-70 changes(Get Savings Acc number)

      --Sn added by Pankaj S. during DFCCSD-70(Review) changes
      IF v_dr_cr_flag IS NULL
      THEN
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
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prodcode IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
              INTO v_prodcode, v_cardtype, v_cardstat, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = gethash (p_pan_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      --Sn added by Pankaj S. during DFCCSD-70(Review) changes

      IF v_spd_acct_type IS NULL THEN
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
           INTO v_acct_balance, v_ledger_balance,v_spd_acct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
     --En Added by Pankaj S. for DFCCSD-70 changes


      --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, cardstatus, trans_desc,
                      response_id,--Added cardstatus insert in transactionlog by srinivasu.k
                      --Sn added by Pankaj S. for 10871
                      productid, categoryid, cr_dr_flag,acct_type,time_stamp,
                      --En added by Pankaj S. for 10871
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      acct_balance,ledger_balance,topup_card_no,
                      topup_card_no_encr,topup_acct_no,topup_acct_type,
                      topup_acct_balance,topup_ledger_balance
                      --En Added by Pankaj S. for DFCCSD-70 changes
                     )
              VALUES (p_msg,              -- Updated by Ramesh.A on 27/03/2012
                            p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      --shweta on 2ndJune13    p_inst_code, v_encr_pan_from, v_acct_number,
                      p_inst_code, v_encr_pan_from, p_svg_acct_no,
                                 --shweta on 2ndJune13 for defect ID DFCCSD-70
                      v_errmsg, p_ipaddress, v_cardstat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                      v_trans_desc,v_resp_cde,-- p_resp_code, --modified by Pankaj S. for 10871(to logging proper resp id)
                      --Sn added by Pankaj S. for 10871
                      v_prodcode, v_cardtype, v_dr_cr_flag,v_acct_type,v_timestamp,--Modified on 29-08-2013 for FSS-1144
                      --En added by Pankaj S. for 10871
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                      v_savings_acct_balance,v_savings_ledger_balance,v_hash_pan,
                      v_encr_pan_from,v_acct_number,v_spd_acct_type,
                      v_acct_balance, v_ledger_balance
                      --Sn Added by Pankaj S. for DFCCSD-70 changes
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :='Exception while inserting to transaction log '|| SUBSTR (SQLERRM, 1, 300);--|| SQLCODE|| '---'|| SQLERRM;  modified by Pankaj S. during DFCCSD-70(Review) changes
            --RAISE exp_reject_record;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number,
                      ctd_addr_verify_response,CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, p_curr_code, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE,
                      v_encr_pan_from, p_msg,
                                              -- Added by Ramesh.A on 27/03/2012
                      '',
                      --Shweta on 03June13    v_acct_number, ''
                      p_svg_acct_no,
                      '',          --Shweta on 03June13 for defect ID DFCCSD-70
                      V_HASHKEY_ID  --Added  on 29-08-2013 for Fss-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            --RETURN;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;
--En Inserting data in transactionlog dtl
   p_resmsg := v_errmsg;  --Added by Pankaj S. during DFCCSD-70(Review) changes
END;
/
show error