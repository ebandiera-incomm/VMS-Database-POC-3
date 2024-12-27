create or replace PACKAGE BODY  VMSCMS.PKG_DAILY_JOBS 
AS
   PROCEDURE pr_eod_passiveperiod_calc (
      p_inst_code   IN       NUMBER,
      p_resp_msg    OUT      VARCHAR2
   )
   is
     -- v_passive_days         cms_prod_cattype.cpc_passive_time%TYPE     := 90;
      v_resp_code            cms_passiveperiod_fail_dtl.cpd_resp_code%TYPE
                                                                    DEFAULT 1;
      exp_reject_passive     EXCEPTION;
      v_last_tran_date       transactionlog.business_date%TYPE;
      v_last_tran_time       transactionlog.business_time%TYPE;
      v_rrn                  transactionlog.rrn%TYPE;
      v_tran_code            transactionlog.txn_code%TYPE        DEFAULT '04';
      v_del_channel          transactionlog.delivery_channel%TYPE DEFAULT '05';
      v_tran_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
      v_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      v_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      v_acct_no              cms_acct_mast.cam_acct_no%TYPE;
      v_passivestatupd_rrn   NUMBER (20);
      v_acct_type            cms_acct_mast.cam_type_code%TYPE;
      v_passive_check        NUMBER (20);
      v_txndt_flag               VARCHAR2(1);
    v_last_txndate       DATE;
    v_last_loaddate      cms_appl_pan.cap_last_corporate_loaddate%TYPE;
    v_toggle_value       cms_inst_param.cip_param_value%TYPE; --Added for VMS-5657 changes
    v_prd_chk            NUMBER; --Added for VMS-5657 changes

