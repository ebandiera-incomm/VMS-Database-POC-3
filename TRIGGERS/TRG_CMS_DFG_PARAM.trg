CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_DFG_PARAM
AFTER UPDATE ON VMSCMS.CMS_DFG_PARAM FOR EACH ROW
/*************************************************
     * Created Date     :  30-Apr-2012
     * Created By       :  Saravanakumar
     * PURPOSE          :  For moving the data into history table
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  30-May-2012
     * Release Number   :  CMS3.4.4_RI0008_B00019
     
	 * Modified By      : Sagar More
     * Modified Date    : 26-Sep-2013
     * Modified For     : LYFEHOST-63
     * Modified Reason  : To fetch saving acct parameter based on product code 
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Sep-2013
     * Build Number     : RI0024.5_B0001
     
*************************************************/
BEGIN
    IF :OLD.CDP_PARAM_KEY <> :NEW.CDP_PARAM_KEY
    OR :OLD.CDP_PARAM_VALUE<> :NEW.CDP_PARAM_VALUE
    OR :OLD.CDP_MANDARORY_FLAG<> :NEW.CDP_MANDARORY_FLAG THEN
        INSERT INTO cms_dfg_param_hist
                    (cdp_inst_code  ,
                    cdp_param_key   ,
                    cdp_param_value ,
                    cdp_ins_user   ,
                    cdp_ins_date   ,
                    cdp_lupd_user   ,
                    cdp_lupd_date  ,
                    cdp_mandarory_flag,
                    CDP_PROD_CODE       -- added for LYFEHOST-63 
                    )
        VALUES
                    (:OLD.cdp_inst_code  ,
                    :OLD.cdp_param_key   ,
                    :OLD.cdp_param_value ,
                    1  ,
                    SYSDATE  ,
                    1  ,
                    SYSDATE ,
                    :OLD.cdp_mandarory_flag,
                    :OLD.cdp_prod_code       -- added for LYFEHOST-63 
                    );
    END IF;
END;
/
show error;

