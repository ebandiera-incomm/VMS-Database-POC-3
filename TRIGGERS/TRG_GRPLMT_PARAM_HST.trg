CREATE OR REPLACE TRIGGER VMSCMS.TRG_GRPLMT_PARAM_HST
   BEFORE UPDATE
   ON VMSCMS.CMS_GRPLMT_PARAM
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   INSERT INTO CMS_GRPLMT_PARAM_HIST (cgp_inst_code,
                                      cgp_group_code,
                                      CgP_DLVR_CHNL,
                                      cgp_tran_code,
                                      CgP_INTL_FLAG,
                                      CgP_PNSIGN_FLAG,
                                      CgP_MCC_CODE,
                                      CgP_TRFR_CRDACNT,
                                      CGP_GRPCOMB_HASH,
                                      cgp_lupd_date,
                                      cgp_lupd_user,
                                      cgp_orgins_date,
                                      cgp_orgins_user,
                                      cgp_ins_date)
        VALUES (:OLD.cgp_inst_code,
                :OLD.cgp_group_code,
                :OLD.CgP_DLVR_CHNL,
                :OLD.cgp_tran_code,
                :OLD.CgP_INTL_FLAG,
                :OLD.CgP_PNSIGN_FLAG,
                :OLD.CgP_MCC_CODE,
                :OLD.CgP_TRFR_CRDACNT,
                :OLD.CGP_GRPCOMB_HASH,
                :OLD.cgp_lupd_date,
                :OLD.cgp_lupd_user,
                :OLD.CGP_INS_DATE,
                :OLD.CGP_INS_USER,
                SYSDATE);
END;                                                       --Trigger body ends
/
show error