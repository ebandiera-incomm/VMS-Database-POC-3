CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Maintain_Branchstock

   ( prm_instcode IN NUMBER,
    prm_refno IN NUMBER,
	prm_req_stock IN NUMBER,
    prm_ins_user IN NUMBER,
    prm_stock OUT NUMBER,
    prm_errmsg OUT VARCHAR2
   )
AS
v_bran_code  CMS_BRANCH_STOCK.cbs_branch_code%TYPE;
v_check_branch  NUMBER;
v_product_code  VARCHAR2(6);
v_product_denomination VARCHAR2(10);
v_card_type  NUMBER(2);
v_current_stock  NUMBER (8);
BEGIN

  prm_errmsg := 'OK';

  --Sn check branch in  REQUEST_INVENTORY for the reference no

  BEGIN

   SELECT
			    cri_branch_code,
			    cri_product_code ,
			    cri_card_amount ,
			    cri_card_type

   INTO
			   v_bran_code,
			    v_product_code ,
			    v_product_denomination ,
			    v_card_type
   FROM CMS_REQUEST_INVENTORY
   WHERE CRI_INST_CODE =prm_instcode and cri_ref_no =  prm_refno;

  EXCEPTION

  WHEN NO_DATA_FOUND THEN
   prm_errmsg := 'Invalid reference number '|| prm_refno || ' no record found in request_inventorY';
   RETURN;

  WHEN TOO_MANY_ROWS THEN
   prm_errmsg := 'More than one record found in request_inventory for reference no' || prm_refno;
   RETURN;

  END;
  --En check branch in  REQUEST_INVENTORYfor the reference no;

  --Sn check branch in branch stock
  BEGIN

   SELECT 	 		cbs_card_stock
   INTO   				  v_current_stock
   FROM 				  CMS_BRANCH_STOCK
   WHERE CBS_INST_CODE=prm_instcode and cbs_branch_code = v_bran_code
    AND      CBS_PRODUCT_CODE = v_product_code
   AND      CBS_CARD_TYPE = v_card_type
   AND   CBS_CARD_DENOMINATION= v_product_denomination;

   v_current_stock := v_current_stock + prm_req_stock;

   UPDATE CMS_BRANCH_STOCK
   SET    cbs_card_stock = v_current_stock
   WHERE  CBS_INST_CODE=prm_instcode and cbs_branch_code = v_bran_code
   AND      CBS_PRODUCT_CODE = v_product_code
   AND      CBS_CARD_TYPE = v_card_type
   AND   CBS_CARD_DENOMINATION= v_product_denomination;


   IF SQL%rowcount = 0 THEN

   prm_errmsg := 'Problem while updating in Branch_stock'  ;
   RETURN;
   END IF;

   prm_stock := v_current_stock;





  EXCEPTION
   WHEN TOO_MANY_ROWS THEN
   prm_errmsg := 'More than one record found in branch_stock for branch code' || v_bran_code;
   RETURN;


   WHEN NO_DATA_FOUND THEN

    BEGIN

     INSERT INTO
     CMS_BRANCH_STOCK
     (CBS_INST_CODE,
     CBS_BRANCH_CODE,
     CBS_PRODUCT_CODE,
     CBS_CARD_TYPE,
     CBS_CARD_DENOMINATION,
     CBS_CARD_STOCK,
     CBS_CARD_REORDER,
     CBS_CARD_MAX,
     CBS_INS_USER,
     CBS_INS_DATE,
     CBS_LUPD_USER,
     CBS_LUPD_DATE
     )
     VALUES
     (
     prm_instcode,
     v_bran_code,
     v_product_code ,
     v_card_type,
     v_product_denomination,
     prm_req_stock,
     0,
     0,
     prm_ins_user,
     SYSDATE,
     prm_ins_user,
     SYSDATE
     );

     prm_stock := prm_req_stock;


    EXCEPTION
     WHEN OTHERS THEN

     prm_errmsg := 'Error while inserting records into BRANCH_STOCK'  ;
     RETURN;


    END;

  END;
  --En check branch in branch stock



END;
/
SHOW ERRORS

