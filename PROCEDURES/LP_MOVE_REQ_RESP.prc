CREATE OR REPLACE PROCEDURE VMSCMS.lp_move_req_resp (
      req_mode     IN   VARCHAR2,
      req_rowid    IN   ROWID,
      resp_mode    IN   VARCHAR2,
      resp_rowid   IN    ROWID
   )
   AS
   BEGIN
      IF req_mode='M'   THEN
 INSERT INTO PCMS_REQ_HOST_ALL SELECT * FROM PCMS_REQ_HOST WHERE ROWID=req_rowid;
 DELETE FROM PCMS_REQ_HOST WHERE ROWID=req_rowid;
      ELSIF req_mode='C'   THEN
       INSERT INTO PCMS_REQ_HOST_ALL SELECT * FROM PCMS_REQ_HOST WHERE ROWID=req_rowid;
      END IF;
      IF resp_mode='M'   THEN
 INSERT INTO PCMS_RESP_HOST_ALL SELECT * FROM PCMS_RESP_HOST WHERE ROWID=resp_rowid;
 DELETE FROM PCMS_RESP_HOST WHERE ROWID=resp_rowid;
      ELSIF resp_mode='C'   THEN
       INSERT INTO PCMS_RESP_HOST_ALL SELECT * FROM PCMS_RESP_HOST WHERE ROWID=resp_rowid;
      END IF;
   END;
   -- End Local Procedure
/


