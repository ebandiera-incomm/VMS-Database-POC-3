create or replace
PACKAGE        VMSCMS.VMS_CARDPRINTRUN AS

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
  );
  END VMS_CARDPRINTRUN;
  /
  show error