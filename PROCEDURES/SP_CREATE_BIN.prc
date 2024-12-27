CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Bin (instcode  IN NUMBER ,
            interchange IN VARCHAR2 ,
            bin   IN NUMBER ,
            bin_status in char,
            lupduser  IN NUMBER ,
            errmsg  OUT VARCHAR2)
AS

BEGIN  --Main begin starts
    errmsg := 'OK';

    --shyamjith CR 138 - 28 Feb 05, to add bin level status
/*    INSERT INTO cms_bin_mast( CBM_INST_CODE   ,
        CBM_INTERCHANGE_CODE,
        CBM_SERV_CODE,
        CBM_INST_BIN   ,
        CBM_INS_USER   ,
        CBM_LUPD_USER         )
          VALUES( instcode  ,
        interchange ,
        srvccode    ,
        bin   ,
        lupduser  ,
        lupduser  );*/
        BEGIN
                                    INSERT INTO CMS_BIN_MAST( CBM_INST_CODE   ,
                                        CBM_INTERCHANGE_CODE,
                                        CBM_INST_BIN   ,
                                        CBM_BIN_STAT,
                                        CBM_INS_USER   ,
                                        CBM_LUPD_USER
                                       )
                                          VALUES( instcode  ,
                                        interchange ,
                                        bin   ,
                                        bin_status,
                                        lupduser  ,
                                        lupduser
                                     );
        EXCEPTION
                                      WHEN DUP_VAL_ON_INDEX THEN
                                       errmsg := ' Bin already present in master';
                                       RETURN;
                                     WHEN OTHERS THEN
                                        errmsg := ' Error Occured while adding Interchange';
                                        RETURN;
        END;


 --added on 06-09-02...to be commented for other banks...for icici this part of code is sspecific...depending on the situation for banks other than icici, this part of code might be present in sp_ctreate_prodbin also

     /*IF errmsg = 'OK' THEN

          sp_create_panctrl_data(instcode,null,bin,null,'BIN',lupduser,errmsg);
          IF errmsg != 'OK' THEN
               errmsg := 'From sp_create_panctrl_data -- '||errmsg;
          END IF;
     END IF;*/ -- Commented By Hari 1st Dec 2005

EXCEPTION --Excp of main begin
     WHEN OTHERS THEN
         errmsg := 'Main Exception -- '||SQLERRM;
END;  --Main begin ends
/
SHOW ERROR