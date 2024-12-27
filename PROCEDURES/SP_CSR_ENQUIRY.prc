create or replace PROCEDURE    VMSCMS.sp_csr_enquiry (
                                                   prm_inst_code                NUMBER,
                                                   prm_msg                      VARCHAR2,
                                                   prm_rrn                      VARCHAR2,
                                                   prm_delivery_channel         VARCHAR2,
                                                   prm_txn_code                 VARCHAR2,
                                                   prm_txn_mode                 VARCHAR2,
                                                   prm_tran_date                VARCHAR2,
                                                   prm_tran_time                VARCHAR2,
                                                   prm_card_no                  VARCHAR2,
                                                   prm_mbr_numb                 VARCHAR2,
                                                   prm_fee_calc                 CHAR,
                                                   prm_txn_amt                  NUMBER,
                                                   prm_curr_code                VARCHAR2,
                                                   prm_stan                     VARCHAR2,
                                                   prm_ins_user                 NUMBER,
                                                   prm_ins_date                 DATE,
                                                   prm_comment                  VARCHAR2,-- added by sagar on 03-Jul-2012 for jun bug fix RI0010.2
                                                   prm_ipaddress                VARCHAR2, --added by amit on 07-Oct-2012
                                                   prm_call_id           OUT    NUMBER,
                                                   prm_err_msg           OUT    VARCHAR2,
                                                   prm_resp_code         OUT    VARCHAR2,
                                                   prm_pin_flag          OUT    VARCHAR2,
                                                   prm_fee_amt           IN OUT VARCHAR2,
                                                   prm_avail_bal         OUT    VARCHAR2,
                                                   prm_ledger_bal        OUT    VARCHAR2,
                                                   prm_process_msg       OUT    VARCHAR2
                                                 )
IS
/******************************************************************************************
     * Created Date                 : 22/Feb/2012.
     * Created By                   : Dhiraj M.G.
     * Purpose                      : CSR call log
     * Last Modification Done by    : Amit Sonar
     * Last Modification Date       : 07-Oct-2012
     * Mofication Reason            : Log ipaddress,remark and lupduser in transactionlog table      
     * Build Number                 : RI0021
     
     * Modified By      : Sagar M.
     * Modified Date    : 19-Apr-2013
	 * Modified for     : Defect 10871
     * Modified Reason  : Logging of Timestamp and updating below details in tranasctionlog
                          1) Product code,Product Category,Card Status,Dr Cr flag,balance details   
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-apr-2013
     * Build Number     : RI0024.1_B0013
     
     * Modified By      : Abhay R
     * Modified Date    : 26-08-2013
	 * Modified for     : MVCSD-4099
     * Modified Reason  : Durbin Changes
	 * Build Number     : RI0024.4_B0004
	 
	* Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
********************************************************************************************/
   excp_main        EXCEPTION;
   v_txn_amt        NUMBER;
   v_ledger_bal     NUMBER;
   v_auth_id        VARCHAR2 (20);
   v_resp_code      VARCHAR2 (10);
   v_resp_msg       VARCHAR2 (300);
   v_capture_date   DATE;
   v_hash_pan       cms_appl_pan.cap_pan_code%TYPE;
   v_comment        VARCHAR2 (3000);
   v_spnd_acctno    cms_appl_pan.cap_acct_no%TYPE;
