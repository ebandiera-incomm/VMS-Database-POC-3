CREATE OR REPLACE PROCEDURE VMSCMS.SP_DUP_CHECK_ACCT_INSTSPECIFIC
      (
       prm_instcode  IN VARCHAR2,
       prm_acctid  IN CMS_ACCT_MAST.cam_acct_id%TYPE,
       prm_dupcheck_flag OUT VARCHAR2,
       prm_errmsg  OUT VARCHAR2
      )
    IS
       /*************************************************
         * VERSION   :  1.0
         * Created Date  :  27/May/2010
         * Created By  :  Chinmaya Behera
         * PURPOSE   :  Created for Institute specific duplicate check .In ICICI DUP Check is on Account only
         * Modified By:  :
         * Modified Date  :
       ***********************************************/
      V_CHECK_CNT    NUMBER(1);

    BEGIN
     /*SELECT  DISTINCT 1
       INTO V_CHECK_CNT
       FROM CMS_PAN_ACCT,CMS_APPL_PAN
       WHERE cpa_inst_code = prm_instcode
       AND cpa_acct_id = prm_acctid
       AND cap_pan_code = cpa_pan_code
       AND cap_mbr_numb = cpa_mbr_numb
       AND cap_card_stat = '1'
     AND cap_expry_date > SYSDATE;*/


     SELECT  DISTINCT 1
       INTO V_CHECK_CNT
       FROM CMS_ACCT_MAST
       WHERE cam_inst_code = prm_instcode
       AND cam_acct_id = prm_acctid ;

     prm_dupcheck_flag := 'T';
     prm_errmsg  := 'OK';

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
     prm_dupcheck_flag := 'F';
     prm_errmsg  := 'OK';
     RETURN;
     WHEN OTHERS THEN
     prm_errmsg  := 'Error while checking duplicate acct'|| SUBSTR(SQLERRM,1,200);
     RETURN;
    END;
/

SHOW ERRORS
