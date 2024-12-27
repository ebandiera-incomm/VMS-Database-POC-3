CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Calc_Fees_Offline_Debit
							(prm_inst_code	 	IN	NUMBER,
							 prm_card_number	IN	VARCHAR2,
							 prm_tran_code		IN	VARCHAR2,
							 prm_tran_mode		IN	VARCHAR2,
							 prm_delv_chnl		IN	VARCHAR2,
							 prm_tran_type		IN	VARCHAR2,
							 prm_feetype_code	OUT VARCHAR2,
							 prm_fee_code		OUT	VARCHAR2,
							 prm_fee_amt		OUT	VARCHAR2,
							 prm_err_msg		OUT     VARCHAR2
							 )
IS
v_prod_code		CMS_APPL_PAN.cap_prod_code%TYPE;
v_card_type		CMS_APPL_PAN.cap_card_type%TYPE;
 v_hash_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  

 
BEGIN						--<< MAIN BEGIN >>
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_card_number);
EXCEPTION
WHEN OTHERS THEN
PRM_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RETURN;
END;
--EN CREATE HASH PAN

    --Sn find product code and card type
        BEGIN
            SELECT     cap_prod_code,
                cap_card_type
            INTO    v_prod_code,
                v_card_type
            FROM     CMS_APPL_PAN
            WHERE     cap_pan_code = v_hash_pan;--prm_card_number;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            PRM_ERR_MSG := 'Card number not found in master';
            RETURN;
            WHEN OTHERS THEN
            PRM_ERR_MSG := 'Error while selecting card detail from master';
            RETURN;
        END;
    --En find product code and card type
    --Sn check fee attached to card 
 prm_err_msg := 'OK';
        BEGIN
                    SELECT    cfm_fee_amt,cfm_feetype_code,cfm_fee_code
                    INTO    prm_fee_amt,prm_feetype_code,prm_fee_code
                    FROM    CMS_FEE_MAST, CMS_CARD_EXCPFEE
                    WHERE    CFM_INST_CODE        =    prm_inst_code 
                    AND    CFM_INST_CODE        =    CCE_INST_CODE 
                    AND    cce_pan_code        =    v_hash_pan--prm_card_number
                    AND    SYSDATE            BETWEEN cce_valid_from AND cce_valid_to
                    AND    cfm_fee_code        =    cce_fee_code
                    AND    cfm_delivery_channel    =    prm_delv_chnl
                    AND    cfm_tran_type        =    prm_tran_type
                    AND    cfm_tran_code        =    prm_tran_code
                    AND    cfm_tran_mode        =    prm_tran_mode
                    AND    cfm_consodium_code    IS NULL
                    AND    cfm_partner_code    IS NULL
                    AND    cfm_currency_code    IS NULL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    --Sn check fee attached from product and cardtype
                        BEGIN
                            SELECT        cfm_fee_amt,cfm_feetype_code,cfm_fee_code
                            INTO        prm_fee_amt,prm_feetype_code,prm_fee_code
                            FROM        CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
                            WHERE        CFM_INST_CODE        = prm_inst_code 
                            AND        CFM_INST_CODE        = CPF_INST_CODE 
                            AND        cpf_prod_code        = v_prod_code
                            AND        cpf_card_type        = v_card_type
                            AND        SYSDATE BETWEEN cpf_valid_from AND cpf_valid_to
                            AND        cfm_fee_code        = cpf_fee_code
                            AND        cfm_delivery_channel    = prm_delv_chnl
                            AND        cfm_tran_type        = prm_tran_type
                            AND        cfm_tran_code        = prm_tran_code
                            AND        cfm_tran_mode        = prm_tran_mode
                            AND        cfm_currency_code    IS NULL
                            AND        cfm_consodium_code    IS NULL
                            AND        cfm_partner_code    IS NULL;
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                            prm_fee_amt := 0;
                            WHEN OTHERS THEN
                            PRM_ERR_MSG := 'Error while selecting data from product category wise fees';
                            RETURN;
                        END;
                    --En check fee attached from product and cardtype
            WHEN OTHERS THEN
                            PRM_ERR_MSG := 'Error while selecting data from card wise fees';
                            RETURN;
        END;
    --En check fee attached to card
EXCEPTION                    --<< MAIN EXCEPTION>>
    WHEN OTHERS THEN
    PRM_ERR_MSG := 'Error while selecting data from main';
    RETURN;
END;                        --<< MAIN END >>
/


show error