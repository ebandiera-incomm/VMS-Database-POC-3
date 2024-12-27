CREATE OR REPLACE PROCEDURE VMSCMS.SP_ACCOUNT_CONSTRUCT_26112012(
   prm_instcode     IN       NUMBER,
   prm_branc_code   IN       VARCHAR2,
   prm_prod_code    IN       VARCHAR2,
   prm_lupduser     IN       NUMBER,
   PROD_CATTYPE     IN       NUMBER, --product category type, Added Ramkumar.MK
   prm_acct_num     OUT      VARCHAR2,
   prm_errmsg       OUT      VARCHAR2
)
AS

    /*************************************************
     * Created Date     :  NA
     * Created By       :  NA
     * PURPOSE          :  NA
     * Modified By      :  Saravanakumar
     * Modified Date    :  16-Nov-2012
     * Modified Reason  :  Added for update clause while selecting contorl number
     * Reviewer         :  Sachin
     * Reviewed Date    :  16-Nov-2012
     * Release Number   :  CMS3.5.1_RI0021.1

 *************************************************/

   v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
   v_errmsg                 VARCHAR2 (500);
   v_acct_id                cms_acct_mast.cam_acct_id%TYPE;
   exp_reject_record        EXCEPTION;
   v_loop_cnt               NUMBER                                  DEFAULT 0;
   v_loop_max_cnt           NUMBER;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_tmp_acct_no            cms_appl_pan.cap_acct_no%TYPE;
   v_chk_index              NUMBER (1);
   v_serial_index           NUMBER;
   v_serial_maxlength       NUMBER (2);
   v_serial_no              NUMBER;
   v_check_digit            NUMBER;
   --v_tmp_acct               cms_appl_mast.cam_appl_bran%TYPE;
   v_tmp_acct               VARCHAR2 (16);
   t_cac_profile_code       cms_acct_construct.cac_profile_code%TYPE;
   t_cac_field_name         cms_acct_construct.cac_field_name%TYPE;
   t_cac_start_from         cms_acct_construct.cac_start_from%TYPE;
   t_cac_start              cms_acct_construct.cac_start%TYPE;
   t_cac_length             cms_acct_construct.cac_length%TYPE;
   t_cac_field_value        VARCHAR2 (30);
   t_cac_tot_length         cms_acct_construct.cac_tot_length%TYPE;
   v_prod_prefix            varchar(3);

   resource_busy exception; -- SN: 20121116
   pragma exception_init (resource_busy,-54); -- SN: 20121116


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
      SELECT   cac_profile_code, cac_field_name, cac_start_from,
               cac_length, cac_start, cac_tot_length
          INTO t_cac_profile_code, t_cac_field_name, t_cac_start_from,
               t_cac_length, t_cac_start, t_cac_tot_length
          FROM cms_acct_construct
         WHERE cac_profile_code = p_profile_code
           AND cac_inst_code = prm_instcode
      ORDER BY cac_start_from DESC;

   PROCEDURE lp_acct_srno (
      l_instcode     IN       NUMBER,
      l_lupduser     IN       NUMBER,
      l_tmp_acct     IN       VARCHAR2,
      l_max_length   IN       NUMBER,
      l_srno         OUT      VARCHAR2,
      l_errmsg       OUT      VARCHAR2
   )
   IS
      v_ctrlnumb        NUMBER;
      v_max_serial_no   NUMBER;


   BEGIN
      l_errmsg := 'OK';

      /*
      *   V_TMP_ACCT equals 'XXXX' when the account number construct don't have branch code.
      *   'XXXX' is used to fetch the SRNO when the account number construct don't have branch code.
      *   If branch is choosen in account number consturct then SRNO for that particular branch will be fetched.
      */
      IF l_tmp_acct IS NULL
      THEN
         v_tmp_acct := 'XXXX';
      ELSE
         v_tmp_acct := l_tmp_acct;
      END IF;

	  -- SN: 20121116: TO HANDLE REQUEST FROM DIFFERANT SOURCES
	  BEGIN


      SELECT cac_ctrl_numb,
             SUBSTR (cac_max_serial_no,
                     1,
                     (SELECT cac_length
                        FROM cms_acct_construct
                       WHERE cac_profile_code =
                                (SELECT cpm_profile_code
                                   FROM cms_prod_mast
                                  WHERE cpm_prod_code = prm_prod_code
                                    AND cpm_inst_code = prm_instcode)
                         AND cac_inst_code = prm_instcode
                         AND cac_field_name = 'Serial Number')
                    )
        INTO v_ctrlnumb,
             v_max_serial_no
        FROM cms_acct_ctrl
       WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = prm_instcode
        for update nowait;--Added by Saravanakumar on 16-Nov-2012 to avoid duplicate account number


	EXCEPTION

		WHEN resource_busy then

			l_errmsg := 'PLEASE TRY AFTER SOME TIME' ;
			 RETURN;

		WHEN others THEN

		    l_errmsg := SUBSTR(SQLERRM, 1, 100);
			RETURN;
	END;

	-- EN: 20121116: TO HANDLE REQUEST FROM DIFFERANT SOURCES

    --   IF v_ctrlnumb > v_max_serial_no
      IF v_ctrlnumb > LPAD ('9', l_max_length, 9) --Modified by Ramkumar.Mk, check the condition max serial number length
      THEN
         l_errmsg := 'Maximum serial number reached';
         RETURN;
      END IF;

      l_srno := v_ctrlnumb;

      UPDATE cms_acct_ctrl
         SET cac_ctrl_numb = v_ctrlnumb + 1
       WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = prm_instcode;

      IF SQL%ROWCOUNT = 0
      THEN
         l_errmsg := 'Error while updating serial no';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO cms_acct_ctrl
                     (cac_inst_code, cac_bran_code, cac_ctrl_numb,
                      cac_max_serial_no
                     )
              VALUES (1, v_tmp_acct, 2,
                      LPAD ('9', l_max_length, 9)
                     );

         v_ctrlnumb := 1;
         l_srno := v_ctrlnumb;
      WHEN OTHERS
      THEN
         l_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
   END;


   PROCEDURE lp_acct_chkdig (                              --l_prfx IN NUMBER,
                             -- l_prod_prefix IN VARCHAR2,
                             -- l_srno IN VARCHAR2,
                             l_tmpacct IN VARCHAR2, l_checkdig OUT NUMBER)
   IS
      ceilable_sum   NUMBER     := 0;
      ceiled_sum     NUMBER;
      temp_acct      NUMBER;
      len_acct       NUMBER (3);
      res            NUMBER (3);
      mult_ind       NUMBER (1);
      dig_sum        NUMBER (2);
      dig_len        NUMBER (1);
   BEGIN
      DBMS_OUTPUT.put_line ('In check digit gen logic');
      --temp_pan    := l_prfx||l_prod_prefix||l_srno ;
      --len_pan        := LENGTH(temp_pan);
      temp_acct := l_tmpacct;
      len_acct := LENGTH (temp_acct);
      mult_ind := 2;

      FOR i IN REVERSE 1 .. len_acct
      LOOP
         res := SUBSTR (temp_acct, i, 1) * mult_ind;
         dig_len := LENGTH (res);

         IF dig_len = 2
         THEN
            dig_sum := SUBSTR (res, 1, 1) + SUBSTR (res, 2, 1);
         ELSE
            dig_sum := res;
         END IF;

         ceilable_sum := ceilable_sum + dig_sum;

         IF mult_ind = 2
         THEN
            --IF 2
            mult_ind := 1;
         ELSE
            --Else of If 2
            mult_ind := 2;
         END IF;                                                 --End of IF 2
      END LOOP;

      ceiled_sum := ceilable_sum;

      IF MOD (ceilable_sum, 10) != 0
      THEN
         LOOP
            ceiled_sum := ceiled_sum + 1;
            EXIT WHEN MOD (ceiled_sum, 10) = 0;
         END LOOP;
      END IF;

      l_checkdig := ceiled_sum - ceilable_sum;
   --dbms_output.put_line('FROM LOCAL CHK GEN---->'||l_checkdig);
   END;
