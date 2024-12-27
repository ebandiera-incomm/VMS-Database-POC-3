CREATE OR REPLACE PROCEDURE VMSCMS.sp_calc_loyl_prior (
   instcode   IN       NUMBER,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   yes_no                     CHAR (1);
   excp_flag                  NUMBER (1);
   pccc_flag                  NUMBER (1);
   v_clm_loyl_catg            NUMBER (3);
   v_cpl_loyl_code            NUMBER (3);
   v_cce_loyl_code            NUMBER (3);
   v_clm_loyl_catg_prod       NUMBER (3);
   v_clm_loyl_catg_pccc       NUMBER (3);
   v_clm_loyl_catg_excp       NUMBER (3);
   excp_temp_loyl_code        NUMBER (3);
   excp_temp_trans_amt        NUMBER;
   excp_temp_loyl_point       NUMBER;
   pccc_temp_loyl_code        NUMBER (3);
   pccc_temp_trans_amt        NUMBER;
   pccc_temp_loyl_point       NUMBER;
   applicable_loyl_code       NUMBER (3);
   applicable_trans_amt       NUMBER;
   applicable_loyl_point      NUMBER;
   applicable_slab_code       NUMBER (3);
   calc_loyl_points           NUMBER (5);         --calculated loyalty points
   addon_for_insert           VARCHAR2 (20);
   mbr_for_addon              VARCHAR2 (3);
   excp_addon                 VARCHAR2 (20);
   excp_mbr                   VARCHAR2 (3);
   excp_slabout_code          NUMBER (3);
   pccc_slabout_code          NUMBER (3);
   slab_flag                  CHAR (1);
   pccc_temp_loyl_point_out   NUMBER;
   excp_temp_loyl_point_out   NUMBER;
   v_card_level_prior         NUMBER;
   v_pccc_level_prior         NUMBER;
   v_raise_exception          EXCEPTION;
   rec_cnt                    NUMBER (15)   := 0;

--main cursor which picks up the transactions to calculate loyalty points
   CURSOR c1
   IS
      SELECT   ROWID, cpt_id_col, cpt_auth_code, cpt_trans_type,
               cpt_trans_date, cpt_trans_amt, cpt_term_id, cpt_mcc_code,
               cpt_merc_id, TRIM (cpt_pan_code) cpt_pan_code, cpt_mbr_numb,
               cpt_addon_link, cpt_mbr_link, cpt_addon_stat, cpt_prod_code,
               cpt_card_type, cpt_cust_code, cpt_cust_catg, cpt_loyl_calc,
               cpt_loyl_calcdate, cpt_ins_user, cpt_ins_date, cpt_lupd_user,
               cpt_lupd_date, cpt_trans_code, TRIM (cpt_acct_no) cpt_acct_no,
               cpt_acq_bank
          FROM cms_pan_trans
         WHERE cpt_inst_code = instcode
		 ---AND cpt_pan_code = '4667061100000015'for testing purpos
           AND cpt_rec_typ = '02'
           AND cpt_trans_code = '10'
           AND cpt_loyl_calc = 'N'
-- added on  to populate properly in the monthwise loyalty table
      ORDER BY cpt_trans_date;

--now find out whether there is any loyalty scheme attached to the pan at the card exceptional level
   CURSOR c2 (c_pancode IN VARCHAR2, c_mbrnumb IN VARCHAR2, c_transdate IN DATE)
   IS
      SELECT a.cce_loyl_code, b.clm_loyl_catg, c.clc_catg_prior
        FROM cms_card_excployl a, cms_loyl_mast b, cms_loyl_catg c
       WHERE a.cce_inst_code = b.clm_inst_code
         AND a.cce_loyl_code = b.clm_loyl_code
         AND b.clm_inst_code = c.clc_inst_code
         AND b.clm_loyl_catg = c.clc_catg_code
         AND a.cce_inst_code = instcode
         AND a.cce_pan_code = c_pancode
         AND a.cce_mbr_numb = c_mbrnumb
         AND c.clc_catg_code != 9
         AND TRUNC (c_transdate) BETWEEN TRUNC (cce_valid_from)
                                     AND TRUNC (cce_valid_to);

--now find out whether there is any loyalty scheme attached to the pan generally
   CURSOR c3 (c_prodcode IN VARCHAR2, c_cardtype IN NUMBER, c_transdate IN DATE)
   IS
      SELECT a.cpl_loyl_code, b.clm_loyl_catg, c.clc_catg_prior
        FROM cms_prodcattype_loyl a, cms_loyl_mast b, cms_loyl_catg c
       WHERE a.cpl_inst_code = b.clm_inst_code
         AND a.cpl_loyl_code = b.clm_loyl_code
         AND b.clm_inst_code = c.clc_inst_code
         AND b.clm_loyl_catg = c.clc_catg_code
         AND a.cpl_inst_code = instcode
         AND a.cpl_prod_code = c_prodcode
         AND a.cpl_card_type = c_cardtype
         AND c.clc_catg_code != 9
         AND TRUNC (c_transdate) BETWEEN TRUNC (cpl_valid_from)
                                     AND TRUNC (cpl_valid_to);

   ---------------------------Sn local procedures to find out the applicable loyalties-----------------------------
-----------------------------Sn 0. local procedure to find out whether there is any loyalty based on customer category-----------------------------
   PROCEDURE lp_find_custcatg_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr0          OUT      VARCHAR2
   )
   IS
   BEGIN                                                           --begin lp0
      lperr0 := 'OK';

      SELECT ccl_trans_amt, ccl_loyl_point
        INTO lp_trans_amt, lp_loyl_point
        FROM cms_custcatg_loyl
       WHERE ccl_inst_code = instcode AND ccl_loyl_code = lp_loyl_code;

      lp_yes_no := 'Y';
   EXCEPTION                                                        --excp lp0
      WHEN NO_DATA_FOUND
      THEN
         lperr0 := 'No loyalty found in customer category loyalty.';
      WHEN OTHERS
      THEN
         lperr0 := 'Excp LP0-1 --' || SQLERRM;
   END;                                                              --end lp0

-----------------------------Sn 1.local procedure to find out whether there is any loyalty based on merchant category code-----------------------------
   PROCEDURE lp_find_merccatg_loyl (
      lp_loyl_code       IN       NUMBER,
      lp_merccatg_code   IN       VARCHAR2,
      lp_yes_no          OUT      CHAR,
      lp_trans_amt       OUT      NUMBER,
      lp_loyl_point      OUT      NUMBER,
      lperr1             OUT      VARCHAR2
   )
   IS
      v_cml_merc_catg   VARCHAR2 (4);
   BEGIN                                                           --begin lp1
      lperr1 := 'OK';

      SELECT cml_merc_catg, cml_trans_amt, cml_loyl_point
        INTO v_cml_merc_catg, lp_trans_amt, lp_loyl_point
        FROM cms_merccatg_loyl
       WHERE cml_inst_code = instcode AND cml_loyl_code = lp_loyl_code;

      IF v_cml_merc_catg = lp_merccatg_code
      THEN
         lp_yes_no := 'Y';
      ELSE
         lp_yes_no := 'N';
      END IF;
   EXCEPTION                                                     --excp of lp1
      WHEN NO_DATA_FOUND
      THEN
         lperr1 := 'No loyalty found in merchant categorywise loyalty master';
      WHEN OTHERS
      THEN
         lperr1 := 'Excp LP1-1 --' || SQLERRM;
   END;                                                              --end lp1

-----------------------------Sn 2.local procedure to find out whether there is any loyalty based on merchant code-----------------------------
   PROCEDURE lp_find_merc_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_acq_bank     IN       VARCHAR2,
      lp_term_id      IN       VARCHAR2,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr2          OUT      VARCHAR2
   )
   IS
      v_cml_merc_code   VARCHAR2 (8);
      v_ctm_merc_code   VARCHAR2 (8);
   BEGIN
      lperr2 := 'OK';

      BEGIN                                                     --begin lp2.1
         SELECT ctm_merc_code
           INTO v_ctm_merc_code
           FROM cms_term_mast
          WHERE ctm_inst_code = instcode
            AND ctm_bank_id = lp_acq_bank
            AND ctm_term_id = lp_term_id
            AND ctm_rel_stat = 'Y';
      EXCEPTION                                                --excp of lp2.1
         WHEN NO_DATA_FOUND
         THEN
            lperr2 := 'No such Merchant found for terminal --' || lp_term_id;
         WHEN OTHERS
         THEN
            lperr2 := 'Excp LP2.1-1 --' || SQLERRM;
      END;                                                      --end of lp2.1

      IF lperr2 = 'OK'
      THEN
         BEGIN                                                  --begin lp2.2
            SELECT cml_merc_code, cml_trans_amt, cml_loyl_point
              INTO v_cml_merc_code, lp_trans_amt, lp_loyl_point
              FROM cms_merc_loyl
             WHERE cml_inst_code = instcode AND cml_loyl_code = lp_loyl_code;

            IF v_ctm_merc_code = v_cml_merc_code
            THEN
               lp_yes_no := 'Y';
            ELSE
               lp_yes_no := 'N';
            END IF;
         EXCEPTION                                               --excp of lp2
            WHEN NO_DATA_FOUND
            THEN
               lperr2 := 'No loyalty found in merchant wise loyalty master';
            WHEN OTHERS
            THEN
               lperr2 := 'Excp LP2.2-1 --' || SQLERRM;
         END;                                                        --end lp2
      END IF;
   END;

