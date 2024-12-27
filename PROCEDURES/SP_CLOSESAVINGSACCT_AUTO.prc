set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.sp_closesavingsacct_auto
AS
     /*************************************************
     * Created Date     :  09-Mar-2012
     * Created By       :  Siva Kumar M
     * PURPOSE          :  Automatic Savings Account Close.
     * Modified Reason  :  Exception handling changes
     * Modified Date    :  06-nov-12
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  06-nov-12
     * Build Number     :  CMS3.5.1_RI0021_B0003

     * Modified By      :  Saravanakumar
     * Modified Reason  :  for CR - 40 phase 2
     * Modified Date    :  23-Jan-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  23-Jan-2013
     * Build Number     :  CMS3.5.1_RI0023.1_B0005

     * Modified By      :  Pankaj S.
     * Modified Reason  :  Defect Id-10081
     * Modified Date    :  25-Jan-2013
     * Reviewer         :  Dhiraj G.
     * Reviewed Date    :  25-Jan-2013
     * Build Number     :  CMS3.5.1_RI0023.1_B0010

     * Modified By      : Sagar M.
     * Modified Date    : 18-Apr-2013
     * Modified for     : 10871
     * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
     * Reviewer         : Dhiraj
     * Reviewed Date    : 18-Apr-2013
     * Build Number     : RI0024.1_B0010

     * Modified By      : S Ramkumar.
     * Modified Date    : 13-June-2013
     * Modified for     : 11153
     * Modified Reason  : Changes for Duplicate data found
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.2_B0004

     * Modified by      :  Santosh Palo
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  11-Jun-2013
     * Reviewer         :  Sachin P.
     * Reviewed Date    :  17-Jun-2013
     * Build Number     :  RI0024.2_B0004

     * Modified by      :  Pankaj S.
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  23-Aug-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  22-Aug-2013
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

    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

	 * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07

	* Modified by       : UBAIDUR RAHMAN.H
    * Modified Date     : 06-Nov-19.
    * Modified For      : VMS-1138 -- Implementation for adding missing Primary Key
										for VMS Table "CMS_INACTIVESAVINGS_ACCT" - Phase 2
    * Reviewer          : Saravanakumar A
    * Build Number      : VMSGPRHOST_R22_B2
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

   *************************************************/
   v_spending_acctid        cms_appl_pan.cap_acct_id%TYPE;
   v_spending_acctno        cms_appl_pan.cap_acct_no%TYPE;
   v_pan_code               VARCHAR2 (100);
   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_savings_bal            cms_acct_mast.cam_acct_bal%TYPE;
   v_saving_ledger_bal      cms_acct_mast.cam_ledger_bal%TYPE;
   last_txn_date            transactionlog.business_date%TYPE;
   v_idle_time              cms_dfg_param.cdp_param_value%TYPE;
   v_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   v_switch_spndacct_type   cms_acct_type.cat_switch_type%TYPE   DEFAULT '11';
   v_acct_type              cms_acct_type.cat_type_code%TYPE;
   v_spndacct_type          cms_acct_type.cat_type_code%TYPE;
   v_switch_acct_stats      cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '2';
   --Added by sivakumar on 12/03/2012
   v_acct_statcode          cms_acct_mast.cam_stat_code%TYPE;
   v_tran_date              VARCHAR2 (10);
   --modified by sivakumar on 12/03/2012
   v_tran_time              VARCHAR2 (10);
   day_diff                 NUMBER (8);
   v_inst_code              VARCHAR2 (3);
   v_errmsg                 VARCHAR2 (500);
   v_rrn1                   NUMBER (10);
   v_rrn2                   VARCHAR2 (15);
   v_term_id                VARCHAR2 (20);
   v_mcc_code               VARCHAR2 (4);
   v_card_expry             VARCHAR2 (5);
   v_stan                   VARCHAR2 (12);
   v_capture_date           DATE;
   v_auth_id                transactionlog.auth_id%TYPE;
   -- Modified the data type by sivakumar on 12/03/2012
   v_resp_code              VARCHAR2 (4);
   -- upadtaed by sivakumar.m on 14/03/2012
   v_trans_desc             VARCHAR2 (50);
   v_narration              VARCHAR2 (300);
   v_dr_cr_flag             VARCHAR2 (4)                         DEFAULT 'DR';
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_delivery_channel       VARCHAR2 (2)                         DEFAULT '05';
   v_txn_code               VARCHAR2 (2)                         DEFAULT '12';
   v_tran_bindate           DATE;          --Added by sivakumar on 12/03/2012
   v_msg_type               VARCHAR2 (10)                      DEFAULT '0200';
   --Added by sivakumar on 15/03/2012
   v_txn_mode               VARCHAR2 (1)                          DEFAULT '0';
   --Added by sivakumar on 15/03/2012
   v_curr_code              VARCHAR2 (5)                        DEFAULT '840';
   --Added by sivakumar on 15/03/2012
   v_rvsl_code              VARCHAR2 (3)                         DEFAULT '00';
   --Added by sivakumar on 15/03/2012
   v_cardstat               NUMBER (5);     --Added by ramesh.a on 11/04/2012
   v_interest_forfeited     NUMBER;         --Added by ramesh.a on 27/04/2012
   exp_reject_record        EXCEPTION;
   exp_reject_rec           EXCEPTION;
   exp_auth_reject_record   EXCEPTION;      --Added by Ramesh.A on 22/05/2012
   v_saving_type_code       cms_acct_mast.cam_type_code%TYPE;
                                     -- added on 18-Apr-2013 for defect 10871
   v_timestamp              TIMESTAMP;
                                     -- Added on 18-Apr-2013 for defect 10871
   v_spending_acct_type     cms_acct_mast.cam_type_code%TYPE;
                                     -- added on 18-Apr-2013 for defect 10871
   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
                                     -- added on 18-Apr-2013 for defect 10871
   v_prod_cattype           cms_prod_cattype.cpc_card_type%TYPE;
                                     -- added on 18-Apr-2013 for defect 10871
   v_cr_dr_flag             cms_transaction_mast.CTM_CREDIT_DEBIT_FLAG%TYPE;   -- modified during LYFEHOST-63 testing
                                     -- added on 18-Apr-2013 for defect 10871
   v_saving_acct_id         cms_acct_mast.cam_acct_id%TYPE;
                                     -- added on 18-Apr-2013 for defect 10871
   v_savacc_pancount        NUMBER                                DEFAULT '0';
           --Added for Mantis - 11153     on      10th, June 2013  Ramkumar.S
   v_savacc_trancount       NUMBER                                DEFAULT '0';
           --Added for Mantis - 11153     on      10th, June 2013  Ramkumar.S
   v_cust_code              cms_appl_pan.cap_cust_code%TYPE;
           --Added for Mantis - 11153     on      10th, June 2013  Ramkumar.S

   --Sn Added by Pankaj S. for DFCCSD-70
   v_acct_balance         cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance       cms_acct_mast.cam_ledger_bal%TYPE;
   v_cca_cust_code        cms_cust_acct.cca_cust_code%TYPE;
      v_Retperiod  date; --Added for VMS-5733/FSP-991
      v_Retdate  date; --Added for VMS-5733/FSP-991
   --En Added by Pankaj S. for DFCCSD-70
   CURSOR acctno(instcode       NUMBER)  --Modified as parameterised cursor by Pankaj S. during DFCCSD-70(Review) changes
   IS
      SELECT cam_acct_no, cam_inst_code,
             cam_acct_id,cam_acct_bal, cam_ledger_bal,cam_interest_amount, cam_type_code,   --Added by Pankaj S. during DFCCSD-70(Review) changes
             cam_acct_crea_tnfr_date  --Added for Transactionlog Functional Removal Phase-II changes
        FROM cms_acct_mast
       WHERE cam_type_code = 2 AND cam_stat_code = 8
         AND cam_inst_code=instcode; --Added by Pankaj S. during DFCCSD-70(Review) changes

   CURSOR code
   IS
      SELECT cim_inst_code
        FROM cms_inst_mast;

   --Added for Mantis - 11153     on      10th, June 2013       Ramkumar.S
   CURSOR spending_acc (
      --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
      cust_code NUMBER,
      --savacc_no      VARCHAR2,
      --savacct_type   NUMBER,
      --En Modified by Pankaj S. during DFCCSD-70(Review) changes
      instcode       NUMBER
   )
   IS
      SELECT   cap_acct_id, cap_acct_no,
               fn_dmaps_main (cap_pan_code_encr) AS pancode, cap_card_stat,
               cap_prod_code, cap_card_type,           --Added on defect 10871
               cap_pan_code_encr,cap_pan_code  --Added by Pankaj S. during DFCCSD-70(Review) changes
          FROM cms_appl_pan
         WHERE cap_inst_code = instcode
         --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
           AND cap_cust_code =cust_code
           /*       (SELECT cca_cust_code
                     FROM cms_cust_acct
                    WHERE cca_acct_id =
                             (SELECT cam_acct_id
                                FROM cms_acct_mast
                               WHERE cam_type_code = savacct_type
                                 AND cam_acct_no = savacc_no
                                 AND cam_inst_code = instcode)
                      AND cca_inst_code = instcode)*/
        --En Modified by Pankaj S. during DFCCSD-70(Review) changes
           AND cap_addon_stat = 'P'
      ORDER BY cap_pangen_date DESC;
BEGIN
   v_rrn1 := 0;

   --SAVEPOINT v_auth_savepoint;
   FOR i IN code
   LOOP
      BEGIN
         v_inst_code := i.cim_inst_code;

         BEGIN
            SELECT ctm_tran_desc,
                   CTM_CREDIT_DEBIT_FLAG           --dr/cr flag added for defect 10871 --  modified during LYFEHOST-63 testing
              INTO v_trans_desc,
                   v_cr_dr_flag
              FROM cms_transaction_mast
             WHERE ctm_inst_code = v_inst_code
               AND ctm_tran_code = v_txn_code
               AND ctm_delivery_channel = v_delivery_channel;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_errmsg := 'No records founds while getting narration ';
               RAISE exp_reject_rec;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_errmsg :=
                     'Error in finding the narration '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_rec;
         END;

         --Sn select spending acct type
         BEGIN
            SELECT cat_type_code
              INTO v_spndacct_type                   --spending account type 1
              FROM cms_acct_type
             WHERE cat_inst_code = v_inst_code
               AND cat_switch_type = v_switch_spndacct_type;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_errmsg := 'Switch spedning Acct type not defined in master'; -- Change in error message as per review observation for LYFEHOST-63
               RAISE exp_reject_rec;
            WHEN OTHERS
            THEN
               v_resp_code := '12';
               v_errmsg :=
                     'Error while selecting accttype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_rec;
         END;

         -- en select spending acct type.

         --Sn select savings acct type
         BEGIN
            SELECT cat_type_code
              INTO v_acct_type                           --savings acct type 2
              FROM cms_acct_type
             WHERE cat_inst_code = v_inst_code
               AND cat_switch_type = v_switch_acct_type;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_errmsg := 'Acct type not defined in master';
               --CONTINUE;
               RAISE exp_reject_rec;
            WHEN OTHERS
            THEN
               v_resp_code := '12';
               v_errmsg :=
                     'Error while selecting accttype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_rec;
         END;

         -- en select savings acct type.

         -- Added by sivakumar on 12/03/2012.

         -- Sn select savings acct status.
         BEGIN
            SELECT cas_stat_code
              INTO v_acct_statcode
              FROM cms_acct_stat
             WHERE cas_inst_code = v_inst_code
               AND cas_switch_statcode = v_switch_acct_stats;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_errmsg := 'ERROR WHILE SELECTING SAVINGS ACCT STATUS';
               RAISE exp_reject_rec;
            WHEN OTHERS
            THEN
               v_resp_code := '12';
               v_errmsg :=
                     'ERROR WHILE SELECTING ACCT STATUS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_rec;
         END;

         --En select savinsgs acct status.

         -- Added by sivakumar on 12/03/2012
         BEGIN
            --SAVEPOINT v_auth_savepoint;
            FOR savingsno IN acctno(i.cim_inst_code)  --Modified as parameterised cursor by Pankaj S. during DFCCSD-70(Review) changes
            LOOP
               v_auth_savepoint := v_auth_savepoint + 1;
               SAVEPOINT v_auth_savepoint;
               v_errmsg := 'OK';

               BEGIN
                  --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
                  BEGIN
                  SELECT cca_cust_code
                     INTO v_cca_cust_code
                     FROM cms_cust_acct
                    WHERE cca_acct_id =savingsno.cam_acct_id;
                  EXCEPTION
                  WHEN OTHERS THEN
                   v_resp_code := '12';
                   v_errmsg :='ERROR WHILE SELECTING CUST CODE'|| SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
                  END;
                  --En Modified by Pankaj S. during DFCCSD-70(Review) changes

                  --SN GETTING TRAN DATE AND TIME'
                  BEGIN
                     SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                            TO_CHAR (SYSDATE, 'HH24MISS'), SYSDATE
                       INTO v_tran_date,
                            v_tran_time, v_tran_bindate
                       FROM DUAL;          --Added by sivakumar on 12/03/2012.
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_resp_code := '21';
                        v_errmsg := 'ERROR WHILE GETTING DATE AND TIME';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_resp_code := '12';
                        v_errmsg :=
                              'ERROR WHILE GETTING DATE AND TIME'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  -- EN GETTING TRAN DATE AND TIME.
                  v_rrn1 := v_rrn1 + 1;
                  v_rrn2 := 'AC000' || v_rrn1;

                  --SN Modified for Mantis - 11153     on      10th, June 2013      Ramkumar.S
                  --SN SPENDING ACCOUNT NUMBER
                  BEGIN
                     FOR s IN spending_acc (
                                            v_cca_cust_code,--savingsno.cam_acct_no,
                                            --v_acct_type,
                                            v_inst_code
                                           )
                     LOOP
                        v_savacc_pancount := spending_acc%ROWCOUNT;

                        --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
                        v_encr_pan_from :=s.cap_pan_code_encr;
                        v_hash_pan := s.cap_pan_code;
                        /*--Sn Get the HashPan
                        BEGIN
                           v_hash_pan := gethash (s.pancode);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_code := '12';
                              v_errmsg :=
                                    'Error while converting pan '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;

                        --En Get the HashPan

                        --Sn Create encr pan
                        BEGIN
                           v_encr_pan_from := fn_emaps_main (s.pancode);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_code := '12';
                              v_errmsg :=
                                    'Error while converting pan '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                        --En Create encr pan*/
                        --En Modified by Pankaj S. during DFCCSD-70(Review) changes

                        BEGIN
                          IF savingsno.cam_acct_crea_tnfr_date IS NULL THEN  --Condition added for transactionlog Functional Removal Phase-II changes
                           SELECT MAX (business_date)
                             INTO last_txn_date
                             FROM transactionlog
                            WHERE response_code = '00'
                              AND instcode = v_inst_code
                              AND customer_card_no = v_hash_pan
                              AND (   (    delivery_channel = '07'
                                       AND txn_code IN ('10', '11', '14')
                                      )
                                   OR (    delivery_channel = '10'
                                       AND txn_code IN
                                                     ('18', '19', '20', '32')
                                      )
                                   OR (    delivery_channel = '13'
                                       AND txn_code IN ('04', '11')
                                      )
                                  );
                         if (last_txn_date is null)
                         then
                                 SELECT MAX (business_date)
                             INTO last_txn_date
                             FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                            WHERE response_code = '00'
                              AND instcode = v_inst_code
                              AND customer_card_no = v_hash_pan
                              AND (   (    delivery_channel = '07'
                                       AND txn_code IN ('10', '11', '14')
                                      )
                                   OR (    delivery_channel = '10'
                                       AND txn_code IN
                                                     ('18', '19', '20', '32')
                                      )
                                   OR (    delivery_channel = '13'
                                       AND txn_code IN ('04', '11')
                                      )
                                  ); 
                           end if;               
                          ELSE    --Added for transactionlog Functional Removal Phase-II changes
                              last_txn_date:=to_char(savingsno.cam_acct_crea_tnfr_date,'YYYYMMDD');  --Added for transactionlog Functional Removal Phase-II changes
                          END IF;   --Added for transactionlog Functional Removal Phase-II changes
                           v_spending_acctid := s.cap_acct_id;
                           v_spending_acctno := s.cap_acct_no;
                           v_pan_code := s.pancode;
                           v_cardstat := s.cap_card_stat;
                           v_prod_code := s.cap_prod_code;
                           v_prod_cattype := s.cap_card_type;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_savacc_trancount := v_savacc_trancount + 1;

                              IF v_savacc_pancount = v_savacc_trancount
                              THEN
                                 v_resp_code := '21';
                                 v_errmsg :=
                                    'Error while selecting last transaction date';
                                 RAISE exp_reject_record;
                              END IF;
                           WHEN OTHERS
                           THEN
                              v_resp_code := '12';
                              v_errmsg :=
                                    'Error while selecting last transaction date '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;

                        --EN  SELECTING LAST TRANSACTION DATE.
                        EXIT WHEN last_txn_date IS NOT NULL;
                     END LOOP;

                     IF NVL (v_savacc_pancount, 0) = 0
                     THEN
                        RAISE NO_DATA_FOUND;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_resp_code := '21';
                        v_errmsg := 'Account details not defined';
                        RAISE exp_reject_record;
                    --Sn Added by Pankaj S. during DFCCSD-70(Review) Changes
                     WHEN OTHERS THEN
                       v_resp_code := '21';
                        v_errmsg := 'Error while Selecting Account details-' || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
                    --En Added by Pankaj S. during DFCCSD-70(Review) Changes
                  END;

                  --EN SPENDING ACCOUNT NUMBER.
                  --EN Modified for Mantis - 11153     on      10th, June 2013      Ramkumar.S


                  --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
                  v_savings_bal:= savingsno.cam_acct_bal;
                  v_saving_ledger_bal:=savingsno.cam_ledger_bal;
                  v_interest_forfeited:=savingsno.cam_interest_amount;
                  v_saving_type_code:=savingsno.cam_type_code;
                  v_saving_acct_id:=savingsno.cam_acct_id;

                  --SN SELECTING SAVINGS ACCOUNT BALANCE.
                  /*BEGIN
                     SELECT cam_acct_bal, cam_ledger_bal,
                            cam_interest_amount, cam_type_code,
                                      -- Added on 18-Apr-2013 for defect 10871
                            cam_acct_id
                                      -- Added on 18-Apr-2013 for defect 10871
                       INTO v_savings_bal, v_saving_ledger_bal,
                            v_interest_forfeited, v_saving_type_code,
                                      -- Added on 18-Apr-2013 for defect 10871
                            v_saving_acct_id
                                      -- Added on 18-Apr-2013 for defect 10871
                       FROM cms_acct_mast
                      WHERE cam_acct_no = savingsno.cam_acct_no
                        AND cam_inst_code = v_inst_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_resp_code := '21';
                        v_errmsg := 'Error while selecting balance';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_resp_code := '12';
                        v_errmsg :=
                              'Error while selecting savings account balance'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
                  -- EN SELECTING SAVINGS ACCOUNT BALANCE.*/
                  --En Modified by Pankaj S. during DFCCSD-70(Review) changes


                  --SN  SELECTING LAST TRANSACTION DATE.

                  --SN SELECTING IDLE TIME FROM DFG PARAM.
                  BEGIN
                     SELECT cdp_param_value
                       INTO v_idle_time
                       FROM cms_dfg_param
                      WHERE cdp_param_key = 'SavingAccClose'
                        AND cdp_inst_code = v_inst_code
                        AND cdp_prod_code = v_prod_code   -- Added for LYFEHOST-63
                        AND  CDP_CARD_TYPE = v_prod_cattype;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_resp_code := '21';
                        v_errmsg := 'Idle time not defined in mast for product '||v_prod_code||' and instcode '||v_inst_code; -- Change in error msg for LYFEHOST-63
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_resp_code := '12';
                        v_errmsg :=
                              'Error while selecting idle time'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  --EN  SELECTING IDLE TIME FROM DFG PARAM.
                  day_diff :=
                          TRUNC (SYSDATE)
                          - TO_DATE (last_txn_date, 'YYYYMMDD');

                  --St : check inactive period condition
                  IF day_diff > v_idle_time
                  THEN
                     --SN  CALLING AUTHORIZE PROCEDURE
                     BEGIN
                        sp_authorize_txn_cms_auth (v_inst_code,
                                                   v_msg_type,
                                                   --  Modified by sivakumar on 15/03/2012
                                                   v_rrn2,
                                                   v_delivery_channel,
                                                   v_term_id,
                                                   v_txn_code,
                                                   v_txn_mode,
                                                   --   Modified by sivakumar on 15/03/2012
                                                   v_tran_date,
                                                   v_tran_time,
                                                   v_pan_code,
                                                   v_inst_code,
                                                   v_savings_bal,
                                                   NULL,
                                                   NULL,
                                                   v_mcc_code,
                                                   v_curr_code,
                                                   -- Modified by sivakumar on 15/03/2012
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   v_spending_acctno,
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
                                                   v_rvsl_code,
                                                   -- Modified by sivakumar on 15/03/2012
                                                   v_savings_bal,
                                                   v_auth_id,
                                                   v_resp_code,
                                                   v_errmsg,
                                                   v_capture_date
                                                  );

                        IF v_resp_code <> '00' AND v_errmsg <> 'OK'
                        THEN
                           RAISE exp_auth_reject_record;
                        --updated by Ramesh.A on 22/05/2012
                        END IF;
                     EXCEPTION
                        WHEN exp_auth_reject_record
                        THEN                 --Added by Ramesh.A on 22/05/2012
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error from Card authorization'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --EB  CALLING AUTHORIZE PROCEDURE

                     --Sn Update the Amount & status To Savings acct no
                     BEGIN
                        UPDATE cms_acct_mast
                           SET cam_acct_bal = cam_acct_bal - v_savings_bal,
                               cam_ledger_bal = cam_ledger_bal - v_savings_bal,
                               cam_stat_code = v_acct_statcode,
                               cam_interest_amount = 0,
                               --Updated by Ramesh.A on 23/04/2012
                               cam_lupd_date = SYSDATE,
                               cam_lupd_user = 1
                         WHERE cam_inst_code = v_inst_code
                           AND cam_acct_no = savingsno.cam_acct_no
                           AND cam_type_code = v_acct_type;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                               'Updating amount in to acct no(Savings) error';
                           RAISE exp_reject_record;
                        END IF;

                        --Added by sivakumar on 12/03/2012
                        v_resp_code := '1';
                        v_errmsg := 'OK';
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating amount in to acct no(Savings) '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --En Update the Amount  & status To Savings acct no


                     --St : Add narration using transaction details   & add in statements
                     BEGIN
                       --Sn Commented below query during DFCCSD-70(Review) changes
                        /*SELECT ctm_tran_desc
                          INTO v_trans_desc
                          FROM cms_transaction_mast
                         WHERE ctm_inst_code = v_inst_code
                           AND ctm_tran_code = v_txn_code
                           AND ctm_delivery_channel = v_delivery_channel;*/
                        --En Commented below query during DFCCSD-70(Review) changes

                        IF TRIM (v_trans_desc) IS NOT NULL
                        THEN
                           v_narration := v_trans_desc || '/';
                        END IF;

                        IF TRIM (v_auth_id) IS NOT NULL
                        THEN
                           v_narration := v_narration || v_auth_id || '/';
                        END IF;

                        IF TRIM (savingsno.cam_acct_no) IS NOT NULL
                        THEN
                           v_narration :=
                                  v_narration || savingsno.cam_acct_no || '/';
                        END IF;

                        IF TRIM (v_tran_date) IS NOT NULL
                        THEN
                           v_narration := v_narration || v_tran_date;
                        END IF;
                     EXCEPTION
                        --Sn Commented during DFCCSD-70(Review) changes
                        /*WHEN NO_DATA_FOUND
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'No records founds while getting narration ';
                           RAISE exp_reject_record;*/
                        --Sn Commented during DFCCSD-70(Review) changes
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error in finding the narration '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     v_timestamp := SYSTIMESTAMP;
                                      -- Added on 18-Apr-2013 for defect 10871

                     BEGIN
                        -- v_dr_cr_flag := 'DR';
                        INSERT INTO cms_statements_log
                                    (csl_pan_no, csl_acct_no,
                                     -- Added by Ramesh.A on 27/03/2012
                                     csl_opening_bal,
                                     csl_trans_amount, csl_trans_type,
                                     csl_trans_date,
                                     csl_closing_balance,
                                     csl_trans_narrration, csl_pan_no_encr,
                                     csl_rrn, csl_auth_id,
                                     csl_business_date, csl_business_time,
                                     txn_fee_flag, csl_delivery_channel,
                                     csl_inst_code, csl_txn_code,
                                     csl_ins_date, csl_ins_user,
                                     csl_acct_type,
                                       --Added on 18-Apr-2013 for defect 10871
                                                   csl_time_stamp,
                                       --Added on 18-Apr-2013 for defect 10871
                                     csl_prod_code,csl_card_type
                                       --Added on 18-Apr-2013 for defect 10871
                                    )
                             VALUES (v_hash_pan, savingsno.cam_acct_no,
                                     -- Added by Ramesh.A on 27/03/2012
                                     v_saving_ledger_bal,
                                     v_saving_ledger_bal,
               --v_savings_bal replace by v_saving_ledger_bal for defect 10871
                                                         'DR',
                                     SYSDATE,
                                     v_saving_ledger_bal - v_saving_ledger_bal,
               --v_savings_bal replace by v_saving_ledger_bal for defect 10871
                                     /*DECODE (v_dr_cr_flag,
                                             'DR', v_savings_bal
                                              - v_savings_bal,
                                             'CR', v_savings_bal
                                              - v_savings_bal,
                                             'NA', v_savings_bal
                                            ),*/
                                     v_narration, v_encr_pan_from,
                                     v_rrn2, v_auth_id,
                                     v_tran_date, v_tran_time,
                                     'N', v_delivery_channel,
                                     v_inst_code, v_txn_code,
                                     SYSDATE, 1,
                                     v_saving_type_code,
                                       --Added on 18-Apr-2013 for defect 10871
                                                        v_timestamp,
                                       --Added on 18-Apr-2013 for defect 10871
                                     v_prod_code,v_prod_cattype
                                       --Added on 18-Apr-2013 for defect 10871
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error creating entry in statement log '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

---------------------------------------
 --SN:updating latest timestamp value
---------------------------------------
                     BEGIN
                     --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_tran_date), 1, 8), 'yyyymmdd');
       
