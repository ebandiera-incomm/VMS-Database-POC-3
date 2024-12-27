CREATE OR REPLACE PROCEDURE vmscms.sp_cardstatus_copy (
    PRM_INST_CODE     IN    NUMBER,
    PRM_FROMPROD_CODE IN    VARCHAR2,
    PRM_FROMPROD_CATG IN    VARCHAR2,
    PRM_TOPROD_CODE   IN    VARCHAR2,
    PRM_TOPROD_CATG   IN    VARCHAR2,
    PRM_USER          IN    NUMBER,
    p_resp_msg        OUT   VARCHAR2
)
IS
  /*************************************************
   * Created Date      :  05-Aug-2014
   * Created By        :  Abdul Hameed M.A
   * PURPOSE           :  For FWR-48
   * Build Number      : RI0027.3.1_B0002

  * Modified By      : Dhinakaran B
  * Modified Date    : 13/03/2019
  * Purpose          : VMS_812
  * Reviewer         : SaravanaKumar
  * Release Number   :VMSGPRHOST_R13_B0005

  * Modified By      : Jahnavi B
  * Modified Date    : 08-May-2019
  * Purpose          : VMS_867
  * Reviewer         : SaravanaKumar
  * Release Number   :VMSGPRHOST_R16_B0001
  *************************************************/
  P_ERROR_MSG         VARCHAR2 (900);
  EXP_REJECT_RECORD   EXCEPTION;
  V_MCC_ID            GPR_VALID_CARDSTAT.GVC_MCC_ID%TYPE;
  V_AUDIT_ID GPR_VALIDCARDSTAT_AUDIT.GVA_AUDIT_ID%TYPE;
  V_DATE              DATE;

