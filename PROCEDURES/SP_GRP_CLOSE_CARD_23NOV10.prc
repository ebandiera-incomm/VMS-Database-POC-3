CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_close_card_23Nov10
  (
    p_instcode IN NUMBER,
    p_lupduser IN NUMBER,
    p_errmsg OUT VARCHAR2 )
AS
  v_mbrnumb VARCHAR2(3);
  v_remark CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_spprtrsn CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;
  v_cardstat CMS_APPL_PAN.cap_card_stat%TYPE;
  v_cardstatdesc VARCHAR2(10);
  v_prod_catg CMS_APPL_PAN.cap_prod_catg%type;
  v_txn_code       VARCHAR2 (2);
  v_txn_type       VARCHAR2 (2);
  v_txn_mode       VARCHAR2 (2);
  v_del_channel    VARCHAR2 (2);
  v_closesavepoint NUMBER;
  v_resoncode      NUMBER (3);
  v_reasondesc CMS_SPPRT_REASONS.csr_reasondesc%TYPE;
  v_succ_flag VARCHAR2 (1);
  v_errmsg    VARCHAR2 (300);
  v_errflag CHAR (1);
  exp_loop_reject_record exception;
  CURSOR c1
  IS
    SELECT TRIM(cgc_pan_code) cgc_pan_code ,
      cgc_remark ,
      ROWID ROW_ID,
      cgc_mbr_numb,
      cgc_file_name
    FROM cms_group_cardclose_temp
    WHERE CGC_PROCESS_FLAG = 'N' --kirti 23 jun 10 CGC_PIN_CLOSE = 'N' 
    AND cgc_inst_code= p_instcode;
