CREATE OR REPLACE TRIGGER VMSCMS.trg_prod_rulegroup
   BEFORE INSERT
   ON pcms_prod_rulegroup
   FOR EACH ROW
DECLARE
   v_message   NUMBER := 0;

   CURSOR cur_prod_rule
   IS
      SELECT ppr_inst_code, ppr_prod_code, ppr_valid_from, ppr_valid_to, ppr_ins_user
      FROM   pcms_prod_rulegroup
       WHERE ppr_inst_code = :NEW.ppr_inst_code
         AND ppr_prod_code = :NEW.ppr_prod_code
         AND ppr_rulegroup_code = :NEW.ppr_rulegroup_code
          AND (   (ppr_valid_from BETWEEN :NEW.ppr_valid_from AND :NEW.ppr_valid_to
                 )
              OR (ppr_valid_to BETWEEN :NEW.ppr_valid_from AND :NEW.ppr_valid_to
                 )
              OR (:NEW.ppr_valid_from BETWEEN ppr_valid_from AND ppr_valid_to
                 )
              OR (:NEW.ppr_valid_to BETWEEN ppr_valid_from AND ppr_valid_to)
             );
BEGIN                                                     --<< main begin >>--
    
   IF :NEW.ppr_valid_from >= SYSDATE-1
   THEN
      FOR x IN cur_prod_rule
      LOOP
         IF cur_prod_rule%ROWCOUNT > 0
         THEN
            v_message := 1;
         END IF;

         IF v_message = 1
         THEN
            raise_application_error
                           (-20001,
                            'Same Rule group is already attached with the rule Type ' 
                           );
         END IF;
      END LOOP;
   END IF;
END;                                                  --<< main begin end >>--
/


