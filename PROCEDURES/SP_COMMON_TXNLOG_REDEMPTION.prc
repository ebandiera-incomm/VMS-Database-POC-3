create or replace PROCEDURE              VMSCMS.SP_COMMON_TXNLOG_REDEMPTION(
                                         P_INST_CODE           		  IN   NUMBER,
                                         P_MSG                 	  	IN   VARCHAR2,
                                         P_RRN                 		  IN   VARCHAR2,
                                         P_DELIVERY_CHANNEL    		  IN   VARCHAR2,
                                         P_TXN_CODE            	  	IN   VARCHAR2,
                                         P_TRAN_DATE           	  	IN   VARCHAR2,
                                         P_TRAN_TIME           		  IN   VARCHAR2,
                                         P_CARD_NO             		  IN   VARCHAR2,
                                         P_COUNTRY_CODE        	  	IN   VARCHAR2,
                                         P_RESP_MSG            	  	OUT  VARCHAR2,
                                         P_EMVSERV_DTL         	  	IN   VARCHAR2,
                                         P_OTHER_SERVRSLTCODE  	  	IN   VARCHAR2,
                                         p_posentry_mode       	  	IN   VARCHAR2,
                                         p_bill_curcde         	  	IN   VARCHAR2,
                                         P_MERCHANT_STREET     		  IN   VARCHAR2,
                                         P_REMARK              	  	IN   VARCHAR2,
                                         P_CNP_IND             		  IN   VARCHAR2,
                                         P_AMEX_CSC_RESULT          IN   VARCHAR2,
                                         P_AMEX_TID                 IN   VARCHAR2,
                                         P_AMEX_SETT_RRN            IN   VARCHAR2,
                                         P_CARDHLD_TRA              IN   VARCHAR2,
                                         P_DATA_VER                 IN   VARCHAR2,
                                         P_SELLER_ID                IN   VARCHAR2,
                                         P_PROB_SCORE               IN   VARCHAR2,
                                         P_DYN_RULE_CODE            IN   VARCHAR2,
                                         P_CSC5_IND                 IN   VARCHAR2,
                                         p_amex_csc_indicator       IN   VARCHAR2,
                                         p_amex_csc_status          in   varchar2,
                                         p_AEVVValidationResult     in   varchar2,
                                         p_AEIPSValidationResult    in   varchar2,
                                         p_PINValidationResults     in   varchar2,
                                         p_EMVDataResults           in   varchar2,
                                         p_ATCValidationResults     in   varchar2,
                                         p_ATCValue                 in   varchar2,
                                         p_CardmemberTravelingIndicator      in   varchar2,
                                         p_CSC4Indicator            in   varchar2,
                                         p_TokenexpirationDateresult in   varchar2,
                                         p_MC_TERM_ATTENDANCE       IN   VARCHAR2,
                                         p_MC_TERM_LOCATION 	  	  IN   VARCHAR2,
                                         p_MC_CARDHOLDER_PRESENCE 	IN   VARCHAR2,
                                         p_MC_CARD_PRESENCE 	  	  IN   VARCHAR2,
                                         p_MC_CARD_CAPTURE_CAP 	  	IN   VARCHAR2,
                                         p_MC_TRANSACTION_STATUS 	  IN   VARCHAR2,
                                         p_MC_TRANSACTION_SECURITY 	IN   VARCHAR2,
                                         p_MC_CAT_LEVEL 	  	      IN   VARCHAR2,
                                         p_MC_TERM_INPUT_CAP 	  	  IN   VARCHAR2,
                                         p_MC_AUTH_LIFE_CYCLE 	  	IN   VARCHAR2,
                                         p_MC_COUNTRY_CODE 	  	    IN   VARCHAR2,
                                         p_MC_POSTAL_CODE 	  	    IN   VARCHAR2,
                                         p_MC_CARDHOLDER_AUTH_CAP 	IN   VARCHAR2,
                                         p_MC_TERM_OPR_ENV 	  	    IN   VARCHAR2,
                                         p_MC_CARDDATA_INPUT_MODE 	IN   VARCHAR2,
                                         p_MC_CARDHOLD_AUTH_MTHD    IN   VARCHAR2,
                                         p_MC_CARDHOLD_AUTH_ENTITY  IN   VARCHAR2,
                                         p_MC_CARDDATA_OUTPUT_CAP 	IN   VARCHAR2,
                                         p_MC_TERMDATA_OUTPUT_CAP 	IN   VARCHAR2,
                                         p_MC_PIN_CAPTURE_CAP 	  	IN   VARCHAR2,
                                         p_MC_TERM_PIN_ENTRY_MODE   IN   VARCHAR2,
                                         p_TOKEN_TRAN_TYPE          IN   VARCHAR2,
                                         P_Terminal_Id              In   Varchar2,
                                         P_Merchant_Id              In   Varchar2,
                                         P_Merchant_Name            In   Varchar2,
                                         P_Merchant_State           In   Varchar2,
                                         P_Merchant_City            In   Varchar2,
                                         P_Merchant_Zip             In   Varchar2,
                                         P_NETWORKID_SWITCH         In   Varchar2,
                                         P_Payment_Status           In   Varchar2,
                                         p_network_fee_amt  in   varchar2,
                                         p_network_fee_prgm_indr  in   varchar2,
                                         p_auth_id_in               in varchar2,
                                         p_internation_ind_in      in varchar2,
                                         p_surchargefee_ind_in      in varchar2,
                                         p_digitalcapabilities_ind in varchar2,
                                         p_ran_matched_merchant_id  IN VARCHAR2 DEFAULT NULL,
                                         p_network_auth_id          IN VARCHAR2 DEFAULT NULL, -- Added for VMS-7480
                                         p_merchant_blocking_info   IN VARCHAR2 DEFAULT NULL, -- added for VMS-7695
                                         p_ols_rule_group           IN VARCHAR2 DEFAULT NULL, -- added for VMS-7695
                                         p_merchant_country_of_origin IN VARCHAR2 DEFAULT NULL, -- added for VMS-8145
										 p_src_of_decline   IN VARCHAR2  DEFAULT NULL,  -- added for VMS-8895										
										 p_verbal_actioncode	IN VARCHAR2  DEFAULT NULL,  -- added for VMS_9002
										 p_negative_list		IN VARCHAR2  DEFAULT NULL,  -- added for VMS_9002
                                         p_error_msg                out varchar2
                                         )
