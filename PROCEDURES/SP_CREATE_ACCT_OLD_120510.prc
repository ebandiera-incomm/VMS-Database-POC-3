CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_acct_old_120510( instcode   IN NUMBER ,
            acctno  IN VARCHAR2 ,
            holdcount  IN NUMBER ,
            currbran  IN VARCHAR2 ,
            billaddr  IN NUMBER ,
            accttype  IN NUMBER ,
            acctstat  IN NUMBER ,
            lupduser  IN NUMBER ,
            acctid  OUT  NUMBER ,
            errmsg  OUT VARCHAR2)

AS
uniq_excp_acctno  EXCEPTION  ;
PRAGMA EXCEPTION_INIT(uniq_excp_acctno,-00001);

BEGIN  --Main Begin Block Starts Here
--this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
--IF instcode IS NOT NULL  AND acctno IS NOT NULL AND holdcount IS NOT NULL AND currbran IS NOT NULL AND accttype IS NOT NULL AND acctstat IS NOT NULL AND lupduser IS NOT NULL THEN
--IF 1(this is a comment)
--dbms_output.put_line('ckpt1');
 SELECT seq_acct_id.NEXTVAL
 INTO acctid
 FROM  dual;
 INSERT INTO CMS_ACCT_MAST(CAM_INST_CODE ,
                   CAM_ACCT_ID  ,
        CAM_ACCT_NO  ,
        CAM_HOLD_COUNT ,
        CAM_CURR_BRAN ,
        CAM_BILL_ADDR  ,
        CAM_TYPE_CODE ,
        CAM_STAT_CODE ,
        CAM_INS_USER  ,
        CAM_LUPD_USER )
        VALUES(instcode   ,
      acctid   ,
      trim(acctno) ,
      holdcount   ,
      currbran   ,
      billaddr   ,
      accttype   ,
      acctstat   ,
      lupduser   ,
      lupduser);
errmsg := 'OK';
--ELSE --IF 1
--dbms_output.put_line('ckpt2');
--errmsg := 'sp_create_acct expected a not null parameter';
--END IF; --IF 1

EXCEPTION --Main block Exception
WHEN uniq_excp_acctno THEN
errmsg := 'Account No already in Master.';
SELECT cam_acct_id
INTO acctid
FROM CMS_ACCT_MAST
WHERE cam_inst_code  = instcode
AND cam_acct_no  = trim(acctno) ;
WHEN OTHERS THEN
errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/


