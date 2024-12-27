CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_transdisp(instcode	IN		NUMBER		,
						dispcode	IN		NUMBER		,--dispute code
						source		IN		VARCHAR2	,--this string is either RECONCILED or UNRECONCILED...tells the sp to look for the table on which to query...would be of help when idcol is also given
						idcol		IN		VARCHAR2	,--changed to varchar2 on 26-08-02 to make calling easy on the front end side
						pancode		IN		VARCHAR2	,
						mbrnumb		IN		VARCHAR2	,
						arncode		IN		VARCHAR2	,
						authcode	IN		VARCHAR2	,
						dispamt		IN		NUMBER		,
						transdate	IN		DATE		,
						reasoncode	IN		VARCHAR2	,
						mesgtext	IN		VARCHAR2	,
						retreq_type	IN		VARCHAR2	,--will decide the transaction code original = 51, copy = 52
						lupduser	IN		NUMBER		,
						idcol_spout	OUT		VARCHAR2	,
						errmsg		OUT		VARCHAR2	)
AS
--main procedure variables
v_mbrnumb	VARCHAR2(3)	;
dum		NUMBER (1)	;
intercode	VARCHAR2(2)	;
days		NUMBER (5)	;
v_trans_amt	NUMBER(20)	;
v_trans_date	DATE		;
v_auth_code	VARCHAR2 (6)	;
v_disp_amt	NUMBER (20)	;
v_disp_date	DATE		;
ctf_id_col	CMS_PAN_TRANS.cpt_id_col%TYPE;
locator		CHAR(1)		;
ctr		NUMBER(4)	;
chgbck_ref	VARCHAR2(6)	;
usage_code	VARCHAR2 (2)	;
temp_date	VARCHAR2(4)	;
trans_id	CHAR(1)		;--its is a transaction tyope indicator which indicates whether the transaction is U = us-on-us, N = us-on-network
new_idcol	NUMBER(14)	;--generated in the LP of the ret req part
new_purchdate	DATE		;--queried for in the LP of the ret req part
new_transamt	NUMBER (15)	;--queried for in the LP of the ret req part
new_authcode	VARCHAR2(6)	;--queried for in the LP of the ret req part

--main procedure variables

--1. local procedure which gives out the interchange for the entered bin
PROCEDURE lp_get_interchange(lp_pancode IN VARCHAR2, lp_intercode OUT VARCHAR2, lperr OUT VARCHAR2)
IS
BEGIN
lperr := 'OK';
	SELECT			cbm_interchange_code
	INTO			lp_intercode
	FROM			CMS_BIN_MAST
	WHERE			cbm_inst_code			=		instcode
	AND			cbm_inst_bin			=		SUBSTR(lp_pancode,1,6);
EXCEPTION
WHEN NO_DATA_FOUND THEN
lperr	:=	'Cannot find the interchange code for this PAN';
WHEN OTHERS THEN
lperr	:=	'Excp LP1 -- '||SQLERRM;
END;

--2. local procedure which gives out the days limit for a reason code
PROCEDURE lp_get_days_limit(lp_intercode IN VARCHAR2, lp_dispcode IN NUMBER, lp_reasoncode IN VARCHAR2, lp_days OUT NUMBER, lperr OUT VARCHAR2)
IS
BEGIN
lperr := 'OK';
	SELECT	crm_days_limt
	INTO	lp_days
	FROM	CMS_REASON_MAST
	WHERE	crm_inst_code		=	instcode
	AND	crm_interchange_code	=	lp_intercode
	AND	crm_disp_code		=	lp_dispcode
	AND	crm_reason_code		=	lp_reasoncode;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	lperr	:=	'Cannot find the Reason code for this PAN';
	WHEN OTHERS THEN
	lperr	:=	'Excp LP2 -- '||SQLERRM;
END;

--3. local procedure to insert records into the table cms_trans_disp
PROCEDURE lp_insert_into_cms_trans_disp(lp_intercode IN VARCHAR2, lp_pan IN VARCHAR2, lp_mbrnumb IN VARCHAR2, lp_auth_code IN VARCHAR2, lp_idcol IN NUMBER, lp_dispstatus IN VARCHAR2, lp_transdate IN DATE, lp_trans_amt IN NUMBER, lperr OUT VARCHAR2)
IS
uniq_excp EXCEPTION;
PRAGMA EXCEPTION_INIT(uniq_excp,-0001);
BEGIN
lperr := 'OK';


INSERT INTO CMS_TRANS_DISP(	CTD_INST_CODE		,
				CTD_INTER_CODE		,
				CTD_DISP_CODE		,
				CTD_PAN_CODE		,
				CTD_MBR_NUMB		,
				CTD_AUTH_CODE		,
				CTD_ARN_CODE		,
				CTD_DISP_AMT		,
				CTD_DISP_DATE		,
				CTD_INS_USER		,
				CTD_LUPD_USER		,
				CTD_DISP_STAT		,
				CTD_TRANS_AMT		,
				CTD_TRANS_DATE		,
				CTD_REASON_CODE		,
				CTD_ID_COL		)
	VALUES		(	instcode	,
				lp_intercode	,
				dispcode	,
				lp_pan		,
				lp_mbrnumb	,
				lp_auth_code	,
				arncode		,
				DECODE(dispcode,6,NULL,dispamt)	,--in case of ret ret the dispute amt should go as null else whatever is the input 31-08-02
				SYSDATE		,
				lupduser	,
				lupduser	,
				lp_dispstatus	,
				lp_trans_amt	,
				lp_transdate	,
				reasoncode	,
				lp_idcol	);
EXCEPTION
WHEN uniq_excp THEN
lperr := 'Same type of dispute already registered for this Card.';
WHEN OTHERS THEN
lperr := 'Excp LP3 -- '||SQLERRM;
END;

--4. local procedure to insert the dispute row in cms_retreq_info
--this lp contains two parts
--first find the transaction in ctf reco, if not found theere then find it in base2 recon or vice versa
PROCEDURE lp_pop_retreq_info	(pancode IN VARCHAR2, mbrnumb IN VARCHAR2, idcol_in IN NUMBER, arn IN VARCHAR2, idcol_out OUT NUMBER, purchdate_out OUT DATE, transamt_out OUT NUMBER, authcode_out OUT VARCHAR2, lperr OUT VARCHAR2)
IS
tc	NUMBER (2);
BEGIN		--begin lp4
lperr := 'OK';
IF UPPER(retreq_type) = 'ORIGINAL' THEN	--if 4.1
tc := 51;
ELSIF UPPER(retreq_type) = 'PHOTOCOPY' THEN	--if 4.1
tc := 52;
END IF;		--if 4.1