BEGIN
  IF PRM_FROMPROD_CODE IS NOT NULL AND PRM_TOPROD_CODE IS NOT NULL AND  PRM_FROMPROD_CATG IS NOT NULL AND PRM_TOPROD_CATG IS NOT NULL THEN
    BEGIN
      P_ERROR_MSG := 'OK';

         BEGIN
          --Generating Sequence for Audit ID
                V_AUDIT_ID :=SEQ_CARDSTAT_AUDITID.NEXTVAL;
                V_DATE:=SYSDATE;
              EXCEPTION
              WHEN OTHERS THEN
                P_ERROR_MSG := 'Error While generating AUDIT ID'||SQLERRM;
                RAISE EXP_REJECT_RECORD;
          END;

        BEGIN
        --Copying Existing Records of 'to product category' from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table
          INSERT
          INTO GPR_VALIDCARDSTAT_AUDIT
            ( GVA_SEQ_NO,
              GVA_AUDIT_ID,
              GVA_AUDIT_USER,
              GVA_AUDIT_KEY,
              GVA_AUDIT_DATE,
              GVA_RECORD_TYPE,
              GVA_INST_CODE,
              GVA_CARD_STAT,
              GVA_TRAN_CODE,
              GVA_INS_USER,
              GVA_INS_DATE,
              GVA_LUPD_DATE,
              GVA_LUPD_USER,
              GVA_DELIVERY_CHANNEL,
              GVA_MSG_TYPE,
              GVA_STAT_FLAG,
              GVA_PROD_CODE,
              GVA_CARD_TYPE,
              GVA_APPROVE_TXN,
              GVA_INT_IND,
              GVA_PINSIGN,
              GVA_MCC_ID,
              GVA_CONFIG_TYPE
            )
            ( SELECT SEQ_CARDSTAT_SEQNO.NEXTVAL,
              V_AUDIT_ID,
              PRM_USER,
              (GVC_PROD_CODE || '~' || GVC_CARD_TYPE || '~' || GVC_STAT_FLAG || '~' || GVC_CARD_STAT || '~' ||
               GVC_DELIVERY_CHANNEL || '~' || GVC_INT_IND || '~' || GVC_PINSIGN || '~' || (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = GVC_MCC_ID)),
              V_DATE,
              'O',
              GVC_INST_CODE,
              GVC_CARD_STAT,
              GVC_TRAN_CODE,
              GVC_INS_USER,
              GVC_INS_DATE,
              GVC_LUPD_DATE,
              GVC_LUPD_USER,
              GVC_DELIVERY_CHANNEL,
              GVC_MSG_TYPE,
              GVC_STAT_FLAG,
              GVC_PROD_CODE,
              GVC_CARD_TYPE,
              GVC_APPROVE_TXN,
              GVC_INT_IND,
              GVC_PINSIGN,
              GVC_MCC_ID,
              'C' 
              FROM GPR_VALID_CARDSTAT 
              WHERE GVC_PROD_CODE = PRM_TOPROD_CODE
                AND GVC_CARD_TYPE   = PRM_TOPROD_CATG
                AND GVC_INST_CODE   = PRM_INST_CODE
              );

        EXCEPTION
        WHEN OTHERS THEN
          P_ERROR_MSG := 'Error on copy card status from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;


      BEGIN
      --Deleting existing 'to product category' records
        DELETE
        FROM CMS_MCC_TRAN
        WHERE cmt_mcc_id IN
          (SELECT gvc_mcc_id
          FROM GPR_VALID_CARDSTAT
          WHERE GVC_PROD_CODE = PRM_TOPROD_CODE
          AND GVC_CARD_TYPE   = PRM_TOPROD_CATG
          AND GVC_INST_CODE   = PRM_INST_CODE
          );
      EXCEPTION
      WHEN OTHERS THEN
        P_ERROR_MSG := 'Error on Delete CMS_MCC_TRAN:'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
      END;

      BEGIN
       --Deleting existing 'to product category' records
        DELETE
        FROM GPR_VALID_CARDSTAT
        WHERE GVC_PROD_CODE = PRM_TOPROD_CODE
        AND GVC_CARD_TYPE   = PRM_TOPROD_CATG
        AND GVC_INST_CODE   = PRM_INST_CODE;
      EXCEPTION
      WHEN OTHERS THEN
        P_ERROR_MSG := 'Error on Delete GPR_VALID_CARDSTAT:'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
      END;

       --Fetching  'from product category' records
      FOR C1 IN
      (SELECT GVC_INST_CODE,
        GVC_CARD_STAT,
        GVC_TRAN_CODE,
        GVC_INS_USER,
        SYSDATE GVC_INS_DATE,
        SYSDATE GVC_LUPD_DATE,
        GVC_LUPD_USER,
        GVC_DELIVERY_CHANNEL,
        GVC_MSG_TYPE,
        GVC_STAT_FLAG,
        PRM_TOPROD_CODE GVC_PROD_CODE,
        PRM_TOPROD_CATG GVC_CARD_TYPE,
        GVC_APPROVE_TXN,
        GVC_INT_IND,
        GVC_PINSIGN,
        GVC_MCC_ID
      FROM GPR_VALID_CARDSTAT
      WHERE GVC_PROD_CODE = PRM_FROMPROD_CODE
      AND GVC_CARD_TYPE   = PRM_FROMPROD_CATG
      AND GVC_INST_CODE   = PRM_INST_CODE
      )
      LOOP
        IF c1.GVC_MCC_ID IS NOT NULL THEN
        --generating mcc id
          BEGIN
            V_MCC_ID :=SEQ_MCC_ID.NEXTVAL;
          EXCEPTION
          WHEN OTHERS THEN
            P_ERROR_MSG := 'Error While generating MCC ID'||SQLERRM;
            RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_MCC_ID :=NULL;
        END IF;

        BEGIN
        --Creating new records for 'to product category'
          INSERT
          INTO GPR_VALID_CARDSTAT
            (
              GVC_INST_CODE,
              GVC_CARD_STAT,
              GVC_TRAN_CODE,
              GVC_INS_USER,
              GVC_INS_DATE,
              GVC_LUPD_DATE,
              GVC_LUPD_USER,
              GVC_DELIVERY_CHANNEL,
              GVC_MSG_TYPE,
              GVC_STAT_FLAG,
              GVC_PROD_CODE,
              GVC_CARD_TYPE,
              GVC_APPROVE_TXN,
              GVC_INT_IND,
              GVC_PINSIGN,
              GVC_MCC_ID
            )
            VALUES
            (
              C1.GVC_INST_CODE,
              C1.GVC_CARD_STAT,
              C1.GVC_TRAN_CODE,
              C1.GVC_INS_USER,
              C1.GVC_INS_DATE,
              C1.GVC_LUPD_DATE,
              C1.GVC_LUPD_USER,
              C1.GVC_DELIVERY_CHANNEL,
              C1.GVC_MSG_TYPE,
              C1.GVC_STAT_FLAG,
              C1.GVC_PROD_CODE,
              C1.GVC_CARD_TYPE,
              C1.GVC_APPROVE_TXN,
              C1.GVC_INT_IND,
              C1.GVC_PINSIGN,
              V_MCC_ID
            );
        EXCEPTION
        WHEN OTHERS THEN
          P_ERROR_MSG := 'Error on copy card status from product to product'||V_MCC_ID||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
        --Copying Existing Records of 'to product category' from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table
          INSERT
          INTO GPR_VALIDCARDSTAT_AUDIT
            ( GVA_SEQ_NO,
              GVA_AUDIT_ID,
              GVA_AUDIT_USER,
              GVA_AUDIT_KEY,
              GVA_AUDIT_DATE,
              GVA_RECORD_TYPE,
              GVA_INST_CODE,
              GVA_CARD_STAT,
              GVA_TRAN_CODE,
              GVA_INS_USER,
              GVA_INS_DATE,
              GVA_LUPD_DATE,
              GVA_LUPD_USER,
              GVA_DELIVERY_CHANNEL,
              GVA_MSG_TYPE,
              GVA_STAT_FLAG,
              GVA_PROD_CODE,
              GVA_CARD_TYPE,
              GVA_APPROVE_TXN,
              GVA_INT_IND,
              GVA_PINSIGN,
              GVA_MCC_ID,
              GVA_CONFIG_TYPE
            )
            VALUES
            (SEQ_CARDSTAT_SEQNO.NEXTVAL,
              V_AUDIT_ID,
              PRM_USER,
              (C1.GVC_PROD_CODE || '~' || C1.GVC_CARD_TYPE || '~' || c1.GVC_STAT_FLAG || '~' || c1.GVC_CARD_STAT || '~' ||
               c1.GVC_DELIVERY_CHANNEL || '~' || c1.GVC_INT_IND || '~' || c1.GVC_PINSIGN || '~' || (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = c1.GVC_MCC_ID)),
               V_DATE,
               'N',
              c1.GVC_INST_CODE,
              c1.GVC_CARD_STAT,
              c1.GVC_TRAN_CODE,
              c1.GVC_INS_USER,
              c1.GVC_INS_DATE,
              c1.GVC_LUPD_DATE,
              c1.GVC_LUPD_USER,
              c1.GVC_DELIVERY_CHANNEL,
              c1.GVC_MSG_TYPE,
              c1.GVC_STAT_FLAG,
              c1.GVC_PROD_CODE,
              c1.GVC_CARD_TYPE,
              c1.GVC_APPROVE_TXN,
              c1.GVC_INT_IND,
              c1.GVC_PINSIGN,
              V_MCC_ID,
              'C'
            );

        EXCEPTION
        WHEN OTHERS THEN
          P_ERROR_MSG := 'Error on copy card status from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
          IF V_MCC_ID IS NOT NULL THEN
          --Creating new records for 'to product category' mcc id
            INSERT
            INTO CMS_MCC_TRAN
              (
                CMT_INST_CODE,
                CMT_MCC_ID,
                CMT_MCC_CODE,
                CMT_INS_USER,
                CMT_LUPD_USER,
                CMT_INS_DATE,
                CMT_LUPD_DATE
              )
              VALUES
              (
                C1.GVC_INST_CODE,
                V_MCC_ID,
                (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = C1.GVC_MCC_ID),
                C1.GVC_INS_USER,
                C1.GVC_LUPD_USER,
                SYSDATE,
                SYSDATE
              );
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          P_ERROR_MSG := 'Error While inserting MCC Data'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;

      END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
      P_ERROR_MSG := 'Error on copy card status '||P_ERROR_MSG;
      RAISE EXP_REJECT_RECORD;
    END;
  ELSE
    P_ERROR_MSG := 'FROM OR TO Product  value is null';
  END IF;

  IF P_ERROR_MSG = 'OK' THEN
    BEGIN
    --Logging records
      INSERT
      INTO CMS_COPY_LOG
        (
          CCL_INST_CODE,
          CCL_LOG_ID,
          CCL_COPIED_TO,
          CCL_COPIED_FROM,
          CCL_FROMCARD_TYPE,
          CCL_TOCARD_TYPE,
          CCL_COPIED_TYPE,
          CCL_INS_DATE,
          CCL_INS_USER
        )
        VALUES
        (
          PRM_INST_CODE,
          CCL_LOG_ID.NEXTVAL,
          PRM_TOPROD_CODE,
          PRM_FROMPROD_CODE,
          PRM_FROMPROD_CATG,
          PRM_TOPROD_CATG,
          '1',
          SYSDATE,
          PRM_USER
        );
    EXCEPTION
    WHEN OTHERS THEN
      P_ERROR_MSG := 'Error on inserting details into CMS_COPY_LOG'||SQLERRM;
      RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  P_RESP_MSG := P_ERROR_MSG;

EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  P_RESP_MSG := 'EXP_REJECT_RECORD on '||P_ERROR_MSG;
  ROLLBACK;
END;
/
show error