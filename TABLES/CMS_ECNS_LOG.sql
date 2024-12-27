CREATE TABLE vmscms.cms_ecns_log
(
  cel_inst_code      NUMBER(5),
  cel_ecns_logid  VARCHAR2(20),
  cel_ecns_rrn            VARCHAR2(30 BYTE),
  cel_ecns_req        VARCHAR2(4000 BYTE),
  cel_ecns_res        VARCHAR2(4000 BYTE),
  cel_process_msg      VARCHAR2(500 BYTE),
  cel_ins_date       DATE,
  cel_lupd_date      DATE,
CONSTRAINT ecns_log_pk  PRIMARY KEY (cel_inst_code,cel_ecns_logid)
)tablespace cms_big_txn;
