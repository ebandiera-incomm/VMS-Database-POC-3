CREATE OR REPLACE PROCEDURE VMSCMS.sp_migr_rollback (
   p_migr_seq   IN       NUMBER,
   p_migruser   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS
   v_migr_seqno            NUMBER (5);
   v_check_otherset_card   VARCHAR2 (2)    := 'N';
   v_check_online_card     VARCHAR2 (2)    := 'N';
   v_online_txn            VARCHAR2 (2)    := 'N';
   v_chk_acct              NUMBER (5);
   v_check_card            NUMBER (5);
   v_txn_check             NUMBER (5);
   v_chk_roll              NUMBER (5);
   v_validate_flag         VARCHAR2 (2);
   v_instcode              NUMBER (5)      := 1;
   v_indx                  NUMBER (5);
   v_errmsg                VARCHAR2 (500);
   v_reason                VARCHAR2 (500);
   v_temp_pan              VARCHAR2 (20);
   v_temp_acct             VARCHAR2 (20);
   v_acct_file_cnt         NUMBER (5);
   v_card_file_cnt         NUMBER (5);
   v_tran_file_cnt         NUMBER (5);
   v_chk_invalid_seqno     NUMBER (5);
   v_chk_txn               NUMBER (5);
   v_chk_mail_addr         NUMBER(1); 
   v_mail_addr             cms_addr_mast.cam_addr_code%type;

   CURSOR cur_file
   IS
      SELECT   mfi_file_name, mfi_process_date
          FROM migr_file_load_info
         WHERE mfi_migr_seqno = p_migr_seq
           AND mfi_process_status = 'OK'
           AND mfi_file_name LIKE '%CUST%'
      ORDER BY mfi_file_name, mfi_migr_seqno;

   TYPE array_card_data IS TABLE OF VARCHAR2 (100)
      INDEX BY PLS_INTEGER;

   v_array_card_data       array_card_data;

   PROCEDURE lp_migr_rollback_data (
      l_inst_code    IN       NUMBER,
      l_file_name    IN       VARCHAR2,
      l_migr_seqno   IN       NUMBER,
      l_acct_id      IN       VARCHAR2,
      l_acct_type    IN       VARCHAR2,
      l_cust_code    IN       NUMBER,
      l_migr_user    IN       NUMBER,
      l_mail_addr    IN       NUMBER, 
      l_errmsg       OUT      VARCHAR2
   )
   AS
      v_sel_cnt             NUMBER (20)                              := 0;
      v_del_cnt             NUMBER (20)                              := 0;
      v_acct_id             cms_acct_mast.cam_acct_id%TYPE;
      v_merinv_ordr         cms_merinv_merpan.cmm_ordr_refrno%TYPE;
      v_cap_appl_code       cms_appl_pan.cap_appl_code%TYPE;
      v_cap_cust_code       cms_appl_pan.cap_cust_code%TYPE;
      v_cap_acct_no         cms_appl_pan.cap_acct_no%TYPE;
      v_cap_prod_code       cms_appl_pan.cap_prod_code%TYPE;
      v_cap_card_type       cms_appl_pan.cap_card_type%TYPE;
      v_cap_cust_catg       cms_appl_pan.cap_cust_catg%TYPE;
      v_cap_acct_id         cms_appl_pan.cap_acct_id%TYPE;
      excp_exit_proc        EXCEPTION;
      v_cust_file           migr_caf_info_entry.mci_file_name%TYPE;
      v_tran_cnt            NUMBER (10);
      v_spend_saving_acct   VARCHAR2 (50);
      v_spending_acct       VARCHAR2 (20);
      v_chk_accts           NUMBER (5);
      v_gethash             cms_appl_pan.cap_pan_code%TYPE;
      v_financial_cnt       NUMBER (10);
      v_dispute_cnt         NUMBER (10);
      v_c2c_cnt             NUMBER (10);
      v_manadj_cnt          NUMBER (10);
      v_preauth_cnt         NUMBER (10);
      v_merinv_ordr_cnt     NUMBER (10);
      v_hold_release_cnt    NUMBER (10);
      v_saving_acct         CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
      v_del_FLAG            NUMBER (1)                              := 0;

      
      TYPE cust_det_tab IS RECORD
      (
        pan_code    cms_appl_pan.cap_pan_code%TYPE,
        addr_code   cms_appl_pan.cap_bill_addr%TYPE
      );

      type table_pan_addrcode is table of cust_det_tab index by binary_integer;  

      v_pan_addrcode table_pan_addrcode;
      
      --TYPE pan_tab IS TABLE OF cms_appl_pan.cap_pan_code%TYPE INDEX BY PLS_INTEGER;
      --v_pan_code              pan_tab;
      --TYPE addr_tab IS TABLE OF cms_appl_pan.cap_bill_addr%TYPE INDEX BY PLS_INTEGER;
      --v_addr_code           addr_tab;
      v_pan_string          clob;
      v_addr_string         clob;
      v_query               clob;
      
      
   BEGIN
      l_errmsg := 'OK';
      
      BEGIN
           SELECT cap_pan_code,cap_bill_addr bulk collect into v_pan_addrcode
           from cms_appl_pan
           WHERE cap_inst_code = l_inst_code
           AND cap_cust_code = l_cust_code;
           
            for i in 1..v_pan_addrcode.count 
            loop
                v_pan_string :=  v_pan_string||''''||v_pan_addrcode(i).pan_code||''''||',';
                v_addr_string := v_addr_string||''''||v_pan_addrcode(i).addr_code||''''||',';
            end loop;
            
            
            
          v_pan_string := substr(v_pan_string,1,instr(v_pan_string,',',-1)-1);
          
          v_addr_string := substr(v_addr_string,1,instr(v_addr_string,',',-1)-1);
          
          if l_mail_addr is not null
          then
               v_addr_string := v_addr_string||','||''''||l_mail_addr||''''; --append l_mail_addr mailing addr code          
          
          end if; 
          
           v_addr_string := ltrim(rtrim(v_addr_string,','),',');
          
      EXCEPTION 
          WHEN NO_DATA_FOUND
          THEN 
                l_errmsg :='DATA NOT FOUND IN APPL PAN'|| SUBSTR (SQLERRM, 1, 200);
                   RAISE excp_exit_proc; 
          WHEN OTHERS
          THEN
                l_errmsg :='ERROR WHILE SELECTING PAN CODE LIST'|| SUBSTR (SQLERRM, 1, 200);
                   RAISE excp_exit_proc;      
      END; 
      
     /*   --Commented for PT on 10-oct-2013
          
      IF l_addr_flag IS NULL -- it means there is no mailing address
      THEN
      
          BEGIN
               SELECT cap_bill_addr bulk collect into v_addr_code
               from cms_appl_pan
               WHERE cap_inst_code = l_inst_code
               AND cap_cust_code = l_cust_code;
               
                for i in 1..v_addr_code.count loop
                    v_addr_string := v_addr_string||''''||v_addr_code(i)||''''||',';
                end loop;
                
              v_addr_string := substr(v_addr_string,1,instr(v_addr_string,',',-1)-1);
              
          EXCEPTION 
              WHEN NO_DATA_FOUND
              THEN 
                    l_errmsg :='DATA NOT FOUND IN APPL PAN FOR ADDR CODES'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE excp_exit_proc; 
              WHEN OTHERS
              THEN
                    l_errmsg :='ERROR WHILE SELECTING ADDR CODE LIST'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE excp_exit_proc;      
          END;
          
      END IF;              
     */     --Commented for PT on 10-oct-2013   
      
      BEGIN
      
        --IF l_acct_type = 1        --commented on 10-oct-2013
        --THEN
          
           /* 
            select cca_acct_id
            into   v_saving_acct
            from cms_cust_acct,cms_acct_mast 
            where cca_cust_code = l_cust_code
            and   cca_acct_id=cam_acct_id
            and   cam_type_code = '2';
           */ 

            select cca_acct_id                 --Added on 10-oct-2013 for PT
            into   v_saving_acct
            from  cms_cust_acct
            where cca_inst_code = l_inst_code
            and   cca_cust_code = l_cust_code
            and   cca_acct_id <> l_acct_id;

          
        --END IF;            
          
            
      EXCEPTION WHEN NO_DATA_FOUND
      THEN 
          v_saving_acct := NULL;
      WHEN OTHERS
      THEN
      
            l_errmsg :=
                     'ERROR WHILE SAVING ACCT CHECK'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;      
      
      END;        
        

      --SN: Rollback Saving Account data in file
      IF l_acct_type = 2
      THEN
         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_cust_acct
                  WHERE cca_inst_code = l_inst_code
                    AND cca_cust_code = l_cust_code;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := SQL%ROWCOUNT;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_CUST_ACCT',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_CUST_ACCT DATA ROLLBACK FOR SAVING ACCT'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_acct_mast
                  WHERE cam_inst_code = l_inst_code
                    AND cam_acct_id = l_acct_id;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_ACCT_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_ACCT_MAST DATA ROLLBACK FOR SAVING ACCT'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;
      --EN: Rollback Saving Account data in file
      ELSE
      
          begin
             v_query := 'SELECT COUNT (CASE
                              WHEN response_code = '||''''||'00'||''''||'
                              AND (cr_dr_flag IN ('||''''||'DR'||''''||','||''''||'CR'||''''||') OR tranfee_amt > 0)
                                 THEN 1
                           END
                          ),
                    COUNT (CASE
                              WHEN delivery_channel = '||''''||'03'||''''||'
                              AND txn_code = '||''''||'25'||''''||'
                                 THEN 1
                           END
                          ),
                    COUNT (CASE
                              WHEN delivery_channel = '||''''||'03'||''''||'
                              AND txn_code = '||''''||'38'||''''||'
                                 THEN 1
                           END
                          ),
                    COUNT (CASE
                              WHEN response_code = '||''''||'00'||''''||'
                              AND delivery_channel = '||''''||'03'||''''||'
                              AND txn_code IN ('||''''||'13'||''''||','||''''||'14'||''''||')
                                 THEN 1
                           END
                          ),
                    COUNT (CASE
                              WHEN response_code = '||''''||'00'||''''||'
                              AND delivery_channel = '||''''||'02'||''''||'
                              AND txn_code IN ('||''''||'11'||''''||','||''''||'12'||''''||')
                                 THEN 1
                           END
                          ),
                    COUNT (CASE
                              WHEN response_code = '||''''||'00'||''''||'
                              AND delivery_channel = '||''''||'03'||''''||'
                              AND txn_code ='||''''||'11'||''''||'
                                 THEN 1
                           END
                          )                      
               FROM transactionlog
              WHERE instcode = '||l_inst_code||'
                AND customer_card_no IN ('||v_pan_string||')';
                
                
                
            execute immediate v_query INTO v_financial_cnt,v_dispute_cnt,v_c2c_cnt,v_manadj_cnt,v_preauth_cnt,v_hold_release_cnt;
          
          EXCEPTION
                WHEN OTHERS
                THEN
                   l_errmsg :=
                         'ERROR WHILE SELECTING DATA FROM transactionlog'
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE excp_exit_proc;
          END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_financial_cnt > 0
            THEN
            
                v_del_flag := 1;
             
                v_query := 'DELETE FROM cms_statements_log
                     WHERE csl_inst_code = '||l_inst_code||'
                       AND csl_pan_no in ('||v_pan_string||')';
                     
              execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_STATEMENTS_LOG',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_STATEMENTS_LOG DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query := 'DELETE FROM cms_transaction_log_dtl
                  WHERE ctd_inst_code = '||l_inst_code||'
                    AND ctd_customer_card_no in ('||v_pan_string||')';

            execute immediate v_query;
                    
            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_TRANSACTION_LOG_DTL',
                                 v_sel_cnt,
                                 v_del_cnt
                                );

            if v_del_cnt >= 1
            then
                 v_del_flag := 1;
            end if;                                
                                
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_TRANSACTION_LOG_DTL DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query := 'DELETE FROM transactionlog
                  WHERE instcode = '||l_inst_code||'
                    AND customer_card_no in ('||v_pan_string||')';
                    
            execute immediate v_query;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'TRANSACTIONLOG',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
                                
                                
            if v_del_cnt >= 1
            then
                 v_del_flag := 1;
            end if;       
                         
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE TRANSACTIONLOG DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_manadj_cnt > 0
            THEN
            
               v_del_flag := 1;
               
               v_query := 'DELETE FROM cms_manual_adjustment
                     WHERE cma_inst_code = '||l_inst_code||'
                       AND cma_pan_code in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_MANUAL_ADJUSTMENT',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_MANUAL_ADJUSTMENT DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_dispute_cnt > 0
            THEN
            
             v_del_flag := 1;
             
             v_query := 'DELETE FROM cms_dispute_txns
                     WHERE cdt_inst_code = '||l_inst_code||'
                       AND cdt_pan_code in ('||v_pan_string||')';

              execute immediate v_query;
                       
               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_DISPUTE_TXNS',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_DISPUTE_TXNS DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query := 'SELECT 1
              FROM cms_htlst_reisu
             WHERE chr_inst_code = '||l_inst_code||'
               AND chr_pan_code in ('||v_pan_string||')
               AND ROWNUM = 1';
               
            execute immediate v_query INTO v_sel_cnt;

            IF v_sel_cnt > 0
            THEN
            
             v_del_flag := 1;
             
             v_query := 'DELETE FROM cms_htlst_reisu
                     WHERE chr_inst_code = '||l_inst_code||'
                       AND chr_pan_code in ('||v_pan_string||')';
                       
             execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_HTLST_REISU',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_HTLST_REISU DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

             v_query := 'SELECT 1
              FROM cms_pan_spprt
              WHERE cps_inst_code = '||l_inst_code||'
               AND cps_pan_code in ('||v_pan_string||')
               AND ROWNUM = 1';
               
            execute immediate v_query INTO v_sel_cnt;

            IF v_sel_cnt > 0
            THEN
            
              v_del_flag := 1;
              
              v_query :='DELETE FROM cms_pan_spprt
                     WHERE cps_inst_code = '||l_inst_code||'
                       AND cps_pan_code in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_PAN_SPPRT',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_PAN_SPPRT DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_preauth_cnt > 0
            THEN
             
             v_del_flag := 1;
            
              v_query :='DELETE FROM cms_preauth_transaction
                     WHERE cpt_inst_code = '||l_inst_code||'
                       AND cpt_card_no ('||v_pan_string||')';

               execute immediate v_query;
                       
               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_PREAUTH_TRANSACTION',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_PREAUTH_TRANSACTION DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_preauth_cnt > 0 or v_hold_release_cnt >0
            THEN
            
               v_del_flag := 1;
               
               v_query :='DELETE FROM cms_preauth_trans_hist
                     WHERE cph_inst_code = '||l_inst_code||'
                       AND cph_card_no in ('||v_pan_string||')';

               execute immediate v_query;
                       
               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_PREAUTH_TRANS_HIST',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_PREAUTH_TRANSACTION DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            IF v_c2c_cnt > 0
            THEN
             
              v_del_flag := 1;
            
              v_query :='DELETE FROM cms_c2ctxfr_transaction
                     WHERE cct_inst_code = '||l_inst_code||'
                       AND cct_from_card in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_C2CTXFR_TRANSACTION',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_C2CTXFR_TRANSACTION DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
         
            IF v_del_flag > 0
            THEN
              v_query :='UPDATE migr_transactionlog_temp
                  SET mtt_roll_flag = '||''''||'Y'||''''||'
                WHERE mtt_migr_seqno = '||p_migr_seq||'
                  AND mtt_roll_flag = '||''''||'N'||''''||'
                  AND mtt_flag = '||''''||'S'||''''||'
                  AND gethash (mtt_card_no) in ('||v_pan_string||')';
                  
            execute immediate v_query;
                  
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE UPDATING TXN STAGING TABLE FOR ROLL FLAG '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;
         
         --*******************SN Call Logging***********************
         
         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query := 'SELECT 1
              FROM CMS_CALLLOG_DETAILS
             WHERE ccd_inst_code = '||l_inst_code||'
               AND CCD_PAN_CODE in ('||v_pan_string||')
               AND ROWNUM = 1';
               
            execute immediate v_query INTO v_sel_cnt;

            IF v_sel_cnt > 0
            THEN
            
              v_del_flag := 1;
             
              v_query :='DELETE FROM CMS_CALLLOG_DETAILS
                     WHERE ccd_inst_code = '||l_inst_code||'
                       AND CCD_PAN_CODE in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_CALLLOG_DETAILS',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
      
                                   
            END IF;
            
         EXCEPTION WHEN NO_DATA_FOUND
         THEN
             NULL;
         
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CALL LOG DETAIL DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;         
         
         
         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query := 'SELECT 1
              FROM CMS_CALLLOG_MAST
             WHERE ccm_inst_code = '||l_inst_code||'
               AND ccm_pan_code in ('||v_pan_string||')
               AND ROWNUM = 1';
               
            execute immediate v_query INTO v_sel_cnt;

            IF v_sel_cnt > 0
            THEN
            
               v_del_flag := 1;
            
              v_query :='DELETE FROM CMS_CALLLOG_MAST
                     WHERE ccm_inst_code = '||l_inst_code||'
                       AND ccm_pan_code in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_CALLLOG_DETAILS',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
            
         EXCEPTION WHEN NO_DATA_FOUND
         THEN
             NULL;
         
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CALL LOG DETAIL DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;           
         
         BEGIN
            IF v_del_flag > 0
            THEN
              v_query :='UPDATE MIGR_CSR_CALLLOG_TEMP
                  SET MCC_ROLL_FLAG = '||''''||'Y'||''''||'
                WHERE MCC_MIGR_SEQNO = '||p_migr_seq||'
                  AND MCC_ROLL_FLAG = '||''''||'N'||''''||'
                  AND MCC_PROC_FLAG = '||''''||'S'||''''||'
                  AND MCC_HASH_PAN in ('||v_pan_string||')';
                  
               execute immediate v_query;
                  
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE UPDATING CALLLOG STAGING TABLE FOR ROLL FLAG '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;
         
         
         
         --******************EN Call Logging***********************************
         

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query :='DELETE FROM cms_smsandemail_alert
                  WHERE csa_inst_code = '||l_inst_code||'
                    AND csa_pan_code in ('||v_pan_string||')';
                    
           execute immediate v_query;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_SMSANDEMAIL_ALERT',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
                                   
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_SMSANDEMAIL_ALERT DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query :='DELETE FROM cms_cardissuance_status
                  WHERE ccs_inst_code = '||l_inst_code||'
                    AND ccs_pan_code in ('||v_pan_string||')';
                    
            execute immediate v_query;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_CARDISSUANCE_STATUS',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_CARDISSUANCE_STATUS DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query :='SELECT 1
              FROM cms_translimit_check
             WHERE ctc_inst_code = '||l_inst_code||'
               AND ctc_pan_code in ('||v_pan_string||')
               AND ROWNUM = 1';

             execute immediate v_query INTO v_sel_cnt;
               
            IF v_sel_cnt > 0
            THEN
               v_query :='DELETE FROM cms_translimit_check
                     WHERE ctc_inst_code = '||l_inst_code||'
                       AND ctc_pan_code in ('||v_pan_string||')';
                       
              execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_TRANSLIMIT_CHECK',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_TRANSLIMIT_CHECK DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query :='SELECT COUNT (cmm_ordr_refrno)
              FROM cms_merinv_merpan
             WHERE cmm_inst_code = '||l_inst_code||'
               AND cmm_pan_code in ('||v_pan_string||')';

             execute immediate v_query INTO v_merinv_ordr_cnt;
               
            /*
                     SELECT 1
                       INTO v_sel_cnt
                       FROM cms_merinv_merpan
                      WHERE cmm_inst_code = l_inst_code
                        AND exists (select 1 from cms_appl_pan where cap_inst_code=l_inst_code and cap_cust_code = l_cust_code and cap_pan_code = cmm_pan_code);
                        AND ROWNUM = 1;
                */
            IF v_merinv_ordr_cnt > 0
            THEN
               v_query :='DELETE FROM cms_merinv_merpan
                     WHERE cmm_inst_code = '||l_inst_code||'
                       AND cmm_pan_code in ('||v_pan_string||')';
                       
               execute immediate v_query;

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_MERINV_MERPAN',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_MERINV_MERPAN DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            v_query :='DELETE FROM cms_pan_acct
                WHERE cpa_pan_code in  ('||v_pan_string||')';
            
            execute immediate v_query;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_PAN_ACCT',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_PAN_ACCT DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_appl_pan
                  WHERE cap_inst_code = l_inst_code
                    AND cap_cust_code = l_cust_code;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_APPL_PAN',
                                 v_sel_cnt,
                                 v_del_cnt
                                );

            if v_del_cnt >= 1
            then
                 v_del_flag := 1;
            end if;                                 
                                
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_APPL_PAN DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_appl_det
                  WHERE cad_inst_code = l_inst_code
                    AND cad_appl_code IN (SELECT cam_appl_code
                                            FROM cms_appl_mast
                                           WHERE cam_cust_code = l_cust_code);

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_APPL_DET',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_APPL_DET DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_appl_mast
                  WHERE cam_inst_code = l_inst_code
                    AND cam_cust_code = l_cust_code;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_APPL_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_APPL_MAST DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_caf_info_entry
                  WHERE cci_inst_code = l_inst_code
                    AND cci_appl_code IN (SELECT cam_appl_code
                                            FROM cms_appl_mast
                                           WHERE cam_cust_code = l_cust_code);

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_CAF_INFO_ENTRY',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_CAF_INFO_ENTRY DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         IF v_merinv_ordr_cnt > 1
         THEN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            FOR m IN (SELECT cmm_ordr_refrno
                        FROM cms_merinv_merpan
                       WHERE cmm_inst_code = l_inst_code
                         AND EXISTS (
                                SELECT 1
                                  FROM cms_appl_pan
                                 WHERE cap_inst_code = l_inst_code
                                   AND cap_cust_code = l_cust_code
                                   AND cap_pan_code = cmm_pan_code))
            LOOP
               BEGIN
                  DELETE FROM cms_merinv_ordr
                        WHERE cmo_inst_code = l_inst_code
                          AND cmo_ordr_refrno = m.cmm_ordr_refrno;

                  v_del_cnt := SQL%ROWCOUNT;
                  v_sel_cnt := v_del_cnt;
                  migr_file_roll_info (l_migr_seqno,
                                       'CMS_MERINV_ORDR',
                                       v_sel_cnt,
                                       v_del_cnt
                                      );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_errmsg :=
                           'ERROR WHILE CMS_MERINV_ORDR DATA ROLLBACK '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_exit_proc;
               END;
            END LOOP;
         END IF;

         /*
                 BEGIN
                    SELECT mci_file_name
                      INTO v_cust_file
                      FROM migr_caf_info_entry
                     WHERE exists (select 1 from cms_appl_pan where cap_inst_code=l_inst_code and cap_cust_code = l_cust_code and cap_pan_code = mci_pan_code )
                       AND mci_inst_code = l_inst_code
                       AND ROWNUM = 1;
                 EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                       NULL;
                       v_cust_file := NULL;
                    WHEN OTHERS
                    THEN
                       l_errmsg :=
                             'ERROR WHILE SELECTING CUST FILE NAME-'
                          || SUBSTR (SQLERRM, 1, 200);
                       RAISE excp_exit_proc;
                 END;
         */
        BEGIN         --chages done for performance(GETHASH (MCI_PAN_CODE) replace MCI_HASH_PAN on 05092013                               
           
            v_query := 'UPDATE migr_caf_info_entry
               SET mci_roll_flag = '||''''||'Y'||''''||'
             WHERE mci_migr_seqno = '||p_migr_seq||'
              AND mci_roll_flag ='||''''||'N'||''''||'
               AND mci_hash_pan  in ('||v_pan_string||')';
   
         execute immediate v_query;
         
        EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Error while updationg rollback flag for cust-'
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_exit_proc;
        END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_cust_acct
                  WHERE cca_inst_code = l_inst_code
                    AND cca_cust_code = l_cust_code;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_CUST_ACCT',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_CUST_ACCT DATA ROLLBACK '
                  || v_cap_acct_id
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_acct_mast
                  WHERE cam_inst_code = l_inst_code
                    AND cam_acct_id = l_acct_id;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_ACCT_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
                                
                                
            if v_saving_acct is not null
            then
            
                DELETE FROM cms_acct_mast
                  WHERE cam_inst_code = l_inst_code
                    AND cam_acct_id = v_saving_acct;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_ACCT_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );            
            
            
            end if;                    
                                
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_ACCT_MAST DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;
            
            --             IF l_addr_flag is not null
            --             THEN                
            --                
            --                delete from cms_addr_mast
            --                      where cam_cust_code = l_cust_code;
            --                       --AND cam_inst_code = l_inst_code
            --                       
            --             ELSE 
             
               v_query:=  'delete from cms_addr_mast
                      where cam_inst_code = '||l_inst_code||'
                      and   cam_addr_code in ('||v_addr_string||')';        
               
               execute immediate v_query;            
             
              
             --END IF;          
                  
                   

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_ADDR_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_ADDR_MAST DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            SELECT 1
              INTO v_sel_cnt
              FROM cms_security_questions
             WHERE csq_cust_id IN (
                      SELECT ccm_cust_id
                        FROM cms_cust_mast
                       WHERE ccm_inst_code = l_inst_code
                         AND ccm_cust_code = l_cust_code)
               AND ROWNUM = 1;

            IF v_sel_cnt > 0
            THEN
               DELETE FROM cms_security_questions
                     WHERE csq_cust_id IN (
                              SELECT ccm_cust_id
                                FROM cms_cust_mast
                               WHERE ccm_inst_code = l_inst_code
                                 AND ccm_cust_code = l_cust_code);

               v_del_cnt := SQL%ROWCOUNT;
               v_sel_cnt := v_del_cnt;
               migr_file_roll_info (l_migr_seqno,
                                    'CMS_SECURITY_QUESTIONS',
                                    v_sel_cnt,
                                    v_del_cnt
                                   );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_SECURITY_QUESTIONS DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;

         BEGIN
            v_sel_cnt := 0;
            v_del_cnt := 0;

            DELETE FROM cms_cust_mast
                  WHERE ccm_inst_code = l_inst_code
                    AND ccm_cust_code = l_cust_code;

            v_del_cnt := SQL%ROWCOUNT;
            v_sel_cnt := v_del_cnt;
            migr_file_roll_info (l_migr_seqno,
                                 'CMS_CUST_MAST',
                                 v_sel_cnt,
                                 v_del_cnt
                                );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'ERROR WHILE CMS_CUST_MAST DATA ROLLBACK '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_exit_proc;
         END;
      END IF;
   EXCEPTION
      WHEN excp_exit_proc
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Local Procedure Main excp-' || SUBSTR (SQLERRM, 1, 100);
   END;
