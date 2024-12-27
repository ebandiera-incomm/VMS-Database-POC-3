CREATE OR REPLACE TRIGGER VMSCMS."TRG_LMTPRFL_HST"
   BEFORE UPDATE
   ON VMSCMS.cms_limit_prfl
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   INSERT INTO CMS_LIMIT_PRFL_HIST
               (clp_inst_code, clp_lmtprfl_id, clp_dlvr_chnl,
                clp_tran_code, clp_tran_type, clp_intl_flag,
                clp_pnsign_flag, clp_mcc_code,
                clp_pertxn_minamnt, clp_pertxn_maxamnt,
                clp_dmax_txncnt, clp_dmax_txnamnt,
                clp_wmax_txncnt, clp_wmax_txnamnt,
                clp_mmax_txncnt, clp_mmax_txnamnt,
                clp_ymax_txncnt, clp_ymax_txnamnt,
                clp_comb_hash, clp_trfr_crdacnt,
                clp_lupd_date, clp_lupd_user, clp_orgins_user,
                clp_orgins_date, clp_ins_date
               )
        VALUES (:OLD.clp_inst_code, :OLD.clp_lmtprfl_id, :OLD.clp_dlvr_chnl,
                :OLD.clp_tran_code, :OLD.clp_tran_type, :OLD.clp_intl_flag,
                :OLD.clp_pnsign_flag, :OLD.clp_mcc_code,
                :OLD.clp_pertxn_minamnt, :OLD.clp_pertxn_maxamnt,
                :OLD.clp_dmax_txncnt, :OLD.clp_dmax_txnamnt,
                :OLD.clp_wmax_txncnt, :OLD.clp_wmax_txnamnt,
                :OLD.clp_mmax_txncnt, :OLD.clp_mmax_txnamnt,
                :OLD.clp_ymax_txncnt, :OLD.clp_ymax_txnamnt,
                :OLD.clp_comb_hash, :OLD.clp_trfr_crdacnt,
                :OLD.clp_lupd_date, :OLD.clp_lupd_user, :OLD.clp_ins_user,
                :OLD.clp_ins_date, SYSDATE
               );
END;                                                       --Trigger body ends
/
SHOW ERRORS;


