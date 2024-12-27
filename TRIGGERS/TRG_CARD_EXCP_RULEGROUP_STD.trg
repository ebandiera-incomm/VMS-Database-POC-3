CREATE OR REPLACE TRIGGER VMSCMS.trg_card_excp_rulegroup_std
	BEFORE INSERT OR UPDATE ON VMSCMS.PCMS_CARD_EXCP_RULEGROUP 		FOR EACH ROW
 /*
  * VERSION               :  1.0
  * DATE OF CREATION      : 23/Feb/2006
  * CREATED BY            : Chandrashekar Gurram.
  * PURPOSE               : Trigger on table pcms_card_excp_rulegroup.
  * MODIFICATION REASON   :
  *
  *
  * LAST MODIFICATION DONE BY :
  * LAST MODIFICATION DATE    :
  *
***/
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:NEW.pcer_ins_date := SYSDATE;
		:NEW.pcer_lupd_date := SYSDATE;
	ELSIF UPDATING THEN
		:NEW.pcer_lupd_date := SYSDATE;
	END IF;
END;	--Trigger body ends
/