IF idcol_in IS NULL THEN	--if 4.2
	BEGIN	--begin lp4.1
	--to find out the transaction date, the transaction amount and the authcode, the query has to be repeated
	--SELECT	to_date(rcr_purch_date||to_char(sysdate,'YY'),'MMDDYY'),to_number(rcr_dest_amt)/100,rcr_auth_code
	SELECT	rcr_purch_date,TO_NUMBER(rcr_dest_amt)/100,rcr_auth_code
	INTO	temp_date, transamt_out, authcode_out
	FROM	REC_CTF_RECO
	WHERE	rcr_pan_numb		=	pancode
	AND	rcr_pan_extn		=	mbrnumb
	AND	rcr_acq_ref_numb	=	arncode
	AND	rcr_tran_code		IN	('05','06','07')
	AND	rcr_usage_code		=	'1';
	--74938262109210810034325
	--'4667060018049536';
	IF TO_NUMBER(SUBSTR(temp_date,1,2))>TO_NUMBER(TO_CHAR(SYSDATE,'MM')) THEN
	purchdate_out := TO_DATE(temp_date||SUBSTR(TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))-1,3,2),'MMDDYY');
	ELSE
	purchdate_out := TO_DATE(temp_date||TO_CHAR(SYSDATE,'YY'),'MMDDYY');
	END IF;

	IF TRUNC(SYSDATE) - TRUNC(purchdate_out) > days THEN	--if 4.3
		lperr := 'The dispute registration date is overshooting the allowed timeframe as per the reason code';
	ELSE	--if 4.3
	SELECT	TO_CHAR(SYSDATE,'YYYY')||LPAD(seq_pan_trans.NEXTVAL,10,0)
	INTO	idcol_out
	FROM	dual;
	--now update the table rec_ctf_reco with the id col that is generated
	UPDATE	REC_CTF_RECO
	SET	rcr_id_col		=	idcol_out
	WHERE	rcr_acq_ref_numb	=	arncode
	AND	rcr_tran_code		IN	('05','06','07')
	AND	rcr_usage_code		=	'1';
	--commented on 03-09-02 because arn is common in tcr0 and tcr1 and we want both the rows to be updated
	--by using the commented conditions we were updating only one row(tcr0) because in tcr1 pan was coming as null
	--where as we want both the rows to be updated
	/*rcr_pan_numb		=	pancode
	AND	rcr_pan_extn		=	mbrnumb	*/



	INSERT INTO CMS_RETREQ_INFO (
				CRI_INST_CODE                   , CRI_TRANS_CODE                     ,
				CRI_TRANSCODE_QUAL              , CRI_TRANS_COMP_SEQ_NUMB_TCR0       ,
				CRI_PAN_CODE                    , CRI_MBR_NUMB                       ,
				CRI_ARN_CODE                    , CRI_ACQ_BUISS_ID                   ,
				CRI_PURCHASE_DATE               , CRI_TRANS_AMT                      ,
				CRI_TRANS_CURR_CODE             , CRI_MERC_NAME                      ,
				CRI_MERC_CITY                   , CRI_MERC_CNTRY_CODE                ,
				CRI_MERC_CATG_CODE              , CRI_US_MERC_ZIP_CODE               ,
				CRI_MERC_STATE                  , CRI_ISSUER_CTRL_NUMB               ,
				CRI_REQ_REASON_CODE             , CRI_SETTLEMENT_FLAG                ,
				CRI_NATIONAL_REIMB_FEE		, CRI_ATM_ACCT_SELECTION             ,
				CRI_RETREQ_ID                   , CRI_CENTRAL_PROC_DATE              ,
				CRI_REIMB_ATTRIB                , CRI_TRANS_COMP_SEQ_NUMB_TCR1       ,
				CRI_RESERVED_TCR1_1             , CRI_FAX_NUMBER                     ,
				CRI_INTERFACE_TRACE_NUMB	, CRI_REQ_FULLFILL_METHOD            ,
				CRI_EST_FULLFILL_METHOD		, CRI_ISSUER_RFC_BIN                 ,
				CRI_ISSUER_RFC_SUB_ADDR		, CRI_ISSUER_BILL_CURR_CODE          ,
				CRI_BILL_TRANS_AMT              , CRI_TRANS_IDENT                    ,
				CRI_EXCLD_TRANS_ID_REASON	, CRI_CRS_PROCESS_CODE               ,
				CRI_MULT_CLEARING_SEQ_NUMB	, CRI_RESERVED_TCR1_2                ,
				CRI_TRANS_COMP_SEQ_NUMB_TCR4	, CRI_RESERVED_TCR4_1                ,
				CRI_DEBIT_PROD_CODE             , CRI_CONTACT_FOR_INFO		     ,
				CRI_RESERVED_TCR4_2		, cri_filegen_flag		     ,
				cri_ins_user			, cri_ins_date			     ,
				cri_lupd_user			, cri_lupd_date			     )
	SELECT			1					, tc			      ,
				0					, 0                           ,
				RCR_PAN_NUMB                            , RCR_PAN_EXTN                ,
				RCR_ACQ_REF_NUMB                        , RCR_ACQ_BUS_ID              ,
				RCR_PURCH_DATE                          , RCR_DEST_AMT                ,
				RCR_DEST_CURR                           , RCR_MER_NAME                ,
				RCR_MER_CITY                            , RCR_MER_CNTRY               ,
				RCR_MER_CAT                             , 'USZIP'                     ,
				RCR_MER_STATE_CODE                      , '999999999'                 ,
				'09'                                    , 'F'			      ,
				RCR_NATIONAL_REIMB_FEE			, RCR_ATM_ACCT_SELECTION      ,
				'00123456789'                           , TO_CHAR(SYSDATE,'yddd')     ,
				RCR_REIMB_ATTRIB                        , '1'                         ,
				LPAD(' ', 12, ' ')                      , 'FAX_NUMBER'                ,
				LPAD(' ', 6, ' ')                       , '0'                         ,
				'0'                                     , LPAD('0', 6, '0')	      ,
				LPAD('0', 7, '0')                       , LPAD('0', 3, '0')           ,
				LPAD(' ', 12, ' ')                      , LPAD('0', 12, '0')          ,
				' '                                     , ' '			      ,
				LPAD('0', 2, '0')                       , LPAD(' ', 81, ' ')          ,
				'4'                                     , LPAD(' ', 12, ' ')	      ,
				LPAD('0', 4, '0')                       , LPAD(' ', 25, ' ')          ,
				LPAD(' ', 123, ' ')                     , 'N'			      ,
				lupduser				, SYSDATE		      ,
				lupduser				, SYSDATE
	FROM	REC_CTF_RECO
	WHERE	rcr_pan_numb		=	pancode
	AND	rcr_pan_extn		=	mbrnumb
	AND	rcr_acq_ref_numb	=	arncode
	AND	rcr_tran_code		IN	('05','06','07')
	AND	rcr_usage_code		=	'1';
	END IF;							--if 4.3
	EXCEPTION	--excp of begin lp4.1
	WHEN NO_DATA_FOUND THEN	--means transaction not found in rec_ctf_reco(unreconciled) so look for it into cms_pan_trans,rec_base2_recon(reconciled)
	NULL;
	WHEN OTHERS THEN
	lperr := 'Excp lp4.1 -- '||SQLERRM;
	END	;--end begin lp4.1

ELSIF idcol_in IS NOT NULL THEN	--if 4.2
idcol_out := idcol_in;

--here there are two possibilities again even when the idcol is given as input
--1.the transaction is reconciled ...in that state it can be queried for in the cms_pan_trans
--2.still the transaction might lie in the rec_ctf_reco though due to some previous dispute registration(during which idcol is generated and updated in rec_ctf_reco)

