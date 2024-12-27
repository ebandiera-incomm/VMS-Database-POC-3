CREATE OR REPLACE procedure VMSCMS.sp_startercard_link_process ( p_inst_code        number,
                                                                 p_mbr_numb         varchar2,
                                                                 p_msg_type         varchar2,  
                                                                 p_curr_code        varchar2,
                                                                 p_rrn              varchar2,
                                                                 p_stan             varchar2,
                                                                 p_gpr_card_no      varchar2,
                                                                 p_starter_card_no  varchar2,
                                                                 p_delivery_channel varchar2,
                                                                 p_txn_code         varchar2,
                                                                 p_txn_mode         varchar2,
                                                                 p_tran_date        varchar2,     
                                                                 p_tran_time        varchar2,
                                                                 p_reason_code      number,     
                                                                 p_remark           varchar2,
                                                                 p_ins_user         number,
                                                                 p_resp_code    out varchar2,
                                                                 p_resp_msg     out varchar2       
                                                               ) 
is                                                        
      
/**********************************************************************************************
  * VERSION                   :  1.0
  * DATE OF CREATION          : 9/May/2012
  * PURPOSE                   : Starter card linking process
  * CREATED BY                : Sagar More
  * MODIFICATION REASON       : Response id changed from 49 to 10 
                                To show invalid card status msg in popup query                                 
  * MODIFICATION DONE FOR     : Internal Enhancement
  * MODIFICATION DATE         : 09Oct2012
  * Build Number              : RI0019 B0008
**************************************************************************************************/

         
v_hash_starter_pan cms_appl_pan.cap_pan_code%type;
v_hash_gpr_pan    cms_appl_pan.cap_pan_code%type;
v_encr_gpr_pan    cms_appl_pan.cap_pan_code_encr%type;
v_encr_starter_pan    cms_appl_pan.cap_pan_code_encr%type;
v_cap_acct_no     cms_appl_pan.cap_acct_no%type;
v_resp_cde        varchar2(3); 
v_errmsg          varchar2(400);
v_txn_type        cms_transaction_mast.ctm_tran_type%type;

exp_reject_record exception ;

v_cap_prod_code cms_appl_pan.cap_prod_code%type;
v_cap_prod_cattype cms_appl_pan.cap_card_type%type;
v_cap_expry_date cms_appl_pan.cap_expry_date%type;
v_cap_applpan_cardstat cms_appl_pan.cap_card_stat%type;
v_cap_atmonline_limit cms_appl_pan.cap_atm_online_limit%type;
v_cap_posonline_limit cms_appl_pan.cap_pos_online_limit%type;
v_cap_atmoffline_limit cms_appl_pan.cap_atm_offline_limit%type;
v_cap_posoffline_limit cms_appl_pan.cap_pos_offline_limit%type;
v_cap_proxunumber cms_appl_pan.cap_proxy_number%type;
v_cap_cust_code  cms_appl_pan.cap_cust_code%type;
v_startercard_cust_code cms_appl_pan.cap_cust_code%type;
v_cap_bill_addr cms_appl_pan.cap_bill_addr%type;
v_cap_card_stat cms_appl_pan.cap_card_stat%type;  
v_cap_acct_id   cms_appl_pan.cap_acct_id%type;
v_cap_disp_name cms_appl_pan.cap_disp_name%type;
v_cap_startercard_flag  cms_appl_pan.cap_startercard_flag%type;
v_cap_offline_aggr_limit cms_appl_pan.cap_offline_aggr_limit%type;
v_cap_online_aggr_limit  cms_appl_pan.cap_online_aggr_limit%type; 
v_tran_amt               transactionlog.amount%type; 
v_startercard_mbr_numb   cms_appl_pan.cap_mbr_numb%type;
v_gpr_mbr_numb           cms_appl_pan.cap_mbr_numb%type;   

v_ccm_cust_id cms_cust_mast.ccm_cust_id%type; 
v_cam_addr_code cms_addr_mast.cam_addr_code%TYPE;
v_tran_type     cms_transaction_mast.ctm_tran_type%TYPE;
v_cap_prod_catg cms_appl_pan.cap_prod_catg%TYPE;
                                         
