CREATE OR REPLACE TRIGGER VMSCMS.TRG_GROUP_LIMIT_HST
   BEFORE UPDATE
   ON vmscms.CMS_GROUP_LIMIT
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   INSERT INTO CMS_GROUP_LIMIT_HIST (cgl_inst_code,
                                     cgl_LMTPRFL_ID,
                                     cgl_group_code,
                                     Cgl_GRPLMT_HASH,
                                     Cgl_PERTXN_MINAMNT,
                                     Cgl_PERTXN_MAXAMNT,
                                     Cgl_DMAX_TXNCNT,
                                     Cgl_DMAX_TXNAMNT,
                                     Cgl_WMAX_TXNCNT,
                                     Cgl_WMAX_TXNAMNT,
                                     Cgl_MMAX_TXNCNT,
                                     Cgl_MMAX_TXNAMNT,
                                     Cgl_YMAX_TXNCNT,
                                     Cgl_YMAX_TXNAMNT,
                                     cgl_lupd_date,
                                     cgl_lupd_user,
                                     cgl_orgins_date,
                                     cgl_orgins_user,
                                     cgl_ins_date)
        VALUES (:OLD.cgl_inst_code,
                :OLD.cgl_LMTPRFL_ID,
                :OLD.cgl_group_code,
                :OLD.Cgl_GRPLMT_HASH,
                :OLD.Cgl_PERTXN_MINAMNT,
                :OLD.Cgl_PERTXN_MAXAMNT,
                :OLD.Cgl_DMAX_TXNCNT,
                :OLD.Cgl_DMAX_TXNAMNT,
                :OLD.Cgl_WMAX_TXNCNT,
                :OLD.Cgl_WMAX_TXNAMNT,
                :OLD.Cgl_MMAX_TXNCNT,
                :OLD.Cgl_MMAX_TXNAMNT,
                :OLD.Cgl_YMAX_TXNCNT,
                :OLD.Cgl_YMAX_TXNAMNT,
                :OLD.cgl_lupd_date,
                :OLD.cgl_lupd_user,
                :OLD.CGL_INS_DATE,
                :OLD.CGL_INS_USER,
                SYSDATE);
END;                                                       --Trigger body ends
/
show error