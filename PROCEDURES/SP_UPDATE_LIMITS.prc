CREATE OR REPLACE PROCEDURE VMSCMS.sp_update_limits
(
p_instcode		IN	NUMBER		,
p_pancode	 	IN	VARCHAR2	,
p_remark		IN	VARCHAR2	,
p_rsncode		IN	NUMBER		,
p_atmofflinelimit	IN	NUMBER	,
p_atmonlinelimit	IN	NUMBER	,
p_posofflinelimit	IN	NUMBER	,
p_posonlinelimit	IN	NUMBER	,
p_paymentofflinelimit	IN       NUMBER,
p_paymentonlinelimit   IN       NUMBER,
p_flag 			IN	VARCHAR2, -- 2 indicate the process used, U - upload, S - Screen
p_lupduser		IN	NUMBER	,
p_errmsg			OUT	VARCHAR2
)
AS

v_prod_catg		CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg		VARCHAR2(500):='OK';
v_mbrnumb		CMS_APPL_PAN.cap_mbr_numb%type;
exp_reject_record	EXCEPTION;
v_savepoint		NUMBER	DEFAULT 0;
v_card_stat cms_appl_pan.cap_card_stat%type;
v_txn_code               VARCHAR2 (2);
v_txn_type               VARCHAR2 (2);
v_txn_mode               VARCHAR2 (2);
v_del_channel            VARCHAR2 (2);
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
v_hash_pan    cms_appl_pan.cap_pan_code%type;
v_encr_pan    cms_appl_pan.cap_pan_code_encr%type;


BEGIN

v_savepoint := v_savepoint + 1;
SAVEPOINT v_savepoint;
p_errmsg  := 'OK';

--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN ;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN ;
END;
--EN create encr pan


		---------------------
		-- SN FIND PROD CATG
		--------------------
		BEGIN
			SELECT cap_prod_catg,cap_card_stat
			INTO   v_prod_catg, v_card_stat
			FROM   CMS_APPL_PAN
			WHERE  cap_pan_code  = v_hash_pan--p_pancode
			AND    cap_inst_code = p_instcode;


		EXCEPTION

		WHEN NO_DATA_FOUND THEN
			v_errmsg := 'Product category not defined in master';
			RAISE exp_reject_record;

		WHEN OTHERS THEN
			v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
			RAISE exp_reject_record;
		END;

		--------------------
		--EN FIND PROD CATG
		--------------------
    IF v_card_stat <> '1' THEN
		    v_errmsg := 'Card status in not open, cannot be updated';
			RAISE exp_reject_record;
		END IF;

    ------------------------------ Sn get Function Master----------------------------
   BEGIN
		SELECT  cfm_txn_code,
		        cfm_txn_mode,
		        cfm_delivery_channel,
		        cfm_txn_type
		INTO	v_txn_code,
				v_txn_mode,
				v_del_channel,
				v_txn_type
		FROM	CMS_FUNC_MAST
		WHERE 	 cfm_func_code = 'LIMT'
    AND      cfm_inst_code= p_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
                   'Function Master Not Defined for Delink' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
   ------------------------------ En get Function Master----------------------------


