CREATE OR REPLACE PROCEDURE VMSCMS.sp_acct_tmpno (
   prm_instcode     IN       NUMBER,
   prm_branc_code   IN       VARCHAR2,
   prm_prod_code    IN       VARCHAR2,
   prod_cattype     IN       NUMBER,
   prm_tmp_num      OUT      VARCHAR2,
   prm_cac_length             OUT      NUMBER,
   prm_errmsg       OUT      VARCHAR2
)
AS
   v_errmsg                 VARCHAR2 (500);
   exp_reject_record        EXCEPTION;
   v_loop_cnt               NUMBER                                  DEFAULT 0;
   v_loop_max_cnt           NUMBER;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_tmp_acct_no            cms_appl_pan.cap_acct_no%TYPE;
   v_chk_index              NUMBER (1);
   v_prod_prefix            VARCHAR (3);
   TYPE rec_acct_construct IS RECORD (
      cac_profile_code   cms_acct_construct.cac_profile_code%TYPE,
      cac_field_name     cms_acct_construct.cac_field_name%TYPE,
      cac_start_from     cms_acct_construct.cac_start_from%TYPE,
      cac_start          cms_acct_construct.cac_start%TYPE,
      cac_length         cms_acct_construct.cac_length%TYPE,
      cac_field_value    VARCHAR2 (30),
      cac_tot_length     cms_acct_construct.cac_tot_length%TYPE
   );

   TYPE table_acct_construct IS TABLE OF rec_acct_construct
      INDEX BY BINARY_INTEGER;

   v_table_acct_construct   table_acct_construct;

   CURSOR c (p_profile_code IN VARCHAR2)
   IS
      SELECT   cac_profile_code, cac_field_name, cac_start_from, cac_length,
               cac_start, cac_tot_length
          FROM cms_acct_construct
         WHERE cac_profile_code = p_profile_code
           AND cac_inst_code = prm_instcode
      ORDER BY cac_start_from DESC;
BEGIN
   prm_errmsg := 'OK';

   BEGIN
      SELECT cpm_profile_code
        INTO v_profile_code
        FROM cms_prod_mast
       WHERE cpm_inst_code = prm_instcode AND cpm_prod_code = prm_prod_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                'Profile code not defined for product code ' || prm_prod_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting profile code from product mast as '  --Error message modified by Pankaj S. on 25-Sep-2013
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
         SELECT cac_length
           INTO prm_cac_length
           FROM cms_acct_construct
          WHERE cac_profile_code =
                   (SELECT cpm_profile_code
                      FROM cms_prod_mast
                     WHERE cpm_prod_code = prm_prod_code
                       AND cpm_inst_code = prm_instcode)
            AND cac_inst_code = prm_instcode
            AND cac_field_name = 'Serial Number';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Account construct parameters not defined for product code ' || prm_prod_code; --Error message modified by Pankaj S. on 25-Sep-2013
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting Account construct parameters as '  --Error message modified by Pankaj S. on 25-Sep-2013
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

   BEGIN
      v_loop_cnt := 0;

      FOR i IN c (v_profile_code)
      LOOP
         v_loop_cnt := v_loop_cnt + 1;

         SELECT i.cac_profile_code,
                i.cac_field_name,
                i.cac_start_from,
                i.cac_length,
                i.cac_start,
                i.cac_tot_length
           INTO v_table_acct_construct (v_loop_cnt).cac_profile_code,
                v_table_acct_construct (v_loop_cnt).cac_field_name,
                v_table_acct_construct (v_loop_cnt).cac_start_from,
                v_table_acct_construct (v_loop_cnt).cac_length,
                v_table_acct_construct (v_loop_cnt).cac_start,
                v_table_acct_construct (v_loop_cnt).cac_tot_length
           FROM DUAL;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting Account construct parameters as ' --Error message modified by Pankaj S. on 25-Sep-2013
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_loop_max_cnt := v_table_acct_construct.COUNT;
      v_tmp_acct_no := NULL;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_acct_construct (i).cac_field_name = 'Branch'
         THEN
            v_table_acct_construct (i).cac_field_value :=
               LPAD (SUBSTR (TRIM (prm_branc_code),
                             v_table_acct_construct (i).cac_start,
                             v_table_acct_construct (i).cac_length
                            ),
                     v_table_acct_construct (i).cac_length,
                     '0'
                    );
         ELSIF v_table_acct_construct (i).cac_field_name = 'Product Prefix'
         THEN
            BEGIN
               SELECT cpc_acct_prod_prefix
                 INTO v_prod_prefix
                 FROM cms_prod_cattype
                WHERE cpc_prod_code = prm_prod_code
                  AND cpc_card_type = prod_cattype;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'Data not available in cms_prod_cattype for product code'
                     || prm_prod_code;
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting Account Product Category Prefix from cms_prod_cattype as '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;

            IF v_prod_prefix IS NULL
            THEN
               BEGIN
                  SELECT cip_param_value
                    INTO v_prod_prefix
                    FROM cms_inst_param
                   WHERE cip_inst_code = prm_instcode
                     AND cip_param_key = 'ACCTPRODCATPREFIX';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Data not available in CMS_INST_PARAM for paramkey ACCTPRODCATPREFIX';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting Account Product Category Prefix from CMS_INST_PARAM as  '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;
            END IF;

            v_table_acct_construct (i).cac_field_value :=
               LPAD (SUBSTR (TRIM (v_prod_prefix),
                             v_table_acct_construct (i).cac_start,
                             v_table_acct_construct (i).cac_length
                            ),
                     v_table_acct_construct (i).cac_length,
                     '0'
                    );
         ELSIF v_table_acct_construct (i).cac_field_name = 'Check Digit'
         THEN
            v_chk_index := 1;
         ELSE
            IF v_table_acct_construct (i).cac_field_name <> 'Serial Number'
            THEN
               v_errmsg :=
                     'Account Number construct '
                  || v_table_acct_construct (i).cac_field_name
                  || ' not exist ';
               RAISE exp_reject_record;
            END IF;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
                'Error from Account gen process as ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         IF     v_table_acct_construct (j).cac_start_from = i
            AND v_table_acct_construct (j).cac_field_name <> 'Serial Number'
         THEN
            v_tmp_acct_no :=
                  v_tmp_acct_no || v_table_acct_construct (j).cac_field_value;
            prm_tmp_num := v_tmp_acct_no;
            EXIT;
         END IF;
      END LOOP;
   END LOOP;

   DBMS_OUTPUT.put_line ('Temp Acct_No ---' || prm_tmp_num);
EXCEPTION
   WHEN exp_reject_record
      THEN
    prm_errmsg:=v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Exception From account construct -- ' || SQLERRM;
END;
/
SHOW ERRORS;
