create or replace PACKAGE BODY           VMSCMS.VMSMMPOS AS

PROCEDURE  Personalized_card_load(p_inst_code_in                IN      NUMBER,
                                  p_appl_code_in                IN      NUMBER,
                                  p_userpin_in                  IN      VARCHAR2,
                                  p_delvery_chnl_in             IN      VARCHAR2,
                                  P_TXN_CODE_in                 IN      VARCHAR2,
                                  P_TRAN_DATE_in                IN      VARCHAR2,
                                  P_TRAN_TIME_in                IN      VARCHAR2,
                                  P_RRN_in                      IN      VARCHAR2,
                                  P_TXN_MODE_in                 IN      VARCHAR2,
                                  P_MSG_TYPE_in                 IN      VARCHAR2,
                                  p_tran_amt_in                 IN      NUMBER,
                                  p_optin_list                  IN      VARCHAR2, --Added for FSS-3626
                                  p_activation_code_in          IN      VARCHAR2,--Added for FSS-5103 Of 17.05R
                                  p_business_name_in            IN      VARCHAR2,
                                  p_id_type_in                  IN      VARCHAR2,
                                  p_id_number_in                IN      VARCHAR2,
                                  p_id_expiry_date_in           IN      VARCHAR2,
                                  p_type_of_employment_in       IN      VARCHAR2,
                                  p_occupation_in               IN      VARCHAR2,
                                  p_id_province_in              IN      VARCHAR2,
                                  p_id_country_in               IN      VARCHAR2,
                                  p_id_verification_date_in     IN      VARCHAR2,
                                  p_tax_res_of_canada_in        IN      VARCHAR2,
                                  P_Tax_Payer_Id_Number_In      In      Varchar2,
                                  p_reason_for_no_tax_id_type_in     In      Varchar2,
                                  p_reason_for_no_tax_id_in     IN      VARCHAR2,
                                  p_jurisdiction_of_tax_res_in  IN      VARCHAR2,
                                  p_resp_code_out          OUT     VARCHAR2,
                                  --p_resp_message_out        OUT     VARCHAR2,
                                  p_card_number_out             OUT     VARCHAR2,
                                  p_card_acctnum_out            OUT     VARCHAR2,
                                  P_Proxy_Number_Out            Out     Varchar2,
                                   p_resp_message_out            OUT     VARCHAR2,
                                  P_Cust_Id_Out                 Out     Varchar2 ,--Added for VP-177 Of 3.3R
                                   --Added on 11-04-2018 VMS-207--END
                                   p_ThirdPartyEnabled             In        Varchar2,
                                  p_ThirdPartyType                In        Varchar2,
                                  p_ThirdPartyFirstName           In        Varchar2,
                                  p_ThirdPartyLastName            In        Varchar2,
                                  p_ThirdPartyCorporationName     In        Varchar2,
                                  p_ThirdPartyCorporation         In        Varchar2,
                                  p_ThirdPartyAddress1            In        Varchar2,
                                  p_ThirdPartyAddress2            In        Varchar2,
                                  p_ThirdPartyCity                In        Varchar2,
                                  p_ThirdPartyState               In        Varchar2,
                                  p_ThirdPartyZIP                 In        Varchar2,
                                  p_ThirdPartyCountry             In        Varchar2,
                                  p_ThirdPartyNatureRelationship  In        Varchar2,
                                  p_ThirdPartyBusiness            In        Varchar2,
                                  p_ThirdPartyOccupationType      In        Varchar2,
                                  p_ThirdPartyOccupation          In        Varchar2,
                                  P_Thirdpartydob                 In        Varchar2,
                                  p_member_id                     In        Varchar2, --Added on 22-03-2021 for VMS-3846
                                  p_shipment_method               In        NUMBER
                                  )
                                AS

  /***********************************************************

* Created By                   : Siva Kumar M
* Created  Date                : 14-Aug-15
* Created  For                 : FSS-2125
* Created  reason              : B2B Production Solution
* Reviewer                     : Spankaj/Saravana Kumar
* Build Number                 : VMSGPRHOSTCSD3.1_B0002

* Modified by                  : Siva Kumar M
* Modified Date                : 01-SEPT-15
* Modified  For                 : Mantis id:16168
* Created  reason              : Limit validation not working
* Reviewer                     : aravana Kumar
* Build Number                 : VMSGPRHOSTCSD3.1_B0008

* Modified by                  : Siva Kumar M
* Modified Date                : 09-SEPT-15
* Modified  For                 : Mantis id:16168
* Created  reason              : Review Changes
* Reviewer                     : saravana Kumar
* Build Number                 : VMSGPRHOSTCSD3.1_B0010

* Modified by                  : MageshKumar S
* Modified Date                : 14-SEPT-15
* Modified  For                 : Mantis id:16196
* Reviewer                     : saravana Kumar
* Build Number                 : VMSGPRHOSTCSD3.1_B0013

* Modified by                  : MageshKumar S
* Modified Date                : 09-OCT-15
* Modified  For                : B2B Card Status and Limit Change
* Reviewer                     : saravana Kumar
* Build Number                 : VMSGPRHOSTCSD3.1.2_B0001

* Modified by                  : Ramesh A
* Modified Date                : 30-Sep-15
* Modified For                 : FSS-3626
* Reviewer                     : Saravanankumar
* Build Number                 : VMSGPRHOSTCSD3.2

* Modified by                  : MageshKumar S
* Modified Date                : 05-JAN-16
* Modified  For                : VP-177
* Reviewer                     : SARAVANAKUMAR/SPANKAJ
* Build Number                 : VMSGPRHOSTCSD3.3_B0003

* Modified by                  : MageshKumar S
* Modified Date                : 09-MAY-17
* Modified  For                : FSS-5103
* Reviewer                     : SARAVANAKUMAR/SPANKAJ
* Build Number                 : VMSGPRHOSTCSD17.05_B0001

    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

    * Modified by        : Siva Kumar M
     * Modified Date     : 21-Jul-17
     * Modified For      : FSS-5165-MMPOS - Business Name
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

	 * Modified by        :Saravanakumar
     * Modified Date     : 31-Aug-17
     * Modified For      : Integration changes of 17.05.4
     * Reviewer          : Pankaj salunkhe
     * Build Number      :

	   * Modified by         : Sreeja D
     * Modified Date     : 23-Nov-17
     * Modified For      : VMS - 74
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.11

     * Modified By      : MAGESHKUMAR S
     * Modified Date    : 22-MAR-2021
     * Purpose          : VMS-3846.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R44

     * Modified By      : MAGESHKUMAR S
     * Modified Date    : 10-AUG-2022
     * Purpose          : VMS-5697
     * Reviewer         : Pankaj Salunkhe
     * Release Number   : VMSGPRHOST_R67

     * Modified By      : Shanmugavel
     * Modified Date    : 23/05/2024
     * Purpose          : VMS-8526-Remove Auto Enabled Reload Alerts for Instant Personalized Category
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR98_B0001
  ***********************************************************/

      l_err_msg               VARCHAR2(500);
      l_respcode              cms_response_mast.CMS_ISO_RESPCDE%type;
      l_tran_date             DATE;
      l_pan_number            VARCHAR2(20);
      l_applproces_msg        VARCHAR2(100);
      l_expiry_date           CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
      l_prod_code             CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
      l_card_type             CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
      l_card_stat             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
      L_PRECHECK_FLAG         PCMS_TRANAUTH_PARAM.PTP_PARAM_VALUE%TYPE;
      l_lmtprfl               cms_prdcattype_lmtprfl.cpl_lmtprfl_id%type;
      l_profile_level         cms_appl_pan.cap_prfl_levl%type;
      l_CARD_ACCT_NO          cms_appl_pan.CAP_ACCT_NO%TYPE;
      l_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
      l_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
      l_TXN_TYPE              CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
      l_TRANSFER_FLAG         CMS_TRANSACTION_MAST.CTM_AMNT_TRANSFER_FLAG%TYPE;
      l_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
      l_LOGIN_TXN             CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      l_prfl_flag             CMS_TRANSACTION_MAST. ctm_prfl_flag%TYPE;
      l_hash_pan              cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan              cms_appl_pan.cap_pan_code_encr%TYPE;
      l_tran_amt              NUMBER;
      l_cap_prod_catg         cms_appl_pan.cap_prod_catg%type;
      l_base_curr             cms_bin_param.cbp_param_value%type;
      l_comb_hash             pkg_limits_check.type_hash;
      l_card_curr             VARCHAR2 (5);
      exp_reject_record       EXCEPTION;
      l_timestamp             TIMESTAMP;
      l_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
      l_NARRATION             VARCHAR2 (300);
      L_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
      l_spprt_resoncode       cms_spprt_reasons.csr_spprt_rsncode%TYPE;
      l_remrk                 VARCHAR2(100);
      L_CAP_PROXY_NUMBER      CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
      l_b2bcard_status        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;--added for B2B Card status change
 --Sn Added for FSS-3626 Implementation for MMPOS
     l_sms_optinflag            cms_optin_status.cos_sms_optinflag%TYPE;
     l_email_optinflag          cms_optin_status.cos_email_optinflag%TYPE;
     l_markmsg_optinflag        cms_optin_status.cos_markmsg_optinflag%TYPE;
     l_gpresign_optinflag       cms_optin_status.cos_gpresign_optinflag%TYPE;
     l_savingsesign_optinflag   cms_optin_status.cos_savingsesign_optinflag%TYPE;
     l_optin_type               cms_optin_status.cos_sms_optinflag%TYPE;
     l_optin_split              cms_optin_status.cos_sms_optinflag%TYPE;
     l_optin_list               VARCHAR2(1000);
     l_comma_pos                NUMBER;
     l_comma_pos1               NUMBER;
     i                          NUMBER:=1;
     l_tandc_version            CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
     l_OPTIN_FLAG               VARCHAR2(10) DEFAULT 'N';
     l_cust_id                  cms_cust_mast.ccm_cust_id%TYPE;
     l_CUST_CODE                cms_cust_mast.ccm_cust_code%TYPE;
     l_count                    NUMBER;
     l_optin                    VARCHAR2(1);
	   l_id_province              GEN_STATE_MAST.GSM_SWITCH_STATE_CODE%TYPE;
	   l_id_country               GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
	   L_Jurisdiction_Of_Tax_Res  Gen_Cntry_Mast.Gcm_Alpha_Cntry_Code%Type;
         L_Thirdparty_Count Number(2);
   L_Occupation_Desc Vms_Occupation_Mast.Vom_Occu_Name%Type;
      L_State_Switch_Code  Gen_State_Mast.Gsm_Switch_State_Code%Type;
   L_Cntrycode   Number(10);
    L_State_Desc  Vms_Thirdparty_Address.Vta_State_Desc%Type;
   l_state_code Vms_Thirdparty_Address.Vta_State_code%Type;
    --En Added for FSS-3626 Implementation for MMPOS
	V_PROXY_GENFLAG           	CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

 BEGIN
         l_remrk :='PERSONALIZED CARD WITH LOAD';
         p_resp_code_out :='00';
         p_resp_message_out :='OK';



           BEGIN
              l_tran_date :=
                 TO_DATE (   SUBSTR (TRIM (P_TRAN_DATE_in), 1, 8)
                          || SUBSTR (TRIM (P_TRAN_TIME_in), 1, 10),
                          'yyyymmddhh24:mi:ss'
                         );
           EXCEPTION
              WHEN OTHERS
              THEN
                 l_respcode := '32';
                 l_err_msg :=
                       'Problem while converting transaction Time '
                    || SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
           END;



           BEGIN
                    SELECT CTM_CREDIT_DEBIT_FLAG,
                      CTM_OUTPUT_TYPE,
                      CTM_TRAN_TYPE,
                      CTM_AMNT_TRANSFER_FLAG,
                      CTM_TRAN_DESC,
                      CTM_LOGIN_TXN,
                      ctm_prfl_flag
                      INTO
                      l_DR_CR_FLAG,
                      l_OUTPUT_TYPE,
                      l_TXN_TYPE,
                      l_TRANSFER_FLAG,
                      l_TRANS_DESC ,
                      l_LOGIN_TXN,
                      l_prfl_flag
                      FROM CMS_TRANSACTION_MAST
                      WHERE  CTM_TRAN_CODE = P_TXN_CODE_in
                             AND CTM_DELIVERY_CHANNEL = p_delvery_chnl_in
                             AND CTM_INST_CODE = p_inst_code_in;
           EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_respcode := '21';
                        l_err_msg:= 'Error while selecting transflag ' || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
           END;

		   BEGIN
			 SELECT
				NVL(CIP_PARAM_VALUE,'N')
			INTO V_PROXY_GENFLAG
			FROM
				CMS_INST_PARAM
			WHERE
				CIP_PARAM_KEY = 'MMPOS_PROXYGEN_FLAG'
				AND CIP_INST_CODE = 1;
			EXCEPTION
				WHEN OTHERS THEN
					V_PROXY_GENFLAG := 'N';
		   END;

            BEGIN

              sp_gen_pan (p_inst_code_in,
                        p_appl_code_in,
                        p_userpin_in,
                        l_pan_number,
                        l_applproces_msg,
                        l_err_msg,
                        V_PROXY_GENFLAG );   -- for generating the proxy number
      --Sn modified for Mantis id:16196
                IF l_err_msg <> 'OK'
                THEN

                IF l_err_msg ='Institution multiple SSN / Other ID level check failed' OR l_err_msg ='Product multiple SSN / Other ID level check failed'
                THEN
                   l_respcode := '146';
                   l_err_msg := l_err_msg;
                   RAISE exp_reject_record;


               ELSIF l_err_msg <> 'Institution multiple SSN / Other ID level check failed' AND l_err_msg <> 'Product multiple SSN / Other ID level check failed'
               THEN
                   l_respcode := '21';
                   l_err_msg := l_err_msg;
                   RAISE exp_reject_record;
              END IF;
              END IF;

                IF l_applproces_msg <> 'OK'
                THEN

                IF l_applproces_msg ='Institution multiple SSN / Other ID level check failed' OR l_applproces_msg ='Product multiple SSN / Other ID level check failed'
                THEN
                   l_respcode := '146';
                   l_err_msg := l_applproces_msg;
                   RAISE exp_reject_record;
               -- END IF;

                ELSIF l_applproces_msg <> 'Institution multiple SSN / Other ID level check failed' AND l_applproces_msg <> 'Product multiple SSN / Other ID level check failed'
                THEN
                   l_respcode := '21';
                   l_err_msg := l_applproces_msg;
                   RAISE exp_reject_record;
                END IF;
                END IF;
    --En modified for Mantis id:16196
             EXCEPTION
            WHEN exp_reject_record
            THEN
             -- l_respcode := l_respcode;
              -- l_err_msg := l_applproces_msg||l_err_msg;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_err_msg :=
                     'Error while generating PAN ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
            ENd;

            BEGIN

                SELECT CAP_EXPRY_DATE,
                CAP_PROD_CODE,
                CAP_CARD_TYPE,
                CAP_CARD_STAT,
                fn_dmaps_main(cap_pan_code_encr),
                cap_acct_no,cap_prod_catg,CAP_PROXY_NUMBER ,
                ccm_cust_code,--Added for FSS-3626 Implementation for MMPOS
                ccm_cust_id --Added for FSS-3626 Implementation for MMPOS
                INTO
                l_expiry_date,
                l_prod_code,
                l_card_type,
                l_card_stat,
                l_pan_number,
                l_CARD_ACCT_NO,
                l_cap_prod_catg,
                L_CAP_PROXY_NUMBER,
                l_CUST_CODE,--Added for FSS-3626 Implementation for MMPOS
                l_cust_id --Added for FSS-3626 Implementation for MMPOS
                FROM CMS_APPL_PAN,cms_cust_mast  --Added for FSS-3626 Implementation for MMPOS
                WHERE CAp_appl_code =p_appl_code_in
                AND  CAp_inst_code=p_inst_code_in
				AND cap_inst_code=ccm_inst_code
                AND cap_cust_code = ccm_cust_code; --Added for FSS-3626 Implementation for MMPOS

            EXCEPTION
            WHEN OTHERS THEN
            l_err_msg := 'Error while selecting pan details' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;

            END;


           BEGIN
              l_hash_pan := gethash (l_pan_number);

           EXCEPTION
              WHEN OTHERS
              THEN
                 l_err_msg :='Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_reject_record;
           END;


           BEGIN
              l_encr_pan := fn_emaps_main (l_pan_number);
           EXCEPTION
              WHEN OTHERS
              THEN
                 l_respcode := '12';
                 l_err_msg := 'Error while converting encrypted pan ' || SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_reject_record;
           END;


          --Sn added for B2B card status changes

            BEGIN

               SELECT CPC_B2BCARD_STAT
               INTO l_b2bcard_status
               FROM CMS_PROD_CATTYPE
               WHERE CPC_PROD_CODE=l_prod_code AND CPC_CARD_TYPE=l_card_type AND CPC_INST_CODE=p_inst_code_in;

              EXCEPTION

              WHEN OTHERS THEN
                l_respcode := '21';
                l_err_msg  := 'Error while checking b2b card status configured' ||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;

            END;

            IF l_b2bcard_status IS NOT NULL THEN

            BEGIN

                    UPDATE cms_appl_pan
                    SET    cap_card_stat = l_b2bcard_status
                    WHERE  cap_pan_code  = l_hash_pan;

              EXCEPTION WHEN OTHERS
              THEN
                   l_err_msg := 'Error while changing B2B card status '||substr(sqlerrm,1,100);
                   RAISE EXP_REJECT_RECORD;

            END;

            END IF;

            --En added for B2B card status changes

           l_timestamp := SYSTIMESTAMP;

             BEGIN
                L_HASHKEY_ID := GETHASH (p_delvery_chnl_in
                                                        || P_TXN_CODE_in
                                                        || l_pan_number
                                                        || P_RRN_in
                                                        || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_err_msg :='Error while converting hashkeyid '|| SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
            END;



              BEGIN

                SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO l_AUTH_ID FROM DUAL;
              EXCEPTION
                WHEN OTHERS
                THEN
                    l_err_msg :='Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                    l_respcode := '21';
                    RAISE exp_reject_record;
                END;

            Begin

              IF TRIM (l_TRANS_DESC) IS NOT NULL
              THEN
              l_NARRATION := l_TRANS_DESC || '/';
              END IF;

                IF TRIM (l_AUTH_ID) IS NOT NULL
                THEN
                    l_NARRATION := l_NARRATION || l_AUTH_ID || '/';
                END IF;

                  IF TRIM (l_CARD_ACCT_NO) IS NOT NULL
                THEN
                    l_NARRATION := l_NARRATION || l_CARD_ACCT_NO || '/';
                END IF;

                IF TRIM (P_TRAN_DATE_in) IS NOT NULL
                THEN
                    l_NARRATION := l_NARRATION || P_TRAN_DATE_in;
                END IF;

            EXCEPTION
               WHEN OTHERS THEN
                l_err_msg :='Error in  narration'|| SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;

            end;

            BEGIN
--                      SELECT TRIM (cbp_param_value)  INTO l_base_curr FROM cms_bin_param
--                      WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_inst_code_in
--                      AND cbp_profile_code in (select  cpm_profile_code from
--                      cms_prod_mast where cpm_prod_code = l_prod_code and cpm_inst_code=p_inst_code_in);
vmsfunutilities.get_currency_code(l_prod_code,l_card_type,p_inst_code_in,l_base_curr,l_err_msg);

      if l_err_msg<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;
                 IF TRIM (l_base_curr) IS NULL
                    THEN
                       l_respcode := '21';
                       l_err_msg  := 'Base currency cannot be null ';
                       RAISE EXP_REJECT_RECORD;
                    END IF;
            EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                    RAISE;
              WHEN OTHERS
             THEN
              l_respcode := '21';
              l_err_msg  :='Error while selecting bese currecy'|| SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
            END;
        BEGIN
           UPDATE CMS_CUST_MAST
             SET CCM_BUSINESS_NAME = p_business_name_in,
                 CCM_ID_TYPE = UPPER(p_id_type_in),
			        	 CCM_SSN  = fn_maskacct_ssn(p_inst_code_in,p_id_number_in,0),
                 CCM_SSN_ENCR = fn_emaps_main(p_id_number_in),
				         CCM_IDEXPRY_DATE =
                   DECODE (UPPER(p_id_type_in),
                           'SSN', NULL,'SIN', NULL,
                           TO_DATE (p_id_expiry_date_in, 'mmddyyyy')
                          ),
				         CCM_OCCUPATION_OTHERS = p_type_of_employment_in,
                 CCM_OCCUPATION = p_occupation_in,
                 CCM_ID_PROVINCE = p_id_province_in,
                 CCM_ID_COUNTRY = p_id_country_in,
                 CCM_VERIFICATION_DATE = DECODE (UPPER(p_id_type_in),
                                   'SSN', NULL,'SIN', NULL,
                                   TO_DATE (p_id_verification_date_in, 'mmddyyyy')
                                  ),
                 CCM_TAX_RES_OF_CANADA = UPPER(p_tax_res_of_canada_in),
                 Ccm_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number_In,
               Ccm_Reason_For_No_Tax_Id = P_Reason_For_No_Tax_Id_Type_In,
                    ccm_reason_for_no_taxid_others = upper(p_reason_for_no_tax_id_IN),
                 CCM_JURISDICTION_OF_TAX_RES = p_jurisdiction_of_tax_res_in,
                 Ccm_Third_Party_Enabled=upper(P_Thirdpartyenabled),CCM_MEMBER_ID=p_member_id
                   WHERE  ccm_cust_code = l_CUST_CODE
                   AND ccm_inst_code = p_inst_code_in;
              IF SQL%ROWCOUNT = 0 THEN
                l_err_msg :='bussiness name not updated against customer';
                 RAISE EXP_REJECT_RECORD;
               END IF;
               EXCEPTION
                   WHEN EXP_REJECT_RECORD THEN
                            RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                    l_err_msg :='Error while upadating bussiness name in custmat' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
               END;


     If  P_Thirdpartyenabled Is Not Null And Upper(P_Thirdpartyenabled)='Y'
      then

          Begin
              select to_number(gcm_cntry_code) into l_cntryCode
              from gen_cntry_mast
              where GCM_ALPHA_CNTRY_CODE=upper(p_ThirdPartyCountry) or GCM_SWITCH_CNTRY_CODE=upper(p_ThirdPartyCountry)
              and Gcm_Inst_Code=p_inst_code_in;
           EXCEPTION
            When No_Data_Found Then
             l_err_msg   := 'Invalid Country Code' ;
             l_respcode := '49';
             Raise EXP_REJECT_RECORD;
              When Others Then
               l_respcode := '21';
               l_err_msg   := 'Error while selecting gen_cntry_mast ' || Substr(Sqlerrm, 1, 300);
               Raise EXP_REJECT_RECORD;
          end;

    if p_thirdpartytype = '1' and p_thirdpartyoccupationType is not null and p_thirdpartyoccupationType <> '00' then
        begin
           select vom_occu_name into l_occupation_desc
           from vms_occupation_mast
           where vom_occu_code =p_thirdpartyoccupationtype;

         EXCEPTION
          When No_Data_Found Then
             l_err_msg   := 'Invalid ThirdParty Occupation Code' ;
             l_respcode := '49';
             Raise EXP_REJECT_RECORD;
           When Others Then
           L_Respcode := '21';
           l_err_msg   := 'Error while selecting Vms_Occupation_Mast ' || substr(sqlerrm, 1, 300);
           Raise Exp_Reject_Record;
        End;
    End If;
    If P_Thirdpartycountry Is Not Null And P_Thirdpartycountry  In ('US','CA','USA','CAN') Then
         Begin
        --  l_State_Code:=P_Thirdpartystate;

        Select Gsm_Switch_State_Code,gsm_state_code  Into l_State_Switch_Code,l_State_Code
        from Gen_State_Mast
        Where GSM_SWITCH_STATE_CODE=upper(P_Thirdpartystate)
        and Gsm_Cntry_Code=l_cntryCode
        and Gsm_Inst_Code=p_inst_code_in;

        EXCEPTION
         When No_Data_Found Then
           l_err_msg   := 'Invalid ThirdParty State Code' ;
           l_Respcode := '49';
           Raise EXP_REJECT_RECORD;
          When Others Then
           l_Respcode := '21';
           l_err_msg   := 'Error while selecting Gen_State_Mast ' || Substr(Sqlerrm, 1, 300);
           Raise EXP_REJECT_RECORD;
        End;
    Else
       L_State_Code:='';
      l_State_Desc:=P_Thirdpartystate;
      end if;

    Begin

     Insert Into Vms_Thirdparty_Address
          (Vta_Inst_Code,Vta_Cust_Code,VTA_THIRDPARTY_TYPE,VTA_FIRST_NAME,VTA_LAST_NAME,VTA_ADDRESS_ONE,VTA_ADDRESS_TWO,VTA_CITY_NAME,VTA_STATE_CODE,VTA_STATE_DESC,VTA_STATE_SWITCH,VTA_CNTRY_CODE,
        Vta_Pin_Code,Vta_Occupation,Vta_Occupation_Others,VTA_NATURE_OF_BUSINESS,VTA_DOB,VTA_NATURE_OF_RELEATIONSHIP,
        VTA_CORPORATION_NAME,VTA_INCORPORATION_NUMBER,Vta_Ins_User ,Vta_Ins_Date ,Vta_Lupd_User ,Vta_Lupd_Date)
     Values (P_Inst_Code_In,L_Cust_Code,P_Thirdpartytype,Upper(P_Thirdpartyfirstname),Upper(P_Thirdpartylastname),Upper(P_Thirdpartyaddress1),Upper(P_Thirdpartyaddress2),
    Upper(P_Thirdpartycity),L_State_Code,Upper(L_State_Desc),L_State_Switch_Code,L_Cntrycode,P_Thirdpartyzip,P_Thirdpartyoccupationtype,
    Upper(Decode(P_Thirdpartyoccupationtype,'00',P_Thirdpartyoccupation,L_Occupation_Desc)),Upper(P_Thirdpartybusiness),To_Date(P_Thirdpartydob,'MM/DD/YYYY'),Upper(P_Thirdpartynaturerelationship),Upper(P_Thirdpartycorporationname),
    upper(p_ThirdPartyCorporation),1,sysdate,1,sysdate);


      EXCEPTION
            When Others Then
             l_Respcode := '21';
             l_err_msg   := 'Error while Inserting third party  address details in Vms_Thirdparty_Address ' || SUBSTR(SQLERRM, 1, 300);
             Raise EXP_REJECT_RECORD;
    End ;
  end if;


                    BEGIN
                            SELECT cpl_lmtprfl_id
                              INTO l_lmtprfl
                              FROM cms_prdcattype_lmtprfl
                             WHERE cpl_inst_code = p_inst_code_in
                               AND cpl_prod_code = l_prod_code
                               AND cpl_card_type = l_card_type;

                            l_profile_level := 2;
                    EXCEPTION
                     WHEN NO_DATA_FOUND
                            THEN
                               BEGIN
                                  SELECT cpl_lmtprfl_id
                                    INTO l_lmtprfl
                                    FROM cms_prod_lmtprfl
                                   WHERE cpl_inst_code = p_inst_code_in
                                     AND cpl_prod_code = l_prod_code;

                                  l_profile_level := 3;
                               EXCEPTION
                                  WHEN NO_DATA_FOUND
                                  THEN
                                     NULL;
                                  WHEN OTHERS
                                  THEN
                                     l_err_msg:='Error while selecting Limit Profile At Product Level'|| SQLERRM;

                                     RAISE EXP_REJECT_RECORD;
                               END;
                    WHEN EXP_REJECT_RECORD THEN
                    RAISE;

                    WHEN OTHERS
                     THEN
                     l_err_msg :='Error while selecting Limit Profile At Product Catagory Level'|| SQLERRM;
                     RAISE EXP_REJECT_RECORD;

                    END;


                      BEGIN
                           UPDATE cms_appl_pan
                                SET  cap_prfl_code = l_lmtprfl,
                                cap_prfl_levl = l_profile_level,
                                cap_activation_code=p_activation_code_in,
                                cap_repl_flag=NVL(p_shipment_method,cap_repl_flag)
                                WHERE cap_inst_code = p_inst_code_in
                                AND cap_pan_code =l_hash_pan;

                      IF SQL%ROWCOUNT = 0
                        THEN
                          l_err_msg :='Activating GPR card ACTIVE DATE NOT UPDATED' || l_hash_pan;
                          RAISE EXP_REJECT_RECORD;
                         END IF;
                      EXCEPTION
                         WHEN EXP_REJECT_RECORD
                         THEN
                            RAISE EXP_REJECT_RECORD;
                      WHEN OTHERS
                         THEN
                            l_err_msg :='Error while Activating GPR card' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                      END;


                   IF l_cap_prod_catg = 'P' THEN

                      BEGIN
                         IF l_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y' THEN


                            pkg_limits_check.sp_limits_check (l_hash_pan,
                                                              NULL,
                                                              NULL,
                                                              NULL,
                                                              P_TXN_CODE_in,
                                                              l_TXN_TYPE,
                                                              NULL,
                                                              NULL,
                                                              p_inst_code_in,
                                                              NULL,
                                                              l_lmtprfl,
                                                              p_tran_amt_in,
                                                              p_delvery_chnl_in,
                                                              l_comb_hash,
                                                              l_respcode,
                                                              l_err_msg
                                                             );
                         END IF;

                         IF l_respcode <> '00' AND l_err_msg <> 'OK'
                         THEN
                          /*
                          IF( NVL(SUBSTR(l_respcode,1,1),0)='F'
                          OR NVL(SUBSTR(l_respcode,1,1),0)='T'
                          OR NVL(SUBSTR(l_respcode,1,1),0)='A'
                          OR NVL(SUBSTR(l_respcode,1,1),0)='R'
                          OR NVL(SUBSTR(l_respcode,1,1),0)='S'
                          OR NVL(SUBSTR(l_respcode,1,1),0)='0') THEN

                          if  l_respcode='79' then
                              l_respcode:='231';
                              l_err_msg:='Denomination below minimal amount permitted';

                          RAISE EXP_REJECT_RECORD;
                          end if;

                            if l_respcode='80' then
                              l_respcode:='230';
                              l_err_msg:='Denomination exceed permitted amount';

                          RAISE EXP_REJECT_RECORD;
                          end if;

                         else

                            l_err_msg := 'Error from Limit Check Process ' || l_err_msg; */
                            RAISE EXP_REJECT_RECORD;
                          -- END IF;
                         END IF;
                      EXCEPTION
                         WHEN EXP_REJECT_RECORD
                         THEN
                            RAISE;
                         WHEN OTHERS
                         THEN
                            l_respcode := '21';
                            l_err_msg := 'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                      END;

                   END IF;

               --Sn Selecting Reason code for Initial Load
               BEGIN
                  SELECT csr_spprt_rsncode
                    INTO l_spprt_resoncode
                    FROM cms_spprt_reasons
                   WHERE csr_inst_code = p_inst_code_in AND csr_spprt_key = 'INILOAD';
               EXCEPTION
                   WHEN OTHERS
                  THEN
                     l_respcode := '21';
                     l_err_msg  :='Error while selecting reason code from master'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
               END;

               --Sn create a record in pan spprt
               BEGIN
                  INSERT INTO cms_pan_spprt
                              (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                               cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                               cps_ins_user, cps_lupd_user, cps_cmd_mode,
                               cps_pan_code_encr
                              )
                       VALUES (p_inst_code_in, l_hash_pan, '000', l_cap_prod_catg,
                               'INLOAD', l_spprt_resoncode, l_remrk,
                               1, 1, 0,
                               l_encr_pan);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                    l_respcode := '21';
                    l_err_msg:='Error while inserting records into card support master'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;
               END;

               --En create a record in pan spprt

--            VMS-8526 : I removed the CSA_LOADORCREDIT_FLAG update in the CMS_SMSANDEMAIL_ALERT table.
--            BEGIN
--                  UPDATE CMS_SMSANDEMAIL_ALERT
--                  SET CSA_LOADORCREDIT_FLAG=3
--                  WHERE CSA_INST_CODE=p_inst_code_in AND CSA_PAN_CODE=l_hash_pan;
--
--                IF SQL%ROWCOUNT = 0 THEN
--               l_err_msg   := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT'||Substr(Sqlerrm, 1, 200);
--               l_respcode := '21';
--               Raise EXP_REJECT_RECORD;
--             END IF;
--             EXCEPTION
--           WHEN EXP_REJECT_RECORD THEN
--                     RAISE EXP_REJECT_RECORD;
--           WHEN OTHERS THEN
--                l_err_msg   := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT table'||Substr(Sqlerrm, 1, 200);
--                l_respcode := '21';
--           Raise EXP_REJECT_RECORD;
--
--           END;



                       IF (TO_NUMBER (p_tran_amt_in) >= 0)
                      THEN
                        -- v_tran_amt := prm_act_amt;

                         BEGIN
                            sp_convert_curr (p_inst_code_in,
                                             l_base_curr,
                                             l_pan_number,
                                             p_tran_amt_in,
                                             l_tran_date,
                                             l_tran_amt,
                                             l_card_curr,
                                             l_err_msg,
                                             l_prod_code,
                                             l_card_type
                                            );

                            IF l_err_msg <> 'OK'
                            THEN
                               l_respcode := '23';
                               RAISE EXP_REJECT_RECORD;
                            END IF;
                         EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                               RAISE;
                         WHEN OTHERS  THEN
                               l_respcode := '22';
                               l_err_msg :='::'||l_err_msg||'::'|| SUBSTR (SQLERRM, 1, 200);
                               RAISE EXP_REJECT_RECORD;
                         END;
                      ELSE

                         l_respcode := '43';
                         l_err_msg := 'INVALID AMOUNT';
                         RAISE EXP_REJECT_RECORD;
                      END IF;


		IF p_id_province_in IS NOT NULL
		AND p_id_country_in IS NOT NULL
		THEN
			BEGIN
				SELECT gcm_cntry_code
				INTO l_id_country
				FROM gen_cntry_mast
				WHERE gcm_inst_code   = p_inst_code_in
				AND gcm_switch_cntry_code  = p_id_country_in;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_respcode := '274';
          l_err_msg  := 'Invalid Data for Country code';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_respcode := '21';
          l_err_msg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;

        BEGIN
          SELECT gsm_switch_state_code
          INTO l_id_province
          FROM gen_state_mast
          WHERE gsm_inst_code   = p_inst_code_in
		    AND gsm_cntry_code = l_id_country
            AND gsm_switch_state_code  = p_id_province_in;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_respcode := '273';
          l_err_msg  := 'Invalid Data for Province';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_respcode := '21';
          l_err_msg  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
	 END IF;
	 IF p_jurisdiction_of_tax_res_in IS NOT NULL
	 THEN
         BEGIN
          SELECT gcm_switch_cntry_code
          INTO l_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_inst_code_in
          AND gcm_switch_cntry_code  = p_jurisdiction_of_tax_res_in;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_respcode := '275';
          l_err_msg  := 'Invalid Data for Jurisdiction of tax residence';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_respcode := '21';
          l_err_msg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
       END IF;


            BEGIN
                  SP_UPD_TRANSACTION_ACCNT_AUTH (p_inst_code_in,
                                                                     l_TRAN_DATE,
                                                                     l_prod_code,
                                                                     l_card_type,
                                                                     l_tran_amt,
                                                                     null,
                                                                     P_TXN_CODE_in,
                                                                     l_DR_CR_FLAG,
                                                                     P_RRN_in,
                                                                     NULL,
                                                                     p_delvery_chnl_in,
                                                                     P_TXN_MODE_in,
                                                                     l_pan_number,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     l_CARD_ACCT_NO,
                                                                     '',
                                                                     P_MSG_TYPE_in,
                                                                     l_respcode,
                                                                     l_err_msg);

              IF (l_respcode <> '1' OR l_err_msg <> 'OK')
                THEN
               l_respcode := '10';
               RAISE EXP_REJECT_RECORD;
              END IF;

            EXCEPTION
            WHEN EXP_REJECT_RECORD
             THEN
             RAISE;
            WHEN OTHERS
             THEN
             l_respcode := '11';
             l_err_msg :='Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
            END;

--Sn Added for FSS-3626 Implementation for MMPOS
     IF p_optin_list IS NOT NULL THEN
      BEGIN

         LOOP

            l_comma_pos:= instr(p_optin_list,',',1,i);

            IF i=1 AND l_comma_pos=0 THEN
                l_optin_list:=p_optin_list;
            ELSIF i<>1 AND l_comma_pos=0 THEN
                l_comma_pos1:= instr(p_optin_list,',',1,i-1);
                l_optin_list:=substr(p_optin_list,l_comma_pos1+1);
             ELSIF i<>1 AND l_comma_pos<>0 THEN
                l_comma_pos1:= instr(p_optin_list,',',1,i-1);
                l_optin_list:=substr(p_optin_list,l_comma_pos1+1,l_comma_pos-l_comma_pos1-1);
            ELSIF i=1 AND l_comma_pos<>0 THEN
                l_optin_list:=substr(p_optin_list,1,l_comma_pos-1);
            END IF;

            i:=i+1;

            l_optin_type:=substr(l_optin_list,1,instr(l_optin_list,':',1,1)-1);
            l_optin_split:=substr(l_optin_list,instr(l_optin_list,':',1,1)+1);


          BEGIN
             IF l_optin_type IS NOT NULL AND l_optin_type = '1'
             THEN
                l_sms_optinflag := l_optin_split;
                 l_OPTIN_FLAG := 'Y';
             ELSIF l_optin_type IS NOT NULL AND l_optin_type = '2'
             THEN
                l_email_optinflag := l_optin_split;
                l_OPTIN_FLAG := 'Y';
             ELSIF l_optin_type IS NOT NULL AND l_optin_type = '3'
             THEN
                l_markmsg_optinflag := l_optin_split;
                l_OPTIN_FLAG := 'Y';
             ELSIF l_optin_type IS NOT NULL AND l_optin_type = '4'
             THEN
                l_gpresign_optinflag := l_optin_split;
                l_OPTIN_FLAG := 'Y';
              if l_gpresign_optinflag = 1 then
                BEGIN

               	   SELECT nvl(CPC_TANDC_VERSION,'')
                   INTO l_tandc_version
                   FROM CMS_PROD_CATTYPE
					WHERE CPC_PROD_CODE=l_prod_code
					AND CPC_CARD_TYPE= l_card_type
					AND CPC_INST_CODE=p_inst_code_in;

                EXCEPTION
                WHEN others THEN

                  l_respcode := '21';
                  l_err_msg :='Error from  featching the t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;

                END;

                BEGIN

                        UPDATE cms_cust_mast
                        set ccm_tandc_version=l_tandc_version
                        WHERE ccm_inst_code=p_inst_code_in
						  AND ccm_cust_code=l_CUST_CODE;

                        IF  SQL%ROWCOUNT =0 THEN
                           l_respcode := '21';
                           l_err_msg :=
                                 ' T and C version not updated ';
                             RAISE EXP_REJECT_RECORD;

                        END IF;


                EXCEPTION

                 WHEN EXP_REJECT_RECORD THEN
                  RAISE ;
                 WHEN others THEN

                   l_respcode := '21';
                   l_err_msg :='Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
                END;
               end if;
             ELSIF l_optin_type IS NOT NULL AND l_optin_type = '5'
               THEN
                l_savingsesign_optinflag := l_optin_split;
                l_OPTIN_FLAG := 'Y';
             END IF;
          END;

         IF l_OPTIN_FLAG = 'Y' THEN
              BEGIN
                 SELECT COUNT (*)
                   INTO l_count
                   FROM cms_optin_status
                  WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;

                 IF l_count > 0
                 THEN
                    UPDATE cms_optin_status
                       SET cos_sms_optinflag =
                                              NVL (l_sms_optinflag, cos_sms_optinflag),
                           cos_sms_optintime =
                              NVL (DECODE (l_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                   cos_sms_optintime
                                  ),
                           cos_sms_optouttime =
                              NVL (DECODE (l_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                   cos_sms_optouttime
                                  ),
                           cos_email_optinflag =
                                          NVL (l_email_optinflag, cos_email_optinflag),
                           cos_email_optintime =
                              NVL (DECODE (l_email_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optintime
                                  ),
                           cos_email_optouttime =
                              NVL (DECODE (l_email_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optouttime
                                  ),
                           cos_markmsg_optinflag =
                                      NVL (l_markmsg_optinflag, cos_markmsg_optinflag),
                           cos_markmsg_optintime =
                              NVL (DECODE (l_markmsg_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optintime
                                  ),
                           cos_markmsg_optouttime =
                              NVL (DECODE (l_markmsg_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optouttime
                                  ),
                           cos_gpresign_optinflag =
                                    NVL (l_gpresign_optinflag, cos_gpresign_optinflag),
                           cos_gpresign_optintime =
                              NVL (DECODE (l_gpresign_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optintime
                                  ),
                           cos_gpresign_optouttime =
                              NVL (DECODE (l_gpresign_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optouttime
                                  ),
                           COS_SAVINGSESIGN_OPTINFLAG =
                                    NVL (l_savingsesign_optinflag, COS_SAVINGSESIGN_OPTINFLAG),
                           COS_SAVINGSESIGN_OPTINTIME =
                              NVL (DECODE (l_savingsesign_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   COS_SAVINGSESIGN_OPTINTIME
                                  ),
                           COS_SAVINGSESIGN_OPTOUTTIME =
                              NVL (DECODE (l_savingsesign_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   COS_SAVINGSESIGN_OPTOUTTIME
                                  )

                     WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;
                 ELSE
                    INSERT INTO cms_optin_status
                                (cos_inst_code, cos_cust_id, cos_sms_optinflag,
                                 cos_sms_optintime,
                                 cos_sms_optouttime,
                                 cos_email_optinflag,
                                 cos_email_optintime,
                                 cos_email_optouttime,
                                 cos_markmsg_optinflag,
                                 cos_markmsg_optintime,
                                 cos_markmsg_optouttime,
                                 cos_gpresign_optinflag,
                                 cos_gpresign_optintime,
                                 cos_gpresign_optouttime,
                                 COS_SAVINGSESIGN_OPTINFLAG,
                                 COS_SAVINGSESIGN_OPTINTIME,
                                 COS_SAVINGSESIGN_OPTOUTTIME
                                )
                         VALUES (p_inst_code_in, l_cust_id, l_sms_optinflag,
                                 DECODE (l_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (l_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                 l_email_optinflag,
                                 DECODE (l_email_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (l_email_optinflag, '0', SYSTIMESTAMP, NULL),
                                 l_markmsg_optinflag,
                                 DECODE (l_markmsg_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (l_markmsg_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 l_gpresign_optinflag,
                                 DECODE (l_gpresign_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (l_gpresign_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 l_savingsesign_optinflag,
                                 DECODE (l_savingsesign_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (l_savingsesign_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        )
                                );
                 END IF;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    l_respcode := '21';
                    l_err_msg  :='ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' || SUBSTR (SQLERRM, 1, 300);
                    RAISE EXP_REJECT_RECORD;
              END;
         END IF;

              IF l_comma_pos=0 THEN
                    exit;
                END IF;


        END LOOP;
        END;

     END IF;

   --En Added for FSS-3626 Implementation for MMPOS

              begin

                         INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                        CSL_ACCT_NO,
                                                        CSL_PANNO_LAST4DIGIT,
                                                        csl_acct_type,
                                                        csl_time_stamp,
                                                        csl_prod_code,csl_card_type )
                                                     VALUES (l_HASH_PAN,
                                                               0,  -- opening balance
                                                               l_tran_amt,
                                                               l_DR_CR_FLAG,
                                                               l_TRAN_DATE,
                                                               l_tran_amt,
                                                               l_NARRATION,
                                                               l_encr_pan,
                                                               P_RRN_in,
                                                               l_AUTH_ID,
                                                               P_TRAN_DATE_in,
                                                               P_TRAN_TIME_in,
                                                               'N',
                                                               p_delvery_chnl_in,
                                                               p_inst_code_in,
                                                               P_TXN_CODE_in,
                                                               SYSDATE,
                                                               1,
                                                               l_CARD_ACCT_NO,
                                                               (SUBSTR (l_pan_number,
                                                                           LENGTH (l_pan_number) - 3,
                                                                           LENGTH (l_pan_number))),
                                                               1,
                                                               l_timestamp,
                                                               l_prod_code,l_card_type);
              EXCEPTION
                     WHEN OTHERS THEN
                  l_respcode := '21';
                  l_err_msg := 'Error while inserting in statements log' || SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
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
                          TOPUP_CARD_NO,
                          TOPUP_ACCT_NO,
                          TOPUP_ACCT_TYPE,
                          BANK_CODE,
                          TOTAL_AMOUNT,
                          RULE_INDICATOR,
                          RULEGROUPID,
                          MCCODE,
                          CURRENCYCODE,
                          ADDCHARGE,
                          PRODUCTID,
                          CATEGORYID,
                          TIPS,
                          DECLINE_RULEID,
                          ATM_NAME_LOCATION,
                          AUTH_ID,
                          TRANS_DESC,
                          AMOUNT,
                          PREAUTHAMOUNT,
                          PARTIALAMOUNT,
                          MCCODEGROUPID,
                          CURRENCYCODEGROUPID,
                          TRANSCODEGROUPID,
                          RULES,
                          PREAUTH_DATE,
                          GL_UPD_FLAG,
                          SYSTEM_TRACE_AUDIT_NO,
                          INSTCODE,
                          CR_DR_FLAG,
                          CUSTOMER_CARD_NO_ENCR,
                          RESPONSE_ID,
                          REVERSAL_CODE,
                          TIME_STAMP,
                          ERROR_MSG,
                          CUSTOMER_ACCT_NO,
                          ACCT_BALANCE,
                          LEDGER_BALANCE,
                          PROXY_NUMBER)
                        VALUES
                         (P_MSG_TYPE_in,
                          P_RRN_in,
                          p_delvery_chnl_in,
                          NULL,
                          l_TRAN_DATE,
                          P_TXN_CODE_in,
                          l_TXN_TYPE,
                          P_TXN_MODE_in,
                          'C',
                          '00',
                          P_TRAN_DATE_in,
                          P_TRAN_TIME_in,
                          l_HASH_PAN,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          p_tran_amt_in,
                          NULL,
                          NULL,
                          NULL,
                          l_base_curr,
                          NULL,
                          l_prod_code,
                          l_card_type,
                          NULL,
                          NULL,
                          NULL,
                          l_AUTH_ID,
                          l_TRANS_DESC,
                          p_tran_amt_in,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          'N',
                          NULL,
                          p_inst_code_in,
                          l_DR_CR_FLAG,
                          l_ENCR_PAN,
                          1,
                          0,
                          l_timestamp,
                          p_resp_message_out,l_CARD_ACCT_NO,l_tran_amt,l_tran_amt,L_CAP_PROXY_NUMBER);
                     EXCEPTION
                        WHEN OTHERS THEN
                         l_respcode := '21';
                         l_err_msg := 'Error while inserting in transaction log' || SUBSTR(SQLERRM, 1, 200);
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
                          CTD_FEE_AMOUNT,
                          CTD_WAIVER_AMOUNT,
                          CTD_SERVICETAX_AMOUNT,
                          CTD_CESS_AMOUNT,
                          CTD_BILL_AMOUNT,
                          CTD_BILL_CURR,
                          CTD_PROCESS_FLAG,
                          CTD_PROCESS_MSG,
                          CTD_RRN,
                          CTD_SYSTEM_TRACE_AUDIT_NO,
                          CTD_CUSTOMER_CARD_NO_ENCR,
                          CTD_HASHKEY_ID)
                        VALUES
                         (p_delvery_chnl_in,
                          P_TXN_CODE_in,
                          L_TXN_TYPE,
                          P_TXN_MODE_in,
                          P_TRAN_DATE_in,
                          P_TRAN_TIME_in,
                          l_HASH_PAN,
                          p_tran_amt_in,
                          l_base_curr,
                          p_tran_amt_in,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          'Y',
                          'Successful',
                          P_RRN_in,
                          NULL,
                          l_ENCR_PAN,
                          L_HASHKEY_ID);

               EXCEPTION
                 WHEN OTHERS THEN
                    l_respcode := '21';
                    l_err_msg := 'Error while inserting in transaction log detail' || SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
               END;
               p_resp_message_out :=l_tran_amt;
               p_card_number_out  :=l_pan_number;
               p_card_acctnum_out :=l_CARD_ACCT_NO;
               p_proxy_number_out :=L_CAP_PROXY_NUMBER;
               p_cust_id_out      :=l_cust_id;--Added for VP-177 Of 3.3R
         COMMIT;

 EXCEPTION  -- MAIN  exception

 WHEN EXP_REJECT_RECORD THEN

  ROLLBACK;

     BEGIN

        SELECT CMS_ISO_RESPCDE
        INTO   p_resp_code_out
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE_IN AND
            CMS_DELIVERY_CHANNEL = p_delvery_chnl_in AND
            CMS_RESPONSE_ID = l_respcode;
     EXCEPTION
       WHEN OTHERS THEN
       p_resp_message_out  := 'Problem while selecting data from response master ' ||
                    l_respcode || SUBSTR(SQLERRM, 1, 300);
        p_resp_code_out := '69';


     END;
     p_resp_message_out := l_err_msg;

 WHEN OTHERS THEN

   ROLLBACK;

     p_resp_code_out :=l_respcode;
     p_resp_message_out := l_err_msg;

   END;

PROCEDURE        View_profileaudit_details (
   p_inst_code          IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_reason_code        IN       VARCHAR2,
   p_res_code           OUT      VARCHAR2,
   p_res_msg            OUT      VARCHAR2
)
AS
   v_auth_savepoint     NUMBER                                      DEFAULT 0;
   v_err_msg            VARCHAR2 (500);
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type           transactionlog.txn_type%TYPE;
   v_auth_id            transactionlog.auth_id%TYPE;
   exp_reject_record    EXCEPTION;
   v_dr_cr_flag         VARCHAR2 (2);
   v_tran_type          VARCHAR2 (2);
   v_tran_amt           NUMBER;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde           VARCHAR2 (5);
   v_time_stamp         TIMESTAMP;
   v_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag          cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_preauth_flag       cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type          cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number       cms_appl_pan.cap_proxy_number%TYPE;
   v_fee_code           transactionlog.feecode%TYPE;
   v_fee_plan           transactionlog.fee_plan%TYPE;
   v_feeattach_type     transactionlog.feeattachtype%TYPE;
   v_tranfee_amt        transactionlog.tranfee_amt%TYPE;
   v_total_amt          transactionlog.total_amount%TYPE;
   v_expry_date         cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash          pkg_limits_check.type_hash;
   v_login_txn          cms_transaction_mast.ctm_login_txn%TYPE;
   v_logdtl_resp        VARCHAR2 (500);
   v_cap_mbrno          cms_appl_pan.cap_mbr_numb%TYPE;
   v_rrn_count          NUMBER;
   v_cust_code          cms_appl_pan.cap_cust_code%TYPE;
      v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
/**********************************************************************************************
               * Created Date     :20-August-2014
               * Created By       :Dhinakaran B
               * PURPOSE          : JH=3005

               * Modified Date     :20-August-2014
               * Modified By       :Dhinakaran B
               * Modified PURPOSE  : Addind the response code for 89.


  * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;

   BEGIN
      SAVEPOINT v_auth_savepoint;

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan

      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while converting encrypted pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Start Generate HashKEY value
      BEGIN
         v_hashkey_id :=
            gethash (   p_delivery_channel
                     || p_txn_code
                     || p_pan_code
                     || p_rrn
                     || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Generate HashKEY

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                ctm_preauth_flag, ctm_login_txn
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag,
                v_preauth_flag, v_login_txn
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting transaction details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

      --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_proxy_number, cap_mbr_numb, cap_cust_code
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_proxy_number, v_cap_mbrno, v_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Card number not found ' || v_encr_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --Sn Duplicate RRN Check.
      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
       WHERE  OPERATION_TYPE='ARCHIVE'
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN


         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = p_inst_code
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
ELSE
		 SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
END IF;

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while duplicate rrn check  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Duplicate RRN Check
      BEGIN
         sp_cmsauth_check (p_inst_code,
                           p_msg_type,
                           p_rrn,
                           p_delivery_channel,
                           p_txn_code,
                           p_txn_mode,
                           p_tran_date,
                           p_tran_time,
                           v_cap_mbrno,
                           p_rvsl_code,
                           v_tran_type,
                           p_curr_code,
                           v_tran_amt,
                           p_pan_code,
                           v_hash_pan,
                           v_encr_pan,
                           v_card_stat,
                           v_expry_date,
                           v_prod_code,
                           v_card_type,
                           v_prfl_flag,
                           v_prfl_code,
                           NULL,
                           NULL,
                           NULL,
                           v_resp_cde,
                           v_err_msg,
                           v_comb_hash
                          );

         IF v_err_msg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error from  cmsauth Check Procedure '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting Account  detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_fee_calc (p_inst_code,
                      p_msg_type,
                      p_rrn,
                      p_delivery_channel,
                      p_txn_code,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      v_cap_mbrno,
                      p_rvsl_code,
                      v_txn_type,
                      p_curr_code,
                      v_tran_amt,
                      p_pan_code,
                      v_hash_pan,
                      v_encr_pan,
                      v_acct_number,
                      v_prod_code,
                      v_card_type,
                      v_preauth_flag,
                      NULL,
                      NULL,
                      NULL,
                      v_trans_desc,
                      v_dr_cr_flag,
                      v_acct_bal,
                      v_ledger_bal,
                      v_acct_type,
                      v_login_txn,
                      v_auth_id,
                      v_time_stamp,
                      v_resp_cde,
                      v_err_msg,
                      v_fee_code,
                      v_fee_plan,
                      v_feeattach_type,
                      v_tranfee_amt,
                      v_total_amt,
                     v_compl_fee,
                     v_compl_feetxn_excd,
                     v_compl_feecode
                     );

         IF v_err_msg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
      FOR i  IN
         ( SELECT a.vai_column_name fieldName,
  DECODE(b.vai_action_user,'1','SYSTEM',nvl(fn_dmaps_main(b.vai_action_username),(SELECT cum_user_name
  FROM cms_user_mast
  WHERE cum_user_pin= b.vai_action_user
  ))) lastModifiedUserName,
  to_char(b.vai_action_date,'MM/DD/YYYY') lastModifiedDate,
  to_char(b.vai_action_date,'HH24MISS') lastModifiedTime,
  CASE
    WHEN upper(a.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
    THEN
      (SELECT gcm_cntry_name
      FROM gen_cntry_mast
      WHERE gcm_inst_code=1
      AND gcm_cntry_code = to_number(a.vai_old_val )
      )
    WHEN upper(a.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
    THEN
      (SELECT upper(gsm_state_name)
      FROM gen_state_mast
      WHERE gsm_inst_code=1
      AND gsm_cntry_code = to_number(SUBSTR(a.vai_old_val ,1,1))
      AND gsm_state_code = to_number(SUBSTR( a.vai_old_val , 3 ))
      )
    ELSE a.vai_old_val
  END originalValue,
  CASE
    WHEN upper(b.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
    THEN
      (SELECT gcm_cntry_name
      FROM gen_cntry_mast
      WHERE gcm_inst_code=1
      AND gcm_cntry_code = to_number(b.vai_new_val )
      )
    WHEN upper(b.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
    THEN
      (SELECT upper(gsm_state_name)
      FROM gen_state_mast
      WHERE gsm_inst_code=1
      AND gsm_cntry_code = to_number(SUBSTR(b.vai_new_val ,1,1))
      AND gsm_state_code = to_number(SUBSTR( b.vai_new_val , 3 ))
      )
    ELSE b.vai_new_val
  END updatedValue
FROM
  (SELECT *
  FROM
    (SELECT vai_cust_code,
      vam_table_name,
      vai_column_name,
      vai_action_type,
      fn_dmaps_main(decode(vai_action_type,'I',TO_CHAR(vai_new_val),TO_CHAR(vai_old_val))) vai_old_val,
      vai_action_date,
      ROW_NUMBER () OVER (PARTITION BY vai_cust_code,vai_column_name ORDER BY vai_action_date ASC)r
    FROM vms_audit_info,
      vms_audit_mast
    WHERE vam_table_id = vai_table_id
    AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
  AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH','O-CAM_PHONE_ONE','O-CAM_MOBL_ONE','O-CAM_EMAIL')
    AND vai_cust_code  = v_cust_code
    )
  WHERE r=1
  )a,
  (SELECT *
  FROM
    (SELECT vai_cust_code,
      vam_table_name,
      vai_column_name,
      vai_action_user,
      vai_action_date,
      vai_action_username,
      vai_action_type,
      fn_dmaps_main(TO_CHAR(vai_new_val)) vai_new_val,
      ROW_NUMBER () OVER (PARTITION BY vai_cust_code,vai_column_name ORDER BY vai_action_date DESC)r
    FROM vms_audit_info,
      vms_audit_mast
    WHERE vam_table_id = vai_table_id
  AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH','O-CAM_PHONE_ONE','O-CAM_MOBL_ONE','O-CAM_EMAIL')
    AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
    AND vai_cust_code  = v_cust_code
    )
  WHERE r=1
  )b
WHERE a.vai_column_name=b.vai_column_name
and ((a.vai_action_type='I' AND a.vai_action_date <>b.vai_action_date) or a.vai_action_type='U'))
LOOP
BEGIN
   IF i.fieldName = 'CCM_FIRST_NAME' THEN
         i.fieldName := 'First Name';
   ELSIF  i.fieldName = 'CCM_LAST_NAME' THEN
         i.fieldName := 'Last Name';
   ELSIF  i.fieldName = 'CCM_LAST_NAME' THEN
         i.fieldName := 'Last Name';
   ELSIF  i.fieldName = 'CCM_SSN' THEN
         i.fieldName := 'ID Number';
   ELSIF  i.fieldName = 'CCM_BIRTH_DATE' THEN
         i.fieldName := 'DOB';
   ELSIF  i.fieldName = 'CCM_AUTH_USER' THEN
         i.fieldName := 'Authorized User';
   ELSIF  i.fieldName = 'CCM_ID_PROVINCE' THEN
         i.fieldName := 'ID Province';
   ELSIF  i.fieldName = 'CCM_ID_COUNTRY' THEN
         i.fieldName := 'ID Country';
   ELSIF  i.fieldName = 'CCM_VERIFICATION_DATE' THEN
         i.fieldName := 'Verification Date';
   ELSIF  i.fieldName = 'CCM_TAX_RES_OF_CANADA' THEN
         i.fieldName := 'Res of Canada';
   ELSIF  i.fieldName = 'CCM_TAX_PAYER_ID_NUM' THEN
         i.fieldName := 'Tax Payer Id Number';
   ELSIF  i.fieldName = 'CCM_JURISDICTION_OF_TAX_RES' THEN
         i.fieldName := 'Tax Jurisdiction Residence';
   ELSIF  i.fieldName = 'CCM_OCCUPATION_OTHERS' THEN
         i.fieldName := 'Occupation';
   ELSIF  i.fieldName = 'CCM_ID_TYPE' THEN
         i.fieldName := 'Id Type';
   ELSIF  i.fieldName = 'CCM_IDEXPRY_DATE' THEN
         i.fieldName := 'Id Expiry Date';
   ELSIF  i.fieldName = 'CCM_THIRD_PARTY_ENABLED' THEN
         i.fieldName := 'Third Party Enabled';
   ELSIF  i.fieldName = 'CCM_REASON_FOR_NO_TAXID_OTHERS' THEN
         i.fieldName := 'Reason For No Tax ID';
   ELSIF  i.fieldName = 'P-CAM_ADD_ONE' THEN
         i.fieldName := 'Physical Address 1';
   ELSIF  i.fieldName = 'P-CAM_ADD_TWO' THEN
         i.fieldName := 'Physical Address 2';
   ELSIF  i.fieldName = 'P-CAM_CITY_NAME' THEN
         i.fieldName := 'Physical City';
   ELSIF  i.fieldName = 'P-CAM_CNTRY_CODE' THEN
         i.fieldName := 'Physical Country';
   ELSIF  i.fieldName = 'P-CAM_STATE_CODE' THEN
         i.fieldName := 'Physical State';
   ELSIF  i.fieldName = 'P-CAM_PIN_CODE' THEN
         i.fieldName := 'Physical ZIP';
   ELSIF  i.fieldName = 'P-CAM_MOBL_ONE' THEN
         i.fieldName := 'Cell Phone Number';
   ELSIF  i.fieldName = 'P-CAM_PHONE_ONE' THEN
         i.fieldName := 'Home Phone Number';
   ELSIF  i.fieldName = 'P-CAM_EMAIL' THEN
         i.fieldName := 'Email Address';
   ELSIF  i.fieldName = 'O-CAM_ADD_ONE' THEN
         i.fieldName := 'Mailing Address 1';
   ELSIF  i.fieldName = 'O-CAM_ADD_TWO' THEN
         i.fieldName := 'Mailing Address 2';
   ELSIF  i.fieldName = 'O-CAM_CITY_NAME' THEN
         i.fieldName := 'Mailing City';
   ELSIF  i.fieldName = 'O-CAM_CNTRY_CODE' THEN
         i.fieldName := 'Mailing Country';
   ELSIF  i.fieldName = 'O-CAM_STATE_CODE' THEN
         i.fieldName := 'Mailing State';
   ELSIF  i.fieldName = 'O-CAM_PIN_CODE' THEN
         i.fieldName := 'Mailing ZIP';
   ELSIF  i.fieldName = 'VTA_THIRDPARTY_TYPE' THEN
         i.fieldName := 'Third Party Type';
         IF i.originalValue = '1' THEN
            i.originalValue := 'Individual';
         ELSIF i.originalValue = '2' THEN
            i.originalValue := 'Corporation';
         END IF;
         IF  i.updatedValue = '1' THEN
            i.updatedValue := 'Individual';
         ELSIF  i.updatedValue = '2' THEN
            i.updatedValue := 'Corporation';
         END IF;
   ELSIF  i.fieldName = 'VTA_FIRST_NAME' THEN
         i.fieldName := 'Third Party First Name';
   ELSIF  i.fieldName = 'VTA_LAST_NAME' THEN
         i.fieldName := 'Third Party Last Name';
   ELSIF  i.fieldName = 'VTA_ADDRESS_ONE' THEN
         i.fieldName := 'Third Party Address 1';
   ELSIF  i.fieldName = 'VTA_ADDRESS_TWO' THEN
         i.fieldName := 'Third Party Address 2';
   ELSIF  i.fieldName = 'VTA_CITY_NAME' THEN
         i.fieldName := 'Third Party City Name';
   ELSIF  i.fieldName = 'VTA_STATE_CODE' THEN
         i.fieldName := 'Third Party State Code';
   ELSIF  i.fieldName = 'VTA_STATE_DESC' THEN
         i.fieldName := 'Third Party State Desc';
   ELSIF  i.fieldName = 'VTA_CNTRY_CODE' THEN
         i.fieldName := 'Third Party Country Code';
   ELSIF  i.fieldName = 'VTA_PIN_CODE' THEN
         i.fieldName := 'Third Party Pin Code';
   ELSIF  i.fieldName = 'VTA_OCCUPATION_OTHERS' THEN
         i.fieldName := 'Third Party Occupation';
   ELSIF  i.fieldName = 'VTA_NATURE_OF_BUSINESS' THEN
         i.fieldName := 'Third Party Nature of Business';
   ELSIF  i.fieldName = 'VTA_DOB' THEN
         i.fieldName := 'Third Party DOB';
   ELSIF  i.fieldName = 'VTA_NATURE_OF_RELEATIONSHIP' THEN
         i.fieldName := 'Third Party Nature of RelationShip';
   ELSIF  i.fieldName = 'VTA_CORPORATION_NAME' THEN
         i.fieldName := 'Third Party Corporation Name';
   ELSIF  i.fieldName = 'VTA_INCORPORATION_NUMBER' THEN
         i.fieldName := 'Third Party InCorporation Name';
          END IF;

p_res_msg := p_res_msg||i.fieldName||'~'||i.originalValue||'~'||i.updatedValue||'~'||i.lastModifiedDate||'~'||i.lastModifiedTime||'~'||i.lastModifiedUserName ||'||';
EXCEPTION
WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                       'Error in Audit array  ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
END;
 END LOOP;
 IF p_res_msg is not null AND length(p_res_msg)>0 THEN
    p_res_msg := substr(p_res_msg,1,(length(p_res_msg)-2));
 END IF;
 EXCEPTION
    WHEN exp_reject_record THEN
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg        := 'Error in Audit info'||SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;

  p_res_code := '00';

   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_res_msg := v_err_msg;
         ROLLBACK TO v_auth_savepoint;

         --Sn Get responce code fomr master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_res_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Problem while selecting data from response master '
                  || p_res_code
                  || SUBSTR (SQLERRM, 1, 300);
               p_res_code := '89';
         END;
      WHEN OTHERS
      THEN
         p_res_code := '21';
         p_res_msg :=
                v_err_msg || 'Main Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_acct_bal := 0;
         v_ledger_bal := 0;
   END;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code,
                     p_msg_type,
                     p_rrn,
                     p_delivery_channel,
                     p_txn_code,
                     v_tran_type,
                     p_txn_mode,
                     p_tran_date,
                     p_tran_time,
                     p_rvsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_trans_desc,
                     NULL,
                     NULL,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_bal,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_total_amt,
                     v_fee_code,
                     v_tranfee_amt,
                     v_fee_plan,
                     v_feeattach_type,
                     v_resp_cde,
                     p_res_code,
                     p_curr_code,
                     v_err_msg,
                     p_rrn
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_res_code := '89';
         v_err_msg :=
                   'Exception while inserting to transaction log ' || SQLERRM;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (p_inst_code,
                         p_msg_type,
                         p_rrn,
                         p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_acct_number,
                         v_auth_id,
                         v_tran_amt,
                         NULL,
                         NULL,
                         v_hashkey_id,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         p_res_code,
                         NULL,
                         p_reason_code,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_res_code := '89';
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_res_code := '69';                                  -- Server Declined
      p_res_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;


PROCEDURE sp_mmpos_cardreload_txnstatus (
        p_inst_code          IN NUMBER,
        p_msg_type           IN VARCHAR2,
        p_rrn                IN VARCHAR2,
        p_delivery_channel   IN VARCHAR2,
        p_txn_code           IN VARCHAR2,
        p_txn_mode           IN VARCHAR2,
        p_tran_date          IN VARCHAR2,
        p_tran_time          IN VARCHAR2,
        p_pan_code           IN VARCHAR2,
        p_curr_code          IN VARCHAR2,
        p_tran_amount        IN VARCHAR2,
        p_rvsl_code          IN VARCHAR2,
        p_orgnl_rrn          IN VARCHAR2,
        p_client_refno       IN VARCHAR2,
        p_res_code           OUT VARCHAR2,
        p_res_msg            OUT VARCHAR2
    ) AS

        v_auth_savepoint   NUMBER DEFAULT 0;
        v_err_msg          VARCHAR2(500);
        v_hash_pan         cms_appl_pan.cap_pan_code%TYPE;
        v_encr_pan         cms_appl_pan.cap_pan_code_encr%TYPE;
        v_txn_type         transactionlog.txn_type%TYPE;
        v_auth_id          transactionlog.auth_id%TYPE;

        v_dr_cr_flag       cms_transaction_mast.ctm_credit_debit_flag%TYPE;
        v_tran_type        cms_transaction_mast.ctm_tran_type%TYPE;

        v_prod_code        cms_appl_pan.cap_prod_code%TYPE;
        v_card_type        cms_appl_pan.cap_card_type%TYPE;
        v_resp_cde         cms_response_mast.cms_response_id%TYPE;
        v_time_stamp       TIMESTAMP;
        v_hashkey_id       cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
        v_trans_desc       cms_transaction_mast.ctm_tran_desc%TYPE;
        v_prfl_flag        cms_transaction_mast.ctm_prfl_flag%TYPE;
        v_acct_number      cms_appl_pan.cap_acct_no%TYPE;
        v_prfl_code        cms_appl_pan.cap_prfl_code%TYPE;
        v_card_stat        cms_appl_pan.cap_card_stat%TYPE;
        v_preauth_flag     cms_transaction_mast.ctm_preauth_flag%TYPE;
        v_acct_bal         cms_acct_mast.cam_acct_bal%TYPE;
        v_ledger_bal       cms_acct_mast.cam_ledger_bal%TYPE;
        v_acct_type        cms_acct_mast.cam_type_code%TYPE;
        v_proxy_number     cms_appl_pan.cap_proxy_number%TYPE;
        v_fee_code         transactionlog.feecode%TYPE;
        v_fee_plan         transactionlog.fee_plan%TYPE;
        v_feeattach_type   transactionlog.feeattachtype%TYPE;
        v_tranfee_amt      transactionlog.tranfee_amt%TYPE;
        v_expry_date       cms_appl_pan.cap_expry_date%TYPE;
        v_comb_hash        pkg_limits_check.type_hash;
        v_login_txn        cms_transaction_mast.ctm_login_txn%TYPE;
        v_logdtl_resp      VARCHAR2(500);
        v_rrn_count        PLS_INTEGER;
        v_txnresp_msg      transactionlog.error_msg%TYPE;
        txn_hashkey_id     cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
        v_cur_hashkey      cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
       -- v_clientref_cnt    PLS_INTEGER;
        v_orgl_date        vms_additional_parameters.VAP_INS_DATE%TYPE;
        v_orgl_txncode     vms_additional_parameters.VAP_TRANS_CODE%TYPE;
        v_orgl_channel     vms_additional_parameters.VAP_CHANNEL%TYPE;
        exp_reject_record  EXCEPTION;

/**********************************************************************************************
               * Created Date     :05-MAR-2020
               * Created By       :Dhinakaran B
               * PURPOSE          :VMS-1970
               * Reviewer         : Saravana Kumar A

               * Modified by                 : Mageshkumar S
               * Modified Date               : 27-JULY-2020
               * Modified For                : VMS-2875
               * Reviewer                    : Saravana Kumar A
               * Build Number                : VMSGPRHOST_R34_B1

               * Modified by                 : Shanmugavel M
               * Modified Date               : 15-DEC-2023
               * Modified For                : VMS-8133-MMPOS - GetReloadStatus API returns "89" response code when the original RRN not found.
               * Reviewer                    : Venkat/John/Pankaj
               * Build Number                : VMSGPRHOST_R90_B1
/**********************************************************************************************/
    BEGIN
        v_time_stamp := systimestamp;
        BEGIN


      --Sn Get the HashPan
            BEGIN
                v_hash_pan := gethash(p_pan_code);
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '12';
                    v_err_msg := 'Error while converting hash pan '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --En Get the HashPan

      --Sn Create encr pan

            BEGIN
                v_encr_pan := fn_emaps_main(p_pan_code);
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '12';
                    v_err_msg := 'Error while converting encrypted pan '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --Start Generate HashKEY value

            BEGIN
                v_hashkey_id := gethash(p_delivery_channel
                 || p_txn_code
                 || p_pan_code
                 || p_rrn
                 || TO_CHAR(v_time_stamp,'YYYYMMDDHH24MISSFF5') );
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error while converting hashkey id data '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --End Generate HashKEY

      --Sn find debit and credit flag

            BEGIN
                SELECT
                    ctm_credit_debit_flag,
                    to_number(DECODE(
                        ctm_tran_type,
                        'N',
                        '0',
                        'F',
                        '1'
                    ) ),
                    ctm_tran_type,
                    ctm_tran_desc,
                    ctm_prfl_flag,
                    ctm_preauth_flag,
                    ctm_login_txn
                INTO v_dr_cr_flag,v_txn_type,v_tran_type,v_trans_desc,v_prfl_flag,v_preauth_flag,v_login_txn
                FROM cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                    AND ctm_delivery_channel = p_delivery_channel
                    AND ctm_inst_code = p_inst_code;
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error while selecting transaction details'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --En find debit and credit flag

      --Sn Get the card details

            BEGIN
                SELECT
                    cap_card_stat,
                    cap_prod_code,
                    cap_card_type,
                    cap_acct_no,
                    cap_proxy_number
                INTO
                    v_card_stat,v_prod_code,v_card_type,v_acct_number,v_proxy_number
                FROM cms_appl_pan
                WHERE  cap_inst_code = p_inst_code
                AND cap_pan_code = v_hash_pan
                AND CAP_MBR_NUMB = '000';
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '12';
                    v_err_msg := 'Problem while selecting card detail'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --End Get the card details

            BEGIN
                SELECT
                    cam_acct_bal,
                    cam_ledger_bal,
                    cam_type_code
                INTO
                    v_acct_bal,v_ledger_bal,v_acct_type
                FROM
                    cms_acct_mast
                WHERE  cam_acct_no = v_acct_number
                AND  cam_inst_code = p_inst_code;
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Problem while selecting Account  detail '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --Sn generate auth id

            BEGIN
                SELECT
                    lpad(
                        seq_auth_id.NEXTVAL,
                        6,
                        '0'
                    )
                INTO   v_auth_id
                FROM  dual;

            EXCEPTION
                WHEN OTHERS THEN
                    v_err_msg := 'Error while generating authid '
                     || substr(sqlerrm,1,300);
                    v_resp_cde := '21';
                    RAISE exp_reject_record;
            END;

      --En generate auth id

      --Sn Duplicate RRN Check.

          /*  BEGIN
                SELECT  COUNT(1)
                INTO  v_rrn_count
                FROM  transactionlog
                WHERE instcode = p_inst_code
                    AND rrn = p_rrn
                    AND  business_date = p_tran_date
                    AND delivery_channel = p_delivery_channel;

                IF
                    v_rrn_count > 0
                THEN
                    v_resp_cde := '22';
                    v_err_msg := 'Duplicate RRN ' || ' on ' || p_tran_date;
                    RAISE exp_reject_record;
                END IF;

            EXCEPTION
                WHEN exp_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error while duplicate rrn check  '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;*/--Duplicate check not required hence commented out

      --En Duplicate RRN Check


      --Sn Get the original details from vms_additional_parameters

            BEGIN
            SELECT  vap_ins_date ,vap_trans_code ,vap_channel  INTO v_orgl_date,v_orgl_txncode,v_orgl_channel FROM (
                SELECT vap_ins_date ,vap_trans_code ,vap_channel
               -- INTO  v_orgl_date,v_orgl_txncode,v_orgl_channel
                FROM  vms_additional_parameters
                WHERE vap_rrn = p_orgnl_rrn
                    AND vap_attribute_value = p_client_refno
                    AND vap_attribute_name = 'ClientRefNo'
                    AND vap_channel = p_delivery_channel
                    AND vap_trans_code in('10','80','81','82','85','86','88','92','93')
		    ORDER BY VAP_INS_DATE ASC )WHERE ROWNUM=1;
            EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                    v_resp_cde := '97';
                    v_err_msg := 'Original Not found,Retry  ';
                    RAISE exp_reject_record;
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := ' Error while  getting the client_referno and original rrn matching  '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;
          --En Get the original details from vms_additional_parameters

          --Sn Get the original txn status from trasactionlog
            BEGIN
                SELECT response_code INTO p_res_code FROM (SELECT response_code
                FROM VMSCMS.TRANSACTIONLOG	--Added for VMS-5733/FSP-991
                WHERE RRN = p_orgnl_rrn
                    AND DELIVERY_CHANNEL = v_orgl_channel
                    AND ADD_INS_DATE  >= v_orgl_date
                    AND TXN_CODE IN(v_orgl_txncode,'10','80','81','82','85','86','88','92','93')
                    ORDER BY ADD_INS_DATE ASC)
                    WHERE ROWNUM=1;
					IF SQL%ROWCOUNT = 0 THEN
					 SELECT response_code INTO p_res_code FROM (SELECT response_code
                FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST	--Added for VMS-5733/FSP-991
                WHERE RRN = p_orgnl_rrn
                    AND DELIVERY_CHANNEL = v_orgl_channel
                    AND ADD_INS_DATE  >= v_orgl_date
                    AND TXN_CODE IN(v_orgl_txncode,'10','80','81','82','85','86','88','92','93')
                    ORDER BY ADD_INS_DATE ASC)
                    WHERE ROWNUM=1;
					END IF;

            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    v_resp_cde := '97';
                    v_err_msg := 'Original Not found,Retry  ';
                    RAISE exp_reject_record;
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := ' Error while  getting the original status of the reload transaction  '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;
          --En Get the original txn status from trasactionlog

			v_resp_cde :='1';

       /*  BEGIN
                    SELECT  cms_iso_respcde
                    INTO p_res_code
                    FROM cms_response_mast
                    WHERE cms_inst_code = p_inst_code
                        AND cms_delivery_channel = p_delivery_channel
                        AND cms_response_id = v_resp_cde;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_err_msg := 'Problem while selecting data from response master '
                         || p_res_code
                         || substr(sqlerrm,1,300);
                        p_res_code := '89';
                END;*/ --This block not required hence commented out

        EXCEPTION
            WHEN exp_reject_record THEN
                p_res_msg := v_err_msg;
                ROLLBACK;

         --Sn Get responce code fomr master
                BEGIN
                    SELECT  cms_iso_respcde
                    INTO p_res_code
                    FROM cms_response_mast
                    WHERE cms_inst_code = p_inst_code
                        AND cms_delivery_channel = p_delivery_channel
                        AND cms_response_id = v_resp_cde;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_err_msg := v_err_msg ||' Problem while selecting data from response master '
                         || v_resp_cde
                         || substr(sqlerrm,1,300);
                        p_res_code := '89';
                END;

            WHEN OTHERS THEN
                p_res_code := '21';
                p_res_msg := v_err_msg
                 || 'Main Exception '
                 || sqlcode
                 || '---'
                 || sqlerrm;
                ROLLBACK TO v_auth_savepoint;
        END;

        IF v_prod_code IS NULL  THEN
            BEGIN
                SELECT  cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
                INTO v_card_stat,v_prod_code,v_card_type,v_acct_number
                FROM cms_appl_pan
                WHERE  cap_inst_code = p_inst_code
                AND cap_pan_code = gethash(p_pan_code);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;

        BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,  cam_type_code
            INTO
                v_acct_bal,v_ledger_bal,v_acct_type
            FROM
                cms_acct_mast
            WHERE  cam_acct_no = v_acct_number
            AND cam_inst_code = p_inst_code;

        EXCEPTION
            WHEN OTHERS THEN
                v_acct_bal := 0;
                v_ledger_bal := 0;
        END;

        IF
            v_dr_cr_flag IS NULL  THEN
            BEGIN
                SELECT
                    ctm_credit_debit_flag,
                    to_number(DECODE(
                        ctm_tran_type,
                        'N',
                        '0',
                        'F',
                        '1'
                    ) ),
                    ctm_tran_type,
                    ctm_tran_desc,
                    ctm_prfl_flag
                INTO  v_dr_cr_flag,v_txn_type,v_tran_type,v_trans_desc,v_prfl_flag
                FROM  cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                    AND  ctm_delivery_channel = p_delivery_channel
                    AND  ctm_inst_code = p_inst_code;

            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;

   --Sn Inserting data in transactionlog

        BEGIN
            sp_log_txnlog(
                p_inst_code,
                p_msg_type,
                p_rrn,
                p_delivery_channel,
                p_txn_code,
                v_tran_type,
                p_txn_mode,
                p_tran_date,
                p_tran_time,
                p_rvsl_code,
                v_hash_pan,
                v_encr_pan,
                v_err_msg,
                NULL,
                v_card_stat,
                v_trans_desc,
                NULL,
                NULL,
                v_time_stamp,
                v_acct_number,
                v_prod_code,
                v_card_type,
                v_dr_cr_flag,
                v_acct_bal,
                v_ledger_bal,
                v_acct_type,
                v_proxy_number,
                v_auth_id,
                NULL,
                NULL,
                v_fee_code,
                v_tranfee_amt,
                v_fee_plan,
                v_feeattach_type,
                v_resp_cde,
                p_res_code,
                p_curr_code,
                v_err_msg,
                p_orgnl_rrn
            );
        EXCEPTION
            WHEN OTHERS THEN
                p_res_code := '89';
                v_err_msg := 'Exception while inserting to transaction log ' || sqlerrm;
        END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl

        BEGIN
            sp_log_txnlogdetl(
                p_inst_code,
                p_msg_type,
                p_rrn,
                p_delivery_channel,
                p_txn_code,
                v_txn_type,
                p_txn_mode,
                p_tran_date,
                p_tran_time,
                v_hash_pan,
                v_encr_pan,
                v_err_msg,
                v_acct_number,
                v_auth_id,
                NULL,
                NULL,
                NULL,
                v_hashkey_id,
                NULL,
                NULL,
                NULL,
                NULL,
                p_res_code,
                NULL,
                NULL,
                NULL,
                v_logdtl_resp
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_err_msg := 'Problem while inserting data into transaction log  dtl'
                 || substr(sqlerrm,1,300);
                p_res_code := '89';
        END;

        p_res_msg := v_acct_bal;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_res_code := '69';                                  -- Server Declined
            p_res_msg := 'Main exception from  authorization '
             || substr(sqlerrm,1,300);
    END;

end;

/
show error;