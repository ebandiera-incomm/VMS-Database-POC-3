SET DEFINE OFF;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_IVR_GPR_CARD_ACTIVATION (P_INSTCODE         IN NUMBER,
                                            P_CARDNUM          IN VARCHAR2,
                                            P_RRN              IN VARCHAR2,
                                            P_TRANDATE         IN VARCHAR2,
                                            P_TRANTIME         IN VARCHAR2,
                                            P_TXN_CODE         IN VARCHAR2,
                                            P_DELIVERY_CHANNEL IN VARCHAR2,
                                            P_ANI              IN VARCHAR2,
                                            P_DNI              IN VARCHAR2,
                                            P_RESP_CODE        OUT VARCHAR2,
                                            P_EXP_DATE         OUT VARCHAR2,
                                            P_SRV_CODE         OUT VARCHAR2,
                                            P_TABLE_PINOFF     OUT VARCHAR2,
                                            P_ERRMSG           OUT VARCHAR2,
                                            p_closed_card      OUT VARCHAR2,
                                            p_activation_code_in IN VARCHAR2
                                          ) AS

  /*************************************************
    * Created Date     :  20-Feb-2012
    * Created By       :  Sivapragasam
    * PURPOSE          :  For GPR Card Activation
    * Modified By      :  B.Besky
    * Modified Date    :  08-nov-12
    * Modified Reason  : Logging Customer Account number in to transactionlog table.
    * Reviewer         :  Saravanakumar
    * Reviewed Date    : 19-nov-12
    * Release Number     :  CMS3.5.1_RI0022_B0002

    * Modified By      :  Pankaj S.
    * Modified Date    :  15-Feb-13
    * Modified Reason  : Multiple SSN check & card replacement changes
    * Reviewer         : Dhiraj
    * Reviewed Date    :
    * Release Number   :
    
    * Modified By      : Pankaj S.
    * Modified Date    : 15-Mar-2013
    * Modified Reason  : Logging of system initiated card status change(FSS-390)
    * Reviewer         : Dhiraj
    * Reviewed Date    : 
    * Build Number     :  CMS3.5.1_RI0024_B0008
  
    * Modified By      : Ramesh
    * Modified Date    : 01-Apr-2013
    * Modified Reason  : Mantis DI 10766
    * Reviewer         : Dhiraj
    * Reviewed Date    : 
    * Build Number     : CMS3.5.1_RI0024_B0017    


 
    * Modified By      : Siva Kumar M
    * Modified Date    : 14/Sept/2013
    * Modified Reason  : MVCSD-4099 Additional changes
    * Reviewer         : dhiraj
    * Reviewed Date    : 
    * Build Number     : RI0024.4_B0012
    
    * Modified By      : Siva Kumar A
    * Modified Date    : 05/DEC/2013
    * Modified Reason  : Mantis-12153
    * Reviewer         : Dhiraj
    * Reviewed Date    : 05/DEC/2013
    * Build Number     : RI0024.7_B0001
    
    * Modified Date    : 16-Dec-2013
    * Modified By      : Sagar More
    * Modified for     : Defect ID 13160
    * Modified reason  : To log below details in transactinlog if applicable
                         Acct_type,timestamp,dr_cr_flag,product code,cardtype,error_msg
    * Reviewer         : Dhiraj
    * Reviewed Date    : 16-Dec-2013
    * Release Number   : RI0024.7_B0002
    
    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal
    * Modified Date    : 13-May-2015
    * Reviewer         :  Saravanankumar
    * Build Number     : VMSGPRHOAT_3.0.3_B0001
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 23-June-15
    * Modified For         : MVCAN-77
    * Modified reason      : Canada account limit check
    * Reviewer             : Spankaj
    * Build Number         : VMSGPRHOSTCSD3.1_B0001
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 18-Dec-15
    * Modified For         : FSS-3921
    * Modified reason      : Account number not logging 
    * Reviewer             : Pankaj
    * Build Number         : VMSGPRHOSTCSD3.3_B0001
    
     * Modified by         : Spankaj
     * Modified Date     : 23-Dec-15
     * Modified For       : FSS-3925
     * Reviewer              : Saravanankumar
     * Build Number       : VMSGPRHOSTCSD3.3_B0001
     
    * Modified by                  : MageshKumar S.
    * Modified Date                : 29-DECEMBER-15
    * Modified For                 : FSS-3506
    * Modified reason              : ALERTS TRANSFER
    * Reviewer                     : SARAVANAKUMAR/SPANKAJ
    * Build Number                 : VMSGPRHOSTCSD3.3_B0002
    
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
    * Modified by          : MageshKumar S.
    * Modified Date        : 19-July-16
    * Modified For         : FSS-4423
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0001
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 02-Aug-16
    * Modified For         : FSS-4423 Additional Changes
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0002
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 11-May-17
    * Modified For         : FSS-5103
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD17.05_B0001
    
     * Modified by          : Pankaj S.
    * Modified Date        : 23-May-17
    * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.05
    
        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
    
    * Modified By      : Puvanesh. N
    * Modified Date    : 07-JUL-2021
    * Purpose          : VMS-4727 IVR GPR CARD ACTIVATION - Defunding Inactive Card and Then Funding it on Activation
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST48.1
	
	* Modified By      : Mohan Kumar E
    * Modified Date    : 24-JULY-2023
    * Purpose          : VMS-7196 - Funding on Activation for Replacements
    * Reviewer         : Pankaj S.
    * Release Number   : R83

    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
  *************************************************/

  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ERRMSG          VARCHAR2(300);
  V_CURRCODE        VARCHAR2(3);
  V_APPL_CODE       CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE        VARCHAR2(5);
  V_RESPMSG         VARCHAR2(500);
  V_CAPTURE_DATE    DATE;
  V_MBRNUMB         CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_TYPE        CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID     TRANSACTIONLOG.AUTH_ID%TYPE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN             CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_OLD_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE; --Added for VMS_7196
  V_ENCR_PAN             CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT            NUMBER;
  V_DELCHANNEL_CODE      VARCHAR2(2);
  V_BASE_CURR            CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_TRAN_DATE            DATE;
  V_TRAN_AMT             NUMBER;
  V_BUSINESS_DATE        DATE;
  V_BUSINESS_TIME        VARCHAR2(5);
  V_CUTOFF_TIME          VARCHAR2(5);
 -- V_VALID_CARDSTAT_COUNT NUMBER;
 -- V_CARD_TOPUP_FLAG      NUMBER;
  V_CUST_CODE            CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_TRAN_COUNT           NUMBER;
  V_TRAN_COUNT_REVERSAL  NUMBER;
  V_CAP_PROD_CATG        VARCHAR2(100);
 -- V_MMPOS_USAGEAMNT      CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
 -- V_MMPOS_USAGELIMIT     CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
 -- V_BUSINESS_DATE_TRAN   DATE;
  V_ACCT_BALANCE         CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_PROD_CODE            CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE         CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_EXPRY_DATE           DATE;
  V_ATMONLINE_LIMIT      CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT      CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_TOACCT_BAL           CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  --V_EXP_DATE             VARCHAR2(10);
  --V_SRV_CODE             VARCHAR2(5);
  V_REMRK                VARCHAR2(100);
  V_RESONCODE            CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_CRD_ISS_COUNT        NUMBER;
  V_COUNT                NUMBER;
  V_LEDGER_BALANCE       NUMBER;
  V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);

  /* START  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
  V_INST_CODE     CMS_APPL_PAN.CAP_INST_CODE%TYPE;
  V_LMTPRFL       CMS_PRDCATTYPE_LMTPRFL.CPL_LMTPRFL_ID%TYPE;
  V_PROFILE_LEVEL  cms_appl_pan.cap_prfl_levl%TYPE;  -- NUMBER (2);  --added by amit on 20-Jul-2012 for activation part in LIMITS modified by type Dhiraj
  /* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
  V_TRANS_DESC CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
   --Sn added on 15-Feb-13 for multiple SSN checks
   v_ssn                    cms_cust_mast.ccm_ssn%TYPE;
   v_ssn_crddtls            VARCHAR2 (4000);
--En added on 15-Feb-13 for multiple SSN checks
--Sn Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
   v_dup_check              NUMBER (3);
   v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;
--En Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
--Sn Added by Pankaj S. for FSS-390
   v_starter_card          cms_appl_pan.cap_pan_code%TYPE;
   v_starter_card_encr     cms_appl_pan.cap_pan_code_encr%TYPE;
   v_oldcrd_encr           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_crdstat_chnge         VARCHAR2(2):='N';
  --En Added by Pankaj S. for FSS-390
  v_oldcardstat NUMBER;

    --SN Added for 13160
    v_acct_type cms_acct_mast.cam_type_code%type;
    v_timestamp timestamp(3);
    --EN Added for 13160
    v_cardactive_dt   cms_appl_pan.cap_active_date%TYPE;  
    
    V_FLDOB_HASHKEY_ID         CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;  --Added for MVCAN-77 OF 3.1 RELEASE
    v_chkcurr              cms_bin_param.cbp_param_value%TYPE;    
    v_oldcrd_clear varchar2(19);
    v_card_activation_code  cms_appl_pan.cap_activation_code%type;
    v_replace_expdt   cms_appl_pan.cap_replace_exprydt%TYPE;

	V_DEFUND_FLAG        	CMS_ACCT_MAST.CAM_DEFUND_FLAG%TYPE;
	V_ORDER_PROD_FUND    	VMS_ORDER_LINEITEM.VOL_PRODUCT_FUNDING%TYPE;
	V_LINEITEM_DENOM     	VMS_ORDER_LINEITEM.VOL_DENOMINATION%TYPE;
	V_PROD_FUND		     	CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
	V_FUND_AMT           	CMS_PROD_CATTYPE.CPC_FUND_AMOUNT%TYPE;
	V_ORDER_FUND_AMT     	VMS_ORDER_LINEITEM.VOL_FUND_AMOUNT%TYPE;
	V_PROFILE_CODE       	CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
	V_INITIALLOAD_AMOUNT	CMS_ACCT_MAST.CAM_INITIALLOAD_AMT%TYPE;
	V_TXN_CODE              cms_transaction_mast.CTM_TRAN_CODE%TYPE;--Added for VMS_7196
    v_toggle_value         cms_inst_param.cip_param_value%TYPE;--Added for VMS_7196
	V_ACTIVECARD_COUNT		PLS_INTEGER;
	V_TXN_AMT             	NUMBER;
    V_REMARK                TRANSACTIONLOG.REMARK%TYPE;
    VOD_REPL_ORDER          VMS_ORDER_LINEITEM.VOL_ORDER_ID%TYPE;
    V_PARAM_VALUE           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
  P_ERRMSG   := 'OK';
  V_ERRMSG   := 'OK';
  V_RESPCODE := '1';
  V_REMRK    := 'IVR GPR Card Activation';
  --P_auth_message := 'OK';
  V_TXN_AMT := 0;
    V_TXN_CODE := P_TXN_CODE;--Added for VMS_7196
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn find card detail
  BEGIN
    SELECT CAP_PROD_CODE,
         CAP_CARD_TYPE,
         TO_CHAR(CAP_EXPRY_DATE, 'DD-MON-YY'),
         CAP_CARD_STAT,
         CAP_ATM_ONLINE_LIMIT,
         CAP_POS_ONLINE_LIMIT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_CUST_CODE,
         CAP_PIN_OFF,
         CAP_INST_CODE ,--Added by Dhiraj G Limits BRD
         CAP_PRFL_CODE, -- Added on 30102012 Dhiraj 
         CAP_PRFL_LEVL, -- Added on 30102012 Dhiraj
         CAP_ACCT_NO,     --Added by Besky on 09-nov-12
         cap_replace_exprydt, 
         cap_active_date,
         cap_activation_code
     INTO V_PROD_CODE,
         V_PROD_CATTYPE,
         V_EXPRY_DATE,
         V_CAP_CARD_STAT,
         V_ATMONLINE_LIMIT,
         V_ATMONLINE_LIMIT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_CUST_CODE,
         P_TABLE_PINOFF,
         V_INST_CODE, --Added by Dhiraj G Limits BRD
         v_lmtprfl ,-- Added on 30102012 Dhiraj 
         v_profile_level , -- Added on 30102012 Dhiraj     
         V_ACCT_NUMBER,   --Added by Besky on 09-nov-12
         v_replace_expdt,
         v_cardactive_dt,
         v_card_activation_code
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '16'; --Ineligible Transaction
     V_ERRMSG   := 'Card number not found' || P_TXN_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find card detail

		BEGIN

          SELECT CPC_PROFILE_CODE,CPC_PRODUCT_FUNDING,CPC_FUND_AMOUNT
          INTO V_PROFILE_CODE,V_PROD_FUND,V_FUND_AMT
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE = V_PROD_CODE
          AND CPC_CARD_TYPE = V_PROD_CATTYPE
          AND CPC_INST_CODE = P_INSTCODE;
          EXCEPTION
          WHEN OTHERS THEN
           V_RESPCODE := '21';
           V_ERRMSG :='ERROR WHILE GETTING PROFILE -' || SUBSTR (SQLERRM, 1, 200);
           RAISE EXP_MAIN_REJECT_RECORD;

          END;

   BEGIN
      SELECT  CAM_ACCT_BAL, CAM_LEDGER_BAL,NVL(CAM_DEFUND_FLAG,'N'),NVL(CAM_NEW_INITIALLOAD_AMT,CAM_INITIALLOAD_AMT)
            INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,V_DEFUND_FLAG,V_INITIALLOAD_AMOUNT
            FROM CMS_ACCT_MAST
           WHERE CAM_ACCT_NO = V_ACCT_NUMBER
             AND CAM_INST_CODE = P_INSTCODE
             FOR UPDATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_RESPCODE := '12';
         V_ERRMSG :=
               'ERROR WHILE SELECTING DATA FROM ACCOUNT MASTER FOR CARD NUMBER '
            || V_HASH_PAN
            || SUBSTR (SQLERRM, 1, 100);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
   
   BEGIN
    SELECT
        NVL(CIP_PARAM_VALUE,'N')
    INTO V_PARAM_VALUE
    FROM
        CMS_INST_PARAM
    WHERE
        CIP_PARAM_KEY = 'VMS_4727_TOGGLE'
        AND CIP_INST_CODE = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_PARAM_VALUE := 'N';
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            V_ERRMSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;

   IF P_TXN_CODE = '09' AND  V_CARDACTIVE_DT IS NULL AND V_DEFUND_FLAG = 'Y' AND V_ACCT_BALANCE = 0 AND V_PARAM_VALUE = 'N'
   THEN

		BEGIN
              SELECT TO_NUMBER(NVL(LINEITEM.VOL_DENOMINATION,'0')),LINEITEM.VOL_PRODUCT_FUNDING,LINEITEM.VOL_FUND_AMOUNT,UPPER(SUBSTR(VOL_ORDER_ID,1,4))
              INTO V_LINEITEM_DENOM,V_ORDER_PROD_FUND,V_ORDER_FUND_AMT,VOD_REPL_ORDER
              FROM 
                VMS_LINE_ITEM_DTL DETAIL,
                VMS_ORDER_LINEITEM LINEITEM
              WHERE
               DETAIL.VLI_ORDER_ID= LINEITEM.VOL_ORDER_ID
              AND DETAIL.VLI_PARTNER_ID=LINEITEM.VOL_PARTNER_ID
              AND DETAIL.VLI_LINEITEM_ID = LINEITEM.VOL_LINE_ITEM_ID
              AND DETAIL.VLI_PAN_CODE  = V_HASH_PAN;

	  ---    v_order_prod_fund = 1 / 'Load on Order'
	  ---    v_order_prod_fund = 2 / 'Load on Activation'

					IF V_LINEITEM_DENOM = 0 AND VOD_REPL_ORDER = 'ROID' THEN

						SELECT
							COUNT(1)
						INTO V_ACTIVECARD_COUNT
						FROM
							CMS_APPL_PAN
						WHERE
							CAP_INST_CODE = P_INSTCODE
							AND CAP_ACCT_NO = V_ACCT_NUMBER
							AND CAP_ACTIVE_DATE IS NOT NULL;

						IF V_ACTIVECARD_COUNT = 0 THEN

							V_LINEITEM_DENOM := V_INITIALLOAD_AMOUNT;
						ELSE
							V_LINEITEM_DENOM := 0;
						END IF;

					END IF;

	                 V_TXN_AMT := V_LINEITEM_DENOM;  
                

   	EXCEPTION
	    WHEN NO_DATA_FOUND 
	    THEN 
	    NULL;
            WHEN OTHERS
            THEN
             V_RESPCODE := '12';
                     V_ERRMSG :=
                           'ERROR WHILE SELECTING DENOMINATION DETAILS -  '
                        || V_HASH_PAN
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE EXP_MAIN_REJECT_RECORD;
        END; 

    END IF;

        --Sn added for VMS_7196
            BEGIN
                SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                INTO v_toggle_value
                FROM vmscms.cms_inst_param
                    WHERE cip_inst_code = 1
                    AND cip_param_key = 'VMS_7196_TOGGLE';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                     v_toggle_value := 'Y';
            END;

    IF v_toggle_value = 'Y' THEN

        if P_TXN_CODE = '09' and V_DEFUND_FLAG='N' and V_INITIALLOAD_AMOUNT=0  then

            BEGIN

            select  cap_pan_code
                    into v_old_pan
                    from ( select cap_pan_code
                    from vmscms.cms_appl_pan
                    where cap_inst_code = 1
                    and cap_acct_no = V_ACCT_NUMBER
                    and  cap_repl_flag = 0
                    ORDER BY cap_ins_date
                    )
            where rownum =1;

                  SELECT TO_NUMBER(NVL(LINEITEM.VOL_DENOMINATION,'0')),LINEITEM.VOL_FUND_AMOUNT
                  INTO V_LINEITEM_DENOM,V_ORDER_FUND_AMT
                  FROM
                    VMS_LINE_ITEM_DTL DETAIL,
                    VMS_ORDER_LINEITEM LINEITEM
                  WHERE DETAIL.VLI_ORDER_ID= LINEITEM.VOL_ORDER_ID
                  AND DETAIL.VLI_PARTNER_ID=LINEITEM.VOL_PARTNER_ID
                  AND DETAIL.VLI_LINEITEM_ID = LINEITEM.VOL_LINE_ITEM_ID
                  AND DETAIL.VLI_PAN_CODE  = v_old_pan;


                IF V_ORDER_FUND_AMT = 1 AND V_LINEITEM_DENOM>0 THEN
                             V_TXN_AMT := V_LINEITEM_DENOM;
                             v_txn_code := '59';
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                NULL;
                    WHEN OTHERS
                    THEN
                     V_RESPCODE := '12';
                             V_ERRMSG :=
                                   'ERROR WHILE SELECTING FUND AMOUNT -  '
                                || V_HASH_PAN
                                || SUBSTR (SQLERRM, 1, 100);
                    RAISE EXP_MAIN_REJECT_RECORD;
            END;

        end if;
    END IF;

    --En added for VMS_7196
  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC --Added for transaction detail report on 210812
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = v_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
      V_ERRMSG   := 'Transflag  not defined for txn code ' || v_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_RESPCODE := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Date Check

  --Sn Transaction Time Check
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
  --En Transaction Time Check

  V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

  IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
  ELSE
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
  END IF;

  BEGIN

    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'IVR' AND CDM_INST_CODE = P_INSTCODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
  
    IF V_DELCHANNEL_CODE = P_DELIVERY_CHANNEL THEN
    
     BEGIN
--       SELECT CIP_PARAM_VALUE
--        INTO V_BASE_CURR
--        FROM CMS_INST_PARAM
--        WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';

            SELECT TRIM (cbp_param_value)  
			INTO v_base_curr 
			FROM cms_bin_param 
            WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
            AND cbp_profile_code = V_PROFILE_CODE;


     
       IF V_BASE_CURR IS NULL THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency cannot be null ';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the BIN PROFILE ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting base currency for bin  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    
     V_CURRCODE := V_BASE_CURR;
    
    ELSE
     V_CURRCODE := '840';
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting the Delivery Channel of IVR  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
    
  END;

  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return

  /*BEGIN
  
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRANDATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
  
    IF V_RRN_COUNT > 0 THEN
    
     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN ' || ' on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
  
  END;*/--Unwanted Code removed

  --En Duplicate RRN Check
  
  --Sn Commented for Transactionlog Functional Removal
  /*BEGIN
  
    SELECT COUNT(*)
     INTO V_TRAN_COUNT
     FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
         TXN_CODE = '68' AND DELIVERY_CHANNEL = '04';
  
    SELECT COUNT(*)
     INTO V_TRAN_COUNT_REVERSAL
     FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
         TXN_CODE = '69' AND DELIVERY_CHANNEL = '04';
  
    IF V_TRAN_COUNT <> V_TRAN_COUNT_REVERSAL THEN
    
     V_RESPCODE := '27';
     V_ERRMSG   := 'Card Activation Already Done For This Card ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  
  END;

  BEGIN
    SELECT COUNT(*)
     INTO V_TRAN_COUNT
     FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
         TXN_CODE = '02' AND DELIVERY_CHANNEL = '07';
  
    IF V_TRAN_COUNT > '0' THEN
     V_RESPCODE := '27';
     V_ERRMSG   := 'Card Activation Already Done For This Card ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  
  END;

  BEGIN
    SELECT COUNT(*)
     INTO V_TRAN_COUNT
     FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
         TXN_CODE = '09' AND DELIVERY_CHANNEL = '07';
  
    IF V_TRAN_COUNT > '0' THEN
     V_RESPCODE := '27';
     V_ERRMSG   := 'Card Activation Already Done For This Card ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  
  END;

  BEGIN
    SELECT COUNT(*)
     INTO V_TRAN_COUNT
     FROM TRANSACTIONLOG
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
         TXN_CODE = '02' AND DELIVERY_CHANNEL = '10';
  
    IF V_TRAN_COUNT > '0'  THEN
     V_RESPCODE := '27';
     V_ERRMSG   := 'Card Activation Already Done For This Card ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  
  END;*/
  --En Commented for Transactionlog Functional Removal


  
  --Sn Added for Transactionlog Functional Removal
  IF v_cardactive_dt is not null AND v_replace_expdt is null
    THEN
     V_RESPCODE := '27';
     V_ERRMSG   := 'Card Activation Already Done For This Card ';
     RAISE EXP_MAIN_REJECT_RECORD;
  END IF;
  --En Added for Transactionlog Functional Removal
  
  IF v_card_activation_code IS NOT NULL AND v_card_activation_code != p_activation_code_in 
  THEN
     V_RESPCODE := '266';
     V_ERRMSG   := 'Activation Codes Not Matched';
     RAISE EXP_MAIN_REJECT_RECORD;
  
  END IF;
  
   --Sn Added by Pankaj S. on 19-Feb-2013 for card replacement changes(FSS-391)
   if v_replace_expdt is null Then 
    BEGIN
       SELECT chr_pan_code,chr_pan_code_encr,fn_dmaps_main(chr_pan_code_encr)
         INTO v_oldcrd,v_oldcrd_encr,v_oldcrd_clear  --v_oldcrd_encr added by pankaj S. for FSS-390
         FROM cms_htlst_reisu
        WHERE chr_inst_code = p_instcode
          AND chr_new_pan = v_hash_pan
          AND chr_reisu_cause = 'R'
          AND chr_pan_code IS NOT NULL;

       BEGIN
          SELECT COUNT (1)
            INTO v_dup_check
            FROM cms_appl_pan
           WHERE cap_inst_code = p_instcode
             AND cap_acct_no = v_acct_number
             AND cap_startercard_flag='N'  --ADDED FOR MANTIS-12153
             AND cap_card_stat IN ('0', '1', '2', '5', '6', '8', '12');

          IF v_dup_check <> 1 
          THEN
             v_errmsg := 'Card is not allowed for activation';
             v_respcode := '89';            --need to configure new response code
             RAISE exp_main_reject_record;
          END IF;
       END;

       BEGIN
           SELECT cap_card_stat into v_oldcardstat from cms_appl_pan WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;
            if v_oldcardstat = 3 or v_oldcardstat = 7 then
            
          UPDATE cms_appl_pan
             SET cap_card_stat = '9'
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;

          IF SQL%ROWCOUNT != 1
          THEN
             v_errmsg := 'Problem in updation of status for old damage card';
             v_respcode := '89';            --need to configure new response code
             RAISE exp_main_reject_record;
          END IF;
          v_crdstat_chnge:='Y'; --Added for FSS-390
          
          p_closed_card :=v_oldcrd_clear;
          end if;
       END;
       
    EXCEPTION
       WHEN exp_main_reject_record
       THEN
          RAISE;
       WHEN NO_DATA_FOUND
       THEN
          NULL;
       WHEN OTHERS
       THEN
          v_respcode := '21';
          v_errmsg :=
                'Error while selecting damage card details '
             || SUBSTR (SQLERRM, 1, 100);
          RAISE exp_main_reject_record;
    END;
    End if ;
    --En Added by Pankaj S. on 19-Feb-2013 for card replacement changes(FSS-391)
    
     /* START   Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
/*IF v_lmtprfl IS NULL OR v_profile_level IS NULL -- Added on 30102012 Dhiraj 
   THEN
 
  BEGIN
    SELECT CPL_LMTPRFL_ID
     INTO V_LMTPRFL
     FROM CMS_PRDCATTYPE_LMTPRFL
    WHERE CPL_INST_CODE = V_INST_CODE AND CPL_PROD_CODE = V_PROD_CODE AND
         CPL_CARD_TYPE = V_PROD_CATTYPE;
  
    V_PROFILE_LEVEL := 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     BEGIN
       SELECT CPL_LMTPRFL_ID
        INTO V_LMTPRFL
        FROM CMS_PROD_LMTPRFL
        WHERE CPL_INST_CODE = V_INST_CODE AND CPL_PROD_CODE = V_PROD_CODE;
     
       V_PROFILE_LEVEL := 3;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        NULL;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG   := 'Error while selecting Limit Profile At Product Level' ||
                    SQLERRM;
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting Limit Profile At Product Catagory Level' ||
                SQLERRM;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
END IF  ;*/-- Added on 30102012 Dhiraj 


