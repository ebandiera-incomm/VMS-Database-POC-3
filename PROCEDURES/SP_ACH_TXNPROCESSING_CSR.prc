CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACH_TXNPROCESSING_CSR (  prm_inst_code           IN  number,
                                                        prm_revrsl_code         IN  varchar2,
                                                        prm_msg_type            IN  varchar2,
                                                        prm_rrn                 IN  varchar2,
                                                        prm_stan                IN  varchar2,
                                                        prm_tran_date           IN  varchar2,
                                                        prm_tran_time           IN  varchar2,
                                                        prm_txn_amt             IN  varchar2,
                                                        prm_txn_code            IN  varchar2,
                                                        prm_delivery_chnl       IN  varchar2,
                                                        prm_txn_mode            IN  varchar2,
                                                        prm_mbr_numb            IN  varchar2,
                                                        prm_orgnl_rrn           IN  VARCHAR2,
                                                        prm_orgnl_card_no       IN  varchar2,
                                                        prm_orgnl_stan          IN  VARCHAR2,
                                                        prm_orgnl_tran_date     IN  VARCHAR2,
                                                        prm_orgnl_tran_time     IN  VARCHAR2,
                                                        prm_orgnl_txn_amt       IN  VARCHAR2,
                                                        prm_orgnl_txn_code      IN  VARCHAR2,
                                                        prm_orgnl_delivery_chnl IN  VARCHAR2,
                                                        prm_orgnl_auth_id       IN  VARCHAR2,
                                                        prm_reason_code         IN  VARCHAR2,
                                                        prm_remark              IN  VARCHAR2,
                                                        --prm_reason_desc         IN  VARCHAR2,
                                                        prm_Txn_processFlag     IN  VARCHAR2,                                                   
                                                        prm_approve_rej         IN  varchar2,
                                                        prm_ipaddress            IN  VARCHAR2,  --added by amit on 07-Oct-2012
                                                        prm_ins_user            IN  NUMBER,
                                                        prm_r17_response_in     IN VARCHAR2,
                                                        prm_resp_code           OUT VARCHAR2,
                                                        prm_errmsg              OUT VARCHAR2,
                                                        prm_ach_resp_cde        OUT VARCHAR2,
                                                        prm_ach_err_msg         OUT VARCHAR2,
                                                        prm_ach_startledgerbal  OUT VARCHAR2,
                                                        prm_ach_startaccountbalance OUT VARCHAR2,
                                                        prm_ach_endledgerbal    OUT VARCHAR2,
                                                        prm_ach_endaccountbalance OUT VARCHAR2,
                                                        prm_ach_auth_id           OUT VARCHAR2
                                                      )
is