IS
  EXP_REJECT_RECORD EXCEPTION;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_RESP_MSG  VARCHAR2 (300);

  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991

  /*************************************************
  * Created Date     :  30-SEP-2014
  * Created By       :  Abdul Hameed M.A
  * Created For      :  FWR 70  changes
  * PURPOSE          :  Update the country code in txnlog
  * Reviewer         : Spankaj
  * Build Number     : RI0027.4_B0002

  * Modified Date     :  05-FEB-2014
  * Created By       :  Dhinakaran B
  * PURPOSE          :  Update the DE-61 Tag 39 details in txnlog table
  * Reviewer         : Spankaj
  * Build Number     : RI0027.5


  * Modified Date     : 02-SPET-2015
  * Modified By       :  siva kumar M
  * PURPOSE          :  FSS-3610 changes
  * Reviewer         : Saravana kumar 
  *Build Number     : VMSGPRHOST_3.1_B0008  

  * Modified By       : Abdul Hameed M.A
  * Modified Date     : 19-APR-2016
  * Purpose           : FSS-4119
  * Reviewer          : Spankaj
  *Build Number       : VMSGPRHOSTCSD_4.0.1_B0001 

  * Modified By       : MageshKumar S
  * Modified Date     : 15-SEP-2016
  * Purpose           : OLS partial Indicator Flag Cahnges
  * Reviewer          : Saravanakumar/Spankaj
  *Build Number       : VMSGPRHOSTCSD_4.2.3_B0001

  * Modified By       : Narayanaswamy.T
  * Modified Date     : 21-APR-2017
  * Purpose           : Master card Tokenization changes
  * Reviewer          : Saravanakumar/Spankaj
  * Build Number      : VMSGPRHOST 17.05

  * Modified By       : Sreeja D
  * Modified Date     : 08-DEC-2017
  * Purpose           : FSS-5306
  * Reviewer          : Saravanakumar
  * Build Number      : VMSGPRHOST_17.11

  * Modified By       : Baskar K
  * Modified Date     : 28-JUN-2018
  * Purpose           : VMS-317,318,320
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR03-B0002

  * Modified By       : Divya Bhaskaran
  * Modified Date     : 24-SEP-2018
  * Purpose           : VMS-540
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR06-B0002

    * Modified By       : Sivakumar M
  * Modified Date     : 11-Oct-2018
  * Purpose           : VMS-581
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR07-B0004

  * Modified By       : Sivakumar M
  * Modified Date     : 07-Feb-2019 
  * Purpose           : VMS-780
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR12-B0003

  * Modified By       : Baskar K
  * Modified Date     : 22-May-2019 
  * Purpose           : VMS-934
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR16-B0004

   * Modified By       : Baskar K
  * Modified Date     : 20-OCT-2020
  * Purpose           : VMS-3138
  * Reviewer          : Saravanakumar
  * Build Number      : VMSGPRHOST_R37_B0002

  * Modified By       : Rajan Devakotta
  * Modified Date     : 11-NOV-2020
  * Purpose           : VMS-3178 - Ran report original merchant ID support
  * Reviewer          : Saravanakumar
  * Build Number      : VMSGPRHOST_R39_B0001

    * Modified By      : Karthick/Jey
    * Modified Date    : 05-17-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
    
  * Modified By       : Bhavani
  * Modified Date     : 30-May-2023
  * Purpose           : VMS-7480 - Log Auth Code
  * Reviewer          : Pankaj
  * Build Number      : VMSGPRHOST_R81_B0001
  
  * Modified By       : Navaneeth
  * Modified Date     : 08-Dec-2023
  * Purpose           : VMS-8145 : Country of Origin Identifier for Bancorp
  * Reviewer          : Pankaj/Venkat/John
  * Build Number      : VMSGPRHOST_R90_B0001
  
  * Modified By       : Mohan E.
  * Modified Date     : 25-July-2024
  * Purpose           : VMS_9002 : Persist Accertify Decline Data Elements in the Transaction Log Table
  * Reviewer          : Pankaj
  * Build Number      : VMSGPRHOST_R100_B0001
*************************************************/

