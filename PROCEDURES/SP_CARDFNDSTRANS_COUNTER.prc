CREATE OR REPLACE PROCEDURE VMSCMS.sp_cardfndstrans_counter
(p_inst_code IN NUMBER,
p_from_card IN VARCHAR2,
p_to_card IN VARCHAR2,
p_amount IN VARCHAR2,
p_lupd_user IN VARCHAR2,
p_display_str OUT VARCHAR2,
p_err_msg OUT VARCHAR2)
AS
v_seq NUMBER;
v_err_msg VARCHAR2(300);
v_count NUMBER;
v_display_str VARCHAR2(50);
BEGIN
p_err_msg:='OK';
	 BEGIN
		 select seq_fndstrans_counter.nextval INTO v_seq from dual;
		 
		 INSERT INTO cms_cardfndstrans_counter 
		 VALUES(p_inst_code,v_seq,p_from_card,p_to_card,p_amount,
		 p_lupd_user,sysdate,p_lupd_user,sysdate);
		 
		 IF SQL%ROWCOUNT = 0 THEN 
		 	v_err_msg:= 'Error While Inserting Record'||SQLERRM;	
		 END IF;
		 
	 EXCEPTION 
	 WHEN OTHERS THEN
	 	v_err_msg:= 'Error While Inserting Record'||SQLERRM;	  									  
	 END;
	 
	 BEGIN
		 select COUNT(1) INTO v_count from cms_cardfndstrans_counter 
		 where ccc_inst_code = p_inst_code 
		 and CCC_FROM_CARD = p_from_card 
		 AND CCC_TO_CARD = p_to_card AND TRUNC(CCC_INS_DATE) = TRUNC(SYSDATE)
		 GROUP BY TRUNC(CCC_INS_DATE); 
		 
	 	 IF v_count = 0 OR v_count IS NULL THEN 
		   	SELECT 'FNDS'||LPAD (v_count, 8, 0)||TO_CHAR (SYSDATE, 'yyyymmdd')  INTO v_display_str FROM DUAL;
			p_display_str := v_display_str;
		 ELSE
			SELECT 'FNDS'||LPAD (v_count, 8, 0)||TO_CHAR (SYSDATE, 'yyyymmdd') INTO v_display_str FROM DUAL;
			p_display_str := v_display_str; 
		 END IF;
		 	  
	 EXCEPTION
	 WHEN OTHERS THEN
	 	  SELECT 'FNDS'||LPAD (v_count, 8, 0)||TO_CHAR (SYSDATE, 'yyyymmdd')  INTO v_display_str FROM DUAL;
		   p_display_str := v_display_str;
	 END;
EXCEPTION 
WHEN OTHERS THEN
	 p_err_msg := 'main Exception '||SQLERRM;
	  	 
END;
/


