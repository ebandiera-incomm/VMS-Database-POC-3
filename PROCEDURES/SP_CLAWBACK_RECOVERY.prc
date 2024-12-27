CREATE OR REPLACE PROCEDURE VMSCMS.SP_CLAWBACK_RECOVERY (
   prm_inst_code       IN       NUMBER,
   prm_card_no         IN       VARCHAR2,
   prm_mbr_numb        IN       VARCHAR2,
   prm_resp_msg        OUT      VARCHAR2
   
)
IS
  V_ACCT_BALANCE           cms_acct_mast.cam_acct_bal%TYPE;
   V_LEDGER_BALANCE         cms_acct_mast.cam_ledger_bal%TYPE;
   V_old_ACCT_BALANCE           cms_acct_mast.cam_acct_bal%TYPE;
   V_old_LEDGER_BALANCE         cms_acct_mast.cam_ledger_bal%TYPE;
   V_CARD_ACCT_NO       cms_acct_mast.cam_acct_no%TYPE;
   V_cam_type_code       cms_acct_mast.cam_type_code%TYPE;
    v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_clawback_amount    cms_acct_mast.cam_acct_bal%TYPE;
   v_narration          VARCHAR2 (300);
   v_rrn                VARCHAR2 (15);
   v_auth_id            transactionlog.auth_id%TYPE;
   v_errmsg             VARCHAR2 (300)                            := 'OK';
   exp_reject           EXCEPTION;
   v_pending_amnt       NUMBER (20, 3);
   v_cardno_fourdigit   VARCHAR2 (4);
   v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   v_business_date      VARCHAR2 (8);
   v_card_no            VARCHAR2 (19);
   v_card_curr          transactionlog.currencycode%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_clawback_rrn       NUMBER (20);
   --Sn added by Pankaj S. for 10871
   v_timestamp          TIMESTAMP ( 3 );
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
    v_clawback_flag     Varchar2(1) default 'N';
   --En added by Pankaj S. for 10871
    v_savepoint           NUMBER                                     DEFAULT 1;
   v_business_time      transactionlog.business_time%type; -- Added on 19-Feb-2014 
   v_error_flag  Varchar2(1) default 'N';
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
/*********************************************************************************************************
       * Created By      : Mageshkumar S 
       * Created Date    : 10-Mar-2014
       * Purpose         : To change Clawback recovery as Procedure
       * Reviewer        : Dhiraj
       * Reviewed Date   : 10-Mar-2014
       * Release Number  : RI0024.6.8_B0004
       
       
     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     : 
     * Modified Reason  : Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_ACCT_MAST,CMS_STATEMENTS_LOG.
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 06-APR-2014
     * Build Number     : CMS3.5.1_RI0027.2_B0004
       
     * Modified by      : MageshKumar S
       * Modified Date    : 08-Feb-2016
       * PURPOSE          : DFCTNM-108
       * Review           : Saravana
       * Build Number     : 3.2.4
       
       * Modified by      : Pankaj S.
       * Modified Date    : 09-Feb-2017
       * PURPOSE          : FSS-4366
       * Review           : Saravana
       * Build Number     : 17.02
       
       * Modified by      : Pankaj S.
       * Modified Date    : 11-Apr-2017
       * Purpose          : FSS-5118
       * Review           : Saravanan
       * Build Number     : 17.04
       
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
	
	    * Modified By      : Saravana Kumar A
    * Modified Date    : 09/03/2017
    * Purpose          : FSS-5224
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.08.B0002
   *********************************************************************************************************/
Begin
prm_resp_msg:='OK';
 
 BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO, cam_type_code
                                             
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE, V_CARD_ACCT_NO, V_cam_type_code
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = prm_card_no AND CAP_MBR_NUMB = prm_mbr_numb AND
                 CAP_INST_CODE = prm_inst_code) AND
           CAM_INST_CODE = prm_inst_code
           for update;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      
       prm_resp_msg  := 'Invalid Card ';
       
     WHEN OTHERS THEN
       prm_resp_msg := 'Invalid Card err';
    
    END;