--EN    LOCAL PROCEDURES
BEGIN
   --<< MAIN BEGIN>>

   --Sn find profile code attached to cardtype
   BEGIN
      SELECT cpm_profile_code
        INTO v_profile_code
        FROM cms_prod_mast
       WHERE cpm_inst_code = prm_instcode AND cpm_prod_code = prm_prod_code;
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
                               || v_table_acct_construct (i).cac_field_name
                              );

         IF v_table_acct_construct (i).cac_field_name = 'Branch'
         THEN
         DBMS_OUTPUT.put_line(prm_branc_code||'=='||v_table_acct_construct (i).cac_start||'=='||v_table_acct_construct (i).cac_length);
            v_table_acct_construct (i).cac_field_value :=
               LPAD (SUBSTR (TRIM (prm_branc_code),
                             v_table_acct_construct (i).cac_start,
                             v_table_acct_construct (i).cac_length
                            ),
                     v_table_acct_construct (i).cac_length,
                     '0'
                    );

             /*************************************************

                * PURPOSE          :  added Product Prefix in Account Construct on Profile
                * Modified By      :  Ramkumar.MK
                * Modified Date    :  08-March-2012
                * Modified Reason  :  Account Construct Prefix
                * Reviewer         :  Saravanakumar
                * Reviewed Date    :  08_Mar-2012
 *          ************************************************/


         ELSIF v_table_acct_construct (i).cac_field_name = 'Product Prefix'
         THEN
             BEGIN
             select CPC_ACCT_PROD_PREFIX -- Modified by Trivikram on 06 June 2012 , In Acccount construction we needs to use Account Product Category Prefix
             INTO v_prod_prefix
             FROM cms_prod_cattype
             where CPC_PROD_CODE = prm_prod_code and CPC_CARD_TYPE=PROD_CATTYPE;
             exception
               when no_data_found then
                v_errmsg  := 'Data not available in cms_prod_cattype for product code' ||
                        prm_prod_code;
                RAISE EXP_REJECT_RECORD;
                when others then
                 v_errmsg  := 'Error while selecting Account Product Category Prefix from cms_prod_cattype ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;

             -- Added by Trivkram on 08 June 2012 , If not configure Account Product Category Prefix with Product Category level it will take from Instistute level

             IF v_prod_prefix IS NULL THEN
              BEGIN
                 SELECT CIP_PARAM_VALUE
                 INTO v_prod_prefix
                 FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = prm_instcode AND
                     CIP_PARAM_KEY = 'ACCTPRODCATPREFIX';
                EXCEPTION
                 when no_data_found then
                  v_errmsg  := 'Data not available in CMS_INST_PARAM for paramkey ACCTPRODCATPREFIX';
                   RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                v_errmsg  := 'Error while selecting Account Product Category Prefix from CMS_INST_PARAM ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;
            END IF;



