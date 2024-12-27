CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Bulkreissue (	instcode    IN NUMBER ,
											 	seqno    IN  VARCHAR2,
												--oldpan    IN  VARCHAR2,
												--newpan    IN  VARCHAR2,
												prm_mbr_numb	IN VARCHAR2,
												lupduser  IN  NUMBER,
												errmsg    OUT VARCHAR2)
AS
v_mbrnumb 			  VARCHAR2(3);
v_remark  			  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_spprtrsn 			  CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;
v_cardstat  		  CMS_APPL_PAN.cap_card_stat%TYPE;
v_newpan 			  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
v_oldprod_code 		  CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
v_prod_code 		  CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
v_oldprod_cat 		  CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
v_olddisp_name 		  CMS_APPL_PAN.CAP_DISP_NAME%TYPE;
v_disp_name 		  CMS_APPL_PAN.CAP_DISP_NAME%TYPE;
v_cafgen_flag 		  CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
v_cardtype 			  CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
v_cardstat_desc   	  VARCHAR2(15);
v_newcard_stat		  cms_appl_pan.cap_card_stat%TYPE; -- sandip , new card stat should be always 0 - 190106
v_cafgen_flag1 VARCHAR2(1);
ReissueException 	  EXCEPTION;
NullValueException    EXCEPTION;
dum  				  NUMBER;
CURSOR c1 IS
   SELECT	 TRIM(cgr_pan_code) cgr_pan_code , TRIM(CGR_NEW_PAN_CODE) CGR_NEW_PAN_CODE, cgr_remark, ROWID
   --cgr_new_product, cgr_new_productcat, -- these two fields are not longer being picked up bcoz they will be maintained as they are...
FROM	 CMS_GROUP_BULKREISSUE
WHERE 	 cgr_pin_reissue = 'N'  AND CGR_CHKR_PROC_STAT='P' AND CGR_SEQ_NO=seqno;
-- CGR_PAN_CODE=oldpan and CGR_NEW_PAN_CODE=newpan;--the procedure will based on old and new pan details to reissue
--WHERE 	 cgr_pin_reissue = 'N' ;
--WHERE 	 cgr_pin_reissue = 'N' and CGR_FILE_NAME=filename and CGR_CHKR_PROC_STAT='P'; --added filename and process stat
-- Main begin starts here ***************
BEGIN
	 errmsg    	  := 'OK';
	 v_remark  	  := 'Group Reissue';
	 v_spprtrsn   := 1;
	 FOR x IN c1
	 	 LOOP
             BEGIN -- begin 1
				 IF  NVL(LENGTH(trim(x.CGR_PAN_CODE)),0)=0 THEN
					 errmsg:='Old PAN Code Is Null';
					 RAISE NullValueException;
	 			 ELSIF  NVL(LENGTH(trim(x.CGR_NEW_PAN_CODE)),0)=0 THEN  --Sandip cr162
					 errmsg:='New PAN Code Is Null';
					 RAISE NullValueException;
				 ELSIF NVL(LENGTH(trim(x.CGR_REMARK)),0) =0 THEN
					 errmsg:='Remark Is Null';
					 RAISE NullValueException;
				 ELSE
					 errmsg:='OK';
				 END IF;
				   BEGIN		--begin 1 starts
				   SELECT  1 , cap_card_stat ,DECODE(cap_card_stat , '1','OPEN','2','HOTLISTED','3','STOLEN','4','RESTRICTED','9','CLOSED','INVALID STATUS'),
   				   		   cap_prod_code,--for reissue report - for which prod code the error came 260106 sandip
						   --cap_card_type, --commented by tejas 5 jan 06....because these have to be maintained as they are...
						   cap_disp_name,
						   cap_cafgen_flag  -- this is to check whether the CAF has been generated atleast once or not
			 	   INTO    dum  ,v_cardstat,v_cardstat_desc,     v_oldprod_code,-- v_oldprod_cat,
				                  v_olddisp_name, v_cafgen_flag
				   FROM    CMS_APPL_PAN
				   WHERE   cap_pan_code = x.cgr_pan_code  --select details of old pan
				   AND cap_mbr_numb = prm_mbr_numb;  -- index maintained on pan code and mbr numb ****
				     dbms_output.put_line('For old Pan v_cafgen_flag  : '|| v_cafgen_flag);
				   EXCEPTION
				   WHEN NO_DATA_FOUND THEN
				   		errmsg := 'Old PAN Not found.';
					WHEN OTHERS THEN
						 errmsg := 'Old PAN found.';
						--errmsg := 'Excp 1 -- '||SQLERRM;
				   END;
				   IF errmsg = 'OK' AND v_cafgen_flag = 'N' THEN	--cafgen if
				   	  errmsg := 'CAF has to be generated atleast once for this pan';
					  UPDATE CMS_GROUP_BULKREISSUE
												   SET 	  CGR_PIN_REISSUE = 'E'   ,
												   		  cgr_result =  errmsg ,
														  CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
					  WHERE ROWID = X.ROWID;
					  COMMIT;
				   ELSE
