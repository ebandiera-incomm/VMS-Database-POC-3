CREATE OR REPLACE PACKAGE vmscms.vmsredemptiondelay
AS
   -- Purpose : redemption delay functionality

   -- Public variable declarations

   -- Public function and procedure declarations
   FUNCTION check_overlaps (p_existing_time_in    VARCHAR2,
                            p_new_time_in         VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE redemption_delay (
      p_acct_no_in                VARCHAR2,
      p_rrn_in                    VARCHAR2,
      p_delivery_channel_in       VARCHAR2,
      p_txn_code_in               VARCHAR2,
      p_txn_amt_in                NUMBER,
      p_prod_code_in              VARCHAR2,
      p_card_typ_in               NUMBER,
      p_merchant_in               VARCHAR2,
      p_merchantZipCode_in           varchar2,
      p_process_msg_out           OUT VARCHAR2,
      p_revsl_flag_in             VARCHAR2 DEFAULT 'N',
      P_MERCHANT_ID_IN            VARCHAR2 default null);

   PROCEDURE check_delayed_load (p_acct_no_in            VARCHAR2,
                               p_delayed_amt_out   OUT NUMBER,
                               p_process_msg_out   OUT VARCHAR2);
END vmsredemptiondelay;
/

SHOW ERROR