create or replace
PACKAGE        vmscms.PKG_LIMITS_CHECK
AS
   TYPE rec_hash IS RECORD (
      prfl_id     cms_limit_prfl.clp_lmtprfl_id%type, --aded by amit on 30-Jul-2012
      comb_hash   cms_cardsumry_dwmy.ccd_comb_hash%TYPE,
      pan_code    cms_cardsumry_dwmy.ccd_pan_code%TYPE,
      load_amount cms_acct_mast.cam_new_initialload_amt%type
   );

   TYPE type_hash IS TABLE OF rec_hash
      INDEX BY BINARY_INTEGER;
      
    /**********************************************************************************************
     * Modified By      : Sachin P.
      * Modified Date    : 04-Apr-2013
      * Modified Reason  : Limit Profile not accounting for reversal                       
      * Modified For     : MVHOST-298                       
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Apr-2013
      * Build Number     : RI0024.1_B0008
      
      * Modified By      : Ramesh
      * Modified Date    : 14-June-2013
      * Modified Reason  : Added delivery channel condition for medagate for limit check                     
      * Modified For     : MVHOST-383                       
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     : RI0024.2_B0004
    
      * Modified By      : Shweta
      * Modified Date    : 21-June-2013
      * Modified Reason  : Over the Counter (Bank) Withdrawal - Daily Limit 2,500, Approved $2800                     
      * Modified For     : NCGPR-429                     
      * Reviewer         : Sachin Patil
      * Reviewed Date    : 21-Jun-2013
      * Build Number     : RI0024.2_B0006
      
      * Modified By      : Sachin Patil
      * Modified Date    : 12-Jul-2013
      * Modified Reason  : NextCala - Sum of C2C transfers per month exceeds 2000.00 and should not                     
      * Modified For     : NCGPR-434                      
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19.07.2013
      * Build Number     : RI0024.3_B0005
      
      * Modified By      : Sachin Patil
      * Modified Date    : 20-AuG-2013
      * Modified Reason  : Enable Card to Card Transfer Feature for Mobile API                                  
      * Modified For     : MOB-31                      
      * Reviewer         : Dhiraj
      * Reviewed Date    : 20-AuG-2013
      * Build Number     : RI0024.4_B0003
      
      * Modified By      : Pankaj S.
      * Modified Date    : 21-jan-2014
      * Modified Reason  : FWR-44 & Yearly count not reset issue                                  
      * Reviewer         : Dhiraj
      * Reviewed Date    :  20-Jan-2014
      * Build Number     :  RI0027_B0004 
      
      * Modified By      : Pankaj S.
      * Modified Date    : 24-Mar-2014
      * Modified Reason  : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)                             
      * Reviewer         : Dhiraj
      * Reviewed Date    : 07-April-2014
      * Build Number     : RI0027.2_B0004
      
      * Modified by       : Spankaj
      * Modified for      : MVHOST-1041     
      * Modified Date     : 12-Nov-2014
      * Build Number      : RI0027.4.2.1
      
      * Modified by       : Spankaj
      * Modified for      : ACH canada
      * Build Number      : RI0027.4.3
      
      * Modified By      : Ramesh A
      * Modified Date    : 11-FEB-2015
      * Modified Reason  : DFCTNM-4(MoneySend)                             
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     : 
      
      * Modified By      : Ramesh A
      * Modified Date    : 26-FEB-2015
      * Modified Reason  : DFCTNM-4(MoneySend) for reversal changes                          
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     : 
	  
      * Modified by      : Spankaj
      * Modified for     : FSS-3418-Limit Reset changes
      * Reviewer         : Saravanan kumar
      * Build Number     : VMSGPRHOAT_3.0.3
	  
      * Modified by      : A.Sivakaminathan
      * Modified Date    : 22-JUL-2015
      * Modified for     : FSS-3560 Group Limit not applied for Card to Card Transfer transaction
      * Reviewer         : A.Saravanakumar
      * Build Number     : VMSGPRHOSTCSD_3.0.4	  
     
   *************************************************************************************************/  

   PROCEDURE sp_limits_check (
      prm_hash_pan           IN       VARCHAR2,
      prm_frmacct_no         IN       VARCHAR2,
      prm_toacct_no          IN       VARCHAR2,
      prm_mcc_code           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_tran_type          IN       CHAR,
      prm_intl_flag          IN       VARCHAR2,
      prm_pnsign_flag        IN       CHAR,
      prm_inst_code          IN       NUMBER,
      prm_trfr_crdacnt       IN       VARCHAR2,
      prm_lmt_prfl           IN       VARCHAR2,
      prm_txn_amt            IN       NUMBER,
      prm_delivery_channel   IN       VARCHAR2,
      prm_crdcomb_hash       OUT      pkg_limits_check.type_hash,
      prm_err_code           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2,
      prm_mr_flag                IN     VARCHAR2 default 'N',   --Added by Pankaj S. for MR INGO limit issue
      prm_payment_type        IN     VARCHAR2 default null --Added for DFCTNM-4(MoneySend)
   );

   PROCEDURE sp_limitcnt_reset (
      prm_inst_code      IN       NUMBER,
      prm_hash_pan       IN       VARCHAR2,
      prm_txn_amt        IN       NUMBER,
      prm_crdcomb_hash   IN       pkg_limits_check.type_hash,
      prm_err_code       OUT      VARCHAR2,
      prm_err_msg        OUT      VARCHAR2
   );

   PROCEDURE sp_limits_eod (prm_err_code OUT VARCHAR2, prm_err_msg OUT VARCHAR2);
   
     --SN Added on 03.04.2013 for MVHOST-298 
   PROCEDURE sp_limitcnt_rever_reset(
       prm_inst_code         IN       NUMBER,
      prm_frmcrd_no         IN       VARCHAR2,
      prm_tocrd_no          IN       VARCHAR2,
      prm_mcc_code           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_tran_type          IN       CHAR,
      prm_intl_flag          IN       VARCHAR2,
      prm_pnsign_flag        IN       CHAR,   
      prm_lmt_prfl           IN       VARCHAR2,
      prm_txn_amt            IN       NUMBER,
      prm_orgnl_txn_amnt       IN       NUMBER,
      prm_delivery_channel   IN       VARCHAR2,
      prm_hash_pan           IN       VARCHAR2, 
      prm_orgnl_date        IN       DATE,
      prm_err_code          OUT      VARCHAR2,
      prm_err_msg           OUT      VARCHAR2,
       prm_payment_type        IN     VARCHAR2 default null --Added for DFCTNM-4(MoneySend)
   
   );
  --EN Added on 03.04.2013 for MVHOST-298 
END;                                                      --END PACKAGE HEADER
/
show error

