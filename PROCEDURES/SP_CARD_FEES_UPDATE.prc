CREATE OR REPLACE PROCEDURE VMSCMS.SP_CARD_FEES_UPDATE (
   p_cce_inst_code           IN       NUMBER,
   p_cce_pan_code            IN       VARCHAR2,
   p_cce_mbr_numb            IN       VARCHAR2,   
   p_cce_crgl_catg           IN       VARCHAR2,
   p_cce_crgl_code           IN       VARCHAR2,
   p_cce_crsubgl_code        IN       VARCHAR2,
   p_cce_cracct_no           IN       VARCHAR2,
   p_cce_drgl_catg           IN       VARCHAR2,
   p_cce_drgl_code           IN       VARCHAR2,
   p_cce_drsubgl_code        IN       VARCHAR2,
   p_cce_dracct_no           IN       VARCHAR2,
   p_cce_flow_source         IN       VARCHAR2,
    p_cce_ins_user            IN       NUMBER,
   p_cce_ins_date            IN       DATE,
   p_cce_tran_code           IN       VARCHAR2,
   p_cce_lupd_date           IN       DATE,
   p_cce_st_crgl_catg        IN       VARCHAR2,
   p_cce_st_crgl_code        IN       VARCHAR2,
   p_cce_st_crsubgl_code     IN       VARCHAR2,
   p_cce_st_cracct_no        IN       VARCHAR2,
   p_cce_st_drgl_catg        IN       VARCHAR2,
   p_cce_st_drgl_code        IN       VARCHAR2,
   p_cce_st_drsubgl_code     IN       VARCHAR2,
   p_cce_st_dracct_no        IN       VARCHAR2,
   p_cce_cess_crgl_catg      IN       VARCHAR2,
   p_cce_cess_crgl_code      IN       VARCHAR2,
   p_cce_cess_crsubgl_code   IN       VARCHAR2,
   p_cce_cess_cracct_no      IN       VARCHAR2,
   p_cce_cess_drgl_catg      IN       VARCHAR2,
   p_cce_cess_drgl_code      IN       VARCHAR2,
   p_cce_cess_drsubgl_code   IN       VARCHAR2,
   p_cce_cess_dracct_no      IN       VARCHAR2,
   p_cce_st_calc_flag        IN       NUMBER,
   p_cce_cess_calc_flag      IN       NUMBER,   
   p_cce_valid_from_new      IN       DATE,  
   p_fee_plan               in varchar2,
   p_cce_cardfee_id          IN       NUMBER,
   p_cce_lupd_user           IN       NUMBER,
   p_err                     OUT      VARCHAR2
)
AS
   v_error     VARCHAR2 (100);
   v_message   NUMBER;
   V_COUNT VARCHAR2(100);
   V_VALID_FROM_OLD     DATE;
   V_VALID_TO_OLD       DATE;
   V_FEE_PLAN_OLD       CMS_CARD_EXCPFEE.CCE_FEE_PLAN%TYPE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   V_CARD_FEEPLAN_ID    CMS_CARD_EXCPFEE.CCE_CARDFEE_ID%TYPE;
   V_WAIVER_ID          CMS_CARD_EXCPWAIV.CCE_CARD_WAIV_ID%TYPE;
   V_WAIVER_FEEPLAN     CMS_CARD_EXCPWAIV.CCE_FEE_PLAN%TYPE;
   V_WAIVER_FEE_CODE    CMS_CARD_EXCPWAIV.CCE_FEE_CODE%TYPE;    
   V_WAIVER_FROM_OLD     DATE;
   V_WAIVER_TO_OLD       DATE;
   V_DATE_UPD           NUMBER(1);
   V_samedrangecnt      NUMBER(1);
   V_SYSDATE             DATE DEFAULT TRUNC(SYSDATE);
   V_ACTIVE_FEEPLAN       CMS_PROD_FEES.CPF_FEE_PLAN%TYPE;
   V_ACTIVE_FEEPLANID     CMS_PROD_FEES.CPF_PRODFEEPLAN_ID%TYPE;


   
      CURSOR C(P_FEEPLAN IN VARCHAR2) IS
    SELECT CCE_CARD_WAIV_ID,cce_valid_from,cce_valid_to,CCE_FEE_CODE  
  FROM cms_card_excpwaiv
 WHERE cce_pan_code = gethash (p_cce_pan_code)
   AND CCE_FEE_PLAN=P_FEEPLAN
   AND (cce_valid_to IS NULL OR cce_valid_to > SYSDATE);  
    
   
    CURSOR C1(P_FEEPLAN IN VARCHAR2) IS
   SELECT CCE_CARD_WAIV_ID,CCE_FEE_CODE             
              FROM cms_card_excpwaiv
             WHERE cce_pan_code = gethash (p_cce_pan_code)
              AND CCE_FEE_PLAN=P_FEEPLAN              
              AND cce_valid_to IS NOT NULL
              AND  cce_valid_to > v_sysdate
                and CCE_VALID_FROM < p_cce_valid_from_new;