IF source = 'RECONCILED' THEN	--if 4.2.1
	BEGIN	--begin lp4.2
	SELECT	cpt_trans_date,cpt_trans_amt,cpt_auth_code,DECODE(cpt_trans_type,'0','U','1','N')
	INTO	purchdate_out, transamt_out, authcode_out, trans_id
	FROM	CMS_PAN_TRANS
	WHERE	cpt_pan_code	=	pancode
	AND	cpt_mbr_numb	=	mbrnumb
	AND	cpt_id_col	=	idcol	;
	IF trans_id = 'N' THEN	--if 4.4.0 retrival request allowed only for Us-on-remote
	IF TRUNC(SYSDATE) - TRUNC(purchdate_out) > days THEN	--if 4.4
		lperr := 'The dispute registration date is overshooting the allowed timeframe as per the reason code';
	ELSE	--if 4.4
	--now populate the table cms_retreq_info using the rec_base2_recon table
	INSERT INTO CMS_RETREQ_INFO (
				CRI_INST_CODE                   , CRI_TRANS_CODE                     ,
				CRI_TRANSCODE_QUAL              , CRI_TRANS_COMP_SEQ_NUMB_TCR0       ,
				CRI_PAN_CODE                    , CRI_MBR_NUMB                       ,
				CRI_ARN_CODE                    , CRI_ACQ_BUISS_ID                   ,
				CRI_PURCHASE_DATE               , CRI_TRANS_AMT                      ,
				CRI_TRANS_CURR_CODE             , CRI_MERC_NAME                      ,
				CRI_MERC_CITY                   , CRI_MERC_CNTRY_CODE                ,
				CRI_MERC_CATG_CODE              , CRI_US_MERC_ZIP_CODE               ,
				CRI_MERC_STATE                  , CRI_ISSUER_CTRL_NUMB               ,
				CRI_REQ_REASON_CODE             , CRI_SETTLEMENT_FLAG                ,
				CRI_NATIONAL_REIMB_FEE		, CRI_ATM_ACCT_SELECTION             ,
				CRI_RETREQ_ID                   , CRI_CENTRAL_PROC_DATE              ,
				CRI_REIMB_ATTRIB                , CRI_TRANS_COMP_SEQ_NUMB_TCR1       ,
				CRI_RESERVED_TCR1_1             , CRI_FAX_NUMBER                     ,
				CRI_INTERFACE_TRACE_NUMB	, CRI_REQ_FULLFILL_METHOD            ,
				CRI_EST_FULLFILL_METHOD		, CRI_ISSUER_RFC_BIN                 ,
				CRI_ISSUER_RFC_SUB_ADDR		, CRI_ISSUER_BILL_CURR_CODE          ,
				CRI_BILL_TRANS_AMT              , CRI_TRANS_IDENT                    ,
				CRI_EXCLD_TRANS_ID_REASON	, CRI_CRS_PROCESS_CODE               ,
				CRI_MULT_CLEARING_SEQ_NUMB	, CRI_RESERVED_TCR1_2                ,
				CRI_TRANS_COMP_SEQ_NUMB_TCR4	, CRI_RESERVED_TCR4_1                ,
				CRI_DEBIT_PROD_CODE             , CRI_CONTACT_FOR_INFO		     ,
				CRI_RESERVED_TCR4_2		, cri_filegen_flag		     ,
				cri_ins_user			, cri_ins_date			     ,
				cri_lupd_user			, cri_lupd_date			     )
	SELECT			1					, tc			      ,
				0					, 0                           ,
				RBR_PAN_NUMB                            , RBR_PAN_EXTN                ,
				RBR_ACQ_REF_NUMB                        , RBR_ACQ_BUS_ID              ,
				RBR_PURCH_DATE                          , RBR_DEST_AMT                ,
				RBR_DEST_CURR                           , RBR_MER_NAME                ,
				RBR_MER_CITY                            , RBR_MER_CNTRY               ,
				RBR_MER_CAT                             , 'USZIP'                     ,
				RBR_MER_STATE_CODE                      , '999999999'                 ,
				'09'                                    , 'F'			      ,
				RBR_NATIONAL_REIMB_FEE			, RBR_ATM_ACCT_SELECTION      ,
				'00123456789'                           , TO_CHAR(SYSDATE,'yddd')     ,
				RBR_REIMB_ATTRIB                        , '1'                         ,
				LPAD(' ', 12, ' ')                      , 'FAX_NUMBER'                ,
				LPAD(' ', 6, ' ')                       , '0'                         ,
				'0'                                     , LPAD('0', 6, '0')	      ,
				LPAD('0', 7, '0')                       , LPAD('0', 3, '0')           ,
				LPAD(' ', 12, ' ')                      , LPAD('0', 12, '0')          ,
				' '                                     , ' '			      ,
				LPAD('0', 2, '0')                       , LPAD(' ', 81, ' ')          ,
				'4'                                     , LPAD(' ', 12, ' ')	      ,
				LPAD('0', 4, '0')                       , LPAD(' ', 25, ' ')          ,
				LPAD(' ', 123, ' ')                     , 'N'			      ,
				lupduser				, SYSDATE		      ,
				lupduser				, SYSDATE
	FROM	REC_BASE2_RECON
	WHERE	rbr_id_col	=	idcol_in;
	END IF;--if 4.4
	ELSE	--if 4.4.0
	lperr:= 'Retrival request operation allowed only on Us-On-Remote transactions.';
	END IF;--if 4.4.0
	EXCEPTION	--excp of begin lp4.2
	WHEN OTHERS THEN
	lperr := 'Excp lp4.2 -- '||SQLERRM;
	END;	--end begin lp4.2
ELSIF source = 'UNRECONCILED' THEN	--if 4.2.1
/*no need for the below query...can be removed*/
SELECT	1
INTO	dum
FROM	REC_CTF_RECO
WHERE	rcr_id_col = idcol_in;
lperr := 'Transaction already registered for retrival request';
END IF	;--if 4.2.1

END IF	;--if 4.2

EXCEPTION	--excp of lp4
WHEN OTHERS THEN
lperr := 'Excp lp4 -- '||SQLERRM;
END;		--end lp4


--5. local procedure to insert the dispute row in cms_ctf_info
--lp created because the insert statement is very long
PROCEDURE lp_pop_ctf_info(pancode IN VARCHAR2, mbrnumb IN VARCHAR2, arn IN VARCHAR2,authcode IN VARCHAR2, locator IN CHAR, lperr OUT VARCHAR2)
IS
BEGIN			--begin lp5
--locator indicates which source to use to select the transaction if C then in rec_ctf_reco, if B then in rec_base2_recon
lperr := 'OK';
--dbms_output.put_line('Record found in --->>'||locator);


	--begin 1 block gives us the chargeback ref number and is to be generated only in the case of 1st chgbck
	--in case of 2nd chgbck the chgbck ref number should be the same as  used for the first chgbck
	IF dispcode = 1 THEN
	BEGIN		--begin 1
		SELECT	cct_ctrl_code||LPAD(cct_ctrl_numb,3,'0'),cct_ctrl_numb
		INTO	chgbck_ref,ctr
		FROM	CMS_CTRL_TABLE
		WHERE	cct_ctrl_code	= TO_CHAR(SYSDATE,'ddd')
		AND	cct_ctrl_key	= 'CHGBCK REF'
		FOR	UPDATE;

		IF ctr != 1000 THEN
			UPDATE	CMS_CTRL_TABLE
			SET	cct_ctrl_numb = LPAD(TO_NUMBER(cct_ctrl_numb)+1,3,'0')
			WHERE	cct_ctrl_code	= TO_CHAR(SYSDATE,'ddd')
			AND	cct_ctrl_key	= 'CHGBCK REF'	;
		ELSE
			lperr := 'Chargeback count reached 999 for date '||SYSDATE;
		END IF;
	EXCEPTION	--excp of begin 1
		WHEN NO_DATA_FOUND THEN
		chgbck_ref := TO_CHAR(SYSDATE,'ddd')||LPAD('1',3,'0');
		INSERT INTO CMS_CTRL_TABLE(	CCT_CTRL_CODE				,
						CCT_CTRL_KEY				,
						CCT_CTRL_NUMB				,
						CCT_CTRL_DESC				,
						CCT_INS_USER				,
						CCT_LUPD_USER )
				   VALUES (	TO_CHAR(SYSDATE,'ddd')			,
						'CHGBCK REF'				,
						'2'					,
						'COUNTER FOR CHARGEBACK INDICATOR'	,
						lupduser				,
						lupduser				);
	END;		--end begin 1
	END IF;
