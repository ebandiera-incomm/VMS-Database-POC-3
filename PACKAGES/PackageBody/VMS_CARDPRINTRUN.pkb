create or replace
PACKAGE BODY                      VMSCMS.VMS_CARDPRINTRUN AS

PROCEDURE INSERT_CARDPRINTRUN (

   p_Track1FormatValid_in             IN     NUMBER,
   p_Track2FormatValid_in             IN     NUMBER,
   p_Track1Track2DataMatch_in         IN     NUMBER,
   p_Track1Track2CardDataMatch_in     IN     NUMBER,
   p_BINValid_in                      IN     NUMBER,
   p_CardNumberDataMatch_in           IN     NUMBER,
   p_CheckDigitValid_in               IN     NUMBER,
   p_ExpirationDateDataMatch_in       IN     NUMBER,
   p_CVV1Match_in                     IN     NUMBER,
   p_CVV2Match_in                     IN     NUMBER,
   p_ProductID_in                     IN     NUMBER,
   p_CardNumber_in                    IN     VARCHAR2,
   p_ExpirationDate_in                IN     VARCHAR2,
   p_ServiceCode_in                   IN     VARCHAR2,
   p_ProxyNumber_in                   IN     VARCHAR2, -- PROXYNUMBER FOR AMEX
   p_QAAnalyst_in                     IN     VARCHAR2,
   p_productDescription_in            IN     VARCHAR2,
   p_cardTypeID_in                    IN     NUMBER,
   p_testID_in                        IN     VARCHAR2,
   p_variableNameMatch_in             IN     NUMBER,
   p_testResult_in                    IN     VARCHAR2,
   p_PdctCdAndCtgryCdMtch_in          IN     NUMBER,
   p_ProxyNumberMatch_in              IN     NUMBER,
   p_CardScrtyCdMtch_in               IN     NUMBER,
   p_EffctveDtDataMtch_in             IN     NUMBER,
   p_ProductCode_in                   IN     VARCHAR2,
   p_ProductCategoryCode_in           IN     VARCHAR2,
   p_EffectiveDate_in                 IN     VARCHAR2,
   p_resp_msg_out                     OUT    VARCHAR2
  )
  AS
      v_encr_pan    VMS_PRINTRUN_TEST_DATA.VPTD_CARD_NUMBER%TYPE;
      e_exception   EXCEPTION;
BEGIN
  p_resp_msg_out := 'OK';
  
	BEGIN
      v_encr_pan := fn_emaps_main (p_cardnumber_in);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg_out :=
               'Error while converting pan (encrypted) for from card no '
            || SUBSTR (SQLERRM, 1, 200);
            RAISE e_exception;
   END;
   
	BEGIN
		  INSERT INTO VMS_PRINTRUN_TEST_RESULTS
		   (VPTR_TEST_ID
		   ,VPTR_TRACK1_FORMAT_VALID
		   ,VPTR_TRACK2_FORMAT_VALID
		   ,VPTR_TRACK1_TRACK2_DATA_MATCH
		   ,VPTR_TRK1_TRK2_CARD_DATA_MATCH
		   ,VPTR_BIN_VALID
		   ,VPTR_CARD_NUMBER_DATA_MATCH
		   ,VPTR_CHECK_DIGIT_VALID
		   ,VPTR_EXPRATION_DATE_DATA_MATCH
		   ,VPTR_CVV1_MATCH
		   ,VPTR_CVV2_MATCH
		   ,VPTR_VARIABLE_NAME_MATCH
		   ,VPTR_CARD_SECURITY_CODE_MATCH
		   ,VPTR_EFFECTIVE_DATE_DATA_MATCH
		   ,VPTR_PROXY_NUMBER_MATCH
		   ,VPTR_PRDCTCODE_CATCODE_MATCH)
		  VALUES
		   (p_testID_in,
		   p_Track1FormatValid_in,
		   p_Track2FormatValid_in,
		   p_Track1Track2DataMatch_in,
		   p_Track1Track2CardDataMatch_in,
		   p_BINValid_in,
		   p_CardNumberDataMatch_in,
		   p_CheckDigitValid_in,
		   p_ExpirationDateDataMatch_in,
		   p_CVV1Match_in,
		   p_CVV2Match_in,
		   p_variableNameMatch_in,
		   p_CardScrtyCdMtch_in,
		   p_EffctveDtDataMtch_in,
		   p_ProxyNumberMatch_in,
		   p_PdctCdAndCtgryCdMtch_in
		   );

		 INSERT INTO VMS_PRINTRUN_TEST_DATA
		   (VPTD_TEST_ID
		   ,VPTD_TEST_DATE
		   ,VPTD_PRODUCT_ID
		   ,VPTD_PRODUCT_DESCRIPTION
		   ,VPTD_CARD_TYPE_ID
		   ,VPTD_CARD_NUMBER
		   ,VPTD_EXPIRATION_DATE
		   ,VPTD_SERVICE_CODE
		   ,VPTD_PROXY_NUMBER
		   ,VPTD_QA_ANALYST
		   ,VPTD_TEST_RESULT
		   ,VPTD_PRODUCT_CODE
		   ,VPTD_PRODUCT_CATEGORY_CODE
		   ,VPTD_EFFECTIVE_DATE)
		 VALUES
		   (p_testID_in,
		 	 SYSDATE,
		   p_ProductID_in,
		   p_productDescription_in,
		   p_cardTypeID_in,
		   v_encr_pan,
		   p_ExpirationDate_in,
		   p_ServiceCode_in,
		   p_ProxyNumber_in,
		   p_QAAnalyst_in,
		   p_testResult_in,
		   p_ProductCode_in,
		   p_ProductCategoryCode_in,
		   p_EffectiveDate_in);
       
		EXCEPTION
		  WHEN OTHERS THEN
			p_resp_msg_out      := 'Problem while inserting data into VMS_PRINTRUN_TEST_DATA and VMS_PRINTRUN_TEST_RESULTS ' ||
							SUBSTR(SQLERRM, 1, 300);
      RAISE e_exception;
	END;
  
   EXCEPTION
      WHEN e_exception
      THEN
         p_resp_msg_out := p_resp_msg_out;
      WHEN OTHERS
      THEN
         p_resp_msg_out :=
               'Error from main '
            || SUBSTR (SQLERRM, 1, 300);

END INSERT_CARDPRINTRUN;

END VMS_CARDPRINTRUN;
/
show error