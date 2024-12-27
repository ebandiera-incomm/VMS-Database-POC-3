CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_ONLINE_CARDDATA_AFTMIG (PRM_SEQNO in number,p_resp_msg OUT VARCHAR2) IS

v_initial_topup_amt  number(20,2);          
v_perm_addr_line1    cms_addr_mast.CAM_ADD_ONE%TYPE;    
v_perm_addr_line2    cms_addr_mast.CAM_ADD_TWO%TYPE;    
v_perm_addr_city     cms_addr_mast.CAM_CITY_NAME%TYPE;  
v_perm_addr_state    cms_addr_mast.CAM_STATE_CODE%TYPE; 
v_perm_addr_cntry    cms_addr_mast.CAM_CNTRY_CODE%TYPE; 
v_perm_addr_zip      cms_addr_mast.CAM_PIN_CODE%TYPE;   
v_perm_addr_phone    cms_addr_mast.CAM_PHONE_ONE%TYPE;  
v_perm_addr_mobile   cms_addr_mast.CAM_MOBL_ONE%TYPE;   
v_mail_addr_line1    cms_addr_mast.CAM_ADD_ONE%TYPE;    
v_mail_addr_line2    cms_addr_mast.CAM_ADD_TWO%TYPE;    
v_mail_addr_city     cms_addr_mast.CAM_CITY_NAME%TYPE;  
v_mail_addr_state    cms_addr_mast.CAM_STATE_CODE%TYPE; 
v_mail_addr_cntry    cms_addr_mast.CAM_CNTRY_CODE%TYPE; 
v_mail_addr_zip      cms_addr_mast.CAM_PIN_CODE%TYPE;   
v_mail_addr_phone    cms_addr_mast.CAM_PHONE_ONE%TYPE;  
v_mail_addr_mobile   cms_addr_mast.CAM_MOBL_ONE%TYPE;   
v_merchant_id        cms_merinv_merpan.CMM_MER_ID%TYPE;
v_ccf_file_name      cms_cardissuance_status.CCS_CCF_FNAME%TYPE;
v_kyc_flag           cms_caf_info_entry.CCI_KYC_FLAG%TYPE;
v_total_accts        migr_online_cardlog.TOTAL_ACCTS%TYPE;    
v_saving_acct        cms_acct_mast.CAM_ACCT_NO%TYPE;
/*  
v_sec_ques           cms_security_questions.CSQ_QUESTION%TYPE;  
v_sec_ans            cms_security_questions.CSQ_ANSWER_HASH%TYPE;
v_sec_ques_two       cms_security_questions.CSQ_QUESTION%TYPE;  
v_sec_ans_two        cms_security_questions.CSQ_ANSWER_HASH%TYPE;
v_sec_ques_three     cms_security_questions.CSQ_QUESTION%TYPE;  
v_sec_ans_three      cms_security_questions.CSQ_ANSWER_HASH%TYPE;*/
v_cust_password      cms_cust_mast.CCM_PASSWORD_HASH%TYPE;
v_sms_alert_flag     migr_online_cardlog.SMS_ALERT_FLAG%TYPE := 'N';
v_email_alert_flag   migr_online_cardlog.EMAIL_ALERT_FLAG%TYPE := 'N';
v_store_id           cms_caf_info_entry.CCI_STORE_ID%TYPE;
v_flag               varchar2(1);
v_err                varchar2(1000);
v_inst_code           number(3) :=1;
v_cnt                 number(1);
v_cust_code          cms_appl_pan.CAP_CUST_CODE%TYPE;
v_gethash            cms_appl_pan.cap_pan_code%type;   
v_appl_code          cms_caf_info_entry.cci_appl_code%type ;

TYPE migr_sec_ques_detl IS RECORD (
v_sec_ques       cms_security_questions.CSQ_QUESTION%TYPE,
v_sec_ans        cms_security_questions.CSQ_ANSWER_HASH%TYPE);
TYPE migr_question_detl_tab IS TABLE OF migr_sec_ques_detl
 INDEX BY PLS_INTEGER;
