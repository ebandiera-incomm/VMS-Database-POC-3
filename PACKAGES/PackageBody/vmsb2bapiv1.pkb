create or replace
PACKAGE BODY          vmscms.VMSB2BAPIV1
IS
procedure  card_replacerenewal(p_inst_code_in            IN  NUMBER,
                                 P_CARD_NO_in            IN  VARCHAR2,
                                 P_MSG_in                IN  VARCHAR2,
                                 P_TXN_MODE_in           in  varchar2,
                                 P_CURR_CODE_in          IN  VARCHAR2,
                                 p_first_name_in         IN  varchar2,
                                 p_middleinitial_in      IN  varchar2,
                                 p_last_name_in          IN  varchar2,
                                 p_email_in              in  varchar2,
                                 p_phone_in              IN  varchar2,
                                 p_addressLine_one_in    IN  varchar2,
                                 p_addressLine_two_in    IN  varchar2,
                                 p_addressLine_three_in  IN  varchar2,
                                 p_state_in              IN  varchar2,
                                 p_city_in               IN  varchar2,
                                 p_country_in            IN  varchar2,
                                 p_postal_code_in        in  varchar2,
                                 p_comments_in           in  varchar2,
                                 p_request_reason_in     IN  varchar2,
                                 P_shippingMethod_in     in  varchar2,
                                 p_isFeeWaived_in        in  varchar2,
                                 P_fsapi_channel_in      in  varchar2,
                                 P_STAN_IN               IN  VARCHAR2,
                                 P_MBR_NUMB_IN           IN  VARCHAR2,
                                 P_RVSL_CODE_IN          IN  NUMBER,
                                 p_ship_CompanyName_in   in  varchar2,
                                 p_card_expirty_date_out out varchar2,
                                 p_available_balance_out out varchar2,
                                 p_last4digits_pan_out   out varchar2,
                                 p_card_fee_out          out varchar2,
                                 p_resp_code_out         out varchar2,
                                 p_resp_messge_out       out varchar2)
