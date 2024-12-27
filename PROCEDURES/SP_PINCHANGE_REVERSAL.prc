CREATE OR REPLACE PROCEDURE VMSCMS.SP_PINCHANGE_REVERSAL(
   p_inst_code             IN       NUMBER,
   p_msg_typ               IN       VARCHAR2,
   p_rvsl_code             IN       VARCHAR2,
   p_rrn                   IN       VARCHAR2,
   p_delv_chnl             IN       VARCHAR2,
   p_terminal_id           IN       VARCHAR2,
   p_merc_id               IN       VARCHAR2,
   p_txn_type              IN       VARCHAR2,
    --T.Narayanan. changed the order for the trancode passed as trantype issue
   p_txn_code              IN       VARCHAR2,
    --T.Narayanan. changed the order for the trancode passed as trantype issue
   p_txn_mode              IN       VARCHAR2,
   p_business_date         IN       VARCHAR2,
   p_business_time         IN       VARCHAR2,
   p_card_no               IN       VARCHAR2,
   p_bank_code             IN       VARCHAR2,
   p_stan                  IN       VARCHAR2,
   p_expry_date            IN       VARCHAR2,
   p_orgnl_business_date   IN       VARCHAR2,
   p_orgnl_business_time   IN       VARCHAR2,
   p_orgnl_rrn             IN       VARCHAR2,
   p_mbr_numb              IN       VARCHAR2,
   p_orgnl_terminal_id     IN       VARCHAR2,
   p_ani                   IN       VARCHAR2,
   p_dni                   IN       VARCHAR2,
   p_resp_cde              OUT      VARCHAR2,
   p_resp_msg              OUT      VARCHAR2,
   p_card_status           OUT      VARCHAR2,
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
   p_card_stat_desc        OUT      VARCHAR2,
   p_old_card_number       OUT      VARCHAR2
)
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
AS
   /*************************************************
      * Modified By      :  DHINAKARAN B
       * Modified Date    :  24-OCT-12
       * Modified Reason  : Auth id length change
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  25-OCT-2012
       * Build Number     :  CMS3.5.1_RI0020_B0007

      * Modified By      :  Ramesh.A
      * Modified Date    :  02-Sep-13
      * Modified Reason  :  MVCSD-4099(IVR PIN Update /Reversal transaction changes)
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  02-Sep-13
      * Release Number   :  RI0024.4_B0007

      * Modified By      :  Ramesh.A
      * Modified Date    :  06-Sep-13
      * Modified Reason  :  Mantis id :0012273 and v_resp_cde is replaced with p_resp_cde on line number 144
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  06-Sep-13
      * Release Number   :  RI0024.4_B0008

      * Modified By      :  Ramesh.A
      * Modified Date    :  17-Sep-13
      * Modified Reason  :  Mantis id :12309 IVR Update PIN reversal txn displays null in CR_DR_FLAG, AMOUNT and TRANFEE_AMT
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Release Number   :  RI0024.4_B0016

      * Modified By      :  Ramesh.A
      * Modified Date    :  20-Sep-13
      * Modified Reason  :  Mantis id :12309 changes for getting acct no not found due to variable used as number instead of varchar.
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Release Number   :  RI0024.4_B0017

      * Modified By      :  Ramesh.A
      * Modified Date    :  23-Sep-13
      * Modified Reason  :  Mantis id :12436 revese the card status if starercard present while activating the GPR card.
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  23-Sep-13
      * Release Number   :  RI0024.4_B0018

      * Modified By      :  Ramesh.A
      * Modified Date    :  23-OCT-13
      * Modified Reason  :  Mantis id :12809 Date not updated while activating the card in IVR Update PIN transaction .
      * Reviewer         :
      * Reviewed Date    :
      * Release Number   :  RI0024.5.2_B0001

      * Modified By      :  Ramesh.A
      * Modified Date    :  06-DEC-13
      * Modified Reason  :  Mantis id :13134 TOPUP is application only after initial load throws the error message in SPIL Valins transaction
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  06-DEC-13
      * Release Number   :  RI0024.6.2_B0003

      * Modified By      :  Ramesh.A
      * Modified Date    :  17-DEC-13
      * Modified Reason  :  Mantis id :13251 PIN UPDATE Reversal (for an active card) goes inactive
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  17-DEC-13
      * Release Number   :  RI0024.6.3_B0005

     * Modified By       : Pankaj S.
     * Modified Date     : 19-Dec-2013
     * Modified Reason   : Logging issue changes(Mantis ID-13160)
     * Reviewer          : Dhiraj
     * Reviewed Date     : 
     * Build Number      : RI0027_B0004   
     
     * Modified By       : Pankaj S.
     * Modified Date     : 29-JAN-2014
     * Modified Reason   : 0013477: INCOMM : CMS: Update PIN Normal not listed under fees, but still card is charged for the same 
     * Reviewer          : Dhiraj
     * Reviewed Date     : 
     * Build Number      : RI0027_B0005   
     
     * Modified By       : Ramesh.
     * Modified Date     : 07-FEB-2014
     * Modified Reason   : 0013477: INCOMM : Acctount and Ledger balance not updated properly 
     * Reviewer          : Dhiraj
     * Reviewed Date     : 07-FEB-2014
     * Build Number      : RI0027_B0006
     
     * Modified By       : Ramesh.
     * Modified Date     : 11-FEB-2014
     * Modified Reason   : 0013639: INCOMM : CMS : MYVIVR-50 - Update PIN reversal - Does not capture business date and business time in transactionlog 
     * Reviewer          : Dhiraj
     * Reviewed Date     : 
     * Build Number      : RI0027_B0007
     
     * Modified By       : Ramesh.
     * Modified Date     : 28-MAY-2014
     * Modified Reason   : 14868: Damaged card not closed when card is activated through update pin ivr  
     * Reviewer          : spankaj
     * Reviewed Date     : 28-May-2014
     * Build Number      : RI0027.1.7_B0003
     
    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 11-Nov-14    
    * Modified For      : FSS-1906
    * Reviewer          : Spankaj
    * Build Number      : RI0027.4.3_B0003
    
    * Modified by       : Saravanakumar a
    * Modified Date     : 12-Feb-16    
    * Modified For      : 
    * Reviewer          : Spankaj
    * Build Number      : FEB_VMSGPRHOST_3.3.2_RELEASE

     * Modified by          : Spankaj
     * Modified Date        : 21-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11  
     
     * Modified by          : MageshKumar
     * Modified Date        : 26-Apr-2017
     * Modified For         : FSS-4427 : CVV PLUS
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD17.04
	 
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
 
    * Modified By      : venkat Singamaneni
    * Modified Date    : 5-02-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

   *************************************************/
   v_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
   v_orgnl_resp_code            transactionlog.response_code%TYPE;
   v_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
   v_orgnl_txn_code             transactionlog.txn_code%TYPE;
   v_orgnl_txn_type             transactionlog.txn_type%TYPE;
   v_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
   v_orgnl_business_date        transactionlog.business_date%TYPE;
   v_orgnl_business_time        transactionlog.business_time%TYPE;
   v_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
   v_orgnl_total_amount         transactionlog.amount%TYPE;
   v_actual_amt                 NUMBER (9, 2);
   v_reversal_amt               NUMBER (9, 2);
   v_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
   v_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
   v_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
   v_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
   v_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
   v_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
   v_actual_dispatched_amt      transactionlog.amount%TYPE;
   v_prod_cattype               cms_prod_cattype.cpc_card_type%TYPE;
   v_expry_date                 DATE;
   v_atmonline_limit            cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit            cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_cap_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag            cms_appl_pan.cap_cafgen_flag%TYPE;
   v_cap_prod_catg              VARCHAR2 (100);
   v_firsttime_topup            cms_appl_pan.cap_firsttime_topup%TYPE;
   v_appl_code                  cms_appl_mast.cam_appl_code%TYPE;
   v_mbrnumb                    cms_appl_pan.cap_mbr_numb%TYPE;
   v_cust_code                  cms_cust_mast.ccm_cust_code%TYPE;
   v_proxunumber                cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance               NUMBER;
   v_ledger_bal                 NUMBER;
   v_capture_date               DATE;
   v_authid_date                VARCHAR2 (8);
   v_trans_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
                              --Added for transaction detail report on 210812
   v_resp_cde                   VARCHAR2 (3);
   v_func_code                  cms_func_mast.cfm_func_code%TYPE;
   v_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
   v_orgnl_trandate             DATE;
   v_rvsl_trandate              DATE;
   v_orgnl_termid               transactionlog.terminal_id%TYPE;
   v_orgnl_mcccode              transactionlog.mccode%TYPE;
   v_errmsg                     VARCHAR2 (300);
   v_actual_feecode             transactionlog.feecode%TYPE;
   v_orgnl_tranfee_amt          transactionlog.tranfee_amt%TYPE;
   v_orgnl_servicetax_amt       transactionlog.servicetax_amt%TYPE;
   v_orgnl_cess_amt             transactionlog.cess_amt%TYPE;
   v_orgnl_cr_dr_flag           transactionlog.cr_dr_flag%TYPE;
   v_orgnl_tranfee_cr_acctno    transactionlog.tranfee_cr_acctno%TYPE;
   v_orgnl_tranfee_dr_acctno    transactionlog.tranfee_dr_acctno%TYPE;
   v_orgnl_st_calc_flag         transactionlog.tran_st_calc_flag%TYPE;
   v_orgnl_cess_calc_flag       transactionlog.tran_cess_calc_flag%TYPE;
   v_orgnl_st_cr_acctno         transactionlog.tran_st_cr_acctno%TYPE;
   v_orgnl_st_dr_acctno         transactionlog.tran_st_dr_acctno%TYPE;
   v_orgnl_cess_cr_acctno       transactionlog.tran_cess_cr_acctno%TYPE;
   v_orgnl_cess_dr_acctno       transactionlog.tran_cess_dr_acctno%TYPE;
   v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                  cms_appl_pan.cap_card_type%TYPE;
   v_gl_upd_flag                transactionlog.gl_upd_flag%TYPE;
   v_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
   v_savepoint                  NUMBER                              DEFAULT 1;
   v_curr_code                  transactionlog.currencycode%TYPE;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_delchannel_code            VARCHAR2 (2);
   v_base_curr                  CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
   v_currcode                   VARCHAR2 (3);
   v_rrn_count                  NUMBER;
   v_terminal_indicator         pcms_terminal_mast.ptm_terminal_indicator%TYPE;
   exp_rvsl_reject_record       EXCEPTION;
   exp_reject_record            EXCEPTION;
   v_card_acct_no               NUMBER;
   v_oldpin_offset              VARCHAR2 (10);
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_timestamp                  TIMESTAMP;
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
   v_cam_type_code              cms_acct_mast.cam_type_code%TYPE;
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
   v_txn_type                   NUMBER (1);
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013

