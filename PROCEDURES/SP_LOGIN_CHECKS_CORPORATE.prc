CREATE OR REPLACE PROCEDURE VMSCMS.sp_login_checks_corporate (
   instcode        IN       NUMBER,
   usercode        IN       VARCHAR2,
   --userpin      IN    number   ,
   loginpswd       IN       VARCHAR2,
   usergroup       IN       NUMBER,
   -- lupduser    IN    number   ,
   dateformate     IN       VARCHAR2,
   lastlogintime   OUT      VARCHAR2,
   flagint         OUT      NUMBER,
--1,2 denotes that the errmsg which this proc gives out has to be shown to the end user, else 0
   errmsg          OUT      VARCHAR2
)
AS
   dum                NUMBER (3);
   days               NUMBER (3);
   v_cum_user_susp    CHAR (1);
   v_cum_user_code    cms_user_mast.cum_user_code%TYPE;
   v_cum_encr_pswd    cms_user_mast.cum_encr_pswd%TYPE;
   v_wrong_logins     cms_inst_param.cip_param_value%TYPE;
   v_pswd_change      cms_inst_param.cip_param_value%TYPE;
   userpin            cms_user_mast.cum_user_pin%TYPE;
   v_cum_valid_frdt   DATE;
   v_cum_valid_todt   DATE;
   v_cug_group_code   cms_user_group.cug_group_code%TYPE;
   v_cug_group_name   cms_user_group.cug_group_name%TYPE;
   v_force_pswd       cms_user_mast.cum_force_pswd%TYPE;
--lastlogintime    varchar2(10) ;
BEGIN                                                             --main begin
   errmsg := 'OK';
   flagint := 0;

   --First check the status of the user id (whether it is active)
   SELECT cum_user_susp, cum_user_code, cum_user_pin, cum_encr_pswd,
          TRUNC (SYSDATE) - TRUNC (cum_pswd_date), cum_valid_frdt,
          cum_valid_todt,
          TO_CHAR (NVL (TO_DATE (cum_last_logintime, 'dd-mon-yyyy hh24:mi:ss'),
                        SYSDATE
                       ),
                   dateformate || ' HH24:MI:SS'
                  ),
          cum_force_pswd
                                        --(password already in encrypted form)
     --NVL(cum_last_logintime,TO_CHAR(' '))  --(password already in encrypted form)
   INTO   v_cum_user_susp, v_cum_user_code, userpin, v_cum_encr_pswd,
          days, v_cum_valid_frdt,
          v_cum_valid_todt,
          lastlogintime,
          v_force_pswd
     FROM cms_user_mast_corporate
    WHERE cum_inst_code = instcode
-- AND      cum_user_pin      =  userpin;
          AND UPPER (cum_user_code) = UPPER (usercode);

   IF errmsg = 'OK'
   THEN                                                                --ok if
      BEGIN                                                         --begin 1
         SELECT cip_param_value
           INTO v_wrong_logins
           FROM cms_inst_param
          WHERE cip_inst_code = instcode AND cip_param_key = 'WRONG PSWDS';

         SELECT cip_param_value
           INTO v_pswd_change
           FROM cms_inst_param
          WHERE cip_inst_code = instcode AND cip_param_key = 'PSWD CHANGE';

         IF loginpswd != v_cum_encr_pswd
         THEN
            --password not matching, update the wrong login count in the track login table for the wrong entry
            --if the wrong logins count equals to the parameter set then lock the userid
            --if the the wrong login count is 1 less than the parameter set then give appropriate warning
            UPDATE cms_track_login
               SET ctl_wrong_logincnt = ctl_wrong_logincnt + 1,
                   ctl_login_date = SYSDATE
             WHERE ctl_inst_code = instcode AND ctl_user_pin = userpin;

            errmsg := 'Wrong password, try one more time';
            flagint := 1;

            SELECT ctl_wrong_logincnt
              INTO dum
              FROM cms_track_login
             WHERE ctl_inst_code = instcode AND ctl_user_pin = userpin;

            -- Ashwini 1 Dec 2004 -- Start  CR99
            -- User of 'Super User' group will not be locked even if wrong pswd is entered more thn 3 times.
            SELECT cug_group_name
              INTO v_cug_group_name
              FROM cms_user_group
             WHERE cug_group_code = usergroup;

            IF NOT (UPPER (v_cug_group_name) = UPPER ('SUPER USER'))
            THEN
               IF dum >= v_wrong_logins
               THEN
                  errmsg :=
                        v_wrong_logins
                     || ' continuous wrong passwords. User id is locked. Contact System Administrator';

                  UPDATE cms_user_mast
                     SET cum_user_susp = 'L',
                         --cum_lupd_user   =  lupduser
                         cum_lupd_user = userpin
                   WHERE cum_inst_code = instcode AND cum_user_pin = userpin;
               ELSIF dum = v_wrong_logins - 1
               THEN
                  errmsg :=
                     'Your user id will be locked if you enter one more invalid password';
               END IF;
            -- Ashwini 1 Dec 2004 -- End  CR99
            END IF;
         ELSE
      --password right
