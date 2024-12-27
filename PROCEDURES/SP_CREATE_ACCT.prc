CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Acct( 
                        prm_instcode    IN NUMBER ,
                        prm_acctno        IN VARCHAR2 ,
                        prm_holdcount    IN NUMBER ,
                        prm_currbran    IN VARCHAR2 ,
                        prm_billaddr    IN NUMBER ,
                        prm_accttype    IN NUMBER ,
                        prm_acctstat    IN NUMBER ,
                        prm_lupduser    IN NUMBER ,
                        prm_gen_acctdata    IN TYPE_ACCT_REC_ARRAY,
                        prm_bin                NUMBER,
                        prm_cust_id        CMS_CUST_MAST.ccm_cust_id%type,
                        prm_prod_code  IN VARCHAR2,
                        prm_card_type   IN  NUMBER,
                        prm_dup_flag    OUT VARCHAR2,
                        prm_acctid        OUT  NUMBER ,
                        prm_errmsg        OUT VARCHAR2
                          )
AS
v_acctno                    CMS_ACCT_MAST.cam_acct_no%type;
uniq_excp_acctno             EXCEPTION  ;
v_acctrec_outdata            TYPE_ACCT_REC_ARRAY;
v_check_skipacct             NUMBER(2);
v_check_primaryrec           NUMBER(1);            
v_acctdata_errmsg            VARCHAR2(500);
v_dupacct_check               VARCHAR2(1);
v_dupcheck_param_flag       CMS_INST_PARAM.cip_param_value%type;
v_instspecific_dupchk       VARCHAR2(1);
v_instspecific_errmsg       VARCHAR2(500);
PRAGMA EXCEPTION_INIT(uniq_excp_acctno,-00001);
BEGIN  --Main Begin Block Starts Here
 --Sn get acct number
       BEGIN
            SELECT seq_acct_id.NEXTVAL
              INTO prm_acctid
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                  'Error while selecting acctnum '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE uniq_excp_acctno;
         END;
            --En get acct number
          IF prm_acctno IS NULL THEN 
             v_acctno := trim(prm_acctid);
         ELSIF prm_acctno IS NOT NULL THEN
             v_acctno := trim(prm_acctno);
         END IF;
    --Sn set acct data
        SP_SET_GEN_ACCTDATA
                (
                  prm_instcode ,
                  prm_gen_acctdata ,
                  v_acctrec_outdata ,
                  v_acctdata_errmsg
                );
        IF v_acctdata_errmsg <> 'OK' THEN
           prm_errmsg := 'Error in set gen parameters   ' ||  v_acctdata_errmsg;
           RETURN;
            END IF;
    --En set acct data
    
    if v_acctrec_outdata is null then
    
     INSERT INTO CMS_ACCT_MAST(
               CAM_INST_CODE ,
               CAM_ACCT_ID  ,
               CAM_ACCT_NO  ,
               CAM_HOLD_COUNT ,
               CAM_CURR_BRAN ,
               CAM_BILL_ADDR  ,
               CAM_TYPE_CODE ,
               CAM_STAT_CODE ,
               CAM_INS_USER  ,
               CAM_LUPD_USER ,
               cam_prod_code,
               cam_card_type 
            )
            VALUES
            (     prm_instcode   ,
                   prm_acctid   ,
                   trim(v_acctno) ,
                   prm_holdcount   ,
                   prm_currbran   ,
                   prm_billaddr   ,
                   prm_accttype   ,
                   prm_acctstat   ,
                   prm_lupduser   ,
                   prm_lupduser,
                   prm_prod_code,
                   prm_card_type
                   );
                   
    else 
    
 INSERT INTO CMS_ACCT_MAST(
               CAM_INST_CODE ,
               CAM_ACCT_ID  ,
               CAM_ACCT_NO  ,
               CAM_HOLD_COUNT ,
               CAM_CURR_BRAN ,
               CAM_BILL_ADDR  ,
               CAM_TYPE_CODE ,
               CAM_STAT_CODE ,
               CAM_INS_USER  ,
               CAM_LUPD_USER ,
               CAM_ACCT_PARAM1, 
               CAM_ACCT_PARAM2, 
               CAM_ACCT_PARAM3, 
               CAM_ACCT_PARAM4, 
               CAM_ACCT_PARAM5, 
               CAM_ACCT_PARAM6, 
               CAM_ACCT_PARAM7, 
               CAM_ACCT_PARAM8, 
               CAM_ACCT_PARAM9, 
               CAM_ACCT_PARAM10,
               cam_prod_code,
               cam_card_type 
            )
            VALUES
            (     prm_instcode   ,
                   prm_acctid   ,
                   trim(v_acctno) ,
                   prm_holdcount   ,
                   prm_currbran   ,
                   prm_billaddr   ,
                   prm_accttype   ,
                   prm_acctstat   ,
                   prm_lupduser   ,
                   prm_lupduser  ,
                   v_acctrec_outdata(1),
                   v_acctrec_outdata(2),
                   v_acctrec_outdata(3),
                   v_acctrec_outdata(4),
                   v_acctrec_outdata(5),
                   v_acctrec_outdata(6),
                   v_acctrec_outdata(7),
                   v_acctrec_outdata(8),
                   v_acctrec_outdata(9),
                   v_acctrec_outdata(10),
                   prm_prod_code,
                   prm_card_type
                   );
                   
                   end if;
      prm_dup_flag := 'A';
