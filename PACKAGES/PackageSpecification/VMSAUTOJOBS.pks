CREATE OR REPLACE PACKAGE VMSCMS.vmsautojobs
IS
   -- Author  : Pankaj S.
   -- Created : 01/03/2016
   -- Purpose : Auto DB job's in VMS
   --                  1.Automatic closure of account with balance write-off job
   --                  2.Automatic credit of reward job
   --                  3.Automatic sweep acct  job   
   --                  4.Automatic card replacement job
   
   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public functions and procedures declarations
   --closure of account with balance write-off job
   PROCEDURE card_auto_closure;
   
   --sweep acct  job
   PROCEDURE sweep_acct_job;
   
   --card replacement job
   PROCEDURE card_replacement_job(p_rec_count       OUT NUMBER);

  --credit of reward job
   PROCEDURE rewards_auto_credit (p_src_dir_in    IN VARCHAR2,
                                  p_dest_dir_in   IN VARCHAR2,
                                  p_rej_dir_in   IN VARCHAR2);

   PROCEDURE get_AutoReward_filelist (p_directory_in IN VARCHAR2);

   PROCEDURE load_reward_file (p_directory_in   IN     VARCHAR2,
                               p_filename_in    IN     VARCHAR2,
                               p_batch_id_in    IN     VARCHAR2,
                               p_resp_msg_out      OUT VARCHAR2);

   PROCEDURE acct_bal_adjustment (p_instcode_in           NUMBER,
                                  p_rrn_in                VARCHAR2,
                                  p_cardno_in             VARCHAR2,
                                  p_cardno_encr_in        VARCHAR2,
                                  p_acctno_in             VARCHAR2,
                                  p_prodcode_in           VARCHAR2,
                                  p_cardtype_in           NUMBER,
                                  p_cardstat_in           VARCHAR2,
                                  p_txnamt_in             NUMBER,
                                  p_txntype_in            VARCHAR2,
                                  p_rsn_code_in           NUMBER,
                                  p_txnnarration_in       VARCHAR2,
                                  p_remark_in             VARCHAR2,
                                  p_resp_msg_out      OUT VARCHAR2,
                                  p_bal_impctflag_in      VARCHAR2 DEFAULT 'B',  
                                  p_batchid_in              VARCHAR2 DEFAULT NULL,
                                  p_txncode_in              VARCHAR2 DEFAULT NULL);
	
	--sweep acct job Year End
   PROCEDURE sweep_acct_job_yearend;
END vmsautojobs;
/
SHOW ERROR