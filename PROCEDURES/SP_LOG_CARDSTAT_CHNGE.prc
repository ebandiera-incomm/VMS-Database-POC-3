CREATE OR REPLACE PROCEDURE VMSCMS.sp_log_cardstat_chnge (
   p_inst_code             IN       NUMBER,
   p_hash_pan              IN       VARCHAR2,
   p_encr_pan              IN       RAW,
   p_auth_id               IN       VARCHAR2,
   p_txn_code              IN       VARCHAR2,
   p_orgnl_rrn             IN       VARCHAR2,
   p_orgnl_business_date   IN       VARCHAR2,
   p_orgnl_business_time   IN       VARCHAR2,
   p_resp_code             OUT      VARCHAR2,
   p_errmsg                OUT      VARCHAR2,
   P_remark                IN       VARCHAR2  DEFAULT NULL,
   P_reason_code_in        IN       VARCHAR2  DEFAULT NULL,
   P_reason_in             IN       VARCHAR2  DEFAULT NULL
)
AS
   /**************************************************************************
     * Created Date                 : 15_Mar_2013
     * Created By                   : Pankaj S.
     * Purpose                      : Logging of system initiated card status change(FSS-390)
     * Modified Date                : 27/03/2013
     * Release Number               : CSR3.5.1_RI0024_B0007

     * Modified By                  : Ramesh.A
     * Modified For                 : Defect 0010719
     * Purpose                      : To log card status details transaction_log_dtl table.
     * Reviewer                     : Dhiraj
     * Reviewed Date                :
     * Release Number               : CMS3.5.1_RI0024_B0011

     * Modified By                  : Pankaj S.
     * Modified For                 : Defect 10720
     * Purpose                      : To Handled duplicate RRN
     * Reviewer                     : Dhiraj
     * Reviewed Date                :
     * Release Number               : CMS3.5.1_RI0024_B0016

     * Modified By                  : Pankaj S.
     * Modified For                : JH-3019
     * Purpose                       : To mark remark for purge proxy
     * Release Number           : CMS3.5.1_RI0027.3.2_B0003
	 
	 * Modified By                   : Baskar K.
     * Modified For                  : VMS-412
     * Purpose                       : Consumed Flag Status Update
     * Release Number                : R03 - B0003
     **************************************************************************/
   v_txn_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
   v_card_stat        cms_appl_pan.cap_card_stat%TYPE;
   v_acct_no          cms_acct_mast.cam_acct_no%TYPE;
   v_acct_balance     cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance   cms_acct_mast.cam_ledger_bal%TYPE;
   v_prod_code   cms_appl_pan.cap_prod_code%TYPE;
   v_card_type   cms_appl_pan.cap_card_type%TYPE;
   v_rrn              VARCHAR2 (20);        --Added by Ramesh.A on 27/03/2013
   
BEGIN
   p_errmsg := 'OK';
   p_resp_code := '00';
   
   --Sn added for  defect ID 10720
   BEGIN
      SELECT    TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')|| seq_passivestatupd_rrn.NEXTVAL
        INTO v_rrn
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg := 'Error while getting RRN ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;
   --En added for  defect ID 10720

   --v_rrn := TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS');
   BEGIN
       SELECT cap_acct_no, cap_card_stat,cap_prod_code,cap_card_type
        INTO v_acct_no, v_card_stat,v_prod_code,v_card_type
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = p_hash_pan;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
            'Error while selecting Card details-' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal
        INTO v_acct_balance, v_ledger_balance
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_no AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';
         p_errmsg := 'Invalid Card ';
         RETURN;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
            'Error while selecting acct details-' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      SELECT ctm_tran_desc
        INTO v_txn_desc
        FROM cms_transaction_mast
       WHERE ctm_inst_code = p_inst_code
         AND ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = '05';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';
         p_errmsg := 'Txn not defined for txn_code-' || p_txn_code;
         RETURN;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
             'Error while selecting txn details-' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

--  dbms_out.put_line(TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISSFF3'));
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, txn_code, trans_desc,
                   customer_card_no, customer_card_no_encr, business_date,
                   business_time, txn_status, response_code, auth_id,
                   instcode, add_ins_date, response_id, orgnl_rrn,
                   orgnl_business_date, orgnl_business_time, date_time,
                   customer_acct_no, acct_balance, ledger_balance, cardstatus,
                   remark,   --Added for JH-3019
                   reason_code,reason,productid,categoryid
                  )
           VALUES ('0200', v_rrn, '05', p_txn_code, v_txn_desc,
                   p_hash_pan, p_encr_pan, TO_CHAR (SYSDATE, 'yyyymmdd'),
                   TO_CHAR (SYSDATE, 'hh24miss'), 'C', '00', p_auth_id,
                   p_inst_code, SYSDATE, '1', p_orgnl_rrn,
                   p_orgnl_business_date, p_orgnl_business_time, SYSDATE,
                   v_acct_no, v_acct_balance, v_ledger_balance, v_card_stat,
                   decode(p_auth_id,'PRGE','Card has been removed from store inventory and cannot be issued',P_remark),  --Added for JH-3019
                   P_reason_code_in,P_reason_in,v_prod_code,v_card_type
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Error while logging system initiated card status change '
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   --Added by Ramesh.A on 27/03/2013
   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_msg_type, ctd_txn_mode, ctd_business_date,
                   ctd_business_time, ctd_customer_card_no,
                   ctd_process_flag, ctd_process_msg, ctd_rrn,
                   ctd_inst_code, ctd_customer_card_no_encr,
                   ctd_cust_acct_number
                  )
           VALUES ('05', p_txn_code, '0',
                   '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'hh24miss'), p_hash_pan,
                   'Y', 'Successful', v_rrn,
                   p_inst_code, p_encr_pan,
                   v_acct_no
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error in inserting cms_transaction_log_dtl'
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RETURN;
   END;
--End
EXCEPTION
   WHEN OTHERS
   THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERRORS;


