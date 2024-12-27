CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHANGE_ADDR_DEBIT(PRM_INSTCODE     IN NUMBER,
                                        PRM_PANCODE      IN VARCHAR2,
                                        PRM_MBRNUMB      IN VARCHAR2,
                                        PRM_REMARK       IN VARCHAR2,
                                        PRM_ADDRCODE     IN NUMBER,
                                        PRM_RSNCODE      IN NUMBER,
                                        PRM_CUSTOMERCODE IN NUMBER,
                                        PRM_ADDRESSLINE1 IN VARCHAR2,
                                        PRM_ADDRESSLINE2 IN VARCHAR2,
                                        PRM_ADDRESSLINE3 IN VARCHAR2,
                                        PRM_PINCODE      IN VARCHAR2,
                                        PRM_PHONE1       IN VARCHAR2,
                                        PRM_PHONE2       IN VARCHAR2,
                                        PRM_COUNTRYCODE  IN VARCHAR2,
                                        PRM_CITYNAME     IN VARCHAR2,
                                        PRM_STATENAME    IN VARCHAR2,
                                        PRM_FAX1         IN VARCHAR2,
                                        PRM_ADDRESSFLAG  IN VARCHAR2,
                                        PRM_LUPDUSER     IN NUMBER,
                                        PRM_WORKMODE     IN NUMBER,
                                        PRM_NEWADDRCODE  OUT NUMBER,
                                        PRM_ERRMSG       OUT VARCHAR2) AS
  DUM             NUMBER(1);
  V_CAP_PROD_CATG VARCHAR2(2);
  --v_mbrnumb           VARCHAR2 (3);
  V_CAP_CAFGEN_FLAG CHAR(1);
  V_RECORD_EXIST    CHAR(1) := 'Y';
  V_CAFFILEGEN_FLAG CHAR(1) := 'N';
  V_ISSUESTATUS     VARCHAR2(2);
  V_PINMAILER       VARCHAR2(1);
  V_CARDCARRIER     VARCHAR2(1);
  V_PINOFFSET       VARCHAR2(16);
  V_REC_TYPE        VARCHAR2(1);
  V_ADDRCODE        NUMBER;
  L_ADDRCODE        NUMBER;
  V_BILL_ADDR       CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
  V_COMM_TYPE       CHAR(1);
  V_GEN_ADDR        TYPE_ADDR_REC_ARRAY;
  V_TRAN_CODE       VARCHAR2(2);
  V_TRAN_MODE       VARCHAR2(1);
  V_TRAN_TYPE       VARCHAR2(1);
  V_DELV_CHNL       VARCHAR2(2);
  V_FEETYPE_CODE    CMS_FEE_MAST.CFM_FEETYPE_CODE%TYPE;
  V_FEE_CODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_AMT         NUMBER(4);
  V_ACCT_NO         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_ACCT_ID         CMS_APPL_PAN.CAP_ACCT_ID%TYPE;
  V_CUST_CODE       CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_INSTA_CHECK     CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_HASH_PAN        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN        CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;

