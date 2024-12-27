  CREATE OR REPLACE PACKAGE "VMSCMS"."GPP_PRODUCTS" AUTHID CURRENT_USER IS

   -- PL/SQL Package using FS Framework
   -- Author  : SINDHU
   -- Created : 12-08-2015 11:26:31
   -- Purpose : New package for GPP

   -- Global public type declarations should be located in the FSFW.FSTYPE package

   -- Global public constant declarations should be located in the FSFW.FSCONST package

   -- Public variable declarations

   -- Public function and procedure declarations

   --Get products
   PROCEDURE get_products
   (
      p_status_out   OUT VARCHAR2,
      p_err_msg_out  OUT VARCHAR2,
      c_products_out OUT SYS_REFCURSOR
   );

END gpp_products;