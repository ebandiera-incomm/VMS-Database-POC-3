create or replace PROCEDURE        vmscms.SP_SAVINGS_ACCOUNT_CONSTRUCT (
   p_instcode     IN       NUMBER,
   p_branc_code   IN       VARCHAR2,
   p_prod_code    IN       VARCHAR2,
   p_prod_cattype IN       NUMBER,  -- Added by Ramesh.A on 09/032012
   p_acct_num     OUT      VARCHAR2,
   p_errmsg       OUT      VARCHAR2
)
AS
/*************************************************
     * Created Date     :  06-Feb-2012
     * Created By       :  Ramesh
     * PURPOSE          :  Saving account
     
     * Modified By      :  Trivikram
     * Modified Date    :  07-june-12
     * Modified Reason  :  Prefix to be different from PAN and Account number construction
     * Reviewer         :  Nanda Kumar R.
     * Reviewed Date    :  11-june-12
     * Release Number   :  CMS3.5.1_RI0009_B0011
     
     * Modified By      : MageshKumar S
     * Modified Date    : 18/07/2017
     * Purpose          : FSS-5157
     * Reviewer         : Saravanan/Pankaj S. 
     * Release Number   : VMSGPRHOST17.07
*************************************************/
   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
   v_errmsg                 VARCHAR2 (500);
   v_acct_id                cms_acct_mast.cam_acct_id%TYPE;
   exp_reject_record        EXCEPTION;
   v_loop_cnt               NUMBER DEFAULT 0;
   v_loop_max_cnt           NUMBER;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_tmp_acct_no            cms_appl_pan.cap_acct_no%TYPE;
   v_chk_index              NUMBER (1);
   v_serial_index           NUMBER;
   v_serial_maxlength       NUMBER (2);
   v_serial_no              NUMBER;
   v_check_digit            NUMBER;
   --v_tmp_acct               cms_appl_mast.cam_appl_bran%TYPE; --commented by Ramesh.A on 14/03/2012
   v_tmp_acct               VARCHAR2 (16); --Added by Ramesh.A on 14/03/2012
   v_csc_profile_code       CMS_SAVINGSACCT_CONSTRUCT.csc_profile_code%TYPE;
   v_csc_field_name         CMS_SAVINGSACCT_CONSTRUCT.csc_field_name%TYPE;
   v_csc_start_from         CMS_SAVINGSACCT_CONSTRUCT.csc_start_from%TYPE;
   v_csc_start              CMS_SAVINGSACCT_CONSTRUCT.csc_start%TYPE;
   v_csc_length             CMS_SAVINGSACCT_CONSTRUCT.csc_length%TYPE;
   v_cac_field_value        VARCHAR2 (30);  -- Added by Ramesh.A on 09/032012
   v_csc_tot_length         CMS_SAVINGSACCT_CONSTRUCT.csc_tot_length%TYPE;
   v_prod_prefix            varchar(3);  -- Added by Ramesh.A on 09/032012

   TYPE rec_acct_construct IS RECORD (
      csc_profile_code   CMS_SAVINGSACCT_CONSTRUCT.csc_profile_code%TYPE,
      csc_field_name     CMS_SAVINGSACCT_CONSTRUCT.csc_field_name%TYPE,
      csc_start_from     CMS_SAVINGSACCT_CONSTRUCT.csc_start_from%TYPE,
      csc_start          CMS_SAVINGSACCT_CONSTRUCT.csc_start%TYPE,
      csc_length         CMS_SAVINGSACCT_CONSTRUCT.csc_length%TYPE,
      csc_field_value    VARCHAR2 (50),
      csc_tot_length     CMS_SAVINGSACCT_CONSTRUCT.csc_tot_length%TYPE
   );

   TYPE table_acct_construct IS TABLE OF rec_acct_construct
      INDEX BY BINARY_INTEGER;

   v_table_acct_construct   table_acct_construct;

   CURSOR c (p_profile_code IN VARCHAR2)
   IS
      SELECT   csc_profile_code, csc_field_name, csc_start_from,
               csc_length, csc_start, csc_tot_length
          INTO v_csc_profile_code, v_csc_field_name, v_csc_start_from,
               v_csc_length, v_csc_start, v_csc_tot_length
          FROM CMS_SAVINGSACCT_CONSTRUCT
         WHERE csc_profile_code = p_profile_code
           AND csc_inst_code = p_instcode
      ORDER BY csc_start_from DESC;

   PROCEDURE lp_acct_srno (
      p_tmp_acct     IN       VARCHAR2,
      p_max_length   IN       NUMBER,
      p_profile_code IN       VARCHAR2,
      p_srno         OUT      VARCHAR2,
      p_errmsg       OUT      VARCHAR2
   )
   IS
      v_ctrlnumb        NUMBER;
      v_max_serial_no   NUMBER;
   BEGIN
      p_errmsg := 'OK';
    DBMS_OUTPUT.put_line ('  STEP 1 ' ||p_tmp_acct);
      /*
      *   V_TMP_ACCT equals 'XXXX' when the account number construct don't have branch code.
      *   'XXXX' is used to fetch the SRNO when the account number construct don't have branch code.
      *   If branch is choosen in account number consturct then SRNO for that particular branch will be fetched.
      */
      IF p_tmp_acct IS NULL
      THEN
         v_tmp_acct := 'XXXX';
      ELSE
      DBMS_OUTPUT.put_line ('  STEP 01 ' ||p_tmp_acct);
         v_tmp_acct := p_tmp_acct;
         DBMS_OUTPUT.put_line ('  STEP 02 ' ||v_tmp_acct);
      END IF;

 DBMS_OUTPUT.put_line ('  STEP 2 ' ||v_tmp_acct);
      SELECT cac_ctrl_numb,
             SUBSTR (cac_max_serial_no,
                     1,
                     (SELECT csc_length
                        FROM CMS_SAVINGSACCT_CONSTRUCT
                       WHERE csc_profile_code = p_profile_code
                         AND csc_inst_code = p_instcode
                         AND csc_field_name = 'Serial Number')
                    )
        INTO v_ctrlnumb,
             v_max_serial_no
        FROM cms_acct_ctrl
       WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = p_instcode;

    DBMS_OUTPUT.put_line (v_ctrlnumb||'  STEP 3 ' ||v_max_serial_no);

      IF v_ctrlnumb > v_max_serial_no
      THEN
         p_errmsg := 'Maximum serial number reached';
         RETURN;
      END IF;

      p_srno := v_ctrlnumb;

      UPDATE cms_acct_ctrl
         SET cac_ctrl_numb = v_ctrlnumb + 1
       WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = p_instcode;

      IF SQL%ROWCOUNT = 0
      THEN
         p_errmsg := 'Error while updating serial no';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO cms_acct_ctrl
                     (cac_inst_code, cac_bran_code, cac_ctrl_numb,
                      cac_max_serial_no
                     )
              VALUES (1, v_tmp_acct, 2,
                      LPAD ('9', p_max_length, 9)
                     );

         v_ctrlnumb := 1;
         p_srno := v_ctrlnumb;
      WHEN OTHERS
      THEN
         p_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
   END  lp_acct_srno;

   PROCEDURE lp_acct_chkdig ( p_tmpacct IN VARCHAR2, p_checkdig OUT NUMBER)
   IS
       v_ceilable_sum   NUMBER     := 0;
      v_ceiled_sum     NUMBER;
      v_temp_acct      NUMBER; --updated by Ramesh.A on 14/03/2012
      v_len_acct       NUMBER (3);
      v_res            NUMBER (3);
      v_mult_ind       NUMBER (1);
      v_dig_sum        NUMBER (2);
      v_dig_len        NUMBER (1);
   BEGIN
	DBMS_OUTPUT.put_line ('In check digit gen logic');
      v_temp_acct := p_tmpacct;
      v_len_acct := LENGTH (v_temp_acct);
      v_mult_ind := 2;

      FOR i IN REVERSE 1 .. v_len_acct
      LOOP

         v_res := SUBSTR (v_temp_acct, i, 1) * v_mult_ind;
         v_dig_len := LENGTH (v_res);

         IF v_dig_len = 2
         THEN
            v_dig_sum := SUBSTR (v_res, 1, 1) + SUBSTR (v_res, 2, 1);
         ELSE
            v_dig_sum := v_res;
         END IF;

         v_ceilable_sum := v_ceilable_sum + v_dig_sum;

         IF v_mult_ind = 2
         THEN
            --IF 2
            v_mult_ind := 1;
         ELSE
            --Else of If 2
            v_mult_ind := 2;
         END IF;
         --End of IF 2
      END LOOP;

      v_ceiled_sum := v_ceilable_sum;

      IF MOD (v_ceilable_sum, 10) != 0
      THEN
         LOOP
            v_ceiled_sum := v_ceiled_sum + 1;
            EXIT WHEN MOD (v_ceiled_sum, 10) = 0;
         END LOOP;
      END IF;
      p_checkdig := v_ceiled_sum - v_ceilable_sum;


   EXCEPTION
   WHEN OTHERS THEN
         v_errmsg :=
               'Error while selecting DIG_SUM'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END  lp_acct_chkdig;