IF V_ACCT_BALANCE > 0 Then 
 FOR i IN (SELECT   cad_clawback_amnt, cad_delivery_channel, cad_txn_code,  cad_pan_code
                 FROM cms_acctclawback_dtl
                WHERE cad_acct_no = V_CARD_ACCT_NO
                  AND cad_inst_code = prm_inst_code
                  AND cad_recovery_flag = 'N'
                  AND cad_clawback_amnt > 0
             ORDER BY cad_clawback_amnt)
   LOOP
      FOR j IN (SELECT   ccd_clawback_amnt, ccd_pan_code, ccd_gl_acct_no,
                         ccd_pan_code_encr, ccd_rrn, ccd_calc_date,
                         ccd_feeattachtype, ccd_fee_plan, ccd_fee_code, ccd_process_id
                    FROM cms_charge_dtl
                   WHERE ccd_file_status = 'C'
                     AND ccd_clawback = 'Y'
                     AND ccd_inst_code = prm_inst_code
                     AND ccd_acct_no = V_CARD_ACCT_NO
                     AND ccd_pan_code = i.cad_pan_code  --Added for FSS-5118
                     AND ccd_delivery_channel = i.cad_delivery_channel
                     AND ccd_txn_code = i.cad_txn_code
                ORDER BY ccd_clawback_amnt)
      LOOP
         v_timestamp := SYSTIMESTAMP;          --added by Pankaj S. for 10871
          savepoint v_savepoint;
        Begin
       -- DBMS_OUTPUT.PUT_LINE('ccd_rrn = ' || j.ccd_rrn);
      
       
         IF V_ACCT_BALANCE > 0 AND j.ccd_clawback_amnt > 0
         THEN
            v_clawback_flag := 'Y';
            v_acct_bal := V_LEDGER_BALANCE;
           --cam_acct_bal replaced by Pankaj S. with cam_ledger_bal for 10871
          V_OLD_ACCT_BALANCE:=V_ACCT_BALANCE;
          V_OLD_LEDGER_BALANCE:=V_LEDGER_BALANCE;
            IF V_ACCT_BALANCE >= j.ccd_clawback_amnt 
             
            THEN
            --DBMS_OUTPUT.PUT_LINE('V_ACCT_BALANCE = ' || V_ACCT_BALANCE);
               V_ACCT_BALANCE := V_ACCT_BALANCE - j.ccd_clawback_amnt;
               V_LEDGER_BALANCE :=
                                    V_LEDGER_BALANCE - j.ccd_clawback_amnt;
               v_clawback_amount := j.ccd_clawback_amnt;
            ELSE
               V_LEDGER_BALANCE := V_LEDGER_BALANCE - V_ACCT_BALANCE;
               v_clawback_amount := V_ACCT_BALANCE;
               V_ACCT_BALANCE := 0;
            END IF;
        --  DBMS_OUTPUT.PUT_LINE('V_ACCT_BALANCE = ' || V_ACCT_BALANCE);
            BEGIN
               SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                      TO_CHAR (SYSDATE, 'YYYYMMDD'),
                      TO_CHAR (SYSDATE, 'hh24miss')
                 INTO v_auth_id,
                      v_business_date,
                      v_business_time                -- Added on 19-Feb-2014
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while generating authid '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

 /* Commented for Jira FSS-5224 			
             BEGIN
                SELECT csl_trans_narrration, csl_panno_last4digit
                 INTO v_narration, v_cardno_fourdigit
                 FROM cms_statements_log
                WHERE csl_pan_no = j.ccd_pan_code
                  AND csl_rrn = j.ccd_rrn
                  AND csl_inst_code = prm_inst_code
                  AND csl_acct_no = V_CARD_ACCT_NO;
            EXCEPTION
               WHEN NO_DATA_FOUND
               then */
               
              --Start Added for DFCTNM-108 on 08/02/16 (3.2.4)
               BEGIN
                     SELECT CFM_FEE_DESC
                         INTO v_narration
                         FROM CMS_FEE_MAST
                         WHERE CFM_INST_CODE=prm_inst_code AND
                         CFM_FEE_CODE=j.ccd_fee_code;
                         
                         V_CARD_NO := FN_DMAPS_MAIN (J.CCD_PAN_CODE_ENCR);
                         v_cardno_fourdigit :=SUBSTR (v_card_no,
                          LENGTH (v_card_no) - 3,
                          LENGTH (v_card_no)
                         );
                         
                     EXCEPTION
                         WHEN NO_DATA_FOUND
                          THEN
                          v_errmsg := 'Not found Fee Descriiption';
                         RAISE exp_reject;
                         WHEN OTHERS
                         THEN
                        v_errmsg := 'While getting Fee Descriiption Details' || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject;
              end;
              --End Added for DFCTNM-108 on 08/02/16 (3.2.4)
              
               /* --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                  BEGIN
                     SELECT ctm_tran_desc
                       INTO v_tran_desc
                       FROM cms_transaction_mast
                      WHERE ctm_tran_code = i.cad_txn_code
                        AND ctm_delivery_channel = i.cad_delivery_channel
                        AND ctm_inst_code = prm_inst_code;
                 
                  IF TRIM (v_tran_desc) IS NOT NULL
                     THEN
                        v_narration := v_tran_desc || '/';
                     END IF;

                     IF TRIM (v_auth_id) IS NOT NULL
                     THEN
                        v_narration := v_narration || v_auth_id || '/';
                     END IF;

                     IF TRIM (V_CARD_ACCT_NO) IS NOT NULL
                     THEN
                        v_narration := v_narration || V_CARD_ACCT_NO || '/';
                     END IF;

                     IF TRIM (v_business_date) IS NOT NULL
                     THEN
                        v_narration := v_narration || v_business_date;
                     END IF;
                     
                                       
                     v_card_no := fn_dmaps_main (j.ccd_pan_code_encr);
                     v_cardno_fourdigit :=
                        SUBSTR (v_card_no,
                                LENGTH (v_card_no) - 3,
                                LENGTH (v_card_no)
                               );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while narration creation'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject;
                  end;
                */