/*IF V_LMTPRFL IS NOT NULL THEN -- Added on 30102012 Dhiraj 
  BEGIN
  
    UPDATE CMS_APPL_PAN
      SET CAP_PRFL_CODE = V_LMTPRFL, --Added by Dhiraj G on 12072012 for  - LIMITS BRD
         CAP_PRFL_LEVL = V_PROFILE_LEVEL --Added by Dhiraj G on 12072012 for  - LIMITS BRD
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
  
    IF SQL%ROWCOUNT = 0 THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Limit Profile not updated for :' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while Limit profile Update ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
END IF;  */-- Added on 30102012 Dhiraj 
  /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */

  --Sn Check initial load
  IF V_FIRSTTIME_TOPUP = 'Y' AND V_CAP_CARD_STAT = '1' THEN
    V_RESPCODE := '27'; -- response for invalid transaction
    V_ERRMSG   := 'Card Activation Already Done For This Card ';
    RAISE EXP_MAIN_REJECT_RECORD;
  ELSE
    IF TRIM(V_FIRSTTIME_TOPUP) IS NULL THEN
     V_ERRMSG := 'Invalid Card Activation ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END IF;

  --En Check initial load

 /* BEGIN
    SELECT COUNT(*)
     INTO V_VALID_CARDSTAT_COUNT
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN AND
         CAP_CARD_STAT = 0;
  
    IF V_VALID_CARDSTAT_COUNT = 0 THEN
    
     V_RESPCODE := '10'; --Modified resp code '09' to '10' by A.Sivakaminathan on 02-Oct-2012
     V_ERRMSG   := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;*/
 IF v_replace_expdt IS NULL THEN 
  IF V_CAP_CARD_STAT != 0 THEN
     V_RESPCODE := '10'; 
     V_ERRMSG   := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;

 /* BEGIN
    SELECT COUNT(*)
     INTO V_CARD_TOPUP_FLAG
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN AND
         CAP_FIRSTTIME_TOPUP = 'N';
  
    IF V_CARD_TOPUP_FLAG = 0 THEN
    
     V_RESPCODE := '28';
     V_ERRMSG   := 'CARD FIRST TIME TOPUP MUST BE N STATUS FOR ACTIVATION';
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
  END;*/
  
  IF V_FIRSTTIME_TOPUP = 'Y' THEN
    
     V_RESPCODE := '28';
     V_ERRMSG   := 'CARD FIRST TIME TOPUP MUST BE N STATUS FOR ACTIVATION';
     RAISE EXP_MAIN_REJECT_RECORD;
    
    END IF;
