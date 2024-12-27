ALTER TABLE vmscms.GPR_VALID_CARDSTAT ADD(gvc_validcrdstat_seq NUMBER);

UPDATE vmscms.GPR_VALID_CARDSTAT
   SET gvc_validcrdstat_seq = vmscms.seq_valid_cardstat.NEXTVAL;
   
   
ALTER TABLE vmscms.GPR_VALID_CARDSTAT ADD (
  CONSTRAINT pk_valid_cardstat
  PRIMARY KEY
  (gvc_validcrdstat_seq));