AS

    /*************************************************
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18
       
   *************************************************/
  l_auth_savepoint        PLS_INTEGER DEFAULT 0;
  l_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 

  L_ENCR_PAN             CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;

  l_CAP_PROD_CATG        CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  l_CAP_CARD_STAT        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  l_ACCT_NUMBER          CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  l_CUST_CODE            CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  l_APPL_CODE            CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  l_STARTERCARD_FLAG     CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
  l_NEW_DISPNAME         CMS_APPL_PAN.CAP_DISP_NAME%TYPE;
  l_PROD_CODE            CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  l_PROD_CATTYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  l_lmtprfl              CMS_APPL_PAN.cap_prfl_code%TYPE;
  l_profile_level        CMS_APPL_PAN.cap_prfl_levl%TYPE;
  L_oldcard_expry        CMS_APPL_PAN.cap_expry_date%TYPE;
  L_RRN                  TRANSACTIONLOG.RRN%TYPE;
  L_BUSINESS_DATE        TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  L_BUSINESS_TIME        TRANSACTIONLOG.BUSINESS_TIME%TYPE;
   
  l_DR_CR_FLAG           CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  l_OUTPUT_TYPE          CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
  l_TXN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  l_TRAN_TYPE            CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  l_replacement_option    cms_prod_cattype.cpc_renew_replace_option%type;
  l_profile_code          cms_prod_cattype.cpc_profile_code%type;
  l_new_product           cms_prod_cattype.CPC_RENEW_REPLACE_PRODCODE%type;
  l_new_cardtype          cms_prod_cattype.CPC_RENEW_REPLACE_CARDTYPE%type;
  l_DISABLE_REPL_FLAG     cms_prod_cattype.CPC_DISABLE_REPL_FLAG%TYPE;
  l_DISABLE_REPL_EXPDAYS  cms_prod_cattype.CPC_DISABLE_REPL_EXPRYDAYS%TYPE;
  l_DISABLE_REPL_MINBAL   cms_prod_cattype.CPC_DISABLE_REPL_MINBAL%TYPE;
  l_disable_repl_message  cms_prod_cattype.CPC_DISABLE_REPL_MESSAGE%TYPE;
  l_shipment_id           vms_shipment_tran_mast.vsm_shipment_id%TYPE;
  l_timestamp             TRANSACTIONLOG.TIME_STAMP%TYPE;
  l_delivery_channel      cms_transaction_mast.CTM_DELIVERY_CHANNEL%type;
  l_txn_code              cms_transaction_mast.CTM_TRAN_CODE%type;
  L_TRANS_DATE            TRANSACTIONLOG.DATE_TIME%TYPE;
  L_PROXUNUMBER           cms_appl_pan.cap_proxy_number%type;
  l_RESP_CDE              TRANSACTIONLOG.RESPONSE_CODE%TYPE;  
  l_ERR_MSG               TRANSACTIONLOG.ERROR_MSG%TYPE; 
  l_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
  l_dup_check            PLS_INTEGER;
  l_CAM_LUPD_DATE        CMS_ADDR_MAST.CAM_LUPD_DATE%type;
  l_ACCT_BALANCE         cms_acct_mast.cam_acct_bal%type;
  l_LEDGER_BAL           cms_acct_mast.cam_LEDGER_BAL%type;
   
  l_NEW_HASH_PAN         cms_appl_pan.cap_pan_code%type;
  l_CAM_TYPE_CODE        CMS_ACCT_MAST.CAM_TYPE_CODE%type;
  l_NEW_CARD_NO          VARCHAR2(100);
  p_expiry_date_out      date;
  l_FEE_FLAG_out         VARCHAR2(1)  DEFAULT  'Y';
  L_APPLPAN_CARDSTAT     cms_appl_pan.cap_card_stat%type;
  p_resp_msg_out         varchar2(100);
  l_CAPTURE_DATE_out     date;
  L_cntry_code           GEN_STATE_MAST.gsm_cntry_code%TYPE;
  L_state_code           GEN_STATE_MAST.gsm_state_code%TYPE;
  l_TRAN_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%type;
  l_cardstat_tran_code   CMS_TRANSACTION_MAST.CTM_TRAN_code%type;
  l_fee_amt_out          varchar2(20);
  l_serial_no            cms_appl_pan.CAP_SERIAL_NUMBER%type;
  l_card_id              cms_appl_pan.CAP_CARDPACK_ID%type;
  l_encrypt_enable       cms_prod_cattype.cpc_encrypt_enable%type;
  l_encr_addr_lineone    cms_addr_mast.cam_add_one%type;
  l_encr_addr_linetwo    cms_addr_mast.cam_add_two%type;
  l_encr_addr_linethree  cms_addr_mast.cam_add_three%type;
  l_encr_city            cms_addr_mast.cam_city_name%type;
  l_encr_mob_one         cms_addr_mast.cam_mobl_one%type;
  l_encr_email           cms_addr_mast.cam_email%type;
  l_encr_zip             cms_addr_mast.cam_pin_code%type;
  l_encr_first_name      cms_cust_mast.ccm_first_name%type;
  l_encr_mid_name        cms_cust_mast.ccm_mid_name%type;
  l_encr_last_name       cms_cust_mast.ccm_last_name%type;
  
  EXP_REJECT_RECORD      EXCEPTION;
  
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  SAVEPOINT l_auth_savepoint;
            L_RESP_CDE := '00';
            L_ERR_MSG  := 'OK';

     begin
             select vft_channel_code,vft_tran_code
                into l_delivery_channel,l_txn_code
                from vms_fsapi_trans_mast
                where vft_channel_desc=P_fsapi_channel_in
                and vft_request_type=P_shippingMethod_in;
         Exception when others then
           l_RESP_CDE := '89';
            L_ERR_MSG := 'Error while getting delivery channel and tran code '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
       end;

           BEGIN
           l_HASH_PAN := GETHASH(P_CARD_NO_IN);
           EXCEPTION
            WHEN OTHERS THEN
           l_RESP_CDE := '89';
           L_ERR_MSG := 'Error while converting into hash value ' ||fn_mask(P_CARD_NO_in,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        BEGIN
         L_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO_IN);
        EXCEPTION
         WHEN OTHERS THEN
           l_RESP_CDE := '89';
           L_ERR_MSG := 'Error while converting into encrypted value '||fn_mask(P_CARD_NO_IN,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       BEGIN
         SELECT TO_CHAR (TO_CHAR (SYSDATE, 'YYMMDDHH24MISS')||LPAD (seq_cardrplrenewal.NEXTVAL, 3, '0'))
         INTO L_RRN FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
           l_RESP_CDE := '89';
         L_ERR_MSG := 'Error while generating rrn'||' '||SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
       END;

       BEGIN
         SELECT  TO_CHAR (SYSDATE, 'YYYYMMDD'),TO_CHAR(SYSDATE, 'HH24MMSS')
         INTO L_BUSINESS_DATE,L_BUSINESS_TIME  FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
           l_RESP_CDE := '89';
         L_ERR_MSG := 'Error while generating business date'||' '||SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;

       BEGIN
        L_TRANS_DATE := TO_DATE(SUBSTR(TRIM(L_BUSINESS_DATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(L_BUSINESS_TIME), 1, 10),
                            'yyyymmdd hh24:mi:ss');
      EXCEPTION
         WHEN OTHERS THEN
         l_RESP_CDE := '89';
          L_ERR_MSG := 'Error while generating TRANS_DATE'||' '||SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;

        BEGIN
           SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO l_AUTH_ID FROM DUAL;
        EXCEPTION
          WHEN OTHERS THEN
           l_ERR_MSG  := 'Error while generating authid ' || SUBSTR(SQLERRM, 1, 300);
           l_RESP_CDE := '89';
           RAISE EXP_REJECT_RECORD;
        END;
          BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG,
               CTM_OUTPUT_TYPE,
               TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
               CTM_TRAN_TYPE,CTM_TRAN_DESC
           INTO l_DR_CR_FLAG, l_OUTPUT_TYPE, l_TXN_TYPE, l_TRAN_TYPE,l_TRAN_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = l_txn_code AND
               CTM_DELIVERY_CHANNEL = l_delivery_channel AND
               CTM_INST_CODE = P_INST_CODE_in;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           L_RESP_CDE := '89'; --Ineligible Transaction
           L_ERR_MSG  := 'Transflag  not defined for txn code ' || l_txn_code ||
                      ' and delivery channel ' || l_delivery_channel;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           L_RESP_CDE := '89'; --Ineligible Transaction
           L_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
        END;
          BEGIN
           select vsm_shipment_id into l_shipment_id
               from vms_shipment_tran_mast where vsm_shipment_key=P_shippingMethod_in;
           EXCEPTION  WHEN NO_DATA_FOUND THEN
           L_RESP_CDE := '89'; --Ineligible Transaction
           L_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            l_RESP_CDE := '89'; --Ineligible Transaction
           L_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
           END;
       BEGIN
        SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE,
                CAP_APPL_CODE, CAP_STARTERCARD_FLAG, CAP_DISP_NAME, CAP_PROD_CODE, CAP_CARD_TYPE
                ,cap_prfl_code,cap_prfl_levl,cap_expry_date,cap_proxy_number,CAP_SERIAL_NUMBER,CAP_CARDPACK_ID
           INTO l_CAP_PROD_CATG, l_CAP_CARD_STAT,l_ACCT_NUMBER,l_CUST_CODE,
                l_APPL_CODE,l_STARTERCARD_FLAG,l_NEW_DISPNAME,l_PROD_CODE,l_PROD_CATTYPE
                ,l_lmtprfl,l_profile_level,L_oldcard_expry,L_PROXUNUMBER,l_serial_no,l_card_id
          FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = L_HASH_PAN AND CAP_INST_CODE = P_INST_CODE_IN;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           L_ERR_MSG  := 'Pan not found in master';
           L_RESP_CDE := '89';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           L_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||SUBSTR(SQLERRM, 1, 200);
           L_RESP_CDE := '89';
           RAISE EXP_REJECT_RECORD;
        END;
 --- form factor validation..

            BEGIN
              IF l_CAP_PROD_CATG ='V' THEN
                  L_RESP_CDE := '28';  --
                  L_ERR_MSG  := 'Replacement Not Allowed For Virtual product';
                   RAISE EXP_REJECT_RECORD;
                END if;
             EXCEPTION  WHEN EXP_REJECT_RECORD THEN
              RAISE;
              WHEN OTHERS THEN
                  L_RESP_CDE := '89';
                  L_ERR_MSG  := 'Error while selecting card type '||substr(sqlerrm,1,200);
                  raise EXP_REJECT_RECORD;
             END;

            BEGIN
             SELECT gsm_cntry_code,gsm_state_code
                  INTO L_cntry_code,L_state_code
                 FROM GEN_STATE_MAST
                 WHERE GSM_SWITCH_STATE_CODE=p_state_in
                 AND gsm_cntry_code= (select gcm_cntry_code from gen_cntry_mast where gcm_switch_cntry_code=p_country_in);

                EXCEPTION  WHEN NO_DATA_FOUND  THEN
                  L_RESP_CDE := '26';
                  L_ERR_MSG  := 'State code is not valid';
                  raise EXP_REJECT_RECORD;
              WHEN OTHERS THEN
              L_RESP_CDE := '89';
                  L_ERR_MSG  := 'Error while selecting state code '||substr(sqlerrm,1,200);
                  raise EXP_REJECT_RECORD;
              END;

         BEGIN
             SELECT COUNT (1)
               INTO l_dup_check
               FROM cms_htlst_reisu
              WHERE chr_inst_code = p_inst_code_in
                AND chr_pan_code = l_hash_pan
                AND chr_reisu_cause = 'R'
                AND chr_new_pan IS NOT NULL;

             IF l_dup_check > 0
             THEN
                l_resp_cde := '29';
                l_err_msg := 'Card already Replaced';
                RAISE exp_reject_record;
             END IF;

             EXCEPTION WHEN EXP_REJECT_RECORD THEN
                 RAISE;
                WHEN OTHERS THEN
                  L_RESP_CDE := '89';
                  L_ERR_MSG  := 'Error while selecting Replaced or Renewed dtls '||substr(sqlerrm,1,200);
                  RAISE EXP_REJECT_RECORD;
          END;

         BEGIN
                  SELECT CAM_LUPD_DATE
                  INTO l_CAM_LUPD_DATE
                  FROM CMS_ADDR_MAST
                  WHERE CAM_INST_CODE=P_INST_CODE_In
                  AND CAM_CUST_CODE=l_CUST_CODE
                  AND CAM_ADDR_FLAG='P';

                  IF l_cam_lupd_date > sysdate-1 THEN
                     l_ERR_MSG  := 'Card replacement is not allowed to customer who changed address in last 24 hr';
                     l_RESP_CDE := '25';
                    RAISE EXP_REJECT_RECORD;
                  END IF;

                EXCEPTION  WHEN EXP_REJECT_RECORD THEN
                RAISE;
                WHEN OTHERS THEN
                   l_ERR_MSG  := 'Error while selecting customer address details' ||SUBSTR(SQLERRM, 1, 200);
                   l_RESP_CDE := '89';
                   RAISE EXP_REJECT_RECORD;
                END;

                IF upper(p_isFeeWaived_in) ='TRUE' OR p_isFeeWaived_in ='1' THEN
                     l_FEE_FLAG_out :='N';
                  else
                    l_FEE_FLAG_out :='Y';
                END IF;

        BEGIN
             sp_authorize_txn_cms_auth (P_INST_CODE_in,
                                        P_MSG_in,
                                        l_RRN,
                                        l_delivery_channel,
                                        '0',--P_TERM_ID,
                                        l_txn_code,
                                        P_TXN_MODE_in,
                                        L_BUSINESS_DATE,--P_TRAN_DATE,
                                        L_BUSINESS_TIME,--P_TRAN_TIME,
                                        P_CARD_NO_in,
                                        P_INST_CODE_in,
                                        NULL,--P_TXN_AMT,
                                        NULL,
                                        NULL,
                                        NULL,--P_MCC_CODE,
                                        P_CURR_CODE_IN,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        'B',--NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        null,--P_EXPRY_DATE,
                                        P_STAN_IN,
                                        P_MBR_NUMB_IN,
                                        P_RVSL_CODE_IN,
                                        NULL,--P_TXN_AMT,
                                        l_fee_amt_out,--l_AUTH_ID,--P_AUTH_ID,
                                        L_RESP_CDE,
                                        L_ERR_MSG,
                                        l_CAPTURE_DATE_out,
                                        l_FEE_FLAG_out);

            IF L_RESP_CDE <> '00' AND L_ERR_MSG <> 'OK'
             THEN
                p_resp_code_out := L_RESP_CDE;
                p_resp_messge_out := 'Error from auth process' || L_ERR_MSG;
				        RAISE EXP_REJECT_RECORD;
             END IF;

          EXCEPTION  WHEN EXP_REJECT_RECORD THEN
		          RAISE;
		    WHEN OTHERS  THEN
                L_RESP_CDE := '89';
                L_ERR_MSG :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
          END;
           BEGIN
                select  DECODE(upper(p_request_reason_in),'LOST-STOLEN','48','DAMAGED','41') into l_cardstat_tran_code
                   from dual;
            EXCEPTION WHEN OTHERS THEN
                L_RESP_CDE := '89';
                L_ERR_MSG :='Error from DECODE of cards trans code' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
          END;
       BEGIN
                    UPDATE CMS_APPL_PAN
                    SET CAP_CARD_STAT=DECODE(p_request_reason_in,'LOST-STOLEN',2,'DAMAGED',3)
                    WHERE  CAP_PAN_CODE=l_hash_pan
                    AND CAP_INST_CODE=p_inst_code_in;

                  IF SQL%ROWCOUNT <> 1 THEN
                      L_ERR_MSG := 'Error while updating appl_pan';
                      l_resp_cde := '89';
                      RAISE exp_reject_record;
                   END IF;
                 EXCEPTION
                     WHEN exp_reject_record THEN
                     RAISE;
                     WHEN OTHERS THEN
                      L_ERR_MSG := 'Error while updating appl_pan '|| SUBSTR(SQLERRM, 1, 200);
                      l_resp_cde := '89';
                      RAISE exp_reject_record;
                END;

                 BEGIN

                       sp_log_cardstat_chnge (p_inst_code_in,
                                              l_hash_pan,
                                              l_encr_pan,
                                              l_auth_id,
                                             l_cardstat_tran_code,-- '02',
                                              l_rrn,
                                              L_BUSINESS_DATE,
                                              L_BUSINESS_time,
                                              l_resp_cde,
                                              l_err_msg);

                       IF l_resp_cde <> '00' AND l_err_msg <> 'OK'  THEN
                         RAISE exp_reject_record;
                       END IF;
                    EXCEPTION  WHEN exp_reject_record  THEN
                          RAISE;
                       WHEN OTHERS THEN
                          l_resp_cde := '89';
                          L_ERR_MSG :='Error while logging system initiated card status change '|| SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_record;
                END;
       BEGIN
           SELECT NVL(cpc_renew_replace_option, 'NP'),
                  cpc_profile_code,
                  CPC_RENEW_REPLACE_PRODCODE,
                  CPC_RENEW_REPLACE_CARDTYPE,
                  CPC_DISABLE_REPL_FLAG,
                  NVL(CPC_DISABLE_REPL_EXPRYDAYS,0),
                  NVL(CPC_DISABLE_REPL_MINBAL,0),
                  CPC_DISABLE_REPL_MESSAGE,
				  CPC_ENCRYPT_ENABLE
             INTO l_replacement_option, l_profile_code, l_new_product, l_new_cardtype,
                  l_DISABLE_REPL_FLAG,l_DISABLE_REPL_EXPDAYS,l_DISABLE_REPL_MINBAL,
                  l_disable_repl_message,
				  l_encrypt_enable
             FROM cms_prod_cattype
            WHERE     cpc_inst_code = p_inst_code_in
                  AND cpc_prod_code = l_prod_code
                  AND cpc_card_type = l_prod_cattype;
        EXCEPTION
           WHEN OTHERS
           THEN
              l_err_msg := 'Error while selecting replacement params '|| SUBSTR (SQLERRM, 1, 200);
              l_resp_cde := '89';
              RAISE exp_reject_record;
        END;
              -- Added for Disable replacement config changes beg
            BEGIN
               SELECT CAM_ACCT_BAL
                INTO l_ACCT_BALANCE
                FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO =
                    (SELECT CAP_ACCT_NO
                       FROM CMS_APPL_PAN
                      WHERE CAP_PAN_CODE = l_HASH_PAN AND
                           CAP_INST_CODE = P_INST_CODE_in) AND
                    CAM_INST_CODE = P_INST_CODE_in;
             EXCEPTION
               WHEN OTHERS THEN
                l_ACCT_BALANCE := 0;
                l_LEDGER_BAL   := 0;
             end;

            BEGIN
        SELECT CAP_CARD_STAT
           INTO   l_CAP_CARD_STAT
          FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = L_HASH_PAN AND CAP_INST_CODE = P_INST_CODE_IN;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           L_ERR_MSG  := 'Pan not found in master';
           L_RESP_CDE := '89';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           L_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||SUBSTR(SQLERRM, 1, 200);
           L_RESP_CDE := '89';
           RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
            if L_DISABLE_REPL_FLAG = 'Y' then
              if sysdate between (L_OLDCARD_EXPRY-L_DISABLE_REPL_EXPDAYS) and L_OLDCARD_EXPRY
                 or (NVL(l_ACCT_BALANCE,0) <= L_DISABLE_REPL_MINBAL) then
                l_err_msg := L_disable_repl_message;
                l_resp_cde := '27';
                RAISE EXP_REJECT_RECORD; 
              end if;  
            end if;
        EXCEPTION
          WHEN exp_reject_record   then
            RAISE;
           WHEN OTHERS      THEN
              l_ERR_MSG :=  'Error while selecting replacement param '|| SUBSTR (SQLERRM, 1, 200);
              l_resp_cde := '89';
              RAISE EXP_REJECT_RECORD;
        END;
       -- Added for Disable replacement config changes end
       IF L_replacement_option = 'SP'  and l_CAP_CARD_STAT<>'2' THEN
         --Sn find validitty param
          vmsfunutilities.get_expiry_date(p_inst_code_in,
                                         l_prod_code ,
                                         l_prod_cattype ,
                                         l_profile_code,
                                         p_expiry_date_out,
                                         p_resp_msg_out);

          --Sn Update new expry
           BEGIN
             UPDATE cms_appl_pan
                SET cap_replace_exprydt = p_expiry_date_out,
                        cap_repl_flag =  l_shipment_id
              WHERE cap_inst_code = p_inst_code_IN AND cap_pan_code = L_hash_pan;

             IF SQL%ROWCOUNT <> 1     THEN
                l_err_msg := 'Error while updating appl_pan ';
                l_resp_cde := '89';
                RAISE exp_reject_record;
             END IF;
           EXCEPTION    WHEN exp_reject_record     THEN
                RAISE;
             WHEN OTHERS   THEN
                l_err_msg := 'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
                l_resp_cde := '89';
                RAISE exp_reject_record;
          END;
          --En Update new expry
             p_last4digits_pan_out:= SUBSTR(P_CARD_NO_in, LENGTH(P_CARD_NO_in) - 3, LENGTH(P_CARD_NO_in));
          --Sn Update application status as printer pending
          BEGIN
             UPDATE cms_cardissuance_status
                SET ccs_card_status = '20'
              WHERE ccs_inst_code = p_inst_code_in AND ccs_pan_code = l_hash_pan;

             IF SQL%ROWCOUNT <> 1 THEN
                l_err_msg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
                l_resp_cde := '89';
                RAISE exp_reject_record;
             END IF;
          EXCEPTION  WHEN exp_reject_record  THEN
                RAISE;
             WHEN OTHERS  THEN
                l_err_msg := 'Error while updating Application Card Issuance Status'|| SUBSTR (SQLERRM, 1, 200);
                l_resp_cde := '89';
                RAISE exp_reject_record;
          END;
       --En Update application status as printer pending
     ELSE   -- NP ,NPP

             IF  l_replacement_option='NPP' THEN
                   l_prod_code:=l_new_product;
                   l_prod_cattype:=l_new_cardtype;
              END IF;

          BEGIN
                 SP_ORDER_REISSUEPAN_CMS(P_INST_CODE_in,
                                    P_CARD_NO_in,
                                    l_PROD_CODE,
                                    l_PROD_CATTYPE,
                                    l_NEW_DISPNAME,
                                    P_INST_CODE_in,--P_BANK_CODE,
                                    l_NEW_CARD_NO,
                                    l_ERR_MSG);
                 IF l_ERR_MSG <> 'OK' THEN
                   l_ERR_MSG  := 'From reissue pan generation process-- ' ||l_ERR_MSG;
                   l_RESP_CDE := '89';
                   RAISE EXP_REJECT_RECORD;
                 END IF;
                EXCEPTION WHEN EXP_REJECT_RECORD   THEN
                    RAISE;
                 WHEN OTHERS THEN
                   l_ERR_MSG  := 'From reissue pan generation process-- ' || l_ERR_MSG;
                   l_RESP_CDE := '89';
                   RAISE EXP_REJECT_RECORD;
                END;
           p_last4digits_pan_out:= SUBSTR(l_NEW_CARD_NO, LENGTH(l_NEW_CARD_NO) - 3, LENGTH(l_NEW_CARD_NO));
               BEGIN
                     l_NEW_HASH_PAN := GETHASH(l_NEW_CARD_NO);
                    EXCEPTION   WHEN OTHERS THEN
                        l_RESP_CDE := '89';
                       l_ERR_MSG := 'Error while converting new pan. into hash value ' ||fn_mask(l_NEW_CARD_NO,'X',7,6)||' '||SUBSTR(SQLERRM, 1, 200);
                       RAISE EXP_REJECT_RECORD;
                 END;
               BEGIN
                     SELECT cap_expry_date
                       INTO p_expiry_date_out
                       FROM cms_appl_pan
                      WHERE cap_pan_code = l_new_hash_pan AND cap_inst_code = p_inst_code_in;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_err_msg :=
                           'Error while selecting new expry date' || SUBSTR (SQLERRM, 1, 200);
                        l_resp_cde := '89';
                        RAISE exp_reject_record;
                  END;

                BEGIN
               UPDATE cms_appl_pan
                  SET cap_repl_flag = l_shipment_id,
                      CAP_SERIAL_NUMBER=l_serial_no,                
                      CAP_CARDPACK_ID=l_card_id
                WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_NEW_HASH_PAN;

               IF SQL%ROWCOUNT = 0   THEN
                  l_err_msg :='Problem in updation of replacement flag for pan '|| fn_mask (l_NEW_CARD_NO, 'X', 7, 6);
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION when exp_reject_record then
                      raise;
                    WHEN OTHERS THEN
                  l_err_msg :='Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
            END;

 BEGIN
              INSERT INTO CMS_CARD_EXCPFEE(CCE_INST_CODE,CCE_PAN_CODE,CCE_INS_DATE,cce_ins_user,CCE_LUPD_USER,CCE_LUPD_DATE,CCE_FEE_PLAN,CCE_FLOW_SOURCE,
              CCE_VALID_FROM,CCE_VALID_TO,CCE_PAN_CODE_ENCR,CCE_MBR_NUMB)
              (SELECT  CCE_INST_CODE,GETHASH(l_NEW_CARD_NO),sysdate,cce_ins_user,CCE_LUPD_USER,sysdate,CCE_FEE_PLAN,CCE_FLOW_SOURCE,
              (case when cce_valid_from>=trunc(sysdate) then cce_valid_from else sysdate end)cce_valid_from,
               CCE_VALID_TO,FN_EMAPS_MAIN(l_NEW_CARD_NO),CCE_MBR_NUMB
               FROM CMS_CARD_EXCPFEE WHERE CCE_PAN_CODE=GETHASH(P_CARD_NO_in) AND CCE_INST_CODE=P_INST_CODE_in
               AND ((CCE_VALID_TO IS NOT NULL AND (trunc(sysdate) between cce_valid_from and CCE_VALID_TO))
               OR (CCE_VALID_TO IS NULL AND trunc(sysdate) >= cce_valid_from)  or (cce_valid_from >=trunc(sysdate))));

      EXCEPTION
           WHEN OTHERS THEN
            l_ERR_MSG  := 'Error while attaching fee plan to reissuue card ' ||SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';
            RAISE EXP_REJECT_RECORD;
    END;


   END IF;

IF L_RESP_CDE = '00' THEN

      p_resp_code_out :='00';
      p_resp_messge_out :='OK';
      p_card_expirty_date_out :=to_char(p_expiry_date_out,'MM/YY');
      p_available_balance_out:=TRIM(TO_CHAR(l_ACCT_BALANCE,'999999999999999990.99'));
      p_card_fee_out       :=TRIM(TO_CHAR(l_fee_amt_out,'999999999999999990.99'));

         if l_NEW_CARD_NO is not null then
         BEGIN
           INSERT INTO CMS_HTLST_REISU
            (CHR_INST_CODE,
             CHR_PAN_CODE,
             CHR_MBR_NUMB,
             CHR_NEW_PAN,
             CHR_NEW_MBR,
             CHR_REISU_CAUSE,
             CHR_INS_USER,
             CHR_LUPD_USER,
             CHR_PAN_CODE_ENCR,
             CHR_NEW_PAN_ENCR)
           VALUES
            (P_INST_CODE_in,
             l_HASH_PAN,
             P_MBR_NUMB_IN,
             GETHASH(l_NEW_CARD_NO),
             P_MBR_NUMB_IN,
             'R',
             P_INST_CODE_in,
             P_INST_CODE_in,
             l_ENCR_PAN,
             FN_EMAPS_MAIN(l_NEW_CARD_NO));
         EXCEPTION
           --excp of begin 4
           WHEN OTHERS THEN
            l_ERR_MSG  := 'Error while creating  reissuue record ' ||
                        SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_CARDISSUANCE_STATUS
            (CCS_INST_CODE,
             CCS_PAN_CODE,
             CCS_CARD_STATUS,
             CCS_INS_USER,
             CCS_INS_DATE,
             CCS_PAN_CODE_ENCR,
             CCS_APPL_CODE
             )
           VALUES
            (P_INST_CODE_in,
             GETHASH(l_NEW_CARD_NO),
             '2',
             P_INST_CODE_in,
             SYSDATE,
             FN_EMAPS_MAIN(l_NEW_CARD_NO),
             l_APPL_CODE
             );
         EXCEPTION
           WHEN OTHERS THEN
            l_ERR_MSG  := 'Error while Inserting CCF table ' ||SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';
            RAISE EXP_REJECT_RECORD;
         END;
    end if;
 
     END IF;
	 IF l_encrypt_enable = 'Y' THEN
        l_encr_addr_lineone   := fn_emaps_main(p_addressLine_one_in);
		l_encr_addr_linetwo   := fn_emaps_main(p_addressLine_two_in);
		l_encr_addr_linethree := fn_emaps_main(p_addressLine_three_in);
		l_encr_city           := fn_emaps_main(p_city_in);
		l_encr_mob_one        := fn_emaps_main(p_phone_in);
		l_encr_email          := fn_emaps_main(p_email_in);
		l_encr_zip            := fn_emaps_main(p_postal_code_in);
		l_encr_first_name     := fn_emaps_main(p_first_name_in);
		l_encr_mid_name       := fn_emaps_main(p_middleinitial_in);
		l_encr_last_name      := fn_emaps_main(p_last_name_in);
     ELSE
        l_encr_addr_lineone   := p_addressLine_one_in;
		l_encr_addr_linetwo   := p_addressLine_two_in;
		l_encr_addr_linethree := p_addressLine_three_in;
		l_encr_city           := p_city_in;
		l_encr_mob_one        := p_phone_in;
		l_encr_email          := p_email_in;
		l_encr_zip            := p_postal_code_in;
		l_encr_first_name     := p_first_name_in;
		l_encr_mid_name       := p_middleinitial_in;
		l_encr_last_name      := p_last_name_in;
     END IF;
        BEGIN
        
            UPDATE cms_addr_mast
            SET
                cam_add_one = l_encr_addr_lineone,
                cam_add_two = l_encr_addr_linetwo,
                cam_add_three = l_encr_addr_linethree,
                cam_city_name = l_encr_city,
                cam_state_switch = p_state_in,
                cam_state_code = l_state_code,
                cam_mobl_one = l_encr_mob_one,
                cam_email = l_encr_email,
                cam_pin_code = l_encr_zip,
                cam_cntry_code = l_cntry_code,--p_country_in,
                cam_lupd_date = SYSDATE,
                CAM_ADD_ONE_ENCR = fn_emaps_main(p_addressLine_one_in),
                CAM_ADD_TWO_ENCR = fn_emaps_main(p_addressLine_two_in),
                CAM_CITY_NAME_ENCR = fn_emaps_main(p_city_in),
                CAM_PIN_CODE_ENCR = fn_emaps_main(p_postal_code_in),
                CAM_EMAIL_ENCR = fn_emaps_main(p_email_in)
            WHERE
                cam_cust_code = l_cust_code
              AND
                cam_inst_code = p_inst_code_in;  
                
                 IF SQL%ROWCOUNT = 0   THEN
                  l_err_msg :='No records found in addrss mast';
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
               END IF;
                  EXCEPTION WHEN exp_reject_record THEN
                            raise;
                         when others then
                  l_err_msg :='Error while updating address mast' || SUBSTR (SQLERRM, 1, 200);
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
            END;
           BEGIN
            UPDATE cms_cust_mast
                   SET
                    ccm_first_name = l_encr_first_name,
                    ccm_mid_name = l_encr_mid_name,
                    ccm_last_name = l_encr_last_name,
            --				  CCM_EMAIL_ONE = l_encr_email,
            --                CCM_MOBL_ONE = l_encr_mob_one,
                    ccm_business_name = p_ship_companyname_in,
                    ccm_lupd_date = SYSDATE,
                    CCM_FIRST_NAME_ENCR = fn_emaps_main(p_first_name_in),
                    CCM_LAST_NAME_ENCR = fn_emaps_main(p_last_name_in)
            WHERE
                    ccm_cust_code = l_cust_code
                AND
                    ccm_inst_code = p_inst_code_in;
        
                 IF SQL%ROWCOUNT = 0   THEN
                  l_err_msg :='No records found in cust mast';
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
               END IF;
                  EXCEPTION WHEN exp_reject_record THEN
                            raise;
                          when others then
                  l_err_msg :='Error while updating cust mast' || SUBSTR (SQLERRM, 1, 200);
                  l_resp_cde := '89';
                  RAISE exp_reject_record;
             END;
          begin
		  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(L_TRANS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                   update transactionlog set remark=substr(p_comments_in,1,1000),date_time=L_TRANS_DATE
                    where rrn=l_rrn;
ELSE
				update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991 
				set remark=substr(p_comments_in,1,1000),date_time=L_TRANS_DATE
                    where rrn=l_rrn;
END IF;					
        IF SQL%ROWCOUNT = 0   THEN
                          l_err_msg :='No records found in transactionlog to update';
                          l_resp_cde := '89';
                          RAISE exp_reject_record;
                       END IF;
                          EXCEPTION WHEN exp_reject_record THEN
                                    raise;
                                  when others then
                          l_err_msg :='Error while updating transactionlog' || SUBSTR (SQLERRM, 1, 200);
                          l_resp_cde := '89';
                          RAISE exp_reject_record;
          end;

EXCEPTION
WHEN EXP_REJECT_RECORD THEN
 ROLLBACK TO l_auth_savepoint;

    begin
      SELECT  CAP_PROD_CODE, CAP_CARD_TYPE
           INTO l_PROD_CODE,l_PROD_CATTYPE
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = L_HASH_PAN AND CAP_INST_CODE = P_INST_CODE_IN;
         exception   when others then
          l_err_msg  := 'Problem while selecting data from response master ' ||
                        l_RESP_CDE || SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';

      end;

     BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO
            INTO l_ACCT_BALANCE, l_LEDGER_BAL,
                  l_CAM_TYPE_CODE,l_ACCT_NUMBER
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
                (SELECT CAP_ACCT_NO
                   FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = l_HASH_PAN AND
                       CAP_INST_CODE = P_INST_CODE_in) AND
                CAM_INST_CODE = P_INST_CODE_in;
         EXCEPTION
           WHEN OTHERS THEN
            l_ACCT_BALANCE := 0;
            l_LEDGER_BAL   := 0;
         END;

         BEGIN
           SELECT CMS_ISO_RESPCDE,CMS_ISO_RESPCDE,CMS_RESP_DESC
            INTO l_RESP_CDE,p_resp_code_out,p_resp_messge_out
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE_in AND
                CMS_DELIVERY_CHANNEL = decode(l_DELIVERY_CHANNEL,'13','17',l_DELIVERY_CHANNEL) AND
                CMS_RESPONSE_ID = l_RESP_CDE;

         EXCEPTION
           WHEN OTHERS THEN
            l_err_msg  := 'Problem while selecting data from response master ' ||
                        l_RESP_CDE || SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';

              END;
     BEGIN
           INSERT INTO CMS_TRANSACTION_LOG_DTL
            (CTD_DELIVERY_CHANNEL,
             CTD_TXN_CODE,
             CTD_TXN_TYPE,
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
             CTD_SYSTEM_TRACE_AUDIT_NO,
             CTD_INST_CODE,
             CTD_CUSTOMER_CARD_NO_ENCR,
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (l_delivery_channel,
             null,--P_TXN_CODE,
             null,--V_TXN_TYPE,
             P_MSG_in,
             P_TXN_MODE_in,
             l_delivery_channel,
             l_txn_code,
             l_HASH_PAN,
             null,--P_TXN_AMT,
             P_CURR_CODE_in,
             null,--V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             null,--V_TOTAL_AMT,
             null,--V_CARD_CURR,
             'E',
             L_ERR_MSG,
             l_RRN,
             P_STAN_IN,
             P_INST_CODE_in,
             l_ENCR_PAN,
             l_ACCT_NUMBER);

         EXCEPTION
           WHEN OTHERS THEN
            l_err_msg  := 'Problem while inserting data into transaction log  dtl'||
                        SUBSTR(SQLERRM, 1, 300);
            l_RESP_CDE := '89'; -- Server Declined
           -- ROLLBACK;
           -- RETURN;
         END;

          l_timestamp := systimestamp;

      BEGIN
        INSERT INTO TRANSACTIONLOG
         (MSGTYPE,
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
          RULE_INDICATOR,
          RULEGROUPID,
          MCCODE,
          CURRENCYCODE,
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
          TIPS,
          DECLINE_RULEID,
          ATM_NAME_LOCATION,
          AUTH_ID,
          TRANS_DESC,
          AMOUNT,
          PREAUTHAMOUNT,
          PARTIALAMOUNT,
          MCCODEGROUPID,
          CURRENCYCODEGROUPID,
          TRANSCODEGROUPID,
          RULES,
          PREAUTH_DATE,
          GL_UPD_FLAG,
          SYSTEM_TRACE_AUDIT_NO,
          INSTCODE,
          FEECODE,
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          CARDSTATUS,
          FEE_PLAN,
          CSR_ACHACTIONTAKEN,
          error_msg,
          PROCESSES_FLAG,
          ACCT_TYPE,
          TIME_STAMP,
          remark
          )
        VALUES
         (P_MSG_in,
          l_RRN,
          l_delivery_channel,
          '0',--P_TERM_ID,
          L_TRANS_DATE,
          l_txn_code,
          l_TXN_TYPE,
          P_TXN_MODE_in,
          DECODE(l_RESP_CDE, '00', 'C', 'F'),
          l_RESP_CDE,
          L_BUSINESS_DATE,
          SUBSTR(L_BUSINESS_TIME, 1, 10),
          l_HASH_PAN,
          NULL,
          NULL, --P_topup_acctno    ,
          NULL, --P_topup_accttype,
          null,--P_BANK_CODE,
          null,--TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),
          '',
          '',
          null,--P_MCC_CODE,
          P_CURR_CODE_IN,
          NULL, -- P_add_charge,
          L_PROD_CODE,
          L_PROD_CATTYPE,
          0,
          '',
          '',
          l_AUTH_ID,
          l_TRAN_DESC,--V_NARRATION,
          null,--TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')),
          '0.00',
          '0.00',
          '',
          '',
          '',
          '',
          '',
          null,--V_GL_UPD_FLAG,
          P_STAN_IN,
          P_INST_CODE_in,
          null,--V_FEE_CODE,
          null,--NVL(V_FEE_AMT,0),
          null,--NVL(V_SERVICETAX_AMOUNT,0),
          null,--NVL(V_CESS_AMOUNT,0),
          null,--V_DR_CR_FLAG,
          null,--V_FEE_CRACCT_NO,
          null,--V_FEE_DRACCT_NO,
          null,--V_ST_CALC_FLAG,
          null,--V_CESS_CALC_FLAG,
          null,-- V_ST_CRACCT_NO,
          null,--V_ST_DRACCT_NO,
          null,--V_CESS_CRACCT_NO,
          null,--V_CESS_DRACCT_NO,
          l_ENCR_PAN,
          NULL,
          L_PROXUNUMBER,
          P_RVSL_CODE_in,
          L_ACCT_NUMBER,
          NVL(L_ACCT_BALANCE,0),
          NVL(L_LEDGER_BAL,0),
          l_RESP_CDE,
          L_APPLPAN_CARDSTAT,
          null,--V_FEE_PLAN,
          null,--P_FEE_FLAG,
          L_ERR_MSG,
          'E',
           L_cam_type_code,
           l_timestamp,
          substr(p_comments_in,1,1000)
          );
      EXCEPTION
        WHEN OTHERS THEN
         --ROLLBACK;
         l_RESP_CDE := '89'; -- Server Declione
         L_ERR_MSG  := 'Problem while inserting data into transaction log  ' ||SUBSTR(SQLERRM, 1, 300);
        -- return;
      END;
WHEN OTHERS THEN
 ROLLBACK TO l_auth_savepoint;
 BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO
            INTO l_ACCT_BALANCE, l_LEDGER_BAL,
                  l_CAM_TYPE_CODE,l_ACCT_NUMBER
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
                (SELECT CAP_ACCT_NO
                   FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = l_HASH_PAN AND
                       CAP_INST_CODE = P_INST_CODE_in) AND
                CAM_INST_CODE = P_INST_CODE_in;
         EXCEPTION
           WHEN OTHERS THEN
            l_ACCT_BALANCE := 0;
            l_LEDGER_BAL   := 0;
         END;

        begin
      SELECT  CAP_PROD_CODE, CAP_CARD_TYPE
           INTO l_PROD_CODE,l_PROD_CATTYPE
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = L_HASH_PAN AND CAP_INST_CODE = P_INST_CODE_IN;
         exception   when others then
          l_err_msg  := 'Problem while selecting data from response master ' ||
                        l_RESP_CDE || SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';

      end;
         BEGIN
           SELECT CMS_ISO_RESPCDE,CMS_ISO_RESPCDE,CMS_RESP_DESC
            INTO l_RESP_CDE,p_resp_code_out,p_resp_messge_out
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE_in AND
                CMS_DELIVERY_CHANNEL = decode(l_DELIVERY_CHANNEL,'13','17',l_DELIVERY_CHANNEL) AND
                CMS_RESPONSE_ID = l_RESP_CDE;

         EXCEPTION
           WHEN OTHERS THEN
            l_err_msg  := 'Problem while selecting data from response master ' ||
                        l_RESP_CDE || SUBSTR(SQLERRM, 1, 200);
            l_RESP_CDE := '89';
            --ROLLBACK;
              END;

     BEGIN
           INSERT INTO CMS_TRANSACTION_LOG_DTL
            (CTD_DELIVERY_CHANNEL,
             CTD_TXN_CODE,
             CTD_TXN_TYPE,
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
             CTD_SYSTEM_TRACE_AUDIT_NO,
             CTD_INST_CODE,
             CTD_CUSTOMER_CARD_NO_ENCR,
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (l_delivery_channel,
             null,--P_TXN_CODE,
             null,--V_TXN_TYPE,
             P_MSG_in,
             P_TXN_MODE_in,
             l_delivery_channel,
             l_txn_code,
             l_HASH_PAN,
             null,--P_TXN_AMT,
             P_CURR_CODE_in,
             null,--V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             null,--V_TOTAL_AMT,
             null,--V_CARD_CURR,
             'E',
             L_ERR_MSG,
             l_RRN,
             P_STAN_IN,
             P_INST_CODE_in,
             l_ENCR_PAN,
             l_ACCT_NUMBER);

           --P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            l_err_msg  := 'Problem while inserting data into transaction log  dtl'||
                        SUBSTR(SQLERRM, 1, 300);
            l_RESP_CDE := '89'; -- Server Declined
            --ROLLBACK;
           -- RETURN;
         END;
       l_timestamp := systimestamp;
              BEGIN
                INSERT INTO TRANSACTIONLOG
                 (MSGTYPE,
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
                  RULE_INDICATOR,
                  RULEGROUPID,
                  MCCODE,
                  CURRENCYCODE,
                  ADDCHARGE,
                  PRODUCTID,
                  CATEGORYID,
                  TIPS,
                  DECLINE_RULEID,
                  ATM_NAME_LOCATION,
                  AUTH_ID,
                  TRANS_DESC,
                  AMOUNT,
                  PREAUTHAMOUNT,
                  PARTIALAMOUNT,
                  MCCODEGROUPID,
                  CURRENCYCODEGROUPID,
                  TRANSCODEGROUPID,
                  RULES,
                  PREAUTH_DATE,
                  GL_UPD_FLAG,
                  SYSTEM_TRACE_AUDIT_NO,
                  INSTCODE,
                  FEECODE,
                  TRANFEE_AMT,
                  SERVICETAX_AMT,
                  CESS_AMT,
                  CR_DR_FLAG,
                  TRANFEE_CR_ACCTNO,
                  TRANFEE_DR_ACCTNO,
                  TRAN_ST_CALC_FLAG,
                  TRAN_CESS_CALC_FLAG,
                  TRAN_ST_CR_ACCTNO,
                  TRAN_ST_DR_ACCTNO,
                  TRAN_CESS_CR_ACCTNO,
                  TRAN_CESS_DR_ACCTNO,
                  CUSTOMER_CARD_NO_ENCR,
                  TOPUP_CARD_NO_ENCR,
                  PROXY_NUMBER,
                  REVERSAL_CODE,
                  CUSTOMER_ACCT_NO,
                  ACCT_BALANCE,
                  LEDGER_BALANCE,
                  RESPONSE_ID,
                  CARDSTATUS,
                  FEE_PLAN,
                  CSR_ACHACTIONTAKEN,
                  error_msg,
                  PROCESSES_FLAG,
                  ACCT_TYPE,
                  TIME_STAMP,
                  remark
                  )
                VALUES
                 (P_MSG_in,
                  l_RRN,
                  l_delivery_channel,
                  '0',--P_TERM_ID,
                  L_TRANS_DATE,
                  l_txn_code,
                  l_TXN_TYPE,
                  P_TXN_MODE_in,
                  DECODE(l_RESP_CDE, '00', 'C', 'F'),
                  l_RESP_CDE,
                  L_BUSINESS_DATE,
                  SUBSTR(L_BUSINESS_TIME, 1, 10),
                  l_HASH_PAN,
                  NULL,
                  NULL, --P_topup_acctno    ,
                  NULL, --P_topup_accttype,
                  null,--P_BANK_CODE,
                  null,--TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),
                  '',
                  '',
                  null,--P_MCC_CODE,
                  P_CURR_CODE_IN,
                  NULL, -- P_add_charge,
                  L_PROD_CODE,
                  L_PROD_CATTYPE,
                  0,
                  '',
                  '',
                  l_AUTH_ID,
                  l_TRAN_DESC,--V_NARRATION,
                  null,--TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')),
                  '0.00',
                  '0.00',
                  '',
                  '',
                  '',
                  '',
                  '',
                  null,--V_GL_UPD_FLAG,
                  P_STAN_IN,
                  P_INST_CODE_in,
                  null,--V_FEE_CODE,
                  null,--NVL(V_FEE_AMT,0),
                  null,--NVL(V_SERVICETAX_AMOUNT,0),
                  null,--NVL(V_CESS_AMOUNT,0),
                  null,--V_DR_CR_FLAG,
                  null,--V_FEE_CRACCT_NO,
                  null,--V_FEE_DRACCT_NO,
                  null,--V_ST_CALC_FLAG,
                  null,--V_CESS_CALC_FLAG,
                  null,-- V_ST_CRACCT_NO,
                  null,--V_ST_DRACCT_NO,
                  null,--V_CESS_CRACCT_NO,
                  null,--V_CESS_DRACCT_NO,
                  l_ENCR_PAN,
                  NULL,
                  L_PROXUNUMBER,
                  P_RVSL_CODE_in,
                  L_ACCT_NUMBER,
                  NVL(L_ACCT_BALANCE,0),
                  NVL(L_LEDGER_BAL,0),
                  l_RESP_CDE,
                  L_APPLPAN_CARDSTAT,
                  null,--V_FEE_PLAN,
                  null,--P_FEE_FLAG,
                  L_ERR_MSG,
                  'E',
                   L_cam_type_code,
                   l_timestamp,
                  substr(p_comments_in,1,1000)
                  );
         EXCEPTION
                WHEN OTHERS THEN
                -- ROLLBACK;
                 l_RESP_CDE := '89'; -- Server Declione
                 L_ERR_MSG  := 'Problem while inserting data into transaction log  ' ||SUBSTR(SQLERRM, 1, 300);
                -- return;
        end;
END;
END vmsb2bapiv1;
/
show error;