v_cfm_func_code cms_func_mast.cfm_func_code%type;

v_acct_balance    cms_acct_mast.cam_acct_bal%type;
v_ledger_bal      cms_acct_mast.cam_ledger_bal%type;

V_OLD_GL_CATG           CMS_GL_ACCT_MAST.CGA_GLCATG_CODE%TYPE;
V_OLD_GL_CODE           CMS_GL_ACCT_MAST.CGA_GL_CODE%TYPE;
V_OLD_SUB_GL_CODE       CMS_GL_ACCT_MAST.CGA_SUBGL_CODE%TYPE;
V_OLD_ACCT_DESC         CMS_GL_ACCT_MAST.CGA_ACCT_DESC%TYPE;
v_check_statcnt          NUMBER;


CURSOR c1 (gpr_pan_code IN cms_pan_acct.cpa_pan_code%type,gpr_acct_id in cms_pan_acct.cpa_acct_id%type)
IS
  SELECT cpa_acct_id, cpa_acct_posn, cpa_card_posn, cpa_cust_code,cpa_del_flag
    FROM cms_pan_acct
   WHERE cpa_inst_code = p_inst_code
   and   cpa_pan_code = gpr_pan_code
   and   cpa_acct_id  <> gpr_acct_id;



Begin

    Begin
    
            
        BEGIN
         v_hash_gpr_pan := GETHASH(p_gpr_card_no);
        EXCEPTION
         WHEN OTHERS THEN
           v_resp_cde  := '21';
           v_errmsg := 'Error while converting gpr pan into hash' ||
                       SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
         v_hash_starter_pan := GETHASH(p_starter_card_no);
        EXCEPTION
         WHEN OTHERS THEN
           v_resp_cde  := '120';
           v_errmsg := 'Error while converting starter pan into hash' ||
                       SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;


        BEGIN
         v_encr_gpr_pan := fn_emaps_main(p_gpr_card_no);
        EXCEPTION
         WHEN OTHERS THEN
           v_resp_cde  := '21';
           v_errmsg := 'Error while encrypting gpr pan ' ||
                       SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
            
            

        BEGIN
         v_encr_starter_pan := fn_emaps_main(p_starter_card_no);
        EXCEPTION
         WHEN OTHERS THEN
           v_resp_cde  := '120';
           v_errmsg := 'Error while encrypting starter pan ' ||
                       SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        
        
        
        BEGIN
        
         SELECT ctm_tran_type,to_number(decode(ctm_tran_type, 'N', '0', 'F', '1'))
         INTO   v_tran_type,v_txn_type
         FROM   cms_transaction_mast
         WHERE  ctm_tran_code = p_txn_code and
                ctm_delivery_channel = p_delivery_channel and
                ctm_inst_code = p_inst_code;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           v_resp_cde  := '12'; 
           v_errmsg := 'Transflag  not defined for txn code ' ||
                       p_txn_code || ' and delivery channel ' ||
                       p_delivery_channel;
           raise exp_reject_record;
         WHEN OTHERS THEN
           v_resp_cde  := '21'; 
           v_errmsg := 'Error while selecting transaction details'||substr(sqlerrm,1,100);
           raise exp_reject_record;
           
        END;
        
        
        BEGIN
        
              SELECT cfm_func_code
              INTO   v_cfm_func_code
              FROM   cms_func_mast
              WHERE  cfm_inst_code = p_inst_code
              AND    cfm_txn_code  = p_txn_code
              AND    cfm_delivery_channel = p_delivery_channel;
              
        Exception when no_data_found
        then
            v_resp_cde := '49';
            v_errmsg := 'Function not defined for txn code ' ||
                       p_txn_code || ' and delivery channel ' ||
                       p_delivery_channel;
           raise exp_reject_record; 
        when others then
            v_resp_cde := '21';
            v_errmsg := 'error while fetching function code '||substr(sqlerrm,1,100);
           raise exp_reject_record; 
        END;
        
        
        BEGIN
        
             select cap_mbr_numb
             into   v_startercard_mbr_numb
             from   cms_appl_pan
             where  cap_inst_code = p_inst_code
             and    cap_pan_code  = v_hash_gpr_pan;
             
        exception when no_data_found
        then
            v_resp_cde := '14';
            v_errmsg :='starter card not found';
            RAISE exp_reject_record;                
        when others
        then     
            v_resp_cde := '21';
            v_errmsg :='while fetching mbr number for starter card '||substr(sqlerrm,1,100);
            RAISE exp_reject_record;                
        END;
        
        
        
           BEGIN
                
                sp_check_starter_card (
                                       p_inst_code,       
                                       p_starter_card_no, 
                                       p_txn_code,      
                                       p_delivery_channel,
                                       v_errmsg
                                      );
                                          
                  IF v_errmsg <> 'OK'
                  THEN
                   v_resp_cde  := '49'; 
                  raise exp_reject_record;
                      
                  END IF;                    
                                      
           END;        
        
        BEGIN
        
         SELECT cap_prod_code,
                cap_card_type,
                cap_expry_date,
                cap_card_stat,
                cap_atm_online_limit,
                cap_pos_online_limit,
                cap_atm_offline_limit,
                cap_pos_offline_limit,
                cap_proxy_number,
                cap_acct_no,
                cap_cust_code,
                cap_bill_addr,
                cap_acct_id,
                cap_disp_name,
                cap_offline_aggr_limit,
                cap_online_aggr_limit,
                cap_startercard_flag,
                cap_prod_catg,
                cap_mbr_numb
           INTO v_cap_prod_code,
                v_cap_prod_cattype,
                v_cap_expry_date,
                v_cap_card_stat,
                v_cap_atmonline_limit,
                v_cap_posonline_limit,
                v_cap_atmoffline_limit,
                v_cap_posoffline_limit,
                v_cap_proxunumber,
                v_cap_acct_no,
                v_cap_cust_code,
                v_cap_bill_addr,
                v_cap_acct_id,
                v_cap_disp_name,
                v_cap_offline_aggr_limit,
                v_cap_online_aggr_limit,
                v_cap_startercard_flag,
                v_cap_prod_catg,
                v_gpr_mbr_numb
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_gpr_pan 
          AND   cap_inst_code = p_inst_code;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           v_resp_cde  := '14';
           v_errmsg := 'GPR CARD NOT FOUND ' || v_hash_gpr_pan;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           v_resp_cde  := '21';
           v_errmsg := 'Problem while selecting gpr card detail' ||
                       SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
           
        END;
        
        
         BEGIN -- added by sagar to check valid card status from pcms_valid_cardstat on 28-May-2012
         
            SELECT COUNT (1)
              INTO v_check_statcnt
              FROM pcms_valid_cardstat
             WHERE pvc_inst_code = p_inst_code
               AND pvc_card_stat = v_cap_card_stat
               AND pvc_tran_code = p_txn_code
               AND pvc_delivery_channel = p_delivery_channel;

            IF v_check_statcnt = 0
            THEN
               v_resp_cde := '10'; -- response id changed from 49 to 10 on 09Oct2012
               v_errmsg := 'Invalid Card Status';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                     'Problem while selecting card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;        
        
      /*                -- commented on 28-May-2012 by sagar to check valid card status from pcms_valid_cardstat
        BEGIN
            
           IF v_cap_card_stat NOT IN ('2', '3')
           THEN
              v_resp_cde  := '49'; -- changed from 89 to 49 by sagar on 25-May-2012
              v_errmsg    := 
                    'GPR card must be hotlisted before reissue';
              RAISE EXP_REJECT_RECORD;
           END IF;
              
        EXCEPTION
           WHEN EXP_REJECT_RECORD
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_errmsg := 'while cheking card status ' || SQLERRM;
              RAISE EXP_REJECT_RECORD;
        END;
       */ 
        

    
        BEGIN
            
           UPDATE cms_appl_pan
              SET cap_cust_code          = v_cap_cust_code,
                  cap_acct_id            = v_cap_acct_id,
                  cap_bill_addr          = v_cap_bill_addr,
                  cap_acct_no            = v_cap_acct_no,
                  cap_disp_name          = v_cap_disp_name,
                  cap_atm_offline_limit  = v_cap_atmoffline_limit,
                  cap_atm_online_limit   = v_cap_atmonline_limit,
                  cap_pos_offline_limit  = v_cap_posoffline_limit,
                  cap_pos_online_limit   = v_cap_posonline_limit,
                  cap_offline_aggr_limit = v_cap_offline_aggr_limit,
                  cap_online_aggr_limit  = v_cap_online_aggr_limit--,
                  --cap_active_date        = sysdate                       
            WHERE cap_inst_code          = p_inst_code
              AND cap_pan_code           = v_hash_starter_pan;

           IF SQL%ROWCOUNT = 0
           THEN
              v_resp_cde  := '49';
              v_errmsg :=
                    'pan master not updated,for starter card '
                 || v_hash_starter_pan;
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_resp_cde  := '21';
              v_errmsg :=
                    'error occured during pan master update '
                 || substr(SQLERRM,1,100);
              RAISE exp_reject_record;
        END;        
        
            
        BEGIN
            
                update cms_pan_acct
                set    cpa_cust_code = v_cap_cust_code,
                       cpa_acct_id   = v_cap_acct_id 
                where  cpa_inst_code = p_inst_code
                and    cpa_pan_code  = v_hash_starter_pan;
                    
           IF SQL%ROWCOUNT = 0
           THEN
              v_resp_cde  := '49';
              v_errmsg :=
                    'panacct master not updated,for starter card '
                 || v_hash_starter_pan;
              RAISE exp_reject_record;
           END IF;
           
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_resp_cde  := '21';
              v_errmsg :=
                    'error occured during panacct master update '
                 || substr(SQLERRM,1,100);
              RAISE exp_reject_record;
                     
            
        END;
        
        IF v_errmsg = 'OK'
        THEN
           FOR x IN c1 (v_hash_gpr_pan,v_cap_acct_id)
           LOOP

              INSERT INTO cms_pan_acct
                          (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                           cpa_acct_posn, cpa_pan_code,
                           cpa_mbr_numb, cpa_card_posn, cpa_ins_user,
                           cpa_lupd_user,cpa_del_flag,cpa_pan_code_encr
                          )
                   VALUES (p_inst_code, x.cpa_cust_code, x.cpa_acct_id,
                           x.cpa_acct_posn, v_hash_starter_pan,
                           v_startercard_mbr_numb, x.cpa_card_posn, p_ins_user,
                           p_ins_user,x.cpa_card_posn,v_encr_starter_pan
                          );

              EXIT WHEN c1%NOTFOUND;
           END LOOP;

           v_errmsg := 'OK';
        END IF;
        
       /*      
        BEGIN
             SELECT cga_glcatg_code, cga_gl_code, cga_subgl_code, cga_acct_desc
               INTO v_old_gl_catg,
                    v_old_gl_code,
                    v_old_sub_gl_code,
                    v_old_acct_desc
               FROM CMS_GL_ACCT_MAST
              WHERE CGA_ACCT_CODE = p_gpr_card_no AND CGA_INST_CODE = p_inst_code;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERRMSG := 'GL details not found for GPR card ';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERRMSG := 'Error while selecting gpr card GL detail ' ||
                    SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
     
    
        BEGIN
               UPDATE CMS_GL_ACCT_MAST
               SET cga_glcatg_code = v_old_gl_catg,
                   cga_gl_code     = v_old_gl_code,
                   cga_subgl_code  = v_old_sub_gl_code,
                   cga_acct_desc   = v_old_acct_desc
               WHERE cga_acct_code = p_starter_card_no AND cga_inst_code = p_inst_code;
               
               
               if sql%rowcount = 0
               then
               
                v_resp_cde := '49';
                v_errmsg :='gl details not updated for starter card '||substr(sqlerrm,1,100);
                RAISE exp_reject_record;                
               
               end if;
        
        exception when  exp_reject_record
        then 
            raise;
            
        when others
        then
            v_resp_cde := '21';
            v_errmsg :='while updating gl details for starter card '||substr(sqlerrm,1,100);
            RAISE exp_reject_record;                
        END; 
        */
        
        BEGIN
        
            update cms_appl_pan
            set   cap_card_stat =  '9'
            where cap_inst_code =  p_inst_code
            and   cap_pan_code  =  v_hash_gpr_pan;
                
        exception when others
        then
            v_resp_cde := '29';
            v_errmsg   :='While closing GPR card '|| substr(SQLERRM,1,100);
            RAISE exp_reject_record;                
        
        END;
        
      /*      -- Commented by sagar as per change suggested by tejas on 24-May-2012
        BEGIN
        
            update cms_appl_pan
            set   cap_card_stat =  '1'
            where cap_inst_code =  p_inst_code
            and   cap_pan_code  =  v_hash_starter_pan;
                
        exception when others
        then
            v_resp_cde := '29';
            v_errmsg :='while activating starter card '|| substr(SQLERRM,1,100);
            RAISE exp_reject_record;                
        
        END;
        */
        
         BEGIN
         
           INSERT INTO CMS_PAN_SPPRT
            (cps_inst_code,
             cps_pan_code,
             cps_mbr_numb,
             cps_prod_catg,
             cps_spprt_key,
             cps_spprt_rsncode,
             cps_func_remark,
             cps_ins_user,
             cps_lupd_user,
             cps_cmd_mode,
             cps_pan_code_encr
             )
           VALUES
            (p_inst_code, 
             v_hash_gpr_pan,
             p_mbr_numb,
             v_cap_prod_catg,
             'REISSUE',
             p_reason_code,
             p_remark,
             p_ins_user,
             p_ins_user,
             0,
             v_encr_gpr_pan);
         EXCEPTION
           WHEN OTHERS THEN
            v_resp_cde  := '21';
            v_errmsg := 'Error while inserting records into card support master' ||
                        SUBSTR(SQLERRM, 1, 200);

            RAISE exp_reject_record;
         END;
            
             
         BEGIN
         
           INSERT INTO CMS_HTLST_REISU
            (
             chr_inst_code,
             chr_pan_code,
             chr_mbr_numb,
             chr_new_pan,
             chr_new_mbr,
             chr_reisu_cause,
             chr_ins_user,
             chr_lupd_user,
             chr_pan_code_encr,
             chr_new_pan_encr
             )
           VALUES
            (
             p_inst_code,
             v_hash_gpr_pan,
             v_gpr_mbr_numb,
             v_hash_starter_pan,
             v_startercard_mbr_numb,
             'R',
             p_ins_user,
             p_ins_user,
             v_encr_gpr_pan,
             v_encr_starter_pan
             );
         EXCEPTION
           WHEN OTHERS THEN
            V_ERRMSG := 'Error while creating  reissuue record ' || SUBSTR(SQLERRM, 1, 100);
            V_RESP_CDE  := '21';
            RAISE EXP_REJECT_RECORD;
         END;       
    
          v_resp_cde := 1;
        

          BEGIN
          
             SELECT cms_iso_respcde
               INTO p_resp_code
               FROM cms_response_mast
              WHERE cms_inst_code = p_inst_code
                AND cms_delivery_channel = p_delivery_channel
                AND cms_response_id = v_resp_cde;

             p_resp_msg := v_errmsg;
             
          EXCEPTION
             WHEN OTHERS
             THEN
                p_resp_msg :=
                      'Problem while selecting data from response master '
                   || v_resp_cde
                   || SUBSTR (SQLERRM, 1, 100);
                p_resp_code := '89';
                ROLLBACK;
                RETURN;
          END;        
    
    
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
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_gpr_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'Y', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_gpr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );


        EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
        END;

        BEGIN

            SELECT cam_acct_bal, cam_ledger_bal
            INTO   v_acct_balance, v_ledger_bal
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code 
            AND    cam_acct_no   = v_cap_acct_no;

                     
        EXCEPTION
         WHEN OTHERS THEN
         v_acct_balance := 0;
         v_ledger_bal   := 0;
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
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'),
                         p_resp_code, p_tran_date, p_tran_time,
                         v_hash_gpr_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         p_curr_code, v_cap_prod_code, v_cap_prod_cattype,
                          p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_gpr_pan, v_cap_proxunumber, 
                         v_cap_acct_no, v_acct_balance, v_ledger_bal,
                         v_resp_cde, v_errmsg,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );
                        
                  p_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;    
    
    ---------------------------------------------------------------------------------------------------------------------------------------------    
    exception when exp_reject_record
    then
    
          BEGIN
          
             SELECT cms_iso_respcde
               INTO p_resp_code
               FROM cms_response_mast
              WHERE cms_inst_code = p_inst_code
                AND cms_delivery_channel = p_delivery_channel
                AND cms_response_id = v_resp_cde;

             p_resp_msg := v_errmsg;
             
          EXCEPTION
             WHEN OTHERS
             THEN
                p_resp_msg :=
                      'Problem while selecting data from response master1 '
                   || v_resp_cde
                   || SUBSTR (SQLERRM, 1, 100);
                p_resp_code := '89';
                ROLLBACK;
                RETURN;
          END;        
    

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
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_gpr_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_gpr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl1'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

        BEGIN

            SELECT cam_acct_bal, cam_ledger_bal
            INTO   v_acct_balance, v_ledger_bal
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code 
            AND    cam_acct_no   = v_cap_acct_no;

                     
        EXCEPTION
         WHEN OTHERS THEN
         v_acct_balance := 0;
         v_ledger_bal   := 0;
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
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'),
                         p_resp_code, p_tran_date, p_tran_time,
                         v_hash_gpr_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         p_curr_code, v_cap_prod_code, v_cap_prod_cattype,
                          p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_gpr_pan, v_cap_proxunumber, 
                         v_cap_acct_no, v_acct_balance, v_ledger_bal,
                         v_resp_cde, v_errmsg,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );
                        
                  p_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog1 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

    when others 
    then

          BEGIN
          
             SELECT cms_iso_respcde
               INTO p_resp_code
               FROM cms_response_mast
              WHERE cms_inst_code = p_inst_code
                AND cms_delivery_channel = p_delivery_channel
                AND cms_response_id = v_resp_cde;

             p_resp_msg := v_errmsg;
             
          EXCEPTION
             WHEN OTHERS
             THEN
                p_resp_msg :=
                      'Problem while selecting data from response master1 '
                   || v_resp_cde
                   || SUBSTR (SQLERRM, 1, 100);
                p_resp_code := '89';
                ROLLBACK;
                RETURN;
          END;        
    

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
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_gpr_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_gpr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl2'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

        BEGIN

            SELECT cam_acct_bal, cam_ledger_bal
            INTO   v_acct_balance, v_ledger_bal
            FROM   cms_acct_mast
            WHERE  cam_inst_code = p_inst_code 
            AND    cam_acct_no   = v_cap_acct_no;

                     
        EXCEPTION
         WHEN OTHERS THEN
         v_acct_balance := 0;
         v_ledger_bal   := 0;
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
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg,
                         add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'),
                         p_resp_code, p_tran_date, p_tran_time,
                         v_hash_gpr_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         p_curr_code, v_cap_prod_code, v_cap_prod_cattype,
                          p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_gpr_pan, v_cap_proxunumber, 
                         v_cap_acct_no, v_acct_balance, v_ledger_bal,
                         v_resp_cde, v_errmsg,
                         sysdate,p_ins_user,sysdate,p_ins_user
                        );
                        
                  p_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog2 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

    End;
    
exception when others
then
p_resp_msg := 'Exception occured in main '||substr(sqlerrm,1,100);
p_resp_code := '89';    
End;
/
show error;