create or replace
PROCEDURE        vmscms.SP_TRAN_FEES_CMSAUTH(PRM_INST_CODE        IN NUMBER,
                                         PRM_CARD_NUMBER      IN VARCHAR2,
                                         PRM_DEL_CHANNEL      IN VARCHAR2,
                                         PRM_TRAN_TYPE        IN VARCHAR2, -- FIN/NON FIN TRAN
                                         PRM_TRAN_MODE        IN VARCHAR2, -- ONUS/OFFUS
                                         PRM_TRAN_CODE        IN VARCHAR2,
                                         PRM_CURRENCY_CODE    IN VARCHAR2,
                                         PRM_CONSODIUM_CODE   IN VARCHAR2,
                                         PRM_PARTNER_CODE     IN VARCHAR2,
                                         PRM_TRN_AMT          IN NUMBER,
                                         PRM_TRN_DATE         IN DATE,
                                         PRM_INTL_INDICATOR   IN VARCHAR2, --Added by Deepa
                                         PRM_POS_VERIFICATION IN VARCHAR2, --Added by Deepa
                                         PRM_RESPONSE_CODE    IN VARCHAR2, --Added by Deepa
                                         PRM_MSG_TYPE         IN VARCHAR2, --Added by Deepa
                                         PRM_REVERSAL_CODE    IN VARCHAR2, --Added by Deepa on June 25 2012 for Reversal txn Fee
                                         PRM_MCC_CODE         IN VARCHAR2, -- Added by Trivikram on Sep 05 2012 for Merchant code
                                         PRM_TRAN_FEE         OUT NUMBER,
                                         PRM_ERROR            OUT VARCHAR2,
                                         PRM_FEE_CODE         OUT NUMBER, --   To Return  FEE_CODE
                                         PRM_CRGL_CATG        OUT VARCHAR2,
                                         PRM_CRGL_CODE        OUT VARCHAR2,
                                         PRM_CRSUBGL_CODE     OUT VARCHAR2,
                                         PRM_CRACCT_NO        OUT VARCHAR2,
                                         PRM_DRGL_CATG        OUT VARCHAR2,
                                         PRM_DRGL_CODE        OUT VARCHAR2,
                                         PRM_DRSUBGL_CODE     OUT VARCHAR2,
                                         PRM_DRACCT_NO        OUT VARCHAR2,
                                         PRM_ST_CALC_FLAG     OUT VARCHAR2,
                                         PRM_CESS_CALC_FLAG   OUT VARCHAR2,
                                         PRM_ST_CRACCT_NO     OUT VARCHAR2,
                                         PRM_ST_DRACCT_NO     OUT VARCHAR2,
                                         PRM_CESS_CRACCT_NO   OUT VARCHAR2,
                                         PRM_CESS_DRACCT_NO   OUT VARCHAR2,
                                         PRM_FEEAMNT_TYPE     OUT VARCHAR2, --Added by Deepa
                                         PRM_CLAWBACK         OUT VARCHAR2, --Added by Deepa
                                         PRM_FEE_PLAN         OUT VARCHAR2, --Added by Deepa
                                         PRM_PER_FEES         OUT NUMBER, --Added by Deepa
                                         PRM_FLAT_FEES        OUT NUMBER, --Added by Deepa
                                         PRM_FREETXN_EXCEED   OUT VARCHAR2,  -- Added by trivikram
                                         PRM_DURATION         OUT VARCHAR2,  -- Added by trivikram
                                         prm_fee_attach_type  OUT VARCHAR2,   -- Added by Trivkram
                                         PRM_FEE_DESC  OUT VARCHAR2,   -- Added for MVCSD-4471
                                         prm_complfree_flag   IN VARCHAR2 DEFAULT 'N',
                                         prm_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
                                         ) IS
  /**********************************************************************************************************************
        * Modified By      :  Deepa T
        * Modified Date    :   17-Sept-2012
        * Modified Reason  :   To change the condition for reversal transaction as the SAF is also considered as reversal
        * Reviewer         :  Dhiraj
        * Reviewed Date    : 27-Dec-2012
        * Build Number     :  CMS3.5.1_RI0023_B0003
              
        * Modified by      : Sachin P.
        * Modified for     : Mantis ID -11613
        * Modified Reason  : We need to include the message type 1421 in the query to get the transaction 
                             Type Normal /Reversal based on message type                 
        * Modified Date    : 17-Jul-2013
        * Reviewer         : Sagarm
        * Reviewed Date    : 22.07.2013
        * Build Number     : RI0024.3_B0005

        * Modified by      : Anil Kumar
        * Modified for     : Mantis ID -0011891
        * Modified Reason  : In ELAN delivery channel Reversal fee (Configured for Reversal Transactions) 
                             is taking for SAF_Repeat_Merchandise Return Transactions.              
        * Modified Date    : 06-Aug-2013
        * Reviewer         : 
        * Reviewed Date    : 
        * Build Number     :            
        
        * Modified by      : Sai Prasad 
        * Modified for     : JIRA FWR-11
        * Modified Reason  :                
        * Modified Date    : 16-Aug-2013
        * Reviewer         : Sagar
        * Reviewed Date    : 16-Aug-2013
        * Build Number     : RI0024.4_B0004     
        
        * Modified By      : Sachin P.
        * Modified Date    : 03-Sep-2013
        * Modified for     : DFCHOST-340
        * Modified Reason  : Momentum Production Testing - Loading test card with $20.00
        * Reviewer         : dhiraj
        * Reviewed Date    : 11-sep-2013
        * Build Number     : RI0024.4_B0009
      
        * Modified By      : MageshKumar S
        * Modified Date    : 28-Jan-2014
        * Modified for     : MVCSD-4471
        * Modified Reason  : Narration change for FEE amount
        * Reviewer         : Dhiraj
        * Reviewed Date    : 
        * Build Number     : RI0027_B0007
        
        * Modified By      : Sagar
        * Modified Date    : 11-Feb-2014
        * Modified for     : Spil_#.0
        * Modified Reason  : Msg Type 1400 added in CMS_TXN_PROPERTIES query 
        * Reviewer         : Dhiraj
        * Reviewed Date    : 12-Feb-2014
        * Build Number     : RI0027.1_B0001
        
      * Modified By      : Abdul Hameed M.A
      * Modified Date    : 03-July-2014
      * Modified for     : Mantis ID 15194
      * Modified Reason  : Merchandise return auth transaction fee issues
      * Reviewer         : Spankaj
      * Build Number     : RI0027.2.2_B0002
      
        * Modified By      : Ramesh A
      * Modified Date    : 18-SEP-2014 
      * Modified Reason  : MVCSD-5381
      * Reviewer         : 
      * Build Number     :RI0027.4_B0001
      
     * Modified by          : Spankaj
     * Modified Date        : 08-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11     
     
     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06


     * Modified by      : Sivakumar M.
     * Modified for     : VMS-952
     * Modified Date    : 30-May-2019
     * Reviewer         : Saravanankumar
     * Build Number     : R16

     * Modified by      : Pankaj S.
     * Modified for     : VMS-5856
     * Modified Date    : 29-Jun-2022
     * Reviewer         : Venkat S.
     * Build Number     : R65
  ***********************************************************************************************************************/
  
  EXP_MAIN EXCEPTION;
  EXP_NOFEES EXCEPTION;
  V_CONSODIUM_CODE  NUMBER(3); -- hardcoded temporary
  V_PARTNER_CODE    NUMBER(3); -- hardcoded temporary
  V_INST_CODE       CMS_FEE_MAST.CFM_INST_CODE%TYPE;
  V_FEE_CODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_TYPE        CMS_FEE_MAST.CFM_FEETYPE_CODE%TYPE;
  V_FLAT_FEE        CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_PER_FEES        CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_MIN_FEES        CMS_FEE_MAST.CFM_MIN_FEES%TYPE;
  V_PROD_CODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_CARD_FEE        CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_PROD_FEE        CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_FEEATTACH_FLAG  NUMBER;
  V_ERR_WAIV        VARCHAR2(300);
  V_FEEATTACH_TYPE  VARCHAR2(2);
  V_HASH_PAN        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_REVERSAL_TXN    VARCHAR2(1) DEFAULT 'N';
  V_REVESAL_MSGTYPE CMS_TXN_PROPERTIES.CTP_MSG_TYPE%TYPE;
  V_ACCT_NUMBER      CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  v_feecap_flag     VARCHAR2(1);
  --ABDUL
  v_preauth_flag       CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  V_CR_DR_FLAG       CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  
