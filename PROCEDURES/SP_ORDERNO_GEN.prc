CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Orderno_Gen
                        ( PRM_IN_DATE IN DATE,
			              PRM_ORD_NO  OUT VARCHAR2,
			              PRM_ERR_MESG OUT VARCHAR2 )
IS

DMP  NUMBER;
v_requisition_date VARCHAR2(6);
v_ctrl_no  NUMBER;
v_err_msg  VARCHAR2(300) := 'OK';
EXP_ERROR EXCEPTION;

----------------------------<<MAIN BEGIN>>-------------------------
BEGIN
PRM_ERR_MESG := v_err_msg ;

	   BEGIN    -----<<Begin 1 >>   SN Check for record in table PCMS_ORDERNO_GEN for given date
		          SELECT COUNT(1) INTO DMP FROM PCMS_ORDERNO_GEN
		          WHERE TO_CHAR(prc_ORDERNO_date,'YYMM') = TO_CHAR(PRM_IN_DATE,'YYMM');

                  DBMS_OUTPUT.PUT_LINE('COUNT'|| DMP);
		  EXCEPTION
		  WHEN NO_DATA_FOUND THEN
                  DBMS_OUTPUT.PUT_LINE('IN EXP' );
		  NULL;
		  WHEN OTHERS THEN
		  v_err_msg := 'ERROR WHILE SELECTING FROM ORDERNO_GEN : '||SUBSTR(SQLERRM,1,200);
		  RAISE EXP_ERROR;
		  END;    -----<Begin 1 Ends >>---------

			  IF DMP <> 0 THEN  ---SN If record exist then Increment the CTRL_NUMB
				    BEGIN
					    UPDATE PCMS_ORDERNO_GEN
					    SET PRC_CTRL_NUMB  = PRC_CTRL_NUMB + 1, PRC_ORDERNO_DATE = PRM_IN_DATE
					    WHERE TO_CHAR(PRC_ORDERNO_DATE,'YYMM') = TO_CHAR(PRM_IN_DATE,'YYMM');

					    IF SQL%ROWCOUNT = 0 THEN
				        v_err_msg := 'ERROR WHILE UPDATING IN ORDERNO_GEN'||SUBSTR(SQLERRM,1,200);
				        RAISE EXP_ERROR;
				        END IF;
				    EXCEPTION
				    WHEN OTHERS THEN
				     v_err_msg := 'ERROR WHILE UPDATING IN ORDERNO_GEN: '||SUBSTR(SQLERRM,1,200);
				    RAISE EXP_ERROR;
				    END;
			ELSE          ---SN If record does not exist then truncate table and insert new record for the DATE
			  DELETE FROM PCMS_ORDERNO_GEN;

					       BEGIN        ---< BEGIN FOR INSERT >--------
						       INSERT INTO PCMS_ORDERNO_GEN(prc_orderno_date,prc_ctrl_numb)
						       VALUES (PRM_IN_DATE,1 );

						       IF SQL%ROWCOUNT= 0 THEN
						       v_err_msg := 'ERROR WHILE INSERTING IN ORDERNO_GEN'||SUBSTR(SQLERRM,1,200);
						       RAISE EXP_ERROR;
					               END IF;
					       EXCEPTION     ---<EXCEPTION FOR INSERT>--------
					       WHEN OTHERS THEN
					       v_err_msg := 'ERROR WHILE INSERTING IN ORDERNO_GEN: '||SUBSTR(SQLERRM,1,200);
					       RAISE EXP_ERROR;
					       END;          ---< BEGIN FOR INSERT ENDS >--------
		   END IF;

			  BEGIN  -----<Begin 2 >>---SN Generate order no
					  SELECT TO_CHAR(prc_orderno_date,'YYMM'), prc_ctrl_numb INTO v_requisition_date, v_ctrl_no
					  FROM PCMS_ORDERNO_GEN
					  WHERE TO_CHAR(prc_orderno_date,'YYMM') = TO_CHAR(prm_in_date,'YYMM');

 		             DBMS_OUTPUT.PUT_LINE('PRC_CTRL_NUMB: '|| v_ctrl_no);
			  		   PRM_ORD_NO := v_requisition_date|| 'RM' ||LPAD(v_ctrl_no,5,'0');
                 DBMS_OUTPUT.PUT_LINE('ORDER_NO: '||  PRM_ORD_NO);
			  EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			  v_err_msg := 'ERROR WHILE GENERATING ORDER NO';
			  RAISE EXP_ERROR;
			  WHEN OTHERS THEN
			  v_err_msg := 'ERROR WHILE GENERATING ORDER NO: '||SUBSTR(SQLERRM,1,200);
			  RAISE EXP_ERROR;
			  END;   -----<Begin 2 Ends >>-

 DBMS_OUTPUT.PUT_LINE('ERROR:'||   v_err_msg);

----------------------------<<MAIN BEGIN ENDS>>---------------------

EXCEPTION     ----<<EXCEPTION FOR MAIN BEGIN>>--------
WHEN EXP_ERROR THEN
ROLLBACK;
PRM_ERR_MESG := v_err_msg ;
WHEN OTHERS THEN
ROLLBACK;
v_err_msg := 'FROM SP_ORDERNO_GEN:  '||SUBSTR(SQLERRM,1,200);
PRM_ERR_MESG := v_err_msg ;
END;
/
SHOW ERRORS

