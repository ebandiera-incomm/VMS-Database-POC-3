CREATE OR REPLACE PROCEDURE VMSCMS.SP_ATTACH_FEEPLAN_PROD(P_INST_CODE         IN NUMBER,
                                             P_PROD_CODE               IN VARCHAR2,                                            
                                             P_VALID_FROM       VARCHAR2,
                                             P_VALID_TO         VARCHAR2,
                                             P_FEE_PLAN         VARCHAR2,                                            
                                             P_LUPD_USER          VARCHAR2,
                                             P_DRGL_CATG          VARCHAR2,
                                             P_DRGL_CODE          VARCHAR2,
                                             P_DRSUBGL_CODE       VARCHAR2,
                                             P_DRACCT_NO       VARCHAR2,
                                             P_CRGL_CATG          VARCHAR2,
                                             P_CRGL_CODE          VARCHAR2,
                                             P_CRSUBGL_CODE       VARCHAR2,
                                             P_CRACCT_NO       VARCHAR2,
                                             P_ST_CALC_FLAG          VARCHAR2,
                                             P_CESS_CALC_FLAG          VARCHAR2,
                                             P_ST_DRGL_CATG          VARCHAR2,
                                             P_ST_DRGL_CODE          VARCHAR2,
                                             P_ST_DR_SUBGL_CODE       VARCHAR2,
                                             P_ST_DRACCT_NO       VARCHAR2,
                                             P_ST_CRGL_CATG          VARCHAR2,
                                             P_ST_CRGL_CODE          VARCHAR2,
                                             P_ST_CR_SUBGL_CODE       VARCHAR2,
                                             P_ST_CRACCT_NO       VARCHAR2,
                                             P_CESS_DRGL_CATG          VARCHAR2,
                                             P_CESS_DRGL_CODE          VARCHAR2,
                                             P_CESS_DR_SUBGL_CODE       VARCHAR2,
                                             P_CESS_DRACCT_NO       VARCHAR2,
                                             P_CESS_CRGL_CATG          VARCHAR2,
                                             P_CESS_CRGL_CODE          VARCHAR2,
                                             P_CESS_CR_SUBGL_CODE       VARCHAR2,
                                             P_CESS_CRACCT_NO       VARCHAR2,
                                           --  P_FEEPLAN_COUNT        NUMBER,  
                                             P_INS_USER          NUMBER,                                          
                                             P_RESP_MSG          OUT VARCHAR2
                                             ) AS
 V_EX_FEEPLAN_FROM_DATE    DATE;
 V_FROM_DATE               DATE;
 V_TO_DATE               DATE;
 
 V_FEEPLAN_COUNT         NUMBER;
 v_activeFeePlan_Count   NUMBER;
 v_samefeeplan_count     NUMBER;
 v_samedate_count     NUMBER;
 V_EX_FEEPLAN              CMS_PROD_FEES.CPF_FEE_PLAN%TYPE;   
 
 /*************************************************
      * Created By       :  Deepa
      * Created Date     :  10-Aug-2012
      * Purpose          :  To attach fee plan to Product
      * Modified By      :  
      * Modified Date    :  
      * Modified Reason  :  
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0015_B0001
  *************************************************/
  
 CURSOR C_WAIVDEL_DET(feeplan NUMBER,validdate DATE) IS 
  select CPW_WAIV_ID
         from cms_prod_waiv where 
         cpw_inst_code = p_inst_code
                    AND cpw_prod_code = P_PROD_CODE                    
                    AND cpw_fee_plan = feeplan
                    AND cpw_valid_from > validdate;   
                    
 CURSOR C_WAIVUPD_DET(feeplan NUMBER,validdate DATE) IS 
  select CPW_WAIV_ID
         from cms_prod_waiv where 
         cpw_inst_code = p_inst_code
                    AND cpw_prod_code = P_PROD_CODE                    
                    AND cpw_fee_plan = feeplan
                    AND (v_from_date - 1) BETWEEN cpw_valid_from AND cpw_valid_to;   
 BEGIN
 P_RESP_MSG:='OK';
 
 
   
 BEGIN
     V_FROM_DATE := TO_DATE(SUBSTR(TRIM(P_VALID_FROM), 1, 8), 'yyyymmdd');
    EXCEPTION
     WHEN OTHERS THEN
      
       P_RESP_MSG  := 'Problem while converting From date:' ||
                  SUBSTR(SQLERRM, 1, 200);
       RETURN;
       
    END;
    
BEGIN

