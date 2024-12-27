CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_corp (
                                            instcode    IN    NUMBER    ,
                                            Name    IN    VARCHAR2    ,
                                            ShortName    IN    VARCHAR2    ,
                                            Add1    IN    VARCHAR2    ,
                                            Add2    IN    VARCHAR2    ,
                                            Add3        IN    VARCHAR2    ,
                                            City        IN    VARCHAR2    ,
                                            Pin    IN    VARCHAR2    ,
                                            State    IN    VARCHAR2    ,
                                            Country     IN    VARCHAR2    ,
                                             CPerson IN    VARCHAR2    ,
                                                email        IN    VARCHAR2,              --Added by vikrant 04Arp08 for adding email
                                            lupduser    IN    NUMBER    ,
                                            corpCode    OUT     VARCHAR2    ,
                                            errmsg        OUT     VARCHAR2     )

AS
BEGIN        --Main Begin Block Starts Here
errmsg:='OK';
   SELECT SEQ_corp_Code.NEXTVAL INTO corpCode FROM dual;

    INSERT INTO    PCMS_CORPORATE_MASTER (    PCM_ORGANIZATION_CODE        ,
                    PCM_SHORT_NAME,
               PCM_ORGANIZATION_NAME,
               PCM_CONTACT_PERSON,
               PCM_ADDR_LINE1        ,
               PCM_ADDR_LINE2         ,
               PCM_ADDR_LINE3         ,
               PCM_PIN                ,
               PCM_CITY               ,
               PCM_STATE              ,
               PCM_COUNTRY            ,
               PCM_UPD_USER           ,
               PCM_UPD_DATE           ,
               PCM_INS_USER           ,
               PCM_INS_DATE           ,
               PCM_CORP_EMAIL,
               PCM_LUPD_DATE,
               PCM_INST_CODE, 
               PCM_LUPD_USER                )
                VALUES(    corpcode        ,
                    ShortName        ,
                    Name        ,
          CPerson,
                    Add1        ,
                    Add2,
                    Add3,
                    Pin,
                    City,
                    State    ,
                    Country            ,
                    lupduser        ,
               SYSDATE,
                    lupduser,
               SYSDATE       ,
               email,SYSDATE,instcode,lupduser    );
EXCEPTION    --Excp of Main Begin Block
    WHEN OTHERS THEN
    errmsg := 'Main Exception --- '||SQLERRM;
END;        --Main Begin Block Ends Here
/


show error