CREATE OR REPLACE TRIGGER vmscms.trg_cardsumry_dwmy_hist
   AFTER DELETE
   ON vmscms.cms_cardsumry_dwmy
   REFERENCING OLD AS OLD
   FOR EACH ROW
 /*************************************************
    * Created By       : Sachin Patil
    * Created Date     : 12-Jul-2013
    * Created Reason   : NextCala - Sum of C2C transfers per month exceeds 2000.00 and should not
    * Created For      : NCGPR-434    
    * Reviewer          : Dhiraj
    * Reviewed Date     : 19.07.2013
    * Build Number     : RI0024.3_B0005

*************************************************/
BEGIN                                                    --Trigger body begins
   INSERT INTO cms_cardsumry_dwmy_hist
               (ccd_inst_code, ccd_pan_code, ccd_comb_hash,
                ccd_daly_txncnt, ccd_daly_txnamnt,
                ccd_wkly_txncnt, ccd_wkly_txnamnt,
                ccd_mntly_txncnt, ccd_mntly_txnamnt,
                ccd_yerly_txncnt, ccd_yerly_txnamnt,
                ccd_lupd_date, ccd_lupd_user, ccd_ins_date,
                ccd_ins_user
               )
        VALUES (:OLD.ccd_inst_code, :OLD.ccd_pan_code, :OLD.ccd_comb_hash,
                :OLD.ccd_daly_txncnt, :OLD.ccd_daly_txnamnt,
                :OLD.ccd_wkly_txncnt, :OLD.ccd_wkly_txnamnt,
                :OLD.ccd_mntly_txncnt, :OLD.ccd_mntly_txnamnt,
                :OLD.ccd_yerly_txncnt, :OLD.ccd_yerly_txnamnt,
                :OLD.ccd_lupd_date, :OLD.ccd_lupd_user, SYSDATE,
                :OLD.ccd_ins_user
               );
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20003,
                                  'Main exception from trg_applpan_lmthst '
                               || SQLERRM
                              );
END;                                                       --Trigger body ends
/
SHOW ERROR
