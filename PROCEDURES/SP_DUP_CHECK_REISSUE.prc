CREATE OR REPLACE PROCEDURE VMSCMS.sp_dup_check_reissue(
                                                  prm_instcode IN NUMBER,
                                                  prm_old_pancode IN VARCHAR2,
                                                  prm_reissue_dupflag OUT CHAR,
                                                  prm_errmsg OUT VARCHAR2
                                                )
as
v_reissue_check number;
BEGIN
    prm_errmsg:='OK';
    prm_reissue_dupflag:='F';
    
    SELECT count(*) 
    INTO v_reissue_check
    FROM cms_reissue_detail
    WHERE crd_inst_code = prm_instcode
    AND crd_old_card_no = prm_old_pancode
    AND crd_process_flag='S';
    
    IF v_reissue_check !=0 then
       prm_reissue_dupflag:='D';
    END IF;
    
EXCEPTION 
WHEN OTHERS THEN
    prm_errmsg := ' Error while getting reissue history data '|| SUBSTR(sqlerrm,1,150);
    RETURN;
END;
/
SHOW ERRORS

