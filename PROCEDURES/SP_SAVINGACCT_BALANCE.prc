set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVINGACCT_BALANCE (
                              P_INST_CODE        IN NUMBER ,
                              P_PAN_CODE         IN NUMBER,
                              P_DELIVERY_CHANNEL IN VARCHAR2,
                              P_TXN_CODE         IN VARCHAR2, --Modified by Kaliraj as on 06-Mar-2012
                              P_RRN              IN VARCHAR2,
                              P_TXN_MODE         IN VARCHAR2,
                              P_TRAN_DATE        IN VARCHAR2,
                              P_TRAN_TIME        IN VARCHAR2,
                              P_IPADDRESS        IN VARCHAR2,
                              P_SVG_ACCT_NO      IN VARCHAR2 ,
                              P_ANI              IN VARCHAR2,
                              P_DNI              IN VARCHAR2,
                              P_BANK_CODE        IN  VARCHAR2,  --Added by Ramesh.A on 08/03/2012
                              P_CURR_CODE        IN  VARCHAR2,  --Added by Ramesh.A on 08/03/2012
                              P_RVSL_CODE        IN VARCHAR2,   --Added by Ramesh.A on 08/03/2012
                              P_MSG              IN VARCHAR2,   --Added by Ramesh.A on 08/03/2012
                              P_RESP_CODE        OUT VARCHAR2 ,
                              P_AVAIL_BAL_AMT    OUT VARCHAR2,
                              P_BUSINESS_DATE    OUT VARCHAR2,
                              P_RESMSG           OUT VARCHAR2,
                              P_SAVING_COMP_BAL  OUT VARCHAR2,--Added for CR - 40 in release 23.1.1
                              P_DAILY_INT_ACCUR  OUT VARCHAR2,--Added for CR - 40 in release 23.1.1
                              P_QTD_INTEREST     OUT VARCHAR2,--Added for CR - 40 in release 23.1.1
                              P_YTD_INTEREST     OUT VARCHAR2,--Added for CR - 40 in release 23.1.1
                              P_BEGINING_BAL     OUT VARCHAR2)--Added for CR - 40 in release 23.1.1
AS
/*************************************************
  * Created Date     :  20-Feb-2012
  * Created By       :  Sriram
  * PURPOSE          :  Saving account balance
  * modified by      :  Saravanakumar
  * modified Date    :  14-Feb-2013
  * modified reason  :  Assigned 0.00 in P_BEGINING_BAL if no data found instead of null
  * Reviewer         :  Sachin
  * Reviewed Date    :  14-Feb-2013
  * Build Number     :  CMS3.5.1_RI0023.1.1_B0005

  * Modified by      :  Pankaj S.
  * Modified Reason  :  10871
  * Modified Date    :  18-Apr-2013
  * Reviewer         :  Dhiraj
  * Reviewed Date    :
  * Build Number     :  RI0024.1_B0013

  * Modified by      :  Pankaj S.
  * Modified Reason  :  DFCCSD-70
  * Modified Date    :  21-Aug-2013
  * Reviewer         :  Dhiraj
  * Reviewed Date    :  20-Aug-2013
  * Build Number     :  RI0024.4_B0006

   * Modified By      : Sai Prasad
   * Modified Date    : 11-Sep-2013
   * Modified For     : Mantis ID: 0012275 (JIRA FSS-1144)
   * Modified Reason  : ANI & DNI is not logged in transactionlog table.
   * Reviewer         : Dhiraj
   * Reviewed Date    : 11-Sep-2013
   * Build Number     : RI0024.4_B0010

    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
 *************************************************/
V_STAT_CODE         VARCHAR2(3);
V_SAVING_ACCTNO    VARCHAR2(20);
V_TRAN_DATE        DATE;
V_CARDSTAT         VARCHAR2(5);
V_CARDEXP          DATE;
--V_AUTH_SAVEPOINT   NUMBER DEFAULT 0; --Commented for CR - 40 in release 23.1.1
V_COUNT            NUMBER;
V_RRN_COUNT        NUMBER;
V_ACCT_BALANCE     NUMBER;
V_BRANCH_CODE      VARCHAR2(5);
V_ERRMSG           VARCHAR2(500);
V_HASH_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM     CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE         CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_SAVING_ACCT_NO      CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_ACCT_TYPE         CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_ACCT_STATCODE     CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
V_TXN_TYPE          TRANSACTIONLOG.TXN_TYPE%TYPE;
V_SWITCH_ACCT_TYPE  CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_SWITCH_ACCT_STATCODE CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '2';

