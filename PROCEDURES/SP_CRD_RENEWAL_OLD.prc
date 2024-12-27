CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Crd_Renewal_old  (instcode IN NUMBER ,
						remark	IN VARCHAR2,
        				lupduser IN NUMBER,
        				errmsg OUT VARCHAR2)
AS
--change history
--1CH070303 Anup add an update stmt for renewal of expired cards
v_expiryparam NUMBER;
v_renew_param NUMBER;
renew_cnt	  NUMBER := 0;
v_rencaf_fname CMS_RENCAF_HEADER.crh_rencaf_fname%TYPE;
v_errmsg VARCHAR2(500) ;
--gets the cards that are expiring in the month on which this procedure is executed.
CURSOR C1 IS
SELECT 	cap_pan_code,cap_mbr_numb,cap_prod_catg,cap_acct_no,cap_disp_name,cap_expry_date,cap_card_stat,cap_prod_code
FROM 	CMS_APPL_PAN
WHERE 	TRUNC(cap_expry_date) BETWEEN TO_DATE('01-'||TO_CHAR(SYSDATE,'MON-YYYY')) AND LAST_DAY(SYSDATE) ;
--AND		cap_card_stat = '1'
--AND cap_pan_code like '466706%';
--status 1 denotes active cards
BEGIN --1.1
errmsg:='OK';
-- Gets the Validity period from the Parameter table.
            --dbms_output.put_line('Start');
 SELECT cip_param_value
 INTO v_expiryparam
 FROM CMS_INST_PARAM
 WHERE cip_param_key = 'CARD EXPRY';
 SELECT TO_NUMBER(cip_param_value)
 INTO	v_renew_param
 FROM	CMS_INST_PARAM
 WHERE	cip_param_key = 'RENEWCAF';
        FOR x IN C1
          LOOP
          --1CH070303 condition to generate a file
IF x.cap_prod_catg = 'D' THEN
IF x.cap_card_stat  = '1'  THEN  -- 1.1
  BEGIN --1.2
          IF renew_cnt = 0 THEN
          	--generate new file here and store it in a variable and use the filename below
          	Sp_Create_Rencaffname(instcode,lupduser,v_rencaf_fname,errmsg);
          	--dbms_output.put_line('something1 ->'||v_rencaf_fname);
          	IF errmsg != 'OK' THEN
          		errmsg := 'Error while creating filename -- '||errmsg;
          	END IF;
          END IF;
--Renews the card by updating its Expiry date.
      UPDATE CMS_APPL_PAN
      SET  cap_expry_date 		= LAST_DAY(ADD_MONTHS(SYSDATE , v_expiryparam)),
           cap_next_bill_date 	= SYSDATE,--because the amc calculation should start for the card again on the day
           cap_lupd_date 		= SYSDATE
      WHERE  	cap_inst_code 	= instcode
      AND		cap_pan_code 	= x.cap_pan_code
      AND  		cap_mbr_numb 	= x.cap_mbr_numb ;
	--now log the support function into cms_pan_spprt
	INSERT INTO CMS_PAN_SPPRT(	CPS_INST_CODE		,
							CPS_PAN_CODE		,
							CPS_MBR_NUMB		,
							CPS_PROD_CATG		,
							CPS_SPPRT_KEY		,
							CPS_SPPRT_RSNCODE	,
							CPS_FUNC_REMARK		,
							CPS_INS_USER		,
							CPS_LUPD_USER		)
						VALUES(	instcode		,
							x.cap_pan_code		,
							x.cap_mbr_numb		,
							x.cap_prod_catg		,
							'RENEW'				,
							1					,
							remark				,
							lupduser			,
							lupduser			);
	--Before insert into into cms_caf_info, delete the row from cms_caf_info
            --dbms_output.put_line('After insert');
	DELETE 	FROM CMS_CAF_INFO
	WHERE	cci_pan_code 	= 	x.cap_pan_code||'   '
	AND		cci_mbr_numb	=	x.cap_mbr_numb;

   dbms_output.put_line('card-'||x.cap_pan_code);

    Sp_Caf_Rfrsh(instcode,x.cap_pan_code,NULL,SYSDATE,'C',NULL,'RENEW',lupduser,errmsg);
     IF errmsg !='OK' THEN
        errmsg:='From Caf Refresh -- '||errmsg;
     ELSE
     	renew_cnt := renew_cnt+1;
     	IF renew_cnt = v_renew_param THEN
     		renew_cnt := 0;
     	END IF;
     	--dbms_output.put_line('something2 ->'||v_rencaf_fname);
		UPDATE 	CMS_CAF_INFO
		SET		cci_file_name = v_rencaf_fname,
				cci_file_gen  = 'R'--renewed pans filegen
		WHERE	cci_pan_code  = x.cap_pan_code||'   '
		AND		cci_mbr_numb  = x.cap_mbr_numb;
     END IF;
  EXCEPTION
  WHEN OTHERS THEN
   v_errmsg := 'EXCP 1.2 '||SQLERRM ;
   INSERT INTO  CMS_CARDRENEWAL_ERRLOG
   (
   cce_pan_code,
   cce_disp_name ,
   cce_acct_no ,
   cce_card_stat,
   cce_expry_date ,
   cce_error_mesg ,
   cce_ins_user )
   VALUES
   (
   x.cap_pan_code  ,
   x.cap_disp_name ,
   x.cap_acct_no ,
   x.cap_card_stat ,
   x.cap_expry_date ,
   v_errmsg ,
   lupduser) ;
  END ; --1.2
ELSE
     v_errmsg := 'Card Not in Open Status.' ;
   INSERT INTO  CMS_CARDRENEWAL_ERRLOG
   (
   cce_pan_code,
   cce_disp_name ,
   cce_acct_no ,
   cce_card_stat,
   cce_expry_date ,
   cce_error_mesg ,
   cce_ins_user )
   VALUES
   (
   x.cap_pan_code  ,
   x.cap_disp_name ,
   x.cap_acct_no ,
   x.cap_card_stat ,
   x.cap_expry_date ,
   v_errmsg ,
   lupduser) ;
END IF ; -- 1.1
END IF ;
          END LOOP;
EXCEPTION
      WHEN OTHERS THEN
         errmsg:= 'Main Excp -- '||SQLERRM;
END;
/


