CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Upload_Exchangerate_Mast(
    	  		  			instcode IN	NUMBER		,
							lupduser IN	NUMBER		,
							errmsg	OUT	VARCHAR2	)
AS
dum 				NUMBER;
v_errmsg			VARCHAR2(350) := 'OK';
exp_reject_record	EXCEPTION;     -- Sn exception declaration
v_transaction       NUMBER (12) DEFAULT 1; 

 /*
  * VERSION               :  1.0
  * DATE OF CREATION      : 12/Sep/2008
  * CREATED BY            : Ashutosh Deo.
  * PURPOSE               : Upload data to exchangerate master table
  * MODIFICATION REASON   :
  *
  *
  * LAST MODIFICATION DONE BY :
  * LAST MODIFICATION DATE    :
  *
***/

CURSOR  c1 IS SELECT 
				PEM_CURR_CODE, 
				PEM_SELLING_RATE, 
				PEM_BUYING_RATE, 
				PEM_MARKUP_PERC, 
				PEM_NUMOF_DECI, 
				PEM_SUCC_FLAG,
				PEM_ASOF_DATE,
				ROWID row_id
				FROM
				PCMS_EXCHANGERATE_MAST_TEMP
				WHERE PEM_INST_CODE =instcode  
				and PEM_SUCC_FLAG = 'N';


-----------*****************************************************************************---------

BEGIN	 --Sn main begin
errmsg	 	 := 'OK';

	FOR x IN c1  
	LOOP  	 	 -- Sn Cursor C1
	v_errmsg := 'OK';    -- SN SET ERROR MESSAGE TO 'OK'  
