/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.rec_bic_recon_view (rec_type,
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
   SELECT DECODE (rbr_rec_typ, '01', 'ATM', '02', 'POS') rec_type,
          rbr_tran_dat tran_date, rbr_tran_tim tran_time,
          rbr_process_date process_date, rbr_from_acct account_no,
          TRIM (rbr_seq_num) ref_no, rbr_tran_typ mesg_type,
          TO_NUMBER (TRIM (rbr_amt1)) / 100 amount1,
          TO_NUMBER (TRIM (rbr_amt2)) / 100 amount2,
          TRIM (rbr_term_id) term_id, rbr_file_name file_name,
          TRIM (rbr_orig_crncy_cde) currency_code,
          rbr_acq_inst_id_num acq_inst_id_num,
             TRIM (rbr_tran_cde)
          || rbr_from_acct_typ
          || rbr_to_acct_typ process_code,
          rbr_pan pan, 'Reconciled' recon_flag
     FROM rec_bic_recon;


