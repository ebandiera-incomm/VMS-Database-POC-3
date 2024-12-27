create or replace
TRIGGER vmscms.trg_resp_std
   BEFORE INSERT OR UPDATE OR DELETE
   ON vmscms.cms_response_mast
   FOR EACH ROW
   
 Declare  
  CHANNEL_DESC cms_delchannel_mast.CDM_CHANNEL_DESC%TYPE;
  v_errmsg VARCHAR2(300);
  exp_raise_error exception;
  V_CNT NUMBER;   -- Added for release 23.1.1
 /*************************************************
      * Created By      :  Amit
     * Created Date   :  
     * Purpose  : 
    * Modified by      : Saravanakumar
    * Modified Reason  : Add insert block if the record is not available before update
    * Modified Date    : 12-Feb-2013
     * Reviewer         : Sachin
     * Reviewed Date    :  12-Feb-2013
     * Release Number     :  CMS3.5.1_RI0023.1.1_B0003

  *************************************************/
BEGIN  
--Trigger body begins
   BEGIN
        --Modified for release 23.1.1
	   /*SELECT CDM_CHANNEL_DESC
	   INTO CHANNEL_DESC
	    FROM cms_response_mast,
	      cms_delchannel_mast
	    WHERE CDM_CHANNEL_CODE=CMS_DELIVERY_CHANNEL
	    AND CDM_INST_CODE =CMS_INST_CODE
	    AND CMS_INST_CODE=:NEW.CMS_INST_CODE
	    AND CMS_DELIVERY_CHANNEL=:NEW.CMS_DELIVERY_CHANNEL
	    AND CMS_response_id=:NEW.CMS_response_id;*/

	   SELECT CDM_CHANNEL_DESC
	   INTO CHANNEL_DESC
	    FROM  cms_delchannel_mast
	    WHERE CDM_CHANNEL_CODE=NVL(:NEW.CMS_DELIVERY_CHANNEL,:OLD.CMS_DELIVERY_CHANNEL)
	    AND CDM_INST_CODE =NVL(:NEW.CMS_INST_CODE,:OLD.CMS_INST_CODE);
    EXCEPTION
	WHEN OTHERS 
	THEN
		RAISE_APPLICATION_ERROR(-20001,'Error whilr selecting channel description '||substr(sqlerrm,1,200));
	END;
   IF INSERTING
   THEN
      BEGIN
	      INSERT INTO cms_lookup_mast
	                  (clm_inst_code, clm_record_type, clm_file_name,
	                   clm_field_name, clm_code_name, clm_code_desc,
	                   clm_ins_date, clm_ins_user
	                  )
	           VALUES (:old.cms_inst_code, 'D', 'T',
	                   'Authorization_Response', :old.CMS_ISO_RESPCDE, CHANNEL_DESC ||'-'|| :old.CMS_RESP_DESC,
	                   SYSDATE, :old.cms_ins_user
	                  );
	   EXCEPTION
	   WHEN OTHERS 
	   THEN
			RAISE_APPLICATION_ERROR(-20002,'Error while creating record in lookup segment '||substr(sqlerrm,1,200));
	   END;
   ELSIF UPDATING
   THEN
   -- Sn Added for release 23.1.1
    BEGIN
        SELECT COUNT(1)INTO V_CNT
        FROM cms_lookup_mast WHERE clm_code_name = :OLD.CMS_ISO_RESPCDE
        AND clm_code_desc = CHANNEL_DESC ||'-'|| :OLD.CMS_RESP_DESC;

        IF V_CNT =0 THEN
            BEGIN
                INSERT INTO cms_lookup_mast
                (clm_inst_code, clm_record_type, clm_file_name,
                clm_field_name, clm_code_name, clm_code_desc,
                clm_ins_date, clm_ins_user
                )
                VALUES (:NEW.cms_inst_code, 'D', 'T',
                'Authorization_Response', :OLD.CMS_ISO_RESPCDE, CHANNEL_DESC ||'-'|| :OLD.CMS_RESP_DESC,
                SYSDATE, :OLD.cms_ins_user
                );
            EXCEPTION
                WHEN OTHERS  THEN
                    RAISE_APPLICATION_ERROR(-20002,'Error while creating record in lookup segment '||substr(sqlerrm,1,200));
            END;        
        END IF;
    EXCEPTION
        WHEN OTHERS  THEN
            RAISE_APPLICATION_ERROR(-20002,'Error while selecting V_CNT '||substr(sqlerrm,1,200));
    END;
   -- En Added for release 23.1.1

	  BEGIN
	      UPDATE cms_lookup_mast
	         SET clm_code_name = nvl(:NEW.CMS_ISO_RESPCDE,:old.CMS_ISO_RESPCDE),
	             clm_code_desc = CHANNEL_DESC ||'-'|| nvl(:NEW.CMS_RESP_DESC,:old.CMS_RESP_DESC),
	             clm_lupd_date = SYSDATE,
	             clm_lupd_user = nvl(:NEW.cms_lupd_user,:old.cms_lupd_user)
	       WHERE clm_code_name = :OLD.CMS_ISO_RESPCDE
	         AND clm_code_desc = CHANNEL_DESC ||'-'|| :OLD.CMS_RESP_DESC;
			 
		  IF sql%rowcount=0
			 THEN
				v_errmsg:='ISO response code not found for updating info';
				RAISE exp_raise_error;
		  END IF;
	  EXCEPTION
	  WHEN exp_raise_error
	  THEN
		RAISE_APPLICATION_ERROR(-20003,v_errmsg);
	  WHEN OTHERS
	  THEN
		RAISE_APPLICATION_ERROR(-20004,'Error while updating record in lookup segment '||substr(sqlerrm,1,200));
	  END;
   ELSIF DELETING
   THEN
	 BEGIN
        SELECT COUNT(1)INTO V_CNT
        FROM cms_lookup_mast WHERE clm_code_name = :OLD.CMS_ISO_RESPCDE
        AND clm_code_desc = CHANNEL_DESC ||'-'|| :OLD.CMS_RESP_DESC;

        IF V_CNT <> 0 THEN
            DELETE FROM cms_lookup_mast
            WHERE clm_code_name = :OLD.CMS_ISO_RESPCDE
            AND clm_code_desc =CHANNEL_DESC ||'-'|| :OLD.CMS_RESP_DESC;
			
            IF sql%rowcount=0   THEN
                v_errmsg:='ISO response code not found for deleting record';
                RAISE exp_raise_error;
            END IF;
        END IF;
     EXCEPTION
	  WHEN exp_raise_error
	  THEN 
		RAISE_APPLICATION_ERROR(-20005,v_errmsg);
	  WHEN OTHERS
	  THEN
		RAISE_APPLICATION_ERROR(-20006,'Error while deleting record in lookup segment '||substr(sqlerrm,1,200));
	 END;
   END IF;
END;                                                       --Trigger body ends
/
show error