BEGIN
  PRM_ERROR := 'OK';
  /* TO GET CONSODIUM CODE AND PARTNER CODE, SEARCH CONSODIUM CODE
  FROM CMS_CONST_MAST BASED ON CARD_FIID (AFTER CONFIRMATION)
  AND BASED ON CONSD. CODE SERACH FOR PARTNER CODE FROM CMS_PARTACQ_MAST
  */
   PRM_TRAN_FEE :=0;
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_CARD_NUMBER);
  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERROR := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN;
  END;
  --EN CREATE HASH PAN
  BEGIN
    -- PAN DATE
    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_ACCT_NO
     INTO V_PROD_CODE, V_CARD_TYPE, V_ACCT_NUMBER
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = PRM_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN -- prm_card_number
    ;
  EXCEPTION
    -- PAN DATE
    WHEN OTHERS THEN
     PRM_ERROR := 'ERROR FROM PAN DATA SECTION =>' || SQLERRM;
     RAISE EXP_MAIN;
  END; -- PAN DATE

  --Added by Deepa on June 25 2012 for Reversal txn Fee
  BEGIN

    SELECT CTP_MSG_TYPE
     INTO V_REVESAL_MSGTYPE
     FROM CMS_TXN_PROPERTIES
    WHERE CTP_INST_CODE = PRM_INST_CODE AND
         CTP_DELIVERY_CHANNEL = PRM_DEL_CHANNEL AND
         CTP_TXN_CODE = PRM_TRAN_CODE AND
         CTP_MSG_TYPE IN ('0400', '1420', '9220', '9221', '1220', '1221','1421','1400' ) AND --Added 1421 message type for Mantis id 11613
         CTP_MSG_TYPE = PRM_MSG_TYPE AND
         --CTP_REVERSAL_CODE = PRM_REVERSAL_CODE;
         CTP_REVERSAL_CODE !=0;--modified by Deepa on Nov-20-2012 to change the condition for reversal transaction as the SAF is also considered as reversal

    V_REVERSAL_TXN := 'R';
    
   --Added for Mantis id : 0011891  
    IF(PRM_MSG_TYPE IN ('9220','9221') AND PRM_REVERSAL_CODE ='0')
      THEN
        V_REVERSAL_TXN := 'N';
    END IF;
   --End for Mantis id : 0011891

  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_REVERSAL_TXN := 'N';

    WHEN OTHERS THEN

     --V_REVERSAL_TXN := 'N';
     PRM_ERROR := 'Error while selecting the Reversal Flag   ' ||
                 PRM_ERROR;
     RETURN;--Added by Deepa on Sep-17-2012 to raise the exception
  END;
  
 -- Sn Added by Abdul Hameed for 15194 
 BEGIN
  SELECT CTM_PREAUTH_FLAG,
    CTM_CREDIT_DEBIT_FLAG
  INTO v_preauth_flag ,
    V_CR_DR_FLAG
  FROM CMS_TRANSACTION_MAST
  WHERE CTM_DELIVERY_CHANNEL=PRM_DEL_CHANNEL
  AND CTM_TRAN_CODE         =PRM_TRAN_CODE
  AND CTM_INST_CODE         =PRM_INST_CODE;
EXCEPTION
WHEN OTHERS THEN
  PRM_ERROR := 'Error while getting transaction details' || SQLERRM;
  RAISE EXP_MAIN;
   -- En Added by Abdul Hameed for 15194 
END; 
-- Added for MVCSD-5381
BEGIN

  SP_CHECK_FEES_CARD(prm_inst_code,prm_card_number,prm_del_channel,prm_tran_code,V_FEEATTACH_FLAG,prm_error);
  
   EXCEPTION        
     WHEN OTHERS THEN
     PRM_ERROR := 'Error in CHECK_FEES_CARD proc' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN;

END;

  IF V_FEEATTACH_FLAG = -1 THEN
    --Error from tran_fees_card procedure
    PRM_ERROR := 'Error from fee attach  card proc  ' || PRM_ERROR;
    RETURN;
  END IF;
  
  IF V_FEEATTACH_FLAG = 1 THEN --Added for MVCSD-5381

  BEGIN
  SP_TRAN_FEES_CARD(PRM_INST_CODE,
                PRM_CARD_NUMBER,
                PRM_DEL_CHANNEL,
                PRM_TRAN_TYPE,
                PRM_TRAN_MODE,
                PRM_TRAN_CODE,
                PRM_CURRENCY_CODE,
                PRM_TRN_AMT,
                PRM_CONSODIUM_CODE,
                PRM_PARTNER_CODE,
                PRM_TRN_DATE,
                PRM_INTL_INDICATOR,
                PRM_POS_VERIFICATION,
                PRM_RESPONSE_CODE,
                PRM_MSG_TYPE,
                V_REVERSAL_TXN, --Added by Deepa on June 25 2012 for Reversal txn Fee
                PRM_REVERSAL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
                PRM_MCC_CODE, --Added by Trivikram on 05-Sep-2012 for merchant catg code
                v_preauth_flag ,--Added by Abdul Hameed for 15194
                
                V_CR_DR_FLAG,--Added by Abdul Hameed for 15194
                v_acct_number, --Added for OTC changes
                V_FEE_CODE,
                PRM_FLAT_FEES,
                PRM_PER_FEES,
                V_MIN_FEES,
                V_FEEATTACH_FLAG,
                PRM_FEEAMNT_TYPE,
                PRM_CLAWBACK,
                PRM_FEE_PLAN,
                PRM_TRAN_FEE,
                PRM_ERROR,
                PRM_CRGL_CATG,
                PRM_CRGL_CODE,
                PRM_CRSUBGL_CODE,
                PRM_CRACCT_NO,
                PRM_DRGL_CATG,
                PRM_DRGL_CODE,
                PRM_DRSUBGL_CODE,
                PRM_DRACCT_NO,
                PRM_ST_CALC_FLAG,
                PRM_CESS_CALC_FLAG,
                PRM_ST_CRACCT_NO,
                PRM_ST_DRACCT_NO,
                PRM_CESS_CRACCT_NO,
                PRM_CESS_DRACCT_NO,
                PRM_FREETXN_EXCEED, -- Added by Trivikra on 26-July-2012
                PRM_DURATION, --added by Trivikram on 27-july-2012
                PRM_FEE_DESC, -- added for MVCSD-4471
                prm_complfree_flag,
                prm_surchrg_ind --Added for VMS-5856
                );
    EXCEPTION         --Added on 12-Aug-2013 
      WHEN OTHERS THEN
     PRM_ERROR := 'Error in tran fee card proc' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN;
  END;
  IF V_FEEATTACH_FLAG = -1 THEN
    --Error from tran_fees_card procedure
    PRM_ERROR := 'Error from fee attach  card proc  ' || PRM_ERROR;
    RETURN;
  END IF;

  IF V_FEEATTACH_FLAG = 1 THEN
    PRM_ERROR        := 'OK';
    V_FEEATTACH_TYPE := 'C';
    prm_fee_attach_type := 'C'; --Added by Trivikram on Sep 05 2012
    PRM_TRAN_FEE := NVL(PRM_TRAN_FEE,0);--Added on 03.09.2013 for DFCHOST-340
  ELSE
    IF V_FEEATTACH_FLAG = 0 THEN
      BEGIN
        SP_TRAN_FEES_PRODUCTCATG(PRM_INST_CODE,
                         PRM_DEL_CHANNEL,
                         PRM_TRAN_TYPE,
                         PRM_TRAN_MODE,
                         PRM_TRAN_CODE,
                         PRM_CURRENCY_CODE,
                         PRM_TRN_AMT,
                         V_PROD_CODE,
                         V_CARD_TYPE,
                         PRM_CONSODIUM_CODE,
                         PRM_PARTNER_CODE,
                         PRM_TRN_DATE,
                         PRM_INTL_INDICATOR,
                         PRM_POS_VERIFICATION,
                         PRM_RESPONSE_CODE,
                         PRM_MSG_TYPE,
                         PRM_CARD_NUMBER,
                         V_REVERSAL_TXN, --Added by Deepa on June 25 2012 for Reversal txn Fee
                         PRM_REVERSAL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
                         PRM_MCC_CODE, --Added by Trivikram on 05-Sep-2012 for merchant catg code
                        v_preauth_flag ,--Added by Abdul Hameed for 15194
                          V_CR_DR_FLAG,--Added by Abdul Hameed for 15194
                         v_acct_number, --Added for OTC changes
                         V_FEE_CODE,
                         PRM_FLAT_FEES,
                         PRM_PER_FEES,
                         V_MIN_FEES,
                         V_FEEATTACH_FLAG,
                         PRM_FEEAMNT_TYPE,
                         PRM_CLAWBACK,
                         PRM_FEE_PLAN,
                         PRM_TRAN_FEE,
                         PRM_ERROR,
                         PRM_CRGL_CATG,
                         PRM_CRGL_CODE,
                         PRM_CRSUBGL_CODE,
                         PRM_CRACCT_NO,
                         PRM_DRGL_CATG,
                         PRM_DRGL_CODE,
                         PRM_DRSUBGL_CODE,
                         PRM_DRACCT_NO,
                         PRM_ST_CALC_FLAG,
                         PRM_CESS_CALC_FLAG,
                         PRM_ST_CRACCT_NO,
                         PRM_ST_DRACCT_NO,
                         PRM_CESS_CRACCT_NO,
                         PRM_CESS_DRACCT_NO,
                         PRM_FREETXN_EXCEED,--Added by Trivikram on 27-July-2012
                         PRM_DURATION,--Added by Trivikram on 27-July-2012
                         PRM_FEE_DESC, prm_complfree_flag, -- added for MVCSD-4471 
                         prm_surchrg_ind); --Added for VMS-5856
        EXCEPTION         --Added on 12-Aug-2013
          WHEN OTHERS THEN
            PRM_ERROR := 'Error in tran fee product category proc' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN;
      END;
     IF V_FEEATTACH_FLAG = -1 THEN
       --Error from tran_fees_card procedure
       PRM_ERROR := 'Error from fee attach  prod cattype proc   ' ||
                 PRM_ERROR;
       RETURN;
     END IF;
     IF V_FEEATTACH_FLAG = 1 THEN

       V_FEEATTACH_TYPE := 'PC';
       PRM_ERROR        := 'OK';
       prm_fee_attach_type := 'PC'; --Added by Trivikram on Sep 05 2012
       PRM_TRAN_FEE := NVL(PRM_TRAN_FEE,0);--Added on 03.09.2013 for DFCHOST-340
     ELSE
       IF V_FEEATTACH_FLAG = 0 THEN
       BEGIN
        SP_TRAN_FEES_PRODUCT_CMSAUTH(PRM_INST_CODE,
                                PRM_DEL_CHANNEL,
                                PRM_TRAN_TYPE,
                                PRM_TRAN_MODE,
                                PRM_TRAN_CODE,
                                PRM_CURRENCY_CODE,
                                PRM_TRN_AMT,
                                V_PROD_CODE,
                                PRM_CONSODIUM_CODE,
                                PRM_PARTNER_CODE,
                                PRM_TRN_DATE,
                                PRM_INTL_INDICATOR,
                                PRM_POS_VERIFICATION,
                                PRM_RESPONSE_CODE,
                                PRM_MSG_TYPE,
                                PRM_CARD_NUMBER,
                                V_REVERSAL_TXN, --Added by Deepa on June 25 2012 for Reversal txn Fee
                                PRM_REVERSAL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
                                PRM_MCC_CODE, --Added by Trivikram on 05-Sep-2012 for merchant catg code
                                v_preauth_flag ,--Added by Abdul Hameed for 15194
                                V_CR_DR_FLAG,--Added by Abdul Hameed for 15194
                                v_acct_number, --Added for OTC changes
                                V_FEE_CODE,
                                PRM_FLAT_FEES,
                                PRM_PER_FEES,
                                V_MIN_FEES,
                                V_FEEATTACH_FLAG,
                                PRM_FEEAMNT_TYPE,
                                PRM_CLAWBACK,
                                PRM_FEE_PLAN,
                                PRM_TRAN_FEE,
                                PRM_ERROR,
                                PRM_CRGL_CATG,
                                PRM_CRGL_CODE,
                                PRM_CRSUBGL_CODE,
                                PRM_CRACCT_NO,
                                PRM_DRGL_CATG,
                                PRM_DRGL_CODE,
                                PRM_DRSUBGL_CODE,
                                PRM_DRACCT_NO,
                                PRM_ST_CALC_FLAG,
                                PRM_CESS_CALC_FLAG,
                                PRM_ST_CRACCT_NO,
                                PRM_ST_DRACCT_NO,
                                PRM_CESS_CRACCT_NO,
                                PRM_CESS_DRACCT_NO,
                                PRM_FREETXN_EXCEED,--Added by Trivikram on 27-July-2012
                                PRM_DURATION, --Added by Trivikram on 27-July-2012
                                PRM_FEE_DESC, prm_complfree_flag, -- added for MVCSD-4471
                                prm_surchrg_ind);  --Added for VMS-5856
         EXCEPTION         --Added on 12-Aug-2013
          WHEN OTHERS THEN
            PRM_ERROR := 'Error in tran fee product category proc' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN;
        END;

        IF V_FEEATTACH_FLAG = -1 THEN
          --Error from tran_fees_card procedure
          PRM_ERROR := 'Error from fee attach  prod  proc   ' ||
                    PRM_ERROR;
          RETURN;
        END IF;
        IF V_FEEATTACH_FLAG = 1 THEN
          V_FEEATTACH_TYPE := 'P';
          PRM_ERROR        := 'OK';
          prm_fee_attach_type := 'P'; --Added by Trivikram on Sep 05 2012
          PRM_TRAN_FEE := NVL(PRM_TRAN_FEE,0);--Added on 03.09.2013 for DFCHOST-340
        ELSE
          IF V_FEEATTACH_FLAG = 0 THEN

            --  NO FEE ATTACHED AT PRODUCT CATG LEVEL

            PRM_ERROR := 'NO FEES ATTACHED';
            RAISE EXP_NOFEES; -- NO FEES ATTACHED RETURN -1
          ELSE
            RAISE EXP_MAIN; -- Error from  Procedure
          END IF;
        END IF;

       ELSE
        RAISE EXP_MAIN; -- Error from  Procedure
       END IF;
     END IF;
    ELSE
     RAISE EXP_MAIN;
    END IF;
  END IF;

