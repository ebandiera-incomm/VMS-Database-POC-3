create or replace PROCEDURE        vmscms.SP_SAVINGACCT_INTEREST_POSTING AS
  /*************************************************
     * Created Date     :  24-APR-2012
     * Created By       :  Saravanakumar
     * Purpose          :  For interest posting.
     * Modified By      : Saravanakumar
     * Modified Reason  : Modified for CR - 40 to round the interest amount
     * Modified Date    : 15-Jan-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  18-Jan-2013
     * Build Number     :  CMS3.5.1_RI0023.1_B0003

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  18-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0013

     * Modified by      :  DHINAKARAN B
     * Modified Reason  :  FSS-744
     * Modified Date    :  10-JUN-2013
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :  RI0024.2_B0001

     * Modified by      :  Pankaj S.
     * Modified Reason  :  DFCCSD-70
     * Modified Date    :  23-Aug-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  22-Aug-2013
     * Build Number     :  RI0024.4_B0006

     * Modified By      : Sagar More
     * Modified Date    : 26-Sep-2013
     * Modified For     : LYFEHOST-63
     * Modified Reason  : To fetch saving acct parameter based on product code
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : MageshKumar S
    * Modified For      : FWR-48
    * Modified Date     : 25-July-2014
    * Modified Reason   : GL Mapping changes.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.1_B0001

      
    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	    * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
		
     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
  *************************************************/
  V_FACTOR             NUMBER(30, 10);
  V_COMPOUND_BALANCE   CMS_INTEREST_DETL.CID_INTEREST_AMOUNT%TYPE;
  V_DAILY_ACCRUAL      CMS_INTEREST_DETL.CID_INTEREST_AMOUNT%TYPE;
  V_TYPE_CODE          CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
  V_STATUS_CODE        CMS_ACCT_STAT.CAS_STAT_CODE%TYPE;
  V_RESP_CODE          VARCHAR2(4);
  V_MSG_TYPE           TRANSACTIONLOG.MSGTYPE%TYPE DEFAULT '0200';
  V_RRN1               NUMBER(10) DEFAULT 0;
  V_RRN2               VARCHAR2(15);
  V_MCC_CODE           TRANSACTIONLOG.MCCODE%TYPE;
  V_BUSINESS_DATE      VARCHAR2(10);
  V_TRAN_DATE          DATE;
  V_BUSINESS_TIME      VARCHAR2(10);
  V_TXN_MODE           CMS_FUNC_MAST.CFM_TXN_MODE%TYPE DEFAULT '0';
  V_CURRCODE           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_RVSL_CODE          TRANSACTIONLOG.REVERSAL_CODE%TYPE DEFAULT '00';
  V_AUTH_ID            TRANSACTIONLOG.AUTH_ID%TYPE;
  V_DELIVERY_CHANNEL   CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE DEFAULT '05';
  V_TXN_CODE           CMS_FUNC_MAST.CFM_TXN_CODE%TYPE DEFAULT '13';
  V_PAN_CODE           VARCHAR2(20);
  V_SAVEPOINT          NUMBER DEFAULT 0;
  V_SPENDING_ACCTNO    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_SWITCH_ACCT_TYPE   CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
  V_SWITCH_ACCT_STATUS CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '8';
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_FUNC_CODE          CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_CARD_STATUS        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_QUARTER1           VARCHAR2(4) DEFAULT '0331';
  V_QUARTER2           VARCHAR2(4) DEFAULT '0630';
  V_QUARTER3           VARCHAR2(4) DEFAULT '0930';
  V_QUARTER4           VARCHAR2(4) DEFAULT '1231';
  V_HALFYEARLY1        VARCHAR2(4) DEFAULT '0630';
  V_HALFYEARLY2        VARCHAR2(4) DEFAULT '1231';
  V_YEARLY             VARCHAR2(4) DEFAULT '1231';
  V_POSTING_FLAG       BOOLEAN DEFAULT FALSE;
  V_CURRDAY            VARCHAR2(4);
  V_POSTING_PERIOD     CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
  V_TXN_AMT            CMS_INTEREST_DETL.CID_INTEREST_AMOUNT%TYPE;
  V_INT_AMT_CF         CMS_INTEREST_DETL.CID_INTEREST_AMOUNT%TYPE;--Added for CR - 40 to round the interest amount
  V_PROD_CODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE          CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_DRACCT_NO          CMS_FUNC_PROD.CFP_DRACCT_NO%TYPE;
  V_DR_CR_FLAG         CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_TRAN_DESC          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_NARRATION          CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_TERMINAL_ID        TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_CARD_CURR          CMS_TRANSACTION_LOG_DTL.CTD_BILL_CURR%TYPE;
  V_TXN_TYPE           TRANSACTIONLOG.TXN_TYPE%TYPE;
--  V_GL_ACCT_BAL        CMS_GL_ACCT_MAST.CGA_TRAN_AMT%TYPE;  COMMENTED the GL account Debit entry For JIRA -744 on 07062013
  V_ERR_MSG            VARCHAR2(500);
  EXP_REJECT_RECORD EXCEPTION;
  v_timestamp  timestamp(3); --Added by Pankaj S. for 10871

  p_resp_code  transactionlog.response_code%TYPE;  --Added by Pankaj S. for DFCCSd-70 changes

