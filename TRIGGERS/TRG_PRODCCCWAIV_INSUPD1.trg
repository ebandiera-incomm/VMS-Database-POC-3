CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcccwaiv_insupd1
	BEFORE INSERT OR UPDATE
		ON cms_prodccc_waiv
			FOR EACH ROW
DECLARE
err number(1) ;
CURSOR c1 IS
SELECT	cpf_valid_from,cpf_valid_to
FROM	cms_prodccc_fees
WHERE	cpf_inst_code		=	:new.cpw_inst_code
AND		cpf_fee_code		=	:new.cpw_fee_code
AND		cpf_prod_code	=	:new.cpw_prod_code
AND		cpf_card_type		=	:new.cpw_card_type
AND		cpf_cust_catg		=	:new.cpw_cust_catg	;

BEGIN	--trigger body begins
	FOR x IN c1
	LOOP
		IF err = 0 THEN
		EXIT;
		END IF;
		IF (trunc(:new.cpw_valid_from) >= trunc(x.cpf_valid_from) AND trunc(:new.cpw_valid_from)<=trunc(x.cpf_valid_to)       AND      trunc(:new.cpw_valid_to) >=  trunc(x.cpf_valid_from) AND trunc(:new.cpw_valid_to) <= trunc(x.cpf_valid_to)) THEN
			err := 0;
		ELSE
			err := 1;
		END IF;
	EXIT WHEN c1%NOTFOUND;
	END LOOP;

	IF err = 1 THEN
		RAISE_APPLICATION_ERROR(-20001,'Waiver dates have to be within or equal to Fee daterange.');
	END IF;
END;	--trigger body ends
/