/*******************************************************************************
    * Modified By      : Ubaidur Rahman.H
    * Modified Date    : 21-Oct-2019
    * Purpose          : VMS-1212 - Inactivity fee wrongly debited twice for 
    					the customers not used for more than 90 days.
    * Reviewer         : Saravanan
    * Release Number   : VMS_RSI0221

	* Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 17-MAR-2020
    * Purpose          : VMS - 2183 State Restriction logic for monthly fee calculation.
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R28_B2

     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 21-SEP-2021
    * Purpose          : VMS-3366 - Dormancy Fee--HealthCare from LAST CORPORATE LOAD
    * Reviewer         : Saravana Kumar. A
    * Release Number   : VMSGPRHOST_52

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 25-NOV-2021
    * Purpose          : VMS-5327 - Dormancy Fee--HealthCare from LAST CORPORATE LOAD via B2BV2
    * Reviewer         : Saravana Kumar. A
    * Release Number   : VMSGPRHOST_55

    * Modified By      : Pankaj S.
    * Modified Date    : 11/07/2022
    * Purpose          : VMS-5657 (VMS-6087 -Changes to passive period calculation for insta fin prods)
    * Reviewer         : Venkat S.
    * Build Number     : VMS_R66
    
    * Modified By      : Bhavani. E
    * Modified Date    : 20/02/2023
    * Purpose          : VMS-7038 (Inactive card fee charges)
    * Reviewer         : Venkat S.
    * Build Number     : VMS_R76
********************************************************************************/      

      CURSOR c1
      IS
         /*SELECT cap_pan_code, cap_pan_code_encr, cap_active_date,
                cap_prod_code, cap_card_type,
                cpc_passive_time v_passive_time_prodcatg,
                NVL
                   ((SELECT MAX (business_date || business_time)
                       FROM transactionlog
                      WHERE customer_card_no = i1.cap_pan_code
                        AND instcode = p_inst_code
                        AND delivery_channel IN (
                               SELECT cdm_channel_code
                                 FROM cms_delchannel_mast
                                WHERE cdm_passiveperiod_flag = 'Y'
                                  AND cdm_inst_code = p_inst_code)),
                    TO_CHAR (i1.cap_active_date, 'yyyymmddhh24miss')
                   ) v_last_trandate
           FROM cms_appl_pan i1, cms_prod_cattype
          WHERE cap_card_stat = '1'
            AND cap_inst_code = p_inst_code
            AND cap_prod_code = cpc_prod_code
            AND cap_card_type = cpc_card_type
            AND (cpc_passive_time IS NOT NULL AND cpc_passive_time ! = '0')
            AND cpc_inst_code = p_inst_code
            AND cap_expry_date > SYSDATE;*/
         /*WITH proddtls AS
              (SELECT cpc_inst_code, cpc_prod_code, cpc_card_type,
                      cpc_passive_time
                 FROM cms_prod_cattype
                WHERE cpc_inst_code = p_inst_code
                  AND (cpc_passive_time IS NOT NULL AND cpc_passive_time != 0))
         SELECT cap_pan_code, cap_pan_code_encr, cap_active_date,
                cap_prod_code, cap_card_type,cap_acct_no,
                cpc_passive_time v_passive_time_prodcatg
           FROM cms_appl_pan i1, proddtls
          WHERE cap_card_stat = '1'
            AND cap_inst_code = p_inst_code
            AND cap_inst_code = proddtls.cpc_inst_code
            AND cap_prod_code = proddtls.cpc_prod_code
            AND cap_card_type = proddtls.cpc_card_type
            AND cap_expry_date > SYSDATE;*/

            SELECT a.rowid rd,cap_pan_code, cap_pan_code_encr, cap_active_date, cap_prod_code,
                   cap_card_type, cap_acct_no,cap_last_txndate,
                   NVL(to_number(CAP_PANMAST_PARAM6), cpc_passive_time) as cpc_passive_time, --modified for VMS-7038
		   cap_last_corporate_loaddate,cpc_dormancy_oncorporateload
              FROM cms_appl_pan a, cms_prod_mast,cms_prod_cattype
             WHERE cap_inst_code = cpm_inst_code
               AND cap_prod_code = cpm_prod_code
               and cpm_prod_code=cpc_prod_code
               and cap_card_type=cpc_card_type
               AND cap_inst_code = p_inst_code
               AND cap_card_stat IN( '1','13')
               AND cpm_passive_flag = 'Y'
               AND cap_expry_date > SYSDATE
               --AND cap_active_date < SYSDATE - cpc_passive_time /*Commented for Inactivity Fee Issue*/               
              -- AND (cap_last_txndate < SYSDATE - cpc_passive_time or cap_last_txndate is null  /*Commented for Inactivity Fee Issue for VMS-7038 Passive period*/ 
               AND ((cap_last_txndate < SYSDATE - NVL(to_number(CAP_PANMAST_PARAM6), cpc_passive_time)) -- added for VMS-7038 Inactive fee for passive period
               OR cap_last_txndate is null 
               OR (cap_last_corporate_loaddate IS NULL AND cpc_dormancy_oncorporateload = 'Y'));


   BEGIN
     -- p_resp_msg := 'OK';

       /* BEGIN

           EXECUTE IMMEDIATE 'drop table cms_90daystxn_dtls';

           EXECUTE IMMEDIATE 'CREATE TABLE cms_90daystxn_dtls NOLOGGING PARALLEL 4 TABLESPACE CMS_BIG_TXN AS
                                SELECT instcode AS inst_code, customer_card_no AS card_no,
                                       customer_card_no_encr AS card_no_encr, add_ins_date AS txn_date,
                                       txn_code AS txn_code, delivery_channel AS delivery_channel
                                  FROM transactionlog
                                 WHERE instcode = 1
                                   AND NOT (delivery_channel=''05'' AND txn_code IN (''04'',''13'',''16'',''17'',''18'',''97''))
                                   AND add_ins_date >= TRUNC (SYSDATE) - 90
                                   AND add_ins_date <= TRUNC (SYSDATE)';

           EXECUTE IMMEDIATE 'create index idx_90days_txns on cms_90daystxn_dtls(inst_code,card_no) TABLESPACE CMS_BIG_IDX';

        EXCEPTION
           WHEN OTHERS
           THEN
              EXECUTE IMMEDIATE 'CREATE TABLE cms_90daystxn_dtls TABLESPACE CMS_BIG_TXN AS
                                SELECT instcode AS inst_code, customer_card_no AS card_no,
                                       customer_card_no_encr AS card_no_encr, add_ins_date AS txn_date,
                                       txn_code AS txn_code, delivery_channel AS delivery_channel
                                  FROM transactionlog where 1=2';
              p_resp_msg := 'Error while recreating CMS_90DAYSTXN_DTLS-' || SQLERRM;

              RETURN;
        END;*/

      FOR i1 IN c1
      LOOP
         BEGIN
            v_txndt_flag:='N';
            v_prd_chk:=0; --Added for VMS-5657
           /* BEGIN
               SELECT COUNT (1)
                 INTO v_passive_check
                 FROM cms_90daystxn_dtls
                WHERE inst_code = p_inst_code
                  AND card_no = i1.cap_pan_code;
            EXCEPTION
               WHEN OTHERS THEN
                  v_resp_code := '89';
                  p_resp_msg :='Problem in getting 90 days txn count-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_passive;
            END;*/

            /*BEGIN
               SELECT TRUNC (  SYSDATE
                             - TO_DATE (i1.v_last_trandate,
                                        'yyyymmdd hh24:mi:ss'
                                       )
                            )
                 INTO v_passive_days
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_code := '89';
                  p_resp_msg :=
                        'Problem in calculating passive days '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_passive;
            END;*/

            --v_last_tran_date := SUBSTR (i1.v_last_trandate, 1, 8);
            --v_last_tran_time := SUBSTR (i1.v_last_trandate, 9);
            --IF v_passive_days > i1.v_passive_time_prodcatg
           --IF v_passive_check=0 THEN


        IF i1.cap_last_corporate_loaddate IS NULL 
		AND i1.cpc_dormancy_oncorporateload = 'Y'
        THEN

            BEGIN                                  
            SELECT MAX(add_ins_date)
              INTO v_last_loaddate
              FROM transactionlog
             WHERE instcode = 1
               AND customer_acct_no = i1.cap_acct_no
               AND delivery_channel||txn_code IN ('0481','0491','1703','1704','0826' ) 	--- Modified for VMS-5327 	       
	       AND response_code = '00';

          EXCEPTION
            WHEN OTHERS THEN
              v_last_loaddate:= NULL;
          END;


          BEGIN
              UPDATE cms_appl_pan
                 SET cap_last_corporate_loaddate = v_last_loaddate
               WHERE ROWID = i1.rd; 
            EXCEPTION
              WHEN OTHERS THEN
                v_resp_code := '89';
                p_resp_msg  := 'Problem while updating cap_last_corporate_loaddate - ' ||
                               substr(SQLERRM, 1, 200);
                RAISE exp_reject_passive;
            END;



        END IF;
             --SN: Added for VMS-5657
             BEGIN
              SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                INTO v_toggle_value
                FROM vmscms.cms_inst_param
               WHERE cip_inst_code = 1
                 AND cip_param_key = 'VMS_5657_TOGGLE';
             EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_toggle_value := 'Y';
             END;

             IF v_toggle_value = 'Y' THEN
               BEGIN
                SELECT COUNT(1)
                  INTO v_prd_chk
                  FROM vmscms.vms_dormantfee_txns_config
                 WHERE vdt_prod_code = i1.cap_prod_code
                   AND vdt_card_type = i1.cap_card_type
                   AND vdt_is_active = 1;
               EXCEPTION
                WHEN OTHERS THEN
                  NULL;
               END;
             END IF;
             --EN: Added for VMS-5657

           if i1.cap_last_txndate is null 
           AND v_prd_chk=0 --Added for VMS-5657
           then
                begin
                    SELECT nvl(max(add_ins_date),sysdate-180)
                    into v_last_txndate
                    FROM transactionlog
                    WHERE instcode = 1
                    AND customer_card_no =i1.cap_pan_code
                    AND NOT (delivery_channel='05' AND txn_code IN ('04','13','16','17','18','97'))
                    AND add_ins_date >= TRUNC (SYSDATE) - 180 ;
                exception
                    when others then
                        v_last_txndate:=sysdate-180;
                end;

             --   i1.cap_last_txndate:=v_last_txndate;
                if v_last_txndate< SYSDATE - i1.cpc_passive_time then
                   v_txndt_flag:='Y';
                ELSE
                    BEGIN
                           UPDATE cms_appl_pan
                              SET cap_last_txndate = v_last_txndate
                            WHERE rowid=i1.rd; --cap_pan_code = i1.cap_pan_code 
                            --AND cap_inst_code = p_inst_code;
                    EXCEPTION
                       WHEN OTHERS THEN
                          v_resp_code := '89';
                          p_resp_msg :='Problem while updating cap_last_txndate - ' || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_passive;
                    END;
                     commit;
                     continue; 
                end if;

           end if;

          -- if i1.cap_last_txndate < SYSDATE - 90 then
	  IF NVL (i1.cap_last_txndate,v_last_txndate ) < SYSDATE - i1.cpc_passive_time 
	  THEN
               BEGIN
                    BEGIN
                     INSERT INTO cms_passivecard_details
                                                  (cpd_inst_code, cpd_pan_code,
                                                   cpd_pan_code_encr, cpd_last_trandate,
                                                   cpd_last_trantime,
                                                   cpd_currtran_date,
                                                   cpd_currtran_time,
                                                   cpd_passive_period, cpd_process_flag
                                                  )
                                           VALUES (p_inst_code, i1.cap_pan_code,
                                                   i1.cap_pan_code_encr, v_last_tran_date,
                                                   v_last_tran_time,
                                                   TO_CHAR (SYSDATE, 'yyyymmdd'),
                                                   TO_CHAR (SYSDATE, 'hh24miss'),
                                                   i1.cpc_passive_time, 'N'
                                                  );
                       IF SQL%ROWCOUNT = 0 THEN
                          v_resp_code := '89';
                          p_resp_msg := 'Problem in inserting the passive details';
                          RAISE exp_reject_passive;
                       END IF;
                    EXCEPTION
                       WHEN exp_reject_passive THEN
                          RAISE;
                       WHEN OTHERS THEN
                          v_resp_code := '89';
                          p_resp_msg :='Problem while inserting into passive_dtl- ' || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_passive;
                    END; 

                    BEGIN
                       UPDATE cms_appl_pan
                          SET cap_card_stat = '8',
                              --cap_inactive_feecalc_date = ADD_MONTHS (SYSDATE, -1),/*Commented for Inactivity Fee Issue*/
                              cap_last_txndate = decode(v_txndt_flag,'Y',v_last_txndate,cap_last_txndate)
                           WHERE rowid=i1.rd; --cap_pan_code = i1.cap_pan_code AND cap_inst_code = p_inst_code;

                       IF SQL%ROWCOUNT = 0 THEN
                          v_resp_code := '89';
                          p_resp_msg := 'Problem in updating the card status to passive';
                          RAISE exp_reject_passive;
                       END IF;
                    EXCEPTION
                       WHEN exp_reject_passive THEN
                          RAISE;
                       WHEN OTHERS THEN
                          v_resp_code := '89';
                          p_resp_msg :='Problem while updating PAN master- ' || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_passive;
                    END;                 

                  SELECT seq_passivestatupd_rrn.NEXTVAL
                    INTO v_passivestatupd_rrn
                    FROM DUAL;

                  v_rrn :='PSU'|| TO_CHAR (SYSDATE, 'YYYYMMDD')|| v_passivestatupd_rrn;

                  BEGIN
                     SELECT ctm_tran_desc
                       INTO v_tran_desc
                       FROM cms_transaction_mast
                      WHERE ctm_delivery_channel = v_del_channel
                        AND ctm_tran_code = v_tran_code
                        AND ctm_inst_code = p_inst_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        p_resp_msg := 'Transaction Details Not Found';
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                     WHEN OTHERS THEN
                        p_resp_msg :='While getting Transaction Description '|| SUBSTR (SQLERRM, 1, 200);
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                  END;

                  BEGIN
                     SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no,cam_type_code
                       INTO v_acct_bal, v_ledger_bal, v_acct_no, v_acct_type
                       FROM cms_acct_mast
                      WHERE cam_acct_no =i1.cap_acct_no
                               /*(SELECT cap_acct_no
                                  FROM cms_appl_pan
                                 WHERE cap_pan_code = i1.cap_pan_code
                                   AND cap_inst_code = p_inst_code)*/
                        AND cam_inst_code = p_inst_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        p_resp_msg := 'Account Details Not Found';
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                     WHEN OTHERS THEN
                        p_resp_msg :='While getting account details '|| SUBSTR (SQLERRM, 1, 200);
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                  END;

                  BEGIN
                     INSERT INTO transactionlog
                                 (msgtype, rrn, delivery_channel, date_time,
                                  txn_code, txn_type, txn_status,
                                  response_code, business_date,
                                  business_time,
                                  customer_card_no, bank_code,
                                  auth_id,
                                  trans_desc, instcode,
                                  customer_card_no_encr, customer_acct_no,
                                  acct_balance, ledger_balance, response_id,
                                  txn_mode, cardstatus,acct_type,time_stamp
                                 )
                          VALUES ('0200', v_rrn, v_del_channel, SYSDATE,
                                  v_tran_code, '0', 'C',
                                  '00', TO_CHAR (SYSDATE, 'yyyymmdd'),
                                  TO_CHAR (SYSDATE, 'hh24miss'),
                                  i1.cap_pan_code, p_inst_code,
                                  LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                                  v_tran_desc, p_inst_code,
                                  i1.cap_pan_code_encr, v_acct_no,
                                  v_acct_bal, v_ledger_bal, 1,
                                  0, '8',v_acct_type,systimestamp
                                 );

                     IF SQL%ROWCOUNT <> 1 THEN
                        p_resp_msg :='Error while inserting details in transactionlog';
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS THEN
                        p_resp_msg :='Error in inserting transactionlog '|| SUBSTR (SQLERRM, 1, 200);
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                  END;

                  BEGIN
                     INSERT INTO cms_transaction_log_dtl
                                 (ctd_delivery_channel, ctd_txn_code,
                                  ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                                  ctd_business_date,
                                  ctd_business_time,
                                  ctd_customer_card_no, ctd_process_flag,
                                  ctd_process_msg, ctd_rrn, ctd_inst_code,
                                  ctd_customer_card_no_encr,
                                  ctd_cust_acct_number
                                 )
                          VALUES (v_del_channel, v_tran_code,
                                  '0', '0200', 0,
                                  TO_CHAR (SYSDATE, 'yyyymmdd'),
                                  TO_CHAR (SYSDATE, 'hh24miss'),
                                  i1.cap_pan_code, 'Y',
                                  'Successful', v_rrn, p_inst_code,
                                  i1.cap_pan_code_encr,
                                  v_acct_no
                                 );

                     IF SQL%ROWCOUNT <> 1 THEN
                        p_resp_msg :='Error while inserting details in cms_transaction_log_dtl';
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_passive THEN
                        RAISE;
                     WHEN OTHERS THEN
                        p_resp_msg :='Error in inserting cms_transaction_log_dtl '|| SUBSTR (SQLERRM, 1, 200);
                        v_resp_code := '89';
                        RAISE exp_reject_passive;
                  END;
               EXCEPTION
                  WHEN exp_reject_passive THEN
                    RAISE;
                  WHEN OTHERS THEN
                     v_resp_code := '89';
                     p_resp_msg :='Problem while inserting data passive card details '|| SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_passive;
               END;
               COMMIT;
           -- end if;
            END IF;
         EXCEPTION
            WHEN exp_reject_passive THEN
               ROLLBACK;                               --Added on 22/Aug/2013

               BEGIN
                  INSERT INTO cms_passiveperiod_fail_dtl
                              (cpd_inst_code, cpd_pan_code,
                               cpd_pan_code_encr,
                               cpd_currtran_date,
                               cpd_currtran_time,
                               cpd_lasttran_date, cpd_lasttrantime,
                               cpd_ins_user, cpd_ins_date, cpd_lupd_user,
                               cpd_lupd_date, cpd_resp_code, cpd_process_msg
                              )
                       VALUES (p_inst_code, i1.cap_pan_code,
                               i1.cap_pan_code_encr,
                               TO_CHAR (SYSDATE, 'yyyymmdd'),
                               TO_CHAR (SYSDATE, 'hh24miss'),
                               v_last_tran_date, v_last_tran_time,
                               '1', SYSDATE, '1',
                               SYSDATE, v_resp_code, 'EOD' || p_resp_msg
                              );

                  IF SQL%ROWCOUNT = 0 THEN
                     v_resp_code := '89';
                     p_resp_msg :='Problem in inserting the failure details of passive period calculation';
                  END IF;

                  COMMIT;                               --Added on 22/Aug/2013
               END;
            WHEN OTHERS THEN
               ROLLBACK;                               --Added on 22/Aug/2013
               v_resp_code := '89';
               p_resp_msg := 'Error in for loop ' || SUBSTR (SQLERRM, 1, 200);
         END;

        -- COMMIT;                                        --Added on 22/Aug/2013
      END LOOP;
      p_resp_msg := 'OK';
   --COMMIT;--Commented on 22/Aug/2013
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;                                     --Added on 22/Aug/2013
         p_resp_msg := 'Error in main ' || SUBSTR (SQLERRM, 1, 200);
   END pr_eod_passiveperiod_calc;   


   PROCEDURE pr_calc_inactive_fees (
      p_instcode   IN       NUMBER,
      p_lupduser   IN       NUMBER,
      p_rundate    IN       DATE,
      p_errmsg     OUT      VARCHAR2
   )
   AS
   /*************************************************
     * Modified By      : Saravanakumar
     * Modified Date    : 13-Jan-2015
     * Modified Reason  : To calculate inactive fees only once even if card is set to inactive before 4 months 
                          and the incative fee is not calculated yet for past 3 months.
     * Reviewer         : Sai Prasad
     * Reviewed Date    :  13-Jan-2015
     * Build Number     : VMS_Package_1.4.3

     * Modified by       : Siva kumar M
     * Modified Date     : 18-Aug-17
     * Modified For      : FSS-5157 B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.08

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 21-SEP-2021
    * Purpose          : VMS-3366 - Dormancy Fee--HealthCare from LAST CORPORATE LOAD
    * Reviewer         : Saravana Kumar. A
    * Release Number   : VMSGPRHOST_52
   *************************************************/
      v_debit_amnt         NUMBER;
      --V_FEE_AMOUNT NUMBER;
      v_fee_amount         cms_fee_mast.cfm_fee_amt%TYPE;
      -- Modified for FWR-11
      v_err_msg            VARCHAR2 (900)                             := 'OK';
      exp_reject_record    EXCEPTION;
      v_inactive_cardcnt   NUMBER;
      v_waivamt            NUMBER;
      v_cpw_waiv_prcnt     NUMBER;
      v_feeamt             NUMBER;
      v_upd_rec_cnt        NUMBER                                        := 0;
      v_rrn1               NUMBER (10)                              DEFAULT 0;
      v_rrn2               VARCHAR2 (15);
      v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;
      -- added on 17-apr-2013 for defect 10871
      v_timestamp          TIMESTAMP;
                                     -- Added on 17-Apr-2013 for defect 10871
      --V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE; --Commented on 06.09.2013 for DFCHOST-340(review)
      --V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE; --Commented on 06.09.2013 for DFCHOST-340(review)
      v_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      v_card_cnt           NUMBER;      --Added on 03.09.2013 for DFCHOST-340
      v_prdcatg_cnt        NUMBER;      --Added on 03.09.2013 for DFCHOST-340
      v_fee_cal_date       DATE;                       --Added by Arunprasath
      v_chk_card           NUMBER;  --Added by Pankaj S. on 23-Jan-2015
      v_last_txndt          cms_appl_pan.cap_last_txndate%TYPE;
      v_tot_clwbck_count    CMS_FEE_MAST.cfm_clawback_count%TYPE;
      V_CLAWBACK_TOGGLE     CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

      CURSOR cardfee
      IS
         SELECT a.rowid rd,cfm_fee_code, cfm_fee_amt, cce_pan_code, cce_pan_code_encr,
                cce_crgl_catg, cce_crgl_code, cce_crsubgl_code,
                cce_cracct_no, cce_drgl_catg, cce_drgl_code,
                cce_drsubgl_code, cce_dracct_no, cff_fee_plan,
                cap_active_date, cap_card_stat, cfm_feecap_flag,
                                                                -- Modified for FWR-11
                                                                cap_acct_no,

                -- Modified for FWR-11
                cap_prod_code, cap_card_type,

                --Added on 06.09.2013 for DFCHOST-340(review)
                cap_inactive_feecalc_date,              --Added by Arunprasath
                cfm_fee_desc,cap_last_txndate,  --added by Pankaj S. onn 23-Jan-2015
                 nvl(cpc_state_restrict,'N') staterestflag, cap_cust_code,
                 CFM_CLAWBACK_FLAG,
                 NVL(cfm_clawback_count,0) cfm_clawback_count,
                 NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
                 NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
                 CFT_FEE_FREQ,
                 CFT_FEETYPE_CODE
           FROM cms_fee_mast,
                cms_card_excpfee,
                cms_fee_types,
                cms_fee_feeplan,
                cms_appl_pan a,
                cms_prod_cattype
          WHERE cfm_inst_code = p_instcode
            AND cfm_inst_code = cce_inst_code
            --AND cce_fee_code = cfm_fee_code--Modified by Deepa on June 26 2012  as the cce_fee_code will be NULL
            AND cce_fee_plan = cff_fee_plan
            AND cff_fee_code = cfm_fee_code
            AND 
                --TRUNC(SYSDATE) >= TRUNC(CCE_VALID_FROM) AND
                (   (    cce_valid_to IS NOT NULL
                     AND (TRUNC (SYSDATE) BETWEEN cce_valid_from AND cce_valid_to
                         )
                    )
                 OR (cce_valid_to IS NULL AND TRUNC (SYSDATE) >=
                                                                cce_valid_from
                    )
                )
            AND  --Modified by Deepa on Aug-18-2012 to have two active FeePlan
                cfm_feetype_code = cft_feetype_code
            AND cft_inst_code = cfm_inst_code
            and cap_prod_code=cpc_prod_code
            and cap_card_type=cpc_card_type
            --AND cap_card_stat = '8'
            AND cap_card_stat IN (SELECT ccs_stat_code FROM cms_card_stat WHERE ccs_passivechk_flag = 'Y')
            AND cap_expry_date > SYSDATE
            -- AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - cpc_passive_time  /*Commented for Inactivity Fee Issue for VMS-7038 Passive period*/ 
            AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - NVL(to_number(CAP_PANMAST_PARAM6), cpc_passive_time) -- added for VMS-7038 Inactive fee for passive period
            AND ( (cap_startercard_flag='Y' AND cap_firsttime_topup='Y') OR cap_startercard_flag='N')
            AND cft_fee_freq = 'M'
            AND cft_fee_type = 'I'
            AND cap_pan_code = cce_pan_code;

      /*AND
      ((TRUNC(CAP_INACTIVE_FEECALC_DATE) <> TRUNC(SYSDATE)) OR
      (CAP_INACTIVE_FEECALC_DATE IS NULL));*/
      --Commented by Arunprasath
      CURSOR prodcatgfee
      IS
         SELECT a.rowid rd,cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_card_type,
                cpf_crgl_catg, cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
                cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no,
                cff_fee_plan, cap_pan_code, cap_pan_code_encr,
                cap_active_date, cap_card_stat, cfm_feecap_flag,
                                                                -- Modified for FWR-11
                                                                cap_acct_no,

                -- Modified for FWR-11
                cap_prod_code, cap_card_type,

                --Added on 06.09.2013 for DFCHOST-340(review)
                cap_inactive_feecalc_date ,              --Added by Arunprasath
                cfm_fee_desc, cap_last_txndate,  --added by Pankaj S. onn 23-Jan-2015
                nvl(cpc_state_restrict,'N') staterestflag, cap_cust_code,
                 CFM_CLAWBACK_FLAG,
                 NVL(cfm_clawback_count,0) cfm_clawback_count,
                 NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
                 NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
                 CFT_FEE_FREQ,
                 CFT_FEETYPE_CODE
           FROM cms_fee_mast,
                cms_prodcattype_fees,
                cms_fee_types,
                cms_fee_feeplan,
                cms_appl_pan a,
                cms_prod_cattype 
          WHERE cfm_inst_code = p_instcode
            AND cfm_inst_code = cpf_inst_code
            --AND cpf_fee_code = cfm_fee_code--Modified by Deepa on June 26 2012  as the cce_fee_code will be NULL
            AND cff_fee_plan = cpf_fee_plan
            AND cff_fee_code = cfm_fee_code
            AND 
                --TRUNC(SYSDATE) >= TRUNC(CPF_VALID_FROM) AND
                (   (    cpf_valid_to IS NOT NULL
                     AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                         )
                    )
                 OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >=
                                                                cpf_valid_from
                    )
                )
            AND  --Modified by Deepa on Aug-18-2012 to have two active FeePlan
                cfm_feetype_code = cft_feetype_code
            AND cft_inst_code = cfm_inst_code
            AND cap_prod_code = cpf_prod_code
            --AND cap_prod_catg= cpf_card_type--Modified by Deepa on June 26 2012
            AND cap_card_type = cpf_card_type
            AND cap_inst_code = cfm_inst_code
            and cap_prod_code=cpc_prod_code
            and cap_card_type=cpc_card_type
            --AND cap_card_stat = '8'
            AND cap_card_stat IN (SELECT ccs_stat_code FROM cms_card_stat WHERE ccs_passivechk_flag = 'Y')
            AND cap_expry_date > SYSDATE
            --AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - cpc_passive_time /*Commented for Inactivity Fee Issue for VMS-7038 Passive period*/ 
            AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - NVL(to_number(CAP_PANMAST_PARAM6), cpc_passive_time) -- added for VMS-7038 Inactive fee for passive period
            AND ( (cap_startercard_flag='Y' AND cap_firsttime_topup='Y') OR cap_startercard_flag='N')
            AND cft_fee_freq = 'M'
            AND cft_fee_type = 'I';

      /*AND
      ((TRUNC(CAP_INACTIVE_FEECALC_DATE) <> TRUNC(SYSDATE)) OR
      (CAP_INACTIVE_FEECALC_DATE IS NULL));*/
      --Commented by Arunprasath
      CURSOR prodfee
      IS
         SELECT a.rowid rd,cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_crgl_catg,
                cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_catg,
                cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no, cff_fee_plan,
                cap_pan_code, cap_pan_code_encr, cap_active_date,
                cap_card_stat, cfm_feecap_flag,         -- Modified for FWR-11
                                               cap_acct_no,
                                                           -- Modified for FWR-11
                                                           cap_card_type,

                ---Added on 03.09.2013 for DFCHOST-340
                cap_prod_code,   --Added on 06.09.2013 for DFCHOST-340(review)
                cap_inactive_feecalc_date,               --Added by Arunprasath
                cfm_fee_desc, cap_last_txndate,  --added by Pankaj S. onn 23-Jan-2015
               nvl(cpc_state_restrict,'N') staterestflag, cap_cust_code,
                CFM_CLAWBACK_FLAG,
                 NVL(cfm_clawback_count,0) cfm_clawback_count,
                 NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
                 NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
                 CFT_FEE_FREQ,
                 CFT_FEETYPE_CODE
           FROM cms_fee_mast,
                cms_prod_fees,
                cms_fee_types,
                cms_fee_feeplan,
                cms_appl_pan a,
                cms_prod_cattype
          WHERE cfm_inst_code = p_instcode
            AND cfm_inst_code = cpf_inst_code
            AND cff_fee_plan = cpf_fee_plan
            AND cff_fee_code = cfm_fee_code
            AND 
                -- TRUNC(SYSDATE) >= TRUNC(CPF_VALID_FROM) AND
                (   (    cpf_valid_to IS NOT NULL
                     AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                         )
                    )
                 OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >=
                                                                cpf_valid_from
                    )
                )
            AND  --Modified by Deepa on Aug-18-2012 to have two active FeePlan
                cfm_feetype_code = cft_feetype_code
            AND cft_inst_code = cfm_inst_code
            AND cap_prod_code = cpf_prod_code
            AND cap_inst_code = cpf_inst_code
            and cap_prod_code=cpc_prod_code
            and cap_card_type=cpc_card_type
            --AND cap_card_stat = '8'
            AND cap_card_stat IN (SELECT ccs_stat_code FROM cms_card_stat WHERE ccs_passivechk_flag = 'Y')
            AND cap_expry_date > SYSDATE
            --AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - cpc_passive_time /*Commented for Inactivity Fee Issue for VMS-7038 Passive period*/ 
            AND DECODE(cpc_dormancy_oncorporateload,'Y',cap_last_corporate_loaddate,cap_last_txndate) < SYSDATE - NVL(to_number(CAP_PANMAST_PARAM6), cpc_passive_time) -- added for VMS-7038 Inactive fee for passive period
            AND ( (cap_startercard_flag='Y' AND cap_firsttime_topup='Y') OR cap_startercard_flag='N')
            AND cft_fee_freq = 'M'
            AND cft_fee_type = 'I';

      /*AND
      ((TRUNC(CAP_INACTIVE_FEECALC_DATE) <> TRUNC(SYSDATE)) OR
      (CAP_INACTIVE_FEECALC_DATE IS NULL));*/
      --Commented by Arunprasath
      PROCEDURE lp_transaction_log (
         p_instcode           IN   NUMBER,
         p_hashpan            IN   VARCHAR2,
         p_encrpan            IN   VARCHAR2,
         p_rrn                IN   VARCHAR2,
         p_delivery_channel   IN   VARCHAR2,
         p_business_date      IN   VARCHAR2,
         p_business_time      IN   VARCHAR2,
         p_acct_number        IN   VARCHAR2,
         p_acct_bal           IN   VARCHAR2,
         p_ledger_bal         IN   VARCHAR2,
         p_fee_amnt           IN   VARCHAR2,
         p_auth_id            IN   VARCHAR2,
         p_tran_desc          IN   VARCHAR2,
         p_tran_code          IN   VARCHAR2,
         p_response_id        IN   VARCHAR2,
         p_card_curr          IN   VARCHAR2,
         p_waiv_amnt          IN   NUMBER,
         p_fee_code           IN   VARCHAR2,
         p_fee_plan           IN   VARCHAR2,
         p_cr_acctno          IN   VARCHAR2,
         p_dr_acctno          IN   VARCHAR2,
         p_attach_type        IN   VARCHAR2,
         p_card_stat          IN   VARCHAR2,
         p_cam_type_code      IN   VARCHAR2,
         -- Added on 17-Apr-2013 for defect 10871
         p_timestamp          IN   TIMESTAMP,
         -- Added on 17-Apr-2013 for defect 10871
         p_prod_code          IN   VARCHAR2,
         -- Added on 17-Apr-2013 for defect 10871
         p_prod_cattype       IN   VARCHAR2,
         -- Added on 17-Apr-2013 for defect 10871
         p_dr_cr_flag         IN   VARCHAR2,
         -- Added on 17-Apr-2013 for defect 10871
         p_err_msg            IN   VARCHAR2,
      -- Added on 17-Apr-2013 for defect 10871
         p_remark             IN   VARCHAR2--Added by Pankaj S. on 23-Jan-2015
      )
      AS
      BEGIN
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, date_time,
                         txn_code, txn_type,
                         txn_status,
                         response_code,
                         business_date, business_time, customer_card_no,
                         bank_code,
                         total_amount,
                         auth_id, trans_desc, amount,
                                                     -- Uncomented on 17-apr-2013 for defect 10871
                                                     instcode,
                         customer_card_no_encr, customer_acct_no,
                         acct_balance, ledger_balance,
                         response_id, txn_mode, currencycode,
                         tranfee_amt,
                         feeattachtype, fee_plan, feecode,
                         tranfee_cr_acctno, tranfee_dr_acctno, cardstatus,
                         acct_type,   -- Added on 17-Apr-2013 for defect 10871
                                   time_stamp,
                                              -- Added on 17-Apr-2013 for defect 10871
                                              productid,
                         -- Added on 17-Apr-2013 for defect 10871
                         categoryid,  -- Added on 17-Apr-2013 for defect 10871
                                    cr_dr_flag,
                         -- Added on 17-Apr-2013 for defect 10871
                         error_msg,    -- Added on 17-Apr-2013 for defect 10871
                         remark  --Added by Pankaj S. on 23-Jan-2015
                        )
                 VALUES ('0200', p_rrn, p_delivery_channel, SYSDATE,
                         p_tran_code, '1',
                         DECODE (p_response_id, '1', 'C', 'F'),
                         DECODE (p_response_id, '1', '00', '89'),
                         p_business_date, p_business_time, p_hashpan,
                         p_instcode,
                         TRIM (TO_CHAR (  NVL (p_fee_amnt, 0)
                                        - NVL (p_waiv_amnt, 0),
                                        '99999999999999990.99'
                                       )
                              ),  -- NVL added on 17-Apr-2013 for defect 10871
                         p_auth_id, p_tran_desc, '0.00',
                                                        --added on 17-Apr-2013 for defect 10871
                                                                         -- TRIM(TO_CHAR(P_TRAN_AMNT, '99999999999999990.99')),
                                                        p_instcode,
                         p_encrpan, p_acct_number,
                         NVL (p_acct_bal, 0),
                                             -- NVL,to_char added on 17-Apr-2013 for defect 10871
                                             NVL (p_ledger_bal, 0),
                         -- NVL,to_char  added on 17-Apr-2013 for defect 10871
                         p_response_id, 0, p_card_curr,
                         TRIM (TO_CHAR (  NVL (p_fee_amnt, 0)
                                        - NVL (p_waiv_amnt, 0),
                                        '99999999999999990.99'
                                       )
                              ),  -- NVL added on 17-Apr-2013 for defect 10871
                         p_attach_type, p_fee_plan, p_fee_code,
                         p_cr_acctno, p_dr_acctno, p_card_stat,
                         p_cam_type_code,
                                         -- Added on 17-Apr-2013 for defect 10871
                                         p_timestamp,
                                                     -- Added on 17-Apr-2013 for defect 10871
                                                     p_prod_code,
                         -- Added on 17-Apr-2013 for defect 10871
                         p_prod_cattype,
                                        -- Added on 17-Apr-2013 for defect 10871
                                        p_dr_cr_flag,
                         -- Added on 17-Apr-2013 for defect 10871
                         p_err_msg,    -- Added on 17-Apr-2013 for defect 10871
                         p_remark  --Added by Pankaj S. on 23-Jan-2015
                        );
         --SN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         /* IF SQL%ROWCOUNT=0 THEN
         P_ERRMSG:='Error while insertg in transactionlog'||SUBSTR(SQLERRM, 1, 200);
         END IF;*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while insertg in transactionlog'
                  || SUBSTR (SQLERRM, 1, 200);
         --EN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_curr, ctd_fee_amount, ctd_waiver_amount,
                         ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
                         ctd_cust_acct_number
                        )
                 VALUES (p_delivery_channel, p_tran_code, '1',
                         '0200', 0, p_business_date,
                         p_business_time, p_hashpan,
                         p_card_curr, p_fee_amnt, p_waiv_amnt,
                         p_card_curr, DECODE (p_response_id, '1', 'Y', 'F'),
                         DECODE (p_response_id, '1', 'Successful', p_errmsg),
                         p_rrn, p_instcode, p_encrpan,
                         p_acct_number
                        );
         --SN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         /*IF SQL%ROWCOUNT=0 THEN
         P_ERRMSG:='Error while insertg in cms_transaction_log_dtl'||SUBSTR(SQLERRM, 1, 200);
         END IF;*/
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while insertg in cms_transaction_log_dtl'
                  || SUBSTR (SQLERRM, 1, 200);
         --EN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         END;
      END lp_transaction_log;

      PROCEDURE lp_fee_update_log (
         p_instcode       IN       NUMBER,
         p_hashpan        IN       VARCHAR2,
         p_encrpan        IN       VARCHAR2,
         p_fee_code       IN       NUMBER,
         p_fee_amnt       IN       NUMBER,
         p_fee_plan       IN       VARCHAR2,
         p_cr_glcatg      IN       VARCHAR2,
         p_cr_glcode      IN       VARCHAR2,
         p_cr_subglcode   IN       VARCHAR2,
         p_cr_acctno      IN       VARCHAR2,
         p_dr_glcatg      IN       VARCHAR2,
         p_dr_glcode      IN       VARCHAR2,
         p_dr_subglcode   IN       VARCHAR2,
         p_dr_acctno      IN       VARCHAR2,
         p_waiv_amnt      IN       NUMBER,
         p_attach_type    IN       VARCHAR2,
         p_card_stat      IN       VARCHAR2,
         p_acct_no        IN       VARCHAR2,
         --Added on 06.09.2013 for DFCHOST-340(review)
         p_prod_code      IN       VARCHAR2,
         --Added on 06.09.2013 for DFCHOST-340(review)
         p_card_type      IN       NUMBER,
         --Added on 06.09.2013 for DFCHOST-340(review)
         P_fee_desc       IN       VARCHAR2,  --Added by Pankaj S. on 23-Jan-2015
          p_staterestictflag IN     VARCHAR2,
          p_cust_code        IN     VARCHAR2,
          p_active_date      IN      DATE,
          P_last_txndate     IN     DATE,
          P_CLAWBACK_TYPE     IN VARCHAR2,
          P_CLAWBACK_MAXAMT   IN NUMBER,
          P_CLAWBACK          IN VARCHAR2,
          P_FEE_FREQ     IN VARCHAR2,
          P_FEETYPE_CODE IN VARCHAR2,
         p_errmsg         OUT      VARCHAR2
      )
      AS

