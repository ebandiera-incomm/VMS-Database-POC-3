CREATE OR REPLACE PROCEDURE VMSCMS.SP_TRAN_FEES
(
prm_inst_code       IN      NUMBER,
PRM_CARD_NUMBER        IN        VARCHAR2,
PRM_DEL_CHANNEL        IN        VARCHAR2,
PRM_TRAN_TYPE        IN        VARCHAR2,    -- FIN/NON FIN TRAN
PRM_TRAN_MODE        IN        VARCHAR2,    -- ONUS/OFFUS
PRM_TRAN_CODE        IN        VARCHAR2,
PRM_CURRENCY_CODE    IN        VARCHAR2,
PRM_CONSODIUM_CODE IN        VARCHAR2,
PRM_PARTNER_CODE      IN        VARCHAR2,
PRM_TRN_AMT        IN        NUMBER,
PRM_TRAN_FEE        OUT        NUMBER,
PRM_ERROR        OUT        VARCHAR2,
PRM_FEE_CODE        OUT        NUMBER     ,    --   To Return  FEE_CODE
prm_crgl_catg           OUT             VARCHAR2,
prm_crgl_code           OUT             VARCHAR2,
prm_crsubgl_code        OUT             VARCHAR2,
prm_cracct_no           OUT             VARCHAR2,
prm_drgl_catg           OUT             VARCHAR2,
prm_drgl_code           OUT             VARCHAR2,
prm_drsubgl_code        OUT             VARCHAR2,
prm_dracct_no           OUT             VARCHAR2,
prm_st_calc_flag                   OUT            VARCHAR2,
prm_cess_calc_flag               OUT               VARCHAR2    ,
prm_st_cracct_no                  OUT       VARCHAR2,
prm_st_dracct_no                   OUT               VARCHAR2,
prm_cess_cracct_no                OUT                VARCHAR2,
prm_cess_dracct_no                OUT               VARCHAR2
)
IS
/**********************************************************************************************************************
      * Modified By      :  Trivikram
      * Modified Date    :  27-July-2012
      * Modified Reason  :  logging fee for free transactions 
       * Reviewer         :  B.Besky Anand.
      * Reviewed Date    :  29-July-2012
      * Release Number     :CMS3.5.1_RI0012_B0022
***********************************************************************************************************************/
exp_main     EXCEPTION        ;
exp_nofees     EXCEPTION;
v_consodium_code NUMBER(3)         ; -- hardcoded temporary
v_partner_code   NUMBER(3)     ; -- hardcoded temporary
v_inst_code    CMS_FEE_MAST.cfm_inst_code%TYPE        ;
v_fee_code    CMS_FEE_MAST.cfm_fee_code%TYPE        ;
v_fee_type    CMS_FEE_MAST.cfm_feetype_code%TYPE    ;
v_flat_fee    CMS_FEE_MAST.cfm_fee_amt%TYPE        ;
v_per_fees    CMS_FEE_MAST.cfm_per_fees%TYPE        ;
v_min_fees    CMS_FEE_MAST.cfm_min_fees%TYPE        ;
v_prod_code    CMS_APPL_PAN.cap_prod_code%TYPE        ;
v_card_type    CMS_APPL_PAN.cap_card_type%TYPE        ;
v_card_fee    CMS_FEE_MAST.cfm_fee_amt%TYPE        ;
v_prod_fee    CMS_FEE_MAST.cfm_fee_amt%TYPE        ;
v_feeattach_flag                                        NUMBER;
v_err_waiv                                        VARCHAR2(300);
v_feeattach_type                                VARCHAR2(1);
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 
--Added as the parameter changes by Deepa on June 21 2012
V_fee_attach        NUMBER;
V_feeamnt_type      VARCHAR2(1);
V_clawback          VARCHAR2(1);
V_fee_plan          NUMBER;
V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions

  
  
BEGIN
    prm_error := 'OK'    ;
    /* TO GET CONSODIUM CODE AND PARTNER CODE, SEARCH CONSODIUM CODE
    FROM CMS_CONST_MAST BASED ON CARD_FIID (AFTER CONFIRMATION)
    AND BASED ON CONSD. CODE SERACH FOR PARTNER CODE FROM CMS_PARTACQ_MAST
    */
  
  --SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(PRM_CARD_NUMBER);
EXCEPTION
WHEN OTHERS THEN
prm_error := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
        RAISE exp_main;
