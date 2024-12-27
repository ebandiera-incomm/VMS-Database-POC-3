create or replace
PROCEDURE                  vmscms.SP_CHNGE_CRDSTAT_CMSAUTH(P_INSTCODE      IN NUMBER,
                                           P_RRN           IN VARCHAR2,
                                           P_PAN           IN VARCHAR2,
                                           P_LUPDUSER      IN NUMBER,
                                           P_TXN_CODE      IN VARCHAR2,
                                           P_DELIVERY_CHNL IN VARCHAR2,
                                           P_MSG_TYPE      IN VARCHAR2,
                                           P_REVRSL_CODE   IN VARCHAR2,
                                           P_TXN_MODE      IN VARCHAR2,
                                           P_MBRNUMB       IN VARCHAR2,
                                           P_TRANDATE      IN VARCHAR2,
                                           P_TRANTIME      IN VARCHAR2,
                                           P_ANI           IN VARCHAR2,
                                           P_DNI           IN VARCHAR2,
                                           P_IPADDRESS     IN VARCHAR2,
                                           P_MERCHANT_NAME IN VARCHAR2,
                                           P_MERCHANT_CITY IN VARCHAR2,
                                           P_SPPRTKEY      IN VARCHAR2,  --Added by Pankaj S. on 19-Feb-2013 for FSS_391
                                           P_RESP_CODE     OUT VARCHAR2,
                                           P_ERRMSG        OUT VARCHAR2,
                                           P_ACCT_BAL       OUT VARCHAR2,--ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
                                           P_LEDGER_BAL       OUT VARCHAR2,--ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
                                           P_MEDAGATEREFID IN VARCHAR2 DEFAULT NULL) -- Added for Meda Gate Changes defect Id: MVHOST:381
   AS 
  /************************************************************************************************
   * modified by      : B.Besky
   * modified Date    : 06-NOV-12
   * modified reason  : Changes in Exception handling
   * Reviewer         : Saravanakumar
   * Reviewed Date    : 06-NOV-12
   * Build Number     :  CMS3.5.1_RI0021_B0003
   
   * Modified By      :  Pankaj S.
   * Modified Date    :  15-Feb-2013
   * Modified Reason  :  CLosing account with balance(FSS-193)
   * Reviewer         :  Dhiraj
   * Reviewed Date    :
   * Build Number     :  CMS3.5.1_RI0023.2_B0001

   * Modified By      :  Pankaj S.
   * Modified Date    :  19-Feb-2013
   * Modified Reason  :  Card replacement changes(FSS-391)
   * Reviewer         :  Dhiraj
   * Reviewed Date    :
   * Build Number     :  CMS3.5.1_RI0023.2_B0004

   * Modified By      :  Pankaj S.
   * Modified Date    :  27-Feb-2013
   * Modified Reason  :  Mantis ID-10422 (Description not change in account activity tab)
   * Reviewer         :  Dhiraj
   * Reviewed Date    :
   * Build Number     :  CMS3.5.1_RI0023.2_B0010

   * Modified By      :  Pankaj S.
   * Modified Date    :  01-Mar-2013
   * Modified Reason  :  Mantis ID-10252(card status 3 replaced by 2 for txn code-75)
   * Reviewer         :  Dhiraj
   * Reviewed Date    :
   * Build Number     :  CMS3.5.1_RI0023.2_B0011
   
   * Modified By      :  Sagar M.
   * Modified Date    :  21-Mar-2013
   * Modified For     :  FSS-922 
   * Modified Reason  :  If condition changed for V_KYC_FLAG 
                        (Card Got Changed to Active-Unregistered Mistakenly)
   * Reviewer         :  Dhiraj
   * Reviewed Date    :  21-Mar-2013
   * Build Number     :  RI0024_B0008
   
   * Modified By      :  Siva kumar M.
   * Modified Date    :  23-june-2013
   * Modified For     :  MVHOST-381(MedaGate Changes)
   * Modified Reason  :  Changes done for MedaGate Card Status Update API.
   * Reviewer         :  
   * Reviewed Date    :  
   * Build Number     :  RI0024.2_B0008
   
   * Modified By      :  Siva kumar M.
   * Modified Date    :  27-june-2013
   * Modified For     :  Defect id:11411 ,0011414(spelling mistake) 
   * Modified Reason  :  System closes an expired card with account balance available.
   * Reviewer         :  
   * Reviewed Date    :  
   * Build Number     : RI0024.2_B0009   
   
   * Modified By      :  Siva kumar M.
   * Modified Date    :  28-june-2013
   * Modified For     : Defect id:11441 
   * Modified Reason  : modified for logging transaction log and transaction log dtl entries for closed card.
   * Reviewer         :  
   * Reviewed Date    :  
   * Build Number     : RI0024.2_B0011   
   
   * Modified By      : Siva kumar M.
   * Modified Date    : 04-july-2013
   * Modified For     : Defect id:11450
   * Modified Reason  : 
   * Reviewer         :  
   * Reviewed Date    :  
   * Build Number     : RI0024.3_B0003  
   
   * Modified By      : Siva kumar M.
   * Modified Date    : 05-Aug-2013
   * Modified For     : Defect id:11450(Review Comments Changes)
   * Modified Reason  : 
   * Reviewer         : Dhiarj
   * Reviewed Date    : 05-Aug-2013 
   * Build Number     : RI0024.4_B0001
   
   * Modified By      : Ramesh.A
   * Modified Date    : 22-Aug-2013
   * Modified For     : MVCSD-4099 : 
   * Modified Reason  : Added pin_off validation for card activation
   * Reviewer         : Dhiraj
   * Reviewed Date    : 22-Aug-2013
   * Build Number     : RI0024.4_B0004
   
   * Modified By      : Sachin P.
   * Modified Date    : 29-AUG-2013
   * Modified For     : MVCSD-4099(Review)changes
   * Modified Reason  : Review changes
   * Reviewer         : Dhiraj
   * Reviewed Date    : 29-AUG-2013
   * Build Number     : RI0024.4_B0006  
   
   * Modified By      : RameshA
   * Modified Date    : 24-SEP-2013
   * Modified For     : mantis id: 12451 and 12437  
   * Reviewer         : Dhiraj
   * Reviewed Date    : 29-AUG-2013
   * Build Number     : RI0024.4_B0018   
   
   * Modified Date    : 10-Dec-2013
   * Modified By      : Sagar More
   * Modified for     : Defect ID 13160
   * Modified reason  : To log below details in transactinlog if applicable
                        Account Type,CR_DR_FLAG,error_msg
   * Reviewer         : Dhiraj
   * Reviewed Date    : 10-Dec-2013
   * Release Number   : RI0024.7_B0001     
   
     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893/EEP2.1
     * Modified Reason   : To return the ledger balance and available balance for medagate /Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 10-Mar-2014
     * Build Number      : RI0027.2_B0002 
   
     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13991
     * Modified Reason   : To return the updated ledger balance and available balance after fee calculation for medagate 
     * Modified Date     : 28-Mar-2014
     * Reviewer          : 
     * Reviewed Date     : 
     * Build Number      : 
     
     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13991
     * Modified Reason   : Modified for review comments
     * Modified Date     : 01-Apr-2014
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 02-April-2014
     * Build Number     : RI0027.2_B0003
     
     * Modified By      : Siva kumar M.
     * Modified Date    : 13-Nov-2014
     * Modified For     : Defect id:15857
     * Modified Reason  : package id and prod id impact changes.
     * Reviewer         :Spankaj
     * Build Number     : RI0027.4.3_B0004
     
     * Modified By          :  Pankaj S.
     * Modified Date      :  13-Sep-2016
     * Modified Reason  : Modified for 4.2.2 changes
     * Reviewer              : Saravanakumar
     * Build Number      :   4.2.2     
     
     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
    * Modified By      : Venkata Naga Sai S
    * Modified Date    : 05-SEP-2019
    * Modified For     : VMS-1067
    * Reviewer         : Saravanakumar
    * Release Number   : R20

  ********************************************************************************************/

  V_CAP_PROD_CATG CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_PROD_CODE     CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE     CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_CAP_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_REQ_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_RESONCODE     CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_TOPUP_AUTH_ID TRANSACTIONLOG.AUTH_ID%TYPE;
  V_SPPRT_KEY     CMS_SPPRT_REASONS.CSR_SPPRT_KEY%TYPE;
  V_ERRMSG        VARCHAR2(300);
  V_RESPCODE      VARCHAR2(5);
  V_RESPMSG       VARCHAR2(500);
  V_CAPTURE_DATE  DATE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BASE_CURR          CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_REMRK              VARCHAR2(100);
  V_ISPREPAID          BOOLEAN DEFAULT FALSE;
  V_CAP_CAFGEN_FLAG    CHAR(1);
  V_RRN_COUNT          NUMBER;
