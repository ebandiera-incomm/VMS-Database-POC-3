SET DEFINE OFF;
create or replace PROCEDURE VMSCMS.SP_IVR_UPDATE_ZIPCODE(P_INSTCODE     IN NUMBER,
                                          P_CARDNUM          IN VARCHAR2,
                                          P_RRN              IN VARCHAR2,
                                          P_TRANDATE         IN VARCHAR2,
                                          P_TRANTIME         IN VARCHAR2,
                                          P_TXN_CODE         IN VARCHAR2,
                                          P_DELIVERY_CHANNEL IN VARCHAR2,
                                          P_ANI              IN VARCHAR2,
                                          P_DNI              IN VARCHAR2,
                                          P_ZIPCODE          IN VARCHAR2,
                                          P_MSG_TYPE         IN VARCHAR2,--Added for defect 9787
                                          P_TXN_MODE         IN VARCHAR2,--Added for defect 9787
                                          P_IP_ADDRESS_IN    IN VARCHAR2,
                                          P_MOBILENUMBER_IN  IN VARCHAR2,
                                          P_EMAILID_IN       IN VARCHAR2,
                                          P_RESP_CODE        OUT VARCHAR2,
                                          P_ERRMSG           OUT VARCHAR2) AS

  /*************************************************
     * Created Date     :  17-Dec-2012
     * Created By       :  Saravanakumar
     * PURPOSE          :  For updating zipcode
     * Modified reason  : Modified for defect 9781 and 9787
     * Modified by      : Saravanakumar
     * Modified date    : 04-Jan-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  04-Jan-2013
     * Release Number   :  CMS3.5.1_RI0023_B0008
     
     * Modified By      : Pankaj S.
     * Modified Date    : 10-May-2013
     * Modified For     : MVHOST-346
     * Modified Reason  : Call the fee calculation procedure SP_AUTHORIZE_TXN_CMS_AUTH 
                          and comment the card status check 
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 10-May-2013
     * Build Number     : RI0024.1_B0021
     
       * Modified By      : Sai Prasad
     * Modified Date    : 11-Sep-2013
     * Modified For     : Mantis ID: 0012275 (JIRA FSS-1144)
     * Modified Reason  : ANI & DNI is not logged in transactionlog table.
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 11-Sep-2013
     * Build Number     : RI0024.4_B0010
     
     * Modified By      : Pankaj S.
     * Modified Date    : 19-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0003
     
     * Modified by      :Spankaj
     * Modified Date    : 07-Sep-15
     * Modified For     : FSS-2321
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOSTCSD3.2     
     
     * Modified by      : MageshKumar
     * Modified Date    : 05-MAY-17
     * Modified For     : FSS-5103
     * Reviewer         : Saravanankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.05_B0001
     
       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
       
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
    
    
       * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
	  
	  
	  	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01
    
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

  *************************************************/

    V_CAP_CARD_STAT       CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
    V_CURRCODE            cms_bin_param.cbp_param_value%type;
    V_RESPCODE            VARCHAR2(5);
    V_TXN_TYPE            CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
    
    V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
    V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
     
    V_TRAN_DATE           DATE;
    V_ACCT_BALANCE        CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
    V_LEDGER_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
    V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
    V_TRANS_DESC          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
    V_ADDR_CODE           CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
    V_EXPRY_DATE          CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
    V_PROD_CODE           CMS_APPL_PAN.CAP_PROD_CODE%TYPE;--Added for defect 9787
    V_PROD_CATTYPE        CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;--Added for defect 9787
     
    --Sn Added by Pankaj S. for MVHOST-346
    v_authid               transactionlog.auth_id%TYPE;
    v_business_date        DATE;
    
    --En Added by Pankaj S. for MVHOST-346
   --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)    
   v_acct_type             cms_acct_mast.cam_type_code%TYPE;  
   v_dr_cr_flag            cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_cap_cust_code         cms_appl_pan.cap_cust_code%TYPE;  --Added for FSS-2321
   V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
   V_PROFILE_CODE          CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   v_zip_code              cms_addr_mast.cam_pin_code%type;
   v_mob_one               cms_addr_mast.CAM_MOBL_ONE%type;
   v_email_id              cms_addr_mast.cam_email%type;
   
   EXP_MAIN_REJECT_RECORD   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
    P_ERRMSG   := 'OK';
    V_RESPCODE := '1';

    --SN CREATE HASH PAN
    BEGIN
        V_HASH_PAN := GETHASH(P_CARDNUM);
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '12';
        P_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
        V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '12';
        P_ERRMSG   := 'Error while converting pan ' ||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN create encr pan

    --Sn find debit and credit flag
    BEGIN
        SELECT  TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
                CTM_TRAN_DESC,  
                ctm_credit_debit_flag  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
        INTO    V_TXN_TYPE, 
                V_TRANS_DESC ,
                v_dr_cr_flag  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
        CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
        CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE || ' and delivery channel ' || P_DELIVERY_CHANNEL;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG := 'Error while selecting CMS_TRANSACTION_MAST' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En find debit and credit flag

    --Sn Transaction Date Check
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
    EXCEPTION
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Problem while converting transaction date ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Transaction Date Check

    --Sn Transaction Time Check
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' || SUBSTR(TRIM(P_TRANTIME), 1, 10),'yyyymmdd hh24:mi:ss');
    EXCEPTION
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Transaction Time Check


   --Sn find card detail
    BEGIN
        SELECT  CAP_CARD_STAT,
                CAP_ACCT_NO,
                CAP_BILL_ADDR,
                CAP_EXPRY_DATE,--Added for defect 9787
                CAP_PROD_CODE,--Added for defect 9787
                CAP_CARD_TYPE,--Added for defect 9787
                cap_cust_code    --Added for FSS-2321
        INTO    V_CAP_CARD_STAT,
                V_ACCT_NUMBER,
                V_ADDR_CODE,
                V_EXPRY_DATE,--Added for defect 9787
                V_PROD_CODE,--Added for defect 9787
                V_PROD_CATTYPE,--Added for defect 9787
                v_cap_cust_code   --Added for FSS-2321
       FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '16'; 
            P_ERRMSG   := 'Card number not found ' || V_HASH_PAN;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Problem while selecting card detail' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En find card detail

       --Sn check if Encrypt Enabled AND PROFILE FOR PRODUCT
    BEGIN
       SELECT  CPC_ENCRYPT_ENABLE,CPC_PROFILE_CODE
         INTO  V_ENCRYPT_ENABLE,V_PROFILE_CODE
         FROM  CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INSTCODE 
          AND CPC_PROD_CODE = V_PROD_CODE
          AND CPC_CARD_TYPE = V_PROD_CATTYPE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '16';
            P_ERRMSG   := 'Invalid Prod Code Card Type ' || V_PROD_CODE || ' ' || V_PROD_CATTYPE;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Problem while selecting product category details' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En find card detail


    BEGIN
        
             SELECT TRIM (cbp_param_value) 
	             INTO V_CURRCODE 
	             FROM cms_bin_param 
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code = V_PROFILE_CODE;
	

        IF V_CURRCODE IS NULL THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Base currency cannot be null ';
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Base currency is not defined for the bin profile ';
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Error while selecting base currency for bin ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;


   --Sn Authorize procedure call added by Pankaj S. on 10_May_2013 for MVHOST-346 
     BEGIN
         
         sp_authorize_txn_cms_auth (p_instcode,
                                    p_msg_type,
                                    p_rrn,
                                    p_delivery_channel,
                                    0,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    p_cardnum,
                                    NULL,
                                    NULL,--p_amount,
                                    NULL,--p_merchant_name,
                                    NULL,--p_merchant_city,
                                    NULL,
                                    v_currcode,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,--p_stan, 
                                    '000',
                                    '0',   
                                    NULL, --v_tran_amt,
                                    v_authid,
                                    v_respcode,
                                    p_errmsg,
                                    v_business_date
                                   );

         IF v_respcode <> '00' AND p_errmsg <> 'OK'
         THEN
          p_errmsg := 'Error from auth process' || p_errmsg;
            RAISE exp_auth_reject_record;
          END IF; 
                  
         v_respcode := '1';
        
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '12';
            p_errmsg :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Authorize procedure call added by Pankaj S. on 10_May_2013 for MVHOST-346
      
    --Sn Added for FSS-2321
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_channel, p_txn_code, v_cap_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          v_respcode := '21';
          p_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;   
   --En Added for FSS-2321



    --Sn updating zipcode
    if v_encrypt_enable='Y' then
       v_zip_code:=fn_emaps_main(P_ZIPCODE);
       v_email_id:=fn_emaps_main(P_EMAILID_IN);
       v_mob_one:=fn_emaps_main(P_MOBILENUMBER_IN);
    else
       v_zip_code:=P_ZIPCODE;
       v_email_id:=P_EMAILID_IN;
       v_mob_one:=P_MOBILENUMBER_IN;
    end if;
    BEGIN
        UPDATE CMS_ADDR_MAST 
           SET CAM_PIN_CODE=NVL(v_zip_code,CAM_PIN_CODE),
               CAM_EMAIL = NVL(v_email_id,CAM_EMAIL),
               CAM_MOBL_ONE = NVL(v_mob_one,CAM_MOBL_ONE),
               CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_ZIPCODE),CAM_PIN_CODE_ENCR),
               CAM_EMAIL_ENCR = NVL(fn_emaps_main(P_EMAILID_IN),CAM_EMAIL_ENCR)
         WHERE CAM_INST_CODE=P_INSTCODE
           AND CAM_ADDR_CODE=V_ADDR_CODE;

        IF SQL%ROWCOUNT =0 THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Zipcode is not updated properly' ;
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Error while updating CMS_ADDR_MAST' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En updating zipcode

     BEGIN
         SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INSTCODE AND
        CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
        CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG    := 'Problem while selecting data from response master ' ||
            V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89';
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
      --sn Added for mantis id 0012275(FSS-1144)
     BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET 
             ANI=P_ANI, 
             DNI=P_DNI,
             IPADDRESS=P_IP_ADDRESS_IN
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
ELSE
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET 
             ANI=P_ANI, 
             DNI=P_DNI,
             IPADDRESS=P_IP_ADDRESS_IN
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
  
