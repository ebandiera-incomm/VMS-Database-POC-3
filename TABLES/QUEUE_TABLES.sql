--grant roles to VMSCMS
GRANT aq_administrator_role TO vmscms; 
GRANT create type TO vmscms; 
GRANT EXECUTE ON dbms_aqadm TO VMSCMS;
GRANT EXECUTE ON dbms_aq TO VMSCMS;
GRANT EXECUTE ON dbms_aqin TO VMSCMS;


CREATE TYPE vmscms.ach_type AS OBJECT(
       transaction_id           VARCHAR2 (20),
       business_date            VARCHAR2 (8),
       business_time            VARCHAR2 (10),
       txn_code                 VARCHAR2 (2),
       delivery_chnl            VARCHAR2 (2),
       trans_desc               VARCHAR2 (50),
       card_no                  VARCHAR2 (90),
       card_no_encr             RAW (100),
       card_stat                VARCHAR2 (3),
       amount                   NUMBER (9, 2),
       Fee_amount               NUMBER (9, 2),
       date_time                DATE,
       ach_filename             VARCHAR2 (40),
       return_achfilename       VARCHAR2 (40),
       achactiontaken           CHAR (1),
       auth_id                  VARCHAR2 (14),
       indname                  VARCHAR2 (25),
       acct_balance             NUMBER (20, 2),
       ledger_balance           NUMBER (20, 2),
       response_id              VARCHAR2 (7),
       response_code            VARCHAR2 (7),
       merchant_name            VARCHAR2 (100)); 
/	   
                                   
                                   
BEGIN
   DBMS_AQADM.create_queue_table
                                (queue_table                   => 'vmscms.ach_qt',
                                 queue_payload_type      => 'vmscms.ach_type'
                                );
END;
/


BEGIN
  DBMS_AQADM.create_queue (queue_name         => 'vmscms.ach_excp_queue',
                                                        queue_table          => 'vmscms.ach_qt',
                                                       queue_type => DBMS_AQADM.normal_queue,
                                                       max_retries          => 0,
                                                       retry_delay           => 0,
                                                       retention_time      => 0,
                                                      dependency_tracking      => FALSE,
                                                      COMMENT          => 'ACH non-federal excp Queue',
                                                      auto_commit         => FALSE );
END;
/

BEGIN
  DBMS_AQADM.create_queue (queue_name         => 'vmscms.ach_fedexcp_queue',
                                                        queue_table          => 'vmscms.ach_qt',
                                                       queue_type => DBMS_AQADM.normal_queue,
                                                       max_retries          => 0,
                                                       retry_delay           => 0,
                                                       retention_time      => 0,
                                                      dependency_tracking      => FALSE,
                                                      COMMENT          => 'ACH federal excp Queue',
                                                      auto_commit         => FALSE );
END;
/


BEGIN
  DBMS_AQADM.create_queue (queue_name         => 'vmscms.ach_achview_queue',
                                                        queue_table          => 'vmscms.ach_qt',
                                                       queue_type => DBMS_AQADM.normal_queue,
                                                       max_retries          => 0,
                                                       retry_delay           => 0,
                                                       retention_time      => 0,
                                                      dependency_tracking      => FALSE,
                                                      COMMENT          => 'ACH view Queue',
                                                      auto_commit         => FALSE );
END;
/

BEGIN
  DBMS_AQADM.create_queue (queue_name         => 'vmscms.ach_reversal_queue',
                                                        queue_table          => 'vmscms.ach_qt',
                                                       queue_type => DBMS_AQADM.normal_queue,
                                                       max_retries          => 0,
                                                       retry_delay           => 0,
                                                       retention_time      => 0,
                                                      dependency_tracking      => FALSE,
                                                      COMMENT          => 'ACH reversal txn Queue',
                                                      auto_commit         => FALSE );
END;
/
BEGIN
  DBMS_AQADM.start_queue ('vmscms.ach_excp_queue');
  DBMS_AQADM.start_queue ('vmscms.ach_fedexcp_queue');
  DBMS_AQADM.start_queue ('vmscms.ach_achview_queue');
  DBMS_AQADM.start_queue ('vmscms.ach_reversal_queue');
END;
/

