create or replace TRIGGER VMSCMS.TRG_ADDRMAST_STD 
	BEFORE INSERT OR UPDATE ON cms_addr_mast
		FOR EACH ROW
/***********************************************************************
    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 22-April-2019.
    * Modified For     : VMS-891.
    * Reviewer         : Saravanankumar A
    * Release Number   : VMS_RSI0192.
***********************************************************************/

BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cam_ins_date := sysdate;
		:new.cam_lupd_date := sysdate;      
            IF LOWER(FN_DMAPS_MAIN(:NEW.CAM_ADD_TWO))='null' 
            THEN 
                :new.cam_add_two := null;
            END IF;              
        
	ELSIF UPDATING THEN
		:new.cam_lupd_date := sysdate;
        
            IF LOWER(FN_DMAPS_MAIN(:NEW.CAM_ADD_TWO))='null' 
            THEN 
                :new.cam_add_two := null;
            END IF;
	END IF;
END;	--Trigger body ends
/


