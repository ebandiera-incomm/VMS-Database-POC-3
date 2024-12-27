CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Populate_Audit
  (
    PRM_INSTCODE IN NUMBER,
    PRM_TABLE_ID  NUMBER ,
    PRM_COL_NAME  VARCHAR2 ,
    PRM_OLD_VAL   VARCHAR2 ,
    PRM_NEW_VAL   VARCHAR2 ,
    PRM_LUPD_USER NUMBER,
    PRM_ACTION    VARCHAR2,
    PRM_SEQ_NO    NUMBER,
    PRM_ERRMSG OUT VARCHAR2)
AS
  /*
  * VERSION               :  1.0
  * DATE OF CREATION      : 23/JUL/2008
  * CREATED BY            : Ashutosh.
  * PURPOSE               : Audit trail
  *
  *
  * LAST MODIFICATION DONE BY :
  * LAST MODIFICATION DATE    :
  *
  ***/
  ------------------------------------------------------------------------------
  v_cai_ins_date DATE := SYSDATE ;
  v_seq_no        NUMBER;
  v_errmsg        VARCHAR2(300) := 'OK';
  DMP1            NUMBER;
  DMP2            NUMBER;
  DMP_MAIN        NUMBER;
  v_err_exception EXCEPTION;
  --------------------------------------------------------Sn  Main Bigin
BEGIN
  PRM_ERRMSG := v_errmsg ;
  -----********************************* Sn Check for Column name in Column Mater  *********************************
  BEGIN -- Sn no audit will be done if none of the columns are Y  ie. all 'N'
     SELECT COUNT(1)
       INTO DMP_MAIN
       FROM CMS_GENAUDIT_TABLE
      WHERE CGT_TABLE_ID = PRM_TABLE_ID
    AND CGT_COLUMN_FLAG  = 'Y'
    AND cgt_inst_code=PRM_INSTCODE;
    IF DMP_MAIN         <> 0 THEN
      -----------------------------------------------------------------------------------------------------------------------
      BEGIN
         SELECT COUNT(1)
           INTO DMP1
           FROM CMS_GENAUDIT_TABLE
          WHERE CGT_TABLE_ID       = PRM_TABLE_ID
        AND CGT_COLUMN_NAME        = PRM_COL_NAME
        AND CGT_COLUMN_FLAG        = 'Y' 
        AND cgt_inst_code          = PRM_INSTCODE;
        IF DMP1                   <> 0 THEN -- Sn if exist then insert in audit table ( if Flag is 'Y' )
          IF ( NVL(PRM_OLD_VAL,0) <> NVL(PRM_NEW_VAL,0) ) THEN
            BEGIN
               INSERT
                 INTO CMS_AUDIT_INFO
                (
                  cai_ins_date   ,
                  cai_module_name,
                  cai_field_name ,
                  cai_old_val    ,
                  cai_new_val    ,
                  cai_action_user,
                  cai_action_typ ,
                  seq,
                  cai_inst_code
                )
                VALUES
                (
                  v_cai_ins_date       ,
                  PRM_TABLE_ID         ,
                  PRM_COL_NAME         ,
                  TO_CHAR(PRM_OLD_VAL) ,
                  TO_CHAR(PRM_NEW_VAL) ,
                  PRM_LUPD_USER        ,
                  PRM_ACTION           ,
                  PRM_SEQ_NO,
                  prm_instcode
                );
            EXCEPTION
            WHEN OTHERS THEN
              v_errmsg := 'While inserting in Audit Table '||SUBSTR
              (
                SQLERRM,1,250
              )
              ;
              RAISE v_err_exception;
            END;
          END IF;
        END IF; -- En if exist then insert in audit table ( if Flag is 'Y' )
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'Record not defined in table ';
        RAISE v_err_exception;
      WHEN OTHERS THEN
        v_errmsg := 'From Audit Table '||SUBSTR
        (
          SQLERRM,1,250
        )
        ;
        RAISE v_err_exception;
      END;
      --------------------------------------------------Sn Check for mandatory fields ie with flag C .
      BEGIN
         SELECT COUNT(1)
           INTO DMP2
           FROM CMS_GENAUDIT_TABLE
          WHERE CGT_TABLE_ID = PRM_TABLE_ID
        AND CGT_COLUMN_NAME  = PRM_COL_NAME
        AND CGT_COLUMN_FLAG  = 'C'
        AND CGT_INST_CODE    = PRM_INSTCODE;
        IF DMP2             <> 0 THEN -- Sn if exist then insert in audit table ( if Flag is 'C' )
          BEGIN
             INSERT
               INTO CMS_AUDIT_INFO
              (
                cai_ins_date   ,
                cai_module_name,
                cai_field_name ,
                cai_old_val    ,
                cai_new_val    ,
                cai_action_user,
                cai_action_typ ,
                seq,
                cai_inst_code
              )
              VALUES
              (
                v_cai_ins_date       ,
                PRM_TABLE_ID         ,
                PRM_COL_NAME         ,
                TO_CHAR(PRM_OLD_VAL) ,
                TO_CHAR(PRM_NEW_VAL) ,
                PRM_LUPD_USER        ,
                PRM_ACTION           ,
                PRM_SEQ_NO,
                prm_instcode
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'While inserting in Audit Table '||SUBSTR
            (
              SQLERRM,1,250
            )
            ;
            RAISE v_err_exception;
          END;
        END IF; -- En if exist then insert in audit table ( if Flag is 'C' )
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'Record not defined in table for mandatory fields ';
        RAISE v_err_exception;
      WHEN OTHERS THEN
        v_errmsg := 'From Audit Table for mandatory fields '||SUBSTR
        (
          SQLERRM,1,250
        )
        ;
        RAISE v_err_exception;
      END;
      -----------------------------------------------------------------------------------------------------------------------
    END IF; -- En end of  DMP_MAIN
  EXCEPTION
  WHEN v_err_exception THEN
    RAISE v_err_exception;
  WHEN OTHERS THEN
    v_errmsg := 'From Gen audit table '|| SUBSTR
    (
      SQLERRM,1,200
    )
    ;
    RAISE v_err_exception;
  END; -- En no audit will be done if none of the columns are Y  ie. all 'N'
  -----********************************* Sn Check for Column name in Column Mater  *********************************
EXCEPTION
WHEN v_err_exception THEN
  PRM_ERRMSG := v_errmsg;
WHEN OTHERS THEN
  v_errmsg := 'Error from populate audit -'||SUBSTR
  (
    SQLERRM,1,250
  )
  ;
  PRM_ERRMSG := v_errmsg ;
END;
/
SHOW ERRORS