IF lperr = 'OK' THEN	--lperr if
IF	dispcode = 1 THEN --means the dispute to be registered is first chargeback
	usage_code	:=	'1';
ELSIF dispcode = 3 THEN --means the dispute to be registered is second chargeback
	usage_code	:=	'2';
END IF;
	IF locator = 'C' THEN
	--this is for selection from rec_ctf_reco
	--dbms_output.put_line('Before insertion for  --->>'||locator|' '||sqlerrm);

	BEGIN
	INSERT INTO REC_CTF_INFO(			RCI_TRANS_CODE				, RCI_TRANSCODE_QUAL		,	RCI_TRANS_COMP_SEQ_NUMB		, RCI_PAN_CODE			,
							RCI_MBR_NUMB				, RCI_FLOOR_LIMT_IND		,	RCI_CRB_EXCP_FILE_IND		, RCI_PCAS_IND			,
							RCI_ARN_CODE				, RCI_ACQ_BUISS_ID		,	RCI_PURCHASE_DATE		, RCI_DEST_AMT			,
							RCI_DEST_CURR_CODE			, RCI_SOURCE_AMT		,	RCI_SOURCE_CURR_CODE		, RCI_MERC_NAME			,
							RCI_MERC_CITY				, RCI_MERC_CNTRY_CODE		,	RCI_MERC_CATG_CODE		, RCI_MERC_ZIP_CODE		,
							RCI_MERC_STATE				, RCI_RESQ_PAYMT_SERVICE	,	RCI_RESERVED			, RCI_USAGE_CODE		,
							RCI_REASON_CODE				, RCI_SETTLEMENT_FLAG		, 	RCI_AUTH_CHAR_IND		, RCI_AUTH_CODE			,
							RCI_POS_TERM_CAP			, RCI_INTL_FEE_IND		,	RCI_CARDHOLDER_ID_METHOD	, RCI_COLL_ONLY_FLAG		,
							RCI_POS_ENTRY_MODE			, RCI_CENTRAL_PROCESS_DATE	, 	RCI_REIMB_ATTRIB		, RCI_TRANS_COMP_SEQ_NUMB_TCR1	,
							RCI_ISSUER_WORKSTN_BIN			, RCI_ACQ_WORKSTN_BIN		,	RCI_CHGBCK_REF_NUMB		, RCI_DOC_IND			,
							RCI_MEMB_MESG_TEXT			, RCI_SPCL_COND_IND		,	RCI_RESERVED_TCR1_1		, RCI_CARD_ACCPT_ID		,
							RCI_TERM_ID				, RCI_NATIONAL_REIMB_FEE	,	RCI_MAIL_TEL_ECOM_IND		, RCI_SPCL_CHGBK_IND		,
							RCI_INTERFACE_TRACE_NUMB		, RCI_CARDHOLD_ACT_TERM_IND	,	RCI_PREPAID_CARD_IND		, RCI_SERVICE_DEVLP_FIELD	,
							RCI_AVS_RESP_CODE			, RCI_AUTH_SOURCE_CODE		,	RCI_PURCHASE_ID_FORMAT		, RCI_ATM_ACCT_SELECTION	,
							RCI_INSTALL_PAYMT_COUNT			, RCI_PURCHASE_ID		,	RCI_CASHBACK			, RCI_CHIP_COND_CODE		,
							RCI_RESERVRD_TCR1_2			, RCI_FILEGEN_FLAG		,	RCI_FEE_PROG_IND)
	SELECT					DECODE(a.rcr_tran_code,'05','15','06','16','07','17')		, 0		,	0				,  trim(a.RCR_PAN_NUMB)		,
							a.RCR_PAN_EXTN				, a.RCR_FLOOR_LIMIT		,	a.RCR_CRB_EXCP			,  a.RCR_PCAS			,
							a.RCR_ACQ_REF_NUMB			, a.RCR_ACQ_BUS_ID		,	a.RCR_PURCH_DATE		,  LPAD(0,12,'0')		,
							LPAD(' ',3,' ')				, LPAD((dispamt*100),12,'0')	,	a.RCR_SOURCE_CURR		,  a.RCR_MER_NAME		,
							a.RCR_MER_CITY				, a.RCR_MER_CNTRY		,	a.RCR_MER_CAT			,  a.RCR_MER_ZIP_CODE		,
							a.RCR_MER_STATE_CODE			, a.RCR_REQ_PAYMENT		,	' '				,  usage_code			,
							reasoncode				, a.RCR_SETTL_FLAG		,	a.RCR_AUTH_CHAR_IND		,  a.RCR_AUTH_CODE		,
							a.RCR_POS_TERM_CAP			, a.RCR_INTL_FEE_IND		,	a.RCR_CARD_ID_METHOD		,  a.RCR_COLL_ONLY_FLAG		,
							a.RCR_POS_ENT_MODE			, a.RCR_CENTRAL_PR_DATE		,	a.RCR_REIMB_ATTRIB		,  '1'				,
							b.RCR_SOURCE_BIN			, b.RCR_DEST_BIN		,	DECODE(dispcode,1,chgbck_ref,3,a.rcr_chgbk_ref_numb),  b.RCR_DOC_IND		,
							RPAD(NVL(mesgtext,' '),50,' ')		, b.RCR_SPCL_COND_IND		,	LPAD(' ',2,' ')			,  b.RCR_CARD_ACCPT_ID		,-- Card acceptor ID
							b.RCR_TERM_ID				, b.RCR_NATIONAL_REIMB_FEE	,	b.RCR_MAIL_TEL_ECOM_IND		, 'P'				, -- special chgbk indicator
							LPAD('0',6,'0')				, b.RCR_CARDHOLD_ACT_TERM_IND	,	b.RCR_PREPAID_CARD_IND		, b.RCR_SERVICE_DEVLP_FIELD	,
							b.RCR_AVS_RESP_CODE			, b.RCR_AUTH_SOURCE_CODE	,	b.RCR_PURCHASE_ID_FORMAT	, b.RCR_ATM_ACCT_SELECTION	,
							b.RCR_INSTALL_PAYMT_COUNT		, b.RCR_PURCHASE_ID		,	b.RCR_CASHBACK			, b.RCR_CHIP_COND_CODE		,
							' '					, 'N'				,	LPAD(' ',3,' ')
	FROM		REC_CTF_RECO a, REC_CTF_RECO b
	WHERE		a.rcr_acq_ref_numb	=	b.rcr_acq_ref_numb
	AND		a.rcr_acq_ref_numb	=	arn
	AND		a.rcr_pan_numb		=	pancode
	AND		a.rcr_pan_extn		=	mbrnumb
	AND		a.rcr_tcr_numb		=	0
	AND		b.rcr_tcr_numb		=	1
	AND		a.rcr_tran_code         IN	('05','06','07');
		IF SQL%ROWCOUNT = 0 THEN --this means that the select query did not find any row(because the tcr1 might be absent sometimes in the rec_ctf_reco)
				INSERT INTO REC_CTF_INFO(RCI_TRANS_CODE			, RCI_TRANSCODE_QUAL		,	RCI_TRANS_COMP_SEQ_NUMB		, RCI_PAN_CODE			,
							RCI_MBR_NUMB			, RCI_FLOOR_LIMT_IND		,	RCI_CRB_EXCP_FILE_IND		, RCI_PCAS_IND			,
							RCI_ARN_CODE			, RCI_ACQ_BUISS_ID		,	RCI_PURCHASE_DATE		, RCI_DEST_AMT			,
							RCI_DEST_CURR_CODE		, RCI_SOURCE_AMT		,	RCI_SOURCE_CURR_CODE		, RCI_MERC_NAME			,
							RCI_MERC_CITY			, RCI_MERC_CNTRY_CODE		,	RCI_MERC_CATG_CODE		, RCI_MERC_ZIP_CODE		,
							RCI_MERC_STATE			, RCI_RESQ_PAYMT_SERVICE	,	RCI_RESERVED			, RCI_USAGE_CODE		,
							RCI_REASON_CODE			, RCI_SETTLEMENT_FLAG		, 	RCI_AUTH_CHAR_IND		, RCI_AUTH_CODE			,
							RCI_POS_TERM_CAP		, RCI_INTL_FEE_IND		,	RCI_CARDHOLDER_ID_METHOD	, RCI_COLL_ONLY_FLAG		,
							RCI_POS_ENTRY_MODE		, RCI_CENTRAL_PROCESS_DATE	, 	RCI_REIMB_ATTRIB		, RCI_TRANS_COMP_SEQ_NUMB_TCR1	,
							RCI_ISSUER_WORKSTN_BIN		, RCI_ACQ_WORKSTN_BIN		,	RCI_CHGBCK_REF_NUMB		, RCI_DOC_IND			,
							RCI_MEMB_MESG_TEXT		, RCI_SPCL_COND_IND		,	RCI_RESERVED_TCR1_1		, RCI_CARD_ACCPT_ID		,
							RCI_TERM_ID			, RCI_NATIONAL_REIMB_FEE	,	RCI_MAIL_TEL_ECOM_IND		, RCI_SPCL_CHGBK_IND		,
							RCI_INTERFACE_TRACE_NUMB	, RCI_CARDHOLD_ACT_TERM_IND	,	RCI_PREPAID_CARD_IND		, RCI_SERVICE_DEVLP_FIELD	,
							RCI_AVS_RESP_CODE		, RCI_AUTH_SOURCE_CODE		,	RCI_PURCHASE_ID_FORMAT		, RCI_ATM_ACCT_SELECTION	,
							RCI_INSTALL_PAYMT_COUNT		, RCI_PURCHASE_ID		,	RCI_CASHBACK			, RCI_CHIP_COND_CODE		,
							RCI_RESERVRD_TCR1_2		, RCI_FILEGEN_FLAG		,	RCI_FEE_PROG_IND)
	SELECT					DECODE(a.rcr_tran_code,'05','15','06','16','07','17')	, 0		,	0				,  trim(a.RCR_PAN_NUMB)		,
							a.RCR_PAN_EXTN			, a.RCR_FLOOR_LIMIT		,	a.RCR_CRB_EXCP			,  a.RCR_PCAS			,
							a.RCR_ACQ_REF_NUMB		, a.RCR_ACQ_BUS_ID		,	a.RCR_PURCH_DATE		,  LPAD(0,12,'0')		,
							LPAD(' ',3,' ')			, LPAD((dispamt*100),12,'0')	,	a.RCR_SOURCE_CURR		,  a.RCR_MER_NAME		,
							a.RCR_MER_CITY			, a.RCR_MER_CNTRY		,	a.RCR_MER_CAT			,  a.RCR_MER_ZIP_CODE		,
							a.RCR_MER_STATE_CODE		, a.RCR_REQ_PAYMENT		,	' '				,  usage_code			,
							reasoncode			, a.RCR_SETTL_FLAG		,	a.RCR_AUTH_CHAR_IND		,  a.RCR_AUTH_CODE		,
							a.RCR_POS_TERM_CAP		, a.RCR_INTL_FEE_IND		,	a.RCR_CARD_ID_METHOD		,  a.RCR_COLL_ONLY_FLAG		,
							a.RCR_POS_ENT_MODE		, a.RCR_CENTRAL_PR_DATE		,	a.RCR_REIMB_ATTRIB		,  '1'				,
							b.RCR_SOURCE_BIN		, b.RCR_DEST_BIN		,	DECODE(dispcode,1,chgbck_ref,3,a.rcr_chgbk_ref_numb),  b.RCR_DOC_IND		,
							RPAD(NVL(mesgtext,' '),50,' ')	, b.RCR_SPCL_COND_IND		,	LPAD(' ',2,' ')			,  b.RCR_CARD_ACCPT_ID		,-- Card acceptor ID
							b.RCR_TERM_ID			, b.RCR_NATIONAL_REIMB_FEE	,	b.RCR_MAIL_TEL_ECOM_IND		, 'P'				, -- special chgbk indicator
							LPAD('0',6,'0')			, b.RCR_CARDHOLD_ACT_TERM_IND	,	b.RCR_PREPAID_CARD_IND		, b.RCR_SERVICE_DEVLP_FIELD	,
							b.RCR_AVS_RESP_CODE		, b.RCR_AUTH_SOURCE_CODE	,	b.RCR_PURCHASE_ID_FORMAT	, b.RCR_ATM_ACCT_SELECTION	,
							b.RCR_INSTALL_PAYMT_COUNT	, b.RCR_PURCHASE_ID		,	b.RCR_CASHBACK			, b.RCR_CHIP_COND_CODE		,
							' '				, 'N'				,	LPAD(' ',3,' ')
		FROM		REC_CTF_RECO a, REC_CTF_RECO b
		WHERE		a.rcr_acq_ref_numb	=	b.rcr_acq_ref_numb
		AND		a.rcr_acq_ref_numb	=	arn
		AND		a.rcr_pan_numb		=	pancode
		AND		a.rcr_pan_extn		=	mbrnumb
		AND		a.rcr_tcr_numb		=	0
		AND		a.rcr_tran_code         IN	('05','06','07');
		END IF;
	EXCEPTION
	WHEN OTHERS THEN
	lperr := SQLERRM;
	END;
	--dbms_output.put_line('After insertion for  --->>'||locator||' '||SQLERRM);
	ELSIF locator = 'B' THEN
	--dbms_output.put_line('Before insertion for  --->>'||locator);
	--this is for selection from rec_base2_recon
	BEGIN
	INSERT INTO REC_CTF_INFO(			RCI_TRANS_CODE				, RCI_TRANSCODE_QUAL		,	RCI_TRANS_COMP_SEQ_NUMB		, RCI_PAN_CODE			,
							RCI_MBR_NUMB				, RCI_FLOOR_LIMT_IND		,	RCI_CRB_EXCP_FILE_IND		, RCI_PCAS_IND			,
							RCI_ARN_CODE				, RCI_ACQ_BUISS_ID		,	RCI_PURCHASE_DATE		, RCI_DEST_AMT			,
							RCI_DEST_CURR_CODE			, RCI_SOURCE_AMT		,	RCI_SOURCE_CURR_CODE		, RCI_MERC_NAME			,
							RCI_MERC_CITY				, RCI_MERC_CNTRY_CODE		,	RCI_MERC_CATG_CODE		, RCI_MERC_ZIP_CODE		,
							RCI_MERC_STATE				, RCI_RESQ_PAYMT_SERVICE	,	RCI_RESERVED			, RCI_USAGE_CODE		,
							RCI_REASON_CODE				, RCI_SETTLEMENT_FLAG		, 	RCI_AUTH_CHAR_IND		, RCI_AUTH_CODE			,
							RCI_POS_TERM_CAP			, RCI_INTL_FEE_IND		,	RCI_CARDHOLDER_ID_METHOD	, RCI_COLL_ONLY_FLAG		,
							RCI_POS_ENTRY_MODE			, RCI_CENTRAL_PROCESS_DATE	, 	RCI_REIMB_ATTRIB		, RCI_TRANS_COMP_SEQ_NUMB_TCR1	,
							RCI_ISSUER_WORKSTN_BIN			, RCI_ACQ_WORKSTN_BIN		,	RCI_CHGBCK_REF_NUMB		, RCI_DOC_IND			,
							RCI_MEMB_MESG_TEXT			, RCI_SPCL_COND_IND		,	RCI_RESERVED_TCR1_1		, RCI_CARD_ACCPT_ID		,
							RCI_TERM_ID				, RCI_NATIONAL_REIMB_FEE	,	RCI_MAIL_TEL_ECOM_IND		, RCI_SPCL_CHGBK_IND		,
							RCI_INTERFACE_TRACE_NUMB		, RCI_CARDHOLD_ACT_TERM_IND	,	RCI_PREPAID_CARD_IND		, RCI_SERVICE_DEVLP_FIELD	,
							RCI_AVS_RESP_CODE			, RCI_AUTH_SOURCE_CODE		,	RCI_PURCHASE_ID_FORMAT		, RCI_ATM_ACCT_SELECTION	,
							RCI_INSTALL_PAYMT_COUNT			, RCI_PURCHASE_ID		,	RCI_CASHBACK			, RCI_CHIP_COND_CODE		,
							RCI_RESERVRD_TCR1_2			, RCI_FILEGEN_FLAG		,	RCI_FEE_PROG_IND)
	SELECT						RBR_TRAN_CODE				,  0				,	0				,  trim(RBR_PAN_NUMB)		,
							RBR_PAN_EXTN				,  RBR_FLOOR_LIMIT		,	RBR_CRB_EXCP			,  RBR_PCAS			,
							RBR_ACQ_REF_NUMB			,  RBR_ACQ_BUS_ID		,	RBR_PURCH_DATE			,  LPAD(0,12,'0')		,
							LPAD(' ',3,' ')				,  LPAD((dispamt*100),12,'0')	,	RBR_SOURCE_CURR			,  RBR_MER_NAME			,
							RBR_MER_CITY				,  RBR_MER_CNTRY		,	RBR_MER_CAT			,  RBR_MER_ZIP_CODE		,
							RBR_MER_STATE_CODE			,  RBR_REQ_PAYMENT		,	' '				,  usage_code 			,
							reasoncode				,  RBR_SETTL_FLAG		,	RBR_AUTH_CHAR_IND		,  RBR_AUTH_CODE		,
							RBR_POS_TERM_CAP			,  RBR_INTL_FEE_IND		,	RBR_CARD_ID_METHOD		,  RBR_COLL_ONLY_FLAG		,
							RBR_POS_ENT_MODE			,  RBR_CENTRAL_PR_DATE		,	RBR_REIMB_ATTRIB		,  '1'				,
							RBR_ISSUER_WORKSTN_BIN			,  RBR_ACQ_WORKSTN_BIN		,	DECODE(dispcode,1,chgbck_ref,3,rbr_chgbk_ref_numb),  RBR_DOC_IND,
							RPAD(NVL(mesgtext,' '),50,' ')		,  RBR_SPCL_COND_IND		,	LPAD(' ',2,' ')			,  RBR_CARD_ACCPT_ID		,
							RBR_CTF_TERM_ID				,  RBR_NATIONAL_REIMB_FEE	,	RBR_MAIL_TEL_ECOM_IND		,  'P'				/*RBR_SPCL_CHGBK_IND to add logic for P or F as on 19-08-02*/		,
							LPAD('0',6,'0')				,  RBR_CARDHOLD_ACT_TERM_IND	,	RBR_PREPAID_CARD_IND		,  RBR_SERVICE_DEVLP_FIELD	,
							RBR_AVS_RESP_CODE			,  RBR_AUTH_SOURCE_CODE		,	RBR_PURCHASE_ID_FORMAT          ,  RBR_ATM_ACCT_SELECTION	,
							RBR_INSTALL_PAYMT_COUNT			,  RBR_PURCHASE_ID		,	RBR_CASHBACK			,  RBR_CHIP_COND_CODE		,
							' '					, 'N'				,	LPAD(' ',3,' ')
	FROM		REC_BASE2_RECON
	WHERE		rbr_acq_ref_numb		=	arn
	AND		rbr_pan_numb			=	pancode
	AND		rbr_pan_extn			=	mbrnumb
	AND		rbr_tran_code			IN	('05','06','07');
	EXCEPTION
	WHEN OTHERS THEN
	lperr := SQLERRM;
	END;

	END IF;
