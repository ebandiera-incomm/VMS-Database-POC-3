CREATE OR REPLACE PROCEDURE VMSCMS.SP_PBF_TIP_CTRL(instcode    IN     NUMBER,
                                                   p_filename IN VARCHAR2,
                                            p_userpin IN NUMBER,
                                            p_errmsg OUT VARCHAR2)
IS
v_count NUMBER(6);
CURSOR c1 IS
SELECT CAP_PAN_CODE,CAP_PBF_FNAME,CAP_PBFGEN_DATE,CAP_PBFGEN_USER FROM CMS_APPL_PAN WHERE CAP_PBFGEN_FLAG='T';
BEGIN
 p_errmsg:='OK';
 v_count := 0;
 FOR i IN c1
 LOOP
Begin
 Insert into CMS_PBFTIP_HIST (CPH_INST_CODE,CPH_PAN_CODE,CPH_OLD_PBF_FNAME,CPH_OLD_PBFGEN_DATE,CPH_OLD_PBFGEN_USER,CPH_TIPGEN_CNT,CPH_NEW_PBF_FNAME,CPH_NEW_PBFGEN_DATE,CPH_NEW_PBFGEN_USER,CPH_INS_USER,CPH_INS_DATE) values(instcode,i.CAP_PAN_CODE,i.CAP_PBF_FNAME,i.CAP_PBFGEN_DATE,i.CAP_PBFGEN_USER,(SELECT NVL(MAX(CPH_REGEN_CNT),0)+1 FROM CMS_PINREGEN_HIST WHERE CPH_PAN_CODE =i.CAP_PAN_CODE),p_filename,sysdate,p_userpin,p_userpin,sysdate);
v_count :=v_count +1;
EXCEPTION
WHEN OTHERS THEN
	  p_errmsg := 'Error while insert records into CMS_PBFTIP_HIST ' || SUBSTR(SQLERRM,1,200);
 End;
 END LOOP;

Begin
Update cms_appl_pan set CAP_PBF_FNAME=p_filename,CAP_PBFGEN_DATE=sysdate,CAP_PBFGEN_USER=p_userpin,CAP_PBFGEN_FLAG='Y' WHERE CAP_PBFGEN_FLAG='T';
EXCEPTION
WHEN OTHERS THEN
	  p_errmsg := 'Error while update records in the cms_appl_pan table ' || SUBSTR(SQLERRM,1,200);
End;

Begin
Insert into cms_pbftip_ctrl(CPC_INST_CODE,CPC_PBFGEN_DATE,CPC_PBF_FNAME,CPC_TOT_REC,CPC_INS_USER,CPC_INS_DATE) values(instcode,sysdate,p_filename,v_count,p_userpin,sysdate);
EXCEPTION
WHEN OTHERS THEN
	  p_errmsg := 'Error while insert records into the cms_pbftip_ctrl table ' || SUBSTR(SQLERRM,1,200);
End;

EXCEPTION
	 WHEN OTHERS THEN
	p_errmsg := 'Main Excp -- '||SQLERRM;
END;
/


