CREATE OR REPLACE PROCEDURE vmscms.sp_requisition_id (
   prm_in_date    IN       DATE,
   prm_req_id     OUT      VARCHAR2,
   prm_err_mesg   OUT      VARCHAR2
)
IS
   dmp                  NUMBER;
   v_requisition_date   VARCHAR2 (6);
   v_ctrl_no            NUMBER;
   v_err_msg            VARCHAR2 (300) := 'OK';
   exp_error            EXCEPTION;
BEGIN
   prm_err_mesg := v_err_msg;

   BEGIN
      SELECT COUNT (1)
        INTO dmp
        FROM pcms_requisition_ctrl
       WHERE TRUNC (prc_requisition_date) = TRUNC (prm_in_date);

      DBMS_OUTPUT.put_line ('COUNT' || dmp);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('IN EXP');
         NULL;
      WHEN OTHERS
      THEN
         v_err_msg :=
               'ERROR WHILE SELECTING FROM REQUISITION_CTRL: '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_error;
   END;

   IF dmp <> 0
   THEN
      BEGIN
         UPDATE pcms_requisition_ctrl
            SET prc_ctrl_numb = prc_ctrl_numb + 1
          WHERE TRUNC (prc_requisition_date) = TRUNC (prm_in_date);

         IF SQL%ROWCOUNT = 0
         THEN
            v_err_msg :=
                  'ERROR WHILE UPDATING IN REQUISITION_CTRL'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_error;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'ERROR WHILE UPDATING IN REQUISITION_CTRL: '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_error;
      END;
   ELSE
      DELETE FROM pcms_requisition_ctrl;

      BEGIN
         INSERT INTO pcms_requisition_ctrl
                     (prc_requisition_date, prc_ctrl_numb
                     )
              VALUES (prm_in_date, 1
                     );

         IF SQL%ROWCOUNT = 0
         THEN
            v_err_msg :=
                  'ERROR WHILE INSERTING IN REQUISITION_CTRL'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_error;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'ERROR WHILE INSERTING IN REQUISITION_CTRL: '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_error;
      END;
   END IF;

   BEGIN
      SELECT TO_CHAR (prc_requisition_date, 'YYMMDD'), prc_ctrl_numb
        INTO v_requisition_date, v_ctrl_no
        FROM pcms_requisition_ctrl
       WHERE TRUNC (prc_requisition_date) = TRUNC (prm_in_date);

      DBMS_OUTPUT.put_line ('PRC_CTRL_NUMB: ' || v_ctrl_no);
      prm_req_id := v_requisition_date || LPAD (v_ctrl_no, 5, '0');
      DBMS_OUTPUT.put_line ('REQUISITION_ID: ' || prm_req_id);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_err_msg := 'ERROR WHILE GENERATING REQUISITION ID';
         RAISE exp_error;
      WHEN OTHERS
      THEN
         v_err_msg :=
               'ERROR WHILE GENERATING REQUISITION ID: '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_error;
   END;

   DBMS_OUTPUT.put_line ('ERROR:' || v_err_msg);
EXCEPTION
   WHEN exp_error
   THEN
      ROLLBACK;
      prm_err_mesg := v_err_msg;
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err_msg := 'FROM SP_REQUISITION_ID:  ' || SUBSTR (SQLERRM, 1, 200);
      prm_err_mesg := v_err_msg;
END;
/

SHOW ERROR