--  V_MMPOS_USAGEAMNT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
--  V_MMPOS_USAGELIMIT   CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN DATE;
  V_TRAN_DATE          DATE;
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BALANCE     NUMBER;
  V_AUTHID_DATE        VARCHAR2(8);

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);
  V_TXN_TYPE    VARCHAR2(2);
  V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
  V_KYC_FLAG CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;  -- Added by A.Sivakaminathan on 02-Oct-2012
   --Sn Added by Pankaj S. on 15-Feb-2013 for FSS-193
   V_CAP_CUST_CODE          cms_appl_pan.cap_cust_code%TYPE;
   v_ccount                 NUMBER (3);
   v_savngledgr_bal         cms_acct_mast.cam_ledger_bal%TYPE;
--En Added by Pankaj S. on 15-Feb-2013 for FSS-193
--Sn Added by Pankaj S. on 19-Feb-2013 for Card replacement changes (FSS-391)
  v_dup_check              NUMBER (3);
  v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;
  --En Added by Pankaj S. on 19-Feb-2013 for Card replacement changes (FSS-391)
  
  V_PROD_ID  CMS_PROD_CATTYPE.CPC_PROD_ID%TYPE; -- Added for Meda Gate Changes defect Id: MVHOST:381
  V_NEW_PAN_CODE        cms_appl_pan.cap_pan_code_encr%type;    -- Added for Meda Gate Changes defect Id: MVHOST:381   Modified on 05/Aug/2013 for review comment Changes.  
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;  -- Added for Meda Gate Changes defect Id: MVHOST:381   
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;             -- Added for Meda Gate Changes defect Id: MVHOST:381  
   v_hash_pan_temp      CMS_APPL_PAN.CAP_PAN_CODE%TYPE; -- added on 04/07/13 
   V_ENCR_PAN_temp           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   V_HASH_PAN_CODE           CMS_APPL_PAN.CAP_PAN_CODE%TYPE; -- Added  on 05/Aug/2013 for review comments Changes.
   v_pin_offset              CMS_APPL_PAN.cap_pin_off%TYPE; --Added for MVCSD-4099 on 22/08/2013
   v_timestamp       timestamp;     --Added on 29.08.2013 for MVCSD-4099(Review)changes
   v_appl_code       CMS_APPL_PAN.CAP_APPL_CODE%type;--Added on 29.08.2013 for MVCSD-4099(Review)changes
   
   v_acct_type cms_acct_mast.cam_type_code%type; --Added on 10-Dec-2013 for 13160
   
   V_CARD_ID            CMS_PROD_CATTYPE.CPC_CARD_ID%TYPE; -- ADDED for Mantis id:15857
   v_prod_type               cms_product_param.cpp_product_type%type; --Added for 4.2.2 changes
   v_profile_code       CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE; 

   v_user_type          cms_prod_cattype.CPC_USER_IDENTIFY_TYPE%type;
BEGIN
  P_ERRMSG   := 'OK';
  V_RESPCODE := '1';
  V_REMRK    := 'Online Card Status Change';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21'; -- added by chinmaya
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21'; -- added by chinmaya
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN create encr pan

  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
          DECODE(P_SPPRTKEY,NULL,CTM_TRAN_DESC,'CARD REPORT FOR DAMAGE')  --added by Pankaj S. for Mantis ID 0010422 
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC --Added for transaction detail report on 210812
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
     V_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHNL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_RESPCODE := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  --Sn Duplicate RRN Check

 /* BEGIN
  
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
         INSTCODE = P_INSTCODE AND DELIVERY_CHANNEL = P_DELIVERY_CHNL; --Added by ramkumar.Mk on 25 march 2012
  
    IF V_RRN_COUNT > 0 THEN
    
     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
  --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes   
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;    
    WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG  := 'Error while checking duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;  
  --En Added on 29.08.2013 for MVCSD-4099(Review)changes
  END;
*/

