CREATE OR REPLACE PROCEDURE VMSCMS.SP_BANK_GET_ACTID
  (
    p_instcode        IN VARCHAR2 ,
    p_pan_code        IN VARCHAR2 ,
    p_new_acct_no     IN VARCHAR2 ,
    p_primary_acct_no IN VARCHAR2 ,
    p_lupduser        IN VARCHAR2,
    prm_acct_id OUT CMS_ACCT_MAST.cam_acct_id%type,
    p_errmsg OUT VARCHAR2 )
IS
  v_acct_type_tmp VARCHAR2(5) ;
  v_cam_acct_id CMS_ACCT_MAST.cam_acct_id%TYPE ;
  v_acct_stat CMS_ACCT_MAST.cam_stat_code%TYPE ;
  v_bill_addr CMS_ACCT_MAST.cam_bill_addr%TYPE ;
  v_type_code CMS_ACCT_TYPE.cat_type_code%TYPE ;
  v_dup_flag VARCHAR2(10) ;
BEGIN
  SAVEPOINT v_savepoint ;
  p_errmsg := 'OK';
  BEGIN
    IF p_instcode = 3 THEN
      SELECT cam_acct_id
      INTO prm_acct_id
      FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = p_instcode
      AND CAM_ACCT_NO     = SUBSTR(p_new_acct_no,7,9) ;
    ELSIF p_instcode      = 4 THEN
      SELECT cam_acct_id
      INTO prm_acct_id
      FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = p_instcode
      AND CAM_ACCT_NO     = SUBSTR(p_new_acct_no,7,8) ;
    ELSE
      IF (SUBSTR(p_pan_code,1,6) = '940134' AND LENGTH( SUBSTR(p_new_acct_no,7)) = 10 ) THEN
        SELECT cam_acct_id
        INTO prm_acct_id
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_instcode
        AND CAM_ACCT_NO     = SUBSTR( p_new_acct_no ,7,10) ;
      ELSE
        SELECT cam_acct_id
        INTO prm_acct_id
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_instcode
        AND CAM_ACCT_NO     = p_new_acct_no;
      END IF;
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BEGIN
      SELECT cam_acct_id,
        cam_stat_code,
        cam_bill_addr
      INTO prm_acct_id,
        v_acct_stat,
        v_bill_addr
      FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = p_instcode
      AND CAM_ACCT_NO     = p_primary_acct_no;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_errmsg := 'TO  CREATE NEW ACCOUNT, DETAILS OF PRIMARY ACCOUNT NOT FOUND';
      RETURN ;
    END;
    v_acct_type_tmp       :=SUBSTR(p_new_acct_no,5,2);
    IF p_instcode          = 1 THEN -- for India, Host acct type is 01 for Savings  for Current
      IF v_acct_type_tmp   ='01' THEN
        v_acct_type_tmp   :='11';
      ELSIF v_acct_type_tmp='05' THEN
        v_acct_type_tmp   :='01';
      ELSE
        p_errmsg := 'WHILE SELECTING CRITERIA FOR NEW ACT, HOST ACCOUNT TYPE OTHER THAN 01 AND 05';
        RETURN ;
      END IF;
    END IF;
    BEGIN
      SELECT cat_type_code
      INTO v_type_code
      FROM CMS_ACCT_TYPE
      WHERE cat_inst_code = p_instcode
      AND cat_switch_type = v_acct_type_tmp ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_errmsg := 'WHILE SELECTING CRITERIA FOR NEW ACT, ACCOUNT TYPE NOT FOUND';
      RETURN ;
    WHEN OTHERS THEN
      p_errmsg:='ERROR WHILE SELECTING ACCOUNT TYPE-'||SUBSTR(SQLERRM,1,200);
    END;
    --------------------------
    -- SN: CREATE NEW ACCOUNT
    --------------------------
    BEGIN
      IF(p_instcode = 3 AND LENGTH( SUBSTR(p_new_acct_no,7)) = 9 ) THEN
        sp_create_acct(p_instcode, SUBSTR(p_new_acct_no,7,9), 1, SUBSTR(p_new_acct_no,1,4), v_bill_addr, v_type_code , 1, p_lupduser, NULL,NULL,NULL, v_dup_flag, prm_acct_id, p_errmsg ) ;
        IF p_errmsg <> 'OK' THEN
          --ROLLBACK TO v_savepoint ;
          p_errmsg := 'WHILE CREATING NEW ACCOUNT FOR INST CODE 3 : ' || p_errmsg ;
          RETURN ;
        END IF;
      ELSIF (p_instcode = 4 AND LENGTH( SUBSTR(p_new_acct_no,7)) = 8 ) THEN
        sp_create_acct(p_instcode, SUBSTR(p_new_acct_no,7,8), 1, SUBSTR(p_new_acct_no,1,4), v_bill_addr, v_type_code , 1, p_lupduser, NULL,NULL,NULL, v_dup_flag, prm_acct_id, p_errmsg );
        IF p_errmsg <> 'OK' THEN
          --ROLLBACK TO v_savepoint ;
          p_errmsg := 'WHILE CREATING NEW ACCOUNT FOR INST CODE 4 : ' || p_errmsg ;
          RETURN;
        END IF;
      ELSE
        IF ( p_instcode = 1 AND SUBSTR(p_pan_code,1,6) = '940134' AND LENGTH( SUBSTR(p_new_acct_no,7)) = 10 ) THEN
          sp_create_acct( p_instcode, SUBSTR( p_new_acct_no ,7,10), 1, SUBSTR(p_new_acct_no,1,4), v_bill_addr, v_type_code , 1, p_lupduser, NULL,NULL,NULL, v_dup_flag, prm_acct_id, p_errmsg );
          IF p_errmsg <> 'OK' THEN
            --ROLLBACK TO v_savepoint ;
            p_errmsg := 'WHILE CREATING NEW ACCOUNT FOR INST CODE 1 : ' || p_errmsg ;
            RETURN ;
          END IF ;
        ELSE
          IF ((p_instcode = 1 OR p_instcode = 5 ) AND SUBSTR(p_pan_code,1,6) <> '940134' AND LENGTH(p_new_acct_no) = 12 ) THEN
            sp_create_acct( p_instcode, p_new_acct_no , 1, SUBSTR(p_new_acct_no,1,4), v_bill_addr, v_type_code , 1, p_lupduser, NULL,NULL,NULL, v_dup_flag, prm_acct_id, p_errmsg );
            IF p_errmsg <> 'OK' THEN
              --ROLLBACK TO v_savepoint ;
              p_errmsg := 'WHILE CREATING NEW ACCOUNT FOR INST CODE 1 OR 5 : ' || p_errmsg ;
              RETURN ;
            END IF ;
          ELSE
            p_errmsg := 'length of Account ' || p_new_acct_no ||'Length'||length(p_new_acct_no)||' is not valid';
            --ROLLBACK TO v_savepoint ;
            RETURN ;
          END IF;
        END IF;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      p_errmsg := 'MAIN ERROR WHILE CREATION NEW ACCOUNT : ' || SUBSTR(SQLERRM, 1, 100) ;
      --ROLLBACK TO v_savepoint ;
      RETURN ;
    END;
    --------------------------
    -- EN: CREATE NEW ACCOUNT
    --------------------------
  END;
END;
/


show error