-- ADDED BY GANESH ON 19-JUL-12
    v_fee_amt cms_statements_log.csl_trans_amount%type; -- Added by sagar on 21-Aug-2012 to fetch addtional fee details
    v_cam_acct_no    cms_acct_mast.cam_acct_no%type;
    v_chk_clawback   varchar2(2);
    v_rrn_count      number;
    v_clawback_amt CMS_CHARGE_DTL.ccd_clawback_amnt%type;
    v_timestamp       timestamp;                         -- Added on 19-apr-2013 for defect 10871  
    v_flag            varchar2(1) default '0';           -- Added on 19-apr-2013 for defect 10871   
    V_ACCT_BALANCE    CMS_ACCT_MAST.CAM_ACCT_BAL%type;   -- Added on 19-apr-2013 for defect 10871
    v_cam_type_code   CMS_ACCT_MAST.cam_type_code%type;  -- Added on 19-apr-2013 for defect 10871             
    v_prod_code       CMS_APPL_PAN.CAP_PROD_CODE%type;   -- Added on 19-apr-2013 for defect 10871  
    v_prod_cattype    CMS_APPL_PAN.CAP_CARD_TYPE%type;   -- Added on 19-apr-2013 for defect 10871
    v_applpan_cardstat CMS_APPL_PAN.CAP_CARD_STAT%type;  -- Added on 19-apr-2013 for defect 10871
    v_acct_number      CMS_APPL_PAN.CAP_ACCT_NO%type;    -- Added on 19-apr-2013 for defect 10871 
    V_DR_CR_FLAG CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;    
    v_cap_pin_flag     VARCHAR2(1):='N'; -- Added by Abhay R for MVCSD-4099
    v_user_type          cms_prod_cattype.CPC_USER_IDENTIFY_TYPE%type;
    v_card_stat    cms_appl_pan.cap_card_stat%type;
    v_cardstat_expiry_flag varchar2(2);
    v_card_encr cms_appl_pan.cap_pan_code_encr%type;
  
    v_Retperiod  date; --Added for VMS-5733/FSP-991
    v_Retdate  date; --Added for VMS-5733/FSP-991
        
