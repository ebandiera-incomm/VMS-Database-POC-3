  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_ALERTS" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : SINDHU
   -- Created : 12-08-2015 16:17:33
   -- Purpose : New package for GPP

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations
   g_alerts_row vmscms.cms_smsandemail_alert%ROWTYPE;
   -- Public function and procedure declarations
   --Get alerts
   PROCEDURE get_alerts
   (
      p_customer_id_in    IN VARCHAR2,
      p_status_out        OUT VARCHAR2,
      p_err_msg_out       OUT VARCHAR2,
      p_email_out         OUT VARCHAR2,
      p_phone_no_out      OUT VARCHAR2,
      p_mobile_status_out OUT VARCHAR2,
      c_alerts_out        OUT SYS_REFCURSOR
   );

   PROCEDURE update_alerts
   (
      p_customer_id_in IN VARCHAR2,
      p_email_in       IN VARCHAR2,
      p_phone_no_in    IN VARCHAR2,
      p_alerts_in      IN VARCHAR2,
      p_comment_in     IN VARCHAR2,
      --p_dummy_in       IN varchar2,
      p_status_out     OUT VARCHAR2,
      p_err_msg_out    OUT VARCHAR2,
	    p_optinflag_out  OUT VARCHAR2
   );

--PROCEDURE update_alerts_new
--   (
--      p_customer_id_in IN VARCHAR2,
--      p_email_in       IN VARCHAR2,
--      p_phone_no_in    IN VARCHAR2,
--      p_alerts_in      IN VARCHAR2,
--      p_comment_in     IN VARCHAR2,
--      p_status_out     OUT VARCHAR2,
--      p_err_msg_out    OUT VARCHAR2
--   );

  -- PROCEDURE test_get_alerts(p_customer_id_in IN VARCHAR2);

  -- PROCEDURE test;

END gpp_alerts;