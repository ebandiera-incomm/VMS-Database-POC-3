create or replace
PROCEDURE               VMSCMS.SP_HOST_PREAUTH_HOLD_RELEASE (
   prm_inst_code       IN       NUMBER,
   prm_business_date   IN       VARCHAR2,
   prm_business_time   IN       VARCHAR2,
   prm_card_no         IN       VARCHAR2,
   prm_mbr_numb        IN       VARCHAR2,
   prm_resp_msg        OUT      VARCHAR2
)
IS
/*********************************************************************************************************
       * Created By      : Deepa T
       * Created Date    : 27-Nov-2012
       * Purpose         : To change the Preauth Hold Rlease as Procedure
       * Modified By     : B.Besky Anand
       * Modified Date   : 09/01/2013
       * Modified Reason : For Performance.
       * Reviewer        : Dhiraj
       * Reviewed Date   : 09/01/2013
       * Release Number  : CMS3.5.1_RI0023_B0011

       * Modified By     : Sagar
       * Modified Date   : 14/02/2013
       * Modified For    : DEFECT 10295
       * Modified Reason : Need to release expired preauth based on sysdate instead of business_Date
       * Reviewer        : Dhiraj
       * Reviewed Date   : NA
       * Release Number  : CMS3.5.1_RI0023.2_B0013
       
       * Modified By     : Deepa T
       * Modified Date   : 26/11/2013
       * Modified For    : MVCSD-4570 
       * Modified Reason : To have Forupdate with wait time specified as the Preauth Hold was done double time for the concurrent transactions
       * Reviewer        : Dhiraj
       * Reviewed Date   : 26/11/2013
       * Release Number  : RI0024.6.1_B0003
       
       * Modified By     : Deepa T
       * Modified Date   : 09/01/2014
       * Modified For    : MVHOST-547
       * Modified Reason : Performance issue
       * Reviewer        : Dhiraj
       * Reviewed Date   : 09/01/2014
       * Release Number  : RI0027_B0003
       
      * Modified by       : Sagar
      * Modified for      : 
      * Modified Reason   : Concurrent Processsing Issue 
                            (1.7.6.7 changes integarted)
      * Modified Date     : 04-Mar-2014
      * Reviewer          : Dhiarj
      * Reviewed Date     : 06-Mar-2014
      * Build Number      : RI0027.1.1_B0001       
      
      * Modified by       : Sagar
      * Modified for      : 
      * Modified Reason   : Commented dynamic execution of query 
                            (RI0024.6.8_B0001  integrated)
      * Modified Date     : 07-Mar-2014
      * Reviewer          : Dhiarj
      * Reviewed Date     : 07-Mar-2014
      * Build Number      : RI0027.1.1_B0002    
      
      * Modified by       :  Dhinakaran B
      * Modified Reason   :  To reset the limit count for expired preauth hold release( Mantis ID 14092 )
      * Modified Date     :  04-APR-2014
      * Reviewer          :   Pankaj S
      * Reviewed Date     :  06-Apr-2014
      * Build Number      :  RI0027.2_B0004  
       
      * Modified by       :  Abdul Hameed M.A
      * Modified Reason   :  To hold the Preauth completion fee at the time of preauth
      * Modified for      :  FSS 837
      * Modified Date     :  27-JUNE-2014
      * Reviewer          : spankaj
      * Build Number      : RI0027.3_B0001  
      
      * Modified by       : Dhinakaran B
      * Modified for      : VISA Certtification Changes integration in 2.3
      * Modified Date     : 08-JUL-2014
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3_B0002
   *********************************************************************************************************/
