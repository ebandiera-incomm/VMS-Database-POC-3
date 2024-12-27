CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACCT_CLOSE (
   PRM_INSTCODE   IN     NUMBER,
   PRM_ACCTNO     IN     VARCHAR2,
   PRM_REMARK     IN     VARCHAR2,
   PRM_RSNCODE    IN     NUMBER,
   PRM_LUPDUSER   IN     NUMBER,
   PRM_WORKMODE   IN     NUMBER,
   PRM_ERRMSG        OUT VARCHAR2)
AS
   V_PROD_CATG         CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
   V_ERRMSG            VARCHAR2 (500);
   V_MBRNUMB           CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
   V_ACCTID            CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
   V_CHECK_ACCT        NUMBER (1);
   V_CHECK_REL         NUMBER (1);
   EXP_REJECT_RECORD   EXCEPTION;
   V_LINK_ERRMSG       VARCHAR2 (300);
   V_TRAN_CODE         CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
   V_TRAN_MODE         CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
   V_DELV_CHNL         CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
   V_SAVEPOINT         NUMBER DEFAULT 0;
   V_ACCT_STAT         CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
   V_REASONDESC        CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   V_ENCR_PAN          CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
BEGIN
   V_SAVEPOINT := V_SAVEPOINT + 1;
   SAVEPOINT V_SAVEPOINT;
   PRM_ERRMSG := 'OK';

   BEGIN
      SELECT 1
        INTO V_CHECK_ACCT
        FROM CMS_ACCT_MAST
       WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_NO = PRM_ACCTNO;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'Account no not defined in master';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting account no ' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT DISTINCT CAP_PROD_CATG
        INTO V_PROD_CATG
        FROM CMS_PAN_ACCT, CMS_APPL_PAN, CMS_ACCT_MAST
       WHERE     CAP_MBR_NUMB = CPA_MBR_NUMB
             AND CAP_PAN_CODE = CPA_PAN_CODE
             AND CAM_ACCT_ID = CPA_ACCT_ID
             AND CAM_INST_CODE = CPA_INST_CODE
             AND CAM_ACCT_NO = PRM_ACCTNO
             AND CAM_INST_CODE = PRM_INSTCODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'Product category not defined in master';
         RAISE EXP_REJECT_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         V_ERRMSG :=
            'More than one type of product category is linked to this account, can not be closed ';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting product category '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT CIP_PARAM_VALUE
        INTO V_MBRNUMB
        FROM CMS_INST_PARAM
       WHERE CIP_INST_CODE = PRM_INSTCODE AND CIP_PARAM_KEY = 'MBR_NUMB';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'memeber number not defined in master';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting memeber number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT CFM_TXN_CODE, CFM_TXN_MODE, CFM_DELIVERY_CHANNEL
        INTO V_TRAN_CODE, V_TRAN_MODE, V_DELV_CHNL
        FROM CMS_FUNC_MAST
       WHERE CFM_INST_CODE = PRM_INSTCODE AND CFM_FUNC_CODE = 'ACCCLOSE';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'Support function acct close not defined in master ';
         RAISE EXP_REJECT_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         V_ERRMSG :=
            'More than one record found in master for acct close support func ';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting acct close function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT CSR_REASONDESC
        INTO V_REASONDESC
        FROM CMS_SPPRT_REASONS
       WHERE     CSR_SPPRT_KEY = 'ACCCLOSE'
             AND CSR_SPPRT_RSNCODE = PRM_RSNCODE
             AND CSR_INST_CODE = PRM_INSTCODE
             AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'Account close reason code not present in master';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT CAM_ACCT_ID, CAM_STAT_CODE
        INTO V_ACCTID, V_ACCT_STAT
        FROM CMS_ACCT_MAST
       WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_NO = PRM_ACCTNO;

      IF V_ACCT_STAT = 2
      THEN
         V_ERRMSG := 'Account is already closed';
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         V_ERRMSG := 'Account number not defined in master';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while selecting account number from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   IF V_PROD_CATG = 'P'
   THEN
      NULL;
   ELSIF V_PROD_CATG IN ('D', 'A')
   THEN
      SP_ACCT_CLOSE_DEBIT (PRM_INSTCODE,
                           V_ACCTID,
                           PRM_RSNCODE,
                           PRM_REMARK,
                           PRM_LUPDUSER,
                           V_ERRMSG);

      IF V_ERRMSG <> 'OK'
      THEN
         RAISE EXP_REJECT_RECORD;
      END IF;

      BEGIN
         INSERT INTO CMS_ACCTCLOSE_DETAIL (CRD_INST_CODE,
                                           CRD_ACCT_NO,
                                           CRD_FILE_NAME,
                                           CRD_REMARKS,
                                           CRD_MSG24_FLAG,
                                           CRD_PROCESS_FLAG,
                                           CRD_PROCESS_MSG,
                                           CRD_PROCESS_MODE,
                                           CRD_INS_USER,
                                           CRD_INS_DATE,
                                           CRD_LUPD_USER)
              VALUES (PRM_INSTCODE,
                      PRM_ACCTNO,
                      NULL,
                      PRM_REMARK,
                      'N',
                      'S',
                      'Successful',
                      'S',
                      PRM_LUPDUSER,
                      SYSDATE,
                      PRM_LUPDUSER);
      EXCEPTION
         WHEN OTHERS
         THEN
            PRM_ERRMSG :=
               'Error while creating record in detail table '
               || SUBSTR (SQLERRM, 1, 150);
            RETURN;
      END;


      BEGIN
         V_ENCR_PAN := FN_EMAPS_MAIN (PRM_ACCTNO);
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERRMSG :=
               'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;

      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG (PAL_INST_CODE,
                                        PAL_CARD_NO,
                                        PAL_ACTIVITY_TYPE,
                                        PAL_TRANSACTION_CODE,
                                        PAL_DELV_CHNL,
                                        PAL_TRAN_AMT,
                                        PAL_SOURCE,
                                        PAL_SUCCESS_FLAG,
                                        PAL_INS_USER,
                                        PAL_INS_DATE,
                                        PAL_PROCESS_MSG,
                                        PAL_REASON_DESC,
                                        PAL_REMARKS,
                                        PAL_SPPRT_TYPE,
                                        PAL_CARD_NO_ENCR)
              VALUES (PRM_INSTCODE,
                      PRM_ACCTNO,
                      'Account close',
                      V_TRAN_CODE,
                      V_DELV_CHNL,
                      0,
                      'HOST',
                      'S',
                      PRM_LUPDUSER,
                      SYSDATE,
                      'Successful',
                      V_REASONDESC,
                      PRM_REMARK,
                      'S',
                      V_ENCR_PAN);
      EXCEPTION
         WHEN OTHERS
         THEN
            PRM_ERRMSG :=
               'Error while creating record in detail table '
               || SUBSTR (SQLERRM, 1, 150);
            RETURN;
      END;
   ELSE
      V_ERRMSG := 'Not a valid product for acct close';
      RAISE EXP_REJECT_RECORD;
   END IF;
