create or replace
PROCEDURE       vmscms.SP_CSR_SMSANDEMAIL_ALERT 
                                                    (
                                                     prm_inst_code          in number,
                                                     prm_rrn               in varchar2,
                                                     prm_terminalid        in varchar2,
                                                     prm_stan              in varchar2,
                                                     prm_tran_date          in varchar2,
                                                     prm_tran_time          in varchar2,
                                                     prm_card_no             in varchar2,
                                                     prm_currcode          in varchar2,
                                                     prm_msg_type          in varchar2,
                                                     prm_txn_code          in varchar2,
                                                     prm_txn_mode          in varchar2,
                                                     prm_delivery_channel  in varchar2,
                                                     prm_mbr_numb          in varchar2,
                                                     prm_rvsl_code         in varchar2,
                                                     prm_cellphoneno       in varchar2,
                                                     prm_cellphonecarrier  in varchar2,
                                                     prm_emailid1          in varchar2,
                                                     prm_emailid2          in varchar2,
                                                     prm_loadorcreditalert in varchar2,
                                                     prm_lowbalalert       in varchar2,
                                                     prm_lowbalamount      in varchar2,
                                                     prm_negativebalalert  in varchar2,
                                                     prm_highauthamtalert  in varchar2,
                                                     prm_highauthamt       in varchar2,
                                                     prm_dailybalalert     in varchar2,
                                                     prm_begintime         in varchar2,
                                                     prm_endtime           in varchar2,
                                                     prm_insufficientalert in varchar2,
                                                     prm_incorrectpinalert in varchar2,
                                                     --prm_c2calert          in varchar2,--Added by Dnyaneshwar J on 20 Aug 2013 for MOB-31 changes--Commented By Narsing Ingle on 24th Dec 2013 to remove C2C Alert for MVHOST-671
                                                     prm_fast50alert       in varchar2,--Added by Dnyaneshwar J on 30 Sept 2013 for JH-6 changes
                                                     prm_federalstatealert in varchar2,--Added by Dnyaneshwar J on 30 Sept 2013 for JH-6 changes
                                                     prm_ipaddress         in varchar2,
                                                     prm_ins_user          in number,
                                                     prm_call_id           in number,
                                                     prm_remark            in varchar2,
                                                     prm_lang_id           in vARCHAR2,
                                                     prm_resp_code         out varchar2,
                                                     Prm_Resp_Msg          Out Varchar2,
                                                     prm_doubleoptinFlag     OUT      VARCHAR2  
                                                    ) is
                                                    
/**********************************************************************************************
 * DATE OF CREATION          :  18/Jun/2012
 * PURPOSE                   :  Call logging for sms and email alert txns from CSR
 * CREATED BY                :  Sagar More
 * MODIFICATION REASON       :  Commented One IN parameter  for this "sp_smsandemail_alert" for mobile carrier changes 
 * LAST MODIFICATION DONE BY :  Siva Kumar M
 * LAST MODIFICATION DATE    :  12-Oct-2012
 * Reviewer                  :  Saravanakumar
 * Reviewed Date             :  12-Oct-2012
 * Build Number              :  CMS3.5.1_RI0023_B0001
   
  * Modified by              :  Dnyaneshwar J
  * Modified for             :  Mantis - 0011400
  * Modification Reason      :  Update SMS and EMAIL Alerts transaction's are not displaying in comments tab
  * Modified Date            :  25-June-13
  * Reviewer                 : 
  * Reviewed Date            :  
  * Build Number             :  RI0024.2_B0010
  
  * Modified by              :  Dnyaneshwar J
  * Modified for             :  Mantis - 0011400
  * Modification Reason      :  MOB-31 add C2C alert flag as input parameter
  * Modified Date            :  20-Aug-13
  * Reviewer                 :  Dhiraj
  * Reviewed Date            :  21-Aug-13
  * Build Number             :  RI0024.4_B0003

  * Modified by              :  Dnyaneshwar J
  * Modified for             :  JH-6
  * Modification Reason      :  JH-6
  * Modified Date            :  30-Sept-13
  * Reviewer         		 :  Dhiraj
  * Reviewed Date    		 :  30-Sept-2013
  * Build Number     		 :  RI0024.5_B0002  

  * Modified by              :  Narsing I
  * Modified for             :  MVHOST-671
  * Modification Reason      :  MVHOST-671
  * Modified Date            :  31-Dec-13
  * Build Number     		 :  RI0027_B0002
  
  * Modified By      : venkat Singamaneni
  * Modified Date    : 4-4-2022
  * Purpose          : Archival changes.
  * Reviewer         : Saravana Kumar A
  * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

**************************************************************************************************/

   v_table_list       VARCHAR2 (2000);
   v_colm_list        VARCHAR2 (2000);
   v_colm_qury        VARCHAR2 (4000);
   v_old_value        VARCHAR2 (4000);
   v_new_value        VARCHAR2 (4000);
   v_value            VARCHAR2 (4000); 
   v_call_seq         number (3);
   v_hash_pan         cms_appl_pan.cap_pan_code%type; 
   v_encr_pan         cms_appl_pan.cap_pan_code_encr%type; 
   v_resp_code        varchar2(3);
   v_resp_msg         varchar2(300);   
   excp_rej_record    exception;
                                                       