BEGIN
   --  prm_err_msg := 'OK';
   v_txn_amt := NVL (prm_txn_amt, 0);
   prm_pin_flag := v_cap_pin_flag;

   if prm_fee_calc ='N'
   then
   prm_process_msg := 'FEE NOT APPLIED';
   end if;


   --prm_fee_amt := 0.00; --commented by sagar on 27Aug2012

   v_resp_msg := 'OK';
   v_resp_code := 1;



   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_resp_msg  :=
             'Error while converting in hashpan ' || SUBSTR (SQLERRM, 1, 100);
         RAISE excp_main;
   END;
   
   
   BEGIN
   
   select case when cap_cardstatus_expiry is null then 'N' when cap_cardstatus_expiry > sysdate then 'N' when 
   cap_cardstatus_expiry <= sysdate then 'Y' end as cap_cardstatus_expiry,cap_card_stat,cap_pan_code_encr 
   into v_cardstat_expiry_flag,v_card_stat,v_card_encr from cms_appl_pan where cap_pan_code=v_hash_pan and cap_inst_code=prm_inst_code;
   
   if v_cardstat_expiry_flag ='Y' and v_card_stat='19' then
       update cms_appl_pan set cap_card_stat=cap_old_cardstat,cap_cardstatus_expiry=null where cap_pan_code=v_hash_pan  and cap_inst_code=prm_inst_code;
        IF SQL%ROWCOUNT = 1 then 
                     sp_log_cardstat_chnge (prm_inst_code,
                                             v_hash_pan,
                                            v_card_encr,
                                              v_auth_id,
                                                   '99',
                                                 prm_rrn,
                                                prm_tran_date,
                                               prm_tran_time,
                                                v_resp_code,
                                                v_resp_msg
                                                );

       IF v_resp_code <> '00' AND v_resp_msg <> 'OK'
       then
          v_resp_code := '21';
            v_resp_msg := 'Error while log cardstat change' || SUBSTR (SQLERRM, 1, 200);
          RAISE excp_main;
       END IF;
   
   end if;
       
   end if;
   exception 
   when excp_main then raise;
   WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg := 'Error while revert fraud hold card stat' || SUBSTR (SQLERRM, 1, 200);

            RAISE excp_main;
   
   END;

      BEGIN
      
      v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
        SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delivery_channel
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
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time;
         END IF;   

         IF v_rrn_count > 0
         THEN
            v_resp_code := '22';
            v_resp_msg := 'Duplicate RRN found - ' || prm_rrn;
            RAISE excp_main;
         END IF;
      EXCEPTION
         WHEN excp_main
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'While checking for duplicate '
               || prm_rrn
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_main;
      END;



      BEGIN                                  -- Added by sagar on 10-Jul-2012
         sp_authorize_txn_cms_auth (prm_inst_code,
                                    prm_msg,
                                    prm_rrn,
                                    prm_delivery_channel,
                                    NULL,                          --P_TERM_ID
                                    prm_txn_code,
                                    prm_txn_mode,
                                    prm_tran_date,
                                    prm_tran_time,
                                    prm_card_no,
                                    prm_inst_code,
                                    v_txn_amt,                           --AMT
                                    NULL,                      --MERCHANT NAME
                                    NULL,                      --MERCHANT CITY
                                    NULL,                         --P_MCC_CODE
                                    prm_curr_code,
                                    NULL,                          --P_PROD_ID
                                    NULL,                          --P_CATG_ID
                                    NULL,                          --P_TIP_AMT
                                    NULL,                       --P_TO_ACCT_NO
                                    NULL,                      --P_ATMNAME_LOC
                                    NULL,                  --P_MCCCODE_GROUPID
                                    NULL,                 --P_CURRCODE_GROUPID
                                    NULL,                --P_TRANSCODE_GROUPID
                                    NULL,                            --P_RULES
                                    NULL,                     --P_PREAUTH_DATE
                                    NULL,                   --P_CONSODIUM_CODE
                                    NULL,                     --P_PARTNER_CODE
                                    NULL,                       --P_EXPRY_DATE
                                    prm_stan,
                                    prm_mbr_numb,
                                    '00',
                                    v_txn_amt,                --P_CURR_CONVERT_AMNT
                                    v_auth_id,
                                    v_resp_code,
                                    v_resp_msg,
                                    v_capture_date,
                                    prm_fee_calc
                                   );

         IF v_resp_code <> '00' AND v_resp_msg <> 'OK'
         THEN

             v_resp_msg := 'OK';
             v_resp_code := '1';

         END IF;


      EXCEPTION  WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);

            RAISE excp_main;
      END;
      
      v_flag := '1';
   /*
    sp_authorize_txn_pot (prm_inst_code,
                          prm_msg,
                          prm_rrn,
                          prm_delivery_channel,
                          NULL,                               --prm_term_id,
                          prm_txn_code,
                          prm_txn_mode,
                          prm_tran_date,
                          prm_tran_time,
                          prm_card_no,
                          NULL,                             --prm_bank_code,
                          v_txn_amt,
                          NULL,                        -- prm_merchant_name,
                          NULL,                         --prm_merchant_city,
                          NULL,                             -- prm_mcc_code,
                          prm_curr_code,
                          NULL,                               --prm_prod_id,
                          NULL,                               --prm_catg_id,
                          NULL,                               --prm_tip_amt,
                          NULL,                        --prm_decline_ruleid,
                          NULL,                           --prm_atmname_loc,
                          NULL,                       --prm_mcccode_groupid,
                          NULL,                      --prm_currcode_groupid,
                          NULL,                     --prm_transcode_groupid,
                          NULL,                                 --prm_rules,
                          NULL,                          --prm_preauth_date,
                          NULL,                        --prm_consodium_code,
                          NULL,                          --prm_partner_code,
                          NULL,                            --prm_expry_date,
                          prm_stan,
                          prm_mbr_numb,                     -- prm_mbr_numb,
                          NULL,                     --prm_preauth_expperiod,
                          NULL,                   --  prm_international_ind,
                          NULL,                             --prm_rvsl_code,
                          NULL,                             -- prm_tran_cnt,
                        -- End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes
                          NULL,
                          NULL,
                          NULL,
                        -- End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes
                          v_auth_id,
                          v_resp_code,
                          v_resp_msg,
                          v_ledger_bal
                         );

    IF (v_resp_code <> '1' OR v_resp_msg <> 'OK')
    THEN
       RAISE excp_main;
    END IF;
   */