BEGIN
  V_ERR_MSG := 'OK';

  FOR I IN (SELECT /*DISTINCT*/ CIM_INST_CODE FROM CMS_INST_MAST) LOOP  --distinct commented by Pankaj S. during DFCCSD-70(Review) changes
    BEGIN
     V_SAVEPOINT := V_SAVEPOINT + 1;
     SAVEPOINT V_SAVEPOINT;


       --fn getting tran desc
          BEGIN
           SELECT CTM_TRAN_DESC,
                 CTM_CREDIT_DEBIT_FLAG,
                 DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')
             INTO V_TRAN_DESC, V_DR_CR_FLAG, V_TXN_TYPE
             FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = V_TXN_CODE AND
                 CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                 CTM_INST_CODE = I.CIM_INST_CODE;

          EXCEPTION
            WHEN OTHERS THEN
             V_RESP_CODE := '21';
             V_ERR_MSG   := 'Error while selecting narration' ||
                         SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;


      --SN : Commented to fetch saving acct parameter based on product code LYFEHOST-63

       /*
         BEGIN
           SELECT UPPER(CDP_PARAM_VALUE)
            INTO V_POSTING_PERIOD
            FROM CMS_DFG_PARAM
            WHERE CDP_PARAM_KEY = 'Interest rate posting period' AND
                CDP_INST_CODE = I.CIM_INST_CODE;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_RESP_CODE := '21';
            V_ERR_MSG   := 'Interest rate posting period is not defined for the institution';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_RESP_CODE := '21';
            V_ERR_MSG   := 'Error while selecting Interest rate posting period for the institution' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;



         V_CURRDAY := TO_CHAR(SYSDATE, 'MMDD');

         IF V_POSTING_PERIOD = 'YEARLY' AND V_CURRDAY = V_YEARLY THEN
           V_POSTING_FLAG := TRUE;
         ELSIF V_POSTING_PERIOD = 'HALFYEARLY' AND
              V_CURRDAY IN (V_HALFYEARLY1, V_HALFYEARLY2) THEN
           V_POSTING_FLAG := TRUE;
         ELSIF V_POSTING_PERIOD = 'QUARTERLY' AND
              V_CURRDAY IN (V_QUARTER1, V_QUARTER2, V_QUARTER3, V_QUARTER4) THEN
           V_POSTING_FLAG := TRUE;
         ELSE
           V_POSTING_FLAG := FALSE;
         END IF;

        */

     --EN : Commented to fetch saving acct parameter based on product code LYFEHOST-63

      --IF V_POSTING_FLAG         -- IF Commented to fetch saving acct parameter based on product code LYFEHOST-63
      --THEN

           --Fetching type code for saving account
           BEGIN
            SELECT CAT_TYPE_CODE
              INTO V_TYPE_CODE
              FROM CMS_ACCT_TYPE
             WHERE CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE AND
                  CAT_INST_CODE = I.CIM_INST_CODE;
           EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_RESP_CODE := '21';
              V_ERR_MSG   := 'Type code is not defined for the institution';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              V_ERR_MSG   := 'Error while selecting type code for the institution ' ||
                          SUBSTR(SQLERRM, 1, 200);
              V_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
           END;

           --Fetching status code for saving account
           BEGIN
            SELECT CAS_STAT_CODE
              INTO V_STATUS_CODE
              FROM CMS_ACCT_STAT
             WHERE CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STATUS AND
                  CAS_INST_CODE = I.CIM_INST_CODE;
           EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_ERR_MSG   := 'Status code is not defined for the institution';
              V_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              V_ERR_MSG   := 'Error while selecting status for the institution ' ||
                          SUBSTR(SQLERRM, 1, 200);
              V_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
           END;

           --Fetching saving account with account status is open
           FOR J IN (SELECT CAM_ACCT_ID,
                        CAM_ACCT_NO,
                        CAM_ACCT_BAL,
                        NVL(CAM_INTEREST_AMOUNT, 0) CAM_INTEREST_AMOUNT,
                        CAM_LEDGER_BAL
                    FROM CMS_ACCT_MAST
                    WHERE CAM_TYPE_CODE = V_TYPE_CODE AND
                        CAM_STAT_CODE = V_STATUS_CODE AND
                        CAM_INST_CODE = I.CIM_INST_CODE AND
                        CAM_INTEREST_AMOUNT > 0)
           LOOP

                BEGIN
                  V_SAVEPOINT := V_SAVEPOINT + 1;
                  SAVEPOINT V_SAVEPOINT;

                  BEGIN
                    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD'),
                         TO_CHAR(SYSDATE, 'HH24MISS')
                     INTO V_BUSINESS_DATE, V_BUSINESS_TIME
                     FROM DUAL;
                  EXCEPTION
                    WHEN OTHERS THEN
                     V_RESP_CODE := '12';
                     V_ERR_MSG   := 'Error while selecting date' ||
                                 SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                  END;

                  V_TRAN_DATE := SYSDATE;
                  V_RRN1      := V_RRN1 + 1;
                  V_RRN2      := 'INT000' || V_RRN1;

                  --Fetching spending account details
                  BEGIN
                    --Sn Below query modified by Pankaj S. for DFCCSD-70 to get latest card details only
                    SELECT mm.cap_acct_no, mm.card_encr, mm.cap_card_stat, mm.cap_prod_code,
                           mm.cap_card_type,mm.cap_pan_code,mm.cap_pan_code_encr
                      INTO v_spending_acctno, v_pan_code, v_card_status, v_prod_code,
                           v_card_type,v_hash_pan,v_encr_pan
                      FROM (SELECT   cap_acct_no, fn_dmaps_main (cap_pan_code_encr) card_encr,
                                     cap_card_stat, cap_prod_code, cap_card_type,cap_pan_code,cap_pan_code_encr
                                FROM cms_appl_pan
                               WHERE cap_cust_code =
                                        (SELECT cca_cust_code
                                           FROM cms_cust_acct
                                          WHERE cca_acct_id = j.cam_acct_id
                                            AND cca_inst_code = i.cim_inst_code)
                                 --AND cap_card_stat NOT IN ('0', '9')
                                 AND cap_card_stat NOT IN ('9')
                                 AND cap_addon_stat = 'P'
                                 AND cap_inst_code = i.cim_inst_code
                            ORDER BY cap_pangen_date DESC)mm
                     WHERE ROWNUM = 1;
                    --En Below query modified by Pankaj S. for DFCCSD-70 to get latest card details only
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     V_RESP_CODE := '21';
                     V_ERR_MSG   := 'Account details not defined';
                     RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                     V_RESP_CODE := '12';
                     V_ERR_MSG   := 'Error while selecting spending acct details' ||
                                 SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
                  END;


                  ----------------------------
                  --SN: Added for LYFEHOST-63
                  ----------------------------

                     BEGIN
                       SELECT UPPER(CDP_PARAM_VALUE)
                        INTO V_POSTING_PERIOD
                        FROM CMS_DFG_PARAM
                        WHERE CDP_PARAM_KEY = 'Interest rate posting period'
                        AND   CDP_INST_CODE = I.CIM_INST_CODE
                        and   cdp_prod_code = v_prod_code
                        and   cdp_card_type = v_card_type;
                     EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                        V_RESP_CODE := '21';
                        V_ERR_MSG   := 'Interest rate posting period is not defined for product '||v_prod_code||' and card type '||v_card_type||' and instcode '||I.CIM_INST_CODE;
                        RAISE EXP_REJECT_RECORD;
                       WHEN OTHERS THEN
                        V_RESP_CODE := '21';
                        V_ERR_MSG   := 'Error while selecting Interest rate posting period for product '||v_prod_code||'and card type '||v_card_type||' and instcode '||I.CIM_INST_CODE ||
                                    SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                     END;

                     V_CURRDAY := TO_CHAR(SYSDATE, 'MMDD');

                     IF V_POSTING_PERIOD = 'YEARLY' AND V_CURRDAY = V_YEARLY THEN
                       V_POSTING_FLAG := TRUE;
                     ELSIF V_POSTING_PERIOD = 'HALFYEARLY' AND
                          V_CURRDAY IN (V_HALFYEARLY1, V_HALFYEARLY2) THEN
                       V_POSTING_FLAG := TRUE;
                     ELSIF V_POSTING_PERIOD = 'QUARTERLY' AND
                          V_CURRDAY IN (V_QUARTER1, V_QUARTER2, V_QUARTER3, V_QUARTER4) THEN
                       V_POSTING_FLAG := TRUE;
                     ELSE
                       V_POSTING_FLAG := FALSE;
                     END IF;

                  ----------------------------
                  --EN: Added for LYFEHOST-63
                  ----------------------------

                  IF V_POSTING_FLAG
                  THEN

                      --Sn commented by Pankaj S. during DFCCSD-70(Review) changes
                      /*BEGIN
                        V_HASH_PAN := GETHASH(V_PAN_CODE);
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '12';
                         V_ERR_MSG   := 'Error while converting pan ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      BEGIN
                        V_ENCR_PAN := FN_EMAPS_MAIN(V_PAN_CODE);
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '12';
                         V_ERR_MSG   := 'Error while converting pan ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;*/
                      --En commented by Pankaj S. during DFCCSD-70(Review) changes

                      --Fetching base currency
                      BEGIN