--St:Added by Ramesh.A on 08/03/2012
V_CARD_EXPRY           VARCHAR2(20);
V_STAN                 VARCHAR2(20);
V_CAPTURE_DATE         DATE;
V_TERM_ID              VARCHAR2(20);
V_MCC_CODE             VARCHAR2(20);
V_TXN_AMT               NUMBER;
V_ACCT_NUMBER           NUMBER;

V_DR_CR_FLAG       VARCHAR2(2);
V_OUTPUT_TYPE      VARCHAR2(2);
V_TRAN_TYPE         VARCHAR2(2);
v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
V_AUTH_ID              TRANSACTIONLOG.AUTH_ID%TYPE;
EXP_AUTH_REJECT_RECORD EXCEPTION;
--End: Added by Ramesh.A on 08/03/2012
V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

EXP_REJECT_RECORD EXCEPTION;
v_cur_month number; --Added for CR - 40 in release 23.1.1
v_pre_month varchar2(2);--Added for CR - 40 in release 23.1.1
--Sn added by Pankaj S. for 10871
v_prod_code      cms_appl_pan.cap_prod_code%TYPE;
v_prod_cattype   cms_appl_pan.cap_card_type%TYPE;
v_resp_cde       cms_response_mast.cms_response_id%TYPE;
--En added by Pankaj S. for 10871

--Sn Added by Pankaj S. for DFCCSD-70 changes
v_spd_acct_no   cms_acct_mast.cam_acct_no%TYPE;
v_avail_bal     cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal    cms_acct_mast.cam_ledger_bal%TYPE;
--En Added by Pankaj S. for DFCCSD-70 changes
v_savacct_balenq_date   cms_acct_mast.cam_savacct_balenq_date%TYPE; --Added for transactionlog Functional Removal Phase-II changes

--Main Begin Block Starts Here
BEGIN
   V_TXN_TYPE := '1';
    P_RESP_CODE := '1';--Added for CR - 40 in release 23.1.1
    P_RESMSG := 'OK';--Added for CR - 40 in release 23.1.1
   --SAVEPOINT V_AUTH_SAVEPOINT;

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
       RAISE EXP_REJECT_RECORD;
    END;


    --En find debit and credit flag

       --Sn Duplicate RRN Check
        BEGIN
          --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;--Added by ramkumar.Mk on 25 march 2012
      ELSE
           SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
      END IF;    
          IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
        --Sn added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
        EXCEPTION
        WHEN exp_reject_record THEN
         RAISE;
        WHEN OTHERS THEN
           p_resp_code := '21';
           v_errmsg :='Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
           RAISE exp_reject_record;
       --En added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
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
              SELECT CAP_CARD_STAT, CAP_EXPRY_DATE,
                   cap_prod_code, cap_card_type,cap_cust_code, --added by Pankaj S. for 10871
                   cap_acct_no   --Added by Pankaj S. for DFCCSD-70
              INTO V_CARDSTAT, V_CARDEXP,
                   v_prod_code,v_prod_cattype,v_cust_code, --added by Pankaj S. for 10871
                   v_spd_acct_no   --Added by Pankaj S. for DFCCSD-70
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

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
    --Commented for CR - 40 in release 23.1.1
     --Sn Check Delivery Channel Added by Sriram as on 29-02-2012
      /*IF P_DELIVERY_CHANNEL NOT IN ('10','07') THEN
        V_ERRMSG  := 'Not a valid delivery channel';
        P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
        RAISE EXP_REJECT_RECORD;
      END IF;*/
--En Check Delivery Channel
--Commented for CR - 40 in release 23.1.1
--Sn Check Transaction code Added by Sriram as on 29-02-2012.
       /*IF P_TXN_CODE NOT IN ('22','13') THEN
            V_ERRMSG  := 'Not a valid transaction code for ' ||
                 ' saving account balance enquiry';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;*/
--En Check Transaction code.

         --Sn commented by Pankaj S. during 10871 changes and fetch same using above query
         --St Get Cust code from master
         /* BEGIN
            SELECT CAP_CUST_CODE INTO  V_CUST_CODE
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE=V_HASH_PAN AND CAP_INST_CODE=P_INST_CODE;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              P_RESP_CODE := '21';
              V_ERRMSG := 'Product code,Cust code Not Found';
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 P_RESP_CODE := '12';
                 V_ERRMSG :='Error while getting product code,cust code from master '|| SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;--Added for CR - 40 in release 23.1.1
          END;*/
        --En Get Cust code from master
        --En commented by Pankaj S. during 10871 changes and fetch same using above query

        --Sn select acct type
          BEGIN
            SELECT CAT_TYPE_CODE
            INTO V_ACCT_TYPE
            FROM CMS_ACCT_TYPE
            WHERE CAT_INST_CODE = P_INST_CODE AND
            CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               P_RESP_CODE := '12';  --Added by Ramesh.A on 08/03/2012
               V_ERRMSG := 'Acct type not defined in master';
               RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
               P_RESP_CODE := '21';  --Added by Ramesh.A on 08/03/2012
               V_ERRMSG := 'Error while selecting accttype ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          END;
        --En select acct type



  BEGIN
           SELECT CAS_STAT_CODE
           INTO V_ACCT_STATCODE
           FROM CMS_ACCT_STAT
           WHERE CAS_INST_CODE = P_INST_CODE AND
           CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STATCODE;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '12'; --Added by Ramesh.A on 08/03/2012
             V_ERRMSG := 'Acct stat not defined for  master';
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
             V_ERRMSG := 'Error while selecting accttype ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;


        --Sn Below query commented by Pankaj S. during DFCCSD-70(Review) changes
        /*--Sn check whether the Saving Account already created or not
         BEGIN
           SELECT COUNT(1) INTO V_COUNT FROM CMS_ACCT_MAST
           WHERE cam_acct_id in( SELECT cca_acct_id FROM CMS_CUST_ACCT
           where cca_cust_code=V_CUST_CODE and cca_inst_code=P_INST_CODE) and cam_type_code=V_ACCT_TYPE
           AND CAM_INST_CODE=P_INST_CODE;

           IF V_COUNT = 0 THEN
           V_ERRMSG := 'SAVING ACCOUNT NOT YET CREATED FOR THIS CARD';
           P_RESMSG := V_ERRMSG;
           P_RESP_CODE := '105';
           RAISE EXP_REJECT_RECORD;
           END IF;
           EXCEPTION
            WHEN EXP_REJECT_RECORD THEN --Added by Ramesh.A on 08/03/2012
            RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
             V_ERRMSG := 'Error while selecting CMS_ACCT_MAST1 ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;
      --En check whether the Saving Account already created or not*/
      --Sn Below query commented by Pankaj S. during DFCCSD-70(Review) changes

      --SN CHECK SAVINGS ACCOUNT IS VALID OR NOT.


      BEGIN
          SELECT CAM_ACCT_NO,
                 CAM_STAT_CODE,  --Added by Pankaj S. during DFCCSD-70(Review) changes
                 cam_savacct_balenq_date   --Added for transactionlog Functional Removal Phase-II changes
          INTO V_SAVING_ACCTNO,
               V_STAT_CODE,  --Added by Pankaj S. during DFCCSD-70(Review) changes
               v_savacct_balenq_date  --Added for transactionlog Functional Removal Phase-II changes
          FROM CMS_ACCT_MAST WHERE  CAM_ACCT_ID IN(SELECT cca_acct_id FROM CMS_CUST_ACCT
          WHERE cca_cust_code = V_CUST_CODE  AND cca_inst_code=P_INST_CODE) and cam_type_code = V_ACCT_TYPE
          AND CAM_INST_CODE=P_INST_CODE;

          IF V_SAVING_ACCTNO <> P_SVG_ACCT_NO THEN
             V_ERRMSG:='SAVINGS ACCOUNT NUMBER IS INVALID';
             P_RESP_CODE:='109';
              RAISE EXP_REJECT_RECORD;
          END IF;

          --Sn Added here & commented down by Pankaj S. during DFCCSD-70(Review) changes
          IF V_ACCT_STATCODE = V_STAT_CODE THEN     --added for close as on 01-03-2012 by sriram
                 V_ERRMSG:='SAVINGS ACCOUNT ALREADY CLOSED';
                 P_RESP_CODE:='106';
                  RAISE EXP_REJECT_RECORD;
          END IF;
          --En Added here & commented down by Pankaj S. during DFCCSD-70(Review) changes

           EXCEPTION
            WHEN EXP_REJECT_RECORD THEN --Added by Ramesh.A on 08/03/2012
            RAISE EXP_REJECT_RECORD;
            --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
            WHEN NO_DATA_FOUND THEN
             V_ERRMSG := 'SAVING ACCOUNT NOT YET CREATED FOR THIS CARD';
             P_RESP_CODE := '105';
           RAISE EXP_REJECT_RECORD;
           --En Added by Pankaj S. during DFCCSD-70(Review) changes
             WHEN OTHERS THEN
             P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
             V_ERRMSG := 'Error while selecting CMS_ACCT_MAST2 ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
      END;
      --EN CHECK SAVINGS ACCOUNT IS VALID OR NOT.

   --Sn Below query commented by Pankaj S. during DFCCSD-70(Review) changes
   --CHECKING SAVINGS ACCOUNT IS OPEN OR NOT. ADDED BY SRIRAM ON 29/02/2012
    /*BEGIN
          SELECT CAM_STAT_CODE INTO V_STAT_CODE
          FROM CMS_ACCT_MAST WHERE  CAM_ACCT_ID IN(SELECT cca_acct_id FROM CMS_CUST_ACCT
          WHERE cca_cust_code = V_CUST_CODE  AND cca_inst_code=P_INST_CODE) and cam_type_code = V_ACCT_TYPE
          AND CAM_INST_CODE=P_INST_CODE;

              IF V_ACCT_STATCODE = V_STAT_CODE THEN     --added for close as on 01-03-2012 by sriram
                 V_ERRMSG:='SAVINGS ACCOUNT ALREADY CLOSED';
                 P_RESP_CODE:='106';
                  RAISE EXP_REJECT_RECORD;
              END IF;
     EXCEPTION
      WHEN EXP_REJECT_RECORD THEN --Added by Ramesh.A on 08/03/2012
            RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
       V_ERRMSG := 'Error while selecting CMS_ACCT_MAST3 ' ||
            SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;
    --END CHECKING SAVINGS ACCOUNT IS OPEN NOT.*/
    --En Below query commented by Pankaj S. during DFCCSD-70(Review) changes

      --ST :  Added by Ramesh.A on 08/03/2012
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
        RAISE EXP_AUTH_REJECT_RECORD; --Updated by Ramesh.A on 25/05/2012
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;                    -- Added by Ramesh.A on 25/05/2012
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure
    --End :  Added by Ramesh.A on 08/03/2012
   --Sn Select A/c No. Balance
        BEGIN
           SELECT CAM_ACCT_NO,CAM_ACCT_BAL ,
           to_char(nvl((CAM_ACCT_BAL+CAM_INTEREST_AMOUNT),'0'),'99999999999999990.99'),--Added for CR - 40 in release 23.1.1
           to_char(nvl(CAM_INTEREST_AMOUNT,'0'),'99999999999999990.99')--Added for CR - 40 in release 23.1.1
           INTO V_SAVING_ACCT_NO,V_ACCT_BALANCE,
           P_SAVING_COMP_BAL,P_DAILY_INT_ACCUR--Added for CR - 40 in release 23.1.1
           FROM CMS_ACCT_MAST
           --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
           WHERE cam_acct_no=p_svg_acct_no
           --cam_acct_id in( SELECT cca_acct_id FROM CMS_CUST_ACCT
           --where cca_cust_code=V_CUST_CODE and cca_inst_code=P_INST_CODE) and cam_type_code=V_ACCT_TYPE
           --En Modified by Pankaj S. during DFCCSD-70(Review) changes
           AND CAM_INST_CODE=P_INST_CODE;
           P_AVAIL_BAL_AMT := TRIM(TO_CHAR(V_ACCT_BALANCE, '99999999999999990.99')); --Updated by Ramesh.A on 08/03/2012
           EXCEPTION
             WHEN OTHERS THEN
             V_ERRMSG := 'Error while selecting CMS_ACCT_MAST4 ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;
 --En Select A/c No. Balance
