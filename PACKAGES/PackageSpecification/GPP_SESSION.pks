  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_SESSION" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin
   -- Created : 8/17/2015 1:29:36 PM
   -- Purpose : New package for GPP to address session specific requirements

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations

   --To start a session
   PROCEDURE start_session
   (
      p_customer_id_in     IN VARCHAR2,
      p_session_type_in    IN VARCHAR2,
      p_session_ref_num_in IN VARCHAR2,
      p_session_id_out     OUT VARCHAR2,
      p_status_out         OUT VARCHAR2,
      p_err_msg_out        OUT VARCHAR2
   );

   --To end a session
   -- Call log id is really not required as an explicit input (obtain from x-incfs-sessionid
   -- Type is always going to be 'session'
   -- Call status is always going to be 'CLOSED'
   PROCEDURE end_session
   (
      p_customer_id_in IN VARCHAR2,
      p_comment_in     IN VARCHAR2,
      p_status_out     OUT VARCHAR2,
      p_err_msg_out    OUT VARCHAR2
   );

END gpp_session;