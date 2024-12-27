/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.rec_bic_recon_all_view (rec_type,
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
   SELECT DECODE (rba_rec_typ, '01', 'ATM', '02', 'POS') rec_type,
          rba_tran_dat tran_date, rba_tran_tim tran_time,
          rba_process_date process_date, rba_from_acct account_no,
          TRIM (rba_seq_num) ref_no, rba_tran_typ mesg_type,
          TO_NUMBER (TRIM (rba_amt1)) / 100 amount1,
          TO_NUMBER (TRIM (rba_amt2)) / 100 amount2,
          TRIM (rba_term_id) term_id, rba_file_name file_name,
          TRIM (rba_orig_crncy_cde) currency_code,
          rba_acq_inst_id_num acq_inst_id_num,
             TRIM (rba_tran_cde)
          || rba_from_acct_typ
          || rba_to_acct_typ process_code,
          rba_pan pan, 'Reconciled' recon_flag
     FROM rec_bic_recon_all;


