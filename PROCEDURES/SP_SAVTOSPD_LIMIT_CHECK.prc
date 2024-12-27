set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVTOSPD_LIMIT_CHECK(
   p_inst_code          IN       NUMBER,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2,
   p_svg_acct_no        IN       VARCHAR2,
   p_acct_type          IN       NUMBER,
   p_tran_date          IN       date, --varchar2 modified for mantis id 0014019
   p_tran_time          IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2,
   p_savtospd_count     OUT      NUMBER

)
AS
/*************************************************
     * Modified By      : MageshKumar S
     * Modified Date    : 19-02-2014
     * Modified For     : MVCSD-4479
     * Modified Reason  :
     * Reviewer         : Dhiraj
     * Reviewed Date    : 7-03-2014
     * Build Number     : RI0027.2_B0001

  	 * Modified By      : Sai prasad
     * Modified Date    : 02-Apr-2014
     * Modified For     : Mantis Id 0014019
     * Modified Reason  :
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 02-April-2014
     * Build Number     : RI0027.2_B0003

  	 * Modified By      : Dnyaneshwar J
     * Modified Date    : 23-Apr-2014
     * Modified For     : Mantis Id 14045
     * Reviewer         : spankaj
     * Reviewed Date    : 23-April-2014
     * Build Number     : RI0027.2_B0008

  	 * Modified By      : Dnyaneshwar J
     * Modified Date    : 24-Apr-2014
     * Modified For     : Mantis Id 14045
     * Reviewer         : spankaj
     * Reviewed Date    : 24-April-2014
     * Build Number     : RI0027.2_B0009

     * Modified by          : Saravanakumar
     * Modified Date        : 19-Aug-2015
     * Modified For         :Performance changes
     * Reviewer             : Spankaj
     * Build Number         : VMSGPRHOSTCSD3.1_B0003

     * Modified by          : Abdul Hameed
     * Modified Date        : 30 -Nov-2015
     * Modified For         : Modified reset logic
     * Reviewer             : Spankaj
     * Build Number         : VMSGPRHOSTCSD3.2.1_B0001
     
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

 *************************************************/
   v_errmsg                   VARCHAR2 (500);
   exp_reject_record          EXCEPTION;
   v_svgtospd_Rev_trans       NUMBER(10);
   V_SAV_COUNT                NUMBER(10);
   V_SAVTOSPD_DATE            date;
   V_SAVTOSPD_COUNT           NUMBER (10);
   v_Retperiod  date; --Added for VMS-5733/FSP-991

--Main Begin Block Starts Here

BEGIN

   p_resp_code := '00';
   v_errmsg := 'OK';

    BEGIN
      SELECT CAM_SAVTOSPD_TFER_COUNT,CAM_SAVTOSPD_TFER_DATE
        INTO V_SAVTOSPD_COUNT,V_SAVTOSPD_DATE
        FROM cms_acct_mast
         WHERE cam_acct_no = p_svg_acct_no
          AND cam_type_code = p_acct_type
          AND cam_inst_code = p_inst_code;

   EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error on CAM_SAVTOSPD_TFER_COUNT || CAM_SAVTOSPD_TFER_DATE details';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from Acct Mast for getting the number of transactions for a month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;


    IF NVL(V_SAVTOSPD_DATE,NULL) IS NULL
    THEN

   --Sn Get the number of transactions for a month(Saving to Spending)
   BEGIN
       --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       


IF (p_tran_date>v_Retperiod)
    THEN
      SELECT COUNT (*)
        INTO v_svgtospd_Rev_trans
        FROM transactionlog
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code IN ('11','12'))
             )
 AND add_ins_date BETWEEN TRUNC (p_tran_date, 'month') AND
        to_date(to_char(LAST_DAY (p_tran_date),'yyyymmdd')||'235959','yyyymmddhh24miss')
         AND response_code = '00'
         AND tran_reverse_flag='Y'
         AND customer_card_no =p_pan_code
         AND customer_acct_no =p_svg_acct_no;
    ELSE
       SELECT COUNT (*)
        INTO v_svgtospd_Rev_trans
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code IN ('11','12'))
             )
 AND add_ins_date BETWEEN TRUNC (p_tran_date, 'month') AND
        to_date(to_char(LAST_DAY (p_tran_date),'yyyymmdd')||'235959','yyyymmddhh24miss')
         AND response_code = '00'
         AND tran_reverse_flag='Y'
         AND customer_card_no =p_pan_code
         AND customer_acct_no =p_svg_acct_no;
     END IF;    

     
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from TRANSACTIONLOG for getting the number of transactions for a month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;



   BEGIN
       --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (p_tran_date>v_Retperiod)
    THEN
      SELECT COUNT (*) -v_svgtospd_Rev_trans
        INTO V_SAVTOSPD_COUNT
        FROM transactionlog
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code IN ('11','12'))
             )
