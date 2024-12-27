CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Tran_Fees_Product
(prm_inst_code	     IN NUMBER,
prm_del_channel		IN		VARCHAR2,
prm_tran_type		IN		VARCHAR2,	-- FIN/NON FIN TRAN
prm_tran_mode		IN		VARCHAR2,	-- ONUS/OFFUS
prm_tran_code		IN		VARCHAR2,
prm_currency_code	IN		VARCHAR2,
prm_trn_amt		IN		NUMBER,
prm_prod_code		IN		VARCHAR2,
prm_card_type		IN		NUMBER,
prm_consodium_code	IN		NUMBER,
prm_partner_code	IN		NUMBER,
prm_tran_date       IN      DATE,
prm_fee_code		OUT		NUMBER,
prm_flat_fee		OUT		NUMBER,
prm_per_fees		OUT		NUMBER,
prm_min_fees		OUT		NUMBER,
prm_tran_fee		OUT		NUMBER,
prm_error		OUT		VARCHAR2,
prm_crgl_catg           OUT             VARCHAR2,
prm_crgl_code           OUT             VARCHAR2,
prm_crsubgl_code        OUT             VARCHAR2,
prm_cracct_no           OUT             VARCHAR2,
prm_drgl_catg           OUT             VARCHAR2,
prm_drgl_code           OUT             VARCHAR2,
prm_drsubgl_code        OUT             VARCHAR2,
prm_dracct_no           OUT             VARCHAR2,
prm_st_calc_flag				   OUT            VARCHAR2,
prm_cess_calc_flag			   OUT 			  VARCHAR2	 ,
prm_st_cracct_no				  OUT	   VARCHAR2,
prm_st_dracct_no				   OUT			   VARCHAR2,
prm_cess_cracct_no				OUT	 		   VARCHAR2,
prm_cess_dracct_no				OUT			   VARCHAR2
)
IS
/***************************************************************************************
     * VERSION               :  1.1
     * DATE OF CREATION      : 24/MAY/2008
     * CREATED BY            : Sachin Nikam
     * PURPOSE               : PROCEDURE TO FIND FEE APPLIED ON PRODUCT
     * MODIFICATION REASON   : To return gl_acct detail from procedure.
     *
     *
     * LAST MODIFICATION DONE BY : Chinmaya Behera
     * LAST MODIFICATION DATE    : 21-July-2008
     *
****************************************************************************************/
exp_main	EXCEPTION		;
exp_nofees	EXCEPTION		;
BEGIN
	prm_error := 'OK'	;
	BEGIN -- BEGIN 1
		SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
			cpf_crgl_catg,
			cpf_crgl_code,
			cpf_crsubgl_code,
			cpf_cracct_no,
			cpf_drgl_catg,
			cpf_drgl_code,
			cpf_drsubgl_code,
			cpf_dracct_no,
			 cpf_st_calc_flag ,
			 cpf_cess_calc_flag,
			 cpf_st_cracct_no,
			 cpf_st_dracct_no,
			 cpf_cess_cracct_no,
			 cpf_cess_dracct_no
					INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
			prm_crgl_catg    ,
			prm_crgl_code    ,
			prm_crsubgl_code ,
			prm_cracct_no    ,
			prm_drgl_catg    ,
			prm_drgl_code    ,
			prm_drsubgl_code ,
			prm_dracct_no ,
			prm_st_calc_flag,
			prm_cess_calc_flag,
			prm_st_cracct_no,
			prm_st_dracct_no,
			prm_cess_cracct_no,
			prm_cess_dracct_no
		FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
		WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
		AND   cpf_card_type		= prm_card_type
		AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
		AND   cfm_fee_code		= cpf_fee_code
		AND   cfm_delivery_channel	= prm_del_channel
		AND   cfm_tran_type		= prm_tran_type
		AND   cfm_tran_code		= prm_tran_code
		AND   cfm_tran_mode		= prm_tran_mode
		AND   cfm_consodium_code	= prm_consodium_code
		AND   cfm_partner_code		= prm_partner_code
		AND   cfm_currency_code		= prm_currency_code
		;
		prm_tran_fee := 1	;
	EXCEPTION -- EXCEPTION 1
		WHEN NO_DATA_FOUND THEN
			BEGIN -- BEGIN 2
				SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
					cpf_crgl_catg,
					cpf_crgl_code,
					cpf_crsubgl_code,
					cpf_cracct_no,
					cpf_drgl_catg,
					cpf_drgl_code,
					cpf_drsubgl_code,
					cpf_dracct_no,
					cpf_st_calc_flag ,
					 cpf_cess_calc_flag,
					 cpf_st_cracct_no,
					 cpf_st_dracct_no,
					 cpf_cess_cracct_no,
					 cpf_cess_dracct_no
				INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
					prm_crgl_catg    ,
					prm_crgl_code    ,
					prm_crsubgl_code ,
					prm_cracct_no    ,
					prm_drgl_catg    ,
					prm_drgl_code    ,
					prm_drsubgl_code ,
					prm_dracct_no,
					prm_st_calc_flag,
					prm_cess_calc_flag,
					prm_st_cracct_no,
					prm_st_dracct_no,
					prm_cess_cracct_no,
					prm_cess_dracct_no
				FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
				WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
				AND   cpf_card_type		= prm_card_type
				AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
				AND   cfm_fee_code		= cpf_fee_code
				AND   cfm_delivery_channel	= prm_del_channel
				AND   cfm_tran_type		= prm_tran_type
				AND   cfm_tran_code		= prm_tran_code
				AND   cfm_tran_mode		= prm_tran_mode
				AND   cfm_currency_code		= prm_currency_code
				AND   cfm_consodium_code	= prm_consodium_code
				AND   cfm_partner_code		IS NULL ;
				prm_tran_fee := 1	;
			EXCEPTION -- EXCEPTION 2
				WHEN NO_DATA_FOUND THEN
					BEGIN -- BEGIN 3
						SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
							cpf_crgl_catg,
							cpf_crgl_code,
							cpf_crsubgl_code,
							cpf_cracct_no,
							cpf_drgl_catg,
							cpf_drgl_code,
							cpf_drsubgl_code,
							cpf_dracct_no,
							cpf_st_calc_flag ,
							 cpf_cess_calc_flag,
							 cpf_st_cracct_no,
							 cpf_st_dracct_no,
							 cpf_cess_cracct_no,
							 cpf_cess_dracct_no
						INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
							prm_crgl_catg    ,
							prm_crgl_code    ,
							prm_crsubgl_code ,
							prm_cracct_no    ,
							prm_drgl_catg    ,
							prm_drgl_code    ,
							prm_drsubgl_code ,
							prm_dracct_no,
							prm_st_calc_flag,
							prm_cess_calc_flag,
							prm_st_cracct_no,
							prm_st_dracct_no,
							prm_cess_cracct_no,
							prm_cess_dracct_no
						FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
						WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
						AND   cpf_card_type		= prm_card_type
						AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
						AND   cfm_fee_code		= cpf_fee_code
						AND   cfm_delivery_channel	= prm_del_channel
						AND   cfm_tran_type		= prm_tran_type
						AND   cfm_tran_code		= prm_tran_code
						AND   cfm_tran_mode		= prm_tran_mode
						AND   cfm_currency_code		= prm_currency_code
						AND   cfm_consodium_code	IS NULL
						AND   cfm_partner_code		IS NULL;
						prm_tran_fee := 1	;
					EXCEPTION -- EXCEPTION 3
						WHEN NO_DATA_FOUND THEN
							BEGIN -- BEGIN 4
								SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
									cpf_crgl_catg,
									cpf_crgl_code,
									cpf_crsubgl_code,
									cpf_cracct_no,
									cpf_drgl_catg,
									cpf_drgl_code,
									cpf_drsubgl_code,
									cpf_dracct_no,
									cpf_st_calc_flag ,
									 cpf_cess_calc_flag,
									 cpf_st_cracct_no,
									 cpf_st_dracct_no,
									 cpf_cess_cracct_no,
									 cpf_cess_dracct_no
								INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
									prm_crgl_catg    ,
									prm_crgl_code    ,
									prm_crsubgl_code ,
									prm_cracct_no    ,
									prm_drgl_catg    ,
									prm_drgl_code    ,
									prm_drsubgl_code ,
									prm_dracct_no ,
									prm_st_calc_flag,
									prm_cess_calc_flag,
									prm_st_cracct_no,
									prm_st_dracct_no,
									prm_cess_cracct_no,
									prm_cess_dracct_no
								FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
								WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
								AND   cpf_card_type		= prm_card_type
								AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
								AND   cfm_fee_code		= cpf_fee_code
								AND   cfm_delivery_channel	= prm_del_channel
								AND   cfm_tran_type		= prm_tran_type
								AND   cfm_tran_code		= prm_tran_code
								AND   cfm_tran_mode		= prm_tran_mode
								AND   cfm_currency_code		IS NULL
								AND   cfm_consodium_code	IS NULL
								AND   cfm_partner_code		IS NULL;
								prm_tran_fee := 1	;
							EXCEPTION -- EXCEPTION 4
								WHEN NO_DATA_FOUND THEN
									BEGIN -- BEGIN 5
										SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
											cpf_crgl_catg,
											cpf_crgl_code,
											cpf_crsubgl_code,
											cpf_cracct_no,
											cpf_drgl_catg,
											cpf_drgl_code,
											cpf_drsubgl_code,
											cpf_dracct_no,
											cpf_st_calc_flag ,
											 cpf_cess_calc_flag,
											 cpf_st_cracct_no,
											 cpf_st_dracct_no,
											 cpf_cess_cracct_no,
											 cpf_cess_dracct_no
										INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
											prm_crgl_catg    ,
											prm_crgl_code    ,
											prm_crsubgl_code ,
											prm_cracct_no    ,
											prm_drgl_catg    ,
											prm_drgl_code    ,
											prm_drsubgl_code ,
											prm_dracct_no ,
											prm_st_calc_flag,
											prm_cess_calc_flag,
											prm_st_cracct_no,
											prm_st_dracct_no,
											prm_cess_cracct_no,
											prm_cess_dracct_no
										FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
										WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
										AND   cpf_card_type		= prm_card_type
										AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
										AND   cfm_fee_code		= cpf_fee_code
										AND   cfm_delivery_channel	= prm_del_channel
										AND   cfm_tran_type		= prm_tran_type
										AND   cfm_tran_code		= prm_tran_code
										AND   cfm_tran_mode		IS NULL
										AND   cfm_consodium_code	IS NULL
										AND   cfm_partner_code		IS NULL
										AND   cfm_currency_code		IS NULL
										;
										prm_tran_fee := 1	;
									EXCEPTION -- EXCEPTION 5
										WHEN NO_DATA_FOUND THEN
											BEGIN -- BEGIN 6
												SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
													cpf_crgl_catg,
													cpf_crgl_code,
													cpf_crsubgl_code,
													cpf_cracct_no,
													cpf_drgl_catg,
													cpf_drgl_code,
													cpf_drsubgl_code,
													cpf_dracct_no,
													cpf_st_calc_flag ,
													 cpf_cess_calc_flag,
													 cpf_st_cracct_no,
													 cpf_st_dracct_no,
													 cpf_cess_cracct_no,
													 cpf_cess_dracct_no
												INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
													prm_crgl_catg    ,
													prm_crgl_code    ,
													prm_crsubgl_code ,
													prm_cracct_no    ,
													prm_drgl_catg    ,
													prm_drgl_code    ,
													prm_drsubgl_code ,
													prm_dracct_no,
													prm_st_calc_flag,
													prm_cess_calc_flag,
													prm_st_cracct_no,
													prm_st_dracct_no,
													prm_cess_cracct_no,
													prm_cess_dracct_no
												FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
												WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
												AND   cpf_card_type		= prm_card_type
												AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
												AND   cfm_fee_code		= cpf_fee_code
												AND   cfm_delivery_channel	= prm_del_channel
												AND   cfm_tran_type		= prm_tran_type
												AND   cfm_tran_code		IS NULL
												AND   cfm_tran_mode		IS NULL
												AND   cfm_consodium_code	IS NULL
												AND   cfm_partner_code		IS NULL
												AND   cfm_currency_code		IS NULL
												;
												prm_tran_fee := 1	;
											EXCEPTION -- -- EXCEPTION 6
												WHEN NO_DATA_FOUND THEN
													BEGIN -- BEGIN 7
														SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
															cpf_crgl_catg,
															cpf_crgl_code,
															cpf_crsubgl_code,
															cpf_cracct_no,
															cpf_drgl_catg,
															cpf_drgl_code,
															cpf_drsubgl_code,
															cpf_dracct_no,
															cpf_st_calc_flag ,
															 cpf_cess_calc_flag,
															 cpf_st_cracct_no,
															 cpf_st_dracct_no,
															 cpf_cess_cracct_no,
															 cpf_cess_dracct_no
														INTO	prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
															prm_crgl_catg    ,
															prm_crgl_code    ,
															prm_crsubgl_code ,
															prm_cracct_no    ,
															prm_drgl_catg    ,
															prm_drgl_code    ,
															prm_drsubgl_code ,
															prm_dracct_no ,
															prm_st_calc_flag,
															prm_cess_calc_flag,
															prm_st_cracct_no,
															prm_st_dracct_no,
															prm_cess_cracct_no,
															prm_cess_dracct_no
														FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
														WHERE CFM_INST_CODE = prm_inst_code 
		and  CFM_INST_CODE=CPF_INST_CODE 
		and cpf_prod_code		= prm_prod_code
														AND   cpf_card_type		= prm_card_type
														AND   prm_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
														AND   cfm_fee_code		= cpf_fee_code
														AND   cfm_delivery_channel	= prm_del_channel
														AND   cfm_tran_type		IS NULL
														AND   cfm_tran_code		IS NULL
														AND   cfm_tran_mode		IS NULL
														AND   cfm_consodium_code	IS NULL
														AND   cfm_partner_code		IS NULL
														AND   cfm_currency_code		IS NULL
														;
														prm_tran_fee := 1	;
													EXCEPTION -- EXCEPTION 7
														WHEN NO_DATA_FOUND THEN
																prm_error := 'NO FEES ATTACHED'	;
																RAISE exp_nofees; -- NO FEES ATTACHED RETURN -1
														WHEN OTHERS THEN
															prm_error := 'ERROR FROM MAIN 7 =>' || SQLERRM	;
															RAISE exp_main;
													END ; -- END 7
												WHEN OTHERS THEN
													prm_error := 'ERROR FROM MAIN 6 =>' || SQLERRM	;
													RAISE exp_main;
											END ; -- END 6
										WHEN OTHERS THEN
											prm_error := 'ERROR FROM MAIN 5 =>' || SQLERRM	;
											RAISE exp_main;
									END ; -- END 5
								WHEN OTHERS THEN
									prm_error := 'ERROR FROM MAIN 4 =>' || SQLERRM	;
									RAISE exp_main;
							END ; -- END 4
						WHEN OTHERS THEN
							prm_error := 'ERROR FROM MAIN 3 =>' || SQLERRM	;
							RAISE exp_main;
					END ; -- END 3
				WHEN OTHERS THEN
					prm_error := 'ERROR FROM MAIN 2 =>' || SQLERRM	;
					RAISE exp_main;
			END ; -- END 2
		WHEN OTHERS THEN
			prm_error := 'ERROR FROM MAIN 1 =>' || SQLERRM	;
			RAISE exp_main;
	END ; -- END 1
EXCEPTION -- MAIN
	WHEN exp_nofees	THEN
	prm_tran_fee := 0	;
	WHEN exp_main THEN
		prm_error := prm_error	;
		prm_tran_fee := -1	;
	WHEN OTHERS THEN
		prm_error := SQLERRM	;
		prm_tran_fee := -1	;
END; -- MAIN
/


SHOW ERRORS