--Sn Added for CR - 40 in release 23.1.1

    ---------------------------------------------------------------------------------
    --Sn Modified to used single query during DFCCSD-70(Review) changes by Pankaj S.
    ---------------------------------------------------------------------------------
    /*begin
        select TO_CHAR (nvl(sum(CSL_TRANS_AMOUNT),'0'), '99999999999999990.99')
        into  P_YTD_INTEREST
        from CMS_STATEMENTS_LOG
        where CSL_TRANS_TYPE='CR' and CSL_DELIVERY_CHANNEL='05' and CSL_TXN_CODE='13'
        and CSL_INS_DATE between trunc(V_TRAN_DATE,'year') and V_TRAN_DATE and
        CSL_ACCT_NO=V_SAVING_ACCT_NO And CSL_INST_CODE=P_INST_CODE;
    exception
        when no_data_found then
            P_YTD_INTEREST:=null;
        when others then
            V_ERRMSG := 'Error while selecting P_YTD_INTEREST ' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    end;*/

    v_cur_month:= to_char(V_TRAN_DATE,'mm');

    if v_cur_month <=3 then
        v_pre_month:='01';
    elsif v_cur_month <=6 then
        v_pre_month:='04';
    elsif v_cur_month <=9 then
        v_pre_month:='07';
    else
        v_pre_month:='10';
    end if;

    /*begin
        select TO_CHAR (nvl(sum(CSL_TRANS_AMOUNT),'0'), '99999999999999990.99')
        into  P_QTD_INTEREST
        from CMS_STATEMENTS_LOG
        where CSL_TRANS_TYPE='CR' and CSL_DELIVERY_CHANNEL='05' and CSL_TXN_CODE='13'
        and CSL_INS_DATE between to_date(v_pre_month||to_char(V_TRAN_DATE,'yyyy'),'mmyyyy') and V_TRAN_DATE
        and CSL_ACCT_NO=V_SAVING_ACCT_NO And CSL_INST_CODE=P_INST_CODE;
    exception
        when no_data_found then
            P_QTD_INTEREST:=null;
        when others then
            V_ERRMSG := 'Error while selecting P_YTD_INTEREST ' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    end;*/

    BEGIN
    SELECT TO_CHAR(NVL(SUM
                      (CASE
                          WHEN csl_ins_date BETWEEN TO_DATE(v_pre_month|| TO_CHAR(v_tran_date,'yyyy'),'mmyyyy')AND v_tran_date
                             THEN csl_trans_amount
                       END),'0'),'99999999999999990.99'),
           TO_CHAR(NVL(SUM
                      (CASE
                          WHEN csl_ins_date BETWEEN TRUNC (v_tran_date, 'year')AND v_tran_date
                             THEN csl_trans_amount
                       END),'0'),'99999999999999990.99')
      INTO p_qtd_interest,
           p_ytd_interest
      FROM CMS_STATEMENTS_LOG_VW
     WHERE csl_trans_type = 'CR'
       AND csl_delivery_channel = '05'
       AND csl_txn_code = '13'
       AND csl_acct_no = v_saving_acct_no
       AND csl_inst_code = p_inst_code;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      p_qtd_interest := NULL;
      p_ytd_interest := NULL;
     WHEN OTHERS THEN
      v_errmsg := 'Error while selecting p_ytd_interest & p_qtd_interest ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    ---------------------------------------------------------------------------------
    --En Modified to used single query during DFCCSD-70(Review) changes by Pankaj S.
    ---------------------------------------------------------------------------------

    begin
        select TO_CHAR (nvl(CSS_ACCT_BAL,'0'), '99999999999999990.99')
        into P_BEGINING_BAL
        from CMS_STMTPRD_SVGACTBAL
        where trunc(CSS_STATMENT_PERIOD)=trunc(V_TRAN_DATE,'month')
        and CSS_ACCT_NO=V_SAVING_ACCT_NO
        and CSS_INST_CODE=P_INST_CODE;
    exception
        when no_data_found then
            P_BEGINING_BAL:='0.00';
        when others then
            V_ERRMSG := 'Error while selecting P_BEGINING_BAL ' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    end;