V_FEE_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE; --Added for fee reversal defect :12309 on 17/09/2013

 --St Added for mantis id :12436 on 23/09/2013
v_starterCard_hash        transactionlog.customer_card_no%type;
v_starterCard_encr        transactionlog.customer_card_no_encr%type;
v_starterCardStatus  transactionlog.cardstatus%type;
v_txn_code           transactionlog.txn_code%type;
v_totpup_pan_hash TRANSACTIONLOG.TOPUP_CARD_NO%type;
 --End Added for mantis id :12436 on 23/09/2013
 v_orgnl_cardstatus  transactionlog.cardstatus%type; --Added for defect id : 13251 on 17/12/13
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
   v_resp_cde := '00'; --Modifeid for response not getting properly on 06/09/2013
   p_resp_msg := 'OK';
   SAVEPOINT v_savepoint;
   v_timestamp := SYSTIMESTAMP;

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN create encr pan

   --Sn Getting the Transaction Description
   BEGIN
      SELECT ctm_tran_desc,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_trans_desc,
             v_txn_type
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delv_chnl
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      --T.Narayanan raised exception if tran desc not found
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'Transaction description cannot be null ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'Transaction description cannot be null ';
         RAISE exp_rvsl_reject_record;
   END;

   --T.Narayanan raised exception if tran desc not found
   --Sn check msg type
   IF (p_msg_typ NOT IN ('0400')) OR (p_rvsl_code = '00')
   THEN
      v_resp_cde := '21';
      p_resp_msg := 'Invalid Reversal Request';
      RAISE exp_rvsl_reject_record;
   END IF;

   --En check msg type

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
   BEGIN

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_inst_code
         AND rrn = p_rrn
         AND business_date = p_business_date
         AND business_time = p_business_time
         AND delivery_channel = p_delv_chnl;
 ELSE
     SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE instcode = p_inst_code
         AND rrn = p_rrn
         AND business_date = p_business_date
         AND business_time = p_business_time
         AND delivery_channel = p_delv_chnl;
END IF;
                                       --Added by ramkumar.Mk on 25 march 2012

      IF v_rrn_count > 0
      THEN
         v_resp_cde := '22';
         p_resp_msg := 'Duplicate RRN ' || ' on ' || p_business_date;
         RAISE exp_rvsl_reject_record;
      END IF;
   END;

   --En Duplicate RRN Check

   --Sn find card detail
   BEGIN
      SELECT cap_prod_code, cap_card_type,
             TO_CHAR (cap_expry_date, 'DD-MON-YY'), cap_card_stat,
             cap_atm_online_limit, cap_pos_online_limit, cap_prod_catg,
             cap_cafgen_flag, cap_appl_code, cap_firsttime_topup,
             cap_mbr_numb, cap_cust_code, cap_proxy_number, cap_acct_no
        INTO v_prod_code, v_prod_cattype,
             v_expry_date, v_cap_card_stat,
             v_atmonline_limit, v_atmonline_limit, v_cap_prod_catg,
             v_cap_cafgen_flag, v_appl_code, v_firsttime_topup,
             v_mbrnumb, v_cust_code, v_proxunumber, v_acct_number
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '16';                         --Ineligible Transaction
         p_resp_msg := 'Card number not found ' || v_hash_pan;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         p_resp_msg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   
   
      BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'IVR' AND cdm_inst_code = p_inst_code;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = p_delv_chnl
      THEN
         BEGIN
--            SELECT cip_param_value
--              INTO v_base_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = p_inst_code AND cip_param_key = 'CURRENCY';

                SELECT trim(cbp_param_value) 
		INTO v_base_curr 
		FROM cms_bin_param 
               WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_inst_code
               AND cbp_profile_code = (select  cpc_profile_code from 
               cms_prod_cattype where cpc_prod_code = v_prod_code 
	          and cpc_card_type = v_prod_cattype 
			  and cpc_inst_code=p_inst_code);	


            IF v_base_curr IS NULL
            THEN
               v_resp_cde := '21';
               p_resp_msg := 'Base currency cannot be null ';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               p_resp_msg :=
                          'Base currency is not defined for the bin profile ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_resp_msg :=
                     'Error while selecting base currency for bin  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := '840';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
               'Error while selecting the Delivery Channel of IVR  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   
/* Commented and moved to below for to get updated balance changes on 29/01/14 for defect id :13477
   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal
            INTO v_acct_balance, v_ledger_bal
            FROM cms_acct_mast
           WHERE cam_acct_no = v_acct_number --Added for v_acct_number is already used and defect id :12309 on 20/09/2013
               /* (SELECT cap_acct_no
                   FROM cms_appl_pan
                  WHERE cap_pan_code = v_hash_pan
                    AND cap_mbr_numb = p_mbr_numb
                    AND cap_inst_code = p_inst_code) */
        /*
             AND cam_inst_code = p_inst_code
      FOR UPDATE NOWAIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';                         --Ineligible Transaction
         p_resp_msg := 'Invalid Card ';
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         p_resp_msg :=
               'Error while selecting data from card Master for card number '
            || SQLERRM;
   END;
*/
   --En find card detail

   -- Expiry Check
   /*
   BEGIN

    IF TO_DATE(p_business_date, 'YYYYMMDD') >
       LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN

      v_resp_cde := '13';
      P_RESP_MSG  := 'EXPIRED CARD';
      RAISE exp_rvsl_reject_record;

    END IF;

   EXCEPTION

    WHEN exp_rvsl_reject_record THEN
      RAISE;

    WHEN OTHERS THEN
      v_resp_cde := '21';
      P_RESP_MSG  := 'ERROR IN EXPIRY DATE CHECK : Tran Date - ' ||
                 p_business_date || ', Expiry Date - ' || V_EXPRY_DATE || ',' ||
                 SUBSTR(SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;

   END;*/

   -- End Expiry Check

   --Sn check orginal transaction    (-- Amount is missing in reversal request)
   BEGIN

