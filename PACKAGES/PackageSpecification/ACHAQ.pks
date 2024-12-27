CREATE OR REPLACE PACKAGE VMSCMS.achaq
IS
   -- Author  : Pankaj S.
   -- Created : 10/04/2016 11:00:00 AM
   -- Purpose : ACH advanced view

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE enqueue_ach_msgs (p_msg_in            VMSCMS_NONEBR.ach_type,
                               p_queue_in          VARCHAR2,
                               p_respmsg_out   OUT VARCHAR2);

   PROCEDURE dequeue_ach_msgs (p_msgid_in             VARCHAR2,
                               p_srcqueue_in          VARCHAR2,
                               p_deqeuemode_in        NUMBER,
                               p_destqueue_in         VARCHAR2,
                               p_actiontaken_in       VARCHAR2,
                               --p_msg_out            OUT NOCOPY ach_type,
                               p_respmsg_out      OUT VARCHAR2);

   PROCEDURE purge_queue (p_queue_tbl_in       VARCHAR2,
                          p_queue_in           VARCHAR2,
                          p_respmsg_out    OUT VARCHAR2);
END;
/

SHOW ERROR
