CREATE OR REPLACE PROCEDURE VMSCMS.SP_MASBATCH_CARDSTATUSUPDATE(
    P_INSTCODE      IN NUMBER,
    P_LUPDUSER      IN NUMBER,
    P_DELIVERY_CHNL IN VARCHAR2,
    P_MSG_TYPE      IN VARCHAR2,
    P_TXN_MODE      IN VARCHAR2,
    P_MBRNUMB       IN VARCHAR2,
   -- P_TRANDATE      IN VARCHAR2, -- commented for defect id- 11441 28/06/2013
   -- P_TRANTIME      IN VARCHAR2,-- commented for defect id- 11441 28/06/2013
    P_SPPRTKEY      IN VARCHAR2,
    P_FileName      IN VARCHAR2,
    P_REVRSL_CODE   IN VARCHAR2)
AS
  /******************************************************************************
  * Created  By      : Muralidharan A
  * Created  Date    : 21-06-2013
  * REASON           : MEDAGATE HOST BATCHUPLOAD CARD STATUS UPDATE (MVHOST-383)
  * Reviewer         : Dhiraj
  * Reviewed Date    : 25-06-2013
  * Release Number   : RI0024.2_B0008
  * Modifies  By      : Ramesh A
  * Modifies  Date    : 26-06-2013
  * Modifies REASON   : Removed unwanted code and exception handled and added code for calling gpr_status procedure
   * Reviewer          : Dhiraj
   * Reviewed Date     : 27-06-2013
   * Build Number      : RI0024.2_B0009
   
   * Modifies  By      : Muralidharan A
   * Modifies  Date    : 28-06-2013
   * Modifies REASON   : Card Status Batch Upload - Details in Transactiong log table and Transaction log detail table is incorrect 
   * Reviewer          : 
   * Reviewed Date     : 
   * Build Number      : RI0024.2_B0011
   
   * Modifies  By      : Siva kumar M
   * Modifies  Date    : 05-07-2013
   * Modifies REASON   : Defect Id:11450
   * Reviewer          : 
   * Reviewed Date     : 
   * Build Number      : RI0024.3_B0003
   
   * Modifies  By      : Siva kumar M
   * Modifies  Date    : 17-07-2013
   * Modifies REASON   : Card Status Batch Upload - Details in Transactiong log table and Transaction log detail table is incorrect (Defect Id:11441)
   * Reviewer          : 
   * Reviewed Date     : 
   * Build Number      : RI0024.3_B0004
   
   * Modifies  By      : Dinesh B
   * Modifies  Date    : 24-07-2013
   * Modifies REASON   : MVHOST-492 : Card Status Batch Upload - Added rrn to update the response description in CMS_BATCHUPLOAD_DETL table.
   * Reviewer          : Sagar M.
   * Reviewed Date     : 25-07-2013
   * Build Number      : RI0024.3_B0006
   
    * Modifies  By      : Dinesh B/Sivakumar M
    * Modifies  Date    : 30-07-2013
    * Modifies REASON   : Defect Id's:-11852 & 11450: Batch Upload Card Status update  - To update transaction description and transaction type in transactionlog table 
                          and Review Comments Changes.
    * Reviewer          : Dhiraj
    * Reviewed Date     : 
    * Build Number      : RI0024.4_B0001
    
   * Modified By        : Ramesh.A
   * Modified Date      : 22-Aug-2013
   * Modified For       : MVCSD-4099 : Added pin_off validation for card activation
   
   * Modified By       : Sachin P.
   * Modified Date      : 29-AUG-2013
   * Modified For       : MVCSD-4099(Review)changes
   * Modified Reason    : Review changes
   * Reviewer           : Dhiraj
   * Reviewed Date      : 30-AUG-2013
   * Build Number       : RI0024.4_B0006
   
   
     * Modified By      : Siva kumar M.
     * Modified Date    : 13-Nov-2014
     * Modified For     : Defect id:15857
     * Modified Reason  : package id and prod id impact changes.
     * Reviewer         : spankaj
     * Build Number     : RI0027.4.3_B0004
   *****************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_req_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_topup_auth_id          transactionlog.auth_id%TYPE;
   v_spprt_key              cms_spprt_reasons.csr_spprt_key%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_base_curr              cms_inst_param.cip_param_value%TYPE;
   v_remrk                  VARCHAR2 (100);
   v_tran_date              VARCHAR2 (8);
                  -- modified for defect id- 11441 by muralidharan 28/06/2013
   v_tran_time              VARCHAR2 (8);
                     -- added for defect id- 11441 by muralidharan 28/06/2013
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance           NUMBER;
   v_ledger_balance         NUMBER;
   v_txn_type               VARCHAR2 (2);
   --V_TRANS_DESC CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; -- commented for defect id- 11441  28/06/2013
   v_cap_cust_code          cms_appl_pan.cap_cust_code%TYPE;
   v_ccount                 NUMBER (3);
   v_savngledgr_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_dup_check              NUMBER (3);
   v_prod_id                cms_prod_cattype.cpc_prod_id%TYPE;
   v_txn_code               VARCHAR2 (3);
   v_pan                    VARCHAR2 (40);
   v_new_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;
   
   --Added for calling gpr_status procedure   
     EXP_MAIN_REJECT_RECORD EXCEPTION;
   v_savepoint            NUMBER DEFAULT 0;   
   V_CAP_APPL_CODE        CMS_APPL_PAN.CAP_APPL_CODE%TYPE;    
   v_status_chk            NUMBER;
   v_expry_date            DATE;
   v_delivery_channel     NUMBER default '05';
   v_msg               varchar2(4) default '0200';
   V_PAN_NO                  VARCHAR2(40);
   V_TRANS_DESC   varchar2(50);   -- Added for defect id- 11441 28/06/2013
   V_CAM_TYPE_CODE varchar2(2);  -- Added for defect id- 11441  28/06/2013
   v_new_pan_code          cms_appl_pan.cap_pan_code_encr%type; -- Modified on 05/Aug/2013 for review comment Changes.
   v_pin_offset              CMS_APPL_PAN.cap_pin_off%TYPE; --Added for MVCSD-4099 on 22/08/2013  
   v_timestamp       timestamp;     --Added on 29.08.2013 for MVCSD-4099(Review)changes
   
    
   V_CARD_ID            CMS_PROD_CATTYPE.CPC_CARD_ID%TYPE; -- ADDED for Mantis id:15857

  CURSOR BATCH_CARDSTATUS_CUR
  IS
    SELECT *
    FROM CMS_BATCHUPLOAD_DETL
    WHERE CBD_FILE_NAME   = P_FileName
    AND CBD_RESPONSE_CODE = '00';
    
BEGIN

 
  FOR V_BATCHDETAIL IN BATCH_CARDSTATUS_CUR
  LOOP
  
    BEGIN
      V_TXN_CODE := V_BATCHDETAIL.CBD_TRAN_CODE;
         v_proxunumber := v_batchdetail.cbd_proxy_number;   --Modified On 30/07/2013 defect id - 11852
      V_ERRMSG   := 'OK';
      V_RESPCODE := '00';
      V_REMRK    := 'Online Card Status Change';
      
       v_savepoint:= v_savepoint+1;  --Added for rollback if exception occurs
       SAVEPOINT v_savepoint;
      
      V_TRAN_DATE:= TO_CHAR(SYSDATE,'YYYYMMDD'); -- added for defectid-11441 28/06/2013
      V_TRAN_TIME:= TO_CHAR(SYSDATE, 'HH24MISS'); -- added for defectid-11441 28/06/2013
     --This block is moved on top.  Modified On 30/07/2013 defect id - 11852
         -- select trans description from transaction master table for the given txn code
         BEGIN
            SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_desc
              INTO v_txn_type,
                   v_trans_desc
              FROM cms_transaction_mast
             WHERE ctm_delivery_channel = p_delivery_chnl
               AND ctm_inst_code = p_instcode
               AND ctm_tran_code = v_txn_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '89';
               v_errmsg :=
                     'Transflag  not defined for txn code '
                  || v_txn_code
                  || ' and delivery channel '
                  || p_delivery_chnl;
               RAISE exp_main_reject_record;
         END;
--End
         BEGIN
            SELECT cap_pan_code, cap_pan_code_encr
              INTO v_hash_pan, v_encr_pan       --Query modified on 26/06/2013
              FROM cms_appl_pan
             WHERE cap_proxy_number = v_batchdetail.cbd_proxy_number
               AND cap_card_stat NOT IN ('0', '9');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cap_pan_code, cap_pan_code_encr
                    INTO v_hash_pan, v_encr_pan --Query modified on 26/06/2013
                    FROM cms_appl_pan
                   WHERE cap_proxy_number = v_batchdetail.cbd_proxy_number
                     AND cap_card_stat = '0';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT   cap_pan_code,
                                 cap_pan_code_encr
                            INTO v_hash_pan,
                                 v_encr_pan     --Query modified on 26/06/2013
                            FROM cms_appl_pan
                           WHERE cap_proxy_number =
                                                v_batchdetail.cbd_proxy_number
                             AND cap_card_stat = '9'
                        ORDER BY cap_ins_date DESC;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_respcode := '165';
                           v_errmsg :=
                                 'Invalid Proxy Number '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_main_reject_record;
                     --Sn Added on 30.08.2013 for MVCSD-4099(Review)changes        
                         WHEN OTHERS THEN 
                          v_respcode := '21';
                           v_errmsg :=
                                 'Error while selecting card number for card stat 9 '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_main_reject_record;
                     --En Added on 30.08.2013 for MVCSD-4099(Review)changes       
                     END;
                 --Sn Added on 30.08.2013 for MVCSD-4099(Review)changes            
               WHEN OTHERS THEN 
                  v_respcode := '21';
                   v_errmsg :=
                                 'Error while selecting card number for card stat 0 '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_main_reject_record;
               --En Added on 30.08.2013 for MVCSD-4099(Review)changes       
               END;
            WHEN OTHERS
            THEN
               v_respcode := '165';
               v_errmsg :=
                          'Invalid Proxy Number ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --commented for defect id- 11441 by muralidharan 28/06/2013
         /* BEGIN
            V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' || SUBSTR(TRIM(P_TRANTIME), 1, 10), 'yyyymmdd hh24:mi:ss');
          EXCEPTION
          WHEN OTHERS THEN
            V_RESPCODE := '32';
            V_ERRMSG   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;*/
          --SN :Query modified on 26/06/2013
          --Sn select Pan detail
         BEGIN
            SELECT cap_prod_catg, cap_card_stat, cap_prod_code,
                   cap_card_type, cap_proxy_number, cap_acct_no,
                   cap_cust_code, cap_appl_code, cap_expry_date,
                   fn_dmaps_main (cap_pan_code_encr),cap_pin_off  --Added for MVCSD-4099 on 22/08/2013
              INTO v_cap_prod_catg, v_cap_card_stat, v_prod_code,
                   v_card_type, v_proxunumber, v_acct_number,
                   v_cap_cust_code, v_cap_appl_code, v_expry_date,
                   v_pan_no,v_pin_offset  --Added for MVCSD-4099 on 22/08/2013
              FROM cms_appl_pan 
             WHERE cap_pan_code = v_hash_pan
               AND cap_inst_code = p_instcode
               AND cap_mbr_numb = p_mbrnumb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               v_errmsg := 'Invalid Card number ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting card number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --fOR REPORTS

         --Query modified on 26/06/2013
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_balance, v_ledger_balance, v_cam_type_code
              FROM cms_acct_mast
             WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '14';
               v_errmsg := 'Invalid Card ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '12';
               v_errmsg :=
                     'Error while selecting data from card Master for card number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --Checking valid Batch upload card status Transaction code
         --Commented on 26/06/2013
         --IF V_TXN_CODE <> '27' AND V_TXN_CODE<>'28' AND V_TXN_CODE<>'29' AND V_TXN_CODE<>'30' AND V_TXN_CODE<>'31' AND V_TXN_CODE<>'32' AND V_TXN_CODE<>'33' THEN
         IF v_txn_code NOT IN ('27', '28', '29', '30', '31', '32', '33')
         THEN                                           -- Added on 26/06/2013
            BEGIN
               v_respcode := '89';
               v_errmsg := 'Invalid Transaction Code';
               RAISE exp_main_reject_record;
            END;
         END IF;

         --En select Pan detail
         IF v_txn_code = '27' AND v_acct_balance <> 0
            AND v_ledger_balance <> 0
         THEN
            v_errmsg :=
               'To Close card spending account available & ledger balance should be 0';
            v_respcode := '147';
            /* SELECT DECODE (p_delivery_chnl, '05','147')
             INTO v_respcode
             FROM DUAL;*/
            RAISE exp_main_reject_record;
         END IF;

         IF v_cap_card_stat = '3' AND v_txn_code <> '30'
         THEN                                         --Modified on 26/06/2013
            BEGIN
               SELECT COUNT (1)
                 INTO v_dup_check
                 FROM cms_htlst_reisu
                WHERE chr_inst_code = p_instcode
                  AND chr_pan_code = v_hash_pan
                  AND chr_reisu_cause = 'R'
                  AND chr_new_pan IS NOT NULL;

               IF v_dup_check > 0 AND v_txn_code <> '27'
               THEN
                  v_errmsg :=
                             'Only closing operation allowed for damage card';
                  v_respcode := '148';
                  -- SELECT DECODE (p_delivery_chnl, '05', '148') INTO v_respcode FROM DUAL;
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN                            --Added exception on 26/06/2013
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '89';
                  v_errmsg :=
                        'Error while selecting damage card details '
                     || SUBSTR (SQLERRM, 1, 500);
                  RAISE exp_main_reject_record;
            END;
         END IF;

         BEGIN
            SELECT DECODE (v_txn_code,
                           '27', 'CARDCLOSE',
                           '28', 'BLOCK',
                           '29', 'DBLOK',
                           '30', 'CARDACTIVE',
                           '31', 'CARDONHOLD',
                           '32', 'CARDEXPRED',
                           '33', 'CARDDEACT'
                          )
              INTO v_spprt_key
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '89';
               v_errmsg :=
                     'Error while selecting spprt key   for txn code'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            IF v_cap_card_stat = '4'
            THEN
               v_respcode := '14';
               v_errmsg := 'Card Restricted';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF     v_cap_card_stat = '2'
               AND v_txn_code <> '27'
               AND v_txn_code <> '29'
               AND v_txn_code <> '32'
            THEN
               v_respcode := '41';
               v_errmsg := 'Lost Card';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF v_cap_card_stat = '9'
            THEN
               v_respcode := '46';
               v_errmsg := 'Closed Card';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF v_txn_code = '28' AND v_cap_card_stat = '0'
            THEN
               v_respcode := '10';
               v_errmsg := 'Card Already Blocked';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF (   (v_txn_code = '29' AND v_cap_card_stat = '1')
                OR (v_txn_code = '30' AND v_cap_card_stat = '1')
               )
            THEN
               v_respcode := '9';
               v_errmsg := 'Card Already Activated';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF v_txn_code = '31' AND v_cap_card_stat = '6'
            THEN
               v_respcode := '172';
               v_errmsg := 'Card On Hold';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF v_txn_code = '32' AND v_cap_card_stat = '7'
            THEN
               v_respcode := '173';
               v_errmsg := 'Card Expired';
               RAISE exp_main_reject_record;
            END IF;
         END;

         BEGIN
            IF v_txn_code = '33' AND v_cap_card_stat = '0'
            THEN
               v_respcode := '174';
               v_errmsg := 'Card Already in Inactive Status';
               RAISE exp_main_reject_record;
            END IF;
         END;

         IF v_txn_code NOT IN ('28', '29')
         THEN
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = v_spprt_key
                  AND csr_inst_code = p_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_respcode := '89';
                  v_errmsg :=
                            'Change status reason code not present in master';
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  v_respcode := '89';
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         ELSE
            IF v_txn_code = '28'
            THEN
               v_resoncode := 43;
            ELSE
               v_resoncode := 54;
            END IF;
         END IF;

         IF p_spprtkey IS NULL
         THEN
            BEGIN
               SELECT DECODE (v_txn_code,
                              '27', '9',
                              '28', '2',
                              '29', '1',
                              '30', '1',
                              '31', '6',
                              '32', '7',
                              '33', '0'
                             )
                 INTO v_req_card_stat
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '89';
                  v_errmsg :=
                        'Error while selecting card stat  for support func'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         ELSE
            v_req_card_stat := p_spprtkey;
         END IF;

         --Sn GPR Card status check on 20/06/2013
         BEGIN
            sp_status_check_gpr
                     (p_instcode,
                      v_pan_no,
                      v_delivery_channel,
                      v_expry_date,
                      v_cap_card_stat,
                      v_txn_code,
                      '0',
                      v_prod_code,
                      v_card_type,
                      v_msg,
                      v_tran_date, -- modified for defect id- 11441 28/06/2013
                      v_tran_time, -- modified for defect id- 11441 28/06/2013
                      NULL,
                      NULL,
                      NULL,
                      v_respcode,
                      v_errmsg
                     );

         IF (   (V_RESPCODE <> '1' AND V_ERRMSG <> 'OK')
             OR (V_RESPCODE <> '0' AND V_ERRMSG <> 'OK')
            )
         THEN
            RAISE EXP_MAIN_REJECT_RECORD;
         ELSE
            v_status_chk := V_RESPCODE;
            V_RESPCODE:='00';  -- modified for defect id- 11441 28/06/2013
  
         END IF;
      EXCEPTION
         WHEN EXP_MAIN_REJECT_RECORD
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            V_RESPCODE := '21';
            V_ERRMSG :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      --En GPR Card status check
      IF v_status_chk = '1'
      THEN
         -- Expiry Check
         BEGIN
            IF TO_DATE (V_TRAN_DATE, 'YYYYMMDD') >  -- modified for defect id- 11441  28/06/2013 
                               LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY'))
            THEN
               V_RESPCODE := '21';
               V_ERRMSG := 'EXPIRED CARD';
               RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               V_RESPCODE := '21';
               V_ERRMSG :=
                    'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;        
 
      END IF;
         -- End Expiry Check
     
    
        
        
      --Query modified on 26/06/2013
        IF V_REQ_CARD_STAT = '1' AND V_TXN_CODE ='30' THEN
        
        --Sn Added for MVCSD-4099 on 22/08/2013
         IF v_pin_offset is null  THEN 
              v_respcode := '52';
              v_errmsg   := 'PIN Generation not done';
           RAISE exp_main_reject_record;
         END IF;
         --End Added for MVCSD-4099 on 22/08/2013
         
            BEGIN
               SELECT chr_new_pan,chr_new_pan_encr -- Modified  on 05/Aug/2013 for review comment Changes.
                                   -- modified for defect id- 11441 28/06/2013
                 INTO v_new_hash_pan,v_new_pan_code
                 FROM cms_htlst_reisu
                WHERE chr_inst_code = p_instcode
                  AND chr_pan_code = v_hash_pan
                  AND chr_reisu_cause = 'R'
                  AND chr_new_pan IS NOT NULL;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_NEW_HASH_PAN:= NULL;
            WHEN OTHERS THEN
              v_respcode := '89';
              v_errmsg   := 'Error while selecting  card details ' || SUBSTR (SQLERRM, 1, 100);
              RAISE exp_main_reject_record;
            END;
               -- BEGIN
                  IF V_NEW_PAN_CODE IS NOT NULL THEN -- modified for defect id- 11441 28/06/2013
                        BEGIN
                          UPDATE CMS_APPL_PAN
                          SET CAP_CARD_STAT ='9'
                          WHERE CAP_PAN_CODE=V_HASH_PAN
                          AND CAP_INST_CODE = P_INSTCODE
                          AND CAP_MBR_NUMB  = P_MBRNUMB;
                          IF SQL%ROWCOUNT  !=1 THEN
                            V_RESPCODE     := '89';
                            V_ERRMSG       := 'Problem in updation of old card status.' || SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_MAIN_REJECT_RECORD;
                          END IF;
                        EXCEPTION
                        WHEN EXP_MAIN_REJECT_RECORD THEN
                          RAISE;
                        WHEN OTHERS THEN
                          V_RESPCODE := '89';
                          V_ERRMSG   := 'Error ocurs while old card status  ' || SUBSTR(SQLERRM, 1, 200);
                          RAISE EXP_MAIN_REJECT_RECORD;
                        END;
                        
                    -- modified for defect id- 11441 28/06/2013    
                        
                       BEGIN
                       sp_log_cardstat_chnge (P_INSTCODE,
                                              V_HASH_PAN,
                                              V_ENCR_PAN,
                                              V_TOPUP_AUTH_ID,
                                              '02',
                                              V_BATCHDETAIL.cbd_rrn,
                                              V_tran_date,
                                              V_tran_time,
                                              V_RESPCODE,
                                              V_ERRMSG
                                             );

                           IF V_RESPCODE <> '00' AND V_ERRMSG <> 'OK'
                           THEN
                              RAISE EXP_MAIN_REJECT_RECORD;
                           END IF;
                   
                      EXCEPTION
                           WHEN EXP_MAIN_REJECT_RECORD
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              V_RESPCODE := '21';
                              V_ERRMSG :=
                                    'Error while logging system initiated card status change '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE EXP_MAIN_REJECT_RECORD;
                      END;
                      
                              -- Commented on 05/Aug/2013 for review comments Changes.
                        /*   BEGIN
                                V_HASH_PAN := GETHASH(V_NEW_PAN_CODE);
                          EXCEPTION
                              WHEN OTHERS THEN
                                V_RESPCODE := '21'; 
                                       V_ERRMSG   := 'Error while converting pan ' ||
                                                   SUBSTR(SQLERRM, 1, 200);
                             RAISE EXP_MAIN_REJECT_RECORD;
                          END;
                          
                          
                        BEGIN
                            V_ENCR_PAN := FN_EMAPS_MAIN(V_NEW_PAN_CODE);
                          EXCEPTION
                            WHEN OTHERS THEN
                             V_RESPCODE := '21'; -- added by chinmaya
                             V_ERRMSG   := 'Error while converting pan ' ||
                                        SUBSTR(SQLERRM, 1, 200);
                             RAISE EXP_MAIN_REJECT_RECORD;
                        END;
                      */  
                      
                      v_hash_pan := v_new_hash_pan; -- added  on 05/Aug/2013 for review comment changes.
                      v_encr_pan := v_new_pan_code; -- added  on 05/Aug/2013 for review comment changes.
                      V_CAP_CARD_STAT:=V_REQ_CARD_STAT;
                      
                   
                  END IF;
                --END;
                                       -- Modified for defect id:11450
               -- NEW CARD DETAILS 
                 BEGIN
                        SELECT CAP_PROD_CODE,
                          CAP_CARD_TYPE,
                          cap_prfl_code, 
                          cap_prfl_levl   
                          INTO 
                          V_PROD_CODE,
                          V_CARD_TYPE,
                          v_lmtprfl,
                          v_profile_level 
                        FROM CMS_APPL_PAN
                        WHERE CAP_PAN_CODE = V_HASH_PAN
                        AND CAP_INST_CODE  = P_INSTCODE
                        AND CAP_MBR_NUMB   = P_MBRNUMB;
                      EXCEPTION                           
                      WHEN NO_DATA_FOUND THEN
                        V_RESPCODE := '89';
                        V_ERRMSG   := 'Invalid Card number ' || SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_MAIN_REJECT_RECORD;
                      WHEN OTHERS THEN
                        V_RESPCODE := '89';
                        V_ERRMSG   := 'Error while selecting card number ' || SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_MAIN_REJECT_RECORD;
                END;
                            
                IF v_lmtprfl IS NULL OR v_profile_level IS NULL  
                      THEN
                        BEGIN
                         SELECT cpl_lmtprfl_id
                           INTO v_lmtprfl
                           FROM cms_prdcattype_lmtprfl
                          WHERE cpl_inst_code = P_INSTCODE
                            AND cpl_prod_code = v_prod_code
                            AND cpl_card_type = V_CARD_TYPE;

                         v_profile_level := 2;
                      EXCEPTION
                         WHEN NO_DATA_FOUND
                         THEN
                            BEGIN
                               SELECT cpl_lmtprfl_id
                                 INTO v_lmtprfl
                                 FROM cms_prod_lmtprfl
                                WHERE cpl_inst_code = P_INSTCODE
                                  AND cpl_prod_code = v_prod_code;

                               v_profile_level := 3;
                            EXCEPTION
                               WHEN NO_DATA_FOUND
                               THEN
                                  NULL;
                               WHEN OTHERS
                               THEN
                                  v_respcode := '21';
                                  V_ERRMSG:=
                                        'Error while selecting Limit Profile At Product Level'
                                     || SQLERRM;
                                  RAISE exp_main_reject_record;
                            END;
                         WHEN OTHERS
                         THEN
                            v_respcode := '21';
                           V_ERRMSG :=
                                  'Error while selecting Limit Profile At Product Catagory Level'
                               || SQLERRM;
                            RAISE exp_main_reject_record;
                      END;
              END IF;                                          

               IF v_lmtprfl IS NOT NULL    THEN   
                                                               
                  BEGIN
                     UPDATE cms_appl_pan
                        SET cap_prfl_code = v_lmtprfl,
                            cap_prfl_levl = v_profile_level
                       WHERE  cap_inst_code =P_INSTCODE 
                       AND cap_pan_code = v_hash_pan;
                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_respcode := '21';
                        v_errmsg := 'Limit Profile not updated for :' || v_hash_pan;
                        RAISE exp_main_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_main_reject_record
                     THEN
                        RAISE exp_main_reject_record;
                     WHEN OTHERS
                     THEN
                        v_respcode := '21';
                        v_errmsg :=
                           'Error while Limit profile Update '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
                          
               END IF;
                
            BEGIN
              UPDATE CMS_APPL_PAN
              SET CAP_ACTIVE_DATE=SYSDATE,  -- added for defect Id 11450
              CAP_FIRSTTIME_TOPUP='Y'
              WHERE CAP_INST_CODE    = P_INSTCODE
              AND CAP_PAN_CODE       = V_HASH_PAN
              AND CAP_MBR_NUMB       = P_MBRNUMB;
              IF SQL%ROWCOUNT       !=1 THEN
                V_RESPCODE          := '89';
                V_ERRMSG            := 'Problem in updation of first time topup flag.';
              END IF;
            EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD THEN
              RAISE;
            WHEN OTHERS THEN
              V_RESPCODE := '89';
              V_ERRMSG   := 'Error ocurs while updating first time topup flag ' || SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
            END;
            
        BEGIN
    
          --Query modified on 26/06/2013
          UPDATE CMS_CAF_INFO_ENTRY
          SET CCI_KYC_FLAG   ='Y'
          WHERE CCI_APPL_CODE=V_CAP_APPL_CODE            
          AND CCI_INST_CODE=P_INSTCODE;
          
          IF SQL%ROWCOUNT !=1 THEN
            V_RESPCODE    := '89';
            V_ERRMSG      := 'Problem in updation of KYC  flag.';
            RAISE EXP_MAIN_REJECT_RECORD;
          END IF;
          
        EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESPCODE := '89';
          V_ERRMSG   := 'Error ocurs while updating KYC  flag ' || SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;

        BEGIN   
          /*SELECT CPC_PROD_ID               COMMENTED FOR PACKAGE ID /PROD ID IMPACT CHANGES.
          INTO V_PROD_ID
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE=V_PROD_CODE
          AND CPC_CARD_TYPE  =V_CARD_TYPE
          AND CPC_INST_CODE  = P_INSTCODE;*/
          
           SELECT CPC_CARD_ID
          INTO V_CARD_ID
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE=V_PROD_CODE
          AND CPC_CARD_TYPE  =V_CARD_TYPE
          AND CPC_INST_CODE  = P_INSTCODE;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while selecting PROD_ID ' || SUBSTR(SQLERRM, 1, 200);
          V_RESPCODE := '89';
          RAISE EXP_MAIN_REJECT_RECORD;
        END;

       -- IF V_PROD_ID IS NOT NULL THEN   COMMENTED FOR PACKAGE ID /PROD ID IMPACT CHANGES.
        IF V_CARD_ID IS NOT NULL THEN
          BEGIN
            UPDATE CMS_CARDISSUANCE_STATUS
            SET CCS_CARD_STATUS='15'
            WHERE CCS_PAN_CODE =V_HASH_PAN
            AND CCS_INST_CODE  =P_INSTCODE;
            
            
            --To handle no rows updated exception
             IF SQL%ROWCOUNT           = 0 THEN
               V_ERRMSG               :='Error ocurs while updating applicationn status';
               RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
              --Ends
          EXCEPTION
          --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes
          WHEN EXP_MAIN_REJECT_RECORD THEN
           RAISE; 
          --En Added on 29.08.2013 for MVCSD-4099(Review)changes  
          WHEN OTHERS THEN
            V_RESPCODE := '89';
            V_ERRMSG   := 'Error ocurs while updating applicationn status ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
        END IF;
        
      END IF;
      
      BEGIN
        --Begin 2 starts
        UPDATE CMS_APPL_PAN
        SET CAP_CARD_STAT   = V_REQ_CARD_STAT
        WHERE CAP_INST_CODE = P_INSTCODE
        AND CAP_PAN_CODE    = V_HASH_PAN
        AND CAP_MBR_NUMB    = P_MBRNUMB;
        IF SQL%ROWCOUNT    != 1 THEN
          V_RESPCODE       := '89';
          V_ERRMSG         := 'Problem in updation of status for pan ' || SUBSTR(SQLERRM, 1, 200) || '.';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
        IF V_TXN_CODE IN ('29') THEN
          UPDATE CMS_PIN_CHECK
          SET CPC_PIN_COUNT   = 0,
            CPC_LUPD_DATE     = TO_DATE(V_TRAN_DATE, 'YYYY/MM/DD') -- modified for defect id- 11441 28/06/2013
          WHERE CPC_INST_CODE = P_INSTCODE
          AND CPC_PAN_CODE    = V_HASH_PAN;
        END IF;
      EXCEPTION
        --excp of begin 2
      WHEN EXP_MAIN_REJECT_RECORD 
        THEN
        RAISE;
      WHEN OTHERS THEN
        V_RESPCODE := '89';
        V_ERRMSG   := 'Error ocurs while updating card status-- ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
      END; --begin 2 ends
      
     
      BEGIN
        INSERT
        INTO CMS_PAN_SPPRT
          (
            CPS_INST_CODE,
            CPS_PAN_CODE,
            CPS_MBR_NUMB,
            CPS_PROD_CATG,
            CPS_SPPRT_KEY,
            CPS_SPPRT_RSNCODE,
            CPS_FUNC_REMARK,
            CPS_INS_USER,
            CPS_LUPD_USER,
            CPS_CMD_MODE,
            CPS_PAN_CODE_ENCR
          )
          VALUES
          (
            P_INSTCODE,
            V_HASH_PAN,
            P_MBRNUMB,
            V_CAP_PROD_CATG,
            DECODE(V_TXN_CODE, '27', 'CARDCLOSE', '28', 'BLOCK', '29', 'DBLOK', '30', 'CARDACTIVE', '31', 'CARDONHOLD', '32', 'CARDEXPRED', '33', 'CARDDEACT'),
            V_RESONCODE,
            V_REMRK,
            P_LUPDUSER,
            P_LUPDUSER,
            0,
            V_ENCR_PAN
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESPCODE := '89';
        V_ERRMSG   := 'Error while inserting records into card support master' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
     
      --Sn generate auth id
      BEGIN
        SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_TOPUP_AUTH_ID FROM DUAL;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERRMSG   := 'Error while generating authid ' || SUBSTR(SQLERRM, 1, 300);
        V_RESPCODE := '89'; -- Server Declined
        
      END;
      --Sn select response code and insert record into txn log dtl
     
     v_timestamp := systimestamp; --Added on 29.08.2013 for MVCSD-4099(Review)changes
      --Sn create a entry in txn log
      BEGIN
        INSERT
        INTO TRANSACTIONLOG
          (
            MSGTYPE,
            RRN,
            DELIVERY_CHANNEL,
            TERMINAL_ID,
            DATE_TIME,
            TXN_CODE,
            TXN_TYPE,
            TXN_MODE,
            TXN_STATUS,
            RESPONSE_CODE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CUSTOMER_CARD_NO,
            TOPUP_CARD_NO,
            TOPUP_ACCT_NO,
            TOPUP_ACCT_TYPE,
            BANK_CODE,
            TOTAL_AMOUNT,
            CURRENCYCODE,
            ADDCHARGE,
            PRODUCTID,
            CATEGORYID,
            ATM_NAME_LOCATION,
            AUTH_ID,
            AMOUNT,
            PREAUTHAMOUNT,
            PARTIALAMOUNT,
            INSTCODE,
            CUSTOMER_CARD_NO_ENCR,
            TOPUP_CARD_NO_ENCR,
            PROXY_NUMBER,
            REVERSAL_CODE,
            CUSTOMER_ACCT_NO,
            ACCT_BALANCE,
            LEDGER_BALANCE,
            CR_DR_FLAG, -- added for defect id- 11441 28/06/2013
            RESPONSE_ID,
            CARDSTATUS, 
            TRANS_DESC, 
            ERROR_MSG,
            ACCT_TYPE, -- added for defect id- 11441  28/06/2013
            TIME_STAMP           
          )
          VALUES
          (
            P_MSG_TYPE,
            V_BATCHDETAIL.CBD_RRN,
            P_DELIVERY_CHNL,
            NULL,
            SYSDATE,
            V_TXN_CODE,
            V_TXN_TYPE,
            P_TXN_MODE,
            DECODE(V_RESPCODE, '00', 'C', 'F'),
            V_RESPCODE,
            V_TRAN_DATE,-- modified for defect id- 11441 28/06/2013
            V_TRAN_TIME,-- modified for defect id- 11441 28/06/2013
            V_HASH_PAN,
            NULL,
            NULL,
            NULL,
            P_INSTCODE,
            NULL,
            NULL,
            NULL,
            V_PROD_CODE,
            V_CARD_TYPE,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            P_INSTCODE,
            V_ENCR_PAN,
            V_ENCR_PAN,  
            V_PROXUNUMBER,
            P_REVRSL_CODE,
            V_ACCT_NUMBER,
            V_ACCT_BALANCE,
            V_LEDGER_BALANCE,
            'NA',        -- modified for defect id- 11441 28/06/2013
            V_RESPCODE,
            V_CAP_CARD_STAT,
            V_TRANS_DESC,    
            V_ERRMSG,
            V_CAM_TYPE_CODE ,   -- modified for defect id- 11441 28/06/2013
            v_timestamp --Added on 29.08.2013 for MVCSD-4099(Review)changes
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESPCODE := '69';
        V_ERRMSG   := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 300);
      END;
      
      BEGIN
        INSERT
        INTO CMS_TRANSACTION_LOG_DTL
          (
            CTD_DELIVERY_CHANNEL,
            CTD_TXN_CODE,
            CTD_MSG_TYPE,
            CTD_TXN_MODE,
            CTD_BUSINESS_DATE,
            CTD_BUSINESS_TIME,
            CTD_CUSTOMER_CARD_NO,
            CTD_TXN_AMOUNT,
            CTD_TXN_CURR,
            CTD_ACTUAL_AMOUNT,
            CTD_FEE_AMOUNT,
            CTD_WAIVER_AMOUNT,
            CTD_SERVICETAX_AMOUNT,
            CTD_CESS_AMOUNT,
            CTD_BILL_AMOUNT,
            CTD_BILL_CURR,
            CTD_PROCESS_FLAG,
            CTD_PROCESS_MSG,
            CTD_RRN,
            CTD_INST_CODE,
            CTD_CUSTOMER_CARD_NO_ENCR,
            CTD_CUST_ACCT_NUMBER,
            CTD_TXN_TYPE
          )
          VALUES
          (
            P_DELIVERY_CHNL,
            V_TXN_CODE,
            P_MSG_TYPE,
            P_TXN_MODE,
            V_TRAN_DATE,-- modified for defect id- 11441 28/06/2013
            V_TRAN_TIME,-- modified for defect id- 11441  28/06/2013
            V_HASH_PAN,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            'Y',          -- Modified for defect id -11441 on 17/07/2013
            'Successful', -- Modified on 05/aug/2013 for reveiw comments Changes.
            V_BATCHDETAIL.CBD_RRN,
            P_INSTCODE,
            V_ENCR_PAN,
            V_ACCT_NUMBER,
            V_TXN_TYPE
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERRMSG   := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 300);
        V_RESPCODE := '69';
       
      END;
     
      
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK TO v_savepoint;  --Added on 26/06/2013
   
      BEGIN
        UPDATE CMS_BATCHUPLOAD_DETL
        SET CBD_RESPONSE_CODE = V_RESPCODE,
          CBD_RESPONSE_DESC   = V_ERRMSG
          WHERE CBD_TRAN_CODE=V_TXN_CODE
          AND   CBD_PROXY_NUMBER= V_PROXUNUMBER
          AND  CBD_INS_DATE=V_BATCHDETAIL.CBD_INS_DATE
          AND CBD_FILE_NAME=V_BATCHDETAIL.CBD_FILE_NAME
              AND CBD_RRN=V_BATCHDETAIL.CBD_RRN --Added for MVHOST:492 on 24/07/2013
          AND CBD_INST_CODE=P_INSTCODE;
          
           --To handle no rows updated exception
             IF SQL%ROWCOUNT           = 0 THEN
               V_ERRMSG               :='Problem while updating data into CMS_BATCHUPLOAD_DETL table';
            --   RAISE EXP_MAIN_REJECT_RECORD; --Commented on 29.08.2013 for MVCSD-4099(Review)changes  
            END IF;
              --Ends
            

      EXCEPTION
      
      WHEN OTHERS THEN
        V_ERRMSG   := 'Problem while updating data into CMS_BATCHUPLOAD_DETL table' || SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '89';
      END;
      
      v_timestamp := systimestamp; --Added on 29.08.2013 for MVCSD-4099(Review)changes
      
      BEGIN
        INSERT
        INTO TRANSACTIONLOG
          (
            MSGTYPE,
            RRN,
            DELIVERY_CHANNEL,
            TERMINAL_ID,
            DATE_TIME,
            TXN_CODE,
            TXN_TYPE,
            TXN_MODE,
            TXN_STATUS,
            RESPONSE_CODE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CUSTOMER_CARD_NO,
            TOPUP_CARD_NO,
            TOPUP_ACCT_NO,
            TOPUP_ACCT_TYPE,
            BANK_CODE,
            TOTAL_AMOUNT,
            CURRENCYCODE,
            ADDCHARGE,
            PRODUCTID,
            CATEGORYID,
            ATM_NAME_LOCATION,
            AUTH_ID,
            AMOUNT,
            PREAUTHAMOUNT,
            PARTIALAMOUNT,
            INSTCODE,
            CUSTOMER_CARD_NO_ENCR,
            TOPUP_CARD_NO_ENCR, 
            PROXY_NUMBER,
            REVERSAL_CODE,
            CUSTOMER_ACCT_NO,
            ACCT_BALANCE,
            LEDGER_BALANCE,
            CR_DR_FLAG, -- added for defect id- 11441 28/06/2013
            RESPONSE_ID,
            CARDSTATUS, 
            TRANS_DESC, 
            ERROR_MSG,
            ACCT_TYPE , -- added for defect id- 11441 28/06/2013
            time_stamp --Added on 29.08.2013 for MVCSD-4099(Review)changes
          )
          VALUES
          (
            P_MSG_TYPE,
            V_BATCHDETAIL.CBD_RRN,
            P_DELIVERY_CHNL,
            NULL,
            SYSDATE,
            V_TXN_CODE,
            V_TXN_TYPE,
            P_TXN_MODE,
            DECODE(V_RESPCODE, '00', 'C', 'F'),
            V_RESPCODE,
            V_TRAN_DATE,-- modified for defect id- 11441 28/06/2013
            V_TRAN_TIME,-- modified for defect id- 11441 28/06/2013
            V_HASH_PAN,
            NULL,
            NULL,
            NULL,
            P_INSTCODE,
            NULL,
            NULL,
            NULL,
            V_PROD_CODE,
            V_CARD_TYPE,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            P_INSTCODE,
            V_ENCR_PAN,
            V_ENCR_PAN,  
            V_PROXUNUMBER,
            P_REVRSL_CODE,
            V_ACCT_NUMBER,
            V_ACCT_BALANCE,
            V_LEDGER_BALANCE,
            'NA',        -- added for defect id- 11441 28/06/2013
            V_RESPCODE,
            V_CAP_CARD_STAT, 
            V_TRANS_DESC,    
            V_ERRMSG,
            V_CAM_TYPE_CODE , -- added for defect id- 11441 28/06/2013
            v_timestamp --Added on 29.08.2013 for MVCSD-4099(Review)changes
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESPCODE := '69';
        V_ERRMSG   := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 300);       
      END;
      --Sn Create an entry in transaction_log_dtl
      BEGIN
        INSERT
        INTO CMS_TRANSACTION_LOG_DTL
          (
            CTD_DELIVERY_CHANNEL,
            CTD_TXN_CODE,
            CTD_MSG_TYPE,
            CTD_TXN_MODE,
            CTD_BUSINESS_DATE,
            CTD_BUSINESS_TIME,
            CTD_CUSTOMER_CARD_NO,
            CTD_TXN_AMOUNT,
            CTD_TXN_CURR,
            CTD_ACTUAL_AMOUNT,
            CTD_FEE_AMOUNT,
            CTD_WAIVER_AMOUNT,
            CTD_SERVICETAX_AMOUNT,
            CTD_CESS_AMOUNT,
            CTD_BILL_AMOUNT,
            CTD_BILL_CURR,
            CTD_PROCESS_FLAG,
            CTD_PROCESS_MSG,
            CTD_RRN,
            CTD_INST_CODE,
            CTD_CUSTOMER_CARD_NO_ENCR,
            CTD_CUST_ACCT_NUMBER,
            CTD_TXN_TYPE
          )
          VALUES
          (
            P_DELIVERY_CHNL,
            V_TXN_CODE,
            P_MSG_TYPE,
            P_TXN_MODE,
            V_TRAN_DATE,-- modified for defect id- 11441  28/06/2013
            V_TRAN_TIME,-- modified for defect id- 11441 28/06/2013
            V_HASH_PAN,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            'E',
            V_ERRMSG,
            V_BATCHDETAIL.CBD_RRN,
            P_INSTCODE,
            V_ENCR_PAN,
            V_ACCT_NUMBER,
            V_TXN_TYPE
          );
      EXCEPTION
      WHEN OTHERS THEN
   
        V_ERRMSG   := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM, 1, 300);
        V_RESPCODE := '69';       
      END;
      --En Create an entry in transaction_log_dtl
    END;
  END LOOP;
END;
/
SHOW ERROR;