/*******************************************************************************
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 21-MAY-2020
    * Purpose          : VMS - 2183 State Restriction logic for monthly fee calculation.
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R30.1 (Immediate fix)
********************************************************************************/      

         v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
         v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
         v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
         v_auth_id            transactionlog.auth_id%TYPE;
         v_business_date      VARCHAR2 (10);
         v_business_time      VARCHAR2 (10);
         v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE     DEFAULT '0';
         v_delivery_channel   cms_func_mast.cfm_delivery_channel%TYPE
                                                                 DEFAULT '05';
         v_txn_code           cms_func_mast.cfm_txn_code%TYPE    DEFAULT '17';
         v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
         v_narration          cms_statements_log.csl_trans_narrration%TYPE;
         v_pan_code           VARCHAR2 (19);
         v_fee_amnt           cms_acct_mast.cam_acct_bal%TYPE;
         v_bin_curr            cms_bin_param.cbp_param_value%TYPE;
         v_card_curr          transactionlog.currencycode%TYPE;
         v_remark             transactionlog.remark%TYPE; --Added by Pankaj S. on 23-Jan-2015
      v_rule_based         VMS_STATE_RESTRICTION.vsr_rule_based%type;
      v_fee_period         VMS_STATE_RESTRICTION.vsr_fee_period%type;
      V_FIRST_PURCHASEDATE CMS_ACCT_MAST.CAM_FIRST_PURCHASEDATE%TYPE;
      V_STRULE_FLAG          VARCHAR2(1) DEFAULT 'Y'; 
	  V_STRULE_NOT_CONFIG    VARCHAR2(1) DEFAULT 'Y';
	  V_STATE_CODE 			VMS_STATE_RESTRICTION.VSR_STATE_CODE%TYPE;
	  V_ADD_STATE_CODE		GEN_STATE_MAST.GSM_STATE_CODE%TYPE;
      V_CLAWBACK_AMNT           CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
      V_CLAWBACK_COUNT          NUMBER;
      v_chrg_dtl_amt_sum        NUMBER;
      V_CLAWBACK_MAXAMT_CHECK   BOOLEAN;
      V_FILE_STATUS             CMS_CHARGE_DTL.CCD_FILE_STATUS%TYPE DEFAULT 'N';
      V_CHRG_DTL_CNT            number;
      L_ERRMSG                  TRANSACTIONLOG.ERROR_MSG%TYPE;


      BEGIN 
         p_errmsg := 'OK';
         L_ERRMSG := 'OK';
         V_CLAWBACK_MAXAMT_CHECK := FALSE;

         --Sn Moved  to handle RRN null issuefor defect MVHost-448
         BEGIN
            SELECT TO_CHAR (SYSDATE-1, 'YYYYMMDD'),  --Modified by Pankaj S. to sysdte-1 on 23-Jan-2015
                   TO_CHAR (SYSDATE, 'HH24MISS')
              INTO v_business_date,
                   v_business_time
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         SELECT seq_passivefee_rrn.NEXTVAL
           INTO v_rrn1
           FROM DUAL;

         v_rrn2 := 'IF' || TO_CHAR (SYSDATE, 'MMDD') || v_rrn1;

         --En Moved to handle RRN null issue for defect MVHost-448
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                       cam_type_code  -- Added on 17-Apr-2013 for defect 10871
                  INTO v_acct_bal, v_ledger_bal, v_acct_number,
                       v_cam_type_code
                  -- Added on 17-Apr-2013 for defect 10871
            FROM       cms_acct_mast
                 WHERE cam_inst_code = p_instcode AND cam_acct_no = p_acct_no
                --Commented and modified on 06.09.2013 for DFCHOST-340(review)
            /*(SELECT CAP.CAP_ACCT_NO
            FROM CMS_APPL_PAN CAP
            WHERE CAP.CAP_PAN_CODE = P_HASHPAN)*/
            FOR UPDATE NOWAIT;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg := 'Account Details Not Found in Master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting data from Account Master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_fee_amnt := p_fee_amnt - p_waiv_amnt;
         v_pan_code := fn_dmaps_main (p_encrpan);




         BEGIN
