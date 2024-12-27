create or replace
PROCEDURE        vmscms.SP_CREATE_EMBFNAME(
    INSTCODE    IN NUMBER,
    FILENAME    IN VARCHAR2,
    TYPEOFORDER IN VARCHAR2,
    VENDER      IN VARCHAR2,
    P_BIN       IN VARCHAR2,
    LUPDUSER    IN NUMBER,
    EMBFNAME OUT VARCHAR2,
    ERRMSG OUT VARCHAR2)
AS
  /*************************************************
  * Modified By       :  Ramesh.A.
  * Modified Date     :  20-NOV-2012
  * Modified Reason   :  Added file count in file format and updated the query for getting file count for defect 9566
  * Reviewer          :  Saravanakumar
  * Reviewed Date     :  21-NOV-2012
  * Release Number    :  CMS3.5.1_RI0021.1
  * Modified By       : Ramesh
  * Modified Date     : 30-Sep-2014
  * Modified For      : MFCHOST-389
  * Reviewer          : Spankaj
  * Release Number    : RI0027.4_B0002
  * Modified By       : Siva Kumar M
  * Modified Date     : 04-Oct-2014
  * Modified For      : Mantis id:0015803
  * Modified Reason   : CCF File name format is wrong for Source One
  * Reviewer          : Spankaj
  * Release Number    : RI0027.4_B0003
  * Modified By       : siva kumar M
  * Modified Date     : 12-Feb-2015
  * Modified For      : FSS-2161
  * Reviewer          : SaravanaKumar A
  * Release Number    :  RI0027.5_B0007
  * Modified By       : Ramesh
  * Modified Date     : 19-FEB-2015
  * Modified For      : FSS-2236
  * Reviewer          : Pankaj S
  * Release Number    : RI0027.5_B0008
  * Modified By       : DHINAKARAN B
  * Modified Date     : 24-JUL-2017
  * Modified For      : FSS-5157 B2B
  * Reviewer          :
   * Modified By       : DHINAKARAN B
  * Modified Date     : 12-mar-2018
  * Modified For      : FSS-5157 B2B
  * Reviewer          :
  
  * Modified By      : Shanmugavel
  * Modified Date    : 13/09/2024
  * Purpose          : VMS-9087-Enhance CCF Spec(5.0) File Format to include Network Specifications 
  * Reviewer         : John/Filipe
  * Release Number   : VMSGPRHOSTR103_B0002
  *************************************************/
  V_CURR_DATE VARCHAR2(8);
  V_FILE_NUM  NUMBER(3);
  V_FILE_CNT  VARCHAR2(3);
  V_FILE_LEN  NUMBER(3);
  V_PROD_CODE CMS_PROD_BIN.CPB_PROD_CODE%TYPE;
  v_FILE_FORMAT VMS_FULFILLMENT_VENDOR_MAST.VFV_CCF_FILE_FORMAT%TYPE;
  V_REISSU_FILE_FORMAT VMS_FULFILLMENT_VENDOR_MAST.VFV_REPLACE_CCF_FILE_FORMAT%TYPE;
  V_FLE_FORMAT VMS_FULFILLMENT_VENDOR_MAST.VFV_CCF_FILE_FORMAT%TYPE;
  V_EMB_FNAME VARCHAR2(200);
  V_INTERCHANGE_NAME VARCHAR2(100); -- VMS-9087