--En Added for CR - 40 in release 23.1.1

--Sn for selecting Trans Date
   IF v_savacct_balenq_date IS NULL THEN   --Added for transactionlog Functional Removal Phase-II changes
        BEGIN
            SELECT to_char(to_date(max(BUSINESS_DATE),'yyyymmdd'),'mm/dd/yyyy')
            INTO P_BUSINESS_DATE from  TRANSACTIONLOG_VW
            where ((DELIVERY_CHANNEL ='10' and TXN_CODE='22') or
               (DELIVERY_CHANNEL ='07' and TXN_CODE='13'))--Modified for CR - 40 in release 23.1.1
            and  RESPONSE_CODE='00'
            and CUSTOMER_CARD_NO = v_hash_pan;  --GETHASH(P_PAN_CODE); Modified by Pankaj S. during DFCCSD-70(Review) changes
            --order by BUSINESS_DATE;
        --P_RESP_CODE := '1'; --Commented for CR - 40 in release 23.1.1
        --P_RESMSG := 'SUCCESS'; --Commented for CR - 40 in release 23.1.1
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_ERRMSG  := 'Cannot get the Transaction Date Null Details of the Card' ||P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '21';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_ERRMSG  := 'Problem in Getting Transaction Date Details of the Card' ||P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69';
            RAISE EXP_REJECT_RECORD;
         END;
   ELSE
      P_BUSINESS_DATE:=to_char(v_savacct_balenq_date,'mm/dd/yyyy');   --Added for transactionlog Functional Removal Phase-II changes
   END IF;
 --En for selecting Trans Date

     --ST Get responce code fomr master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO P_RESP_CODE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '12'; --Added by Ramesh.A on 08/03/2012
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
           RAISE EXP_REJECT_RECORD;  --Added by Pankaj S. during DFCCSD-70(Review) changes
        END;
      --En Get responce code fomr master

    --Sn update topup card number details in translog
        BEGIN
        
        --Added for VMS-5733/FSP-991

