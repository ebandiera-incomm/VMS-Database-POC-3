CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACCT_CLOSE_DEBIT (
   PRM_INSTCODE   IN     NUMBER,
   PRM_ACCTID     IN     NUMBER,
   PRM_RSNCODE    IN     NUMBER,
   PRM_REMARK     IN     VARCHAR2,
   PRM_LUPDUSER   IN     NUMBER,
   PRM_ERRMSG        OUT VARCHAR2)
IS
   V_CARD_LINKED       NUMBER (3);
   V_SPPRT_TYPE        VARCHAR2 (30);
   V_CAF_CNT           NUMBER;
   V_RECORD_EXIST      CHAR (1) := 'Y';
   V_CAFFILEGEN_FLAG   CHAR (1) := 'N';
   V_ISSUESTATUS       VARCHAR2 (2);
   V_PINMAILER         VARCHAR2 (1);
   V_CARDCARRIER       VARCHAR2 (1);
   V_PINOFFSET         VARCHAR2 (16);
   V_REC_TYPE          VARCHAR2 (1);
   V_CAM_ACCT_NO       CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
   V_INSTA_CHECK       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

   CURSOR C1 (P_INSTCODE IN NUMBER, P_ACCTID IN NUMBER)
   IS
      SELECT CPA_PAN_CODE,
             CPA_MBR_NUMB,
             CPA_ACCT_POSN,
             CPA_PAN_CODE_ENCR
        FROM CMS_PAN_ACCT
       WHERE CPA_INST_CODE = P_INSTCODE AND CPA_ACCT_ID = P_ACCTID;

   CURSOR C2 (P_INSTCODE IN NUMBER, P_ACCTID IN NUMBER)
   IS
      SELECT CCA_CUST_CODE
        FROM CMS_CUST_ACCT
       WHERE CCA_INST_CODE = P_INSTCODE AND CCA_ACCT_ID = P_ACCTID;