--            SELECT cip_param_value
--              INTO bin_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

             SELECT TRIM (cbp_param_value)  
			 INTO v_bin_curr 
			 FROM cms_bin_param 
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code = (select  cpc_profile_code from 
             cms_prod_cattype where cpc_prod_code = p_prod_code and
             cpc_card_type = p_card_type  and cpc_inst_code=p_instcode);			 

			EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg := 'No Currency Found for the bin';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error in selecting base currency for bin profile '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN Added and moved here to avoid repetation on 06.09.2013 for DFCHOST-340(review)
         BEGIN
            SELECT ctm_tran_desc, ctm_credit_debit_flag
              INTO v_tran_desc, v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_inst_code = p_instcode
               AND ctm_tran_code = v_txn_code
               AND ctm_delivery_channel = v_delivery_channel;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting narration and CR/DR flag'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN Added and moved here to avoid repetation on 06.09.2013 for DFCHOST-340(review)
         BEGIN
            sp_convert_curr (p_instcode,
                             v_bin_curr,
                             v_pan_code,
                             v_fee_amnt,
                             SYSDATE,
                             v_fee_amnt,
                             v_card_curr,
                             p_errmsg,
							 p_prod_code,
                             p_card_type
                            );

            --SN Added on 06.09.2013 for DFCHOST-340(review)
            IF p_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         --SN Added on 06.09.2013 for DFCHOST-340(review)
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


    IF P_CLAWBACK = 'Y' AND V_CLAWBACK_TOGGLE = 'Y' THEN
          IF V_ACCT_BAL > 0 THEN
            IF (V_ACCT_BAL >= V_FEE_AMNT) THEN
                V_DEBIT_AMNT    := V_FEE_AMNT;
                V_CLAWBACK_AMNT := 0;
            ELSE
                V_DEBIT_AMNT    := V_ACCT_BAL;
                V_CLAWBACK_AMNT := V_FEE_AMNT - V_DEBIT_AMNT;
            END IF;
        ELSE
            V_CLAWBACK_AMNT := V_FEE_AMNT;
            V_DEBIT_AMNT    := 0;
        END IF;

    ELSE

    IF v_acct_bal > 0
         THEN                 -- clarfication reqd to check for ledger balance
            IF (v_acct_bal > v_fee_amnt)
            THEN
               v_debit_amnt := v_fee_amnt;
            ELSE
               v_debit_amnt := v_acct_bal;
            END IF;
         ELSE
            v_debit_amnt := 0;
         END IF;

        V_CLAWBACK_AMNT := 0;

    END IF;


 IF p_staterestictflag ='Y' THEN

			BEGIN
				SELECT GSM_STATE_CODE
				INTO	
					   V_ADD_STATE_CODE
				FROM
				(
				SELECT
						GSM_STATE_CODE	
				FROM
						VMS_ORDER_DETAILS,
						VMS_LINE_ITEM_DTL,
						GEN_STATE_MAST
				WHERE
						VOD_ORDER_ID = VLI_ORDER_ID
						AND VOD_PARTNER_ID = VLI_PARTNER_ID
						AND GSM_SWITCH_STATE_CODE = FN_DMAPS_MAIN(VOD_STATE)
						AND VLI_PAN_CODE = P_HASHPAN
						ORDER BY VOD_INS_DATE DESC
				)
				WHERE ROWNUM = 1;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						BEGIN
							SELECT 
								GSM_STATE_CODE
							INTO	
								V_ADD_STATE_CODE
							FROM
								CMS_ADDR_MAST,
								GEN_STATE_MAST
							WHERE
							FN_DMAPS_MAIN(CAM_STATE_SWITCH) = GSM_SWITCH_STATE_CODE
							AND CAM_INST_CODE = GSM_INST_CODE
							AND CAM_CUST_CODE = P_CUST_CODE
							AND CAM_ADDR_FLAG = 'O';
						EXCEPTION
							WHEN NO_DATA_FOUND THEN
								BEGIN
									SELECT 
										GSM_STATE_CODE
									INTO	
										V_ADD_STATE_CODE
									FROM
										CMS_ADDR_MAST,
										GEN_STATE_MAST
									WHERE
									FN_DMAPS_MAIN(CAM_STATE_SWITCH) = GSM_SWITCH_STATE_CODE
									AND CAM_INST_CODE = GSM_INST_CODE
									AND CAM_CUST_CODE = P_CUST_CODE
									AND CAM_ADDR_FLAG = 'P';
								EXCEPTION
									WHEN OTHERS THEN
										p_errmsg := 'Error while selecting physical address ' || SUBSTR (SQLERRM, 1, 200);
										RAISE exp_reject_record;
								END;
							WHEN OTHERS THEN
								p_errmsg := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
								RAISE exp_reject_record;
						END;
					WHEN OTHERS THEN
						p_errmsg := 'Error while selecting order address ' || SUBSTR (SQLERRM, 1, 200);
						RAISE exp_reject_record;	
				END;

				BEGIN
					SELECT 	VSR_STATE_CODE,VSR_RULE_BASED,VSR_FEE_PERIOD
					INTO	V_STATE_CODE,V_RULE_BASED,V_FEE_PERIOD
					FROM	VMS_STATE_RESTRICTION
					WHERE	vsr_prod_code = P_PROD_CODE
					AND 	vsr_card_type = P_CARD_TYPE
					AND 	VSR_FEE_TYPE  = 'I'
					AND 	VSR_STATE_CODE = V_ADD_STATE_CODE;

				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						V_STRULE_NOT_CONFIG := 'N';
					WHEN OTHERS THEN
						p_errmsg := 'Error while selecting state restriction rule ' || SUBSTR (SQLERRM, 1, 200);
						RAISE exp_reject_record;
				END;

   IF V_STRULE_NOT_CONFIG = 'Y' THEN

     IF v_rule_based ='A' THEN
                  IF SYSDATE<p_active_date+v_fee_period THEN
                  V_STRULE_FLAG:='N';
                  END IF;
     ELSIF  v_rule_based ='L' THEN
                IF SYSDATE<p_last_txndate+v_fee_period  THEN
                  V_STRULE_FLAG:='N';
                  END IF;
     ELSIF  v_rule_based ='F' THEN --F first purchase date.

             BEGIN
                 SELECT CAM_FIRST_PURCHASEDATE
                 INTO V_FIRST_PURCHASEDATE
                 FROM CMS_ACCT_MAST 
                 WHERE  CAM_ACCT_NO=p_acct_no
                 AND   CAM_INST_CODE=p_instcode;
            EXCEPTION 
                  WHEN NO_DATA_FOUND THEN
                      null;
                  WHEN OTHERS THEN
                 p_errmsg := 'Error while selecting last transaction date frm acctmast '||SUBSTR(SQLERRM,1,200);
                RAISE exp_reject_record;
             END;

           IF SYSDATE<V_FIRST_PURCHASEDATE+v_fee_period  THEN
              V_STRULE_FLAG:='N';
           END IF;
        ELSIF  v_rule_based ='N' THEN
             V_STRULE_FLAG :='N';
       END IF;
     END IF;
  END IF;

 IF  V_STRULE_FLAG = 'Y'  THEN
         IF v_debit_amnt > 0 or (P_CLAWBACK = 'Y' and V_CLAWBACK_AMNT > 0 AND V_CLAWBACK_TOGGLE = 'Y')
         THEN
            --Sn Moving here from down by Pankaj S. on 18-March-2014
            BEGIN
               -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
               SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                 INTO v_auth_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while generating authid '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            v_pan_code := fn_dmaps_main (p_encrpan);

            IF v_debit_amnt > 0 THEN

            --En Moving here from down by Pankaj S. on 18-March-2014
            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal - v_debit_amnt,
                      cam_ledger_bal = cam_ledger_bal - v_debit_amnt
                WHERE cam_acct_no = v_acct_number
                  AND cam_inst_code = p_instcode;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_err_msg :=
                        'Error while updating balance'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
               END IF;
            --SN Added on 06.09.2013 for DFCHOST-340(review)
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_err_msg :=
                        'Error while updating balance'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            --EN Added on 06.09.2013 for DFCHOST-340(review)
            END;

            --Sn Moving up & commented here by Pankaj S. on 18-March-2014
            /*BEGIN
               -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
               SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                 INTO v_auth_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while generating authid '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;*/
            --En Moving up & commented here by Pankaj S. on 18-March-2014

            --Sn Moved up to handle RRN null issue    for defect MVHost-448
            /* BEGIN
            SELECT TO_CHAR(SYSDATE, 'YYYYMMDD'), TO_CHAR(SYSDATE, 'HH24MISS')
            INTO V_BUSINESS_DATE, V_BUSINESS_TIME
            FROM DUAL;
            EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG := 'Error while selecting date' ||
            SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
            END;
            V_RRN1     := V_RRN1 + 1;
            V_RRN2     := 'IF' || V_BUSINESS_DATE || V_RRN1;*/
            --En Moved up to handle RRN null issue    for defect MVHost-448

            BEGIN
               --SN Commented on 06.09.2013 for DFCHOST-340(review)
               /*SELECT CTM_TRAN_DESC
               INTO V_TRAN_DESC
               FROM CMS_TRANSACTION_MAST
               WHERE CTM_TRAN_CODE = V_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INSTCODE;*/
               --EN Commented on 06.09.2013 for DFCHOST-340(review)
               --Sn modified by Pankaj S. on 23-Jan-2015
               IF TRIM (p_fee_desc) IS NOT NULL THEN
               --IF TRIM (v_tran_desc) IS NOT NULL THEN
                --v_narration := v_tran_desc || '/';
                 v_narration := p_fee_desc || '/';
               END IF;
               --En modified by Pankaj S. on 23-Jan-2015

               IF TRIM (v_auth_id) IS NOT NULL
               THEN
                  v_narration := v_narration || v_auth_id || '/';
               END IF;

               IF TRIM (v_acct_number) IS NOT NULL
               THEN
                  v_narration := v_narration || v_acct_number || '/';
               END IF;

               IF TRIM (v_business_date) IS NOT NULL
               THEN
                  v_narration := v_narration || v_business_date;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while selecting narration'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