-----------------------------Sn 3.local procedure to find out whether there is any loyalty based on city code-----------------------------
   PROCEDURE lp_find_city_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_pan          IN       VARCHAR2,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr3          OUT      VARCHAR2
   )
   IS
      v_cbm_cntry_code   NUMBER (3);
      v_cbm_city_code    NUMBER (5);
      v_ccl_cntry_code   NUMBER (3);
      v_ccl_city_code    NUMBER (5);
   BEGIN                                                           --begin lp3
      lperr3 := 'OK';

      BEGIN                                                     --begin lp3.1
         SELECT cbm_cntry_code, cbm_city_code
           INTO v_cbm_cntry_code, v_cbm_city_code
           FROM cms_bran_mast
          WHERE cbm_inst_code = instcode
            AND cbm_bran_code = SUBSTR (lp_pan, 7, 4);
      --used substr to avoid querying cms_appl_pan
      EXCEPTION                                                --excp of lp3.1
         WHEN NO_DATA_FOUND
         THEN
            lperr3 :=
                  'No such city found for branch --' || SUBSTR (lp_pan, 7, 4);
         WHEN OTHERS
         THEN
            lperr3 := 'Excp LP3-1 --' || SQLERRM;
      END;                                                      --end of lp3.1

      IF lperr3 = 'OK'
      THEN
         BEGIN                                                  --begin lp3.2
            SELECT ccl_cntry_code, ccl_city_code, ccl_trans_amt,
                   ccl_loyl_point
              INTO v_ccl_cntry_code, v_ccl_city_code, lp_trans_amt,
                   lp_loyl_point
              FROM cms_city_loyl
             WHERE ccl_inst_code = instcode AND ccl_loyl_code = lp_loyl_code;

            IF     v_ccl_cntry_code = v_cbm_cntry_code
               AND v_ccl_city_code = v_cbm_city_code
            THEN
               lp_yes_no := 'Y';
            ELSE
               lp_yes_no := 'N';
            END IF;
         EXCEPTION                                             --excp of lp3.2
            WHEN NO_DATA_FOUND
            THEN
               lperr3 := 'No loyalty found in city wise loyalty master';
            WHEN OTHERS
            THEN
               lperr3 := 'Excp LP3-2 --' || SQLERRM;
         END;                                                   --end of lp3.2
      END IF;
   EXCEPTION                                                     --excp of lp3
      WHEN OTHERS
      THEN
         lperr3 := 'Excp LP3 --' || SQLERRM;
   END;                                                              --end lp3

-----------------------------Sn 4.local procedure to find out whether there is any monthwise loyalty-----------------------------
   PROCEDURE lp_find_month_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_transdate    IN       DATE,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr4          OUT      VARCHAR2
   )
   IS
      v_cml_first_date   DATE;
      v_cml_last_date    DATE;
   BEGIN                                                           --begin lp4
      lperr4 := 'OK';

      SELECT cml_first_date, cml_last_date, cml_trans_amt, cml_loyl_point
        INTO v_cml_first_date, v_cml_last_date, lp_trans_amt, lp_loyl_point
        FROM cms_month_loyl
       WHERE cml_inst_code = instcode AND cml_loyl_code = lp_loyl_code;

      IF TRUNC (lp_transdate) BETWEEN TRUNC (v_cml_first_date)
                                  AND TRUNC (v_cml_last_date)
      THEN
         lp_yes_no := 'Y';
      ELSE
         lp_yes_no := 'N';
      END IF;
   EXCEPTION                                                     --excp of lp4
      WHEN NO_DATA_FOUND
      THEN
         lperr4 := 'No loyalty found in month wise loyalty master';
      WHEN OTHERS
      THEN
         lperr4 := 'Excp LP4-1 --' || SQLERRM;
   END;                                                              --end lp4

-----------------------------Sn 5.local procedure to find out whether there is any datewise loyalty-----------------------------
   PROCEDURE lp_find_date_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_transdate    IN       DATE,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr5          OUT      VARCHAR2
   )
   IS
      v_cdl_date_oftrans   DATE;
   BEGIN                                                           --begin lp5
      lperr5 := 'OK';

      SELECT cdl_date_oftrans, cdl_trans_amt, cdl_loyl_point
        INTO v_cdl_date_oftrans, lp_trans_amt, lp_loyl_point
        FROM cms_date_loyl
       WHERE cdl_inst_code = instcode AND cdl_loyl_code = lp_loyl_code;

      IF TRUNC (lp_transdate) = TRUNC (v_cdl_date_oftrans)
      THEN
         lp_yes_no := 'Y';
      ELSE
         lp_yes_no := 'N';
      END IF;
   EXCEPTION                                                     --excp of lp5
      WHEN NO_DATA_FOUND
      THEN
         lperr5 := 'No loyalty found in date wise loyalty master';
      WHEN OTHERS
      THEN
         lperr5 := 'Excp LP5-1 --' || SQLERRM;
   END;                                                              --end lp5

