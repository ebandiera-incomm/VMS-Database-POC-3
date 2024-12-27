create or replace PROCEDURE        VMSCMS.SP_USER_VALIDATEQUEST_ANS(
                          P_INST_CODE         IN   NUMBER ,
                          P_PAN_CODE          IN   VARCHAR2,
                          P_DELIVERY_CHANNEL  IN   VARCHAR2,
                          P_TXN_CODE          IN   VARCHAR2,   
                          P_RRN               IN   VARCHAR2,
                          P_USERNAME          IN   VARCHAR2, 
                          P_SECQUEST1         IN   VARCHAR2,
                          P_SECQUEST1ANS      IN   VARCHAR2,
                          P_TXN_MODE          IN   VARCHAR2,
                          P_TRAN_DATE         IN   VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_IPADDRESS         IN   VARCHAR2,
                          P_CURR_CODE         IN   VARCHAR2,
                          P_RVSL_CODE         IN   VARCHAR2,
                          P_BANK_CODE         IN   VARCHAR2,
                          P_MSG               IN   VARCHAR2,
                          P_APPL_ID           IN   VARCHAR2 ,   
                          P_MOB_NO            IN   VARCHAR2,   
                          P_DEVICE_ID         IN   VARCHAR2,   
                          P_PASSWORD          IN   VARCHAR2,
                          P_RESP_CODE         OUT  VARCHAR2 ,
                          P_RESMSG            OUT  VARCHAR2)

AS
/*************************************************
     * Created Date     :  05-Apr-2012
     * Created By       :  Ramesh.A
     * PURPOSE          :  Validate the security question with answer using username
	 
     * modified by      : B.Besky
     * modified Date    : 06-NOV-12
     * modified reason  : Changes in Exception handling
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 06-NOV-12
     * Build Number     :  CMS3.5.1_RI0021

     * Modified by      : S Ramkumar
     * Modified Reason  : Mantis Id - 11357
     * Modified Date    : 25-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 26-Jun-13
     * Build Number     : RI0024.2_B0009

     * modified by       :  RAVI N
     * modified Date     :  09-AUG-13
     * modified reason   :  Adding new Input [P_MOB_NO,P_DEVICE_ID] parameters and logging cms_transaction_log_dtl
     * modified reason   :  FSS-1144
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  29-AUG-13
     * Build Number      :  RI0024.4_B0006

     * Modified By       : Sai Prasad
     * Modified Date     : 11-Sep-2013
     * Modified For      : Mantis ID: 0012278 (JIRA FSS-1144)
     * Modified Reason   : IP Address is not logged in transactionlog table.
     * Reviewer          : Dhiraj
     * Reviewed Date     : 12-SEP-2013
     * Build Number      : RI0024.4_B0010

     * Modified By      : Pankaj S.
     * Modified Date    : 10-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0027_B0003

      * Modified By     : Siva Kumar M
     * Modified Date    : 06/Mar/2015
     * Modified Reason  : DFCTNM-36
     * Reviewer         : SaravanKumar A
     * Reviewed Date    : 06/Mar/2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By       : Siva Kumar M
     * Modified Date    : 24/Mar/2015
     * Modified Reason  : DFCTNM-36
     * Reviewer         : Pankaj s
     * Reviewed Date    : 24/Mar/2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0002

     * Modified By       : Siva Kumar M
     * Modified Date    : 27/Mar/2015
     * Modified Reason  : DFCTNM-36
     * Reviewer         : Pankaj s
     * Reviewed Date    : 27/Mar/2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0003

     * Modified By      : Siva Kumar M
     * Modified Date    : 24-Sep-2015
     * Modified Reason  : DFCTNM-79
	   * Reviewer         : Saravana kumar
     * Reviewed Date    : 25-Sep-2015
     * Build Number     : VMSGPRHOSTCSD3.2_B0002

      * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
      
      * Modified By      : VINI PUSHKARAN
      * Modified Date    : 01-MAR-2019
      * Purpose          : VMS-809 (Decline Request for Web-account Username if Username is Already Taken)
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R13_B0002 

    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991     
*************************************************/

