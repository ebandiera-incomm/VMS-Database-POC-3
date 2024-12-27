create or replace FUNCTION  VMSCMS.FN_GENERATE_PROXY (
	p_user        IN  NUMBER,	
	p_row_num    IN  NUMBER,
    p_seq_number        IN  NUMBER,
	p_proxy_length        IN  NUMBER,
	p_program_id        IN  NUMBER,
	p_check_digit_request        IN  VARCHAR2,
	p_program_id_request        IN  VARCHAR2
   )  RETURN VARCHAR2 IS
	
	v_check_digit          NUMBER(1);
    exp_reject_record EXCEPTION;	
	p_proxy_number          VARCHAR2(50);
	p_errmsg        VARCHAR2(50);
	v_SEQ_NUMBER          NUMBER(20);
	
	
/*************************************************
       * Modified by       : Santhosh
       * Modified Date     : 10-Jan-2022
       * Modified Reason   : VMS-5348
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R57_B0001
	   
*************************************************/	 
	
	
BEGIN
	p_errmsg := 'OK';
	v_SEQ_NUMBER :=  p_seq_number + p_row_num;
    IF p_program_id_request = 'Y' THEN
        BEGIN
            IF p_check_digit_request = 'Y' THEN
                SELECT
                    lpad(p_program_id, 4, 0)
                    || lpad(v_SEQ_NUMBER, p_proxy_length, 0)
                INTO p_proxy_number
                FROM
                    dual;

                sp_chk_digit_calc(p_proxy_number, v_check_digit);
                p_proxy_number := p_proxy_number || v_check_digit;
            ELSIF p_check_digit_request = 'N' THEN
                SELECT
                    lpad(p_program_id, 4, 0)
                    || lpad(v_SEQ_NUMBER, p_proxy_length, 0)
                INTO p_proxy_number
                FROM
                    dual;

            END IF;

        END;

    ELSIF p_program_id_request = 'N' THEN
        BEGIN
            SELECT
                lpad(v_SEQ_NUMBER, p_proxy_length, 0)
            INTO p_proxy_number
            FROM
                dual;

        EXCEPTION
            WHEN no_data_found THEN
				p_errmsg := 'Error while selecting cms_prxy_cntrl';
               RAISE exp_reject_record;
            WHEN OTHERS THEN
               p_errmsg := 'Error while selecting cms_prxy_cntrl'
                  || SUBSTR (SQLERRM, 1, 200);
                --DBMS_OUTPUT.PUT('Error while selecting cms_prxy_cntrl'|| SUBSTR (SQLERRM, 1, 200));
               RAISE exp_reject_record;
        END;
    ELSE
         p_errmsg := 'Invalid length for proxy number generation';
         --DBMS_OUTPUT.PUT('Invalid length for proxy number generation');         
                 RAISE exp_reject_record;
    END IF;

	
	IF p_errmsg = 'OK' THEN
		RETURN p_proxy_number;
	ELSE
	   RETURN NULL;
	END IF;

EXCEPTION
    WHEN exp_reject_record THEN
        p_errmsg := 'Error while Generating proxy.';
    WHEN OTHERS THEN
         p_errmsg := 'Error in function FN_GET_PROXY ' || SUBSTR (SQLERRM, 1, 200);
         --DBMS_OUTPUT.PUT('Error while updating CMS_ORDER_PROXY_RANGE '|| SUBSTR (SQLERRM, 1, 200)); 
        --RAISE;
		RETURN NULL;

END;
/
show error