CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_cardstats (
   prm_inst_code                   NUMBER,
   p_cust_acct_no         IN       VARCHAR2,
   p_pan_number           OUT      VARCHAR2,
   p_cust_current_accno   OUT      VARCHAR2,
   p_pan_encr             OUT      VARCHAR2,
   p_response             OUT      VARCHAR2,
   prm_errmsg             OUT      VARCHAR2
)
/*************************************************
     * Created Date     :  05-June-2011
     * Created By       :  Ramkumar.MK
     * PURPOSE          :  For Get the card Number for ACH Transaction
     * Reviewd by       : Nanda Kumar R.
     * Reviewed Date    : 06-June-2012
     * Build No         : CMS3.5.1_RI0009_B0003
 *************************************************/
IS
   v_cust_card_no           VARCHAR2 (19);
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_respcode               VARCHAR2 (5);
   exp_main_reject_record   EXCEPTION;
   v_errmsg                 VARCHAR2 (500);
   exp_reject_record        EXCEPTION;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_count                  NUMBER;
   v_card_stat              NUMBER;
   v_card_count             NUMBER;
BEGIN
prm_errmsg :='OK';

   SELECT COUNT (*)
     INTO v_count
     FROM cms_appl_pan
    WHERE cap_acct_no = p_cust_acct_no
      AND cap_inst_code = prm_inst_code
      AND cap_card_stat != '9'
      AND cap_addon_stat = 'P';

   --   and cap_card_stat !=0;
   IF v_count > 1
   THEN
      SELECT COUNT (*)
        INTO v_card_count
        FROM cms_appl_pan
       WHERE cap_acct_no = p_cust_acct_no
         AND cap_inst_code = prm_inst_code
         AND cap_card_stat = '0'
         AND cap_addon_stat = 'P';

      IF v_card_count > 1
      THEN
         BEGIN
            SELECT   cap_pan_code, fn_dmaps_main (cap_pan_code_encr),
                     cap_pan_code_encr
                INTO v_hash_pan, v_cust_card_no,
                     v_encr_pan
                FROM cms_appl_pan
               WHERE cap_acct_no = p_cust_acct_no
                 AND cap_inst_code = prm_inst_code
                 AND cap_card_stat != '9'
                 AND cap_addon_stat = 'P'
                 AND ROWNUM = 1
            ORDER BY cap_ins_date ASC;

            p_cust_current_accno := v_cust_card_no;
            p_pan_number := v_hash_pan;
            p_pan_encr := v_encr_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '12';
               v_errmsg := 'Invalid Card Status';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while getting the primary pan for the Account Number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      ELSE
         BEGIN
            SELECT cap_pan_code, fn_dmaps_main (cap_pan_code_encr),
                   cap_pan_code_encr
              INTO v_hash_pan, v_cust_card_no,
                   v_encr_pan
              FROM cms_appl_pan
             WHERE cap_acct_no = p_cust_acct_no
               AND cap_inst_code = prm_inst_code
               AND cap_card_stat != '9'
               AND cap_addon_stat = 'P'
               AND cap_card_stat != 0;

            p_cust_current_accno := v_cust_card_no;
            p_pan_number := v_hash_pan;
            p_pan_encr := v_encr_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '12';
               v_errmsg := 'Invalid Card Status';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while getting the primary pan for the Account Number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;
   ELSE
      BEGIN
         SELECT cap_pan_code, fn_dmaps_main (cap_pan_code_encr),
                cap_pan_code_encr
           INTO v_hash_pan, v_cust_card_no,
                v_encr_pan
           FROM cms_appl_pan
          WHERE cap_acct_no = p_cust_acct_no
            AND cap_inst_code = prm_inst_code
            AND cap_card_stat != '9'
            AND cap_addon_stat = 'P' ;

          --and cap_card_stat !=0;
         p_cust_current_accno := v_cust_card_no;
         p_pan_number := v_hash_pan;
         p_pan_encr := v_encr_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '12';
            v_errmsg := 'Invalid Card Status';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while getting the primary pan for the Account Number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;
EXCEPTION
   WHEN exp_main_reject_record THEN
       p_response:=v_respcode;
       prm_errmsg:= v_errmsg;
   WHEN OTHERS
   THEN
         p_response := '21';
          prm_errmsg :='Error while executing sp_check_cardstats'||substr(sqlerrm,1,200);

END;
/