-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
BEGIN
     sp_dup_rrn_check (v_hash_pan, p_rrn, P_TRANDATE, P_DELIVERY_CHNL, P_MSG_TYPE, p_txn_code, V_ERRMSG );
      IF V_ERRMSG <> 'OK' THEN
        V_RESPCODE := '22';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESPCODE := '22';
      V_ERRMSG  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_MAIN_REJECT_RECORD;
    END;
  --En Duplicate RRN Check

  BEGIN
  
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');
  
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn select Pan detail
  BEGIN
    SELECT CAP_PROD_CATG,
         CAP_CARD_STAT,
         CAP_PROD_CODE,
         CAP_CARD_TYPE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_CUST_CODE, --Added by Pankaj S. on 15-Feb-2013 for FSS-193
         cap_pin_off ,--Added for MVCSD-4099 on 22/08/2013
         CAP_APPL_CODE --Added on 29.08.2013 for MVCSD-4099(Review)changes         
     INTO V_CAP_PROD_CATG,
         V_CAP_CARD_STAT,
         V_PROD_CODE,
         V_CARD_TYPE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         V_CAP_CUST_CODE, --Added by Pankaj S. on 15-Feb-2013 for FSS-193
         v_pin_offset,  --Added for MVCSD-4099 on 22/08/2013
         v_appl_code --Added on 29.08.2013 for MVCSD-4099(Review)changes     
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE AND
         CAP_MBR_NUMB = P_MBRNUMB;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
 

  --fOR REPORTS
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
     INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
     FROM CMS_ACCT_MAST
    WHERE /*(SELECT CAP_ACCT_NO 
            FROM CMS_APPL_PAN
           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE) AND*/
           --Added on 29.08.2013 for MVCSD-4099(Review)changes  
           CAM_INST_CODE = P_INSTCODE
        AND CAM_ACCT_NO =  V_ACCT_NUMBER 
      FOR UPDATE NOWAIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '14'; --Ineligible Transaction
   --  V_ERRMSG   := 'Invalid Card ';
     V_ERRMSG   := 'Invalid Account No ';  --Modified  on 01/04/2014 for review comment changes
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En select Pan detail
  --Sn Added for MVCSD-4099 on 22/08/2013
  IF p_delivery_chnl ='14' and p_txn_code = '07' then
    IF v_pin_offset is null  THEN 
        V_RESPCODE := '52';
        V_ERRMSG   := 'PIN Generation not done';
        RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END IF;      
  --End Added for MVCSD-4099 on 22/08/2013
  
  --Sn Added by Pankaj S. on 15-Feb-2013 for closing account with balance FSS-193
    IF ( p_txn_code = '83' OR  p_txn_code = '04' )  -- Added for Meda Gate Changes defect Id: MVHOST:381  
   THEN
      /* BEGIN
            SELECT COUNT (1)                              commented for defect id:11411
              INTO v_ccount
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode
               AND cap_acct_no = v_acct_number
               AND  cap_card_stat IN ('0', '1', '2','3','5','6','8','12');

         IF v_ccount = 1                                         
         THEN */
            IF v_acct_balance = 0 AND v_ledger_balance = 0 
            THEN 
               BEGIN
                  SELECT cam_ledger_bal
                    INTO v_savngledgr_bal
                    FROM cms_cust_acct, cms_acct_mast
                   WHERE cca_inst_code = cam_inst_code
                     AND cca_acct_id = cam_acct_id
                     AND cam_type_code = 2
                     AND cca_inst_code = p_instcode
                     AND cca_cust_code = v_cap_cust_code;

                  IF v_savngledgr_bal <> 0
                  THEN
                     v_errmsg :=
                        'To Close card saving account ledger balance should be 0';
                     SELECT DECODE (p_delivery_chnl, '10', '158', '04', '147', '07', '159')
                       INTO v_respcode
                       FROM DUAL; 
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                --SN Added on 29.08.2013 for MVCSD-4099(Review)changes
                  WHEN exp_main_reject_record
                  THEN 
                   RAISE;
                 --EN Added on 29.08.2013 for MVCSD-4099(Review)changes 
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
                 --SN Added on 29.08.2013 for MVCSD-4099(Review)changes                     
                  WHEN OTHERS
                  THEN      
                       v_errmsg :='Error while selecting ledger balance --'||substr(sqlerrm,1,200);
                       RAISE exp_main_reject_record;
                 --EN Added on 29.08.2013 for MVCSD-4099(Review)changes      
               END;  
            ELSE
               v_errmsg :=
                  'To Close card spending account available & ledger balance should be 0';
               SELECT DECODE (p_delivery_chnl, '10', '158', '04', '147', '07', '159','14','147')  -- Added for Meda Gate Changes defect Id: MVHOST:381  
                 INTO v_respcode
                 FROM DUAL;     
               RAISE exp_main_reject_record;
            END IF;
        -- END IF;
     -- END;
   END IF;

   --En Added by Pankaj S. on 15-Feb-2013 for closing account with balance FSS-193
   --Sn Added by Pankaj S. on 19-Feb-2013 for card replacement changes FSS-391
   BEGIN
      IF v_cap_card_stat = '3'
      THEN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_instcode
            AND chr_pan_code = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF v_dup_check > 0 AND p_txn_code <> '83' and p_txn_code <> '07'  -- Added for Meda Gate Changes defect Id: MVHOST:381  
         THEN
            v_errmsg := 'Only closing operation allowed for damage card';
            SELECT DECODE (p_delivery_chnl, '10', '159', '04', '148', '07', '160')
             INTO v_respcode
             FROM DUAL; 
            RAISE exp_main_reject_record;
         END IF;
   
      END IF;
   EXCEPTION
      --SN Added on 29.08.2013 for MVCSD-4099(Review)changes
     WHEN exp_main_reject_record
     THEN 
          RAISE;
     --EN Added on 29.08.2013 for MVCSD-4099(Review)changes 
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting damage card details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   --En Added by Pankaj S. on 19-Feb-2013 for card replacement changes FSS-391
   
   BEGIN
                               
           SELECT CPC_CARD_ID,CPC_PROFILE_CODE,nvl(CPC_USER_IDENTIFY_TYPE,'0')
             INTO V_CARD_ID,V_PROFILE_CODE, v_user_type
            FROM CMS_PROD_CATTYPE
            WHERE CPC_PROD_CODE=V_PROD_CODE
            AND CPC_CARD_TYPE=V_CARD_TYPE
            AND CPC_INST_CODE= P_INSTCODE;


           EXCEPTION
               WHEN OTHERS THEN
                 V_ERRMSG   := 'Error while selecting CARD,PROFILE FOR PROD_ID ' ||
                       SUBSTR(SQLERRM, 1, 200);
                 V_RESPCODE := '21';
                RAISE EXP_MAIN_REJECT_RECORD;
           END;
   
  BEGIN
