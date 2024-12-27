create or replace
PACKAGE vmscms.VMSPARTNER IS

   -- Author  : SSUBRAMANIAN
   -- Created : 4/16/2015 12:55:12 PM
   -- Purpose : Provides functionality for managing FS partners accessing VMS

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   FUNCTION validate
   (
      p_partner_id_in  IN VARCHAR2,
      p_customer_id_in IN VARCHAR2
   ) RETURN VARCHAR2;
   
   
     PROCEDURE attach_detach_prid_grid(      p_partner_id_in in varchar2,
                                             p_added_group_ids_in IN VARCHAR2,
                                             p_delete_group_ids_in in varchar2,
                                             p_user_in in number,
                                             p_resp_msg_out out VARCHAR2);
END VMSPARTNER;
/
show error