--Sn Added for MVCSD-4570  
   v_row_id              ROWID;
   v_preauthexpdate      VARCHAR2 (20);
   v_cpt_totalhold_amt   cms_preauth_transaction.cpt_totalhold_amt%TYPE;
   v_cpt_rrn             cms_preauth_transaction.cpt_rrn%TYPE;
   v_cpt_txn_date        cms_preauth_transaction.cpt_txn_date%TYPE;
   v_cpt_txn_time        cms_preauth_transaction.cpt_txn_time%TYPE;
   v_cpt_terminalid      cms_preauth_transaction.cpt_terminalid%TYPE;
   v_cpt_acct_no         cms_preauth_transaction.cpt_acct_no%TYPE;
   v_cpt_card_no         cms_preauth_transaction.cpt_card_no%TYPE;
   v_cardno              cms_preauth_transaction.cpt_card_no_encr%TYPE;
   --TYPE rc IS REF CURSOR;                                             -- commented as same is not required 07-Mar-2014
   --c1                    rc;                                          -- commented as same is not required 07-Mar-2014
   -- v_time1               NUMBER;--Commented by Saravanakumar on 03-Mar-2014 for concurrent Processsing Issue
   --v_query               VARCHAR2 (2000);                             -- commented as same is not required 07-Mar-2014
      --En Added for MVCSD-4570
   v_fee_reversal_flag   transactionlog.fee_reversal_flag%TYPE;
   --v_business_date  DATE;  -- Commented on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
   exp_reject_record     EXCEPTION;
   v_savepoint           NUMBER                                     DEFAULT 1;
   v_resp_cde            transactionlog.response_id%TYPE;
   v_match_rule          cms_preauth_transaction.cpt_match_rule%TYPE; --Added on 04/04/2014 for Mantis ID 14092 
   v_completion_fee      cms_preauth_transaction.cpt_completion_fee%TYPE;--Added for FSS 837
   v_preauth_type     cms_preauth_transaction.cpt_preauth_type%TYPE;--added for mvhost 926
    
       --CURSOR c1(business_date DATE) -- Commented on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
   --/*CURSOR c1                       -- Added on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
   
   -------------------------------------------------------------------
   --SN : Uncommented below query as dynamic execution is not required
   -------------------------------------------------------------------
   
   CURSOR c1
   IS
   SELECT ROWID ROW_ID,TO_CHAR (cpt_expiry_date, 'dd/mm/yyyy hh24:mi:ss') AS preauthexpdate, --Added Rowid by Besky on 09/01/2013 for Performance.
       cpt_totalhold_amt, cpt_rrn,
       cpt_txn_date , cpt_txn_time ,
       cpt_terminalid , cpt_acct_no ,
       cpt_card_no ,fn_dmaps_main(cpt_card_no_encr) cardno,cpt_match_rule --Modified on 04/04/2014 for Mantis ID 14092 
       ,cpt_completion_fee--Added for FSS 837
       ,cpt_preauth_type 
  FROM cms_preauth_transaction
 WHERE cpt_acct_no =
          (SELECT cap_acct_no
             FROM cms_appl_pan
            WHERE cap_pan_code = prm_card_no AND cap_inst_code = prm_inst_code)
   AND cpt_expiry_flag = 'N'
   AND CPT_PREAUTH_VALIDFLAG='Y'
   AND CPT_COMPLETION_FLAG='N'
   AND cpt_inst_code = prm_inst_code
   --AND cpt_expiry_date <= v_business_date -- Commented on 14-Feb-2013 for DEFECT-10295 , need to release expiry preauth based on sysdate instead of business_Date
   AND cpt_expiry_date <= sysdate           -- Added on 14-Feb-2013 for DEFECT-10295 , need to release expiry preauth based on sysdate instead of business_Date
   AND cpt_totalhold_amt > 0 
   for update;
   
   -------------------------------------------------------------------
   --EN : Uncommented below query as dynamic execution is not required
   -------------------------------------------------------------------
      
   
   --*/ --Commented for MVCSD-4570
   

