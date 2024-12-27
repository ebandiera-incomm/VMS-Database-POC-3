CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Reissueclose 
                    (instcode IN NUMBER,
                    ipaddr    IN VARCHAR2,
                    lupduser IN NUMBER,
                    errmsg OUT VARCHAR2
                    )
                    
AS
v_mbrnumb VARCHAR2(3);
v_remark  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_spprtrsn CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;
v_cardstat  CMS_APPL_PAN.cap_card_stat%TYPE;
v_cardstatdesc VARCHAR2(10);
v_savepoint NUMBER := 1; 
v_dup_rec_count NUMBER(3);      
v_pancode CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
exp_reject_record EXCEPTION;

CURSOR c1 IS
    SELECT TRIM(CRC_PAN_CODE) CRC_PAN_CODE,CRC_PAN_CODE_ENCR,ROWID FROM CMS_REISSUE_CLOSE WHERE CRC_FLAG = 'N';

BEGIN
    
    errmsg := 'OK';
    v_mbrnumb :='000';
    v_remark := 'Group Reissue Close';
    v_spprtrsn := 9;  -- changed   1-->9  ( as 9 is for Closing.)
    
    FOR x IN c1
        LOOP
                     errmsg := 'OK';
                  BEGIN                        --Loop begin 
                  SAVEPOINT v_savepoint; 
            --
                                             BEGIN 
                                              SELECT DISTINCT X.CRC_PAN_CODE INTO v_pancode      --- CHECK THE PAN FOR REISSUE IN PAN SPPRT
                                              FROM    CMS_HTLST_REISU ,CMS_PAN_SPPRT
                                              WHERE   CHR_NEW_PAN = X.CRC_PAN_CODE  
                                              AND     CHR_PAN_CODE  = CPS_PAN_CODE
                                              AND     CPS_SPPRT_KEY = 'REISU';        
                                              v_dup_rec_count :=1;
                                          EXCEPTION            
                                             WHEN NO_DATA_FOUND THEN
                                            errmsg := X.CRC_PAN_CODE || ' Card is not reissued';
                                            RAISE exp_reject_record;
                                                --v_dup_rec_count :=0;
                                            WHEN TOO_MANY_ROWS THEN
                                            errmsg := 'More than one record present for Pan Code ' || X.CRC_PAN_CODE;
                                            RAISE exp_reject_record;
                                          END;--to check for dup
                            
                                        DBMS_OUTPUT.PUT_LINE(v_pancode);
              
                                      BEGIN
                           
                                       SELECT cap_card_stat  ,DECODE(cap_card_stat , '1','OPEN','2','HOTLISTED','3','STOLEN','4','RESTRICTED','9','CLOSED','0','BLOCKED','INVALID  STATUS') 
                                       INTO  v_cardstat ,v_cardstatdesc
                                       FROM  CMS_APPL_PAN
                                       WHERE cap_pan_code = TRIM(v_pancode )
                                       AND cap_mbr_numb = '000'
                                       AND cap_card_stat <> 9 ;
                                   EXCEPTION
                                            WHEN NO_DATA_FOUND THEN 
                                                errmsg := TRIM(v_pancode ) ||'  is  already closed ' ;
                                            RAISE exp_reject_record;
                                            WHEN OTHERS THEN
                                                errmsg := 'Error while selecting data from appl_pan ' || SUBSTR(SQLERRM,1,300);
                                            RAISE exp_reject_record;
                                         
                                   END;
                       
                                   BEGIN            -- Hari 22 Feb - workmode
                                
                                Sp_Close_Pan(instcode,ipaddr,Fn_DMaps_Main(x.CRC_PAN_CODE_ENCR),v_spprtrsn,v_remark,lupduser,0,errmsg);
                                
                                IF ERRMSG = 'OK' THEN
                                        UPDATE CMS_REISSUE_CLOSE SET CRC_FLAG = 'Y',CRC_PROCESS_RESULT= 'SUCCESSFUL' WHERE ROWID = X.ROWID;
                                ELSE
                                    RAISE exp_reject_record;        
                                END IF;
                                
                                END;
            EXCEPTION
                    WHEN exp_reject_record THEN
                    ROLLBACK TO v_savepoint;
                    UPDATE CMS_REISSUE_CLOSE 
                    SET    CRC_FLAG = 'E' , 
                           CRC_PROCESS_RESULT= errmsg 
                    WHERE ROWID = X.ROWID;
                    
                    WHEN OTHERS  THEN
                    ROLLBACK TO v_savepoint;
                    errmsg := SUBSTR(SQLERRM,1,300);
                    UPDATE CMS_REISSUE_CLOSE 
                    SET    CRC_FLAG = 'E' , 
                           CRC_PROCESS_RESULT= errmsg
                    WHERE ROWID = X.ROWID;
                    
            END;      -- end loop begin
            v_savepoint := v_savepoint + 1 ;  -- shyam 261006 -- CR 170
    END LOOP;
        ERRMSG := 'OK';
EXCEPTION
WHEN OTHERS THEN
    errmsg := 'Main Excp from sp_grp_reissueclose  -- '||SQLERRM;
END;
/
SHOW ERRORS

