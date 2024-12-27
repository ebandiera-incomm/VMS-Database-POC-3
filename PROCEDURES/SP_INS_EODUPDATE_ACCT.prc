CREATE OR REPLACE PROCEDURE vmscms.sp_ins_eodupdate_acct (
   prm_rrn                      VARCHAR2,
   prm_terminal_id              VARCHAR2,
   prm_delivery_channel         VARCHAR2,
   prm_txn_code                 VARCHAR2,
   prm_txn_mode                 VARCHAR2,
   prm_tran_date                DATE,
   prm_card_no                  VARCHAR2,
   prm_upd_acctno               VARCHAR2,
   prm_upd_amount               NUMBER,
   prm_upd_flag                 VARCHAR2,
   prm_inst_code                NUMBER,
   prm_err_msg            OUT   VARCHAR2
)
IS
   v_hash_pan   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan   cms_appl_pan.cap_pan_code_encr%TYPE;
BEGIN
   prm_err_msg := 'OK';
END;
/

SHOW ERROR