--EN    LOCAL PROCEDURES
BEGIN
   --<< MAIN BEGIN>>

   --Sn find profile code attached to cardtype
   BEGIN
      SELECT cpc_profile_code,CPC_ACCT_PROD_PREFIX
        INTO v_profile_code,v_prod_prefix
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_instcode AND cpc_prod_code = p_prod_code and cpc_card_type=p_prod_cattype;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :='Profile code not defined for product code ' || v_prod_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting applcode from applmast'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En find profile code attached to cardtype

   --Sn find account number construct details based on profile code
   BEGIN
      v_loop_cnt := 0;

      FOR i IN c (v_profile_code)
      LOOP
         v_loop_cnt := v_loop_cnt + 1;

         SELECT i.csc_profile_code,
                i.csc_field_name,
                i.csc_start_from,
                i.csc_length,
                i.csc_start,
                i.csc_tot_length
           INTO v_table_acct_construct (v_loop_cnt).csc_profile_code,
                v_table_acct_construct (v_loop_cnt).csc_field_name,
                v_table_acct_construct (v_loop_cnt).csc_start_from,
                v_table_acct_construct (v_loop_cnt).csc_length,
                v_table_acct_construct (v_loop_cnt).csc_start,
                v_table_acct_construct (v_loop_cnt).csc_tot_length
           FROM DUAL;

      END LOOP;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting profile detail from profile mast '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En find account number construct details based on profile code

   --Sn built the account number gen logic based on the value (except serial no)
   BEGIN
      v_loop_max_cnt := v_table_acct_construct.COUNT;
      v_tmp_acct_no := NULL;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         DBMS_OUTPUT.put_line (   'IFIELD NAME '
                               || i
                               || v_table_acct_construct (i).csc_field_name
                              );
         IF v_table_acct_construct (i).csc_field_name = 'Branch'
         THEN
            v_table_acct_construct (i).csc_field_value :=
               LPAD (SUBSTR (TRIM (p_branc_code),
                             v_table_acct_construct (i).csc_start,
                             v_table_acct_construct (i).csc_length
                            ),
                     v_table_acct_construct (i).csc_length,
                     '0'
                    );
	 ELSIF v_table_acct_construct (i).csc_field_name = 'Product Prefix'  -- Added by Ramesh.A on 09/032012
         THEN
             /*BEGIN
             select CPC_ACCT_PROD_PREFIX -- Modified by Trivikram on 06 June 2012 , In Acccount construction we needs to use Account Product Category Prefix
             INTO v_prod_prefix
             FROM cms_prod_cattype
             where CPC_PROD_CODE = p_prod_code and CPC_CARD_TYPE=p_prod_cattype and cpc_inst_code=p_instcode;
             exception
              when no_data_found then
                v_errmsg  := 'Data not available in cms_prod_cattype  for product' ||p_prod_code||'and product category type' ||
                        p_prod_cattype;
                RAISE EXP_REJECT_RECORD;
              when others then
              v_errmsg  := 'Error while selecting Account Product Category Prefix from cms_prod_cattype ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;*/

              -- Added by Trivkram on 08 June 2012 , If not configure Account Product Category Prefix with Product Category level it will take from Instistute level

             IF v_prod_prefix IS NULL THEN
              BEGIN
                 SELECT CIP_PARAM_VALUE
                 INTO v_prod_prefix
                 FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = p_instcode AND
                     CIP_PARAM_KEY = 'ACCTPRODCATPREFIX';
                EXCEPTION
                WHEN OTHERS THEN
                v_errmsg  := 'Error while selecting Account Product Category Prefix from CMS_INST_PARAM ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;
            END IF;


            v_table_acct_construct (i).csc_field_value :=
               LPAD (SUBSTR (TRIM (v_prod_prefix),
                             v_table_acct_construct (i).csc_start,
                             v_table_acct_construct (i).csc_length
                            ),
                     v_table_acct_construct (i).csc_length,
                     '0'
                    );
         ELSIF v_table_acct_construct (i).csc_field_name = 'Check Digit'
         THEN
            v_chk_index := 1;


         ELSE
            IF v_table_acct_construct (i).csc_field_name <> 'Serial Number'
            THEN
               v_errmsg :=
                     'Saving Account Number construct '
                  || v_table_acct_construct (i).csc_field_name
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
                'Error from Saving Account gen process ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En built the account number gen logic based on the value
   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      DBMS_OUTPUT.put_line ('  PRINT loop indicator ' || i);
      DBMS_OUTPUT.put_line (   'PRINT START FROM  I  '
                            || v_table_acct_construct (i).csc_start_from
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD NAME I  '
                            || v_table_acct_construct (i).csc_field_name
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD VALUE I  '
                            || v_table_acct_construct (i).csc_field_value
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD LENGTH I  '
                            || v_table_acct_construct (i).csc_length
                           );
   END LOOP;
   --Sn generate the serial no
   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      --<< i loop >>
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         --<< j  loop >>
         DBMS_OUTPUT.put_line (   ' j start from '
                               || v_table_acct_construct (j).csc_start_from
                              );
         IF     v_table_acct_construct (j).csc_start_from = i
            AND v_table_acct_construct (j).csc_field_name <> 'Serial Number'
         THEN
            DBMS_OUTPUT.put_line (   'FIELD VALUE I '
                                  || v_table_acct_construct (j).csc_field_value
                                 );
            v_tmp_acct_no :=
                   v_tmp_acct_no || v_table_acct_construct (j).csc_field_value;
	 DBMS_OUTPUT.put_line (v_tmp_acct_no);
            EXIT;
         END IF;
      END LOOP;                                            --<< j  end loop >>
   END LOOP;                                                --<< i end loop >>

   --Sn get  index value of serial no from PL/SQL table
   FOR i IN 1 .. v_table_acct_construct.COUNT
   LOOP
      IF v_table_acct_construct (i).csc_field_name = 'Serial Number'
      THEN
         v_serial_index := i;
      END IF;
   END LOOP;

   --En get  index value of serial no from PL/SQL table
   IF v_serial_index IS NOT NULL
   THEN
      v_serial_maxlength :=
                           v_table_acct_construct (v_serial_index).csc_length;
   	DBMS_OUTPUT.put_line ('SERIAL MAX LENGTH ' || v_serial_maxlength);

    DBMS_OUTPUT.put_line (v_serial_maxlength||'v_tmp_acct_no' || v_tmp_acct_no);
     BEGIN
      lp_acct_srno ( v_tmp_acct_no,
                    v_serial_maxlength,
                    v_profile_code,
                    v_serial_no,
                    v_errmsg
                   );
      EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while calling lp_acct_srno ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;

      v_table_acct_construct (v_serial_index).csc_field_value :=
         LPAD (SUBSTR (TRIM (v_serial_no),
                       v_table_acct_construct (v_serial_index).csc_start,
                       v_table_acct_construct (v_serial_index).csc_length
                      ),
               v_table_acct_construct (v_serial_index).csc_length,
               '0'
              );
      DBMS_OUTPUT.put_line
                       (   'SERIAL NO '
                        || v_table_acct_construct (v_serial_index).csc_field_value
                       );
   END IF;

   --En generate the serial no
   v_tmp_acct_no := NULL;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_acct_construct (j).csc_start_from = i
         THEN
            v_tmp_acct_no :=
                    v_tmp_acct_no || v_table_acct_construct (j).csc_field_value;
            EXIT;
         END IF;
      END LOOP;
   END LOOP;

   --En generate temp account number for check digit
   DBMS_OUTPUT.put_line ('V_TMP_ACCT_NO' || v_tmp_acct_no);

   --Sn generate for check digit
   /*
   *   V_CHK_INDEX Value equals '1' only when check digit is selected in Account Construct
   *   LP_ACCT_CHKDIG is called only when V_CHK_INDEX value is '1'
   */

   IF v_chk_index = 1
   THEN
      lp_acct_chkdig (v_tmp_acct_no, v_check_digit);
      p_acct_num := v_tmp_acct_no || v_check_digit; -- || v_profile_code;  -- Commented by Ramesh.A on 29/02/12
DBMS_OUTPUT.put_line (p_acct_num);
   ELSE
      p_acct_num := v_tmp_acct_no; -- || v_profile_code;  -- Commented by Ramesh.A on 29/02/12
DBMS_OUTPUT.put_line (p_acct_num);
   END IF;
--En generate for check digit
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      p_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      p_errmsg :=
           'Error from Saving Account Number Construct ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error