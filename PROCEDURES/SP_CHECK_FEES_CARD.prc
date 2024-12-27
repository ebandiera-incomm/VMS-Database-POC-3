create or replace
PROCEDURE        vmscms.SP_CHECK_FEES_CARD (  
prm_inst_code         IN          NUMBER,
prm_card_number       IN          VARCHAR2,
prm_del_channel       IN          VARCHAR2,
prm_tran_code         IN          VARCHAR2,
prm_fee_attach        OUT         NUMBER,
prm_error             OUT         VARCHAR2
)
IS

exp_main          EXCEPTION;
v_hash_pan         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
v_card_cnt        NUMBER;
v_cardFee_cnt        NUMBER;

/**********************************************************************************************************************
    * Created By      : Ramesh A
  	* Created Date    : 18-SEP-2014 
  	* Created Reason  : MVCSD-5381
  	* Reviewer        : 
  	* Build Number    :RI0027.4_B0001
     ***********************************************************************************************************************/
BEGIN
  BEGIN
      v_hash_pan := Gethash(prm_card_number);
  EXCEPTION
  WHEN OTHERS THEN
  prm_error := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
      RAISE exp_main;
  END;  
 
  BEGIN
    select COUNT(CASE WHEN  (cce_valid_to IS NOT NULL AND (TRUNC(SYSDATE) between cce_valid_from and cce_valid_to))
         OR (cce_valid_to IS NULL AND TRUNC(SYSDATE) >= cce_valid_from)   THEN
          1 END)
    into   v_card_cnt
    from  cms_card_excpfee
    where cce_inst_code = prm_inst_code
    and   cce_pan_code = v_hash_pan  and cce_fee_plan=0;
  EXCEPTION
  WHEN OTHERS THEN
        prm_error := 'Error while selecting count from card level fee plan --'||SUBSTR(SQLERRM,1,200) ;
        RAISE exp_main;    
  END;
  
  IF v_card_cnt = 1 THEN 
  
    prm_fee_attach := 0; -- SKIP ALL FEES
          
      BEGIN
    
             select count(1) INTO v_cardFee_cnt
             FROM cms_fee_mast, cms_card_excpfee, cms_fee_types, cms_fee_feeplan
             WHERE cfm_inst_code =prm_inst_code
             AND cfm_inst_code = cce_inst_code
             AND cce_fee_plan = cff_fee_plan
             AND cfm_feetype_code = cft_feetype_code
             AND cft_fee_freq = 'T'
             AND cce_pan_code = v_hash_pan                                     
             AND ((CCE_VALID_TO IS NOT NULL AND (trunc(sysdate) between cce_valid_from and CCE_VALID_TO))           
             OR (CCE_VALID_TO IS NULL AND trunc(sysdate)  >= cce_valid_from)) 
             AND cfm_fee_code = cff_fee_code
             AND cfm_delivery_channel = prm_del_channel       
             AND cfm_tran_code= prm_tran_code;
    
            EXCEPTION
            WHEN OTHERS THEN
                prm_error := 'Error while selecting count from card level fee code --'||SUBSTR(SQLERRM,1,200) ;
                RAISE exp_main;    
      END;
  
      IF v_cardFee_cnt = 1 THEN 
    
        prm_fee_attach := 1; -- CHECK CARD LEVEL FEES
       
       ELSE
     
        prm_fee_attach:=0;  -- SKIP ALL FEES
     
       END IF;
       
    ELSE
    
     prm_fee_attach := 1; -- CHECK CARD LEVEL FEES
     
   END IF;
 
EXCEPTION
WHEN exp_main THEN
        prm_error := prm_error;
        prm_fee_attach := -1;
    WHEN OTHERS THEN
        prm_error := SQLERRM;
        prm_fee_attach := -1;
  
END;
  
/
show error