SELECT COUNT (*)
  INTO v_samefeeplan_count
  FROM CMS_PROD_FEES
 WHERE CPF_INST_CODE = p_inst_code 
 AND CPF_PROD_CODE = P_PROD_CODE 
 AND CPF_FEE_PLAN=P_FEE_PLAN;
 
 IF v_samefeeplan_count=0 THEN
 
 
 
  BEGIN
    SELECT COUNT (*)
      INTO v_samedate_count
      FROM CMS_PROD_FEES
     WHERE CPF_INST_CODE = p_inst_code 
     AND CPF_PROD_CODE = P_PROD_CODE    
     AND ((V_FROM_DATE >= trunc(sysdate)) AND (V_FROM_DATE=trunc(CPF_VALID_FROM)));
     
     EXCEPTION
     WHEN OTHERS THEN
      P_RESP_MSG  := 'Error while getting the FeePlan Count:' ||
                      SUBSTR(SQLERRM, 1, 200);
      RETURN;
     
     END;
     IF v_samedate_count>0 THEN
     
      P_RESP_MSG  := 'Already FeePlan exist in the same date range :';
                      
      RETURN;
     END IF;
 
     BEGIN
    SELECT COUNT (*)
      INTO v_feeplan_count
      FROM CMS_PROD_FEES
     WHERE CPF_INST_CODE = p_inst_code     
     AND CPF_PROD_CODE = P_PROD_CODE;     
     EXCEPTION
     WHEN OTHERS THEN
      P_RESP_MSG  := 'Error while getting the FeePlan Count :' ||
                      SUBSTR(SQLERRM, 1, 200);
      RETURN;
     
     END;
     
IF v_feeplan_count >=2 THEN


SELECT COUNT (*)
INTO v_activeFeePlan_Count
  FROM CMS_PROD_FEES
 WHERE CPF_INST_CODE = p_inst_code
  AND CPF_PROD_CODE = P_PROD_CODE     
   AND ( (CPF_VALID_TO IS NULL AND CPF_VALID_FROM >= trunc(SYSDATE))
        OR (CPF_VALID_TO IS NOT NULL AND CPF_VALID_TO >= trunc(SYSDATE))
       );
       
 IF v_activeFeePlan_Count >=2 THEN
 
 P_RESP_MSG  := 'More than two Active FeePlan Cannot be attached :';
 RETURN;
 
 ELSE
  
     BEGIN
     SELECT TRUNC (CPF_VALID_FROM),CPF_FEE_PLAN
    INTO V_EX_FEEPLAN_FROM_DATE,V_EX_FEEPLAN
      FROM CMS_PROD_FEES
     WHERE CPF_INST_CODE = p_inst_code
       AND CPF_PROD_CODE = P_PROD_CODE     
       AND (((cpf_valid_from > trunc(SYSDATE))
            OR (cpf_valid_to IS NOT NULL 
            AND cpf_valid_to > trunc(SYSDATE)))
            OR (cpf_valid_from < sysdate 
            and cpf_valid_to IS NULL));
     EXCEPTION           
     WHEN OTHERS THEN
         P_RESP_MSG := 'Error while Selecting the Existing FeePlan Date :' ||
                         SUBSTR(SQLERRM, 1, 200); 
     END;
 END IF;
