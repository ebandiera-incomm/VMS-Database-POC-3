create or replace
PROCEDURE        VMSCMS.SP_MOB_CUSTOMER_LOCATOR(
                          P_INST_CODE         IN NUMBER ,
                          P_MSG               in varchar2,
                          P_RRN               IN  VARCHAR2,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN  VARCHAR2,
                          P_TXN_MODE          IN  VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN  VARCHAR2,
                          P_MBR_NUMB          IN  VARCHAR2,
                          P_RVSL_CODE         in  varchar2,
                          P_PAN_CODE   in  varchar2,
                          p_RETURNED_TYPE      IN  number,
                          P_CURR_CODE         in  varchar2,
                 --        P_MOBL_NO           IN  VARCHAR2  ,
                          P_APPL_ID           IN VARCHAR2 ,
                          P_MOBILE_NO            IN VARCHAR2,   
                          P_DEVICE_ID         IN VARCHAR2, 
                          P_RESP_CODE         OUT varchar2 ,
                          P_RESMSG            OUT VARCHAR2,
                          P_AUTH_ID           OUT VARCHAR2,
                          p_RETURN_LOCATOR    OUT  VARCHAR2,
                          p_partner_id_in     IN VARCHAR2 -- Added for FSS-3672
                          )

AS
/*************************************************
     * Created Date     :  12-July-2012
     * Created By       :  Abdul Hameed M.A
     * PURPOSE          :  To retieve customer details
     * Reviewer         :   
     * Reviewed Date    :   
     * Build Number     :   
     
      * Modified By      : Siva Kumar M
     * Modified Date    : 09-Mar-2015
     * Modified for     : review changes
     * Reviewer         : Pankaj S
     * Reviewed Date    : 09-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001
     
     * Modified By      : MageshKumar S
     * Modified Date    : 05-Oct-2015
     * Modified for     : FSS-3672
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOSTCSD_3.2_B0004
	 
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
*************************************************/

V_AUTH_SAVEPOINT        NUMBER DEFAULT 0;
V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CARDSTAT              VARCHAR2(5);
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
V_DR_CR_FLAG            VARCHAR2(2);
V_CAPTURE_DATE          DATE;
V_RESP_CDE           VARCHAR2(5);
V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
 v_cap_cust_code       CMS_APPL_PAN.cap_cust_code%TYPE; 
V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
V_TIME_STAMP   TIMESTAMP;                                   
v_acct_number           cms_acct_mast.cam_acct_no%TYPE;
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
V_ACCT_BALANCE          CMS_ACCT_MAST.CAM_ACCT_BAL%type;
v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
V_ACCT_TYPE             CMS_ACCT_MAST.CAM_TYPE_CODE%type;
v_proxy_number          cms_appl_pan.cap_proxy_number%type;
l_partner_id            cms_product_param.cpp_partner_id%TYPE; --Added for FSS-3672
l_cust_id               cms_cust_mast.ccm_cust_id%TYPE; --Added for FSS-3672

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN

   SAVEPOINT V_AUTH_SAVEPOINT;
   V_TIME_STAMP :=systimestamp;
   V_RESP_CDE := 1;
        
       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         V_RESP_CDE     := '12';
         V_ERRMSG := 'Error while converting hash pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE     := '12';
            V_ERRMSG := 'Error while converting encryption pan  ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

      --Start Generate HashKEY value 
       begin
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    --End Generate HashKEY value


        --Sn find debit and credit flag

    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_DESC
       INTO V_DR_CR_FLAG,  V_TXN_TYPE, V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; --Ineligible Transaction
       V_ERRMSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;


    --En find debit and credit flag

       --Sn Duplicate RRN Check
      /*  BEGIN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;

          IF V_RRN_COUNT    > 0 THEN
            V_RESP_CDE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
        END;*/
       --En Duplicate RRN Check


        --Sn Get the card details
         BEGIN
              select CAP_CARD_STAT,CAP_CUST_CODE,
                     cap_prod_code,cap_card_type,cap_proxy_number  
              into V_CARDSTAT,V_CAP_CUST_CODE,
                   v_prod_code,v_card_type,v_proxy_number
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'Card number not found ';
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
          END;
      --End Get the card details
    
    
    --Sn added for FSS-3672  
       BEGIN

           SELECT CCM_CUST_ID
           into l_cust_id
           from CMS_CUST_MAST 
           where Ccm_CUST_CODE=v_cap_cust_code
           AND CCM_INST_CODE=P_INST_CODE;
           
          EXCEPTION
            when NO_DATA_FOUND then
              V_ERRMSG := 'Invalid Card No';
              V_RESP_CDE := '118';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG  := 'Error from checking cust name' || SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END;

    IF p_partner_id_in IS NOT NULL THEN

      BEGIN
      
      SELECT cpp_partner_id
        INTO l_partner_id
        FROM cms_product_param 
       WHERE cpp_prod_code=v_prod_code;
   
      EXCEPTION          
        WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERRMSG  := 'Error from partner id Verify flag' ||SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END;
     
     END IF;

         IF p_partner_id_in IS NULL OR (p_partner_id_in IS NOT NULL AND l_partner_id = p_partner_id_in) THEN 
         
         if P_RETURNED_TYPE=0 then
         P_RETURN_LOCATOR:=P_PAN_CODE;
         
         ELSIF P_RETURNED_TYPE=1 then         
         P_RETURN_LOCATOR:=V_PROXY_NUMBER;
         
         elsif   P_RETURNED_TYPE=2 then 
         P_RETURN_LOCATOR := l_cust_id;
         
       /*  begin

           SELECT CCM_CUST_ID
           into p_RETURN_LOCATOR
           from CMS_CUST_MAST 
           where Ccm_CUST_CODE=v_cap_cust_code
           AND CCM_INST_CODE=P_INST_CODE;
     --      AND CCM_APPL_ID =P_APPL_ID  ;


          EXCEPTION
            when NO_DATA_FOUND then
              V_ERRMSG := 'Invalid Card No';
              V_RESP_CDE := '118';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG  := 'Error from checking cust name' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END;*/ --The above block moved up for FSS-3672
         END IF;
  ELSE
  P_RETURN_LOCATOR := NULL;
  V_ERRMSG := 'Customer ID and Partner ID combination not valid';
  V_RESP_CDE := '242';
  RAISE EXP_REJECT_RECORD;
        
  END IF;
