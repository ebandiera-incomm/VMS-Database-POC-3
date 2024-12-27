CREATE OR REPLACE PROCEDURE VMSCMS.SP_GEN_PAN(PRM_INSTCODE        IN NUMBER,
                                PRM_APPLCODE        IN NUMBER,
--                                PRM_IP_ADDR         IN VARCHAR2, /* T.NARAYANAN. ADDED - AUDIT LOG REPORT */
                                PRM_LUPDUSER        IN NUMBER,
                               
                                PRM_PAN             OUT VARCHAR2,
                                PRM_APPLPROCESS_MSG OUT VARCHAR2,
                                PRM_ERRMSG          OUT VARCHAR2,
                                PRM_PRXY_GENFLAG    IN VARCHAR2 default null) AS
                                
                                
/********************************

    * Modified by                  : Siva Kumar M
    * Modified Date                : 14-Aug-15
    * Modified For                 : FSS-2125
    * Modified reason              : B2B Production Solution
    * Reviewer                     : Spankaj/Saravana Kumar 
    * Build Number                 : VMSGPRHOSTCSD3.1_B0002
********************************/

  V_INST_CODE CMS_APPL_MAST.CAM_INST_CODE%TYPE;
  V_PROD_CODE CMS_APPL_MAST.CAM_PROD_CODE%TYPE;
  V_CARD_TYPE CMS_APPL_MAST.CAM_CARD_TYPE%TYPE;
  --v_errmsg VARCHAR2(300);
  V_PROFILE_CODE  CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_CPM_CATG_CODE CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
  V_PROD_PREFIX   CMS_PROD_CATTYPE.CPC_PROD_PREFIX%TYPE;
  EXP_REJECT_RECORD EXCEPTION;
  
    

BEGIN
  PRM_ERRMSG := 'OK';
  BEGIN
    --Begin 1 Block Starts Here
    SELECT CAM_INST_CODE, CAM_PROD_CODE, CAM_CARD_TYPE
     INTO V_INST_CODE, V_PROD_CODE, V_CARD_TYPE
     FROM CMS_APPL_MAST
    WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_APPL_CODE = PRM_APPLCODE AND
         CAM_APPL_STAT = 'A';
  
  EXCEPTION
    --Exception of Begin 1 Block
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'No row found for application code 222' || PRM_APPLCODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while selecting applcode from applmast' ||
                SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    IF V_PROD_CODE IS NOT NULL AND V_CARD_TYPE IS NOT NULL THEN
     SELECT CPM_CATG_CODE
       INTO V_CPM_CATG_CODE
       FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
      WHERE CPC_INST_CODE = PRM_INSTCODE AND CPC_INST_CODE = CPM_INST_CODE AND
           CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
           CPM_PROD_CODE = CPC_PROD_CODE;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'Catg code code not defined for product code ' ||
                V_PROD_CODE || 'card type ' || V_CARD_TYPE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while selecting Catg code from CMS_PROD_MAST' ||
                SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  IF V_CPM_CATG_CODE = 'D' OR V_CPM_CATG_CODE = 'A' THEN
    SP_GEN_PAN_DEBIT_CMS(PRM_INSTCODE,
                    PRM_APPLCODE,
                    PRM_LUPDUSER,
--                    PRM_IP_ADDR, /* T.NARAYANAN. ADDED - AUDIT LOG REPORT */
                    PRM_PAN,
                    PRM_APPLPROCESS_MSG,
                    PRM_ERRMSG);
  ELSIF V_CPM_CATG_CODE = 'P' THEN
    SP_GEN_PAN_PREPAID_CMS(PRM_INSTCODE,
                      PRM_APPLCODE,
                      PRM_LUPDUSER,
                      PRM_PRXY_GENFLAG,
--                      PRM_IP_ADDR, /* T.NARAYANAN. ADDED - AUDIT LOG REPORT */
                      PRM_PAN,
                      PRM_APPLPROCESS_MSG,
                      PRM_ERRMSG);
  END IF;
  IF PRM_ERRMSG != 'OK' THEN
    RAISE EXP_REJECT_RECORD;
  END IF;

EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    PRM_ERRMSG := PRM_ERRMSG;
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Main Exception1' || SUBSTR(SQLERRM, 1, 100);
END;
/
show error