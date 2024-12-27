CREATE OR REPLACE TRIGGER VMSCMS.TRG_FEEPLAN_STD
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_FEE_FEEPLAN 		FOR EACH ROW
/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  20-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0009
 *************************************************/
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.CFF_INS_DATE := sysdate;
		:new.CFF_LUPD_DATE := sysdate;
	ELSIF UPDATING THEN
		:new.CFF_LUPD_DATE := sysdate;
	END IF;
END;
/


