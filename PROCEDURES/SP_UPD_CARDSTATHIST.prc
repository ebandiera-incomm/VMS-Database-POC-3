CREATE OR REPLACE PROCEDURE VMSCMS.sp_upd_cardstathist(    instcode        IN    NUMBER  ,
                                                    filename        IN    VARCHAR2,
                                                    lupduser    IN    NUMBER    ,
                                                    errmsg        OUT     VARCHAR2)
AS
exp_loop_reject_record   EXCEPTION;

  CURSOR c1
   IS
      SELECT  CCS_PAN_CODE,CCS_PAN_CODE_ENCR,ROWID
        FROM CMS_CARDISSUANCE_STATUS
       WHERE CCS_INST_CODE = instcode
        AND  CCS_CCF_FNAME = filename;
       

BEGIN        --Main Begin Block Starts Here
    
    errmsg := 'OK';
    
    FOR x IN c1
   LOOP
   
                BEGIN
                  INSERT INTO CMS_CARDISSUE_STATCHANGE_HIST
                              (CCH_INST_CODE,CCH_PAN_CODE,CCH_CARD_STATUS,
                                CCH_INS_USER,CCH_INS_DATE,CCH_LUPD_USER,
                                CCH_LUPD_DATE,CCH_PAN_CODE_ENCR,CCH_CCF_FNAME
                              )
                       VALUES (instcode, x.ccs_pan_code, 14,
                               lupduser, SYSDATE,
                               lupduser, SYSDATE,
                               x.ccs_pan_code_encr,filename
                              );
               EXCEPTION
                  
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Error while inserting records into CMS_CARDISSUE_STATCHANGE_HIST '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_loop_reject_record;
               END;
               
   
   END LOOP;

EXCEPTION    --Exception of Main Begin
    WHEN OTHERS THEN
        errmsg := 'Exeption Main -- '||SQLCODE||'--'||SQLERRM;
END    ;        --Main Begin Block Ends Here
/


