CREATE OR REPLACE PROCEDURE VMSCMS.sp_overridden_excp_rep (
   prm_dirname   IN       VARCHAR2,
   prm_errmsg    OUT      VARCHAR2
)
AS
   l_file        UTL_FILE.file_type;
   v_file_name   VARCHAR2 (1000);

   CURSOR c
   IS
      SELECT fn_mask (fn_dmaps_main (customer_card_no_encr),'X',7,6) mask_cardno,
             custfirstname || customerlastname customer_name,
             (SELECT cum_user_name
                FROM cms_userdetl_mast
               WHERE cum_user_code = add_ins_user) overridden_user_name,
             time_stamp overridden_timestamp
        FROM VMSCMS.TRANSACTIONLOG_VW 	--Added for VMS-5733/FSP-991
       WHERE instcode = 1
         AND delivery_channel = '03'
         AND txn_code = '91'
         AND response_code = '00'
         AND add_ins_date >= TRUNC (SYSDATE);
BEGIN
   prm_errmsg := 'OK';
   v_file_name :='CSR_OVERRIDDEN_EXCP_REP_' || TO_CHAR (SYSDATE, 'DDMMYYYY')|| '.csv';

   --open file
   BEGIN
      l_file := UTL_FILE.fopen (prm_dirname, v_file_name, 'W', 32767);
   EXCEPTION
      WHEN OTHERS THEN
         prm_errmsg :='Error occured during file open-' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   --write header information
   UTL_FILE.put_line (l_file,'MASK_CARDNO,CUSTOMER_NAME,OVERRIDDEN_USER_NAME,OVERRIDDEN_TIMESTAMP');
   --flush file to disk
   UTL_FILE.fflush (l_file);

   --write records
   FOR cur_data IN c
   LOOP
      BEGIN
         UTL_FILE.put_line (l_file,
                               cur_data.mask_cardno
                            || ','
                            || cur_data.customer_name
                            || ','
                            || cur_data.overridden_user_name
                            || ','
                            || cur_data.overridden_timestamp
                           );
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      EXCEPTION
         WHEN OTHERS THEN
            prm_errmsg :='Error Occured During writting file-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
   END LOOP;

   --close file
   UTL_FILE.fclose (l_file);
EXCEPTION
   WHEN OTHERS THEN
      IF UTL_FILE.is_open (l_file) THEN
         UTL_FILE.fclose (l_file);
      END IF;

      prm_errmsg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR;