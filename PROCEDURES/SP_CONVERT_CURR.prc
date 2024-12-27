create or replace PROCEDURE        vmscms.Sp_Convert_Curr
(
prm_inst_code   NUMBER,
prm_txn_curr    VARCHAR2,
prm_card_no    VARCHAR2,
prm_txn_amt     NUMBER,
prm_tran_date    DATE,
prm_act_amt   OUT   NUMBER,
prm_card_curr OUT  NUMBER,
prm_errmsg      OUT     VARCHAR2,
P_PROD_CODE IN  VARCHAR2,
P_CARD_TYPE IN NUMBER

)
IS
 /************************************************************************************************************
    
     * Modified By      : Deepa T
     * Modified Date    : 09/01/2014
     * Modified Reason  : For the Performance Issue:MVHOST-547
     * Reviewer         : Dhiraj
     * Reviewed Date    : 09/01/2014
     * Release Number   : RI0027_B0003

     * Modified By      : Pankaj S.
     * Modified Date    : 11/03/2015
     * Modified Reason  : For the Performance changes
     * Reviewer         : Saravankumar
     * Release Number   : RI0027.4.3.4     
     
     * Modified By      : MageshKumar S.
     * Modified Date    : 19/07/2017
     * Modified Reason  : FSS-5157
     * Reviewer         : Saravankumar
     * Release Number   : VMSGPRHOST17.07
  /************************************************************************************************************/
     
v_base_curr           CMS_INST_PARAM.cip_param_value%TYPE;
v_card_curr           VARCHAR2(5);
v_tran_curr           VARCHAR2(5);
v_errmsg              VARCHAR2(500);
v_txn_amt             NUMBER;
v_buying_rate         PCMS_EXCHANGERATE_MAST.pem_buying_rate%TYPE;
v_selling_rate        PCMS_EXCHANGERATE_MAST.pem_selling_rate%TYPE;
v_markup          PCMS_EXCHANGERATE_MAST.pem_markup_perc%TYPE;
exp_reject_record     EXCEPTION;

 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE; 
v_prod_code cms_prod_mast.cpm_prod_code%type;
v_card_type cms_prod_cattype.cpc_card_type%type;
 
  
BEGIN           --<< MAIN BEGIN >>
        prm_errmsg := 'OK';
--Sn Commented by Pankaj S. on 11-Mar-2015 for PERF changes        
--SN CREATE HASH PAN 
--BEGIN
--    v_hash_pan := Gethash(prm_card_no);
--EXCEPTION
--WHEN OTHERS THEN
--  v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
--  RAISE    exp_reject_record;
--END;
--EN CREATE HASH PAN*/
--En Commented by Pankaj S. on 11-Mar-2015 for PERF changes


          --Sn find the card curr
   --     BEGIN
               -- query commented as currency profile parameter will not be available for the product category
                  /*SELECT trim(CBP_PARAM_VALUE)
                    INTO     v_card_curr
                    FROM     CMS_APPL_PAN,
                         CMS_BIN_PARAM ,
                         CMS_PROD_CATTYPE
                  WHERE CAP_INST_CODE = prm_inst_code
                  AND CAP_INST_CODE =CBP_INST_CODE
                  AND CAP_INST_CODE = CPC_INST_CODE
                  AND CAP_PROD_CODE = CPC_PROD_CODE
                    AND      CAP_CARD_TYPE = CPC_CARD_TYPE
                    AND    CAP_PAN_CODE  = prm_card_no
                    AND    CBP_PARAM_NAME = 'Currency'
                    AND    CBP_PROFILE_CODE = CPC_PROFILE_CODE;*/
                  
                  