migr_question_data    migr_question_detl_tab;

cursor cur_carddata is
select rowid row_id,a.* from migr_online_cardlog a;

cursor cur_sec_que(p_cust_code number) is
select csq_question,csq_answer_hash 
from cms_security_questions,cms_cust_mast
where ccm_cust_id=csq_cust_id
and ccm_inst_code = csq_inst_code
and ccm_cust_code = p_cust_code
and ccm_inst_code = '1';


BEGIN

     v_err := 'OK';

      BEGIN

        INSERT INTO MIGR_ONLINE_CARDLOG
        SELECT DECODE (UPPER (nn.ccm_salut_code),
                  'MR.', '0',
                  'MR', '0',
                  'MS', '1',
                  'MS.', '1',
                  'MRS', '2',
                  'MRS.', '2',
                  'DR', '3',
                  'DR.', '3'
                 ) TITLE                                                        --TITLE
       ,
       nn.ccm_first_name FIRST_NAME                                             --FIRST_NAME
       ,
       nn.ccm_last_name LAST_NAME                                               --LAST_NAME
       ,
       nn.ccm_ssn       ID_NUMBER                                               --ID_NUMBER
       ,
       '0.00'  INITIAL_TOPUP_AMT                                                --Initial Load amount
       ,  
       TO_CHAR (nn.ccm_birth_date, 'yyyymmdd') BIRTH_DATE                       --BIRTH_DATE
       ,
       NULL PERM_ADDR_LINE1                                                     --PERMANENT_ADDRESS_LINE1
       ,
       NULL PERM_ADDR_LINE2                                                     --PERMANENT_ADDRESS_LINE2
       ,
       NULL PERM_ADDR_CITY                                                      --PERMANENT_ADDRESS_CITY
       ,
       NULL PERM_ADDR_STATE                                                     --PERMANENT_ADDR_STATE
       ,
       NULL PERM_ADDR_CNTRY                                                     --PERMANENT_ADDR_CNTRY
       ,
       NULL PERM_ADDR_ZIP                                                       --PERM_ADDR_ZIP
       ,
       NULL PERM_ADDR_PHONE                                                     --PERM_ADDR_PHONE
       ,                                                                        
       NULL PERM_ADDR_MOBILE                                                    --PERM_ADDR_MOBILE
       ,                                                                        
       NULL MAIL_ADDR_LINE1                                                     --MAIL_ADDR_LINE1
       ,                                                                        
       NULL MAIL_ADDR_LINE2                                                     --MAIL_ADDR_LINE2
       ,                                                                        
       NULL MAIL_ADDR_CITY                                                      --MAIL_ADDR_CITY
       ,                                                                        
       NULL MAIL_ADDR_STATE                                                     --MAIL_ADDR_STATE
       ,                                                                        
       NULL MAIL_ADDR_CNTRY                                                     --MAIL_ADDR_CNTRY
       ,                                                                        
       NULL MAIL_ADDR_ZIP                                                       --MAIL_ADDR_ZIP
       ,                                                                        
       NULL MAIL_ADDR_PHONE                                                     --MAIL_ADDR_PHONE
       ,                                                                        
       NULL MAIL_ADDR_MOBILE                                                    --MAIL_ADDR_MOBILE
       ,
       nn.ccm_email_one EMAIL_ADDRESS                                           --EMAIL_ADDRESS
       ,
       cap_prod_code    PRODUCT_CODE                                            --Product Code
       , 
       cap_card_type    PROD_CATG_CODE                                          --Prodcatg 
       ,
       NVL (cap_appl_bran, '0001') BRANCH_ID                                    --BRANCH_ID
       ,
       NULL MERCHANT_ID                                                         -- Merchant ID
       ,
       fn_dmaps_main (cap_pan_code_encr) CARD_NUMBER                            --CARD_NUMBER
       ,
       cap_card_stat CARD_STAT                                                  --CARD_STAT
       ,
       cap_proxy_number PROXY_NUMBER                                            --PROXY_NUMBER
       ,
       DECODE (cap_startercard_flag, 'N', '1', 'Y', '0') STARTER_CARD_FLAG      --STARTER_CARD_FLAG
       ,
       TO_CHAR (cap_active_date, 'yyyymmdd hh24:mi:ss') ACTIVE_DATE_TIME        --ACTIVE_DATE_TIME
       ,
       TO_CHAR (cap_expry_date, 'yyyymmdd') EXPIRY_DATE                         --EXPIRY_DATE
       ,
       TO_CHAR (cap_pangen_date, 'yyyymmdd hh24:mi:ss') PANGEN_DATE_TIME        --PANGEN_DATE_TIME
       ,
       cap_atm_offline_limit ATM_OFFLINE_LIMIT                                  --ATM_OFFLINE_LIMIT
       ,                                                                        
       cap_atm_online_limit  ATM_ONLINE_LIMIT                                   --ATM_ONLINE_LIMIT
       ,                                                                        
       cap_pos_offline_limit  POS_OFFLINE_LIMIT                                 --POS_OFFLINE_LIMIT
       ,                                                                         
       cap_pos_online_limit   POS_ONLINE_LIMIT                                  --POS_ONLINE_LIMIT
       ,                                                                        
       cap_offline_aggr_limit OFFLINE_AGGR_LIMIT                                --OFFLINE_AGGR_LIMIT
       ,                                                                        
       cap_online_aggr_limit  ONLINE_AGGR_LIMIT                                 --ONLINE_AGGR_LIMIT 
       ,                                                                        
       cap_mmpos_online_limit MMPOS_ONLINE_LIMIT                                --MMPOS_ONLINE_LIMIT
       ,
       cap_mmpos_offline_limit MMPOS_OFFLINE_LIMIT                              --MMPOS_OFFLINE_LIMIT
       ,
       cap_pin_off PIN_OFFSET                                                   --PIN_OFFSET
       ,
       TO_CHAR (cap_next_bill_date, 'yyyymmdd') NEXT_BILL_DATE                  --NEXT_BILL_DATE
       ,
       TO_CHAR (cap_next_mb_date, 'yyyymmdd') NEXT_MON_BILL_DATE                --NEXT_MON_BILL_DATE
       ,
       TO_CHAR (cap_embos_date, 'yyyymmdd HH24:MI:SS') EMBOSS_DATE              --EMBOSS_DATE
       ,
       DECODE (cap_embos_flag, 'N', '1', 'Y', '0') EMBOSS_FLAG                  --EMBOSS_FLAG
       ,
       TO_CHAR (cap_pingen_date, 'yyyymmdd HH24:MI:SS') PINGEN_DATE             --PINGEN_DATE
       ,
       DECODE (cap_pin_flag, 'N', '1', 'Y', '0') PIN_FLAG                       --PIN_FLAG
       ,
       NULL  CCF_FILE_NAME                                                      --CCF FILE NAME
       ,
       NULL  KYC_FLAG                                                            --KYC flag
       ,
       NULL  TOTAL_ACCTS                                                        --No of Accounts    
       ,
       cap_acct_no ACCT_NUMB1                                                   -- Spending acct
       ,
       NULL ACCT_NUMB2                                                            -- Acct 2    
       ,
       NULL ACCT_NUMB3                                                            -- Acct 3    
       ,
       NULL ACCT_NUMB4                                                            -- Acct 4    
       ,
       NULL ACCT_NUMB5                                                            -- Acct 5                           
       ,
       NULL SAVING_ACCT                                                         -- Saving Account
       ,
       cap_serial_number SERIAL_NUMBER                                          --SERIAL_NUMBER    
       ,
       cap_firsttime_topup INITIAL_LOAD_FLAG                                    --INITIAL_LOAD_FLAG
       ,                                      
       NULL  SEC_QUES_ONE                                                       --"SECURITY Question ONE",
       ,
       NULL  SEC_ANS_ONE                                                        --"SECURITY ANSWER ONE",
       ,
       NULL  SEC_QUES_TWO                                                       --"SECURITY QUESTION TWO" ,
       ,
       NULL  SEC_ANS_TWO                                                        --"SECURITY ANSWER TWO",
       ,
       NULL  SEC_QUES_THREE                                                     --"SECURITY QUESTION  THREE" ,
       ,
       NULL SEC_ANS_THREE                                                       --"SECURITY ANSWER THREE",
       , 
       nn.ccm_user_name CUST_USERNAME                                           -- Cust_User Name
       ,
       NULL CUST_PASSWORD                                                       -- Cust_Password,   
       ,
       NULL SMS_ALERT_FLAG                                                      --Sms_Alert_Flag,
       ,
       NULL EMAIL_ALERT_FLAG                                                    --Email_Alert_Flag,    
       ,
       NULL STORE_ID                                                            --Store id    
       ,
       nn.ccm_id_type  ID_TYPE                                                  --ID_TYPE
       ,
       nn.ccm_id_issuer ID_ISSUER                                               --ID_ISSUER             
       ,
       to_char(nn.ccm_idissuence_date,'yyyymmdd hh24:mis:ss') ID_ISSUE_DATE     --ID_ISSUE_DATE
       ,
       to_char(nn.ccm_idexpry_date,'yyyymmdd hh24:mis:ss') ID_EXPRY_DATE        --ID_EXPRY_DATE
      FROM cms_appl_pan, CMS_CUST_MAST nn
      where nn.CCM_INST_CODE = cap_inst_code
      and nn.CCM_CUST_CODE   = cap_cust_code
      and CAP_ACCT_NO in (select MCI_SEG31_NUM from migr_caf_info_entry where MCI_PROC_FLAG ='S' and MCI_MIGR_SEQNO =PRM_SEQNO)
      and cap_ins_user <> (select CUM_USER_CODE from cms_userdetl_mast where CUM_LGIN_CODE ='MIGR_USER');

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                     'ERROR WHILE INSERTION INTO MIGR_ONLINE_CARDLOG TABLE ' || SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
            RETURN;
      END;

    for i in cur_carddata
    loop
    
        v_gethash := gethash(i.card_number);
    
        BEGIN
            Select cap_cust_code,cap_appl_code INTO v_cust_code,v_appl_code
            from cms_appl_pan
            where cap_pan_code = v_gethash;
            
              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    p_resp_msg := 'CARD NOT FOUND IN CMS';--NO DATA FOUND WHILE SELECTING CUST CODE FROM APPL PAN -' ||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
                    RETURN;
           WHEN OTHERS THEN
                    p_resp_msg := 'ERROR WHILE SELECTING CARD DETAILS FROM PAN MASTER -' ||SUBSTR (SQLERRM, 1, 200); --Error message modified by Pankaj S. on 25-Sep-2013
                    RETURN;
        END;

      Begin
        select cam_add_one, 
               cam_add_two, 
               cam_city_name,
               cam_state_code, 
               cam_cntry_code, 
               cam_pin_code, 
               cam_phone_one, 
               cam_mobl_one
          into
               v_perm_addr_line1, 
               v_perm_addr_line2, 
               v_perm_addr_city,  
               v_perm_addr_state, 
               v_perm_addr_cntry, 
               v_perm_addr_zip,   
               v_perm_addr_phone, 
               v_perm_addr_mobile
         FROM cms_addr_mast
         WHERE cam_addr_flag = 'P'
           AND v_inst_code  = cam_inst_code 
           AND v_cust_code = cam_cust_code;

           v_flag := 'Y';
        exception 
            when no_data_found
            then
               v_perm_addr_line1 := null;
               v_perm_addr_line2 := null;
               v_perm_addr_city  := null;  
               v_perm_addr_state := null; 
               v_perm_addr_cntry := null; 
               v_perm_addr_zip   := null; 
               v_perm_addr_phone := null; 
               v_perm_addr_mobile:= null;            
            when others
            then
                p_resp_msg := 'ERROR WHILE SELECTING PARMANENT ADDRESS -' ||SUBSTR (SQLERRM, 1, 200);
                RETURN;
        End;
        
        Begin
        select     cam_add_one, 
                cam_add_two, 
                cam_city_name,
                cam_state_code, 
                cam_cntry_code, 
                cam_pin_code,
                cam_phone_one, 
                cam_mobl_one
         into 
               v_mail_addr_line1, 
               v_mail_addr_line2, 
               v_mail_addr_city,  
               v_mail_addr_state, 
               v_mail_addr_cntry, 
               v_mail_addr_zip,   
               v_mail_addr_phone, 
               v_mail_addr_mobile
         FROM cms_addr_mast
         WHERE cam_addr_flag = 'O'
           AND v_inst_code  = cam_inst_code
           AND v_cust_code = cam_cust_code;

           v_flag := 'Y';
        exception 
            when no_data_found
            then
               v_mail_addr_line1 := null; 
               v_mail_addr_line2 := null; 
               v_mail_addr_city  := null; 
               v_mail_addr_state := null; 
               v_mail_addr_cntry := null; 
               v_mail_addr_zip   := null; 
               v_mail_addr_phone := null; 
               v_mail_addr_mobile:= null;                
            when others
            then
                p_resp_msg := 'ERROR WHILE SELECTING MAILING ADDRESS -' ||SUBSTR (SQLERRM, 1, 200);
                RETURN;
        End;

        BEGIN

            select CMM_MER_ID into v_merchant_id
            from cms_merinv_merpan     
            where  CMM_PAN_CODE= v_gethash;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_merchant_id := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING MERCHANT ID -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN

            SELECT ccs_ccf_fname into v_ccf_file_name
            FROM cms_cardissuance_status
            WHERE ccs_pan_code = v_gethash;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_ccf_file_name := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING CCF FILE NAME -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN

            SELECT DECODE (cci_kyc_flag,'N', '0',
                                        'Y', '1',
                                        'E', '2',
                                        'P', '3',
                                        'F', '4',
                                        'O', '5'),cci_store_id INTO v_kyc_flag,v_store_id
             FROM cms_caf_info_entry
             WHERE cci_appl_code = v_appl_code;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_kyc_flag := null;
               v_store_id := NULL;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING KYC FLAG -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN

          SELECT COUNT (1) INTO v_total_accts
             FROM cms_cust_acct
            WHERE cca_cust_code = v_cust_code;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_total_accts := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING TOTAL ACCOUNT NUMBER -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN

            SELECT cam_acct_no into v_saving_acct
             FROM cms_acct_mast, cms_cust_acct
            WHERE cam_type_code = '2'
              AND cam_acct_id = cca_acct_id
              And cca_cust_code = v_cust_code;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_saving_acct := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING SAVING ACCOUNT NUMBER -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN
            v_cnt := 0;
            for j in cur_sec_que(v_cust_code) loop
                 v_cnt := v_cnt +1;
                 migr_question_data(v_cnt).v_sec_ques := j.csq_question;
                 migr_question_data(v_cnt).v_sec_ans := j.csq_answer_hash;
            end loop;
                  v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 migr_question_data(1).v_sec_ques := null;
                 migr_question_data(1).v_sec_ans := null;
                 migr_question_data(2).v_sec_ques := null;
                 migr_question_data(2).v_sec_ans := null;
                 migr_question_data(3).v_sec_ques := null;
                 migr_question_data(3).v_sec_ans := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING SECURITY QUESTIONS -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
        
        BEGIN

            select CCM_PASSWORD_HASH into v_cust_password
            from cms_cust_mast
            where ccm_cust_code = v_cust_code
            and ccm_inst_code = v_inst_code;

              v_flag := 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_cust_password := null;
        WHEN OTHERS THEN
           p_resp_msg := 'ERROR WHILE SELECTING CUSTOMER PASSWORD -' ||SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;

       if v_flag = 'Y'
       then

            BEGIN
                update MIGR_ONLINE_CARDLOG
                set     INITIAL_TOPUP_AMT =v_initial_topup_amt, 
                        PERM_ADDR_LINE1   =v_perm_addr_line1  , 
                        PERM_ADDR_LINE2   =v_perm_addr_line2  , 
                        PERM_ADDR_CITY    =v_perm_addr_city   , 
                        PERM_ADDR_STATE   =v_perm_addr_state  , 
                        PERM_ADDR_CNTRY   =v_perm_addr_cntry  , 
                        PERM_ADDR_ZIP     =v_perm_addr_zip    , 
                        PERM_ADDR_PHONE   =v_perm_addr_phone  , 
                        PERM_ADDR_MOBILE  =v_perm_addr_mobile , 
                        MAIL_ADDR_LINE1   =v_mail_addr_line1  , 
                        MAIL_ADDR_LINE2   =v_mail_addr_line2  ,
                        MAIL_ADDR_CITY    =v_mail_addr_city   , 
                        MAIL_ADDR_STATE   =v_mail_addr_state  , 
                        MAIL_ADDR_CNTRY   =v_mail_addr_cntry  , 
                        MAIL_ADDR_ZIP     =v_mail_addr_zip    , 
                        MAIL_ADDR_PHONE   =v_mail_addr_phone  , 
                        MAIL_ADDR_MOBILE  =v_mail_addr_mobile , 
                        MERCHANT_ID       =v_merchant_id      , 
                        CCF_FILE_NAME     =v_ccf_file_name    , 
                        KYC_FLAG          =v_kyc_flag         , 
                        TOTAL_ACCTS       =v_total_accts      ,    
                        SAVING_ACCT       =v_saving_acct      , 
                        SEC_QUES_ONE      =migr_question_data(1).v_sec_ques, 
                        SEC_ANS_ONE       =migr_question_data(1).v_sec_ans, 
                        SEC_QUES_TWO      =migr_question_data(2).v_sec_ques, 
                        SEC_ANS_TWO       =migr_question_data(2).v_sec_ans,
                        SEC_QUES_THREE    =migr_question_data(3).v_sec_ques, 
                        SEC_ANS_THREE     =migr_question_data(3).v_sec_ans, 
                        CUST_PASSWORD     =v_cust_password    , 
                        SMS_ALERT_FLAG    =v_sms_alert_flag   , 
                        EMAIL_ALERT_FLAG  =v_email_alert_flag , 
                        STORE_ID          =v_store_id   
                 where rowid = i.row_id;

            EXCEPTION WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE UPDATING CARD DETAILS -' ||SUBSTR (SQLERRM, 1, 200);
              RETURN;
            END;

        end if;

    end loop;

    BEGIN

     MIGR_ONLINE_CARDDATA_FILE(PRM_SEQNO,p_resp_msg);
     
         if p_resp_msg <> 'OK'
         then
         
         p_resp_msg := 'Error while card file writting '||substr(sqlerrm,1,100); --Error message modified by Pankaj S. on 25-Sep-2013
         return;         
         
         end if;

    EXCEPTION WHEN OTHERS
    THEN
     p_resp_msg := 'Error While calling file writting method for CardData '||substr(sqlerrm,1,100); --Error message modified by Pankaj S. on 25-Sep-2013
     return;
    END;

    p_resp_msg := v_err;


EXCEPTION WHEN OTHERS
THEN

p_resp_msg := 'MAIN EXCEPTION -' ||SUBSTR (SQLERRM, 1, 200);
RETURN;

end;
/

show error;