--    SELECT CIP_PARAM_VALUE
--     INTO V_BASE_CURR
--       FROM CMS_INST_PARAM
--    WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';
    
    SELECT TRIM(cbp_param_value)  
	     INTO v_base_curr
    FROM cms_bin_param 
    WHERE cbp_param_name = 'Currency'
      AND cbp_inst_code= p_instcode
      AND cbp_profile_code = v_profile_code;
  
    IF TRIM(V_BASE_CURR) IS NULL THEN
     V_ERRMSG := 'Base currency cannot be null ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD -- this block added by chinmaya
    THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Base currency is not defined for the institution ';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting bese currecy  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;



  BEGIN
    SELECT DECODE(P_TXN_CODE,
               '75',
               'HTLST',
               '76',
               'BLOCK',
               '77',
               'DBLOK',
               '83',
               'CARDCLOSE',
                '04',         -- Added for Meda Gate Changes defect Id: MVHOST:381
                'CARDCLOSE',  -- Added for Meda Gate Changes defect Id: MVHOST:381
               '05',
               'BLOCK',
               '06',
               'DEBLOCK',
                '07',         -- Added for Meda Gate Changes defect Id: MVHOST:381
                'UNBLOKSPRT', -- Added for Meda Gate Changes defect Id: MVHOST:381
                '08',         -- Added for Meda Gate Changes defect Id: MVHOST:381
                'CARDONHOLD', -- Added for Meda Gate Changes defect Id: MVHOST:381
                '09',         -- Added for Meda Gate Changes defect Id: MVHOST:381
                'CARDEXPRED', -- Added for Meda Gate Changes defect Id: MVHOST:381
                '15',        -- Added for Meda Gate Changes defect Id: MVHOST:381
                'CARDDEACT')  -- Added for Meda Gate Changes defect Id: MVHOST:381
     INTO V_SPPRT_KEY
     FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting spprt key   for txn code' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '4' THEN
     V_RESPCODE := '14';
     V_ERRMSG   := 'Card Restricted';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    --Added by Ramkumar.mK, check the transaction code for Block and Deblock
    IF V_CAP_CARD_STAT = '2' AND P_TXN_CODE <> '06' AND P_TXN_CODE <> '77'  AND P_TXN_CODE <> '04'  AND P_TXN_CODE <> '09' THEN  -- Added condition "P_TXN_CODE <> '04'  AND P_TXN_CODE <> '09' " for Meda Gate Changes defect Id: MVHOST:381
     V_RESPCODE := '41';
     V_ERRMSG   := 'Lost Card';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '9' THEN
     V_RESPCODE := '46';
     V_ERRMSG   := 'Closed Card';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;

  BEGIN
    IF P_TXN_CODE = '05' AND V_CAP_CARD_STAT = '0' THEN
     V_RESPCODE := '10';
     V_ERRMSG   := 'Card Already Blocked';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    IF( (P_TXN_CODE = '06' AND V_CAP_CARD_STAT = '1' ) or  (P_TXN_CODE = '07' AND V_CAP_CARD_STAT = '1' )) THEN -- Added condition  "P_TXN_CODE = '07' AND V_CAP_CARD_STAT = '1'" for Meda Gate Changes defect Id: MVHOST:381
     V_RESPCODE := '9';
     V_ERRMSG   := 'Card Already Activated';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  
    -- ST -- Added for Meda Gate Changes defect Id: MVHOST:381
   BEGIN
    IF P_TXN_CODE = '08' AND V_CAP_CARD_STAT = '6' THEN
     V_RESPCODE := '172';
     V_ERRMSG   := 'Card On Hold';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  
   BEGIN
    IF P_TXN_CODE = '09' AND V_CAP_CARD_STAT = '7' THEN
     V_RESPCODE := '173';
     V_ERRMSG   := 'Card Expired';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  
     BEGIN
    IF P_TXN_CODE = '15' AND V_CAP_CARD_STAT = '0' THEN
     V_RESPCODE := '174';
     V_ERRMSG   := 'Card Already in Inactive Status'; --Modified for defect 0011414(spelling mistake) on 27/06/2013
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  
  
  -- EN -- Added for Meda Gate Changes defect Id: MVHOST:381
  
  
  IF P_TXN_CODE NOT IN ('05', '06') THEN
    BEGIN
     SELECT CSR_SPPRT_RSNCODE
       INTO V_RESONCODE
       FROM CMS_SPPRT_REASONS
      WHERE CSR_SPPRT_KEY = V_SPPRT_KEY AND CSR_INST_CODE = P_INSTCODE AND
           ROWNUM < 2;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Change status reason code not present in master';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error while selecting reason code from master' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  ELSE
    IF P_TXN_CODE = '05' THEN
     V_RESONCODE := 43;
    ELSE
     V_RESONCODE := 54;
    END IF;
  END IF;
  
   IF p_spprtkey IS NULL THEN  --Added by Pankaj S. on 19-Feb-2013 for card replacement changes (FSS-391)
          BEGIN
            -- Begin And End Block Added By Chinmaya
            SELECT DECODE(P_TXN_CODE,
                       '75',
                       '2',    --3 replaced by 2  as discussed with Shyam sir on 01_Mar_2013 for Mantis ID-10252
                       '76',
                       '2',
                       '77',
                       '1',
                       '83',
                       '9',
                       '04', -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '9',  -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '05',
                       '2',
                       '06',
                       '1',
                       '07',  -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '1',   -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '08',  -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '6',    -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '09',  -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '7',   -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '15',  -- Added for Meda Gate Changes defect Id: MVHOST:381
                       '0')   -- Added for Meda Gate Changes defect Id: MVHOST:381
             INTO V_REQ_CARD_STAT
             FROM DUAL;
            -- Begin And End Block Added By Chinmaya   
          EXCEPTION
            WHEN OTHERS THEN
             V_RESPCODE := '21';
             V_ERRMSG   := 'Error while selecting card stat  for support func' ||
                        SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_MAIN_REJECT_RECORD;
          END;
    --Sn Added by Pankaj S. on 19-Feb-2013 for card replacement changes FSS-391
  ELSE
   V_REQ_CARD_STAT:=P_SPPRTKEY;
   END IF;
  --En Added by Pankaj S. on 19-Feb-2013 for card replacement changes FSS-391


  --------------Sn For Debit Card No need using authorization -----------------------------------
 -- IF V_CAP_PROD_CATG = 'P' THEN
    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          P_MSG_TYPE,
                          P_RRN,
                          P_DELIVERY_CHNL,
                          NULL,
                          P_TXN_CODE,
                          P_TXN_MODE,
                          P_TRANDATE,
                          P_TRANTIME,
                          P_PAN,
                          NULL,
                          NULL,
                          P_MERCHANT_NAME,
                          P_MERCHANT_CITY,
                          NULL,
                          V_BASE_CURR,
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
                          NULL, -- P_stan
                          P_MBRNUMB, --Ins User
                          P_REVRSL_CODE, --Added by Deepa For Fee Calculation on June 26 2012
                          NULL,
                          V_TOPUP_AUTH_ID,
                          V_RESPCODE,
                          V_RESPMSG,
                          V_CAPTURE_DATE);
    
     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       V_ERRMSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;
    
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;
     WHEN EXP_MAIN_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error from Card authorization' || SQLERRM;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
 -- END IF;

  --------------------------En
  --En call to authorize txn
  
  --SN Added on 28/03/2014 for Mantis ID 13991 to return the updated acct balance after fee calculation
  
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
     INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
     FROM CMS_ACCT_MAST
    WHERE  CAM_INST_CODE = P_INSTCODE
        AND CAM_ACCT_NO =  V_ACCT_NUMBER 
      FOR UPDATE ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '14'; 
   --  V_ERRMSG   := 'Invalid Card ';
    V_ERRMSG   := 'Invalid Account No ';--Modified on 01/04/2014 for review comment changes
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  --EN  Added on 28/03/2014 for Mantis ID 13991 to return the updated acct balance after fee calculation
        --SN: Added for 4.2.2 changes       
        BEGIN
           SELECT UPPER (NVL (cpp_product_type, 'O'))
             INTO v_prod_type
             FROM cms_product_param
            WHERE cpp_prod_code = v_prod_code AND cpp_inst_code = p_instcode;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_respcode := '21';
              v_errmsg :=
                 'Error While selecting the product type' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
        --EN: Added for 4.2.2 changes
  
     --Sn Based on KYC flag, the system will change the status to Active-Unregistered or Active  
     -- Added by A.Sivakaminathan on 02-Oct-2012
     IF V_REQ_CARD_STAT = '1' and P_DELIVERY_CHNL <> '14'  THEN
     
        BEGIN
        
        --Sn Commented and Modified on 29.08.2013 for MVCSD-4099(Review)changes
           /* SELECT  CCI_KYC_FLAG
            INTO V_KYC_FLAG            
            FROM CMS_APPL_PAN, CMS_CAF_INFO_ENTRY 
            WHERE CAP_PAN_CODE = V_HASH_PAN
            AND CAP_INST_CODE = P_INSTCODE AND CAP_APPL_CODE = CCI_APPL_CODE;*/
            
            SELECT  CCI_KYC_FLAG
            INTO V_KYC_FLAG            
            FROM  CMS_CAF_INFO_ENTRY 
            WHERE CCI_INST_CODE = P_INSTCODE 
            AND CCI_APPL_CODE = to_char(v_appl_code);
                        
         --En Commented and Modified on 29.08.2013 for MVCSD-4099(Review)changes
            
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while selecting KYC flag ' ||
                       SUBSTR(SQLERRM, 1, 200);
            V_RESPCODE := '21';
            RAISE EXP_MAIN_REJECT_RECORD;
        END;
       
       /*                                  --Commented on 21-Mar-2013 for FSS-922          
        IF V_KYC_FLAG <> 'Y' THEN
            V_REQ_CARD_STAT := '13';
        END IF;
       */ 
        
        IF V_KYC_FLAG not in ('Y','P','O','I') --Added on 21-Mar-2013 for FSS-922
             AND v_prod_type<>'C' THEN --Added for 4.2.2 changes
              IF v_user_type in ('1','4') and V_KYC_FLAG ='N' then
                 V_REQ_CARD_STAT := '1';
                 else
                 V_REQ_CARD_STAT:= '13';
              END IF; 