END IF;
  --Sn Expiry date, service code
  /*BEGIN
    SELECT TO_CHAR(CAP_EXPRY_DATE, 'MMYY'), CBP_PARAM_VALUE
     INTO V_EXP_DATE, V_SRV_CODE
     FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_MAST
    WHERE CBP_PROFILE_CODE = CPM_PROFILE_CODE AND
         CPM_INST_CODE = CAP_INST_CODE AND CPM_PROD_CODE = CAP_PROD_CODE AND
         CBP_PARAM_NAME = 'Service Code' AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '16'; --Ineligible Transaction
     V_ERRMSG   := 'Card number not found' || P_TXN_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
    
  END;*/

  --En  Expiry date, service code
  /*
   --card status
   BEGIN
     IF V_CAP_CARD_STAT IN (2, 3) THEN
  
      V_RESPCODE := '41';
      V_ERRMSG   := ' Lost Card ';
      RAISE EXP_MAIN_REJECT_RECORD;
  
     ELSIF V_CAP_CARD_STAT = 4 THEN
  
      V_RESPCODE := '14';
      V_ERRMSG   := ' Restricted Card ';
      RAISE EXP_MAIN_REJECT_RECORD;
  
     ELSIF V_CAP_CARD_STAT = 9 THEN
  
      V_RESPCODE := '46';
      V_ERRMSG   := ' Closed Card ';
      RAISE EXP_MAIN_REJECT_RECORD;
  
     END IF;
   END;
   --card status
  
   -- Expiry Check
  
   BEGIN
  
  
     IF TO_DATE(P_TRANDATE, 'YYYYMMDD') >
       LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN
  
      V_RESPCODE := '13';
      V_ERRMSG   := 'EXPIRED CARD';
      RAISE EXP_MAIN_REJECT_RECORD;
  
     END IF;
  
   EXCEPTION
  
     WHEN EXP_MAIN_REJECT_RECORD THEN
      RAISE;
  
     WHEN OTHERS THEN
      V_RESPCODE := '21';
      V_ERRMSG   := 'ERROR IN EXPIRY DATE CHECK : Tran Date - ' ||
                 P_TRANDATE || ', Expiry Date - ' || V_EXPRY_DATE || ',' ||
                 SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_MAIN_REJECT_RECORD;
  
   END;
  */
  -- End Expiry Check

 -- IF V_CAP_PROD_CATG = 'P' THEN
  
    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          '0200',
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          '0',
                           V_TXN_CODE, --P_TXN_CODE,-- Modified for VMS_7196
                          0,
                          P_TRANDATE,
                          P_TRANTIME,
                          P_CARDNUM,
                          NULL,
                          0,
                          NULL,
                          NULL,
                          NULL,
                          V_CURRCODE,
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
                          '0', -- P_stan
                          '000', --Ins User
                          '00', --INS Date
                          V_TXN_AMT,--0,-- Modified for VMS_7196
                          V_INIL_AUTHID,
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
     
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
    --En call to authorize txn
 -- END IF;
  
      --Sn Added for FSS-3925
        BEGIN
