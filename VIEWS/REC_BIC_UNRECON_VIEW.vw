/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.rec_bic_unrecon_view (rec_type,
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
   SELECT DECODE (rbu_rec_typ, '01', 'ATM', '02', 'POS') rec_type,
          rbu_tran_dat tran_date, rbu_tran_tim tran_time,
          rbu_process_date process_date, rbu_from_acct account_no,
          TRIM (rbu_seq_num) ref_no, rbu_tran_typ mesg_type,
          TO_NUMBER (TRIM (rbu_amt1)) / 100 amount1,
          TO_NUMBER (TRIM (rbu_amt2)) / 100 amount2,
          TRIM (rbu_term_id) term_id, rbu_file_name file_name,
          TRIM (rbu_orig_crncy_cde) currency_code,
          rbu_acq_inst_id_num acq_inst_id_num,
             TRIM (rbu_tran_cde)
          || rbu_from_acct_typ
          || rbu_to_acct_typ process_code,
          rbu_pan pan, 'UnReconciled' recon_flag
     FROM rec_bic_unrecon
    WHERE rbu_recon_flag = 0;


