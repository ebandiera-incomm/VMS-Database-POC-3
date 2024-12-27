create or replace PROCEDURE  VMSCMS.SP_DUP_RRN_CHECK(
    P_HASH_PAN    IN VARCHAR2,
    P_RRN         IN VARCHAR2,
    P_TXN_DATE    IN VARCHAR2,
    P_DEL_CHANNEL IN VARCHAR2,
    P_MSG_TYPE    IN VARCHAR2,
    P_TXN_CODE    IN VARCHAR2,
    P_ERR_MSG OUT VARCHAR2,
    P_INCR_INDICATOR IN VARCHAR2 DEFAULT NULL)
AS

/*************************************************
  * Created Date     :  06-MAR-2014
  * Created By       :  Abdul Hameed M.A
  * Created For      :  Mantis ID 13893
  * PURPOSE          :  For duplicate RRN check
  * Reviewer         : Dhiraj
  * Reviewed Date    : 06/Mar/2013
  * Build Number     : RI0027.2_B0002
  
  * Modified  Date   :  24-MAR-2014
  * Created By       :  Siva Kumar M
  * Created For      :  Mantis ID 13893
  * PURPOSE          :  Modified for review comment changes.
  * Reviewer         : Pankaj S.
  * Reviewed Date    : 02-April-2014
  * Build Number     : RI0027.2_B0003
     
  * Modified by      : MAGESHKUMAR S.
  * Modified Date    : 03-FEB-2015
  * Modified For     : 2.4.2.4.1 & 2.4.3.1 integration
  * Reviewer         : PANKAJ S.
  * Build Number     : RI0027.5_B0006
  
  * Modified By      : MAGESHKUMAR S
  * Modified Date    : 29/10/2019
  * Purpose          : SPIL Deactivation Issue- Duplicate RRN
  * Reviewer         : Saravanan
  * Release Number   : VMSGPRHOST-R20

**************************************************/
  V_RRN_CNT NUMBER;
  EXP_REJECT_RECORD   EXCEPTION;
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  P_ERR_MSG      := 'OK';
  IF (P_MSG_TYPE IN ('1420','1421','9220','9221') )THEN
  
    BEGIN
	--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TXN_DATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
		
		SELECT COUNT(1)
		INTO V_RRN_CNT
		FROM TRANSACTIONLOG
		WHERE RRN           =P_RRN
		AND BUSINESS_DATE   =P_TXN_DATE
		AND DELIVERY_CHANNEL=P_DEL_CHANNEL
		AND CUSTOMER_CARD_NO=P_HASH_PAN
		AND TXN_CODE        = P_TXN_CODE
		AND MSGTYPE         = P_MSG_TYPE;
	ELSE
		 SELECT COUNT(1)
		INTO V_RRN_CNT
		FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
		WHERE RRN           =P_RRN
		AND BUSINESS_DATE   =P_TXN_DATE
		AND DELIVERY_CHANNEL=P_DEL_CHANNEL
		AND CUSTOMER_CARD_NO=P_HASH_PAN
		AND TXN_CODE        = P_TXN_CODE
		AND MSGTYPE         = P_MSG_TYPE;
	END IF;	
    
    IF V_RRN_CNT        > 0 THEN
      P_ERR_MSG        := 'Duplicate RRN ';
    END IF;

  EXCEPTION WHEN OTHERS THEN
   
   P_ERR_MSG := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200); 
   
   RAISE   EXP_REJECT_RECORD;
    
   END;
   
  ELSE
  
    IF ((P_INCR_INDICATOR IS NULL) OR (P_INCR_INDICATOR='0') ) THEN
    
     
   IF ((   ((p_del_channel = '01')  OR (p_del_channel = '02')) AND p_msg_type IN ('1101', '1201')
             ) ) THEN
            BEGIN
			--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_txn_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
				   SELECT COUNT (1)
					 INTO v_rrn_cnt
					 FROM transactionlog
					WHERE rrn = p_rrn
					  AND business_date = p_txn_date
					  AND delivery_channel = p_del_channel
					  AND txn_code = p_txn_code
					  AND msgtype = DECODE (p_msg_type,
									   '1101', '1100',
									   '1201', '1200' )
					  AND customer_card_no = p_hash_pan;
	ELSE
					SELECT COUNT (1)
					 INTO v_rrn_cnt
					 FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
					WHERE rrn = p_rrn
					  AND business_date = p_txn_date
					  AND delivery_channel = p_del_channel
					  AND txn_code = p_txn_code
					  AND msgtype = DECODE (p_msg_type,
									   '1101', '1100',
									   '1201', '1200' )
					  AND customer_card_no = p_hash_pan;
	END IF;				  

               IF v_rrn_cnt > 0
               THEN
                  p_err_msg := 'Duplicate RRN ';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_err_msg :=
                       'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
    ELSE
    
      IF NOT (P_DEL_CHANNEL = '08' AND P_TXN_CODE IN( '28', '36')) THEN       
      
      				--- 28-DEACTIVATION AND UNLOAD , 36-DEACTIVATION
    
     BEGIN
	 --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TXN_DATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
		 
		  SELECT COUNT(1)
		  INTO V_RRN_CNT
		  FROM TRANSACTIONLOG
		  WHERE RRN           =P_RRN
		  AND BUSINESS_DATE   =P_TXN_DATE
		  AND DELIVERY_CHANNEL=P_DEL_CHANNEL
		  AND CUSTOMER_CARD_NO=P_HASH_PAN;
	ELSE
		SELECT COUNT(1)
		  INTO V_RRN_CNT
		  FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
		  WHERE RRN           =P_RRN
		  AND BUSINESS_DATE   =P_TXN_DATE
		  AND DELIVERY_CHANNEL=P_DEL_CHANNEL
		  AND CUSTOMER_CARD_NO=P_HASH_PAN;
	END IF;	  
      
      IF V_RRN_CNT        > 0 THEN
        P_ERR_MSG        := 'Duplicate RRN ';
      END IF;
      
     EXCEPTION WHEN OTHERS THEN
      P_ERR_MSG := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE   EXP_REJECT_RECORD;
     
     END;
    END IF; 
     END IF;
    ELSE
    
      IF (P_INCR_INDICATOR='1') THEN
      
       BEGIN
	   
        SELECT COUNT(*)
        INTO V_RRN_CNT
        FROM VMSCMS.CMS_PREAUTH_TRANSACTION_VW		--Added for VMS-5733/FSP-991
        WHERE CPT_CARD_NO          = P_HASH_PAN
        AND CPT_RRN                = P_RRN
        AND (CPT_PREAUTH_VALIDFLAG = 'N'
        OR CPT_EXPIRY_FLAG         = 'Y');
        
        IF V_RRN_CNT               > 0 THEN
          P_ERR_MSG               := 'Duplicate RRN Pre-Auth';
        END IF;
        
      EXCEPTION  WHEN OTHERS THEN
          
      P_ERR_MSG  := 'Error while Preauth  RRN checking' || SUBSTR (SQLERRM, 1, 200);
      RAISE   EXP_REJECT_RECORD;
      
      END;
            
      ELSE
        P_ERR_MSG := 'Duplicate RRN ';
      END IF;
    END IF;
  END IF;
  
  
EXCEPTION 
WHEN   EXP_REJECT_RECORD THEN 

P_ERR_MSG := 'Error while checking RRN ' || SUBSTR(SQLERRM, 1, 200);

WHEN OTHERS THEN
  P_ERR_MSG := 'Error while checking RRN ' || SUBSTR(SQLERRM, 1, 200);
END ;
/
SHOW ERROR;