END IF; --Added for MVCSD-5381
  PRM_FEE_CODE := V_FEE_CODE; -- Sn To Return  FEE_CODE
 Begin 
 select CFM_FEECAP_FLAG into v_feecap_flag from CMS_FEE_MAST 
 where CFM_INST_CODE = PRM_INST_CODE and CFM_FEE_CODE = V_FEE_CODE;
 EXCEPTION
    WHEN NO_DATA_FOUND THEN
       v_feecap_flag := '';
     WHEN OTHERS THEN
            PRM_ERROR := 'Error in feecap flag fetch ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN;
 End;
 if v_feecap_flag = 'Y' then 
  SP_TRAN_FEES_CAP(PRM_INST_CODE,
                    V_ACCT_NUMBER,
                    PRM_TRN_DATE,
                    PRM_TRAN_FEE,
                    PRM_FEE_PLAN,
                    V_FEE_CODE,
                    PRM_ERROR                 
                  ); -- Added for FWR-11
  End if;
EXCEPTION
  -- MAIN
  WHEN EXP_NOFEES THEN
    PRM_ERROR    := 'OK';
    PRM_TRAN_FEE := 0;
  WHEN EXP_MAIN THEN
    PRM_ERROR    := PRM_ERROR;
    PRM_TRAN_FEE := -1;
  WHEN OTHERS THEN
    PRM_ERROR    := SQLERRM;
    PRM_TRAN_FEE := -1;
END;
/
show error