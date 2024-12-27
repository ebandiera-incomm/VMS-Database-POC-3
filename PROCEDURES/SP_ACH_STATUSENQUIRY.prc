create or replace PROCEDURE        VMSCMS.SP_ACH_STATUSENQUIRY(
                                         p_instcode           IN       NUMBER,
                                         p_rrn                IN       VARCHAR2,
                                         p_terminalid         IN       VARCHAR2,
                                         p_delivery_channel   IN       VARCHAR2,
                                         p_trandate           IN       VARCHAR2,
                                         p_trantime           IN       VARCHAR2,
                                         p_panno              IN       VARCHAR2,
                                         p_orig_rrn           IN       VARCHAR2,
                                         p_orig_trandate      IN       VARCHAR2,
                                         p_orig_trantime      IN       VARCHAR2,
                                         p_lupd_user          IN       VARCHAR2,
                                         p_msgtype            IN       VARCHAR2,
                                         p_trancde            IN       VARCHAR2,
                                         p_tran_mode          IN       VARCHAR2,
                                         p_mem_number         IN       VARCHAR2,
                                         p_rvslcde            IN       VARCHAR2,
                                         p_resp_code          OUT      VARCHAR2,
                                         p_resp_msg           OUT      VARCHAR2
)
AS
/*************************************************
      * Created Date     :  27-Feb-2012
      * Created By       :  Srinivasu.k
      * PURPOSE          :  For Status Enquiry transaction
      * Modified Reason  :  Modified for VMS ACH Exception Q
      * Modified Date    :  29-Nov-2012
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     :   CMS3.5.1_RI0023_B0001

      * Modified Date    : 06_Mar_2013
      * Modified By      : Pankaj S.
      * Purpose          : Defect ID FSS-1031
      * Reviewer         : Dhiraj
      * Release Number   : CMS3.5.1_RI0023.2_B0016

     * Modified Date    : 10-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog and cms_transaction_log_dtl if applicable
                          Account Type,Card Status,
                          Productid,Categoryid,Acct_No
                          Timestamp,CR_DR_FLAG,Error Message
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Dec-2013
     * Release Number   : RI0024.7_B0001

     * Modified By      : Dhinakaran B
     * Modified Date    : 14JUL2014
     * Purpose          : MANTIS ID-12684
	 * Reviewer         : Spankaj
     * Release Number   : RI0027.3_B0004

     * Modified By      : Siva Kumar M
     * Modified Date    : 27/05/2016
     * Purpose          : FSS-4354,4355&4356
     * Reviewer         : Saravana Kumar
     * Release Number   : VMSGPRHOSTCSD_4.1_B0003

     * Modified By      : MageshKumar S
     * Modified Date    : 10/08/2016
     * Purpose          : FSS-4354&4356
     * Reviewer         : Saravana Kumar
     * Release Number   : VMSGPRHOSTCSD_4.2.1_B0001

*************************************************/
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_topupremrk             VARCHAR2 (30);
   v_respcode               VARCHAR2 (5);
   exp_main_reject_record   EXCEPTION;
   v_authid_date            VARCHAR2 (8);
   v_auth_id                VARCHAR2 (30);
   v_rrn_count              VARCHAR2 (30);
   v_orig_rrn_count         VARCHAR2 (30);
   v_business_date          DATE;
   v_tran_date              DATE;
   v_date                   DATE;
   v_orig_date              DATE;
   v_orig_tran_date         DATE;
   v_error_masg             VARCHAR2 (300);
   v_cap_prod_catg   CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
   v_prod_code    CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
   V_CARD_TYPE    CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
   v_profile_code  CMS_PROD_MAST.CPM_PROFILE_CODE%TYPE;
   v_achflag CMS_PROD_CATTYPE.CPC_ACHTXN_FLG%TYPE;
   V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;

   V_DR_CR_FLAG       VARCHAR2(2);
   V_OUTPUT_TYPE      VARCHAR2(2);
   V_TRAN_TYPE         VARCHAR2(2);
   V_TXN_TYPE          VARCHAR2(2);
   V_trans_desc         CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
   V_CUST_CARD_NO   CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   V_HASH_PAN_VAL   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   V_ENCR_PAN_VAL   CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;

   v_acct_type cms_acct_mast.cam_type_code%type;
   v_card_stat cms_appl_pan.cap_card_stat%type;
   v_timestamp timestamp(3);
   v_cam_acct_bal  cms_acct_mast.cam_acct_bal%type;
   v_cam_ledger_bal cms_acct_mast.cam_ledger_bal%type;
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN
   v_errmsg := 'OK ';
   v_topupremrk := 'ACH Status Enquiry Transaction';


   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_panno);
      V_HASH_PAN_VAL := V_HASH_PAN;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_panno);
      V_ENCR_PAN_VAL := v_encr_pan;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

  --Sn find debit and credit flag

   /*Added by Besky on 09-nov-12*/

   BEGIN
    SELECT
        CAP_ACCT_NO
    INTO
        V_ACCT_NUMBER

    FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
      RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;


  --SN : Added on 10-Dec-2013 for 13160

  BEGIN

    SELECT CAM_TYPE_CODE,cam_acct_bal,cam_ledger_bal
    into   v_acct_type,v_cam_acct_bal,v_cam_ledger_bal
    FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = P_INSTCODE
    AND   CAM_ACCT_NO = V_ACCT_NUMBER;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Invalid Account number ' || V_ACCT_NUMBER;
      RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting Acct Type ' || V_ACCT_NUMBER;
     RAISE EXP_MAIN_REJECT_RECORD;

  END;

 --EN : Added on 10-Dec-2013 for 13160

  --Sn Commented on 06_Mar_2013 for FSS-1031
  --Sn select the active card for the account number
  /*BEGIN
    --Modified by Ramkumar.MK on 05 June 2012,
    --Added the store procedure for get the card number,hashpan,encrypan

    --Begin
    SP_CHECK_CARDSTATS(P_INSTCODE,
                   V_ACCT_NUMBER,
                   -- p_panno,
                   V_HASH_PAN,
                   V_CUST_CARD_NO,
                   V_ENCR_PAN,
                   V_RESPCODE,
                   V_ERRMSG);
    IF V_ERRMSG <> 'OK' THEN

     V_HASH_PAN := V_HASH_PAN_VAL;

     V_ENCR_PAN := V_ENCR_PAN_VAL;

     --V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while getting the primary pan for the Account Number ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;*/
  --En select the active card for the account number
  --En Commented on 06_Mar_2013 for FSS-1031


    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_trans_desc
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_trancde AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  p_trancde || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '21'; --Ineligible Transaction
       V_RESPCODE  := 'Error while selecting transaction details';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

   --Generate AuthId
   BEGIN
     /*( SELECT TO_CHAR (SYSDATE, 'YYYYMMDD')
        INTO v_authid_date
        FROM DUAL;

      SELECT v_authid_date || LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;*/
        --Auth_id length change from 14 to 6 on 221012
        SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';                               -- Server Declined
         RAISE exp_main_reject_record;
   END;

   --Tran date check
   BEGIN
      v_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting transaction time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;


   --Orig trandate check

   --Tran date check
   BEGIN
      v_orig_date :=
                  TO_DATE (SUBSTR (TRIM (p_orig_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
               'Problem while converting Original transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_orig_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_orig_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_orig_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting Original transaction time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;



--En find debit and credit flag

   --Check
   BEGIN
   
   --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn AND business_date = p_trandate
       and DELIVERY_CHANNEL = p_delivery_channel; --Added by ramkumar.Mk on 25 march 2012
	   
	   ELSE
		SELECT COUNT (1)
			INTO v_rrn_count
			FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
		   WHERE rrn = p_rrn AND business_date = p_trandate
		   and DELIVERY_CHANNEL = p_delivery_channel; --Added by ramkumar.Mk on 25 march 2012
	END IF;	 

      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || 'on ' || p_trandate;
         RAISE exp_main_reject_record;
      END IF;
   END;
   --Start

   BEGIN

      SELECT   cap_prod_catg,
             cap_prod_code,cap_card_type,
             cap_card_stat                  --Added on 10-Dec-2013 for 13160
        INTO   v_cap_prod_catg,
             v_prod_code,V_CARD_TYPE,
             v_card_stat                    --Added on 10-Dec-2013 for 13160
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_instcode;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
   END;


     BEGIN
      SELECT cpc_profile_code
        INTO v_profile_code
        FROM cms_prod_cattype
       WHERE cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cpc_inst_code = p_instcode;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
   END;

  begin

    SELECT cpc_achtxn_flg
        INTO v_achflag
        FROM cms_prod_cattype
       WHERE cpc_profile_code = v_profile_code
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cpc_inst_code = p_instcode;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'profile_code not defined ' || v_profile_code;
         RAISE exp_main_reject_record;
   END;

     BEGIN

      IF TRIM (v_achflag) = 'N'

      THEN
      v_respcode := '33';
      v_errmsg :=
            'ACH Transaction is not Supported for the Product Category';
      RAISE exp_main_reject_record;

   END IF;

   END;

    --Original transaction Checking
   BEGIN
   --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_orig_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
      SELECT COUNT (1)
        INTO v_orig_rrn_count
        FROM transactionlog
       WHERE rrn = p_orig_rrn
         AND business_date = p_orig_trandate
               /*
               Card No condition not required since ACH is account based
               and original transaction can be fetched based on the
               original RRN, date and time
               */
         --AND customer_card_no = v_hash_pan
         AND business_time = p_orig_trantime;
		 	ELSE
				SELECT COUNT (1)
			INTO v_orig_rrn_count
			FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
		   WHERE rrn = p_orig_rrn
			 AND business_date = p_orig_trandate
				   /*
				   Card No condition not required since ACH is account based 
				   and original transaction can be fetched based on the 
				   original RRN, date and time
				   */         
			 --AND customer_card_no = v_hash_pan
			 AND business_time = p_orig_trantime;
	END IF;
		 

      IF v_orig_rrn_count = 0
      THEN
         v_respcode := '19';   --Modified for ACH Exception Q on 28-Nov-2012
         v_errmsg := 'Original transaction details not found on ' || p_trandate;--Modified for ACH Exception Q on 28-Nov-2012
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record  then
        raise;
      WHEN OTHERS  then
         v_respcode := '19';--Modified for ACH Exception Q on 28-Nov-2012
         v_errmsg :='Problem while selecting  response detail'|| substr(sqlerrm,1,200);--Modified for ACH Exception Q on 28-Nov-2012
         RAISE exp_main_reject_record;
   END;

   --Sn Getting response code of original transaction --<<Commented here & used after txnlog insert for FSS-1031>>--
   /*IF v_orig_rrn_count > 0
   THEN
      IF TO_NUMBER (p_delivery_channel) = 11
      THEN
         BEGIN --Query modified for getting latest Respones MSG
             SELECT response_code, ctd_process_msg
              INTO v_respcode, v_error_masg
              FROM (SELECT   response_code, ctd_process_msg
                        --INTO v_respcode, v_error_masg
                    FROM     transactionlog tlog, cms_transaction_log_dtl ctd
                       WHERE rrn = p_orig_rrn
                         AND business_date = p_orig_trandate
                         /*
                         Card No condition not required since ACH is account based
                         and original transaction can be fetched based on the
                         original RRN, date and time
                         */
                         --AND customer_card_no = v_hash_pan
                         /*AND business_time = p_orig_trantime
                         AND instcode = p_instcode
                         AND ctd.ctd_rrn = tlog.rrn
                         AND ctd.ctd_customer_card_no = tlog.customer_card_no
                         AND tlog.business_date = ctd.ctd_business_date
                         AND tlog.business_time = ctd.ctd_business_time
                         AND ctd.ctd_inst_code = tlog.instcode
                         AND ctd.ctd_delivery_channel = tlog.delivery_channel
                    ORDER BY ctd_ins_date DESC)
             WHERE ROWNUM = 1;


            p_resp_code := v_respcode;
            v_errmsg := v_error_masg;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting  response detail of Original transaction'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '89';
               RAISE exp_main_reject_record;                -- Server Declined
         END;
      END IF;
   END IF; */
   --En Getting response code of original transaction --<<Commented here & used after txnlog insert for FSS-1031>>--

   --Sn Commented on 06_Mar_2013 for FSS-1031
   --p_resp_msg := v_errmsg;
   --p_resp_code := v_respcode;
   --En Commented on 06_Mar_2013 for FSS-1031

   --Sn Added on 06_Mar_20133 FSS-1031.,to get response code
    BEGIN
       v_respcode := '1';
     SELECT cms_iso_respcde
       INTO p_resp_code
       FROM cms_response_mast
      WHERE cms_inst_code = p_instcode
        AND cms_delivery_channel = p_delivery_channel
        AND cms_response_id = v_respcode;
    EXCEPTION
     WHEN OTHERS THEN
       v_errmsg  := 'Problem while selecting data from response master for respose code' ||
                  v_respcode || SUBSTR(SQLERRM, 1, 300);
       v_respcode := '89';
       RAISE exp_main_reject_record;
    END;
    --En Added on 06_Mar_20133 FSS-1031.,to get response code

    --SN : Added on 10-Dec-2013 for 13160
    v_timestamp := systimestamp;

    --SN : Added on 10-Dec-2013 for 13160

   BEGIN
      INSERT INTO transactionlog
                  (instcode, rrn, business_date, business_time, txn_code,
                   response_code, customer_card_no, customer_card_no_encr,
                   auth_id, orgnl_rrn, orgnl_business_date,
                   orgnl_business_time, delivery_channel, msgtype,TXN_TYPE,trans_desc,response_id,customer_acct_no,     --Added by Besky on 09-nov-12
                   -- SN Added on 10-Dec-2013  for 13160
                   acct_type,cardstatus,productid,Categoryid,Time_stamp,CR_DR_FLAG,error_msg
                   -- EN Added on 10-Dec-2013 for 13160
                   ,TXN_STATUS,ACCT_BALANCE,LEDGER_BALANCE,REVERSAL_CODE
                  )
           VALUES (p_instcode, p_rrn, p_trandate, p_trantime, p_trancde,
                   p_resp_code, v_hash_pan, v_encr_pan,
                   v_auth_id, p_orig_rrn, p_orig_trandate,
                   p_orig_trantime, p_delivery_channel, p_msgtype,V_TXN_TYPE,V_trans_desc,v_respcode,v_acct_number,   --Modified for ACH Exception Q on 28-Nov-2012
                   -- Added on 10-Dec-2013 for 13160
                   v_acct_type,v_card_stat,v_prod_code,v_card_type,v_timestamp,v_dr_cr_flag,v_errmsg
                   -- Added on 10-Dec-2013 for 13160
                   ,DECODE (P_RESP_CODE, '00', 'C', 'F'),v_cam_acct_bal,v_cam_ledger_bal,p_rvslcde
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem in delivery channel conversion'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
         RAISE exp_main_reject_record;                      -- Server Declined
   END;

   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_process_flag, ctd_process_msg,
                   ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,CTD_TXN_TYPE
                  )
           VALUES (p_delivery_channel, p_trancde, p_msgtype,
                   0, p_trandate, p_trantime,
                   v_hash_pan, 'Y', v_errmsg,   --'E' replaced by 'Y' for FSS-1031
                   p_rrn, p_instcode, v_encr_pan,V_TXN_TYPE
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem while inserting transactionlg dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
         RAISE exp_main_reject_record;
   END;

   --Sn Getting response code of original transaction --<<added here & commented above for FSS-1031>--
   IF v_orig_rrn_count > 0
   THEN
      IF TO_NUMBER (p_delivery_channel) = 11
      THEN
         BEGIN --Query modified for getting latest Respones MSG
             SELECT response_code, ctd_process_msg
              INTO v_respcode, v_error_masg
              FROM (SELECT   response_code, ctd_process_msg
                        --INTO v_respcode, v_error_masg
                    FROM     VMSCMS.TRANSACTIONLOG_VW tlog, VMSCMS.CMS_TRANSACTION_LOG_DTL_VW ctd --Added for VMS-5733/FSP-991
                       WHERE rrn = p_orig_rrn
                         AND business_date = p_orig_trandate
                         /*
                         Card No condition not required since ACH is account based
                         and original transaction can be fetched based on the
                         original RRN, date and time
                         */
                         --AND customer_card_no = v_hash_pan
                         AND business_time = p_orig_trantime
                         AND instcode = p_instcode
                         AND ctd.ctd_rrn = tlog.rrn
                         AND ctd.ctd_customer_card_no = tlog.customer_card_no
                         AND tlog.business_date = ctd.ctd_business_date
                         AND tlog.business_time = ctd.ctd_business_time
                         AND ctd.ctd_inst_code = tlog.instcode
                         AND ctd.ctd_delivery_channel = tlog.delivery_channel
                    ORDER BY ctd_ins_date DESC)
             WHERE ROWNUM = 1;


            p_resp_code := v_respcode;
            --v_errmsg := v_error_masg;
            p_resp_msg:= v_error_masg; --Modified on 06_Mar_2013 for FSS-1031

         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting  response detail of Original transaction'
                  || SUBSTR (SQLERRM, 1, 300);
               --p_resp_code := '89';
               v_respcode:='89';
               RAISE exp_main_reject_record;                -- Server Declined
         END;
      END IF;
   END IF;
   --En Getting response code of original transaction --<<added here & commented above for FSS-1031>--

EXCEPTION
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         p_resp_msg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_msg :=
               'Response code not available in response master '
               || v_respcode;
            --p_resp_code := 'R20';
            p_resp_code := 'R16';
--Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
           -- p_resp_code := 'R20';
            p_resp_code := 'R16';
--Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      END;

    --Sn commented here & added below after txnlog insert for FSS-1031
      /*BEGIN
         IF v_rrn_count > 0
         THEN
            IF TO_NUMBER (p_delivery_channel) = 11
            THEN
               BEGIN
                  SELECT response_code
                    INTO v_respcode
                    FROM transactionlog a,
                         (SELECT MIN (add_ins_date) mindate
                            FROM transactionlog
                           WHERE rrn = p_rrn) b
                   WHERE a.add_ins_date = mindate AND rrn = p_rrn;

                  p_resp_code := v_respcode;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem in selecting the response detail of Original transaction'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code := '89';                   -- Server Declined
                     ROLLBACK;
                     RETURN;
               END;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem in delivery channel conversion'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';                            -- Server Declined
            ROLLBACK;
            RETURN;
      END;*/
      --En commented here & added below after txnlog insert for FSS-1031



    --SN : Added on 10-Dec-2013 for 13160

    if v_acct_type is null
    then


      BEGIN

        SELECT CAM_TYPE_CODE,cam_acct_bal,cam_ledger_bal
        into   v_acct_type,v_cam_acct_bal,v_cam_ledger_bal
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INSTCODE
        AND   CAM_ACCT_NO = (
                             SELECT CAP_ACCT_NO
                             FROM CMS_APPL_PAN
                             WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE
                             );

      EXCEPTION
        WHEN  OTHERS THEN
        null;

      END;

    end if;


   if v_prod_code is null
    then

       BEGIN

          SELECT cap_prod_catg,
                 cap_prod_code,
                 cap_card_type,
                 cap_card_stat
            INTO v_cap_prod_catg,
                 v_prod_code,
                 v_card_type,
                 v_card_stat
            FROM cms_appl_pan
           WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_instcode;
       EXCEPTION WHEN OTHERS
          THEN
             null;
       END;

   end if;

   v_timestamp := systimestamp;




  if V_DR_CR_FLAG is null
  then

    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_trans_desc
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_trancde AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
        null;

    END;

  end if;

   --EN : Added on 10-Dec-2013 for 13160

    IF v_respcode NOT IN ('45','32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
      BEGIN
         INSERT INTO transactionlog
                     (instcode, rrn, business_date, business_time, txn_code,
                      response_code, customer_card_no,
                      customer_card_no_encr, auth_id, orgnl_rrn,
                      orgnl_business_date, orgnl_business_time,
                      delivery_channel, msgtype,TXN_TYPE,trans_desc,response_id,CUSTOMER_ACCT_NO,     --Added by Besky on 09-nov-12
                      -- Added on 10-Dec-2013 for 13160
                      acct_type,cardstatus,productid,Categoryid,Time_stamp,CR_DR_FLAG,error_msg
                      -- Added on 10-Dec-2013 for 13160
                      ,TXN_STATUS,ACCT_BALANCE,LEDGER_BALANCE,REVERSAL_CODE
                     )
              VALUES (p_instcode, p_rrn, p_trandate, p_trantime, p_trancde,
                      p_resp_code, v_hash_pan,
                      v_encr_pan, v_auth_id, p_orig_rrn,
                      p_orig_trandate, p_orig_trantime,
                      p_delivery_channel, p_msgtype,V_TXN_TYPE,V_trans_desc,v_respcode,V_ACCT_NUMBER,   --Modified for ACH Exception Q on 28-Nov-2012
                      -- Added on 10-Dec-2013 for 13160
                      v_acct_type,v_card_stat,v_prod_code,v_card_type,v_timestamp,v_dr_cr_flag,v_errmsg
                      -- Added on 10-Dec-2013 for 13160
                      ,'F',v_cam_acct_bal,v_cam_ledger_bal,p_rvslcde
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting transactionlg'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RAISE exp_main_reject_record;                   -- Server Declined
            ROLLBACK;
            RETURN;
      END;
      END IF;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr,CTD_TXN_TYPE
                     )
              VALUES (p_delivery_channel, p_trancde, p_msgtype,
                      0, p_trandate, p_trantime,
                      v_hash_pan, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan,V_TXN_TYPE
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting transactionlg dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RAISE exp_main_reject_record;
      END;
      --Sn added here & commented above for FSS-1031
      BEGIN
         IF v_rrn_count > 0
         THEN
            IF TO_NUMBER (p_delivery_channel) = 11
            THEN
               BEGIN
                   SELECT response_code
                    INTO v_respcode
                    FROM VMSCMS.TRANSACTIONLOG a,		--Added for VMS-5733/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS.TRANSACTIONLOG		--Added for VMS-5733/FSP-991
                           WHERE rrn = p_rrn) b
                   WHERE a.add_ins_date = mindate AND rrn = p_rrn;
				   IF SQL%ROWCOUNT = 0 THEN 
				   SELECT response_code
                    INTO v_respcode
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST a,		--Added for VMS-5733/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST		--Added for VMS-5733/FSP-991
                           WHERE rrn = p_rrn) b
                   WHERE a.add_ins_date = mindate AND rrn = p_rrn;
				   END IF;

                  p_resp_code := v_respcode;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem in selecting the response detail of Original transaction'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code := '89';                   -- Server Declined
                     ROLLBACK;
                     RETURN;
               END;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem in delivery channel conversion'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';                            -- Server Declined
            ROLLBACK;
            RETURN;
      END;
      --En added here & commented above for FSS-1031
   WHEN OTHERS
   THEN
      BEGIN
         p_resp_msg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_msg :=
               'Response code not available in response master '
               || v_respcode;
            --p_resp_code := 'R20';
            p_resp_code := 'R16';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            --p_resp_code := 'R20';
            p_resp_code := 'R16';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      END;

    --SN : Added on 10-Dec-2013 for 13160

    if v_acct_type is null
    then


      BEGIN

        SELECT CAM_TYPE_CODE,cam_acct_bal,cam_ledger_bal
        into   v_acct_type,v_cam_acct_bal,v_cam_ledger_bal
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INSTCODE
        AND   CAM_ACCT_NO = (
                             SELECT CAP_ACCT_NO
                             FROM CMS_APPL_PAN
                             WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE
                             );

      EXCEPTION
        WHEN  OTHERS THEN
        null;

      END;

    end if;


   if v_prod_code is null
    then

       BEGIN

          SELECT cap_prod_catg,
                 cap_prod_code,
                 cap_card_type,
                 cap_card_stat
            INTO v_cap_prod_catg,
                 v_prod_code,
                 v_card_type,
                 v_card_stat
            FROM cms_appl_pan
           WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_instcode;
       EXCEPTION WHEN OTHERS
          THEN
             null;
       END;

   end if;


   if v_timestamp is null
   then
        v_timestamp := systimestamp;

   end if;


  if V_DR_CR_FLAG is null
  then

    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_trans_desc
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_trancde AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
        null;

    END;

  end if;

   --EN : Added on 10-Dec-2013 for 13160


      IF v_respcode NOT IN ('45','32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
      BEGIN
         INSERT INTO transactionlog
                     (instcode, rrn, business_date, business_time, txn_code,
                      response_code, customer_card_no,
                      customer_card_no_encr, auth_id, orgnl_rrn,
                      orgnl_business_date, orgnl_business_time,
                      delivery_channel, msgtype,TXN_TYPE,trans_desc,response_id,CUSTOMER_ACCT_NO,     --Added by Besky on 09-nov-12
                      -- Added on 10-Dec-2013 for 13160
                      acct_type,cardstatus,productid,Categoryid,Time_stamp,CR_DR_FLAG,error_msg
                      -- Added on 10-Dec-2013 for 13160
                      ,TXN_STATUS,ACCT_BALANCE,LEDGER_BALANCE,REVERSAL_CODE
                     )
              VALUES (p_instcode, p_rrn, p_trandate, p_trantime, p_trancde,
                      p_resp_code, v_hash_pan,
                      v_encr_pan, v_auth_id, p_orig_rrn,
                      p_orig_trandate, p_orig_trantime,
                      p_delivery_channel, p_msgtype,V_TXN_TYPE,V_trans_desc,v_respcode, --p_resp_code,  --Modified on 06_Mar_2013 for FSS-1031
                      V_ACCT_NUMBER,   --Added by Besky on 09-nov-12
                      -- Added on 10-Dec-2013 for 13160
                      v_acct_type,v_card_stat,v_prod_code,v_card_type,v_timestamp,v_dr_cr_flag,v_errmsg
                      -- Added on 10-Dec-2013 for 13160,
                      ,'F',v_cam_acct_bal,v_cam_ledger_bal,p_rvslcde
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting transactionlg'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RAISE exp_main_reject_record;                   -- Server Declined
            ROLLBACK;
            RETURN;
      END;
      END IF;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr,CTD_TXN_TYPE
                     )
              VALUES (p_delivery_channel, p_trancde, p_msgtype,
                      0, p_trandate, p_trantime,
                      v_hash_pan, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan,V_TXN_TYPE
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting transactionlg dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RAISE exp_main_reject_record;
      END;
      --Sn Commented on 06_Mar_2013 for FSS-1031
      --p_resp_msg := v_errmsg;
      --p_resp_code := v_respcode;
      --En Commented on 06_Mar_2013 for FSS-1031
END;
/
SHOW ERROR