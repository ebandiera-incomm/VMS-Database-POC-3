CREATE OR REPLACE PROCEDURE VMSCMS.SP_BKUP_ACT (prm_errmsg OUT VARCHAR2)
AS
   CURSOR c1
   IS
      SELECT a.cap_acct_no
        FROM cms_dup_acct_no a
       ;

   v_errmsg             VARCHAR2 (300);
   v_check_pan          NUMBER;
   exp_reject_records   EXCEPTION;
   v_savepoint          NUMBER         := 0;
   V_ACTIV_CRD_FLG      VARCHAR2(1);
   V_EXIST_CHK          NUMBER(10)  ;
   V_CNT                NUMBER(10)  ;

   V_COMMIT             NUMBER(10) := 0 ;

   exp_reject_records exception;


BEGIN
   prm_errmsg := 'OK';



   FOR x IN c1 LOOP
   BEGIN

   v_savepoint:=v_savepoint+1;

   V_COMMIT :=  V_COMMIT + 1    ;
   V_EXIST_CHK := 0 ;
   V_ACTIV_CRD_FLG := 'N'    ;

        SELECT COUNT(*)
        INTO V_CNT
        FROM CMS_APPL_PAN
        WHERE CAP_ACCT_NO = x.cap_acct_no
        AND CAP_STARTERCARD_FLAG = 'Y'
        AND cap_card_stat in (1,13);

        IF V_CNT > 0 THEN

            V_ACTIV_CRD_FLG := 'Y'  ;


        END IF;


        -- SN : IF HAVING ATLEST ONE ACTIVE CARD
        IF V_ACTIV_CRD_FLG = 'Y' THEN

            FOR i IN (SELECT CAP_PAN_CODE, CAP_CARD_STAT, ROWID ROW_ID FROM CMS_APPL_PAN WHERE CAP_ACCT_NO = x.cap_acct_no) LOOP


                IF i.CAP_CARD_STAT = 0 THEN

                    UPDATE CMS_APPL_PAN
                    SET CAP_CARD_STAT = 4
                    WHERE ROWID = i.ROW_ID
                    ;

                END IF;



            END LOOP;


        ELSE -- ELSE IF HAVING ALL CARD AS INACTIVE

            FOR i IN (SELECT CAP_PAN_CODE, ROWID ROW_ID FROM CMS_APPL_PAN WHERE CAP_ACCT_NO = x.cap_acct_no) LOOP

            V_EXIST_CHK := V_EXIST_CHK + 1    ;

                IF V_EXIST_CHK > 1 THEN

                    UPDATE CMS_APPL_PAN
                    SET CAP_CARD_STAT = 4
                    WHERE ROWID = i.ROW_ID
                    ;

                END IF;



            END LOOP;

        END IF;

        -- EN : IF HAVING ATLEST ONE ACTIVE CARD


        INSERT INTO cms_backup_log VALUES (x.cap_acct_no, 'S', 'OK' , SYSDATE) ;


        IF V_COMMIT = 10 THEN

            COMMIT;

            V_COMMIT := 0    ;

        END IF;


   EXCEPTION

        WHEN OTHERS THEN

            v_errmsg    :=  SUBSTR(SQLERRM, 1, 100);

            ROLLBACK TO v_savepoint;

            INSERT INTO cms_backup_log VALUES (x.cap_acct_no, 'E', v_errmsg, SYSDATE) ;




   END;
   END LOOP;
END;
/

SHOW ERRORS;


