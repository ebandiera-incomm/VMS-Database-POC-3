CREATE OR REPLACE PROCEDURE VMSCMS.sp_prodcattypefee_update (
   p_cpf_inst_code           IN       NUMBER,
   p_cpf_prod_code           IN       VARCHAR2,
   p_cpf_card_type           IN       NUMBER,
   p_cpf_fee_type            IN       NUMBER,
   p_cpf_fee_code            IN       NUMBER,
   p_cpf_crgl_catg           IN       VARCHAR2,
   p_cpf_crgl_code           IN       VARCHAR2,
   p_cpf_crsubgl_code        IN       VARCHAR2,
   p_cpf_cracct_no           IN       VARCHAR2,
   p_cpf_drgl_catg           IN       VARCHAR2,
   p_cpf_drgl_code           IN       VARCHAR2,
   p_cpf_drsubgl_code        IN       VARCHAR2,
   p_cpf_dracct_no           IN       VARCHAR2,
   p_cpf_flow_source         IN       VARCHAR2,
   p_cpf_ins_user            IN       NUMBER,
   p_cpf_ins_date            IN       DATE,
   p_cpf_lupd_user           IN       NUMBER,
   p_cpf_lupd_date           IN       DATE,
   p_cpf_st_crgl_catg        IN       VARCHAR2,
   p_cpf_st_crgl_code        IN       VARCHAR2,
   p_cpf_st_crsubgl_code     IN       VARCHAR2,
   p_cpf_st_cracct_no        IN       VARCHAR2,
   p_cpf_st_drgl_catg        IN       VARCHAR2,
   p_cpf_st_drgl_code        IN       VARCHAR2,
   p_cpf_st_drsubgl_code     IN       VARCHAR2,
   p_cpf_st_dracct_no        IN       VARCHAR2,
   p_cpf_cess_crgl_catg      IN       VARCHAR2,
   p_cpf_cess_crgl_code      IN       VARCHAR2,
   p_cpf_cess_crsubgl_code   IN       VARCHAR2,
   p_cpf_cess_cracct_no      IN       VARCHAR2,
   p_cpf_cess_drgl_catg      IN       VARCHAR2,
   p_cpf_cess_drgl_code      IN       VARCHAR2,
   p_cpf_cess_drsubgl_code   IN       VARCHAR2,
   p_cpf_cess_dracct_no      IN       VARCHAR2,
   p_cpf_st_calc_flag        IN       NUMBER,
   p_cpf_cess_calc_flag      IN       NUMBER,
   p_cpf_valid_from_old      IN       DATE,
   p_cpf_valid_to_old        IN       DATE,
   p_cpf_valid_from_new      IN       DATE,
   p_cpf_valid_to_new        IN       DATE,
   p_CPF_PRODCATTYPE_ID      IN       NUMBER,
   p_err                     OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 16/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Update prod cattype fee  after checking all condition
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_error                VARCHAR2 (100);
   v_cpw_fee_code_count   NUMBER;
   v_message              NUMBER;
BEGIN
   p_err := 'OK';
   --this procedure is used for validation, all type of validation is check in this proc
   sp_prodcattypefees_validation (p_cpf_inst_code,
                                  p_cpf_prod_code,
                                  p_cpf_card_type,
                                  p_cpf_fee_type,
                                  p_cpf_fee_code,
                                  p_cpf_valid_from_old,
                                  p_cpf_valid_to_old,
                                  p_cpf_valid_from_new,
                                  p_cpf_valid_to_new,
								  p_CPF_PRODCATTYPE_ID,
                                  v_error,
                               --   v_cpw_fee_code_count,
                                  v_message
                                 );
   DBMS_OUTPUT.put_line (   'all the out param from proc'
                         || v_error
                         || ' '
                        -- || v_cpw_fee_code_count
                         || ' '
                         || v_message
                        );

   IF --    v_cpw_fee_code_count = 0
      --AND 
	  v_message = 0 AND v_error = 'OK'
-- if there is no fee attached with the waiver, No same fee attached between the date range and No error, then only we will allowed to update
   THEN
      IF (    p_cpf_valid_from_old <= SYSDATE
          AND p_cpf_valid_to_old >= SYSDATE
          AND p_cpf_valid_to_new >= SYSDATE
         )
      THEN
         UPDATE cms_prodcattype_fees
            SET cpf_valid_to =
                        TO_DATE (p_cpf_valid_to_new, 'DD/MM/YYYY HH:MI:SS AM')
          WHERE CPF_PRODCATTYPE_ID = p_CPF_PRODCATTYPE_ID;
		  --cpf_inst_code = p_cpf_inst_code
           -- AND cpf_fee_type = p_cpf_fee_type
           -- AND cpf_prod_code = p_cpf_prod_code
            --AND cpf_card_type = p_cpf_card_type
           -- AND cpf_fee_code = p_cpf_fee_code
            --AND cpf_valid_from =
                    --  TO_DATE (p_cpf_valid_from_old, 'DD/MM/YYYY HH:MI:SS AM')
           -- AND cpf_valid_to =
                       -- TO_DATE (p_cpf_valid_to_old, 'DD/MM/YYYY HH:MI:SS AM'); 

         IF SQL%NOTFOUND
         THEN
            p_err := 'Update is not Done Record Not Found';
         END IF;
      ELSIF (    p_cpf_valid_from_old > SYSDATE
             AND p_cpf_valid_to_old > SYSDATE
             AND p_cpf_valid_from_new > SYSDATE
             AND p_cpf_valid_to_new > SYSDATE
            )
      THEN
         UPDATE cms_prodcattype_fees
            SET cpf_valid_to =
                        TO_DATE (p_cpf_valid_to_new, 'DD/MM/YYYY HH:MI:SS AM'),
                cpf_valid_from =
                      TO_DATE (p_cpf_valid_from_new, 'DD/MM/YYYY HH:MI:SS AM'),
                cpf_crgl_catg = p_cpf_crgl_catg,
                cpf_crgl_code = p_cpf_crgl_code,
                cpf_crsubgl_code = p_cpf_crsubgl_code,
                cpf_cracct_no = p_cpf_cracct_no,
                cpf_drgl_catg = p_cpf_drgl_catg,
                cpf_drgl_code = p_cpf_drgl_code,
                cpf_drsubgl_code = p_cpf_drsubgl_code,
                cpf_dracct_no = p_cpf_dracct_no,
                cpf_st_crgl_catg = p_cpf_st_crgl_catg,
                cpf_st_crgl_code = p_cpf_st_crgl_code,
                cpf_st_crsubgl_code = p_cpf_st_crsubgl_code,
                cpf_st_cracct_no = p_cpf_st_cracct_no,
                cpf_st_drgl_catg = p_cpf_st_drgl_catg,
                cpf_st_drgl_code = p_cpf_st_drgl_code,
                cpf_st_drsubgl_code = p_cpf_st_drsubgl_code,
                cpf_st_dracct_no = p_cpf_st_dracct_no,
                cpf_cess_crgl_catg = p_cpf_cess_crgl_catg,
                cpf_cess_crgl_code = p_cpf_cess_crgl_code,
                cpf_cess_crsubgl_code = p_cpf_cess_crsubgl_code,
                cpf_cess_cracct_no = p_cpf_cess_cracct_no,
                cpf_cess_drgl_catg = p_cpf_cess_drgl_catg,
                cpf_cess_drgl_code = p_cpf_cess_drgl_code,
                cpf_cess_drsubgl_code = p_cpf_cess_drsubgl_code,
                cpf_cess_dracct_no = p_cpf_cess_dracct_no,
                cpf_st_calc_flag = p_cpf_st_calc_flag,
                cpf_cess_calc_flag = p_cpf_cess_calc_flag
          WHERE CPF_PRODCATTYPE_ID = p_CPF_PRODCATTYPE_ID;
		  
		  --cpf_inst_code = p_cpf_inst_code
            --AND cpf_fee_type = p_cpf_fee_type
            --AND cpf_prod_code = p_cpf_prod_code
            --AND cpf_card_type = p_cpf_card_type
            --AND cpf_fee_code = p_cpf_fee_code
            --AND cpf_valid_from =
                 --     TO_DATE (p_cpf_valid_from_old, 'DD/MM/YYYY HH:MI:SS AM')
            --AND cpf_valid_to =
                  --      TO_DATE (p_cpf_valid_to_old, 'DD/MM/YYYY HH:MI:SS AM');

         IF SQL%NOTFOUND
         THEN
            p_err := 'Update is not Done Record Not Found';
         END IF;
      ELSE
         p_err := 'Date range Is not Proper';
      END IF;
------------------------------------------------------------------------------------------------------------
  /* ELSIF    --- v_cpw_fee_code_count <> 0
        -- AND 
		 v_error =
                'OK'
                    -- else for waiver is attached with the fee and date range
   THEN
      p_err :=
            'Waiver is Attached With The Fee '
         || p_cpf_fee_code
         || ' between the Date range '
         || p_cpf_valid_from_old
         || ' And '
         || p_cpf_valid_to_old;*/
   ELSIF v_message = 1 AND v_error = 'OK'
   THEN                    -- else for same date range condition checking fail
      p_err :=
            'Same fee is already attached with the Fee Type'
         || p_cpf_fee_type
         || 'between this date range From'
         || p_cpf_valid_from_new
         || 'and to'
         || p_cpf_valid_to_new;
   ELSIF v_error <> 'OK'
   THEN
      p_err := v_error;
   END IF;
EXCEPTION                                               --Main block Exception
   WHEN OTHERS
   THEN
      p_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;                                              --Main Begin Block Ends Here
/
SHOW ERRORS