EXCEPTION
   WHEN EXP_REJECT_RECORD
   THEN
      ROLLBACK TO V_SAVEPOINT;
      SP_ACCTCLOSE_SUPPORT_LOG (PRM_INSTCODE,
                                PRM_ACCTNO,
                                NULL,
                                PRM_REMARK,
                                'N',
                                'E',
                                V_ERRMSG,
                                'S',
                                PRM_LUPDUSER,
                                SYSDATE,
                                'Account close',
                                V_TRAN_CODE,
                                V_DELV_CHNL,
                                0,
                                'HOST',
                                V_REASONDESC,
                                'S',
                                PRM_ERRMSG);

      IF PRM_ERRMSG <> 'OK'
      THEN
         RETURN;
      ELSE
         PRM_ERRMSG := V_ERRMSG;
      END IF;
   WHEN OTHERS
   THEN
      V_ERRMSG := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
      SP_ACCTCLOSE_SUPPORT_LOG (PRM_INSTCODE,
                                PRM_ACCTNO,
                                NULL,
                                PRM_REMARK,
                                'N',
                                'E',
                                V_ERRMSG,
                                'S',
                                PRM_LUPDUSER,
                                SYSDATE,
                                'Account close',
                                V_TRAN_CODE,
                                V_DELV_CHNL,
                                0,
                                'HOST',
                                V_REASONDESC,
                                'S',
                                PRM_ERRMSG);

      IF PRM_ERRMSG <> 'OK'
      THEN
         RETURN;
      ELSE
         PRM_ERRMSG := V_ERRMSG;
      END IF;
END;
/

SHOW ERROR