END IF	;--lperr if
EXCEPTION		--excp of lp5
WHEN OTHERS THEN
lperr := 'Excp lp5 -- '||SQLERRM;
END;			--end of lp5




/*Procedure Body Starts with Main*/
BEGIN		--Main Begin
dbms_output.put_line('Not yet entered the main proc body');
IF dispcode IN(1,3,6,7) THEN	--if 1
dbms_output.put_line('Just entered the main proc body...dispute code = '||dispcode);

	IF	mbrnumb IS NULL  THEN	--if 2
	v_mbrnumb := '000';
	ELSE				--else 2
	v_mbrnumb := mbrnumb;
	END IF;				--if 2
	errmsg := 'OK';

	lp_get_interchange(pancode,intercode,errmsg);
		dbms_output.put_line('After getting the interchange -- '||errmsg);
	IF errmsg = 'OK' THEN	--if 3
	lp_get_days_limit(intercode,dispcode,reasoncode,days,errmsg);
		dbms_output.put_line('After getting the days limit -- '||errmsg);
	END IF;			--if 3

IF errmsg = 'OK' THEN	--if 4
dbms_output.put_line('Before entering the dispcode 6 if 4 condition');
	/*The Reversal Part*/
	IF dispcode = 7 THEN	--if 5    means this is a check for reversal
	BEGIN	--begin  1
	--SELECT	decode(rbr_recon,'0','U','1','N'/*what about 2? late presentment*/),to_number(rbr_amt1)/100, to_date(rbr_purch_date||to_char(sysdate,'YY'),'MMDDYY'), trim(rbr_resp_cde)
	SELECT	DECODE(rbr_recon,'0','U','1','N'/*what about 2? late presentment*/),TO_NUMBER(rbr_amt1)/100, TO_DATE(rbr_tran_dat,'YYMMDD'), trim(rbr_resp_cde)
	INTO	trans_id,v_trans_amt,v_trans_date,v_auth_code
	FROM	REC_BASE2_RECON
	WHERE	trim(rbr_pan)			=	pancode
	AND	rbr_mbr_num			=	v_mbrnumb
	AND	rbr_id_col			=	idcol;

	--AND	trim(rbr_resp_cde)		=	authcode
	--AND	TO_DATE(rbr_tran_dat,'YYMMDD')	=	TRUNC(transdate);
	IF trans_id = 'U' THEN	--if 5.1 ... means that the transaction is us-on-us (Reversal allowed only for U-O-U)
		IF dispamt > v_trans_amt THEN	--if 6
		errmsg := 'Dispute amount, Rs.'||dispamt||' cannot be greater than the transaction amount Rs.'||v_trans_amt;
			IF TRUNC(SYSDATE) - TRUNC(v_trans_date) > days THEN	--if 7
			errmsg := 'The dispute registration date is overshooting the allowed timeframe as per the reason code';
			END IF;							--if 7
		END IF;				--if 6
		IF errmsg = 'OK' THEN	--if 7
		lp_insert_into_cms_trans_disp(intercode, pancode, v_mbrnumb, v_auth_code, idcol, 'O', v_trans_date, v_trans_amt, errmsg);
		END IF;			--if 7


		IF errmsg = 'OK' THEN	--if 8
		sp_revrse_loyl_for_pan(instcode,pancode,v_mbrnumb,dispamt,idcol,SYSDATE,1,lupduser,errmsg);
			IF errmsg != 'OK' THEN	--if 9
			errmsg := 'From sp_reverse_loyl_for_pan -- '||errmsg;
			END IF;		--if 9
		END IF;		--if 8
	ELSE	--if 5.1
	errmsg := 'Reversal operation allowed only for Us-On-Us transactions.';
	END IF;	--if 5.1
	idcol_spout := idcol;
	EXCEPTION	--excp of begin 1
	WHEN NO_DATA_FOUND THEN
	errmsg := 'Transaction not found for reversal.';
	WHEN OTHERS THEN
	errmsg := 'Excp 1 -- '||SQLERRM;
	END;		--end begin 1
	END IF;	--if 5
	/*End Reversal Part*/

	/*The Retrival Request Part*/
	IF dispcode = 6	THEN--if 10		means this is a check for retrieval request
	dbms_output.put_line('Before entering the dispcode 6 if condition');
	BEGIN	--begin 2
	dbms_output.put_line('Before calling the LP for retreq errmsg = '||errmsg);
	lp_pop_retreq_info (pancode,v_mbrnumb,idcol,arncode,new_idcol,new_purchdate,new_transamt,new_authcode,errmsg);
	dbms_output.put_line('After calling the LP for retreq errmsg = '||errmsg);
		IF errmsg != 'OK' THEN	--if 11
		errmsg := 'From lp_pop_retreq_info -- '||errmsg;
		ELSIF errmsg = 'OK' THEN	--if 11
		idcol_spout := new_idcol;
		lp_insert_into_cms_trans_disp(intercode, pancode, v_mbrnumb, new_authcode, new_idcol, 'O', new_purchdate,new_transamt, errmsg);
		END IF;			--if 11
	END;	--end begin 2
	END IF	;--if 10
	/*End Retrival Request Part*/

	/*The Chargeback Part*/
	IF dispcode IN(1,3) THEN--if 11    means that the dispute is either 1st(1) or 2nd chargeback(3)
		/*IF dispcode =3  THEN -- if 12
			BEGIN	--begin 3 starts
			SELECT	1
			INTO	dum
			FROM	cms_trans_disp
			WHERE	ctd_inst_code	=	instcode
			AND	ctd_disp_code	=	2
			AND	ctd_arn_code	=	arncode
			AND	ctd_pan_code	=	pancode
			AND	ctd_mbr_numb	=	v_mbrnumb
			AND	ctd_id_col	=	idcol;

			EXCEPTION	--excp 3
			WHEN NO_DATA_FOUND THEN
			errmsg	:= 'No Corresponding First Representment found for the requested Second Chargeback';
			WHEN OTHERS THEN
			errmsg	:= 'Excp 3 -- '||SQLERRM;
			END;	--end begin 3
		END IF;		--if 12*/
		IF errmsg = 'OK' THEN	--if 13
			BEGIN		--begin 4
			IF dispcode = 1 THEN	--if 13.1
			dbms_output.put_line('Charge back...first query on the basis of id_col');
			SELECT	cpt_trans_amt,cpt_trans_date,cpt_auth_code,DECODE(cpt_trans_type,'0','U','1','N')
			INTO	v_trans_amt,v_trans_date,v_auth_code,trans_id
			FROM	CMS_PAN_TRANS
			WHERE	cpt_id_col	=	idcol;
			idcol_spout := idcol;
		IF trans_id != 'N' THEN
		errmsg := 'First Chargeback request allowed only on Us-On-Remote transactions.';
		END IF;
			locator := 'B';--means while populating the table rec_ctf_info look in the table rec_base2_recon for data
			ELSIF	dispcode = 3 THEN	--if 13.1
				BEGIN	--begin 3.1
				SELECT	ctd_disp_amt, ctd_disp_date, ctd_trans_amt, ctd_trans_date, ctd_auth_code
				INTO	v_disp_amt,v_disp_date,v_trans_amt,v_trans_date,v_auth_code
				--here the dispute amount and the dispute dates are of concern since they are of the representment. thats why these variables shud be compared with the incoming parameter values for dispute date and dispute amount
				FROM	CMS_TRANS_DISP
				WHERE	ctd_disp_code	=	2--code for representment
				AND	ctd_id_col	=	idcol;
				idcol_spout := idcol;
					--now find out whether its an Us on Network trans
					--commented on 02-09-02 because if the above query returns that means the transaction is an US on remote...so no need to check
					/*BEGIN	--begin 3.1.1
					SELECT	decode(cpt_trans_type,'0','U','1','N')
					INTO	trans_id
					FROM	cms_pan_trans
					WHERE	cpt_id_col	=	idcol;

					EXCEPTION	--excp of begin 3.1.1
					WHEN NO_DATA_FOUND THEN
					errmsg := 'Could not find the transaction for its type.';
					WHEN OTHERS THEN
					errmsg := 'Excp 3.1.1 -- '||SQLERRM;
					END;	--end of begin 3.1.1*/
			IF trans_id != 'N' THEN
			errmsg := 'Second Chargeback request allowed only on Us-On-Remote transactions.';
			END IF;
				locator := 'B';--means while populating the table rec_ctf_info look in the table rec_base2_recon for data
				EXCEPTION	--excp 3.1
				WHEN NO_DATA_FOUND THEN
				errmsg	:= 'No Corresponding Representment found for the requested Second Chargeback';
				WHEN OTHERS THEN
				errmsg	:= 'Excp 3.1 -- '||SQLERRM;
				END;	--end begin 3.1
			END IF;		--if 13.1

			EXCEPTION	--excp 4
			WHEN NO_DATA_FOUND THEN
			--means that the transaction was not found in the reconciled transactions and so it is queried for in the unreconciled transactions
				BEGIN		--begin 5
				--SELECT	to_number(rcr_dest_amt)/100, to_date(rcr_purch_date||to_char(sysdate,'YY'),'MMDDYY'), rcr_id_col, rcr_auth_code
dbms_output.put_line('Charge back...before second query on the basis of pan authcode');
				SELECT	TO_NUMBER(rcr_dest_amt)/100, rcr_purch_date, rcr_id_col, rcr_auth_code
				INTO	v_trans_amt,temp_date,ctf_id_col, v_auth_code
				FROM	REC_CTF_RECO
				WHERE	rcr_acq_ref_numb	=	arncode
				AND	rcr_pan_numb		=	pancode
				AND	rcr_pan_extn		=	v_mbrnumb
				AND	rcr_auth_code		=	authcode;
dbms_output.put_line('Charge back...after second query on the basis of pan authcode');
dbms_output.put_line('Value of temp_date ='||temp_date);
				IF TO_NUMBER(SUBSTR(temp_date,1,2))>TO_NUMBER(TO_CHAR(SYSDATE,'MM')) THEN
dbms_output.put_line('Else cond');
				v_trans_date := TO_DATE(temp_date||SUBSTR(TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))-1,3,2),'MMDDYY');
				ELSE
dbms_output.put_line('Else cond 1');
				v_trans_date := TO_DATE(temp_date||TO_CHAR(SYSDATE,'YY'),'MMDDYY');
dbms_output.put_line('Else cond 2');
				END IF;

				locator := 'C';--means while populating the table rec_ctf_info look in the table rec_ctf_reco for data
				--now generate an id col for this transaction
				IF ctf_id_col IS NULL THEN	--if 13.2 means if at this stage if the id col is not generated in ctf , only then generate it else use the id col(generated while the retrival request)
