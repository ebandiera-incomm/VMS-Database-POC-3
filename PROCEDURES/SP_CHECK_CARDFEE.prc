CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_cardfee (
   instcode   IN       NUMBER,
   feecode        IN    NUMBER    ,
   pancode        IN    VARCHAR2    ,
   mbrnumb        IN    VARCHAR2    ,
   validfrom        IN    DATE        ,
   validto        IN    DATE        ,
   lupduser        IN    NUMBER    ,
   errmsg        OUT     VARCHAR2    )
AS
v_cfm_fee_code    NUMBER(3);
newdate                DATE        ;
flowsource            CHAR(1)    ;
v_mbrnumb            VARCHAR2(3);
mesg                VARCHAR2(500);

BEGIN

    BEGIN
        INSERT INTO cms_card_excpfee
            (cce_inst_code, cce_fee_code, cce_pan_code, cce_mbr_numb,
             cce_valid_from, cce_valid_to, cce_flow_source, cce_ins_user,
             cce_lupd_user, cce_crgl_catg, cce_crgl_code, cce_crsubgl_code,
             cce_cracct_no, cce_drgl_catg, cce_drgl_code, cce_drsubgl_code,
             cce_dracct_no, cce_st_calc_flag, cce_cess_calc_flag,
             cce_st_crgl_catg, cce_st_crgl_code, cce_st_crsubgl_code,
             cce_st_cracct_no, cce_st_drgl_catg, cce_st_drgl_code,
             cce_st_drsubgl_code, cce_st_dracct_no, cce_cess_crgl_catg,
             cce_cess_crgl_code, cce_cess_crsubgl_code, cce_cess_cracct_no,
             cce_cess_drgl_catg, cce_cess_drgl_code, cce_cess_drsubgl_code,
             cce_cess_dracct_no, cce_fee_type, cce_tran_code,
             cce_pan_code_encr
            )
        VALUES (1,286,gethash(4567891234000478),'000',
             TO_DATE ('20110221', 'YYYYMMDD'), TO_DATE (20110521, 'YYYYMMDD'),'C', 1,
             1, '2:L', '020501000001', '020501030001',
             '02050103000001', null, null, null,
             null, null, null,
             null, null, null,
             null, null, null,
             null, null, null,
             null, null, null,
             null, null, null,
             null, '99', '58',
             fn_emaps_main ('4567891234000478'))
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_err := 'FEE TYPE NOT DEFINED';
         WHEN OTHERS
         THEN
            l_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
         END    

EXCEPTION
   WHEN OTHERS
   THEN
      l_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM;

END
/


