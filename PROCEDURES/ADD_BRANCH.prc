CREATE OR REPLACE PROCEDURE VMSCMS.add_branch ( p_bran_code IN VARCHAR2,
      p_bran_fiid IN VARCHAR2,
      p_ctrl_numb IN VARCHAR2,
      errmsg OUT VARCHAR2  )
AS
 v_count NUMBER(4);
 v_CPC_CTRL_NUMB VARCHAR2(10);
BEGIN
 SELECT COUNT(1) INTO v_count
 FROM CMS_BRAN_MAST
 WHERE cbm_bran_code=p_bran_code
 AND cbm_bran_fiid=p_bran_fiid;    ---Checking in table for the row in cms_bran_mast

 IF v_count != 0 THEN
   errmsg:='The branch code or branch fiid is already in table ';
  END IF;
  BEGIN
    INSERT INTO CMS_BRAN_MAST
    VALUES( 100  , 200  ,  111  ,
      'p_bran_code' , 'p_bran_fiid' ,  'asdasd' ,
      'abhijit' , 'abhijit' , 'CBM_ADDR_TWO' ,
      'CBM_ADDR_THREE',  10000  ,  400016  ,
      '22829042' ,  'CBM_PHON_TWO' , 'CBM_PHON_THREE',
      'CBM_CONT_PRSN' ,  'CBM_FAX_NO' , 'CBM_EMAIL_ID' ,
      20000  ,  'sysdate' , 'OMKAR'  , 'sysdate'   );  ---if row is not there in table then inserting a row

  errmsg:='Row is inserted into Table ';
  --dbms_output.put_line('Please execute the script <script name>');
   EXCEPTION
    WHEN OTHERS THEN
    errmsg:='compulsory field is missing ';
  END;
  BEGIN
    SELECT CPC_CTRL_NUMB INTO v_CPC_CTRL_NUMB
  FROM CMS_PANGEN_CTRL
    WHERE cpc_ctrl_bran=p_bran_code
    --and cpc_ctrl_bin=
    AND cpc_ctrl_catg='NORMAL'
    AND TRUNC(cpc_ins_date)=TRUNC(SYSDATE);

  errmsg :='The control number set in the table before update is '||v_cpc_ctrl_numb;

  IF v_cpc_ctrl_numb != p_ctrl_numb THEN
      UPDATE CMS_PANGEN_CTRL
      SET CPC_CTRL_NUMB    =p_ctrl_numb
      WHERE cpc_ctrl_bran    =p_bran_code
      AND cpc_ctrl_catg    ='NORMAL'
      AND TRUNC(cpc_ins_date)=TRUNC(SYSDATE);
     END IF;
  EXCEPTION
    WHEN OTHERS THEN
    errmsg := SQLCODE ||SQLERRM || 1 ;
  END;
EXCEPTION
 WHEN OTHERS THEN
 errmsg := SQLCODE ||SQLERRM ;
END;
/


