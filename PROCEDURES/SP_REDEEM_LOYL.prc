CREATE OR REPLACE PROCEDURE VMSCMS.sp_redeem_loyl (
   instcode   IN       NUMBER,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   thresh_loyl_param   NUMBER;

--accounts are picked up branchwise so as to limit the cursor size of the cursor picking up the accounts
--cursor which picks up the branches from branch master
   CURSOR c1
   IS
      SELECT cbm_bran_code
        FROM cms_bran_mast
       WHERE cbm_inst_code = instcode;

--cursor pick up the account numbers for different branches
   CURSOR c2 (c_brancode IN VARCHAR2)
   IS
      SELECT cam_acct_no, cam_curr_loyl, cam_unclaimed_loyl
        FROM cms_acct_mast
       WHERE cam_inst_code = instcode AND cam_curr_bran = c_brancode;

--and cam_acct_no = '9'   for testing purpose only
--for update??? where current of mein unique condition ke liye tereko double cursur lena padega on an account number
   v_crm_redm_amt      cms_rwrd_mast.crm_redm_amt%TYPE;
   redeemedamount      NUMBER (12, 2);

--1.local procedure to lapse points which are less than the threshold
   PROCEDURE lp_lapse_points (
      instcode   IN       NUMBER,
      acctno     IN       VARCHAR2,
      lperr1     OUT      VARCHAR2
   )
   IS
   BEGIN                                                         --begin lp 1
      lperr1 := 'OK';

      UPDATE cms_acct_mast
         SET cam_curr_loyl = 0,
             cam_unclaimed_loyl = 0,
             cam_lupd_user = lupduser
       WHERE cam_inst_code = instcode AND cam_acct_no = acctno;

--log error into a log table?
      IF SQL%ROWCOUNT = 0
      THEN
         lperr1 :=
               'Problem while lapsing account no '
            || acctno
            || ' for loyalty points. No such account found';
      END IF;

      IF SQL%ROWCOUNT > 1
      THEN
         lperr1 :=
               'Problem while lapsing account no '
            || acctno
            || ' for loyalty points. Duplicate accounts found';
      END IF;
--log error into a log table?
   EXCEPTION                                                    --excp of lp 1
      WHEN OTHERS
      THEN
         lperr1 := 'Excp lp1 -- ' || SQLERRM;
   END;                                                              --end lp1
   
-------------------------------------------------MAIN BEGIN--------------------------------------------------------   
BEGIN                                                             --main begin
   errmsg := 'OK';

   SELECT crm_redm_amt
     INTO v_crm_redm_amt
     FROM cms_rwrd_mast
    WHERE crm_inst_code = instcode;

   DBMS_OUTPUT.put_line (   'Amount from reward master =-=-=-=-=-=-=>>>>>'
                         || v_crm_redm_amt
                        );

   SELECT TO_NUMBER (cip_param_value)
     INTO thresh_loyl_param
     FROM cms_inst_param
    WHERE cip_inst_code = 1 AND cip_param_key = 'THRESHOLD LOYL';

   FOR x IN c1
   LOOP
      FOR y IN c2 (x.cbm_bran_code)
      LOOP
         IF errmsg != 'OK'
         THEN
            EXIT;
         END IF;

         IF y.cam_unclaimed_loyl < thresh_loyl_param
         THEN
            --if the loyalty points are to be carried forward then it can be done so by not calling the lapse local procedure
            --select whether to carry forward or lapse the points from a parameter table here
            --IF carry forward  = 'yes' then dont call the local procedure to lapse
            --ELSE
            --call the local procedure
            --END IF;
            lp_lapse_points (instcode, y.cam_acct_no, errmsg);

            IF errmsg != 'OK'
            THEN
               errmsg := '1.From lp_lapse_points --' || errmsg;
            END IF;
         END IF;

         IF errmsg = 'OK'
         THEN
            BEGIN                                                   --begin 1
               SELECT cam_unclaimed_loyl * v_crm_redm_amt
                 INTO redeemedamount
                 FROM cms_acct_mast
                WHERE cam_inst_code = instcode AND cam_acct_no = y.cam_acct_no;

               DBMS_OUTPUT.put_line
                                   (   'Filhal redeemed amount for account =>'
                                    || y.cam_acct_no
                                    || ' =>'
                                    || redeemedamount
                                   );

               --insert this amount in a table here which can be used for ttum population later
               INSERT INTO cms_redeem_loyl
                           (crl_inst_code, crl_curr_bran, crl_acct_no,
                            crl_calc_amt,              --cash(amount redeemed)
                                         crl_tot_loyl,             --gift+cash
                            crl_loyl_points,                       --only cash
                                            crl_loyl_ind, crl_parti_cular,
                            crl_file_name, crl_ins_user, crl_lupd_user
                           )
                    VALUES (instcode, x.cbm_bran_code, y.cam_acct_no,
                            redeemedamount, y.cam_curr_loyl,
                            y.cam_unclaimed_loyl, 'C', 'Loyalty Points Redm',
                            'N', lupduser, lupduser
                           );

               --now reset the loyalty points to 0 for that call the local procedure again
               lp_lapse_points (instcode, y.cam_acct_no, errmsg);

               IF errmsg != 'OK'
               THEN
                  errmsg := '2.From lp_lapse_points --' || errmsg;
               END IF;
            EXCEPTION                                        --excp of begin 1
               WHEN NO_DATA_FOUND
               THEN
                  errmsg :=
                        'No such account '
                     || y.cam_acct_no
                     || ' in account master.';
               WHEN TOO_MANY_ROWS
               THEN
                  errmsg :=
                        'Duplicate accounts found for account number '
                     || y.cam_acct_no
                     || '.';
               WHEN OTHERS
               THEN
                  errmsg := 'Excp 1 -- ' || SQLERRM;
            END;                                                --begin 1 ends
         END IF;

         EXIT WHEN c2%NOTFOUND;
      END LOOP;

      EXIT WHEN c1%NOTFOUND;
   END LOOP;

--now the population of the table from which the ttum file will be generated
   IF errmsg = 'OK'
   THEN
      sp_pop_ttum (1, 'L', 1, errmsg);

      IF errmsg != 'OK'
      THEN
         errmsg := 'From sp_pop_ttum -- ' || errmsg;
      END IF;
   END IF;
EXCEPTION                                                 --excp of main begin
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;                                                                --end main
/
SHOW ERRORS