--                        SELECT CIP_PARAM_VALUE
--                         INTO V_CURRCODE
--                         FROM CMS_INST_PARAM
--                        WHERE CIP_INST_CODE = I.CIM_INST_CODE AND
--                             CIP_PARAM_KEY = 'CURRENCY';


                           SELECT TRIM (cbp_param_value)
			    INTO V_CURRCODE 
			    FROM cms_bin_param 
			    WHERE cbp_param_name = 'Currency' AND 
			    cbp_inst_code= I.CIM_INST_CODE 
   		           AND cbp_profile_code = (select  cpc_profile_code 
			   from cms_prod_cattype where cpc_prod_code = v_prod_code
			   and cpc_card_type = v_card_type
			   and cpc_inst_code=I.CIM_INST_CODE );			 

                        IF V_CURRCODE IS NULL THEN
                         V_ERR_MSG   := 'Base currency cannot be null ';
                         V_RESP_CODE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;
                      EXCEPTION
                        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN EXP_REJECT_RECORD THEN
                          RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN NO_DATA_FOUND THEN
                         V_ERR_MSG   := 'Base currency is not defined for the bin profile ';
                         V_RESP_CODE := '21';
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while selecting base currency for bin  ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                    -- SN-Commented for FWR-48
                      --Fetching function code
                    /*  BEGIN
                        SELECT CFM_FUNC_CODE
                         INTO V_FUNC_CODE
                         FROM CMS_FUNC_MAST
                        WHERE CFM_TXN_CODE = V_TXN_CODE AND
                             CFM_TXN_MODE = V_TXN_MODE AND
                             CFM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                             CFM_INST_CODE = I.CIM_INST_CODE;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         V_RESP_CODE := '69';
                         V_ERR_MSG   := 'Function code not defined for txn code ' ||
                                     V_TXN_CODE;
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_RESP_CODE := '69';
                         V_ERR_MSG   := 'Error while selecting function code ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      --Fetching debit account no
                      BEGIN
                        SELECT CFP_DRACCT_NO
                         INTO V_DRACCT_NO
                         FROM CMS_FUNC_PROD
                        WHERE CFP_FUNC_CODE = V_FUNC_CODE AND
                             CFP_PROD_CODE = V_PROD_CODE AND
                             CFP_PROD_CATTYPE = V_CARD_TYPE AND
                             CFP_INST_CODE = I.CIM_INST_CODE;

                        IF TRIM(V_DRACCT_NO) IS NULL THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Debit account cannot be null for a transaction code ' ||
                                     V_TXN_CODE || ' Function code ' ||
                                     V_FUNC_CODE;
                         RAISE EXP_REJECT_RECORD;
                        END IF;
                      EXCEPTION
                        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN EXP_REJECT_RECORD THEN
                         RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN NO_DATA_FOUND THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Debit account no is not defined';
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while selecting debit account no ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END; */

                       -- SN-Commented for FWR-48

                    /* COMMENTED the GL account Debit entry For JIRA -744 on 07062013
                      --Fetching gl account balance
                      BEGIN
                        SELECT NVL(CGA_TRAN_AMT, 0)
                         INTO V_GL_ACCT_BAL
                         FROM CMS_GL_ACCT_MAST
                        WHERE CGA_ACCT_CODE = V_DRACCT_NO AND
                             CGA_INST_CODE = I.CIM_INST_CODE;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'GL account balance is not defined';
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while selecting Gl Acct balance' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;
                      */
                        --Sn Added for CR - 40 to round the interest amount
                         -- V_TXN_AMT := J.CAM_INTEREST_AMOUNT;
                         V_TXN_AMT := ROUND(J.CAM_INTEREST_AMOUNT,2);

                        IF V_TXN_AMT >J.CAM_INTEREST_AMOUNT THEN
                            V_INT_AMT_CF:=0;
                        ELSE
                            V_INT_AMT_CF:=J.CAM_INTEREST_AMOUNT-V_TXN_AMT;
                        END IF;
                        --En Added for CR - 40 to round the interest amount

                  -- Sn - commented for FWR-48
                    /*  BEGIN
                        SP_INS_EODUPDATE_ACCT_CMSAUTH(V_RRN2,
                                                V_TERMINAL_ID,
                                                V_DELIVERY_CHANNEL,
                                                V_TXN_CODE,
                                                V_TXN_MODE,
                                                V_TRAN_DATE,
                                                V_PAN_CODE,
                                                V_DRACCT_NO,
                                                V_TXN_AMT,
                                                'D',
                                                I.CIM_INST_CODE,
                                                V_ERR_MSG);

                        IF V_ERR_MSG <> 'OK' THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH' ||
                                     V_ERR_MSG;
                         RAISE EXP_REJECT_RECORD;
                        END IF;
                      EXCEPTION
                        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN EXP_REJECT_RECORD THEN
                         RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH' ||
                                     SUBSTR(SQLERRM, 1, 250);
                         RAISE EXP_REJECT_RECORD;
                      END; */

                       -- En - commented for FWR-48

                      BEGIN
                        --                            SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
                        SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
                         INTO V_AUTH_ID
                         FROM DUAL;
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_ERR_MSG   := 'Error while generating authid ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         V_RESP_CODE := '21';
                         RAISE EXP_REJECT_RECORD;
                      END;

                      BEGIN
                        --SELECT CTM_TRAN_DESC,
                          --   CTM_CREDIT_DEBIT_FLAG,
                           --  DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')
                         --INTO V_TRAN_DESC, V_DR_CR_FLAG, V_TXN_TYPE
                         --FROM CMS_TRANSACTION_MAST
                        --WHERE CTM_TRAN_CODE = V_TXN_CODE AND
                         --    CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                          --   CTM_INST_CODE = I.CIM_INST_CODE;

                        IF TRIM(V_TRAN_DESC) IS NOT NULL THEN
                         V_NARRATION := V_TRAN_DESC || '/';
                        END IF;

                        IF TRIM(V_AUTH_ID) IS NOT NULL THEN
                         V_NARRATION := V_NARRATION || V_AUTH_ID || '/';
                        END IF;

                        IF TRIM(V_DRACCT_NO) IS NOT NULL THEN
                         V_NARRATION := V_NARRATION || V_DRACCT_NO || '/';
                        END IF;

                        IF TRIM(V_BUSINESS_DATE) IS NOT NULL THEN
                         V_NARRATION := V_NARRATION || V_BUSINESS_DATE;
                        END IF;

                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error while selecting narration' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      v_timestamp:=systimestamp;  --added by Pankaj S. for 10871
                    /* COMMENTED the GL account Debit entry For JIRA -744 on 07062013
                      BEGIN
                        INSERT INTO CMS_STATEMENTS_LOG
                         (CSL_PAN_NO,
                          CSL_ACCT_NO,
                          CSL_OPENING_BAL,
                          CSL_TRANS_AMOUNT,
                          CSL_TRANS_TYPE,
                          CSL_TRANS_DATE,
                          CSL_CLOSING_BALANCE,
                          CSL_TRANS_NARRRATION,
                          CSL_PAN_NO_ENCR,
                          CSL_RRN,
                          CSL_AUTH_ID,
                          CSL_BUSINESS_DATE,
                          CSL_BUSINESS_TIME,
                          TXN_FEE_FLAG,
                          CSL_DELIVERY_CHANNEL,
                          CSL_INST_CODE,
                          CSL_TXN_CODE,
                          CSL_INS_DATE,
                          CSL_INS_USER,
                          CSL_PANNO_LAST4DIGIT, -- Added by Ramesh.A on 06/07/2012);
                          --Sn added by Pankaj S. for 10871
                          csl_acct_type,
                          csl_prod_code,
                          csl_time_stamp
                          --En added by Pankaj S. for 10871
                          )
                        VALUES
                         (V_HASH_PAN,
                          V_DRACCT_NO,
                          V_GL_ACCT_BAL,
                          V_TXN_AMT,
                          'DR',
                          V_TRAN_DATE,
                          V_GL_ACCT_BAL - V_TXN_AMT,
                          V_NARRATION,
                          V_ENCR_PAN,
                          V_RRN2,
                          V_AUTH_ID,
                          V_BUSINESS_DATE,
                          V_BUSINESS_TIME,
                          'N',
                          V_DELIVERY_CHANNEL,
                          I.CIM_INST_CODE,
                          V_TXN_CODE,
                          SYSDATE,
                          1,
                          (SUBSTR(V_PAN_CODE,
                                LENGTH(V_PAN_CODE) - 3,
                                LENGTH(V_PAN_CODE))), -- Added by Ramesh.A on 06/07/2012
                          --Sn added by Pankaj S. for 10871
                          v_type_code,
                          v_prod_code,
                          v_timestamp
                          --En added by Pankaj S. for 10871
                          );
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error creating entry in statement log ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;
                      */
                      BEGIN
                        UPDATE CMS_ACCT_MAST
                          /*SET CAM_ACCT_BAL        = CAM_ACCT_BAL +
                                               CAM_INTEREST_AMOUNT,
                             CAM_LEDGER_BAL      = CAM_LEDGER_BAL +
                                               CAM_INTEREST_AMOUNT,
                             CAM_INTEREST_AMOUNT = 0,*/
                          --Sn Modified for CR - 40 to round the interest amount
                          SET CAM_ACCT_BAL        = CAM_ACCT_BAL +
                                               V_TXN_AMT,
                             CAM_LEDGER_BAL      = CAM_LEDGER_BAL +
                                               V_TXN_AMT,
                             CAM_INTEREST_AMOUNT = V_INT_AMT_CF,
                          --En Modified for CR - 40 to round the interest amount
                             CAM_LUPD_DATE       = SYSDATE,
                             CAM_LUPD_USER       = 1
                        WHERE CAM_ACCT_NO = J.CAM_ACCT_NO AND
                             CAM_INST_CODE = I.CIM_INST_CODE;

                        IF SQL%ROWCOUNT = 0 THEN
                         V_ERR_MSG   := 'Interest amount is not updated';
                         V_RESP_CODE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;
                      EXCEPTION
                        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN EXP_REJECT_RECORD THEN
                        RAISE;
                        --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN OTHERS THEN
                         V_ERR_MSG   := 'Error while updating interest amount ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         V_RESP_CODE := '21';
                         RAISE EXP_REJECT_RECORD;
                      END;

                      BEGIN
                        INSERT INTO CMS_STATEMENTS_LOG
                         (CSL_PAN_NO,
                          CSL_ACCT_NO,
                          CSL_OPENING_BAL,
                          CSL_TRANS_AMOUNT,
                          CSL_TRANS_TYPE,
                          CSL_TRANS_DATE,
                          CSL_CLOSING_BALANCE,
                          CSL_TRANS_NARRRATION,
                          CSL_PAN_NO_ENCR,
                          CSL_RRN,
                          CSL_AUTH_ID,
                          CSL_BUSINESS_DATE,
                          CSL_BUSINESS_TIME,
                          TXN_FEE_FLAG,
                          CSL_DELIVERY_CHANNEL,
                          CSL_INST_CODE,
                          CSL_TXN_CODE,
                          CSL_INS_DATE,
                          CSL_INS_USER,
                          CSL_PANNO_LAST4DIGIT, -- Added by Ramesh.A on 06/07/2012);
                          --Sn added by Pankaj S. for 10871
                          csl_acct_type,
                          csl_prod_code,
                          csl_card_type,
                          csl_time_stamp
                          --En added by Pankaj S. for 10871
                          )
                        VALUES
                         (V_HASH_PAN,
                          J.CAM_ACCT_NO,
                          j.cam_ledger_bal, --j.CAM_ACCT_BAL repalced by Pankaj S with j.cam_ledger_bal for 10871
                          V_TXN_AMT,
                          'CR',
                          V_TRAN_DATE,
                          j.cam_ledger_bal + V_TXN_AMT, --j.CAM_ACCT_BAL repalced by Pankaj S with j.cam_ledger_bal for 10871
                          V_NARRATION,
                          V_ENCR_PAN,
                          V_RRN2,
                          V_AUTH_ID,
                          V_BUSINESS_DATE,
                          V_BUSINESS_TIME,
                          'N',
                          V_DELIVERY_CHANNEL,
                          I.CIM_INST_CODE,
                          V_TXN_CODE,
                          SYSDATE,
                          1,
                          (SUBSTR(V_PAN_CODE,
                                LENGTH(V_PAN_CODE) - 3,
                                LENGTH(V_PAN_CODE))), -- Added by Ramesh.A on 06/07/2012);
                          --Sn added by Pankaj S. for 10871
                          v_type_code,
                          v_prod_code,
                          v_card_type,
                          v_timestamp
                          --En added by Pankaj S. for 10871
                          );
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Error creating entry in statement log ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      V_RESP_CODE := 1;
                      V_ERR_MSG   := 'Interest rate posted successfuly';

                      BEGIN
                        SELECT CMS_ISO_RESPCDE
                         INTO V_RESP_CODE
                         FROM CMS_RESPONSE_MAST
                        WHERE CMS_INST_CODE = I.CIM_INST_CODE AND
                             CMS_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                             CMS_RESPONSE_ID = V_RESP_CODE;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         V_RESP_CODE := '21';
                         V_ERR_MSG   := 'Responce code not found ' || V_RESP_CODE;
                         RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS THEN
                         V_RESP_CODE := '69';
                         V_ERR_MSG   := 'Problem while selecting data from response master ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                          RAISE EXP_REJECT_RECORD;  --Added by Pankaj S. during DFCCSD-70(Review) changes
                      END;

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
                          BANK_CODE,
                          TOTAL_AMOUNT,
                          MCCODE,
                          CURRENCYCODE,
                          PRODUCTID,
                          CATEGORYID,
                          AUTH_ID,
                          TRANS_DESC,
                          AMOUNT,
                          INSTCODE,
                          CR_DR_FLAG,
                          CUSTOMER_CARD_NO_ENCR,
                          REVERSAL_CODE,
                          CUSTOMER_ACCT_NO,
                          ACCT_BALANCE,
                          LEDGER_BALANCE,
                          RESPONSE_ID,
                          ADD_INS_DATE,
                          ADD_INS_USER,
                          CARDSTATUS,
                          ERROR_MSG,
                          --Sn added by Pankaj S. for 10871
                          acct_type,
                          time_stamp
                          --En added by Pankaj S. for 10871
                          )
                        VALUES
                         (V_MSG_TYPE,
                          V_RRN2,
                          V_DELIVERY_CHANNEL,
                          V_TERMINAL_ID,
                          V_TRAN_DATE,
                          V_TXN_CODE,
                          V_TXN_TYPE,
                          V_TXN_MODE,
                          DECODE(V_RESP_CODE, '00', 'C', 'F'),
                          V_RESP_CODE,
                          V_BUSINESS_DATE,
                          V_BUSINESS_TIME,
                          V_HASH_PAN,
                          I.CIM_INST_CODE,
                          trim(to_char(V_TXN_AMT,'99999999999999990.99')),  --formated by Pankaj S. for 10871
                          V_MCC_CODE,
                          V_CURRCODE,
                          V_PROD_CODE,
                          V_CARD_TYPE,
                          V_AUTH_ID,
                          V_TRAN_DESC,
                          trim(to_char(V_TXN_AMT,'99999999999999990.99')),  --formated by Pankaj S. for 10871
                          I.CIM_INST_CODE,
                          V_DR_CR_FLAG,
                          V_ENCR_PAN,
                          V_RVSL_CODE,
                          J.CAM_ACCT_NO,
                          J.CAM_ACCT_BAL+ V_TXN_AMT,
                          J.CAM_LEDGER_BAL+ V_TXN_AMT,
                          '1',--V_RESP_CODE, modified by Pankaj S. for 10871 (To log proper response ID)
                          SYSDATE,
                          1,
                          V_CARD_STATUS,
                          V_ERR_MSG,
                          --Sn added by Pankaj S. for 10871
                          v_type_code,
                          v_timestamp
                          --En added by Pankaj S. for 10871
                          );
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '99';
                         V_ERR_MSG   := 'Error while inserting transactionlog ' ||
                                     SUBSTR(SQLERRM, 1, 300);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      BEGIN
                        INSERT INTO CMS_TRANSACTION_LOG_DTL
                         (CTD_DELIVERY_CHANNEL,
                          CTD_TXN_CODE,
                          CTD_TXN_TYPE,
                          CTD_TXN_MODE,
                          CTD_BUSINESS_DATE,
                          CTD_BUSINESS_TIME,
                          CTD_CUSTOMER_CARD_NO,
                          CTD_TXN_AMOUNT,
                          CTD_TXN_CURR,
                          CTD_ACTUAL_AMOUNT,
                          CTD_BILL_AMOUNT,
                          CTD_BILL_CURR,
                          CTD_PROCESS_FLAG,
                          CTD_PROCESS_MSG,
                          CTD_RRN,
                          CTD_CUSTOMER_CARD_NO_ENCR,
                          CTD_MSG_TYPE,
                          CTD_CUST_ACCT_NUMBER,
                          CTD_INST_CODE,
                          CTD_INS_DATE,
                          CTD_INS_USER)
                        VALUES
                         (V_DELIVERY_CHANNEL,
                          V_TXN_CODE,
                          V_TXN_TYPE,
                          V_TXN_MODE,
                          V_BUSINESS_DATE,
                          V_BUSINESS_TIME,
                          V_HASH_PAN,
                          V_TXN_AMT,
                          V_CURRCODE,
                          V_TXN_AMT,
                          V_TXN_AMT,
                          V_CARD_CURR,
                          'Y',
                          'Successful',
                          V_RRN2,
                          V_ENCR_PAN,
                          V_MSG_TYPE,
                          J.CAM_ACCT_NO,
                          I.CIM_INST_CODE,
                          SYSDATE,
                          1);
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESP_CODE := '99';
                         V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

                      --Moving the data to history table
                      BEGIN
                        INSERT INTO CMS_INTEREST_DETL_HIST
                         (SELECT * FROM CMS_INTEREST_DETL);

