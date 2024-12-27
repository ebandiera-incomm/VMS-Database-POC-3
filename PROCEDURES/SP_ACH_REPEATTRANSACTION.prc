CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACH_REPEATTRANSACTION(P_INSTCODE      IN NUMBER,
                                           P_RRN           IN VARCHAR2,
                                           P_TRANCDE       IN VARCHAR2,
                                           P_DEL_CHNL      IN VARCHAR2,
                                           P_RVSL          IN VARCHAR2,
                                           P_ACHFILE       IN VARCHAR2,
                                           P_ACHREPEATFILE IN VARCHAR2,
                                           P_ACHREPETTIME  IN VARCHAR2,
                                           P_MSG_TYPE      IN VARCHAR2,
                                           P_FILE_PATH     IN VARCHAR2,
                                           P_RESP_CODE     OUT VARCHAR2,
                                           P_ERRMSG        OUT VARCHAR2) AS
  V_RRN_COUNT    NUMBER;
  V_RESPCODE     VARCHAR2(4);
  V_ERRMSG       VARCHAR2(100);
  V_TRAN_DATE    DATE;
  V_ACHREPETTIME DATE;
  REPEATFILECNT  NUMBER;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  v_err_code                   VARCHAR2 (5);--Added by Deepa on 23-Apr-2012 not to log Invalid transaction Date and time
  V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

  --Added on 10-Dec-2013
  v_cr_dr_flag    CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%type;
  v_timestamp     timestamp(3);    
  
  
  
/*************************************************
     * Modified By      :  B.Dhinakaran
     * Modified Date    : 22-Aug-2012
     * Modified Reason  :  Transaction detail report
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  23-July-2012
     * Build Number     :  CMS3.5.1_RI0014.1_B0001
     
     * Modified Date    : 06_Mar_2013
     * Modified By      : Pankaj S.
     * Purpose          : Defect ID FSS-1031
     * Reviewer         : Dhiraj
     * Release Number   : CMS3.5.1_RI0023.2_B0016

     * Modified Date    : 10-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog and cms_transaction_log_dtl if applicable
                          Timestamp,CR_DR_FLAG,Error Message
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Dec-2013
     * Release Number   : RI0024.7_B0001
     
     * Modified By      : Dhinakaran B
     * Modified Date    : 14JUL2014
     * Purpose          : MANTIS ID-12684
	 * Reviewer         : spankaj
     * Release Number   : RI0027.3_B0004
          
 *************************************************/

