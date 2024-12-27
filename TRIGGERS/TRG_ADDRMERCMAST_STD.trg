CREATE OR REPLACE TRIGGER VMSCMS.trg_addrmercmast_std 
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_MERC_ADDR_MAST 
		FOR EACH ROW
BEGIN	--Trigger body begins 
	IF INSERTING THEN 
		:new.cam_ins_date := sysdate; 
		:new.cam_lupd_date := sysdate; 
	ELSIF UPDATING THEN 
		:new.cam_lupd_date := sysdate; 
	END IF; 
END;	--Trigger body ends
/