--           SELECT TRIM (cbp_param_value)
--             INTO v_chkcurr
--             FROM cms_bin_param, cms_prod_mast
--            WHERE     cbp_param_name = 'Currency'
--                  AND cbp_inst_code = cpm_inst_code
--                  AND cbp_profile_code = cpm_profile_code
--                  AND cpm_inst_code = p_instcode
--                  AND cpm_prod_code = v_prod_code;

      vmsfunutilities.get_currency_code(v_prod_code,V_PROD_CATTYPE,p_instcode,v_chkcurr,v_errmsg);
      
      if v_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;
                  
           IF v_chkcurr IS NULL THEN
              v_respcode := '21';
              v_errmsg := 'Base currency cannot be null ';
              RAISE exp_main_reject_record;
           END IF;     
        EXCEPTION
           WHEN exp_main_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg :='Error while selecting base currency -' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
     IF v_chkcurr<>'124' THEN                 
      --En Added for FSS-3925

  --Sn Added on 15_Feb_13 to call procedure for multiple SSN check
         BEGIN
            SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) --,gethash(ccm_first_name||ccm_last_name||ccm_birth_date) --Added for MVCAN-77 of 3.1 release
              INTO v_ssn--,V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
              FROM cms_cust_mast
             WHERE ccm_inst_code = p_instcode AND ccm_cust_code = v_cust_code;
             
            sp_check_ssn_threshold (p_instcode,
                                    v_ssn,
                                    v_prod_code,
									V_PROD_CATTYPE,
                                    NULL,
                                    v_ssn_crddtls,
                                    v_respcode,
                                    v_respmsg,
                                    V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
                                   );

            IF v_respmsg <> 'OK'
            THEN
               v_respcode := '158';
               v_errmsg := v_respmsg;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               ROLLBACK;
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                          'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --En Added on 15_Feb_13 to call procedure for multiple SSN check
      END IF;   

  IF V_RESPCODE = '00' THEN
    BEGIN
        --Sn added by Pankaj S. for FSS-390
        --Sn select Starter Card
        BEGIN
           SELECT cap_pan_code,cap_pan_code_encr
             INTO v_starter_card,v_starter_card_encr
             from (SELECT cap_pan_code,cap_pan_code_encr
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode
              AND cap_acct_no = v_acct_number
              AND cap_startercard_flag = 'Y'
              AND cap_card_stat NOT IN ('9')  order by cap_pangen_date desc)
              where rownum=1;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
            NULL;
           WHEN OTHERS
           THEN
              v_respcode := '21';
              v_errmsg :=
                    'Error while selecting Starter Card details for Account No '
                 || v_acct_number||'-'||SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
        --En select Starter Card
        --En added by Pankaj S. for FSS-390
    
     SP_IVR_GPR_CARD_ACTIVATE(P_INSTCODE,
                          P_CARDNUM,
                          P_RRN,          -- added for mvcsd-4099 additional changes on 14/Sept/2013
                          P_TRANDATE,      -- added for mvcsd-4099 additional changes on 14/Sept/2013
                          P_TRANTIME,      -- added for mvcsd-4099 additional changes on 14/Sept/2013
                          V_INIL_AUTHID,    -- added for mvcsd-4099 additional changes on 14/Sept/2013
                          V_RESPCODE,                                                     
                          V_RESPMSG,
                          p_closed_card);
     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       V_ERRMSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;
    
    --Sn added by Pankaj S. for FSS-390
       IF v_starter_card IS NOT NULL THEN
       sp_log_cardstat_chnge (p_instcode,
                              v_starter_card,
                              v_starter_card_encr,
                              v_inil_authid,
                              '02',
                              p_rrn,
                              p_trandate,
                              p_trantime,
                              v_respcode,
                              v_respmsg
                              );

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;
          
        --Sn added by MAGESHKUMAR S. for FSS-3506
        IF v_respcode = '00' AND v_respmsg = 'OK' THEN
        
         VMSCOMMON.TRFR_ALERTS (p_instcode,
                                 v_starter_card,
                                 V_HASH_PAN,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;
          END IF;
          
          ELSE
          
          IF v_oldcrd IS NOT NULL THEN
          
          VMSCOMMON.TRFR_ALERTS (p_instcode,
                                 v_oldcrd,
                                 V_HASH_PAN,
                                 v_respcode,
                                 v_respmsg);

          IF v_respcode <> '00' AND v_respmsg <> 'OK'
          THEN
             v_errmsg := v_respmsg;
             RAISE exp_main_reject_record;
          END IF;
          
          END IF;
          
      --En added by MAGESHKUMAR S. for FSS-3506
          
       END IF;
      --En added by Pankaj S. for FSS-390
    
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;
     WHEN exp_main_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error from IVR Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;
  
  --Sn added by Pankaj S. for FSS-390
   IF v_errmsg='OK' and v_crdstat_chnge='Y'
   THEN
    BEGIN
       sp_log_cardstat_chnge (p_instcode,
                              v_oldcrd,
                              v_oldcrd_encr,
                              v_inil_authid,
                              '02',
                              p_rrn,
                              p_trandate,
                              p_trantime,
                              v_respcode,
                              v_errmsg
                             );

       IF v_respcode <> '00' AND v_errmsg <> 'OK'
       THEN
        RAISE exp_main_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_main_reject_record
       THEN
          RAISE;
       WHEN OTHERS
       THEN
          v_respcode := '21';
          v_errmsg :=
                'Error while logging system initiated card status change '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;    
   END IF;
    --En added by Pankaj S. for FSS-390
  --Sn Selecting Reason code for Online Order Replacement
  BEGIN
    SELECT CSR_SPPRT_RSNCODE
     INTO V_RESONCODE
     FROM CMS_SPPRT_REASONS
    WHERE CSR_INST_CODE = P_INSTCODE AND CSR_SPPRT_KEY = 'ACTVTCARD';
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Card Activation reason code is present in master';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Error while selecting reason code from master' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn create a record in pan spprt
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
      V_MBRNUMB,
      V_CAP_PROD_CATG,
      'ACTVTCARD',
      V_RESONCODE,
      V_REMRK,
      '1',
      '1',
      0,
      V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into card support master' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En create a record in pan spprt

  IF V_RESPCODE <> '00' THEN
    BEGIN
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     -- Assign the response code to the out parameter
    
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
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    
    END;
  ELSE
    P_RESP_CODE := V_RESPCODE;
  END IF;

  --En select response code and insert record into txn log dtl

  ---Sn Updation of Usage limit and amount
 /* BEGIN
    SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
     INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
     FROM CMS_TRANSLIMIT_CHECK
    WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
         CTC_MBR_NUMB = '000';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while calling CMS_TRANSLIMIT_CHECK1 ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
  
    --Sn Usage limit and amount updation for MMPOS
    IF P_DELIVERY_CHANNEL = '04' THEN
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
              CTC_MBR_NUMB = '000';
       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK1 ' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESPCODE := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     ELSE
       V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
       BEGIN
        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
         WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = '000';
       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK2 ' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESPCODE := '21';
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     END IF;
    END IF;
    --En Usage limit and amount updation for MMPOS
  
  END;*/

  ---En Updation of Usage limit and amount

  --IF errmsg is OK then balance amount will be returned

  IF P_ERRMSG = 'OK' THEN
  
    --Sn of Getting  the Acct Balannce
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_ACCT_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
          /* (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = '000' AND
                 CAP_INST_CODE = P_INSTCODE)*/ AND
           CAM_INST_CODE = P_INSTCODE
        FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       V_ERRMSG   := 'Invalid Card ';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                  V_HASH_PAN;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
    --En of Getting  the Acct Balannce
  
    --En of Getting  the Acct Balannce
    IF P_ERRMSG = 'OK' THEN
     P_ERRMSG   := '';
    -- P_EXP_DATE := V_EXP_DATE;
    -- P_SRV_CODE := V_SRV_CODE;
    END IF;
  
  END IF;
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
    UPDATE TRANSACTIONLOG
      SET ANI = P_ANI, DNI = P_DNI
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
          TXN_CODE = v_TXN_CODE AND BUSINESS_TIME = P_TRANTIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
ELSE
    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      SET ANI = P_ANI, DNI = P_DNI
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
          TXN_CODE = v_TXN_CODE AND BUSINESS_TIME = P_TRANTIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
END IF;
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '69';
     P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;
  
  IF V_RESPCODE = '00' AND V_ERRMSG = 'OK' THEN
    
    IF V_DEFUND_FLAG = 'Y' AND NVL(V_TXN_AMT,0) > 0 AND V_PARAM_VALUE = 'N' THEN
    
        V_REMARK := 'Activated and Loaded the Defunded Amount For the Account';
  
    SP_CARD_LOAD_DEFUND_AMOUNT(P_INSTCODE,
                               '0200',
                                P_RRN,
                                P_DELIVERY_CHANNEL,
                                '0',
                                P_TXN_CODE,
                                0,
                                P_TRANDATE,
                                P_TRANTIME,
                                P_CARDNUM,
                                V_TXN_AMT,
                                NULL,
                                NULL,
                                NULL,
                                V_CURRCODE,
                                '000',
                                '0',
                                V_REMARK,
                                'CR',
                                '00',
                                P_ANI,
                                P_DNI,
                                V_RESPCODE,
                                V_ERRMSG);

                  IF V_RESPCODE <> '00' AND V_ERRMSG <> 'OK' THEN
                       RAISE EXP_MAIN_REJECT_RECORD;
                     END IF;
                END IF;
        END IF;
  
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    P_ERRMSG    := V_ERRMSG;
    P_RESP_CODE := V_RESPCODE;
  
    ---Sn Updation of Usage limit and amount
 /*   BEGIN
     SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
       INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = '000';
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK2 ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
    BEGIN
    
     --Sn Usage limit and amount updation for MMPOS
     IF P_DELIVERY_CHANNEL = '04' THEN
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
                CTC_MBR_NUMB = '000';
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK3 ' ||
                       SUBSTR(SQLERRM, 1, 300);
            V_RESPCODE := '21';
            RAISE EXP_MAIN_REJECT_RECORD;
        END;
       ELSE
        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
        BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
           WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = '000';
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK4 ' ||
                       SUBSTR(SQLERRM, 1, 300);
            V_RESPCODE := '21';
            RAISE EXP_MAIN_REJECT_RECORD;
        END;
       END IF;
     END IF;
     --En Usage limit and amount updation for MMPOS
    
    END;*/
  
  ---En Updation of Usage limit and amount

  --Sn create a entry in txn log

  --En create a entry in txn log

  WHEN EXP_MAIN_REJECT_RECORD THEN
    ---Sn Updation of Usage limit and amount
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code                   --Added for 13160
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type                     --Added for 13160
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
   /* BEGIN
     SELECT CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT, CTC_BUSINESS_DATE
       INTO V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT, V_BUSINESS_DATE_TRAN
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = '000';
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK3 ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
    BEGIN
    
     --Sn Usage limit and amount updation for MMPOS
     IF P_DELIVERY_CHANNEL = '04' THEN
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
                CTC_MBR_NUMB = '000';
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK5 ' ||
                       SUBSTR(SQLERRM, 1, 300);
            V_RESPCODE := '21';
            RAISE EXP_MAIN_REJECT_RECORD;
        END;
       ELSE
        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
        BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
           WHERE CTC_INST_CODE = P_INSTCODE AND CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = '000';
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK6 ' ||
                       SUBSTR(SQLERRM, 1, 300);
            V_RESPCODE := '21';
            RAISE EXP_MAIN_REJECT_RECORD;
        END;
       END IF;
     END IF;
     --En Usage limit and amount updation for MMPOS
    
    END;*/
  
    ---En Updation of Usage limit and amount
  
    --Sn select response code and insert record into txn log dtl
    BEGIN
     P_ERRMSG    := V_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     -- Assign the response code to the out parameter
    
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
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    END;
  
    --Sn select response code and insert record into txn log dtl
    BEGIN
     IF P_RESP_CODE = '00' THEN
       SELECT CAM_ACCT_BAL
        INTO V_TOACCT_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INSTCODE AND
            CAM_ACCT_NO =
            (SELECT CAP.CAP_ACCT_NO
               FROM CMS_APPL_PAN CAP
              WHERE CAP.CAP_PAN_CODE = V_HASH_PAN);
     --  P_EXP_DATE := V_EXP_DATE;
     --  P_SRV_CODE := V_SRV_CODE;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '99';
    END;
  
    P_ERRMSG   := V_ERRMSG;
   -- P_EXP_DATE := V_EXP_DATE;
   -- P_SRV_CODE := V_SRV_CODE;
    
 --SN Added for 13160 

    if v_dr_cr_flag is null
    then
    
       BEGIN
          SELECT ctm_credit_debit_flag,
                 ctm_tran_desc
            INTO v_dr_cr_flag, 
                 v_trans_desc  
            FROM cms_transaction_mast
           WHERE ctm_tran_code = v_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_instcode;
       EXCEPTION
          WHEN OTHERS
          THEN
               null; 
       END;
       
    end if;
        
    if v_prod_code is null
    then
    
       BEGIN
       
          SELECT cap_card_stat, cap_acct_no,
                 cap_prod_code,cap_card_type
            INTO v_cap_card_stat,v_acct_number,
                 v_prod_code,V_PROD_CATTYPE
            FROM cms_appl_pan
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
       EXCEPTION
          WHEN OTHERS
          THEN
              null;
       END;   
       
    end if;    

   v_timestamp := systimestamp;   
   
   --EN Added for 13160        
  
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
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        ssn_fail_dtls, --ssn_crd_dtls added on 15-Feb-13 for multiple SSN checks
        --Sn Added for 13160
        acct_type,
        Time_stamp,
        cr_dr_flag,
        error_msg
        --En Added for 13160
        )
     VALUES
       ('0200',
        P_RRN,
        P_DELIVERY_CHANNEL,
        0,
        V_BUSINESS_DATE,
         v_TXN_CODE,
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
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), -- NVL added for 13160
        V_CURRCODE,
        NULL,
        v_prod_code,--SUBSTR(P_CARDNUM, 1, 4), --modified for 13160 
        v_prod_cattype,--NULL,                 --modified for 13160
        0,
        V_INIL_AUTHID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), -- NVL added for 13160
        '0.00',--NULL,          --modified for 13160 
        '0.00',--NULL,          --modified for 13160 
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        '',
        0,
        V_ACCT_NUMBER, -- Added for Account number logging issue in production - FSS-3921
        nvl(V_ACCT_BALANCE,0),     -- NVL added for 13160
        nvl(V_LEDGER_BALANCE,0),   -- NVL added for 13160
     --   V_LEDGER_BALANCE, -- Commented for Account number logging issue in production - FSS-3921
        V_RESPCODE,
        P_ANI,
        P_DNI,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRANS_DESC, -- FOR Transaction detail report issue
        v_ssn_crddtls, --v_ssn_crddtls added on 15-Feb-13 for multiple SSN checks
        --Sn Added for 13160
        v_acct_type,
        v_Timestamp,
        v_dr_cr_flag,
        v_errmsg
        --En Added for 13160             
        );
    
    EXCEPTION
     WHEN OTHERS THEN
     
       P_RESP_CODE := '89';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
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
        v_TXN_CODE,
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
        V_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        --'', -- Commented for Account number logging issue in production - FSS3921
        V_ACCT_NUMBER, -- Added for Account number logging issue in production - FSS-3921
        V_TXN_TYPE);
    
     P_ERRMSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '22'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;
  WHEN OTHERS THEN
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
  
END;

/

show error