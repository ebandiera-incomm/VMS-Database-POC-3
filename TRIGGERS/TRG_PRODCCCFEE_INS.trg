CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCCCFEE_INS
AFTER INSERT
ON VMSCMS.CMS_PROD_CCC 
FOR EACH ROW
DISABLE
DECLARE
 CURSOR c1 IS
 SELECT cpf_fee_code,cpf_valid_to,cpf_valid_from
 FROM cms_prod_fees
 WHERE cpf_inst_code = :new.cpc_inst_code
 AND  cpf_prod_code  = :new.cpc_prod_code;
BEGIN --main begin
 FOR x IN c1
 LOOP
 insert into cms_prodccc_fees
   (CPF_INST_CODE,
   CPF_CUST_CATG,
   CPF_CARD_TYPE,
   CPF_PROD_CODE,
   CPF_FEE_CODE,
   CPF_VALID_FROM,
   CPF_VALID_TO,
   CPF_FLOW_SOURCE,
   CPF_INS_USER,
   CPF_LUPD_USER
   )
   values
   (:new.cpc_inst_code,
    :new.cpc_cust_catg,
    :new.CPc_CARD_TYPE,
    :new.CPc_PROD_CODE,
    x.CPF_FEE_CODE ,
    x.CPF_VALID_FROM,
    x.CPF_VALID_TO ,
    'P',
    :new.CPC_INS_USER,
    :new.CPC_INS_USER
   );
 EXIT WHEN c1%NOTFOUND;
 END LOOP;
END; --main end
/


