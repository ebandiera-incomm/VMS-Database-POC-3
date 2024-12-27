CREATE OR REPLACE PROCEDURE VMSCMS.SP_SET_BRANCH(
PRM_INSTCODE	IN NUMBER,
PRM_BRANCODE	IN VARCHAR2,
PRM_LUPDUSER	IN NUMBER,
PRM_ERRMSG		OUT VARCHAR2
)
AS
v_autoinsert_check CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
BEGIN
PRM_ERRMSG:='OK';
	BEGIN
		SELECT CIP_PARAM_VALUE
		INTO   v_autoinsert_check
		FROM   CMS_INST_PARAM
		WHERE  CIP_INST_CODE = PRM_INSTCODE
		AND    CIP_PARAM_KEY = 'ADD AUTO BRANCH';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_autoinsert_check := 'N';
    WHEN OTHERS THEN
			PRM_ERRMSG := 'Error while selecting data from inst param' || SUBSTR(SQLERRM,1,200);
			RETURN;
	END;

	IF v_autoinsert_check='Y' then
		sp_create_branch(
				   PRM_INSTCODE,           
				   null,       
				   null,       
				   null,        
				   PRM_BRANCODE,        
				   PRM_BRANCODE,            
				   null,          
				   'India',         
				   'ICICI bank,Lower Parel(E),Mumbai',           
				   null,           
				   null,           
				   '400013',         
				   '284569024',          
				   null,          
				   null,          
				   'Mr. Ajay Gadiya',        
				   null,           
				   null,           
				   '1',        
				   null,        
				   null,   
				   null,  
				   null,
				   null,      
				   null,      
				   null,        
				   null,     
				   '1',       
				   null,      
				   PRM_LUPDUSER,        
				   PRM_ERRMSG      
				);

		IF PRM_ERRMSG <> 'OK' then 
			PRM_ERRMSG:='Error from creating branch '||substr(sqlerrm,1,200);
			RETURN;
		END IF;
	ELSE
		PRM_ERRMSG:='Auto branch addition not available.';
		RETURN;
	END IF;
EXCEPTION 
	WHEN OTHERS THEN
	PRM_ERRMSG:='Error while creating the Branch '|| substr(sqlerrm,1,200);
	RETURN;
END;
/
SHOW ERRORS