------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'updatelimits'
                  AND csr_spprt_rsncode=p_rsncode
                  AND csr_inst_code = p_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Update limit reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

   ------------------------------start find member number--------------------------
   	BEGIN

			SELECT cip_param_value
			INTO   v_mbrnumb
			FROM   CMS_INST_PARAM
			WHERE  cip_inst_code = p_instcode
			AND    cip_param_key = 'MBR_NUMB';

		EXCEPTION

			WHEN NO_DATA_FOUND THEN
				v_errmsg := 'memeber number not defined in master';
				RAISE exp_reject_record;
			WHEN OTHERS THEN
				v_errmsg := 'Error while selecting memeber number '|| substr(sqlerrm,1,200);
				RAISE exp_reject_record;
		END;
   ------------------------------end find member number----------------------------

		--SN CHECK PRODUCT CATG
		-------------------------
		IF v_prod_catg = 'P' THEN
		------------------------------
		--SN: ACCOUNT UPDATE LIMITS FOR PREPAID
		-------------------------------

			null;

		-------------------------------
		--EN: ACCOUNT UPDATE LIMITS FOR PREPAID
		-------------------------------

		ELSIF v_prod_catg in('D','A') THEN

		-------------------------------
		--SN: ACCOUNT UPDATE LIMITS FOR DEBIT
		-------------------------------

		sp_update_limits_debit (
					p_instcode	,
					p_pancode	,
					v_mbrnumb	,
					p_remark	,
					p_rsncode	,
					p_atmofflinelimit,
					p_atmonlinelimit,
					p_posofflinelimit,
					p_posonlinelimit,
					p_paymentofflinelimit,
					p_paymentonlinelimit ,
					p_flag 		,
					p_lupduser	,
					v_errmsg
			            );

			IF v_errmsg <> 'OK' THEN

				RAISE exp_reject_record;
			ELSE

				-------------------------------
				--SN CREATE SUCCESSFUL RECORDS
				-------------------------------

				BEGIN
				INSERT INTO CMS_UPD_LIMIT_DETAIL (
						cud_inst_code   ,
						cud_card_no     ,
						cud_file_name   ,
						cud_remarks     ,
						cud_msg24_flag  ,
						cud_process_flag,
						cud_process_msg ,
						cud_process_mode,
						cud_ins_user    ,
						cud_ins_date    ,
						cud_lupd_user   ,
						cud_lupd_date   ,
            cud_card_no_encr
						)
					   VALUES ( p_instcode,
						    v_hash_pan,--p_pancode
						    NULL,
						    p_remark,
						    'N',
						    'S',
						    'SUCCESSFUL',
						    'S',
						    p_lupduser,
						    sysdate,
						    p_lupduser,
						    sysdate,
                v_encr_pan
				  );
				EXCEPTION

				WHEN OTHERS THEN

					 ROLLBACK TO v_savepoint;

					 p_errmsg := 'ERROR WHILE LOGGING SUCCESSFUL RECORDS ' || substr(sqlerrm,1,150);
					 RETURN;
				END;

				-------------------------------
				--EN CREATE SUCCESSFUL RECORDS
				-------------------------------

				-------------------------------
				--SN CREATE AUDIT LOG RECORDS
				-------------------------------

				  BEGIN
				  INSERT INTO PROCESS_AUDIT_LOG
						(
						 pal_inst_code,
						 pal_card_no,
						 pal_activity_type,
						 pal_transaction_code,
						 pal_delv_chnl,
						 pal_tran_amt,
						 pal_source,
						 pal_success_flag,
						 pal_ins_user,
						 pal_ins_date,
						 pal_process_msg,
						 pal_reason_desc,
						 pal_remarks,
						 pal_spprt_type,
             pal_card_no_encr
						)
				      VALUES
						(p_instcode,
						 v_hash_pan,--p_pancode
						 'Update limit',
						 v_txn_code,
						 v_del_channel,
						 0,
						 'HOST',
						 'S',
						 p_lupduser,
						 sysdate,
						 'SUCCESSFUL',
						 v_reasondesc,
						 p_remark,
						 'S',
             v_encr_pan
				     );
				EXCEPTION

					WHEN OTHERS THEN
						p_errmsg := 'ERROR WHILE LOGGING AUDIT FOR SUCCESS RECORDS ' || substr(sqlerrm,1,150);
						RAISE exp_reject_record;
				END;

				------------------------------
				--EN CREATE AUDIT LOG RECORDS
				------------------------------

			END IF;

			-------------------------------
			--EN ACCOUNT UPDATE LIMITS FOR DEBIT
			-------------------------------

		ELSE
			v_errmsg := 'NOT A VALID PRODUCT CATEGORY FOR ACT DELINK';
			RAISE exp_reject_record;

		END IF;

		------------------------
		--EN CHECK PRODUCT CATG
		-------------------------



EXCEPTION		-- MAIN EXCEPTION

WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;

p_errmsg :=	v_errmsg	;

	sp_upd_limit_support_log
		    (
		     p_instcode,
		     p_pancode,
		     NULL,
		     p_remark,
		     'N',
		     'E',
		     v_errmsg,
		     'S',
		     p_lupduser,
		     SYSDATE,
	           'Update limit',
		     v_txn_code,
		     v_del_channel,
		     0,
		    'HOST',
		     v_reasondesc,
		     'S',
		     p_errmsg
		   );

	IF p_errmsg <> 'OK' THEN
	   RETURN;
	ELSE
	   p_errmsg  := v_errmsg;
	END IF;

WHEN OTHERS THEN

	v_errmsg := ' ERROR FROM MAIN ' || substr(sqlerrm,1,200);

	p_errmsg :=	v_errmsg	;

	sp_upd_limit_support_log
		    (
		     p_instcode,
		     p_pancode,
		     NULL,
		     p_remark,
		     'N',
		     'E',
		     v_errmsg,
		     'S',
		     p_lupduser,
		     SYSDATE,
	            'Update limit',
		     v_txn_code,
		     v_del_channel,
		     0,
		    'HOST',
		     v_reasondesc,
		     'S',
		     p_errmsg
		   );
	IF p_errmsg <> 'OK' THEN
	   RETURN;
	ELSE
	   p_errmsg  := v_errmsg;
	END IF;

END;
/
SHOW ERRORS

