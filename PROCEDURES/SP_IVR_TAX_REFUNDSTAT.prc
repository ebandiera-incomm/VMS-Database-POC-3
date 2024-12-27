create or replace Procedure VMSCMS.Sp_Ivr_Tax_Refundstat(
                              P_Inst_Code        IN Number ,
                              P_Msg_Type         IN Varchar2,
                              P_Rrn              IN Varchar2,
                              P_Delivery_Channel In Varchar2,
                              P_TERM_ID          In VARCHAR2,
                              P_Txn_Code         IN Varchar2,
                              P_Txn_Mode         IN VARCHAR2,
                              P_Tran_Date        IN Varchar2,
                              P_Tran_Time        IN VARCHAR2,
                              P_Pan_Code         IN Number,
                              P_BANK_CODE        IN VARCHAR2,
                              P_CURR_CODE        IN VARCHAR2,
                              P_Ani              IN Varchar2,
                              P_Dni              In Varchar2,
                              P_Resp_Code        Out Varchar2 ,
                              P_Resp_Msg         Out Varchar2,
                              P_Fast50_Amt       Out Varchar2,
                              P_Fast50_Date      Out Varchar2,
                              P_Fstax_Amt        Out Varchar2,
                              P_Fstax_Date       Out Varchar2)
As 
/*************************************************
       * Created Date     : 26-Sep-13
       * Created By       : Anil Kumar
       * Created For      : JH-14
       * build Number     : RI0024.5_B0001 

       * Modified Date    : 16-Dec-2013
       * Modified By      : Sagar More
       * Modified for     : Defect ID 13160
       * Modified reason  : To log below details in transactinlog if applicable
                            Acct_type
       * Reviewer         : Dhiraj
       * Reviewed Date    : 16-Dec-2013
       * Release Number   : RI0024.7_B0001       
   
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991    
       
*************************************************/
V_TRAN_DATE             DATE;
V_AUTH_SAVEPOINT        NUMBER DEFAULT 0;
V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_Encr_Pan_From         Cms_Appl_Pan.Cap_Pan_Code_Encr%Type;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_CAPTURE_DATE          DATE;
V_TXN_AMT               NUMBER;
V_Acct_Number           Number;
V_Acct_Balance          Number;
V_Ledger_Balance        Number;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_DR_CR_FLAG            VARCHAR2(2);
V_OUTPUT_TYPE           VARCHAR2(2);
V_TRAN_TYPE             VARCHAR2(2);
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
V_CARDSTAT              NUMBER(5); 
V_PROD_CODE             CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
V_CARD_TYPE             CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
Exp_Reject_Record       Exception;
V_Hashkey_Id            Cms_Transaction_Log_Dtl.Ctd_Hashkey_Id%Type; 
V_Time_Stamp            Timestamp;
V_Fast50_Date           varchar2(14);
V_Fast50_Amt            varchar2(14);
V_Fstax_Date            varchar2(14);
V_Fstax_Amt             Varchar2(14);
V_Fast_Available        Boolean Default True;
V_Fs_Available          Boolean Default True;

v_acct_type cms_acct_mast.cam_type_code%type; -- Added for 13160
v_resp_id  cms_response_mast.CMS_RESPONSE_ID%type; -- Added for 13160
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991