/* Commented for Jira FSS-5224  	
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in narration selection'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;
*/

            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat
                 INTO v_prod_code, v_card_type, v_card_stat
                 FROM cms_appl_pan
                WHERE cap_pan_code = j.ccd_pan_code
                  AND cap_inst_code = prm_inst_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Card Details Not Found';
                  RAISE exp_reject;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'While getting card details' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;
            
            --Start-Added on 04/02/14 for regarding MVCSD-4471
          /*  BEGIN
                           SELECT CFM_FEE_DESC 
                               INTO v_narration
                               FROM CMS_FEE_MAST
                               WHERE CFM_INST_CODE=prm_inst_code AND
                               CFM_FEE_CODE=j.ccd_fee_code; 
                           EXCEPTION
                               WHEN NO_DATA_FOUND
                                THEN
                                v_errmsg := 'Not found Fee Descriiption';
                               RAISE exp_reject;
                               WHEN OTHERS
                               THEN
                              v_errmsg := 'While getting Fee Descriiption Details' || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject;
                    END;*/
            --END-Added on 04/02/14 for regarding MVCSD-4471
            SELECT seq_clawback_rrn.NEXTVAL
              INTO v_clawback_rrn
              FROM DUAL;

            v_rrn := 'CBK' || v_business_date || v_clawback_rrn;
            v_pending_amnt := j.ccd_clawback_amnt - v_clawback_amount;

            IF i.cad_delivery_channel = '05' AND i.cad_txn_code = '16'
            THEN
              v_narration := v_narration || TO_CHAR (TO_DATE (j.ccd_process_id, 'MM'),' - '|| 'MONTH');
            END IF;

            BEGIN
           
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_acct_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date, csl_closing_balance,
                            csl_trans_narrration, csl_pan_no_encr,
                            csl_rrn, csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_inst_code,
                            csl_txn_code, csl_ins_date, csl_ins_user,
                            csl_panno_last4digit, 
                            csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp      --added by Pankaj S. for 10871
                           )
                    VALUES (j.ccd_pan_code, V_CARD_ACCT_NO, ROUND(v_acct_bal,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            ROUND(v_clawback_amount,2), 'DR',--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            SYSDATE, ROUND(v_acct_bal - v_clawback_amount,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            'CLAWBACK-' || v_narration, j.ccd_pan_code_encr,
                            v_rrn, v_auth_id, v_business_date,
                            --TO_CHAR (SYSDATE, 'hh24miss')                 -- Commented on 19-Feb-2014
                            v_business_time,                                 -- Added on 19-Feb-2014
                            'Y',
                            i.cad_delivery_channel, prm_inst_code,
                            i.cad_txn_code, SYSDATE, 1,
                            v_cardno_fourdigit, 
                            v_prod_code,v_card_type,V_cam_type_code,v_timestamp         --added by Pankaj S. for 10871
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error creating entry in statement log '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;
    
            BEGIN
               INSERT INTO cms_eodupdate_acct
                           (ceu_rrn, ceu_terminal_id, ceu_delivery_channel,
                            ceu_txn_code, ceu_txn_mode, ceu_tran_date,
                            ceu_customer_card_no, ceu_upd_acctno,
                            ceu_upd_amount, ceu_upd_flag, ceu_process_flag,
                            ceu_process_msg, ceu_inst_code,
                            ceu_customer_card_no_encr
                           )
                    VALUES (v_rrn, NULL, i.cad_delivery_channel,
                            i.cad_txn_code, '0', SYSDATE,
                            j.ccd_pan_code, j.ccd_gl_acct_no,
                            v_clawback_amount, 'C', 'N',
                            NULL, prm_inst_code,
                            j.ccd_pan_code_encr
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg := 'Error while inseting GL details';
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in GL details insertion'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               UPDATE cms_charge_dtl
                  SET ccd_file_status = DECODE (v_pending_amnt, 0, 'Y', 'C'),
                      ccd_clawback_amnt = ROUND(v_pending_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      ccd_clawback = DECODE (v_pending_amnt, 0, 'N', 'Y'),
                      ccd_debited_amnt = ROUND(ccd_debited_amnt + v_clawback_amount,2)--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                WHERE ccd_file_status = 'C'
                  AND ccd_clawback = 'Y'
                  AND ccd_inst_code = prm_inst_code
                  AND ccd_acct_no = V_CARD_ACCT_NO
                  AND ccd_rrn = j.ccd_rrn
                  AND ccd_pan_code = j.ccd_pan_code
                  AND ccd_calc_date = j.ccd_calc_date
                  AND ccd_delivery_channel = i.cad_delivery_channel
                  AND ccd_txn_code = i.cad_txn_code;

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while updating cms_charge_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;

               UPDATE cms_acctclawback_dtl
                  SET cad_clawback_amnt =
                                        ROUND( cad_clawback_amnt - v_clawback_amount,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      cad_recovery_flag =
                         DECODE (cad_clawback_amnt - v_clawback_amount,
                                 0, 'Y',
                                 'N'
                                )
                WHERE cad_delivery_channel = i.cad_delivery_channel
                  AND cad_txn_code = i.cad_txn_code
                  AND cad_acct_no = V_CARD_ACCT_NO
                  AND cad_pan_code =  j.ccd_pan_code  --Added for FSS-5118
                  AND cad_inst_code = prm_inst_code
                  AND cad_recovery_flag = 'N';

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while updating cms_acctclawback_dtl and cms_acctclawback_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  --RAISE exp_reject;
               END IF;
            EXCEPTION
                WHEN exp_reject THEN
                    RAISE exp_reject;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in updating cms_charge_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
--               SELECT TRIM (cbp_param_value)
--                 INTO v_card_curr
--                 FROM cms_appl_pan, cms_bin_param, cms_prod_mast
--                WHERE cap_inst_code = cbp_inst_code
--                  AND cpm_inst_code = cbp_inst_code
--                  AND cap_prod_code = cpm_prod_code
--                  AND cpm_profile_code = cbp_profile_code
--                  AND cbp_param_name = 'Currency'
--                  AND cap_pan_code = j.ccd_pan_code;

      vmsfunutilities.get_currency_code(v_prod_code,v_card_type,prm_inst_code,v_card_curr,v_errmsg);
      
      if v_errmsg<>'OK' then
           raise exp_reject;
      end if;
      
            EXCEPTION
              when exp_reject then
                  raise;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in selecting card Currency'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

          
            BEGIN
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, date_time,
                            txn_code, txn_type, txn_status, response_code,
                            business_date, business_time,
                            customer_card_no, bank_code,
                            total_amount,
                            auth_id, trans_desc, instcode,
                            customer_card_no_encr, customer_acct_no,
                            acct_balance,
                            ledger_balance,
                            response_id, txn_mode,
                            tranfee_amt,
                            feeattachtype, fee_plan,
                            feecode, tranfee_cr_acctno,
                            tranfee_dr_acctno, currencycode, cardstatus,
                            clawback_indicator,
                            productid,categoryid,acct_type,time_stamp  --added by Pankaj S. for 10871
                           )
                    VALUES ('0200', v_rrn, i.cad_delivery_channel, SYSDATE,
                            i.cad_txn_code, '1', 'C', '00',
                            v_business_date, 
                            --TO_CHAR (SYSDATE, 'hh24miss')                 -- Commented on 19-Feb-2014
                            v_business_time,                                -- Added on 19-Feb-2014
                            j.ccd_pan_code, prm_inst_code,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '999999999999999990.99'  --Formatted for 10871
                                          )
                                 ),
                            v_auth_id, 
                            --v_tran_desc,                          -- Commented on 19-Feb-2014
                            substr('CLAWBACK-' || v_narration,1,50),             -- added on 19-Feb-2014
                            prm_inst_code,
                            j.ccd_pan_code_encr, V_CARD_ACCT_NO,
                            TRIM (TO_CHAR (V_ACCT_BALANCE,
                                           '99999999999999999.99'
                                          )
                                 ),
                            TRIM (TO_CHAR (V_LEDGER_BALANCE,
                                           '99999999999999999.99'
                                          )
                                 ),
                            1, 0,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '999999999999999990.99'   --Formatted for 10871
                                          )
                                 ),
                            j.ccd_feeattachtype, j.ccd_fee_plan,
                            j.ccd_fee_code, j.ccd_gl_acct_no,
                            V_CARD_ACCT_NO, v_card_curr, v_card_stat,
                            'Y',
                            v_prod_code,v_card_type,V_cam_type_code,v_timestamp  --added by Pankaj S. for 10871
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while inserting details in transactionlog'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in inserting transactionlog'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               INSERT INTO cms_transaction_log_dtl
                           (ctd_delivery_channel, ctd_txn_code,
                            ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                            ctd_business_date, ctd_business_time,
                            ctd_customer_card_no,
                            ctd_fee_amount,
                            ctd_process_flag, ctd_process_msg, ctd_rrn,
                            ctd_inst_code, ctd_customer_card_no_encr,
                            ctd_cust_acct_number, ctd_txn_curr
                           )
                    VALUES (i.cad_delivery_channel, i.cad_txn_code,
                            '1', '0200', 0,
                            v_business_date, 
                            --TO_CHAR (SYSDATE, 'hh24miss')                 -- Commented on 19-Feb-2014
                            v_business_time,                                -- Added on 19-Feb-2014
                            j.ccd_pan_code,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '99999999999999999.99'
                                          )
                                 ),
                            'Y', 'Successful', v_rrn,
                            prm_inst_code, j.ccd_pan_code_encr,
                            V_CARD_ACCT_NO, v_card_curr
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while inserting details in cms_transaction_log_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in inserting cms_transaction_log_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;
            Begin
              UPDATE CMS_ACCT_MAST SET CAM_ACCT_BAL =ROUND(V_ACCT_BALANCE,2), CAM_LEDGER_BAL = ROUND(V_LEDGER_BALANCE,2) --Modified by Revathi on 02-APR-2014 for 3decimal place issue
              WHERE CAM_ACCT_NO = V_CARD_ACCT_NO and 
              CAM_INST_CODE = prm_inst_code;
           
              IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                        'Error while updating acct master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;
            Exception
              When others then 
              v_errmsg :=
                                  'Error in updating CMS_ACCT_MAST'
                               || SUBSTR (SQLERRM, 1, 200);
              End;
      
         END IF;
          EXCEPTION
      when exp_reject then 
          V_ACCT_BALANCE:=V_old_ACCT_BALANCE;
          V_LEDGER_BALANCE:=V_old_LEDGER_BALANCE;
           --DBMS_OUTPUT.PUT_LINE('V_ACCT_BALANCE = ' || V_ACCT_BALANCE);
             ROLLBACK TO savepoint  v_savepoint;
       when OTHERS THEN
       V_ACCT_BALANCE:=V_old_ACCT_BALANCE;
          V_LEDGER_BALANCE:=V_old_LEDGER_BALANCE;
        v_errmsg :=   'Error in updating CMS_ACCT_MAST';
               ROLLBACK TO savepoint  v_savepoint;
         END;
         
         Begin
         if v_errmsg <>'OK' THEN
          v_error_flag := 'Y';
               INSERT INTO cms_sopfailure_dtl
                           (csd_card_no, csd_rrn, csd_mbr_no,
                            csd_inst_code,
                            csd_error_msg,CSD_CLAWBACK_AMNT,CSD_ERRLOG_TYPE
                           )
                    VALUES ( j.ccd_pan_code, j.ccd_rrn, prm_mbr_numb,
                            prm_inst_code
                            ,v_errmsg,j.ccd_CLAWBACK_AMNT,'C'
                           );
            END IF;
            EXCEPTION
                WHEN OTHERS
                THEN         
                prm_resp_msg :=
               'Error in inserting the failure details '
                || SUBSTR (SQLERRM, 1, 100);
         
            END;
     
      END LOOP;
     
   END LOOP;
    
END if;
if(v_error_flag='Y') then
v_errmsg:='Executed with Error';
end if;
prm_resp_msg:=v_errmsg;
Commit;
Exception 
when exp_reject then 
prm_resp_msg:='OK';
when Others then 
prm_resp_msg:='Main Error'   || SUBSTR (SQLERRM, 1, 100);
END;

/

show error;