v_cap_acct_no   cms_appl_pan.cap_acct_no%type;      
v_prod_code    cms_appl_pan.cap_prod_code%type;
v_prod_cattype cms_appl_pan.cap_card_type%type; 
v_proxynumber  cms_appl_pan.cap_proxy_number%type;
v_acct_balance cms_acct_mast.cam_acct_bal%type;  
v_ledger_balance cms_acct_mast.cam_ledger_bal%type;   
v_alert_lang_id   VMS_ALERTS_SUPPORTLANG.VAS_ALERT_LANG%TYPE;
p_optin_flag_out varchar2(300);

v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991

BEGIN


   Begin
            prm_resp_msg  := 'OK';
            prm_resp_code := '00';
   
          BEGIN
          
             V_HASH_PAN := GETHASH(prm_card_no);
            EXCEPTION
             WHEN OTHERS THEN
               v_resp_code := '89';
               v_resp_msg := 'Error while converting pan into hash' ||
                           SUBSTR(SQLERRM, 1, 100);
               raise excp_rej_record;
          END;
          
          BEGIN
             v_encr_pan := fn_emaps_main(prm_card_no);
             
            EXCEPTION
             WHEN OTHERS THEN
               v_resp_code := '89';
               v_resp_msg := 'Error while converting pan into encr ' ||
                           SUBSTR(SQLERRM, 1, 100);
               raise excp_rej_record;
             
          END; 

        /* To get account number added by Dnyaneshwar J to log account number in call log details table for mantis 0011400*/
        BEGIN

         SELECT cap_acct_no
           INTO v_cap_acct_no
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code
            AND cap_pan_code = v_hash_pan
            AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_resp_code := '16';
            prm_resp_msg := 'Pan code is not defined ';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            prm_resp_code := '21';
            prm_resp_msg := ' Error while selecting data from card master  '|| SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;
      /* To get account number added by Dnyaneshwar J to log account number in call log details table for mantis 0011400*/
        
                 /*  call log info   start */
          BEGIN
          
             SELECT cut_table_list, cut_colm_list, cut_colm_qury
               INTO v_table_list, v_colm_list, v_colm_qury
               FROM cms_calllogquery_mast
              WHERE cut_inst_code = prm_inst_code
                AND cut_devl_chnl = prm_delivery_channel
                AND cut_txn_code = prm_txn_code;
                
                
                
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_resp_code := '49';
                v_resp_msg := 'Column list not found in cms_calllogquery_mast ';
                raise excp_rej_record;
             WHEN OTHERS
             THEN
                v_resp_msg := 'Error while finding Column list ' || SUBSTR (SQLERRM, 1, 100);
                v_resp_code := '21';
                raise excp_rej_record;
                
          END;

          BEGIN
               
               EXECUTE IMMEDIATE v_colm_qury
                            INTO v_old_value
                           USING prm_inst_code, v_hash_pan;
                           
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_msg :=
                        'Error while selecting old values -- '
                     || '---'
                     || SUBSTR (SQLERRM, 1, 100);
                  v_resp_code := '89';
                  raise excp_rej_record;
          END;
          
            BEGIN
                 SELECT VAS_ALERT_LANG INTO
                  v_alert_lang_id
                  FROM VMS_ALERTS_SUPPORTLANG
                WHERE VAS_ALERT_LANG_ID=TRIM(prm_lang_id);
                
            EXCEPTION    
                 WHEN OTHERS
                     THEN
                        v_resp_msg :=
                              'Error while selecting old values -- '
                           || '---'
                           || SUBSTR (SQLERRM, 1, 100);
                        v_resp_code := '89';
                        raise excp_rej_record;
                
             END;
          
          
          
         BEGIN
          
              SP_SMSANDEMAIL_ALERT(
                                    prm_inst_code,         
                                    prm_rrn,              
                                    prm_terminalid,       
                                    prm_stan,             
                                    prm_tran_date,         
                                    prm_tran_time,         
                                    prm_card_no,           
                                    prm_currcode,         
                                    prm_msg_type,         
                                    prm_txn_code,         
                                    prm_txn_mode,         
                                    prm_delivery_channel, 
                                    prm_mbr_numb,         
                                    prm_rvsl_code,        
                                    prm_cellphoneno,      
                                   -- prm_cellphonecarrier,   commented by siva kumar m as on Oct/12/2012 for mobile carrier changes .
                                    prm_emailid1,         
                                    prm_emailid2,         
                                    prm_loadorcreditalert,
                                    prm_lowbalalert,      
                                    prm_lowbalamount,     
                                    prm_negativebalalert, 
                                    prm_highauthamtalert, 
                                    prm_highauthamt,      
                                    prm_dailybalalert,    
                                    prm_begintime,        
                                    prm_endtime,          
                                    prm_insufficientalert,
                                    prm_incorrectpinalert,
                                    prm_ipaddress,
                                    --prm_c2calert,--Added by Dnyaneshwar J on 20 Aug 2013 for MOB-31 changes --Commented By Narsing Ingle on 24th Dec 2013 to remove C2C Alert for MVHOST-671
                                    prm_fast50alert,--Added by Dnyaneshwar J on 30 Sept 2013 for JH-6 changes
                                    prm_federalstatealert,--Added by Dnyaneshwar J on 30 Sept 2013 for JH-6 changes
                                  --  'English',
                                  v_alert_lang_id,
                                    prm_resp_code ,      
                                    Prm_Resp_Msg,
                                     Prm_Doubleoptinflag
                                  );
          
          
         Exception when others 
          then
          v_resp_code := '89';
          v_resp_msg  := 'while calling sms and email alert process '||substr(sqlerrm,1,100);
          raise excp_rej_record;
         End; 
         
         begin
    v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
            update transactionlog 
         set add_ins_user=prm_ins_user,add_lupd_user=prm_ins_user
           WHERE instcode = prm_inst_code
         AND rrn = prm_rrn
         AND business_date = prm_tran_date
         AND delivery_channel = prm_delivery_channel;
      ELSE
            update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991 
         set add_ins_user=prm_ins_user,add_lupd_user=prm_ins_user
           WHERE instcode = prm_inst_code
         AND rrn = prm_rrn
         AND business_date = prm_tran_date
         AND delivery_channel = prm_delivery_channel;
       END IF;  
         
         Exception when others 
          then
          v_resp_code := '89';
          v_resp_msg  := 'Error while updating user detailss '||substr(sqlerrm,1,100);
          raise excp_rej_record;

         end;
         
          
          
         If prm_resp_code ='00'
         then

             BEGIN
                   
                   EXECUTE IMMEDIATE v_colm_qury
                                INTO v_new_value
                               USING prm_inst_code, v_hash_pan;

               EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_msg :=
                        'Error while selecting new values -- '
                     || '---'
                     || SUBSTR (SQLERRM, 1, 100);
                  v_resp_code := '89';
                  raise excp_rej_record;
             END;

              BEGIN
              
                 BEGIN
                 
                    SELECT NVL (MAX (ccd_call_seq), 0) + 1
                      INTO v_call_seq
                      FROM cms_calllog_details
                     WHERE ccd_inst_code = ccd_inst_code
                       AND ccd_call_id = prm_call_id
                       AND ccd_pan_code = v_hash_pan;
                 EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                       v_resp_msg := 'record is not present in cms_calllog_details  ';
                       v_resp_code := '49';
                       raise excp_rej_record;
                    WHEN OTHERS
                    THEN
                       v_resp_msg :=
                             'Error while selecting frmo cms_calllog_details '
                          || SUBSTR (SQLERRM, 1, 100);
                       v_resp_code := '21';
                       raise excp_rej_record;
                 END;

                 INSERT INTO cms_calllog_details
                             (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                              ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                              ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                              ccd_colm_name, ccd_old_value, ccd_new_value,
                              ccd_comments, ccd_ins_user, ccd_ins_date,
                              ccd_lupd_user, ccd_lupd_date,ccd_acct_no--Added by Dnyaneshwar J on 25 June 2013 for mantis 0011400
                             )
                      VALUES (prm_inst_code, prm_call_id, v_hash_pan, v_call_seq,
                              prm_rrn, prm_delivery_channel, prm_txn_code,
                              prm_tran_date, prm_tran_time, v_table_list,
                              v_colm_list, v_old_value, v_new_value,
                              prm_remark, prm_ins_user, SYSDATE,
                              prm_ins_user, SYSDATE,v_cap_acct_no--Added by Dnyaneshwar J on 25 June 2013 for mantis 0011400
                             );
                             
              EXCEPTION WHEN excp_rej_record
              THEN 
                  RAISE;
                  
              WHEN OTHERS
                 THEN
                    v_resp_code := '21';
                    v_resp_msg := ' Error while inserting into cms_calllog_details ' || substr(SQLERRM,1,100);
                    raise excp_rej_record;
              END;
         
         End if;          
         
   ------------------------------------------------------------------------------------------------------------------------------------------------
   EXCEPTION
      WHEN excp_rej_record
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_resp_code;

            prm_resp_msg := v_resp_msg;
            
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;
         
         Begin
         
             select cap_acct_no ,cap_prod_code,cap_card_type,cap_proxy_number
             into   v_cap_acct_no,v_prod_code, v_prod_cattype,v_proxynumber
             from   cms_appl_pan
             where cap_inst_code = prm_inst_code
             and   cap_pan_code = v_hash_pan;
             
         exception when others
         then
             v_cap_acct_no := null;
             v_prod_code   := null; 
             v_prod_cattype := null;
             v_proxynumber  := null;
         End; 
         
         Begin
         
              select cam_acct_bal,cam_ledger_bal
              into   v_acct_balance, v_ledger_balance
              from   cms_acct_mast
              where cam_inst_code =  prm_inst_code
              and   cam_acct_no   =  v_cap_acct_no;
              
         exception when others
         then
             v_acct_balance := null;
             v_ledger_balance := null;
         
         End;         
                 

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code,
                         ctd_lupd_date,ctd_lupd_user,ctd_ins_date,ctd_ins_user
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, prm_currcode,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         v_cap_acct_no, prm_inst_code,
                         sysdate,prm_ins_user,sysdate,prm_ins_user
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_currcode, v_prod_code, v_prod_cattype,
                         prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_inst_code, 'NA',
                         v_encr_pan, v_proxynumber, '00',
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg,
                         sysdate,prm_ins_user,sysdate,prm_ins_user
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      --En create a entry in txn log
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = '21';

            prm_resp_msg :=
                    'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master3 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         Begin
         
             select cap_acct_no ,cap_prod_code,cap_card_type,cap_proxy_number
             into  v_cap_acct_no,v_prod_code, v_prod_cattype,v_proxynumber
             from  cms_appl_pan
             where cap_inst_code = prm_inst_code
             and   cap_pan_code = v_hash_pan;
             
         exception when others
         then
             v_cap_acct_no := null;
             v_prod_code   := null; 
             v_prod_cattype := null;
             v_proxynumber  := null;
         End; 
         
         Begin
         
              select cam_acct_bal,cam_ledger_bal
              into   v_acct_balance, v_ledger_balance
              from cms_acct_mast
              where cam_inst_code = prm_inst_code
              and   cam_acct_no   =  v_cap_acct_no;
              
         exception when others
         then
             v_acct_balance := null;
             v_ledger_balance := null;
         
         End;         
                 

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code,
                         ctd_lupd_date,ctd_lupd_user,ctd_ins_date,ctd_ins_user
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, prm_currcode,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         v_cap_acct_no, prm_inst_code,
                         sysdate,prm_ins_user,sysdate,prm_ins_user
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
              RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                          trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_currcode, v_prod_code, v_prod_cattype,
                          prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_inst_code, 'NA',
                         v_encr_pan, v_proxynumber, '00',
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg,
                         sysdate,prm_ins_user,sysdate,prm_ins_user
                        );

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   End;
   
   dbms_output.put_line(prm_resp_msg);   

Exception when others
then
prm_resp_code := '89';
prm_resp_msg := ' Error from mail' || substr(SQLERRM,1,100);
RETURN;



End; 
/
show error