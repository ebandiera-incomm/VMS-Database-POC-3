CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Cardexcprule (
   p_instcode       IN       NUMBER,
   p_rulegroup_id   IN       NUMBER,
   p_pancode        IN       VARCHAR2,
   p_mbrnumb        IN       VARCHAR2,
   p_validfrom      IN       DATE,
   p_validto        IN       DATE,
   p_lupduser       IN       NUMBER,
   p_errmsg         OUT      VARCHAR2
)
AS
 /*
  * VERSION               :  1.0
  * DATE OF CREATION      : 23/Feb/2006
  * CREATED BY            : Chandrashekar Gurram.
  * PURPOSE               : Module to attach rule group to a pan.
  * MODIFICATION REASON   :
  *
  *
  * LAST MODIFICATION DONE BY :
  * LAST MODIFICATION DATE    :
  *
***/
   v_pcer_rulegroup_id   PCMS_CARD_EXCP_RULEGROUP.pcer_rulegroup_id%TYPE;
   v_newdate               DATE;
   v_flowsource            CHAR (1);
   v_mbrnumb             VARCHAR2 (3);
   CURSOR c1
   IS
      SELECT a.*
        FROM PCMS_CARD_EXCP_RULEGROUP a, RULEGROUPING b
       WHERE a.pcer_inst_code = p_instcode
         AND a.pcer_pan_code = p_pancode
         AND a.pcer_mbr_numb = v_mbrnumb
	 AND a.pcer_delete_flg != 'Y'
         AND a.pcer_rulegroup_id = b.rulegroupid
         AND (   TRUNC (p_validfrom) BETWEEN TRUNC (pcer_valid_from)
                                       AND TRUNC (pcer_valid_to)
              OR TRUNC (p_validfrom) < TRUNC (pcer_valid_from)
             );
BEGIN                                                      --main begin starts
   v_flowsource := 'C';
-- C is hard coded because this procedure is always called explicitly,
-- i.e. when the fee is to be attached to the card level,
-- so no flow source will come from any of the levels above card level
   --here change level and change source both are same
   IF p_mbrnumb IS NULL
   THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := p_mbrnumb ;
   END IF;
   p_errmsg := 'OK';
   BEGIN                                                      --begin 1 starts
      FOR x IN c1
      LOOP
         --now perform the reqd operation on the current row of the resultset
         IF TRUNC (p_validfrom) <= TRUNC (x.pcer_valid_from)
         THEN
            -- set delete flag to 'Y' for the row,
	    -- so the pcms application considers it as deleted
            UPDATE PCMS_CARD_EXCP_RULEGROUP
               SET pcer_delete_flg = 'Y'
             WHERE pcer_inst_code = p_instcode
               AND pcer_pan_code = p_pancode
               AND pcer_mbr_numb = v_mbrnumb
               AND pcer_rulegroup_id = x.pcer_rulegroup_id
               AND pcer_valid_from = x.pcer_valid_from
               AND pcer_valid_to = x.pcer_valid_to;
            IF SQL%ROWCOUNT = 1
            THEN
               p_errmsg := 'OK';
            ELSE
               p_errmsg :=
                     'Problem in deletion of rule group code '
                  || x.pcer_rulegroup_id
                  || ' PAN '
                  || p_pancode;
            END IF;
         ELSE
            -- set delete flag to 'Y' for the row,
	    -- so the pcms application considers it as deleted
            UPDATE PCMS_CARD_EXCP_RULEGROUP
               SET pcer_delete_flg = 'Y'
             WHERE pcer_inst_code = p_instcode
               AND pcer_pan_code = p_pancode
               AND pcer_mbr_numb = v_mbrnumb
               AND pcer_rulegroup_id = x.pcer_rulegroup_id
               AND pcer_valid_from = x.pcer_valid_from
               AND pcer_valid_to = x.pcer_valid_to;
            IF SQL%ROWCOUNT = 1
            THEN
               p_errmsg := 'OK';
            ELSE
               p_errmsg :=
                     'Problem in updation of rule group code '
                  || x.pcer_rulegroup_id
                  || ' PAN '
                  || p_pancode;
            END IF;
            -- create new entry for the current row with status/delete flag as modified
	    v_newdate := TRUNC (p_validfrom) - 1;
            INSERT INTO PCMS_CARD_EXCP_RULEGROUP
                 VALUES (x.pcer_inst_code, x.pcer_rulegroup_id,
                         x.pcer_pan_code, x.pcer_mbr_numb, x.pcer_valid_from,
                         v_newdate, x.pcer_flow_source, x.pcer_ins_user,
                         x.pcer_ins_date, p_lupduser, x.pcer_lupd_date, 'M');
         END IF;
         EXIT WHEN c1%NOTFOUND;
      END LOOP;
       -- create a new entry/ attach rulegroup to the pan.
      INSERT INTO PCMS_CARD_EXCP_RULEGROUP
                  (pcer_inst_code, pcer_rulegroup_id, pcer_pan_code,
                   pcer_mbr_numb, pcer_valid_from, pcer_valid_to,
                   pcer_flow_source, pcer_ins_user, pcer_lupd_user,
                   pcer_delete_flg
                  )
           VALUES (p_instcode, p_rulegroup_id, p_pancode,
                   v_mbrnumb, TRUNC (p_validfrom), TRUNC (p_validto),
                   v_flowsource, p_lupduser, p_lupduser,
                   'N'
                  );
   EXCEPTION                                                 --excp of begin 1
      WHEN OTHERS
      THEN
         p_errmsg := 'Error in sp_create_cardexcprule - when others: ' || SQLERRM;
   END;                                                         --begin 1 ends
EXCEPTION                                          ----exception of main begin
   WHEN OTHERS
   THEN
      p_errmsg := 'Error in main sp_create_cardexcprule - when others: ' || SQLERRM;
END Sp_Create_Cardexcprule;                             --main begin ends
/


