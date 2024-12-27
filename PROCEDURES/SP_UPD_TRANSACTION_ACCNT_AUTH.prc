create or replace
PROCEDURE          VMSCMS.SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE   NUMBER,
                                                        P_TRAN_DATE            DATE,
                                                        P_PROD_CODE            VARCHAR2,
                                                        P_PROD_CATTYPE         VARCHAR2,
                                                        P_TRAN_AMT             NUMBER,
                                                        P_FUNC_CODE            VARCHAR2,
                                                        P_TXN_CODE             VARCHAR2,
                                                        P_TRAN_TYPE            VARCHAR2,
                                                        P_RRN                  VARCHAR2,
                                                        P_TERMINAL_ID          VARCHAR,
                                                        P_DELIVERY_CHANNEL     VARCHAR2,
                                                        P_TXN_MODE             VARCHAR2,
                                                        P_CARD_NO              VARCHAR2,
                                                        P_FEE_CODE             VARCHAR2,
                                                        P_FEE_AMT              NUMBER,
                                                        P_FEE_CRACCT_NO        VARCHAR2,
                                                        P_FEE_DRACCT_NO        VARCHAR2,
                                                        P_SERVICETAX_CALCFLAG  VARCHAR2,
                                                        P_CESS_CALCFLAG        VARCHAR2,
                                                        P_SERVICETAX_AMOUNT    NUMBER,
                                                        P_SERVICETAX_CRACCT_NO VARCHAR2,
                                                        P_SERVICETAX_DRACCT_NO VARCHAR2,
                                                        P_CESS_AMOUNT          NUMBER,
                                                        P_CESS_CRACCT_NO       VARCHAR2,
                                                        P_CESS_DRACCT_NO       VARCHAR2,
                                                        P_CARD_ACCT_NO         VARCHAR2,
                                                        P_PREAUTH_AMNT         VARCHAR2,
                                                        P_MSG                  VARCHAR2,
                                                        P_RESP_CDE             OUT VARCHAR2,
                                                        P_ERR_MSG              OUT VARCHAR2,
                                                        P_REVERSE_FEE          NUMBER DEFAULT 0) IS --Added for FSS 837
 /*************************************************
     * Created Date     :  10-Dec-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For transaction account auth
     * Modified For     :  Internal Enhancement
     * Modified Date    :  28-Nov-2012
     * Modified Reason  :  Space added between error message and P_FUNC_CODE variable
     * Reviewer         :  NA
     * Reviewed Date    :
     * Build Number     :  RI0023_B0003

     * Modified By      :  Deepa T
     * Modified For     :  Mantis Id: 12296 ,Code Review Comments
     * Modified Date    :  12-Sep-2013,17-Sep-2013
     * Modified Reason  :  OLS Changes to support the adjustment
     *                     transaction for Preauth with message type 1120
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.3.8_B0001

     * Modified By      :  Siva Kumar M
     * Modified For     :  Mantis Id: 13787
     * Modified Date    :  05-Mar-2014
     * Modified Reason  :  ACH performance issue
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  05-Mar-2014
     * Build Number     :  RI0027.2_B0001

	 * Modified by       :  Abdul Hameed M.A
      * Modified Reason  :  To hold the Preauth completion fee at the time of preauth
      * Modified for     :  FSS 837
      * Modified Date    :  27-JUNE-2014
      * Reviewer         :  spankaj
      * Build Number     :  RI0027.3_B0001

     * Modified By      :  Mageshkumar S
     * Modified For     :  FWR-48
     * Modified Date    :  25-July-2014
     * Modified Reason  :  GL Mapping changes.
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0001

     * Modified By      :  Siva Kumar M
     * Modified For     :  Mantis id:16168
     * Modified Date    :  31-Aug-2015
     * Modified Reason  :  to update initial load amount
     * Reviewer         :  Saravana kumar
     * Build Number     :  RI0027.3.1_B0008

     * Modified By      :  Ramesh A
     * Modified For     :  FSS-3679
     * Modified Date    :  07-OCT-2015
     * Modified Reason  :  To reverse fee amount
     * Reviewer         :  Saravana kumar
     * Build Number     :   VMSGPRHOST_3.1.2_B0001
	 
	 * Modified By      : PUVANESH.N
     * Modified Date    : 07-SEP-2021
     * Purpose          : VMS-4652 - AC 2: Settlement file for MoneySend credit transaction
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R51 - BUILD 2 
     
     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 21-SEP-2021
     * Purpose          : VMS-3366 - Dormancy Fee Helath Care on Load date
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R52 - BUILD 1
     
     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 25-NOV-2021
     * Purpose          : VMS-5327 - Dormancy Fee Helath Care on Load date VIA V2
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R55 BUILD 3
	 
	 * Modified By      : Mohan Kumar E
     * Modified Date    : 24-JULY-2023
     * Purpose          : VMS-7196 - Funding on Activation for Replacements
     * Reviewer         : Pankaj S.
     * Release Number   : R83

 *************************************************/
  V_CR_GL_CODE           CMS_FUNC_PROD.CFP_CRGL_CODE%TYPE;
  V_CRGL_CATG            CMS_FUNC_PROD.CFP_CRGL_CATG%TYPE;
  V_CRSUBGL_CODE         CMS_FUNC_PROD.CFP_CRSUBGL_CODE%TYPE;
  V_CRACCT_NO            CMS_FUNC_PROD.CFP_CRACCT_NO%TYPE;
  V_DR_GL_CODE           CMS_FUNC_PROD.CFP_DRGL_CODE%TYPE;
  V_DRGL_CATG            CMS_FUNC_PROD.CFP_DRGL_CATG%TYPE;
  V_DRSUBGL_CODE         CMS_FUNC_PROD.CFP_DRSUBGL_CODE%TYPE;
  V_DRACCT_NO            CMS_FUNC_PROD.CFP_DRACCT_NO%TYPE;
  V_FEE_CR_GL_CODE       CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRGL_CATG        CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRSUBGL_CODE     CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO        CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DR_GL_CODE       CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRGL_CATG        CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRSUBGL_CODE     CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO        CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  V_GL_ERRMSG            VARCHAR2(500);
  V_GL_UPD_FLAG          TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_SERVICETAX_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_SERVICETAX_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  V_ACCT_BAL             NUMBER;
  V_LEDGER_BAL           NUMBER;
  V_PREAUTH_EXPIRY_FLAG  CHARACTER(1);
  V_HOLD_AMOUNT          NUMBER;
  V_LASTTIME_INDICATOR   VARCHAR2(2);
  V_TRAN_PREAUTH_FLAG     CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  V_ADJUSTMENT_FLAG       CMS_TRANSACTION_MAST.CTM_ADJUSTMENT_FLAG %TYPE;--Added by Deepa for the Mantis ID : 12296 on 12-Sep
  V_LOADTRANS_FLAG        CMS_TRANSACTION_MAST.CTM_LOADTRANS_FLAG%TYPE; -- added for mantis id:13787
  V_PARAM_VALUE           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  v_dormancy_oncorporateload  CMS_PROD_CATTYPE.CPC_DORMANCY_ONCORPORATELOAD%TYPE;
