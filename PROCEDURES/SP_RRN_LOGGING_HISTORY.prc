create or replace
PROCEDURE        vmscms.SP_RRN_LOGGING_HISTORY
                             ( P_INST_CODE IN NUMBER,
                               P_ERROR_MSG OUT VARCHAR2
                               ) IS
/*************************************************


     * Modified By      : RAVI  N
     * Modified Date    : 05-03-2014
     * Modified Reason  : RRNLogging changes
     * Reviewer         : Dhiraj
     * Reviewed Date    : 7-03-2014
     * Build Number     : RI0027.2_B0001
     
     * Modified By      : MageshKumar S
     * Modified Date    : 20-11-2014
     * Modified For     : Logging MsgType
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 21-Nov-2014
     * Build Number     : RI0027.4.2.2_B0003
     
     * Modified By      : Sai Prasad
     * Modified Date    : 11-FEB-2015
     * Modified for     : Logging DB Response Time(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

     * Modified By      : Saravanakumar
     * Modified Date    : 31-Aug-2015
     * Modified For     : Commending inst code
     * Reviewer         : Pankaj Salunkhe
     * Reviewed Date    : 31-Aug-2015
     * Build Number     : VMSGPRHOST_3.1_B0007
 *************************************************/

  V_ERROR_MSG VARCHAR2(900) DEFAULT 'OK';


BEGIN



  BEGIN
       INSERT INTO CMS_RRNLOGGING_HISTORY
                 (CRH_INST_CODE,
                  CRH_RRN,
                  CRH_DELIVERY_CHANNEL,
                  CRH_TXN_CODE,
                  CRH_CARD_NO,
                  CRH_TRANS_DATE,
                  CRH_TRANS_TIME,
                  CRH_TIME_TAKENMS,
                  CRH_SEVER,
                  CRH_TIME_STAMP,
                  CRH_HISTORYTIME_STAMP,
                  CRH_MSG_TYPE,Crh_Dbresp_Timems
                  )      
                ( SELECT CRL_INST_CODE,
                  CRL_RRN,
                  CRL_DELIVERY_CHANNEL,
                  CRL_TXN_CODE,
                  CRL_CARD_NO,
                  CRL_TRANS_DATE,
                  CRL_TRANS_TIME,
                  CRL_TIME_TAKENMS,
                  CRL_SEVER,
                  CRL_TIME_STAMP,systimestamp,CRL_MSG_TYPE,Crl_Dbresp_Timems
                  FROM  CMS_RRN_LOGGING WHERE --CRL_INST_CODE=P_INST_CODE AND 
                  TRUNC(CRL_TIME_STAMP) <= TRUNC(SYSDATE-1));
       EXCEPTION
         WHEN OTHERS
         THEN
            V_ERROR_MSG :=
                'Error in inseration logging details CMS_RRN_LOGGING to CMS_RRNLOGGING_HISTORY ' || SUBSTR (SQLERRM, 1, 200);
  END;

    BEGIN
         DELETE CMS_RRN_LOGGING
         WHERE --CRL_INST_CODE=P_INST_CODE AND 
            TRUNC(CRL_TIME_STAMP) <= TRUNC(SYSDATE-1);
    EXCEPTION
         WHEN OTHERS
         THEN
            V_ERROR_MSG :=
                'Error in deletion on CMS_RRN_LOGGING ' || SUBSTR (SQLERRM, 1, 200);


    END;
  P_ERROR_MSG :=V_ERROR_MSG;

END;
 /
show error
 
 
 