/******************************************************************************************
     * Created Date     : 01/Mar/2012.
     * Created By       : Sagar More.
     * Purpose          : to process ACH EXCEPTION QUEUE transactions
     * Modified By      : Amit Sonar
     * Modified Reason  : To log ipaddress and lupduser in transactionlog
     * Modified Date    : 07-Oct-2012
     * Reviewer         : Sagar
     * Reviewed Date    : 09-Oct-2012
     * Build Number     : RI0019_B0008
     
     * Modified By      : Dhiarj
     * Modified Reason  : ACH Exception Queue's are allowing 1 deposit to be posted multiple 
                          times if more than 1 user is in the queue
     * Modified For     : 10570
     * Modified Date    : 11-Mar-2013
     * Reviewer         : NA
     * Reviewed Date    : NA
     * Build Number     : RI0023.2_B0022
     
     * Modified By      : Pankaj S.
     * Modified Date    : 21-Mar-2013
     * Modified Reason  : FSS-390 (Passing auth id of ACH txn to log same for system initiated card status change)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : CSR3.5.1_RI0024_B0007
     
     * Modified By      : Pankaj S.
     * Modified Date    : 01-07-2015 / 22-07-2015
     * Modified Reason  : For new ach changes
     * Reviewer         : Sarvanan
     * Reviewed Date    : 
     * Build Number     : VMSGPRHOST3.0.4
     
      * Modified By      : Abdul Hameed M.A
     * Modified Date    : 23-07-2015
     * Modified Reason  : For new ach changes
     * Reviewer         : Spankaj
     * Reviewed Date    : 23-07-2015
     * Build Number     : VMSGPRHOST3.0.4
     
          
     * Modified By      : Siva Kumar M
     * Modified Date    : 05-01-2016
     * Modified Reason  : Reason code logging
     * Reviewer         : Saravana kumar
     * Reviewed Date    : 05-01-2016
     * Build Number     : VMSGPRHOST3.3_B0002
	 
	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
     
     * Modified by       : Mageshkumar  S
     * Modified Date     : 28-May-20
     * Modified For      : VMS-2548
     * Reviewer          : Saravanakumar A
     * Build Number      : R31_build_3
     
      * Modified by       : BASKAR
     * Modified Date     : 10-Nov-20
     * Modified For      : VMS-3326
     * Reviewer          : Saravanakumar A
     * Build Number      : 
     
     * Modified by       : RAJ DEVKOTA
     * Modified Date     : 17-DEC-20
     * Modified For      : VMS-3412
     * Reviewer          : Ubaidur Rahman.H
     * Reviewed Date     : 18/Dec/2020.
     * Build Number      : VMS_GPRHOST_R40_B1    

 ********************************************************************************************/



   v_resp_cde               VARCHAR2 (2);
   v_err_msg                VARCHAR2 (300);
   v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id                VARCHAR2 (6);
   v_rrn_count              NUMBER (3);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_card_acct_no           cms_appl_pan.cap_acct_no%TYPE;
   dum                      NUMBER;
   exp_reject_record        exception;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_proxy_number           transactionlog.proxy_number%TYPE;
   v_tran_desc              cms_transaction_mast.ctm_tran_desc%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   v_mbr_numb               cms_appl_pan.cap_mbr_numb%TYPE;


   v_orgnl_terminal_id      transactionlog.terminal_id%type;
   v_orgnl_msgtype          transactionlog.msgtype%type;
   v_orgnl_rrn              transactionlog.rrn%type;
   v_orgnl_delivery_channel transactionlog.delivery_channel%type;
   v_orgnl_txn_code         transactionlog.txn_code%type;
   v_orgnl_txn_mode         transactionlog.txn_mode%type;
   v_orgnl_response_code    transactionlog.response_code%type;
   v_orgnl_business_date    transactionlog.business_date%type;
   v_orgnl_business_time    transactionlog.business_time%type;
   v_orgnl_total_amount     transactionlog.total_amount%type;
   v_orgnl_amount           transactionlog.amount%type;
   v_orgnl_instcode         transactionlog.instcode%type;
   v_orgnl_cardnum          varchar2(50);
   v_orgnl_reversal_code    transactionlog.reversal_code%type;
   v_orgnl_customer_acct_no transactionlog.customer_acct_no%type;
   v_orgnl_achfilename      transactionlog.achfilename%type;
   v_orgnl_rdfi             transactionlog.rdfi%type;
   v_orgnl_seccodes         transactionlog.seccodes%type;
   v_orgnl_impdate          transactionlog.impdate%type;
   v_orgnl_processdate      transactionlog.processdate%type;
   v_orgnl_effectivedate    transactionlog.effectivedate%type;
   v_orgnl_tracenumber      transactionlog.tracenumber%type;
   v_orgnl_incoming_crfileid transactionlog.incoming_crfileid%type;
   v_orgnl_auth_id          transactionlog.auth_id%type;
   v_orgnl_achtrantype_id   transactionlog.achtrantype_id%type;
   v_orgnl_indidnum         transactionlog.indidnum%type;
   v_orgnl_indname          transactionlog.indname%type;
   v_orgnl_companyname      transactionlog.companyname%type;
   v_orgnl_companyid        transactionlog.companyid%type;
   v_orgnl_ach_id           transactionlog.ach_id%type;
   v_orgnl_compentrydesc    transactionlog.compentrydesc%type;
   v_orgnl_response_id      transactionlog.response_id%type;
   v_orgnl_customerlastname transactionlog.customerlastname%type;
   v_orgnl_odfi             transactionlog.odfi%type;
   v_orgnl_currencycode     transactionlog.currencycode%type;

   v_startledgerbal         cms_acct_mast.cam_ledger_bal%type;
   v_startaccountbalance    cms_acct_mast.cam_acct_bal%type;
   v_endledgerbal           cms_acct_mast.cam_ledger_bal%type;
   v_endaccountbalance      cms_acct_mast.cam_acct_bal%type;
   v_out_auth_id            varchar2(50);

   v_ach_resp_cde           transactionlog.RESPONSE_CODE%type;
   v_ach_err_msg           transactionlog.ERROR_MSG%type;
   v_ach_startledgerbal    transactionlog.LEDGER_BALANCE%type;
   v_ach_startaccountbalance transactionlog.ACCT_BALANCE%type;
   v_ach_endledgerbal       transactionlog.LEDGER_BALANCE%type;
   v_ach_endaccountbalance  transactionlog.ACCT_BALANCE%type;
   v_ach_auth_id             transactionlog.AUTH_ID%type;
   v_orgnl_drcr_flag         cms_transaction_mast.ctm_credit_debit_flag%type;
   v_addcharge        transactionlog.ADDCHARGE%type;
   v_achblckexpry_period  CMS_PROD_CATTYPE.CPC_ACHBLCKEXPRY_PERIOD%type;
   v_reason_desc         cms_spprt_reasons.csr_reasondesc%TYPE;
   v_resp_desc           cms_response_mast.cms_resp_desc%TYPE;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
