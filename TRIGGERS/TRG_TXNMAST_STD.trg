create or replace
TRIGGER vmscms.trg_txnmast_std
   BEFORE INSERT OR UPDATE OR DELETE
   ON vmscms.cms_transaction_mast
   FOR EACH ROW
DECLARE
v_errmsg VARCHAR2(300);
exp_raise_error exception;
 /*************************************************
      * Created By      :  Amit
     * Created Date   :  
     * Purpose  : 
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  31-Dec-2012
     * Release Number     :  CMS3.5.1_RI0023_B0004

  *************************************************/
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
	  BEGIN
	      INSERT INTO cms_lookup_mast
	                  (clm_inst_code, clm_record_type, clm_file_name,
	                   clm_field_name, clm_code_name, clm_code_desc,
	                   clm_ins_date, clm_ins_user
	                  )
	           VALUES (:NEW.ctm_inst_code, 'D', 'T',
	                   'Transaction_Code_Type', :NEW.CTM_DELIVERY_CHANNEL||:NEW.CTM_TRAN_CODE, :NEW.CTM_TRAN_DESC,
	                   SYSDATE, :NEW.ctm_ins_user
	                  );
	  EXCEPTION
	  WHEN OTHERS
	  THEN
		RAISE_APPLICATION_ERROR(-20001,'Error while creating record in lookup segment'||substr(sqlerrm,1,200));
	  END;
   ELSIF UPDATING
   THEN
	  BEGIN
	      UPDATE cms_lookup_mast
	         SET clm_code_name = :NEW.CTM_DELIVERY_CHANNEL||:NEW.CTM_TRAN_CODE,
	             clm_code_desc = :NEW.CTM_TRAN_DESC,
	             clm_lupd_date = SYSDATE,
	             clm_lupd_user = :NEW.ctm_lupd_user
	       WHERE clm_code_name = :OLD.CTM_DELIVERY_CHANNEL||:OLD.CTM_TRAN_CODE
	         AND clm_code_desc = :OLD.CTM_TRAN_DESC;
		  
		  IF sql%rowcount=0
		  THEN
				v_errmsg:='Delivery Channel and Txn code not found for updating info';
				RAISE exp_raise_error;
		  END IF;
	  EXCEPTION
	  WHEN exp_raise_error
	  THEN
		  RAISE_APPLICATION_ERROR(-20002,v_errmsg);
	  WHEN OTHERS
	  THEN
		RAISE_APPLICATION_ERROR(-20003,'Error while updating record in lookup segment '||substr(sqlerrm,1,200));	 
	  END;
   ELSIF DELETING
   THEN
	  BEGIN
	      DELETE FROM cms_lookup_mast
	            WHERE clm_code_name = :OLD.CTM_DELIVERY_CHANNEL||:OLD.CTM_TRAN_CODE
	              AND clm_code_desc = :OLD.CTM_TRAN_DESC;
				  
		  IF sql%rowcount=0
		  THEN
			 v_errmsg:='Delivery Channel and Txn code not found for deleting record';
			 RAISE exp_raise_error;
		  END IF;
	  EXCEPTION
	  WHEN exp_raise_error
	  THEN
		RAISE_APPLICATION_ERROR(-20004,v_errmsg);
	  WHEN OTHERS
	  THEN
		RAISE_APPLICATION_ERROR(-20005,'Error while deleting record in lookup segment '||substr(sqlerrm,1,200));
	  END;
   END IF;
END;                                                       --Trigger body ends
/
show error