BEGIN
   FOR I IN C1 (PRM_INSTCODE, PRM_ACCTID)
   LOOP
      BEGIN
         BEGIN
            SELECT CAM_ACCT_NO
              INTO V_CAM_ACCT_NO
              FROM CMS_ACCT_MAST
             WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_ID = PRM_ACCTID;
         EXCEPTION
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while selecting acct no. '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN
            SELECT CIP_PARAM_VALUE
              INTO V_INSTA_CHECK
              FROM CMS_INST_PARAM
             WHERE CIP_PARAM_KEY = 'INSTA_CARD_CHECK'
                   AND CIP_INST_CODE = PRM_INSTCODE;

            IF V_INSTA_CHECK = 'Y'
            THEN
               SP_GEN_INSTA_CHECK (PRM_ACCTNO   => V_CAM_ACCT_NO,
                                   PRM_ERRMSG   => PRM_ERRMSG);

               IF PRM_ERRMSG <> 'OK'
               THEN
                  PRM_ERRMSG :=
                     'You can not close the account issued for instant cards.';
                  RETURN;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while checking the instant card validation. '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO V_CARD_LINKED
              FROM CMS_PAN_ACCT
             WHERE     CPA_INST_CODE = PRM_INSTCODE
                   AND CPA_PAN_CODE = I.CPA_PAN_CODE
                   AND CPA_MBR_NUMB = I.CPA_MBR_NUMB;

            IF V_CARD_LINKED = 1
            THEN
               V_SPPRT_TYPE := 'ACCCL1';
            ELSE
               V_SPPRT_TYPE := 'ACCCL2';
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               PRM_ERRMSG := 'No record found for card ';
               RETURN;
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while selecting data from pan acct master '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN
            INSERT INTO CMS_PAN_ACCT_HIST (CPA_INST_CODE,
                                           CPA_PAN_CODE,
                                           CPA_MBR_NUMB,
                                           CPA_ACCT_ID,
                                           CPA_ACCT_POSN,
                                           CPA_INS_USER,
                                           CPA_LUPD_USER,
                                           CPA_PAN_CODE_ENCR)
                 VALUES (PRM_INSTCODE,
                         I.CPA_PAN_CODE,
                         I.CPA_MBR_NUMB,
                         PRM_ACCTID,
                         I.CPA_ACCT_POSN,
                         PRM_LUPDUSER,
                         PRM_LUPDUSER,
                         I.CPA_PAN_CODE_ENCR);
         EXCEPTION
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while inserting records in pan acct history '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         IF V_CARD_LINKED = 1
         THEN
            BEGIN
               UPDATE CMS_APPL_PAN
                  SET CAP_CARD_STAT = 9, CAP_LUPD_USER = PRM_LUPDUSER
                WHERE     CAP_PAN_CODE = I.CPA_PAN_CODE
                      AND CAP_MBR_NUMB = I.CPA_MBR_NUMB
                      AND CAP_INST_CODE = PRM_INSTCODE;

               IF SQL%ROWCOUNT = 0
               THEN
                  PRM_ERRMSG := 'card status updation failed';
                  RETURN;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  PRM_ERRMSG :=
                     'Error while update the status of the card in card master for single rec '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         ELSE
            BEGIN
               DELETE FROM CMS_PAN_ACCT
                     WHERE     CPA_INST_CODE = PRM_INSTCODE
                           AND CPA_PAN_CODE = I.CPA_PAN_CODE
                           AND CPA_MBR_NUMB = I.CPA_MBR_NUMB
                           AND CPA_ACCT_POSN = I.CPA_ACCT_POSN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  PRM_ERRMSG :=
                     'Error while deleting records in from pan acct '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            BEGIN
               UPDATE CMS_PAN_ACCT
                  SET CPA_ACCT_POSN = CPA_ACCT_POSN - 1,
                      CPA_LUPD_USER = PRM_LUPDUSER
                WHERE     CPA_INST_CODE = PRM_INSTCODE
                      AND CPA_PAN_CODE = I.CPA_PAN_CODE
                      AND CPA_MBR_NUMB = I.CPA_MBR_NUMB
                      AND CPA_ACCT_POSN > I.CPA_ACCT_POSN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  PRM_ERRMSG :=
                     'Error while updating acct position '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            IF I.CPA_ACCT_POSN = 1
            THEN
               BEGIN
                  UPDATE CMS_APPL_PAN
                     SET (CAP_ACCT_ID, CAP_ACCT_NO) =
                            (SELECT CPA_ACCT_ID, CAM_ACCT_NO
                               FROM CMS_PAN_ACCT A, CMS_ACCT_MAST B
                              WHERE     B.CAM_INST_CODE = A.CPA_INST_CODE
                                    AND B.CAM_ACCT_ID = A.CPA_ACCT_ID
                                    AND A.CPA_PAN_CODE = I.CPA_PAN_CODE
                                    AND A.CPA_MBR_NUMB = I.CPA_MBR_NUMB
                                    AND A.CPA_ACCT_POSN = 1)
                   WHERE     CAP_PAN_CODE = I.CPA_PAN_CODE
                         AND CAP_MBR_NUMB = I.CPA_MBR_NUMB
                         AND CAP_INST_CODE = PRM_INSTCODE;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     PRM_ERRMSG :=
                        'Primary acct updation in card master failed';
                     RETURN;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     PRM_ERRMSG :=
                        'Error while updating primarry acct in card master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RETURN;
               END;

               BEGIN
                  UPDATE CMS_ACCT_MAST
                     SET CAM_STAT_CODE = 8
                   WHERE CAM_INST_CODE = PRM_INSTCODE
                         AND CAM_ACCT_ID =
                                (SELECT CPA_ACCT_ID
                                   FROM CMS_PAN_ACCT
                                  WHERE     CPA_PAN_CODE = I.CPA_PAN_CODE
                                        AND CPA_MBR_NUMB = I.CPA_MBR_NUMB
                                        AND CPA_INST_CODE = PRM_INSTCODE
                                        AND CPA_ACCT_POSN = 1);

                  IF SQL%ROWCOUNT = 0
                  THEN
                     PRM_ERRMSG := 'Primary acct status  updation failed';
                     RETURN;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     PRM_ERRMSG :=
                        'Error while updating primarry acct status in acct master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RETURN;
               END;
            END IF;
         END IF;

         BEGIN
            BEGIN
                 SELECT CCI_REC_TYP,
                        CCI_FILE_GEN,
                        CCI_SEG12_ISSUE_STAT,
                        CCI_SEG12_PIN_MAILER,
                        CCI_SEG12_CARD_CARRIER,
                        CCI_PIN_OFST
                   INTO V_REC_TYPE,
                        V_CAFFILEGEN_FLAG,
                        V_ISSUESTATUS,
                        V_PINMAILER,
                        V_CARDCARRIER,
                        V_PINOFFSET
                   FROM CMS_CAF_INFO
                  WHERE     CCI_INST_CODE = PRM_INSTCODE
                        AND CCI_PAN_CODE = I.CPA_PAN_CODE
                        AND CCI_MBR_NUMB = I.CPA_MBR_NUMB
                        AND CCI_FILE_GEN = 'N'
               GROUP BY CCI_REC_TYP,
                        CCI_FILE_GEN,
                        CCI_SEG12_ISSUE_STAT,
                        CCI_SEG12_PIN_MAILER,
                        CCI_SEG12_CARD_CARRIER,
                        CCI_PIN_OFST;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_RECORD_EXIST := 'N';
               WHEN OTHERS
               THEN
                  PRM_ERRMSG :=
                     'Error while selecting caf details '
                     || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;

            DELETE FROM CMS_CAF_INFO
                  WHERE     CCI_INST_CODE = PRM_INSTCODE
                        AND CCI_PAN_CODE = I.CPA_PAN_CODE
                        AND CCI_MBR_NUMB = I.CPA_MBR_NUMB;

            BEGIN
               SP_CAF_RFRSH (PRM_INSTCODE,
                             FN_DMAPS_MAIN (I.CPA_PAN_CODE_ENCR),
                             '000',
                             SYSDATE,
                             'C',
                             PRM_REMARK,
                             'ACCCL',
                             PRM_LUPDUSER,
                             FN_DMAPS_MAIN (I.CPA_PAN_CODE_ENCR),
                             PRM_ERRMSG);

               IF PRM_ERRMSG <> 'OK'
               THEN
                  PRM_ERRMSG := 'From CAF refresh process ' || PRM_ERRMSG;
                  RETURN;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  PRM_ERRMSG :=
                     'Error while creating caf record '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            IF V_REC_TYPE = 'A'
            THEN
               V_ISSUESTATUS := '00';
               V_PINOFFSET := RPAD ('Z', 16, 'Z');
            END IF;

            IF V_RECORD_EXIST = 'Y'
            THEN
               BEGIN
                  UPDATE CMS_CAF_INFO
                     SET CCI_SEG12_ISSUE_STAT = V_ISSUESTATUS,
                         CCI_SEG12_PIN_MAILER = V_PINMAILER,
                         CCI_SEG12_CARD_CARRIER = V_CARDCARRIER,
                         CCI_PIN_OFST = V_PINOFFSET
                   WHERE     CCI_INST_CODE = PRM_INSTCODE
                         AND CCI_PAN_CODE = I.CPA_PAN_CODE
                         AND CCI_MBR_NUMB = I.CPA_MBR_NUMB;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     PRM_ERRMSG := 'CAF  status  updation failed';
                     RETURN;
                  END IF;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while generating CAF details '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;


         BEGIN
            INSERT INTO CMS_PAN_SPPRT (CPS_INST_CODE,
                                       CPS_PAN_CODE,
                                       CPS_MBR_NUMB,
                                       CPS_PROD_CATG,
                                       CPS_SPPRT_KEY,
                                       CPS_SPPRT_RSNCODE,
                                       CPS_FUNC_REMARK,
                                       CPS_INS_USER,
                                       CPS_LUPD_USER,
                                       CPS_CMD_MODE,
                                       CPS_PAN_CODE_ENCR)
                 VALUES (PRM_INSTCODE,
                         I.CPA_PAN_CODE,
                         I.CPA_MBR_NUMB,
                         'D',
                         V_SPPRT_TYPE,
                         PRM_RSNCODE,
                         PRM_REMARK,
                         PRM_LUPDUSER,
                         PRM_LUPDUSER,
                         0,
                         I.CPA_PAN_CODE_ENCR);
         EXCEPTION
            WHEN OTHERS
            THEN
               PRM_ERRMSG :=
                  'Error while creating record in support detail '
                  || SUBSTR (SQLERRM, 1, 150);
               RETURN;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            PRM_ERRMSG :=
               'Error in acct close process ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
   END LOOP;

   FOR J IN C2 (PRM_INSTCODE, PRM_ACCTID)
   LOOP
      INSERT INTO CMS_CLOSED_ACCTS (CCA_INST_CODE,
                                    CCA_CUST_CODE,
                                    CCA_ACCT_ID,
                                    CCA_INS_USER,
                                    CCA_LUPD_USER)
           VALUES (PRM_INSTCODE,
                   J.CCA_CUST_CODE,
                   PRM_ACCTID,
                   PRM_LUPDUSER,
                   PRM_LUPDUSER);
   END LOOP;

   BEGIN
      UPDATE CMS_CUST_ACCT
         SET CCA_REL_STAT = 'N', CCA_LUPD_USER = PRM_LUPDUSER
       WHERE CCA_ACCT_ID = PRM_ACCTID AND CCA_INST_CODE = PRM_INSTCODE;

      IF SQL%ROWCOUNT = 0
      THEN
         PRM_ERRMSG := 'Customer acct relation status updation failed';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PRM_ERRMSG :=
            'Error while customer acct relation ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      UPDATE CMS_ACCT_MAST
         SET CAM_STAT_CODE = 2, CAM_LUPD_USER = PRM_LUPDUSER
       WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_ID = PRM_ACCTID;

      IF SQL%ROWCOUNT = 0
      THEN
         PRM_ERRMSG := 'Acct  status cannot be updation failed';
         RETURN;
      END IF;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      PRM_ERRMSG := 'Error in acct close process ' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR