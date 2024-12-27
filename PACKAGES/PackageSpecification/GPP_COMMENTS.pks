  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_COMMENTS" AUTHID CURRENT_USER IS

   -- Author  : Rojalin Beura
   -- Created : 12-08-2015 12:13:10
   -- Purpose : New package for GPP

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   --Get comments
   PROCEDURE get_comments
   (
      p_customer_id_in  IN VARCHAR2,
      p_comment_type_in IN VARCHAR2 DEFAULT 'ALL',
      p_status_out      OUT VARCHAR2,
      p_err_msg_out     OUT VARCHAR2,
      c_comments_out    OUT SYS_REFCURSOR
   );

END gpp_comments;