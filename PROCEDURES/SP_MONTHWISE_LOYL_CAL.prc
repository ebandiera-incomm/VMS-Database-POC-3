CREATE OR REPLACE PROCEDURE VMSCMS.sp_monthwise_loyl_cal
(instcode	IN NUMBER,
AcctNO		IN VARCHAR2,
TranDt		IN DATE,
LoylPts		IN NUMBER,
lupduser	IN NUMBER,
errmsg		OUT VARCHAR2
)
AS
c_loylbal	NUMBER(5);
BEGIN		--	main begin
errmsg	:= 'oK';
	-- Trans which are that month only
	UPDATE CMS_MONTHWISE_LOYL SET cml_loyl_points = cml_loyl_points + LoylPts
	WHERE cml_tran_date = TO_CHAR(TranDt,'YYYY-MM') AND CML_ACCT_NO = AcctNO AND cml_lock = 'N';
	IF SQL%NOTFOUND THEN
		-- Transaction from previous months
		UPDATE	CMS_MONTHWISE_LOYL  SET cml_loyl_points = cml_loyl_points + LoylPts
		WHERE	cml_tran_date > TranDt
		AND	CML_ACCT_NO = AcctNO AND cml_lock = 'N';
		IF SQL%NOTFOUND THEN
			BEGIN	-- begin 1
				-- First insertion for particuler month make prev trans loked
				SELECT CML_LOYLOPN_BAL + CML_LOYL_POINTS - CML_REDEEM  INTO c_loylbal FROM CMS_MONTHWISE_LOYL
				WHERE  cml_tran_date =	(SELECT MAX(cml_tran_date) FROM CMS_MONTHWISE_LOYL
							WHERE CML_ACCT_NO = AcctNO );
				UPDATE CMS_MONTHWISE_LOYL SET CML_LOCK = 'Y'
				WHERE CML_ACCT_NO = AcctNO;
				INSERT INTO CMS_MONTHWISE_LOYL
				( CML_INST_CODE  ,CML_ACCT_NO  ,CML_TRAN_DATE ,CML_LOYLOPN_BAL ,CML_LOYL_POINTS ,CML_REDEEM, CML_INS_USER , CML_LUPD_USER  )
				VALUES (instcode ,AcctNO,TO_CHAR(TranDt,'YYYY-MM'),c_loylbal,LoylPts,0,lupduser,lupduser);
			EXCEPTION -- exception 1
			WHEN NO_DATA_FOUND THEN
				-- Totaly New Transaction
				INSERT INTO CMS_MONTHWISE_LOYL
				( CML_INST_CODE  ,CML_ACCT_NO  ,CML_TRAN_DATE ,CML_LOYLOPN_BAL ,CML_LOYL_POINTS ,CML_REDEEM , CML_INS_USER , CML_LUPD_USER )
				VALUES (instcode ,AcctNO,TO_CHAR(TranDt,'YYYY-MM'),0,LoylPts,0,lupduser,lupduser);
			END;
		END IF;
	END IF;
EXCEPTION	--main exception
WHEN OTHERS THEN
	dbms_output.put_line('In main excp of Procedure '||SQLERRM);
	ERRMSG	:= 'Exce main ' || SQLERRM;
END;-- Main Procedure body ends
/


