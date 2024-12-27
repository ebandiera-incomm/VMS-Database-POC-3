create or replace
PROCEDURE        vmscms.SP_SET_AVF( 
    PRM_INSTCODE   IN       NUMBER,
    PRM_ERRMSG OUT VARCHAR2 )
as
/**************************************************************************************************
      * Created by       : Ramesh
      * Created for      : MVCSD-4121 FR 3.1
      * Created Reason   : New Requirement           
      * Created Date     : 28-Jan-14
      * Reviewer         : Dhiraj
      * Reviewed Date    : 06-Mar-2014
      * build number     : RI0027.2_B0002
      
     * Modified Date    : 31_Mar_2014
     * Modified By      : Dinesh
     * Purpose          : Review changes for MVCSD-4121 and FWR-47
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 01-April-2014
     * Build Number     : RI0027.2_B0003
     
     * Modified Date    : 11_APR_2014
     * Modified By      : RAMESH
     * Purpose          : REVIEW CHANGES MODIFIED FOR TO CHECK CARD RENEWAL FOR THE CARD
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005
      
      *****************************************************************************************************/
  v_pan_code CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_pan_code_encr CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  v_cust_code CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  v_resp_code       NUMBER;
  exp_reject_record EXCEPTION;
  v_savepoint            NUMBER DEFAULT 0;
  V_CARDRENEWAL_CHECK     number;
  V_OLD_EXPRY_DATE        CMS_APPL_PAN.cap_expry_date%TYPE;
 
CURSOR C_GET_DETAILS IS
     /* Commented for review changes
	 select cap_pan_code,cap_pan_code_encr,CAP_CUST_CODE     
     from cms_appl_pan,cms_cust_mast,CMS_PROD_MAST,CMS_PROD_CATTYPE,cms_renewal_config
     where cap_inst_code= ccm_inst_code 
     AND CAP_INST_CODE=CPM_INST_CODE
     AND CPM_INST_CODE=CPC_INST_CODE
     and cap_inst_code=crc_inst_code
     AND CAP_PROD_CODE=CPM_PROD_CODE
     AND CAP_CARD_TYPE=CPC_CARD_TYPE
     AND CPM_PROD_CODE= cpc_prod_code
     and CAP_PROD_CODE= crc_prod_code
     and cap_card_type= crc_card_type
     and cap_card_stat = crc_card_stat
     and cap_cust_code=ccm_cust_code
     and ccm_addrverify_flag=0
     and cap_expry_date is not null
     AND CPC_CRDEXP_PENDING IS NOT NULL --AND CPC_CRDEXP_PENDING >0
     and (trunc(cap_expry_date)-trunc(sysdate))<=CPC_CRDEXP_PENDING
     --and (trunc(cap_expry_date)-trunc(sysdate))>0
     AND CAP_INST_CODE=V_INST_CODE
     ORDER BY trunc(cap_expry_date)-trunc(sysdate);    
     */
     --Added for review changes
     with temp_start as(
select b.CPC_REPL_PERIOD,c.CPM_PROD_CODE,b.cpc_card_type,a.CRC_CARD_TYPE,
       a.crc_card_stat,c.CPM_INST_CODE,b.CPC_CRDEXP_PENDING
from cms_renewal_config a,
     cms_prod_cattype b,
     CMS_PROD_MAST c
 where 
 c.cpm_prod_code =   b.CPC_PROD_CODE  
 and c.cpm_prod_code =  a.CRC_PROD_CODE
 and b.cpc_card_type = a.CRC_CARD_TYPE
 and c.cpm_inst_code = b.cpc_inst_code
 and c.cpm_inst_code = a.crc_inst_code
 --and b.CPC_REPL_PERIOD > 0
 and c.CPM_INST_CODE = PRM_INSTCODE
 )select a.cap_pan_code,a.cap_pan_code_encr,a.CAP_CUST_CODE,a.CAP_EXPRY_DATE    
 from cms_appl_pan a,
      cms_cust_mast b,
      temp_start c
  where a.cap_inst_Code = b.ccm_inst_code
  and a.cap_inst_Code = c.CPM_INST_CODE
  and a.cap_prod_code = c.CPM_PROD_CODE
  and a.cap_card_type = c.CRC_CARD_TYPE
  and a.cap_card_stat = c.crc_card_stat
  and a.cap_cust_code = b.ccm_cust_code
  and b.ccm_addrverify_flag = 0
  and (trunc(a.cap_expry_date)-trunc(sysdate))<=c.CPC_CRDEXP_PENDING
  and a.cap_inst_code = PRM_INSTCODE
  ORDER BY trunc(a.cap_expry_date)-trunc(sysdate);
  