BEGIN
  P_RESP_MSG := 'OK';
  V_RESP_MSG := 'OK'; --Added for FWR 70 review commets
  BEGIN
    V_HASH_PAN := GETHASH(P_CARD_NO);
  EXCEPTION
  WHEN OTHERS THEN
    v_RESP_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
  BEGIN

       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

  IF (v_Retdate>v_Retperiod) THEN                                                        --Added for VMS-5739/FSP-991

    UPDATE TRANSACTIONLOG
    SET COUNTRY_CODE     = P_COUNTRY_CODE,
    merchant_street=p_merchant_street,
    remark=nvl(p_remark,remark),
    AMEX_CSC_RESULT = P_AMEX_CSC_RESULT,
    AMEX_TID = P_AMEX_TID,
    AMEX_SETTLEMENT_RRN = P_AMEX_SETT_RRN,
    amex_csc_indicator = p_amex_csc_indicator,
    amex_csc_status = p_amex_csc_status,
    MC_TERM_ATTENDANCE=p_MC_TERM_ATTENDANCE,
    MC_TERM_LOCATION= p_MC_TERM_LOCATION,
    MC_CARDHOLDER_PRESENCE= p_MC_CARDHOLDER_PRESENCE,
    MC_CARD_PRESENCE= p_MC_CARD_PRESENCE,
    MC_CARD_CAPTURE_CAP= p_MC_CARD_CAPTURE_CAP,
    MC_TRANSACTION_STATUS= p_MC_TRANSACTION_STATUS,
    MC_TRANSACTION_SECURITY= p_MC_TRANSACTION_SECURITY,
    MC_CAT_LEVEL= p_MC_CAT_LEVEL,
    MC_TERM_INPUT_CAP= p_MC_TERM_INPUT_CAP,
    MC_AUTH_LIFE_CYCLE= p_MC_AUTH_LIFE_CYCLE,
    MC_COUNTRY_CODE= p_MC_COUNTRY_CODE,
    MC_POSTAL_CODE= p_MC_POSTAL_CODE,
    MC_CARDHOLDER_AUTH_CAP= p_MC_CARDHOLDER_AUTH_CAP,
    MC_TERM_OPR_ENV= p_MC_TERM_OPR_ENV,
    MC_CARDDATA_INPUT_MODE= p_MC_CARDDATA_INPUT_MODE,
    MC_CARDHOLDER_AUTH_METHOD= p_MC_CARDHOLD_AUTH_MTHD,
    MC_CARDHOLDER_AUTH_ENTITY= p_MC_CARDHOLD_AUTH_ENTITY,
    MC_CARDDATA_OUTPUT_CAP= p_MC_CARDDATA_OUTPUT_CAP,
    MC_TERMDATA_OUTPUT_CAP= p_MC_TERMDATA_OUTPUT_CAP,
    MC_PIN_CAPTURE_CAP= p_MC_PIN_CAPTURE_CAP,
    MC_TERM_PIN_ENTRY_MODE= p_MC_TERM_PIN_ENTRY_MODE, 
    TOKEN_TRAN_TYPE = p_TOKEN_TRAN_TYPE,
    Terminal_Id=P_Terminal_Id,
    Merchant_Id=P_Merchant_Id,
    Merchant_Name=P_Merchant_Name,
    Merchant_State=P_Merchant_State,
    Merchant_City=P_Merchant_City,
    Merchant_Zip=P_Merchant_Zip,
    NETWORKID_SWITCH=P_NETWORKID_SWITCH,
    TRAN_PAYMENT_TYPE=P_Payment_Status,
 	NETWORK_FEE_AMT=p_network_fee_amt,
    NETWORK_FEE_IND=p_network_fee_prgm_indr,
    surchargefee_ind=p_surchargefee_ind_in,
    INTERNATION_IND_RESPONSE=p_internation_ind_in,
    store_id = p_ran_matched_merchant_id,
    NETWORK_AUTH_ID = p_network_auth_id, -- Added for VMS-7480
    rules = p_ols_rule_group,
    rulegroupid = p_merchant_blocking_info,
    de61_tag136_merchantcountryoforigin = p_merchant_country_of_origin,
	src_of_decline = p_src_of_decline,  --Added for VMS-8895
	verbal_actioncode = p_verbal_actioncode,  	-- added for VMS_9002
	negative_list = p_negative_list 			-- added for VMS_9002

    WHERE RRN            = P_RRN
    AND BUSINESS_DATE    = P_TRAN_DATE
    AND BUSINESS_TIME    = P_TRAN_TIME
    AND CUSTOMER_CARD_NO = V_HASH_PAN
    AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
    AND TXN_CODE         = P_TXN_CODE
    AND MSGTYPE          = P_MSG
    And Instcode         = P_Inst_Code
    return error_msg||decode(nvl(p_remark,''),'','',' / '||p_remark) into p_error_msg;

  ELSE

    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                     --Added for VMS-5739/FSP-991
    SET COUNTRY_CODE     = P_COUNTRY_CODE,
    merchant_street=p_merchant_street,
    remark=nvl(p_remark,remark),
    AMEX_CSC_RESULT = P_AMEX_CSC_RESULT,
    AMEX_TID = P_AMEX_TID,
    AMEX_SETTLEMENT_RRN = P_AMEX_SETT_RRN,
    amex_csc_indicator = p_amex_csc_indicator,
    amex_csc_status = p_amex_csc_status,
    MC_TERM_ATTENDANCE=p_MC_TERM_ATTENDANCE,
    MC_TERM_LOCATION= p_MC_TERM_LOCATION,
    MC_CARDHOLDER_PRESENCE= p_MC_CARDHOLDER_PRESENCE,
    MC_CARD_PRESENCE= p_MC_CARD_PRESENCE,
    MC_CARD_CAPTURE_CAP= p_MC_CARD_CAPTURE_CAP,
    MC_TRANSACTION_STATUS= p_MC_TRANSACTION_STATUS,
    MC_TRANSACTION_SECURITY= p_MC_TRANSACTION_SECURITY,
    MC_CAT_LEVEL= p_MC_CAT_LEVEL,
    MC_TERM_INPUT_CAP= p_MC_TERM_INPUT_CAP,
    MC_AUTH_LIFE_CYCLE= p_MC_AUTH_LIFE_CYCLE,
    MC_COUNTRY_CODE= p_MC_COUNTRY_CODE,
    MC_POSTAL_CODE= p_MC_POSTAL_CODE,
    MC_CARDHOLDER_AUTH_CAP= p_MC_CARDHOLDER_AUTH_CAP,
    MC_TERM_OPR_ENV= p_MC_TERM_OPR_ENV,
    MC_CARDDATA_INPUT_MODE= p_MC_CARDDATA_INPUT_MODE,
    MC_CARDHOLDER_AUTH_METHOD= p_MC_CARDHOLD_AUTH_MTHD,
    MC_CARDHOLDER_AUTH_ENTITY= p_MC_CARDHOLD_AUTH_ENTITY,
    MC_CARDDATA_OUTPUT_CAP= p_MC_CARDDATA_OUTPUT_CAP,
    MC_TERMDATA_OUTPUT_CAP= p_MC_TERMDATA_OUTPUT_CAP,
    MC_PIN_CAPTURE_CAP= p_MC_PIN_CAPTURE_CAP,
    MC_TERM_PIN_ENTRY_MODE= p_MC_TERM_PIN_ENTRY_MODE, 
    TOKEN_TRAN_TYPE = p_TOKEN_TRAN_TYPE,
    Terminal_Id=P_Terminal_Id,
    Merchant_Id=P_Merchant_Id,
    Merchant_Name=P_Merchant_Name,
    Merchant_State=P_Merchant_State,
    Merchant_City=P_Merchant_City,
    Merchant_Zip=P_Merchant_Zip,
    NETWORKID_SWITCH=P_NETWORKID_SWITCH,
    TRAN_PAYMENT_TYPE=P_Payment_Status,
 	NETWORK_FEE_AMT=p_network_fee_amt,
    NETWORK_FEE_IND=p_network_fee_prgm_indr,
    surchargefee_ind=p_surchargefee_ind_in,
    INTERNATION_IND_RESPONSE=p_internation_ind_in,
    store_id = p_ran_matched_merchant_id,
    NETWORK_AUTH_ID = p_network_auth_id, -- Added for VMS-7480
    rules = p_ols_rule_group,
    rulegroupid = p_merchant_blocking_info,
    de61_tag136_merchantcountryoforigin = p_merchant_country_of_origin,
	src_of_decline = p_src_of_decline  --Added for VMS-8895

    WHERE RRN            = P_RRN
    AND BUSINESS_DATE    = P_TRAN_DATE
    AND BUSINESS_TIME    = P_TRAN_TIME
    AND CUSTOMER_CARD_NO = V_HASH_PAN
    AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
    AND TXN_CODE         = P_TXN_CODE
    AND MSGTYPE          = P_MSG
    And Instcode         = P_Inst_Code
    return error_msg||decode(nvl(p_remark,''),'','',' / '||p_remark) into p_error_msg;

  END IF;

    IF SQL%ROWCOUNT      = 0 THEN
      v_RESP_MSG        := 'Error While updating countrycode ';
      RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    v_RESP_MSG := 'Error While updating countrycode ' || SUBSTR(SQLERRM, 1, 200);
  END;

    BEGIN

       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

	IF (v_Retdate>v_Retperiod) THEN                                                      --Added for VMS-5739/FSP-991

       UPDATE cms_transaction_log_dtl
          SET ctd_EMVserv_dtl = P_EMVSERV_DTL,
              ctd_othremv_serv = P_OTHER_SERVRSLTCODE,
              CTD_POSENTRYMODE_ID = p_posentry_mode,
              CTD_BILL_CURR  = P_BILL_CURCDE,
              CTD_CNP_INDICATOR=P_CNP_IND,
              CTD_CARDHOLDER_TRAVELING = P_CARDHLD_TRA,
              CTD_DATA_VERSION = P_DATA_VER,
              ctd_seller_id = p_seller_id,
              ctd_probability_score = p_prob_score,
              ctd_dynamic_rulecode = p_dyn_rule_code,
              ctd_csc5_indicator = p_csc5_ind,
              ctd_aevvvalidationresult=p_aevvvalidationresult,
              ctd_aeipsexpresspayrslt=p_AEIPSValidationResult,
              ctd_pinvalidationresults=p_pinvalidationresults,
              ctd_emvdataresults=p_emvdataresults,
              ctd_atcvalidationresults=p_atcvalidationresults,
              ctd_atcvalue=p_atcvalue,
              ctd_cardmbrtravelind=p_cardmembertravelingindicator,
              Ctd_Csc4indicator=P_Csc4indicator,
              ctd_tokenexpdateresult=p_tokenexpirationdateresult,
              ctd_auth_id=p_auth_id_in,  --updating auth while decline case.
              ctd_surchargefee_ind=p_surchargefee_ind_in,
              CTD_INTERNATION_IND_RESPONSE=p_internation_ind_in,
			  CTD_DIGITALCAPABILITIES_IND=p_digitalcapabilities_ind
        WHERE ctd_rrn = p_rrn
          AND ctd_business_date = p_tran_date
          AND ctd_business_time = p_tran_time
          AND ctd_customer_card_no = v_hash_pan
          AND ctd_delivery_channel = p_delivery_channel
          AND ctd_txn_code = p_txn_code
          AND ctd_msg_type = p_msg
          AND ctd_inst_code = p_inst_code;

	ELSE

	       UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                         --Added for VMS-5739/FSP-991                                   
          SET ctd_EMVserv_dtl = P_EMVSERV_DTL,
              ctd_othremv_serv = P_OTHER_SERVRSLTCODE,
              CTD_POSENTRYMODE_ID = p_posentry_mode,
              CTD_BILL_CURR  = P_BILL_CURCDE,
              CTD_CNP_INDICATOR=P_CNP_IND,
              CTD_CARDHOLDER_TRAVELING = P_CARDHLD_TRA,
              CTD_DATA_VERSION = P_DATA_VER,
              ctd_seller_id = p_seller_id,
              ctd_probability_score = p_prob_score,
              ctd_dynamic_rulecode = p_dyn_rule_code,
              ctd_csc5_indicator = p_csc5_ind,
              ctd_aevvvalidationresult=p_aevvvalidationresult,
              ctd_aeipsexpresspayrslt=p_AEIPSValidationResult,
              ctd_pinvalidationresults=p_pinvalidationresults,
              ctd_emvdataresults=p_emvdataresults,
              ctd_atcvalidationresults=p_atcvalidationresults,
              ctd_atcvalue=p_atcvalue,
              ctd_cardmbrtravelind=p_cardmembertravelingindicator,
              Ctd_Csc4indicator=P_Csc4indicator,
              ctd_tokenexpdateresult=p_tokenexpirationdateresult,
              ctd_auth_id=p_auth_id_in,  --updating auth while decline case.
              ctd_surchargefee_ind=p_surchargefee_ind_in,
              CTD_INTERNATION_IND_RESPONSE=p_internation_ind_in,
			  CTD_DIGITALCAPABILITIES_IND=p_digitalcapabilities_ind
        WHERE ctd_rrn = p_rrn
          AND ctd_business_date = p_tran_date
          AND ctd_business_time = p_tran_time
          AND ctd_customer_card_no = v_hash_pan
          AND ctd_delivery_channel = p_delivery_channel
          AND ctd_txn_code = p_txn_code
          AND ctd_msg_type = p_msg
          AND ctd_inst_code = p_inst_code;

	END IF;

       IF SQL%ROWCOUNT = 0
       THEN
          v_resp_msg := 'Error While updating TRANSACTION LOG DTL ';
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record
       THEN
          v_resp_msg :=
                'Error While updating TRANSACTION LOG DTL '
             || SUBSTR (SQLERRM, 1, 200);
    END;
  --<Main Exception>
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  P_RESP_MSG :=v_RESP_MSG;
WHEN OTHERS THEN
  P_RESP_MSG := 'Error While updating countrycode' || SUBSTR(SQLERRM, 1, 200);
END ;
/
show error