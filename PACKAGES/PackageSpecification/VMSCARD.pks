create or replace 
PACKAGE               VMSCMS.VMSCARD
IS
   -- Created : 11/21/2016  17:40:00
   -- Purpose : Card Generation related processes

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE transfer_pan_data (p_file_name_in       VARCHAR2,
                                p_resp_msg_out   OUT VARCHAR2);

   PROCEDURE get_card_no (p_prod_code_in   IN     VARCHAR2,
                          p_prod_catg_in   IN     NUMBER,
                          p_card_no_out       OUT VARCHAR2,
                          p_resp_msg_out      OUT VARCHAR2);

   PROCEDURE process_card_order (p_prod_code_in   IN     VARCHAR2,
                                p_prod_catg_in   IN     NUMBER,
                                p_card_stat_in   IN     VARCHAR2,
                                p_disp_name_in   IN     VARCHAR2,
                                p_stock_cnt_in   IN     NUMBER,
                                p_user_code_in   IN     NUMBER,
                                p_resp_msg_out      OUT VARCHAR2);

   PROCEDURE get_ranges (p_start_bin_in      IN     VARCHAR2,
                         p_end_bin_in        IN     VARCHAR2,
                         p_start_range_in    IN     VARCHAR2,
                         p_end_range_in      IN     VARCHAR2,
                         p_ranges_dtls_out      OUT SYS_REFCURSOR);

   PROCEDURE inventory_job;

   PROCEDURE generate_inventory (p_inst_code_in     IN     NUMBER,
                                 p_user_code_in     IN     NUMBER,
                                 p_prod_code_in     IN     VARCHAR2,
                                 p_prod_catg_in     IN     NUMBER);

   PROCEDURE generate_cards (
      p_inst_code_in     IN     NUMBER,
      p_user_code_in     IN     NUMBER,
      p_prod_code_in     IN     VARCHAR2,
      p_prod_catg_in     IN     NUMBER,
      p_prod_prefix_in   IN     VARCHAR2,
      p_card_range_id	IN	   NUMBER,
      p_bin				IN	   NUMBER,
      p_stock_cnt_in     IN     NUMBER,
	  p_card_cnt_out     OUT     NUMBER,
      p_err_msg_out         OUT VARCHAR2);
PROCEDURE log_consumed_status_change(
    p_inst_code_in       IN NUMBER,
    p_card_number_in   IN VARCHAR2,
    p_tran_date_in       IN VARCHAR2,
    p_tran_time_in       IN VARCHAR2,
    p_updted_cardstat_in IN VARCHAR2,
	p_delivery_channel in varchar2,
    p_updated_count OUT NUMBER
	);

    PROCEDURE get_pan_srno (p_inst_code_in      IN     NUMBER,
                           p_prod_code_in      IN     VARCHAR2,
                           p_prod_catg_in      IN     NUMBER,
                           p_prod_prefix_in    IN     VARCHAR2,
                           p_prod_sufix_in     IN     VARCHAR2,
                           p_start_range_in    IN     VARCHAR2,
                           p_end_range_in      IN     VARCHAR2,
                           p_serl_flag         IN     NUMBER,
                           p_prod_prefix_out      OUT VARCHAR2,
                           p_serial_no_out        OUT VARCHAR2,
                           p_err_msg_out          OUT VARCHAR2);
						   
	
	--SN : Added for VMS-7147
	PROCEDURE get_shuffle_serials (	p_minval_in              NUMBER,
									p_maxval_in              NUMBER,
									p_shufflearray_out   OUT shuffle_array_typ);		   
	--EN : Added for VMS-7147

   PROCEDURE generate_serial_numbers (p_inst_code_in     IN     NUMBER,
                                      p_prod_code_in     IN     VARCHAR2,
                                      p_prod_catg_in     IN     NUMBER,
                                      p_prod_prefix_in   IN     VARCHAR2,
                                      p_serl_flag        IN     NUMBER,
                                      p_minval_in        IN     NUMBER,
                                      p_maxval_in        IN     NUMBER,
                                      p_first_time_flag  IN     VARCHAR2,
                                      p_starter_flag  IN     VARCHAR2,
                                      p_errmsg_out       OUT    VARCHAR2);
    
    --SN : Added for VMS-6652 changes
    PROCEDURE get_pan_srno (p_inst_code_in     IN  NUMBER,
                            p_prod_code_in     IN  VARCHAR2,
                            p_prod_catg_in     IN  NUMBER,
                            p_strtrcrd_flag_in IN  VARCHAR2,
                            p_serl_flag        IN  NUMBER,
							p_bin_out          OUT NUMBER,
                            p_prod_prefix_out  OUT VARCHAR2,
                            p_serial_no_out    OUT VARCHAR2,
                            p_err_msg_out      OUT VARCHAR2);   
   --EN : Added for VMS-6652 changes
   
   FUNCTION GENERATE_SERIALS (P_MIN_VALUE INTEGER, P_MAX_VALUE INTEGER)
    RETURN SERIAL_ARRAY_TYP
    PIPELINED
    DETERMINISTIC;

END;

/
show error;