/*************************************************
     * Created  By      :  NA
     * Created  Date    :  NA
     * Modified By      :  Deepa T
     * Modified Date : 17-Aug-2012
     * Modified By      :  Deepa T
      * Modified Date    :  20--Aug-2012
      * Modified Reason  :  Waiver and fee changes.
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0015_B0001
 ***********************************************/
BEGIN
   v_error := 'OK';
 
    BEGIN
      v_hash_pan := gethash (p_cce_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);        
   END;   
 /*
 Modified by Ramkumar.mk on 20 June 2012, 
 check the pan number present in the card_excpfee table
 */
    SELECT COUNT(*) INTO V_COUNT FROM CMS_CARD_EXCPFEE 
    WHERE CCE_PAN_CODE=gethash(p_cce_pan_code) and
    CCE_INST_CODE=p_cce_inst_code ;
    
 IF V_COUNT >= 1
 THEN
 
BEGIN
SELECT cce_valid_from, cce_valid_to,CCE_CARDFEE_ID
  INTO v_valid_from_old, v_valid_to_old,V_CARD_FEEPLAN_ID
  FROM cms_card_excpfee
 WHERE cce_fee_plan = p_fee_plan
   AND cce_pan_code = v_hash_pan
   AND cce_inst_code = p_cce_inst_code;
   
   V_WAIVER_FEEPLAN:=p_fee_plan;
   
      IF v_valid_from_old <> p_cce_valid_from_new THEN
     V_DATE_UPD:=1;
     
   END IF;

   EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   BEGIN
   SELECT cce_fee_plan, cce_valid_to, cce_valid_from,CCE_CARDFEE_ID
  INTO v_fee_plan_old, v_valid_to_old, v_valid_from_old,V_CARD_FEEPLAN_ID
  FROM cms_card_excpfee
 WHERE cce_valid_from = p_cce_valid_from_new
   AND cce_pan_code = v_hash_pan
   AND cce_inst_code = p_cce_inst_code;
   
   V_WAIVER_FEEPLAN:=v_fee_plan_old;
 EXCEPTION 
 WHEN NO_DATA_FOUND THEN
 v_error :='FeePlan is not attached to card';
 END ;

END;
       
--IF V_VALID_FROM_OLD IS NOT NULL THEN
IF V_VALID_TO_OLD IS NULL THEN

    IF V_VALID_FROM_OLD < sysdate THEN

    v_error :='Active FeePlan should not be updated';
    END IF;

ELSIF (sysdate between V_VALID_FROM_OLD AND V_VALID_TO_OLD) THEN

v_error :='Active FeePlan should not be updated';

ELSIF (sysdate > V_VALID_FROM_OLD AND sysdate > V_VALID_TO_OLD) THEN

v_error :='Expired FeePlan should not be updated';

END IF;


IF V_DATE_UPD=1 THEN


SELECT COUNT (*)
  INTO V_samedrangecnt
  FROM cms_card_excpfee
 WHERE cce_pan_code = v_hash_pan
   AND cce_inst_code = p_cce_inst_code
   AND CCE_FEE_PLAN NOT IN (p_fee_plan)
   AND ((cce_valid_from = p_cce_valid_from_new)        
            OR (p_cce_valid_from_new BETWEEN cce_valid_from AND cce_valid_to)
           );
       
 IF V_samedrangecnt>0 THEN
 v_error :='FeePlan exist in the same Date Range';
 
 END IF;