BEGIN
  BEGIN
    P_ERRMSG := ' ';
  
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS.TRANSACTIONLOG			--Added for VMS-5733/FSP-991
    WHERE RRN = P_RRN
    AND DELIVERY_CHANNEL = P_DEL_CHNL ;--Added by ramkumar.Mk on 25 march 2012
	IF SQL%ROWCOUNT = 0 THEN 
	SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST			--Added for VMS-5733/FSP-991
    WHERE RRN = P_RRN
    AND DELIVERY_CHANNEL = P_DEL_CHNL ;--Added by ramkumar.Mk on 25 march 2012
	END IF;
    
     --Sn Getting the Transaction Description
    BEGIN
     SELECT CTM_TRAN_DESC,CTM_CREDIT_DEBIT_FLAG
       INTO V_TRANS_DESC,v_cr_dr_flag
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TRANCDE AND
           CTM_DELIVERY_CHANNEL = P_DEL_CHNL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type' || P_TRANCDE;
     WHEN OTHERS THEN
       V_TRANS_DESC := 'Transaction type ' || P_TRANCDE;
    END;
  
    IF V_RRN_COUNT > 0 THEN
     V_RESPCODE := '22';
     P_ERRMSG := 'Duplicate RRN';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_ACHREPETTIME), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     v_err_code:= '45';
     P_ERRMSG := 'Problem while converting  ACHREPET  date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_ACHREPETTIME := TO_DATE(SUBSTR(TRIM(P_ACHREPETTIME), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_ACHREPETTIME), 9, 19),
                        'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32';
     v_err_code:= '32';
     V_ERRMSG   := 'Problem while converting  ACHREPETTIME Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En Transaction Date Check
  BEGIN
    SELECT COUNT(*)
     INTO REPEATFILECNT
     FROM CMS_ACH_FILEPROCESS
    WHERE CAF_ACH_RETURNFILE = P_ACHREPEATFILE AND
         CAF_INST_CODE = P_INSTCODE;
  
    IF REPEATFILECNT > 0 THEN
     V_RESPCODE := '44';
     P_ERRMSG := 'Repeat File Already Processed';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;

  BEGIN
    UPDATE CMS_ACH_FILEPROCESS
      SET CAF_ACH_RETURNFILE = P_ACHREPEATFILE
    WHERE CAF_INST_CODE = P_INSTCODE AND CAF_ACH_FILE = P_ACHFILE;
  
    IF SQL%ROWCOUNT = 0 THEN
     V_RESPCODE := '26';
     P_ERRMSG := 'Reverse FILE is not updated ';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '26'; -- Server Declined -220509
     P_ERRMSG := P_ERRMSG||': Problem while UPDATING FILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_RESPCODE := 1;
  
    -- Assign the response code to the out parameter
    SELECT CMS_ISO_RESPCDE
     INTO  P_RESP_CODE --V_RESPCODE --Modified on 06_Mar_2013 for FSS-1031
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INSTCODE AND
         CMS_DELIVERY_CHANNEL = P_DEL_CHNL AND
         CMS_RESPONSE_ID = V_RESPCODE;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
     P_RESP_CODE := '89';
     ---ISO MESSAGE FOR DATABASE ERROR Server Declined
     ROLLBACK;
  END;
  --P_RESP_CODE := V_RESPCODE; --commented on 06_Mar_2013 for FSS-1031
  
  
  v_timestamp := systimestamp; -- Added on 10-Dec-2013 for 13160

  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TXN_CODE,
      RESPONSE_CODE,
      INSTCODE,
      REVERSAL_CODE,
      ACHFILENAME,
      RETURNACHFILENAME,
      ACHRETURNTFILE_TIMESTAMP,
      ACH_FILE_PATH,
      RESPONSE_ID,
      TRANS_DESC,
      -- Added on 10-Dec-2013 for 13160   
      time_stamp,
      cr_dr_flag,
      error_msg
     -- Added on 10-Dec-2013 for 13160
     ,TXN_STATUS         
      )
    VALUES
     (P_MSG_TYPE,
      P_RRN,
      P_DEL_CHNL,
      P_TRANCDE,
      P_RESP_CODE, --V_RESPCODE,  --Modified on 06_Mar_2013 for FSS-1031
      P_INSTCODE,
      P_RVSL,
      P_ACHFILE,
      P_ACHREPEATFILE,
      P_ACHREPETTIME,
      P_FILE_PATH,
      V_RESPCODE,
      V_TRANS_DESC,
      -- Added on 10-Dec-2013 for 13160
      v_timestamp,
      v_cr_dr_flag,
      P_ERRMSG                                                   
      -- Added on 10-Dec-2013 for 13160
      ,DECODE (P_RESP_CODE, '00', 'C', 'F')              
      );
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while inserting TRANSACTIONLOG ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
     P_RESP_CODE := '89';
     ROLLBACK;
  END;

  BEGIN
    INSERT INTO CMS_TRANSACTION_LOG_DTL
     (CTD_DELIVERY_CHANNEL,
      CTD_TXN_CODE,
      CTD_MSG_TYPE,
      CTD_RRN,
      CTD_PROCESS_MSG,
      CTD_INST_CODE
      )
    VALUES
     (P_DEL_CHNL,
      P_TRANCDE,
      P_MSG_TYPE,
      P_RRN,
      P_ERRMSG,
      P_INSTCODE
      );
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while inserting TRANSACTIONLOG_DTL ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
     P_RESP_CODE := '89';
     ROLLBACK;
  END;