END;
--EN CREATE HASH PAN

 

    ---------------------------------------------
    -- SN: TO GET PRO CODE AND TYPE CMS_APPL_PAN
    ---------------------------------------------
    BEGIN -- PAN DATE
            SELECT cap_prod_code, cap_card_type
            INTO   v_prod_code, v_card_type
            FROM CMS_APPL_PAN
            WHERE CAP_INST_CODE =prm_inst_code AND cap_pan_code = v_hash_pan --prm_card_number
            ;
    EXCEPTION 
        WHEN OTHERS THEN
            prm_error := 'ERROR FROM PAN DATA SECTION =>' || SQLERRM    ;
            RAISE exp_main;
    END ;

    Sp_Tran_Fees_Card
    (prm_inst_code,
    prm_card_number        ,
    prm_del_channel        ,
    prm_tran_type        ,
    prm_tran_mode        ,
    prm_tran_code        ,
    prm_currency_code    ,
    prm_trn_amt        ,
    prm_consodium_code    ,
    prm_partner_code    ,
    sysdate, --added issuance date for FEE check, Incase of transaction this date will be transaction orgination date. -- 21-Feb-2011
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    v_fee_code        ,
    v_flat_fee        ,
    v_per_fees        ,
    v_min_fees        ,
    V_fee_attach ,
    V_feeamnt_type , 
    V_clawback ,  
    V_fee_plan,
    v_feeattach_flag        ,
    prm_error        ,
    prm_crgl_catg        ,
    prm_crgl_code        ,
    prm_crsubgl_code    ,
    prm_cracct_no        ,
    prm_drgl_catg        ,
    prm_drgl_code        ,
    prm_drsubgl_code    ,
    prm_dracct_no    ,
    prm_st_calc_flag,
    prm_cess_calc_flag,
    prm_st_cracct_no,
    prm_st_dracct_no,
    prm_cess_cracct_no,
    prm_cess_dracct_no,
    V_FREETXN_EXCEED, -- Added by Trivikra on 26-July-2012
    V_DURATION -- Added by Trivikram for logging fee of free transaction
    );
IF         v_feeattach_flag  =  -1 THEN
--Error from tran_fees_card procedure
PRM_ERROR := 'Error from fee attach  card proc  ' || prm_error;
RETURN;
END IF;
    IF v_feeattach_flag = 1 THEN
        prm_error := 'OK'    ;
        v_feeattach_type := 'C';
        --prm_fee_attach_type := v_feeattach_type;
    ELSE
        IF v_feeattach_flag = 0 THEN
             Sp_Tran_Fees_Product
            (prm_inst_code,
            PRM_DEL_CHANNEL        ,
            PRM_TRAN_TYPE        ,
            PRM_TRAN_MODE        ,
            PRM_TRAN_CODE        ,
            PRM_CURRENCY_CODE    ,
            PRM_TRN_AMT        ,
            V_PROD_CODE        ,
            V_CARD_TYPE        ,
            prm_consodium_code    ,
            prm_partner_code    ,
            sysdate, --added issuance date for FEE check, Incase of transaction this date will be transaction orgination date. -- 21-Feb-2011
            V_FEE_CODE        ,
            V_FLAT_FEE        ,
            V_PER_FEES        ,
            V_MIN_FEES        ,
            v_feeattach_flag        ,
            prm_error        ,
            prm_crgl_catg        ,
            prm_crgl_code        ,
            prm_crsubgl_code    ,
            prm_cracct_no        ,
            prm_drgl_catg        ,
            prm_drgl_code        ,
            prm_drsubgl_code    ,
            prm_dracct_no     ,
            prm_st_calc_flag,
            prm_cess_calc_flag,
            prm_st_cracct_no,
            prm_st_dracct_no,
            prm_cess_cracct_no,
            prm_cess_dracct_no
            );

            IF         v_feeattach_flag  =  -1 THEN
            --Error from tran_fees_card procedure
            PRM_ERROR := 'Error from fee attach  prod cattype proc   ' || prm_error;
                RETURN;
           END IF;
            IF v_feeattach_flag = 1 THEN
                v_feeattach_type := 'P';
                prm_error := 'OK'    ;
            ELSE
                IF v_feeattach_flag = 0 THEN
                    prm_error := 'NO FEES ATTACHED'    ;
                    RAISE exp_nofees; -- NO FEES ATTACHED RETURN -1
                ELSE
                    RAISE exp_main;        -- Error from  Procedure
                END IF;
            END IF;
        ELSE
        RAISE exp_main;
        END IF;
    END IF;
        IF v_per_fees IS NOT NULL AND v_per_fees <> 0 THEN
            prm_tran_fee := prm_trn_amt * (v_per_fees / 100)    ;
            prm_tran_fee := prm_tran_fee + v_flat_fee        ;
            IF prm_tran_fee < v_min_fees THEN
                prm_tran_fee := v_min_fees    ;
            END IF;
        ELSE
            prm_tran_fee := v_flat_fee    ;
        END IF;

   PRM_FEE_CODE := V_FEE_CODE;          
EXCEPTION -- MAIN
    WHEN exp_nofees    THEN
        prm_error := 'OK';
        prm_tran_fee := 0 ;
        WHEN exp_main THEN
        prm_error    := prm_error    ;
        prm_tran_fee    := -1    ;
    WHEN OTHERS THEN
        prm_error    := SQLERRM    ;
        prm_tran_fee    := -1    ;
END;
/
SHOW ERROR;