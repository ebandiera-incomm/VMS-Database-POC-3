CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALCULATE_WAIVER
(
prm_inst_code                   NUMBER,
prm_pan_code                    VARCHAR2,
prm_mbr_numb                    VARCHAR2,
prm_prod_code                   VARCHAR2,
prm_card_type                   VARCHAR2,
prm_fee_code                    VARCHAR2,
prm_fee_plan                    VARCHAR2,
prm_tran_date                   DATE,--Added Deepa on Aug-23-2012 to calculate the waiver based on tran date
prm_waiv_percnt         OUT     VARCHAR2,
prm_err_msg             OUT     VARCHAR2
)
IS
v_rec_found     NUMBER(3);
v_waiv_percent  CMS_PRODCATTYPE_WAIV.cpw_waiv_prcnt%TYPE;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;   
 v_tran_date    DATE;

/*************************************************
      * Modified By      :  Deepa T
     * Modified Date    :  23-Aug-2012
     * Modified Reason  : Added in Parameter 
      * Reviewer        : B.Besky Anand  
     * Reviewed Date    : 27-Aug-2012  
     * Build Number     :  CMS3.5.1_RI0015_B0007

 *************************************************/

 
  
  
BEGIN
         prm_err_msg := 'OK';
         v_tran_date:=trunc(prm_tran_date);
         --SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_pan_code);
EXCEPTION
WHEN OTHERS THEN
PRM_ERR_MSG:= 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
         RETURN;
END;
--EN CREATE HASH PAN

        --Sn find feecode attached to card
                BEGIN
                SELECT  TRIM(CCE_WAIV_PRCNT)
                INTO    v_waiv_percent
                FROM    CMS_CARD_EXCPWAIV
                WHERE   CCE_INST_CODE = prm_inst_code
                AND     CCE_PAN_CODE  = v_hash_pan --prm_pan_code
                AND     CCE_MBR_NUMB  = prm_mbr_numb
                AND     CCE_FEE_CODE  = prm_fee_code
                AND     CCE_FEE_PLAN  = prm_fee_plan
                --AND     SYSDATE BETWEEN CCE_VALID_FROM AND CCE_VALID_TO
                AND ((CCE_VALID_TO IS NOT NULL AND (v_tran_date between cce_valid_from and CCE_VALID_TO))--Modified by Deepa on Aug-23-2012 to calculate the waiver based on tran date 
                        OR (CCE_VALID_TO IS NULL AND v_tran_date >= cce_valid_from));
                prm_waiv_percnt := v_waiv_percent;
                EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                                    --Sn find feecode attached to Product
                BEGIN
                         SELECT  TRIM(CPW_WAIV_PRCNT)
                         INTO    v_waiv_percent
                         FROM    CMS_PRODCATTYPE_WAIV
                         WHERE   cpw_inst_code = prm_inst_code
                         AND     cpw_prod_code = prm_prod_code
                         AND     cpw_card_type = prm_card_type
                         AND     cpw_fee_code  = prm_fee_code
                         AND     CPW_FEE_PLAN = prm_fee_plan
                         --AND     SYSDATE BETWEEN CPW_VALID_FROM AND CPW_VALID_TO;
                         AND ((CPW_VALID_TO IS NOT NULL AND (v_tran_date between CPW_VALID_FROM and CPW_VALID_TO))--Modified by Deepa on Aug-23-2012 to calculate the waiver based on tran date
                                OR (CPW_VALID_TO IS NULL AND v_tran_date >= CPW_VALID_FROM));
                          prm_waiv_percnt := v_waiv_percent;
                EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        --Added by Deepa on june 9 2012 as the product waiver details are not checked
                        BEGIN
                                                    
                            SELECT cpw_waiv_prcnt
                            INTO v_waiv_percent
                            FROM cms_prod_waiv
                            WHERE cpw_inst_code = prm_inst_code
                            AND cpw_prod_code = prm_prod_code
                            AND cpw_fee_code = prm_fee_code
                            AND CPW_FEE_PLAN = prm_fee_plan
                            --AND SYSDATE BETWEEN CPW_VALID_FROM AND CPW_VALID_TO;
                            AND ((CPW_VALID_TO IS NOT NULL AND (v_tran_date between CPW_VALID_FROM and CPW_VALID_TO))--Modified by Deepa on Aug-23-2012 to calculate the waiver based on tran date
                                OR (CPW_VALID_TO IS NULL AND v_tran_date >= CPW_VALID_FROM));                                                   
                                                    
                            prm_waiv_percnt := v_waiv_percent;
                        EXCEPTION    
                        WHEN NO_DATA_FOUND THEN
                        PRM_ERR_MSG := 'OK';
                        v_waiv_percent := 0;
                        prm_waiv_percnt := v_waiv_percent;
                        WHEN OTHERS THEN
                        PRM_ERR_MSG := 'Error while selecting waiver percent from card' || SUBSTR(SQLERRM,1,200);
                        RETURN;
                        END; 
                                                
                        WHEN OTHERS THEN
                        PRM_ERR_MSG := 'Error while selecting waiver percent from card type ' || SUBSTR(SQLERRM,1,200);
                        RETURN;
                END;
                                        --En find feecode attached to Product
                        WHEN OTHERS THEN
                                PRM_ERR_MSG := 'Error while selecting waiver percent from card type ' || SUBSTR(SQLERRM,1,200);
                                RETURN;
                END;
         --En find feecode attached to card
EXCEPTION
        WHEN OTHERS THEN
         PRM_ERR_MSG := 'Error from main ' || SUBSTR(SQLERRM,1,200);
END;
/
SHOW ERROR;