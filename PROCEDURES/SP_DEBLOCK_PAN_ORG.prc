CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Deblock_Pan_org(
    instcode  IN  NUMBER ,
             pancode  IN  VARCHAR2 ,
             mbrnumb  IN  VARCHAR2 ,
             rsncode  IN  NUMBER ,
             remark  IN  varchar2 ,
             lupduser  IN  NUMBER ,
	     workmode IN NUMBER ,
             errmsg  OUT  VARCHAR2 )
AS
dum    NUMBER  ;
v_mbrnumb  VARCHAR2(3) ;
v_cap_prod_catg VARCHAR2(2) ;
v_cap_cafgen_flag CHAR(1)  ;
--Rahul and Hari 22 Feb cafgenFlag - fhm
-- Rahul 01 Apr 05
  v_record_exist CHAR(1):='Y';
  v_caffilegen_flag	CHAR(1):='N'	;
  v_issuestatus VARCHAR2(2);
  v_pinmailer VARCHAR2(1);
  v_cardcarrier VARCHAR2(1);
  v_pinoffset  VARCHAR2(16);
--exception declaration commented on 10-07-02
--uniq_excp_dblok exception  ;
--PRAGMA EXCEPTION_INIT(uniq_excp_dblok,-00001);
BEGIN  --Main begin starts
IF mbrnumb IS NULL  THEN
 v_mbrnumb := '000';
END IF;
errmsg := 'OK';
 BEGIN  --begin 1 starts
  SELECT cap_prod_catg, cap_cafgen_flag
  INTO v_cap_prod_catg, v_cap_cafgen_flag
  FROM CMS_APPL_PAN
  WHERE cap_pan_code = pancode
  AND  cap_mbr_numb = v_mbrnumb;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
  errmsg := 'No such PAN found.';
  WHEN OTHERS THEN
  errmsg := 'Excp 1 -- '||SQLERRM;
 END;  --begin 1 ends
IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N' THEN --cafgen if
errmsg := 'CAF has to be generated atleast once for this pan';
ELSE
 IF errmsg = 'OK'  THEN
 BEGIN  --Begin 2
 UPDATE CMS_APPL_PAN
 SET  cap_card_stat  = 1,
   cap_lupd_user = lupduser
 WHERE cap_inst_code  = instcode
 AND  cap_pan_code = pancode
 AND  cap_mbr_numb = v_mbrnumb;
 IF SQL%ROWCOUNT != 1 THEN
 errmsg := 'Problem in updation of status for pan '||pancode||'.';
 END IF;
 EXCEPTION --Excp of begin 2
 WHEN OTHERS THEN
 errmsg := 'Excp 2 -- '||SQLERRM;
 END;  --End of begin 2
 END IF;
 IF errmsg = 'OK' THEN
 --insert into pan support
 BEGIN  --Begin 3
 INSERT INTO CMS_PAN_SPPRT( CPS_INST_CODE  ,
        CPS_PAN_CODE  ,
        CPS_MBR_NUMB  ,
        CPS_PROD_CATG ,
        CPS_SPPRT_KEY  ,
        CPS_SPPRT_RSNCODE,
        CPS_FUNC_REMARK ,
        CPS_INS_USER  ,
        CPS_LUPD_USER,CPS_CMD_MODE  )
      VALUES( instcode   ,
        pancode   ,
        v_mbrnumb  ,
        v_cap_prod_catg ,
        'DBLOK'   ,
        rsncode   ,
        remark   ,
        lupduser   ,
        lupduser,workmode   );
 EXCEPTION --Excp of begin 3
 --the when uniq_excp_dblok exception commented on 10-07-02
 /*WHEN uniq_excp_dblok THEN
 UPDATE cms_pan_spprt
 SET  cps_lupd_user = lupduser
 WHERE cps_inst_code = instcode
 AND  cps_pan_code = pancode
 AND  cps_mbr_numb = v_mbrnumb
 AND  cps_spprt_key = 'DBLOK';*/
 WHEN OTHERS THEN
 errmsg := 'Excp 3 -- '||SQLERRM;
 END;  --End of begin 3
 END IF;
 --Caf Refresh
 IF errmsg = 'OK' THEN
 BEGIN  --Begin 4
		-- Rahul and  Hari 22 Feb workmode - fhm
		BEGIN
			SELECT CCI_FILE_GEN,CCI_SEG12_ISSUE_STAT,CCI_SEG12_PIN_MAILER,CCI_SEG12_CARD_CARRIER,CCI_PIN_OFST
			INTO	v_caffilegen_flag,v_issuestatus,v_pinmailer,v_cardcarrier,v_pinoffset
			FROM	CMS_CAF_INFO
			WHERE	cci_inst_code			=	instcode
			AND		cci_pan_code	=	RPAD(pancode,19,' ')
			AND		cci_mbr_numb		=	v_mbrnumb
			GROUP BY CCI_FILE_GEN,CCI_SEG12_ISSUE_STAT,CCI_SEG12_PIN_MAILER,CCI_SEG12_CARD_CARRIER,CCI_PIN_OFST;
			DELETE FROM CMS_CAF_INFO
			WHERE	cci_inst_code			=	instcode
  			AND		cci_pan_code	=	RPAD(pancode,19,' ')
  			AND		cci_mbr_numb		=	v_mbrnumb;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_record_exist:='N';
		END ;
  --call the procedure to insert into cafinfo
  Sp_Caf_Rfrsh(instcode,pancode,mbrnumb,SYSDATE,'C',NULL,'DBLOK',lupduser,errmsg)  ;
  		-- Rahul and  Hari 22 Feb - workmode - fhm
-- Rahul 1 apr 05 Update caf_info only if record was exist earlier
		IF workmode = 1 AND v_record_exist='Y' THEN
			UPDATE CMS_CAF_INFO
			SET cci_file_gen=v_caffilegen_flag,
			CCI_SEG12_ISSUE_STAT=v_issuestatus,
			CCI_SEG12_PIN_MAILER=v_pinmailer,
			CCI_SEG12_CARD_CARRIER=v_cardcarrier,
			CCI_PIN_OFST=v_pinoffset -- rahul 10 Mar 05
			WHERE cci_inst_code=1 AND cci_pan_code=RPAD(pancode,19,' ') AND cci_mbr_numb = '000';
		END IF;
		IF workmode=1 AND v_record_exist='N' THEN
			UPDATE CMS_CAF_INFO SET cci_file_gen='Y'
			WHERE cci_inst_code=1 AND cci_pan_code=RPAD(pancode,19,' ') AND cci_mbr_numb = '000';
		END IF ;
  IF errmsg != 'OK' THEN
  errmsg := 'From caf refresh -- '||errmsg;
  END IF;
 EXCEPTION --Excp 4
 WHEN OTHERS THEN
 errmsg := 'Excp 4 -- '||SQLERRM;
 END;  --End of begin 4
 END IF;
END IF; --cafgen if
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Main Exception -- '||SQLERRM;
END;
/


