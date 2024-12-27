create or replace PROCEDURE VMSCMS.Prc_User_Authentication
  (
    prm_login_id IN VARCHAR2,
    prm_err_msg OUT VARCHAR2 )
AS
  /*************************************************
  * VERSION             :  1.0
  * Created Date       : 10/Dec/2009..
  * Created By        : Mahesh.P.
  * PURPOSE          : User Authentication.
  * Modified By:    :  Ewan Drego
  * Modified Date  : Tuesday, June 29, 2010 10:26:22 AM
  * NAB Defect id :  699
  *Internal Defect ID:      0007971
  *************************************************/

  from_date cms_userdetl_mast.cum_vald_frdt%TYPE;
  to_dat cms_userdetl_mast.cum_vald_todt%TYPE;
  force_txn_pswd cms_userdetl_mast.cum_frtx_pswd%TYPE;
  force_login_pswd cms_userdetl_mast.cum_frlg_pswd%TYPE;
  login_pswd_reset cms_userdetl_mast.cum_lgpw_rsfl%TYPE;
  txn_pswd_reset cms_userdetl_mast.cum_txpw_rsfl%TYPE;
  user_status       VARCHAR2 (50);
  login_pswd_days   NUMBER;
  txn_pswd_days     NUMBER;
  lgin_expiry_days  NUMBER;
  txn_expiry_days   NUMBER;
  login_pswd_change NUMBER;
  txn_pswd_change   NUMBER;
  days_of_expiry    NUMBER;
  exp_rej          exception;
  v_inst_code     cms_user_inst.cui_inst_code%type;
  ----For the timing pswd_Expiry_date is hardcoding to 15 days later fetch from cms_param_tbl-----------
BEGIN
  prm_err_msg := 'OK';
  --pswd_Expiry_date:=15;

    Begin
      SELECT
        cgm_lgpw_chin,
        cgm_txpw_chin,
        cui_inst_code
      INTO
        lgin_expiry_days,
        txn_expiry_days,
        v_inst_code     -- added by sagar on 28-Dec-2011
      FROM
        cms_groupdetl_mast groupmast, cms_usgpdetl_mast usergroup, cms_userdetl_mast usermast, cms_user_inst userinst
      WHERE usermast.cum_user_code    = usergroup.cum_user_code
      AND usergroup.cum_grup_code     = groupmast.cgm_grup_code
      AND usermast.cum_lgin_code      = prm_login_id
      AND userinst.cui_user_code      = usermast.cum_user_code
      AND userinst.cui_inst_code      = groupmast.cgm_inst_code
      AND userinst.cui_dflt_inst      = 1;

    exception when no_data_found then
    prm_err_msg := 'userid '||prm_login_id||'not found ';
    raise exp_rej;
    when others then
    prm_err_msg := 'while fetching details for user code '||prm_login_id||' '||substr(sqlerrm,1,100);
    raise exp_rej;
    end;
  --days_of_expiry := 7;

 Begin
  SELECT cip_param_value
  INTO days_of_expiry
  FROM cms_inst_param
  WHERE cip_inst_code = v_inst_code
  and   cip_param_key = 'WRONG PSWDS';

    exception when no_data_found then
    prm_err_msg := 'param key not found in master ';
    raise exp_rej;
    when others then
    prm_err_msg := 'while fetching expiry days '||' '||substr(sqlerrm,1,100);
    raise exp_rej;
 End;
  --------- Checking User Status ----------------

 Begin
      SELECT DECODE (cum_user_stus, 1, 'active', 2, 'suspended', 3, 'locked', 4, 'expired', 5, 'notapproved' ),
            cum_vald_frdt,
            cum_vald_todt,
            cum_frtx_pswd,
            cum_frlg_pswd,
            sysdate - cum_lgpw_date,
            sysdate - cum_txpw_date, cum_lgpw_rsfl,
            sysdate - cum_lgpw_rsdt, cum_txpw_rsfl,
            sysdate - cum_txpw_rsdt
      INTO
            user_status, from_date, to_dat, force_txn_pswd,
            force_login_pswd, login_pswd_days, txn_pswd_days, login_pswd_reset,
            login_pswd_change, txn_pswd_reset, txn_pswd_change
      FROM cms_userdetl_mast
      WHERE cum_lgin_code = prm_login_id;

    exception when no_data_found then
    prm_err_msg := 'login code '||prm_login_id||' not found in master ';
    raise exp_rej;
    when others then
    prm_err_msg := 'while fetching details for login code '||substr(sqlerrm,1,100);
    raise exp_rej;

 End;

  IF user_status = 'active' THEN
    ----Checking Validity period of user---------
    IF TRUNC (SYSDATE) BETWEEN TRUNC (from_date) AND TRUNC (to_dat) THEN
      --IF (force_txn_pswd = 0 AND force_login_pswd = 0)  -- 18 Nov 2011
      IF (force_login_pswd = 0) THEN
        ----Reset Password----------
        --IF (login_pswd_reset = 0 AND txn_pswd_reset = 0)
        IF (login_pswd_reset = 0 ) THEN
          ------Password Expired------
          IF ( login_pswd_days > lgin_expiry_days) THEN
            --  IF (login_pswd_days <= lgin_expiry_days)         -- SN commenting 18 Nov 2011
            -- prm_err_msg := 'loginPasswordExpired';
            -- END IF;                                           -- EN commenting 18 Nov 2011
            -- ELSE
            prm_err_msg := 'PasswordExpired';
          END IF;
        ELSE
          IF (login_pswd_reset    = 1) THEN
            prm_err_msg := 'ResetPassword';
          END IF;
        END IF;
        --END IF
      ELSE
        IF ( login_pswd_change > days_of_expiry ) THEN
          prm_err_msg         := 'ResetloginPassword';
        ELSE
          prm_err_msg := 'FirstTimeLogin';
        END IF;
      END IF;
    ELSE
      IF TRUNC (SYSDATE) < TRUNC (from_date) THEN
        prm_err_msg     := 'UserValidityNotStarted';
      ELSE
        UPDATE
          cms_userdetl_mast
        SET
          cum_user_stus = 4, cum_lupd_user = cum_user_code, cum_lupd_date = SYSDATE
        WHERE cum_lgin_code = prm_login_id;

        prm_err_msg := 'UserNotValid';
      END IF;
    END IF;
  ELSE
    prm_err_msg := user_status;
  END IF;
  -------------End Checking Validity period of user---------
EXCEPTION WHEN exp_rej
then
prm_err_msg := prm_err_msg;
  --WHEN NO_DATA_FOUND
  --Then prm_err_msg:='Error While checking validity period due to NO_DATA_FOUND';
WHEN OTHERS
  ----Then prm_err_msg:= 'DataBase Error';
  THEN
  --prm_err_msg:='Error While checking validity period due to NO_DATA_FOUND';
  prm_err_msg := 'DataBaseError';
END;
 