select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag ,TOPUP_CARD_NO , -- Added for mantis id :12436 on 23/09/2013
             cardstatus --Added for defect id : 13251 on 17/12/13
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag ,v_totpup_pan_hash, -- Added for mantis id :12436 on 23/09/2013
             v_orgnl_cardstatus --Added for defect id : 13251 on 17/12/13
        FROM transactionlog
       WHERE rrn = p_orgnl_rrn
         AND business_date = p_orgnl_business_date
         AND business_time = p_orgnl_business_time
         AND customer_card_no = v_hash_pan                         --p_card_no
         AND delivery_channel =
                            p_delv_chnl
                                       --Added by ramkumar.Mk on 25 march 2012
         AND instcode = p_inst_code
         AND response_code = '00';
          -- Added to fetch only success original transaction. -- 20-June-2011
ELSE
 SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag ,TOPUP_CARD_NO , -- Added for mantis id :12436 on 23/09/2013
             cardstatus --Added for defect id : 13251 on 17/12/13
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag ,v_totpup_pan_hash, -- Added for mantis id :12436 on 23/09/2013
             v_orgnl_cardstatus --Added for defect id : 13251 on 17/12/13
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE rrn = p_orgnl_rrn
         AND business_date = p_orgnl_business_date
         AND business_time = p_orgnl_business_time
         AND customer_card_no = v_hash_pan                         --p_card_no
         AND delivery_channel =
                            p_delv_chnl
                                       --Added by ramkumar.Mk on 25 march 2012
         AND instcode = p_inst_code
         AND response_code = '00';
END IF;

      IF v_orgnl_resp_code <> '00'
      THEN
         v_resp_cde := '23';
         p_resp_msg := ' The original transaction was not successful';
         RAISE exp_rvsl_reject_record;
      END IF;

      IF v_tran_reverse_flag = 'Y'
      THEN
         v_resp_cde := '52';
         p_resp_msg :=
                      'The reversal already done for the orginal transaction';
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '53';
         p_resp_msg := 'Matching transaction not found';
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'More than one matching record found in the master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
              'Error while selecting master data' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En check orginal transaction

   ---Sn check card number
   IF v_orgnl_customer_card_no <> v_hash_pan
   THEN
      v_resp_cde := '21';
      p_resp_msg :=
         'Customer card number is not matching in reversal and orginal transaction';
      RAISE exp_rvsl_reject_record;
   END IF;

   --En check card number

   --Sn generate auth id
   BEGIN
      IF v_auth_id IS NULL
      THEN
          --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
         -- --Auth_id length change from 14 to 6 on 221012
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En generate auth id   

 BEGIN
 --Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

       SELECT CSL_TRANS_NARRRATION
        INTO V_FEE_NARRATION
        FROM CMS_STATEMENTS_LOG
        WHERE CSL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
            CSL_RRN = P_ORGNL_RRN AND
            CSL_DELIVERY_CHANNEL = p_delv_chnl AND
            CSL_TXN_CODE = P_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
ELSE
    SELECT CSL_TRANS_NARRRATION
        INTO V_FEE_NARRATION
        FROM VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5733/FSP-991
        WHERE CSL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
            CSL_RRN = P_ORGNL_RRN AND
            CSL_DELIVERY_CHANNEL = p_delv_chnl AND
            CSL_TXN_CODE = P_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
  END IF;


     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_FEE_NARRATION := NULL;
       WHEN OTHERS THEN
        V_FEE_NARRATION := NULL;
     END;


  --En find narration
  --Added for mantis id: 0013639 on 11/02/14
    --Sn get date
    BEGIN
     V_RVSL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_BUSINESS_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');

    EXCEPTION
     WHEN OTHERS THEN
       v_resp_cde := '21';
       p_resp_msg  := 'Problem while converting V_RVSL_TRANDATE date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En get date
    
  --St Added for fee reversal defect :12309 on 17/09/2013
    BEGIN
        SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                          P_RRN,
                          P_DELV_CHNL,
                          P_ORGNL_TERMINAL_ID,
                          P_MERC_ID,
                          P_TXN_CODE,
                          V_RVSL_TRANDATE,
                          P_TXN_MODE,
             -- C1.CSL_TRANS_AMOUNT,
                         V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                          P_CARD_NO,
                          V_ACTUAL_FEECODE,
                          --C1.CSL_TRANS_AMOUNT,
                          V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                          V_ORGNL_TRANFEE_CR_ACCTNO,
                          V_ORGNL_TRANFEE_DR_ACCTNO,
                          V_ORGNL_ST_CALC_FLAG,
                          V_ORGNL_SERVICETAX_AMT,
                          V_ORGNL_ST_CR_ACCTNO,
                          V_ORGNL_ST_DR_ACCTNO,
                          V_ORGNL_CESS_CALC_FLAG,
                          V_ORGNL_CESS_AMT,
                          V_ORGNL_CESS_CR_ACCTNO,
                          V_ORGNL_CESS_DR_ACCTNO,
                          P_ORGNL_RRN,
                         -- V_CARD_ACCT_NO,--Commneted on 20/09/2013 for defect id :12309
                           v_acct_number,--Added for v_acct_number is already used and defect id :12309 on 20/09/2013
                          P_BUSINESS_DATE,
                          P_BUSINESS_TIME,
                          V_AUTH_ID,
                          V_FEE_NARRATION,
                          NULL, --MERCHANT_NAME
                          NULL, --MERCHANT_CITY
                          NULL, --MERCHANT_STATE
                          V_RESP_CDE,
                          P_RESP_MSG);

        IF V_RESP_CDE <> '00' OR P_RESP_MSG <> 'OK' THEN
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       EXCEPTION
        WHEN EXP_RVSL_REJECT_RECORD THEN
          RAISE;

        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          P_RESP_MSG   := 'Error while reversing the fee amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
       END;
    --End Added for fee reversal defect :12309 on 17/09/2013
    
    --Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
    --Modified the below query column cam_acct_no removed for not used on 07/02/14 for Mantis ID:13477
   --Get the card no
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal,
             cam_type_code            -- Added on 17-Apr-2013 for defect 10871
        INTO v_acct_balance, v_ledger_bal, 
             v_cam_type_code          -- Added on 17-Apr-2013 for defect 10871
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number --Added for v_acct_number is already used and defect id :12309 on 20/09/2013
               /* (SELECT cap_acct_no
                   FROM cms_appl_pan
                  WHERE cap_pan_code = v_hash_pan
                    AND cap_mbr_numb = p_mbr_numb
                    AND cap_inst_code = p_inst_code) */
         AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'Invalid Card ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
               'Error while selecting data from card Master for card number '
            || p_card_no;
         RAISE exp_rvsl_reject_record;
   END;

   --Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
    
    
   --Sn find the orginal record