END IF;
 

IF v_error='OK' THEN

 
 IF V_VALID_TO_OLD IS NULL THEN
 
  FOR I IN C(V_WAIVER_FEEPLAN) LOOP 
   
   IF I.cce_valid_from < p_cce_valid_from_new  and V_DATE_UPD=1 THEN  
   
   BEGIN  
      
   update cms_card_excpwaiv set cce_valid_from= p_cce_valid_from_new
   where  cce_pan_code = v_hash_pan
   AND CCE_FEE_PLAN=V_WAIVER_FEEPLAN 
  AND CCE_FEE_CODE=I.CCE_FEE_CODE
   AND cce_valid_from=I.cce_valid_from
   AND  CCE_CARD_WAIV_ID=I.CCE_CARD_WAIV_ID;
   IF SQL%ROWCOUNT <> 0 THEN

  
    update cms_card_excpwaiv_HIST
        SET CCE_CHNG_REASON='Fee Plan Date Updated'
              WHERE  cce_pan_code = v_hash_pan
              AND CCE_FEE_PLAN=V_WAIVER_FEEPLAN 
              AND  CCE_CARD_WAIV_ID=I.CCE_CARD_WAIV_ID
              AND CCE_ACT_TYPE='U';
              
    END IF;
   EXCEPTION 
   WHEN OTHERS THEN
   v_error:='Error while updating Waiver' ||SQLERRM;
   
  END ;
   
  END IF;
  
  END LOOP;  

 
 
 /*BEGIN
 
 SELECT CCE_CARD_WAIV_ID,cce_valid_from,cce_valid_to,CCE_FEE_CODE
 INTO V_WAIVER_ID,V_WAIVER_FROM_OLD ,V_WAIVER_TO_OLD,V_WAIVER_FEE_CODE 
  FROM cms_card_excpwaiv
 WHERE cce_pan_code = v_hash_pan
   AND CCE_FEE_PLAN=V_WAIVER_FEEPLAN
   AND (cce_valid_to IS NULL OR cce_valid_to > SYSDATE);  
   
   IF V_WAIVER_FROM_OLD < p_cce_valid_from_new THEN
    
       
   update cms_card_excpwaiv set cce_valid_from= p_cce_valid_from_new
   where  cce_pan_code = v_hash_pan
   AND CCE_FEE_PLAN=V_WAIVER_FEEPLAN
   AND (cce_valid_to IS NULL OR cce_valid_to > SYSDATE)
   AND cce_valid_to=V_WAIVER_TO_OLD
   AND CCE_FEE_CODE=V_WAIVER_FEE_CODE
   AND cce_valid_from=V_WAIVER_FROM_OLD
   AND  CCE_CARD_WAIV_ID=V_WAIVER_ID;
  END IF;
   
   EXCEPTION 
   WHEN NO_DATA_FOUND THEN
    NULL;   
   END;*/
 
 ELSE IF p_cce_valid_from_new > V_VALID_TO_OLD THEN
 
 v_error :='From date of FeePlan is gereater than End Date'; 
 
 END IF;
 
 END IF;
 END IF;
 
      IF v_error ='OK' 
      THEN
      
         UPDATE cms_card_excpfee
