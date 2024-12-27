CREATE OR REPLACE PROCEDURE VMSCMS.sp_define_prodcattyperulegroup (
   instcode        IN       NUMBER,
   prodcode        IN       VARCHAR2,
   cardtype        IN       NUMBER,
   rulegroupcode   IN       NUMBER,
   flowsource      IN       VARCHAR2,
   from_date       IN       DATE,
   TO_DATE         IN       DATE,
   lupduser        IN       NUMBER,
   errmsg          OUT      VARCHAR2
)
AS
/*************************************************
     * Created  By      :
     * Created  Date    :
     * Modified Reason  :  To update the rule group.
     * Modified BY      : Ram Kumar
     * Reviewer         : Nanda Kumar R.
     * Reviewed Date    : 24-May-2012
     * Build Number     : CMS3.4.4_RI0008_B00014
 *************************************************/
   v_flowsource            VARCHAR2 (3);
  -- newdate                 DATE;
  -- mesg                    VARCHAR2 (500);
   v_curr_rulegroup_code   NUMBER;
   v_curr_flow_source      VARCHAR2 (3);
   v_rule_indicator        CHAR (1);
   exp_reject_record        EXCEPTION;
BEGIN                                                             --Main begin
   errmsg := 'OK';

   IF flowsource = 'EXP'
   THEN                  --this means that the procedure is explicitly called
      v_flowsource := 'PCT';
   ELSE
--this means that the procedure is called from some level above PCT. i.e. from product level(P)
      v_flowsource := flowsource;
   END IF;

   BEGIN                                                             --begin 2
      BEGIN
         SELECT UNIQUE ppr_rulegroup_code, ppr_flow_source
                  INTO v_curr_rulegroup_code, v_curr_flow_source
                  FROM pcms_prodcattype_rulegroup a, rulegrouping b
                 WHERE a.ppr_inst_code = instcode
                   AND a.ppr_rulegroup_code = b.rulegroupid
                   AND a.ppr_rulegroup_code = rulegroupcode
                   AND a.ppr_prod_code = prodcode
                   AND a.ppr_card_type = cardtype
                   AND (   (ppr_valid_from BETWEEN from_date AND TO_DATE)
                        OR (ppr_valid_to BETWEEN from_date AND TO_DATE)
                        OR (from_date BETWEEN ppr_valid_from AND ppr_valid_to
                           )
                        OR (TO_DATE BETWEEN ppr_valid_from AND ppr_valid_to)
                       );

         IF (v_curr_flow_source = 'P' OR v_flowsource = 'PCT')
         THEN
            INSERT INTO pcms_attchrulegroup_hist
                        (pah_inst_code, pah_rulegroup_code,
                         pah_change_level, pah_prod_code, pah_cat_type,
                         pah_change_source, pah_action_taken, pah_change_user
                        )
                 VALUES (instcode, v_curr_rulegroup_code,
                         v_curr_flow_source, prodcode, cardtype,
                         v_flowsource, 'UPDATE', lupduser
                        );

            --Modified by Ramkumar.MK on 22 may 2012, update the rulegroup if daterange within the product
            --Defect id:7655
            UPDATE pcms_prodcattype_rulegroup
               SET ppr_rulegroup_code = rulegroupcode,
                   ppr_flow_source = v_flowsource,
                   ppr_valid_from = from_date,
                   ppr_valid_to = TO_DATE
             WHERE ppr_inst_code = instcode
               AND ppr_prod_code = prodcode
               AND ppr_card_type = cardtype
               AND (   (ppr_valid_from BETWEEN from_date AND TO_DATE)
                    OR (ppr_valid_to BETWEEN from_date AND TO_DATE)
                    OR (from_date BETWEEN ppr_valid_from AND ppr_valid_to)
                    OR (TO_DATE BETWEEN ppr_valid_from AND ppr_valid_to)
                   );
             IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN pcms_card_excp_rulegroup';
               RAISE exp_reject_record;
            END IF;

            UPDATE cms_prod_cattype
               SET cpc_rulegroup_code = rulegroupcode
             WHERE cpc_inst_code = instcode
               AND cpc_prod_code = prodcode
               AND cpc_card_type = cardtype;
            IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN cms_prod_cattype';
               RAISE exp_reject_record;
            END IF;

         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            INSERT INTO pcms_prodcattype_rulegroup
                        (ppr_inst_code, ppr_prod_code, ppr_card_type,
                         ppr_rulegroup_code, ppr_valid_from, ppr_valid_to,
                         ppr_flow_source, ppr_ins_user, ppr_lupd_user
                        )
                 VALUES (instcode, prodcode, cardtype,
                         rulegroupcode, from_date, TO_DATE,
                         v_flowsource, lupduser, lupduser
                        );

            UPDATE cms_prod_cattype
               SET cpc_rulegroup_code = rulegroupcode
             WHERE cpc_inst_code = instcode
               AND cpc_prod_code = prodcode
               AND cpc_card_type = cardtype;
               IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN cms_prod_cattype';
               RAISE exp_reject_record;
            END IF;
        WHEN OTHERS THEN
           errmsg := 'Excp 1 -- ' || SUBSTR(SQLERRM,1,200);
      END;
   EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;                                               --excp of begin 2
      WHEN OTHERS
      THEN
         errmsg := 'Excp 2 -- ' || SUBSTR(SQLERRM,1,200);
   END;                                                       --end of begin 2
EXCEPTION
  WHEN    exp_reject_record then
     errmsg := errmsg;                                          --Excp of main begin
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
 END;                                                          --End main begin
/