/*      ELSE
            V_REQ_CARD_STAT := '13';*/
            
        END IF;        
       
                
     END IF;
     --En Based on KYC flag, the system will change the status to Active-Unregistered or Active
     
     --  ST Added for Meda Gate Changes defect Id: MVHOST:381
     
      IF V_REQ_CARD_STAT = '1' AND  P_DELIVERY_CHNL = '14'  AND P_TXN_CODE ='07' THEN
      
           v_hash_pan_temp :=V_HASH_PAN;  -- added on 04/07/13 
           V_ENCR_PAN_temp := V_ENCR_PAN;
          
           if V_CAP_CARD_STAT ='3' then
              
              begin
                --SELECT  fn_dmaps_main(chr_new_pan_encr)  -- Modified on 05/Aug/2013 for review comments Changes.
                SELECT  CHR_NEW_PAN,chr_new_pan_encr
                INTO   V_HASH_PAN_CODE,V_NEW_PAN_CODE
                  FROM cms_htlst_reisu
                  WHERE chr_inst_code =P_INSTCODE
                  AND chr_pan_code  = V_HASH_PAN
                  AND chr_reisu_cause = 'R'
                  AND chr_new_pan IS NOT NULL;
              EXCEPTION 
          
                 WHEN NO_DATA_FOUND THEN
            
                 V_NEW_PAN_CODE:= NULL;
                              
                 WHEN OTHERS
                         THEN
                  v_respcode := '21';
                  v_errmsg :=
                       'Error while selecting  card details '
                                       || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_main_reject_record;
                end;
                
            -- getting the old pan number by passing replaced card number. Changes done for defect ID:11450
          else  
              
                begin
                  
                  -- SELECT  fn_dmaps_main(CHR_PAN_CODE_ENCR) -- Modified on 05/aug/2013 for review comments Changes.
                   SELECT  CHR_PAN_CODE,CHR_PAN_CODE_ENCR
                          INTO V_HASH_PAN,V_NEW_PAN_CODE 
                              FROM cms_htlst_reisu
                              WHERE chr_inst_code =P_INSTCODE
                              AND chr_new_pan  = V_HASH_PAN
                              AND chr_reisu_cause = 'R'
                              AND chr_new_pan IS NOT NULL;
                  EXCEPTION 
                  
                   WHEN NO_DATA_FOUND THEN
                    
                   V_NEW_PAN_CODE:= NULL;
                                     
                    WHEN OTHERS
                                 THEN
                         v_respcode := '21';
                         v_errmsg :=
                               'Error while selecting  card details '
                                               || SUBSTR (SQLERRM, 1, 100);
                      RAISE exp_main_reject_record;
               end;
           
              V_ENCR_PAN:=V_NEW_PAN_CODE; --added on 05/aug/2013 for review comments Changes.                   
           /* -- Commented 0n 05/Aug/2013 for review comments Changes.
                if V_NEW_PAN_CODE IS NOT NULL then
                
                  BEGIN
                            V_HASH_PAN := GETHASH(V_NEW_PAN_CODE);
                  EXCEPTION
                      WHEN OTHERS THEN
                        V_RESPCODE := '21'; 
                               V_ERRMSG   := 'Error while converting pan ' ||
                                           SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_MAIN_REJECT_RECORD;
                  END;
                  
                  
                   BEGIN
                     
                   V_ENCR_PAN := FN_EMAPS_MAIN(V_NEW_PAN_CODE);
                   EXCEPTION
                       WHEN OTHERS THEN
                         V_RESPCODE := '21'; 
                         V_ERRMSG   := 'Error while converting pan ' ||
                                    SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_MAIN_REJECT_RECORD;
                      END;
                
                end if;
                */
           
          end if;      
           
             IF  V_NEW_PAN_CODE IS NOT NULL   THEN
             
                 BEGIN
                     
                     UPDATE CMS_APPL_PAN SET CAP_CARD_STAT='9'
                     WHERE CAP_PAN_CODE=V_HASH_PAN
                     AND   CAP_INST_CODE = P_INSTCODE
                     AND   CAP_MBR_NUMB = P_MBRNUMB;
                     
                     IF SQL%ROWCOUNT !=1 THEN
                     
                      V_RESPCODE := '21';
                      V_ERRMSG   := 'Problem in updation of old card status.' || 
                                                               SUBSTR(SQLERRM, 1, 200);
                       RAISE EXP_MAIN_REJECT_RECORD;
                  
                  
                     END IF;
                     
                 EXCEPTION
                 
                  WHEN EXP_MAIN_REJECT_RECORD THEN
                       RAISE;
                       
                  WHEN OTHERS THEN
                    V_RESPCODE := '21';
                    V_ERRMSG   := 'Error ocurs while old card status  ' ||
                                       SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;      
                 
                 END;
                            -- modified for logging transaction log and transaction log dtl entries for closed card.
                 BEGIN
                       sp_log_cardstat_chnge (P_INSTCODE,
                                              V_HASH_PAN,
                                              V_ENCR_PAN , 
                                              V_TOPUP_AUTH_ID,
                                              '02',
                                              p_rrn,
                                              p_trandate,
                                              p_trantime,
                                              V_RESPCODE,
                                              V_ERRMSG
                                             );

                   IF V_RESPCODE <> '00' AND V_ERRMSG <> 'OK'
                   THEN
                      RAISE EXP_MAIN_REJECT_RECORD;
                   END IF;
                   
                 EXCEPTION
                           WHEN EXP_MAIN_REJECT_RECORD
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              V_RESPCODE := '21';
                              V_ERRMSG :=
                                    'Error while logging system initiated card status change '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE EXP_MAIN_REJECT_RECORD;
                 END;
                      
                 if V_CAP_CARD_STAT ='3' then
                 
                      V_HASH_PAN := V_HASH_PAN_CODE; -- Added on 05/Aug/2013 for review comments Changes.
                      V_ENCR_PAN := V_NEW_PAN_CODE;  -- Added on 05/Aug/2013 for review comments Changes.
                 /* -- commented  on 05/aug/2013 for review comments Changes.
                   BEGIN
                        V_HASH_PAN := GETHASH(V_NEW_PAN_CODE);
                  EXCEPTION
                      WHEN OTHERS THEN
                        V_RESPCODE := '21'; 
                               V_ERRMSG   := 'Error while converting pan ' ||
                                           SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_MAIN_REJECT_RECORD;
                  END;
                  
                  
                    BEGIN
                     
                       V_ENCR_PAN := FN_EMAPS_MAIN(V_NEW_PAN_CODE);
                      EXCEPTION
                        WHEN OTHERS THEN
                         V_RESPCODE := '21'; 
                         V_ERRMSG   := 'Error while converting pan ' ||
                                    SUBSTR(SQLERRM, 1, 200);
                         RAISE EXP_MAIN_REJECT_RECORD;
                      END;
                      */
                  else
                  
                  V_HASH_PAN := v_hash_pan_temp;
                  V_ENCR_PAN := V_ENCR_PAN_temp;
                  
                  end if;
                
             END IF;
             
             
           BEGIN
                SELECT  CAP_PROD_CODE,
                        CAP_CARD_TYPE, 
                        cap_prfl_code, 
                        cap_prfl_levl                                             
                 INTO V_PROD_CODE,
                      V_CARD_TYPE,
                      v_lmtprfl,
                       v_profile_level                           
                    FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN
                 AND  CAP_INST_CODE = P_INSTCODE 
                 AND  CAP_MBR_NUMB = P_MBRNUMB;
              EXCEPTION
                WHEN EXP_MAIN_REJECT_RECORD THEN
                 RAISE;
                WHEN NO_DATA_FOUND THEN
                   v_respcode := '16';                        
                   v_errmsg := 'Card number not found' || p_txn_code;
                   RAISE exp_main_reject_record;
                WHEN OTHERS THEN
                 V_RESPCODE := '21';
                 V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
                 RAISE EXP_MAIN_REJECT_RECORD;
           END;
                      
                      
           IF v_lmtprfl IS NULL OR v_profile_level IS NULL  
                  THEN
                       BEGIN
                     SELECT cpl_lmtprfl_id
                       INTO v_lmtprfl
                       FROM cms_prdcattype_lmtprfl
                      WHERE cpl_inst_code = P_INSTCODE
                        AND cpl_prod_code = v_prod_code
                        AND cpl_card_type = V_CARD_TYPE;

                     v_profile_level := 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                           SELECT cpl_lmtprfl_id
                             INTO v_lmtprfl
                             FROM cms_prod_lmtprfl
                            WHERE cpl_inst_code = P_INSTCODE
                              AND cpl_prod_code = v_prod_code;

                           v_profile_level := 3;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              NULL;
                           WHEN OTHERS
                           THEN
                              v_respcode := '21';
                              V_ERRMSG:=
                                    'Error while selecting Limit Profile At Product Level'
                                 || SQLERRM;
                              RAISE exp_main_reject_record;
                        END;
                     WHEN OTHERS
                     THEN
                        v_respcode := '21';
                       V_ERRMSG :=
                              'Error while selecting Limit Profile At Product Catagory Level'
                           || SQLERRM;
                        RAISE exp_main_reject_record;
                  END;
          END IF;                                          
                -- if limits are attached then we need update.
           IF v_lmtprfl IS NOT NULL    THEN   
                                                           
              BEGIN
                 UPDATE cms_appl_pan
                    SET cap_prfl_code = v_lmtprfl,
                        cap_prfl_levl = v_profile_level
                   WHERE  cap_inst_code =P_INSTCODE 
                   AND cap_pan_code = v_hash_pan;
                 IF SQL%ROWCOUNT = 0
                 THEN
                    v_respcode := '21';
                    v_errmsg := 'Limit Profile not updated for :' || v_hash_pan;
                    RAISE exp_main_reject_record;
                 END IF;
              EXCEPTION
                 WHEN exp_main_reject_record
                 THEN
                    RAISE exp_main_reject_record;
                 WHEN OTHERS
                 THEN
                    v_respcode := '21';
                    v_errmsg :=
                       'Error while Limit profile Update '
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_main_reject_record;
              END;
                      
           END IF;
             
        
           BEGIN
              UPDATE CMS_APPL_PAN
               SET CAP_ACTIVE_DATE=nvl(CAP_ACTIVE_DATE,SYSDATE), -- added for defect Id 11450
                   CAP_FIRSTTIME_TOPUP='Y'
               WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN AND
                           CAP_MBR_NUMB = P_MBRNUMB;
                 IF SQL%ROWCOUNT !=1 THEN
                 
                  V_RESPCODE := '21';
                  V_ERRMSG   := 'Problem in updation of first time topup flag.';
                  RAISE EXP_MAIN_REJECT_RECORD;
                          
                 END IF;
          EXCEPTION
                      
              WHEN EXP_MAIN_REJECT_RECORD THEN
                 RAISE;
                
             WHEN OTHERS THEN
                V_RESPCODE := '21';
                V_ERRMSG   := 'Error ocurs while updating first time topup flag ' ||
                                   SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
                         
             
          END;   
          
            BEGIN
                
                 UPDATE CMS_CAF_INFO_ENTRY
                   SET CCI_KYC_FLAG=CASE WHEN v_prod_type='C' THEN CCI_KYC_FLAG ELSE  'Y' END --Modified for 4.2.2 changes
                  WHERE  CCI_APPL_CODE=to_char((SELECT CAP_APPL_CODE FROM CMS_APPL_PAN
                                         WHERE CAP_PAN_CODE = V_HASH_PAN
                                          AND CAP_INST_CODE = P_INSTCODE ))
                    AND CCI_INST_CODE=P_INSTCODE;
                        
               IF SQL%ROWCOUNT !=1 THEN
                 
                  V_RESPCODE := '21';
                  V_ERRMSG   := 'Problem in updation of KYC  flag.';
                  RAISE EXP_MAIN_REJECT_RECORD;
                          
                 END IF;
             
           EXCEPTION
           
               WHEN EXP_MAIN_REJECT_RECORD THEN
                 RAISE;
                
                WHEN OTHERS THEN
                    V_RESPCODE := '21';
                    V_ERRMSG   := 'Error ocurs while updating KYC  flag ' ||
                                   SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;
           
           END;
           
        -- IF V_PROD_ID is NOT NULL THEN    COMMENTED FOR PACKAGE ID /PROD ID IMPACT CHANGES.
        if   V_CARD_ID IS NOT NULL THEN

             BEGIN
               UPDATE CMS_CARDISSUANCE_STATUS
               SET CCS_CARD_STATUS='15'
               WHERE CCS_PAN_CODE=V_HASH_PAN
               AND CCS_INST_CODE=P_INSTCODE;
               
               --Sn Added on 30.08.2013 for MVCSD-4099(Review)changes
               IF SQL%ROWCOUNT = 0 THEN                
                    V_RESPCODE := '21';
                    V_ERRMSG   := 'No Records updated in CARDISSUANCE_STATUS ';                                   
                    RAISE EXP_MAIN_REJECT_RECORD;
               
               END IF;               
               --En Added on 30.08.2013 for MVCSD-4099(Review)changes
               
                                    
             EXCEPTION
             --Sn Added on 30.08.2013 for MVCSD-4099(Review)changes
              WHEN EXP_MAIN_REJECT_RECORD then
                RAISE; 
             --En Added on 30.08.2013 for MVCSD-4099(Review)changes            
              WHEN OTHERS THEN
                    V_RESPCODE := '21';
                    V_ERRMSG   := 'Error ocurs while updating applicationn status ' ||
                                   SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;
             END;
             
         END IF;
      
     END IF;
  --  EN Added for Meda Gate Changes defect Id: MVHOST:381

  BEGIN
    --Begin 2 starts
    UPDATE CMS_APPL_PAN
      SET CAP_CARD_STAT = V_REQ_CARD_STAT
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN AND
         CAP_MBR_NUMB = P_MBRNUMB;
  
    IF SQL%ROWCOUNT != 1 THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Problem in updation of status for pan ' || P_PAN || '.';
     RAISE EXP_MAIN_REJECT_RECORD; -- added by chinmaya
    END IF;
    IF P_TXN_CODE IN ('06', '77') THEN
       --SN Added exception on 29.08.2013 for MVCSD-4099(Review)changes
         BEGIN
         UPDATE CMS_PIN_CHECK
            SET CPC_PIN_COUNT = 0,
               CPC_LUPD_DATE = TO_DATE(P_TRANDATE, 'YYYY/MM/DD')
          WHERE CPC_INST_CODE = P_INSTCODE AND CPC_PAN_CODE = V_HASH_PAN;
          
          /* Commented for mantis id :12451 on 24/09/2013
            IF SQL%ROWCOUNT = 0 THEN
                V_RESPCODE := '21';
                V_ERRMSG   := 'No record updated in PIN_CHECK for pan ' || P_PAN || '.';
            RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          */
         EXCEPTION
         WHEN EXP_MAIN_REJECT_RECORD     
         THEN     
         RAISE;
         WHEN OTHERS THEN
             V_RESPCODE := '21';
             V_ERRMSG   := 'Error ocurs while updating PIN_CHECK-- ' ||
                        SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;  
         END; 
       --SN Added exception on 29.08.2013 for MVCSD-4099(Review)changes  
    END IF;
  EXCEPTION    --excp of begin 2
    WHEN EXP_MAIN_REJECT_RECORD -- added by chinmaya
    THEN
     RAISE;
    
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error ocurs while updating card status-- ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD; -- added by chinmaya
  END; --begin 2 ends

  ------------------------------find member number end------------------------------
  BEGIN
    INSERT INTO CMS_PAN_SPPRT
     (CPS_INST_CODE,
      CPS_PAN_CODE,
      CPS_MBR_NUMB,
      CPS_PROD_CATG,
      CPS_SPPRT_KEY,
      CPS_SPPRT_RSNCODE,
      CPS_FUNC_REMARK,
      CPS_INS_USER,
      CPS_LUPD_USER,
      CPS_CMD_MODE,
      CPS_PAN_CODE_ENCR)
    VALUES
     (P_INSTCODE,
      V_HASH_PAN,
      P_MBRNUMB,
      V_CAP_PROD_CATG,
      DECODE(P_TXN_CODE,
            '75',
            'HTLST',
            '76',
            'BLOCK',
            '77',
            'DBLOK',
            '83',
            'CARDCLOSE',
            '04',          -- Added for Meda Gate Changes defect Id: MVHOST:381
            'CARDCLOSE',   -- Added for Meda Gate Changes defect Id: MVHOST:381
            '05',
            'BLOCK',
            '06',
            'DEBLOCK',
            '07',         -- Added for Meda Gate Changes defect Id: MVHOST:381
            'UNBLOKSPRT', -- Added for Meda Gate Changes defect Id: MVHOST:381
            '08',         -- Added for Meda Gate Changes defect Id: MVHOST:381
            'CARDONHOLD',  -- Added for Meda Gate Changes defect Id: MVHOST:381
            '09',          -- Added for Meda Gate Changes defect Id: MVHOST:381
            'CARDEXPRED', -- Added for Meda Gate Changes defect Id: MVHOST:381
            '15',          -- Added for Meda Gate Changes defect Id: MVHOST:381
            'CARDDEACT'),   -- Added for Meda Gate Changes defect Id: MVHOST:381
      V_RESONCODE,
      V_REMRK,
      P_LUPDUSER,
      P_LUPDUSER,
      0,
      V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while inserting records into card support master' ||
                SUBSTR(SQLERRM, 1, 200);
    
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En create a record in pan spprt

/*
  ---Sn Updation of Usage limit and amount
  BEGIN
    SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
     INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
     FROM CMS_TRANSLIMIT_CHECK
    WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
         CTC_MBR_NUMB = P_MBRNUMB;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;


  BEGIN
  
    --Sn Usage limit and amount updation for MMPOS
    IF P_DELIVERY_CHNL = '04' THEN
     IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
       V_MMPOS_USAGELIMIT := 1;
       BEGIN
        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_TRANDATE || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0
         WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBRNUMB;
              
        --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 1 CMS_TRANSLIMIT_CHECK';                                               
               V_RESPCODE := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes   
              
       EXCEPTION
       --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes
       WHEN EXP_MAIN_REJECT_RECORD
       THEN 
         RAISE;
      --En Added on 29.08.2013 for MVCSD-4099(Review)changes  
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 200);
          V_RESPCODE := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     ELSE
       V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
     
       BEGIN
        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
         WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBRNUMB;
            
          --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 2 CMS_TRANSLIMIT_CHECK';                             
               V_RESPCODE := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes     
              
       EXCEPTION
       --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes
       WHEN EXP_MAIN_REJECT_RECORD
       THEN 
         RAISE;
      --En Added on 29.08.2013 for MVCSD-4099(Review)changes  
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 200);
          V_RESPCODE := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     END IF;
    END IF;
    --En Usage limit and amount updation for MMPOS
  
  END;

*/
  ---En Updation of Usage limit and amount

  P_RESP_CODE := V_RESPCODE;
  
  IF V_REQ_CARD_STAT = '1' AND  P_DELIVERY_CHNL = '14'  AND P_TXN_CODE ='07' THEN --added for  updating  transaction log   entry for new  card.
   begin
     UPDATE TRANSACTIONLOG 
     SET CUSTOMER_CARD_NO=V_HASH_PAN,
     CUSTOMER_CARD_NO_ENCR=FN_EMAPS_MAIN(P_PAN), --V_ENCR_PAN, --Modified on 24/09/2013 for mantis id :12437
     CARDSTATUS='1',
     PRODUCTID=V_PROD_CODE,
     CATEGORYID=V_CARD_TYPE,
     MEDAGATEREF_ID=P_MEDAGATEREFID
     WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
             TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG_TYPE AND
             BUSINESS_TIME = P_TRANTIME AND
             DELIVERY_CHANNEL = P_DELIVERY_CHNL;
             
         --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 1 TRANSACTIONLOG';                             
               V_RESPCODE := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes         
             
    EXCEPTION
     --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes
       WHEN EXP_MAIN_REJECT_RECORD
       THEN 
         RAISE;
      --En Added on 29.08.2013 for MVCSD-4099(Review)changes      
      WHEN OTHERS THEN
         P_RESP_CODE := '69';
         P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                     SUBSTR(SQLERRM, 1, 300); 
     end;
  
  ELSE
  
      BEGIN
        UPDATE TRANSACTIONLOG
          SET ANI = P_ANI, DNI = P_DNI, IPADDRESS = P_IPADDRESS,
                    TRANS_DESC=V_TRANS_DESC, --added by Pankaj S. for Mantis ID 0010422 
                    MEDAGATEREF_ID=P_MEDAGATEREFID -- Added for medagate changes defect Id:MVHOST-381
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
             TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG_TYPE AND
             BUSINESS_TIME = P_TRANTIME AND
             DELIVERY_CHANNEL = P_DELIVERY_CHNL;
             
          --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 2 TRANSACTIONLOG';                             
               V_RESPCODE := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes         
              
      EXCEPTION
       --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes
       WHEN EXP_MAIN_REJECT_RECORD
       THEN 
         RAISE;
      --En Added on 29.08.2013 for MVCSD-4099(Review)changes  
        WHEN OTHERS THEN
         P_RESP_CODE := '69';
         P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                     SUBSTR(SQLERRM, 1, 300);
      END;
  END IF;
  
    
 P_ACCT_BAL:=V_ACCT_BALANCE;--ADDED BY BY ABDUL HAMEED M.A. FOR EEP2.1
 P_LEDGER_BAL:=V_LEDGER_BALANCE;    --ADDED BY BY ABDUL HAMEED M.A. FOR EEP2.1
 
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    --ROLLBACK;
  
    P_ERRMSG    := V_ERRMSG;
    P_RESP_CODE := V_RESPCODE; 


  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INSTCODE) AND
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
   
   /* ---Sn Updation of Usage limit and amount
    BEGIN
     SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
       INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = P_MBRNUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
   
   
    BEGIN
    
     --Sn Usage limit and amount updation for MMPOS
     IF P_DELIVERY_CHNL = '04' THEN
       IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
        V_MMPOS_USAGELIMIT := 1;
        BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_AMT     = 0,
                CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
                CTC_ATMUSAGE_AMT       = 0,
                CTC_ATMUSAGE_LIMIT     = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRANDATE || '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_POSUSAGE_AMT       = 0,
                CTC_POSUSAGE_LIMIT     = 0
           WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBRNUMB;
                
          --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 5 CMS_TRANSLIMIT_CHECK';                                               
               V_RESPCODE := '21';              
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes     
        EXCEPTION       
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||
                       SUBSTR(SQLERRM, 1, 200);
            V_RESPCODE := '21';
           -- RAISE EXP_MAIN_REJECT_RECORD; --Commented on 29.08.2013 for MVCSD-4099(Review)changes     
        END;
       ELSE
        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
        BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
           WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBRNUMB;
         --Sn Added on 29.08.2013 for MVCSD-4099(Review)changes      
           IF SQL%ROWCOUNT = 0 
           THEN 
               V_ERRMSG   := 'No RECORDS UPDATED IN 6 CMS_TRANSLIMIT_CHECK';                                               
               V_RESPCODE := '21';              
           END IF;   
        --En Added on 29.08.2013 for MVCSD-4099(Review)changes        
                
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||
                       SUBSTR(SQLERRM, 1, 200);
            V_RESPCODE := '21';
            --RAISE EXP_MAIN_REJECT_RECORD;--Commented on 29.08.2013 for MVCSD-4099(Review)changes
        END;
       END IF;
     END IF;
     --En Usage limit and amount updation for MMPOS
    
    END;
  
    ---En Updation of Usage limit and amount
 */ 
    --Sn generate auth id
    BEGIN
     --   SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
    
     -- SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
       INTO V_TOPUP_AUTH_ID
       FROM DUAL;
    
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21'; -- Server Declined
    
    END;
  
    --En generate auth id
  
    --Sn select response code and insert record into txn log dtl
    BEGIN
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
    
     -- Assign the response code to the out parameter
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
           CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;
    
    --SN Added on 29.08.2013 for MVCSD-4099(Review)changes
    v_timestamp := systimestamp;
    
    IF V_CAP_CARD_STAT IS NULL THEN
      BEGIN
        SELECT CAP_CARD_STAT                  
         INTO V_CAP_CARD_STAT              
         FROM CMS_APPL_PAN
        WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE AND
             CAP_MBR_NUMB = P_MBRNUMB;
      EXCEPTION    
        WHEN NO_DATA_FOUND THEN
         NULL;
        WHEN OTHERS THEN
         NULL;
      END;
    END IF;  
       --EN Added on 29.08.2013 for MVCSD-4099(Review)changes
       
    if V_DR_CR_FLAG is null
    then    
       
      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
         INTO V_DR_CR_FLAG
         FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
             CTM_DELIVERY_CHANNEL = P_DELIVERY_CHNL AND
             CTM_INST_CODE = P_INSTCODE;
      EXCEPTION WHEN OTHERS THEN
        null;
      END;       
   end if;     
      
    --Sn create a entry in txn log
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
        IPADDRESS,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        MEDAGATEREF_ID ,  -- Added for Meda Gate Changes defect Id: MVHOST:381
        TIME_STAMP, --Added on 29.08.2013 for MVCSD-4099(Review)changes
        --Added on 10-Dec-2013 for 13160
        acct_type,
        cr_dr_flag,
        error_msg
        --Added on 10-Dec-2013 for 13160        
        )
     VALUES
       (P_MSG_TYPE,
        P_RRN,
        P_DELIVERY_CHNL,
        NULL,
        SYSDATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INSTCODE,
        '0.00',--NULL,      --Null commented on 10-Dec-2013 for 13160 
        NULL,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        NULL,
        V_TOPUP_AUTH_ID,
        '0.00',--NULL,        --Null commented on 10-Dec-2013 for 13160  
        '0.00',--NULL,        --Null commented on 10-Dec-2013 for 13160  
        '0.00',--NULL,        --Null commented on 10-Dec-2013 for 13160
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_REVRSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        P_RESP_CODE,
        P_ANI,
        P_DNI,
        P_IPADDRESS,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRANS_DESC, -- FOR Transaction detail report issue
        P_MEDAGATEREFID,  -- Added for Meda Gate Changes defect Id: MVHOST:381
        v_timestamp, --Added on 29.08.2013 for MVCSD-4099(Review)changes
        --Added on 10-Dec-2013 for 13160
        v_acct_type,
        v_dr_cr_flag,
        V_ERRMSG
        --Added on 10-Dec-2013 for 13160
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;
  
    --Sn Create an entry in transaction_log_dtl
  
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
       (P_DELIVERY_CHNL,
        P_TXN_CODE,
        P_MSG_TYPE,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        V_TXN_TYPE);
    
     P_ERRMSG := V_ERRMSG;
     RETURN;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69'; --'22';    changed to 69 chinmaya                           -- Server Declined
       ROLLBACK;
       RETURN;
    END;
    --En Create an entry in transaction_log_dtl

END;
/
show error