/*
						IF dum = 1 THEN -- if 1
					-- 			IF x.cgr_new_product IS NOT NULL THEN -- if 3
					--		 	   v_prod_code:= x.cgr_new_product;
					--		 	ELSE
					--		 	   v_prod_code:= v_oldprod_code;  --assigns Old pans prod code --commented by tejas
							 	END IF; -- end if 3
						   v_disp_name:=v_olddisp_name;    --assigns onld pans display name
					 END IF;
*/
					-- the following will deal with the new pan...
					 	BEGIN -- begin 1.1
						-- the prod code and the card type of the new card will be maintained...
									 	   		SELECT cap_pan_code,cap_prod_code, cap_card_type, cap_cafgen_flag,cap_card_stat
												INTO   v_newpan,v_prod_code,v_cardtype, v_cafgen_flag1,v_newcard_stat
												FROM   CMS_APPL_PAN
												WHERE  cap_pan_code = x.CGR_NEW_PAN_CODE
												AND cap_mbr_numb = prm_mbr_numb;
									 	   EXCEPTION
										   		WHEN NO_DATA_FOUND THEN
													 errmsg := 'The Given New Pan not found in Pan master :';
												WHEN OTHERS THEN
													 errmsg := 'Invalid Pan Number';
										END; -- end 1.1
										IF v_newcard_stat <> '0' THEN   -- sandip , new card stat should be always 0 - 190106
										errmsg := 'Pan is not from stock' ;
										UPDATE CMS_GROUP_BULKREISSUE
												   SET 	  CGR_PIN_REISSUE = 'E'   ,
												   		  cgr_result =  errmsg ,
														  CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
										WHERE ROWID = X.ROWID;
												   --
										COMMIT;
										END IF;
  dbms_output.put_line('For new Pan v_cafgen_flag1  : '|| v_cafgen_flag1);
										-- commenting the piece of code below because the card type for the new card is no longer being changed....
								/*		IF x.cgr_new_productcat IS NOT NULL THEN --if 5
								 	 	   BEGIN -- begin 2
									 	   		SELECT cpc_card_type
												INTO   v_cardtype
												FROM   CMS_PROD_CATTYPE
												WHERE  cpc_prod_code = UPPER(trim(x.cgr_new_product))
												AND    cpc_cardtype_desc = UPPER(trim(x.cgr_new_productcat));
									 	   EXCEPTION
										   		WHEN NO_DATA_FOUND THEN
													 errmsg := 'Given Product category not found in Product category master';
												WHEN OTHERS THEN
													 errmsg := 'Invalid Product Category';
										   END; -- end 2
									--	ELSE  commented by tejas5 jan 06
									--	 	 v_cardtype := v_oldprod_cat;  -- ????? --assigns old prod category-- commented by tejas 5 jan 06
										END IF; --end if 5   */
										 	IF ERRMSG = 'OK' THEN  --if 6