Begin



    Begin

        v_err_msg := 'OK';

      BEGIN
         v_hash_pan := gethash (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=  'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

IF prm_orgnl_auth_id IS NULL THEN

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '21';
            RETURN;
      END;
      
      ELSE
      
      v_auth_id := prm_orgnl_auth_id;
      
      END IF;

      BEGIN

         SELECT ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


        BEGIN



             SELECT ctm_credit_debit_flag
               INTO v_orgnl_drcr_flag
               FROM cms_transaction_mast
              WHERE ctm_tran_code = prm_orgnl_txn_code
                AND ctm_delivery_channel = prm_orgnl_delivery_chnl
                AND ctm_inst_code = prm_inst_code;

        EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_resp_cde := '49';
                v_err_msg :=
                      'Transaction detail is not found in master for original txn '
                   || prm_orgnl_txn_code
                   || 'delivery channel '
                   || prm_orgnl_delivery_chnl;
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Problem while selecting debit/credit flag for original txn'
                   || SUBSTR (SQLERRM, 1, 100);
                RAISE exp_reject_record;
        END;



      BEGIN
	--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
			 SELECT COUNT (1)
			   INTO v_rrn_count
			   FROM transactionlog
			  WHERE instcode = prm_inst_code
				AND customer_card_no = v_hash_pan
				AND rrn = prm_rrn
				AND delivery_channel = prm_delivery_chnl
				AND txn_code = prm_txn_code
				AND business_date = prm_tran_date
				AND business_time = prm_tran_time;
	ELSE
			SELECT COUNT (1)
			   INTO v_rrn_count
			   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			  WHERE instcode = prm_inst_code
				AND customer_card_no = v_hash_pan
				AND rrn = prm_rrn
				AND delivery_channel = prm_delivery_chnl
				AND txn_code = prm_txn_code
				AND business_date = prm_tran_date
				AND business_time = prm_tran_time;
	END IF;			

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN found' || prm_rrn;
            RAISE exp_reject_record;
         END IF;
      END;

     ---SN Reason code description 
     
     begin
     
     select  csr_reasondesc 
     into v_reason_desc 
     from cms_spprt_reasons 
     where csr_spprt_rsncode=prm_reason_code
     and csr_inst_code=prm_inst_code;
      
      EXCEPTION
        WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from spprt reasons  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
     
     end;
     
     
     -- EN  Reason code description 


      BEGIN

         SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_card_stat,
                cap_expry_date,cap_mbr_numb
           INTO v_prod_code, v_card_type, v_card_acct_no, v_card_stat,
                v_expry_date,v_mbr_numb
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code
            AND cap_pan_code = v_hash_pan
            -- changed from clear pan to hash pan
            AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Pan code is not defined ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from card master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


      BEGIN

         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_bal
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_inst_code AND cam_acct_no = v_card_acct_no
          for update;

         --prm_acct_bal := v_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Account not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from acct master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


      BEGIN
	  
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN

         SELECT proxy_number,
                msgtype,
                rrn,
                delivery_channel,
                txn_code,
                txn_mode,
                response_code,
                business_date,
                business_time,
                nvl(to_char(total_amount,'999999999990.00'),'0.00') total_amount,
                nvl(to_char(amount,'999999999990.00'),'0.00') amount,
                instcode,
                fn_dmaps_main(customer_card_no_encr) as cardnum,
                reversal_code,
                customer_acct_no,
                achfilename,rdfi,
                seccodes,
                impdate,
                processdate,
                effectivedate,
                tracenumber,
                incoming_crfileid,
                auth_id,
                achtrantype_id,
                indidnum,
                indname,
                companyname,
                companyid,
                ach_id,
                compentrydesc,
                response_id,
                customerlastname ,
                odfi,
                currencycode,
                terminal_id,
                decode(addcharge,'Y',NULL,addcharge)
           INTO v_proxy_number,
                v_orgnl_msgtype,
                v_orgnl_rrn,
                v_orgnl_delivery_channel,
                v_orgnl_txn_code,
                v_orgnl_txn_mode,
                v_orgnl_response_code,
                v_orgnl_business_date,
                v_orgnl_business_time,
                v_orgnl_total_amount,
                v_orgnl_amount,
                v_orgnl_instcode,
                v_orgnl_cardnum,
                v_orgnl_reversal_code,
                v_orgnl_customer_acct_no,
                v_orgnl_achfilename,
                v_orgnl_rdfi,
                v_orgnl_seccodes,
                v_orgnl_impdate,
                v_orgnl_processdate,
                v_orgnl_effectivedate,
                v_orgnl_tracenumber,
                v_orgnl_incoming_crfileid,
                v_orgnl_auth_id,
                v_orgnl_achtrantype_id,
                v_orgnl_indidnum,
                v_orgnl_indname,
                v_orgnl_companyname,
                v_orgnl_companyid,
                v_orgnl_ach_id,
                v_orgnl_compentrydesc,
                v_orgnl_response_id,
                v_orgnl_customerlastname ,
                v_orgnl_odfi,
                v_orgnl_currencycode,
                v_orgnl_terminal_id,
                v_addcharge
           FROM transactionlog
          WHERE instcode         = prm_inst_code
            AND rrn              = prm_orgnl_rrn
            AND business_date    = prm_orgnl_tran_date             --changed here
            AND business_time    = prm_orgnl_tran_time             --changed here
            AND customer_card_no = v_hash_pan
            --AND auth_id          = prm_orgnl_auth_id          commented as per requirement 14032012
            and (  auth_id     is null or auth_id=  prm_orgnl_auth_id )
            AND txn_code         = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl 
              AND  response_code <> '00' ;
        --    AND csr_achactiontaken <> 'R' ;
ELSE
			     SELECT proxy_number,
                msgtype,
                rrn,
                delivery_channel,
                txn_code,
                txn_mode,
                response_code,
                business_date,
                business_time,
                nvl(to_char(total_amount,'999999999990.00'),'0.00') total_amount,
                nvl(to_char(amount,'999999999990.00'),'0.00') amount,
                instcode,
                fn_dmaps_main(customer_card_no_encr) as cardnum,
                reversal_code,
                customer_acct_no,
                achfilename,rdfi,
                seccodes,
                impdate,
                processdate,
                effectivedate,
                tracenumber,
                incoming_crfileid,
                auth_id,
                achtrantype_id,
                indidnum,
                indname,
                companyname,
                companyid,
                ach_id,
                compentrydesc,
                response_id,
                customerlastname ,
                odfi,
                currencycode,
                terminal_id,
                decode(addcharge,'Y',NULL,addcharge)
           INTO v_proxy_number,
                v_orgnl_msgtype,
                v_orgnl_rrn,
                v_orgnl_delivery_channel,
                v_orgnl_txn_code,
                v_orgnl_txn_mode,
                v_orgnl_response_code,
                v_orgnl_business_date,
                v_orgnl_business_time,
                v_orgnl_total_amount,
                v_orgnl_amount,
                v_orgnl_instcode,
                v_orgnl_cardnum,
                v_orgnl_reversal_code,
                v_orgnl_customer_acct_no,
                v_orgnl_achfilename,
                v_orgnl_rdfi,
                v_orgnl_seccodes,
                v_orgnl_impdate,
                v_orgnl_processdate,
                v_orgnl_effectivedate,
                v_orgnl_tracenumber,
                v_orgnl_incoming_crfileid,
                v_orgnl_auth_id,
                v_orgnl_achtrantype_id,
                v_orgnl_indidnum,
                v_orgnl_indname,
                v_orgnl_companyname,
                v_orgnl_companyid,
                v_orgnl_ach_id,
                v_orgnl_compentrydesc,
                v_orgnl_response_id,
                v_orgnl_customerlastname ,
                v_orgnl_odfi,
                v_orgnl_currencycode,
                v_orgnl_terminal_id,
                v_addcharge
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode         = prm_inst_code
            AND rrn              = prm_orgnl_rrn
            AND business_date    = prm_orgnl_tran_date             --changed here
            AND business_time    = prm_orgnl_tran_time             --changed here
            AND customer_card_no = v_hash_pan
            --AND auth_id          = prm_orgnl_auth_id          commented as per requirement 14032012
            and (  auth_id     is null or auth_id=  prm_orgnl_auth_id )
            AND txn_code         = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl 
              AND  response_code <> '00' ;
        --    AND csr_achactiontaken <> 'R' ;
END IF;
		

      EXCEPTION   WHEN NO_DATA_FOUND
      THEN
            v_resp_cde := '16';
            v_err_msg := 'Orginal Transaction Record Not Found Or Record Already Processed.';
            RAISE exp_reject_record;
      WHEN OTHERS
      THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'while selecting orginal txn detail'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;

      END;

      if prm_approve_rej = 'A'
      THEN

              BEGIN

                SP_ACH_CREDITTRANSACTION_CSR(
                                            prm_inst_code,
                                            v_orgnl_rrn,
                                            v_orgnl_terminal_id,
                                            v_orgnl_tracenumber,
                                            v_orgnl_business_date,
                                            v_orgnl_business_time,
                                            v_orgnl_cardnum,        --Dhiraj 12-Mar-2012
                                            v_orgnl_amount,
                                            v_orgnl_currencycode,
                                            prm_ins_user,
                                            v_orgnl_msgtype,
                                            v_orgnl_txn_code,
                                            v_orgnl_txn_mode,
                                            v_orgnl_delivery_channel,
                                            v_mbr_numb,
                                            v_orgnl_reversal_code,
                                            v_orgnl_odfi,
                                            v_orgnl_rdfi,
                                            v_orgnl_achfilename,
                                            v_orgnl_seccodes,
                                            v_orgnl_impdate,
                                            v_orgnl_processdate,
                                            v_orgnl_effectivedate,
                                            v_orgnl_incoming_crfileid,
                                            v_orgnl_achtrantype_id,
                                            v_orgnl_indidnum,
                                            v_orgnl_indname,
                                            v_orgnl_companyname,
                                            v_orgnl_companyid,
                                            v_orgnl_ach_id,
                                            v_orgnl_compentrydesc,
                                            v_orgnl_customer_acct_no,
                                            'N',
                                       --    prm_reason_code,
                                            prm_Txn_processFlag,
                                            prm_remark,
                                            --prm_reason_desc,
                                            v_reason_desc,
                                            v_auth_id,    --v_auth_id added by pankaj S. for FSS-390
                                            v_ach_resp_cde,
                                            v_ach_err_msg,
                                            v_ach_startledgerbal,
                                            v_ach_startaccountbalance,
                                            v_ach_endledgerbal,
                                            v_ach_endaccountbalance,
                                            v_ach_auth_id
                                           );


                        prm_ach_resp_cde            := v_ach_resp_cde;
                        prm_ach_err_msg             := v_ach_err_msg;
                        prm_ach_startledgerbal      := v_ach_startledgerbal;
                        prm_ach_startaccountbalance := v_ach_startaccountbalance;
                        prm_ach_endledgerbal        :=  v_ach_endledgerbal;
                        prm_ach_endaccountbalance   :=  v_ach_endaccountbalance;
                        prm_ach_auth_id             :=  v_ach_auth_id;

              Exception when others
              then

                    v_resp_cde := '21';
                    v_err_msg :=
                          'while calling ACH PROCESS '||substr(sqlerrm,1,100);
                    RAISE exp_reject_record;
              END;
             
             IF v_ach_err_msg='OK' AND v_addcharge IS NOT NULL THEN
                
               BEGIN
                    SELECT NVL (CPC_ACHBLCKEXPRY_PERIOD, 0)
                      INTO v_achblckexpry_period
                       FROM cms_prod_cattype
					   WHERE  cpc_inst_code = prm_inst_code
					   AND cpc_prod_code = v_prod_code
					   AND cpc_card_type = v_card_type;
            
                  INSERT INTO vms_achexc_appd_acc (vaa_acct_no, vaa_company_name,
                                                     vaa_resp_code, vaa_expiry_date, vaa_ins_user, vaa_ins_date)
                     VALUES (v_orgnl_customer_acct_no, UPPER (TRIM (v_orgnl_companyname)),
                             v_addcharge, trunc(SYSDATE) + v_achblckexpry_period, prm_ins_user, SYSDATE);
                 EXCEPTION
                 WHEN dup_val_on_index THEN
                 UPDATE vms_achexc_appd_acc
                   SET vaa_expiry_date = trunc(SYSDATE) + v_achblckexpry_period, vaa_enable_flag = 'Y',
                   vaa_ins_user=prm_ins_user, vaa_ins_date=sysdate
                 WHERE     vaa_acct_no = v_orgnl_customer_acct_no
                       AND vaa_company_name = UPPER (TRIM (v_orgnl_companyname))
                       AND vaa_resp_code = v_addcharge;
                 WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg :='while calling inserting into vms_achexc_appd_acc- '||substr(sqlerrm,1,100);
                    RAISE exp_reject_record;
                 END;           
             END IF;

      Elsif prm_approve_rej = 'R'
      then

         Begin					--- Added for VMS-3412
         IF prm_r17_response_in = 'Y' 
         THEN
	 	       
             SELECT cms_resp_desc
                   INTO v_resp_desc
                   FROM cms_response_mast
                  WHERE cms_inst_code = prm_inst_code
                    AND cms_delivery_channel = '11'
                    AND cms_response_id = 266;	      	       
	    
          END IF;
		  --Added for VMS-5739/FSP-991
  select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          update transactionlog
          set    CSR_ACHACTIONTAKEN ='R',
                 PROCESSTYPE ='N',
                 REMARK = prm_remark ,
                 gl_eod_flag=prm_Txn_processFlag,
                 response_code=decode(prm_r17_response_in,'Y','R17',response_code),
                 response_id=decode(prm_r17_response_in,'Y','266',response_id),
                 error_msg = decode(prm_r17_response_in,'Y',v_resp_desc,error_msg)
          WHERE instcode         = prm_inst_code
            AND rrn              = prm_orgnl_rrn
            AND business_date    = prm_orgnl_tran_date
            AND business_time    = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            --AND auth_id          = prm_orgnl_auth_id    commented as per requirement 14032012
            and (  auth_id     is null or auth_id=  prm_orgnl_auth_id )
            AND txn_code         = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl;
ELSE
			update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          set    CSR_ACHACTIONTAKEN ='R',
                 PROCESSTYPE ='N',
                 REMARK = prm_remark ,
                 gl_eod_flag=prm_Txn_processFlag,
                 response_code=decode(prm_r17_response_in,'Y','R17',response_code),
                 response_id=decode(prm_r17_response_in,'Y','266',response_id),
                 error_msg = decode(prm_r17_response_in,'Y',v_resp_desc,error_msg)
          WHERE instcode         = prm_inst_code
            AND rrn              = prm_orgnl_rrn
            AND business_date    = prm_orgnl_tran_date
            AND business_time    = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            --AND auth_id          = prm_orgnl_auth_id    commented as per requirement 14032012
            and (  auth_id     is null or auth_id=  prm_orgnl_auth_id )
            AND txn_code         = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl;
END IF;			

             if sql%rowcount = 0
             then

             v_resp_cde := '16';
             v_err_msg   := 'Orignal txn not updated';
             RAISE exp_reject_record;
             end if;
             
          IF prm_r17_response_in = 'Y' --- Added for VMS-3412
          THEN
		  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
             UPDATE CMS_TRANSACTION_LOG_DTL 
                SET ctd_process_msg = v_resp_desc
              WHERE ctd_inst_code = prm_inst_code
                AND ctd_rrn = prm_orgnl_rrn 
                AND ctd_business_date = prm_orgnl_tran_date
                AND ctd_business_time = prm_orgnl_tran_time
                AND ctd_customer_card_no = v_hash_pan
                AND ctd_txn_code = prm_orgnl_txn_code
                AND ctd_delivery_channel = prm_orgnl_delivery_chnl;
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST 	--Added for VMS-5733/FSP-991
                SET ctd_process_msg = v_resp_desc
              WHERE ctd_inst_code = prm_inst_code
                AND ctd_rrn = prm_orgnl_rrn 
                AND ctd_business_date = prm_orgnl_tran_date
                AND ctd_business_time = prm_orgnl_tran_time
                AND ctd_customer_card_no = v_hash_pan
                AND ctd_txn_code = prm_orgnl_txn_code
                AND ctd_delivery_channel = prm_orgnl_delivery_chnl;
END IF;				
           END IF;

         exception when exp_reject_record
         then
             raise;
         when others
         then
             v_resp_cde := '21';
             v_err_msg   := 'problem occured while updating orignal txn '||substr(sqlerrm,1,100);
             RAISE exp_reject_record;

         End;

      End if;


      v_resp_cde := '1';

      --Sn get record for successful transaction
      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_inst_code
            AND cms_delivery_channel = prm_delivery_chnl
            AND cms_response_id = v_resp_cde;

         prm_errmsg := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while selecting data from response master1 '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      --En get record for successful transaction
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel,
                      ctd_txn_code,
                      ctd_txn_type,
                      ctd_msg_type,
                      ctd_txn_mode,
                      ctd_business_date,
                      ctd_business_time,
                      ctd_customer_card_no,
                      ctd_txn_amount,
                      ctd_actual_amount,
                      ctd_bill_amount,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn,
                      ctd_system_trace_audit_no,
                      ctd_inst_code,
                      ctd_customer_card_no_encr,
                      ctd_cust_acct_number,
                      ctd_ins_date,
                      ctd_ins_user
                     )
              VALUES (prm_delivery_chnl,
                      prm_txn_code,
                      1,
                      prm_msg_type,
                      prm_txn_mode,
                      prm_tran_date,
                      prm_tran_time,
                      v_hash_pan,
                      prm_txn_amt,
                      prm_txn_amt,
                      prm_txn_amt,
                      'Y',
                      v_err_msg,
                      prm_rrn,
                      prm_stan,
                      prm_inst_code,
                      fn_emaps_main (prm_orgnl_card_no),
                      v_card_acct_no,
                      SYSDATE,
                      prm_ins_user
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '89';
            prm_errmsg :=
                  'Error while inserting in log detail '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      -- Sn create a entry in GL
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn,
                      delivery_channel,
                      terminal_id,
                      date_time,
                      txn_code,
                      txn_type,
                      txn_mode,
                      txn_status,
                      response_code,
                      business_date,
                      business_time,
                      customer_card_no,
                      topup_card_no,
                      topup_acct_no,
                      topup_acct_type,
                      bank_code,
                      total_amount,
                      rule_indicator,
                      rulegroupid,
                      mccode,
                      productid,
                      categoryid,
                      tranfee_amt,
                      tips,
                      decline_ruleid,
                      atm_name_location,
                      auth_id,
                      trans_desc,
                      amount,
                      preauthamount,
                      partialamount,
                      mccodegroupid,
                      currencycodegroupid,
                      transcodegroupid,
                      rules,
                      preauth_date,
                      gl_upd_flag,
                      system_trace_audit_no,
                      instcode,
                      feecode,
                      feeattachtype,
                      tran_reverse_flag,
                      customer_card_no_encr,
                      topup_card_no_encr,
                      proxy_number,
                      reversal_code,
                      customer_acct_no,
                      acct_balance,
                      ledger_balance,
                      error_msg,
                      orgnl_card_no,
                      orgnl_rrn,
                      orgnl_business_date,
                      orgnl_business_time,
                      orgnl_terminal_id,
                      add_ins_date,
                      add_ins_user,
                      remark,
                      reason,
                      csr_achactiontaken,
                      response_id,
                      cr_dr_flag,
                      ipaddress,   --added by amit on 07-Oct-2012
                      add_lupd_user, --added by amit on 07-Oct-2012
                      REASON_CODE
                     )
              VALUES (prm_msg_type,
                      prm_rrn,
                      prm_delivery_chnl,
                      NULL,
                      TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'),
                      prm_txn_code,
                      1,
                      prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'),
                      prm_resp_code,
                      prm_tran_date,
                      prm_tran_time,
                      v_hash_pan,
                      NULL,
                      NULL,
                      NULL,
                      prm_inst_code,
                      prm_txn_amt,
                      NULL,
                      NULL,
                      NULL,
                      v_prod_code,
                      v_card_type,
                      0,
                      0,
                      NULL,
                      NULL,
                      v_auth_id,
                      v_tran_desc|| 'for rrn '|| prm_orgnl_rrn,
                      prm_txn_amt,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      'Y',
                      prm_stan,
                      prm_inst_code,
                      NULL,
                      NULL,
                      'N',
                      fn_emaps_main (prm_orgnl_card_no),
                      NULL,
                      v_proxy_number,
                      prm_revrsl_code,
                      v_orgnl_customer_acct_no, --Changed by sagar on 14Jun2012 for bug id 0007937
                      v_acct_balance,
                      v_ledger_bal,
                      v_err_msg,
                      fn_emaps_main (prm_orgnl_card_no), --Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                      prm_orgnl_rrn,
                      prm_orgnl_tran_date,
                      prm_orgnl_tran_time,
                      v_orgnl_terminal_id,
                      SYSDATE,
                      prm_ins_user,
                      prm_remark,
                     --prm_reason_desc,
                     v_reason_desc,
                      prm_approve_rej,
                      v_resp_cde,
                      v_orgnl_drcr_flag, -- added on 18Sep2012 to log DRCR flag
                      prm_ipaddress,  --added by amit on 07-Oct-2012
                      prm_ins_user,     --added by amit on 07-Oct-2012
                      prm_reason_code
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '89';
            prm_errmsg :=
               'Error while inserting in txnlog ' || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;


    Exception when exp_reject_record
    then
         ROLLBACK;

       IF v_acct_balance IS NULL AND  v_ledger_bal IS NULL
       THEN

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan          --prm_card_no
                          AND cap_mbr_numb = prm_mbr_numb
                          AND cap_inst_code = prm_inst_code);

           -- prm_acct_bal := v_acct_balance;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               --prm_acct_bal := 0;
         END;

       END IF;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = v_resp_cde;

            prm_errmsg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel,
                         ctd_txn_code,
                         ctd_txn_type,
                         ctd_msg_type,
                         ctd_txn_mode,
                         ctd_business_date,
                         ctd_business_time,
                         ctd_customer_card_no,
                         ctd_txn_amount,
                         ctd_actual_amount,
                         ctd_bill_amount,
                         ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_inst_code,
                         ctd_customer_card_no_encr,
                         ctd_cust_acct_number,
                         ctd_ins_date,
                         ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl,
                         prm_txn_code,
                         1,
                         prm_msg_type,
                         prm_txn_mode,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         prm_txn_amt,
                         prm_txn_amt,
                         prm_txn_amt,
                         'E',
                         v_err_msg,
                         prm_rrn,
                         prm_stan,
                         prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no),
                         v_card_acct_no,
                         SYSDATE,
                         prm_ins_user
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype,
                         rrn,
                         delivery_channel,
                         terminal_id,
                         date_time,
                         txn_code,
                         txn_type,
                         txn_mode,
                         txn_status,
                         response_code,
                         business_date,
                         business_time,
                         customer_card_no,
                         topup_card_no,
                         topup_acct_no,
                         topup_acct_type,
                         bank_code,
                         total_amount,
                         rule_indicator,
                         rulegroupid,
                         mccode,
                         productid,
                         categoryid,
                         tranfee_amt,
                         tips,
                         decline_ruleid,
                         atm_name_location,
                         auth_id,
                         trans_desc,
                         amount,
                         preauthamount,
                         partialamount,
                         mccodegroupid,
                         currencycodegroupid,
                         transcodegroupid,
                         rules,
                         gl_upd_flag,
                         system_trace_audit_no,
                         instcode,
                         feecode,
                         feeattachtype,
                         tran_reverse_flag,
                         customer_card_no_encr,
                         topup_card_no_encr,
                         proxy_number,
                         reversal_code,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         error_msg,
                         orgnl_card_no,
                         orgnl_rrn,
                         orgnl_business_date,
                         orgnl_business_time,
                         orgnl_terminal_id,
                         add_ins_date,
                         add_ins_user,
                         remark,
                         reason,
                         csr_achactiontaken,
                         response_id,
                         cr_dr_flag,
                         ipaddress,   --added by amit on 07-Oct-2012
                         add_lupd_user, --added by amit on 07-Oct-2012
                         REASON_CODE
                        )
                 VALUES (prm_msg_type,
                         prm_rrn,
                         prm_delivery_chnl,
                         NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code,
                         1,
                         prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         NULL,
                         NULL,
                         NULL,
                         prm_inst_code,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         v_prod_code,
                         v_card_type,
                         0,
                         0,
                         NULL,
                         NULL,
                         v_auth_id,
                         v_tran_desc,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'Y',
                         prm_stan,
                         prm_inst_code,
                         NULL,
                         NULL,
                         'N',
                         fn_emaps_main (prm_orgnl_card_no),
                         NULL,
                         v_proxy_number,
                         prm_revrsl_code,
                         v_card_acct_no,
                         v_acct_balance,
                         v_ledger_bal,
                         v_err_msg,
                         fn_emaps_main (prm_orgnl_card_no), --Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         prm_rrn,
                         prm_tran_date,
                         prm_tran_time,
                         NULL,
                         SYSDATE,
                         prm_ins_user,
                         prm_remark,
                         --prm_reason_desc,
                         v_reason_desc,
                         prm_approve_rej,
                         v_resp_cde,
                         v_orgnl_drcr_flag,
                         prm_ipaddress,  --added by amit on 07-Oct-2012
                         prm_ins_user,     --added by amit on 07-Oct-2012
                         prm_reason_code
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

      WHEN OTHERS
      THEN
         ROLLBACK;

       IF v_acct_balance IS NULL AND v_ledger_bal IS NULL
       THEN

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan          --prm_card_no
                          AND cap_mbr_numb = prm_mbr_numb
                          AND cap_inst_code = prm_inst_code);

           -- prm_acct_bal := v_acct_balance;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               --prm_acct_bal := 0;
         END;

       END IF;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = '21';
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master3'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel,
                         ctd_txn_code,
                         ctd_txn_type,
                         ctd_msg_type,
                         ctd_txn_mode,
                         ctd_business_date,
                         ctd_business_time,
                         ctd_customer_card_no,
                         ctd_txn_amount,
                         ctd_actual_amount,
                         ctd_bill_amount,
                         ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_inst_code,
                         ctd_customer_card_no_encr,
                         ctd_cust_acct_number,
                         ctd_ins_date,
                         ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl,
                         prm_txn_code,
                         1,
                         prm_msg_type,
                         prm_txn_mode,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         prm_txn_amt,
                         prm_txn_amt,
                         prm_txn_amt,
                         'E',
                         v_err_msg,
                         prm_rrn,
                         prm_stan,
                         prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no),
                         v_card_acct_no,
                         SYSDATE,
                         prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype,
                         rrn,
                         delivery_channel,
                         terminal_id,
                         date_time,
                         txn_code,
                         txn_type,
                         txn_mode,
                         txn_status,
                         response_code,
                         business_date,
                         business_time,
                         customer_card_no,
                         topup_card_no,
                         topup_acct_no,
                         topup_acct_type,
                         bank_code,
                         total_amount,
                         rule_indicator,
                         rulegroupid,
                         mccode,
                         productid,
                         categoryid,
                         tranfee_amt,
                         tips,
                         decline_ruleid,
                         atm_name_location,
                         auth_id,
                         trans_desc,
                         amount,
                         preauthamount,
                         partialamount,
                         mccodegroupid,
                         currencycodegroupid,
                         transcodegroupid,
                         rules,
                         preauth_date,
                         gl_upd_flag,
                         system_trace_audit_no,
                         instcode,
                         feecode,
                         feeattachtype,
                         tran_reverse_flag,
                         customer_card_no_encr,
                         topup_card_no_encr,
                         proxy_number,
                         reversal_code,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         error_msg,
                         orgnl_card_no,
                         orgnl_rrn,
                         orgnl_business_date,
                         orgnl_business_time,
                         orgnl_terminal_id,
                         add_ins_date,
                         add_ins_user,
                         remark,
                         reason,
                         csr_achactiontaken,
                         response_id,
                         cr_dr_flag,
                         ipaddress,   --added by amit on 07-Oct-2012
                         add_lupd_user, --added by amit on 07-Oct-2012
                         REASON_CODE
                        )
                 VALUES (prm_msg_type,
                         prm_rrn,
                         prm_delivery_chnl,
                         NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'),
                         prm_txn_code,
                         1,
                         prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         NULL,
                         NULL,
                         NULL,
                         prm_inst_code,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         v_prod_code,
                         v_card_type,
                         0,
                         0,
                         NULL,
                         NULL,
                         v_auth_id,
                         v_tran_desc,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'Y',
                         prm_stan,
                         prm_inst_code,
                         NULL,
                         NULL,
                         'N',
                         fn_emaps_main (prm_orgnl_card_no),
                         NULL,
                         v_proxy_number,
                         prm_revrsl_code,
                         v_card_acct_no,
                         v_acct_balance,
                         v_ledger_bal,
                         v_err_msg,
                         fn_emaps_main (prm_orgnl_card_no), --Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         prm_rrn,
                         prm_tran_date,
                         prm_tran_time,
                         NULL,
                         SYSDATE,
                         prm_ins_user,
                         prm_remark,
                         --prm_reason_desc,
                         v_reason_desc,
                         prm_approve_rej,
                         v_resp_cde,
                         v_orgnl_drcr_flag,
                         prm_ipaddress,  --added by amit on 07-Oct-2012
                         prm_ins_user,     --added by amit on 07-Oct-2012
                         prm_reason_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;


    End;

EXCEPTION                                              -- << MAIN EXCEPTION >>
   WHEN OTHERS
   THEN
      prm_errmsg := 'ERROR FROM MAIN ' || SUBSTR (SQLERRM, 1, 100);
End;

/

show error;