IF (v_Retdate>v_Retperiod)
    THEN

          UPDATE TRANSACTIONLOG
          SET  --RESPONSE_ID=P_RESP_CODE,  --Commented by Pankaj S. During DFCCSD-70(Review) changes
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               ANI=P_ANI, --Added for mantis id 0012275(FSS-1144)
               DNI=P_DNI --Added for mantis id 0012275(FSS-1144)
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
       else
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET  --RESPONSE_ID=P_RESP_CODE,  --Commented by Pankaj S. During DFCCSD-70(Review) changes
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               ANI=P_ANI, --Added for mantis id 0012275(FSS-1144)
               DNI=P_DNI --Added for mantis id 0012275(FSS-1144)
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;    
    end if;
          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
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
     --En update topup card number details in translog
        --Sn Added for transactionlog Functional Removal Phase-II changes
        BEGIN
           UPDATE cms_acct_mast
                   SET cam_savacct_balenq_date = sysdate
            WHERE cam_inst_code = p_inst_code
                 AND cam_acct_no = v_saving_acct_no;
        EXCEPTION
           WHEN OTHERS THEN
              P_RESP_CODE := '21';
              V_ERRMSG :='Error while updating last savg acct balance enquiry dt-' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;
        --En Added for transactionlog Functional Removal Phase-II changes

/*  commented by Ramesh.A on 25/05/2012
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
                CTD_CUSTOMER_CARD_NO_ENCR,
                CTD_MSG_TYPE,
                REQUEST_XML,
                CTD_CUST_ACCT_NUMBER,
                CTD_ADDR_VERIFY_RESPONSE
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
                'Y',
                V_ERRMSG,
                P_RRN,
                P_INST_CODE,
                SYSDATE,
                V_ENCR_PAN_FROM,
                '000',
                '',
                V_SAVING_ACCTNO,
                ''
              );
          EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
            (
              SQLERRM, 1, 300
            )
            ;
            P_RESP_CODE := '69';
              dbms_output.put_line('step in log dtl inside '||P_RESP_CODE||' msg : '||V_ERRMSG);
            RETURN;
          END;
       --En Inserting data in transactionlog dtl
       */