-- Get the currency profile parameter from the product master and profile master. -- 04-Jan-2011  

                  /* SELECT trim(CBP_PARAM_VALUE) INTO v_card_curr
                   from cms_appl_pan, cms_bin_param, cms_prod_mast
                   where cap_inst_code = cbp_inst_code
                   and cpm_inst_code = cbp_inst_code
                   and cap_prod_code = cpm_prod_code
                   and cpm_profile_code = cbp_profile_code                   
                   AND    CBP_PARAM_NAME = 'Currency'
                  -- AND CAP_ACCT_NO=prm_card_no;
                   AND    CAP_PAN_CODE  =v_hash_pan ;*/ --prm_card_no;
                   
                   --Above query commented and this query added for the Performance issue - MVHOST-547 by Deepa T on 9th Jan 2014
                   /*SELECT TRIM (cbp_param_value) INTO v_card_curr                                    
                   FROM cms_bin_param
                   WHERE cbp_param_name = 'Currency'
                   AND (cbp_inst_code, cbp_profile_code) IN (                    
                   SELECT cpm_inst_code, cpm_profile_code
                   FROM cms_appl_pan, cms_prod_mast
                   WHERE cpm_inst_code = cap_inst_code
                   AND cap_prod_code = cpm_prod_code
                   AND cap_pan_code = v_hash_pan);
		   
                   
                  IF trim(v_card_curr) IS NULL THEN
                        v_errmsg := 'Card currency cannot be null ';
                        RAISE   exp_reject_record;
                  END IF;
                  prm_card_curr := v_card_curr    ;
        EXCEPTION
                WHEN OTHERS THEN
                v_errmsg := 'Error while selecting card currecy  ' || SUBSTR(SQLERRM,1,200);
                RAISE   exp_reject_record;
        END; */
       --En find the card curr
       
       BEGIN
       
       vmsfunutilities.get_currency_code(P_PROD_CODE,P_CARD_TYPE,prm_inst_code,v_card_curr,v_errmsg);
      
      IF v_errmsg <> 'OK' THEN 
      RAISE   exp_reject_record;
      END IF;
      
      
      prm_card_curr := v_card_curr;
      
      END;
      
        IF v_card_curr     <> prm_txn_curr THEN
        --Sn find the base currency
        BEGIN
                SELECT CIP_PARAM_VALUE
                INTO   v_base_curr
                FROM   CMS_INST_PARAM
                WHERE CIP_INST_CODE = prm_inst_code AND cip_param_key = 'CURRENCY';
                IF trim(v_base_curr) IS NULL THEN
                v_errmsg := 'Base currency cannot be null ';
                RAISE   exp_reject_record;
                END IF;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg := 'Base currency is not defined for the institution ';
                RAISE   exp_reject_record;
                WHEN OTHERS THEN
                v_errmsg := 'Error while selecting bese currecy  ' || SUBSTR(SQLERRM,1,200);
                RAISE   exp_reject_record;
        END;
        --En find the base currency

                v_tran_curr := prm_txn_curr;
        --Sn get the buying amt
                IF v_tran_curr <>  v_base_curr THEN
                        --Sn find the buying price
            BEGIN
                                SELECT pem_buying_rate
                                INTO   v_buying_rate
                                FROM   PCMS_EXCHANGERATE_MAST
                                WHERE PEM_INST_CODE = prm_inst_code and PEM_CURR_CODE = v_tran_curr
                                AND      TRUNC(PEM_ASOF_DATE) =    ( SELECT TRUNC( MAX(PEM_ASOF_DATE) ) FROM
                                      PCMS_EXCHANGERATE_MAST
                                WHERE PEM_INST_CODE = prm_inst_code and PEM_CURR_CODE = v_tran_curr) ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg := 'Buying rate is not defined for tran code  ' || v_tran_curr;
                RAISE   exp_reject_record;
                WHEN OTHERS THEN
                v_errmsg := 'Error while selecting buying rate  ' || SUBSTR(SQLERRM,1,200);
                RAISE   exp_reject_record;

            END;
                        --En find the buying price
                        v_txn_amt := prm_txn_amt * v_buying_rate;
            ELSE

              v_txn_amt := prm_txn_amt;
                 END IF;
        --En get the buying amt
        --Sn get the selling amt
                IF v_card_curr <>  v_base_curr THEN
                        --Sn find the buying price
            BEGIN
                                SELECT pem_selling_rate , pem_markup_perc
                                INTO   v_selling_rate , v_markup
                                FROM   PCMS_EXCHANGERATE_MAST
                                WHERE PEM_INST_CODE = prm_inst_code and PEM_CURR_CODE = v_card_curr
                                AND      TRUNC(PEM_ASOF_DATE) =   ( SELECT TRUNC( MAX(PEM_ASOF_DATE) ) FROM
                                      PCMS_EXCHANGERATE_MAST
                                WHERE PEM_INST_CODE = prm_inst_code and PEM_CURR_CODE = v_card_curr ) ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg := 'Buying rate is not defined for tran code  ' || v_tran_curr;
                RAISE   exp_reject_record;
                WHEN OTHERS THEN
                v_errmsg := 'Error while selecting selling rate  ' || SUBSTR(SQLERRM,1,200);
                RAISE   exp_reject_record;
            END;
                        --En find the buying price
                        v_txn_amt :=ROUND(((v_txn_amt / v_selling_rate))  + (( (v_txn_amt / v_selling_rate)  * v_markup ) / 100) ,2) ;
                END IF;
        --En get the selling amt
        ELSE
        v_txn_amt  := prm_txn_amt ;
        END IF;
        prm_act_amt :=  ROUND(v_txn_amt ,2);
EXCEPTION       --<< MAIN EXCEPTION >>
    WHEN exp_reject_record THEN
    prm_errmsg := v_errmsg;
    WHEN OTHERS THEN
    prm_errmsg := SUBSTR(SQLERRM,1,300);
END;            --<< MAIN END >>
/
show error