-----------------------------Sn 6.local procedure to find out the whether there is any default loyalty-----------------------------
   PROCEDURE lp_find_def_loyl (
      lp_loyl_code    IN       NUMBER,
      lp_yes_no       OUT      CHAR,
      lp_trans_amt    OUT      NUMBER,
      lp_loyl_point   OUT      NUMBER,
      lperr6          OUT      VARCHAR2
   )
   IS
   BEGIN                                                           --begin lp6
      lperr6 := 'OK';

      SELECT cdl_trans_amt, cdl_loyl_point
        INTO lp_trans_amt, lp_loyl_point
        FROM cms_def_loyl
       WHERE cdl_inst_code = instcode AND cdl_loyl_code = lp_loyl_code;

      lp_yes_no := 'Y';
   EXCEPTION                                                     --excp of lp6
      WHEN NO_DATA_FOUND
      THEN
         lperr6 := 'No loyalty found in default loyalty master';
      WHEN OTHERS
      THEN
         lperr6 := 'Excp LP6-1 --' || SQLERRM;
   END;                                                              --end lp6

-----------------------------Sn 7.local procedure to find out the whether there is any slabwise loyalty-----------------------------
   PROCEDURE lp_find_slab_loyl (
      lp_loyl_code   IN       NUMBER,
      lp_yes_no      OUT      CHAR,
      slabout_code   OUT      NUMBER,
      lperr7         OUT      VARCHAR2
   )
   IS
   BEGIN                                                           --begin lp7
      lperr7 := 'OK';

      SELECT csl_slab_code
        INTO slabout_code
        FROM cms_slab_loyl
       WHERE csl_inst_code = instcode AND csl_loyl_code = lp_loyl_code;

      lp_yes_no := 'Y';
   EXCEPTION                                                        --excp lp7
      WHEN NO_DATA_FOUND
      THEN
         lperr7 := 'No loyalty found in Slab loyalty master';
      WHEN OTHERS
      THEN
         lperr7 := 'Excp LP7-1 --' || SQLERRM;
   END;                                                              --end lp7

-----------------------------Sn 8. local procedure to calculate the slabwise loyalty points-----------------------------
   PROCEDURE lp_calc_slab_loyl_points (
      slabcode           IN       NUMBER,
      trans_amt          IN       NUMBER,
      calc_loyl_points   OUT      NUMBER,
      lperr8             OUT      VARCHAR2
   )
   IS
      lp_trans_amt          NUMBER;
      slab_amt              NUMBER;
      lp_calc_loyl_points   NUMBER;

      CURSOR lpc1
      IS
         SELECT   csd_from_amt, csd_to_amt, csd_trans_amt, csd_loyl_point
             FROM cms_slabloyl_dtl
            WHERE csd_inst_code = instcode AND csd_slab_code = slabcode
         ORDER BY csd_from_amt;
   BEGIN                                                           --begin lp8
      lperr8 := 'OK';
      lp_trans_amt := trans_amt;
      calc_loyl_points := 0;

      FOR a IN lpc1
      LOOP
         IF a.csd_from_amt = 0
         THEN
            slab_amt := a.csd_to_amt - a.csd_from_amt;
         ELSE
            slab_amt := a.csd_to_amt - a.csd_from_amt;
         END IF;

         IF slab_amt > lp_trans_amt
         THEN
            SELECT   ROUND (NVL (lp_trans_amt, 0) / a.csd_trans_amt)
                   * a.csd_loyl_point
              INTO lp_calc_loyl_points
              FROM DUAL;

            calc_loyl_points := calc_loyl_points + lp_calc_loyl_points;
            EXIT;
         ELSIF slab_amt <= lp_trans_amt
         THEN
            lp_trans_amt := lp_trans_amt - slab_amt;

            SELECT   ROUND (NVL (slab_amt, 0) / a.csd_trans_amt)
                   * a.csd_loyl_point
              INTO lp_calc_loyl_points
              FROM DUAL;

            calc_loyl_points := calc_loyl_points + lp_calc_loyl_points;
         END IF;

         EXIT WHEN lpc1%NOTFOUND;
      END LOOP;
   EXCEPTION                                                        --excp lp8
      WHEN OTHERS
      THEN
         lperr8 := 'Excp LP8-1 --' || SQLERRM;
   END;                                                              --end lp8
------------------------------------------------MAIN BEGIN STARTS-----------------------------------------------------
BEGIN
   errmsg := 'OK';

   BEGIN                                                            --begin 1
      --first open the main cursor
      FOR x IN c1
      LOOP
         v_card_level_prior := 10000;
         v_pccc_level_prior := 10000;
         excp_flag := NULL;
         pccc_flag := NULL;

         FOR y IN c2 (x.cpt_pan_code, x.cpt_mbr_numb, x.cpt_trans_date)
         LOOP
            IF y.clm_loyl_catg = 6
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_card_level_prior := y.clc_catg_prior;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 7
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_card_level_prior := y.clc_catg_prior;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 5
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_card_level_prior := y.clc_catg_prior;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 3
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_card_level_prior := y.clc_catg_prior;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 2
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_card_level_prior := y.clc_catg_prior;
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 1
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_card_level_prior := y.clc_catg_prior;
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 8
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_card_level_prior := y.clc_catg_prior;
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            IF y.clm_loyl_catg = 4
            THEN
               IF y.clc_catg_prior < v_card_level_prior
               THEN
                  v_card_level_prior := y.clc_catg_prior;
                  v_clm_loyl_catg := y.clm_loyl_catg;
                  v_cce_loyl_code := y.cce_loyl_code;
               END IF;
            END IF;

            EXIT WHEN c2%NOTFOUND;
         END LOOP;

