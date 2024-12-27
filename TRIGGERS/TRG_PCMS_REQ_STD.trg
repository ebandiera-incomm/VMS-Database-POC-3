CREATE OR REPLACE TRIGGER VMSCMS.TRG_PCMS_REQ_STD
BEFORE UPDATE
ON VMSCMS.PCMS_REQUISITION REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
v_is_approved   CHAR(1);
v_bran_code VARCHAR2(6);
v_prod_code CMS_PROD_CATTYPE.CPC_PROD_CODE%TYPE;
v_var_flag VARCHAR2(1) := 'F';
v_card_type NUMBER(3);
v_denom CMS_CUST_CATG.ccc_catg_code%TYPE;
v_prod_sname VARCHAR2(30);
v_inst_code NUMBER(3);
dum NUMBER(2);
BEGIN --Trigger body begins
IF UPDATING THEN
--dbms_output.put_line('Pt 0 <'||:NEW.IS_APPROVED||'>');
     v_is_approved := :NEW.IS_APPROVED;
  IF v_is_approved = 'Y' THEN
 v_prod_code := :OLD.PRODUCT_CODE;
 v_bran_code := :OLD.LOC_CODE;
--    dbms_output.put_line(v_prod_code || v_bran_code);
    SELECT cpm_inst_code,cpm_var_flag INTO v_inst_code,v_var_flag
    FROM CMS_PROD_MAST
    WHERE cpm_prod_code = v_prod_code;
    IF v_var_flag = 'V' THEN
 v_denom := 10;
    ELSE
 SELECT ccc_catg_code
 INTO v_denom
 FROM CMS_PROD_CCC,
  CMS_CUST_CATG,
  CMS_PROD_CATTYPE
 WHERE CPC_CUST_CATG = CCC_CATG_CODE
 AND CMS_PROD_CCC.cpc_prod_code = CMS_PROD_CATTYPE.cpc_prod_code
 AND CMS_PROD_CATTYPE.cpc_prod_code =  v_prod_code
 AND CMS_PROD_CCC.cpc_card_type = CMS_PROD_CATTYPE.cpc_card_type
 AND cpc_cardtype_sname = :OLD.CARD_TYPE
 AND CCC_CATG_SNAME = :OLD.AMOUNT;
    END IF;
    SELECT cpc_prod_sname
    INTO v_prod_sname
    FROM CMS_PROD_CCC
    WHERE cpc_prod_code = v_prod_code
    AND  cpc_card_type =
  (SELECT cpc_card_type
  FROM CMS_PROD_CATTYPE
  WHERE cpc_prod_code = v_prod_code
  AND cpc_cardtype_sname = :OLD.CARD_TYPE)
    AND  cpc_cust_catg = v_denom;
    SELECT COUNT(1)
    INTO dum
    FROM CMS_BRANPROD_STOCK
    WHERE cbs_prod_sname = v_prod_sname
    AND  cbs_bran_code = v_bran_code;
    IF  dum = 1 THEN
 UPDATE CMS_BRANPROD_STOCK
 SET cbs_stock = cbs_stock + :NEW.APPR_NO_OF_CARDS
 WHERE cbs_prod_sname = v_prod_sname
 AND cbs_bran_code = v_bran_code;
    ELSE
 INSERT INTO CMS_BRANPROD_STOCK(
  CBS_INST_CODE,
  CBS_PROD_SNAME,
  CBS_BRAN_CODE,
  CBS_STOCK)
 VALUES( v_inst_code,
  v_prod_sname,
  v_bran_code,
  :NEW.APPR_NO_OF_CARDS);
     END IF;
   END IF;
END IF;
END; --Trigger body ends
/