BEGIN
   p_errmsg := 'OK';

   BEGIN
      SELECT 1
        INTO v_chk_invalid_seqno
        FROM migr_file_load_info
       WHERE mfi_migr_seqno = p_migr_seq AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errmsg := 'Invalid sequence number for rollback';
         RETURN;
   END;

   FOR i IN cur_file
   LOOP
     FOR j IN (SELECT mci_seg31_num
                  FROM migr_caf_info_entry
                 WHERE mci_file_name = i.mfi_file_name
                   AND mci_roll_flag = 'N'
                   and mci_proc_flag = 'S'
                   )
                   --and rownum<=1000)               
      
      LOOP
         v_indx := 1;

         FOR k IN (SELECT cca_cust_code,cca_acct_id,cam_type_code
                     FROM cms_acct_mast, cms_cust_acct
                    WHERE cam_inst_code = cca_inst_code
                      AND cam_acct_id = cca_acct_id
                      AND cam_acct_no = j.mci_seg31_num)
         LOOP
         
            
              -- SN : Check if mailing addr present for the customer  
               BEGIN
               
                    SELECT cam_addr_code 
                    INTO v_mail_addr 
                    FROM cms_addr_mast 
                    WHERE cam_cust_code = k.cca_cust_code
                    AND   cam_addr_flag ='O' 
                    AND ROWNUM = 1;
                    
               EXCEPTION WHEN NO_DATA_FOUND
               THEN 
                 v_mail_addr := null;
                  
               WHEN OTHERS
               THEN
                    p_errmsg := 'While fetching mail addr code for cust '||k.cca_cust_code||' and acct '||j.mci_seg31_num;
                    RETURN;
                    
               END;    
              -- EN : Check if mailing addr present for the customer               
         
            lp_migr_rollback_data (v_instcode,
                                   i.mfi_file_name,
                                   p_migr_seq,
                                   k.cca_acct_id,
                                   k.cam_type_code,
                                   k.cca_cust_code,
                                   p_migruser,
                                   v_mail_addr,
                                   v_errmsg
                                  );

            IF v_errmsg <> 'OK'
            THEN
               ROLLBACK;
               p_errmsg := 'Error while deleting data-' || v_errmsg;

               INSERT INTO migr_det_roll_excp
                           (mdr_file_name, mdr_migr_seqno, mdr_acct_no,
                            mdr_reason
                           )
                    VALUES (i.mfi_file_name, p_migr_seq, j.mci_seg31_num,
                            p_errmsg
                           );

               RETURN;
            ELSE
               BEGIN
                  UPDATE migr_acct_data_temp
                     SET mad_roll_flag = 'Y'
                   WHERE mad_migr_seqno = p_migr_seq
                     AND mad_roll_flag = 'N'
                     AND mad_acct_numb = j.mci_seg31_num;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ROLLBACK;
                     p_errmsg :=
                           'Error while updationg rollback flag for acct-'
                        || SUBSTR (SQLERRM, 1, 100);

                     INSERT INTO migr_det_roll_excp
                                 (mdr_file_name, mdr_migr_seqno,
                                  mdr_acct_no, mdr_reason
                                 )
                          VALUES (i.mfi_file_name, p_migr_seq,
                                  j.mci_seg31_num, p_errmsg
                                 );

                     RETURN;
               END;
            END IF;
         END LOOP;
      END LOOP;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_errmsg := 'Main Excp-' || sqlerrm;
END;
/
SHOW ERROR;