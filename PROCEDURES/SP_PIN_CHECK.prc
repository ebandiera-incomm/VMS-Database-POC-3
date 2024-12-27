create or replace PROCEDURE               vmscms.sp_pin_check (
   instcode   IN     NUMBER,
   pancode    IN     VARCHAR,
   busidate   IN     VARCHAR2,
   success    IN     VARCHAR,
   cnt           OUT NUMBER,
   errmsg        OUT VARCHAR2)
AS
   v_pin_count     vms_pin_check.vpc_pin_count%TYPE;
   v_hash_pan      vms_pin_check.vpc_pan_code%TYPE;
   v_encr_pan      vms_pin_check.vpc_pan_code_encr%TYPE;
   v_tran_date     DATE;
   v_rrn           transactionlog.rrn%TYPE;
   v_tran_code     transactionlog.txn_code%TYPE DEFAULT '26';
   v_del_channel   transactionlog.delivery_channel%TYPE DEFAULT '05';
   v_tran_desc     cms_transaction_mast.ctm_tran_desc%TYPE:='PINTRIES-CARDSTAT UPDATE';
   v_acct_bal      cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal    cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_no       cms_acct_mast.cam_acct_no%TYPE;
   v_pin_count_def NUMBER;
   v_exp_main_reject   EXCEPTION;
  -- v_pintrybypass_flag CMS_PROD_CATTYPE.cpc_pintrybypass_flag%TYPE;
   v_prod_code     cms_appl_pan.cap_prod_code%TYPE;
   v_card_type     cms_appl_pan.cap_card_type%TYPE;
   v_cash_access_approve_count  NUMBER;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   
/*************************************************
	   * Modified by       : Ravi N
       * Modified Date     : 06-Jan-2021
       * Modified Reason   : VMS-3596
       * Reviewer          : Ubaidur Rahman.H
       * Build Number      : VMSGPRHOST_R41_B0002
	   
	        * Modified by       : Magesh Kumar S
       * Modified Date     : 03-Nov-2022
       * Modified Reason   : VMS-6441
       * Reviewer          : Pankaj/Venkat/John
       * Build Number      : VMSGPRHOST_R71_B0002

*************************************************/   
 