--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN EXP_AUTH_REJECT_RECORD THEN   -- Added by Ramesh.A on 25/05/2012
 --ROLLBACK TO V_AUTH_SAVEPOINT; Commented by Besky on 10-nov-12
P_RESMSG:=V_ERRMSG;  --Added by Besky on 10-nov-12
WHEN EXP_REJECT_RECORD THEN
 ROLLBACK ;--TO V_AUTH_SAVEPOINT;--Modified for CR - 40 in release 23.1.1

      v_resp_cde:=P_RESP_CODE;--added by Pankaj S. for 10871 (to logging proper response_id in txnlog)

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

     --P_RESMSG:=V_ERRMSG; --Added for CR - 40 in release 23.1.1  --commented here & move down during DFCCSD-70(Review) changes

   --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc
           INTO v_dr_cr_flag,  v_txn_type,v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_prod_cattype, v_cardstat,
               v_spd_acct_no  --modified by Pankaj S. for DFCCSD-70
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      --below block Commented by Pankaj S. during DFCCSD-70 changes
      /*IF v_acct_type IS NULL THEN
      BEGIN
        SELECT cat_type_code
          INTO v_acct_type
          FROM cms_acct_type
         WHERE cat_inst_code = p_inst_code AND cat_switch_type = v_switch_acct_type;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;*/
      --En added by Pankaj S. for 10871

      --Sn Added by Pankaj S. for DFCCSD-70 changes
      BEGIN
          SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
            INTO v_avail_bal, v_ledger_bal,v_acct_type
            FROM cms_acct_mast
           WHERE cam_inst_code = p_inst_code
             AND cam_acct_no = v_spd_acct_no;

      EXCEPTION
         WHEN OTHERS THEN
          v_avail_bal:=0;
          v_ledger_bal:=0;
      END;
      --Sn Added by Pankaj S. for DFCCSD-70 changes

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
                     ANI,
                     DNI,
                     ADD_INS_DATE,      --Added by ramesh.a on 11/04/2012
                     ADD_INS_USER,     --Added by ramesh.a on 11/04/2012
                     CARDSTATUS,       --Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC, -- FOR Transaction detail report issue
                     RESPONSE_id,
                     --Sn added by Pankaj S. for 10871
                     cr_dr_flag,
                     productid,
                     categoryid,
                     acct_type,
                     time_stamp,
                     --En added by Pankaj S. for 10871
                     --Sn added by Pankaj S. for DFCCSD-70
                     acct_balance,
                     ledger_balance
                     --En added by Pankaj S. for DFCCSD-70
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
                     V_ENCR_PAN_FROM,
                     v_spd_acct_no, --V_SAVING_ACCT_NO, modified by Pankaj S. for DFCCSD-70
                     V_ERRMSG,
                     P_IPADDRESS,
                     P_ANI,
                     P_DNI,
                     SYSDATE,     --Added by ramesh.a on 11/04/2012
                     1,           --Added by ramesh.a on 11/04/2012
                     V_CARDSTAT,   --Added CARDSTATUS insert in transactionlog by srinivasu.k
                     V_TRANS_DESC, -- FOR Transaction detail report issue
                     v_resp_cde, -- P_RESP_CODE, --modified by Pankaj S. for 10871(to logging proper resp id)
                     --Sn added by Pankaj S. for 10871
                     v_dr_cr_flag,
                     v_prod_code,
                     v_prod_cattype,
                     v_acct_type,
                     systimestamp,
                     --En added by Pankaj S. for 10871
                     --Sn added by Pankaj S. for DFCCSD-70
                     v_avail_bal,
                     v_ledger_bal
                     --En added by Pankaj S. for DFCCSD-70
                    );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '12';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
        --RAISE EXP_REJECT_RECORD; --Commented by Pankaj S. during DFCCSD-70(Review) changes
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
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE
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
              V_ENCR_PAN_FROM,
              '000',
              '',
              v_spd_acct_no,--V_SAVING_ACCT_NO, modified by Pankaj S. for DFCCSD-70
              ''
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          --RETURN;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
    P_RESMSG:=V_ERRMSG;  --Commented above & added here during DFCCSD-70(Review) changes
