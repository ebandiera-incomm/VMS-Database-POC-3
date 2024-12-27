CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHECK_CARDTYPE
  (
  prm_instcode IN  NUMBER,
  prm_prod_code IN  VARCHAR2,
  prm_card_type IN  VARCHAR2,
  prm_cardtype_code OUT VARCHAR2,
  prm_err_msg OUT  VARCHAR2
  )
IS
v_cardtype NUMBER(2);
BEGIN
 prm_err_msg := 'OK';
 SELECT CPC_CARD_TYPE
 INTO   prm_cardtype_code
 FROM CMS_PROD_CATTYPE
 WHERE cpc_inst_code  = prm_instcode
 AND cpc_prod_code  = prm_prod_code
 AND cpc_cardtype_desc = prm_card_type;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 prm_err_msg := 'Card type detail  not defined in master';
 when others then
 prm_err_msg := 'Error while selecting card type details' || substr(sqlerrm,1,200);
END;
/
SHOW ERROR