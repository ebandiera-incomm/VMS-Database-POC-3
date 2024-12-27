CREATE OR REPLACE PACKAGE VMSCMS.PKG_STOCK
AS

/********************************************************************************************
      * Created BY      : Dhiarj
      * Created for     : 
      * Creatd Date     : 25/03/2013
      * Reviewer        : NA
      * Reviewed Date   : 25/03/2013
	  * Build Number    : RI0024_B0008
************************************************************************************************/	  

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

   TYPE rec_pan_construct IS RECORD (
      cpc_profile_code   cms_pan_construct.cpc_profile_code%TYPE,
      cpc_field_name     cms_pan_construct.cpc_field_name%TYPE,
      cpc_start_from     cms_pan_construct.cpc_start_from%TYPE,
      cpc_start          cms_pan_construct.cpc_start%TYPE,
      cpc_length         cms_pan_construct.cpc_length%TYPE,
      cpc_field_value    VARCHAR2 (30)
   );

   TYPE table_pan_construct IS TABLE OF rec_pan_construct
      INDEX BY BINARY_INTEGER;


END;--end package specs
/
show error;