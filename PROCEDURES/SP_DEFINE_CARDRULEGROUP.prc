CREATE OR REPLACE PROCEDURE VMSCMS.sp_define_cardrulegroup (
   instcode        IN       NUMBER,
   rulegroupcode   IN       NUMBER,
   pancode         IN       VARCHAR2,
   mbrnumb         IN       VARCHAR2,
   flowsource      IN       VARCHAR2,
   from_date       IN       DATE,
   to_date        IN       DATE,
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
   v_mbrnum                VARCHAR2 (3);
   --newdate                 DATE;
   --mesg                    VARCHAR2 (500);
   v_curr_rulegroup_code   NUMBER;
   v_curr_flow_source      VARCHAR2 (3);
   v_rule_indicator        CHAR (1);
   exp_reject_record        EXCEPTION;
BEGIN                                                             --Main begin
   errmsg := 'OK';

   IF flowsource = 'P'
   THEN
      v_rule_indicator := 1;
      v_flowsource := flowsource;
   ELSIF flowsource = 'PCT'
   THEN
      v_rule_indicator := 2;
      v_flowsource := flowsource;
   ELSIF flowsource = 'EXP'
   THEN
      v_flowsource := 'C';
      v_rule_indicator := 3;
   ELSE
      v_flowsource := flowsource;
   END IF;

   IF mbrnumb IS NULL
   THEN
      v_mbrnum := '000';
   ELSE
      v_mbrnum := mbrnumb;
   END IF;

   BEGIN                                                             --begin 2
      BEGIN
         SELECT pcer_rulegroup_id, pcer_flow_source
           INTO v_curr_rulegroup_code, v_curr_flow_source
           FROM pcms_card_excp_rulegroup a, rulegrouping b
          WHERE a.pcer_inst_code = instcode
            AND a.pcer_rulegroup_id = b.rulegroupid
            AND a.pcer_rulegroup_id = rulegroupcode
            AND a.pcer_pan_code = gethash (pancode)
            AND (   (pcer_valid_from BETWEEN from_date AND to_date)
                 OR (pcer_valid_to BETWEEN from_date AND to_date)
                 OR (from_date BETWEEN pcer_valid_from AND pcer_valid_to)
                 OR (to_date BETWEEN pcer_valid_from AND pcer_valid_to)
                );

         INSERT INTO pcms_attchrulegroup_hist
                     (pah_inst_code, pah_rulegroup_code, pah_change_level,
                      pah_pan_code, pah_change_source, pah_action_taken,
                      pah_change_user, pah_epan_code
                     )
              VALUES (instcode, v_curr_rulegroup_code, v_curr_flow_source,
                      gethash (pancode), v_flowsource, 'UPDATE',
                      lupduser, fn_emaps_main (pancode)
                     );

         --Modified by Ramkumar.MK on 22 may 2012, update the rulegroup if daterange within the card
         --Defect id:7655
         UPDATE pcms_card_excp_rulegroup
            SET pcer_rulegroup_id = rulegroupcode,
                pcer_flow_source = v_flowsource,
                pcer_valid_from = from_date,
                pcer_valid_to = to_date
          WHERE pcer_inst_code = instcode
            AND pcer_pan_code = gethash (pancode)
            AND (   (pcer_valid_from BETWEEN from_date AND to_date)
                 OR (pcer_valid_to BETWEEN from_date AND to_date)
                 OR (from_date BETWEEN pcer_valid_from AND pcer_valid_to)
                 OR (to_date BETWEEN pcer_valid_from AND pcer_valid_to)
                );
            IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN pcms_card_excp_rulegroup';
               RAISE exp_reject_record;
            END IF;

         UPDATE cms_appl_pan
            SET cap_rulegroup_code = rulegroupcode,
                cap_rule_indicator = v_rule_indicator
          WHERE cap_pan_code = gethash (pancode);
           IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN cms_appl_pan';
               RAISE exp_reject_record;
            END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            INSERT INTO pcms_card_excp_rulegroup
                        (pcer_inst_code, pcer_rulegroup_id, pcer_pan_code,
                         pcer_mbr_numb, pcer_valid_from, pcer_valid_to,
                         pcer_flow_source, pcer_ins_user, pcer_lupd_user,
                         pcer_delete_flg, pcer_pan_code_encr
                        )
                 VALUES (instcode, rulegroupcode, gethash (pancode),
                         v_mbrnum, from_date, to_date,
                         v_flowsource, lupduser, lupduser,
                         'N', fn_emaps_main (pancode)
                        );

            UPDATE cms_appl_pan
               SET cap_rulegroup_code = rulegroupcode,
                   cap_rule_indicator = v_rule_indicator
             WHERE cap_pan_code = gethash (pancode);
             IF SQL%ROWCOUNT = 0 THEN
               errmsg:='ERROR WHILE UPDATING RECORD IN cms_appl_pan';
               RAISE exp_reject_record;
            END IF;
        WHEN OTHERS THEN
           errmsg := 'Excp 1 -- ' || SUBSTR(SQLERRM,1,200);
      END;
   EXCEPTION
      WHEN exp_reject_record THEN
      RAISE;                                            --excp of begin 2
      WHEN OTHERS
      THEN
         errmsg := 'Excp 2 -- ' || SQLERRM;
   END;                                                       --end of begin 2
EXCEPTION
WHEN exp_reject_record THEN
     errmsg := errmsg;                                                --Excp of main begin
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;  --End main begin
/


