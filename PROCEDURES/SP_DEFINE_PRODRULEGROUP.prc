CREATE OR REPLACE PROCEDURE VMSCMS."SP_DEFINE_PRODRULEGROUP" (
   instcode        IN       NUMBER,
   prodcode        IN       VARCHAR2,
   rulegroupcode   IN       VARCHAR2,
   from_date       IN       DATE,
   TO_DATE         IN       DATE,
   lupduser        IN       NUMBER,
   errmsg          OUT      VARCHAR2
)
AS
   /*************************************************
       * Modified By      :  Dhiraj Gaikwad
       * Modified Date    :  12-June-2012
       * Modified Reason  :  Data type change for variable v_curr_rulegroup_code from NUMBER To Varchar2(6), bcz getting error invalid number
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     :  RI0009_B0014
   *************************************************/
   --newdate                 DATE;
   --mesg                    VARCHAR2 (500);
   v_curr_rulegroup_code   VARCHAR2 (6);--NUMBER; Dhiraj Gaikwad 12062012
   v_curr_flow_source      VARCHAR2 (3);
   v_rule_indicator        CHAR (1);
   --cnt                     NUMBER;
   exp_reject_record       EXCEPTION;
BEGIN
   errmsg := 'OK';

      /*
      INSERT INTO pcms_attchrulegroup_hist
                  (pah_inst_code, pah_rulegroup_code, pah_change_level,
                   pah_prod_code, pah_change_source, pah_action_taken,
                   pah_change_user
                  )
           VALUES (instcode, rulegroupcode, 'P',
                   prodcode, 'P', 'UPDATE',
                   lupduser
                  );

   --Begin Added by Ramkumar.MK on 26 April 2012 for defect id 7461
      BEGIN
         SELECT COUNT (*)
           INTO cnt
           FROM pcms_prod_rulegroup
          WHERE ppr_prod_code = prodcode AND ppr_rulegroup_code = rulegroupcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg := 'Prod rule group Exception -- ' || SQLERRM;
      END;
   --End Added by Ramkumar.MK on 26 April 2012 for defect id 7461

      IF cnt = 0
      THEN
         INSERT INTO pcms_prod_rulegroup
                     (ppr_inst_code, ppr_prod_code, ppr_rulegroup_code,
                      ppr_valid_from, ppr_valid_to, ppr_ins_user, ppr_lupd_user
                     )
              VALUES (instcode, prodcode, rulegroupcode,
                      from_date, TO_DATE, lupduser, lupduser
                     );

            --Begin Added by Ramkumar.MK on 26 April 2012 for defect id 7461

         UPDATE cms_prod_mast
            SET cpm_rulegroup_code = rulegroupcode
          WHERE cpm_inst_code = instcode AND cpm_prod_code = prodcode;
   --End Added by Ramkumar.MK on 26 April 2012 for defect id 7461

      ELSE
         UPDATE pcms_prod_rulegroup
            SET ppr_valid_from = from_date,
                ppr_valid_to = TO_DATE,
                ppr_ins_user = lupduser,
                ppr_lupd_user = lupduser
          WHERE ppr_prod_code = prodcode
            AND ppr_rulegroup_code = rulegroupcode
            AND ppr_inst_code = instcode;
      END IF;
   */
     --Modified by Ramkumar.MK  on May 22 2012 to attach a rulegroup for the product based date range
   --Defect ID : 7655
   BEGIN                                                            --begin 2
      BEGIN
         SELECT UNIQUE ppr_rulegroup_code
                  INTO v_curr_rulegroup_code
                  FROM pcms_prod_rulegroup a, rulegrouping b
                 WHERE a.ppr_inst_code = instcode
                   AND a.ppr_rulegroup_code = b.rulegroupid
                   AND a.ppr_rulegroup_code = rulegroupcode
                   AND a.ppr_prod_code = prodcode
                   AND (   (ppr_valid_from BETWEEN from_date AND TO_DATE)
                        OR (ppr_valid_to BETWEEN from_date AND TO_DATE)
                        OR (from_date BETWEEN ppr_valid_from AND ppr_valid_to
                           )
                        OR (TO_DATE BETWEEN ppr_valid_from AND ppr_valid_to)
                       );

         INSERT INTO pcms_attchrulegroup_hist
                     (pah_inst_code, pah_rulegroup_code, pah_change_level,
                      pah_prod_code, pah_change_source, pah_action_taken,
                      pah_change_user
                     )
              VALUES (instcode, rulegroupcode, 'P',
                      prodcode, 'P', 'UPDATE',
                      lupduser
                     );

         UPDATE pcms_prod_rulegroup
            SET ppr_valid_from = from_date,
                ppr_valid_to = TO_DATE,
                ppr_ins_user = lupduser,
                ppr_lupd_user = lupduser,
                ppr_rulegroup_code = rulegroupcode
          WHERE ppr_prod_code = prodcode
            AND ppr_rulegroup_code = v_curr_rulegroup_code
            AND ppr_inst_code = instcode
            AND (   (ppr_valid_from BETWEEN from_date AND TO_DATE)
                 OR (ppr_valid_to BETWEEN from_date AND TO_DATE)
                 OR (from_date BETWEEN ppr_valid_from AND ppr_valid_to)
                 OR (TO_DATE BETWEEN ppr_valid_from AND ppr_valid_to)
                );

         UPDATE cms_prod_mast
            SET cpm_rulegroup_code = rulegroupcode
          WHERE cpm_inst_code = instcode AND cpm_prod_code = prodcode;

         IF SQL%ROWCOUNT = 0
         THEN
            errmsg := 'ERROR WHILE UPDATING RECORD IN cms_prod_mast';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            INSERT INTO pcms_prod_rulegroup
                        (ppr_inst_code, ppr_prod_code, ppr_rulegroup_code,
                         ppr_valid_from, ppr_valid_to, ppr_ins_user,
                         ppr_lupd_user
                        )
                 VALUES (instcode, prodcode, rulegroupcode,
                         from_date, TO_DATE, lupduser,
                         lupduser
                        );
         WHEN TOO_MANY_ROWS
         THEN
            DELETE FROM pcms_prod_rulegroup
                  WHERE ppr_prod_code = prodcode
                    AND ppr_rulegroup_code = rulegroupcode;

            INSERT INTO pcms_prod_rulegroup
                        (ppr_inst_code, ppr_prod_code, ppr_rulegroup_code,
                         ppr_valid_from, ppr_valid_to, ppr_ins_user,
                         ppr_lupd_user
                        )
                 VALUES (instcode, prodcode, rulegroupcode,
                         from_date, TO_DATE, lupduser,
                         lupduser
                        );
         WHEN OTHERS
         THEN
            errmsg := 'Excp 1 -- ' || SUBSTR (SQLERRM, 1, 200);
      END;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;                           --excp of begin 2
      WHEN OTHERS
      THEN
         errmsg := 'Excp 2 -- ' || SQLERRM;
   END;                                                       --end of begin 2
EXCEPTION
   WHEN exp_reject_record
   THEN
      errmsg := errmsg;
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;
/


