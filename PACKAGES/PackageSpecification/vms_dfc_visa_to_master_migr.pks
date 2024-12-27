CREATE OR REPLACE PACKAGE vmscms.vms_dfc_visa_to_master_migr IS

  -- Author  : NARAYANAST
  -- Created : 3/7/2016 12:30:23 PM
  -- Purpose : To migrate the existing Visa cards to Master card when Activation
  --FSS-4129 - DFC Momentum Visa to MasterCard Migration

  PROCEDURE activate_intial_load_migr(p_instcode_in         IN NUMBER,
							   p_rrn_in              IN VARCHAR2,
							   p_terminalid_in       IN VARCHAR2,
							   p_trandate_in         IN VARCHAR2,
							   p_trantime_in         IN VARCHAR2,
							   p_card_no_in          IN VARCHAR2,
							   p_migrcard_in         IN VARCHAR2,
							   p_amount_in           IN NUMBER,
							   p_currcode_in         IN VARCHAR2,
							   p_lupduser_in         IN NUMBER,
							   p_msg_type_in         IN VARCHAR2,
							   p_txn_code_in         IN VARCHAR2,
							   p_txn_mode_in         IN VARCHAR2,
							   p_delivery_channel_in IN VARCHAR2,
							   p_mbr_numb_in         IN VARCHAR2,
							   p_rvsl_code_in        IN VARCHAR2,
							   p_prod_id_in          IN VARCHAR2,
							   p_merchant_name_in    IN VARCHAR2,
							   p_merchant_city_in    IN VARCHAR2,
							   p_fee_plan_id_in      IN VARCHAR2,
							   p_storeid_in          IN VARCHAR2,
							   p_optin_in            IN VARCHAR2,
							   p_taxprepareid_in     IN VARCHAR2,
							   p_reason_code_in      IN VARCHAR2,
							   p_gpr_optin_in        IN VARCHAR2,
							   p_optin_list_in       IN VARCHAR2,
							   p_resp_code_out       OUT VARCHAR2,
							   p_errmsg_out          OUT VARCHAR2,
							   p_dda_number_out      OUT VARCHAR2);

  -- Migration Reversal
  PROCEDURE reverse_activate_initial_load(p_inst_code_in     IN NUMBER,
								  p_msg_typ_in       IN VARCHAR2,
								  p_rvsl_code_in     IN VARCHAR2,
								  p_rrn_in           IN VARCHAR2,
								  p_delv_chnl_in     IN VARCHAR2,
								  p_terminal_id_in   IN VARCHAR2,
								  p_txn_code_in      IN VARCHAR2,
								  p_txn_type_in      IN VARCHAR2,
								  p_txn_mode_in      IN VARCHAR2,
								  p_business_date_in IN VARCHAR2,
								  p_business_time_in IN VARCHAR2,
								  p_card_no_in       IN VARCHAR2,
								  p_mbr_numb_in      IN VARCHAR2,
								  p_curr_code_in     IN VARCHAR2,
								  p_merchant_name    IN VARCHAR2,
								  p_merchant_city    IN VARCHAR2,
								  p_resp_cde_out     OUT VARCHAR2,
								  p_resp_msg_out     OUT VARCHAR2,
								  p_dda_number_out   OUT VARCHAR2);

  PROCEDURE concurrent_txncheck(p_inst_code_in        IN VARCHAR2,
						  p_new_card_in         IN VARCHAR2,
						  p_old_card_in         IN VARCHAR2,
						  p_txn_code_in         IN VARCHAR2,
						  p_delivery_channel_in IN VARCHAR2,
						  p_msgtype_in          IN VARCHAR2,
						  p_busdate_in          IN VARCHAR2,
						  p_exist_count_out     OUT NUMBER);

  PROCEDURE current_txnlog(p_inst_code_in        IN VARCHAR2,
					  p_new_card_in         IN VARCHAR2,
					  p_old_card_in         IN VARCHAR2,
					  p_txn_code_in         IN VARCHAR2,
					  p_delivery_channel_in IN VARCHAR2,
					  p_msgtype_in          IN VARCHAR2,
					  p_busdate_in          IN VARCHAR2);

  PROCEDURE current_txnlogclear(p_inst_code_in IN NUMBER,
						  p_new_card_in  IN VARCHAR2,
						  p_old_card_in  IN VARCHAR2);

END vms_dfc_visa_to_master_migr;
/
show error