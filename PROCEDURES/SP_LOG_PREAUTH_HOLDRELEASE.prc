CREATE OR REPLACE PROCEDURE VMSCMS.SP_LOG_PREAUTH_HOLDRELEASE(P_INSTCODE IN NUMBER,
                                   P_DEL_CHANNEL IN VARCHAR2,
                                   P_TRAN_CODE    IN VARCHAR2,
                                   P_HASH_PAN    IN VARCHAR2,
                                   P_PAN_CODE    IN VARCHAR2,
                                   P_HOLD_AMOUNT    IN NUMBER,
                                   P_RESP_CODE      IN VARCHAR2,
                                   P_RESP_MSG       IN VARCHAR2,
                                   P_ORGNL_RRN      IN VARCHAR2,--Added for defect 9654
                                   P_ORGNL_DATE     IN VARCHAR2,--Added for defect 9654
                                   P_ORGNL_TIME     IN VARCHAR2,--Added for defect 9654
                                   P_ORGNL_CARDNO   IN VARCHAR2,--Added for defect 9654
                                   P_ORGNL_TERMID   IN VARCHAR2,  --Added for defect 9654
                                   P_MBR_NUMB       IN VARCHAR2, --Added for defect 9654
                                   P_ACCT_NO        IN VARCHAR2, --Added for defect 9654
                                   P_MATCH_RULE     IN VARCHAR2, --Added on 04/04/2014 for Mantis ID 14092
                                   --Sn Added for Transactionlog Functional Removal Phase-II changes
                                   p_orgdelivery_channel           IN       VARCHAR2,
                                   p_orgtxn_code                   IN       VARCHAR2,
                                   p_mcc_code                   IN       VARCHAR2,
                                   p_merchant_id                IN       VARCHAR2,
                                   p_merchant_name              IN       VARCHAR2,
                                   p_merchant_city              IN       VARCHAR2,
                                   p_merchant_state             IN       VARCHAR2,
                                   p_merchant_zip               IN       VARCHAR2,
                                   p_pos_verification           IN       VARCHAR2,
                                   p_internation_ind_response   IN       VARCHAR2,
                                   p_ins_date                   IN       DATE,
                                   --En Added for Transactionlog Functional Removal Phase-II changes
                                   P_ERRMSG   OUT VARCHAR2,
                                   p_completion_fee NUMBER DEFAULT 0 --Added for FSS 837
                                   ,p_preauth_type   IN VARCHAR2, --Added for MVHOST 926
                                   p_complfree_flag IN VARCHAR2 DEFAULT 'N',
                                   p_payment_type in     varchar2 default null
                                   ) AS

 /*************************************************
     * Created By       : Deepa T
     * Created Date     : 22-OCt-2012
     * Purpose          : For logging Preauth Hold Rlease
     * Modified By      : B.Besky Anand
     * Modified Date    : 09/01/2013
     * Modified Reason  : For Performance and exception handling
     * Reviewer         : Dhiraj
     * Reviewed Date    : 09/01/2013
     * Release Number   : CMS3.5.1_RI0023_B0011

     * modified by      : Sagar
     * modified for     : Defect 0010690
     * modified Date    : 04-APR-13
     * modified reason  : To log original transaction merchant details in Transactionlog table
     * Reviewer         : Dhiraj
     * Reviewed Date    : 04-APR-13
     * Build Number     : RI0024.1_B0003

     * Modified by       :  Pankaj S.
     * Modified Reason   :  Enabling Limit configuration and validation for Preauth
     * Modified Date     :  28-Oct-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :
     * Build Number      : RI0024.5.2_B0001

       * Modified By     : Deepa T
       * Modified Date   : 09/01/2014
       * Modified For    : MVHOST-547
       * Modified Reason : Performance issue
       * Reviewer        : Dhiraj
       * Reviewed Date   : 09/01/2014
       * Release Number  : RI0027_B0003

     * Modified by       :  Dhinakaran B
     * Modified Reason   :  Implement the 1.7.6.8 changes (Mantis id-13885)
     * Modified Date     :  14-MAR-2014
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  14-MAR-2014
     * Build Number      :  RI0027.0.1_B0001

     * Modified by       :  Dhinakaran B
     * Modified Reason   :  To reset the limit count for expired preauth hold release( Mantis ID 14092 )
     * Modified Date     :  04-APR-2014
     * Reviewer          :  Pankaj S
     * Reviewed Date     :  06-Apr-2014
     * Build Number      :  RI0027.2_B0004

     * Modified by       :  Abdul Hameed M.A
     * Modified Reason   :  To hold the Preauth completion fee at the time of preauth
     * Modified for      :  FSS 837
     * Modified Date     :  27-JUNE-2014
     * Reviewer          :  Spankaj
     * Build Number      :  RI0027.3_B0001


     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.3
     * Modified Date     : 08-JUL-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0002

     * Modified By      : MageshKumar S
     * Modified Date    : 08-JUNE-2015
     * Modified for     :
     * Modified Reason  : To release hold amount for ATM auth transactions
     * Reviewer         : Pankaj
     * Reviewed Date    :
     * Build Number     : VMSGPRHOSTCSD3.0.3_B0001

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 23-June-15
    * Modified For      : FSS 1960
    * Reviewer          : Pankaj S
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal Phase-II changes
     * Modified Date    : 11-Aug-2015
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1

     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06

              * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
	
    * Modified By      : Puvanesh. N
    * Modified Date    : 04/22/2021
    * Purpose          : VMS-3944 - VMS HOST UI throws SQL Exception upon selecting HOST 
						 as delivery channel in Transaction Configuration for OTP/Event Notification screen
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST45 Build 3
	
	   * Modified By      : Karthick/Jey
       * Modified Date    : 05-17-2022
       * Purpose          : Archival changes.
       * Reviewer         : Venkat Singamaneni
       * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991


   *************************************************/