/* Commented on 03/09/2013 for MVCSD-4099(IVR PIN Update /Reversal transaction changes)not required to check card status and fees
  IF V_CAP_PROD_CATG = 'P' THEN

    -- changed the procedure call for duplicate entry changes by T.Narayanan. on 09/10/2012
    --Sn call to authorize txn
    BEGIN
     --v_currcode := p_currcode;
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                          '0400',
                          P_RRN,
                          P_DELV_CHNL,
                          '0',
                          P_TXN_CODE,
                          0,
                          P_BUSINESS_DATE,
                          P_BUSINESS_TIME,
                          P_CARD_NO,
                          NULL,
                          0,
                          NULL,
                          NULL,
                          NULL,
                          V_CURRCODE,
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
                          '0', -- p_stan
                          '000', --Ins User
                          '00', --INS Date
                          0,
                          V_AUTH_ID,
                          V_RESP_CDE,
                          P_RESP_MSG,
                          V_CAPTURE_DATE);

     IF V_RESP_CDE <> '00' AND P_RESP_MSG <> 'OK' THEN
       IF V_RESP_CDE NOT IN ('12', '10') THEN
        P_RESP_MSG := P_RESP_MSG;

        RAISE EXP_REJECT_RECORD;
       END IF;
     END IF;

    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;

     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       P_RESP_MSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
    --En call to authorize txn
  END IF;
  -- changed the procedure call for duplicate entry changes by T.Narayanan. on 09/10/2012

  V_ERRMSG := 'OK';
  IF V_RESP_CDE <> '00' THEN
    BEGIN
     P_RESP_MSG := V_ERRMSG;
     P_RESP_CDE := V_RESP_CDE;
     -- Assign the response code to the out parameter

     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = V_RESP_CDE;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '89';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK TO V_AUTH_SAVEPOINT;

    END;
  ELSE
    P_RESP_CDE := V_RESP_CDE;
  END IF;
*/

  --Sn check the orginal pin offset
   begin
     /* SELECT ccp_pin_off
        INTO v_oldpin_offset
          FROM cms_cardiss_pin_hist
       WHERE ccp_pan_code = v_hash_pan
         AND ccp_rrn = p_orgnl_rrn
         and CCP_MBR_NUMB = P_MBR_NUMB;*/
         --Modified for FSS-1906
        select * into v_oldpin_offset  from  (SELECT ccp_pin_off
        FROM cms_cardiss_pin_hist
       WHERE ccp_pan_code = v_hash_pan
         AND ccp_rrn = p_orgnl_rrn
         and CCP_MBR_NUMB = P_MBR_NUMB
         order by CCP_INS_DATE desc)
         where rownum=1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         /* Commeneted for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
          V_RESP_CDE := '21';
          V_ERRMSG   := 'Old pin offset not found in master ';
          RAISE EXP_RVSL_REJECT_RECORD;
          */
         v_oldpin_offset := NULL;
--Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'More than one record found in repin hist detail ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
            'Error while getting old pin offset ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En check the orginal pin offset

   --Modified the block for MVCSD-4099(Card will be activate while PIN changes) on 30/08/2013
   --Sn change the orginal pin offset
   BEGIN
      --Sn Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
      IF v_oldpin_offset IS NULL
      THEN

         --Added for defect id :13134 on 06/12/2013
         UPDATE cms_appl_pan
            SET cap_firsttime_topup='N'
          WHERE cap_pan_code = v_hash_pan and cap_card_stat in('1','13') and cap_startercard_flag='N' AND cap_inst_code = p_inst_code;


         UPDATE cms_appl_pan
            SET cap_pin_flag = 'Y',
                cap_pin_off = NULL,
                cap_pingen_date = NULL,
                cap_pingen_user = NULL,
                cap_card_stat = 0 ,
                cap_active_date = NULL  --Added for mantis id:12809 on 23/10/2013
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            p_resp_msg :=
                  'Error while updating old pin offset '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
         END IF;


         BEGIN
            sp_log_cardstat_chnge (p_inst_code,
                                   v_hash_pan,
                                   v_encr_pan,
                                   v_auth_id,
                                   '08',
                                   p_rrn,
                                   p_business_date,
                                   p_business_time,
                                   v_resp_cde,
                                   p_resp_msg
                                  );

            IF v_resp_cde <> '00' AND p_resp_msg <> 'OK'
            THEN
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_resp_msg :=
                     'Error while updating card status in log table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
      ELSE

         UPDATE cms_appl_pan
            SET cap_pin_off = v_oldpin_offset
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            p_resp_msg :=
                  'Error while updating old pin offset '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
         END IF;

           --Added for defect id :13134 on 06/12/2013
        if v_orgnl_cardstatus = '0' then  --Added for defect id : 13251 on 17/12/13

         UPDATE cms_appl_pan
            SET cap_firsttime_topup='N',
                cap_card_stat = 0 ,
                cap_active_date = NULL
          WHERE cap_pan_code = v_hash_pan and cap_card_stat in('1','13') and cap_startercard_flag='N' AND cap_inst_code = p_inst_code;

       IF SQL%ROWCOUNT = 1
         THEN
             BEGIN
            sp_log_cardstat_chnge (p_inst_code,
                                   v_hash_pan,
                                   v_encr_pan,
                                   v_auth_id,
                                   '08',
                                   p_rrn,
                                   p_business_date,
                                   p_business_time,
                                   v_resp_cde,
                                   p_resp_msg
                                  );

            IF v_resp_cde <> '00' AND p_resp_msg <> 'OK'
            THEN
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_resp_msg :=
                     'Error while updating card status in log table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
       END IF;
     END IF; --Added for defect id : 13251 on 17/12/13


    END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
            'Error while updating old pin offset '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

--En Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013

--St Added for mantis id :12436 on 23/09/2013
BEGIN
if v_totpup_pan_hash is not null then

      UPDATE cms_appl_pan
            SET cap_pin_flag = 'Y',
                cap_pin_off = NULL,
                cap_pingen_date = NULL,
                cap_pingen_user = NULL
               -- cap_card_stat = 0,
               -- cap_active_date = NULL , --Added for mantis id:12809 on 23/10/2013
          WHERE cap_pan_code = v_totpup_pan_hash AND cap_inst_code = p_inst_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            p_resp_msg :=
                  'Error while updating old pin offset for GPR'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
         END IF;

         delete from cms_cardiss_pin_hist  WHERE ccp_pan_code = v_totpup_pan_hash
         AND ccp_rrn = p_orgnl_rrn
         AND ccp_mbr_numb = p_mbr_numb;

    IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            p_resp_msg :=
                  'Error while deleting old pinhist for GPR'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
         END IF;
end if;
 EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
            'Error while updating old pin offset gor GPR card'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
END;
--En Added for mantis id :12436 on 23/09/2013


   --En change the orginal pin offset
    --Modified the block for MVCSD-4099(Card will be activate while PIN changes) on 30/08/2013
    --SN GET THE CARD STATUS
   /* BEGIN
       SELECT CAP_CARD_STATUS FROM CMS_APPL_PAN WHERE CAP_PAN_CODE=V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;

    END;
    */
    --EN GET THE CARD STATUS

   /* commented and added this ANi and DNi in above transaction log insert changes done on 03/09/2013
    BEGIN

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE TRANSACTIONLOG
        SET ANI = P_ANI, DNI = P_DNI
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_BUSINESS_TIME AND
           DELIVERY_CHANNEL = P_DELV_CHNL;
ELSE
 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET ANI = P_ANI, DNI = P_DNI
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_BUSINESS_TIME AND
           DELIVERY_CHANNEL = P_DELV_CHNL;
END IF;
    EXCEPTION
      WHEN OTHERS THEN
       V_RESP_CDE := '69';
       V_ERRMSG   := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
    END;
   */

   --Sn Getting Card Status description for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013)
   BEGIN
      SELECT ccs_stat_desc, ccs_stat_code
        INTO p_card_stat_desc, v_cap_card_stat
        FROM cms_card_stat, cms_appl_pan
       WHERE ccs_stat_code = cap_card_stat
         AND ccs_inst_code = cap_inst_code
         AND cap_pan_code = v_hash_pan
         AND ccs_inst_code = p_inst_code;

      p_card_status := v_cap_card_stat;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'Card Status not found ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
               'Error while selecting data from card status '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

--En Getting Card Status description for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013)

   --Sn update reverse flag
   BEGIN
IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET tran_reverse_flag = 'Y'
       WHERE rrn = p_orgnl_rrn
         AND business_date = p_orgnl_business_date
         AND business_time = p_orgnl_business_time
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
ELSE
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET tran_reverse_flag = 'Y'
       WHERE rrn = p_orgnl_rrn
         AND business_date = p_orgnl_business_date
         AND business_time = p_orgnl_business_time
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
 END IF;

      IF SQL%ROWCOUNT = 0
      THEN
         v_resp_cde := '21';
         p_resp_msg := 'Reverse flag is not updated ';
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
  --En update reverse flag

 --Added for VMS-5735/FSP-991
  --Added for defect id :14868 on 28/05/2014(For loop added bcos getting more than one cards)
   FOR j IN (select customer_card_no,customer_card_no_encr, cardstatus,fn_dmaps_main(customer_card_no_encr) cardnumber    
                    FROM VMSCMS.TRANSACTIONLOG_VW WHERE delivery_channel='05' AND txn_code='02' AND instcode = p_inst_code
                    AND orgnl_rrn=p_orgnl_rrn AND business_date=p_orgnl_business_date AND 
                    customer_acct_no=v_acct_number)-- and customer_acct_no condition added by saravanakumara on feb 12,16
          LOOP
     --St Added for mantis id :12436 on 23/09/2013      
  BEGIN
    /*
       --Modified for defect id : 13251 on 17/12/13
       select customer_card_no,customer_card_no_encr, cardstatus into v_starterCard_hash ,v_starterCard_encr , v_starterCardStatus from transactionlog
       where delivery_channel='05' and txn_code='02' AND instcode = p_inst_code
       and orgnl_rrn=p_orgnl_rrn and business_date=p_orgnl_business_date;
    */
      if j.customer_card_no is not null then

        UPDATE cms_appl_pan
            SET cap_card_stat = j.cardstatus
            WHERE cap_pan_code = j.customer_card_no AND cap_inst_code = p_inst_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            p_resp_msg :=
                  'Error while updating old card status '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
         END IF;


        if j.cardstatus = '0' then
            v_txn_code := '08';
        elsif j.cardstatus = '1' then
             v_txn_code := '01';
        elsif j.cardstatus = '8' then
             v_txn_code := '04';
        elsif j.cardstatus = '12' then
             v_txn_code := '03';
         elsif j.cardstatus = '3' then
             v_txn_code := '41';
        end if;

         BEGIN
            sp_log_cardstat_chnge (p_inst_code,
                                   j.customer_card_no,
                                   j.customer_card_no_encr,
                                   v_auth_id,
                                   v_txn_code,
                                   p_rrn,
                                   p_business_date,
                                   p_business_time,
                                   v_resp_cde,
                                   p_resp_msg
                                  );

            IF v_resp_cde <> '00' AND p_resp_msg <> 'OK'
            THEN
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_resp_msg :=
                     'Error while updating card status in log table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;


      p_old_card_number := j.cardnumber;
      end if;

   EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
        NULL;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
                  'Error while selecting starter card details ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
    END;
   END LOOP;
  --End Added for mantis id :12436 on 23/09/2013

  V_RESP_CDE := '1';
   --Sn Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_cde
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delv_chnl
         AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
               p_resp_msg||'Problem while selecting data from response master for respose code'
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';
         RAISE exp_rvsl_reject_record;
   END;

   --En generate response code
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code,
                   txn_type, txn_mode, txn_status, response_code,
                   business_date, business_time, customer_card_no,
                   bank_code, productid, categoryid, auth_id,
                   trans_desc, system_trace_audit_no, instcode,
                   customer_card_no_encr, proxy_number, reversal_code,
                   customer_acct_no, acct_balance, ledger_balance,
                   response_id, add_ins_date, add_ins_user, cardstatus,
                   error_msg, acct_type, time_stamp, ani, dni,amount,total_amount,TRANFEE_AMT ,CR_DR_FLAG,
                   orgnl_card_no, orgnl_business_time, orgnl_business_date, orgnl_rrn  --Added for mantis id: 0013639 on 11/02/14
                  )
           VALUES (p_msg_typ, p_rrn, p_delv_chnl, p_terminal_id,
                   TO_DATE (p_business_date, 'YYYY/MM/DD'), p_txn_code,
                   v_txn_type, p_txn_mode, 'C', p_resp_cde,
                   p_business_date, p_business_time, v_hash_pan,
                   p_bank_code, v_prod_code, v_prod_cattype, v_auth_id,
                   v_trans_desc, p_stan, p_inst_code,
                   v_encr_pan, v_proxunumber, p_rvsl_code,
                   v_acct_number, v_acct_balance, v_ledger_bal,  --Added for v_acct_number is already used and defect id :12309 on 20/09/2013
                   v_resp_cde, SYSDATE,       -- Added by Ramesh.A on 25/02/12
                                       1,     -- Added by Ramesh.A on 25/02/12
                                         v_cap_card_stat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                   p_resp_msg,                -- Added by sagar on 04-Sep-2012
                              v_cam_type_code, v_timestamp, p_ani, p_ani,'0.00','0.00','0',v_orgnl_transaction_type,
                              v_encr_pan,p_orgnl_business_time,p_orgnl_business_date,p_orgnl_rrn  --Added for mantis id: 0013639 on 11/02/14
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_resp_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En create a entry in txn log

   --Sn create a entry for successful
   BEGIN
      IF p_resp_msg = 'OK'
      THEN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_process_flag, ctd_process_msg, ctd_rrn,
                      ctd_system_trace_audit_no, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                      p_msg_typ, p_txn_mode, p_business_date,
                      p_business_time, v_hash_pan,
                      'Y', 'Successful', p_rrn,
                      p_stan, p_inst_code,
                      v_encr_pan, v_acct_number
                     );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
               'Problem while selecting data from response master '
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '32';
         RAISE exp_rvsl_reject_record;
   END;

  --En create a entry for successful
--En Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013

  IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
    BEGIN
       vmsfee.fee_freecnt_reverse (v_acct_number, v_orgnl_txn_feecode, p_resp_msg);
    
       IF p_resp_msg <> 'OK' THEN
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_resp_cde := '21';
          p_resp_msg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
  END IF;
   /* Commeneted and moved to up changes done on 03/09/2013
  --Sn generate auth id
  BEGIN
    IF V_AUTH_ID IS NULL THEN

     --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
    -- --Auth_id length change from 14 to 6 on 221012
     SELECT   LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
       INTO V_AUTH_ID
       FROM DUAL;

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id
*/