BEGIN
   errmsg := 'OK';

   BEGIN
      v_hash_pan := gethash (pancode);
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg := 'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
         RAISE v_exp_main_reject;
   END;

   BEGIN
      v_tran_date := TO_DATE (SUBSTR (TRIM (busidate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg :=
            'Problem while converting transaction date-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE v_exp_main_reject;
   END;
   
   BEGIN													--- Added for VMS-3596
      SELECT cap_acct_no,cap_prod_code,cap_card_type
			into v_acct_no,v_prod_code,v_card_type
                         FROM cms_appl_pan
                        WHERE     cap_pan_code = v_hash_pan
                              AND cap_mbr_numb = '000'
                              AND cap_inst_code = instcode;
       
    EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
               'Problem while fetching acct / prod cattype infprmation from PAN table-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_exp_main_reject;
      END;
   
   
   

   IF (success != '00')
   THEN

         v_pin_count := 0;

      BEGIN
         v_encr_pan := fn_emaps_main (pancode);
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg := 'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_exp_main_reject;
      END;
      
       /*  BEGIN													--- Added for VMS-3596

        SELECT CPC_PINTRYBYPASS_FLAG
             INTO v_pintrybypass_flag
              FROM CMS_PROD_CATTYPE
             WHERE CPC_INST_CODE = instcode
			 AND CPC_PROD_CODE = v_prod_code
			 AND CPC_CARD_TYPE =  v_card_type;

    EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
               'Problem while fetching CPC_PINTRYBYPASS_FLAG from productcatg table-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_exp_main_reject;
      END; */
             
     
      
    

      BEGIN
            UPDATE vms_pin_check
               SET vpc_pin_count =
                      (CASE
                          WHEN vpc_txn_date = v_tran_date THEN vpc_pin_count + 1
                          ELSE 1
                       END),
                   vpc_txn_date = v_tran_date,
                   vpc_lupd_date = SYSDATE
             WHERE vpc_pan_code = v_hash_pan
         RETURNING vpc_pin_count
              INTO v_pin_count;

         IF SQL%ROWCOUNT = 0
         THEN
            INSERT INTO vms_pin_check
                 VALUES (instcode,
                         v_hash_pan,
                         v_encr_pan,
                         1,
                         v_tran_date,
                         SYSDATE,
                         SYSDATE);

            v_pin_count := 1;

         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
               'Problem in updating the pin count-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_exp_main_reject;
      END;
	  
	   BEGIN

          select count(1) into v_cash_access_approve_count from vmscms.gpr_valid_cardstat,vmscms.cms_transaction_mast
          where gvc_delivery_channel = ctm_delivery_channel
          and gvc_tran_code = ctm_tran_code
          and gvc_inst_code = ctm_inst_code
          and gvc_prod_code = v_prod_code
          and gvc_card_type = v_card_type
          and gvc_approve_txn = 'Y'
          and ctm_cash_access_flag = 'Y'
          and rownum  = 1 ;

      EXCEPTION
        WHEN OTHERS
        THEN
            v_cash_access_approve_count := 0;

      END;

      IF v_cash_access_approve_count > 0 THEN

      SELECT CIP_PARAM_VALUE
              INTO v_pin_count_def
              FROM cms_inst_param
             WHERE CIP_PARAM_KEY = 'TOTAL_PIN_ATTEMPTS' AND CIP_INST_CODE='1';

      IF (v_pin_count >= v_pin_count_def)
      THEN
         BEGIN
            UPDATE cms_appl_pan
               SET cap_card_stat = '0'
             WHERE     cap_pan_code = v_hash_pan
                   AND cap_mbr_numb = '000'
                   AND cap_inst_code = instcode
                   AND cap_card_stat <> '9';

            IF SQL%ROWCOUNT = 0
            THEN
               errmsg := 'Card status not updated in PAN master';
               cnt := v_pin_count;
               RAISE v_exp_main_reject;
            END IF;
         EXCEPTION
            when v_exp_main_reject then
               raise;
            WHEN OTHERS
            THEN
               errmsg :=
                  'Error while updating card status-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_exp_main_reject;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_bal, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_acct_no = v_acct_no                      
                   AND cam_inst_code = instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               errmsg := 'Account details not found';
               RAISE v_exp_main_reject;
            WHEN OTHERS
            THEN
               errmsg :=
                  'Error while getting account details-'
                  || SUBSTR (SQLERRM, 1, 200);
                  RAISE v_exp_main_reject;
         END;

         v_rrn :=
               'PEU'
            || TO_CHAR (SYSDATE, 'YYYYMMDD')
            || seq_pintry_crdstatupd_rrn.NEXTVAL;

         BEGIN
            INSERT INTO transactionlog (msgtype,
                                        rrn,
                                        delivery_channel,
                                        date_time,
                                        txn_code,
                                        txn_type,
                                        txn_status,
                                        response_code,
                                        business_date,
                                        business_time,
                                        customer_card_no,
                                        bank_code,
                                        auth_id,
                                        trans_desc,
                                        instcode,
                                        customer_card_no_encr,
                                        customer_acct_no,
                                        acct_balance,
                                        ledger_balance,
                                        response_id,
                                        txn_mode,
                                        cardstatus)
                 VALUES ('0200',
                         v_rrn,
                         v_del_channel,
                         SYSDATE,
                         v_tran_code,
                         '0',
                         'C',
                         '00',
                         TO_CHAR (SYSDATE, 'YYYYMMDD'),
                         TO_CHAR (SYSDATE, 'hh24miss'),
                         v_hash_pan,
                         instcode,
                         LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                         v_tran_desc,
                         instcode,
                         v_encr_pan,
                         v_acct_no,
                         v_acct_bal,
                         v_ledger_bal,
                         1,
                         0,
                         '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               errmsg :=
                  'Error in inserting transactionlog-'
                  || SUBSTR (SQLERRM, 1, 200);
                  RAISE v_exp_main_reject;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                                 ctd_txn_code,
                                                 ctd_txn_type,
                                                 ctd_msg_type,
                                                 ctd_txn_mode,
                                                 ctd_business_date,
                                                 ctd_business_time,
                                                 ctd_customer_card_no,
                                                 ctd_process_flag,
                                                 ctd_process_msg,
                                                 ctd_rrn,
                                                 ctd_inst_code,
                                                 ctd_customer_card_no_encr,
                                                 ctd_cust_acct_number)
                 VALUES (v_del_channel,
                         v_tran_code,
                         '0',
                         '0200',
                         0,
                         TO_CHAR (SYSDATE, 'YYYYMMDD'),
                         TO_CHAR (SYSDATE, 'hh24miss'),
                         v_hash_pan,
                         'Y',
                         'Successful',
                         v_rrn,
                         instcode,
                         v_encr_pan,
                         v_acct_no);
         EXCEPTION
            WHEN OTHERS
            THEN
               errmsg :=
                  'Error in inserting cms_transaction_log_dtl-'
                  || SUBSTR (SQLERRM, 1, 200);
                  RAISE v_exp_main_reject;
         END;
      END IF;
   END IF;
   END IF;


   IF (success = '00')
   THEN
      BEGIN
         UPDATE vms_pin_check
            SET vpc_pin_count =0,
                vpc_txn_date = v_tran_date,
                vpc_lupd_date = SYSDATE
          WHERE vpc_pan_code = v_hash_pan AND vpc_pin_count<>0 ;

         v_pin_count := 0;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
               'Problem in updating the pin count-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_exp_main_reject;
      END;
   END IF;

       cnt := v_pin_count;

EXCEPTION
    WHEN v_exp_main_reject
    THEN
      cnt := nvl(v_pin_count,0);
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception ' || SUBSTR (SQLERRM, 1, 200);
      cnt := nvl(v_pin_count,0);
END;

/
SHOW ERROR;

