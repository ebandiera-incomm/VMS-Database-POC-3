create or replace PACKAGE          VMSCMS.PACK_CMS_WAIVATTACH
AS

   PROCEDURE sp_create_cardexcpwaiv (
      p_instcode    IN       NUMBER,
      p_feecode     IN       NUMBER,
      p_feeplan     IN       NUMBER,
      p_waivprcnt   IN       NUMBER,
      p_pancode     IN       VARCHAR2,
      p_mbrnumb     IN       VARCHAR2,
      p_validfrom   IN       DATE,
      p_validto     IN       DATE,
      p_waivdesc    IN       VARCHAR2,
      p_lupduser    IN       NUMBER,
      p_iden_flag   IN       NUMBER,
      p_waiv_id     IN       NUMBER,
      p_errmsg      OUT      VARCHAR2
   );


   PROCEDURE sp_create_prodcattypewaiv (
      p_instcode     IN       NUMBER,
      p_prodcode     IN       VARCHAR2,
      p_cardtype     IN       NUMBER,
      p_feecode      IN       NUMBER,
      p_feeplan      IN       NUMBER,
      p_waivprcnt    IN       NUMBER,
      p_validfrom    IN       DATE,
      p_validto      IN       DATE,
      p_waivdesc     IN       VARCHAR2,
      p_lupduser     IN       NUMBER,
      p_iden_flag   IN       NUMBER,
      p_waiv_id     IN       NUMBER,
      p_errmsg       OUT      VARCHAR2
   );

   PROCEDURE sp_create_prodwaiv (
      p_instcode    IN       NUMBER,
      p_prodcode    IN       VARCHAR2,
      p_feecode     IN       NUMBER,
      p_feeplan     IN       NUMBER,
      p_waivprcnt   IN       NUMBER,
      p_validfrom   IN       DATE,
      p_validto     IN       DATE,
      p_waivdesc    IN       VARCHAR2,
      p_lupduser    IN       NUMBER,
      p_iden_flag   IN       NUMBER,
      p_waiv_id     IN       NUMBER,
      p_errmsg      OUT      VARCHAR2
   );

END PACK_CMS_WAIVATTACH;
/
show error;