--En added for FSS-3672  
      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                NULL,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_INST_CODE,
                NULL,
                NULL,
                NULL,
                NULL,
                P_CURR_CODE,
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
                NULL,
                '000',
                P_RVSL_CODE,
                NULL,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        if P_RESP_CODE <> '00' and V_ERRMSG <> 'OK' then
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure

  


     --Sn Updtated transactionlog 

            BEGIN
			
			  --Added for VMS-5739/FSP-991
		       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
			   
			IF (v_Retdate>v_Retperiod)  THEN                                                --Added for VMS-5739/FSP-991
			
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
			ELSE
			  
			  UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                           --Added for VMS-5739/FSP-991
              SET CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
						
			END IF;

             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

   --End Updated transaction log 


     --ST Get responce code from master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO V_RESP_CDE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             V_RESP_CDE := '89';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE := '89'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 200);
        END;
      --En Get responce code fomr master

P_RESP_CODE := V_RESP_CDE;

    P_RESMSG    := V_ERRMSG;
   P_AUTH_ID    := V_AUTH_ID;
--Sn Handle EXP_REJECT_RECORD execption
--<<MAIN EXCEPTION>>
EXCEPTION

WHEN EXP_REJECT_RECORD THEN
ROLLBACK TO V_AUTH_SAVEPOINT;

   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION

        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '89';
     END;
  --En Get responce code fomr master

 
      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (P_PAN_CODE);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;


      IF v_dr_cr_flag IS NULL THEN
        BEGIN
        SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), 
               ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, 
               v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;


  --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                     ERROR_MSG,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     RESPONSE_id,
                     TIME_STAMP, 
                     productid,
                     categoryid,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance,
                     acct_type
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN,
                     V_ERRMSG,
                     SYSDATE,
                     1,
                     V_CARDSTAT, 
                     V_TRANS_DESC ,
                     V_RESP_CDE,
                     V_TIME_STAMP, 
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '89';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
     END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_ADDR_VERIFY_RESPONSE,
                      CTD_MOBILE_NUMBER,
                      CTD_DEVICE_ID,        
              CTD_HASHKEY_ID     
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN,
              '000',
              '',
              '',
               P_MOBILE_NO,   
             P_DEVICE_ID,
             V_HASHKEY_ID 
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          P_RESP_CODE := '89';
          RETURN;
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
P_RESMSG    := V_ERRMSG;

WHEN EXP_AUTH_REJECT_RECORD THEN
    P_RESMSG    := V_ERRMSG;

     BEGIN
	 
	    IF (v_Retdate>v_Retperiod) THEN                                               --Added for VMS-5739/FSP-991
		
              update CMS_TRANSACTION_LOG_DTL
              SET CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
		ELSE
		
		      update VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                   --Added for VMS-5739/FSP-991
              SET CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
		
		
		END IF;

             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
             END IF;
             EXCEPTION
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
            END;

 WHEN OTHERS THEN
     V_RESP_CDE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200);
END; 
/
SHOW ERROR