CREATE TABLE vmscms.VMS_PIN_CHECK
(
   vpc_inst_code       NUMBER(5),
   vpc_pan_code        VARCHAR2 (90 BYTE),
   vpc_pan_code_encr   RAW (100),
   vpc_pin_count       NUMBER(5),
   vpc_txn_date        DATE,
   vpc_ins_date        DATE,
   vpc_lupd_date       DATE
);

ALTER TABLE VMSCMS.VMS_PIN_CHECK ADD (
  CONSTRAINT pk_vpc_pan_code
  PRIMARY KEY
  (vpc_pan_code));