/*  Commeneted and moved to up changes done on 03/09/2013
 -- V_RESP_CDE := '1';
  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CDE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INST_CODE AND
         CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate response code
  P_RESP_MSG := 'OK';
*/
EXCEPTION
   --<<MAIN EXCEPTION>>
  /*  Commenteed for not used
  WHEN exp_reject_record
   THEN
      p_resp_cde := v_resp_cde;
   -- P_RESP_MSG := V_ERRMSG;
   */
   WHEN exp_rvsl_reject_record
   THEN
    ROLLBACK TO v_savepoint;
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      --P_RESP_MSG := V_ERRMSG;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  p_resp_msg||'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_cde := '89';
      END;

      --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
        IF v_prod_code IS NULL THEN
        SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
          INTO v_prod_code, v_prod_cattype, v_cap_card_stat, v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_card_no);
        END IF;      
      --En Added by Pankaj S. for logging changes(Mantis ID-13160)
            
      
      -- P_RESP_MSG := V_ERRMSG;
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code   --Added by Pankaj S. for logging changes(Mantis ID-13160)  
           INTO v_acct_balance, v_ledger_bal,
                v_cam_type_code   --Added by Pankaj S. for logging changes(Mantis ID-13160)
           FROM cms_acct_mast
          --Sn Modified by Pankaj S. for logging changes(Mantis ID-13160)
          WHERE cam_acct_no =v_acct_number
                   /*(SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_inst_code = p_inst_code)*/
          --En Modified by Pankaj S. for logging changes(Mantis ID-13160)                       
            AND cam_inst_code = p_inst_code;

      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

            BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code,
                      txn_type, txn_mode, txn_status,
                      response_code, business_date,
                      business_time, customer_card_no, topup_card_no,
                      topup_acct_no, topup_acct_type, bank_code,
                      total_amount, currencycode, addcharge, productid,
                      categoryid, atm_name_location, auth_id, amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id, ani,
                      dni, cardstatus,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                      trans_desc ,       -- FOR Transaction detail report issue
                      error_msg,
                      --Sn Added by Pankaj S. for loggign changes(Mantis ID-13160)
                      time_stamp,cr_dr_flag,
                      --En Added by Pankaj S. for loggign changes(Mantis ID-13160)
                      orgnl_card_no, orgnl_business_time, orgnl_business_date, orgnl_rrn  --Added for mantis id: 0013639 on 11/02/14
                     )
              VALUES ('0400', p_rrn, p_delv_chnl, 0,
                      TO_DATE (p_business_date, 'YYYY/MM/DD'), p_txn_code,
                      p_txn_type, 0, DECODE (p_resp_cde, '00', 'C', 'F'),
                      p_resp_cde, p_business_date,
                      SUBSTR (p_business_time, 1, 10), v_hash_pan, NULL,
                      NULL, NULL, p_inst_code,
                      '0.00',  --Modified by Pankaj S. for loggign changes(Mantis ID-13160)
                      v_currcode, NULL, 
                      v_prod_code, v_prod_cattype,--SUBSTR (p_card_no, 1, 4),NULL,  --Modified by Pankaj S. for loggign changes(Mantis ID-13160)
                       0, '', '0.00', --Modified by Pankaj S. for loggign changes(Mantis ID-13160)
                      '0.00', '0.00', --Modified by Pankaj S. for loggign changes(Mantis ID-13160) 
                      p_inst_code,
                      v_encr_pan, v_encr_pan,
                      '', 69, v_acct_number,  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                      v_acct_balance, v_ledger_bal, v_resp_cde,--p_resp_cde, --Modified by Pankaj S. for loggign changes(Mantis ID-13160)
                      p_ani,
                      p_dni, v_cap_card_stat,
                    --Added cardstatus insert in transactionlog by srinivasu.k
                      v_trans_desc,     -- FOR Transaction detail report issue
                      p_resp_msg,
                      --Sn Added by Pankaj S. for loggign changes(Mantis ID-13160)
                      v_timestamp,v_orgnl_transaction_type,
                      --En Added by Pankaj S. for loggign changes(Mantis ID-13160)
                      v_encr_pan,p_orgnl_business_time,p_orgnl_business_date,p_orgnl_rrn  --Added for mantis id: 0013639 on 11/02/14
                     );

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_cde := '89';
            p_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, '0400',
                      0, p_business_date, p_business_time,
                      v_hash_pan, 0, v_currcode,
                      0, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      p_resp_msg, p_rrn, p_inst_code,
                      v_encr_pan, ''
                     );
      -- P_RESP_MSG := V_ERRMSG;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_cde := '22';                             -- Server Declined
            ROLLBACK;
      END;
   WHEN OTHERS
   THEN
      ROLLBACK TO v_savepoint;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_fee_amount, ctd_waiver_amount,
                         ctd_servicetax_amount, ctd_cess_amount,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number
                        )
                 VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                         p_msg_typ, p_txn_mode, p_business_date,
                         p_business_time, v_hash_pan,
                         NULL, NULL,
                         NULL, NULL,
                         'E', p_resp_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_cde := '69';           -- Server Decline Response 220509
               ROLLBACK;
               RETURN;
         END;
      --  P_RESP_MSG := V_ERRMSG;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_cde := '99';
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_process_flag, ctd_process_msg, ctd_rrn,
                      ctd_system_trace_audit_no, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                      p_msg_typ, p_txn_mode, p_business_date,
                      p_business_time, v_hash_pan,
                      NULL, NULL,
                      NULL, NULL,
                      'E', p_resp_msg, p_rrn,
                      p_stan, p_inst_code,
                      v_encr_pan, v_acct_number
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_cde := '69';              -- Server Decline Response 220509
            ROLLBACK;
            RETURN;
      END;
--P_RESP_MSG := V_ERRMSG;
END;
/
SHOW ERROR