-- suspend all users who hav nt logged in since 60 days shyam 04 oct 05
    /*        UPDATE cms_user_mast
               SET cum_user_susp = 'Y'
             WHERE cum_user_pin IN (SELECT ctl_user_pin
                                      FROM cms_track_login
                                     WHERE (SYSDATE - ctl_login_date) > 60);*/

            --reset the wronglogin count to zero
            --proceed with other chekings(such as user group)
               --these 4 checks below are done only if the user passes the password test
            v_cum_user_susp := 'N';

            IF v_cum_user_susp = 'Y'
            THEN
               errmsg := 'User Already Logged on';
               flagint := 1;
            ELSIF v_cum_user_susp = 'H'
            THEN
               errmsg := 'User on Hold';
               flagint := 1;
            ELSIF v_cum_user_susp = 'L'
            THEN
               errmsg := 'User locked';
               flagint := 1;
            ELSIF v_cum_user_susp = 'S'
            THEN
               errmsg := 'User is Suspended ';
               flagint := 1;
            END IF;

            IF TRUNC (SYSDATE) NOT BETWEEN TRUNC (v_cum_valid_frdt)
                                       AND TRUNC (v_cum_valid_todt)
            THEN
               errmsg := 'User validity over';
               flagint := 1;
            END IF;

            IF errmsg = 'OK'
            THEN
               UPDATE cms_track_login
                  SET ctl_wrong_logincnt = 0,
                      ctl_login_date = SYSDATE
                WHERE ctl_inst_code = instcode AND ctl_user_pin = userpin;

               BEGIN                                               --begin 1.1
                  SELECT 1
                    INTO dum
                    FROM cms_user_groupmast
                   WHERE cug_inst_code = instcode
                     AND cug_group_code = usergroup
                     AND cug_user_code = v_cum_user_code;
               EXCEPTION                                            --excp 1.1
                  WHEN NO_DATA_FOUND
                  THEN
                     flagint := 1;
                     errmsg := 'Invalid combination of User and the group';
                  WHEN OTHERS
                  THEN
                     errmsg := 'Excp 1.1 -- ' || SQLERRM;
               END;                                            --end begin 1.1
            END IF;
         END IF;
      EXCEPTION                                                       --excp 1
         WHEN OTHERS
         THEN
            errmsg := 'Excp 1 -- ' || SQLERRM;
      END;                                                       --end  begin1
   END IF;                                                             --ok if

   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --begin 2
         /*SELECT  sysdate-max(cpp_pswd_date)
         INTO  days
         FROM  cms_prev_pswds
         WHERE cpp_inst_code     =  instcode
         AND   cpp_user_pin      =  userpin;*/--fullfilled in the first query  24-07-02
         -------------------For Change The password on first login--------------------
         IF v_force_pswd = 'N'
         THEN
            errmsg := 'First Login';
            flagint := 2;
         END IF;

         -------------------For Change The password on first login--------------------
         IF days > v_pswd_change
         THEN
            errmsg := 'Please change the password.';
            flagint := 2;
         ELSE
            UPDATE cms_user_mast_corporate
               SET cum_user_susp = 'Y',
                   cum_last_logintime =
                                   TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
             WHERE cum_user_pin = userpin;
         END IF;
      EXCEPTION                                                       --excp 2
         WHEN OTHERS
         THEN
            errmsg := 'Excp 2 -- ' || SQLERRM;
      END;                                                       --end begin 2
   END IF;
EXCEPTION                                                     --main exception
   WHEN NO_DATA_FOUND
   THEN
      errmsg := 'No such user found';
      flagint := 1;
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;                                                               --end main;
/
SHOW ERROR