CREATE OR REPLACE PACKAGE BODY VMSCMS.PACK_CMS_WAIVATTACH
IS

     /*************************************************
      * Created Date     :  09-AUG-2012
      * Created By       :  B.Besky Anand
      * PURPOSE          :  To attach the waiver for card,Product category,Product for Add and Modify Screens.  
      * Modified By      :  Ramkumar.Mk 
      * Modified Date    :  27 Aug 2012
      * Modified Reason  :  Store the waiver description in upper
      * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  27-AUG-2012
      * Build Number     :  CMS3.5.1_RI0015_B0007        
     *************************************************/

   PROCEDURE sp_create_cardexcpwaiv (
      p_instcode    IN       NUMBER,
      p_feecode     IN       NUMBER,
      p_feeplan     IN       NUMBER,
      p_waivprcnt   IN       NUMBER,
      p_pancode     IN       VARCHAR2,
      p_mbrnumb     IN       VARCHAR2,
      p_validfrom   IN       DATE,
      p_validto     IN       DATE,
      p_waivdesc    IN       VARCHAR2,
      p_lupduser    IN       NUMBER,
      p_iden_flag   IN       NUMBER,
      p_waiv_id     IN       NUMBER,
      p_errmsg      OUT      VARCHAR2
   )
   AS
    v_cfm_feetype_code   NUMBER (3);
    v_cnt                NUMBER;
    v_check_flag         CHAR(1):='Y';
    v_waiv_id            cms_card_excpwaiv.cce_card_waiv_id%TYPE;  
    v_encr_pan           cms_card_excpwaiv.cce_pan_code_encr%TYPE;
    v_hash_pan           cms_appl_pan.cap_pan_code%type;
    v_old_from_date      cms_card_excpwaiv.cce_valid_from%TYPE;
    v_old_to_date        cms_card_excpwaiv.cce_valid_to%TYPE;
    v_new_from_date      cms_card_excpwaiv.cce_valid_from%TYPE;
    e_reject_record      EXCEPTION;
    
       
    CURSOR cur_waiver(p_feecode cms_card_excpwaiv.cce_fee_code%TYPE,p_feeplan cms_card_excpwaiv.cce_fee_plan%TYPE,v_hash_pan cms_appl_pan.cap_pan_code%type) IS SELECT 
    cce_valid_from,cce_valid_to,cce_card_waiv_id FROM cms_card_excpwaiv WHERE
    cce_fee_code=p_feecode AND cce_fee_plan=p_feeplan AND cce_pan_code=v_hash_pan;
    
    v_valid_from cms_card_excpwaiv.cce_valid_from%TYPE;
    v_valid_to   cms_card_excpwaiv.cce_valid_to%TYPE;
                                     

    BEGIN                                                   
    
        p_errmsg:= 'OK';

        BEGIN                                                   
            SELECT cfm_feetype_code
            INTO v_cfm_feetype_code
            FROM cms_fee_mast
            WHERE cfm_inst_code = p_instcode AND cfm_fee_code = p_feecode;
        EXCEPTION                                              
            WHEN NO_DATA_FOUND   THEN
                p_errmsg := 'No fee type found for this fee code';
                RAISE e_reject_record;
            WHEN OTHERS    THEN
                p_errmsg := 'Error while selecting from cms_fee_mast ' || SQLERRM;
                RAISE e_reject_record;
        END;                                                    
        
        BEGIN
           v_hash_pan := GETHASH(p_pancode); 
        EXCEPTION
            WHEN OTHERS THEN
                p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
                RAISE e_reject_record;
        END;
  
        BEGIN
            SELECT COUNT(1) INTO v_cnt FROM cms_card_excpfee WHERE 
            cce_fee_plan=p_feeplan AND (p_validfrom  BETWEEN cce_valid_from AND nvl2(cce_valid_to,cce_valid_to,p_validfrom ) )
            AND(nvl2(p_validto,p_validto,cce_valid_from) >= cce_valid_from) AND
            (cce_valid_to IS NULL OR (p_validto IS NOT NULL AND p_validto <=cce_valid_to) ) AND cce_pan_code=v_hash_pan;
        EXCEPTION
            WHEN OTHERS THEN
                p_errmsg := 'Error while selecting from cms_card_excpfee table'||sqlerrm;
                RAISE e_reject_record; 
        END;

            IF v_cnt=1 THEN
                BEGIN
                    v_cnt:=NULL;
                    OPEN cur_waiver(p_feecode,p_feeplan,v_hash_pan);
                    LOOP
                        FETCH cur_waiver INTO v_valid_from,v_valid_to,v_waiv_id ;
                        EXIT WHEN cur_waiver%NOTFOUND;
                    
                        SELECT COUNT(1) INTO v_cnt FROM dual where 
                        v_valid_from  BETWEEN p_validfrom AND nvl2(p_validto,p_validto,p_validfrom) OR
                        nvl2(v_valid_to,v_valid_to,v_valid_from) BETWEEN p_validfrom AND  nvl2(p_validto,p_validto,p_validfrom) OR
                        p_validfrom  BETWEEN v_valid_from AND  nvl2(v_valid_to,v_valid_to,v_valid_from)OR
                        nvl2(p_validto,p_validto,p_validfrom)  BETWEEN v_valid_from AND nvl2(v_valid_to,v_valid_to,v_valid_from) or
                        (p_validto is null and v_valid_to is  null);
                     
                        IF v_cnt <> 0 AND p_iden_flag='0' THEN
                            v_check_flag:='N';
                            EXIT;
                        END IF;

                        IF p_iden_flag='1' AND v_cnt <> 0 THEN
                            IF v_waiv_id <> p_waiv_id THEN
                                v_check_flag:='N';
                                EXIT;
                            END IF;
                        END IF;

                    END LOOP;

                    CLOSE cur_waiver;
                
               EXCEPTION
                    WHEN OTHERS THEN
                        p_errmsg := 'Error while checking the date range'||sqlerrm;
                        RAISE e_reject_record; 
               END;
                           
                IF  v_check_flag='Y' THEN
                 
                 IF p_iden_flag=0 THEN
                  
                   BEGIN
                   
                    INSERT INTO cms_card_excpwaiv
                               (cce_inst_code, cce_fee_code, cce_waiv_prcnt,
                                cce_pan_code, cce_mbr_numb, cce_valid_from,
                                cce_valid_to, cce_waiv_desc, cce_flow_source,
                                cce_ins_user, cce_lupd_user,cce_fee_plan,cce_pan_code_encr
                               )
                   VALUES (p_instcode, p_feecode, p_waivprcnt,
                                v_hash_pan, nvl(p_mbrnumb,'000'), TRUNC (p_validfrom),
                                TRUNC (nvl(p_validto,'')), p_waivdesc, 'C',
                                p_lupduser, p_lupduser,p_feeplan,FN_EMAPS_MAIN(p_pancode)
                               );
                   EXCEPTION                                            
                   WHEN OTHERS THEN
                      p_errmsg := 'Error while inserting in to cms_card_excpwaiv'||sqlerrm;
                      RAISE e_reject_record;
                      
                   END;              
                   
                               
                 ELSIF p_iden_flag=1  THEN
                   
                    BEGIN
                       
                       SELECT cce_valid_from,cce_valid_to INTO v_old_from_date,v_old_to_date  
                       FROM cms_card_excpwaiv WHERE cce_card_waiv_id = p_waiv_id;
                       
                        IF  TRUNC(v_old_from_date) <= TRUNC (SYSDATE)
                            AND (TRUNC (v_old_to_date) >= TRUNC (SYSDATE)or v_old_to_date is NULL)
                            AND (TRUNC (p_validto) >= TRUNC (SYSDATE)or p_validto is NULL)  THEN
                         
                          v_new_from_date:=v_old_from_date;
                         
                        ELSIF   TRUNC (v_old_from_date) > TRUNC (SYSDATE)
                            AND (TRUNC (v_old_to_date) > TRUNC (SYSDATE)or v_old_to_date is NULL)
                            AND TRUNC (p_validfrom) >= TRUNC (SYSDATE)
                            AND (TRUNC (p_validto) >= TRUNC (SYSDATE)or p_validto is NULL) THEN
                          
                          v_new_from_date:=p_validfrom;
                          
                        END IF;
                         
                         UPDATE cms_card_excpwaiv
                         SET   cce_waiv_prcnt = p_waivprcnt,
                               cce_valid_from = v_new_from_date,
                               cce_valid_to   = p_validto,
                               cce_waiv_desc  = p_waivdesc,
                               cce_lupd_user  = p_lupduser
                         WHERE cce_card_waiv_id = p_waiv_id;
                       
                   EXCEPTION    
                     WHEN NO_DATA_FOUND THEN
                        p_errmsg := 'No data found for this waiv id in cms_card_excpwaiv table';
                        RAISE e_reject_record;
                     WHEN OTHERS THEN
                        p_errmsg := 'Exception While selecting from  cms_card_excpwaiv table'||sqlerrm;
                        RAISE e_reject_record;
                   END;
                                                         
                 END IF;
                               
                ELSIF v_check_flag='N' THEN
                
                  p_errmsg := 'Waiver already present for the given date range';
                  RAISE e_reject_record; 
                  
                END IF;
                              
         ELSE
         
            p_errmsg :='No date range found for this feeplan in cms_card_excpfee table';
            RAISE e_reject_record;
         
         END IF;
        
   EXCEPTION    
      WHEN e_reject_record THEN
        ROLLBACK;
      WHEN OTHERS THEN
        p_errmsg := 'Main Exception from other handler -- ' || SQLERRM;
        ROLLBACK;
   END sp_create_cardexcpwaiv;                                                      

   PROCEDURE sp_create_prodcattypewaiv (
      p_instcode     IN       NUMBER,
      p_prodcode     IN       VARCHAR2,
      p_cardtype     IN       NUMBER,
      p_feecode      IN       NUMBER,
      p_feeplan      IN       NUMBER,
      p_waivprcnt    IN       NUMBER,
      p_validfrom    IN       DATE,
      p_validto      IN       DATE,
      p_waivdesc     IN       VARCHAR2,
      p_lupduser     IN       NUMBER,
      p_iden_flag    IN       NUMBER,
      p_waiv_id      IN       NUMBER,
      p_errmsg       OUT      VARCHAR2
   )
   AS
      v_cfm_feetype_code   NUMBER (3);
      v_cnt                NUMBER;
      v_check_flag         CHAR(1):='Y';
      v_waiv_id            cms_prodcattype_waiv.cpw_waiv_id%TYPE; 
      v_old_from_date      cms_prodcattype_waiv.cpw_valid_from%TYPE;
      v_old_to_date        cms_prodcattype_waiv.cpw_valid_to%TYPE;
      v_new_from_date      cms_prodcattype_waiv.cpw_valid_from%TYPE; 
      e_reject_record      EXCEPTION;
    
       
      CURSOR cur_waiver(p_feecode cms_prodcattype_waiv.cpw_fee_code%TYPE,p_feeplan cms_prodcattype_waiv.cpw_fee_plan%TYPE) IS SELECT 
      cpw_valid_from,cpw_valid_to,cpw_waiv_id FROM cms_prodcattype_waiv WHERE
      cpw_fee_code=p_feecode AND cpw_fee_plan=p_feeplan AND cpw_prod_code=p_prodcode AND cpw_card_type=p_cardtype ;
    
      v_valid_from cms_prodcattype_waiv.cpw_valid_from%TYPE;
      v_valid_to   cms_prodcattype_waiv.cpw_valid_to%TYPE;
   
   BEGIN                                                        

          p_errmsg := 'OK';
          
      BEGIN                                                         
         SELECT cfm_feetype_code
           INTO v_cfm_feetype_code
           FROM cms_fee_mast
          WHERE cfm_inst_code = p_instcode AND cfm_fee_code = p_feecode;

      EXCEPTION                                              
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'No fee type found for this fee code';
            RAISE e_reject_record;
         WHEN OTHERS    THEN
            p_errmsg := 'Error while selecting from cms_fee_mast ' || SQLERRM;
            RAISE e_reject_record;
      END;                                                    
      
      BEGIN 
        
          select count(1) into v_cnt from cms_prodcattype_fees where 
          cpf_fee_plan=p_feeplan and (p_validfrom  BETWEEN cpf_valid_from AND nvl2(cpf_valid_to,cpf_valid_to,p_validfrom))
          and(nvl2(p_validto,p_validto,cpf_valid_from) >= cpf_valid_from) and
          (cpf_valid_to is null or (p_validto is not null and p_validto <=cpf_valid_to) ) AND cpf_prod_code=p_prodcode AND cpf_card_type=p_cardtype ;
          
         EXCEPTION
           WHEN OTHERS THEN
            p_errmsg := 'Error while selecting from cms_prodcattype_fees table'||sqlerrm;
            RAISE e_reject_record; 
            
      END;
    
     IF v_cnt=1 THEN
     
              BEGIN
                  
                  v_cnt:=NULL;
                  
                 OPEN cur_waiver(p_feecode,p_feeplan);
                      
                  LOOP
                      
                   FETCH cur_waiver INTO v_valid_from,v_valid_to,v_waiv_id ;
                                       
                     EXIT WHEN cur_waiver%NOTFOUND;
                   
                   
                        SELECT COUNT(1) INTO v_cnt FROM dual where 
                        v_valid_from  BETWEEN p_validfrom AND nvl2(p_validto,p_validto,p_validfrom) OR
                        nvl2(v_valid_to,v_valid_to,v_valid_from) BETWEEN p_validfrom AND  nvl2(p_validto,p_validto,p_validfrom) OR
                        p_validfrom  BETWEEN v_valid_from AND  nvl2(v_valid_to,v_valid_to,v_valid_from)OR
                        nvl2(p_validto,p_validto,p_validfrom)  BETWEEN v_valid_from AND nvl2(v_valid_to,v_valid_to,v_valid_from) or
                        (p_validto is null and v_valid_to is  null);
                  
                  
                        IF v_cnt <> 0 AND p_iden_flag='0' THEN
                            v_check_flag:='N';
                            EXIT;
                        END IF;

                        IF p_iden_flag='1' AND v_cnt <> 0 THEN
                            IF v_waiv_id <> p_waiv_id THEN
                                v_check_flag:='N';
                                EXIT;
                            END IF;
                        END IF;
                     
                  END LOOP;
                      
                CLOSE cur_waiver;
                
               EXCEPTION
                 WHEN OTHERS THEN
                  p_errmsg := 'Error while checking the date range'||sqlerrm;
                  RAISE e_reject_record; 
                  
               END;
                              
                  IF  v_check_flag='Y' THEN
                   
                     IF p_iden_flag=0 THEN
                     
                      BEGIN
                      
                       INSERT INTO cms_prodcattype_waiv
                              (cpw_inst_code, cpw_prod_code, cpw_card_type,
                               cpw_fee_code, cpw_waiv_prcnt, cpw_valid_from,
                               cpw_valid_to, cpw_waiv_desc, cpw_flow_source,
                               cpw_ins_user, cpw_lupd_user,cpw_fee_plan
                              )
                       VALUES (p_instcode, p_prodcode, p_cardtype,
                               p_feecode, p_waivprcnt, TRUNC (p_validfrom),
                               TRUNC (p_validto), p_waivdesc, 'PC',
                               p_lupduser, p_lupduser,p_feeplan
                              );
                              
                      EXCEPTION                                            
                       WHEN OTHERS THEN
                        p_errmsg := 'Error while inserting in to cms_card_excpwaiv'||sqlerrm;
                        RAISE e_reject_record;
                        
                      END; 
                      
                     ELSIF p_iden_flag=1  THEN
                     
                      BEGIN
                         
                         SELECT cpw_valid_from,cpw_valid_to INTO v_old_from_date,v_old_to_date  
                         FROM cms_prodcattype_waiv WHERE cpw_waiv_id = p_waiv_id;
                         
                          IF  TRUNC(v_old_from_date) <= TRUNC (SYSDATE)
                              AND ( TRUNC (v_old_to_date) >= TRUNC (SYSDATE) or v_old_to_date is NULL)
                              AND( TRUNC (p_validto) >= TRUNC (SYSDATE) or p_validto is NULL)  THEN
                           
                            v_new_from_date:=v_old_from_date;
                           
                          ELSIF   TRUNC (v_old_from_date) > TRUNC (SYSDATE)
                              AND (TRUNC (v_old_to_date) > TRUNC (SYSDATE)  or v_old_to_date is NULL)
                              AND TRUNC (p_validfrom) >= TRUNC (SYSDATE)
                              AND (TRUNC (p_validto) >= TRUNC (SYSDATE) or p_validto is NULL) THEN
                            
                            v_new_from_date:=p_validfrom;
                            
                          END IF;
                           
                           UPDATE cms_prodcattype_waiv
                           SET   cpw_waiv_prcnt = p_waivprcnt,
                                 cpw_valid_from = v_new_from_date,
                                 cpw_valid_to   = p_validto,
                                 cpw_waiv_desc  = p_waivdesc,
                                 cpw_lupd_user  = p_lupduser
                           WHERE cpw_waiv_id = p_waiv_id;
                         
                     EXCEPTION    
                       WHEN NO_DATA_FOUND THEN
                          p_errmsg := 'No data found for this waiv id in cms_prodcattype_waiv table';
                          RAISE e_reject_record;
                       WHEN OTHERS THEN
                          p_errmsg := 'Exception While selecting from  cms_prodcattype_waiv table'||sqlerrm;
                          RAISE e_reject_record;
                     END;
                     
                                        
                   END IF;
                 
                  ELSIF v_check_flag='N' THEN
                  
                    p_errmsg := 'Waiver already present for the given date range';
                    RAISE e_reject_record; 
                    
                  END IF;
                  
       ELSE
       
         p_errmsg :='No date range found for this feeplan in cms_prodcattype_waiv table';
         RAISE e_reject_record;
         
      END IF;                                                

    EXCEPTION    
      WHEN e_reject_record THEN
        ROLLBACK;
      WHEN OTHERS THEN
        p_errmsg := 'Main Exception from other handler -- ' || SQLERRM;
        ROLLBACK;
   END sp_create_prodcattypewaiv;                                                     

   PROCEDURE sp_create_prodwaiv (
      p_instcode    IN       NUMBER,
      p_prodcode    IN       VARCHAR2,
      p_feecode     IN       NUMBER,
      p_feeplan     IN       NUMBER,
      p_waivprcnt   IN       NUMBER,
      p_validfrom   IN       DATE,
      p_validto     IN       DATE,
      p_waivdesc    IN       VARCHAR2,
      p_lupduser    IN       NUMBER,
      p_iden_flag   IN       NUMBER,
      p_waiv_id     IN       NUMBER,
      p_errmsg      OUT      VARCHAR2
   )
   AS
      v_cfm_feetype_code   NUMBER (3);
      v_cnt                NUMBER;
      v_check_flag         CHAR(1):='Y';
      v_waiv_id            cms_prod_waiv.cpw_waiv_id%TYPE;
      v_old_from_date      cms_prod_waiv.cpw_valid_from%TYPE;
      v_old_to_date        cms_prod_waiv.cpw_valid_to%TYPE;
      v_new_from_date      cms_prod_waiv.cpw_valid_from%TYPE;
      e_reject_record      EXCEPTION;
    
       
      CURSOR cur_waiver(p_feecode cms_prod_waiv.cpw_fee_code%TYPE,p_feeplan cms_prod_waiv.cpw_fee_plan%TYPE) IS SELECT 
      cpw_valid_from,cpw_valid_to,cpw_waiv_id FROM cms_prod_waiv WHERE
      cpw_fee_code=p_feecode AND cpw_fee_plan=p_feeplan AND cpw_prod_code=p_prodcode;
    
      v_valid_from cms_prod_waiv.cpw_valid_from%TYPE;
      v_valid_to   cms_prod_waiv.cpw_valid_to%TYPE;

   BEGIN   
   
         p_errmsg := 'OK';
               
        BEGIN                                                        
            SELECT cfm_feetype_code
             INTO v_cfm_feetype_code
             FROM cms_fee_mast
            WHERE cfm_inst_code = p_instcode AND cfm_fee_code = p_feecode;
        EXCEPTION                                              
           WHEN NO_DATA_FOUND
           THEN
              p_errmsg := 'No fee type found for this fee code';
              RAISE e_reject_record;
           WHEN OTHERS    THEN
              p_errmsg := 'Error while selecting from cms_fee_mast ' || SQLERRM;
              RAISE e_reject_record;
        END;                                                   
                                            
        BEGIN
        
          select count(1) into v_cnt from cms_prod_fees where 
          cpf_fee_plan=p_feeplan and (p_validfrom  BETWEEN cpf_valid_from AND nvl2(cpf_valid_to,cpf_valid_to,p_validfrom))
          and(nvl2(p_validto,p_validto,cpf_valid_from) >= cpf_valid_from) and
          (cpf_valid_to is null or (p_validto is not null and p_validto <=cpf_valid_to) )  AND cpf_prod_code=p_prodcode;
          
         EXCEPTION
           WHEN OTHERS THEN
            p_errmsg := 'Error while selecting from cms_prod_fees table'||sqlerrm;
            RAISE e_reject_record; 
            
        END;
        
        IF v_cnt=1 THEN
    
              BEGIN
                  
                  v_cnt:=NULL;
                  
                 OPEN cur_waiver(p_feecode,p_feeplan);
                      
                  LOOP
                      
                   FETCH cur_waiver INTO v_valid_from,v_valid_to,v_waiv_id ;
                                       
                     EXIT WHEN cur_waiver%NOTFOUND;
                     
                   
                        SELECT COUNT(1) INTO v_cnt FROM dual where 
                        v_valid_from  BETWEEN p_validfrom AND nvl2(p_validto,p_validto,p_validfrom) OR
                        nvl2(v_valid_to,v_valid_to,v_valid_from) BETWEEN p_validfrom AND  nvl2(p_validto,p_validto,p_validfrom) OR
                        p_validfrom  BETWEEN v_valid_from AND  nvl2(v_valid_to,v_valid_to,v_valid_from)OR
                        nvl2(p_validto,p_validto,p_validfrom)  BETWEEN v_valid_from AND nvl2(v_valid_to,v_valid_to,v_valid_from) or
                        (p_validto is null and v_valid_to is  null);
                     
                        IF v_cnt <> 0 AND p_iden_flag='0' THEN
                            v_check_flag:='N';
                            EXIT;
                        END IF;

                        IF p_iden_flag='1' AND v_cnt <> 0 THEN
                            IF v_waiv_id <> p_waiv_id THEN
                                v_check_flag:='N';
                                EXIT;
                            END IF;
                        END IF;
                     
                  END LOOP;
                      
                CLOSE cur_waiver;
                
               EXCEPTION
                 WHEN OTHERS THEN
                  p_errmsg := 'Error while checking the date range'||sqlerrm;
                  RAISE e_reject_record; 
                  
               END;
                              
                  IF  v_check_flag='Y' THEN
                   
                   IF p_iden_flag=0 THEN
                    
                    BEGIN
                    
                     INSERT INTO cms_prod_waiv
                          (cpw_inst_code, cpw_prod_code, cpw_fee_code,
                           cpw_waiv_prcnt, cpw_valid_from, cpw_valid_to,
                           cpw_waiv_desc, cpw_ins_user, cpw_lupd_user,cpw_fee_plan
                          )
                     VALUES (p_instcode, p_prodcode, p_feecode,
                             p_waivprcnt , TRUNC (p_validfrom), TRUNC (p_validto),
                           --Modified by Ramkumar.MK on 27 aug 2012, waiver description store in upper
                           upper(p_waivdesc), p_lupduser, p_lupduser,p_feeplan 
                          );
                          
                     EXCEPTION                                            
                      WHEN OTHERS THEN
                       p_errmsg := 'Error while inserting in to cms_prod_waiv'||sqlerrm;
                       RAISE e_reject_record;
                       
                      END;  
                      
                    ELSIF p_iden_flag=1  THEN
                     
                      BEGIN
                         
                         SELECT cpw_valid_from,cpw_valid_to INTO v_old_from_date,v_old_to_date  
                         FROM cms_prod_waiv WHERE cpw_waiv_id = p_waiv_id;
                         
                          IF  TRUNC(v_old_from_date) <= TRUNC (SYSDATE)
                              AND ( TRUNC (v_old_to_date) >= TRUNC (SYSDATE) or v_old_to_date is NULL)
                              AND( TRUNC (p_validto) >= TRUNC (SYSDATE) or p_validto is NULL)  THEN
                           
                            v_new_from_date:=v_old_from_date;
                           
                          ELSIF   TRUNC (v_old_from_date) > TRUNC (SYSDATE)
                              AND (TRUNC (v_old_to_date) > TRUNC (SYSDATE)  or v_old_to_date is NULL)
                              AND TRUNC (p_validfrom) >= TRUNC (SYSDATE)
                              AND (TRUNC (p_validto) >= TRUNC (SYSDATE) or p_validto is NULL) THEN
                            
                            v_new_from_date:=p_validfrom;
                            
                          END IF;
                           
                           UPDATE cms_prod_waiv
                           SET   cpw_waiv_prcnt = p_waivprcnt,
                                 cpw_valid_from = v_new_from_date,
                                 cpw_valid_to   = p_validto,
                                   --Modified by Ramkumar.MK on 27 aug 2012, waiver description store in upper
                                 cpw_waiv_desc  = upper(p_waivdesc),
                                 cpw_lupd_user  = p_lupduser
                           WHERE cpw_waiv_id = p_waiv_id;
                         
                     EXCEPTION    
                       WHEN NO_DATA_FOUND THEN
                          p_errmsg := 'No data found for this waiv id in cms_prod_waiv table';
                          RAISE e_reject_record;
                       WHEN OTHERS THEN
                          p_errmsg := 'Exception While selecting from  cms_prod_waiv table'||sqlerrm;
                          RAISE e_reject_record;
                     END;
                     
                                        
                   END IF;
                   
                  ELSIF v_check_flag='N' THEN
                  
                    p_errmsg := 'Waiver already present for the given date range';
                    RAISE e_reject_record; 
                    
                  END IF;
                               
       ELSE
       
         p_errmsg :='No date range found for this feeplan in cms_prod_waiv table';
         RAISE e_reject_record;
         
      END IF;
      
  EXCEPTION    
      WHEN e_reject_record THEN
        ROLLBACK;
      WHEN OTHERS THEN
        p_errmsg := 'Main Exception from other handler -- ' || SQLERRM;
        ROLLBACK;
   END sp_create_prodwaiv;     
   
END PACK_CMS_WAIVATTACH;
/
show error;