--											 dbms_output.put_line(v_prod_code||' ' ||TO_CHAR(v_cardtype));
											   v_newpan :=	x.CGR_NEW_PAN_CODE; --new Pan number
											   dbms_output.put_line('Before calling Sp_Issue_Pan_Fromstock**NPan='||v_newpan);
											   	dbms_output.put_line('Before calling Sp_Issue_Pan_Fromstock**cgr_pan_code='||x.cgr_pan_code||'v_disp_name='||v_disp_name||' v_prod_code='||v_prod_code||'v_newpan'||v_newpan);
											   Sp_Issue_Pan_Fromstock (instcode,x.cgr_pan_code, prm_mbr_numb, x.cgr_remark,v_disp_name,v_prod_code,TO_CHAR(v_cardtype),v_spprtrsn,lupduser,v_newpan,errmsg);
											   dbms_output.put_line(  'After calling   Sp_Issue_Pan_Fromstock ' ||errmsg);
											   			dbms_output.put_line('v_newpan: '||v_newpan||' v_disp_name: '||v_disp_name); -- Sandip Jan.12.2006: debug.
											END IF; -- if 6
												IF ERRMSG = 'OK' THEN --if 7
												   UPDATE CMS_GROUP_BULKREISSUE
												   SET 	  CGR_PIN_REISSUE = 'Y'  ,
												   		  cgr_result = 'SUCCESSFULL' ,
														  cgr_new_pan_code = v_newpan,
														  cgr_new_dispname = v_disp_name,
														  CGR_NEW_PRODUCT = v_prod_code --report will be based on prod code also sandip260106
												   WHERE ROWID = X.ROWID;
												   COMMIT;
												ELSE
												   -- SN Shekar Jan.12.2006, on error update flag in bulk reissue
												   ROLLBACK;
												   --
												   UPDATE CMS_GROUP_BULKREISSUE
												   SET 	  CGR_PIN_REISSUE = 'E'   ,
												   		  cgr_result =  errmsg ,
														  CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
												   WHERE ROWID = X.ROWID;
												   --
												   COMMIT;
												   -- EN Shekar Jan.12.2006, on error update flag in bulk reissue
												   Sp_Auton(NULL,x.cgr_pan_code,ERRMSG);
												   dbms_output.put_line('pt 2.2'); -- Sandip Jan.12.2006: debug.
												END IF; --end if 7
						END IF; -- end if 1
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				-- SN Shekar Jan.12.2006, on error update flag in bulk reissue
				ROLLBACK;
				--
				UPDATE cms_group_bulkreissue
				   SET cgr_pin_reissue = 'E'   ,
				       cgr_result =  'No data found',
					   CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
				 WHERE ROWID = X.ROWID;
				--
				COMMIT;
				-- EN Shekar Jan.12.2006, on error update flag in bulk reissue
				-- sandip cr162 exception handling when no data found for old pan
					-- updation of table goes here
					Sp_Auton(NULL,x.cgr_pan_code,ERRMSG);
				WHEN NullValueException THEN
					dbms_output.put_line(errmsg);
				-- SN Shekar Jan.12.2006, on error update flag in bulk reissue
				ROLLBACK;
				--
				UPDATE cms_group_bulkreissue
				   SET cgr_pin_reissue = 'E'   ,
				       cgr_result =  errmsg ,
					   CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
				 WHERE ROWID = X.ROWID;
				--
				COMMIT;
				-- EN Shekar Jan.12.2006, on error update flag in bulk reissue
					Sp_Auton(NULL,x.cgr_pan_code,ERRMSG);
				WHEN OTHERS THEN
					errmsg :=SQLERRM;
				-- SN Shekar Jan.12.2006, on error update flag in bulk reissue
				ROLLBACK;
				--
				UPDATE cms_group_bulkreissue
				   SET cgr_pin_reissue = 'E'   ,
				       cgr_result =  errmsg ,
					   CGR_NEW_PRODUCT = v_oldprod_code --report will be based on prod code also sandip260106
				 WHERE ROWID = X.ROWID;
				--
				COMMIT;
				-- EN Shekar Jan.12.2006, on error update flag in bulk reissue
					Sp_Auton(NULL,x.cgr_pan_code,ERRMSG);
			END;--begin 1
		END LOOP;
			errmsg := 'OK';
EXCEPTION
	WHEN ReissueException THEN
			errmsg := 'Reissue Excp ';
			--errmsg := 'Reissue Excp -- '||SQLCODE||SQLERRM;
	WHEN OTHERS THEN
		 	errmsg := 'Main Excp ';
		 --errmsg := 'Main Excp -- '||SQLCODE||SQLERRM;
END;
/