BEGIN
   V_TXN_TYPE := '1';
   SAVEPOINT V_AUTH_SAVEPOINT;
    V_Time_Stamp :=Systimestamp;
    
      --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE     := '12';
            V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        End;
      --En 
      
    --Start Generate HashKEY value 
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    --End Generate HashKEY value 
      
      --Sn find debit and credit flag
      BEGIN
          SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
          INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          P_RESP_CODE := '12'; --Ineligible Transaction
          V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
        RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '21'; --Ineligible Transaction
          V_ERRMSG  := 'Error while selecting transaction details';
        Raise Exp_Reject_Record;
      END;
      --En find debit and credit flag

      --Sn Duplicate RRN Check
        BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
   ELSE
     SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
   END IF;

          IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
        END;
       --En Duplicate RRN Check

      --Sn Get Tran date
        BEGIN
          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                  'yyyymmdd hh24:mi:ss');
          EXCEPTION
            WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
      --En Get Tran date

      --Sn Get the card details
        BEGIN
            SELECT CAP_CARD_STAT,CAP_ACCT_NO,cap_prod_code,cap_card_type     
              INTO V_CARDSTAT, V_ACCT_NUMBER,V_PROD_CODE,V_CARD_TYPE   
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'Card number not found ' || P_PAN_CODE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;
      --End Get the card details

      --Sn call to authorize procedure
       BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG_TYPE,
                P_RRN,
                P_DELIVERY_CHANNEL,
                P_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                null,
                NULL,
                NULL,
                null,
                P_CURR_CODE,
                NULL,
                NULL,
                NULL,
                V_ACCT_NUMBER,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                null,
                null,
                '000',
                '00',
                null,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);

       If P_Resp_Code <> '00' And V_Errmsg <> 'OK' Then
        P_RESP_MSG:= 'Error from auth process' || V_ERRMSG;
        RAISE EXP_AUTH_REJECT_RECORD;
        End If;
       EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE EXP_AUTH_REJECT_RECORD;
        When Others Then
         P_Resp_Code := '21';
         V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      End;
     
     Begin
        Select to_date(Business_Date,'YYYYMMDD'), Amount into V_Fast50_Date,V_Fast50_amt From (
          SELECT business_date, amount
            FROM  VMSCMS.TRANSACTIONLOG_VW  WHERE 
            CR_DR_FLAG ='CR' and response_code = '00' and   NVL(TRAN_REVERSE_FLAG,'N') = 'N' 
            and ((DELIVERY_CHANNEL ='04' and TXN_CODE in ('68', '80', '82', '85', '88') 
            and exists (Select * from
            VMSCMS.CMS_TRANSACTION_LOG_DTL_VW where ctd_hashkey_id =
            Gethash (Delivery_Channel||Txn_Code||Fn_Dmaps_Main(Customer_Card_No_Encr)||Rrn||To_Char(Time_Stamp,'YYYYMMDDHH24MISSFF5'))
            And Ctd_Reason_Code Is Not Null And Substr(Ctd_Reason_Code,1,1) = 'F')))
            --Or ((Delivery_Channel ='11' And Txn_Code In ('22', '32')) And Ach_Exception_Queue_Flag ='FD'))
            And Customer_Card_No = V_HASH_PAN
        Order By Add_Ins_Date Desc) Where Rownum = 1;
        Exception
          When No_Data_Found Then
            V_Fast_Available := false;
          WHEN OTHERS THEN
            P_Resp_Code := '69'; ---ISO MESSAGE FOR DATABASE ERROR
            V_Errmsg  := 'Problem while selecting data from log tables ' || Substr(Sqlerrm, 1, 200);
            Raise Exp_Reject_Record;
     End;
     
     Begin
        Select to_date(Business_Date,'YYYYMMDD'), Amount into v_fstax_date,v_fstax_amt From (
          SELECT business_date, amount
            FROM  VMSCMS.TRANSACTIONLOG_VW WHERE 
            CR_DR_FLAG ='CR' and response_code = '00' and   NVL(TRAN_REVERSE_FLAG,'N') = 'N'
            and ((DELIVERY_CHANNEL ='04' and TXN_CODE in ('68', '80', '82', '85', '88') 
            and exists (Select * from
            VMSCMS.CMS_TRANSACTION_LOG_DTL_VW where ctd_hashkey_id =
            Gethash (Delivery_Channel||Txn_Code||Fn_Dmaps_Main(Customer_Card_No_Encr)||Rrn||To_Char(Time_Stamp,'YYYYMMDDHH24MISSFF5'))
            And Ctd_Reason_Code Is Not Null And Substr(Ctd_Reason_Code,1,1) in ('T','S')))
            or  ((Delivery_Channel ='11' And Txn_Code In ('22', '32')) And Ach_Exception_Queue_Flag ='FD'))
            And Customer_Card_No = V_HASH_PAN
        Order By Add_Ins_Date Desc) Where Rownum = 1;
        Exception
          When No_Data_Found Then
            V_Fs_Available := false;
          WHEN OTHERS THEN
            P_Resp_Code := '69'; ---ISO MESSAGE FOR DATABASE ERROR
            V_Errmsg  := 'Problem while selecting data from log tables ' || Substr(Sqlerrm, 1, 200);
            Raise Exp_Reject_Record;
     End;
   
      
    P_Resp_Code := '00';
    if(V_Fast_Available or V_Fs_Available) then
      P_Resp_Msg := 'POSTED';
    Else
      P_Resp_Msg := 'NOT POSTED';
    End If;
    P_Fast50_Date := V_Fast50_Date;
    P_Fast50_Amt := V_Fast50_Amt;
    P_Fstax_Date :=V_Fstax_Date;
    P_Fstax_Amt :=V_Fstax_Amt;
    
    BEGIN

IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE TRANSACTIONLOG
        SET  ANI = P_ANI,  DNI = P_DNI                                                           
        WHERE RRN=P_RRN AND BUSINESS_DATE=P_TRAN_DATE
        AND BUSINESS_TIME=P_TRAN_TIME
        AND DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
        AND TXN_CODE=P_TXN_CODE 
        AND MSGTYPE=P_MSG_TYPE
        AND INSTCODE=P_INST_CODE;
ELSE
     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET  ANI = P_ANI,  DNI = P_DNI                                                           
        WHERE RRN=P_RRN AND BUSINESS_DATE=P_TRAN_DATE
        AND BUSINESS_TIME=P_TRAN_TIME
        AND DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
        AND TXN_CODE=P_TXN_CODE 
        AND MSGTYPE=P_MSG_TYPE
        AND INSTCODE=P_INST_CODE;
 END IF;
              
      IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG  := 'ERROR WHILE UPDATING Trasnsaction log ';
        P_RESP_CODE := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;    
      EXCEPTION
        WHEN EXP_REJECT_RECORD THEN        
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '21';
          V_ERRMSG  := 'Problem on updated Trasnsaction log  ' ||
          SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
    END; 

   BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CODE
     FROM CMS_RESPONSE_MAST
     WHERE CMS_INST_CODE      = P_INST_CODE
     AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
     AND CMS_RESPONSE_ID      = P_RESP_CODE;

    Exception
     WHEN NO_DATA_FOUND THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
      V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 200);
  End;       
       
      
Exception
     --<<Main Exception>>
When Exp_Auth_Reject_Record Then
    --ROLLBACK;
    P_RESP_MSG := V_ERRMSG;
    P_RESP_CODE := P_RESP_CODE;
    
    BEGIN

IF (v_Retdate>v_Retperiod)
    THEN
      Update Transactionlog
       SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         And Delivery_Channel = P_Delivery_Channel
         And Txn_Code = P_Txn_Code
         And Business_Date = P_Tran_Date
         AND business_time = P_TRAN_TIME
         AND msgtype = P_MSG_TYPE
         And Customer_Card_No = V_Hash_Pan
         AND instcode = P_INST_CODE;
ELSE
         Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         And Delivery_Channel = P_Delivery_Channel
         And Txn_Code = P_Txn_Code
         And Business_Date = P_Tran_Date
         AND business_time = P_TRAN_TIME
         AND msgtype = P_MSG_TYPE
         And Customer_Card_No = V_Hash_Pan
         AND instcode = P_INST_CODE;
END IF;
      
      IF SQL%ROWCOUNT = 0
      THEN
         P_Resp_Code := '21';
         V_ERRMSG := 'transactionlog is not updated ';
         RAISE EXP_REJECT_RECORD;
      END IF;
      
    EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE ;
      WHEN OTHERS
      THEN
         p_resp_code := '20';
         V_ERRMSG :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         Raise EXP_REJECT_RECORD;
    END;
   
When Exp_Reject_Record Then
  Rollback ;--TO V_AUTH_SAVEPOINT;
  P_Resp_Msg := V_Errmsg; 
 
    Begin
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code
            INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            Where Cap_Pan_Code = V_Hash_Pan And
            Cap_Inst_Code = P_Inst_Code) And
            CAM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_Ledger_Balance   := 0;
    END;
    
    v_resp_id := P_Resp_Code; -- Added for 13160
    
   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
  --En Get responce code fomr master
  
     --SN added for 13160
     
   if V_DR_CR_FLAG is null
   then  
  
      BEGIN
      
          SELECT CTM_CREDIT_DEBIT_FLAG,
                 CTM_TRAN_DESC
          INTO   V_DR_CR_FLAG,  
                 V_TRANS_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE 
          AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
          AND CTM_INST_CODE = P_INST_CODE;
           
      EXCEPTION
      WHEN  OTHERS THEN
            null;
      END;
   end if; 
   
   if V_PROD_CODE is null
   then
   
      BEGIN
            SELECT CAP_CARD_STAT,CAP_ACCT_NO,cap_prod_code,cap_card_type     
              INTO V_CARDSTAT, V_ACCT_NUMBER,V_PROD_CODE,V_CARD_TYPE   
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN ;
      EXCEPTION
      WHEN OTHERS THEN
            null;
      END;
    
   end if;   
   
   
   v_time_stamp :=systimestamp;
      
   --EN added for 13160    

  --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(
                     MSGTYPE,
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
                     Customer_Acct_No,
                     Acct_Balance,
                     LEDGER_BALANCE,
                     ERROR_MSG,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     ANI,
                     Dni,
                     Currencycode,
                     Productid,
                     Categoryid,
                     Cr_Dr_Flag,
                     TIME_STAMP,
                     acct_type,              --Added for 13160
                     response_id              --Added for 13160
                     )
              VALUES(P_MSG_TYPE,
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
                     V_ENCR_PAN_FROM,
                     --V_SPND_ACCT_NO,
                      V_Acct_Number ,
                      nvl(V_Acct_Balance,0),    --NVL Added for 13160
                      nvl(V_Ledger_Balance,0),  --NVL Added for 13160
                     V_ERRMSG,
                     SYSDATE,
                     1,
                     V_CARDSTAT, 
                     V_TRANS_DESC,
                     P_ANI,
                     P_Dni,
                     P_Curr_Code,
                     V_Prod_Code,
                     V_Card_Type,
                     V_DR_CR_FLAG,
                     V_TIME_STAMP,
                     v_acct_type,                --Added for 13160
                     v_resp_id                   -- Added for 13160
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '12';
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
              Ctd_Cust_Acct_Number,
              Ctd_Addr_Verify_Response,
              Ctd_Txn_Curr,
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
              V_Encr_Pan_From,
              P_Msg_Type,
              '',
              V_ACCT_NUMBER,
              '',
              P_CURR_CODE,
              V_HASHKEY_ID
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
        END;

WHEN OTHERS THEN
        Rollback;  
        v_resp_id := '21'; -- Added on 
        
        Begin
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code
            INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            Where Cap_Pan_Code = V_Hash_Pan And
            Cap_Inst_Code = P_Inst_Code) And
            CAM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_Ledger_Balance   := 0;
        END;
    --Sn Get responce code from master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
   --En Get responce code fomr master
   