V_RRN_COUNT             NUMBER;
V_ERRMSG                TRANSACTIONLOG.ERROR_MSG%TYPE;
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_SPND_ACCT_NO          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  CMS_TRANSACTION_LOG_DTL.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
V_TERM_ID               TRANSACTIONLOG.TERMINAL_ID%TYPE;
V_MCC_CODE              TRANSACTIONLOG.MCCODE%TYPE;
V_TXN_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_ACCT_NUMBER           cms_appl_pan.cap_acct_no%TYPE; 
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CUST_ID               CMS_CUST_MAST.CCM_CUST_ID%TYPE;
V_USER_NAME             CMS_CUST_MAST.CCM_USER_NAME%TYPE;
V_ANSWER                CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_COUNT                 NUMBER;
V_CARDSTAT              CMS_APPL_PAN.CAP_CARD_STAT%TYPE;                               
V_HASH_SQA1             CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;  
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;     
v_respcode              TRANSACTIONLOG.RESPONSE_ID%TYPE;                               
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
V_TIME_STAMP            TRANSACTIONLOG.TIME_STAMP%TYPE;                                  
v_encrypt_enable        cms_prod_cattype.cpc_encrypt_enable%type;
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
v_acct_type             cms_acct_mast.cam_type_code%TYPE;
q1                      varchar2(100);
a1                      varchar2(100);
qp                      number;
qp1                     number;
ap                      number;
ap1                     number;
i                       number:=1;
V_SECUT_ANS_VALIDMSG    VARCHAR2(50);
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991

     CURSOR C (CUST_ID NUMBER,INST_CODE NUMBER) IS
      SELECT CSQ_QUESTION
      FROM CMS_SECURITY_QUESTIONS
      WHERE CSQ_CUST_ID=CUST_ID AND CSQ_INST_CODE=INST_CODE;

BEGIN
   V_TXN_TYPE := '1';
   V_TIME_STAMP :=SYSTIMESTAMP; 
   
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
        END;

      --Start Generate HashKEY value for regarding FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    --End Generate HashKEY value for regarding FSS-1144


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
       P_RESP_CODE := '12'; 
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; 
       V_ERRMSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
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
		  EXCEPTION
		  WHEN EXP_REJECT_RECORD THEN
		     RAISE EXP_REJECT_RECORD;
		  WHEN OTHERS THEN
			 P_RESP_CODE := '21';
			 V_ERRMSG  := 'Error while selecting RRN Count from transactionlog ' ||
			 SUBSTR(SQLERRM, 1, 200);
			 RAISE EXP_REJECT_RECORD;
        END;
       --En Duplicate RRN Check

--      --Sn Get Tran date
--        BEGIN
--          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
--                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
--                  'yyyymmdd hh24:mi:ss');
--          EXCEPTION
--            WHEN OTHERS THEN
--           P_RESP_CODE := '21';
--           V_ERRMSG  := 'Problem while converting transaction date ' ||
--                SUBSTR(SQLERRM, 1, 200);
--           RAISE EXP_REJECT_RECORD;
--        END;
--       --En Get Tran date

         BEGIN
              SELECT CAP_CARD_STAT,
                     cap_prod_code,cap_card_type,cap_acct_no,cap_cust_code  
                INTO V_CARDSTAT,
                     v_prod_code,v_card_type,v_spnd_acct_no,v_cust_code  
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; 
                V_ERRMSG  := 'Card number not found ';
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
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                V_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                V_TXN_AMT,
                NULL,
                NULL,
                V_MCC_CODE,
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
                V_CARD_EXPRY,
                V_STAN,
                '000',
                P_RVSL_CODE,
                V_TXN_AMT,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
        P_RESMSG:= 'Error from auth process' || V_ERRMSG;
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

    --St Get the cust id from mast
    BEGIN

      SELECT cpc_encrypt_enable
          INTO v_encrypt_enable
          FROM cms_prod_cattype
         WHERE cpc_inst_code=p_inst_code
         and cpc_prod_code=v_prod_code
         and cpc_card_type=v_card_type;
    EXCEPTION
      WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error while selecting from prod cattype' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    if v_encrypt_enable='Y' then
      v_user_name:=fn_emaps_main(upper(trim(p_username)));
    else
        v_user_name:=upper(trim(p_username));
    end if;
    
    BEGIN
    
        SELECT CCM_CUST_ID
        INTO V_CUST_ID
        FROM CMS_CUST_MAST
        WHERE CCM_INST_CODE = P_INST_CODE
        AND CCM_CUST_CODE   = V_CUST_CODE; -- Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
            