V_TRAN_DESC        CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
V_ACCT_BAL         cms_acct_mast.cam_acct_bal%TYPE;
V_LEDGER_BAL       cms_acct_mast.cam_ledger_bal%TYPE;
V_RRN              VMS_EVENT_PROCESSING.VEP_RECORD_ID%TYPE;
V_BUSINESS_DATE    TRANSACTIONLOG.BUSINESS_DATE%TYPE;
v_card_curr        TRANSACTIONLOG.CURRENCYCODE%TYPE;
v_card_stat         cms_appl_pan.cap_card_stat%TYPE;
V_BUSINESS_TIME     TRANSACTIONLOG.BUSINESS_TIME%TYPE;--Added for defect 9654
V_RESP_CODE         TRANSACTIONLOG.RESPONSE_CODE%TYPE;--Added for defect 9654
V_ACCT_NO           CMS_ACCT_MAST.cam_acct_no%TYPE;
EXP_REJECT_RECORD    EXCEPTION; --Added by Besky on 09/01/2013 for handing the exception

--SN: Added on 04-Apr-2013 for defect 0010690
v_merchant_zip  transactionlog.merchant_zip%type;
v_merchant_id   transactionlog.merchant_id%type;
v_merchant_name transactionlog.merchant_name%type;
v_merchant_state transactionlog.merchant_state%type;
v_merchant_city  transactionlog.merchant_city%type;
--EN: Added on 04-Apr-2013 for defect 0010690
v_oldest_preauth transactionlog.add_ins_Date%type;

  --Sn Added by Pankaj S. for enabling limit validation
  v_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
  v_orgnl_mcccode            transactionlog.mccode%type;
  v_pos_verification         transactionlog.pos_verification%type;
  v_internation_ind_response transactionlog.internation_ind_response %type;
  v_add_ins_date             transactionlog.add_ins_date %type;
  --En Added by Pankaj S. for enabling limit validation
  --Added for Mantis ID- 13885
 v_txnlog_txncode            transactionlog.txn_code%TYPE;
 v_comp_amount               cms_preauth_transaction.cpt_txn_amnt%type;--Added on 04/04/2014 for Mantis ID 14092
  v_card_no varchar2(19);--Added for MVHOST 926
  V_DELIVERY_CHANNEL           TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;  --Variable added FOR 3.0.3 RELEASE
  v_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
  v_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
  v_prod_code cms_prod_mast.cpm_prod_code%type;
  v_card_type cms_prod_cattype.cpc_card_type%type;
  v_event_status		VMS_EVENT_PROCESSING.VEP_STATUS%TYPE;
  v_nano_time	                NUMBER;
  
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN

        V_BUSINESS_DATE:=to_char(sysdate,'YYYYMMDD');
        V_BUSINESS_TIME:=TO_CHAR (SYSDATE, 'hh24miss');--Added for defect 9654
        V_RRN:='PHR'||V_BUSINESS_DATE||SEQ_HOLDRELEASE_RRN.NEXTVAL;
        V_RESP_CODE:=P_RESP_CODE;--Added for defect 9654
        P_ERRMSG:=P_RESP_MSG;--Added for defect 9654
        --Sn Added for Transactionlog Functional Removal Phase-II changes
        v_delivery_channel:=p_orgdelivery_channel;
        v_txnlog_txncode:=p_orgtxn_code;
        v_orgnl_mcccode:=p_mcc_code;
        v_merchant_id:=p_merchant_id;
        v_merchant_name:=p_merchant_name;
        v_merchant_city:=p_merchant_city;
        v_merchant_state:=p_merchant_state;
        v_merchant_zip:=p_merchant_zip;
        v_pos_verification:=p_pos_verification;
        v_internation_ind_response:=p_internation_ind_response;
        v_add_ins_date:=p_ins_date;
        --En Added for Transactionlog Functional Removal Phase-II changes

        BEGIN


        SELECT ctm_tran_desc
          INTO v_tran_desc
          FROM cms_transaction_mast
         WHERE ctm_delivery_channel = P_DEL_CHANNEL
           AND ctm_tran_code = p_tran_code
           AND ctm_inst_code = p_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        P_ERRMSG:='Transaction Details Not Found';
        V_RESP_CODE:='21';--Added for defect 9654
        RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        WHEN OTHERS THEN
        P_ERRMSG:='While getting Transaction Description'|| SUBSTR(SQLERRM, 1, 200);
        V_RESP_CODE:='21';--Added for defect 9654
        RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        END;

        /*BEGIN               Commented by Besky on 09/01/2013 because we can fetch the card status from the query on line no 100

        SELECT cap_card_stat
          INTO v_card_stat
          FROM cms_appl_pan
         WHERE cap_pan_code = p_hash_pan AND cap_inst_code = p_instcode;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        P_ERRMSG:='Card Details Not Found in Expiry Hold Release';
        V_RESP_CODE:='21';--Added for defect 9654
        WHEN OTHERS THEN
        P_ERRMSG:='While getting card details'|| SUBSTR(SQLERRM, 1, 200);
        V_RESP_CODE:='21';--Added for defect 9654
        END;
        */

        BEGIN


        SELECT cam_acct_bal, cam_ledger_bal
          INTO v_acct_bal, v_ledger_bal
          FROM cms_acct_mast
         WHERE cam_acct_no = P_ACCT_NO
          AND cam_inst_code = p_instcode;
         EXCEPTION
        WHEN NO_DATA_FOUND THEN
        P_ERRMSG:='Account Details Not Found';
        V_RESP_CODE:='21';--Added for defect 9654
        RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        WHEN OTHERS THEN
        P_ERRMSG:='While getting account details'|| SUBSTR(SQLERRM, 1, 200);
        V_RESP_CODE:='21';--Added for defect 9654
        RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        END;
      begin
          select cap_prod_code,cap_card_type,cap_card_stat,
          cap_prfl_code,fn_dmaps_main(CAP_PAN_CODE_ENCR)
          into v_prod_code,v_card_type,V_CARD_STAT,V_PRFL_CODE,V_CARD_NO
          from cms_appl_pan
          where cap_pan_code=P_HASH_PAN and cap_inst_code=p_instcode;
      exception
          when others then
              P_ERRMSG :='Error in selecting card Currency' || SUBSTR (SQLERRM, 1, 200);
              V_RESP_CODE:='21';
              RAISE EXP_REJECT_RECORD;
      end;

        BEGIN



