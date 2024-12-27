CREATE OR REPLACE TRIGGER vmscms.trg_cardstatus_std
   BEFORE INSERT OR UPDATE OR DELETE
   ON vmscms.cms_card_stat
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
	           VALUES (:NEW.ccs_inst_code, 'D', 'C',
	                   'CARD STATUS', :NEW.ccs_stat_code, :NEW.ccs_stat_desc,
	                   SYSDATE, :NEW.ccs_ins_user
	                  );
	   EXCEPTION
	   WHEN OTHERS 
	   THEN
		RAISE_APPLICATION_ERROR(-20001,'Error while creating record in lookup segment '||substr(sqlerrm,1,200));
	   END;
   ELSIF UPDATING
   THEN
	  BEGIN
	      UPDATE cms_lookup_mast
	         SET clm_code_name = :NEW.ccs_stat_code,
	             clm_code_desc = :NEW.ccs_stat_desc,
	             clm_lupd_date = SYSDATE,
	             clm_lupd_user = :NEW.ccs_lupd_user
	       WHERE clm_code_name = :OLD.ccs_stat_code
	         AND clm_code_desc = :OLD.ccs_stat_desc;
			 
			 IF sql%rowcount=0
			 THEN
				v_errmsg:='Status code not found for updating info';
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
	            WHERE clm_code_name = :OLD.ccs_stat_code
	              AND clm_code_desc = :OLD.ccs_stat_desc;
		  
		  IF sql%rowcount=0
			 THEN
				v_errmsg:='Status code not found for deleting record';				
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