----------------------------------------------------------------------------------------------------------------------
         IF v_clm_loyl_catg = 6
         THEN
            lp_find_merc_loyl (v_cce_loyl_code,
                               x.cpt_acq_bank,
                               x.cpt_term_id,
                               yes_no,
                               excp_temp_trans_amt,
                               excp_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-2 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
                  excp_temp_loyl_code := v_cce_loyl_code;
                  excp_temp_loyl_point := excp_temp_loyl_point_out;
               ELSE
                  NULL;
               END IF;
            END IF;
         END IF;

         --check whether the citywise loyalty is applicable
         IF v_clm_loyl_catg = 7
         THEN
            lp_find_city_loyl (v_cce_loyl_code,
                               x.cpt_pan_code,
                               yes_no,
                               excp_temp_trans_amt,
                               excp_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP -3 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
                  excp_temp_loyl_code := v_cce_loyl_code;
                  excp_temp_loyl_point := excp_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the merchant categorywise loyalty is applicable
         IF v_clm_loyl_catg = 5
         THEN
            lp_find_merccatg_loyl (v_cce_loyl_code,
                                   x.cpt_mcc_code,
                                   yes_no,
                                   excp_temp_trans_amt,
                                   excp_temp_loyl_point_out,
                                   errmsg
                                  );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-1 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--that means the transaction has been carried out at the merchant category on which loyalty is defined
                  excp_temp_loyl_code := v_cce_loyl_code;
                  excp_temp_loyl_point := excp_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the monthwise loyalty is applicable
         IF v_clm_loyl_catg = 3
         THEN
            lp_find_month_loyl (v_cce_loyl_code,
                                x.cpt_trans_date,
                                yes_no,
                                excp_temp_trans_amt,
                                excp_temp_loyl_point_out,
                                errmsg
                               );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP -4 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
                  excp_temp_loyl_code := v_cce_loyl_code;
                  excp_temp_loyl_point := excp_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the datewise loyalty is applicable
         IF v_clm_loyl_catg = 2
         THEN
            lp_find_date_loyl (v_cce_loyl_code,
                               x.cpt_trans_date,
                               yes_no,
                               excp_temp_trans_amt,
                               excp_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-5 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--this means that the transaction has been carried out on the date for which a loyalty is defined
                  excp_temp_loyl_code := v_cce_loyl_code;
                  excp_temp_loyl_point := excp_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether default loyalty is applicable
         IF v_clm_loyl_catg = 1
         THEN
            lp_find_def_loyl (v_cce_loyl_code,
                              yes_no,
                              excp_temp_trans_amt,
                              excp_temp_loyl_point_out,
                              errmsg
                             );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-6 ---' || errmsg;
            ELSE
               excp_temp_loyl_code := v_cce_loyl_code;
               excp_temp_loyl_point := excp_temp_loyl_point_out;
            END IF;
         END IF;

         --check whether slabwise loyalty is applicable
         IF v_clm_loyl_catg = 8
         THEN
            lp_find_slab_loyl (v_cce_loyl_code,
                               yes_no,
                               excp_slabout_code,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-7 ---' || errmsg;
            ELSE
               excp_temp_loyl_code := v_cce_loyl_code;
            END IF;
         END IF;

         --check whether the customer category wise loyalty is applicable
         IF v_clm_loyl_catg = 4
         THEN
            lp_find_custcatg_loyl (v_cce_loyl_code,
                                   yes_no,
                                   excp_temp_trans_amt,
                                   excp_temp_loyl_point_out,
                                   errmsg
                                  );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-0 ---' || errmsg;
            ELSE
               excp_temp_loyl_code := v_cce_loyl_code;
               excp_temp_loyl_point := excp_temp_loyl_point_out;
            END IF;
         END IF;

         IF v_card_level_prior = 10000
         THEN
            excp_flag := 0;
         ELSE
            excp_flag := 1;
         END IF;
---------------------------------------------------------------------------------------------------------------------
         FOR z IN c3 (x.cpt_prod_code, x.cpt_card_type, x.cpt_trans_date)
         LOOP
            IF z.clm_loyl_catg = 6
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 7
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 5
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 3
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 2
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 1
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 8
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            IF z.clm_loyl_catg = 4
            THEN
               IF z.clc_catg_prior < v_pccc_level_prior
               THEN
                  v_pccc_level_prior := z.clc_catg_prior;
                  v_clm_loyl_catg_prod := z.clm_loyl_catg;
                  v_cpl_loyl_code := z.cpl_loyl_code;
               END IF;
            END IF;

            EXIT WHEN c3%NOTFOUND;
         END LOOP;

         --check whether the merchant wise loyalty is applicable
         IF v_clm_loyl_catg_prod = 6
         THEN
            lp_find_merc_loyl (v_cpl_loyl_code,
                               x.cpt_acq_bank,
                               x.cpt_term_id,
                               yes_no,
                               pccc_temp_trans_amt,
                               pccc_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-2 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--this means that the transaction has been carried out at a merchant  for which a loyalty is defined
                  pccc_temp_loyl_code := v_cpl_loyl_code;
                  pccc_temp_loyl_point := pccc_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the citywise loyalty is applicable
         IF v_clm_loyl_catg_prod = 7
         THEN
            lp_find_city_loyl (v_cpl_loyl_code,
                               x.cpt_pan_code,
                               yes_no,
                               pccc_temp_trans_amt,
                               pccc_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP -3 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--this means that the transaction has been carried out in the city for which a loyalty is defined
                  pccc_temp_loyl_code := v_cpl_loyl_code;
                  pccc_temp_loyl_point := pccc_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the merchant categorywise loyalty is applicable
         IF v_clm_loyl_catg_prod = 5
         THEN
            lp_find_merccatg_loyl (v_cpl_loyl_code,
                                   x.cpt_mcc_code,
                                   yes_no,
                                   pccc_temp_trans_amt,
                                   pccc_temp_loyl_point_out,
                                   errmsg
                                  );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-1 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--that means the transaction has been carried out at the merchant category on which loyalty is defined
                  pccc_temp_loyl_code := v_cpl_loyl_code;
                  pccc_temp_loyl_point := pccc_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the monthwise loyalty is applicable
         IF v_clm_loyl_catg_prod = 3
         THEN
            lp_find_month_loyl (v_cpl_loyl_code,
                                x.cpt_trans_date,
                                yes_no,
                                pccc_temp_trans_amt,
                                pccc_temp_loyl_point_out,
                                errmsg
                               );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP -4 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
--this means that the transaction has been carried out in the month for which a loyalty is defined
                  pccc_temp_loyl_code := v_cpl_loyl_code;
                  pccc_temp_loyl_point := pccc_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether the datewise loyalty is applicable
         IF v_clm_loyl_catg_prod = 2
         THEN
            lp_find_date_loyl (v_cpl_loyl_code,
                               x.cpt_trans_date,
                               yes_no,
                               pccc_temp_trans_amt,
                               pccc_temp_loyl_point_out,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-5 ---' || errmsg;
            ELSE
               IF yes_no = 'Y'
               THEN
                  pccc_temp_loyl_code := v_cpl_loyl_code;
                  pccc_temp_loyl_point := pccc_temp_loyl_point_out;
               END IF;
            END IF;
         END IF;

         --check whether default loyalty is applicable
         IF v_clm_loyl_catg_prod = 1
         THEN
            lp_find_def_loyl (v_cpl_loyl_code,
                              yes_no,
                              pccc_temp_trans_amt,
                              pccc_temp_loyl_point_out,
                              errmsg
                             );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-6 ---' || errmsg;
            ELSE
               pccc_temp_loyl_code := v_cpl_loyl_code;
               pccc_temp_loyl_point := pccc_temp_loyl_point_out;
            END IF;
         END IF;

         --check whether slabwise loyalty is applicable
         IF v_clm_loyl_catg_prod = 8
         THEN
            lp_find_slab_loyl (v_cpl_loyl_code,
                               yes_no,
                               pccc_slabout_code,
                               errmsg
                              );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-7 ---' || errmsg;
            ELSE
               pccc_temp_loyl_code := v_cpl_loyl_code;
            END IF;
         END IF;

         --check whether the customer category wise loyalty is applicable
         IF v_clm_loyl_catg_prod = 4
         THEN
            lp_find_custcatg_loyl (v_cpl_loyl_code,
                                   yes_no,
                                   pccc_temp_trans_amt,
                                   pccc_temp_loyl_point_out,
                                   errmsg
                                  );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From LP-0 ---' || errmsg;
            ELSE
               pccc_temp_loyl_code := v_cpl_loyl_code;
               pccc_temp_loyl_point := pccc_temp_loyl_point_out;
            END IF;
         END IF;

         IF v_pccc_level_prior = 10000
         THEN
            pccc_flag := 0;
         ELSE
            pccc_flag := 1;
         END IF;

         --now apply the highest priority and perform the calculation for loyalty points
                    --here applicable slab code will be filled in only if the loyalty category is 8 in both the above levels i.e. card and pccc else it will remail null
                    --this is done to calculate the slabwise loyalty
         
		 IF excp_temp_loyl_code IS NOT NULL OR pccc_temp_loyl_code IS NOT NULL     
		 THEN					   	   		   					   	  	  		   	  ---111
		 	IF excp_temp_loyl_point IS NOT NULL OR pccc_temp_loyl_point IS NOT NULL
			THEN					   	   		   						   	   	   	  ---222
				IF  excp_temp_trans_amt IS NOT NULL OR pccc_temp_trans_amt IS NOT  NULL
				THEN					   	   		   					   	  	   	   ---333
		 
		 IF excp_flag = 1 AND pccc_flag = 1
         THEN
            --here see the loyalty category of both the loyalty codes(excp as well as pccc)
            --if the loyalty category is same then the exceptional level is applicable
            --if both codes are of different loyl catg then the priority of the catg is seen and acc to that the loyl code is taken up for calc.
            SELECT clm_loyl_catg
              INTO v_clm_loyl_catg_excp
              FROM cms_loyl_mast
             WHERE clm_inst_code = instcode
               AND clm_loyl_code = excp_temp_loyl_code;

            SELECT clm_loyl_catg
              INTO v_clm_loyl_catg_pccc
              FROM cms_loyl_mast
             WHERE clm_inst_code = instcode
               AND clm_loyl_code = pccc_temp_loyl_code;

            IF v_clm_loyl_catg_pccc = v_clm_loyl_catg_excp
            THEN
               applicable_loyl_code := excp_temp_loyl_code;
               applicable_trans_amt := excp_temp_trans_amt;
               applicable_loyl_point := excp_temp_loyl_point;
               applicable_slab_code := excp_slabout_code;
            ELSE
               IF v_card_level_prior < v_pccc_level_prior
               THEN
                  applicable_loyl_code := excp_temp_loyl_code;
                  applicable_trans_amt := excp_temp_trans_amt;
                  applicable_loyl_point := excp_temp_loyl_point;
                  applicable_slab_code := excp_slabout_code;
               ELSIF v_pccc_level_prior <= v_card_level_prior
               THEN
                  applicable_loyl_code := pccc_temp_loyl_code;
                  applicable_trans_amt := pccc_temp_trans_amt;
                  applicable_loyl_point := pccc_temp_loyl_point;
                  applicable_slab_code := pccc_slabout_code;
               END IF;
            END IF;
         ELSIF excp_flag = 0 AND pccc_flag = 1
         THEN
            applicable_loyl_code := pccc_temp_loyl_code;
            applicable_trans_amt := pccc_temp_trans_amt;
            applicable_loyl_point := pccc_temp_loyl_point;
            applicable_slab_code := pccc_slabout_code;
         ELSIF excp_flag = 1 AND pccc_flag = 0
         THEN
            applicable_loyl_code := excp_temp_loyl_code;
            applicable_trans_amt := excp_temp_trans_amt;
            applicable_loyl_point := excp_temp_loyl_point;
            applicable_slab_code := excp_slabout_code;
         ELSIF excp_flag = 0 AND pccc_flag = 0
         THEN
            NULL;

            --nothing is to be done,go to the next pan
                            --Added to mark that PAN as error record . Change Starts.....
            IF x.cpt_trans_date < SYSDATE
            THEN
               UPDATE cms_pan_trans
                  SET cpt_loyl_calc = 'E'
                WHERE ROWID = x.ROWID;
            END IF;
         --Added to mark that PAN as error record . Change Ends.....
         END IF;

         --now the loyalty points calc part
         IF    (excp_flag = 1 AND pccc_flag = 1)
            OR (excp_flag = 1 AND pccc_flag = 0)
            OR (excp_flag = 0 AND pccc_flag = 1)
         THEN
            --check whether the applicable loyalty code is a slabwise loyalty
            --because we have a different method of calc for slabwise loyalty
            BEGIN                                            --begin 2 starts
               SELECT clm_loyl_catg
                 INTO v_clm_loyl_catg
                 FROM cms_loyl_mast
                WHERE clm_loyl_code = applicable_loyl_code;

               IF v_clm_loyl_catg = 8
               THEN
                  slab_flag := 'Y';
               ELSE
                  slab_flag := 'N';
               END IF;
            EXCEPTION                                        --excp of begin 2
               WHEN NO_DATA_FOUND
               THEN
                  errmsg :=
                        'No Data found in loyalty master for code --'
                     || applicable_loyl_code;
               WHEN OTHERS
               THEN
                  errmsg := 'Excp 2 --' || SQLERRM;
            END;                                                --begin 2 ends

            IF slab_flag != 'Y'
            THEN
               SELECT   ROUND (NVL (x.cpt_trans_amt, 0) / applicable_trans_amt)
                      * applicable_loyl_point
                 INTO calc_loyl_points
                 FROM DUAL;
            ELSE
               --call the local procedure to calculate slabwise loyalty for this transaction,it will directly return the calculated loyalty points
               lp_calc_slab_loyl_points (applicable_slab_code,
                                         x.cpt_trans_amt,
                                         calc_loyl_points,
                                         errmsg
                                        );

               IF errmsg != 'OK'
               THEN
                  -- errmsg := 'From LP-8 ---'||errmsg;
                  -- for Giving errmg with details of records
                  errmsg :=
                        'From LP-8 at Slab loyl calc for PAN:'
                     || x.cpt_pan_code
                     || ' and AuthCode :'
                     || x.cpt_auth_code
                     || ' ---'
                     || errmsg;
               END IF;
            END IF;

            IF errmsg = 'OK'
            THEN                                              --errmsg = ok if
               --insert into loyalty points table
               IF x.cpt_addon_stat = 'A'
               THEN
                  addon_for_insert := x.cpt_addon_link;
                  mbr_for_addon := x.cpt_mbr_link;
                  excp_addon := x.cpt_pan_code;
                  excp_mbr := x.cpt_mbr_numb;
               ELSIF x.cpt_addon_stat = 'P'
               THEN
                  addon_for_insert := x.cpt_pan_code;
                  mbr_for_addon := x.cpt_mbr_numb;
                  excp_addon := NULL;
                  excp_mbr := NULL;
               END IF;

               --Added for Recordwise Exception Handling
               BEGIN
                  --   savepoint loyl_ins ;
                  UPDATE cms_loyl_points
                     SET clp_loyl_points = clp_loyl_points + calc_loyl_points,
                         clp_lupd_user = lupduser,
                         clp_lupd_date = SYSDATE
                   WHERE clp_inst_code = instcode
                     AND clp_pan_code = addon_for_insert
                     AND clp_mbr_numb = mbr_for_addon;

                  IF SQL%NOTFOUND
                  THEN
                     INSERT INTO cms_loyl_points
                                 (clp_inst_code, clp_pan_code, clp_mbr_numb,
                                  clp_loyl_points, clp_last_rdmdate,
                                  clp_ins_user, clp_lupd_user
                                 )
                          VALUES (instcode, addon_for_insert, mbr_for_addon,
                                  calc_loyl_points, NULL,
                                  lupduser, lupduser
                                 );
                  END IF;

                  INSERT INTO cms_loyl_dtl
                              (cld_inst_code, cld_pan_code, cld_mbr_numb,
                               cld_acct_no, cld_loyl_code,
                               cld_trans_amt, cld_loyl_points, cld_addon_pan,
                               cld_addon_mbr, cld_id_col, cld_tran_date,
                               cld_ins_user, cld_lupd_user
                              )
                       VALUES (instcode, addon_for_insert, mbr_for_addon,
                               x.cpt_acct_no, applicable_loyl_code,
                               x.cpt_trans_amt, calc_loyl_points, excp_addon,
                               excp_mbr, x.cpt_id_col, x.cpt_trans_date,
                               lupduser, lupduser
                              );

                  INSERT INTO cms_loyl_audit
                              (cla_inst_code, cla_pan_code, cla_mbr_numb,
                               cla_acct_no, cla_loyl_ind, cla_loyl_points,
                               cla_oprn_date,
                               cla_oprn_desc,
                               cla_ins_user, cla_lupd_user
                              )
                       VALUES (instcode, addon_for_insert, mbr_for_addon,
                               x.cpt_acct_no, 'C', calc_loyl_points,
                               SYSDATE,
                               'Loyalty points credit for transaction',
                               lupduser, lupduser
                              );

                  --now update the  row for which loyalty is calculated
                  UPDATE cms_pan_trans
                     SET cpt_loyl_calc = 'Y',
                         cpt_loyl_calcdate = SYSDATE
                   WHERE ROWID = x.ROWID;
               -- for Recordwise Exception Handling
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Exception for record with PAN :'
                        || x.cpt_pan_code
                        || ' and AuthCode :'
                        || x.cpt_auth_code
                        || ' and Acct No:'
                        || x.cpt_acct_no
                        || 'Err Msg :'
                        || SQLERRM;
                     RAISE v_raise_exception;
               END;
            END IF;
         END IF;                                              --errmsg = ok if
		END IF;												  --111
	   END IF;												  --222
	  END IF;  												  --333

	  
	  IF excp_temp_loyl_code IS NULL AND pccc_temp_loyl_code IS NULL THEN
			  errmsg:='Exception for record with PAN :'|| x.cpt_pan_code;
			  UPDATE cms_pan_trans
                  SET cpt_loyl_calc = 'E'
                WHERE ROWID = x.ROWID;
			 -- RAISE v_raise_exception;
	  END IF;	
	  IF excp_temp_loyl_point IS NULL AND pccc_temp_loyl_point IS NULL
	  THEN		
	          errmsg:='Exception for record with PAN :'|| x.cpt_pan_code;
			  UPDATE cms_pan_trans
                  SET cpt_loyl_calc = 'E'
                WHERE ROWID = x.ROWID;
			  --RAISE v_raise_exception;		
	  END IF;	
	  IF  excp_temp_trans_amt IS NULL AND pccc_temp_trans_amt IS NULL
	  THEN	
    	     errmsg:='Exception for record with PAN :'|| x.cpt_pan_code;
			 UPDATE cms_pan_trans
                  SET cpt_loyl_calc = 'E'
                WHERE ROWID = x.ROWID;
			 --RAISE v_raise_exception;
	  END IF;  
	  
	  					
         EXIT WHEN c1%NOTFOUND;
      END LOOP;
   EXCEPTION                                                          --excp 1
      WHEN v_raise_exception
      THEN
         NULL;
      WHEN OTHERS
      THEN
         errmsg := 'Excp 1 -- ' || SQLERRM;
   END;                                                           --end begin1
EXCEPTION                                                 --Excp of main begin
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;                                                         --Main begin ends
/


show error