BEGIN
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'mmddyyyy') INTO V_CURR_DATE FROM DUAL;
    SELECT LPAD(NVL(MAX(CEC_FILE_COUNT)+1,0),3,0)
    INTO V_FILE_CNT
    FROM CMS_EMBOS_CTRL
    WHERE CEC_INST_CODE        = INSTCODE
    AND CEC_VENDOR_NAME        = VENDER
    AND TRUNC(CEC_CREATE_DATE) = TRUNC(SYSDATE);
    IF TYPEOFORDER  in ('06') THEN 
      V_PROD_CODE :=P_BIN;
    ELSIF TYPEOFORDER not in ('04','05') THEN 
    BEGIN
      SELECT CPB_PROD_CODE
      INTO V_PROD_CODE
      FROM cms_prod_bin
      WHERE cpb_inst_bin=P_BIN
      AND cpb_inst_code =INSTCODE;
    EXCEPTION
    WHEN OTHERS THEN
      ERRMSG := 'Exeption Prod -- ' || SQLCODE || '--' || SQLERRM;
    END;
    /** VMS-9087 : Enhance CCF Spec(5.0) File Format to include Network Specifications */
    -- Start
    IF TYPEOFORDER  IN ('03') THEN
    BEGIN
    SELECT CASE WHEN CIM_INTERCHANGE_CODE in('X','S','V') THEN
    'NONAMEX' ELSE REPLACE(CIM_INTERCHANGE_NAME,' ','_') END 
    INTO V_INTERCHANGE_NAME 
    FROM VMSCMS.CMS_PROD_MAST, VMSCMS.CMS_INTERCHANGE_MAST
    WHERE CPM_INST_CODE = CIM_INST_CODE AND
    CPM_INTERCHANGE_CODE = CIM_INTERCHANGE_CODE AND
    CPM_PROD_CODE=V_PROD_CODE AND CPM_INST_CODE=INSTCODE;
    EXCEPTION
    WHEN OTHERS THEN
      ERRMSG := 'Exeption Prod -- ' || SQLCODE || '--' || SQLERRM;
    END;
    ELSE
    BEGIN 
    SELECT DISTINCT REPLACE(CIM_INTERCHANGE_NAME,' ','_') 
    INTO V_INTERCHANGE_NAME 
    FROM VMSCMS.CMS_PROD_MAST, VMSCMS.CMS_INTERCHANGE_MAST
    WHERE CPM_INST_CODE = CIM_INST_CODE AND
    CPM_INTERCHANGE_CODE = CIM_INTERCHANGE_CODE AND
    CPM_PROD_CODE=V_PROD_CODE AND CPM_INST_CODE = INSTCODE;
    EXCEPTION
    WHEN OTHERS THEN
      ERRMSG := 'Exeption Prod -- ' || SQLCODE || '--' || SQLERRM;
    END;
    END IF;
    -- End
    END IF;
    BEGIN
      SELECT regexp_replace(NVL(DECODE(TYPEOFORDER,'03',VFV_REPLACE_CCF_FILE_FORMAT,'05',VFV_REPLACE_CCF_FILE_FORMAT,'06',VFV_REPLACE_CCF_FILE_FORMAT,VFV_CCF_FILE_FORMAT),''),'('||CHR(10)||'|'||CHR(13)||')+','')
      INTO v_FILE_FORMAT
      FROM VMS_FULFILLMENT_VENDOR_MAST
      WHERE VFV_FVENDOR_ID=VENDER;

       IF TYPEOFORDER not in ('04','05') THEN
      SELECT   replace(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(V_FILE_FORMAT ,'<<PrintVendor>>', VENDER),'<<Network>>',V_INTERCHANGE_NAME),'<<ProductCode>>',V_PROD_CODE),'<<FileCount>>',V_FILE_CNT),'<<Date>>',V_CURR_DATE),'<<FileType>>',TYPEOFORDER)  
      INTO V_EMB_FNAME
      FROM dual;
      else 
        select replace(replace(replace(replace(v_file_format ,'<<PrintVendor>>', vender),'<<ProductCode>>','B2B'),'<<FileCount>>',V_FILE_CNT),'<<Date>>',v_curr_date)
        into v_emb_fname
        from dual;
       END IF;
    EXCEPTION
    WHEN OTHERS THEN
      ERRMSG := 'Exeption Prod -- ' || SQLCODE || '--' || SQLERRM;
    END;
    EMBFNAME :=V_EMB_FNAME|| '.csv';
    BEGIN
      INSERT
      INTO CMS_EMBOS_CTRL
        (
          CEC_INST_CODE,
          CEC_EMB_FNAME,
          CEC_CREATE_TOT,
          CEC_CREATE_DATE,
          CEC_INS_USER,
          CEC_INS_DATE,
          CEC_LUPD_USER,
          CEC_LUPD_DATE,
          CEC_FILE_COUNT,
          CEC_VENDOR_NAME
        )
        VALUES
        (
          INSTCODE,
          EMBFNAME,
          0,
          SYSDATE,
          LUPDUSER,
          SYSDATE,
          LUPDUSER,
          SYSDATE,
          V_FILE_CNT,
          VENDER
        );
      ERRMSG := 'OK';
    EXCEPTION
    WHEN OTHERS THEN
      ERRMSG := 'Exception 2 --' || SQLCODE || '--' || SQLERRM;
    END;
  EXCEPTION
  WHEN OTHERS THEN
    ERRMSG := 'Exeption KK 1 -- ' || SQLCODE || '--' || SQLERRM;
  END;
EXCEPTION
WHEN OTHERS THEN
  ERRMSG := 'Exeption Main -- ' || SQLCODE || '--' || SQLERRM;
END;
/
show error