AND add_ins_date BETWEEN TRUNC (p_tran_date, 'month') AND
        to_date(to_char(LAST_DAY (p_tran_date),'yyyymmdd')||'235959','yyyymmddhh24miss')
         AND response_code = '00'
         AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N')
         AND customer_card_no =p_pan_code
         AND customer_acct_no =p_svg_acct_no;
  ELSE
        SELECT COUNT (*) -v_svgtospd_Rev_trans
        INTO V_SAVTOSPD_COUNT
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
       WHERE (   (delivery_channel = '07' AND txn_code IN ('11', '21'))
              OR (delivery_channel = '10' AND txn_code IN ('20', '40'))
              OR (delivery_channel = '13' AND txn_code IN ('11','12'))
             )
AND add_ins_date BETWEEN TRUNC (p_tran_date, 'month') AND
        to_date(to_char(LAST_DAY (p_tran_date),'yyyymmdd')||'235959','yyyymmddhh24miss')
         AND response_code = '00'
         AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N')
         AND customer_card_no =p_pan_code
         AND customer_acct_no =p_svg_acct_no;
   END IF;             
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting data from TRANSACTIONLOG for getting the number of transactions for a month '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

    --En Get the number of transaction for a month(Saving to Spending)

   BEGIN

   UPDATE cms_acct_mast
         SET CAM_SAVTOSPD_TFER_COUNT = V_SAVTOSPD_COUNT,
           --  CAM_SAVTOSPD_TFER_DATE = last_day(p_tran_date), --last_day(to_date(p_tran_date,'dd/mm/yyyy')), modified for Mantis 0014019
            CAM_SAVTOSPD_TFER_DATE = trunc(last_daY(sysdate)+1)-1/86400,
             cam_lupd_date = SYSDATE,
             cam_lupd_user = 1
       WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =p_svg_acct_no
          AND cam_type_code =p_acct_type;

      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error while updating count and date in acct mast';
         RAISE exp_reject_record;
      END IF;

   END;

   END IF;

  IF SYSDATE > V_SAVTOSPD_DATE  --modified for Mantis 0014019 --Modified by Dnyaneshwar J on 23 April 2014 For Mantis-14045
  THEN
  BEGIN
      UPDATE cms_acct_mast
         SET CAM_SAVTOSPD_TFER_COUNT = '0',
         --    CAM_SAVTOSPD_TFER_DATE = last_day(SYSDATE), --last_day(to_date(p_tran_date,'dd/mm/yyyy')), modified for Mantis 0014019
          CAM_SAVTOSPD_TFER_DATE = trunc(last_daY(sysdate)+1)-1/86400,
             cam_lupd_date = SYSDATE,
             cam_lupd_user = 1
       WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =p_svg_acct_no
        AND cam_type_code =p_acct_type;

      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         v_errmsg := 'Error while updating count and date in acct mast';
         RAISE exp_reject_record;
      END IF;
    EXCEPTION
    when exp_reject_record then
      raise exp_reject_record;
       WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while updating data into cms_acct_mast table'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      END;

     ELSE
      V_SAV_COUNT  := V_SAVTOSPD_COUNT;
   END IF;


 p_savtospd_count := NVL(V_SAV_COUNT,0);
 p_resmsg := v_errmsg;
 EXCEPTION
 when exp_reject_record then
  p_resmsg := v_errmsg;
  when others then
  p_resmsg :=  'Error in Main check '           || SUBSTR (SQLERRM, 1, 200);
END;
/
show error