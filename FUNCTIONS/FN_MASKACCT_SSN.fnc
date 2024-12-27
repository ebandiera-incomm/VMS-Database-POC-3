CREATE OR REPLACE FUNCTION VMSCMS.fn_maskacct_ssn( p_inst_code IN   NUMBER,
                                            p_user_acct IN VARCHAR2,
                                            p_user_pin      IN   NUMBER
                                            )
RETURN VARCHAR2 deterministic
AS

/**************************************************
     * Created Date                 : 01/FEB/2012.
     * Created By                   : Sagar More.
     * Purpose                      : Account Number/SSN Masking.
     * Last Modification Done by    : Dhiraj M. G.
     * Last Modification Date       : 13-Feb-2012
     * Mofication Reason            : length check removed for account number
     * Build Number                 : RI0001B
     
     * Modified By                  :  Pankaj S.
     * Modified Date                :  28-Mar-2013
     * Modified Reason              :  Mantis ID-10744
     * Reviewer                     :  Dhiraj
     * Reviewed Date                : 
     * Build Number                 :  CSR3.5.1_RI0024_B0013 
	 
	 * Modified By                  :  Siva kumar M
     * Modified Date                :  22-Mar-2016
     * Modified Reason              :  SSN Encryption
     * Reviewer                     :  Pankaj
     * Reviewed Date                : 22-Mar-2016
     * Build Number                 :  VMSGPRHOST_4.0_B0006
     
 **************************************************/

/**********Account No Masking Function**************
 * Example
 * Clear acct :- 1234567890123456
 * Masked acct:-  ************3456.
*****************************************************/

   errmsg           varchar2(200);
   v_acct           VARCHAR (40);
   acct             VARCHAR2 (40);  --size modified to 40 for 10744
   v_data_display   VARCHAR (10);
   v_encrypt        VARCHAR (40);  --size modified to 40 for 10744
   v_last           VARCHAR (10);
   v_length         NUMBER (30);
   v_masking_char   VARCHAR2 (10);
   acct_not_found    EXCEPTION;
   v_no             number(2);  -- Added by Yogesh on

BEGIN
   acct := p_user_acct;

   IF acct IS NULL --or length(acct) <= 4
   THEN
   acct:=' ';
    return acct;
   end if;
   if p_user_pin=0 then
      v_data_display:='N';
   else


--Sn Get the Masking Access value from user mast for the perticular userpin--
   BEGIN

      SELECT cum_usermask_flag
        INTO v_data_display
        FROM CMS_USERDETL_MAST,CMS_USER_INST
       WHERE cui_inst_code = p_inst_code
       and   cum_user_code = cui_user_code
       and   cum_user_code = p_user_pin;


   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         errmsg := 'No Data for the user pin' || p_user_pin;
         RETURN errmsg;
      WHEN OTHERS
      THEN
         errmsg := 'Error ' || p_user_pin || SUBSTR (SQLERRM, 1, 30);
         RETURN errmsg;
   end;
  end if;

--Sn Get the Masking Char from Inst param--
   BEGIN
      SELECT LPAD (cip_param_value, 10, cip_param_value)
        INTO v_masking_char
        FROM CMS_INST_PARAM
       WHERE cip_param_key = 'MASKINGCHAR' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_masking_char := '**********';
      WHEN OTHERS
      THEN
         errmsg := 'Error' || SUBSTR (SQLERRM, 1, 35);
         RETURN errmsg;
   END;



  IF v_data_display = 'Y'
  then

  v_acct := acct;

  ELSIF v_data_display = 'N'
  then
       v_no :=4;
       v_last := SUBSTR  (acct,-4, v_no);
       v_length := (LENGTH (acct) - v_no);
       v_encrypt := TRANSLATE (SUBSTR (acct, 1, v_length),'0123456789',v_masking_char);

       v_acct := v_encrypt || v_last;

  else

      errmsg := 'Invalid flag value '||v_data_display||' for account '||acct;
      return errmsg;

  End if;


   RETURN v_acct;
EXCEPTION
   WHEN acct_not_found
   THEN
      RETURN errmsg;
   WHEN OTHERS
   THEN
   errmsg := 'Main Exception '||substr(sqlerrm,1,100);
      RETURN errmsg;
END;
/
show error