--             SELECT TRIM (cbp_param_value) ,cap_card_stat, cap_prfl_code,fn_dmaps_main(CAP_PAN_CODE_ENCR)
--             INTO V_CARD_CURR ,V_CARD_STAT,V_PRFL_CODE,V_CARD_NO
--                FROM cms_appl_pan, cms_bin_param, cms_prod_cattype
--                WHERE cap_inst_code = cpc_inst_code
--                AND CPC_INST_CODE = CBP_INST_CODE
--                AND cap_prod_code = cpc_prod_code and cpc_card_type=cap_card_type
--                AND cpc_profile_code = cbp_profile_code
--                AND cbp_param_name = 'Currency'
--                AND cap_pan_code = P_HASH_PAN;
vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_instcode,v_card_curr,P_ERRMSG);
      if P_ERRMSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;
        EXCEPTION
        WHEN OTHERS  THEN
           P_ERRMSG :='Error in selecting card Currency' || SUBSTR (SQLERRM, 1, 200);
           V_RESP_CODE:='21';
           RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        END;
        --Sn Added for defect 9654
        IF P_RESP_CODE='1' THEN

        BEGIN

          INSERT INTO cms_preauth_trans_hist
                (cph_card_no, cph_mbr_no, cph_inst_code,
                 cph_card_no_encr, cph_preauth_validflag,
                 cph_completion_flag, cph_txn_amnt, cph_approve_amt,
                 cph_rrn, cph_txn_date, cph_txn_time, cph_orgnl_rrn,
                 cph_orgnl_txn_date, cph_orgnl_txn_time,
                 cph_orgnl_card_no, cph_orgnl_terminalid,cph_transaction_flag, cph_totalhold_amt,
                 cph_delivery_channel,cph_tran_code,cph_panno_last4digit,CPH_ACCT_NO,cph_completion_fee --Added for FSS 837
                 ,CPH_PREAUTH_TYPE
                )
         VALUES (P_HASH_PAN, P_MBR_NUMB, p_instcode,
                  fn_emaps_main(P_PAN_CODE), 'N',
                 'N', P_HOLD_AMOUNT, P_HOLD_AMOUNT,
                 V_RRN, V_BUSINESS_DATE, V_BUSINESS_TIME, P_ORGNL_RRN,
                 P_ORGNL_DATE, P_ORGNL_TIME,
                 P_ORGNL_CARDNO,
                 P_ORGNL_TERMID, 'E',   0 ,
                 P_DEL_CHANNEL,
                 P_TRAN_CODE,
                 (SUBSTR (P_PAN_CODE,
                          LENGTH (P_PAN_CODE) - 3,
                          LENGTH (P_PAN_CODE)
                         )
                 ),P_ACCT_NO,0,p_preauth_type);
        EXCEPTION

        WHEN OTHERS THEN
        V_RESP_CODE:='21';  --Added by Besky on 09/01/2013 for handing the exception
        P_ERRMSG :='Error while inserting in cms_preauth_trans_hist' ||SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
        END;
        END IF;
        --En Added for defect 9654


    ----------------------------------------------
    --SN:Addde on 04-Apr-2013 for defect 0010690
    ----------------------------------------------
    IF p_orgtxn_code IS NULL THEN  --Condition added for Transactionlog Functional Removal Phase-II changes
        Begin
		
		
		       --Added for VMS-5739/FSP-991
             select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
             INTO   v_Retperiod 
             FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
             WHERE  OPERATION_TYPE='ARCHIVE' 
             AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
             v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_date), 1, 8), 'yyyymmdd');

        IF (v_Retdate>v_Retperiod) THEN                                                          --Added for VMS-5739/FSP-991
		
               select  merchant_zip,
                       merchant_id,
                       merchant_name,
                       merchant_state,
                       merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       mccode,
                       pos_verification,
                       internation_ind_response,
                       add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                        ,txn_code,DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                        feecode,tranfee_amt
               into    v_merchant_zip,
                       v_merchant_id,
                       v_merchant_name,
                       v_merchant_state,
                       v_merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       v_orgnl_mcccode,
                       v_pos_verification,
                       v_internation_ind_response,
                       v_add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                        ,v_txnlog_txncode,V_DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                        v_orgnl_txn_feecode,v_orgnl_txn_totalfee_amt
               from    transactionlog
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     delivery_channel in ('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101') --Added for Mantis ID- 13885
               and     response_code='00';
             --  and     txn_code         = '11';
			 
		ELSE
		
		               select  merchant_zip,
                       merchant_id,
                       merchant_name,
                       merchant_state,
                       merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       mccode,
                       pos_verification,
                       internation_ind_response,
                       add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                        ,txn_code,DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                        feecode,tranfee_amt
               into    v_merchant_zip,
                       v_merchant_id,
                       v_merchant_name,
                       v_merchant_state,
                       v_merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       v_orgnl_mcccode,
                       v_pos_verification,
                       v_internation_ind_response,
                       v_add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                        ,v_txnlog_txncode,V_DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                        v_orgnl_txn_feecode,v_orgnl_txn_totalfee_amt
               from    VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                   --Added for VMS-5739/FSP-991
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     delivery_channel in ('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101') --Added for Mantis ID- 13885
               and     response_code='00';
             --  and     txn_code         = '11';
		
		
		END IF;

        EXCEPTION WHEN no_data_found
        then

           P_ERRMSG :='Merchant details not found for original transaction';
           V_RESP_CODE:='53';
           RAISE EXP_REJECT_RECORD;

        WHEN TOO_MANY_ROWS
        THEN
            
			IF (v_Retdate>v_Retperiod) THEN                                                            --Added for VMS-5739/FSP-991
			
               select  min(add_ins_date)
               into    v_oldest_preauth
               from    transactionlog
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     delivery_channel IN ('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101') --Added for Mantis ID- 13885
               and     response_code='00';
              -- and     txn_code         = '11';
			  
			ELSE
			
			   select  min(add_ins_date)
               into    v_oldest_preauth
               from    VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                        --Added for VMS-5739/FSP-991
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     delivery_channel IN ('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101') --Added for Mantis ID- 13885
               and     response_code='00';
              -- and     txn_code         = '11';
			
			END IF;

            BEGIN
			
			
			IF (v_Retdate>v_Retperiod) THEN                                                            --Added for VMS-5739/FSP-991

               select  merchant_zip,
                       merchant_id,
                       merchant_name,
                       merchant_state,
                       merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       mccode,
                       pos_verification,
                       internation_ind_response,
                       add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                       ,txn_code,DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                       feecode,tranfee_amt
               into    v_merchant_zip,
                       v_merchant_id,
                       v_merchant_name,
                       v_merchant_state,
                       v_merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       v_orgnl_mcccode,
                       v_pos_verification,
                       v_internation_ind_response,
                       v_add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                       ,v_txnlog_txncode,V_DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                       v_orgnl_txn_feecode,v_orgnl_txn_totalfee_amt
               from    transactionlog
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     add_ins_date     = v_oldest_preauth
               and     delivery_channel IN('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101')  --Added for Mantis ID- 13885
               and     response_code='00'
             --  and     txn_code         = '11'
               and     rownum < 2;
			   
			ELSE
			
			           select  merchant_zip,
                       merchant_id,
                       merchant_name,
                       merchant_state,
                       merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       mccode,
                       pos_verification,
                       internation_ind_response,
                       add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                       ,txn_code,DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                       feecode,tranfee_amt
               into    v_merchant_zip,
                       v_merchant_id,
                       v_merchant_name,
                       v_merchant_state,
                       v_merchant_city,
                       --Sn Added by Pankaj S. for enabling limit validation
                       v_orgnl_mcccode,
                       v_pos_verification,
                       v_internation_ind_response,
                       v_add_ins_date
                       --En Added by Pankaj S. for enabling limit validation
                       ,v_txnlog_txncode,V_DELIVERY_CHANNEL, -- COLUMN ADDED FOR 3.0.3 RELEASE
                       v_orgnl_txn_feecode,v_orgnl_txn_totalfee_amt
               from    VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                --Added for VMS-5739/FSP-991
               where   customer_card_no = p_orgnl_cardno
               and     rrn              = p_orgnl_rrn
               and     business_date    = p_orgnl_date
               and     business_time    = p_orgnl_time
               and     add_ins_date     = v_oldest_preauth
               and     delivery_channel IN('02','01','13') -- CONDITION MODIFIED FOR 3.0.3 RELEASE
               and     msgtype in ('0100','1100','1101')  --Added for Mantis ID- 13885
               and     response_code='00'
             --  and     txn_code         = '11'
               and     rownum < 2;
			
			END IF;

            Exception when others
            then
                 P_ERRMSG :='Error while fetching oldest preauth ' ||SUBSTR (SQLERRM, 1, 100);
                 V_RESP_CODE:='21';
                 RAISE EXP_REJECT_RECORD;

            END;



        WHEN OTHERS  THEN
           P_ERRMSG :='Error while fetching merchant details for original transaction ' || SUBSTR (SQLERRM, 1, 200);
           V_RESP_CODE:='21';
           RAISE EXP_REJECT_RECORD;

        End;
    ELSE
     IF p_complfree_flag='Y' THEN
        BEGIN
		
		IF (v_Retdate>v_Retperiod) THEN                                                       --Added for VMS-5739/FSP-991
		
           SELECT feecode, tranfee_amt
             INTO v_orgnl_txn_feecode, v_orgnl_txn_totalfee_amt
             FROM transactionlog
            WHERE     customer_card_no = p_orgnl_cardno
                  AND rrn = p_orgnl_rrn
                  AND business_date = p_orgnl_date
                  AND business_time = p_orgnl_time
                  AND txn_code = p_orgtxn_code
                  AND delivery_channel = p_orgdelivery_channel
                  AND response_code = '00'
                  AND msgtype IN ('0100', '1100', '1101')
                  AND reversal_code=0
                  AND ROWNUM < 2;
				  
		ELSE
		
		     SELECT feecode, tranfee_amt
             INTO v_orgnl_txn_feecode, v_orgnl_txn_totalfee_amt
             FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                    --Added for VMS-5739/FSP-991
            WHERE     customer_card_no = p_orgnl_cardno
                  AND rrn = p_orgnl_rrn
                  AND business_date = p_orgnl_date
                  AND business_time = p_orgnl_time
                  AND txn_code = p_orgtxn_code
                  AND delivery_channel = p_orgdelivery_channel
                  AND response_code = '00'
                  AND msgtype IN ('0100', '1100', '1101')
                  AND reversal_code=0
                  AND ROWNUM < 2;
		
		END IF;
		
        EXCEPTION
           WHEN OTHERS
           THEN
              p_errmsg :=
                 'Error while fetching Original txn dtls: ' || SUBSTR (SQLERRM, 1, 100);
              v_resp_code := '21';
              RAISE exp_reject_record;
        END;
     END IF;
    END IF;

    ----------------------------------------------
    --EN:Addde on 04-Apr-2013 for defect 0010690
    ----------------------------------------------
    --SN:Added on 04/04/2014 for Mantis ID 14092
    BEGIN
       IF p_match_rule IS NULL
       THEN
          v_comp_amount := p_hold_amount;
       ELSE
          v_comp_amount := p_hold_amount + 1;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          v_comp_amount := p_hold_amount;
    END;
    --EN Added on 04/04/2014 for Mantis ID 14092

    BEGIN

          INSERT INTO TRANSACTIONLOG
         (MSGTYPE,
          RRN,
          DELIVERY_CHANNEL,
          DATE_TIME,
          TXN_CODE,
          TXN_TYPE,
          TXN_STATUS,
          RESPONSE_CODE,
          BUSINESS_DATE,
          BUSINESS_TIME,
          CUSTOMER_CARD_NO,
          BANK_CODE,
          TOTAL_AMOUNT,
          AUTH_ID,
          TRANS_DESC,
          AMOUNT,
          INSTCODE,
          CUSTOMER_CARD_NO_ENCR,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          TXN_MODE,
          CURRENCYCODE,
          CARDSTATUS,
          ORGNL_CARD_NO,--Added for defect 9654
          ORGNL_RRN,--Added for defect 9654
          ORGNL_BUSINESS_DATE,--Added for defect 9654
          ORGNL_BUSINESS_TIME,--Added for defect 9654
          ORGNL_TERMINAL_ID,--Added for defect 9654
         --SN: Added on 04-Apr-2013 for defect 0010690
           merchant_zip,
           merchant_id,
           merchant_name,
           merchant_state,
           merchant_city   ,internation_ind_response,pos_verification,mccode
          --EN: Added on 04-Apr-2013 for defect 0010690
          ,time_stamp
          )
        VALUES
         ('0200',
          V_RRN,
          P_DEL_CHANNEL,
          sysdate,
          P_TRAN_CODE,
          '0',
          DECODE(V_RESP_CODE,'1','C','F'),--Modified for defect 9654
          DECODE(V_RESP_CODE,'1','00','89'), --Modified for defect 9654
          V_BUSINESS_DATE, --Modified for defect 9654
          V_BUSINESS_TIME,  --Modified for defect 9654
          P_HASH_PAN,
          P_INSTCODE,
          TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
          LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0'),
          v_tran_desc,
         TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
          P_INSTCODE,
          fn_emaps_main(P_PAN_CODE),
          P_ACCT_NO,--Modified for defect 9654
          v_acct_bal,
          v_ledger_bal,
          V_RESP_CODE,--Modified for defect 9654
          0,
          v_card_curr ,
          v_card_stat,
          P_ORGNL_CARDNO,--Added for defect 9654
          P_ORGNL_RRN ,--Added for defect 9654
          P_ORGNL_DATE,--Added for defect 9654
          P_ORGNL_TIME,    --Added for defect 9654
          P_ORGNL_TERMID,   --Added for defect 9654
          --SN: Added on 04-Apr-2013 for defect 0010690
           v_merchant_zip,
           v_merchant_id,
           v_merchant_name,
           v_merchant_state,
           v_merchant_city    ,  v_internation_ind_response,  v_pos_verification,v_orgnl_mcccode
          --EN: Added on 04-Apr-2013 for defect 0010690
          ,systimestamp
          );


         IF SQL%ROWCOUNT <> 1
         THEN
               P_ERRMSG :='Error while inserting details in transactionlog' || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
         END IF;

    EXCEPTION
    WHEN OTHERS  THEN
       P_ERRMSG :='Error in inserting transactionlog' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
    END;

    BEGIN

    INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        ctd_completion_fee,ctd_complfee_increment_type  --Added for FSS 837
       )
     VALUES
       (P_DEL_CHANNEL,
        P_TRAN_CODE,
        '0',
        '0200',
        0,
        V_BUSINESS_DATE,
        V_BUSINESS_TIME,   --Modified for defect 9654
         P_HASH_PAN,
        DECODE (V_RESP_CODE, '1', 'Y', 'F'),--Modified for defect 9654
        DECODE (V_RESP_CODE, '1', 'Successful', P_RESP_MSG),--Modified for defect 9654
        V_RRN,
        P_INSTCODE,
        fn_emaps_main(P_PAN_CODE),
        V_ACCT_NO,
        TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
        v_card_curr
        ,p_completion_fee,'C' --Added for FSS 837
        );

     IF SQL%ROWCOUNT <> 1  THEN
           P_ERRMSG :='Error while inserting details in cms_transaction_log_dtl' || SUBSTR (SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception
     END IF;

    EXCEPTION
    WHEN OTHERS  THEN
       V_RESP_CODE:='21'; --Added by Besky on 09/01/2013 for handing the exception
       P_ERRMSG :='Error in inserting cms_transaction_log_dtl' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD; --Added by Besky on 09/01/2013 for handing the exception

    END;

     --Sn Added by Pankaj S. for enabling limit validation
      IF v_add_ins_date IS NOT NULL AND v_prfl_code IS NOT NULL THEN
        BEGIN
           pkg_limits_check.sp_limitcnt_rever_reset (p_instcode,
                                                     NULL,
                                                     NULL,
                                                     v_orgnl_mcccode,
                                                     v_txnlog_txncode,
                                                     'N',
                                                     v_internation_ind_response,
                                                     v_pos_verification,
                                                     v_prfl_code,
                                                     p_hold_amount,
                                                     v_comp_amount,----Modified  on 04/04/2014 for Mantis ID 14092
                                                     --'02',
                                                     V_DELIVERY_CHANNEL,  --CONDITION MODIFIED FOR 3.0.3 RELEASE
                                                     p_orgnl_cardno,
                                                     v_add_ins_date,
                                                     v_resp_code,
                                                     p_errmsg,
                                                     p_payment_type
                                                    );

           IF p_errmsg <> 'OK' THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_code := '21';
              p_errmsg :='Error from Limit count rever Process ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
      END IF;
     --En Added by Pankaj S. for enabling limit validation

       IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (v_acct_no, v_orgnl_txn_feecode, p_errmsg);

           IF p_errmsg <> 'OK' THEN
              v_resp_code := '21';
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_code := '21';
              p_errmsg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
      END IF;
      
BEGIN

	v_event_status:= 'COMPLETED';
	
	BEGIN
        SELECT
            EXTRACT(DAY FROM TIME) * 24 * 60 * 60 * 1E9 + EXTRACT(HOUR FROM TIME) * 60 * 60 * 1E9 + EXTRACT(MINUTE FROM TIME)
            * 60 * 1E9 + EXTRACT(SECOND FROM TIME) * 1E9 AS NANOTIME
        INTO v_nano_time
        FROM
            (
                SELECT
                    SYSTIMESTAMP(9) - TIMESTAMP '1970-01-01 00:00:00 UTC' AS TIME
                FROM
                    DUAL
            );

    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg := '  ERROR WHILE SELECTING NANO TIME '
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;
	
	IF V_RRN IS NOT NULL THEN
        BEGIN
            SELECT
                V_RRN
                || '_'
                || SUBSTR(v_nano_time, 1, 16)
            INTO V_RRN
            FROM
                DUAL;

        EXCEPTION
            WHEN OTHERS THEN
                P_ERRMSG := 'RRN - ERROR WHILE SELECTING RECORDID '
                            || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        IF LENGTH(V_RRN) > 50 THEN
            V_RRN := 'EV_'
                     || SUBSTR(v_nano_time, 1, 16);
        END IF;

    ELSE
        V_RRN := 'EV_'
                 || SUBSTR(v_nano_time, 1, 16);
    END IF;
      
    /*Queue Insert*/
    sp_enqueue_msg(p_instcode,p_hash_pan,p_hold_amount,v_rrn,p_del_channel,p_tran_code,v_acct_bal,v_ledger_bal,v_add_ins_date,p_mbr_numb,p_merchant_name,p_errmsg);
    
		IF p_errmsg <> 'OK' 
		THEN 
				v_event_status:= 'PENDING';
		END IF;
	
	  /*Event Processing Insert*/
    	  vms_ins_push_notification(p_instcode,p_hash_pan,p_hold_amount,v_rrn,p_del_channel,p_tran_code,v_acct_bal,v_ledger_bal,v_add_ins_date,p_mbr_numb,p_merchant_name,v_event_status,p_errmsg);
		  
		  
            IF p_errmsg <> 'OK' 
	    THEN
	            v_resp_code := '21';
		    RAISE exp_reject_record;
	    END IF;
    
    
EXCEPTION
    WHEN exp_reject_record THEN
        RAISE;
    WHEN OTHERS THEN
        v_resp_code := '21';
        p_errmsg := 'Error while reversing freefee count-'
                    || substr(sqlerrm,1,200);
        RAISE exp_reject_record;
END; 
      
EXCEPTION --Main exception

WHEN  EXP_REJECT_RECORD THEN  --Added by Besky on 09/01/2013 for handing the exception

  INSERT INTO TRANSACTIONLOG
                 (MSGTYPE,
                  RRN,
                  DELIVERY_CHANNEL,
                  DATE_TIME,
                  TXN_CODE,
                  TXN_TYPE,
                  TXN_STATUS,
                  RESPONSE_CODE,
                  BUSINESS_DATE,
                  BUSINESS_TIME,
                  CUSTOMER_CARD_NO,
                  BANK_CODE,
                  TOTAL_AMOUNT,
                  AUTH_ID,
                  TRANS_DESC,
                  AMOUNT,
                  INSTCODE,
                  CUSTOMER_CARD_NO_ENCR,
                  CUSTOMER_ACCT_NO,
                  ACCT_BALANCE,
                  LEDGER_BALANCE,
                  RESPONSE_ID,
                  TXN_MODE,
                  CURRENCYCODE,
                  CARDSTATUS,
                  ORGNL_CARD_NO,
                  ORGNL_RRN,
                  ORGNL_BUSINESS_DATE,
                  ORGNL_BUSINESS_TIME,
                  ORGNL_TERMINAL_ID,
                  ERROR_MSG,
                 --SN: Added on 04-Apr-2013 for defect 0010690
                  merchant_zip,
                  merchant_id,
                  merchant_name,
                  merchant_state,
                  merchant_city  ,internation_ind_response,pos_verification,mccode
                  --EN: Added on 04-Apr-2013 for defect 0010690
                  ,time_stamp
                  )
                VALUES
                 ('0200',
                  V_RRN,
                  P_DEL_CHANNEL,
                  sysdate,
                  P_TRAN_CODE,
                  '0',
                  DECODE(V_RESP_CODE,'1','C','F'),
                  DECODE(V_RESP_CODE,'1','00','89'),
                  V_BUSINESS_DATE,
                  V_BUSINESS_TIME,
                  P_HASH_PAN,
                  P_INSTCODE,
                  TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                  LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0'),
                  v_tran_desc,
                 TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                  P_INSTCODE,
                  fn_emaps_main(P_PAN_CODE),
                  P_ACCT_NO,
                  v_acct_bal,
                  v_ledger_bal,
                  V_RESP_CODE,
                  0,
                  v_card_curr ,
                  v_card_stat,
                  P_ORGNL_CARDNO,
                  P_ORGNL_RRN ,
                  P_ORGNL_DATE,
                  P_ORGNL_TIME,
                  P_ORGNL_TERMID ,
                  P_ERRMSG,
                  --SN: Added on 04-Apr-2013 for defect 0010690
                  v_merchant_zip,
                  v_merchant_id,
                  v_merchant_name,
                  v_merchant_state,
                  v_merchant_city   ,v_internation_ind_response,  v_pos_verification ,v_orgnl_mcccode
                  --EN: Added on 04-Apr-2013 for defect 0010690
                  ,systimestamp
                  );

                INSERT INTO CMS_TRANSACTION_LOG_DTL
                   (CTD_DELIVERY_CHANNEL,
                    CTD_TXN_CODE,
                    CTD_TXN_TYPE,
                    CTD_MSG_TYPE,
                    CTD_TXN_MODE,
                    CTD_BUSINESS_DATE,
                    CTD_BUSINESS_TIME,
                    CTD_CUSTOMER_CARD_NO,
                    CTD_PROCESS_FLAG,
                    CTD_PROCESS_MSG,
                    CTD_RRN,
                    CTD_INST_CODE,
                    CTD_CUSTOMER_CARD_NO_ENCR,
                    CTD_CUST_ACCT_NUMBER,
                    CTD_TXN_AMOUNT,
                    CTD_TXN_CURR,
                     ctd_completion_fee,ctd_complfee_increment_type --Added for FSS 837
                   )
                 VALUES
                   (P_DEL_CHANNEL,
                    P_TRAN_CODE,
                    '0',
                    '0200',
                    0,
                    V_BUSINESS_DATE,
                    V_BUSINESS_TIME,
                     P_HASH_PAN,
                    DECODE (V_RESP_CODE, '1', 'Y', 'F'),
                    DECODE (V_RESP_CODE, '1', 'Successful', P_RESP_MSG),
                    V_RRN,
                    P_INSTCODE,
                    fn_emaps_main(P_PAN_CODE),
                    V_ACCT_NO,
                    TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                    v_card_curr
                    ,p_completion_fee,'C' --Added for FSS 837
                    );

WHEN OTHERS THEN

 INSERT INTO TRANSACTIONLOG
                 (MSGTYPE,
                  RRN,
                  DELIVERY_CHANNEL,
                  DATE_TIME,
                  TXN_CODE,
                  TXN_TYPE,
                  TXN_STATUS,
                  RESPONSE_CODE,
                  BUSINESS_DATE,
                  BUSINESS_TIME,
                  CUSTOMER_CARD_NO,
                  BANK_CODE,
                  TOTAL_AMOUNT,
                  AUTH_ID,
                  TRANS_DESC,
                  AMOUNT,
                  INSTCODE,
                  CUSTOMER_CARD_NO_ENCR,
                  CUSTOMER_ACCT_NO,
                  ACCT_BALANCE,
                  LEDGER_BALANCE,
                  RESPONSE_ID,
                  TXN_MODE,
                  CURRENCYCODE,
                  CARDSTATUS,
                  ORGNL_CARD_NO,
                  ORGNL_RRN,
                  ORGNL_BUSINESS_DATE,
                  ORGNL_BUSINESS_TIME,
                  ORGNL_TERMINAL_ID,
                  ERROR_MSG,
                 --SN: Added on 04-Apr-2013 for defect 0010690
                  merchant_zip,
                  merchant_id,
                  merchant_name,
                  merchant_state,
                  merchant_city  ,internation_ind_response,pos_verification ,mccode
                 --EN: Added on 04-Apr-2013 for defect 0010690
                 ,time_stamp
                  )
                VALUES
                 ('0200',
                  V_RRN,
                  P_DEL_CHANNEL,
                  sysdate,
                  P_TRAN_CODE,
                  '0',
                  DECODE(V_RESP_CODE,'1','C','F'),
                  DECODE(V_RESP_CODE,'1','00','89'),
                  V_BUSINESS_DATE,
                  V_BUSINESS_TIME,
                  P_HASH_PAN,
                  P_INSTCODE,
                  TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                  LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0'),
                  v_tran_desc,
                 TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                  P_INSTCODE,
                  fn_emaps_main(P_PAN_CODE),
                  P_ACCT_NO,
                  v_acct_bal,
                  v_ledger_bal,
                  V_RESP_CODE,
                  0,
                  v_card_curr ,
                  v_card_stat,
                  P_ORGNL_CARDNO,
                  P_ORGNL_RRN ,
                  P_ORGNL_DATE,
                  P_ORGNL_TIME,
                  P_ORGNL_TERMID ,
                  P_ERRMSG,
                 --SN: Added on 04-Apr-2013 for defect 0010690
                  v_merchant_zip,
                  v_merchant_id,
                  v_merchant_name,
                  v_merchant_state,
                  v_merchant_city    ,v_internation_ind_response,  v_pos_verification ,v_orgnl_mcccode
                 --EN: Added on 04-Apr-2013 for defect 0010690
                 ,systimestamp
                  );

                INSERT INTO CMS_TRANSACTION_LOG_DTL
                   (CTD_DELIVERY_CHANNEL,
                    CTD_TXN_CODE,
                    CTD_TXN_TYPE,
                    CTD_MSG_TYPE,
                    CTD_TXN_MODE,
                    CTD_BUSINESS_DATE,
                    CTD_BUSINESS_TIME,
                    CTD_CUSTOMER_CARD_NO,
                    CTD_PROCESS_FLAG,
                    CTD_PROCESS_MSG,
                    CTD_RRN,
                    CTD_INST_CODE,
                    CTD_CUSTOMER_CARD_NO_ENCR,
                    CTD_CUST_ACCT_NUMBER,
                    CTD_TXN_AMOUNT,
                    CTD_TXN_CURR
                    , ctd_completion_fee,ctd_complfee_increment_type --Added for FSS 837
                   )
                 VALUES
                   (P_DEL_CHANNEL,
                    P_TRAN_CODE,
                    '0',
                    '0200',
                    0,
                    V_BUSINESS_DATE,
                    V_BUSINESS_TIME,
                     P_HASH_PAN,
                    DECODE (V_RESP_CODE, '1', 'Y', 'F'),
                    DECODE (V_RESP_CODE, '1', 'Successful', P_RESP_MSG),
                    V_RRN,
                    P_INSTCODE,
                    fn_emaps_main(P_PAN_CODE),
                    V_ACCT_NO,
                    TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')),
                    v_card_curr
                    ,p_completion_fee,'C' --Added for FSS 837
                    );
P_ERRMSG :='Error in logging the Preauth Hold Amount'|| SUBSTR (SQLERRM, 1, 200);

END;
/
SHOW ERROR