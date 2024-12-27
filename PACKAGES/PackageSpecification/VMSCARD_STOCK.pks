create or replace
PACKAGE        VMSCMS.vmscard_stock
IS
   -- Created : 11/22/2017  17:40:00
   -- Purpose : Stock issuance and Inventory related processes

   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE stock_issuance_process (p_instcode_in         NUMBER,
                                     p_filename_in         VARCHAR2,
                                     p_prodcode_in         VARCHAR2,
                                     p_cardtype_in         VARCHAR2,
                                     p_merid_in              VARCHAR2,
                                     p_locationid_in         VARCHAR2,
                                     p_merprodcatid_in       VARCHAR2,
                                     P_Quantity_In         Number,
                                     p_cust_catg          varchar2,
                                     p_usercode_in         NUMBER,
                                     p_errmsg_out      OUT VARCHAR2,
                                     p_respdtls_out    OUT VARCHAR2);

   PROCEDURE merinv_process (p_instcode_in       NUMBER,
                             p_usercode_in       NUMBER,
                             p_raise_in          VARCHAR,
                             p_errmsg_out    OUT VARCHAR2);
END;
/
show error