--    upper(ccm_user_name)=v_user_name AND CCM_INST_CODE=P_INST_CODE
--       /* Start CR014 Changes Dhiraj GAikwad 04092012*/
--           AND CCM_APPL_ID =P_APPL_ID  ;
--           /* End CR014 Changes Dhiraj GAikwad 04092012*/

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'CUST ID NOT FOUND';
        RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error while getting cust id from mast' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;
    --St Get the cust id from mast


    IF ( (P_DELIVERY_CHANNEL='13' AND  P_TXN_CODE IN ('35','48')) OR  (P_DELIVERY_CHANNEL='10' AND  P_TXN_CODE  IN ('47','50') ) )   THEN

                         begin

                            loop
                                qp:= instr(P_SECQUEST1,'||',1,i);
                                ap:= instr(P_SECQUEST1ANS,'||',1,i);

                                if i=1 and qp=0 then
                                    q1:=P_SECQUEST1;
                                    a1:=P_SECQUEST1ANS;
                                elsif i<>1 and qp=0 then
                                    qp1:= instr(P_SECQUEST1,'||',1,i-1);
                                    q1:=substr(P_SECQUEST1,qp1+2);
                                    ap1:= instr(P_SECQUEST1ANS,'||',1,i-1);
                                    a1:=substr(P_SECQUEST1ANS,ap1+2);

                                elsif i<>1 and qp<>0 then
                                    qp1:= instr(P_SECQUEST1,'||',1,i-1);
                                    q1:=substr(P_SECQUEST1,qp1+2,qp-qp1-2);
                                    ap1:= instr(P_SECQUEST1ANS,'||',1,i-1);
                                    a1:=substr(P_SECQUEST1ANS,ap1+2,ap-ap1-2);
                                elsif i=1 and qp<>0 then
                                    q1:=substr(P_SECQUEST1,1,qp-1);
                                    a1:=substr(P_SECQUEST1ANS,1,ap-1);
                                end if;

                                i:=i+1;

 
                                    BEGIN
                                      SELECT COUNT(1) INTO V_COUNT
                                      FROM CMS_SECURITY_QUESTIONS
                                      WHERE CSQ_CUST_ID=V_CUST_ID
                                      AND CSQ_INST_CODE=P_INST_CODE and CSQ_QUESTION=TRIM(q1) and CSQ_ANSWER_HASH =gethash(a1);

                                      IF V_COUNT = 0 THEN
                                       P_RESP_CODE := '117';
                                       V_ERRMSG  := 'Invalid Security Question/Answer';
                                      RAISE EXP_REJECT_RECORD;

                                      ELSE

                                      V_SECUT_ANS_VALIDMSG :='OK';

                                      END IF;
                                    EXCEPTION
                                     WHEN EXP_REJECT_RECORD THEN
                                          RAISE EXP_REJECT_RECORD;
                                     WHEN OTHERS THEN
                                       P_RESP_CODE := '21';
                                       V_ERRMSG  := 'Error while checking the security question' ||
                                            SUBSTR(SQLERRM, 1, 200);
                                       RAISE EXP_REJECT_RECORD;
                                    END;

                            --  END IF;

                                exit when qp=0 ;

                            end loop;
                         EXCEPTION

                         when EXP_REJECT_RECORD then
                         raise;

                         WHEN OTHERS THEN
                          P_RESP_CODE := '21';
                          V_ERRMSG  := 'Error while checking the security question  and answer ' ||
                                            SUBSTR(SQLERRM, 1, 200);
                                       RAISE EXP_REJECT_RECORD;




                         end;

     IF ((P_DELIVERY_CHANNEL='13' AND  P_TXN_CODE  <> '48') OR  (P_DELIVERY_CHANNEL='10' AND  P_TXN_CODE <>'50') ) and V_SECUT_ANS_VALIDMSG = 'OK' THEN

                         -- IF V_SECUT_ANS_VALIDMSG = 'OK' THEN


                                BEGIN
                                      UPDATE CMS_CUST_MAST SET CCM_PASSWORD_HASH = GETHASH(P_PASSWORD)
                                      WHERE  CCM_INST_CODE= P_INST_CODE
                                      AND CCM_CUST_CODE = V_CUST_CODE; --Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
                                      