BEGIN
  P_RESP_CDE := '1';
  P_ERR_MSG  := 'OK';

   BEGIN -- modified select statament for mantis id:13787
     SELECT CTM_PREAUTH_FLAG,CTM_ADJUSTMENT_FLAG,CTM_LOADTRANS_FLAG
       INTO V_TRAN_PREAUTH_FLAG,V_ADJUSTMENT_FLAG,V_LOADTRANS_FLAG --Added by Deepa for the Mantis ID : 12296 on 12-Sep
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CDE := '12'; --Ineligible Transaction
       P_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RETURN;
     WHEN OTHERS THEN
       P_RESP_CDE := '12'; --Ineligible Transaction
       P_ERR_MSG  := 'Error while selecting CMS_TRANSACTION_MAST ' ||SUBSTR(SQLERRM,1,200)||
                  P_TXN_CODE || P_DELIVERY_CHANNEL;
       RETURN;
    END;
	
	--- Added for VMS-3366 - Dormancy Feed Helath Care on Load date
    BEGIN 
    
     SELECT CPC_DORMANCY_ONCORPORATELOAD
       INTO v_dormancy_oncorporateload
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = P_INST_CODE AND
           CPC_PROD_CODE = P_PROD_CODE AND
           CPC_CARD_TYPE  =  P_PROD_CATTYPE;
    EXCEPTION     
     WHEN OTHERS THEN
       P_RESP_CDE := '12'; 
       P_ERR_MSG  := 'Error while selecting CMS_PROD_CATTYPE ' ||SUBSTR(SQLERRM,1,200)||
                  P_PROD_CODE || P_PROD_CATTYPE;
       RETURN;
    END;
	
	IF P_DELIVERY_CHANNEL = '02' AND P_TXN_CODE = '37' THEN
	
	BEGIN
		SELECT
			NVL(CIP_PARAM_VALUE,'N')
		INTO V_PARAM_VALUE
		FROM
			CMS_INST_PARAM
		WHERE
			CIP_PARAM_KEY = 'VMS_4199_TOGGLE'
			AND CIP_INST_CODE = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				V_PARAM_VALUE := 'N';
			WHEN OTHERS THEN
				P_RESP_CDE := '12';
				P_ERR_MSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
			 RETURN;
	   END;
	   
	END IF;

  IF P_TRAN_TYPE IN ('CR', 'DR') THEN
    --Sn find tran type and update the concern acct for transaction amount
    --SN select gl entries

    --SN -Commented for FWR-48

  /*  BEGIN
     SELECT CFP_CRGL_CODE,
           CFP_CRGL_CATG,
           CFP_CRSUBGL_CODE,
           CFP_CRACCT_NO,
           CFP_DRGL_CODE,
           CFP_DRGL_CATG,
           CFP_DRSUBGL_CODE,
           CFP_DRACCT_NO
       INTO V_CR_GL_CODE,
           V_CRGL_CATG,
           V_CRSUBGL_CODE,
           V_CRACCT_NO,
           V_DR_GL_CODE,
           V_DRGL_CATG,
           V_DRSUBGL_CODE,
           V_DRACCT_NO
       FROM CMS_FUNC_PROD
      WHERE CFP_FUNC_CODE = P_FUNC_CODE AND
           CFP_PROD_CODE = P_PROD_CODE AND
           CFP_PROD_CATTYPE = P_PROD_CATTYPE AND
           CFP_INST_CODE = P_INST_CODE;

     IF TRIM(V_CRACCT_NO) IS NULL AND TRIM(V_DRACCT_NO) IS NULL THEN
       P_RESP_CDE := '99';
       P_ERR_MSG  := 'Both credit and debit account cannot be null for a transaction code ' ||
                    P_TXN_CODE || ' Function code ' || P_FUNC_CODE;
       RETURN;
     END IF;

     IF TRIM(V_CRACCT_NO) IS NULL THEN
       V_CRACCT_NO := P_CARD_ACCT_NO;
     END IF;

     IF TRIM(V_DRACCT_NO) IS NULL THEN
       V_DRACCT_NO := P_CARD_ACCT_NO;
     END IF;

     IF TRIM(V_CRACCT_NO) = TRIM(V_DRACCT_NO) THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Both debit and credit account cannot be same for the transaction';
       RETURN;
     END IF;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'DEBIT AND CREDIT GL not defined for func code '
                     ||P_FUNC_CODE
                     ||' Prod code '
                     ||P_PROD_CODE
                     ||' and card type '
                     ||P_PROD_CATTYPE;  -- Space added between error message and P_FUNC_CODE variable
       RETURN;
     WHEN OTHERS THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Problem while processing transaction amount '||
                    SUBSTR(SQLERRM, 1, 250);
       RETURN;
    END; */ --En - commented for fwr-48

    --En select gl entries

    --EN -Commented for FWR-48

    --SN - Added for FWR-48

    IF P_TRAN_TYPE = 'CR' THEN
       V_CRACCT_NO := P_CARD_ACCT_NO;
     END IF;

     IF P_TRAN_TYPE = 'DR' THEN
       V_DRACCT_NO := P_CARD_ACCT_NO;
     END IF;



    --EN -Added for FWR-48

    --SN CREDIT THE CONCERN ACCOUNT
    IF V_CRACCT_NO = P_CARD_ACCT_NO THEN

      IF V_LOADTRANS_FLAG='Y' THEN -- Topup count updation for mantis id:13787
            BEGIN
             UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL+P_TRAN_AMT,
                 CAM_LEDGER_BAL =  CAM_LEDGER_BAL+P_TRAN_AMT,
                 CAM_TOPUPTRANS_COUNT = CAM_TOPUPTRANS_COUNT+1
                 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_CRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction tran type ' ||
                         P_TRAN_TYPE;
             RETURN;
            END IF;
            EXCEPTION
             WHEN OTHERS THEN
               P_RESP_CDE := '21';
               P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RETURN;
             END;

      ELSIF ((P_DELIVERY_CHANNEL = '08' AND P_TXN_CODE = '26')  OR (P_DELIVERY_CHANNEL = '04' AND P_TXN_CODE  IN ('45','68' ,'91') )
      OR (P_DELIVERY_CHANNEL = '07' AND P_TXN_CODE = '59') OR  (P_DELIVERY_CHANNEL = '10' AND P_TXN_CODE = '71') ) --Added for VMS_7196 
	  THEN -- Initial Load amount updation.

          BEGIN

           UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL+P_TRAN_AMT,
                 CAM_LEDGER_BAL =  CAM_LEDGER_BAL+P_TRAN_AMT,
                 CAM_INITIALLOAD_AMT = CAM_INITIALLOAD_AMT+P_TRAN_AMT,
                 cam_first_load_date = sysdate
                 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_CRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction tran type ' ||
                         P_TRAN_TYPE;
             RETURN;
            END IF;
            EXCEPTION
             WHEN OTHERS THEN
               P_RESP_CDE := '21';
               P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST intialload ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RETURN;
             END;
		
		ELSIF P_DELIVERY_CHANNEL = '02' AND P_TXN_CODE = '37' AND V_PARAM_VALUE = 'Y' AND P_PREAUTH_AMNT <> '0' THEN 

          BEGIN

           UPDATE CMS_ACCT_MAST
             SET CAM_LEDGER_BAL =  CAM_LEDGER_BAL+P_TRAN_AMT
			 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_CRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction tran type ' ||
                         P_TRAN_TYPE;
             RETURN;
            END IF;
            EXCEPTION
             WHEN OTHERS THEN
               P_RESP_CDE := '21';
               P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST intialload ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RETURN;
             END;

      ELSE

          BEGIN

           UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL+P_TRAN_AMT,
                CAM_LEDGER_BAL =  CAM_LEDGER_BAL+P_TRAN_AMT
               WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_CRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction tran type ' ||
                         P_TRAN_TYPE;
             RETURN;
            END IF;
            EXCEPTION
             WHEN OTHERS THEN
               P_RESP_CDE := '21';
               P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RETURN;
             END;

          END IF;


  /*  ELSE
         --Sn insert a record into EODUPDATE_ACCT
         BEGIN
           SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                   P_TERMINAL_ID,
                                   P_DELIVERY_CHANNEL,
                                   P_TXN_CODE,
                                   P_TXN_MODE,
                                   P_TRAN_DATE,
                                   P_CARD_ACCT_NO,
                                   V_CRACCT_NO,
                                   P_TRAN_AMT,
                                   'C',
                                   P_INST_CODE,
                                   P_ERR_MSG);

       IF P_ERR_MSG <> 'OK' THEN
        P_RESP_CDE := '21';
        RETURN;
       END IF;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH ' ||
                    SUBSTR(SQLERRM, 1, 250);
       RETURN;
     END;*/--review changes for fwr-48
    END IF;

    --En  insert a record into EODUPDATE_ACCT

    --EN CREDIT THE CONCERN ACCOUNT
    --SN DEBIT THE  CONCERN ACCOUNT
    IF V_DRACCT_NO = P_CARD_ACCT_NO THEN
     BEGIN

          -- IF P_TXN_CODE = '12' AND
             --((P_MSG = '0200') OR (P_MSG = '9220') OR (P_MSG = '9221')) THEN
             IF V_TRAN_PREAUTH_FLAG='Y' THEN
            --T.Narayanan Added for completion without preauth beg
                IF P_PREAUTH_AMNT = '0' THEN
                      UPDATE CMS_ACCT_MAST
                        SET CAM_ACCT_BAL   = CAM_ACCT_BAL - P_TRAN_AMT,
                            CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
                       WHERE CAM_INST_CODE = P_INST_CODE AND
                            CAM_ACCT_NO = V_DRACCT_NO;

                        IF SQL%ROWCOUNT = 0 THEN --Added for 12296(review comments)
                            P_RESP_CDE := '21';
                            P_ERR_MSG  := 'Problem while updating in account master for the completion without Preauth';
                            RETURN;
                        END IF;
                ELSE
                          --T.Narayanan Added for completion without preauth end
                          BEGIN
                            SELECT SUBSTR(P_PREAUTH_AMNT, -1),
                                 SUBSTR(P_PREAUTH_AMNT, -2, 1),
                                 TO_NUMBER(SUBSTR(P_PREAUTH_AMNT,
                                               1,
                                               LENGTH(P_PREAUTH_AMNT) - 2))
                             INTO V_LASTTIME_INDICATOR,
                                 V_PREAUTH_EXPIRY_FLAG,
                                 V_HOLD_AMOUNT
                             FROM DUAL;

                          EXCEPTION
                            WHEN OTHERS THEN

                             P_RESP_CDE := '21';
                             P_ERR_MSG  := 'Problem while getting the preauth expiry flag  ' ||
                                          V_PREAUTH_EXPIRY_FLAG || V_HOLD_AMOUNT;
                             RETURN;

                          END;

                          IF V_PREAUTH_EXPIRY_FLAG = 'Y' THEN

                            UPDATE CMS_ACCT_MAST
                              SET CAM_ACCT_BAL   = CAM_ACCT_BAL - P_TRAN_AMT,
                                 CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
                            WHERE CAM_INST_CODE = P_INST_CODE AND
                                 CAM_ACCT_NO = V_DRACCT_NO;

                              IF SQL%ROWCOUNT = 0 THEN--Added for 12296(review comments)
                                P_RESP_CDE := '21';
                                P_ERR_MSG  := 'Problem while updating in account master for the expired Preauth';
                                RETURN;
                               END IF;
                          END IF;

                      IF V_PREAUTH_EXPIRY_FLAG = 'N' THEN

                            IF P_TRAN_AMT >= V_HOLD_AMOUNT THEN

                             UPDATE CMS_ACCT_MAST
                                SET CAM_ACCT_BAL   = CAM_ACCT_BAL +
                                                (V_HOLD_AMOUNT - P_TRAN_AMT),
                                   CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
                              WHERE CAM_INST_CODE = P_INST_CODE AND
                                   CAM_ACCT_NO = V_DRACCT_NO;

                                 IF SQL%ROWCOUNT = 0 THEN--Added for 12296(review comments)
                                P_RESP_CDE := '21';
                                P_ERR_MSG  := 'Problem while updating in account master for the Completion with more than hold amount ' ;
                                RETURN;
                               END IF;
                            ELSE
                                 IF V_LASTTIME_INDICATOR = 'L' THEN
                                   UPDATE CMS_ACCT_MAST
                                     SET CAM_ACCT_BAL   = CAM_ACCT_BAL +
                                                      (V_HOLD_AMOUNT - P_TRAN_AMT),
                                        CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
                                    WHERE CAM_INST_CODE = P_INST_CODE AND
                                        CAM_ACCT_NO = V_DRACCT_NO;
                                        IF SQL%ROWCOUNT = 0 THEN --Added for 12296(review comments)
                                        P_RESP_CDE := '21';
                                        P_ERR_MSG  := 'Problem while updating in account master for the Last completion transaction' ;
                                        RETURN;
                                       END IF;
                                 ELSE
                                   UPDATE CMS_ACCT_MAST
                                     SET CAM_ACCT_BAL   = CAM_ACCT_BAL,
                                        CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
                                    WHERE CAM_INST_CODE = P_INST_CODE AND
                                        CAM_ACCT_NO = V_DRACCT_NO;

                                    IF SQL%ROWCOUNT = 0 THEN --Added for 12296(review comments)
                                    P_RESP_CDE := '21';
                                    P_ERR_MSG  := 'Problem while updating in account master for the Multiple completion ';
                                    RETURN;
                                   END IF;
                                 END IF;

                            END IF;
                      END IF;
                END IF; --T.Narayanan Added for completion without preauth
           ELSE

            if (P_DELIVERY_CHANNEL = '08' AND P_TXN_CODE = '28') then -- added for mantis id:13787


            UPDATE CMS_ACCT_MAST
               SET CAM_ACCT_BAL   = CAM_ACCT_BAL - P_TRAN_AMT,
                  CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT,
                  cam_initialload_amt=0,
                  cam_first_load_date=null
             WHERE CAM_INST_CODE = P_INST_CODE AND
                  CAM_ACCT_NO = V_DRACCT_NO;
               IF SQL%ROWCOUNT = 0 THEN --Added for 12296(review comments)
                P_RESP_CDE := '21';
                P_ERR_MSG  := 'Problem while updating in account master for transaction tran type(initial load) ' ||
                             P_TRAN_TYPE;
                RETURN;
               END IF;


            else

            UPDATE CMS_ACCT_MAST
               SET CAM_ACCT_BAL   = CAM_ACCT_BAL - P_TRAN_AMT,
                  CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_TRAN_AMT
             WHERE CAM_INST_CODE = P_INST_CODE AND
                  CAM_ACCT_NO = V_DRACCT_NO;
               IF SQL%ROWCOUNT = 0 THEN --Added for 12296(review comments)
                P_RESP_CDE := '21';
                P_ERR_MSG  := 'Problem while updating in account master for transaction tran type ' ||
                             P_TRAN_TYPE;
                RETURN;
               END IF;

             end if;

           END IF;



     EXCEPTION

       WHEN OTHERS THEN
        P_ERR_MSG  := 'Problem while updating the details in account master ' ||
                     SUBSTR(SQLERRM, 1, 300);
        P_RESP_CDE := '21';
        RETURN;--Added for 12296(review comments)
     END;
  /*  ELSE
     --Sn insert a record into EODUPDATE_ACCT
     BEGIN
       SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                               P_TERMINAL_ID,
                               P_DELIVERY_CHANNEL,
                               P_TXN_CODE,
                               P_TXN_MODE,
                               P_TRAN_DATE,
                               P_CARD_ACCT_NO,
                               V_DRACCT_NO,
                               P_TRAN_AMT,
                               'D',
                               P_INST_CODE,
                               P_ERR_MSG);

       IF P_ERR_MSG <> 'OK' THEN
        P_RESP_CDE := '21';
        RETURN;
       END IF;
     EXCEPTION
      WHEN OTHERS THEN
        P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH1 ' ||
                     SUBSTR(SQLERRM, 1, 300);
        P_RESP_CDE := '21';
        RETURN; --Added for 12296(review comments)
     END;*/--review changes for fwr-48
     --EN DEBIT THE  CONCERN ACCOUNT
    END IF;
  END IF;

  --Added for CMS-Auth
  --Sn of Pre-Auth transaction.Txn amount will be debited only from available balance.

--  IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
IF V_TRAN_PREAUTH_FLAG='Y' AND P_TRAN_TYPE='NA' THEN
BEGIN
--Sn Added by Deepa for the Mantis ID : 12296 on 12-Sep
    IF V_ADJUSTMENT_FLAG='Y' THEN

    UPDATE CMS_ACCT_MAST
      SET CAM_ACCT_BAL = CAM_ACCT_BAL + (P_PREAUTH_AMNT - P_TRAN_AMT)
    WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = P_CARD_ACCT_NO;

     IF SQL%ROWCOUNT = 0
         THEN
            P_ERR_MSG :='Error while updating the account balance for Preauth Adjustment Trasnaction';
            P_RESP_CDE := '21';
            RETURN;
         END IF;

    ELSE --En Added by Deepa for the Mantis ID : 12296 on 12-Sep

    UPDATE CMS_ACCT_MAST
      SET CAM_ACCT_BAL = CAM_ACCT_BAL - P_TRAN_AMT
    WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = P_CARD_ACCT_NO;

     IF SQL%ROWCOUNT = 0
         THEN
            P_ERR_MSG :='Error while updating the account balance of Preauth Trasnaction';
            P_RESP_CDE := '21';
            RETURN;
         END IF;
    END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
END;
  END IF;

  --En of Pre-Auth transaction

  --En find tran type and update the concern acct for transaction amount
  IF P_FEE_AMT <> 0 or P_REVERSE_FEE <>0 THEN --Modified for FSS-3679
    BEGIN
     --<< FEE begin >>
  --   V_FEE_CRACCT_NO := P_FEE_CRACCT_NO; --Commeneted for FWR-48
  --   V_FEE_DRACCT_NO := P_FEE_DRACCT_NO; --Commeneted for FWR-48

       V_FEE_CRACCT_NO := null; --Modified for FWR-48
       V_FEE_DRACCT_NO := P_CARD_ACCT_NO; --Modified for FWR-48