dbms_output.put_line('Charge back...after second query before generating the id col since it is null');
				SELECT	TO_CHAR(SYSDATE,'YYYY')||LPAD(seq_pan_trans.NEXTVAL,10,0)
				INTO	ctf_id_col
				FROM	dual;
dbms_output.put_line('Generated id col='||ctf_id_col);
				idcol_spout := ctf_id_col;
dbms_output.put_line('Before updation of table rec_ctf_reco');
				UPDATE	REC_CTF_RECO
				SET	rcr_id_col		= ctf_id_col
				WHERE	rcr_acq_ref_numb	= arncode;
	--commented on 03-09-02 because arn is common in tcr0 and tcr1 and we want both the rows to be updated
	--by using the commented conditions we were updating only one row(tcr0) because in tcr1 pan was coming as null
	--where as we want both the rows to be updated
				/*AND	rcr_pan_numb		= pancode
				AND	rcr_pan_extn		= v_mbrnumb
				AND	rcr_auth_code		= authcode;*/
dbms_output.put_line('After updation of table rec_ctf_reco with newly gen id col and rows updated ='||SQL%rowcount);
				ELSE	--if 13.2 --means if the record is still unreconciled lying in ctf reco the out the earlier id col to the front end 31-08-02
				idcol_spout := ctf_id_col;
				END IF;	--if 13.2

				EXCEPTION	--excp 5
				WHEN NO_DATA_FOUND THEN
				errmsg := 'Transaction not found in both reconciled and unreconciled transactions.';
				WHEN TOO_MANY_ROWS THEN
				errmsg := 'Too many transactions found.';
				WHEN OTHERS THEN
				errmsg := 'Excp 5 -- '||SQLERRM;
				END;		--end begin 5
			WHEN OTHERS THEN
			errmsg := 'Excp 4 -- '||SQLERRM;
			END;		--end begin 4
			IF errmsg = 'OK' THEN	--if 14	means transaction found somewhere in either recon or unrecon transactions
			--now perform the amount and the reasoncode/days validations
				IF dispcode = 1 THEN --if 14.1
					IF dispamt > v_trans_amt THEN	--if 15
					errmsg := 'Dispute amount, Rs.'||dispamt||' cannot be greater than the transaction amount Rs.'||v_trans_amt;
						IF TRUNC(SYSDATE) - TRUNC(v_trans_date) > days THEN	--if 16
						errmsg := 'The dispute registration date is overshooting the allowed timeframe as per the reason code';
						END IF;	--if 16
					END IF;	--if 15
				ELSIF dispcode = 3 THEN	--if 14.1
					IF dispamt > v_disp_amt THEN	--if 15.1
					errmsg := 'Dispute amount, Rs.'||dispamt||' cannot be greater than the transaction amount Rs.'||v_disp_amt;
						IF TRUNC(SYSDATE) - TRUNC(v_disp_date) > days THEN	--if 16.1
						errmsg := 'The dispute registration date is overshooting the allowed timeframe as per the reason code';
						END IF;	--if 16.1
					END IF;	--if 15.1
				END IF;	--if 14.1
			END IF;	--if 14
			IF errmsg = 'OK' THEN--if 17
		--now call the local procedure for inserting into cms_trans_disp...
				lp_insert_into_cms_trans_disp(intercode, pancode, v_mbrnumb, v_auth_code, /*ctf_id_col*/idcol_spout, 'O', v_trans_date, v_trans_amt, errmsg);
			END IF;	--if 17

			IF errmsg = 'OK' THEN	--if 18
			IF dispcode = 1 THEN -- if 19... means the loyl points reversal proc to be called only in case of 1st chgbck
			sp_revrse_loyl_for_pan(instcode,pancode,v_mbrnumb,dispamt,idcol,SYSDATE,1,lupduser,errmsg);
				IF errmsg != 'OK' THEN	--if 20
				errmsg := 'From sp_reverse_loyl_for_pan -- '||errmsg;
				END IF;		--if 20
			END IF;	--if 19
			END IF;		--if 18

			IF errmsg = 'OK' THEN	--if 21
			--now generate the rows outgoing ctf
			lp_pop_ctf_info(pancode,v_mbrnumb,arncode,authcode,locator,errmsg);
					IF errmsg != 'OK' THEN	--if 22
					errmsg := 'From lp_pop_ctf_info for dispute code 3 -- '||errmsg;
					END IF;	--if 22
			END IF;	--if 21


		END IF;	--if 13
	END IF	;--if 11
	/*The Chargeback Part*/
END IF;	--if 4

ELSE		--else 1
errmsg := 'Not a valid dispute registration.';
END IF;		--if 1
EXCEPTION	--Exception of Main begin
WHEN OTHERS THEN
errmsg := 'Main Exception '||SQLERRM;
END;		--Main Begin ends
/


