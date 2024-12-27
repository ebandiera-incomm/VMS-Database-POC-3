CREATE OR REPLACE PROCEDURE VMSCMS.SP_GRP_TOPUP (
	 instcode    IN NUMBER,
	 filename IN VARCHAR2 ,
     lupduser  IN NUMBER,
	 PROID OUT NUMBER ,
     errmsg    OUT VARCHAR2
 )
AS

v_count NUMBER(1);
v_remark  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_spprtrsn CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;

CURSOR c1 IS
SELECT CGT_ACCT_NO ,cgt_topup_amt ,CGT_REMARKS, ROWID
FROM CMS_GROUP_TOPUP;
BEGIN

 errmsg := 'OK';
 v_remark := 'Group TopUp';


 SELECT seq_fee_proid.NEXTVAL INTO proid FROM dual;
            --dbms_output.put_line ('B4 Loop 1');
  FOR x IN c1
  LOOP
          SAVEPOINT HTLST_SVPT ;
    BEGIN

      SELECT COUNT(1)
      INTO
      v_count
      FROM CMS_ACCT_MAST
      WHERE
      CAM_ACCT_NO = x.CGT_ACCT_NO ;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
         ERRMSG := 'No Such Card Found :'||x.CGT_ACCT_NO ;
      ROLLBACK TO HTLST_SVPT ;
      UPDATE CMS_GROUP_HOTLIST SET CGH_PIN_HOTLIST = 'E' WHERE ROWID = X.ROWID;
      sp_log_error(x.CGT_ACCT_NO, NULL, errmsg, lupduser,proid);
    WHEN OTHERS THEN
       ERRMSG :='While getting Acct No '||SQLERRM ;
        ROLLBACK TO HTLST_SVPT ;
        UPDATE CMS_GROUP_HOTLIST SET CGH_PIN_HOTLIST = 'E' WHERE ROWID = X.ROWID;
        sp_log_error(x.CGT_ACCT_NO, NULL, errmsg, lupduser,proid);
                END ;
    IF errmsg = 'OK' THEN --to skip if error
    --Change Ends
           sp_hotlist_pan(instcode,x.cgt_acct_no,x.CGT_REMARKS,lupduser,errmsg);

          --dbms_output.put_line ('B5 Loop 2');
         IF ERRMSG = 'OK' THEN
            -- dbms_output.put_line ('B6 Loop 2');
             UPDATE CMS_GROUP_HOTLIST SET CGH_PIN_HOTLIST = 'Y' WHERE ROWID = X.ROWID;
             SP_LOG_SUCCESS(x.cgh_pan_code,v_cap_mbr_numb,'HTLSTU',proid,errmsg);
         ELSE
          ROLLBACK TO HTLST_SVPT ;
              -- dbms_output.put_line ('B7 Loop 2');

             UPDATE CMS_GROUP_HOTLIST SET CGH_PIN_HOTLIST = 'E' WHERE ROWID = X.ROWID;

            sp_log_error(x.cgh_pan_code, NULL, errmsg, lupduser,proid);
            ERRMSG := 'OK' ;
         END IF;
      ELSE
      ERRMSG := 'OK';
     END IF ; --to skip if error
  END LOOP;
 ERRMSG := 'OK';
-- dbms_output.put_line ('B4 Loop 1');
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
   sp_log_error(NULL, NULL, errmsg, lupduser,proid);
END;
/


