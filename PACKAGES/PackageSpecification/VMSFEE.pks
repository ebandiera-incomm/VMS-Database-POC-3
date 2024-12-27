CREATE OR REPLACE PACKAGE vmscms.vmsfee
IS
   -- Author  : Pankaj S.
   -- Created : 11/07/2016
   -- Purpose : VMS OTC Support for Instant Payroll Card
   -- Reviewer: Sarvanan
   -- Build No: VMSGPRHOST4.11

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE fee_freecnt_check (p_acctno_in                VARCHAR2,
                                p_feecode_in               NUMBER,
                                p_freecnt_freq_in          VARCHAR2,
                                p_confgcnt_in              NUMBER,
                                p_freefreq_change_in       DATE,
                                p_free_txn_out         OUT VARCHAR2,
                                p_resp_out             OUT VARCHAR2);

   PROCEDURE fee_freecnt_reset (p_acctno_in             VARCHAR2,
                                p_feecode_in            NUMBER,
                                p_freecnt_freq_in       VARCHAR2,
                                p_reset_flag_in         VARCHAR2,
                                p_resp_out          OUT VARCHAR2);

   PROCEDURE fee_freecnt_reverse (p_acctno_in        VARCHAR2,
                                  p_feecode_in       VARCHAR2,
                                  p_resp_out     OUT VARCHAR2);
END vmsfee;
/
SHOW ERROR