BEGIN
  --Main begin starts
  /* IF mbrnumb IS NULL
  THEN
        v_mbrnumb := '000';
   ELSE
        v_mbrnumb := mbrnumb;
  END IF;
  << commented because passing member number is mandatory. >>
  */

  PRM_ERRMSG := 'OK';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_PANCODE);
  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(PRM_PANCODE);
  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  --EN create encr pan

  BEGIN
    --begin 1 starts
    SELECT CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_BILL_ADDR,
         CAP_ACCT_NO,
         CAP_CUST_CODE,
         CAP_CARD_STAT
     INTO V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_BILL_ADDR,
         V_ACCT_NO,
         V_CUST_CODE,
         V_CAP_CARD_STAT
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = PRM_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN --prm_pancode
         AND CAP_MBR_NUMB = PRM_MBRNUMB;
  EXCEPTION
    --excp of begin 1
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'PAN not found';
     RETURN;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while selecting the product category,bill address for PAN' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END; --begin 1 ends

  IF V_CAP_CAFGEN_FLAG = 'N' THEN
    --cafgen if
    PRM_ERRMSG := 'CAF has to be generated atleast once for this pan';
    RETURN;
  END IF;

  ----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
  BEGIN
    SELECT CIP_PARAM_VALUE
     INTO V_INSTA_CHECK
     FROM CMS_INST_PARAM
    WHERE CIP_PARAM_KEY = 'INSTA_CARD_CHECK' AND
         CIP_INST_CODE = PRM_INSTCODE;

    IF V_INSTA_CHECK = 'Y' THEN
     SP_GEN_INSTA_CHECK(V_ACCT_NO, V_CAP_CARD_STAT, PRM_ERRMSG);
     IF PRM_ERRMSG <> 'OK' THEN
       RETURN;
     END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while checking the instant card validation. ' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  ----------En start insta card check----------

  ------------------------------------------------Sn Pick comm type from addr mast ------------------------------------
  BEGIN
    SELECT CAM_COMM_TYPE,
         TYPE_ADDR_REC_ARRAY(CAM_ADDRMAST_PARAM1,
                         CAM_ADDRMAST_PARAM2,
                         CAM_ADDRMAST_PARAM3,
                         CAM_ADDRMAST_PARAM4,
                         CAM_ADDRMAST_PARAM5,
                         CAM_ADDRMAST_PARAM6,
                         CAM_ADDRMAST_PARAM7,
                         CAM_ADDRMAST_PARAM8,
                         CAM_ADDRMAST_PARAM9,
                         CAM_ADDRMAST_PARAM10)
     INTO V_COMM_TYPE, V_GEN_ADDR
     FROM CMS_ADDR_MAST
    WHERE CAM_ADDR_CODE = V_BILL_ADDR AND CAM_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'Addr Communication Type is not found';
     RETURN;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while selecting Addr Communication Type ' ||
                SUBSTR(SQLERRM, 1, 300);
     RETURN;
  END;

  ------------------------------------------------EN Pick comm type from addr mast --------------------------------------
  -------------start calculate fees offline bebit-----------------------------
  BEGIN
    SELECT CFM_TXN_CODE, CFM_TXN_MODE, CFM_DELIVERY_CHANNEL, CFM_TXN_TYPE
     INTO V_TRAN_CODE, V_TRAN_MODE, V_DELV_CHNL, V_TRAN_TYPE
     FROM CMS_FUNC_MAST
    WHERE CFM_INST_CODE = PRM_INSTCODE AND CFM_FUNC_CODE = 'ADDR';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'Support function reissue not defined in master ';
     RETURN;
    WHEN TOO_MANY_ROWS THEN
     PRM_ERRMSG := 'More than one record found in master for reissue support func ';
     RETURN;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while selecting reissue fun detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  --start Fees details for reissue---
  SP_CALC_FEES_OFFLINE_DEBIT(PRM_INSTCODE,
                        PRM_PANCODE,
                        V_TRAN_CODE,
                        V_TRAN_MODE,
                        V_DELV_CHNL,
                        V_TRAN_TYPE,
                        V_FEETYPE_CODE,
                        V_FEE_CODE,
                        V_FEE_AMT,
                        PRM_ERRMSG);
  IF PRM_ERRMSG <> 'OK' THEN
    RETURN;
  END IF;
  --End fee details for reissue
  --Start inserting fee amt in charge table--
  IF V_FEE_AMT > 0 THEN
    BEGIN
     INSERT INTO CMS_CHARGE_DTL
       (CCD_INST_CODE,
        CCD_FEE_TRANS,
        CCD_PAN_CODE,
        CCD_MBR_NUMB,
        CCD_CUST_CODE,
        CCD_ACCT_ID,
        CCD_ACCT_NO,
        CCD_FEE_FREQ,
        CCD_FEETYPE_CODE,
        CCD_FEE_CODE,
        CCD_CALC_AMT,
        CCD_EXPCALC_DATE,
        CCD_CALC_DATE,
        CCD_FILE_DATE,
        CCD_FILE_NAME,
        CCD_FILE_STATUS,
        CCD_INS_USER,
        CCD_INS_DATE,
        CCD_LUPD_USER,
        CCD_LUPD_DATE,
        CCD_PROCESS_ID,
        CCD_PLAN_CODE,
        CCD_PAN_CODE_ENCR)
     VALUES
       (PRM_INSTCODE,
        NULL,
        --prm_pancode
        V_HASH_PAN,
        NULL,
        V_CUST_CODE,
        V_ACCT_ID,
        V_ACCT_NO,
        'R',
        V_FEETYPE_CODE,
        V_FEE_CODE,
        V_FEE_AMT,
        SYSDATE,
        SYSDATE,
        NULL,
        NULL,
        NULL,
        PRM_LUPDUSER,
        SYSDATE,
        PRM_LUPDUSER,
        SYSDATE,
        NULL,
        NULL,
        V_ENCR_PAN);
    EXCEPTION
     WHEN OTHERS THEN
       PRM_ERRMSG := ' Error while inserting into charge dtl ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RETURN;
    END;
  END IF;

  --start inserting fee amt in charge table--
  -------------End calculate fees offline bebit-----------------------------

  IF PRM_ADDRESSFLAG = 'E' THEN
    BEGIN
     SP_CREATE_ADDR(PRM_INSTCODE,
                 PRM_CUSTOMERCODE,
                 PRM_ADDRESSLINE1,
                 PRM_ADDRESSLINE2,
                 PRM_ADDRESSLINE3,
                 PRM_PINCODE,
                 PRM_PHONE1,
                 PRM_PHONE2,
                 NULL,
                 NULL,
                 PRM_COUNTRYCODE,
                 PRM_CITYNAME,
                 PRM_STATENAME, --state as coming from switch
                 PRM_FAX1,
                 PRM_ADDRESSFLAG,
                 V_COMM_TYPE,
                 PRM_LUPDUSER,
                 V_GEN_ADDR,
                 L_ADDRCODE,
                 PRM_ERRMSG);
     IF PRM_ERRMSG != 'OK' THEN
       PRM_ERRMSG := 'error while creating new address' || PRM_ERRMSG;
     END IF;
     --IF  v_addrcode IS NULL OR v_addrcode = 0 THEN
     --errmsg := 'error while creating new address'||errmsg;
     --END IF;
    EXCEPTION
     WHEN OTHERS THEN
       PRM_ERRMSG := 'error while creating new address' || PRM_ERRMSG;
       RETURN;
    END;

  END IF;

  BEGIN
    IF PRM_ADDRCODE IS NULL THEN
     V_ADDRCODE      := L_ADDRCODE;
     PRM_NEWADDRCODE := L_ADDRCODE;
    ELSE
     V_ADDRCODE := PRM_ADDRCODE;
    END IF; --Begin 2
    UPDATE CMS_APPL_PAN
      SET CAP_BILL_ADDR = V_ADDRCODE
    WHERE CAP_INST_CODE = PRM_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN --prm_pancode
         AND CAP_MBR_NUMB = PRM_MBRNUMB;

    IF SQL%ROWCOUNT != 1 THEN
     PRM_ERRMSG := 'Problem in updation of address for pan ' ||
                PRM_PANCODE || '.';
     RETURN;
    END IF;
  EXCEPTION
    --Excp of begin 2
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while updating address for pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END; --End of begin 2

  BEGIN

    UPDATE CMS_ADDR_MAST
      SET CAM_ADDR_FLAG = 'E'
    WHERE CAM_CUST_CODE = PRM_CUSTOMERCODE AND CAM_ADDR_FLAG = 'P' AND
         CAM_INST_CODE = PRM_INSTCODE;

    UPDATE CMS_ADDR_MAST
      SET CAM_ADDR_FLAG = 'P'
    WHERE CAM_ADDR_CODE = V_ADDRCODE AND CAM_CUST_CODE = PRM_CUSTOMERCODE AND
         CAM_INST_CODE = PRM_INSTCODE;

    IF SQL%ROWCOUNT != 1 THEN
     PRM_ERRMSG := 'Problem in updation of primary address ' ||
                PRM_PANCODE || '.';
     RETURN;
    END IF;
  END;

  ----------------------------------start insert records  in pan support-----------------------------
  BEGIN
    INSERT INTO CMS_PAN_SPPRT
     (CPS_INST_CODE,
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
    VALUES
     (PRM_INSTCODE, --prm_pancode
      V_HASH_PAN,
      PRM_MBRNUMB,
      V_CAP_PROD_CATG,
      'ADDR',
      PRM_RSNCODE,
      PRM_REMARK,
      PRM_LUPDUSER,
      PRM_LUPDUSER,
      PRM_WORKMODE,
      V_ENCR_PAN);
  EXCEPTION

    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while inserting category of support function' ||
                SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  ---------------------------------------End insert records  in pan support----------------------------

  -----------------------------------start Caf Refresh-------------------------------
  BEGIN
    --Begin 3
    BEGIN
     SELECT CCI_FILE_GEN,
           CCI_SEG12_ISSUE_STAT,
           CCI_SEG12_PIN_MAILER,
           CCI_SEG12_CARD_CARRIER,
           CCI_PIN_OFST,
           CCI_REC_TYP
       INTO V_CAFFILEGEN_FLAG,
           V_ISSUESTATUS,
           V_PINMAILER,
           V_CARDCARRIER,
           V_PINOFFSET,
           V_REC_TYPE
       FROM CMS_CAF_INFO
      WHERE CCI_INST_CODE = PRM_INSTCODE AND CCI_PAN_CODE = V_HASH_PAN --DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
          --  19,prm_pancode)
          -- RPAD (pancode, 19, ' ')
           AND CCI_MBR_NUMB = PRM_MBRNUMB
      GROUP BY CCI_FILE_GEN,
             CCI_SEG12_ISSUE_STAT,
             CCI_SEG12_PIN_MAILER,
             CCI_SEG12_CARD_CARRIER,
             CCI_PIN_OFST,
             CCI_REC_TYP;

     DELETE FROM CMS_CAF_INFO
      WHERE CCI_INST_CODE = PRM_INSTCODE AND CCI_PAN_CODE = V_HASH_PAN -- DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
          -- 19,prm_pancode)-- RPAD (pancode, 19, ' ')
           AND CCI_MBR_NUMB = PRM_MBRNUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RECORD_EXIST := 'N';
     WHEN OTHERS THEN
       PRM_ERRMSG := 'Error while selecting from caf info ' ||
                  SUBSTR(SQLERRM, 1, 300);
       RETURN;
    END;

    --call the procedure to insert into cafinfo
    SP_CAF_RFRSH(PRM_INSTCODE,
              --prm_pancode
              PRM_PANCODE,
              PRM_MBRNUMB,
              SYSDATE,
              'C',
              NULL,
              'ADDRUPD',
              PRM_LUPDUSER,
              PRM_PANCODE,
              PRM_ERRMSG);
    IF PRM_ERRMSG != 'OK' THEN
     PRM_ERRMSG := 'From caf refresh -- ' || PRM_ERRMSG;
     RETURN;
    END IF;
    -----------------start Update caf_info only if record was exist earlier-----------------------------------
    IF V_REC_TYPE = 'A' THEN
     V_ISSUESTATUS := '00'; -- no pinmailer no embossa.
     V_PINOFFSET   := RPAD('Z', 16, 'Z'); -- keep original pin .
    END IF;

    IF /*prm_workmode = 1 AND*/
    V_RECORD_EXIST = 'Y' THEN
     BEGIN
       UPDATE CMS_CAF_INFO
         SET CCI_FILE_GEN           = V_CAFFILEGEN_FLAG,
            CCI_SEG12_ISSUE_STAT   = V_ISSUESTATUS,
            CCI_SEG12_PIN_MAILER   = V_PINMAILER,
            CCI_SEG12_CARD_CARRIER = V_CARDCARRIER,
            CCI_PIN_OFST           = V_PINOFFSET
        WHERE CCI_INST_CODE = PRM_INSTCODE AND CCI_PAN_CODE = V_HASH_PAN --DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
            -- 19,prm_pancode)
            AND CCI_MBR_NUMB = PRM_MBRNUMB;
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERRMSG := 'Error while updating the caf info when record exist ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RETURN;
     END;
    END IF;
    -------------------End Update caf_info only if record was exist earlier-----------------------------------

    /*-----------------start Update caf_info only if record was not exist-------------------------------------
          IF prm_workmode = 1 AND v_record_exist = 'N'
          THEN
            BEGIN
             UPDATE CMS_CAF_INFO
                SET cci_file_gen = 'Y'
              WHERE cci_inst_code = prm_instcode
                AND cci_pan_code =  DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                    19,prm_pancode) --RPAD (pancode, 19, ' ')
                AND cci_mbr_numb = prm_mbrnumb;
            EXCEPTION WHEN OTHERS THEN
                prm_errmsg:='Error while updating the caf info when no record exist '||substr(SQLERRM,1,200);
                RETURN;
            END;
          END IF;
    -----------------End Update caf_info only if record was not exist-------------------------------------*/
  EXCEPTION
    --Excp 3
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Error while updating caf ' || SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END; --End of begin 3
  ------------------------------------------End caf refresh---------------------------------------------

EXCEPTION
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Error while updating address' || SUBSTR(SQLERRM, 1, 200);
END;
/


