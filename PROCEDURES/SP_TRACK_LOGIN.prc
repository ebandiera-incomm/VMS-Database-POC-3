CREATE OR REPLACE PROCEDURE VMSCMS.SP_TRACK_LOGIN
(prm_instcode IN number,
prm_usercode IN varchar2,
prm_errmsg OUT varchar2
)
as

/*************************************************
     * Created Date     :  NA
     * Created By       :  NA
     * PURPOSE          :  For ACH transaction
     * Modified By      :  Sivapragasam M
     * Modified Date    :  13-June-2012
     * Modified Reason  :  To change description of error message in login page
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  18-June-2012
     * Release Number   :  CMS3.5.1_RI0010_B0002
 *************************************************/

    v_track_login  varchar2(1);
    v_dum          number;
    v_wrong_logins cms_inst_param.cip_param_value%TYPE;
    v_cum_user_pin cms_user_mast.cum_user_pin%TYPE;
BEGIN
    prm_errmsg:='OK';
    BEGIN
        SELECT cum_user_pin
        INTO v_cum_user_pin
        FROM cms_user_mast
        WHERE cum_inst_code=prm_instcode
        and cum_user_code=prm_usercode;

    EXCEPTION WHEN OTHERS THEN
        prm_errmsg:= 'Error while getting user details '||substr(sqlerrm,1,200);
        RETURN;
    END;
    BEGIN
        SELECT cip_param_value
        INTO v_wrong_logins
        FROM cms_inst_param
        WHERE cip_inst_code = prm_instcode
        AND cip_param_key   = 'WRONG PSWDS';
    EXCEPTION WHEN OTHERS THEN
        prm_errmsg:='Error while fetching wrong login count '||substr(sqlerrm,1,200);
        RETURN;
    END;

    BEGIN
        UPDATE cms_track_login
        SET ctl_wrong_logincnt = ctl_wrong_logincnt + 1,
        ctl_login_date       = SYSDATE
        WHERE ctl_inst_code  = prm_instcode
        AND ctl_user_pin     = v_cum_user_pin;

        prm_errmsg  := 'Wrong Password, Try Again';
        IF sql%rowcount=0 then
          prm_errmsg:='Error while updating wrong login count '||substr(sqlerrm,1,200);
          RETURN;
        END IF;
    END;

    BEGIN
        SELECT ctl_wrong_logincnt
        INTO v_dum
        FROM cms_track_login
        WHERE ctl_inst_code = prm_instcode
        AND ctl_user_pin    = v_cum_user_pin;
    EXCEPTION WHEN OTHERS THEN
        prm_errmsg:='Error whie checkng login count '||substr(sqlerrm,1,200);
        RETURN;
    END;

    IF v_dum >= v_wrong_logins
    THEN
       prm_errmsg:= v_wrong_logins || ' Continuous Wrong Passwords. User id is locked. Contact System Administrator';

       BEGIN
           UPDATE cms_user_mast
           SET cum_user_susp = 'L'
               WHERE cum_inst_code = prm_instcode
               AND cum_user_pin = v_cum_user_pin;

           IF SQL%ROWCOUNT =0 THEN
              prm_errmsg:='Error while updating the user status '||substr(sqlerrm,1,200);
              RETURN;
           END IF;
       END;
   ELSIF v_dum = v_wrong_logins - 1 THEN
         prm_errmsg:= 'Your user id will be locked if you enter one more invalid password';
    END IF;

EXCEPTION WHEN OTHERS THEN
    prm_errmsg:='Main error while tracking login for user '||substr(sqlerrm,1,200);
    RETURN;
END;
/