---$$$$$$$$$$$$$$$$$$$$$ begin 1 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 
	
	  BEGIN		--Sn begin 1	  
		SAVEPOINT v_transaction;
	
		BEGIN  -- Sn Check for currency code in currency master
			SELECT 1
		   		   INTO dum
			FROM   GEN_CURR_MAST
			WHERE  GCM_INST_CODE =instcode  and GCM_CURR_CODE = x.PEM_CURR_CODE;
		EXCEPTION	
		WHEN NO_DATA_FOUND THEN
		v_errmsg	 := 'Currency code '||x.PEM_CURR_CODE||' not Defined in Currency master.';
		RAISE exp_reject_record;
		WHEN OTHERS THEN
		v_errmsg	 := 'Error while selecting Currency from Currency master. '|| SUBSTR(SQLERRM,1,300);
		RAISE exp_reject_record;
		END;  -- En Check for currency code in currency master					
		
		BEGIN     -- Sn Check for duplicate currency code in exchangerate master temp
		   SELECT 1
		   		  INTO   dum
		   FROM   PCMS_EXCHANGERATE_MAST_TEMP
		   WHERE PEM_INST_CODE =instcode  and PEM_CURR_CODE = x.PEM_CURR_CODE
		   AND    PEM_ASOF_DATE = x.PEM_ASOF_DATE;
		EXCEPTION	
		WHEN TOO_MANY_ROWS THEN
		v_errmsg	 := 'Multiple records present for Currency code '||x.PEM_CURR_CODE||' in exchangerate master temp.';
		RAISE exp_reject_record;
		WHEN OTHERS THEN
		v_errmsg	 := 'Error while selecting Currency code from exchangerate master temp. '|| SUBSTR(SQLERRM,1,300);
		RAISE exp_reject_record;
		END;     -- En Check for duplicate currency code in exchangerate master temp
		
		BEGIN   -- Sn Check for record if it already exists in exchangerate master
		   SELECT COUNT(ROWID)
		   		  INTO   dum
		   FROM   PCMS_EXCHANGERATE_MAST
		   WHERE PEM_INST_CODE =instcode  and PEM_CURR_CODE = x.PEM_CURR_CODE
		   AND    PEM_ASOF_DATE = x.PEM_ASOF_DATE;
		   
		     -- Sn if Record already present then update
		   IF dum = 1 THEN
		   	  UPDATE PCMS_EXCHANGERATE_MAST
			  SET 	 PEM_SELLING_RATE =  x.PEM_SELLING_RATE, 
			  	  	 PEM_BUYING_RATE  =  x.PEM_BUYING_RATE, 
			  	  	 PEM_MARKUP_PERC  =  x.PEM_MARKUP_PERC, 
			  	  	 PEM_NUMOF_DECI   =  x.PEM_NUMOF_DECI,
					 PEM_LUPD_USER	  =  lupduser
			  WHERE PEM_INST_CODE=instcode  and PEM_CURR_CODE 	  =  x.PEM_CURR_CODE
		      AND    PEM_ASOF_DATE 	  =  x.PEM_ASOF_DATE;
		      -- En if Record already present then update
		   ELSIF dum > 1 THEN    -- Sn if Multiple Record present then error
			   v_errmsg	 := 'Multiple records present for Currency code '||x.PEM_CURR_CODE||' and Date '||x.PEM_ASOF_DATE||' in exchangerate master.';
			   RAISE exp_reject_record; 
		  
		   ELSE		   	   
			   BEGIN	-- Sn now insert the records in exchangerate master
				INSERT INTO PCMS_EXCHANGERATE_MAST
					(
					PEM_CURR_CODE, 
					PEM_SELLING_RATE, 
					PEM_BUYING_RATE, 
					PEM_MARKUP_PERC, 
					PEM_NUMOF_DECI, 
					PEM_ASOF_DATE, 
					PEM_INS_DATE, 
					PEM_INS_USER, 
					PEM_LUPD_DATE, 
					PEM_LUPD_USER,
					PEM_INST_CODE
					)
					VALUES
					(
					x.PEM_CURR_CODE, 
					x.PEM_SELLING_RATE, 
					x.PEM_BUYING_RATE, 
					x.PEM_MARKUP_PERC, 
					x.PEM_NUMOF_DECI, 
					x.PEM_ASOF_DATE,
					SYSDATE,
					lupduser,
					SYSDATE,
					lupduser,
					instcode
					);	
				 EXCEPTION
				 WHEN OTHERS THEN
				 v_errmsg	 := 'Error while inserting in exchangerate master. '|| SUBSTR(SQLERRM,1,300);
				 RAISE exp_reject_record;
				 END;	-- En now insert the records in exchangerate master					   
		   END IF; -- end of if dum = 1		  		  
		   
		EXCEPTION	
		WHEN exp_reject_record THEN
		RAISE;
		WHEN OTHERS THEN
		v_errmsg	 := 'Error while selecting Currency code from exchangerate master. '|| SUBSTR(SQLERRM,1,300);
		RAISE exp_reject_record;
		END;  -- En Check for record if it already exists in exchangerate master
			
					
		 
		 	 -- Sn mark successful records as 'S' and SUCCESSFUL FLAG = 'Y'
		  IF v_errmsg = 'OK' THEN
			  UPDATE PCMS_EXCHANGERATE_MAST_TEMP
			  SET PEM_ERROR_MESSAGE = 	'Successful',
			  	  PEM_SUCC_FLAG 	= 	'Y'
			  WHERE PEM_INST_CODE=instcode and ROWID = x.row_id;
		  END IF;
		  	  -- En mark successful records as 'S' and SUCCESSFUL FLAG = 'Y'
			   
			  --Sn Now mark Error records and SUCCESSFUL FLAG = 'E' 					
	  EXCEPTION	--En excp of begin 1
	  WHEN exp_reject_record THEN
	  ROLLBACK TO SAVEPOINT v_transaction;
		  
		  UPDATE PCMS_EXCHANGERATE_MAST_TEMP
		  SET PEM_ERROR_MESSAGE = v_errmsg,
		  	  PEM_SUCC_FLAG 	= 	'E'
		  WHERE PEM_INST_CODE=instcode and ROWID = x.row_id;		  
	  WHEN OTHERS THEN
	  ROLLBACK TO SAVEPOINT v_transaction;
	  v_errmsg := 'Exception from main begin '|| SUBSTR(SQLERRM,1,200);
	  
	  	  UPDATE PCMS_EXCHANGERATE_MAST_TEMP
		  SET PEM_ERROR_MESSAGE = v_errmsg,
		  	  PEM_SUCC_FLAG 	= 	'E'
		  WHERE ROWID = x.row_id;		  
	  END ;		--En end of begin 1 
	  	   --En Now mark Error records and SUCCESSFUL FLAG = 'E' 
---$$$$$$$$$$$$$$$$$$$$$ begin 1 ends $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

 	  v_transaction := v_transaction + 1; 
  	  v_errmsg	 := 'OK';		 -- SN SET ERROR MESSAGE TO 'OK' 	  	 
		 			
	END LOOP;  -- En Loop for Cursor C1 ends	
		
		errmsg := v_errmsg;   -- SN SET THE ERROR MESSAGE 
		
--*********************************************************************************	
EXCEPTION	--En excp of main
WHEN OTHERS THEN
errmsg := 'Error From main '|| SUBSTR(SQLERRM,1,200);
END;		--En end of main
/


SHOW ERRORS