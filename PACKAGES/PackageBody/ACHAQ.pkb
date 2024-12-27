CREATE OR REPLACE PACKAGE BODY VMSCMS.achaq
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations

   PROCEDURE enqueue_ach_msgs (p_msg_in            VMSCMS_NONEBR.ach_type,
                               p_queue_in          VARCHAR2,
                               p_respmsg_out   OUT VARCHAR2)
   IS
      l_enqueue_optns   DBMS_AQ.ENQUEUE_OPTIONS_T;
      l_msg_props       DBMS_AQ.MESSAGE_PROPERTIES_T;
      l_msgid           RAW (16);
   BEGIN
      p_respmsg_out := 'OK';
      DBMS_AQ.enqueue (queue_name           => 'VMSCMS_NONEBR.' || p_queue_in,
                       enqueue_options      => l_enqueue_optns,
                       message_properties   => l_msg_props,
                       payload              => p_msg_in,
                       msgid                => l_msgid);
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_respmsg_out :='Problem while enqueue msg into queue-'|| SUBSTR (SQLERRM, 1, 300);
   END;

   PROCEDURE dequeue_ach_msgs (p_msgid_in             VARCHAR2,
                               p_srcqueue_in          VARCHAR2, --source queue name
                               p_deqeuemode_in        NUMBER, --0 : Remove mode, 1:Lock mode, 2:remove and equeue in destination queue
                               p_destqueue_in         VARCHAR2, --destionation queue name in case mode-2
                               p_actiontaken_in       VARCHAR2,
                               --p_msg_out            OUT NOCOPY ach_type,
                               p_respmsg_out      OUT VARCHAR2)
   IS
      l_dequeue_optns   DBMS_AQ.DEQUEUE_OPTIONS_T;
      l_msg_props       DBMS_AQ.MESSAGE_PROPERTIES_T;
      l_msg_handlr      RAW (16);
      l_msg             VMSCMS_NONEBR.ach_type;
      l_qname           VARCHAR2 (30);
      l_no_msgs         EXCEPTION;
      l_lock_rec        EXCEPTION;
      PRAGMA EXCEPTION_INIT (l_lock_rec, -00054);
      PRAGMA EXCEPTION_INIT (l_no_msgs, -25263);
   BEGIN
      p_respmsg_out := 'OK';

      IF p_deqeuemode_in = 1 THEN
         --         l_dequeue_optns.dequeue_mode := DBMS_AQ.locked;
         BEGIN
                SELECT q_name
                  INTO l_qname
                  FROM VMSCMS_NONEBR.ach_qt qt
                 WHERE msgid = p_msgid_in
            FOR UPDATE NOWAIT;

            RETURN;
         EXCEPTION
            WHEN l_lock_rec THEN
               p_respmsg_out := 'Record already in process..!';
               RETURN;
            WHEN OTHERS THEN
               p_respmsg_out :='Error while dequeue in lock mode :'|| SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END IF;

      l_dequeue_optns.wait := DBMS_AQ.no_wait;
      l_dequeue_optns.msgid := p_msgid_in;

      BEGIN
         DBMS_AQ.dequeue (queue_name           => 'VMSCMS_NONEBR.' || p_srcqueue_in,
                          dequeue_options      => l_dequeue_optns,
                          message_properties   => l_msg_props,
                          payload              => l_msg,
                          msgid                => l_msg_handlr);
      EXCEPTION
         WHEN l_no_msgs THEN
            p_respmsg_out := 'No msg found for msgid-' || p_msgid_in;
            RETURN;
         WHEN OTHERS THEN
            p_respmsg_out :='Error while dequeue :' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      IF p_deqeuemode_in = 2 THEN
         l_msg.achactiontaken := p_actiontaken_in;
         enqueue_ach_msgs (l_msg, p_destqueue_in, p_respmsg_out);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_respmsg_out := 'Main Excp-' || SQLERRM;
   END;

   PROCEDURE purge_queue (p_queue_tbl_in       VARCHAR2,
                          p_queue_in           VARCHAR2,
                          p_respmsg_out    OUT VARCHAR2)
   AS
      l_purge_optns   DBMS_AQADM.AQ$_PURGE_OPTIONS_T;
   BEGIN
      p_respmsg_out := 'OK';
      l_purge_optns.block := TRUE;
      DBMS_AQADM.purge_queue_table (
         p_queue_tbl_in,
         CASE
            WHEN TRIM (p_queue_in) IS NOT NULL
            THEN
               'queue=''' || p_queue_in || ''''
            ELSE
               NULL
         END,
         l_purge_optns);
   EXCEPTION
      WHEN OTHERS THEN
         p_respmsg_out := 'Main Excp-' || SQLERRM;
   END;
END;
/

SHOW ERROR