--                                      upper(ccm_user_name)=v_user_name AND CCM_INST_CODE=P_INST_CODE
--                                         AND CCM_APPL_ID =P_APPL_ID ;


                                       IF SQL%ROWCOUNT = 0 THEN
                                       P_RESP_CODE := '21';
                                       V_ERRMSG  := 'Not udpated new password ';
                                       RAISE EXP_REJECT_RECORD;
                                       END IF;

                                EXCEPTION
                                       WHEN EXP_REJECT_RECORD THEN
                                         RAISE EXP_REJECT_RECORD;
                                        WHEN OTHERS THEN
                                         P_RESP_CODE := '21';
                                         V_ERRMSG  := 'Error from while updating new password ' ||
                                              SUBSTR(SQLERRM, 1, 200);
                                       RAISE EXP_REJECT_RECORD;

                                   END;


                                  P_RESP_CODE := '1';
                                  V_ERRMSG := 'SUCCESS';




                         -- END IF;

    END IF;

                           P_RESP_CODE := '1';
                           V_ERRMSG := 'SUCCESS';

            --En Get the questions using username
   ELSIF  ( (P_DELIVERY_CHANNEL='13' AND  P_TXN_CODE='34') OR (P_DELIVERY_CHANNEL='10' AND  P_TXN_CODE='46') )   THEN



         BEGIN

              FOR I IN C(V_CUST_ID,P_INST_CODE) LOOP


              IF P_RESMSG IS NULL THEN
                  P_RESMSG :=I.CSQ_QUESTION;
              ELSE
                  P_RESMSG :=P_RESMSG || '||' || I.CSQ_QUESTION;
              END IF;

            END LOOP;

             P_RESP_CODE := '1';
             V_ERRMSG := 'SUCCESS';

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Cust Id not Found ';
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             P_RESP_CODE := '21';
             V_ERRMSG  := 'Error from while selecting customer id and questions' ||
                  SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;

         END;



   ELSE

    --St check the security question is valid or not
    BEGIN
      SELECT COUNT(1) INTO V_COUNT
      FROM CMS_SECURITY_QUESTIONS
      WHERE CSQ_CUST_ID=V_CUST_ID
      AND CSQ_INST_CODE=P_INST_CODE and upper(CSQ_QUESTION)=upper(TRIM(P_SECQUEST1));

      IF V_COUNT = 0 THEN
       P_RESP_CODE := '117';
       V_ERRMSG  := 'Invalid Security Question';
      RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
          RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error while checking the security question' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --En check the security question is valid or not

    --Sn Get the HashSecuriyAnswerOne
       BEGIN
          V_HASH_SQA1 := GETHASH(trim(P_SECQUEST1ANS));  
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting security answer one ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
     --En Get the HashSecuriyAnswerOne

    --St Get the questions using username

     BEGIN

      SELECT CSQ_ANSWER_HASH INTO V_ANSWER
      FROM CMS_SECURITY_QUESTIONS
      WHERE CSQ_CUST_ID=V_CUST_ID
      AND CSQ_INST_CODE=P_INST_CODE and upper(CSQ_QUESTION)=upper(TRIM(P_SECQUEST1));

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG := 'Cust Id  not Found ';
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting the answer using username ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;

    IF V_ANSWER = V_HASH_SQA1  THEN
      P_RESP_CODE := '1';
      V_ERRMSG := 'SUCCESS';
    ELSE
      P_RESP_CODE := '115';
      V_ERRMSG := 'Invalid Answer to Security Question'; -- Updated by Ramesh.A on 08/06/2012
    END IF;

            --En Get the questions using username
   END IF;

     --ST Get responce code from master
        BEGIN
          SELECT CMS_ISO_RESPCDE
            INTO v_respcode
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69';
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
        END;
      --En Get responce code fomr master

       --Sn update transaction details in translog
        BEGIN

IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE TRANSACTIONLOG
          SET 
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS=P_IPADDRESS 
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
ELSE
     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET 
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS=P_IPADDRESS 
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
   END IF;

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update trasaction details in translog

        P_RESP_CODE := v_respcode;      

        BEGIN


--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE CMS_TRANSACTION_LOG_DTL
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_USER_NAME=v_user_name,
          CTD_MOBILE_NUMBER=P_MOB_NO, 
          CTD_DEVICE_ID=P_DEVICE_ID  
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = P_TXN_CODE AND CTD_BUSINESS_DATE = P_TRAN_DATE AND
           CTD_BUSINESS_TIME = P_TRAN_TIME AND  CTD_MSG_TYPE = P_MSG AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=P_INST_CODE;
ELSE
      UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_USER_NAME=v_user_name,
          CTD_MOBILE_NUMBER=P_MOB_NO, 
          CTD_DEVICE_ID=P_DEVICE_ID  
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = P_TXN_CODE AND CTD_BUSINESS_DATE = P_TRAN_DATE AND
           CTD_BUSINESS_TIME = P_TRAN_TIME AND  CTD_MSG_TYPE = P_MSG AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=P_INST_CODE;
END IF;
  
          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog_detl ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update trasaction details in translog_detl

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION

WHEN EXP_AUTH_REJECT_RECORD THEN  
     BEGIN
IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE CMS_TRANSACTION_LOG_DTL
              --SET CTD_USER_NAME= P_USERNAME,
              SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
   ELSE 
                UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
              --SET CTD_USER_NAME= P_USERNAME,
              SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOB_NO,
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

WHEN EXP_REJECT_RECORD THEN
 ROLLBACK ;--TO V_AUTH_SAVEPOINT;

   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
          INTO v_respcode
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


   IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_cardstat, v_prod_code, v_card_type, v_spnd_acct_no
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
   END IF;

    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_acct_balance, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_acct_no = v_spnd_acct_no AND cam_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          v_acct_balance := 0;
          v_ledger_bal := 0;
    END;

   IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
      INTO v_dr_cr_flag,
           v_txn_type, v_trans_desc
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
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     response_id,
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
                      v_respcode,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_SPND_ACCT_NO,
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARDSTAT, 
                     V_TRANS_DESC,
                     P_RESP_CODE,
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_MOBILE_NUMBER, 
              CTD_DEVICE_ID,     
              CTD_USER_NAME,      
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
              V_ENCR_PAN_FROM,
              '000',
              '',
              V_SPND_ACCT_NO,
              '',
              P_MOB_NO,    
              P_DEVICE_ID, 
              v_user_name,
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

        P_RESP_CODE := v_respcode;     
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
           INTO v_respcode
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


   IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_cardstat, v_prod_code, v_card_type, v_spnd_acct_no
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
   END IF;

    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_acct_balance, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_acct_no = v_spnd_acct_no AND cam_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          v_acct_balance := 0;
          v_ledger_bal := 0;
    END;

   IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
      INTO v_dr_cr_flag,
           v_txn_type, v_trans_desc
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
                       CUSTOMER_ACCT_NO,
                       ERROR_MSG,
                       IPADDRESS,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       TRANS_DESC,
                       response_id,
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
                       v_respcode,
                       P_TRAN_DATE,
                       P_TRAN_TIME,
                       V_HASH_PAN,
                       P_INST_CODE,
                       V_ENCR_PAN_FROM,
                       V_SPND_ACCT_NO,
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       V_CARDSTAT,
                       V_TRANS_DESC,
                       P_RESP_CODE,
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
                      CTD_MOBILE_NUMBER, 
                      CTD_DEVICE_ID,     
                      CTD_USER_NAME,     
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
              V_ENCR_PAN_FROM,
              '000',
              '',
              V_SPND_ACCT_NO,
              '',
              P_MOB_NO,    
              P_DEVICE_ID,
              v_user_name,
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
      P_RESP_CODE := v_respcode;     

END;
/
show error