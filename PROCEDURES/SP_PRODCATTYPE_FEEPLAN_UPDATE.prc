CREATE OR REPLACE PROCEDURE VMSCMS.sp_prodcattype_feeplan_update (
  p_cce_inst_code           IN       NUMBER,
   p_cpf_prod_code           IN       VARCHAR2,
   p_cpf_card_type           IN       NUMBER,   
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
   V_COUNT VARCHAR2(100);
   V_VALID_FROM_OLD     DATE;
   V_VALID_TO_OLD       DATE;
   V_FEE_PLAN_OLD       CMS_PRODCATTYPE_FEES.CPF_FEE_PLAN%TYPE;
   V_PC_FEEPLAN_ID      CMS_PRODCATTYPE_FEES.CPF_PRODCATTYPE_ID%TYPE;
   V_WAIVER_ID          CMS_PRODCATTYPE_WAIV.CPW_WAIV_ID%TYPE;
   V_WAIVER_FEEPLAN     CMS_PRODCATTYPE_WAIV.CPW_FEE_PLAN%TYPE;
   V_WAIVER_FEE_CODE    CMS_PRODCATTYPE_WAIV.CPW_FEE_CODE%TYPE;
   V_WAIVER_FROM_OLD     DATE;
   V_WAIVER_TO_OLD       DATE;
   V_DATE_UPD             NUMBER(1);
   V_SYSDATE             DATE DEFAULT TRUNC(SYSDATE);
   V_ACTIVE_FEEPLAN       CMS_PROD_FEES.CPF_FEE_PLAN%TYPE;
   V_ACTIVE_FEEPLANID     CMS_PROD_FEES.CPF_PRODFEEPLAN_ID%TYPE;
   V_samedrangecnt        NUMBER(1);
   
   
   CURSOR C(P_FEEPLAN IN VARCHAR2) IS
     SELECT CPW_WAIV_ID,CPW_VALID_FROM,CPW_VALID_TO,CPW_FEE_CODE 
  FROM CMS_PRODCATTYPE_WAIV
 WHERE CPW_PROD_CODE = p_cpf_prod_code
 AND CPW_CARD_TYPE=p_cpf_card_type
   AND CPW_FEE_PLAN=P_FEEPLAN
   AND (CPW_VALID_TO IS NULL OR CPW_VALID_TO > V_SYSDATE);
   
    CURSOR C1(P_FEEPLAN IN VARCHAR2) IS
   SELECT CPW_WAIV_ID,CPW_FEE_CODE             
              FROM CMS_PRODCATTYPE_WAIV
             WHERE CPW_PROD_CODE = p_cpf_prod_code
             AND CPW_CARD_TYPE=p_cpf_card_type
               AND CPW_FEE_PLAN=P_FEEPLAN               
              AND CPW_VALID_TO IS NOT NULL
              AND  CPW_VALID_TO > v_sysdate
                and CPW_VALID_FROM < p_cce_valid_from_new;

/*************************************************
     * Created  By      :  NA
     * Created  Date    :  NA
     * Modified By      :  Deepa T
      * Modified Date    :  20--Aug-2012
      * Modified Reason  :  Waiver and fee changes.
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0015_B0001
 ***********************************************/
BEGIN
   v_error := 'OK';
   V_SYSDATE:=trunc(sysdate);

 
    SELECT COUNT(*) INTO V_COUNT FROM CMS_PRODCATTYPE_FEES 
    WHERE CPF_PROD_CODE=p_cpf_prod_code 
    AND CPF_CARD_TYPE=p_cpf_card_type
    AND CPF_INST_CODE=p_cce_inst_code ;
    
 IF V_COUNT >= 1
 THEN
 
BEGIN
SELECT CPF_VALID_FROM, CPF_VALID_TO,CPF_PRODCATTYPE_ID
  INTO v_valid_from_old, v_valid_to_old,V_PC_FEEPLAN_ID
  FROM CMS_PRODCATTYPE_FEES
 WHERE CPF_FEE_PLAN = p_fee_plan
   AND CPF_PROD_CODE=p_cpf_prod_code 
    AND CPF_CARD_TYPE=p_cpf_card_type
    AND CPF_INST_CODE=p_cce_inst_code ;
   
   V_WAIVER_FEEPLAN:=p_fee_plan;
   IF v_valid_from_old <> p_cce_valid_from_new THEN
     V_DATE_UPD:=1;
     
   END IF;

   EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   BEGIN
   SELECT CPF_FEE_PLAN, CPF_VALID_TO, CPF_VALID_FROM,CPF_PRODCATTYPE_ID
  INTO v_fee_plan_old, v_valid_to_old, v_valid_from_old,V_PC_FEEPLAN_ID
  FROM CMS_PRODCATTYPE_FEES
 WHERE CPF_VALID_FROM = p_cce_valid_from_new
   AND CPF_PROD_CODE=p_cpf_prod_code 
    AND CPF_CARD_TYPE=p_cpf_card_type
    AND CPF_INST_CODE=p_cce_inst_code ;
   
   V_WAIVER_FEEPLAN:=v_fee_plan_old;
 EXCEPTION 
 WHEN NO_DATA_FOUND THEN
 v_error :='FeePlan is not attached to Product Category';
 END ;

END;
       
--IF V_VALID_FROM_OLD IS NOT NULL THEN
IF V_VALID_TO_OLD IS NULL THEN

    IF V_VALID_FROM_OLD < V_SYSDATE THEN

    v_error :='Active FeePlan should not be updated';
    END IF;

ELSIF (V_SYSDATE between V_VALID_FROM_OLD AND V_VALID_TO_OLD) THEN

v_error :='Active FeePlan should not be updated';

ELSIF (sysdate > V_VALID_FROM_OLD AND sysdate > V_VALID_TO_OLD) THEN

v_error :='Expired FeePlan should not be updated';

END IF;

IF V_DATE_UPD=1 THEN


SELECT COUNT (*)
  INTO V_samedrangecnt
  FROM CMS_PRODCATTYPE_FEES
 WHERE cpf_prod_code = p_cpf_prod_code
    AND CPF_CARD_TYPE=p_cpf_card_type
   AND cpf_inst_code = p_cce_inst_code
   AND CPF_FEE_PLAN NOT IN (p_fee_plan)
   AND ((cpf_valid_from = p_cce_valid_from_new)        
            OR (p_cce_valid_from_new BETWEEN cpf_valid_from AND cpf_valid_to)
           );
       
 IF V_samedrangecnt>0 THEN
 v_error :='FeePlan exist in the same Date Range';
 
 END IF;


END IF;


IF v_error='OK' THEN
 
 IF V_VALID_TO_OLD IS NULL  THEN
 --BEGIN
 
 FOR I IN C(V_WAIVER_FEEPLAN) LOOP 
   
   IF I.CPW_VALID_FROM < p_cce_valid_from_new  and V_DATE_UPD=1 THEN  
   
   BEGIN  
      
   update CMS_PRODCATTYPE_WAIV set CPW_VALID_FROM= p_cce_valid_from_new
   where  CPW_PROD_CODE=p_cpf_prod_code
   AND CPW_CARD_TYPE=p_cpf_card_type
   AND CPW_FEE_PLAN=V_WAIVER_FEEPLAN   
   AND CPW_FEE_CODE=I.CPW_FEE_CODE
   AND CPW_VALID_FROM=I.CPW_VALID_FROM
   AND CPW_WAIV_ID=I.CPW_WAIV_ID;
   IF SQL%ROWCOUNT <> 0 THEN
   
    update CMS_PRODCATTYPE_WAIV_HIST
        SET CPW_CHNG_REASON='Fee Plan Date Updated'
              WHERE  CPW_PROD_CODE = p_cpf_prod_code
              AND CPW_CARD_TYPE=p_cpf_card_type
              AND CPW_FEE_PLAN=V_WAIVER_FEEPLAN  
              AND CPW_WAIV_ID= I.CPW_WAIV_ID
              AND CPW_ACT_TYPE='U';
              
    END IF;
   EXCEPTION 
   WHEN OTHERS THEN
   v_error:='Error while updating Waiver' ||SQLERRM;
   
  END ;
   
  END IF;
  
  END LOOP;  
 
 
 ELSE IF p_cce_valid_from_new > V_VALID_TO_OLD THEN
 
 v_error :='From date of FeePlan is gereater than End Date'; 
 
 END IF;
 
 END IF;
 END IF;
 
      IF v_error ='OK' 
      THEN
     
UPDATE cms_prodcattype_fees
   SET cpf_valid_from = p_cce_valid_from_new,
       cpf_crgl_catg = p_cce_crgl_catg,
       cpf_crgl_code = p_cce_crgl_code,
       cpf_crsubgl_code = p_cce_crsubgl_code,
       cpf_cracct_no = p_cce_cracct_no,
       cpf_drgl_catg = p_cce_drgl_catg,
       cpf_drgl_code = p_cce_drgl_code,
       cpf_drsubgl_code = p_cce_drsubgl_code,
       cpf_dracct_no = p_cce_dracct_no,
       cpf_st_crgl_catg = p_cce_st_crgl_catg,
       cpf_st_crgl_code = p_cce_st_crgl_code,
       cpf_st_crsubgl_code = p_cce_st_crsubgl_code,
       cpf_st_cracct_no = p_cce_st_cracct_no,
       cpf_st_drgl_catg = p_cce_st_drgl_catg,
       cpf_st_drgl_code = p_cce_st_drgl_code,
       cpf_st_drsubgl_code = p_cce_st_drsubgl_code,
       cpf_st_dracct_no = p_cce_st_dracct_no,
       cpf_cess_crgl_catg = p_cce_cess_crgl_catg,
       cpf_cess_crgl_code = p_cce_cess_crgl_code,
       cpf_cess_crsubgl_code = p_cce_cess_crsubgl_code,
       cpf_cess_cracct_no = p_cce_cess_cracct_no,
       cpf_cess_drgl_catg = p_cce_cess_drgl_catg,
       cpf_cess_drgl_code = p_cce_cess_drgl_code,
       cpf_cess_drsubgl_code = p_cce_cess_drsubgl_code,
       cpf_cess_dracct_no = p_cce_cess_dracct_no,
       cpf_st_calc_flag = p_cce_st_calc_flag,
       cpf_fee_plan = p_fee_plan,
       cpf_cess_calc_flag = p_cce_cess_calc_flag
 WHERE cpf_prod_code = p_cpf_prod_code
   AND cpf_card_type = p_cpf_card_type
   AND cpf_inst_code = p_cce_inst_code
   AND cpf_prodcattype_id = v_pc_feeplan_id;
   
       IF SQL%ROWCOUNT =0 
         THEN
            v_error := 'Update is not Done Record Not Found';
            
      ELSE
      
      
      IF V_DATE_UPD=1 THEN
      
       BEGIN
        SELECT cpf_fee_plan, CPF_PRODCATTYPE_ID
            INTO V_ACTIVE_FEEPLAN,V_ACTIVE_FEEPLANID  
          FROM cms_prodcattype_fees
         WHERE cpf_prod_code = p_cpf_prod_code
            AND cpf_card_type = p_cpf_card_type
            AND cpf_inst_code = p_cce_inst_code
           AND cpf_valid_to IS NOT NULL
           AND cpf_valid_to > v_sysdate and cpf_valid_from < p_cce_valid_from_new;             
          
            UPDATE cms_prodcattype_fees
               SET cpf_valid_to = p_cce_valid_from_new - 1
             WHERE cpf_fee_plan = v_active_feeplan
               AND CPF_PRODCATTYPE_ID = v_active_feeplanid
               AND cpf_prod_code = p_cpf_prod_code
               AND cpf_card_type = p_cpf_card_type
               AND cpf_inst_code = p_cce_inst_code;
               
            IF SQL%ROWCOUNT =0 
            THEN
              v_error := 'Error while updating To Date of other Active FeePlan';
            ELSE
            
           FOR I1 IN C1(V_ACTIVE_FEEPLAN) LOOP 
           
           update CMS_PRODCATTYPE_WAIV
           SET CPW_VALID_TO=p_cce_valid_from_new - 1           
             WHERE CPW_PROD_CODE = p_cpf_prod_code
             AND CPW_CARD_TYPE=p_cpf_card_type
               AND CPW_FEE_PLAN=V_ACTIVE_FEEPLAN  
               AND CPW_WAIV_ID= I1.CPW_WAIV_ID
               AND CPW_FEE_CODE=I1.CPW_FEE_CODE;
               
              update CMS_PRODCATTYPE_WAIV_HIST
              SET CPW_CHNG_REASON='Fee Plan Date Updated'
              WHERE  CPW_PROD_CODE = p_cpf_prod_code
              AND CPW_CARD_TYPE=p_cpf_card_type
              AND CPW_FEE_PLAN=V_ACTIVE_FEEPLAN  
              AND CPW_WAIV_ID= I1.CPW_WAIV_ID
              AND CPW_ACT_TYPE='U';
            
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
 v_error :='Feeplan is Not attached to this Product Category ';
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