-- SN - Commeneted for FWR-48
   /*  IF TRIM(V_FEE_CRACCT_NO) IS NULL AND TRIM(V_FEE_DRACCT_NO) IS NULL THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Both credit and debit account cannot be null for a fee ' ||
                    P_FEE_CODE || ' Function code ' || P_FUNC_CODE;
       RETURN;
     END IF;

     IF TRIM(V_FEE_CRACCT_NO) IS NULL THEN
       V_FEE_CRACCT_NO := P_CARD_ACCT_NO;
     END IF;

     IF TRIM(V_FEE_DRACCT_NO) IS NULL THEN
       V_FEE_DRACCT_NO := P_CARD_ACCT_NO;
     END IF;

     IF TRIM(V_FEE_CRACCT_NO) = TRIM(V_FEE_DRACCT_NO) THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Both debit and credit fee account cannot be same';
       RETURN;
     END IF;*/ -- EN - Commeneted for FWR-48

     IF V_FEE_DRACCT_NO = P_CARD_ACCT_NO THEN
       --SN DEBIT THE  CONCERN FEE  ACCOUNT
       BEGIN

          UPDATE CMS_ACCT_MAST
          --  SET CAM_ACCT_BAL   = CAM_ACCT_BAL - P_FEE_AMT,
           SET CAM_ACCT_BAL   = CAM_ACCT_BAL - (P_FEE_AMT-P_REVERSE_FEE), --Modified for FSS 837
                CAM_LEDGER_BAL = CAM_LEDGER_BAL - P_FEE_AMT
           WHERE CAM_INST_CODE = P_INST_CODE AND
                CAM_ACCT_NO = V_FEE_DRACCT_NO;


        IF SQL%ROWCOUNT = 0 THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Problem while updating in account master for transaction fee  ' ||P_FEE_CODE;
          RETURN;
        END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST1 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
       END;
  /*   ELSE
       --Sn insert a record into EODUPDATE_ACCT
       BEGIN
        SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                P_TERMINAL_ID,
                                P_DELIVERY_CHANNEL,
                                P_TXN_CODE,
                                P_TXN_MODE,
                                P_TRAN_DATE,
                                P_CARD_ACCT_NO,
                                V_FEE_DRACCT_NO,
                                P_FEE_AMT,
                                'D',
                                P_INST_CODE,
                                P_ERR_MSG);

        IF P_ERR_MSG <> 'OK' THEN
          P_RESP_CDE := '21';
          RETURN;
        END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH3 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
       END;*/--review changes for fwr-48
       --En insert a record into EODUPDATE_ACCT
     END IF;

     --EN DEBIT THE  CONCERN FEE  ACCOUNT
     --SN CREDIT THE CONCERN FEE ACCOUNT
     IF V_FEE_CRACCT_NO = P_CARD_ACCT_NO THEN
       BEGIN
        UPDATE CMS_ACCT_MAST
           SET CAM_ACCT_BAL   = CAM_ACCT_BAL + P_FEE_AMT,
              CAM_LEDGER_BAL = CAM_LEDGER_BAL + P_FEE_AMT
         WHERE CAM_INST_CODE = P_INST_CODE AND
              CAM_ACCT_NO = V_FEE_CRACCT_NO;

        IF SQL%ROWCOUNT = 0 THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Problem while updating in account master  for transaction tran type ' ||
                       P_TRAN_TYPE;
          RETURN;
        END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST2 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
       END;
  /*   ELSE
       --Sn insert a record into EODUPDATE_ACCT
       BEGIN
        SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                P_TERMINAL_ID,
                                P_DELIVERY_CHANNEL,
                                P_TXN_CODE,
                                P_TXN_MODE,
                                P_TRAN_DATE,
                                P_CARD_ACCT_NO,
                                V_FEE_CRACCT_NO,
                                P_FEE_AMT,
                                'C',
                                P_INST_CODE,
                                P_ERR_MSG);

        IF P_ERR_MSG <> 'OK' THEN
          P_RESP_CDE := '21';
          RETURN;
        END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH4 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
       END;*/--review changes for fwr-48
       --En insert a record into EODUPDATE_ACCT
     END IF;

     --EN CREDIT THE CONCERN FEE ACCOUNT

     ----SN service tax---
     IF P_SERVICETAX_CALCFLAG = '1' THEN
       V_SERVICETAX_CRACCT_NO := P_SERVICETAX_CRACCT_NO;
       V_SERVICETAX_DRACCT_NO := P_SERVICETAX_DRACCT_NO;

       IF TRIM(V_SERVICETAX_CRACCT_NO) IS NULL AND
         TRIM(V_SERVICETAX_DRACCT_NO) IS NULL THEN
        P_RESP_CDE := '21';
        P_ERR_MSG  := 'Both credit and debit account cannot be null for a Service Tax ' ||
                     P_FEE_CODE || ' Function code ' ||
                     P_FUNC_CODE;
        RETURN;
       END IF;

       IF TRIM(V_SERVICETAX_CRACCT_NO) IS NULL THEN
        V_SERVICETAX_CRACCT_NO := P_CARD_ACCT_NO;
       END IF;

       IF TRIM(V_SERVICETAX_DRACCT_NO) IS NULL THEN
        V_SERVICETAX_DRACCT_NO := P_CARD_ACCT_NO;
       END IF;

       IF TRIM(V_SERVICETAX_CRACCT_NO) = TRIM(V_SERVICETAX_DRACCT_NO) THEN
        P_RESP_CDE := '21';
        P_ERR_MSG  := 'Both debit and credit service tax account cannot be same';
        RETURN;
       END IF;

       IF V_SERVICETAX_DRACCT_NO = P_CARD_ACCT_NO THEN
        --SN  debit service tax amount from cmncern account
        BEGIN
          UPDATE CMS_ACCT_MAST
            SET CAM_ACCT_BAL = CAM_ACCT_BAL - P_SERVICETAX_AMOUNT
           WHERE CAM_INST_CODE = P_INST_CODE AND
                CAM_ACCT_NO = V_SERVICETAX_DRACCT_NO;

          IF SQL%ROWCOUNT = 0 THEN
            P_RESP_CDE := '21';
            P_ERR_MSG  := 'Problem while updating in account master for transaction for transaction tran type ' ||
                        P_TRAN_TYPE;
            RETURN;
          END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST3 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
        END;
   /*    ELSE
        --Sn insert a record into EODUPDATE_ACCT
        BEGIN
          SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                  P_TERMINAL_ID,
                                  P_DELIVERY_CHANNEL,
                                  P_TXN_CODE,
                                  P_TXN_MODE,
                                  P_TRAN_DATE,
                                  P_CARD_ACCT_NO,
                                  V_SERVICETAX_DRACCT_NO,
                                  P_SERVICETAX_AMOUNT,
                                  'D',
                                  P_INST_CODE,
                                  P_ERR_MSG);

          IF P_ERR_MSG <> 'OK' THEN
            P_RESP_CDE := '21';
            RETURN;
          END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH5 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
        END;*/--review changes for fwr-48
        --En insert a record into EODUPDATE_ACCT
       END IF;

       --En debit the service tax amount from cmncern account
       IF V_SERVICETAX_CRACCT_NO = P_CARD_ACCT_NO THEN
        --SN  credit service tax amount from cmncern account
        BEGIN
          UPDATE CMS_ACCT_MAST
            SET CAM_ACCT_BAL = CAM_ACCT_BAL + P_SERVICETAX_AMOUNT
           WHERE CAM_INST_CODE = P_INST_CODE AND
                CAM_ACCT_NO = V_SERVICETAX_CRACCT_NO;

          IF SQL%ROWCOUNT = 0 THEN
            P_RESP_CDE := '21';
            P_ERR_MSG  := 'Problem while updating in account master for transaction for transaction tran type ' ||
                        P_TRAN_TYPE;
            RETURN;
          END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST5 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
        END;
    /*   ELSE
        --Sn insert a record into EODUPDATE_ACCT
        BEGIN
          SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                  P_TERMINAL_ID,
                                  P_DELIVERY_CHANNEL,
                                  P_TXN_CODE,
                                  P_TXN_MODE,
                                  P_TRAN_DATE,
                                  P_CARD_ACCT_NO,
                                  V_SERVICETAX_CRACCT_NO,
                                  P_SERVICETAX_AMOUNT,
                                  'C',
                                  P_INST_CODE,
                                  P_ERR_MSG);

          IF P_ERR_MSG <> 'OK' THEN
            P_RESP_CDE := '21';
            RETURN;
          END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH6 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
        END;*/--review changes for fwr-48
        --En insert a record into EODUPDATE_ACCT
       END IF;

       --En credit  the service tax amount from cmncern account

       ----SN CESS---
       IF P_CESS_CALCFLAG = '1' THEN
        V_CESS_CRACCT_NO := P_CESS_CRACCT_NO;
        V_CESS_DRACCT_NO := P_CESS_DRACCT_NO;

        IF TRIM(V_CESS_CRACCT_NO) IS NULL AND
           TRIM(V_CESS_DRACCT_NO) IS NULL THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Both credit and debit account cannot be null for a Cess ' ||
                       P_FEE_CODE || ' Function code ' ||
                       P_FUNC_CODE;
          RETURN;
        END IF;

        IF TRIM(V_CESS_CRACCT_NO) IS NULL THEN
          V_CESS_CRACCT_NO := P_CARD_ACCT_NO;
        END IF;

        IF TRIM(V_CESS_DRACCT_NO) IS NULL THEN
          V_CESS_DRACCT_NO := P_CARD_ACCT_NO;
        END IF;

        IF TRIM(V_CESS_CRACCT_NO) = TRIM(V_CESS_DRACCT_NO) THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Both debit and credit account for the Cess cannot be same';
          RETURN;
        END IF;

        --SN  debit cess amount from cmncern account
        IF V_CESS_DRACCT_NO = P_CARD_ACCT_NO THEN
          BEGIN
            UPDATE CMS_ACCT_MAST
              SET CAM_ACCT_BAL = CAM_ACCT_BAL - P_CESS_AMOUNT
            WHERE CAM_INST_CODE = P_INST_CODE AND
                 CAM_ACCT_NO = V_CESS_DRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction for transaction tran type ' ||
                          P_TRAN_TYPE;
             RETURN;
            END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST6 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
          END;
     /*   ELSE
          --Sn insert a record into EODUPDATE_ACCT
          BEGIN
            SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                    P_TERMINAL_ID,
                                    P_DELIVERY_CHANNEL,
                                    P_TXN_CODE,
                                    P_TXN_MODE,
                                    P_TRAN_DATE,
                                    P_CARD_ACCT_NO,
                                    V_CESS_DRACCT_NO,
                                    P_CESS_AMOUNT,
                                    'D',
                                    P_INST_CODE,
                                    P_ERR_MSG);

            IF P_ERR_MSG <> 'OK' THEN
             P_RESP_CDE := '21';
             RETURN;
            END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH7 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
          END;*/--review changes for fwr-48
          --En insert a record into EODUPDATE_ACCT
        END IF;

        --En debit the cess amount from cmncern account

        --SN  credit cess  amount from cmncern account
        IF V_CESS_CRACCT_NO = P_CARD_ACCT_NO THEN
          BEGIN
            UPDATE CMS_ACCT_MAST
              SET CAM_ACCT_BAL = CAM_ACCT_BAL + P_CESS_AMOUNT
            WHERE CAM_INST_CODE = P_INST_CODE AND
                 CAM_ACCT_NO = V_CESS_CRACCT_NO;

            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CDE := '21';
             P_ERR_MSG  := 'Problem while updating in account master for transaction for transaction tran type ' ||
                          P_TRAN_TYPE;
             RETURN;
            END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while updating CMS_ACCT_MAST7 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
          END;
    /*    ELSE
          --Sn insert a record into EODUPDATE_ACCT
          BEGIN
            SP_INS_EODUPDATE_ACCT_CMSAUTH(P_RRN,
                                    P_TERMINAL_ID,
                                    P_DELIVERY_CHANNEL,
                                    P_TXN_CODE,
                                    P_TXN_MODE,
                                    P_TRAN_DATE,
                                    P_CARD_ACCT_NO,
                                    V_CESS_CRACCT_NO,
                                    P_CESS_AMOUNT,
                                    'C',
                                    P_INST_CODE,
                                    P_ERR_MSG);

            IF P_ERR_MSG <> 'OK' THEN
             P_RESP_CDE := '21';
             RETURN;
            END IF;
EXCEPTION
WHEN OTHERS THEN
          P_RESP_CDE := '21';
          P_ERR_MSG  := 'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH8 ' ||SUBSTR(SQLERRM,1,200)||
                       P_TRAN_TYPE;
          RETURN;
          END;*/--review changes for fwr-48
          --En insert a record into EODUPDATE_ACCT
        END IF;
        --En credit  the cess amount from concern account
       END IF;
       ----EN CESS---
     END IF;
     ----EN service tax---
    EXCEPTION
     --<< FEE exception >>
     WHEN OTHERS THEN
       P_RESP_CDE := '21';
       P_ERR_MSG  := 'Problem while processing fee for transaction ';
    END; --<< FEE end >>
  END IF;
  --END LOOP;
  --Sn check any fees attached if so credit or debit the acct
  --En check any fees attached if so credit or debit the acct
  
     --- Added for VMS-3366 - Dormancy Feed Helath Care on Load date
  
    IF P_DELIVERY_CHANNEL||P_TXN_CODE IN ('0481','0491','1703','0826')        --- Modified for  VMS-5327 
    	AND NVL(P_MSG,'1200') NOT IN ('0400','1400') AND v_dormancy_oncorporateload = 'Y'
	
    THEN
     
  	UPDATE CMS_APPL_PAN 
	SET CAP_LAST_CORPORATE_LOADDATE = SYSDATE
	WHERE CAP_PAN_CODE = GETHASH(P_CARD_NO)
	AND  CAP_MBR_NUMB = '000';
							   
     END IF;
	
  
EXCEPTION
  WHEN OTHERS THEN
    P_RESP_CDE := '21';
    P_ERR_MSG  := 'Error main ' || 'Problem while processing amount ' || SUBSTR(SQLERRM,1,250);
END;
/
SHOW ERROR;