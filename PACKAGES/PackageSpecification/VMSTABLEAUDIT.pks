create or replace
PACKAGE        vmscms.vmstableaudit
IS
   -- Author  : Pankaj S.
   -- Created : 25/01/2016
   -- Purpose : Audit on VMS table columns

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE generate_audit_trg (p_grp_id_in          NUMBER,
                                 p_audt_flag          VARCHAR2,
                                 p_resp_msg_out   OUT VARCHAR2);
END vmstableaudit;
/
show error