-----------------------------------------------
--SN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
--SN Commented on 06.09.2013 for DFCHOST-340(review)
/* BEGIN
SELECT CAP_PROD_CODE,
CAP_CARD_TYPE
INTO V_PROD_CODE,
V_PROD_CATTYPE
FROM CMS_APPL_PAN
WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = P_HASHPAN; --P_card_no;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;*/
--EN Commented on 06.09.2013 for DFCHOST-340(review)
--SN Commented on 06.09.2013 for DFCHOST-340(review)
/*BEGIN
SELECT CTM_CREDIT_DEBIT_FLAG
INTO   V_DR_CR_FLAG
FROM   CMS_TRANSACTION_MAST
WHERE CTM_TRAN_CODE = V_TXN_CODE
AND   CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL
AND   CTM_INST_CODE = P_INSTCODE;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;*/
--SN Commented on 06.09.2013 for DFCHOST-340(review)
-----------------------------------------------
--EN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
            v_timestamp := SYSTIMESTAMP;

            -- Added on 17-Apr-2013 for defect 10871
            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_acct_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date, csl_closing_balance,
                            csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_inst_code,
                            csl_txn_code, csl_ins_date, csl_ins_user,
                            csl_panno_last4digit,
                            csl_acct_type,
                                          -- Added on 17-Apr-2013 for defect 10871
                                          csl_time_stamp,
                                                         -- Added on 17-Apr-2013 for defect 10871
                                                         csl_prod_code,csl_card_type
                           -- Added on 17-Apr-2013 for defect 10871
                           )
                    VALUES (p_hashpan, v_acct_number, v_ledger_bal,
                            -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
                            v_debit_amnt, 'DR',
                            SYSDATE, v_ledger_bal - v_debit_amnt, 
                            -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
                            v_narration, p_encrpan, v_rrn2,
                            v_auth_id, v_business_date,
                            v_business_time, 'Y',
                            v_delivery_channel, p_instcode,
                            v_txn_code, SYSDATE, 1,
                            (SUBSTR (v_pan_code,
                                     LENGTH (v_pan_code) - 3,
                                     LENGTH (v_pan_code)
                                    )
                            ),
                            v_cam_type_code,
                                            -- Added on 17-Apr-2013 for defect 10871
                                            v_timestamp,
                                                                  -- Added on 17-Apr-2013 for defect 10871
                                                        --V_PROD_CODE        -- Added on 17-Apr-2013 for defect 10871
                                                        p_prod_code,p_card_type
                           --Added on 06.09.2013 for DFCHOST-340(review)
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error creating entry in statement log '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

        END IF;

    IF P_CLAWBACK = 'Y' AND V_CLAWBACK_AMNT > 0 AND V_CLAWBACK_TOGGLE = 'Y' THEN

        V_FILE_STATUS := 'C';

        BEGIN
            SELECT COUNT (*),NVL(SUM(ccd_clawback_amnt),0)
            INTO v_chrg_dtl_cnt,v_chrg_dtl_amt_sum
            FROM cms_charge_dtl
            WHERE      ccd_inst_code = p_instcode
            AND ccd_delivery_channel = v_delivery_channel
            AND ccd_txn_code = v_txn_code
            AND ccd_acct_no = v_acct_number and CCD_FEE_CODE=P_FEE_CODE
            and ccd_clawback ='Y';
        EXCEPTION
            WHEN OTHERS   THEN
                P_ERRMSG :=  'Error occured while fetching count from cms_charge_dtl'|| SUBSTR (SQLERRM, 1, 100);
                RAISE EXP_REJECT_RECORD;
        END;

      IF (v_tot_clwbck_count =0 AND P_CLAWBACK_MAXAMT = 0) THEN -- If clawback count 0, then system should not clawback any fees
          V_CLAWBACK_AMNT := 0;
      ELSIF (v_tot_clwbck_count > 0 AND P_CLAWBACK_MAXAMT = 0) THEN
          IF NOT(v_chrg_dtl_cnt < v_tot_clwbck_count)  THEN -- Validate only value configured count, If 0 is configured as clawback max amount
             V_CLAWBACK_AMNT := 0;
          END IF;
      ELSIF (v_tot_clwbck_count = 0 AND P_CLAWBACK_MAXAMT > 0)  THEN -- Validate only value configured amount ,If 0 is configured as clawback count
          IF (v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)  THEN
             V_CLAWBACK_MAXAMT_CHECK := TRUE;
          ELSE
              V_CLAWBACK_AMNT := 0;
          END IF;
      ELSIF (v_tot_clwbck_count > 0 AND P_CLAWBACK_MAXAMT > 0) THEN
          IF P_CLAWBACK_TYPE = 'O' THEN -- No clawback ,if either configured number of count or max amount exceeds
             IF (NOT(v_chrg_dtl_cnt < v_tot_clwbck_count) or NOT(v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)) THEN
                V_CLAWBACK_AMNT := 0;
             ELSE
                V_CLAWBACK_MAXAMT_CHECK := TRUE;
             END IF;
          ELSIF P_CLAWBACK_TYPE = 'A' THEN -- No clawback ,if both configured number of count and max amount exceeds
             IF (NOT(v_chrg_dtl_cnt < v_tot_clwbck_count) AND NOT(v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)) THEN
                  V_CLAWBACK_AMNT := 0;
             ELSE
                V_CLAWBACK_MAXAMT_CHECK := TRUE;
               END IF;
          ELSE
              V_CLAWBACK_AMNT := 0;
        END IF;
      ELSE
          V_CLAWBACK_AMNT := 0;
      END IF;

      IF V_CLAWBACK_MAXAMT_CHECK  THEN -- IF SUM OF clawback amount exceeds configured clawback MAX amount,THEN clawback diff amt ONLY
         IF (v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT AND v_chrg_dtl_amt_sum+V_CLAWBACK_AMNT  > P_CLAWBACK_MAXAMT ) THEN
            V_CLAWBACK_AMNT := P_CLAWBACK_MAXAMT - v_chrg_dtl_amt_sum;
         END IF;
      END IF;
    IF V_CLAWBACK_AMNT > 0 THEN
        BEGIN

            SELECT COUNT(*)
            INTO V_CLAWBACK_COUNT
            FROM CMS_ACCTCLAWBACK_DTL
            WHERE CAD_INST_CODE = P_INSTCODE AND
            CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
            CAD_TXN_CODE = V_TXN_CODE AND CAD_PAN_CODE = P_HASHPAN AND
            CAD_ACCT_NO = V_ACCT_NUMBER;

            IF V_CLAWBACK_COUNT = 0 THEN

                BEGIN
                    INSERT INTO CMS_ACCTCLAWBACK_DTL
                                        (CAD_INST_CODE,
                                        CAD_ACCT_NO,
                                        CAD_PAN_CODE,
                                        CAD_PAN_CODE_ENCR,
                                        CAD_CLAWBACK_AMNT,
                                        CAD_RECOVERY_FLAG,
                                        CAD_INS_DATE,
                                        CAD_LUPD_DATE,
                                        CAD_DELIVERY_CHANNEL,
                                        CAD_TXN_CODE,
                                        CAD_INS_USER,
                                        CAD_LUPD_USER)
                    VALUES
                                        (P_INSTCODE,
                                        V_ACCT_NUMBER,
                                        P_HASHPAN,
                                        P_ENCRPAN,
                                        ROUND(V_CLAWBACK_AMNT,2),  
                                        'N',
                                        SYSDATE,
                                        SYSDATE,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE,
                                        '1',
                                        '1');
                EXCEPTION
                    WHEN OTHERS THEN
                        P_ERRMSG := 'Error while inserting Account ClawBack details' || SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;

                  ELSE
                BEGIN
                    UPDATE CMS_ACCTCLAWBACK_DTL
                    SET CAD_CLAWBACK_AMNT = ROUND(CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT,2), 
                    CAD_RECOVERY_FLAG = 'N',
                    CAD_LUPD_DATE     = SYSDATE
                    WHERE CAD_INST_CODE = P_INSTCODE AND
                    CAD_ACCT_NO = V_ACCT_NUMBER AND CAD_PAN_CODE = P_HASHPAN AND
                    CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                    CAD_TXN_CODE = V_TXN_CODE;

                    IF SQL%ROWCOUNT =0 THEN
                        P_ERRMSG := 'No records updated in ACCTCLAWBACK_DTL for pan='||P_HASHPAN;
                        RAISE EXP_REJECT_RECORD;
                    END IF;

                    EXCEPTION
                        WHEN EXP_REJECT_RECORD THEN
                            RAISE;
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while Updating ACCTCLAWBACK_DTL' ||SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                END;

            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while inserting Account ClawBack details' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

         BEGIN
            INSERT INTO CMS_CHARGE_DTL
                            (CCD_INST_CODE,
                            CCD_PAN_CODE,
                            CCD_MBR_NUMB,
                            CCD_ACCT_NO,
                            CCD_FEE_FREQ,
                            CCD_FEETYPE_CODE,
                            CCD_FEE_CODE,
                            CCD_CALC_AMT,
                            CCD_EXPCALC_DATE,
                            CCD_CALC_DATE,
                            CCD_FILE_NAME,
                            CCD_FILE_DATE,
                            CCD_INS_USER,
                            CCD_LUPD_USER,
                            CCD_FILE_STATUS,
                            CCD_RRN,
                            CCD_DEBITED_AMNT,
                            CCD_PROCESS_MSG,
                            CCD_CLAWBACK_AMNT,
                            CCD_CLAWBACK,
                            CCD_FEE_PLAN,
                            CCD_PAN_CODE_ENCR,
                            CCD_GL_ACCT_NO,
                            CCD_DELIVERY_CHANNEL,
                            CCD_TXN_CODE,
                            CCD_FEEATTACHTYPE,
                            ccd_process_id)
            VALUES
                            (P_INSTCODE,
                            P_HASHPAN,
                            '000',
                            V_ACCT_NUMBER,
                            P_FEE_FREQ,
                            P_FEETYPE_CODE,
                            P_FEE_CODE,
                            ROUND(P_FEE_AMNT,2), 
                            SYSDATE,
                            SYSDATE,
                            'N',
                            SYSDATE,
                            P_LUPDUSER,
                            P_LUPDUSER,
                            V_FILE_STATUS,
                            V_RRN2,
                            ROUND(V_DEBIT_AMNT,2),  
                            P_ERRMSG,
                            ROUND(V_CLAWBACK_AMNT,2),  
                            P_CLAWBACK,
                            P_FEE_PLAN,
                            P_ENCRPAN,
                            P_CR_ACCTNO,
                            V_DELIVERY_CHANNEL,
                            V_TXN_CODE,
                            P_ATTACH_TYPE,
                            to_char(sysdate,'MM'));
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while inserting Fee details' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        ELSE 
        L_ERRMSG :='CLAW BLACK WAIVED';
        END IF;
    end if;

            BEGIN
               sp_ins_eodupdate_acct_cmsauth (v_rrn2,                --prm_rrn
                                              NULL,         -- prm_terminal_id
                                              v_delivery_channel,
                                              v_txn_code,
                                              v_txn_mode,
                                              SYSDATE,
                                              v_pan_code,
                                              p_cr_acctno,
                                              v_debit_amnt,
                                              'C',
                                              p_instcode,
                                              p_errmsg
                                             );

               IF p_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                        'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                     || p_errmsg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               --SN Added on 06.09.2013 for DFCHOST-340(review)
               WHEN exp_reject_record
               THEN
                  RAISE;
               --EN Added on 06.09.2013 for DFCHOST-340(review)
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            v_upd_rec_cnt := v_upd_rec_cnt + 1;
         END IF; 

         BEGIN
            INSERT INTO cms_inactivity_fee_det
                        (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                         cfd_fee_amnt, cfd_dedited_amnt, cfd_ins_user,
                         cfd_ins_date, cfd_lupd_user, cfd_lupd_date,
                         cfd_process_msg, cfd_fee_plan
                        )
                 VALUES (p_instcode, p_hashpan, p_fee_code,
                         p_fee_amnt, v_debit_amnt, p_lupduser,
                         SYSDATE, p_lupduser, SYSDATE,
                         DECODE (v_err_msg, 'OK', 'SUCCESS'), p_fee_plan
                        );
         --SN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         /*IF SQL%ROWCOUNT = 0 THEN
         V_ERR_MSG := 'Error while inserting Fee details' ||
         SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
         END IF;*/
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while inserting Fee details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         --EN Commented and modified on 06.09.2013 for DFCHOST-340(review)
         END;

          IF v_debit_amnt > 0 THEN --Added by Pankaj S. on 23-Jan-2015
         --Added by Deepa on 22-OCT-2012 To log the Fee details in transactionlog,cms_tarnsaction_log_dtl table.
           v_remark := v_tran_desc||' For the period '|| to_char(add_months(sysdate,-1),'YYYYMMDD') ||' - ' ||v_business_date;

           IF p_errmsg = 'OK' THEN
                p_errmsg := L_ERRMSG;
           END IF;

          lp_transaction_log
                        (p_instcode,
                         p_hashpan,
                         p_encrpan,
                         v_rrn2,
                         v_delivery_channel,
                         v_business_date,
                         v_business_time,
                         v_acct_number,
                         v_acct_bal - v_debit_amnt,
                         v_ledger_bal - v_debit_amnt,
                         v_debit_amnt, --p_fee_amnt,
                         v_auth_id,
                         v_tran_desc,
                         v_txn_code,
                         1,
                         v_card_curr,
                         p_waiv_amnt,
                         p_fee_code,
                         p_fee_plan,
                         p_cr_acctno,
                         p_dr_acctno,
                         p_attach_type,
                         p_card_stat,
                         v_cam_type_code,
                                         -- Added on 17-Apr-2013 for defect 10871
                         --v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
                         NVL (v_timestamp, SYSTIMESTAMP),
                         --Commented and modified on 06.09.2013 for DFCHOST-340(REVIEW) CHANGES
                              --V_PROD_CODE,       -- Added on 17-Apr-2013 for defect 10871
                         p_prod_code,
                                     --Addd on 06.09.2013 for DFCHOST-340(review)
                         --V_PROD_CATTYPE,   -- Added on 17-Apr-2013 for defect 10871
                         p_card_type,
                         --Addd on 06.09.2013 for DFCHOST-340(review)
                         v_dr_cr_flag,
                                      -- Added on 17-Apr-2013 for defect 10871
                         p_errmsg,     -- Added on 17-Apr-2013 for defect 10871
                         v_remark  --Added by Pankaj S. on 23-Jan-2015
                        );
          END IF;  --Added by Pankaj S. on 23-Jan-2015  
END IF;               
      EXCEPTION
         WHEN exp_reject_record
         THEN
            --p_errmsg :='Error in update account ' || SUBSTR (SQLERRM, 1, 200);  --Commented by Pankaj S. on 18-March-2014
            BEGIN
               INSERT INTO cms_inactivity_fee_det
                           (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                            cfd_ins_user, cfd_ins_date, cfd_lupd_user,
                            cfd_lupd_date, cfd_process_msg, cfd_fee_plan,
                            cfd_fee_amnt
                           )
                    VALUES (p_instcode, p_hashpan, p_fee_code,
                            p_lupduser, SYSDATE, p_lupduser,
                            SYSDATE, p_errmsg, p_fee_plan,
                            p_fee_amnt
                           );
            --SN Addd on 06.09.2013 for DFCHOST-340(review)
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while inserting Fee details 1.0'
                     || SUBSTR (SQLERRM, 1, 200);
            --EN Addd on 06.09.2013 for DFCHOST-340(review)
            END;

-----------------------------------------------
--SN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
--SN Commented on 06.09.2013 for DFCHOST-340(review)
/* if V_PROD_CODE is null
then
BEGIN
SELECT CAP_PROD_CODE,
CAP_CARD_TYPE
INTO V_PROD_CODE,
V_PROD_CATTYPE
FROM CMS_APPL_PAN
WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = P_HASHPAN; --P_card_no;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;
end if;*/
--EN Commented on 06.09.2013 for DFCHOST-340(review)
            IF v_dr_cr_flag IS NULL
            THEN
               BEGIN
                  SELECT ctm_credit_debit_flag
                    INTO v_dr_cr_flag
                    FROM cms_transaction_mast
                   WHERE ctm_tran_code = v_txn_code
                     AND ctm_delivery_channel = v_delivery_channel
                     AND ctm_inst_code = p_instcode;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

-----------------------------------------------
--EN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
            v_remark := v_tran_desc||' For the period '|| to_char(add_months(sysdate,-1),'YYYYMMDD') ||' - ' ||v_business_date;

            lp_transaction_log
                     (p_instcode,
                      p_hashpan,
                      p_encrpan,
                      v_rrn2,
                      v_delivery_channel,
                      v_business_date,
                      v_business_time,
                      v_acct_number,
                      v_acct_bal - v_debit_amnt,
                      v_ledger_bal - v_debit_amnt,
                      p_fee_amnt,
                      v_auth_id,
                      v_tran_desc,
                      v_txn_code,
                      21,
                      v_card_curr,
                      p_waiv_amnt,
                      p_fee_code,
                      p_fee_plan,
                      p_cr_acctno,
                      p_dr_acctno,
                      p_attach_type,
                      p_card_stat,
                      v_cam_type_code,
                                      -- Added on 17-Apr-2013 for defect 10871
                      NVL (v_timestamp, SYSTIMESTAMP),
                                        -- Added on 17-Apr-2013 for defect 10871
                      --V_PROD_CODE,       -- Added on 17-Apr-2013 for defect 10871
                      p_prod_code,
                                  --Added on 06.09.2013 for DFCHOST-340(review)
                      --V_PROD_CATTYPE,    -- Added on 17-Apr-2013 for defect 10871
                      p_card_type,
                      --Added on 06.09.2013 for DFCHOST-340(review)
                      v_dr_cr_flag,   -- Added on 17-Apr-2013 for defect 10871
                      p_errmsg,        -- Added on 17-Apr-2013 for defect 10871
                      v_remark         -- Added by Pankaj S. on 23-Jan-2015
                     );
         WHEN OTHERS
         THEN
            p_errmsg :=
                       'Error in update account ' || SUBSTR (SQLERRM, 1, 200);

            BEGIN
               INSERT INTO cms_inactivity_fee_det
                           (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                            cfd_ins_user, cfd_ins_date, cfd_lupd_user,
                            cfd_lupd_date, cfd_process_msg, cfd_fee_plan,
                            cfd_fee_amnt
                           )
                    VALUES (p_instcode, p_hashpan, p_fee_code,
                            p_lupduser, SYSDATE, p_lupduser,
                            SYSDATE, p_errmsg, p_fee_plan,
                            p_fee_amnt
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while inserting into INACTIVITY_FEE_DET '
                     || SUBSTR (SQLERRM, 1, 200);
            END;

-----------------------------------------------
--SN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
--SN Commented on 06.09.2013 for DFCHOST-340(review)
/* if V_PROD_CODE is null
then
BEGIN
SELECT CAP_PROD_CODE,
CAP_CARD_TYPE
INTO V_PROD_CODE,
V_PROD_CATTYPE
FROM CMS_APPL_PAN
WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = P_HASHPAN; --P_card_no;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;
end if;*/
--EN Commented on 06.09.2013 for DFCHOST-340(review)
            IF v_dr_cr_flag IS NULL
            THEN
               BEGIN
                  SELECT ctm_credit_debit_flag
                    INTO v_dr_cr_flag
                    FROM cms_transaction_mast
                   WHERE ctm_tran_code = v_txn_code
                     AND ctm_delivery_channel = v_delivery_channel
                     AND ctm_inst_code = p_instcode;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

-----------------------------------------------
--EN: Added on 17-Apr-2013 for defect 10871
-----------------------------------------------
            v_remark := v_tran_desc||' For the period '|| to_char(add_months(sysdate,-1),'YYYYMMDD') ||' - ' ||v_business_date;

            lp_transaction_log
                     (p_instcode,
                      p_hashpan,
                      p_encrpan,
                      v_rrn2,
                      v_delivery_channel,
                      v_business_date,
                      v_business_time,
                      v_acct_number,
                      v_acct_bal - v_debit_amnt,
                      v_ledger_bal - v_debit_amnt,
                      p_fee_amnt,
                      v_auth_id,
                      v_tran_desc,
                      v_txn_code,
                      21,
                      v_card_curr,
                      p_waiv_amnt,
                      p_fee_code,
                      p_fee_plan,
                      p_cr_acctno,
                      p_dr_acctno,
                      p_attach_type,
                      p_card_stat,
                      v_cam_type_code,
                                      -- Added on 17-Apr-2013 for defect 10871
                      NVL (v_timestamp, SYSTIMESTAMP),
                                        -- Added on 17-Apr-2013 for defect 10871
                      -- V_PROD_CODE,       -- Added on 17-Apr-2013 for defect 10871
                      p_prod_code,
                                  --Added on 06.09.2013 for DFCHOST-340(review)
                      --V_PROD_CATTYPE,    -- Added on 17-Apr-2013 for defect 10871
                      p_card_type,
                      --Added on 06.09.2013 for DFCHOST-340(review)
                      v_dr_cr_flag,   -- Added on 17-Apr-2013 for defect 10871
                      p_errmsg,        -- Added on 17-Apr-2013 for defect 10871
                      v_remark         -- Added by Pankaj S. on 23-Jan-2015
                     );
      END lp_fee_update_log;
   BEGIN
      --IF TRUNC(LAST_DAY(SYSDATE)) = TRUNC(SYSDATE) THEN  --Commented by Arunprasath
      --Sn InActivity Fee Calculation for the Card

          BEGIN
            SELECT
                    NVL(CIP_PARAM_VALUE,'N')
                INTO V_CLAWBACK_TOGGLE
                FROM
                    CMS_INST_PARAM
                WHERE
                    CIP_PARAM_KEY = 'VMS_4532_TOGGLE'
                    AND CIP_INST_CODE = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        V_CLAWBACK_TOGGLE := 'N';
         END;

      BEGIN
        FOR c1 IN cardfee
         LOOP
            v_err_msg := 'OK';
            -- SN Modified for FWR-11
            v_fee_amount := c1.cfm_fee_amt;
             --SN Added by Arunprasath
            IF (c1.cap_inactive_feecalc_date IS NULL OR ADD_MONTHS (c1.cap_inactive_feecalc_date, 1) <= SYSDATE)
            --Added by Arunprasath
            THEN
                BEGIN
                   SELECT MAX (cap_last_txndate)
                     INTO v_last_txndt
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode AND cap_acct_no = c1.cap_acct_no;
                EXCEPTION
                   WHEN OTHERS THEN
                      v_last_txndt := SYSDATE;
                END;

               IF c1.cap_last_txndate<>v_last_txndt THEN
                CONTINUE;
               END IF;   
 
               IF c1.cfm_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_cap (p_instcode,
                                       c1.cap_acct_no,
                                       TRUNC (SYSDATE),
                                       v_fee_amount,
                                       c1.cff_fee_plan,
                                       c1.cfm_fee_code,
                                       v_err_msg
                                      );                   -- Added for FWR-11
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;
               END IF;

               --EN Modified for FWR-11
               BEGIN
                  SELECT cce_waiv_prcnt
                    INTO v_cpw_waiv_prcnt
                    FROM cms_card_excpwaiv
                   WHERE cce_inst_code = p_instcode
                     AND cce_pan_code = c1.cce_pan_code
                     AND cce_fee_code = c1.cfm_fee_code
                     AND
                         --SYSDATE >= CCE_VALID_FROM AND SYSDATE <= CCE_VALID_TO;
                         cce_fee_plan = c1.cff_fee_plan
                     AND 
                         --SYSDATE >= CCE_VALID_FROM AND SYSDATE <= CCE_VALID_TO;
                         (   (    cce_valid_to IS NOT NULL
                              AND (SYSDATE BETWEEN cce_valid_from AND cce_valid_to
                                  )
                             )
                          OR (    cce_valid_to IS NULL
                              AND SYSDATE >= cce_valid_from
                             )
                         );

                  v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
               --C1.CFM_FEE_AMT; -- Modified for FWR-11
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_waivamt := 0;
               END;

               -- V_FEEAMT := C1.CFM_FEE_AMT - V_WAIVAMT;
               v_tot_clwbck_count := C1.cfm_clawback_count;
               lp_fee_update_log (p_instcode,
                                  c1.cce_pan_code,
                                  c1.cce_pan_code_encr,
                                  c1.cfm_fee_code,
                                  --C1.CFM_FEE_AMT,
                                  v_fee_amount,         -- Modified for FWR-11
                                  c1.cff_fee_plan,
                                  c1.cce_crgl_catg,
                                  c1.cce_crgl_code,
                                  c1.cce_crsubgl_code,
                                  c1.cce_cracct_no,
                                  c1.cce_drgl_catg,
                                  c1.cce_drgl_code,
                                  c1.cce_drsubgl_code,
                                  c1.cce_dracct_no,
                                  v_waivamt,
                                  'C',
                                  c1.cap_card_stat,
                                  c1.cap_acct_no,
                                  --Added on 06.09.2013 for DFCHOST-340(review)
                                  c1.cap_prod_code,
                                  --Added on 06.09.2013 for DFCHOST-340(review)
                                  c1.cap_card_type,
                                  --Added on 06.09.2013 for DFCHOST-340(review)
                                  c1.cfm_fee_desc,  --added by Pankaj S. onn 23-Jan-2015
                                  c1.staterestflag,
                                  c1.cap_cust_code,
                                  c1.cap_active_date,
                                  c1.cap_last_txndate,
                                  C1.CFM_CLAWBACK_TYPE,
                                  C1.CFM_CLAWBACK_MAXAMT,
                                  C1.CFM_CLAWBACK_FLAG,
                                  C1.CFT_FEE_FREQ,
                                  C1.CFT_FEETYPE_CODE,
                                  v_err_msg
                                 );
             /*  --Sn added by Pankaj S. on 23-Jan-2015 
                SELECT COUNT (1)
                  INTO v_chk_card
                  FROM transactionlog
                 WHERE instcode = p_instcode
                   AND customer_card_no = c1.cce_pan_code
                   AND NOT (delivery_channel='05' AND txn_code IN ('04','13','16','17','18','97'))
                   AND add_ins_date >TRUNC(p_rundate);
                --En added by Pankaj S. on 23-Jan-2015     */             

               --IF v_err_msg='OK' THEN
               --Modified By Deepa on July 02 2012 as the fees is calculated again if the same has been mapped for the card,prodcatg,product
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_inactive_feecalc_date =p_rundate--, cap_card_stat=case when v_chk_card>0 THEN '1' else cap_card_stat END --Modified by Pankaj S. on 23-Jan-2015
                                  --sysdate--Modified by Saravanakumar on 13-Jan-2015
                                  --ADD_MONTHS (c1.cap_inactive_feecalc_date, 1)
                   WHERE rowid=c1.rd;--cap_pan_code = c1.cce_pan_code
                     --AND cap_card_stat = '8'
                     --AND cap_inst_code = p_instcode
                     --AND cap_expry_date > SYSDATE;

                  --SN Added on 06.09.2013 for DFCHOST-340(review)
                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_errmsg := 'No Records Updated in APPL_PAN 1.0';
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while updating APPL_PAN 1.0--'
                        || SUBSTR (SQLERRM, 1, 200);
               --EN Added on 06.09.2013 for DFCHOST-340(review)
               END;
            --END IF;
            END IF;                                     --Added by Arunprasath

            COMMIT;                      --Added by Pankaj S. on 18-March-2014
         END LOOP;
      END;

      --En InActivity Fee Calculation for the Card
      --Sn InActivity Fee Calculation for the Product Category
      BEGIN
         FOR c2 IN prodcatgfee
         LOOP
            v_err_msg := 'OK';

            --SN Added on 03.09.2013 for DFCHOST-340
            IF (c2.cap_inactive_feecalc_date IS NULL OR ADD_MONTHS (c2.cap_inactive_feecalc_date, 1) <= SYSDATE)
            --Added by Arunprasath
            THEN
               BEGIN
                  SELECT COUNT
                            (CASE
                                WHEN (    cce_valid_to IS NOT NULL
                                      AND (TRUNC (SYSDATE)
                                              BETWEEN cce_valid_from
                                                  AND cce_valid_to
                                          )
                                     )
                                 OR (    cce_valid_to IS NULL
                                     AND TRUNC (SYSDATE) >= cce_valid_from
                                    )
                                   THEN 1
                             END
                            )
                    INTO v_card_cnt
                    FROM cms_card_excpfee
                   WHERE cce_inst_code = p_instcode
                     AND cce_pan_code = c2.cap_pan_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_card_cnt := 0;
               END;

               --EN Added on 03.09.2013 for DFCHOST-340
               IF v_card_cnt = 0
               THEN                      --Added on 03.09.2013 for DFCHOST-340

                    BEGIN
                       SELECT MAX (cap_last_txndate)
                         INTO v_last_txndt
                         FROM cms_appl_pan
                        WHERE cap_inst_code = p_instcode AND cap_acct_no = c2.cap_acct_no;
                    EXCEPTION
                       WHEN OTHERS THEN
                          v_last_txndt := SYSDATE;
                    END;

                   IF c2.cap_last_txndate<>v_last_txndt THEN
                     CONTINUE;
                   END IF;   
                  --SN Modified for FWR-11
                  v_fee_amount := c2.cfm_fee_amt;

                  IF c2.cfm_feecap_flag = 'Y'
                  THEN
                     BEGIN
                        sp_tran_fees_cap (p_instcode,
                                          c2.cap_acct_no,
                                          TRUNC (SYSDATE),
                                          v_fee_amount,
                                          c2.cff_fee_plan,
                                          c2.cfm_fee_code,
                                          v_err_msg
                                         );                -- Added for FWR-11
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_waivamt := 0;
                     END;
                  END IF;

                  --EN Modified for FWR-11
                  BEGIN
                     SELECT cpw_waiv_prcnt
                       INTO v_cpw_waiv_prcnt
                       FROM cms_prodcattype_waiv
                      WHERE cpw_inst_code = p_instcode
                        AND cpw_prod_code = c2.cpf_prod_code
                        AND cpw_card_type = c2.cpf_card_type
                        AND cpw_fee_code = c2.cfm_fee_code
                        AND SYSDATE >= cpw_valid_from
                        AND SYSDATE <= cpw_valid_to;

                     v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
                  --C2.CFM_FEE_AMT; --Modified for FWR-11
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_waivamt := 0;
                  END;

                  -- V_FEEAMT := C2.CFM_FEE_AMT - V_WAIVAMT;
                  v_tot_clwbck_count := C2.cfm_clawback_count;
                  lp_fee_update_log (p_instcode,
                                     c2.cap_pan_code,
                                     c2.cap_pan_code_encr,
                                     c2.cfm_fee_code,
                                     -- C2.CFM_FEE_AMT,
                                     v_fee_amount,       --Modified for FWR-11
                                     c2.cff_fee_plan,
                                     c2.cpf_crgl_catg,
                                     c2.cpf_crgl_code,
                                     c2.cpf_crsubgl_code,
                                     c2.cpf_cracct_no,
                                     c2.cpf_drgl_catg,
                                     c2.cpf_drgl_code,
                                     c2.cpf_drsubgl_code,
                                     c2.cpf_dracct_no,
                                     v_waivamt,
                                     'PC',
                                     c2.cap_card_stat,
                                     --SN Added on 06.09.2013 for DFCHOST-340(review)
                                     c2.cap_acct_no,
                                     c2.cap_prod_code,
                                     c2.cap_card_type,
                                     --EN Added on 06.09.2013 for DFCHOST-340(review)
                                     c2.cfm_fee_desc,  --added by Pankaj S. onn 23-Jan-2015
                                      c2.staterestflag,
                                      c2.cap_cust_code,
                                      c2.cap_active_date,
                                      c2.cap_last_txndate,
                                      C2.CFM_CLAWBACK_TYPE,
                                      C2.CFM_CLAWBACK_MAXAMT,
                                      C2.CFM_CLAWBACK_FLAG,
                                      C2.CFT_FEE_FREQ,
                                      C2.CFT_FEETYPE_CODE,
                                     v_err_msg
                                    );

                /*--Sn added by Pankaj S. on 23-Jan-2015 
                SELECT COUNT (1)
                  INTO v_chk_card
                  FROM transactionlog
                 WHERE instcode = p_instcode
                   AND customer_card_no = c2.cap_pan_code
                   AND NOT (delivery_channel='05' AND txn_code IN ('04','13','16','17','18','97'))
                   AND add_ins_date >TRUNC(p_rundate);
                --En added by Pankaj S. on 23-Jan-2015  */

                  -- IF v_err_msg ='OK' THEN
                  --Modified By Deepa on July 02 2012 as the fees is calculated again if the same has been mapped for the card,prodcatg,product
                  BEGIN
                     UPDATE cms_appl_pan
                        SET cap_inactive_feecalc_date =p_rundate --,cap_card_stat=case when v_chk_card>0 THEN '1' else cap_card_stat END --Modified by Pankaj S. on 23-Jan-2015
                                  --sysdate--Modified by Saravanakumar on 13-Jan-2015
                                  --ADD_MONTHS (c2.cap_inactive_feecalc_date, 1)
                      WHERE rowid=c2.rd;--cap_pan_code = c2.cap_pan_code
                        --AND cap_card_stat = '8'
                       --AND cap_inst_code = p_instcode
                       -- AND cap_expry_date > SYSDATE;

                     --SN Added on 06.09.2013 for DFCHOST-340(review)
                     IF SQL%ROWCOUNT = 0
                     THEN
                        p_errmsg := 'No Records Updated in APPL_PAN 1.1';
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while updating APPL_PAN 1.1--'
                           || SUBSTR (SQLERRM, 1, 200);
                  --EN Added on 06.09.2013 for DFCHOST-340(review)
                  END;
               --END IF;
               END IF;                   --Added on 03.09.2013 for DFCHOST-340
            END IF;                                     --Added by Arunprasath

            COMMIT;                      --Added by Pankaj S. on 18-March-2014
         END LOOP;
      END;

      --En InActivity Fee Calculation for the Product Category
      --Sn InActivity Fee Calculation for the Product Category
      BEGIN
         FOR c3 IN prodfee
         LOOP
            v_err_msg := 'OK';

            IF (c3.cap_inactive_feecalc_date IS NULL OR ADD_MONTHS (c3.cap_inactive_feecalc_date, 1) <= SYSDATE)
            --Added by Arunprasath
            THEN
               --SN Added on 03.09.2013 for DFCHOST-340
               BEGIN
                  SELECT COUNT
                            (CASE
                                WHEN (    cce_valid_to IS NOT NULL
                                      AND (TRUNC (SYSDATE)
                                              BETWEEN cce_valid_from
                                                  AND cce_valid_to
                                          )
                                     )
                                 OR (    cce_valid_to IS NULL
                                     AND TRUNC (SYSDATE) >= cce_valid_from
                                    )
                                   THEN 1
                             END
                            )
                    INTO v_card_cnt
                    FROM cms_card_excpfee
                   WHERE cce_inst_code = p_instcode
                     AND cce_pan_code = c3.cap_pan_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_card_cnt := 0;
               END;

               IF v_card_cnt = 0
               THEN
                  BEGIN
                     SELECT COUNT
                               (CASE
                                   WHEN ((    cpf_valid_to IS NOT NULL
                                          AND TRUNC (SYSDATE)
                                                 BETWEEN cpf_valid_from
                                                     AND cpf_valid_to
                                         )
                                        )
                                    OR (    cpf_valid_to IS NULL
                                        AND TRUNC (SYSDATE) >= cpf_valid_from
                                       )
                                      THEN 1
                                END
                               )
                       INTO v_prdcatg_cnt
                       FROM cms_prodcattype_fees
                      WHERE cpf_inst_code = p_instcode
                        AND cpf_prod_code = c3.cpf_prod_code
                        AND cpf_card_type = c3.cap_card_type;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_prdcatg_cnt := 0;
                  END;
               END IF;

               --EN Added on 03.09.2013 for DFCHOST-340
               --Sn Modified for FWR-11
               IF v_card_cnt = 0 AND v_prdcatg_cnt = 0
               THEN                      --Added on 03.09.2013 for DFCHOST-340

                   BEGIN
                       SELECT MAX (cap_last_txndate)
                         INTO v_last_txndt
                         FROM cms_appl_pan
                        WHERE cap_inst_code = p_instcode AND cap_acct_no = c3.cap_acct_no;
                    EXCEPTION
                       WHEN OTHERS THEN
                          v_last_txndt := SYSDATE;
                    END;

                   IF c3.cap_last_txndate<>v_last_txndt THEN
                     CONTINUE;
                   END IF;   

                  v_fee_amount := c3.cfm_fee_amt;

                  IF c3.cfm_feecap_flag = 'Y'
                  THEN
                     BEGIN
                        sp_tran_fees_cap (p_instcode,
                                          c3.cap_acct_no,
                                          TRUNC (SYSDATE),
                                          v_fee_amount,
                                          c3.cff_fee_plan,
                                          c3.cfm_fee_code,
                                          v_err_msg
                                         );                -- Added for FWR-11
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_waivamt := 0;
                     END;
                  END IF;

                  --En Modified for FWR-11
                  BEGIN
                     SELECT cpw_waiv_prcnt
                       INTO v_cpw_waiv_prcnt
                       FROM cms_prodccc_waiv
                      WHERE cpw_inst_code = p_instcode
                        AND cpw_prod_code = c3.cpf_prod_code
                        AND cpw_fee_code = c3.cfm_fee_code
                        AND SYSDATE >= cpw_valid_from
                        AND SYSDATE <= cpw_valid_to;

                     v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
                  --C3.CFM_FEE_AMT; --Modified for FWR-11
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_waivamt := 0;
                  END;

                  -- V_FEEAMT := C3.CFM_FEE_AMT - V_WAIVAMT;
                  v_tot_clwbck_count := C3.cfm_clawback_count;
                  lp_fee_update_log (p_instcode,
                                     c3.cap_pan_code,
                                     c3.cap_pan_code_encr,
                                     c3.cfm_fee_code,
                                     v_fee_amount,       --Modified for FWR-11
                                     c3.cff_fee_plan,
                                     c3.cpf_crgl_catg,
                                     c3.cpf_crgl_code,
                                     c3.cpf_crsubgl_code,
                                     c3.cpf_cracct_no,
                                     c3.cpf_drgl_catg,
                                     c3.cpf_drgl_code,
                                     c3.cpf_drsubgl_code,
                                     c3.cpf_dracct_no,
                                     v_waivamt,
                                     'P',
                                     c3.cap_card_stat,
                                     --SN Added on 06.09.2013 for DFCHOST-340(review)
                                     c3.cap_acct_no,
                                     c3.cap_prod_code,
                                     c3.cap_card_type,
                                     --EN Added on 06.09.2013 for DFCHOST-340(review)
                                     c3.cfm_fee_desc,  --added by Pankaj S. onn 23-Jan-2015
                                      c3.staterestflag,
                                      c3.cap_cust_code,
                                      c3.cap_active_date,
                                      c3.cap_last_txndate,
                                       C3.CFM_CLAWBACK_TYPE,
                                       C3.CFM_CLAWBACK_MAXAMT,
                                       C3.CFM_CLAWBACK_FLAG,
                                       C3.CFT_FEE_FREQ,
                                       C3.CFT_FEETYPE_CODE,
                                     v_err_msg
                                    );

               /*--Sn added by Pankaj S. on 23-Jan-2015 
                SELECT COUNT (1)
                  INTO v_chk_card
                  FROM transactionlog
                 WHERE instcode = p_instcode
                   AND customer_card_no = c3.cap_pan_code
                   AND NOT (delivery_channel='05' AND txn_code IN ('04','13','16','17','18','97'))
                   AND add_ins_date >TRUNC(p_rundate);
                --En added by Pankaj S. on 23-Jan-2015*/ 

                  --IF v_err_msg ='OK' THEN
                  --Modified By Deepa on July 02 2012 as the fees is calculated again if the same has been mapped for the card,prodcatg,product
                  BEGIN
                     UPDATE cms_appl_pan
                        SET cap_inactive_feecalc_date =p_rundate --, cap_card_stat=case when v_chk_card>0 THEN '1' else cap_card_stat end  --Modified by Pankaj S. on 23-Jan-2015 
                                  --sysdate--Modified by Saravanakumar on 13-Jan-2015
                                  --ADD_MONTHS (c3.cap_inactive_feecalc_date, 1)
                      WHERE rowid=c3.rd;--cap_pan_code = c3.cap_pan_code
                        --AND cap_card_stat = '8'
                        --AND cap_inst_code = p_instcode
                        --AND cap_expry_date > SYSDATE;

                     --SN Added on 06.09.2013 for DFCHOST-340(review)
                     IF SQL%ROWCOUNT = 0
                     THEN
                        p_errmsg := 'No Records Updated in APPL_PAN 1.2';
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while updating APPL_PAN 1.2--'
                           || SUBSTR (SQLERRM, 1, 200);
                  END;
               --EN Added on 06.09.2013 for DFCHOST-340(review)
               --END IF;
               END IF;                   --Added on 03.09.2013 for DFCHOST-340
            END IF;                                     --Added by Arunprasath

            COMMIT;                      --Added by Pankaj S. on 18-March-2014
         END LOOP;
      END;

      --En InActivity Fee Calculation for the Product Category
      p_errmsg :=
                 'Inactivity Fee Calculated for ' || v_upd_rec_cnt || ' Cards';
   -- ELSE --Commented by Arunprasath
   --P_ERRMSG := 'Inactivity Fee can be Calculated only during Month End';--Commented by Arunprasath
   --END IF;--Commented by Arunprasath
   END pr_calc_inactive_fees;

   --Sn Added by Pankaj S. to call calc procedures one after other
   PROCEDURE pr_passive_calc (p_instcode IN NUMBER, p_lupduser IN NUMBER)
   IS
      v_errmsg   VARCHAR2 (500);
      v_rundate              DATE; --Added by Pankaj S. on 23-Jan-2015
   BEGIN
      v_rundate:=SYSDATE; --Added by Pankaj S. on 23-Jan-2015
      pr_eod_passiveperiod_calc (p_instcode, v_errmsg);
      DBMS_OUTPUT.put_line (   'Passive period calculation completed and process message is ' || v_errmsg );
      v_errmsg := NULL;
      pr_calc_inactive_fees (p_instcode, p_lupduser,v_rundate, v_errmsg);
      DBMS_OUTPUT.put_line(   'Inactivity fee calculation completed and process message is '|| v_errmsg);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Main Exception-->' || SQLERRM);
   END pr_passive_calc;
--En Added by Pankaj S. to call calc procedures one after other
END PKG_DAILY_JOBS;
/
show error;