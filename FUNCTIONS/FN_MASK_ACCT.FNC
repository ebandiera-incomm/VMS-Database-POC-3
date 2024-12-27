CREATE OR REPLACE FUNCTION FN_MASK_ACCT(P_USER_ACCT IN VARCHAR2)
  RETURN VARCHAR2 DETERMINISTIC AS

  /**************************************************
      * Created Date                  : 01/FEB/2016.
      * Created By                     : Narayanaswamy.T.
      * Purpose                           : Account Number Masking.   
      * Reviewed By                : Saravanakumar.A
      * Reviewed Date             :
      * Build Number                :  Release 4.0
  
  **************************************************/

  /**********Account No Masking Function**************
   * Example
   * Clear acct :-      123456789012.
   * Masked acct:-  1234****9012.
  *****************************************************/

  V_ENCRYPT VARCHAR(30);

BEGIN

  IF P_USER_ACCT IS NULL OR LENGTH(P_USER_ACCT) < 9 THEN
    RETURN P_USER_ACCT;
  END IF;

  V_ENCRYPT := SUBSTR(P_USER_ACCT, 1, 4)||TRANSLATE(SUBSTR(P_USER_ACCT, 5, LENGTH(P_USER_ACCT) - 8),
                    '0123456789',
                    '**********')||SUBSTR(P_USER_ACCT, -4, 4);
   RETURN V_ENCRYPT;

EXCEPTION
  WHEN OTHERS THEN
    RETURN P_USER_ACCT;
  
END; 
/