--update GL related information attached with this fee and its to date, from date..
         SET
             CCE_FEE_PLAN=p_fee_plan,
             cce_valid_from = p_cce_valid_from_new,
             cce_crgl_catg = p_cce_crgl_catg,
             cce_crgl_code = p_cce_crgl_code,
             cce_crsubgl_code = p_cce_crsubgl_code,
             cce_cracct_no = p_cce_cracct_no,
             cce_drgl_catg = p_cce_drgl_catg,
             cce_drgl_code = p_cce_drgl_code,
             cce_drsubgl_code = p_cce_drsubgl_code,
             cce_dracct_no = p_cce_dracct_no,
             cce_st_crgl_catg = p_cce_st_crgl_catg,
             cce_st_crgl_code = p_cce_st_crgl_code,
             cce_st_crsubgl_code = p_cce_st_crsubgl_code,
             cce_st_cracct_no = p_cce_st_cracct_no,
             cce_st_drgl_catg = p_cce_st_drgl_catg,
             cce_st_drgl_code = p_cce_st_drgl_code,
             cce_st_drsubgl_code = p_cce_st_drsubgl_code,
             cce_st_dracct_no = p_cce_st_dracct_no,
             cce_cess_crgl_catg = p_cce_cess_crgl_catg,
             cce_cess_crgl_code = p_cce_cess_crgl_code,
             cce_cess_crsubgl_code = p_cce_cess_crsubgl_code,
             cce_cess_cracct_no = p_cce_cess_cracct_no,
             cce_cess_drgl_catg = p_cce_cess_drgl_catg,
             cce_cess_drgl_code = p_cce_cess_drgl_code,
             cce_cess_drsubgl_code = p_cce_cess_drsubgl_code,
             cce_cess_dracct_no = p_cce_cess_dracct_no,
             cce_st_calc_flag = p_cce_st_calc_flag,
             cce_cess_calc_flag = p_cce_cess_calc_flag,
             cce_tran_code = p_cce_tran_code           
         where CCE_PAN_CODE=gethash(p_cce_pan_code)
         AND cce_cardfee_id = V_CARD_FEEPLAN_ID
         AND CCE_INST_CODE=p_cce_inst_code;
              IF SQL%ROWCOUNT =0 
         THEN
            v_error := 'Update is not Done Record Not Found';
         ELSE
               IF V_DATE_UPD=1 THEN
      
       BEGIN
        SELECT cce_fee_plan, CCE_CARDFEE_ID
            INTO V_ACTIVE_FEEPLAN,V_ACTIVE_FEEPLANID  
          FROM cms_card_excpfee
         WHERE cce_pan_code = v_hash_pan
            AND cce_inst_code = p_cce_inst_code
           AND cce_valid_to IS NOT NULL
           AND cce_valid_to > v_sysdate and cce_valid_from < p_cce_valid_from_new;             
          
            UPDATE cms_card_excpfee
               SET cce_valid_to = p_cce_valid_from_new - 1
             WHERE cce_fee_plan = v_active_feeplan
               AND CCE_CARDFEE_ID = v_active_feeplanid
              AND cce_pan_code = v_hash_pan
            AND cce_inst_code = p_cce_inst_code;
               
            IF SQL%ROWCOUNT =0 
            THEN
              v_error := 'Error while updating To Date of other Active FeePlan';
            ELSE
            
           FOR I1 IN C1(V_ACTIVE_FEEPLAN) LOOP 
           
           update CMS_CARD_EXCPWAIV
           SET CCE_VALID_TO=p_cce_valid_from_new - 1           
             WHERE cce_pan_code = v_hash_pan             
               AND CCE_FEE_PLAN=V_ACTIVE_FEEPLAN  
               AND CCE_CARD_WAIV_ID= I1.CCE_CARD_WAIV_ID
               AND CCE_FEE_CODE=I1.CCE_FEE_CODE;
               
              update CMS_CARD_EXCPWAIV_HIST
              SET CCE_CHNG_REASON='Fee Plan Date Updated'
              WHERE cce_pan_code = v_hash_pan           
              AND CCE_FEE_PLAN=V_ACTIVE_FEEPLAN  
              AND CCE_CARD_WAIV_ID= I1.CCE_CARD_WAIV_ID
              AND CCE_ACT_TYPE='U';
            
           END LOOP;
              
           END IF;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
       NULL;
       WHEN OTHERS THEN
        v_error := 'Error while selecting other Active FeePlan details '|| SQLCODE || '---' || SQLERRM;
         
       END; 
       END IF;    
   
           
      END IF;
    END IF;
   ELSE
 v_error :='Feeplan is Not attached to this Card';
   END IF;
  
    IF v_error <> 'OK'
   THEN
       p_err := v_error;
     ELSE
     
     p_err := v_error;
   
      END IF;
   
  
EXCEPTION                                               
   WHEN OTHERS
   THEN
      p_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END; 
/
show error;