EXCEPTION
  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
  
    BEGIN
     -- Assign the response code to the out parameter
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE --V_RESPCODE --Modified on 06_Mar_2013 for FSS-1031
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DEL_CHNL AND
           CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                    V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;
    --P_RESP_CODE := V_RESPCODE;  --commented on 06_Mar_2013 for FSS-1031
    --Sn commented here & added below after txnlog insert for FSS-1031
    /*BEGIN
     IF V_RRN_COUNT > 0 THEN
       IF TO_NUMBER(P_DEL_CHNL) = 11 THEN
        BEGIN
          SELECT RESPONSE_CODE
            INTO V_RESPCODE
            FROM TRANSACTIONLOG A,
                (SELECT MIN(ADD_INS_DATE) MINDATE
                  FROM TRANSACTIONLOG
                 WHERE RRN = P_RRN) B
           WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;
        
          P_RESP_CODE := V_RESPCODE;
        EXCEPTION
          WHEN OTHERS THEN
            P_ERRMSG    := 'Problem in selecting the response detail of Original transaction' ||
                         SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; -- Server Declined
            ROLLBACK;
            RETURN;
        END;
       END IF;
     END IF;
    END;*/
    --En commented here & added below after txnlog insert for FSS-1031
    
    --SN Added for 13160
    
      if v_cr_dr_flag is null
      then
        
        
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG
           INTO v_cr_dr_flag
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TRANCDE AND
               CTM_DELIVERY_CHANNEL = P_DEL_CHNL AND
               CTM_INST_CODE = P_INSTCODE;
        EXCEPTION
         WHEN OTHERS THEN
           null;
        END;    
      
      end if;
      
       v_timestamp := systimestamp;
        
     --EN Added for 13160 
    
  IF V_RESPCODE /*v_err_code*/ NOT IN('32','45') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time   --<<Modified on 06_Mar_2013 for FSS-1031>>--
    BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
        RRN,
        DELIVERY_CHANNEL,
        TXN_CODE,
        RESPONSE_CODE,
        INSTCODE,
        REVERSAL_CODE,
        ACHFILENAME,
        RETURNACHFILENAME,
        ACHRETURNTFILE_TIMESTAMP,
        ACH_FILE_PATH,
        RESPONSE_ID,
        TRANS_DESC,
        -- Added on 10-Dec-2013 for 13160   
        time_stamp,
        cr_dr_flag,
        error_msg
        -- Added on 10-Dec-2013 for 13160
        ,TXN_STATUS
      )
     VALUES
       (P_MSG_TYPE,
        P_RRN,
        P_DEL_CHNL,
        P_TRANCDE,
        P_RESP_CODE, --V_RESPCODE,  --Modified on 06_Mar_2013 for FSS-1031
        P_INSTCODE,
        P_RVSL,
        P_ACHFILE,
        P_ACHREPEATFILE,
        P_ACHREPETTIME,
        P_FILE_PATH,
        V_RESPCODE,
        V_TRANS_DESC,
        -- Added on 10-Dec-2013 for 13160
        v_timestamp,
        v_cr_dr_flag,
        p_errmsg                                                  
        -- Added on 10-Dec-2013 for 13160         
        ,'F' 
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '89';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
    END;
  END IF;
  
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_MSG_TYPE,
        CTD_RRN,
        CTD_PROCESS_MSG,
        CTD_INST_CODE        
        )
     VALUES
       (P_DEL_CHNL,
        P_TRANCDE,
        P_MSG_TYPE,
        P_RRN,
        P_ERRMSG,
        P_INSTCODE   
        );
    
     --RETURN;  --commented on 06_Mar_2013 for FSS-1031
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG      := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;
    
    --Sn commented above & added here for FSS-1031
    BEGIN
     IF V_RRN_COUNT > 0 THEN
       IF TO_NUMBER(P_DEL_CHNL) = 11 THEN
        BEGIN
          SELECT RESPONSE_CODE
            INTO V_RESPCODE
            FROM VMSCMS.TRANSACTIONLOG			 A, --Added for VMS-5733/FSP-991
                (SELECT MIN(ADD_INS_DATE) MINDATE
                  FROM VMSCMS.TRANSACTIONLOG		 A--Added for VMS-5733/FSP-991
                 WHERE RRN = P_RRN) B
           WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;
        
          P_RESP_CODE := V_RESPCODE;
		  IF SQL%ROWCOUNT = 0 THEN 
		  SELECT RESPONSE_CODE
            INTO V_RESPCODE
            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST			 A, --Added for VMS-5733/FSP-991
                (SELECT MIN(ADD_INS_DATE) MINDATE
                  FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST			 A--Added for VMS-5733/FSP-991
                 WHERE RRN = P_RRN) B
           WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;
        
          P_RESP_CODE := V_RESPCODE;
		  END IF;
        EXCEPTION
          WHEN OTHERS THEN
            P_ERRMSG    := 'Problem in selecting the response detail of Original transaction' ||
                         SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; -- Server Declined
            ROLLBACK;
            RETURN;
        END;
       END IF;
     END IF;
    END;
    --En commented above & added here for FSS-1031
    
  WHEN OTHERS THEN
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
END;
/
SHOW ERROR;