--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK ;--TO V_AUTH_SAVEPOINT;--Modified for CR - 40 in release 23.1.1

       v_resp_cde:=P_RESP_CODE;--added by Pankaj S. for 10871 (to logging proper response_id in txnlog)

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

   --P_RESMSG:=V_ERRMSG; --Added for CR - 40 in release 23.1.1  --commented here & move down during DFCCSD-70(Review) changes

     --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc
           INTO v_dr_cr_flag,  v_txn_type,v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_prod_cattype, v_cardstat,
               v_spd_acct_no  --modified by Pankaj S. for DFCCSD-70
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      --below block Commented by Pankaj S. during DFCCSD-70 changes
      /*IF v_acct_type IS NULL THEN
      BEGIN
        SELECT cat_type_code
          INTO v_acct_type
          FROM cms_acct_type
         WHERE cat_inst_code = p_inst_code AND cat_switch_type = v_switch_acct_type;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;*/
      --En added by Pankaj S. for 10871

       --Sn Added by Pankaj S. for DFCCSD-70 changes
      BEGIN
          SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
            INTO v_avail_bal, v_ledger_bal,v_acct_type
            FROM cms_acct_mast
           WHERE cam_inst_code = p_inst_code
             AND cam_acct_no = v_spd_acct_no;

      EXCEPTION
         WHEN OTHERS THEN
          v_avail_bal:=0;
          v_ledger_bal:=0;
      END;
      --Sn Added by Pankaj S. for DFCCSD-70 changes

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
                       ANI,
                       DNI,
                       ADD_INS_DATE,      --Added by ramesh.a on 11/04/2012
                       ADD_INS_USER,     --Added by ramesh.a on 11/04/2012
                       CARDSTATUS,     --Added CARDSTATUS insert in transactionlog by srinivasu.k
                       TRANS_DESC, -- FOR Transaction detail report issue
                       RESPONSE_id,
                       --Sn added by Pankaj S. for 10871
                       cr_dr_flag,
                       productid,
                       categoryid,
                       acct_type,
                       time_stamp,
                       --En added by Pankaj S. for 10871
                       --Sn added by Pankaj S. for DFCCSD-70
                       acct_balance,
                       ledger_balance
                       --En added by Pankaj S. for DFCCSD-70
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
                       V_ENCR_PAN_FROM,
                       v_spd_acct_no,--V_SAVING_ACCT_NO, modified by Pankaj S. for DFCCSD-70
                       V_ERRMSG,
                       P_IPADDRESS,
                       P_ANI,
                       P_DNI,
                       SYSDATE,     --Added by ramesh.a on 11/04/2012
                       1,           --Added by ramesh.a on 11/04/2012
                       V_CARDSTAT,   --Added CARDSTATUS insert in transactionlog by srinivasu.k
                       V_TRANS_DESC, -- FOR Transaction detail report issue
                       v_resp_cde, -- P_RESP_CODE, --modified by Pankaj S. for 10871(to logging proper resp id)
                       --Sn added by Pankaj S. for 10871
                       v_dr_cr_flag,
                       v_prod_code,
                       v_prod_cattype,
                       v_acct_type,
                       systimestamp,
                       --En added by Pankaj S. for 10871
                       --Sn added by Pankaj S. for DFCCSD-70
                       v_avail_bal,
                       v_ledger_bal
                       --En added by Pankaj S. for DFCCSD-70
                      );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
            --RAISE EXP_REJECT_RECORD; --Commented by Pankaj S. during DFCCSD-70(Review) changes
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
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE
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
              V_ENCR_PAN_FROM,
              '000',
              '',
              v_spd_acct_no,--V_SAVING_ACCT_NO, modified by Pankaj S. for DFCCSD-70
              ''
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
           dbms_output.put_line('step in log dtl outside '||P_RESP_CODE||' msg : '||V_ERRMSG);
          --RETURN; --Commented by Pankaj S. during DFCCSD-70(Review) changes
      END;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption
     P_RESMSG:=V_ERRMSG;  --Commented above & added here during DFCCSD-70(Review) changes
END;
/
show error