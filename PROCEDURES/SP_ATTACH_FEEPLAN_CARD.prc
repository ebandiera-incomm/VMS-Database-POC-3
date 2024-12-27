CREATE OR REPLACE PROCEDURE VMSCMS.SP_ATTACH_FEEPLAN_CARD(P_INST_CODE         IN NUMBER,
                                             P_PAN_CODE               IN VARCHAR2,
                                             P_MBR_NUMB          IN     VARCHAR2,
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
 V_HASH_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
 V_FROM_DATE               DATE;
 V_TO_DATE               DATE;
 
 V_FEEPLAN_COUNT         NUMBER;
 v_activeFeePlan_Count   NUMBER;
 v_samefeeplan_count     NUMBER;
 v_samedate_count     NUMBER;
 V_EX_FEEPLAN              CMS_CARD_EXCPFEE.CCE_FEE_PLAN%TYPE;  
 V_WAIVER_EXIST         NUMBER(1);  
 
 /*************************************************
      * Created By       :  Deepa
      * Created Date     :  10-Aug-2012
      * Purpose          :  To attach fee plan to card
      * Modified By      :  
      * Modified Date    :  
      * Modified Reason  :  
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0024.1_B0011
  *************************************************/
  
 CURSOR C_WAIVDEL_DET(pancode VARCHAR2,feeplan NUMBER,validdate DATE) IS 
  select CCE_CARD_WAIV_ID
         from cms_card_excpwaiv where 
         cce_inst_code = p_inst_code
                    AND cce_pan_code = pancode
                    AND cce_mbr_numb = p_mbr_numb
                    AND cce_fee_plan = feeplan
                    AND cce_valid_from > validdate;   
                    
 CURSOR C_WAIVUPD_DET(pancode VARCHAR2,feeplan NUMBER,validdate DATE) IS 
  select CCE_CARD_WAIV_ID
         from cms_card_excpwaiv where 
         cce_inst_code = p_inst_code
                    AND cce_pan_code = pancode
                    AND cce_mbr_numb = p_mbr_numb
                    AND cce_fee_plan = feeplan
                    AND (v_from_date - 1) BETWEEN cce_valid_from AND cce_valid_to;   
 BEGIN
 P_RESP_MSG:='OK';
 
  BEGIN
	 V_HASH_PAN := GETHASH(P_PAN_CODE);
    EXCEPTION
	 WHEN OTHERS THEN
	   P_RESP_MSG := 'Error while converting pan:' ||
				 SUBSTR(SQLERRM, 1, 200); 
       RETURN; 
    END;
   
   BEGIN
	 V_ENCR_PAN := FN_EMAPS_MAIN(P_PAN_CODE);
    EXCEPTION
	 WHEN OTHERS THEN
	   P_RESP_MSG := 'Error while converting pan:' ||
				 SUBSTR(SQLERRM, 1, 200);
      RETURN;	   
    END; 
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
  FROM cms_card_excpfee
 WHERE cce_inst_code = p_inst_code AND cce_pan_code = v_hash_pan
 AND cce_fee_plan=P_FEE_PLAN;
 
 IF v_samefeeplan_count=0 THEN
 
 
 
  BEGIN
    SELECT COUNT (*)
      INTO v_samedate_count
      FROM cms_card_excpfee
     WHERE cce_inst_code = p_inst_code AND cce_pan_code = v_hash_pan
     AND ((V_FROM_DATE >= trunc(sysdate)) AND (V_FROM_DATE=trunc(cce_valid_from)));
     
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
      FROM cms_card_excpfee
     WHERE cce_inst_code = p_inst_code AND cce_pan_code = v_hash_pan;
     
     EXCEPTION
     WHEN OTHERS THEN
      P_RESP_MSG  := 'Error while getting the FeePlan Count :' ||
                      SUBSTR(SQLERRM, 1, 200);
      RETURN;
     
     END;
     
IF v_feeplan_count >=2 THEN


SELECT COUNT (*)
INTO v_activeFeePlan_Count
  FROM cms_card_excpfee
 WHERE cce_inst_code = p_inst_code
   AND cce_pan_code = v_hash_pan
   AND ( ( cce_valid_to IS NULL AND cce_valid_from >= trunc(SYSDATE))
        OR (cce_valid_to IS NOT NULL AND cce_valid_to >= trunc(SYSDATE))
       );
       
 IF v_activeFeePlan_Count >=2 THEN
 
 P_RESP_MSG  := 'More than two Active FeePlan Cannot be attached :';
 RETURN;
 
 ELSE
  
     BEGIN
     SELECT TRUNC (cce_valid_from),CCE_FEE_PLAN
    INTO V_EX_FEEPLAN_FROM_DATE,V_EX_FEEPLAN
      FROM cms_card_excpfee
     WHERE cce_inst_code = p_inst_code
       AND cce_pan_code = v_hash_pan
      AND (((cce_valid_from > trunc(SYSDATE))
            OR (cce_valid_to IS NOT NULL 
            AND cce_valid_to > trunc(SYSDATE)))
            OR (cce_valid_from < sysdate 
            and cce_valid_to IS NULL));
     EXCEPTION           
     WHEN OTHERS THEN
         P_RESP_MSG := 'Error while Selecting the Existing FeePlan Date :' ||
                         SUBSTR(SQLERRM, 1, 200); 
      RETURN;
     END;
 END IF;
ELSIF V_FEEPLAN_COUNT=1 THEN
 
     BEGIN
     
        SELECT TRUNC (cce_valid_from),CCE_FEE_PLAN
            INTO V_EX_FEEPLAN_FROM_DATE,V_EX_FEEPLAN
          FROM cms_card_excpfee
         WHERE cce_pan_code =V_HASH_PAN AND cce_mbr_numb = P_MBR_NUMB AND cce_inst_code =P_INST_CODE;
       EXCEPTION
     WHEN OTHERS THEN
     P_RESP_MSG := 'Error while Selecting the Existing FeePlan Date :' ||
                     SUBSTR(SQLERRM, 1, 200); 
      RETURN;
     END;  
 
 END IF;
 
  IF ((V_EX_FEEPLAN_FROM_DATE < V_FROM_DATE)) THEN
  
   
  
         BEGIN         
         
                UPDATE cms_card_excpfee
                   SET cce_valid_to = v_from_date - 1
                 WHERE cce_pan_code = v_hash_pan
                   AND cce_mbr_numb = p_mbr_numb
                   AND cce_inst_code = p_inst_code
                   AND cce_fee_plan = v_ex_feeplan;
                   
                   
           FOR I IN C_WAIVDEL_DET(v_hash_pan,v_ex_feeplan,v_from_date - 1) LOOP
           
           EXIT WHEN C_WAIVDEL_DET%NOTFOUND;
           
            DELETE FROM cms_card_excpwaiv
                  WHERE cce_inst_code = p_inst_code
                    AND cce_pan_code = v_hash_pan
                    AND cce_mbr_numb = p_mbr_numb
                    AND cce_fee_plan = v_ex_feeplan
                    AND cce_valid_from > v_from_date - 1
                    AND CCE_CARD_WAIV_ID=I.CCE_CARD_WAIV_ID;  
                    
                    
                    
                    update cms_card_excpwaiv_hist set CCE_CHNG_REASON='Fee Plan Date Modified' WHERE cce_inst_code = p_inst_code
                    AND cce_pan_code = v_hash_pan
                    AND cce_mbr_numb = p_mbr_numb
                    AND cce_fee_plan = v_ex_feeplan
                    AND cce_valid_from > v_from_date - 1
                    AND CCE_CARD_WAIV_ID=I.CCE_CARD_WAIV_ID
                    AND  CCE_ACT_TYPE='D';             
           
            
           
           END LOOP;     
    
  
              FOR I1 IN C_WAIVUPD_DET(v_hash_pan,v_ex_feeplan,v_from_date - 1) LOOP
                       
                     
               EXIT WHEN C_WAIVUPD_DET%NOTFOUND;
               
                UPDATE cms_card_excpwaiv
                   SET cce_valid_to = v_from_date - 1
                 WHERE cce_inst_code = p_inst_code
                   AND cce_pan_code = v_hash_pan
                   AND cce_mbr_numb = p_mbr_numb
                   AND cce_fee_plan = v_ex_feeplan
                   AND ((v_from_date - 1) BETWEEN cce_valid_from 
                   AND cce_valid_to) AND CCE_CARD_WAIV_ID=I1.CCE_CARD_WAIV_ID  ;                               
                                
                                
               
                UPDATE cms_card_excpwaiv_hist
                   SET cce_chng_reason = 'Fee Plan Date Modified'
                 WHERE cce_inst_code = p_inst_code
                   AND cce_pan_code = v_hash_pan
                   AND cce_mbr_numb = p_mbr_numb
                   AND cce_fee_plan = v_ex_feeplan
                   AND (v_from_date - 1) BETWEEN cce_valid_from AND cce_valid_to
                   AND cce_card_waiv_id = i1.cce_card_waiv_id
                   AND cce_act_type = 'U';                 
                        
                       
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
INSERT INTO cms_card_excpfee
            (cce_inst_code, cce_pan_code, cce_mbr_numb, cce_valid_from,
             cce_valid_to, cce_flow_source, cce_ins_user, cce_lupd_user,
             cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
             cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
             cce_st_calc_flag, cce_cess_calc_flag, cce_st_crgl_catg,
             cce_st_crgl_code, cce_st_crsubgl_code, cce_st_cracct_no,
             cce_st_drgl_catg, cce_st_drgl_code, cce_st_drsubgl_code,
             cce_st_dracct_no, cce_cess_crgl_catg, cce_cess_crgl_code,
             cce_cess_crsubgl_code, cce_cess_cracct_no, cce_cess_drgl_catg,
             cce_cess_drgl_code, cce_cess_drsubgl_code, cce_cess_dracct_no,
             cce_fee_plan, cce_pan_code_encr
            )
     VALUES (p_inst_code, v_hash_pan, p_mbr_numb, v_from_date,
             v_to_date, 'C', p_ins_user, p_lupd_user,
             p_drgl_catg, p_drgl_code, p_drsubgl_code, p_dracct_no,
             p_crgl_catg, p_crgl_code, p_crsubgl_code, p_cracct_no,
             p_st_calc_flag, p_cess_calc_flag,   p_st_crgl_catg, p_st_crgl_code, p_st_cr_subgl_code,
             p_st_cracct_no,p_st_drgl_catg,
             p_st_drgl_code, p_st_dr_subgl_code, p_st_dracct_no,
             p_cess_crgl_catg,
             p_cess_crgl_code, p_cess_cr_subgl_code, p_cess_cracct_no,
            p_cess_drgl_catg, p_cess_drgl_code,
             p_cess_dr_subgl_code, p_cess_dracct_no, 
             p_fee_plan, v_encr_pan
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
SHOW ERROR;