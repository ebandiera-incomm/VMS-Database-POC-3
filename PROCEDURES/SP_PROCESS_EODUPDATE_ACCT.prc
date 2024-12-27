CREATE OR REPLACE PROCEDURE VMSCMS.sp_process_eodupdate_acct
(
prm_inst_code   IN      NUMBER,
prm_errmsg     OUT     VARCHAR2
)
IS
        CURSOR C IS SELECT
                    CEU_TRAN_DATE,
                    CEU_CUSTOMER_CARD_NO,
                    CEU_UPD_ACCTNO,
                    CEU_UPD_AMOUNT,
                    CEU_UPD_FLAG,
                    CEU_PROCESS_FLAG,
                    ROWID R
                    FROM
                    CMS_EODUPDATE_ACCT
                    WHERE CEU_PROCESS_FLAG = 'N';

       V_SAVEPOINT  NUMBER DEFAULT 1;
	   exp_reject_record   EXCEPTION;
BEGIN           --<<MAIN BEGIN >>
        prm_errmsg := 'OK';
        FOR I IN C LOOP
                BEGIN                                   --<< LOOP BEGIN >>
                        SAVEPOINT       V_SAVEPOINT;
                        prm_errmsg := 'OK';
                        UPDATE CMS_ACCT_MAST
                        SET    CAM_ACCT_BAL  = DECODE ( I.CEU_UPD_FLAG , 'C',
                                                          (CAM_ACCT_BAL + I.ceu_upd_amount),
                                                           'D',
                                                           (CAM_ACCT_BAL - I.ceu_upd_amount) ,
                                                           CAM_ACCT_BAL
                                                       )
                        WHERE   CAM_INST_CODE = prm_inst_code
                        AND     CAM_ACCT_NO   = I.ceu_upd_acctno;
                        IF SQL%ROWCOUNT <> 1 THEN
                        prm_errmsg := ' Problem while updating acctno ';
                        RAISE exp_reject_record;
                        ELSE
                                
                                UPDATE  cms_gl_acct_mast 
                                SET cga_tran_amt = DECODE (i.ceu_upd_flag,'C',
                                                     (DECODE(cga_tran_amt,NULL,0,cga_tran_amt) + i.ceu_upd_amount),
                                                     'D',
                                                     (DECODE(cga_tran_amt,NULL,0,cga_tran_amt) - i.ceu_upd_amount),
                                                     DECODE(cga_tran_amt,NULL,0,cga_tran_amt))
                                WHERE cga_inst_code = prm_inst_code 
                                AND cga_acct_code = I.ceu_upd_acctno ;
                                
                                IF SQL%ROWCOUNT <> 1 THEN
                                  prm_errmsg := ' Problem while updating gl acct mast ';
                                RAISE exp_reject_record;
                                
                                ELSE
                                        UPDATE CMS_EODUPDATE_ACCT
                                        SET    CEU_PROCESS_FLAG = 'Y',
                                            CEU_PROCESS_MSG  = 'Successful'
                                        WHERE  ROWID = I.R;
                                END IF;
                        END IF;
                        V_SAVEPOINT := V_SAVEPOINT + 1;
                EXCEPTION                               --<< LOOP EXCEPTION >>
                WHEN exp_reject_record THEN
					 	ROLLBACK TO V_SAVEPOINT;
                        UPDATE CMS_EODUPDATE_ACCT
                        SET    CEU_PROCESS_FLAG = 'E',
                               CEU_PROCESS_MSG  = prm_errmsg
                        WHERE  ROWID = I.R;
               WHEN OTHERS THEN
			   			ROLLBACK TO V_SAVEPOINT;
                        prm_errmsg := ' Problem while update ' || SUBSTR(SQLERRM , 200);
                        UPDATE CMS_EODUPDATE_ACCT
                        SET    CEU_PROCESS_FLAG = 'E',
                               CEU_PROCESS_MSG  = prm_errmsg
                        WHERE  ROWID = I.R;
                END;                                    --<< LOOP END >>
        END LOOP;
         prm_errmsg := 'OK';
EXCEPTION       --<< MAIN EXCEPTION >>
WHEN OTHERS THEN
prm_errmsg := ' Main exception ' || SUBSTR(SQLERRM,1, 300);
END ;           --<< MAIN END >
/
SHOW ERRORS

