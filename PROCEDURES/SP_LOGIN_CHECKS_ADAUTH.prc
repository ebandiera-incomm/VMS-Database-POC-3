CREATE OR REPLACE PROCEDURE vmscms.sp_login_checks_adauth (
   instcode        IN       NUMBER,
   usercode        IN       VARCHAR2,
   loginpswd       IN       VARCHAR2,
   usergroup       IN       NUMBER,
   dateformate     IN       VARCHAR2,
   lastlogintime   OUT      VARCHAR2,
   flagint         OUT      NUMBER,
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
   v_adauth_flag      cms_inst_param.cip_param_value%TYPE;
BEGIN
   errmsg := 'OK';
   flagint := 0;

   SELECT cum_user_susp, cum_user_code, cum_user_pin, cum_encr_pswd,
          TRUNC (SYSDATE) - TRUNC (cum_pswd_date), cum_valid_frdt,
          cum_valid_todt,
          TO_CHAR (NVL (TO_DATE (cum_last_logintime, 'dd-mon-yyyy hh24:mi:ss'),
                        SYSDATE
                       ),
                   dateformate || ' HH24:MI:SS'
                  ),
          cum_force_pswd
     INTO v_cum_user_susp, v_cum_user_code, userpin, v_cum_encr_pswd,
          days, v_cum_valid_frdt,
          v_cum_valid_todt,
          lastlogintime,
          v_force_pswd
     FROM cms_user_mast
    WHERE cum_inst_code = instcode AND UPPER (cum_user_code) =
                                                              UPPER (usercode);

   BEGIN
      SELECT cip_param_value
        INTO v_adauth_flag
        FROM cms_inst_param
       WHERE cip_param_key = 'AD_AUTH_REQ' AND cip_inst_code = instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg :=
            'Error while selecting the auth flag '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   IF v_adauth_flag = 'N'
   THEN
      BEGIN
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

            SELECT cug_group_name
              INTO v_cug_group_name
              FROM cms_user_group
             WHERE cug_group_code = usergroup AND cug_inst_code = instcode;

            IF NOT (UPPER (v_cug_group_name) = UPPER ('SUPER USER'))
            THEN
               IF dum >= v_wrong_logins
               THEN
                  errmsg :=
                        v_wrong_logins
                     || ' continuous wrong passwords. User id is locked. Contact System Administrator';

                  UPDATE cms_user_mast
                     SET cum_user_susp = 'L',
                         cum_lupd_user = userpin
                   WHERE cum_inst_code = instcode AND cum_user_pin = userpin;
               ELSIF dum = v_wrong_logins - 1
               THEN
                  errmsg :=
                     'Your user id will be locked if you enter one more invalid password';
               END IF;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
                  'Error while selecting login details '
               || SUBSTR (SQLERRM, 1, 200);
      END;
   END IF;

   IF errmsg = 'OK'
   THEN
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
      ELSIF v_cum_user_susp = 'D'
      THEN
         errmsg := 'User is Deleted ';
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
         BEGIN
            SELECT 1
              INTO dum
              FROM cms_user_groupmast
             WHERE cug_inst_code = instcode
               AND cug_group_code = usergroup
               AND cug_user_code = v_cum_user_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               flagint := 1;
               errmsg := 'Invalid combination of User and the group';
            WHEN OTHERS
            THEN
               errmsg := 'Excp 1.1 -- ' || SQLERRM;
         END;
      END IF;
   END IF;

   IF errmsg = 'OK'
   THEN
      BEGIN
         IF v_adauth_flag = 'N'
         THEN
            IF v_force_pswd = 'N'
            THEN
               errmsg := 'First Login';
               flagint := 2;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg := 'Excp 2 -- ' || SQLERRM;
      END;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      errmsg := 'No such user found';
      flagint := 1;
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;
/

SHOW ERROR