BEGIN
   -- << MAIN BEGIN>>
   prm_resp_msg := 'OK';
   SAVEPOINT v_savepoint;
   v_resp_cde := '1';

   /*       -- Commented on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
    BEGIN
     v_business_date := TO_DATE(SUBSTR(TRIM(prm_business_date), 1, 8) || ' ' ||
                        SUBSTR(TRIM(prm_business_time), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_resp_cde := '32'; -- Server Declined -220509
       prm_resp_msg  := 'Problem while converting transaction time ' ||
                  SUBSTR(SQLERRM, 1, 200);
       --RAISE EXP_REJECT_RECORD;
    END;
   */
  --Sn Commented by Saravanakumar on 03-Mar-2014 for concurrent Processsing Issue
  /*   
   --Sn Added for MVCSD-4570
   BEGIN
      SELECT TO_NUMBER (cip_param_value)
        INTO v_time1
        FROM cms_inst_param
       WHERE cip_inst_code = prm_inst_code AND cip_param_key = 'WAIT_PARAM';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '69';
         prm_resp_msg :=
               'Wait Parameter not defined for institution code '
            || prm_inst_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         prm_resp_msg :=
               'Error while selecting wait parameter '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;
   */
--En Commented by Saravanakumar on 03-Mar-2014 for concurrent Processsing Issue

   BEGIN
   
     /* v_query :=
            'SELECT ROWID row_id,
             TO_CHAR (cpt_expiry_date,
                      ''dd/mm/yyyy hh24:mi:ss''
                     ) AS preauthexpdate,
                        
             cpt_totalhold_amt, cpt_rrn, cpt_txn_date, cpt_txn_time,
             cpt_terminalid, cpt_acct_no, cpt_card_no,
             fn_dmaps_main (cpt_card_no_encr) cardno
        FROM cms_preauth_transaction
       WHERE cpt_acct_no =
                (SELECT cap_acct_no
                   FROM cms_appl_pan
                  WHERE cap_pan_code = '
         || ''''
         || prm_card_no
         || ''''
         || ' 
                     AND cap_inst_code = '
         || ''''
         || prm_inst_code
         || ''''
         || ')
         AND cpt_expiry_flag = ''N''
         AND cpt_preauth_validflag = ''Y''
         AND cpt_completion_flag = ''N''
         AND cpt_inst_code = '
         || ''''
         || prm_inst_code
         || ''''
         || ' AND cpt_expiry_date <=
                SYSDATE
         AND cpt_totalhold_amt > 0 For UPDATE wait '
         || v_time1; */     
         
      --Above query commented and this query added for the Performance issue - MVHOST-547 by Deepa T on 9th Jan 2014   
      
    /* -- Commented dynamic execution as same is not required since wait time is not used - 07-Mar-2014          
       v_query :=
            '  SELECT a.ROWID row_id,
        TO_CHAR (cpt_expiry_date, ''dd/mm/yyyy hh24:mi:ss'') AS preauthexpdate,
        cpt_totalhold_amt, cpt_rrn, cpt_txn_date, cpt_txn_time, cpt_terminalid,
        cpt_acct_no, cpt_card_no, fn_dmaps_main (cpt_card_no_encr) cardno
        FROM cms_preauth_transaction a, cms_appl_pan b
        WHERE cpt_inst_code = cap_inst_code
    AND cpt_acct_no = b.cap_acct_no
    AND cpt_card_no = b.cap_pan_code
    AND cpt_expiry_flag = ''N''
    AND cpt_preauth_validflag = ''Y''
    AND cpt_completion_flag = ''N''
    AND cpt_expiry_date <= SYSDATE
    AND cpt_totalhold_amt > 0
    AND cap_inst_code = '
         || ''''
         || prm_inst_code
         || ''''
         || '
    AND cap_pan_code = '
         || ''''
         || prm_card_no
         || ''''
         || ' For UPDATE ';
         --|| v_time1;          --Commented by Saravanakumar on 03-Mar-2014 for concurrent Processsing Issue
    */ -- Commented dynamic execution as same is not required since wait time is not used - 07-Mar-2014         

      --FOR i1 IN c1(v_business_date) -- Commented on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
      --OPEN c1 FOR v_query;          -- Commented dynamic execution as same is not required since wait time is not used - 07-Mar-2014

      OPEN c1;
      LOOP
         FETCH c1
          INTO v_row_id, v_preauthexpdate, v_cpt_totalhold_amt, v_cpt_rrn,
               v_cpt_txn_date, v_cpt_txn_time, v_cpt_terminalid,
               v_cpt_acct_no, v_cpt_card_no, v_cardno,v_match_rule,v_completion_fee,v_preauth_type; --Modified on 04/04/2014 for Mantis ID 14092 
         
         EXIT WHEN c1%NOTFOUND;
         --En Added for MVCSD-4570
         -- end loop;

         -- Added on 14-Feb-2013 for FSS-781 , need to release expiry preauth based on sysdate instead of business_Date
         --LOOP
         v_savepoint := v_savepoint + 1;

         BEGIN
            BEGIN
             IF(v_preauth_type!='C') THEN 
               UPDATE cms_acct_mast
                 -- SET cam_acct_bal = cam_acct_bal + v_cpt_totalhold_amt
                  SET cam_acct_bal = cam_acct_bal + v_cpt_totalhold_amt+v_completion_fee --Modified for FSS 837
                WHERE cam_acct_no = v_cpt_acct_no
                  AND cam_inst_code = prm_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  prm_resp_msg :=
                          'No rows updated in cms_acct_mast for Hold Release';
                  RAISE exp_reject_record;
               END IF;
            END IF;   
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  prm_resp_msg :=
                        'Error while updating acct mast-Hold Release'
                     || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;

            BEGIN
               UPDATE cms_preauth_transaction
                  --Added  by Besky on 09/01/2013 for Performance.
               SET cpt_expiry_flag = 'Y',
                   cpt_exp_release_amount = v_cpt_totalhold_amt,
                   cpt_totalhold_amt = '0',
                   cpt_completion_fee=0 --Added for FSS 837
                WHERE ROWID = v_row_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  prm_resp_msg :=
                     'No rows updated in cms_preauth_transaction for Hold Release';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  prm_resp_msg :=
                        'Error while updating expired Preauth'
                     || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               ROLLBACK TO v_savepoint;
            WHEN OTHERS
            THEN
               ROLLBACK TO v_savepoint;
         END;

         BEGIN
            sp_log_preauth_holdrelease (prm_inst_code,
                                        '05',
                                        '24',
                                        prm_card_no,
                                        v_cardno,
                                        v_cpt_totalhold_amt,
                                        v_resp_cde,
                                        prm_resp_msg,
                                        v_cpt_rrn,
                                        v_cpt_txn_date,
                                        v_cpt_txn_time,
                                        v_cpt_card_no,
                                        v_cpt_terminalid,
                                        prm_mbr_numb,
                                        v_cpt_acct_no,
                                        v_match_rule,--Modified on 04/04/2014 for Mantis ID 14092 
                                        prm_resp_msg,
                                        v_completion_fee --Added for FSS 837
                                        ,v_preauth_type
                                       );
            BEGIN
            
            IF prm_resp_msg <> 'OK'
            THEN
               INSERT INTO cms_sopfailure_dtl
                           (csd_card_no, csd_rrn, csd_mbr_no,
                            csd_inst_code, csd_hold_amount,
                            csd_expiry_date, csd_preauthtxn_date,
                            csd_error_msg
                           )
                    VALUES (v_cpt_card_no, v_cpt_rrn, prm_mbr_numb,
                            prm_inst_code, v_cpt_totalhold_amt,
                            v_preauthexpdate, v_cpt_txn_date,
                            prm_resp_msg
                           );
            END IF;
            EXCEPTION
                WHEN OTHERS
                THEN         
                prm_resp_msg :=
               'Error in inserting the failure details '
                || SUBSTR (SQLERRM, 1, 100);
         
            END;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN         
         prm_resp_msg :=
               'Error in releasing the Expired Preauth Hold '
            || SUBSTR (SQLERRM, 1, 100);
         
   END;

         COMMIT;   

END;
/
SHOW ERROR