IF (v_Retdate>v_Retperiod)
    THEN
                        UPDATE cms_statements_log
                           SET csl_time_stamp = v_timestamp
                         WHERE csl_pan_no = v_pan_code
                           AND csl_rrn = v_rrn2
                           AND csl_delivery_channel = v_delivery_channel
                           AND csl_txn_code = v_txn_code
                           AND csl_business_date = v_tran_date
                           AND csl_business_time = v_tran_time;
                   else
                              UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
                           SET csl_time_stamp = v_timestamp
                         WHERE csl_pan_no = v_pan_code
                           AND csl_rrn = v_rrn2
                           AND csl_delivery_channel = v_delivery_channel
                           AND csl_txn_code = v_txn_code
                           AND csl_business_date = v_tran_date
                           AND csl_business_time = v_tran_time;
                     end if;      
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating timestamp in statement log '
                              || SUBSTR (SQLERRM, 1, 100);
                           RAISE exp_reject_record;
                     END;

-------------------------------------
--EN:updating latest timestamp value
-------------------------------------
                     BEGIN
                        sp_daily_bin_bal (v_pan_code,
                                          v_tran_bindate,
                                          v_savings_bal,
                                          v_dr_cr_flag,
                                          v_inst_code,
                                          v_inst_code,
                                          v_errmsg
                                         );

                        --Added by sivakumar on 12/03/2012
                        IF v_errmsg <> 'OK'
                        THEN
                           v_resp_code := '21';
                           v_errmsg := 'Error from sp_daily_bin_bal';
                           RAISE exp_reject_record;
                        END IF;
                     -- Added by sivakumar on 12/03/2012.
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error creating entry in daily_bin log '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --En : Add narration using transaction details   & add in statements

                     --ST Get responce code fomr master
                     BEGIN
                        SELECT cms_iso_respcde
                          INTO v_resp_code
                          FROM cms_response_mast
                         WHERE cms_inst_code = v_inst_code
                           AND cms_delivery_channel = v_delivery_channel
                           AND cms_response_id = v_resp_code;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_resp_code := '21';
                           v_errmsg := 'Responce code not found ';
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           ---ISO MESSAGE FOR DATABASE ERROR
                           v_errmsg :=
                                 'Problem while selecting data from response master '
                              || v_resp_code
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --En Get responce code fomr master

                      --Sn added by Pankaj S. for DFCCSD-70 changes
                       BEGIN
                          SELECT cam_acct_bal,
                                 cam_ledger_bal
                            INTO v_acct_balance,
                                 v_ledger_balance
                            FROM cms_acct_mast
                           WHERE cam_inst_code = v_inst_code
                             AND cam_acct_no = v_spending_acctno;
                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             v_resp_code := '12';
                             v_errmsg :=
                                   'Error while selecting spending acc number '
                                || SUBSTR (SQLERRM, 1, 200);
                             RAISE exp_reject_record;
                       END;
                       --En added by Pankaj S. for DFCCSD-70 changes

                     --Sn update topup card number details in translog
                     BEGIN
                            --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	          v_Retdate := TO_DATE(SUBSTR(TRIM(v_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN             
                        UPDATE transactionlog
                           SET topup_card_no = v_hash_pan,
                               topup_card_no_encr = v_encr_pan_from,
                               topup_acct_no = v_spending_acctno,
                               txn_status = 'C',
                               topup_acct_type = v_spndacct_type,
                               --Sn added by Pankaj S. for DFCCSD-70 changes
                               topup_acct_balance=v_acct_balance,
                               topup_ledger_balance=v_ledger_balance,
                               --En added by Pankaj S. for DFCCSD-70 changes
                               total_amount =
                                  TRIM (TO_CHAR (v_savings_bal,
                                                 '99999999999999990.99'
                                                )
                                       ),
                               acct_balance = v_savings_bal - v_savings_bal,
-- Same varibale subtracted, since balance in acount mast will be 0 after closing saving account defect 10871
                               ledger_balance =
                                     v_saving_ledger_bal - v_saving_ledger_bal,
-- Same varibale subtracted, since balance in acount mast will be 0 after closing saving account defect 10871
                               add_lupd_date = SYSDATE,
                               add_lupd_user = 1,
                               customer_acct_no = savingsno.cam_acct_no,
                               response_id = v_resp_code,
                               time_stamp = v_timestamp,
                                       --Added on 18-Apr-2013 for Defect 10871
                               acct_type = v_saving_type_code
                         WHERE instcode = v_inst_code
                           AND rrn = v_rrn2
                           AND delivery_channel = v_delivery_channel
                           AND txn_code = v_txn_code
                           AND business_date = v_tran_date
                           AND business_time = v_tran_time
                           AND msgtype = v_msg_type
                           -- Modified by sivakumar on 15/03/2012
                           AND customer_card_no = v_hash_pan;
                   ELSE
                                           UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
                           SET topup_card_no = v_hash_pan,
                               topup_card_no_encr = v_encr_pan_from,
                               topup_acct_no = v_spending_acctno,
                               txn_status = 'C',
                               topup_acct_type = v_spndacct_type,
                               --Sn added by Pankaj S. for DFCCSD-70 changes
                               topup_acct_balance=v_acct_balance,
                               topup_ledger_balance=v_ledger_balance,
                               --En added by Pankaj S. for DFCCSD-70 changes
                               total_amount =
                                  TRIM (TO_CHAR (v_savings_bal,
                                                 '99999999999999990.99'
                                                )
                                       ),
                               acct_balance = v_savings_bal - v_savings_bal,
-- Same varibale subtracted, since balance in acount mast will be 0 after closing saving account defect 10871
                               ledger_balance =
                                     v_saving_ledger_bal - v_saving_ledger_bal,
-- Same varibale subtracted, since balance in acount mast will be 0 after closing saving account defect 10871
                               add_lupd_date = SYSDATE,
                               add_lupd_user = 1,
                               customer_acct_no = savingsno.cam_acct_no,
                               response_id = v_resp_code,
                               time_stamp = v_timestamp,
                                       --Added on 18-Apr-2013 for Defect 10871
                               acct_type = v_saving_type_code
                         WHERE instcode = v_inst_code
                           AND rrn = v_rrn2
                           AND delivery_channel = v_delivery_channel
                           AND txn_code = v_txn_code
                           AND business_date = v_tran_date
                           AND business_time = v_tran_time
                           AND msgtype = v_msg_type
                           -- Modified by sivakumar on 15/03/2012
                           AND customer_card_no = v_hash_pan;
                       --Sn Block Un-commented by Pankaj S. during DFCCSD-70(Review) changes
                      END IF;
                  IF SQL%ROWCOUNT <> 1
                       THEN
                          v_resp_code := '21';
                          v_errmsg :=
                                'Error while updating transactionlog '
                             || 'no valid records '
                             || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_record;
                       END IF;
                       --En Block Un-commented by Pankaj S. during DFCCSD-70(Review) changes

                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating transactionlog '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                         --En update topup card number details in translog
                     -- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No in cms_transaction_log_dtl table
                     BEGIN
                   --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
	   
	   	          v_Retdate := TO_DATE(SUBSTR(TRIM(v_tran_date), 1, 8), 'yyyymmdd');

       
IF (v_Retdate>v_Retperiod)
    THEN  
                        UPDATE cms_transaction_log_dtl
                           SET ctd_cust_acct_number = savingsno.cam_acct_no
                         WHERE ctd_inst_code = v_inst_code
                           AND ctd_rrn = v_rrn2
                           AND ctd_delivery_channel = v_delivery_channel
                           AND ctd_txn_code = v_txn_code
                           AND ctd_business_date = v_tran_date
                           AND ctd_business_time = v_tran_time
                           AND ctd_msg_type = v_msg_type
                           AND ctd_customer_card_no = v_hash_pan;
                    else
                         UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST --Added for VMS-5733/FSP-991
                           SET ctd_cust_acct_number = savingsno.cam_acct_no
                         WHERE ctd_inst_code = v_inst_code
                           AND ctd_rrn = v_rrn2
                           AND ctd_delivery_channel = v_delivery_channel
                           AND ctd_txn_code = v_txn_code
                           AND ctd_business_date = v_tran_date
                           AND ctd_business_time = v_tran_time
                           AND ctd_msg_type = v_msg_type
                           AND ctd_customer_card_no = v_hash_pan;
                        end if;       

                          --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                          IF SQL%ROWCOUNT <> 1 THEN
                           v_resp_code := '21';
                           v_errmsg :='Error while updating cms_transaction_log_dtl-'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                          END IF;
                          --En Added by Pankaj S. during DFCCSD-70(Review) changes
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating transaction log  dtl '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --SN INSERTING INTO INACTIVE TABLE.
                     BEGIN
                        INSERT INTO cms_inactivesavings_acct
                                    (cia_inst_code, cia_card_no,
                                     cia_spendingacct_no,
                                     cia_savingsacct_no, cia_closing_date,
                                     cia_savings_bal, cia_interest_rate,
                                     cia_transaction_flag, cia_inst_user,
                                     cia_ins_date, cia_lupd_user,
                                     cia_lupd_date,
                                     cia_lasttxn_date,CIA_UNIQUE_ID
                                                  -- Added for CR - 40 phase 2
                                    )
                             VALUES (v_inst_code, v_encr_pan_from,
                                     v_spending_acctno,
                                     savingsno.cam_acct_no, SYSDATE,
                                     v_savings_bal, v_interest_forfeited,

                                     --Updated by Ramesh.A on 27/04/2012
                                     'S', 1,
                                     SYSDATE, 1,
                                     SYSDATE,
                                     TO_DATE
                                        (last_txn_date, 'yyyymmdd'),
                                                  -- Added for CR - 40 phase 2
												  seq_inactivesavings_acct_uid.NEXTVAL		--- Modified for VMS-1138
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '12';
                           v_errmsg :=
                                 'Error while inserting the record in Inactive savings account success  log'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  --EN  INSERTING INTO INACTIVE TABLE.
                   --Sn Added for transactionlog Functional Removal Phase-II changes
                  ELSE
                      IF savingsno.cam_acct_crea_tnfr_date IS NULL THEN
                           BEGIN
                            UPDATE cms_acct_mast
                               SET cam_acct_crea_tnfr_date = SYSDATE
                             WHERE cam_inst_code = v_inst_code
                               AND cam_acct_no = savingsno.cam_acct_no;
                         EXCEPTION
                            WHEN OTHERS THEN
                               v_resp_code := '21';
                               v_errmsg :='Error while updating cam_acct_crea_tnfr_date for acct no(Savings)-'|| SUBSTR (SQLERRM, 1, 200);
                               RAISE exp_reject_record;
                         END;
                      END IF;
                  --En Added for transactionlog Functional Removal Phase-II changes
                  END IF;
               --End : check inactive period condition
               EXCEPTION
                  WHEN exp_auth_reject_record
                  THEN                       --Added by Ramesh.A on 22/05/2012
                     --ROLLBACK TO v_auth_savepoint; Commented by Besky on 06-nov-12

                     --Sn added by Pankaj S. for DFCCSD-70 changes
                       BEGIN
                          SELECT cam_acct_bal,
                                 cam_ledger_bal
                            INTO v_acct_balance,
                                 v_ledger_balance
                            FROM cms_acct_mast
                           WHERE cam_inst_code = v_inst_code
                             AND cam_acct_no = v_spending_acctno;
                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             v_acct_balance:=0;
                             v_ledger_balance:=0;
                       END;
                       --En added by Pankaj S. for DFCCSD-70 changes

                     BEGIN
                     --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	   	          v_Retdate := TO_DATE(SUBSTR(TRIM(v_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN       
-- DFCCSD-70 Santosh on 13JUN 13 to log Saving account No in transactionlog table
                        UPDATE transactionlog
                           SET customer_acct_no = savingsno.cam_acct_no,
                               acct_type = v_saving_type_code,
                               --Sn added by Pankaj S. for DFCCSD-70 changes
                               acct_balance = v_savings_bal,
                               ledger_balance =v_saving_ledger_bal,
                               topup_card_no = v_hash_pan,
                               topup_card_no_encr = v_encr_pan_from,
                               topup_acct_no = v_spending_acctno,
                               topup_acct_type=v_spndacct_type,
                               topup_acct_balance=v_acct_balance,
                               topup_ledger_balance=v_ledger_balance
                               --En added by Pankaj S. for DFCCSD-70 changes
                         WHERE instcode = v_inst_code
                           AND rrn = v_rrn2
                           AND delivery_channel = v_delivery_channel
                           AND txn_code = v_txn_code
                           AND business_date = v_tran_date
                           AND business_time = v_tran_time
                           AND msgtype = v_msg_type
                           AND customer_card_no = v_hash_pan;
                  ELSE
                       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
                           SET customer_acct_no = savingsno.cam_acct_no,
                               acct_type = v_saving_type_code,
                               --Sn added by Pankaj S. for DFCCSD-70 changes
                               acct_balance = v_savings_bal,
                               ledger_balance =v_saving_ledger_bal,
                               topup_card_no = v_hash_pan,
                               topup_card_no_encr = v_encr_pan_from,
                               topup_acct_no = v_spending_acctno,
                               topup_acct_type=v_spndacct_type,
                               topup_acct_balance=v_acct_balance,
                               topup_ledger_balance=v_ledger_balance
                               --En added by Pankaj S. for DFCCSD-70 changes
                         WHERE instcode = v_inst_code
                           AND rrn = v_rrn2
                           AND delivery_channel = v_delivery_channel
                           AND txn_code = v_txn_code
                           AND business_date = v_tran_date
                           AND business_time = v_tran_time
                           AND msgtype = v_msg_type
                           AND customer_card_no = v_hash_pan;
                      END IF;
                          --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                          IF SQL%ROWCOUNT <> 1 THEN
                           v_resp_code := '21';
                           v_errmsg :='Error while updating transactionlog-'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                          END IF;
                     EXCEPTION
                        WHEN exp_reject_record THEN
                          RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while inserting data into transaction log '
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '12';
                     END;

                     BEGIN
-- DFCCSD-70 Santosh on 13JUN 13 to log Saving account No in cms_transaction_log_dtl table
select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
	   
	   	          v_Retdate := TO_DATE(SUBSTR(TRIM(v_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
                UPDATE cms_transaction_log_dtl
                           SET ctd_cust_acct_number = savingsno.cam_acct_no
                         WHERE ctd_inst_code = v_inst_code
                           AND ctd_rrn = v_rrn2
                           AND ctd_delivery_channel = v_delivery_channel
                           AND ctd_txn_code = v_txn_code
                           AND ctd_business_date = v_tran_date
                           AND ctd_business_time = v_tran_time
                           AND ctd_msg_type = v_msg_type
                           AND ctd_customer_card_no = v_hash_pan;
                     else
                           UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
                           SET ctd_cust_acct_number = savingsno.cam_acct_no
                         WHERE ctd_inst_code = v_inst_code
                           AND ctd_rrn = v_rrn2
                           AND ctd_delivery_channel = v_delivery_channel
                           AND ctd_txn_code = v_txn_code
                           AND ctd_business_date = v_tran_date
                           AND ctd_business_time = v_tran_time
                           AND ctd_msg_type = v_msg_type
                           AND ctd_customer_card_no = v_hash_pan;
                      end if;     

                           --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                          IF SQL%ROWCOUNT <> 1 THEN
                           v_resp_code := '21';
                           v_errmsg :='Error while updating cms_transaction_log_dtl-'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                          END IF;
                     EXCEPTION
                      WHEN exp_reject_record THEN
                          RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while inserting data into transaction log  dtl'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '12';
                     END;

                     NULL;
                  WHEN exp_reject_record
                  THEN
                     --   V_RESP_CODE :='12';
                     --   V_ERRMSG :='Error in main exection' || SUBSTR(SQLERRM, 1, 200);
                     ROLLBACK TO v_auth_savepoint;

                     --SN RESPONSE MASTER
                     BEGIN
                        SELECT cms_iso_respcde
                          INTO v_resp_code
                          FROM cms_response_mast
                         WHERE cms_inst_code = v_inst_code
                           AND cms_delivery_channel = v_delivery_channel
                           AND cms_response_id = v_resp_code;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                              'Problem while selecting data from response master ';
                           v_resp_code := '21';
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while selecting data from response master '
                              || v_resp_code
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '12';
                     END;

                     --EN RESPONSE MASTER

                     --SN INSERTING INTO INACTIVE TABLE.
                     BEGIN
                        INSERT INTO cms_inactivesavings_acct
                                    (cia_inst_code, cia_card_no,
                                     cia_spendingacct_no,
                                     cia_savingsacct_no, cia_closing_date,
                                     cia_savings_bal, cia_interest_rate,
                                     cia_transaction_flag, cia_inst_user,
                                     cia_ins_date, cia_lupd_user,
                                     cia_lupd_date,CIA_UNIQUE_ID
                                    )
                             VALUES (v_inst_code, v_encr_pan_from,
                                     v_spending_acctno,
                                     savingsno.cam_acct_no, SYSDATE,
                                     v_savings_bal, v_interest_forfeited,

                                     --Updated by Ramesh.A on 27/04/2012
                                     'F', 1,
                                     SYSDATE, 1,
                                     SYSDATE,seq_inactivesavings_acct_uid.NEXTVAL		--- Modified for VMS-1138
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '12';
                           v_errmsg :=
                                 'Error while inserting the record in Inactive savings account failure tatus  log'
                              || SUBSTR (SQLERRM, 1, 200);
                     END;

                     --EN  INSERTING INTO INACTIVE TABLE.

                     -----------------------------------------------
--SN: Added on 18-Apr-2013 for defect 10871
-----------------------------------------------
                     IF v_spending_acctid IS NULL
                     THEN
                        --SN Modified for Mantis - 11153     on      10th, June 2013       Ramkumar.S
                          --SN Cust Code
                        BEGIN
                           SELECT cca_cust_code
                             INTO v_cust_code
                             FROM cms_cust_acct
                            WHERE cca_acct_id =
                                     (SELECT cam_acct_id
                                        FROM cms_acct_mast
                                       WHERE cam_type_code = v_acct_type
                                         AND cam_acct_no =
                                                         savingsno.cam_acct_no
                                         AND cam_inst_code = v_inst_code)
                              AND cca_inst_code = v_inst_code;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        --EN Cust Code

                        --SN SPENDING ACCOUNT NUMBER
                        BEGIN
                           SELECT cap_acct_id, cap_acct_no,
                                  fn_dmaps_main (cap_pan_code_encr),
                                  cap_card_stat, cap_prod_code, cap_card_type
                             INTO v_spending_acctid, v_spending_acctno,
                                  v_pan_code,
                                  v_cardstat, v_prod_code, v_prod_cattype
                             FROM cms_appl_pan
                            WHERE cap_inst_code = v_inst_code
                              AND cap_cust_code = v_cust_code
                              AND cap_pangen_date =
                                     (SELECT MAX (cap_pangen_date)
                                        FROM cms_appl_pan
                                       WHERE cap_inst_code = v_inst_code
                                         AND cap_cust_code = v_cust_code)
                              AND cap_addon_stat = 'P';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     --EN SPENDING ACCOUNT NUMBER.
                     --EN Modified for Mantis - 11153     on      10th, June 2013        Ramkumar.S
                     END IF;

                    --Below block commented during DFCCSD-70
                    /* IF v_spending_acct_type IS NULL
                     THEN
                        BEGIN
                           SELECT cam_type_code
                             INTO v_spending_acct_type
                             FROM cms_acct_mast
                            WHERE cam_inst_code = v_inst_code
                              AND cam_acct_id = v_spending_acctid;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     END IF;*/

                     IF v_cr_dr_flag IS NULL
                     THEN
                        BEGIN
                           SELECT ctm_tran_desc,
                                  CTM_CREDIT_DEBIT_FLAG
                                           --dr/cr flag added for defect 10871 -- modified during LYFEHOST-63 testing
                             INTO v_trans_desc,
                                  v_cr_dr_flag
                             FROM cms_transaction_mast
                            WHERE ctm_inst_code = v_inst_code
                              AND ctm_tran_code = v_txn_code
                              AND ctm_delivery_channel = v_delivery_channel;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     END IF;

                      --Sn added by Pankaj S. for DFCCSD-70 changes
                      IF v_saving_type_code IS NULL THEN
                        BEGIN
                           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                             INTO v_savings_bal, v_saving_ledger_bal, v_saving_type_code
                             FROM cms_acct_mast
                            WHERE cam_inst_code = v_inst_code
                              AND cam_acct_no = savingsno.cam_acct_no;
                        EXCEPTION
                           WHEN OTHERS THEN
                            NULL;
                        END;
                      END IF;

                       BEGIN
                          SELECT cam_acct_bal,
                                 cam_ledger_bal,cam_type_code
                            INTO v_acct_balance,
                                 v_ledger_balance,v_spending_acct_type
                            FROM cms_acct_mast
                           WHERE cam_inst_code = v_inst_code
                             AND cam_acct_no = v_spending_acctno;
                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             v_acct_balance:=0;
                             v_ledger_balance:=0;
                       END;
                       --En added by Pankaj S. for DFCCSD-70 changes

-----------------------------------------------
--EN: Added on 18-Apr-2013 for defect 10871
-----------------------------------------------

                     --SN INSERTING  INTO TRANSACTION LOG TABLE.
                     BEGIN
                        INSERT INTO transactionlog
                                    (msgtype, rrn, delivery_channel,
                                     date_time, txn_code, txn_type,
                                     txn_mode, txn_status, response_code,
                                     business_date, business_time,
                                     customer_card_no, instcode,
                                     customer_card_no_encr,
                                     customer_acct_no, error_msg, ipaddress,
                                     add_ins_date,--Added by ramesh.a on 11/04/2012
                                     add_ins_user, --Added by ramesh.a on 11/04/2012
                                     cardstatus,trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                                     productid,categoryid, acct_type,time_stamp,cr_dr_flag,-- Added on 18-apr-2013 for defect 10871
                                     --Sn added by Pankaj S. for DFCCSD-70 changes
                                     acct_balance,ledger_balance,
                                     topup_card_no,topup_card_no_encr,topup_acct_no,topup_acct_type,
                                     topup_acct_balance,topup_ledger_balance
                                     --En added by Pankaj S. for DFCCSD-70 changes
                                    )
                             VALUES (v_msg_type,-- Modified by sivakumar on 15/03/2012
                                     v_rrn2, v_delivery_channel,
                                     SYSDATE, v_txn_code, 1,
                                     v_txn_mode, --  Modified by sivakumar on 15/03/2012
                                     'F', v_resp_code,
                                     v_tran_date, v_tran_time,
                                     v_hash_pan, v_inst_code,
                                     v_encr_pan_from,--  v_spending_acctno, v_errmsg, NULL, -- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No
                                     savingsno.cam_acct_no, v_errmsg, NULL,
                                     SYSDATE,--Added by ramesh.a on 11/04/2012
                                     1,--Added by ramesh.a on 11/04/2012
                                     v_cardstat,v_trans_desc, v_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                                     v_prod_code,v_prod_cattype,--    v_spending_acct_type, -- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account Type
                                     v_saving_type_code,NVL (v_timestamp, SYSTIMESTAMP),v_cr_dr_flag,-- Added on 18-apr-2013 for defect 10871
                                     --Sn added by Pankaj S. for DFCCSD-70 changes
                                     v_savings_bal, v_saving_ledger_bal,
                                     v_hash_pan,v_encr_pan_from,v_spending_acctno,v_spending_acct_type,
                                     v_acct_balance,v_ledger_balance
                                     --En added by Pankaj S. for DFCCSD-70 changes
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '12';
                           v_errmsg :=
                                 'Exception while inserting to transaction log '
                              || SUBSTR (SQLERRM, 1, 200);
                     END;

                     --EN INSERTING INTO TRANSACTIONLOG TABLE.

                     --SN: Reset after insert for defect 10871
                     v_prod_code := NULL;
                     v_prod_cattype := NULL;
                     v_spending_acct_type := NULL;
                     v_cr_dr_flag := NULL;
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     v_acct_balance:=NULL;
                     v_ledger_balance:=NULL;
                     v_saving_type_code:=NULL;
                     --En added by Pankaj S. for DFCCSD-70 changes

                     --EN: Reset after insert for defect 10871

                     --SN INSERTING INTO TRANSACTIONLOG_DTL TABLE.
                     BEGIN
                        INSERT INTO cms_transaction_log_dtl
                                    (ctd_delivery_channel, ctd_txn_code,
                                     ctd_txn_type, ctd_txn_mode,
                                     ctd_business_date, ctd_business_time,
                                     ctd_customer_card_no, ctd_txn_curr,
                                     ctd_fee_amount, ctd_waiver_amount,
                                     ctd_servicetax_amount, ctd_cess_amount,
                                     ctd_process_flag, ctd_process_msg,
                                     ctd_rrn, ctd_inst_code, ctd_ins_date,
                                     ctd_customer_card_no_encr,
                                     ctd_msg_type, request_xml,
                                     ctd_cust_acct_number,
                                     ctd_addr_verify_response
                                    )
                             VALUES (v_delivery_channel, v_txn_code,
                                     1, v_txn_mode,
                                     -- Modified by sivakumar on 15/03/2012
                                     v_tran_date, v_tran_time,
                                     v_hash_pan, v_curr_code,
                                     -- Modified by sivakumar on 15/03/2012
                                     NULL, NULL,
                                     NULL, NULL,
                                     'E', v_errmsg,
                                     v_rrn2, v_inst_code, SYSDATE,
                                     v_encr_pan_from,
                                     v_msg_type,
                                                 -- Modified by sivakumar on 15/03/2012
                                     '',
                                     --  v_spending_acctno, -- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No
                                     savingsno.cam_acct_no,
                                     ''
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while inserting data into transaction log  dtl'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '12';
                     END;
                  -- EN NSERTING INTO TRANSACTIONLOG_DTL TABLE.
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                            'Error in  execetion' || SUBSTR (SQLERRM, 1, 200);
                     ROLLBACK TO v_auth_savepoint;

                     --SN RESPONSE MASTER
                     BEGIN
                        SELECT cms_iso_respcde
                          INTO v_resp_code
                          FROM cms_response_mast
                         WHERE cms_inst_code = v_inst_code
                           AND cms_delivery_channel = v_delivery_channel
                           AND cms_response_id = v_resp_code;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                              'Problem while selecting data from response master ';
                           v_resp_code := '21';
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while selecting data from response master '
                              || v_resp_code
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '21';
                     END;

                     --EN RESPONSE MASTER

                     --SN INSERTING INTO INACTIVE TABLE.
                     BEGIN
                        INSERT INTO cms_inactivesavings_acct
                                    (cia_inst_code, cia_card_no,
                                     cia_spendingacct_no,
                                     cia_savingsacct_no, cia_closing_date,
                                     cia_savings_bal, cia_interest_rate,
                                     cia_transaction_flag, cia_inst_user,
                                     cia_ins_date, cia_lupd_user,
                                     cia_lupd_date,CIA_UNIQUE_ID
                                    )
                             VALUES (v_inst_code, v_encr_pan_from,
                                     v_spending_acctno,
                                     savingsno.cam_acct_no, SYSDATE,
                                     v_savings_bal, v_interest_forfeited,

                                     --Updated by Ramesh.A on 27/04/2012
                                     'F', 1,
                                     SYSDATE, 1,
                                     SYSDATE,seq_inactivesavings_acct_uid.NEXTVAL		--- Modified for VMS-1138
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '12';
                           v_errmsg :=
                                 'Error while inserting the record in Inactive savings account failure status in exection  log'
                              || SUBSTR (SQLERRM, 1, 200);
                     END;

                     --EN  INSERTING INTO INACTIVE TABLE.

                     -----------------------------------------------
--SN: Added on 18-Apr-2013 for defect 10871
-----------------------------------------------
                     IF v_spending_acctid IS NULL
                     THEN
                        --SN Modified for Mantis - 11153     on      10th, June 2013      Ramkumar.S
                        --SN Cust Code
                        BEGIN
                           SELECT cca_cust_code
                             INTO v_cust_code
                             FROM cms_cust_acct
                            WHERE cca_acct_id =
                                     (SELECT cam_acct_id
                                        FROM cms_acct_mast
                                       WHERE cam_type_code = v_acct_type
                                         AND cam_acct_no =
                                                         savingsno.cam_acct_no
                                         AND cam_inst_code = v_inst_code)
                              AND cca_inst_code = v_inst_code;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        --EN Cust Code

                        --SN SPENDING ACCOUNT NUMBER
                        BEGIN
                           SELECT cap_acct_id, cap_acct_no,
                                  fn_dmaps_main (cap_pan_code_encr),
                                  cap_card_stat, cap_prod_code, cap_card_type
                             INTO v_spending_acctid, v_spending_acctno,
                                  v_pan_code,
                                  v_cardstat, v_prod_code, v_prod_cattype
                             FROM cms_appl_pan
                            WHERE cap_inst_code = v_inst_code
                              AND cap_cust_code = v_cust_code
                              AND cap_pangen_date =
                                     (SELECT MAX (cap_pangen_date)
                                        FROM cms_appl_pan
                                       WHERE cap_inst_code = v_inst_code
                                         AND cap_cust_code = v_cust_code)
                              AND cap_addon_stat = 'P';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     --EN SPENDING ACCOUNT NUMBER.
                     --EN Modified for Mantis - 11153     on      10th, June 2013    Ramkumar.S
                     END IF;

                    --Below block commented during DFCCSD-70
                    /* IF v_spending_acct_type IS NULL
                     THEN
                        BEGIN
                           SELECT cam_type_code
                             INTO v_spending_acct_type
                             FROM cms_acct_mast
                            WHERE cam_inst_code = v_inst_code
                              AND cam_acct_id = v_spending_acctid;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     END IF;*/

                     IF v_cr_dr_flag IS NULL
                     THEN
                        BEGIN
                           SELECT ctm_tran_desc,
                                  CTM_CREDIT_DEBIT_FLAG
                                           --dr/cr flag added for defect 10871 -- modified during LYFEHOST-63 testing
                             INTO v_trans_desc,
                                  v_cr_dr_flag
                             FROM cms_transaction_mast
                            WHERE ctm_inst_code = v_inst_code
                              AND ctm_tran_code = v_txn_code
                              AND ctm_delivery_channel = v_delivery_channel;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     END IF;

                     --Sn added by Pankaj S. for DFCCSD-70 changes
                      IF v_saving_type_code IS NULL THEN
                        BEGIN
                           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                             INTO v_savings_bal, v_saving_ledger_bal, v_saving_type_code
                             FROM cms_acct_mast
                            WHERE cam_inst_code = v_inst_code
                              AND cam_acct_no = savingsno.cam_acct_no;
                        EXCEPTION
                           WHEN OTHERS THEN
                            NULL;
                        END;
                      END IF;

                       BEGIN
                          SELECT cam_acct_bal,
                                 cam_ledger_bal,cam_type_code
                            INTO v_acct_balance,
                                 v_ledger_balance,v_spending_acct_type
                            FROM cms_acct_mast
                           WHERE cam_inst_code = v_inst_code
                             AND cam_acct_no = v_spending_acctno;
                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             v_acct_balance:=0;
                             v_ledger_balance:=0;
                       END;
                       --En added by Pankaj S. for DFCCSD-70 changes

-----------------------------------------------
--EN: Added on 18-Apr-2013 for defect 10871
-----------------------------------------------

                     --SN INSERTING  INTO TRANSACTION LOG TABLE.
                     BEGIN
                        INSERT INTO transactionlog
                                    (msgtype, rrn, delivery_channel,
                                     date_time, txn_code, txn_type,
                                     txn_mode, txn_status, response_code,
                                     business_date, business_time,
                                     customer_card_no, instcode,
                                     customer_card_no_encr,
                                     customer_acct_no, error_msg, ipaddress,
                                     add_ins_date,--Added by ramesh.a on 11/04/2012
                                     add_ins_user,--Added by ramesh.a on 11/04/2012
                                     cardstatus,trans_desc, response_id,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                                     productid,categoryid, acct_type,time_stamp,cr_dr_flag, -- Added on 18-apr-2013 for defect 10871
                                     --Sn added by Pankaj S. for DFCCSD-70 changes
                                     acct_balance,ledger_balance,
                                     topup_card_no,topup_card_no_encr,topup_acct_no,topup_acct_type,
                                     topup_acct_balance,topup_ledger_balance
                                     --En added by Pankaj S. for DFCCSD-70 changes
                                    )
                             VALUES (v_msg_type,-- Modified by sivakumar on 15/03/2012
                                     v_rrn2, v_delivery_channel,
                                     SYSDATE, v_txn_code, 1,v_txn_mode,-- Modified by sivakumar on 15/03/2012
                                     'F', v_resp_code,
                                     v_tran_date, v_tran_time,
                                     v_hash_pan, v_inst_code,
                                     v_encr_pan_from,--  v_spending_acctno, v_errmsg, NULL,-- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No
                                     savingsno.cam_acct_no, v_errmsg, NULL,
                                     SYSDATE,--Added by ramesh.a on 11/04/2012
                                     1,--Added by ramesh.a on 11/04/2012
                                     v_cardstat,v_trans_desc, v_resp_code,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                                     v_prod_code,v_prod_cattype,--v_spending_acct_type, -- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No
                                     v_saving_type_code,NVL (v_timestamp, SYSTIMESTAMP),v_cr_dr_flag,-- Added on 18-apr-2013 for defect 10871
                                     --Sn added by Pankaj S. for DFCCSD-70 changes
                                     v_savings_bal, v_saving_ledger_bal,
                                     v_hash_pan,v_encr_pan_from,v_spending_acctno,v_spending_acct_type,
                                     v_acct_balance,v_ledger_balance
                                     --En added by Pankaj S. for DFCCSD-70 changes
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_code := '12';
                           v_errmsg :=
                                 'Exception while inserting to transaction log '
                              || SUBSTR (SQLERRM, 1, 200);
                     END;

                     --EN INSERTING INTO TRANSACTIONLOG TABLE.

                     --SN: Reset after insert for defect 10871
                     v_prod_code := NULL;
                     v_prod_cattype := NULL;
                     v_spending_acct_type := NULL;
                     v_cr_dr_flag := NULL;
                     --Sn added by Pankaj S. for DFCCSD-70 changes
                     v_acct_balance:=NULL;
                     v_ledger_balance:=NULL;
                     v_saving_type_code:=NULL;
                     --En added by Pankaj S. for DFCCSD-70 changes

                     --EN: Reset after insert for defect 10871

                     --SN INSERTING INTO TRANSACTIONLOG_DTL TABLE.
                     BEGIN
                        INSERT INTO cms_transaction_log_dtl
                                    (ctd_delivery_channel, ctd_txn_code,
                                     ctd_txn_type, ctd_txn_mode,
                                     ctd_business_date, ctd_business_time,
                                     ctd_customer_card_no, ctd_txn_curr,
                                     ctd_fee_amount, ctd_waiver_amount,
                                     ctd_servicetax_amount, ctd_cess_amount,
                                     ctd_process_flag, ctd_process_msg,
                                     ctd_rrn, ctd_inst_code, ctd_ins_date,
                                     ctd_customer_card_no_encr,
                                     ctd_msg_type, request_xml,
                                     ctd_cust_acct_number,
                                     ctd_addr_verify_response
                                    )
                             VALUES (v_delivery_channel, v_txn_code,
                                     1, v_txn_mode,
                                     -- Modified by sivakumar on 15/03/2012
                                     v_tran_date, v_tran_time,
                                     v_hash_pan, v_curr_code,
                                     -- Modified by sivakumar on 15/03/2012
                                     NULL, NULL,
                                     NULL, NULL,
                                     'E', v_errmsg,
                                     v_rrn2, v_inst_code, SYSDATE,
                                     v_encr_pan_from,
                                     v_msg_type,
                                                 -- Modified by sivakumar on 15/03/2012
                                     '',
                                     --v_spending_acctno,-- DFCCSD-70 Santosh 13 JUN 13 Commented to log Saving Account No
                                     savingsno.cam_acct_no,
                                     ''
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Problem while inserting data into transaction log  dtl'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_code := '12';
                     END;
               -- EN NSERTING INTO TRANSACTIONLOG_DTL TABLE.
               END;
            END LOOP;                                            --For Savings
         END;
      EXCEPTION
         WHEN exp_reject_rec
         THEN
            v_errmsg :=
                  'Error while selecting savings account number for inst code'
               || v_inst_code;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting the record in Inactive log'
               || SUBSTR (SQLERRM, 1, 200);
      END;
   END LOOP;                                                 --For Institution
END;
/
show error