BEGIN
  p_errmsg := 'OK';
  v_remark := 'GROUP CLOSE';
  ------------------------------ Sn get Function Master----------------------------
  BEGIN
    SELECT cfm_txn_code,
      cfm_txn_mode,
      cfm_delivery_channel,
      cfm_txn_type
    INTO v_txn_code,
      v_txn_mode,
      v_del_channel,
      v_txn_type
    FROM CMS_FUNC_MAST
    WHERE cfm_func_code = 'CRDCLOSE'
    AND cfm_inst_code   = p_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg := 'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------
  ------------------------------Sn get reason code from support reason master----------------------------
  BEGIN
    SELECT csr_spprt_rsncode,
      csr_reasondesc
    INTO v_resoncode,
      v_reasondesc
    FROM CMS_SPPRT_REASONS
    WHERE csr_spprt_key = 'CARDCLOSE'
    AND ROWNUM          < 2
    AND csr_inst_code   = p_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_errmsg := 'Card close  reason code not present in master';
    RETURN;
  WHEN OTHERS THEN
    p_errmsg := 'Error while selecting reason code from master' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  ------------------------------En get reason code from support reason master---------------------------------
  FOR x IN c1
  LOOP
    BEGIN --Loop begin
      v_errmsg         :='OK';
      v_closesavepoint := v_closesavepoint + 1;
      SAVEPOINT v_closesavepoint;
      v_prod_catg := NULL;
      v_cardstat  := NULL;
      ---------------------
      -- SN FIND PROD CATG
      --------------------
      BEGIN
        SELECT cap_prod_catg,
          cap_card_stat
        INTO v_prod_catg,
          v_cardstat
        FROM CMS_APPL_PAN
        WHERE cap_pan_code = x.cgc_pan_code
        AND cap_inst_code  = p_instcode;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'Product category not defined in master';
        RAISE exp_loop_reject_record;
      WHEN OTHERS THEN
        v_errmsg := 'Error while selecting product category '|| SUBSTR(sqlerrm,1,200);
        RAISE exp_loop_reject_record;
      END;
      --------------------
      --EN FIND PROD CATG
      --------------------
      IF v_cardstat <>1 THEN
        p_errmsg :='Invalid card status for closing activity';
        RAISE exp_loop_reject_record;
      END IF;
      IF v_prod_catg = 'P' THEN
        NULL;
      ELSIF v_prod_catg in('D','A') THEN
        sp_close_pan_debit ( p_instcode , x.cgc_pan_code , x.cgc_mbr_numb , v_resoncode, x.cgc_remark , p_lupduser , 0 ,v_errmsg  ) ;
        IF v_errmsg   <> 'OK' THEN
          v_succ_flag := 'E';
          RAISE exp_loop_reject_record;
        elsif v_errmsg = 'OK' THEN
          v_errflag   := 'S';
          v_errmsg    := 'Successful';
          v_succ_flag := 'S';
          BEGIN
            UPDATE cms_group_cardclose_temp
            SET cgc_process_flag = 'S',
              cgc_process_msg    = v_errmsg
            WHERE ROWID = x.ROW_ID;
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while updating record in grp cardclose temp table' || SUBSTR(sqlerrm,1,150);
            RAISE exp_loop_reject_record;
          END;
        END IF;
        BEGIN
          INSERT INTO CMS_CRDCLOSE_DETAIL ( 
                                      CCD_INST_CODE,
                                      CCD_CARD_NO,
                                      CCD_FILE_NAME,
                                      CCD_REMARKS,
                                      CCD_MSG24_FLAG,
                                      CCD_PROCESS_FLAG,
                                      CCD_PROCESS_MSG,
                                      CCD_PROCESS_MODE,
                                      CCD_INS_USER,
                                      CCD_INS_DATE,
                                      CCD_LUPD_USER,
                                      CCD_LUPD_DATE                                      
                                  ) 
                            VALUES(   p_instcode,
                                      x.cgc_pan_code,
                                      x.cgc_file_name,
                                      x.cgc_remark,
                                      'N',
                                      'S',
                                      'SUCCESSFUL',
                                      'G',
                                      p_lupduser,
                                      sysdate,
                                      p_lupduser,
                                      sysdate
                                  );
        EXCEPTION
        WHEN VALUE_ERROR THEN
          v_errmsg := ' Error while inserting in to CMS CRDCLOSE DETAIL';
          RAISE exp_loop_reject_record;
        WHEN OTHERS THEN
          v_errmsg :='Error while inserting records CMS CRDCLOSE DETAIL from master'|| SUBSTR ( SQLERRM, 1, 200 ) ;
          RAISE exp_loop_reject_record;
        END;
      END IF;
    EXCEPTION --<< LOOP I EXCEPTION >>
    WHEN exp_loop_reject_record THEN
      ROLLBACK TO v_closesavepoint;
      v_succ_flag := 'E';
      UPDATE cms_group_cardclose_temp
      SET cgc_process_flag = 'E',
        cgc_process_msg    = v_errmsg
      WHERE ROWID          = x.ROW_ID;
      INSERT
      INTO CMS_CRDCLOSE_DETAIL
        (
          CCD_INST_CODE,
          CCD_CARD_NO,
          CCD_FILE_NAME,
          CCD_REMARKS,
          CCD_MSG24_FLAG,
          CCD_PROCESS_FLAG,
          CCD_PROCESS_MSG,
          CCD_PROCESS_MODE,
          CCD_INS_USER,
          CCD_INS_DATE,
          CCD_LUPD_USER,
          CCD_LUPD_DATE
        )
        VALUES
        (
          p_instcode,
          x.cgc_pan_code,
          x.cgc_file_name,
          x.cgc_remark,
          'N',
          'E',
          v_errmsg,
          'G',
          p_lupduser,
          sysdate,
          p_lupduser,
          sysdate
        );
    WHEN OTHERS THEN
      ROLLBACK TO v_closesavepoint;
      v_succ_flag := 'E';
      v_errmsg    := 'Error while processing group acct link ' || SUBSTR
      (
        sqlerrm,1,150
      )
      ;
      UPDATE cms_group_cardclose_temp
      SET cgc_process_flag = 'E',
        cgc_process_msg    = v_errmsg
      WHERE ROWID          = x.ROW_ID;
      
      INSERT INTO CMS_CRDCLOSE_DETAIL (
                                        CCD_INST_CODE,
                                        CCD_CARD_NO,
                                        CCD_FILE_NAME,
                                        CCD_REMARKS,
                                        CCD_MSG24_FLAG,
                                        CCD_PROCESS_FLAG,
                                        CCD_PROCESS_MSG,
                                        CCD_PROCESS_MODE,
                                        CCD_INS_USER,
                                        CCD_INS_DATE,
                                        CCD_LUPD_USER,
                                        CCD_LUPD_DATE ) 
                                VALUES (
                                        p_instcode,
                                        x.cgc_pan_code,
                                        x.cgc_file_name,
                                        x.cgc_remark,
                                        'N',
                                        'E',
                                        v_errmsg,
                                        'G',
                                        p_lupduser,
                                        sysdate,
                                        p_lupduser,
                                        sysdate);
    END;--<< LOOP I END >>
    BEGIN
      INSERT
      INTO PROCESS_AUDIT_LOG
        (
          pal_card_no,
          pal_activity_type,
          pal_transaction_code,
          pal_delv_chnl,
          pal_tran_amt,
          pal_source,
          pal_success_flag,
          pal_ins_user,
          pal_ins_date,
          pal_process_msg,
          pal_reason_desc,
          pal_remarks,
          pal_spprt_type,
		  pal_inst_code
        )
        VALUES
        (
          x.cgc_pan_code,
          'Group close card',
          v_txn_code,
          v_del_channel,
          0,
          'HOST',
          v_succ_flag,
          p_lupduser,
          SYSDATE,
          v_errmsg,
          v_reasondesc,
          x.cgc_remark,
          'G',
		  p_instcode
        );
    EXCEPTION
    WHEN OTHERS THEN
      --p_errmsg := 'Pan Not Found in Master';
      UPDATE cms_group_cardclose_temp
      SET cgc_process_flag = 'E',
        cgc_process_msg    = 'Error while inserting into Audit log'
      WHERE ROWID          = x.ROW_ID;
    END;
    --------end inserting record in audit log--------
  END LOOP;
  p_errmsg := 'OK';
EXCEPTION
WHEN OTHERS THEN
  p_errmsg := 'MAIN EXCP FROM SP_GRP_CLOSE : '||SQLERRM;
END;
/


