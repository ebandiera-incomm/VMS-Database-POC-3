CREATE OR REPLACE PACKAGE VMSCMS.VMSPRODUCT AS 

  PROCEDURE    PRODUCTCOPY_PROGRAMTEMP (
   p_instcode_in            IN       NUMBER,
   p_bin_in                 IN       VARCHAR2,
   p_prod_code_in           IN       VARCHAR2,
   p_prod_catg_in           IN       VARCHAR2,
   p_prod_copy_in           IN       VARCHAR2,
   P_COPY_OPTION            IN       VARCHAR2,
   P_ENV_OPTION             IN       VARCHAR2,
   p_ins_user_in            IN       NUMBER,
   p_resp_code_out          OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
);

PROCEDURE    PRODUCTCOPY_PROGRAMMAST (
   p_instcode_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
    p_card_type_in           IN       VARCHAR2,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_out          OUT       VARCHAR2,
   p_resp_code_out          OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
);

PROCEDURE SP_CLEAR_COPY (
   p_instcode_in        IN       NUMBER,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
);
                          
PROCEDURE tbl_to_xml (p_xmldata_out  OUT XMLTYPE,
                      p_respmsg_out     OUT VARCHAR2);

PROCEDURE xml_to_tbl (p_prod_code_out   OUT VARCHAR2,
                      p_respmsg_out     OUT VARCHAR2);
                      
PROCEDURE ROLLBACK_TRANSACTION_CONFIG(p_instcode_in            IN       NUMBER,
                                      p_audit_id               IN       VARCHAR2,
                                      p_ins_user_in            IN       NUMBER,
                                      p_errmsg_out             OUT      VARCHAR2
                                     );

END VMSPRODUCT;
/

Show errors;