prm_errmsg := 'OK';
EXCEPTION --Main block Exception
WHEN uniq_excp_acctno THEN
prm_errmsg := 'Account No already in Master.';
SELECT cam_acct_id
INTO prm_acctid
FROM CMS_ACCT_MAST
WHERE cam_inst_code  = prm_instcode
AND cam_acct_no  = trim(prm_acctno) ; 

--Sn check in skip acct table 
BEGIN
     SELECT COUNT(*)
     INTO    v_check_skipacct
     FROM     CMS_SKIPDUP_ACCTS
     WHERE  CSA_INST_CODE = prm_instcode
     AND    CSA_ACCT_NO   = prm_acctno;

EXCEPTION
    WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting data from skip acct ' || substr(sqlerrm,1,200);
    
    RETURN;

END;
--En check in  skip acct table
IF v_check_skipacct > 0 THEN
   prm_dup_flag   := 'A';
   prm_errmsg       := 'OK';
ELSE
     --Sn check for card already present on this acctno
     
     
   BEGIN          
               BEGIN
                 SELECT cip_param_value
                 INTO    v_dupcheck_param_flag
                 FROM    CMS_INST_PARAM
                 WHERE    cip_param_key = 'DUP_ACCT_CHECK'
                 AND    cip_inst_code =  prm_instcode;
            
            
            EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                       prm_errmsg := 'Duplicate Account check flag for institute is not defined in master  ' ;
                         RETURN;
                 WHEN OTHERS THEN
                       prm_errmsg := 'Error while Duplicate Account check flag from master  ' || substr(sqlerrm,1,150);
                         RETURN;
            END;
            
               IF v_dupcheck_param_flag = 'N' THEN 
               RAISE NO_DATA_FOUND;
            ELSE
            
                   BEGIN
                       SELECT  DISTINCT 1 
                      INTO    v_check_primaryrec
                       FROM   CMS_PAN_ACCT, CMS_APPL_PAN, CMS_CUST_MAST
                     WHERE  cpa_inst_code = prm_instcode
                     AND    cpa_acct_id = prm_acctid
                                      AND SUBSTR (cpa_pan_code, 1, 6) = prm_bin
                                      AND cap_pan_code = cpa_pan_code
                                      AND cap_mbr_numb = cpa_mbr_numb
                                      AND ccm_cust_code = cpa_cust_code
                                      AND CCM_CUST_ID   = prm_cust_id 
                                      AND cap_card_stat = '1';
                    
                    prm_dup_flag  := 'D';
                    prm_errmsg       := 'OK';
                    
               EXCEPTION
               
                       WHEN NO_DATA_FOUND THEN
                    SP_DUP_CHECK_ACCT_INSTSPECIFIC(prm_instcode,prm_acctid,v_instspecific_dupchk,v_instspecific_errmsg);
                    IF v_instspecific_errmsg <> 'OK'THEN
                       prm_errmsg       := v_instspecific_errmsg;
                       RETURN;
                    ELSE
                        IF v_instspecific_dupchk = 'T' THEN
                        
                           prm_dup_flag  := 'D';
                           prm_errmsg       := 'OK';
                        
                        ELSE
                            RAISE NO_DATA_FOUND ;
                            
                        END IF;
                    
                    END IF;
                    
                                        
                    WHEN OTHERS THEN
                    prm_errmsg := 'Error while Duplicate Account check flag from master  ' || substr(sqlerrm,1,150);
                       RETURN;
               
               END;
             END IF;
        
   EXCEPTION
               WHEN NO_DATA_FOUND THEN
            
                    v_dupacct_check := Fn_Dup_Appl_Check( prm_cust_id,prm_bin,prm_acctid,prm_instcode );
                 IF v_dupacct_check = 'T' THEN 
                     prm_dup_flag := 'D';
                    ELSE 
                    prm_dup_flag := 'A';
                   END IF;
                 prm_errmsg       := 'OK';
               WHEN OTHERS THEN
                prm_errmsg := 'Error while checking pending appl data for duplicate acct ' || substr(sqlerrm,1,200);
                RETURN; 
   END;
   
      --En check for card already present on this acctno
       
END IF;
WHEN OTHERS THEN
prm_errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/
show error