CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODFEEPLAN_ID
before insert on cms_prod_fees
for each row
/*************************************************************
     * Created Date       : 18/Aug/2012
     * Created By         : Deepa.
     * PURPOSE            : To insert the feeplan id for new fee Plan
     * Reviewer          :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0015_B0001
****************************************************************/
BEGIN 
  :new.CPF_PRODFEEPLAN_ID := SEQ_PRODCATTYPE_ID.NEXTVAL; 
END;
/
SHOW ERROR;