DBMS_OUTPUT.put_line('field valueooo= '||v_table_acct_construct (i).cac_field_value);
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
                'Error from Account gen process ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En built the account number gen logic based on the value
   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      DBMS_OUTPUT.put_line ('  PRINT loop indicator ' || i);
      DBMS_OUTPUT.put_line (   'PRINT START FROM  I  '
                            || v_table_acct_construct (i).cac_start_from
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD NAME I  '
                            || v_table_acct_construct (i).cac_field_name
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD VALUE I  '
                            || v_table_acct_construct (i).cac_field_value
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD LENGTH I  '
                            || v_table_acct_construct (i).cac_length
                           );
   END LOOP;

   --Sn generate the serial no
   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      --<< i loop >>
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
       DBMS_OUTPUT.put_line ( v_table_acct_construct (j).cac_field_name||'loop error valie=='||v_table_acct_construct (j).cac_field_value);

         --<< j  loop >>
         DBMS_OUTPUT.put_line (   ' j start from '
                               || v_table_acct_construct (j).cac_start_from
                              );

         IF     v_table_acct_construct (j).cac_start_from = i
            AND v_table_acct_construct (j).cac_field_name <> 'Serial Number'
         THEN
            DBMS_OUTPUT.put_line (   'FIELD VALUE I '
                                  || v_table_acct_construct (j).cac_field_value
                                 );
            v_tmp_acct_no :=
                   v_tmp_acct_no || v_table_acct_construct (j).cac_field_value;
            DBMS_OUTPUT.put_line (v_tmp_acct_no);
            EXIT;
         END IF;
      END LOOP;                                            --<< j  end loop >>
   END LOOP;                                                --<< i end loop >>

   --Sn get  index value of serial no from PL/SQL table
   FOR i IN 1 .. v_table_acct_construct.COUNT
   LOOP
      IF v_table_acct_construct (i).cac_field_name = 'Serial Number'
      THEN
         v_serial_index := i;
      END IF;
   END LOOP;

   --En get  index value of serial no from PL/SQL table
   IF v_serial_index IS NOT NULL
   THEN
      v_serial_maxlength :=
                           v_table_acct_construct (v_serial_index).cac_length;
      DBMS_OUTPUT.put_line ('SERIAL MAX LENGTH ' || v_serial_maxlength);
       DBMS_OUTPUT.put_line ('v_tmp_acct_no ' || v_tmp_acct_no||'v_serial_maxlength ' || v_serial_maxlength||'v_serial_no ' || v_serial_no);
      lp_acct_srno (prm_instcode,
                    prm_lupduser,
                    v_tmp_acct_no,
                    v_serial_maxlength,
                    v_serial_no,
                    v_errmsg
                   );
DBMS_OUTPUT.put_line ('lp_acct_srno rr ' || v_errmsg);
      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;

      v_table_acct_construct (v_serial_index).cac_field_value :=
         LPAD (SUBSTR (TRIM (v_serial_no),
                       v_table_acct_construct (v_serial_index).cac_start,
                       v_table_acct_construct (v_serial_index).cac_length
                      ),
               v_table_acct_construct (v_serial_index).cac_length,
               '0'
              );
      DBMS_OUTPUT.put_line
                       (   'SERIAL NO '
                        || v_table_acct_construct (v_serial_index).cac_field_value
                       );
   END IF;

   --En generate the serial no
   DBMS_OUTPUT.put_line ('V_TMP_ACCT_no' || v_tmp_acct_no);
   DBMS_OUTPUT.put_line ('V_TMP_ACCT' || v_tmp_acct);
   v_tmp_acct_no := NULL;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_acct_construct (j).cac_start_from = i
         THEN
            v_tmp_acct_no :=
                  v_tmp_acct_no || v_table_acct_construct (j).cac_field_value;
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
      prm_acct_num := v_tmp_acct_no || v_check_digit;
      DBMS_OUTPUT.put_line (prm_acct_num);
   ELSE
      prm_acct_num := v_tmp_acct_no;
      DBMS_OUTPUT.put_line (prm_acct_num);
   END IF;
--En generate for check digit
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg :=
           'Error from Account Number Construct ' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERRORS;


