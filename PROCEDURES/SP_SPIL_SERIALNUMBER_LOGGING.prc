create or replace
PROCEDURE               vmscms.SP_SPIL_SERIALNUMBER_LOGGING
  (
        P_INST_CODE         IN NUMBER,
        P_MSG               IN VARCHAR2,                                               
        P_DELIVERY_CHANNEL  IN VARCHAR2,                                               
        P_TXN_CODE         IN  VARCHAR2,
        P_SERIAL_NUMBER      IN VARCHAR2,
        P_AUTH_ID         IN VARCHAR2,
        P_RESP_CODE        IN  VARCHAR2,
        P_PAN_CODE        IN  VARCHAR2,
        P_RRN             IN  VARCHAR2,
        P_TIMESTAMP       IN  TIMESTAMP,
        P_RESP_ID         OUT VARCHAR2,
        P_RESP_MSG        OUT VARCHAR2
)IS
 /***********************************************************************************
     * Created Date     :  28-OCT-2014
     * Created By       :  Ramesh A
     * PURPOSE          :  SPIL Serial Number changes
     * Reviewer         : Saravanakumar
     * Build Number     :RI0027.4.3_B0002

 ***********************************************************************************/
  BEGIN
  
  P_RESP_MSG :='OK';
  P_RESP_ID :='00';
  
  INSERT INTO CMS_SPILSERIAL_LOGGING(CSL_INST_CODE,CSL_DELIVERY_CHANNEL,CSL_TXN_CODE,CSL_MSG_TYPE,CSL_SERIAL_NUMBER,
  CSL_AUTH_ID,CSL_RESPONSE_CODE,CSL_PAN_CODE,CSL_RRN,CSL_TIME_STAMP)
  VALUES(P_INST_CODE,P_DELIVERY_CHANNEL,P_TXN_CODE,P_MSG,P_SERIAL_NUMBER,P_AUTH_ID,P_RESP_CODE,P_PAN_CODE,P_RRN,P_TIMESTAMP);
  
   If Sql%Rowcount = 0 Then
         P_RESP_MSG   := 'Serial Number not updated';
         P_RESP_ID := '21';
        
       END IF;
     EXCEPTION      
       WHEN OTHERS THEN
        P_RESP_MSG   := 'Error while Updating Serial Number ' ||
                    Substr(Sqlerrm, 1, 200);
        P_RESP_ID := '21';      
  END;
/
show error