END IF;

      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transactionlog is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
   
   BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
        UPDATE CMS_TRANSACTION_LOG_DTL
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER_IN,
             CTD_EMAIL=P_EMAILID_IN
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = p_delivery_channel
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
ELSE
     UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST--Added for VMS-5733/FSP-991
         SET 
             CTD_MOBILE_NUMBER=P_MOBILENUMBER_IN,
             CTD_EMAIL=P_EMAILID_IN
       WHERE CTD_RRN = p_rrn
         AND CTD_DELIVERY_CHANNEL = p_delivery_channel
         AND CTD_TXN_CODE = p_txn_code
         AND CTD_BUSINESS_DATE = p_trandate
         AND CTD_BUSINESS_TIME = P_TRANTIME
         AND CTD_CUSTOMER_CARD_NO = v_hash_pan
         AND CTD_INST_CODE = P_INSTCODE;
END IF;

      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transaction_log_dtl is not updated ';
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
       --en Added for mantis id 0012275(FSS-1144)
 
EXCEPTION
   --Sn Added by Pankaj S. on 10_May_2013 for MVHOST-346
    WHEN exp_auth_reject_record
   THEN
      p_resp_code := v_respcode;      
    WHEN EXP_MAIN_REJECT_RECORD THEN
    
      ROLLBACK;  --added by Pankaj S. on 10_May_2013 for MVHOST-346
      
      --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
           SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
             INTO v_prod_code, v_prod_cattype, v_cap_card_stat, v_acct_number
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_cardnum);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

      IF v_dr_cr_flag IS NULL THEN
        BEGIN
          SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
                 ctm_credit_debit_flag
            INTO v_txn_type, v_trans_desc,
                 v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_instcode; 
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                   cam_type_code  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  v_acct_type  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =v_acct_number
  
            AND CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BAL   := 0;
        END;


        --Sn select response code and insert record into txn log dtl
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;
        
      

        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        RESPONSE_ID,
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        acct_type,
                        error_msg,
                        cr_dr_flag,
                        time_stamp,
                        IPADDRESS
                        --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        )
            VALUES
                        ('0200',
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        0,
                        P_TXN_CODE,
                        V_TXN_TYPE,
                        0,
                        DECODE(P_RESP_CODE, '00', 'C', 'F'),
                        P_RESP_CODE,
                        P_TRANDATE,
                        SUBSTR(P_TRANTIME, 1, 10),
                        V_HASH_PAN,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        V_CURRCODE,
                        NULL,
                        v_prod_code,--SUBSTR(P_CARDNUM, 1, 4),  --Modified by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        v_prod_cattype, --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        0,
                        NULL,
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        V_ACCT_BALANCE,
                        V_LEDGER_BAL,
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        V_CAP_CARD_STAT, 
                        V_TRANS_DESC,
                        --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        v_acct_type,
                        p_errmsg,
                        v_dr_cr_flag,
                        systimestamp,
                        P_IP_ADDRESS_IN
                        --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;

        BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL
                            (CTD_DELIVERY_CHANNEL,
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
                            CTD_TXN_TYPE)
            VALUES
                            (P_DELIVERY_CHANNEL,
                            P_TXN_CODE,
                            '0200',
                            0,
                            P_TRANDATE,
                            P_TRANTIME,
                            V_HASH_PAN,
                            0,
                            V_CURRCODE,
                            0,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            'E',
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;

    WHEN OTHERS THEN
        ROLLBACK;  --added by Pankaj S. on 10_May_2013 for MVHOST-346
        
        --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
           SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
             INTO v_prod_code, v_prod_cattype, v_cap_card_stat, v_acct_number
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode AND cap_pan_code = gethash (p_cardnum);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
          SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc,
                 ctm_credit_debit_flag
            INTO v_txn_type, v_trans_desc,
                 v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_instcode; 
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                    cam_type_code  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  v_acct_type  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =v_acct_number AND
            CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BAL   := 0;
        END;

        --Sn select response code and insert record into txn log dtl
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;

      
      
        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        RESPONSE_ID,
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        acct_type,
                        error_msg,
                        cr_dr_flag,
                        time_stamp,
                        IPADDRESS
                        --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                          )
            VALUES
                        ('0200',
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        0,
                        P_TXN_CODE,
                        V_TXN_TYPE,
                        0,
                        DECODE(P_RESP_CODE, '00', 'C', 'F'),
                        P_RESP_CODE,
                        P_TRANDATE,
                        SUBSTR(P_TRANTIME, 1, 10),
                        V_HASH_PAN,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        V_CURRCODE,
                        NULL,
                        v_prod_code,--SUBSTR(P_CARDNUM, 1, 4),  --Modified by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        v_prod_cattype, --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        0,
                        NULL,
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        '0.00',  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        V_ACCT_BALANCE,
                        V_LEDGER_BAL,
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        V_CAP_CARD_STAT, 
                        V_TRANS_DESC,
                        --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
                        v_acct_type,
                        p_errmsg,
                        v_dr_cr_flag,
                        systimestamp,
                        P_IP_ADDRESS_IN
                        --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160) 
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
        END;

        BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL
                            (CTD_DELIVERY_CHANNEL,
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
                            CTD_TXN_TYPE)
            VALUES
                            (P_DELIVERY_CHANNEL,
                            P_TXN_CODE,
                            '0200',
                            0,
                            P_TRANDATE,
                            P_TRANTIME,
                            V_HASH_PAN,
                            0,
                            V_CURRCODE,
                            0,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            'E',
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;
END;
 
/
show error 