-- SN : ADDED BY Ganesh on 18-JUL-12
   BEGIN
      SELECT cap_acct_no,cap_card_stat,decode(cap_pin_off,null,'N','Y'),CAP_PROD_CODE,
                    CAP_CARD_TYPE                
        INTO v_spnd_acctno,v_applpan_cardstat,v_cap_pin_flag, V_PROD_CODE,
                    V_PROD_CATTYPE
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = prm_inst_code
         AND cap_mbr_numb = prm_mbr_numb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '16';
         v_resp_msg :=
              'Spending Account Number Not Found For the Card in PAN Master ';
         RAISE excp_main;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_resp_msg :=
               'Error While Selecting Spending account Number for Card '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE excp_main;
   END;
  -- EN : ADDED BY Ganesh on 18-JUL-12



   BEGIN
      SELECT seq_call_id.NEXTVAL
        INTO prm_call_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_resp_msg := ' Error while generating call id  ' || SQLERRM;
         RAISE excp_main;
   END;

   BEGIN
      INSERT INTO cms_calllog_mast
                  (ccm_inst_code, ccm_call_id, ccm_call_catg, ccm_pan_code,
                   ccm_callstart_date, ccm_callend_date, ccm_ins_user,
                   ccm_ins_date, ccm_lupd_user, ccm_lupd_date,
                   ccm_acct_no   -- CCM_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                  )
           VALUES (prm_inst_code, prm_call_id, 1, v_hash_pan,
                   SYSDATE, NULL, prm_ins_user,
                   SYSDATE, prm_ins_user, SYSDATE,
                   v_spnd_acctno
                  -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_resp_msg :=
                   ' Error while inserting into cms_calllog_mast ' || SQLERRM;
         RAISE excp_main;
   END;

   IF prm_comment IS NOT NULL
   -- added by sagar on 03-Jul-2012 for jun bug fix RI0010.2
   THEN
      v_comment := prm_comment;
   ELSE
      v_comment := 'CSR INQUIRY START';
   -- spelling corrected for ENQUIRY to INQUIRY
   END IF;

   BEGIN
      INSERT INTO cms_calllog_details
                  (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                   ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                   ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                   ccd_colm_name, ccd_old_value, ccd_new_value,
                   ccd_comments, ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                   ccd_lupd_date,
                   ccd_acct_no   -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                  )
           VALUES (prm_inst_code, prm_call_id, v_hash_pan, 1,
                   prm_rrn, prm_delivery_channel, prm_txn_code,
                   prm_tran_date, prm_tran_time, NULL,
                   NULL, NULL, NULL,
                   v_comment, prm_ins_user, SYSDATE, prm_ins_user,
                   --kinjal patil 14-03-12 comment-temporary purpose
                   SYSDATE,
                   v_spnd_acctno
                  -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_resp_msg :=
                ' Error while inserting into cms_calllog_details ' || SQLERRM;
         RAISE excp_main;
   END;

       -------------------------------------------------------------------
       --SN: Added by sagar on 21-Aug-2012 to fetch additional fee details
       -------------------------------------------------------------------


        BEGIN

           select cam_acct_bal,cam_ledger_bal,cam_acct_no
           into   prm_avail_bal,prm_ledger_bal,v_cam_acct_no
           from   cms_acct_mast
           where cam_inst_code = prm_inst_code
           and   cam_acct_no = (select cap_acct_no
                                 from   cms_appl_pan
                                 where  cap_inst_code = prm_inst_code
                                 and    cap_pan_code  = v_hash_pan
                                 );

        exception when no_data_found
        then
             prm_avail_bal  := null;
             prm_ledger_bal := null;

        when others
        then
                 v_resp_code := '21';
                 v_resp_msg := 'Error While Fetching Balance '||substr(sqlerrm,1,100);
                 raise excp_main;
        END;

   IF prm_fee_calc = 'Y'
   THEN


        Begin

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');
       
IF (v_Retdate>v_Retperiod)
    THEN
           select csl_trans_amount
           into   v_fee_amt
           from   cms_statements_log
           where  csl_pan_no = v_hash_pan
           and    csl_rrn    = prm_rrn
           and    csl_business_date = prm_tran_date
           and    csl_business_time = prm_tran_time
           and    txn_fee_flag      = 'Y'
           and    csl_delivery_channel = prm_delivery_channel
           and    csl_txn_code         = prm_txn_code;
       else
              select csl_trans_amount
           into   v_fee_amt
           from   VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5733/FSP-991
           where  csl_pan_no = v_hash_pan
           and    csl_rrn    = prm_rrn
           and    csl_business_date = prm_tran_date
           and    csl_business_time = prm_tran_time
           and    txn_fee_flag      = 'Y'
           and    csl_delivery_channel = prm_delivery_channel
           and    csl_txn_code         = prm_txn_code;
         end if;  

        exception when no_data_found
        then

           BEGIN

             select 1,ccd_clawback_amnt
             into  v_chk_clawback,v_clawback_amt
             from CMS_CHARGE_DTL
             where ccd_pan_code = v_hash_pan
             and   ccd_rrn      = prm_rrn
             and   ccd_acct_no  = v_cam_acct_no
             and   ccd_delivery_channel = prm_delivery_channel
             and   ccd_txn_code = prm_txn_code
             and   ccd_clawback = 'Y';

             if v_clawback_amt >= prm_fee_amt
             then
                 prm_process_msg := 'Fee Amount Will Be Collected Through Clawback';

             end if;


           Exception when no_data_found
           then
                prm_process_msg := 'Fee not debited';
                v_fee_amt := 0;

           when others
           then
                 v_resp_code := '21';
                 v_resp_msg := 'Error While clawback check '||substr(sqlerrm,1,100);
                 raise excp_main;

           END;

        when excp_main
        then
             raise;

        when others
        then
                 v_resp_code := '21';
                 v_resp_msg := 'Error While fetching fee amount '||substr(sqlerrm,1,100);
                 raise excp_main;
        END;


        BEGIN

         if prm_process_msg is null
         then

             If  prm_fee_amt = v_fee_amt
              then

                 prm_process_msg := 'Fee Debited Successfully';
                 prm_fee_amt := v_fee_amt;


             elsif v_fee_amt = 0
              then

                prm_process_msg := 'Fee not Debited. Complementary';
                prm_fee_amt := v_fee_amt;

             elsif prm_fee_amt > v_fee_amt
             then

                prm_process_msg := ' Fee Debited Partially. Balance fee Will Be Collected Through Clawback';
                prm_fee_amt := v_fee_amt;

             end if;

         end if;

       exception when others
       then
             v_resp_code := '21';
             v_resp_msg := 'Error while assigning fee amt and message '||substr(sqlerrm,1,100);
             raise excp_main;

       END;

   END IF;
       -------------------------------------------------------------------
       --EN: Added by sagar on 21-Aug-2012 to fetch additional fee details
       -------------------------------------------------------------------

    ---Sn to log ipaddress,lupduser and remark in transaction log table for successful record. added by amit on 07-Oct-2012 
   BEGIN 
   
    select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');


   IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
       ELSE
           UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
    END IF;
     

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                     'Txn not updated in transactiolog for ipaddress and lupduser';
            RAISE excp_main;
         END IF;
      EXCEPTION
         WHEN excp_main
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_main;
      END;
   ---En to log ipaddress,lupduser and remark in transaction log table for successful record.
       
   prm_err_msg := v_resp_msg;
   
    --Sn Abhay Durbin Changes  MVCSD-4099
    IF V_CAP_PIN_FLAG = 'N' AND V_APPLPAN_CARDSTAT = '0'
    THEN
     BEGIN
          SELECT  nvl(CPC_USER_IDENTIFY_TYPE,'0')
          INTO  v_user_type
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE = v_prod_code
          AND CPC_CARD_TYPE = V_PROD_CATTYPE
          AND CPC_INST_CODE=prm_inst_code;
     EXCEPTION
          WHEN OTHERS THEN
          v_resp_code := '21';
            v_resp_msg := 'Error while getting v_user_type -' || SUBSTR (SQLERRM, 1, 200);
           RAISE excp_main;
     END;
         if v_user_type <> '1' then
          PRM_PIN_FLAG := 'Y';
         End if;
    END IF;
   
--En Abhay Durbin Changes  MVCSD-4099
   
   
EXCEPTION
   WHEN excp_main
   THEN
      prm_err_msg := v_resp_msg;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_resp_code;

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

       

     -----------------------------------------------
     --SN: Added on 19-apr-2013 for defect 10871
     -----------------------------------------------
     
     if v_flag = '0'
     then
     
     
         BEGIN
             
           SELECT cam_acct_bal, cam_ledger_bal,
                  cam_type_code                                 -- Added on 19-apr-2013 for defect 10871
            INTO  v_acct_balance, v_ledger_bal, 
                  v_cam_type_code                               -- Added on 19-apr-2013 for defect 10871
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
                (SELECT CAP_ACCT_NO
                   FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = V_HASH_PAN AND
                       CAP_INST_CODE = prm_inst_code) AND
                CAM_INST_CODE = prm_INST_CODE;
                
         EXCEPTION
           WHEN OTHERS THEN
            V_ACCT_BALANCE := 0;
            V_LEDGER_BAL   := 0;
         END;          
     
     
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE cap_inst_code = prm_inst_code AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
              
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;     
     
     
        BEGIN
        
             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = Prm_TXN_CODE 
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_channel 
              AND   CTM_INST_CODE = prm_inst_code;
              
        EXCEPTION
         WHEN OTHERS THEN
         
         NULL;

        END;
        
      v_timestamp := systimestamp;              -- Added on 19-apr-2013 for defect 10871   
   
     end if;
          
     -----------------------------------------------
     --EN: Added on 19-apr-2013 for defect 10871
     -----------------------------------------------             
         
        ---Sn to log ipaddress,lupduser in transaction log table for successful record. added by amit on 07-Oct-2012 
        BEGIN 
        
        
   
IF (v_Retdate>v_Retperiod)
    THEN     
         UPDATE transactionlog
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user,
                time_stamp = v_timestamp,                                                       -- Added on 19-apr-2013 for defect 10871
                productid  = decode(v_flag,0,v_prod_code,productid),                            -- Added on 19-apr-2013 for defect 10871
                categoryid = decode(v_flag,0,v_prod_cattype,categoryid),                        -- Added on 19-apr-2013 for defect 10871
                cardstatus = decode(v_flag,0,v_applpan_cardstat,cardstatus),                    -- Added on 19-apr-2013 for defect 10871
                customer_acct_no = decode(v_flag,0,v_acct_number,customer_acct_no),             -- Added on 19-apr-2013 for defect 10871
                cr_dr_flag  = decode(v_flag,0,v_dr_cr_flag,cr_dr_flag),                         -- Added on 19-apr-2013 for defect 10871
                acct_type   = decode(v_flag,0,v_cam_type_code,cr_dr_flag),                      -- Added on 19-apr-2013 for defect 10871
                acct_balance = decode(v_flag,0,v_acct_balance,acct_balance),                    -- Added on 19-apr-2013 for defect 10871
                ledger_balance = decode(v_flag,0,v_ledger_bal,ledger_balance)                   -- Added on 19-apr-2013 for defect 10871 
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
        ELSE
            UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user,
                time_stamp = v_timestamp,                                                       -- Added on 19-apr-2013 for defect 10871
                productid  = decode(v_flag,0,v_prod_code,productid),                            -- Added on 19-apr-2013 for defect 10871
                categoryid = decode(v_flag,0,v_prod_cattype,categoryid),                        -- Added on 19-apr-2013 for defect 10871
                cardstatus = decode(v_flag,0,v_applpan_cardstat,cardstatus),                    -- Added on 19-apr-2013 for defect 10871
                customer_acct_no = decode(v_flag,0,v_acct_number,customer_acct_no),             -- Added on 19-apr-2013 for defect 10871
                cr_dr_flag  = decode(v_flag,0,v_dr_cr_flag,cr_dr_flag),                         -- Added on 19-apr-2013 for defect 10871
                acct_type   = decode(v_flag,0,v_cam_type_code,cr_dr_flag),                      -- Added on 19-apr-2013 for defect 10871
                acct_balance = decode(v_flag,0,v_acct_balance,acct_balance),                    -- Added on 19-apr-2013 for defect 10871
                ledger_balance = decode(v_flag,0,v_ledger_bal,ledger_balance)                   -- Added on 19-apr-2013 for defect 10871 
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
          END IF;  

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                     'Txn not updated in transactiolog for ipaddress,lupduser';
            RETURN;
         END IF;
         
        EXCEPTION         
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while updating transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
        END;
        ---En to log ipaddress,lupduser and remark in transaction log table for successful record.

   WHEN OTHERS
   THEN
      prm_err_msg := 'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
      v_resp_code := '21';

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_resp_code;

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;
        
      
     -----------------------------------------------
     --SN: Added on 19-apr-2013 for defect 10871
     -----------------------------------------------
     
     if v_flag = '0'
     then
     
     
         BEGIN
             
           SELECT cam_acct_bal, cam_ledger_bal,
                  cam_type_code                                 -- Added on 19-apr-2013 for defect 10871
            INTO  v_acct_balance, v_ledger_bal, 
                  v_cam_type_code                               -- Added on 19-apr-2013 for defect 10871
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
                (SELECT CAP_ACCT_NO
                   FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = V_HASH_PAN AND
                       CAP_INST_CODE = prm_inst_code) AND
                CAM_INST_CODE = prm_INST_CODE;
                
         EXCEPTION
           WHEN OTHERS THEN
            V_ACCT_BALANCE := 0;
            V_LEDGER_BAL   := 0;
         END;          
     
     
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE cap_inst_code = prm_inst_code AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
              
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;     
     
     
        BEGIN
        
             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = Prm_TXN_CODE 
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_channel 
              AND   CTM_INST_CODE = prm_inst_code;
              
        EXCEPTION
         WHEN OTHERS THEN
         
         NULL;

        END;
        
      v_timestamp := systimestamp;              -- Added on 19-apr-2013 for defect 10871   
   
     end if;
          
     -----------------------------------------------
     --EN: Added on 19-apr-2013 for defect 10871
     -----------------------------------------------           
      
        ---Sn to log ipaddress,lupduser in transaction log table for successful record. added by amit on 07-Oct-2012 
        BEGIN 
        
        IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user,
                time_stamp = v_timestamp,                                               -- Added on 19-apr-2013 for defect 10871
                productid  = decode(v_flag,0,v_prod_code,productid),                    -- Added on 19-apr-2013 for defect 10871
                categoryid = decode(v_flag,0,v_prod_cattype,categoryid),                -- Added on 19-apr-2013 for defect 10871
                cardstatus = decode(v_flag,0,v_applpan_cardstat,cardstatus),            -- Added on 19-apr-2013 for defect 10871
                customer_acct_no = decode(v_flag,0,v_acct_number,customer_acct_no),     -- Added on 19-apr-2013 for defect 10871
                cr_dr_flag  = decode(v_flag,0,v_dr_cr_flag,cr_dr_flag),                 -- Added on 19-apr-2013 for defect 10871
                acct_type   = decode(v_flag,0,v_cam_type_code,cr_dr_flag),              -- Added on 19-apr-2013 for defect 10871
                acct_balance = decode(v_flag,0,v_acct_balance,acct_balance),            -- Added on 19-apr-2013 for defect 10871
                ledger_balance = decode(v_flag,0,v_ledger_bal,ledger_balance)           -- Added on 19-apr-2013 for defect 10871                
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
            ELSE
             UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = prm_comment,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user,
                time_stamp = v_timestamp,                                               -- Added on 19-apr-2013 for defect 10871
                productid  = decode(v_flag,0,v_prod_code,productid),                    -- Added on 19-apr-2013 for defect 10871
                categoryid = decode(v_flag,0,v_prod_cattype,categoryid),                -- Added on 19-apr-2013 for defect 10871
                cardstatus = decode(v_flag,0,v_applpan_cardstat,cardstatus),            -- Added on 19-apr-2013 for defect 10871
                customer_acct_no = decode(v_flag,0,v_acct_number,customer_acct_no),     -- Added on 19-apr-2013 for defect 10871
                cr_dr_flag  = decode(v_flag,0,v_dr_cr_flag,cr_dr_flag),                 -- Added on 19-apr-2013 for defect 10871
                acct_type   = decode(v_flag,0,v_cam_type_code,cr_dr_flag),              -- Added on 19-apr-2013 for defect 10871
                acct_balance = decode(v_flag,0,v_acct_balance,acct_balance),            -- Added on 19-apr-2013 for defect 10871
                ledger_balance = decode(v_flag,0,v_ledger_bal,ledger_balance)           -- Added on 19-apr-2013 for defect 10871                
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;
         END IF;   

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                     'Txn not updated in transactiolog for ipaddress,lupduser';
            RETURN;
         END IF;
        EXCEPTION         
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while updating transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
        END;
        ---En to log ipaddress,lupduser and remark in transaction log table for successful record.

END;
/

show error;