--SN added for 13160
     
   if V_DR_CR_FLAG is null
   then  
  
      BEGIN
      
          SELECT CTM_CREDIT_DEBIT_FLAG,
                 CTM_TRAN_DESC
          INTO   V_DR_CR_FLAG,  
                 V_TRANS_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE 
          AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
          AND CTM_INST_CODE = P_INST_CODE;
           
      EXCEPTION
      WHEN  OTHERS THEN
            null;
      END;
   end if; 
   
   if V_PROD_CODE is null
   then
   
      BEGIN
            SELECT CAP_CARD_STAT,CAP_ACCT_NO,cap_prod_code,cap_card_type     
              INTO V_CARDSTAT, V_ACCT_NUMBER,V_PROD_CODE,V_CARD_TYPE   
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN ;
      EXCEPTION
      WHEN OTHERS THEN
            null;
      END;
    
   end if;   
   
   
   v_time_stamp :=systimestamp;
      
   --EN added for 13160     

   --Sn Inserting data in transactionlog
      BEGIN
          Insert Into Transactionlog(
                       MSGTYPE,
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
                       Customer_Acct_No,
                       Acct_Balance,
                       LEDGER_BALANCE,
                       ERROR_MSG,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       Trans_Desc,
                       Ani,
                       Dni,
                       Currencycode,
                       Productid,
                       Categoryid,
                       Cr_Dr_Flag,
                       TIME_STAMP,
                       acct_type,              --Added for 13160
                       response_id             --Added for 13160
                       )
                VALUES(P_MSG_TYPE,
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
                       V_ENCR_PAN_FROM,
                      -- V_ACCT_NUMBER,
                       V_Acct_Number ,
                       nvl(V_Acct_Balance,0),       --NVL added for 13160
                       nvl(V_Ledger_Balance,0),      --NVL added for 13160
                       V_ERRMSG,
                       SYSDATE,
                       1,
                       V_CARDSTAT,
                       V_Trans_Desc,
                       P_Ani,
                       P_Dni,
                       P_Curr_Code,
                       V_Prod_Code,
                       V_Card_Type,
                       V_DR_CR_FLAG,
                       V_TIME_STAMP,
                       v_acct_type,                --Added for 13160
                       v_resp_id                   --Added for 13160          
                       );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
            RAISE EXP_REJECT_RECORD;
         END;
     --En Inserting data in transactionlog

     --Sn Inserting data in transactionlog dtl
       BEGIN
          INSERT  INTO CMS_TRANSACTION_LOG_DTL
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
              Ctd_Cust_Acct_Number,
              Ctd_Addr_Verify_Response,
              Ctd_Txn_Curr,
              Ctd_Hashkey_Id
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
              V_ENCR_PAN_FROM,
              P_Msg_Type,
              '',
              V_ACCT_NUMBER,
              '',
              P_CURR_CODE,
              V_HASHKEY_ID
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
      END;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption
 
END;
/
show error;