BEGIN 
 
      OPEN C_GET_DETAILS;
      LOOP      
          FETCH C_GET_DETAILS
            into V_PAN_CODE,V_PAN_CODE_ENCR,V_CUST_CODE,V_OLD_EXPRY_DATE;
          EXIT WHEN C_GET_DETAILS%NOTFOUND;
          
      BEGIN	    
      PRM_ERRMSG :='OK';
            v_savepoint:= v_savepoint+1;
             SAVEPOINT v_savepoint;
          
           SELECT COUNT(1) 
              INTO V_CARDRENEWAL_CHECK
            FROM CMS_CARDRENEWAL_HIST
            WHERE CCH_PAN_CODE =V_PAN_CODE          
             AND trunc(CCH_EXPRY_DATE)= trunc(V_OLD_EXPRY_DATE)
            AND CCH_INST_CODE = PRM_INSTCODE;
           
            IF V_CARDRENEWAL_CHECK = 0 THEN      
                
                                            
            BEGIN
              UPDATE cms_cust_mast
              SET ccm_addrverify_flag = 1,
                ccm_addverify_date    = sysdate
              WHERE ccm_cust_code     = v_cust_code
              AND ccm_inst_code       = PRM_INSTCODE;
              
            IF SQL%ROWCOUNT <> 1 THEN
                PRM_ERRMSG := 'Error While updating address verify flag into cms_cust_mast';
                 RAISE EXP_REJECT_RECORD;
            END IF;
            
            EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE;
            WHEN OTHERS THEN
              PRM_ERRMSG :='Error while updating address verification flag '|| SUBSTR (sqlerrm, 1, 200);
              RAISE EXP_REJECT_RECORD;
            END;
                 
      
          IF SQL%ROWCOUNT = 1 THEN
            BEGIN
              sp_log_cardstat_chnge (PRM_INSTCODE, v_pan_code, v_pan_code_encr, NULL, '38', NULL, NULL, NULL, v_resp_code, PRM_ERRMSG );
              IF V_RESP_CODE <> '00' AND PRM_ERRMSG <> 'OK' THEN
                RAISE EXP_REJECT_RECORD;
              END IF;
            EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
              RAISE;
            WHEN OTHERS THEN
              PRM_ERRMSG := 'Error while inserting in transactionlog-' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
            END;
          END IF;
          
          
          
         END IF;                  
       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
            ROLLBACK TO v_savepoint;
            --Loging error
            BEGIN
            
            INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_msg_type, ctd_txn_mode, ctd_business_date,
                   ctd_business_time, ctd_customer_card_no,
                   CTD_PROCESS_FLAG, CTD_PROCESS_MSG,ctd_inst_code,CTD_CUSTOMER_CARD_NO_ENCR, ctd_ins_date,
                            ctd_ins_user                  
                  )
           VALUES ('05', '38', '0',
                   '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'hh24miss'), V_PAN_CODE,
                   'E', 'Set AVF_'||PRM_ERRMSG, prm_instcode, V_PAN_CODE_ENCR, SYSDATE,1);                
                               
            EXCEPTION
                WHEN OTHERS THEN
                  PRM_ERRMSG := 'Exception while inserts to log dtl table'||SUBSTR(SQLERRM,1,200);
            END;
            WHEN OTHERS THEN
                PRM_ERRMSG := 'Main Exception 1'||SUBSTR(SQLERRM,1,200);
                ROLLBACK TO v_savepoint;
                --Loging error
                BEGIN
                      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_msg_type, ctd_txn_mode, ctd_business_date,
                   ctd_business_time, ctd_customer_card_no,
                   CTD_PROCESS_FLAG, CTD_PROCESS_MSG,ctd_inst_code,CTD_CUSTOMER_CARD_NO_ENCR, ctd_ins_date,
                            ctd_ins_user                  
                  )
           VALUES ('05', '38', '0',
                   '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'hh24miss'), V_PAN_CODE,
                   'E', 'Set AVF_'||PRM_ERRMSG, prm_instcode, V_PAN_CODE_ENCR, SYSDATE,1);   
                EXCEPTION
                    WHEN OTHERS THEN
                        PRM_ERRMSG := 'Exception while inserts to log dtl table'||SUBSTR(SQLERRM,1,200);
                END;
              END;
          END LOOP;
          CLOSE C_GET_DETAILS;
        EXCEPTION          
            WHEN OTHERS THEN
                PRM_ERRMSG := 'Main Exception '||SUBSTR(SQLERRM,1,200);               
        END;
/
SHOW ERROR;