ELSIF V_FEEPLAN_COUNT=1 THEN
 
     BEGIN
     
        SELECT TRUNC (CPF_VALID_FROM),CPF_FEE_PLAN
            INTO V_EX_FEEPLAN_FROM_DATE,V_EX_FEEPLAN
          FROM CMS_PROD_FEES
         WHERE  CPF_PROD_CODE = P_PROD_CODE
         AND CPF_INST_CODE =P_INST_CODE;
       EXCEPTION
     WHEN OTHERS THEN
     P_RESP_MSG := 'Error while Selecting the Existing FeePlan Date :' ||
                     SUBSTR(SQLERRM, 1, 200); 
     END;  
 
 END IF;
 
  IF ((V_EX_FEEPLAN_FROM_DATE < V_FROM_DATE)) THEN
  
   
  
         BEGIN         
         
                UPDATE CMS_PROD_FEES
                   SET CPF_VALID_TO = v_from_date - 1
                 WHERE  CPF_PROD_CODE = P_PROD_CODE                   
                   AND CPF_INST_CODE = p_inst_code
                   AND CPF_FEE_PLAN = v_ex_feeplan;
                   
            FOR I IN C_WAIVDEL_DET(v_ex_feeplan,v_from_date - 1) LOOP
           
           EXIT WHEN C_WAIVDEL_DET%NOTFOUND;
           
            DELETE FROM cms_prod_waiv
                  WHERE CPW_INST_CODE = p_inst_code
                    AND CPW_PROD_CODE = P_PROD_CODE                    
                    AND CPW_FEE_PLAN = v_ex_feeplan
                    AND CPW_VALID_FROM > v_from_date - 1
                    AND CPW_WAIV_ID=I.CPW_WAIV_ID;  
                    
                    
                    
                    update cms_prod_waiv_hist set CPW_CHNG_REASON='Fee Plan Date Modified'
                     WHERE CPW_INST_CODE = p_inst_code                    
                    AND CPW_PROD_CODE = P_PROD_CODE                    
                    AND CPW_FEE_PLAN = v_ex_feeplan                    
                    AND CPW_VALID_FROM > v_from_date - 1
                    AND CPW_WAIV_ID=I.CPW_WAIV_ID
                    AND  CPW_ACT_TYPE='D';             
           
            
           
           END LOOP;     
    
  
              FOR I1 IN C_WAIVUPD_DET(v_ex_feeplan,v_from_date - 1) LOOP
                       
                     
               EXIT WHEN C_WAIVUPD_DET%NOTFOUND;
               
                UPDATE cms_prod_waiv
                   SET CPW_VALID_TO = v_from_date - 1
                 WHERE CPW_INST_CODE = p_inst_code
                    AND CPW_PROD_CODE = P_PROD_CODE                    
                    AND CPW_FEE_PLAN = v_ex_feeplan                   
                   AND ((v_from_date - 1) BETWEEN CPW_VALID_FROM 
                   AND CPW_VALID_TO) AND CPW_WAIV_ID=I1.CPW_WAIV_ID;                                 
                                
                                
               
                UPDATE cms_prod_waiv_hist
                   SET CPW_CHNG_REASON = 'Fee Plan Date Modified'
                 WHERE CPW_INST_CODE = p_inst_code
                    AND CPW_PROD_CODE = P_PROD_CODE                    
                    AND CPW_FEE_PLAN = v_ex_feeplan   
                   AND (v_from_date - 1) BETWEEN CPW_VALID_FROM AND CPW_VALID_TO
                   AND CPW_WAIV_ID = i1.CPW_WAIV_ID
                   AND cpw_act_type = 'U';                 
                        
                       
              END LOOP;     
               
           
         
         
         EXCEPTION
         WHEN OTHERS THEN
         P_RESP_MSG := 'Error while updating the To Date of Existing FeePlan :' ||
                         SUBSTR(SQLERRM, 1, 200);
         RETURN;
         END;
     
     ELSE
     
     V_TO_DATE:=V_EX_FEEPLAN_FROM_DATE-1;
     END IF; 
 
BEGIN           
            
            INSERT INTO CMS_PROD_FEES
            (CPF_INST_CODE, CPF_PROD_CODE, CPF_VALID_FROM,
             CPF_VALID_TO, CPF_FLOW_SOURCE, CPF_INS_USER, CPF_LUPD_USER,
             CPF_DRGL_CATG, CPF_DRGL_CODE, CPF_DRSUBGL_CODE, CPF_DRACCT_NO,
             CPF_CRGL_CATG, CPF_CRGL_CODE, CPF_CRSUBGL_CODE,CPF_CRACCT_NO,
             CPF_ST_CALC_FLAG, CPF_CESS_CALC_FLAG,  CPF_ST_CRGL_CATG,
             CPF_ST_CRGL_CODE, CPF_ST_CRSUBGL_CODE, CPF_ST_CRACCT_NO,
             CPF_ST_DRGL_CATG, CPF_ST_DRGL_CODE, CPF_ST_DRSUBGL_CODE,
            CPF_ST_DRACCT_NO,  CPF_CESS_CRGL_CATG, CPF_CESS_CRGL_CODE,
             CPF_CESS_CRSUBGL_CODE, CPF_CESS_CRACCT_NO, CPF_cess_drgl_catg,
             CPF_CESS_DRGL_CODE, CPF_CESS_DRSUBGL_CODE, CPF_CESS_DRACCT_NO,
             CPF_fee_plan, CPF_INS_DATE
            )
     VALUES (p_inst_code, P_PROD_CODE, v_from_date,
             v_to_date, 'P', p_ins_user, p_lupd_user,
             p_drgl_catg, p_drgl_code, p_drsubgl_code, p_dracct_no,
             p_crgl_catg, p_crgl_code, p_crsubgl_code, p_cracct_no,
             p_st_calc_flag, p_cess_calc_flag, p_st_crgl_catg, 
             p_st_crgl_code, p_st_cr_subgl_code,p_st_cracct_no,
             p_st_drgl_catg, p_st_drgl_code, p_st_dr_subgl_code,
             p_st_dracct_no,p_cess_crgl_catg,p_cess_crgl_code,
             p_cess_cr_subgl_code, p_cess_cracct_no,p_cess_drgl_catg,
             p_cess_drgl_code,p_cess_dr_subgl_code, p_cess_dracct_no, 
             p_fee_plan,sysdate
            );
            
        
            EXCEPTION
 WHEN OTHERS THEN
 P_RESP_MSG := 'Error while inserting the FeePlan Details :' ||
                 SUBSTR(SQLERRM, 1, 200);
 RETURN;
 END;
 
ELSE
P_RESP_MSG  := 'Same FeePlan has already attached:';
RETURN;
END IF;
END;
END; 
/
show error;