CREATE OR REPLACE PROCEDURE VMSCMS.SN_SCHED
IS
   CURSOR C1
   IS
      SELECT CCS_INST_CODE,
             CCS_PAN_CODE,
             CCS_INS_USER,
             CCS_LUPD_USER,
             CCS_PAN_CODE_ENCR,
             CCS_CCF_FNAME,
             ROWID
        FROM CMS_CARDISSUANCE_STATUS
       WHERE CCS_CARD_STATUS = 14 AND CCS_LUPD_DATE <= (SYSDATE - 2);
BEGIN
   FOR X IN C1
   LOOP
      BEGIN
         INSERT INTO CMS_CARDISSUE_STATCHANGE_HIST (CCH_INST_CODE,
                                                    CCH_PAN_CODE,
                                                    CCH_CARD_STATUS,
                                                    CCH_INS_USER,
                                                    CCH_INS_DATE,
                                                    CCH_LUPD_USER,
                                                    CCH_LUPD_DATE,
                                                    CCH_PAN_CODE_ENCR,
                                                    CCH_CCF_FNAME)
              VALUES (X.CCS_INST_CODE,
                      X.CCS_PAN_CODE,
                      '15',
                      X.CCS_INS_USER,
                      SYSDATE,
                      X.CCS_LUPD_USER,
                      SYSDATE,
                      X.CCS_PAN_CODE_ENCR,
                      X.CCS_CCF_FNAME);

         UPDATE CMS_CARDISSUANCE_STATUS
            SET CCS_CARD_STATUS = 15
          WHERE CCS_CARD_STATUS = 14 AND ROWID = X.ROWID;
      END;
   END LOOP;
END;
/

SHOW ERROR