--                         --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
--                         IF SQL%ROWCOUNT = 0 THEN
--                         V_ERR_MSG   := 'No records inserted into itrest dtl';
--                         V_RESP_CODE := '21';
--                         RAISE EXP_REJECT_RECORD;
--                         END IF;
--                         --En Added by Pankaj S. during DFCCSD-70(Review) changes

                        --Below statement commented here  and used down during DFCCSD-70(Review) changes
                        truncate_tab_ebr ('CMS_INTEREST_DETL');
                      EXCEPTION
                      --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
                      WHEN EXP_REJECT_RECORD THEN
                       RAISE;
                       --En Added by Pankaj S. during DFCCSD-70(Review) changes
                        WHEN OTHERS THEN
                         V_RESP_CODE := '99';
                         V_ERR_MSG   := 'Error while inserting cms_interest_detl_hist ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_REJECT_RECORD;
                      END;

--                      --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
--                      BEGIN
--                       truncate_tab_ebr ('CMS_INTEREST_DETL');
--                      EXCEPTION
--                        WHEN OTHERS THEN
--                         V_RESP_CODE := '99';
--                         V_ERR_MSG   := 'Error while truncating cms_interest_detl-' ||SUBSTR(SQLERRM, 1, 200);
--                         RAISE EXP_REJECT_RECORD;
--                      END;
--                      --En Added by Pankaj S. during DFCCSD-70(Review) changes
--

                   END IF;

                EXCEPTION
                  --Inner loop
                  WHEN EXP_REJECT_RECORD THEN
                    ROLLBACK TO V_SAVEPOINT;

                    --Sn Added by Pankaj S. for DFCCSD-70 changes
                      --Sn Get responce code fomr master
                      BEGIN
                        SELECT cms_iso_respcde
                          INTO p_resp_code
                          FROM cms_response_mast
                         WHERE cms_inst_code = i.cim_inst_code
                           AND cms_delivery_channel = v_delivery_channel
                           AND cms_response_id = v_resp_code;
                      EXCEPTION
                         WHEN OTHERS THEN
                            v_err_msg :='Problem while selecting data from response master '|| p_resp_code || SUBSTR (SQLERRM, 1, 300);
                            v_resp_code := '69';
                            --RAISE exp_reject_record;
                      END;
                      --En Get responce code fomr master

                      --Sn added by Pankaj S. for 10871
                      IF v_dr_cr_flag IS NULL THEN
                      BEGIN
                        SELECT ctm_credit_debit_flag,
                               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
                          INTO v_dr_cr_flag,
                               v_txn_type, v_tran_desc
                          FROM cms_transaction_mast
                         WHERE ctm_tran_code = v_txn_code
                           AND ctm_delivery_channel = v_delivery_channel
                           AND ctm_inst_code = i.cim_inst_code;
                      EXCEPTION
                         WHEN OTHERS THEN
                            NULL;
                      END;
                      END IF;

                      IF v_prod_code is NULL THEN
                      BEGIN
                        SELECT mm.card_no, mm.cap_card_stat, mm.cap_prod_code,
                               mm.cap_card_type
                          INTO v_pan_code, v_card_status, v_prod_code,
                               v_card_type
                          FROM (SELECT   cap_acct_no, fn_dmaps_main (cap_pan_code_encr) card_no,
                                         cap_card_stat, cap_prod_code, cap_card_type
                                    FROM cms_appl_pan
                                   WHERE cap_cust_code =
                                            (SELECT cca_cust_code
                                               FROM cms_cust_acct
                                              WHERE cca_acct_id = j.cam_acct_id
                                                AND cca_inst_code = i.cim_inst_code)
                                     --AND cap_card_stat NOT IN ('0', '9')
                                     AND cap_card_stat NOT IN ('9')
                                     AND cap_addon_stat = 'P'
                                     AND cap_inst_code = i.cim_inst_code
                                ORDER BY cap_pangen_date DESC)mm
                         WHERE ROWNUM = 1;
                      EXCEPTION
                         WHEN OTHERS THEN
                            NULL;
                      END;
                      END IF;

                     --Sn Inserting data in transactionlog
                     BEGIN
                     INSERT INTO transactionlog
                                 (msgtype, rrn, delivery_channel, date_time, txn_code,
                                  txn_type, txn_mode, txn_status, response_code, business_date,
                                  business_time, customer_card_no, instcode,cr_dr_flag,
                                  customer_card_no_encr, customer_acct_no, error_msg, cardstatus,
                                  trans_desc, productid, categoryid, response_id, acct_type,
                                  acct_balance, ledger_balance,amount,total_amount,
                                  time_stamp --Added by Pankaj S. during DFCCSD-70(Review) changes
                                 )
                          VALUES (v_msg_type, v_rrn2, v_delivery_channel, SYSDATE, v_txn_code,
                                  v_txn_type, v_txn_mode, 'F', p_resp_code, v_business_date,
                                  v_business_time, v_hash_pan, i.cim_inst_code,v_dr_cr_flag,
                                  v_encr_pan, j.cam_acct_no, v_err_msg, v_card_status,
                                  v_tran_desc, v_prod_code, v_card_type, v_resp_code, v_type_code,
                                  j.cam_acct_bal, j.cam_ledger_bal,'0.00','0.00',
                                  systimestamp --Added by Pankaj S. during DFCCSD-70(Review) changes
                                 );
                     EXCEPTION
                        WHEN OTHERS THEN
                           v_resp_code := '12';
                           v_err_msg :='Exception while inserting to transaction log '|| SQLCODE|| '---'|| SQLERRM;
                           --RAISE exp_reject_record;
                     END;
                    --En Inserting data in transactionlog
                    --En Added by Pankaj S. for DFCCSD-70 changes

                    BEGIN
                     INSERT INTO CMS_TRANSACTION_LOG_DTL
                       (CTD_DELIVERY_CHANNEL,
                        CTD_TXN_CODE,
                        CTD_TXN_TYPE,
                        CTD_TXN_MODE,
                        CTD_BUSINESS_DATE,
                        CTD_BUSINESS_TIME,
                        CTD_CUSTOMER_CARD_NO,
                        CTD_PROCESS_FLAG,
                        CTD_PROCESS_MSG,
                        CTD_RRN,
                        CTD_INST_CODE,
                        CTD_INS_DATE,
                        CTD_INS_USER,
                        CTD_CUSTOMER_CARD_NO_ENCR,
                        CTD_MSG_TYPE,
                        CTD_CUST_ACCT_NUMBER)
                     VALUES
                       (V_DELIVERY_CHANNEL,
                        V_TXN_CODE,
                        1,
                        V_TXN_MODE,
                        V_BUSINESS_DATE,
                        V_BUSINESS_TIME,
                        V_HASH_PAN,
                        'E',
                        V_ERR_MSG,
                        V_RRN2,
                        I.CIM_INST_CODE,
                        SYSDATE,
                        1,
                        V_ENCR_PAN,
                        '000',
                        J.CAM_ACCT_NO);
                    EXCEPTION
                     WHEN OTHERS THEN
                       V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl' ||
                                   SUBSTR(SQLERRM, 1, 200);
                       V_RESP_CODE := '69';
                    END;

                  WHEN OTHERS THEN
                    V_ERR_MSG := 'Exception in inner loop' ||
                              SUBSTR(SQLERRM, 1, 200);
                    ROLLBACK TO V_SAVEPOINT;

                    --Sn Added by Pankaj S. for DFCCSD-70 changes
                      v_resp_code:='21';
                      --Sn Get responce code fomr master
                      BEGIN
                        SELECT cms_iso_respcde
                          INTO p_resp_code
                          FROM cms_response_mast
                         WHERE cms_inst_code = i.cim_inst_code
                           AND cms_delivery_channel = v_delivery_channel
                           AND cms_response_id = v_resp_code;
                      EXCEPTION
                         WHEN OTHERS THEN
                            v_err_msg :='Problem while selecting data from response master '|| p_resp_code || SUBSTR (SQLERRM, 1, 300);
                            v_resp_code := '69';
                            --RAISE exp_reject_record;
                      END;
                      --En Get responce code fomr master

                      --Sn added by Pankaj S. for 10871
                      IF v_dr_cr_flag IS NULL THEN
                      BEGIN
                        SELECT ctm_credit_debit_flag,
                               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
                          INTO v_dr_cr_flag,
                               v_txn_type, v_tran_desc
                          FROM cms_transaction_mast
                         WHERE ctm_tran_code = v_txn_code
                           AND ctm_delivery_channel = v_delivery_channel
                           AND ctm_inst_code = i.cim_inst_code;
                      EXCEPTION
                         WHEN OTHERS THEN
                            NULL;
                      END;
                      END IF;

                      IF v_prod_code is NULL THEN
                      BEGIN
                        SELECT mm.card_no, mm.cap_card_stat, mm.cap_prod_code,
                               mm.cap_card_type
                          INTO v_pan_code, v_card_status, v_prod_code,
                               v_card_type
                          FROM (SELECT   cap_acct_no, fn_dmaps_main (cap_pan_code_encr) card_no,
                                         cap_card_stat, cap_prod_code, cap_card_type
                                    FROM cms_appl_pan
                                   WHERE cap_cust_code =
                                            (SELECT cca_cust_code
                                               FROM cms_cust_acct
                                              WHERE cca_acct_id = j.cam_acct_id
                                                AND cca_inst_code = i.cim_inst_code)
                                     --AND cap_card_stat NOT IN ('0', '9')
                                     AND cap_card_stat NOT IN ('9')
                                     AND cap_addon_stat = 'P'
                                     AND cap_inst_code = i.cim_inst_code
                                ORDER BY cap_pangen_date DESC)mm
                         WHERE ROWNUM = 1;
                      EXCEPTION
                         WHEN OTHERS THEN
                            NULL;
                      END;
                      END IF;

                     --Sn Inserting data in transactionlog
                     BEGIN
                     INSERT INTO transactionlog
                                 (msgtype, rrn, delivery_channel, date_time, txn_code,
                                  txn_type, txn_mode, txn_status, response_code, business_date,
                                  business_time, customer_card_no, instcode,cr_dr_flag,
                                  customer_card_no_encr, customer_acct_no, error_msg, cardstatus,
                                  trans_desc, productid, categoryid, response_id, acct_type,
                                  acct_balance, ledger_balance,amount,total_amount,
                                  time_stamp --Added by Pankaj S. during DFCCSD-70(Review) changes
                                 )
                          VALUES (v_msg_type, v_rrn2, v_delivery_channel, SYSDATE, v_txn_code,
                                  v_txn_type, v_txn_mode, 'F', p_resp_code, v_business_date,
                                  v_business_time, v_hash_pan, i.cim_inst_code,v_dr_cr_flag,
                                  v_encr_pan, j.cam_acct_no, v_err_msg, v_card_status,
                                  v_tran_desc, v_prod_code, v_card_type, v_resp_code, v_type_code,
                                  j.cam_acct_bal, j.cam_ledger_bal,'0.00','0.00',
                                  systimestamp --Added by Pankaj S. during DFCCSD-70(Review) changes
                                 );
                     EXCEPTION
                        WHEN OTHERS THEN
                           v_resp_code := '12';
                           v_err_msg :='Exception while inserting to transaction log '|| SQLCODE|| '---'|| SQLERRM;
                           --RAISE exp_reject_record;
                     END;
                    --En Inserting data in transactionlog
                    --En Added by Pankaj S. for DFCCSD-70 changes

                    BEGIN
                     INSERT INTO CMS_TRANSACTION_LOG_DTL
                       (CTD_DELIVERY_CHANNEL,
                        CTD_TXN_CODE,
                        CTD_TXN_TYPE,
                        CTD_TXN_MODE,
                        CTD_BUSINESS_DATE,
                        CTD_BUSINESS_TIME,
                        CTD_CUSTOMER_CARD_NO,
                        CTD_PROCESS_FLAG,
                        CTD_PROCESS_MSG,
                        CTD_RRN,
                        CTD_INST_CODE,
                        CTD_INS_DATE,
                        CTD_INS_USER,
                        CTD_CUSTOMER_CARD_NO_ENCR,
                        CTD_MSG_TYPE,
                        CTD_CUST_ACCT_NUMBER)
                     VALUES
                       (V_DELIVERY_CHANNEL,
                        V_TXN_CODE,
                        1,
                        V_TXN_MODE,
                        V_BUSINESS_DATE,
                        V_BUSINESS_TIME,
                        V_HASH_PAN,
                        'E',
                        V_ERR_MSG,
                        V_RRN2,
                        I.CIM_INST_CODE,
                        SYSDATE,
                        1,
                        V_ENCR_PAN,
                        '000',
                        J.CAM_ACCT_NO);
                    EXCEPTION
                     WHEN OTHERS THEN
                       V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl' ||
                                   SUBSTR(SQLERRM, 1, 200);
                       V_RESP_CODE := '69';
                    END;

                END;

           END LOOP;


       --END IF;  -- IF Commented to fetch saving acct parameter based on product code LYFEHOST-63

    EXCEPTION
     --Ourter loop
     WHEN EXP_REJECT_RECORD THEN
       BEGIN
        INSERT INTO CMS_TRANSACTION_LOG_DTL
          (CTD_DELIVERY_CHANNEL,
           CTD_TXN_CODE,
           CTD_TXN_TYPE,
           CTD_TXN_MODE,
           CTD_BUSINESS_DATE,
           CTD_BUSINESS_TIME,
           CTD_CUSTOMER_CARD_NO,
           CTD_PROCESS_FLAG,
           CTD_PROCESS_MSG,
           CTD_RRN,
           CTD_INST_CODE,
           CTD_INS_DATE,
           CTD_INS_USER,
           CTD_CUSTOMER_CARD_NO_ENCR,
           CTD_MSG_TYPE)
        VALUES
          (V_DELIVERY_CHANNEL,
           V_TXN_CODE,
           1,
           V_TXN_MODE,
           V_BUSINESS_DATE,
           V_BUSINESS_TIME,
           V_HASH_PAN,
           'E',
           V_ERR_MSG,
           V_RRN2,
           I.CIM_INST_CODE,
           SYSDATE,
           1,
           V_ENCR_PAN,
           '000');
       EXCEPTION
        WHEN OTHERS THEN
          V_ERR_MSG   := 'Error while inserting cms_transaction_log_dtl' ||
                      SUBSTR(SQLERRM, 1, 200);
          V_RESP_CODE := '69';
       END;
     WHEN OTHERS THEN
       V_ERR_MSG := 'Exception in outer loop' || SUBSTR(SQLERRM, 1, 200);
    END;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    V_ERR_MSG := 'Exception in main' || SUBSTR(SQLERRM, 1, 200);
END;

/
show error;
