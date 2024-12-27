CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Acct_Pcms( instcode   IN NUMBER ,
            acctno  IN VARCHAR2 ,
            holdcount  IN NUMBER ,
            currbran  IN VARCHAR2 ,
            billaddr  IN NUMBER ,
            accttype  IN NUMBER ,
            acctstat  IN NUMBER ,
            lupduser  IN NUMBER ,
            prm_prod_code  IN VARCHAR2,
            prm_card_type   IN  NUMBER,
            prm_dup_flag  OUT VARCHAR2,
            acctid  OUT  NUMBER ,
            errmsg  OUT VARCHAR2)

AS
v_acctno CMS_ACCT_MAST.cam_acct_no%type;
uniq_excp_acctno  EXCEPTION  ;
PRAGMA EXCEPTION_INIT(uniq_excp_acctno,-00001);

BEGIN  --Main Begin Block Starts Here
--this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
--IF instcode IS NOT NULL  AND acctno IS NOT NULL AND holdcount IS NOT NULL AND currbran IS NOT NULL AND accttype IS NOT NULL AND acctstat IS NOT NULL AND lupduser IS NOT NULL THEN
--IF 1(this is a comment)
--dbms_output.put_line('ckpt1');
 /*SELECT seq_acct_id.NEXTVAL
 INTO acctid
 FROM  dual;*/
 
 
 --Sn get acct number
       BEGIN
            SELECT seq_acct_id.NEXTVAL
              INTO acctid
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               errmsg :=
                  'Error while selecting acctnum '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE uniq_excp_acctno;
         END;

            --En get acct number
          IF acctno IS NULL THEN 
             v_acctno := trim(acctid);
         ELSIF acctno IS NOT NULL THEN
             v_acctno := trim(acctno);
         END IF;

 INSERT INTO CMS_ACCT_MAST(CAM_INST_CODE ,
                   CAM_ACCT_ID  ,
        CAM_ACCT_NO  ,
        CAM_HOLD_COUNT ,
        CAM_CURR_BRAN ,
        CAM_BILL_ADDR  ,
        CAM_TYPE_CODE ,
        CAM_STAT_CODE ,
        CAM_INS_USER  ,
        CAM_LUPD_USER,
        cam_prod_code,
        cam_card_type 
         )
        VALUES(instcode   ,
      acctid   ,
      trim(v_acctno) ,
      holdcount   ,
      currbran   ,
      billaddr   ,
      accttype   ,
      acctstat   ,
      lupduser   ,
      lupduser,
      prm_prod_code,
      prm_card_type
      );
      prm_dup_flag := 'A';
errmsg := 'OK';
--ELSE --IF 1
--dbms_output.put_line('ckpt2');
--errmsg := 'sp_create_acct expected a not null parameter';
--END IF; --IF 1

EXCEPTION --Main block Exception
WHEN uniq_excp_acctno THEN
errmsg := 'Account No already in Master.';
/*
SELECT cam_acct_id
INTO acctid
FROM CMS_ACCT_MAST
WHERE cam_inst_code  = instcode
AND cam_acct_no  = trim(acctno) ; */
prm_dup_flag  := 'D';

WHEN OTHERS THEN
errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/
show error