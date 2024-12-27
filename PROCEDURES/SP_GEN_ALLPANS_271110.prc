CREATE OR REPLACE PROCEDURE VMSCMS.SP_GEN_ALLPANS_271110 (
prm_instcode IN NUMBER ,
prm_lupduser IN NUMBER ,
prm_totcnt OUT NUMBER,
prm_succnt  OUT NUMBER,
prm_errcnt  OUT NUMBER,
prm_errmsg OUT VARCHAR2)
AS
CURSOR c1 IS
SELECT cam_appl_code FROM CMS_APPL_MAST
WHERE cam_appl_stat = 'A' --and rownum < 2
ORDER BY cam_appl_code; --Added by Abhijit On 11/11/2004
v_panout     VARCHAR2(20);
v_cnt      NUMBER(10) := 0;
v_appl_msg    VARCHAR2(500);
v_totcnt    NUMBER(10) default 0;
v_succnt    NUMBER(10) default 0;
v_errcnt    NUMBER(10) default 0;
BEGIN
prm_errmsg := 'OK';
--Sn get the total count
 BEGIN
 select count(1)
 into   v_totcnt
 from   CMS_APPL_MAST
 WHERE  cam_appl_stat = 'A';
 EXCEPTION
  WHEN others THEN
  prm_errmsg := 'Error while selecting records ' || substr(sqlerrm,1,200);
  RETURN;
 END;
--En get the total count
 FOR x IN c1
 LOOP
  IF prm_errmsg != 'OK' THEN
  dbms_output.put_line('Error message = '||prm_errmsg||'for appl = '||x.cam_appl_code||' and count = '||v_cnt);
  EXIT;
    END IF;
     Sp_Gen_Pan(prm_instcode,x.cam_appl_code,prm_lupduser,v_panout,v_appl_msg,prm_errmsg);
   IF prm_errmsg = 'OK' AND v_appl_msg = 'OK' THEN
   v_succnt := v_succnt + 1;
   dbms_output.put_line('success count '|| ' ' || v_succnt);
   END IF;
        v_cnt := v_cnt+1;
        Sp_Pancount(v_cnt);
 END LOOP;
 IF prm_errmsg = 'OK' THEN
 v_errcnt := v_totcnt - v_succnt;
 ELSE
   v_succnt := 0;
  v_errcnt := 0;
 END IF;
   prm_totcnt  := v_totcnt;
  prm_succnt  := v_succnt;
  prm_errcnt  := v_errcnt;
 EXCEPTION
 WHEN OTHERS THEN
 prm_errmsg :=  'Error from main ' || substr(sqlerrm,1,200);
 END;
/


