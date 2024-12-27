/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.rec_bicpart_unrecon_view (rec_type,
                                                              tran_date,
                                                              tran_time,
                                                              process_date,
                                                              account_no,
                                                              ref_no,
                                                              mesg_type,
                                                              amount1,
                                                              amount2,
                                                              term_id,
                                                              file_name,
                                                              currency_code,
                                                              acq_inst_id_num,
                                                              process_code,
                                                              pan,
                                                              recon_flag
                                                             )
AS
   SELECT DECODE (rpu_rec_typ, '01', 'ATM', '02', 'POS') rec_type,
          rpu_tran_dat tran_date, rpu_tran_tim tran_time,
          rpu_process_date process_date, rpu_from_acct account_no,
          TRIM (rpu_seq_num) ref_no, rpu_tran_typ mesg_type,
          TO_NUMBER (TRIM (rpu_amt1)) / 100 amount1,
          TO_NUMBER (TRIM (rpu_amt2)) / 100 amount2,
          TRIM (rpu_term_id) term_id, rpu_file_name file_name,
          TRIM (rpu_orig_crncy_cde) currency_code,
          rpu_acq_inst_id_num acq_inst_id_num,
             TRIM (rpu_tran_cde)
          || rpu_from_acct_typ
          || rpu_to_acct_typ process_code,
          rpu_pan pan, 'UnReconciled' recon_flag
     FROM rec_bicpart_unrecon
    WHERE rpu_recon_flag = 0;


