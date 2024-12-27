CREATE OR REPLACE PROCEDURE vmscms.sp_upload_limitprofile_card (
   p_inst_code   IN       NUMBER,
   p_file_name   IN       VARCHAR2,
   p_ins_user    IN       NUMBER,
   p_resp_msg    OUT      VARCHAR2
)
AS
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_limitprfl_id           cms_feeplimitprfl_dtl.cfd_feelimit_code%TYPE;
   v_row_id                 cms_feeplimitprfl_dtl.cfd_row_id%TYPE;
   exp_main_reject_record   EXCEPTION;

   /*************************************************
        * Created By       :  MageshKumar S.
        * Created Date     :  31-July-2014
        * Purpose          :  To attach Limit Profile to card
		* Reviewer         :  Spankaj
		* Build Number     :  RI0027.3.1_B0001
    *************************************************/
   CURSOR c_limitprofile_det
   IS
      SELECT cap_pan_code, cfd_feelimit_code, cfd_row_id
        FROM cms_appl_pan, cms_feeplimitprfl_dtl
       WHERE cap_inst_code = cfd_inst_code
         AND cap_acct_no = cfd_acct_no
         AND cap_card_stat <> '9'
         AND cfd_file_name = p_file_name
         AND cfd_attch_type = 'L'
         AND cfd_resp_msg IS NULL;
BEGIN
   FOR i2 IN c_limitprofile_det
   LOOP
      v_hash_pan := i2.cap_pan_code;
      v_limitprfl_id := i2.cfd_feelimit_code;
      v_row_id := i2.cfd_row_id;
      p_resp_msg := 'Success';

      BEGIN
         UPDATE cms_appl_pan
            SET cap_prfl_code = v_limitprfl_id,
                cap_prfl_levl = '1',
                cap_lupd_user = p_ins_user
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0 THEN
            p_resp_msg := 'Problem in updation of profile id.';
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Error while updating for the limit profile id :'|| SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         UPDATE cms_feeplimitprfl_dtl
            SET cfd_resp_msg = p_resp_msg
          WHERE cfd_inst_code = p_inst_code
            AND cfd_file_name = p_file_name
            AND cfd_row_id = v_row_id;
            --AND cfd_resp_msg IS NULL;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   END LOOP;

   p_resp_msg := 'OK';
EXCEPTION
   WHEN OTHERS THEN
      p_resp_msg := 'Main Excp--' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR