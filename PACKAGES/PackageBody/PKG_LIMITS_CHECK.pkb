create or replace
PACKAGE BODY        vmscms.PKG_LIMITS_CHECK
IS
   PROCEDURE sp_limits_check (
      prm_hash_pan           IN       VARCHAR2,
      prm_frmacct_no         IN       VARCHAR2,
      prm_toacct_no          IN       VARCHAR2,
      prm_mcc_code           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_tran_type          IN       CHAR,
      prm_intl_flag          IN       VARCHAR2,
      prm_pnsign_flag        IN       CHAR,
      prm_inst_code          IN       NUMBER,
      prm_trfr_crdacnt       IN       VARCHAR2,
      prm_lmt_prfl           IN       VARCHAR2,
      prm_txn_amt            IN       NUMBER,
      prm_delivery_channel   IN       VARCHAR2,
      prm_crdcomb_hash       OUT      pkg_limits_check.type_hash,
      prm_err_code           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2,
      prm_mr_flag                IN     VARCHAR2 default 'N',   --Added by Pankaj S. for MR INGO limit issue(MVHOST-1041)
      prm_payment_type        IN     VARCHAR2 default null --Added for DFCTNM-4(MoneySend)
   )
   AS
      v_count_qury                VARCHAR2 (4000);
      v_ccd_colm_list             VARCHAR2 (4000);
      v_ccd_cnt_qry               VARCHAR2 (4000);
      v_ccd_upd_qry               VARCHAR2 (4000);
      v_ccd_slct_qry              VARCHAR2 (4000);
      v_str                       VARCHAR2 (4000);
      v_cnt                       NUMBER (10);
      -- v_lmtprfl                   cms_card_lmtprfl.ccl_lmtprfl_id%TYPE;
      v_ccd_daly_txncnt           cms_cardsumry_dwmy.ccd_daly_txncnt%TYPE;
      v_ccd_daly_txnamnt          cms_cardsumry_dwmy.ccd_daly_txnamnt%TYPE;
      v_ccd_wkly_txncnt           cms_cardsumry_dwmy.ccd_wkly_txncnt%TYPE;
      v_ccd_wkly_txnamnt          cms_cardsumry_dwmy.ccd_wkly_txnamnt%TYPE;
      v_ccd_mntly_txncnt          cms_cardsumry_dwmy.ccd_mntly_txncnt%TYPE;
      v_ccd_mntly_txnamnt         cms_cardsumry_dwmy.ccd_mntly_txnamnt%TYPE;
      v_ccd_yerly_txncnt          cms_cardsumry_dwmy.ccd_yerly_txncnt%TYPE;
      v_ccd_yerly_txnamnt         cms_cardsumry_dwmy.ccd_yerly_txnamnt%TYPE;
      v_ccd_lifetime_txncnt       cms_cardsumry_dwmy.ccd_lifetime_txncnt%TYPE;
      v_ccd_lifetime_txnamnt      cms_cardsumry_dwmy.ccd_lifetime_txnamnt%TYPE;
      v_prfl_clp_dlvr_chnl        cms_limit_prfl.clp_dlvr_chnl%TYPE;
      v_prfl_clp_pertxn_minamnt   cms_limit_prfl.clp_pertxn_minamnt%TYPE;
      v_prfl_clp_pertxn_maxamnt   cms_limit_prfl.clp_pertxn_maxamnt%TYPE;
      v_prfl_clp_dmax_txncnt      cms_limit_prfl.clp_dmax_txncnt%TYPE;
      v_prfl_clp_dmax_txnamnt     cms_limit_prfl.clp_dmax_txnamnt%TYPE;
      v_prfl_clp_wmax_txncnt      cms_limit_prfl.clp_wmax_txncnt%TYPE;
      v_prfl_clp_wmax_txnamnt     cms_limit_prfl.clp_wmax_txnamnt%TYPE;
      v_prfl_clp_mmax_txncnt      cms_limit_prfl.clp_mmax_txncnt%TYPE;
      v_prfl_clp_mmax_txnamnt     cms_limit_prfl.clp_mmax_txnamnt%TYPE;
      v_prfl_clp_ymax_txncnt      cms_limit_prfl.clp_ymax_txncnt%TYPE;
      v_prfl_clp_ymax_txnamnt     cms_limit_prfl.clp_ymax_txnamnt%TYPE;
      v_prfl_clp_lmax_txncnt      cms_limit_prfl.clp_lmax_txncnt%TYPE;
      v_prfl_clp_lmax_txnamnt     cms_limit_prfl.clp_lmax_txnamnt%TYPE;
      v_err_flag                  VARCHAR2 (10);
      v_err_msg                   VARCHAR2 (4000);
      v_hash_combination          VARCHAR2 (90);
      v_frmhash_combination       VARCHAR2 (90);
      v_tohash_combination        VARCHAR2 (90);
      v_tran_type                 cms_limit_prfl.clp_tran_type%TYPE;
      v_delivery_channel          cms_limit_prfl.clp_dlvr_chnl%TYPE;
      v_tran_code                 cms_limit_prfl.clp_tran_code%TYPE;
      v_intl_flag                 cms_limit_prfl.clp_intl_flag%TYPE;
      v_pnsign_flag               cms_limit_prfl.clp_pnsign_flag%TYPE;
      v_mcc_code                  cms_limit_prfl.clp_mcc_code%TYPE;
      v_trfr_crdacnt              cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_fromtrfr_crdacnt          cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_totrfr_crdacnt            cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_frm_prfl_code             cms_appl_pan.cap_prfl_code%TYPE; --added by amit on 30-Jul-2012 for Card to card transfer
      v_to_prfl_code               cms_appl_pan.cap_prfl_code%TYPE; --added by amit on 30-Jul-2012 for Card to card transfer
      v_39_txn_code                cms_limit_prfl.clp_tran_code%TYPE;
      v_38_txn_code                cms_limit_prfl.clp_tran_code%TYPE;
      --SN:- Group Limit Checks Parameter 
      v_GRPLMT_HASH  CMS_GROUP_LIMIT.Cgl_GRPLMT_HASH%type;
      v_comb_hash_mcc                VARCHAR2 (90);
      v_single_mcc_code              cms_limit_prfl.clp_mcc_code%TYPE; 
      v_comb_hash_payment             VARCHAR2 (90);
      v_moneysend_flag                NUMBER;
      v_ccd_lupd_date                   cms_cardsumry_dwmy.ccd_lupd_date%TYPE;
      v_from_iniload_amt cms_acct_mast.cam_new_initialload_amt%type;
      v_to_iniload_amt cms_acct_mast.cam_new_initialload_amt%type;
      v_iniload_amt cms_acct_mast.cam_new_initialload_amt%type;
      --EN:- Group Limit Checks Parameter  
      PROCEDURE lp_limit_compare (
         prm_txn_amt                 IN       NUMBER,
         prm_delivery_channel        IN       VARCHAR2,  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         prm_ccd_daly_txncnt                  cms_cardsumry_dwmy.ccd_daly_txncnt%TYPE,
         prm_ccd_daly_txnamnt                 cms_cardsumry_dwmy.ccd_daly_txnamnt%TYPE,
         prm_ccd_wkly_txncnt                  cms_cardsumry_dwmy.ccd_wkly_txncnt%TYPE,
         prm_ccd_wkly_txnamnt                 cms_cardsumry_dwmy.ccd_wkly_txnamnt%TYPE,
         prm_ccd_mntly_txncnt                 cms_cardsumry_dwmy.ccd_mntly_txncnt%TYPE,
         prm_ccd_mntly_txnamnt                cms_cardsumry_dwmy.ccd_mntly_txnamnt%TYPE,
         prm_ccd_yerly_txncnt                 cms_cardsumry_dwmy.ccd_yerly_txncnt%TYPE,
         prm_ccd_yerly_txnamnt                cms_cardsumry_dwmy.ccd_yerly_txnamnt%TYPE,
         prm_ccd_lifetime_txncnt              cms_cardsumry_dwmy.ccd_lifetime_txncnt%TYPE,
         prm_ccd_lifetime_txnamnt             cms_cardsumry_dwmy.ccd_lifetime_txnamnt%TYPE,
         prm_prfl_clp_dmax_txncnt    IN       cms_limit_prfl.clp_dmax_txncnt%TYPE,
         prm_prfl_clp_dmax_txnamnt   IN       cms_limit_prfl.clp_dmax_txnamnt%TYPE,
         prm_prfl_clp_wmax_txncnt    IN       cms_limit_prfl.clp_wmax_txncnt%TYPE,
         prm_prfl_clp_wmax_txnamnt   IN       cms_limit_prfl.clp_wmax_txnamnt%TYPE,
         prm_prfl_clp_mmax_txncnt    IN       cms_limit_prfl.clp_mmax_txncnt%TYPE,
         prm_prfl_clp_mmax_txnamnt   IN       cms_limit_prfl.clp_mmax_txnamnt%TYPE,
         prm_prfl_clp_ymax_txncnt    IN       cms_limit_prfl.clp_ymax_txncnt%TYPE,
         prm_prfl_clp_ymax_txnamnt   IN       cms_limit_prfl.clp_ymax_txnamnt%TYPE,
         prm_prfl_clp_lmax_txncnt    IN       cms_limit_prfl.clp_lmax_txncnt%TYPE,
         prm_prfl_clp_lmax_txnamnt   IN       cms_limit_prfl.clp_lmax_txnamnt%TYPE,

         prm_errcode                 OUT      VARCHAR2,
         prm_errmsg                  OUT      VARCHAR2
      )
      IS
      BEGIN
         IF prm_delivery_channel='01'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
             IF prm_prfl_clp_dmax_txncnt>0  and  prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt 
                --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '71';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '72';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '73';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '74';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '75';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and  prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '76';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '77';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '78';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

			       IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
         ELSIF prm_delivery_channel='02'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND  prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes             
             THEN
                prm_errcode := '71';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '72';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '73';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '74';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '75';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '76';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '77';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '78';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
			       IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

         ELSIF prm_delivery_channel='04'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
         
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '71';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
            END IF;

             IF prm_prfl_clp_dmax_txnamnt >0 AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '72';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '73';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '74';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '75';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '76';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '77';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '78';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
			       IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

         ELSIF prm_delivery_channel='05'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '26';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND  prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '27';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '28';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '29';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '30';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '31';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '32';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '33';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
         ELSIF prm_delivery_channel='07'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '127';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '128';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '129';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '130';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '131';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '132';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '133';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '134';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

         ELSIF prm_delivery_channel='10'  --added by amit on 20-Jul-2012 to set resp code on the basis of del chnl
         THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '127';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND  prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '128';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '129';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '130';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '131';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '132';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '133';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '134';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             end if;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
         elsif prm_delivery_channel='03' then --added by amit on 21-Nov-2012 to handle card to card transfer from CSR
         
          
         
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             then
                prm_errcode := '148';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '149';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '150';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '151';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '152';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and  prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '153';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '154';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '155';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                return;
             end if;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
        ELSIF prm_delivery_channel='14'  --Added for MVHOST-383 on 14/06/2013 to set resp code on the basis of del chnl
         THEN
         
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '71';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
            END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '72';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '73';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '74';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '75';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '76';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '77';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '78';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
          --SN Added on 20.08.2013 for MOB-31 
           ELSIF prm_delivery_channel='13' 
           THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '127';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND   prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '128';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '129';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '130';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '131';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '198';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '199';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '200';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
			       IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
           --EN Added on 20.08.2013 for MOB-31
         --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113) 
         ELSIF prm_delivery_channel IN ('11','15') THEN  --'15' added by Pankaj S. for ACH canada
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '24';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND  prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '25';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '35';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '28';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '36';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '29';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '40';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '41';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
			 
             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
                        
         ELSIF prm_delivery_channel='08' THEN
            IF prm_prfl_clp_dmax_txncnt>0  AND prm_ccd_daly_txncnt + 1 > prm_prfl_clp_dmax_txncnt
            --prm_prfl_clp_dmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '138';
                prm_errmsg := 'Daily Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_dmax_txnamnt >0  AND prm_ccd_daly_txnamnt + prm_txn_amt > prm_prfl_clp_dmax_txnamnt
             --prm_prfl_clp_dmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '137';
                prm_errmsg := 'Daily Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txncnt>0 AND prm_ccd_wkly_txncnt + 1 > prm_prfl_clp_wmax_txncnt  --prm_prfl_clp_wmax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '140';
                prm_errmsg := 'Weekly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_wmax_txnamnt>0 AND prm_ccd_wkly_txnamnt + prm_txn_amt > prm_prfl_clp_wmax_txnamnt  --prm_prfl_clp_wmax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '139';
                prm_errmsg := 'Weekly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF  prm_prfl_clp_mmax_txncnt>0  and prm_ccd_mntly_txncnt + 1 > prm_prfl_clp_mmax_txncnt
             --prm_prfl_clp_mmax_txncnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '142';
                prm_errmsg := 'Monthly Number Of Transaction Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_mmax_txnamnt>0  and prm_ccd_mntly_txnamnt + prm_txn_amt > prm_prfl_clp_mmax_txnamnt
             --prm_prfl_clp_mmax_txnamnt>0 condition added by  during group limts changes
             THEN
                prm_errcode := '141';
                prm_errmsg := 'Monthly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txncnt>0 AND prm_ccd_yerly_txncnt + 1 > prm_prfl_clp_ymax_txncnt   --prm_prfl_clp_ymax_txncnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '144';
                prm_errmsg := 'Yearly Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_ymax_txnamnt>0 AND prm_ccd_yerly_txnamnt + prm_txn_amt > prm_prfl_clp_ymax_txnamnt --prm_prfl_clp_ymax_txnamnt>0 condition added by Pankaj S. during group limts changes
             THEN
                prm_errcode := '143';
                prm_errmsg := 'Yearly Transaction Amount Limit  exceeded';
                RETURN;
             END IF;      

             IF prm_prfl_clp_lmax_txncnt>0 AND prm_ccd_lifetime_txncnt + 1 > prm_prfl_clp_lmax_txncnt   
             THEN
                prm_errcode := '233';
                prm_errmsg := 'Lifetime Number Of Transaction  Limit  exceeded';
                RETURN;
             END IF;

             IF prm_prfl_clp_lmax_txnamnt>0 AND prm_ccd_lifetime_txnamnt + prm_txn_amt > prm_prfl_clp_lmax_txnamnt 
             THEN
                prm_errcode := '234';
                prm_errmsg := 'Lifetime Transaction Amount Limit  exceeded';
                RETURN;
             END IF;
             
         --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)     
         END IF;
         prm_errcode := '00'; --00 added instead of 1 on 12-Feb-2013 
         prm_errmsg := 'OK';
      END;

/**********************************************************************************************
     * Created Date     :11-July-2012
     * Created By       :  Dhiraj Gaikwad
     * PURPOSE          : To Check Limits on Card 
     
     * Modified By      : Sagar
     * Modified Date    : 06-Feb-13
     * Modified For     : FSS-815 , Defect 0010281
     * Modified Reason  : 1) To handle card to card transfer from IVR and CHW (FSS-815)
                          2) Decimal change for amount variable (Defect 0010281)           
     * Reviewer         : Dhiraj
     * Reviewed Date    : 06-Feb-13
     * Build Number     : RI0023.2_B0001
     
     * Modified By      : Sagar
     * Modified Date    : 1-mar-2013
     * Modified For     : 10501
     * Modified Reason  : 1) to uncomment prm_err_code := '1' and comment prm_err_code := '00'         
     * Reviewer         : Dhiraj
     * Reviewed Date    : 1-mar-2013
     * Build Number     : RI0023.2_B0011 
     
   
     * Modified By      : Sachin P.
     * Modified Date    : 04-Apr-2013
     * Modified Reason  : Limit Profile not accounting for reversal                       
     * Modified For     : MVHOST-298                       
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0024.1_B0008
   
     * Modified By      : Ramesh
     * Modified Date    : 14-June-2013
     * Modified Reason  : Added delivery channel condition for medagate for limit check                     
     * Modified For     : MVHOST-383                       
     * Reviewer         : 
     * Reviewed Date    : 
     * Build Number     : RI0024.2_B0004
     
     * Modified By      : Shweta
     * Modified Date    : 21-June-2013
     * Modified Reason  : Over the Counter (Bank) Withdrawal - Daily Limit 2,500, Approved $2800                     
     * Modified For     : NCGPR-429                     
     * Reviewer         : Sachin Patil
     * Reviewed Date    : 21-Jun-2013
     * Build Number     : RI0024.2_B0006     
     
      * Modified By      : Sachin Patil
      * Modified Date    : 12-Jul-2013
      * Modified Reason  : NextCala - Sum of C2C transfers per month exceeds 2000.00 and should not                     
      * Modified For     : NCGPR-434                      
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19.07.2013
      * Build Number     : RI0024.3_B0005
      
      * Modified By      : Sachin Patil
      * Modified Date    : 20-AuG-2013
      * Modified Reason  : Enable Card to Card Transfer Feature for Mobile API                                  
      * Modified For     : MOB-31                      
      
      * Modified by       : Dhiraj G.
      * Modified for      : Group Limit Checks      
      * Modified Date     : 14-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 
      * Build Number      : RI0027.2_B0004
      
      * Modified by       : Spankaj
      * Modified for      : FSS-1963      
      * Modified Date     : 06-Nov-2014
      * Build Number      : RI0027.4.2.1
      
       * Modified by       : Spankaj
      * Modified for      : MVHOST-1041     
      * Modified Date     : 12-Nov-2014
      * Build Number      : RI0027.4.2.1
 ***********************************************************************************************/

   BEGIN
      prm_err_code := '1';  -- Commented on 12-Feb-2013 -- uncommented on 1-mar-2013
      --prm_err_code := '00';   -- Added     on 12-Feb-2013 ,00 added instead of 1 on 12-Feb-2013 --Commented on 1-mar-2013
      prm_err_msg := 'OK';
      

      IF prm_delivery_channel IS NULL
      THEN
         v_delivery_channel := 'NA';
      ELSE
         v_delivery_channel := prm_delivery_channel;
      END IF;
      
      
      IF prm_tran_code IS NULL
      THEN
         v_tran_code := 'NA';
      ELSE
      --Start Card to Card Transfer change for CSR on 28112012   
       
       IF prm_tran_code='38' AND prm_delivery_channel='03' THEN 
         
        v_tran_code := '39';
       ELSE 
       --Start Card to Card Transfer change for CSR on 28112012   
       v_tran_code := prm_tran_code;
       END IF; 
      
                    
      END IF;

      IF prm_tran_type IS NULL
      THEN
         v_tran_type := 'NA';
      ELSE
           IF prm_tran_code='38' AND prm_delivery_channel='03' THEN 
            
           
           v_tran_type := 'F' ;
           ELSE 
           
            v_tran_type := prm_tran_type;
           END IF ;  
         
      END IF;

      IF prm_intl_flag IS NULL
      THEN
         v_intl_flag := 'NA';
      ELSE
         v_intl_flag := prm_intl_flag;
      END IF;

      IF trim(prm_pnsign_flag) IS NULL or prm_delivery_channel = '01'  --OR condition added by Spankaj for FSS-1963 
      THEN
         v_pnsign_flag := 'NA';
      ELSE
         v_pnsign_flag := prm_pnsign_flag;
      END IF;

       ----Sn:Shweta on 14June13 for NCGPR-429
      IF trim(prm_mcc_code) IS NOT NULL  and  PRM_DELIVERY_CHANNEL = '01' and  PRM_TRAN_CODE  = '10'  
      THEN
            v_mcc_code := 'NA';
        --En:Shweta on 14June13 NCGPR-429
     /* ElsIF trim(prm_mcc_code) = '6010'
      THEN
                 v_mcc_code := trim(prm_mcc_code);*/ --commented for group limit check
       --SN Added on 02.04.2014 for Group limit check
      ElsIF  prm_delivery_channel = '02' and trim(prm_mcc_code) is not null  then
            
           v_comb_hash_mcc := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                       );
                                               
                BEGIN
                   SELECT clp_mcc_code
                     INTO v_single_mcc_code
                     FROM cms_limit_prfl
                    WHERE clp_inst_code = prm_inst_code
                      AND clp_lmtprfl_id = prm_lmt_prfl
                      AND clp_comb_hash = v_comb_hash_mcc;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                     v_single_mcc_code := 'NA';
                   WHEN OTHERS
                   THEN
                      prm_err_code := '21';
                      prm_err_msg :=
                            'Error while selecting MCC code For Single '
                         || SUBSTR (SQLERRM, 1, 200);
                      RETURN;
                END;    
                
                BEGIN
                     SELECT cgp_mcc_code
                       INTO v_mcc_code
                       FROM cms_grplmt_param
                      WHERE cgp_inst_code = prm_inst_code AND cgp_grpcomb_hash = v_comb_hash_mcc;
                EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_mcc_code := v_single_mcc_code;
                        
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting MCC code For Group '
                           || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;             
      --EN Added on 02.04.2014 for Group limit check               
      ELSE
                 v_mcc_code := 'NA';
      END IF;

      
      IF prm_frmacct_no IS NOT NULL AND prm_toacct_no IS NOT NULL
      THEN
      
         BEGIN                              --added by amit on 30-Jul-2012 to get profile code of from PAN.
            SELECT cap_prfl_code,nvl(cam_new_initialload_amt,0)
            into v_frm_prfl_code,v_from_iniload_amt
            from cms_appl_pan,cms_acct_mast
            where cap_acct_no=cam_acct_no
            and cap_inst_code=cam_inst_code
            and cap_pan_code=prm_frmacct_no
            and cap_inst_code=prm_inst_code;
         EXCEPTION
         WHEN OTHERS THEN
            prm_err_code:='21';
            prm_err_msg:='Error while selecting profile code of from acct '||substr(sqlerrm,1,200);
            RETURN;
         END;

         BEGIN                             --added by amit on 30-Jul-2012 to get profile code of to PAN.
            SELECT cap_prfl_code,nvl(cam_new_initialload_amt,0)
            into v_to_prfl_code,v_to_iniload_amt
            from cms_appl_pan,cms_acct_mast
            where cap_acct_no=cam_acct_no
            and cap_inst_code=cam_inst_code
            and cap_pan_code=prm_toacct_no
            and cap_inst_code=prm_inst_code;
         EXCEPTION
         WHEN OTHERS THEN
            prm_err_code:='21';
            prm_err_msg:='Error while selecting profile code of to acct '||substr(sqlerrm,1,200);
            RETURN;
         END;

          if v_frm_prfl_code is null and v_to_prfl_code is null ---added by amit on 10-Aug-2012 for discard limit verification if limit profile
          THEN                                               ---is not attached to both the cards 
            prm_err_code := '1';  -- Commented on 12-Feb-2013 -- uncommented on 1-mar-2013
            --prm_err_code := '00';   --Added     on 12-Feb-2013 ,00 added instead of 1 on 12-Feb-2013 --Commented on 1-mar-2013
            prm_err_msg := 'OK';
            RETURN;
          END IF;

         v_fromtrfr_crdacnt := 'OW';
         v_totrfr_crdacnt := 'IW';
      ELSE
         v_trfr_crdacnt := 'NA';
      END IF;


      begin
      
         --if prm_delivery_channel in( '10','07','03') --modified by amit on 08-Aug-2012 to include IVR card to card fund transfer. 
                                                     --'03' added by amit on 21-Nov-2012 to handle Card to card transfer from CSR
      --   IF prm_delivery_channel in( '10','07','03','13') and  prm_frmacct_no IS NOT NULL AND prm_toacct_no IS NOT NULL--Modified on 19.08.2013 for MOB-31
         IF prm_delivery_channel in( '10','07','03','13') and  prm_frmacct_no IS NOT NULL AND prm_toacct_no IS NOT NULL --modified for Group Limit Checks
         THEN
            
             IF v_frm_prfl_code is not null  ---addded by amit on 10-Aug-2012 to insert record in surmy tbale only when profile code is attached
             THEN
              v_frmhash_combination :=
               gethash (   TRIM (v_frm_prfl_code) --added by amit on 24-Jul-2012 to add profile id in hash combination due to change in constraint defination.
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (v_mcc_code)
                        || TRIM (v_fromtrfr_crdacnt)
                       );
                prm_crdcomb_hash (1).prfl_id := v_frm_prfl_code; --added by amit on 30-Jul-2012 for card to card transfer
          
                prm_crdcomb_hash (1).comb_hash := v_frmhash_combination;
              
                prm_crdcomb_hash (1).pan_code := prm_frmacct_no;  --modified by amit on 22-Jul-2012 for card to card transfer
              
                 prm_crdcomb_hash (1).load_amount := v_from_iniload_amt;
             ELSE
                prm_crdcomb_hash (1).prfl_id := NULL; --added by amit on 10-Aug-2012 assign null if  prfile is not attached to from card
                
                prm_crdcomb_hash (1).comb_hash := NULL;    --added by amit on 10-Aug-2012 assign null if  prfile is not attached to from card
               
                prm_crdcomb_hash (1).pan_code := NULL;  --added by amit on 10-Aug-2012 assign null if  prfile is not attached to from card
               
                prm_crdcomb_hash (1).load_amount := null;
             END IF;


            IF v_to_prfl_code is not null ---addded by amit on 10-Aug-2012 to insert record in surmy tbale only when profile code is attached
            THEN
                v_tohash_combination :=
                   gethash (   TRIM (v_to_prfl_code) --added by amit on 24-Jul-2012 to add profile id in hash combination due to change in constraint defination.
                            || TRIM (v_delivery_channel)
                            || TRIM (v_tran_code)
                            || TRIM (v_tran_type)
                            || TRIM (v_intl_flag)
                            || TRIM (v_pnsign_flag)
                            || TRIM (v_mcc_code)
                            || TRIM (v_totrfr_crdacnt)
                           );

                prm_crdcomb_hash (2).prfl_id := v_to_prfl_code;         --added by amit on 30-Jul-2012 for card to card transfer
           
                prm_crdcomb_hash (2).comb_hash := v_tohash_combination;
              
                prm_crdcomb_hash (2).pan_code := prm_toacct_no;  --modified by amit on 22-Jul-2012 for card to card transfer
               
                prm_crdcomb_hash (2).load_amount := v_to_iniload_amt;
            END IF;
            
         ELSE
                 
            v_hash_combination :=
               gethash (   TRIM (prm_lmt_prfl) --added by amit on 24-Jul-2012 to add profile id in hash combination due to change in constraint defination.
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (v_mcc_code)
                        || TRIM (v_trfr_crdacnt)
                       );
     
            BEGIN
                SELECT nvl(CAM_new_INITIALLOAD_AMT,0)
                into v_iniload_amt
                FROM CMS_ACCT_MAST,CMS_APPL_PAN
                WHERE CAP_ACCT_NO=Cam_ACCT_NO
                AND CAP_INST_CODE=CAM_INST_CODE
                AND CAP_PAN_CODE=PRM_HASH_PAN;
            exception
                when others then
                   prm_err_msg:='Error while selecting from acct_mast/appl_pan'||sqlerrm;
                   return;
            end;
            prm_crdcomb_hash (1).prfl_id := prm_lmt_prfl;
          
            prm_crdcomb_hash (1).comb_hash := v_hash_combination;
          
            prm_crdcomb_hash (1).pan_code := prm_hash_pan;                              
           
            prm_crdcomb_hash (1).load_amount := v_iniload_amt;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_err_code := '21';
            prm_err_msg := 'Error While Generating Hash Value ' || SQLERRM;
            RETURN;
      END;

      FOR i IN 1 .. prm_crdcomb_hash.COUNT
      LOOP
         

         IF prm_crdcomb_hash(i).prfl_id is not NULL THEN  --added by amit on 10-Aug-2012 for         
          --ST :Added for DFCTNM-4(MoneySend)
          if prm_delivery_channel = '02' and trim(prm_mcc_code) is not null and prm_payment_type is not null then
         
                 v_comb_hash_payment := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                        ||TRIM (prm_payment_type) 
                       );                
                   
                   BEGIN
                     SELECT count(1) into v_moneysend_flag                      
                       FROM cms_limit_prfl
                      WHERE clp_inst_code = prm_inst_code
                        AND clp_lmtprfl_id = prm_lmt_prfl
                        AND clp_comb_hash = v_comb_hash_payment;
                     EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                      v_moneysend_flag := 0;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting payment type For Single '
                           || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                   END;                                    
                  
                  if v_moneysend_flag = 1 then
                  
                    prm_crdcomb_hash (1).comb_hash := v_comb_hash_payment;
                  
                  end if;
                      
             end if;
             --END: Added for DFCTNM-4(MoneySend)
             BEGIN
                SELECT clp_pertxn_minamnt, greatest(nvl(clp_pertxn_maxamnt,0),prm_crdcomb_hash (i).load_amount),
                       nvl(clp_dmax_txncnt,0), greatest(nvl(clp_dmax_txnamnt,0),prm_crdcomb_hash (i).load_amount),--NVL added during group limit changes
                       nvl(clp_wmax_txncnt,0), greatest(nvl(clp_wmax_txnamnt,0),prm_crdcomb_hash (i).load_amount),  --NVL added by pankaj S. during group limit changes
                       nvl(clp_mmax_txncnt,0), greatest(nvl(clp_mmax_txnamnt,0),prm_crdcomb_hash (i).load_amount),--NVL added  during group limit changes
                       nvl(clp_ymax_txncnt,0), greatest(nvl(clp_ymax_txnamnt,0),prm_crdcomb_hash (i).load_amount),   --NVL added by pankaj S. during group limit changes
                       nvl(clp_lmax_txncnt,0), greatest(nvl(clp_lmax_txnamnt,0),prm_crdcomb_hash (i).load_amount)   
                  INTO v_prfl_clp_pertxn_minamnt, v_prfl_clp_pertxn_maxamnt,
                       v_prfl_clp_dmax_txncnt, v_prfl_clp_dmax_txnamnt,
                       v_prfl_clp_wmax_txncnt, v_prfl_clp_wmax_txnamnt,
                       v_prfl_clp_mmax_txncnt, v_prfl_clp_mmax_txnamnt,
                       v_prfl_clp_ymax_txncnt, v_prfl_clp_ymax_txnamnt,
                       v_prfl_clp_lmax_txncnt, v_prfl_clp_lmax_txnamnt
                  FROM cms_limit_prfl
                 WHERE clp_inst_code = prm_inst_code
                   AND clp_lmtprfl_id = prm_crdcomb_hash(i).prfl_id
                   AND clp_comb_hash = prm_crdcomb_hash (i).comb_hash;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                  prm_err_code := '1';  -- Commented on 12-Feb-2013  -- uncommented on 1-mar-2013
                  -- prm_err_code := '00';   -- Added    on 12-Feb-2013 ,00 added instead of 1 on 12-Feb-2013 --Commented on 1-mar-2013
                   prm_err_msg := 'OK';
                   --RETURN; --Commented And Modified For Group Limit Reversal Reset 
                   --EXIT;
                   continue;
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                      'Error while selecting Limit Profile Parameters '
                      || SQLERRM;
                   RETURN;
             END;
             
             
             
           --Start Card to Card Transfer change for CSR on 28112012   
            IF (prm_delivery_channel ='03'          AND prm_tran_code IN('38','39')) OR
               (prm_delivery_channel in ('10','07') AND prm_tran_code ='07') OR           -- Added on 06-Feb-2013 for FSS-815
                (prm_delivery_channel in ('13') AND prm_tran_code ='13')          -- Added on 19.08.2013 for MOB-31   
            THEN 
             
                 
                 IF prm_txn_amt < v_prfl_clp_pertxn_minamnt
                 THEN
                     
                       IF I=1 -- It indicates loop for From card FSS-815
                       THEN  

                            prm_err_code := '79'; 
                            prm_err_msg := 'From Card Transaction Amount is Less Than Minimum Per Txn Amount';
                            RETURN;
                                
                       ELSIF I=2 -- It indicates loop for To card FSS-815
                       THEN
                       
                            prm_err_code := '79';
                            prm_err_msg := 'To Card Transaction Amount is Less Than Minimum Per Txn Amount';
                            RETURN;
                               
                       END IF;                  
                        
                 END IF;
                     

                 IF prm_txn_amt > v_prfl_clp_pertxn_maxamnt
                 THEN
                 
                      IF I=1 -- It indicates loop for From card FSS-815
                      then                
                   
                        prm_err_code := '80';
                        prm_err_msg :=
                              'From Card Transaction Amount is Greater Than Maximum Per Txn Amount';
                        RETURN;
                        
                      elsif I=2 -- It indicates loop for To card FSS-815
                      THEN
                      
                        prm_err_code := '80';
                        prm_err_msg :=
                              'To Card Transaction Amount is Greater Than Maximum Per Txn Amount';
                        RETURN;
                        
                      END IF;
                    
                 END IF;
                 
                 IF prm_delivery_channel ='03' AND prm_tran_code ='38' 
                 THEN   
                     
                     IF  prm_err_msg = 'OK' 
                     THEN 
                     
                         prm_err_msg :=prm_err_msg;
                         RETURN ;
                     
                     END IF ;
                 
                 END IF; 
                 
            --End Card to Card Transfer change for CSR on 28112012
               
            ELSE 
               IF prm_mr_flag='N' then  --Added by Pankaj S. for MR INGO limit issue(MVHOST-1041)
                 IF prm_txn_amt < v_prfl_clp_pertxn_minamnt
                 THEN
                    prm_err_code := '79';
                    prm_err_msg :=
                             'Transaction Amount is Less Than Minimum Per Txn Amount';
                    RETURN;
                 END IF;

                 IF prm_txn_amt > v_prfl_clp_pertxn_maxamnt
                 THEN
                    prm_err_code := '80';
                    prm_err_msg :=
                          'Transaction Amount is Greater Than Maximum Per Txn Amount';
                    RETURN;
                 END IF;
              END IF;
            END IF; 
            
            
             BEGIN
             
                SELECT ccd_daly_txncnt, ccd_daly_txnamnt, ccd_wkly_txncnt,
                       ccd_wkly_txnamnt, ccd_mntly_txncnt,
                       ccd_mntly_txnamnt, ccd_yerly_txncnt,
                       ccd_yerly_txnamnt,ccd_lupd_date,
                       ccd_lifetime_txncnt, ccd_lifetime_txnamnt
                  INTO v_ccd_daly_txncnt, v_ccd_daly_txnamnt, v_ccd_wkly_txncnt,
                       v_ccd_wkly_txnamnt, v_ccd_mntly_txncnt,
                       v_ccd_mntly_txnamnt, v_ccd_yerly_txncnt,
                       v_ccd_yerly_txnamnt,v_ccd_lupd_date,
                       v_ccd_lifetime_txncnt, v_ccd_lifetime_txnamnt
                  FROM cms_cardsumry_dwmy
                 WHERE ccd_inst_code = prm_inst_code
                   AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
                   AND ccd_comb_hash = prm_crdcomb_hash (i).comb_hash;
                 
                  --Sn Added for FSS-3418
                   IF TRUNC (v_ccd_lupd_date) < TRUNC (SYSDATE)
                   THEN
                      v_ccd_daly_txncnt := 0;
                      v_ccd_daly_txnamnt := 0;

                      IF TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
                         OR SYSDATE > NEXT_DAY (v_ccd_lupd_date, 'SUNDAY')
                      THEN
                         v_ccd_wkly_txncnt := 0;
                         v_ccd_wkly_txnamnt := 0;
                      END IF;

                      IF TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101'
                         OR TRUNC (SYSDATE, 'YY') > v_ccd_lupd_date
                      THEN
                         v_ccd_mntly_txncnt := 0;
                         v_ccd_mntly_txnamnt := 0;
                         v_ccd_yerly_txncnt := 0;
                         v_ccd_yerly_txnamnt := 0;
                      ELSIF TRIM (TO_CHAR (SYSDATE, 'DD')) = '01'
                            OR TRUNC (SYSDATE, 'MM') > v_ccd_lupd_date
                      THEN
                         v_ccd_mntly_txncnt := 0;
                         v_ccd_mntly_txnamnt := 0;
                      END IF;
                   END IF;       
                   --En Added for FSS-3418      
             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   --prm_err_code := 1;  --coomented by amit on 26-Jul-2012
                   --prm_err_msg := 'OK';
                   --RETURN;
                   v_ccd_daly_txncnt:=0; --added on 26-Jul-2012 for first txn which is not present in the card summry table
                   v_ccd_daly_txnamnt:=0;
                   v_ccd_wkly_txncnt:=0;
                   v_ccd_wkly_txnamnt:=0;
                   v_ccd_mntly_txncnt:=0;
                   v_ccd_mntly_txnamnt:=0;
                   v_ccd_yerly_txncnt:=0;
                   v_ccd_yerly_txnamnt:=0;
                   v_ccd_lifetime_txncnt := 0; 
                   v_ccd_lifetime_txnamnt := 0;
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                         'Error while Taking Values  From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                      || prm_delivery_channel
                      || ' -- '
                      || prm_crdcomb_hash (i).pan_code
                      || '--Combo Hash----'
                      || prm_crdcomb_hash (i).comb_hash
                      || ' -- '
                      || SQLERRM;
                   RETURN;
             END;

             BEGIN
                lp_limit_compare (prm_txn_amt,
                                  prm_delivery_channel, --added by amit on 20-Jul-12 to set resp code on the basis of del chnl
                                  v_ccd_daly_txncnt,
                                  v_ccd_daly_txnamnt,
                                  v_ccd_wkly_txncnt,
                                  v_ccd_wkly_txnamnt,
                                  v_ccd_mntly_txncnt,
                                  v_ccd_mntly_txnamnt,
                                  v_ccd_yerly_txncnt,
                                  v_ccd_yerly_txnamnt,
                                  v_ccd_lifetime_txncnt, 
                                  v_ccd_lifetime_txnamnt,
                                  v_prfl_clp_dmax_txncnt,
                                  v_prfl_clp_dmax_txnamnt,
                                  v_prfl_clp_wmax_txncnt,
                                  v_prfl_clp_wmax_txnamnt,
                                  v_prfl_clp_mmax_txncnt,
                                  v_prfl_clp_mmax_txnamnt,
                                  v_prfl_clp_ymax_txncnt,
                                  v_prfl_clp_ymax_txnamnt,
                                  v_prfl_clp_lmax_txncnt,
                                  v_prfl_clp_lmax_txnamnt,
                                  v_err_flag,
                                  v_err_msg
                                 );

                IF v_err_flag <> '00' -- 00 added instead of 1 on 12-Feb-2013 
                AND v_err_msg <> 'OK'
                THEN
                   prm_err_code := v_err_flag;
                   
                   IF (prm_delivery_channel ='03'          AND prm_tran_code IN('38','39')) or 
                      (prm_delivery_channel in ('10','07') AND prm_tran_code ='07') or         -- Added on 06-Feb-2013 for FSS-815
                      (prm_delivery_channel in ('13') AND prm_tran_code ='13')          -- Added on 19.08.2013 for MOB-31
                   THEN                    
                   
                       IF I=1  -- It indicates loop for From card FSS-815
                       THEN
                       
                          v_err_msg   := 'From card '||v_err_msg;
                          prm_err_msg := v_err_msg;
                          return;
                             
                       ELSIF I=2 -- It indicates loop for To card FSS-815
                       THEN
                       
                          v_err_msg   := 'To card '||v_err_msg;
                          prm_err_msg := v_err_msg;
                          return;
                       
                       END IF;
                       
                   END IF;    
                   
                   prm_err_msg := v_err_msg;
                   RETURN;
                END IF;
                
                
             EXCEPTION
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                         'Error while ATM Transaction Limit Checks '
                      || SUBSTR (SQLERRM, 1, 300);
                   RETURN;
             END;
             
         END IF;
         
      END LOOP;
      
   -------------------------------------
   --SN:- Group Limit Checks
   -------------------------------------
   v_prfl_clp_pertxn_minamnt := NULL;
   v_prfl_clp_pertxn_maxamnt := NULL;
   v_prfl_clp_dmax_txncnt := NULL;
   v_prfl_clp_dmax_txnamnt := NULL;
   v_prfl_clp_wmax_txncnt := NULL;
   v_prfl_clp_wmax_txnamnt := NULL;
   v_prfl_clp_mmax_txncnt := NULL;
   v_prfl_clp_mmax_txnamnt := NULL;
   v_prfl_clp_ymax_txncnt := NULL;
   v_prfl_clp_ymax_txnamnt := NULL;
   v_prfl_clp_lmax_txncnt := NULL;
   v_prfl_clp_lmax_txnamnt := NULL;
   v_ccd_daly_txncnt := NULL;
   v_ccd_daly_txnamnt := NULL;
   v_ccd_wkly_txncnt := NULL;
   v_ccd_wkly_txnamnt := NULL;
   v_ccd_mntly_txncnt := NULL;
   v_ccd_mntly_txnamnt := NULL;
   v_ccd_yerly_txncnt := NULL;
   v_ccd_yerly_txnamnt := NULL;
   v_ccd_lifetime_txncnt := NULL;
   v_ccd_lifetime_txnamnt := NULL;
   v_ccd_lupd_date:=NULL;

   FOR i IN 1 .. prm_crdcomb_hash.COUNT
   LOOP
      IF prm_crdcomb_hash (i).prfl_id IS NOT NULL
      THEN
      --ST: Added for DFCTNM-4(MoneySend)
       if prm_delivery_channel = '02' and trim(prm_mcc_code) is not null and prm_payment_type is not null then
         
                 v_comb_hash_payment := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                        ||TRIM (prm_payment_type) 
                       );                
                                  
                  BEGIN
                       SELECT count(1) into v_moneysend_flag                            
                         FROM cms_grplmt_param
                        WHERE cgp_inst_code = prm_inst_code AND cgp_grpcomb_hash = v_comb_hash_payment;
                     EXCEPTION
                       WHEN NO_DATA_FOUND
                       THEN
                          v_moneysend_flag := 0;                         
                       WHEN OTHERS
                       THEN
                          prm_err_code := '21';
                          prm_err_msg :=
                                'Error while selecting payment type For Group '
                             || SUBSTR (SQLERRM, 1, 200);
                          RETURN;
                  END;  
                  
                  if v_moneysend_flag = 1 then
                  
                    prm_crdcomb_hash (1).comb_hash := v_comb_hash_payment;
                  
                  end if;
                      
             end if;
        --END: Added for DFCTNM-4(MoneySend)
         BEGIN
            SELECT gethash (cgp_group_code || cgp_limit_prfl)
              INTO v_grplmt_hash
              FROM cms_grplmt_param
             WHERE cgp_inst_code = prm_inst_code
               AND cgp_grpcomb_hash = prm_crdcomb_hash (i).comb_hash;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_err_code := '1';
               prm_err_msg := 'OK';
               --RETURN;
               continue;
            WHEN OTHERS THEN
               prm_err_code := '21';
               prm_err_msg := 'Error while Group and Limit Relation ' ||  SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
         
         

         BEGIN
            SELECT cgl_pertxn_minamnt,   greatest(nvl(cgl_pertxn_maxamnt,0),prm_crdcomb_hash (i).load_amount),
                   nvl(cgl_dmax_txncnt,0), greatest(nvl(cgl_dmax_txnamnt,0),prm_crdcomb_hash (i).load_amount),--NVL added during group limit changes
                   nvl(cgl_wmax_txncnt,0), greatest(nvl(cgl_wmax_txnamnt,0),prm_crdcomb_hash (i).load_amount), --NVL added by pankaj S. during group limit changes
                   nvl(cgl_mmax_txncnt,0), greatest(nvl(cgl_mmax_txnamnt,0),prm_crdcomb_hash (i).load_amount),--NVL added during group limit changes
                   nvl(cgl_ymax_txncnt,0), greatest(nvl(cgl_ymax_txnamnt,0),prm_crdcomb_hash (i).load_amount),  --NVL added by pankaj S. during group limit changes
				   nvl(cgl_lmax_txncnt,0), greatest(nvl(cgl_lmax_txnamnt,0),prm_crdcomb_hash (i).load_amount)
              INTO v_prfl_clp_pertxn_minamnt, v_prfl_clp_pertxn_maxamnt,
                   v_prfl_clp_dmax_txncnt, v_prfl_clp_dmax_txnamnt,
                   v_prfl_clp_wmax_txncnt, v_prfl_clp_wmax_txnamnt,
                   v_prfl_clp_mmax_txncnt, v_prfl_clp_mmax_txnamnt,
                   v_prfl_clp_ymax_txncnt, v_prfl_clp_ymax_txnamnt,
				   v_prfl_clp_lmax_txncnt, v_prfl_clp_lmax_txnamnt
              FROM cms_group_limit
             WHERE cgl_inst_code = prm_inst_code
               AND cgl_grplmt_hash = v_grplmt_hash;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_err_code := '1';
               prm_err_msg := 'OK';
               --RETURN;
               continue;
            WHEN OTHERS THEN
               prm_err_code := '21';
               prm_err_msg :='Error while selecting Limit Profile Parameters '|| SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

         IF  (prm_delivery_channel = '03' AND prm_tran_code IN ('38', '39')) OR 
             (prm_delivery_channel IN ('10', '07') AND prm_tran_code = '07')
            OR (prm_delivery_channel IN ('13') AND prm_tran_code = '13') THEN
            IF prm_txn_amt < v_prfl_clp_pertxn_minamnt THEN
               IF i = 1 THEN
                  prm_err_code := '79';
                  prm_err_msg :='From Card Transaction Amount is Less Than Minimum Per Txn Amount';
                  RETURN;
               ELSIF i = 2 THEN
                  prm_err_code := '79';
                  prm_err_msg := 'To Card Transaction Amount is Less Than Minimum Per Txn Amount';
                  RETURN;
               END IF;
            END IF;

            IF prm_txn_amt > v_prfl_clp_pertxn_maxamnt THEN
               IF i = 1 THEN
                  prm_err_code := '80';
                  prm_err_msg :=
                     'From Card Group Transaction Amount is Greater Than Maximum Per Txn Amount';
                  RETURN;
               ELSIF i = 2 THEN
                  prm_err_code := '80';
                  prm_err_msg :='To Card Group Transaction Amount is Greater Than Maximum Per Txn Amount';
                  RETURN;
               END IF;
            END IF;

            IF prm_delivery_channel = '03' AND prm_tran_code = '38' THEN
               IF prm_err_msg = 'OK'
               THEN
                  prm_err_msg := prm_err_msg;
                  RETURN;
               END IF;
            END IF;
         ELSE
           IF prm_mr_flag='N' then  --Added by Pankaj S. for MR INGO limit issue(MVHOST-1041)
            IF prm_txn_amt < v_prfl_clp_pertxn_minamnt THEN
               prm_err_code := '79';
               prm_err_msg :=
                     'Transaction Amount is Less Than Minimum Per Txn Amount';
               RETURN;
            END IF;

            IF prm_txn_amt > v_prfl_clp_pertxn_maxamnt THEN
               prm_err_code := '80';
               prm_err_msg :='Transaction Amount is Greater Than Maximum Per Txn Amount';
               RETURN;
            END IF;
           END IF; 
         END IF;

         BEGIN
            SELECT ccd_daly_txncnt, ccd_daly_txnamnt, ccd_wkly_txncnt,
                   ccd_wkly_txnamnt, ccd_mntly_txncnt,
                   ccd_mntly_txnamnt, ccd_yerly_txncnt,
                   ccd_yerly_txnamnt,ccd_lupd_date,
				   ccd_lifetime_txncnt, ccd_lifetime_txnamnt
              INTO v_ccd_daly_txncnt, v_ccd_daly_txnamnt, v_ccd_wkly_txncnt,
                   v_ccd_wkly_txnamnt, v_ccd_mntly_txncnt,
                   v_ccd_mntly_txnamnt, v_ccd_yerly_txncnt,
                   v_ccd_yerly_txnamnt,v_ccd_lupd_date,
				   v_ccd_lifetime_txncnt, v_ccd_lifetime_txnamnt
              FROM cms_cardsumry_dwmy
             WHERE ccd_inst_code = prm_inst_code
               AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
               AND ccd_comb_hash = v_grplmt_hash;
               
                 --Sn Added for FSS-3418
                   IF TRUNC (v_ccd_lupd_date) < TRUNC (SYSDATE)
                   THEN
                      v_ccd_daly_txncnt := 0;
                      v_ccd_daly_txnamnt := 0;

                      IF TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
                         OR SYSDATE > NEXT_DAY (v_ccd_lupd_date, 'SUNDAY')
                      THEN
                         v_ccd_wkly_txncnt := 0;
                         v_ccd_wkly_txnamnt := 0;
                      END IF;

                      IF TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101'
                         OR TRUNC (SYSDATE, 'YY') > v_ccd_lupd_date
                      THEN
                         v_ccd_mntly_txncnt := 0;
                         v_ccd_mntly_txnamnt := 0;
                         v_ccd_yerly_txncnt := 0;
                         v_ccd_yerly_txnamnt := 0;
                      ELSIF TRIM (TO_CHAR (SYSDATE, 'DD')) = '01'
                            OR TRUNC (SYSDATE, 'MM') > v_ccd_lupd_date
                      THEN
                         v_ccd_mntly_txncnt := 0;
                         v_ccd_mntly_txnamnt := 0;
                      END IF;
                   END IF;       
                   --En Added for FSS-3418                 
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_ccd_daly_txncnt := 0;
               v_ccd_daly_txnamnt := 0;
               v_ccd_wkly_txncnt := 0;
               v_ccd_wkly_txnamnt := 0;
               v_ccd_mntly_txncnt := 0;
               v_ccd_mntly_txnamnt := 0;
               v_ccd_yerly_txncnt := 0;
               v_ccd_yerly_txnamnt := 0;
			   v_ccd_lifetime_txncnt := 0;
               v_ccd_lifetime_txnamnt := 0;
            WHEN OTHERS  THEN
               prm_err_code := '21';
               prm_err_msg :='Error while Taking Values  From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                  || prm_delivery_channel
                  || ' -- '
                  || prm_crdcomb_hash (i).pan_code
                  || '--Combo Hash----'
                  || prm_crdcomb_hash (i).comb_hash
                  || ' -- '
                  ||  SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

         BEGIN
            lp_limit_compare (prm_txn_amt,
                              prm_delivery_channel,
                              v_ccd_daly_txncnt,
                              v_ccd_daly_txnamnt,
                              v_ccd_wkly_txncnt,
                              v_ccd_wkly_txnamnt,
                              v_ccd_mntly_txncnt,
                              v_ccd_mntly_txnamnt,
                              v_ccd_yerly_txncnt,
                              v_ccd_yerly_txnamnt,
                              v_ccd_lifetime_txncnt,
                              v_ccd_lifetime_txnamnt,
                              v_prfl_clp_dmax_txncnt,
                              v_prfl_clp_dmax_txnamnt,
                              v_prfl_clp_wmax_txncnt,
                              v_prfl_clp_wmax_txnamnt,
                              v_prfl_clp_mmax_txncnt,
                              v_prfl_clp_mmax_txnamnt,
                              v_prfl_clp_ymax_txncnt,
                              v_prfl_clp_ymax_txnamnt,
                              v_prfl_clp_lmax_txncnt,
                              v_prfl_clp_lmax_txnamnt,
                              v_err_flag,
                              v_err_msg
                             );

            IF v_err_flag <> '00' AND v_err_msg <> 'OK' THEN
               prm_err_code := v_err_flag;

               IF (prm_delivery_channel = '03' AND prm_tran_code IN ('38', '39') ) OR 
                  (prm_delivery_channel IN ('10', '07') AND prm_tran_code = '07')
                  OR (prm_delivery_channel IN ('13') AND prm_tran_code = '13')THEN
                  IF i = 1 THEN
                     v_err_msg := 'From card Group  ' || v_err_msg;
                     prm_err_msg := v_err_msg;
                     RETURN;
                  ELSIF i = 2 THEN
                     v_err_msg := 'To card Group  ' || v_err_msg;
                     prm_err_msg := v_err_msg;
                     RETURN;
                  END IF;
               END IF;

               prm_err_msg := 'Group ' || v_err_msg;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               prm_err_code := '21';
               prm_err_msg := 'Error while Transaction Limit Checks '|| SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      END IF;
   END LOOP;
   -------------------------------------
   --EN:- Group Limit Checks
   -------------------------------------
   EXCEPTION
          WHEN OTHERS THEN
             prm_err_code := '21';
             prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
   END;

------------------------------------------------------------------------------------------------------
   PROCEDURE sp_limits_eod (prm_err_code OUT VARCHAR2, prm_err_msg OUT VARCHAR2)
   AS
      CURSOR cur_crd_summary
      IS
         SELECT '''' || ROWID || '''' row_id, ccd_pan_code, ccd_comb_hash
           FROM cms_cardsumry_dwmy;

      TYPE cur_crd_summary_type IS TABLE OF cur_crd_summary%ROWTYPE;

      cur_crd_summary_data   cur_crd_summary_type;

      v_upd_query            VARCHAR2 (4000);
      v_upd_query1           VARCHAR2(4000);
   BEGIN
      prm_err_code := '1';
      prm_err_msg := 'OK';

      IF     TRIM(TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
         AND TRIM(TO_CHAR (SYSDATE, 'DDMM')) = '0101'
         AND TRIM(TO_CHAR (SYSDATE, 'DD')) = '01'
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_wkly_txncnt = 0,
                   ccd_wkly_txnamnt = 0,
                   ccd_mntly_txncnt = 0,
                   ccd_mntly_txnamnt = 0,
                   ccd_yerly_txncnt = 0,
                   ccd_yerly_txnamnt = 0
             WHERE ROWID =  ';
      ELSIF     TRIM(TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
            AND TRIM(TO_CHAR (SYSDATE, 'DD')) = '01'
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_wkly_txncnt = 0,
                   ccd_wkly_txnamnt = 0,
                   ccd_mntly_txncnt = 0,
                   ccd_mntly_txnamnt = 0
             WHERE ROWID =  ';
      ELSIF    TRIM( TO_CHAR (SYSDATE, 'DDMM')) = '0101'
             --AND TRIM(TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'  --Modified by Pankaj S. for yearly count issue.
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_mntly_txncnt=0, 
                   ccd_mntly_txnamnt=0, 
                   ccd_yerly_txncnt = 0,
                   ccd_yerly_txnamnt = 0
             WHERE ROWID = ';
      ELSIF TRIM(TO_CHAR (SYSDATE, 'DD')) = '01'
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_mntly_txncnt = 0,
                   ccd_mntly_txnamnt = 0
                   WHERE ROWID = ';
      ELSIF TRIM(TO_CHAR (SYSDATE, 'DDMM'))= '0101'
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_yerly_txncnt = 0,
                   ccd_yerly_txnamnt = 0
             WHERE ROWID = ';
      ELSIF TRIM(TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
      THEN
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0,
                   ccd_wkly_txncnt = 0,
                   ccd_wkly_txnamnt = 0
             WHERE ROWID = ';
      ELSE
         v_upd_query :=
            ' UPDATE cms_cardsumry_dwmy
               SET ccd_daly_txncnt = 0,
                   ccd_daly_txnamnt = 0
                     WHERE ROWID = ';
      END IF;

      BEGIN
         OPEN cur_crd_summary;

         LOOP
            FETCH cur_crd_summary
            BULK COLLECT INTO cur_crd_summary_data LIMIT 10000;

            EXIT WHEN cur_crd_summary_data.COUNT () = 0;

            FOR i IN 1 .. cur_crd_summary_data.COUNT ()
            LOOP
               BEGIN
                  v_upd_query1:=v_upd_query || cur_crd_summary_data (i).row_id;
              

                  EXECUTE IMMEDIATE v_upd_query1;
                  IF SQL%ROWCOUNT = 0
                  THEN
                     prm_err_code := '21';
                     prm_err_msg :=
                           'No Rows Updated In CMS_APPL_PAN For Pan --'
                        || cur_crd_summary_data (i).ccd_pan_code
                        || 'Combination Hash Value  --'
                        || cur_crd_summary_data (i).ccd_comb_hash
                        || SQLERRM;
                     RETURN;
                  END IF;
                  v_upd_query1:=NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     prm_err_msg :=
                                 'WHILE UPDATE :' || SUBSTR (SQLERRM, 1, 100);
                     prm_err_code := '21';
                     RETURN;
               END;
            END LOOP;

            COMMIT;
         END LOOP;

         CLOSE cur_crd_summary;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_code := '21';
         prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
   END;

---------------------------------------------------------------------------------------------------------------------
   PROCEDURE sp_limitcnt_reset (
      prm_inst_code      IN       NUMBER,
      prm_hash_pan       IN       VARCHAR2,
      prm_txn_amt        IN       NUMBER,
      prm_crdcomb_hash   IN       pkg_limits_check.type_hash,
      prm_err_code       OUT      VARCHAR2,
      prm_err_msg        OUT      VARCHAR2
   )
   AS
      v_cnt                   NUMBER (10);
      v_err_flag              VARCHAR2 (10);
      v_err_msg               VARCHAR2 (4000);
      v_hash_combination      VARCHAR2 (90);
      v_frmhash_combination   VARCHAR2 (90);
      v_tohash_combination    VARCHAR2 (90);
      --v_txn_amt               NUMBER(20); -- added by amit on 27-Jul-12 to handle non financial txn in which txn amt comes null
      v_txn_amt               cms_cardsumry_dwmy.ccd_daly_txnamnt%type;   -- Added on 12-Feb-2013 Defect 0010281
      
      v_lmtpfrl_cnt           NUMBER ; --Added on 12.07.2013 for NCGPR-434
      --SN:- Group Limit Checks Parameter 
      v_GRPLMT_HASH  CMS_GROUP_LIMIT.Cgl_GRPLMT_HASH%type;
      v_wmax_txncnt      cms_limit_prfl.clp_wmax_txncnt%TYPE;
      v_wmax_txnamnt     cms_limit_prfl.clp_wmax_txnamnt%TYPE;
      v_ymax_txncnt      cms_limit_prfl.clp_ymax_txncnt%TYPE;
      v_ymax_txnamnt     cms_limit_prfl.clp_ymax_txnamnt%TYPE;
	  v_lmax_txncnt      cms_limit_prfl.clp_lmax_txncnt%TYPE;
      v_lmax_txnamnt     cms_limit_prfl.clp_lmax_txnamnt%TYPE;
      v_dmax_txncnt      cms_limit_prfl.clp_dmax_txncnt%TYPE;
      v_dmax_txnamnt     cms_limit_prfl.clp_dmax_txnamnt%TYPE;
      v_mmax_txncnt      cms_limit_prfl.clp_mmax_txncnt%TYPE;
      v_mmax_txnamnt     cms_limit_prfl.clp_mmax_txnamnt%TYPE;
      v_lmtpfrl_id       cms_limit_prfl.clp_lmtprfl_id%TYPE;
      v_lsttxn_date               cms_cardsumry_dwmy.ccd_lupd_date%type;
      --EN:- Group Limit Checks Parameter  
   BEGIN
   
      prm_err_code := '1';  -- Commented on 12-Feb-2013 -- uncommented on 1-mar-2013 
      --prm_err_code := '00';   -- Added     on 12-Feb-2013 ,00 added instead of 1 on 12-Feb-2013 --Commented on 1-mar-2013
      prm_err_msg := 'OK';

      IF prm_txn_amt IS NULL --added by amit on 27-Jul-12 to handle non financial txn
      THEN
        v_txn_amt:=0;
      ELSE
        v_txn_amt:=prm_txn_amt;
      END IF;

      FOR i IN 1 .. prm_crdcomb_hash.COUNT
      LOOP          
           --Sn Added by Pankaj S. during group limit changes
           v_lmtpfrl_id:=NULL;
           v_wmax_txncnt:=NULL;
           v_wmax_txnamnt:=NULL;
           v_ymax_txncnt:=NULL;
           v_ymax_txnamnt:=NULL;
           v_dmax_txncnt:=NULL;
           v_dmax_txnamnt:=NULL;
           v_mmax_txncnt:=NULL;
           v_mmax_txnamnt:=NULL;
		   v_lmax_txncnt:=NULL;
           v_lmax_txnamnt:=NULL;
           v_lsttxn_date :=NULL;
           --En Added by Pankaj S. during group limit changes
      
      
         BEGIN
            SELECT ccd_lupd_date--COUNT (*)
              INTO v_lsttxn_date --v_cnt
              FROM cms_cardsumry_dwmy
             WHERE ccd_inst_code = prm_inst_code
               AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
               AND ccd_comb_hash = prm_crdcomb_hash (i).comb_hash;
           v_cnt:=1;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            v_cnt:=0;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                     'Error while Taking Count From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                  || prm_crdcomb_hash (i).pan_code
                  || ' -- '
                  || '-----Hash Combination---'
                  || prm_crdcomb_hash (i).comb_hash
                  || SQLERRM;
               RETURN;
         END;
         
         --Sn Modified by Pankaj S. during group limits changes
          BEGIN
                SELECT clp_lmtprfl_id,nvl(clp_wmax_txncnt,0),nvl(clp_wmax_txnamnt,0),nvl(clp_ymax_txncnt,0),nvl(clp_ymax_txnamnt,0),
                       nvl(clp_dmax_txncnt,0),nvl(clp_dmax_txnamnt,0),
                       nvl(clp_mmax_txncnt,0),nvl(clp_mmax_txnamnt,0),
					   nvl(clp_lmax_txncnt,0),nvl(clp_lmax_txnamnt,0)
                  INTO v_lmtpfrl_id,v_wmax_txncnt,v_wmax_txnamnt,v_ymax_txncnt,v_ymax_txnamnt,
                      v_dmax_txncnt,v_dmax_txnamnt,
                      v_mmax_txncnt,v_mmax_txnamnt,
					  v_lmax_txncnt,v_lmax_txnamnt
                  FROM cms_limit_prfl
                 WHERE clp_inst_code = prm_inst_code                   
                   AND clp_comb_hash = prm_crdcomb_hash (i).comb_hash;          
          EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                     v_wmax_txncnt:=0;
                     v_wmax_txnamnt:=0;
                     v_ymax_txncnt:=0;
                     v_ymax_txnamnt:=0;    
                     v_lmax_txncnt:=0;
                     v_lmax_txnamnt:=0; 					 
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                      'Error while checking combination hash in Limit Profile Master--'
                      || SQLERRM;
                   RETURN;
          END;    
         
         /*--SN Added on 12.07.2013 for NCGPR-434             
          BEGIN
                SELECT count(1)
                  INTO v_lmtpfrl_cnt
                  FROM cms_limit_prfl
                 WHERE clp_inst_code = prm_inst_code                   
                   AND clp_comb_hash = prm_crdcomb_hash (i).comb_hash;          
          EXCEPTION              
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                      'Error while checking combination hash in Limit Profile Master--'
                      || SQLERRM;
                   RETURN;
       /  END;                   
         --EN Added on 12.07.2013 for NCGPR-434*/
         --En Modified by Pankaj S. during group limits changes
         
       IF v_lmtpfrl_id IS NOT NULL THEN --v_lmtpfrl_cnt  > 0 THEN  --Condition Added on 12.07.2013 for NCGPR-434  --Modified by Pankaj S. during group limit changes
         IF v_cnt = 0 and prm_crdcomb_hash(i).prfl_id is not null --added by amit on 10-Aug-2012
         THEN
            BEGIN
               INSERT INTO cms_cardsumry_dwmy
                           (ccd_inst_code, ccd_pan_code,
                            ccd_comb_hash, ccd_daly_txncnt,
                            ccd_daly_txnamnt, ccd_wkly_txncnt,
                            ccd_wkly_txnamnt, ccd_mntly_txncnt,
                            ccd_mntly_txnamnt, ccd_yerly_txncnt,
                            ccd_yerly_txnamnt, ccd_lupd_date, ccd_lupd_user,
                            ccd_ins_date, ccd_ins_user,
                            ccd_lifetime_txncnt, ccd_lifetime_txnamnt
                           )
                    VALUES (prm_inst_code, prm_crdcomb_hash (i).pan_code,
                            prm_crdcomb_hash (i).comb_hash, decode(v_dmax_txncnt,0,0,1),
                             decode(v_dmax_txnamnt,0,0,v_txn_amt), decode(v_wmax_txncnt,0,0,1),      --Modified during group limit changes               --  modified by amit on 27-Jul-12 to handle non financial txn in which txn amt comes null
                            decode(v_wmax_txnamnt,0,0,v_txn_amt), decode(v_mmax_txncnt,0,0,1), --Modified during group limit changes
                            decode(v_mmax_txnamnt,0,0,v_txn_amt), decode(v_ymax_txncnt,0,0,1), --Modified during group limit changes
                            decode(v_ymax_txnamnt,0,0,v_txn_amt), SYSDATE, 1,  --Modified during group limit changes
                            SYSDATE, 1,
                            decode(v_lmax_txncnt,0,0,1), decode(v_lmax_txnamnt,0,0,v_txn_amt)
                           );

            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                        'Error while Inserting INTO CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '-----Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SQLERRM;
                  RETURN;
            END;
         ELSE
           --Sn added for limit reset issue
           IF trunc(v_lsttxn_date) < trunc(SYSDATE) THEN       
             BEGIN
               UPDATE cms_cardsumry_dwmy
                  SET ccd_daly_txncnt = 1,
                      ccd_daly_txnamnt =v_txn_amt,
                      ccd_wkly_txncnt = case when TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY' OR SYSDATE > NEXT_DAY (v_lsttxn_date, 'SUNDAY')  then 0 else ccd_wkly_txncnt END +1,
                      ccd_wkly_txnamnt = case when TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY' OR SYSDATE > NEXT_DAY (v_lsttxn_date, 'SUNDAY')  then 0 else ccd_wkly_txnamnt END+v_txn_amt, 
                       ccd_mntly_txncnt =  case when TRIM (TO_CHAR (SYSDATE, 'DD')) = '01'  OR TRUNC (SYSDATE, 'MM') > v_lsttxn_date then 0 else ccd_mntly_txncnt END +1,
                      ccd_mntly_txnamnt =case when TRIM (TO_CHAR (SYSDATE, 'DD')) = '01'  OR TRUNC (SYSDATE, 'MM') > v_lsttxn_date then 0 else ccd_mntly_txnamnt END+v_txn_amt, 
                      ccd_yerly_txncnt = case when TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101' OR TRUNC (SYSDATE, 'YY') > v_lsttxn_date then 0 else ccd_yerly_txncnt END +1,
                      ccd_yerly_txnamnt =case when TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101' OR TRUNC (SYSDATE, 'YY') > v_lsttxn_date  then 0 else ccd_yerly_txnamnt END+v_txn_amt,
                      ccd_lupd_date =sysdate,
					  ccd_lifetime_txncnt = ccd_lifetime_txncnt + 1,  
					  ccd_lifetime_txnamnt = ccd_lifetime_txnamnt + v_txn_amt  
                WHERE ccd_inst_code = prm_inst_code
                  AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
                  AND ccd_comb_hash = prm_crdcomb_hash (i).comb_hash;           
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                        'Error while Updating In CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '-----Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SQLERRM;
                  RETURN;
            END;
          ELSE      
           --Sn added for limit reset issue
            BEGIN
               UPDATE cms_cardsumry_dwmy
                  SET --ccd_daly_txncnt = ccd_daly_txncnt + 1,
                      --ccd_daly_txnamnt = ccd_daly_txnamnt + v_txn_amt, --  modified by amit on 27-Jul-12 to handle non financial txn in which txn amt comes null
                      ccd_daly_txncnt = ccd_daly_txncnt + decode(v_dmax_txncnt,0,0,1),
                      ccd_daly_txnamnt = ccd_daly_txnamnt + decode(v_dmax_txnamnt,0,0,v_txn_amt),
                      ccd_wkly_txncnt = ccd_wkly_txncnt + decode(v_wmax_txncnt,0,0,1),   --Modified during group limit changes
                      ccd_wkly_txnamnt = ccd_wkly_txnamnt + decode(v_wmax_txnamnt,0,0,v_txn_amt), --Modified during group limit changes
                     -- ccd_mntly_txncnt = ccd_mntly_txncnt + 1,
                      --ccd_mntly_txnamnt = ccd_mntly_txnamnt + v_txn_amt,
                       ccd_mntly_txncnt = ccd_mntly_txncnt + decode(v_mmax_txncnt,0,0,1),
                      ccd_mntly_txnamnt = ccd_mntly_txnamnt + decode(v_mmax_txnamnt,0,0,v_txn_amt),
                      ccd_yerly_txncnt = ccd_yerly_txncnt + decode(v_ymax_txncnt,0,0,1), --Modified during group limit changes
                      ccd_yerly_txnamnt = ccd_yerly_txnamnt + decode(v_ymax_txnamnt,0,0,v_txn_amt), --Modified during group limit changes
                      ccd_lupd_date =sysdate,
					  ccd_lifetime_txncnt = ccd_lifetime_txncnt + 1, 
					  ccd_lifetime_txnamnt = ccd_lifetime_txnamnt + v_txn_amt  
                WHERE ccd_inst_code = prm_inst_code  
                  AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
                  AND ccd_comb_hash = prm_crdcomb_hash (i).comb_hash;

           
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                        'Error while Updating In CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '-----Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SQLERRM;
                  RETURN;
            END;
           END IF; 
         END IF;
       END IF;  
      END LOOP;
      
   -------------------------------
   --SN:- Group Limit Reset
   -------------------------------
   FOR i IN 1 .. prm_crdcomb_hash.COUNT
   LOOP
       --Sn Added by Pankaj S. during group limit changes
           v_lmtpfrl_id:=NULL;
           v_wmax_txncnt:=NULL;
           v_wmax_txnamnt:=NULL;
           v_ymax_txncnt:=NULL;
           v_ymax_txnamnt:=NULL;
           v_dmax_txncnt:=NULL;
           v_dmax_txnamnt:=NULL;
           v_mmax_txncnt:=NULL;
           v_mmax_txnamnt:=NULL;
		   v_lmax_txncnt:=NULL;
           v_lmax_txnamnt:=NULL;
            v_lsttxn_date :=NULL;
           --En Added by Pankaj S. during group limit changes
           
      BEGIN
         SELECT gethash (cgp_group_code || cgp_limit_prfl)
           INTO v_grplmt_hash
           FROM cms_grplmt_param
          WHERE cgp_inst_code = prm_inst_code
            AND cgp_grpcomb_hash = prm_crdcomb_hash (i).comb_hash;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            prm_err_code := '1';
            prm_err_msg := 'OK';
            RETURN;
         WHEN OTHERS THEN
            prm_err_code := '21';
            prm_err_msg := 'Error while Group and Limit Relation ' || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      BEGIN
         SELECT ccd_lupd_date --COUNT (*)
           INTO v_lsttxn_date --v_cnt
           FROM cms_cardsumry_dwmy
          WHERE ccd_inst_code = prm_inst_code
            AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
            AND ccd_comb_hash = v_grplmt_hash;
         v_cnt:=1;   
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           v_cnt:=0;
         WHEN OTHERS THEN
            prm_err_code := '21';
            prm_err_msg := 'Error while Taking Count From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
               || prm_crdcomb_hash (i).pan_code
               || ' -- '
               || '-----Group Hash Combination---'
               || v_grplmt_hash
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      --Sn modified during group limit changes
          BEGIN
                SELECT cgl_lmtprfl_id,nvl(cgl_wmax_txncnt,0),nvl(cgl_wmax_txnamnt,0),nvl(cgl_ymax_txncnt,0),nvl(cgl_ymax_txnamnt,0),
                        nvl(cgl_dmax_txncnt,0),nvl(cgl_dmax_txnamnt,0),
                        nvl(cgl_mmax_txncnt,0),nvl(cgl_mmax_txnamnt,0),
						nvl(cgl_lmax_txncnt,0),nvl(cgl_lmax_txnamnt,0)
                  INTO v_lmtpfrl_id,v_wmax_txncnt,v_wmax_txnamnt,v_ymax_txncnt,v_ymax_txnamnt,
                       v_dmax_txncnt,v_dmax_txnamnt,
                       v_mmax_txncnt,v_mmax_txnamnt,
					   v_lmax_txncnt,v_lmax_txnamnt
                  FROM cms_group_limit
                 WHERE cgl_inst_code = prm_inst_code                   
                   AND cgl_grplmt_hash = v_grplmt_hash;          
          EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                     v_wmax_txncnt:=0;
                     v_wmax_txnamnt:=0;
                     v_ymax_txncnt:=0;
                     v_ymax_txnamnt:=0;  
					 v_lmax_txncnt:=0;
                     v_lmax_txnamnt:=0;  					 
                WHEN OTHERS
                THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                      'Error while checking combination hash in Limit Profile Master--'
                      || SQLERRM;
                   RETURN;
          END; 
      /*BEGIN
         SELECT COUNT (1)
           INTO v_lmtpfrl_cnt
           FROM cms_group_limit
          WHERE cgl_inst_code = prm_inst_code
            AND cgl_grplmt_hash = v_grplmt_hash;
      EXCEPTION
         WHEN OTHERS THEN
            prm_err_code := '21';
            prm_err_msg := 'Error while checking combination Group hash in Limit Profile Master--' || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;*/
      --En modified during group limit changes

      IF v_lmtpfrl_id is not null then -- v_lmtpfrl_cnt > 0 THEN                     
         IF  v_cnt = 0 AND prm_crdcomb_hash (i).prfl_id IS NOT NULL THEN
            BEGIN
               INSERT INTO cms_cardsumry_dwmy
                           (ccd_inst_code, ccd_pan_code,
                            ccd_comb_hash, ccd_daly_txncnt,
                            ccd_daly_txnamnt, ccd_wkly_txncnt,
                            ccd_wkly_txnamnt, ccd_mntly_txncnt,
                            ccd_mntly_txnamnt, ccd_yerly_txncnt,
                            ccd_yerly_txnamnt, ccd_lupd_date, ccd_lupd_user,
                            ccd_ins_date, ccd_ins_user,
                            ccd_lifetime_txncnt, ccd_lifetime_txnamnt
                           )
                    VALUES (prm_inst_code, prm_crdcomb_hash (i).pan_code,
                            v_grplmt_hash, decode(v_dmax_txncnt,0,0,1),
                            decode(v_dmax_txnamnt,0,0,v_txn_amt), decode(v_wmax_txncnt,0,0,1),      --Modified during group limit changes   
                            decode(v_wmax_txnamnt,0,0,v_txn_amt),  --Modified during group limit changes
                            decode(v_mmax_txncnt,0,0,1),
                            decode(v_mmax_txnamnt,0,0,v_txn_amt), decode(v_ymax_txncnt,0,0,1), --Modified during group limit changes
                            decode(v_ymax_txnamnt,0,0,v_txn_amt), SYSDATE, 1,  --Modified during group limit changes
                            SYSDATE, 1,
                            decode(v_lmax_txncnt,0,0,1), decode(v_lmax_txnamnt,0,0,v_txn_amt)
                           );
            EXCEPTION
               WHEN OTHERS THEN
                  prm_err_code := '21';
                  prm_err_msg :='Error while Inserting INTO CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '----Group -Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         ELSE
          IF trunc(v_lsttxn_date) < trunc(SYSDATE) THEN
                BEGIN
                   UPDATE cms_cardsumry_dwmy
                      SET ccd_daly_txncnt = 1,
                          ccd_daly_txnamnt = v_txn_amt,
                          ccd_wkly_txncnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY' OR SYSDATE > NEXT_DAY (v_lsttxn_date, 'SUNDAY')  THEN 0 ELSE ccd_wkly_txncnt END + 1,
                          ccd_wkly_txnamnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY' OR SYSDATE > NEXT_DAY (v_lsttxn_date, 'SUNDAY')  THEN 0 ELSE ccd_wkly_txnamnt END + v_txn_amt,
                          ccd_mntly_txncnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DD')) = '01' OR TRUNC (SYSDATE, 'MM') > v_lsttxn_date  THEN 0 ELSE ccd_mntly_txncnt END + 1,
                          ccd_mntly_txnamnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DD')) = '01' OR TRUNC (SYSDATE, 'MM') > v_lsttxn_date THEN 0 ELSE ccd_mntly_txnamnt END + v_txn_amt,
                          ccd_yerly_txncnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101' OR TRUNC (SYSDATE, 'YY') > v_lsttxn_date THEN 0 ELSE ccd_yerly_txncnt END + 1,
                          ccd_yerly_txnamnt = CASE WHEN TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101' OR TRUNC (SYSDATE, 'YY') > v_lsttxn_date THEN 0 ELSE ccd_yerly_txnamnt END + v_txn_amt,
                          ccd_lupd_date =sysdate,
						  ccd_lifetime_txncnt = ccd_lifetime_txncnt + 1,  --check vini
					      ccd_lifetime_txnamnt = ccd_lifetime_txnamnt + v_txn_amt  --check vini
                    WHERE     ccd_inst_code = prm_inst_code
                          AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
                          AND ccd_comb_hash = v_grplmt_hash;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      prm_err_code := '21';
                      prm_err_msg :=
                         'Error while Updating In CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                         || prm_crdcomb_hash (i).pan_code
                         || ' -- '
                         || '-----Group Hash Combination---'
                         || prm_crdcomb_hash (i).comb_hash
                         || SUBSTR (SQLERRM, 1, 300);
                      RETURN;
                END;
          ELSE
            BEGIN
               UPDATE cms_cardsumry_dwmy
                  SET --ccd_daly_txncnt = ccd_daly_txncnt + 1,
                      --ccd_daly_txnamnt = ccd_daly_txnamnt + v_txn_amt, --  modified by amit on 27-Jul-12 to handle non financial txn in which txn amt comes null
                      ccd_daly_txncnt = ccd_daly_txncnt + decode(v_dmax_txncnt,0,0,1),
                      ccd_daly_txnamnt = ccd_daly_txnamnt + decode(v_dmax_txnamnt,0,0,v_txn_amt),
                      ccd_wkly_txncnt = ccd_wkly_txncnt + decode(v_wmax_txncnt,0,0,1),   --Modified during group limit changes
                      ccd_wkly_txnamnt = ccd_wkly_txnamnt + decode(v_wmax_txnamnt,0,0,v_txn_amt), --Modified during group limit changes
                     -- ccd_mntly_txncnt = ccd_mntly_txncnt + 1,
                      --ccd_mntly_txnamnt = ccd_mntly_txnamnt + v_txn_amt,
                       ccd_mntly_txncnt = ccd_mntly_txncnt + decode(v_mmax_txncnt,0,0,1),
                      ccd_mntly_txnamnt = ccd_mntly_txnamnt +  decode(v_mmax_txnamnt,0,0,v_txn_amt),
                      ccd_yerly_txncnt = ccd_yerly_txncnt + decode(v_ymax_txncnt,0,0,1), --Modified during group limit changes
                      ccd_yerly_txnamnt = ccd_yerly_txnamnt + decode(v_ymax_txnamnt,0,0,v_txn_amt), --Modified during group limit changes
                      ccd_lupd_date =sysdate,
					  ccd_lifetime_txncnt = ccd_lifetime_txncnt + 1,  --check vini
					  ccd_lifetime_txnamnt = ccd_lifetime_txnamnt + v_txn_amt  --check vini
                WHERE ccd_inst_code = prm_inst_code
                  AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
                  AND ccd_comb_hash = v_grplmt_hash;
            EXCEPTION
               WHEN OTHERS THEN
                  prm_err_code := '21';
                  prm_err_msg := 'Error while Updating In CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '-----Group Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
          END IF; 
         END IF;
      END IF;
   END LOOP;
   -------------------------------
   --EN:- Group Limit Reset
   ------------------------------- 
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_code := '21';
         prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
   END;
   
   --SN Added on 03.04.2013 for MVHOST-298 
    PROCEDURE sp_limitcnt_rever_reset (
      prm_inst_code      IN       NUMBER,
      prm_frmcrd_no         IN       VARCHAR2,
      prm_tocrd_no          IN       VARCHAR2,
      prm_mcc_code           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_tran_type          IN       CHAR,
      prm_intl_flag          IN       VARCHAR2,
      prm_pnsign_flag        IN       CHAR,  
      prm_lmt_prfl           IN       VARCHAR2,
      prm_txn_amt            IN       NUMBER,
      prm_orgnl_txn_amnt       IN       NUMBER,
      prm_delivery_channel   IN       VARCHAR2,
      prm_hash_pan       IN       VARCHAR2,
      prm_orgnl_date     IN       DATE,
      prm_err_code       OUT      VARCHAR2,
      prm_err_msg        OUT      VARCHAR2,
      prm_payment_type        IN     VARCHAR2 default null --Added for DFCTNM-4(MoneySend)
   )
   AS
      v_cnt                   NUMBER (10);
      v_err_flag              VARCHAR2 (10);
      v_err_msg               VARCHAR2 (4000);
      v_hash_combination      VARCHAR2 (90);
      v_frmhash_combination   VARCHAR2 (90);
      v_tohash_combination    VARCHAR2 (90);      
      v_txn_amt               cms_cardsumry_dwmy.ccd_daly_txnamnt%type; 
      v_upd_query             VARCHAR2 (4000);
      v_upd_query1            VARCHAR2 (4000);
      prm_crdcomb_hash        pkg_limits_check.type_hash;     
      v_delivery_channel      cms_limit_prfl.clp_dlvr_chnl%TYPE;
      v_tran_code             cms_limit_prfl.clp_tran_code%TYPE;
      v_intl_flag             cms_limit_prfl.clp_intl_flag%TYPE;
      v_pnsign_flag           cms_limit_prfl.clp_pnsign_flag%TYPE;
      v_mcc_code              cms_limit_prfl.clp_mcc_code%TYPE;
      v_tran_type             cms_limit_prfl.clp_tran_type%TYPE;
      v_frm_prfl_code         cms_appl_pan.cap_prfl_code%TYPE; 
      v_to_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
      v_fromtrfr_crdacnt      cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_totrfr_crdacnt        cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_trfr_crdacnt          cms_limit_prfl.clp_trfr_crdacnt%TYPE;
      v_rowid                 VARCHAR2(50); 
     
      --SN:- Group Limit Checks Parameter 
      v_GRPLMT_HASH  CMS_GROUP_LIMIT.Cgl_GRPLMT_HASH%type;
      v_comb_hash_mcc                VARCHAR2 (90);
      v_single_mcc_code              cms_limit_prfl.clp_mcc_code%TYPE;
      --EN:- Group Limit Checks Parameter  
      v_comb_hash_payment             VARCHAR2 (90); --Added for DFCTNM-4(MoneySend)
      v_moneysend_flag                NUMBER; --Added for DFCTNM-4(MoneySend)
   BEGIN
   
      prm_err_code := '1';        
      prm_err_msg := 'OK';

      IF prm_txn_amt IS NULL 
      THEN
        v_txn_amt:=0;
      ELSE
        v_txn_amt:=prm_txn_amt;
      END IF;
      
       IF prm_delivery_channel IS NULL
      THEN
         v_delivery_channel := 'NA';
      ELSE
         v_delivery_channel := prm_delivery_channel;
      END IF;
      
      
      IF prm_tran_code IS NULL
      THEN
         v_tran_code := 'NA';
      ELSE         
       
       IF prm_tran_code='38' AND prm_delivery_channel='03' THEN 
         
        v_tran_code := '39';
       ELSE          
       v_tran_code := prm_tran_code;
       END IF; 
      
                    
      END IF;

      IF prm_tran_type IS NULL
      THEN
         v_tran_type := 'NA';
      ELSE
           IF prm_tran_code='38' AND prm_delivery_channel='03' THEN 
            
           
           v_tran_type := 'F' ;
           ELSE 
           
            v_tran_type := prm_tran_type;
           END IF ;  
         
      END IF;

      IF prm_intl_flag IS NULL
      THEN
         v_intl_flag := 'NA';
      ELSE
         v_intl_flag := prm_intl_flag;
      END IF;

      IF trim(prm_pnsign_flag) IS NULL  or prm_delivery_channel = '01'  --OR condition added by Spankaj for FSS-1963 
      THEN
         v_pnsign_flag := 'NA';
      ELSE
         v_pnsign_flag := prm_pnsign_flag;
      END IF;

      ----Sn:Shweta on 14June13 for NCGPR-429
      IF trim(prm_mcc_code) IS NOT NULL  and  PRM_DELIVERY_CHANNEL = '01' and  PRM_TRAN_CODE  = '10'  
      THEN
            v_mcc_code := 'NA';
        --En:Shweta on 14June13 NCGPR-429
    /*  ElsIF trim(prm_mcc_code) = '6010' 
      THEN
                 v_mcc_code := trim(prm_mcc_code);
             --SN Added on 02.04.2014 for Group limit check*/ --commented for group limit check
      ElsIF  prm_delivery_channel = '02' and trim(prm_mcc_code) is not null  then
      
           v_comb_hash_mcc := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                       );
                                               
                BEGIN
                   SELECT clp_mcc_code
                     INTO v_single_mcc_code
                     FROM cms_limit_prfl
                    WHERE clp_inst_code = prm_inst_code
                      AND clp_lmtprfl_id = prm_lmt_prfl
                      AND clp_comb_hash = v_comb_hash_mcc;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                     v_single_mcc_code := 'NA';
                   WHEN OTHERS
                   THEN
                      prm_err_code := '21';
                      prm_err_msg :=
                            'Error while selecting MCC code For Single '
                         || SUBSTR (SQLERRM, 1, 200);
                      RETURN;
                END;    
                
                BEGIN
                     SELECT cgp_mcc_code
                       INTO v_mcc_code
                       FROM cms_grplmt_param
                      WHERE cgp_inst_code = prm_inst_code AND cgp_grpcomb_hash = v_comb_hash_mcc;
                EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_mcc_code := v_single_mcc_code;
                        
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting MCC code For Group '
                           || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;         
      
      --EN Added on 02.04.2014 for Group limit check                
      ELSE
                 v_mcc_code := 'NA';
      END IF;


      IF prm_frmcrd_no IS NOT NULL AND prm_tocrd_no IS NOT NULL
      THEN
      
         BEGIN                            
            SELECT cap_prfl_code
            into v_frm_prfl_code
            from cms_appl_pan
            where cap_pan_code=prm_frmcrd_no --prm_tocrd_no modified during FWR-44
            and cap_inst_code=prm_inst_code;
         EXCEPTION
         WHEN OTHERS THEN
            prm_err_code:='21';
            prm_err_msg:='Error while selecting profile code of from acct '||substr(sqlerrm,1,200);
            RETURN;
         END;

         BEGIN                             
            SELECT cap_prfl_code
            into v_to_prfl_code
            from cms_appl_pan
            where cap_pan_code=prm_tocrd_no
            and cap_inst_code=prm_inst_code;
         EXCEPTION
         WHEN OTHERS THEN
            prm_err_code:='21';
            prm_err_msg:='Error while selecting profile code of to acct '||substr(sqlerrm,1,200);
            RETURN;
         END;

          if v_frm_prfl_code is null and v_to_prfl_code is null
          THEN                                              
            prm_err_code := '1';           
            prm_err_msg := 'OK';
            RETURN;
          END IF;

         v_fromtrfr_crdacnt := 'OW';
         v_totrfr_crdacnt := 'IW';
      ELSE
         v_trfr_crdacnt := 'NA';
      END IF;


      begin
      
        -- if prm_delivery_channel in( '10','07','03') --Modified on 19.08.2013 for MOB-31
        --if prm_delivery_channel in( '10','07','03','13') 
         if prm_delivery_channel in( '10','07','03','13') and prm_frmcrd_no IS NOT NULL AND prm_tocrd_no IS NOT NULL --modified for group check
                                                     
         THEN
            
             IF v_frm_prfl_code is not null  
             THEN
              v_frmhash_combination :=
               gethash (   TRIM (v_frm_prfl_code) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (v_mcc_code)
                        || TRIM (v_fromtrfr_crdacnt)
                       );
                prm_crdcomb_hash (1).prfl_id := v_frm_prfl_code;
          
                prm_crdcomb_hash (1).comb_hash := v_frmhash_combination;
              
                prm_crdcomb_hash (1).pan_code := prm_frmcrd_no;
              
             ELSE
                prm_crdcomb_hash (1).prfl_id := NULL; 
                
                prm_crdcomb_hash (1).comb_hash := NULL; 
               
                prm_crdcomb_hash (1).pan_code := NULL;  
                 
               
             END IF;


            IF v_to_prfl_code is not null
            THEN
                v_tohash_combination :=
                   gethash (   TRIM (v_to_prfl_code)
                            || TRIM (v_delivery_channel)
                            || TRIM (v_tran_code)
                            || TRIM (v_tran_type)
                            || TRIM (v_intl_flag)
                            || TRIM (v_pnsign_flag)
                            || TRIM (v_mcc_code)
                            || TRIM (v_totrfr_crdacnt)
                           );

                prm_crdcomb_hash (2).prfl_id := v_to_prfl_code;       
           
                prm_crdcomb_hash (2).comb_hash := v_tohash_combination;
              
                prm_crdcomb_hash (2).pan_code := prm_tocrd_no; 
                  
               
            END IF;
            
         ELSE      
            v_hash_combination :=
               gethash (   TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (v_mcc_code)
                        || TRIM (v_trfr_crdacnt)
                       );

      
            prm_crdcomb_hash (1).prfl_id := prm_lmt_prfl;
          
            prm_crdcomb_hash (1).comb_hash := v_hash_combination;
          
            prm_crdcomb_hash (1).pan_code := prm_hash_pan;                      
           
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_err_code := '21';
            prm_err_msg := 'Error While Generating Hash Value ' || SQLERRM;
            RETURN;
      END;
      
      

      FOR i IN 1 .. prm_crdcomb_hash.COUNT
      LOOP
      
        --ST :Added for DFCTNM-4(MoneySend)
          if prm_delivery_channel = '02' and trim(prm_mcc_code) is not null and prm_payment_type is not null then
         
                 v_comb_hash_payment := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                        ||TRIM (prm_payment_type) 
                       );                
                   
                   BEGIN
                     SELECT count(1) into v_moneysend_flag                      
                       FROM cms_limit_prfl
                      WHERE clp_inst_code = prm_inst_code
                        AND clp_lmtprfl_id = prm_lmt_prfl
                        AND clp_comb_hash = v_comb_hash_payment;
                     EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                      v_moneysend_flag := 0;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting payment type For Single '
                           || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                   END;                                    
                  
                  if v_moneysend_flag = 1 then
                  
                    prm_crdcomb_hash (1).comb_hash := v_comb_hash_payment;
                  
                  end if;
                      
             end if;
             --END: Added for DFCTNM-4(MoneySend)
         BEGIN
            SELECT '''' || ROWID || ''''  
              INTO v_rowid
              FROM cms_cardsumry_dwmy
             WHERE ccd_inst_code = prm_inst_code
               AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
               AND ccd_comb_hash =prm_crdcomb_hash (i).comb_hash;
          
         EXCEPTION
            WHEN NO_DATA_FOUND 
            THEN 
              NULL;
              --RETURN; --Commented And Modified For Group Limit Reversal Reset
              exit;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                     'Error while Taking ROWID From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
                  || prm_crdcomb_hash (i).pan_code
                  || ' -- '
                  || '-----Hash Combination---'
                  || prm_crdcomb_hash (i).comb_hash
                  || SQLERRM;
               RETURN;
         END;

         IF  prm_crdcomb_hash(i).prfl_id is not null 
         THEN
                    
              IF   TRUNC(prm_orgnl_date) = TRUNC(SYSDATE)                 
              THEN           
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                 THEN  
                    v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_daly_txncnt = CASE WHEN ccd_daly_txncnt <= 0 THEN
                         0  ELSE   ccd_daly_txncnt - 1  END,                         
                         ccd_daly_txnamnt = CASE WHEN  ccd_daly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_daly_txnamnt - '||V_TXN_AMT||' END,                                                  
                         ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                         0  ELSE   ccd_wkly_txncnt - 1  END,
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                                          
                         ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END, 
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 						 
                   WHERE ROWID =  ';              
               
              ELSE
              
                v_upd_query := 
                   ' UPDATE cms_cardsumry_dwmy
                     SET        
                         ccd_daly_txnamnt = CASE WHEN  ccd_daly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_daly_txnamnt - '||V_TXN_AMT||' END,          
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,               
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,     
						 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END     
                   WHERE ROWID =  ';                  
                                
                                                  
              END IF;      
                            
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY') AND 
               TO_NUMBER(to_char(prm_orgnl_date,'YYYY')) < TO_NUMBER(to_char(SYSDATE,'YYYY'))              
              THEN
                  
                   IF  prm_orgnl_txn_amnt = prm_txn_amt 
                     THEN  
                            v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                             0  ELSE   ccd_wkly_txncnt - 1  END,
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,    
							 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
							 0  ELSE   ccd_lifetime_txncnt - 1  END,
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 									 
                       WHERE ROWID =  ';          
                              
                     ELSE
                     
                       v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET 
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,    
                             ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                       WHERE ROWID =  ';  
                         
                                                   
                  END IF;  
                  
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY') AND 
               TO_NUMBER(to_char(prm_orgnl_date,'MM')) < TO_NUMBER(to_char(SYSDATE,'MM'))              
              THEN    
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                     THEN  
                            v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                             0  ELSE   ccd_wkly_txncnt - 1  END,
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,
                             ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                             0  ELSE   ccd_yerly_txncnt - 1  END,
                             ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  
							 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
							 0  ELSE   ccd_lifetime_txncnt - 1  END,
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                       WHERE ROWID =  ';          
                              
                     ELSE
                     
                       v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET 
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,
                             ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,     
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                       WHERE ROWID =  ';  
                         
                                                   
                  END IF;   
              
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY')              
              THEN
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                 THEN  
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                         0  ELSE   ccd_wkly_txncnt - 1  END,
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                                          
                         ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  	  
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';          
                          
                 ELSE
                 
                   v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET 
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,               
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,             
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,      
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';  
                     
                                               
                 END IF;   
                 
             
              ELSIF  TRUNC(SYSDATE) <= TRUNC(LAST_DAY(prm_orgnl_date)) 
              THEN
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                 THEN  
                     
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,    
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';   
                
                 ELSE
                                     
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,              
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';   
                       
                 END IF;     
                 
             
              ELSIF TRUNC(SYSDATE) <= LAST_DAY(ADD_MONTHS(TRUNC(prm_orgnl_date,'YYYY'),11))                                        
              THEN
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                 THEN  
                   v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';   
                 
                 ELSE
                 
                    v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET  ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,    
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		
                   WHERE ROWID =  ';                                  
                     
                 END IF;            
              END IF;
             
           IF v_upd_query IS NOT NULL 
           THEN 
               BEGIN
                  v_upd_query1:=v_upd_query || v_rowid;              
         
                  EXECUTE IMMEDIATE v_upd_query1;
         
                  v_upd_query1:=NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN                   
                  prm_err_code := '21';
                  prm_err_msg :=
                        'Error while Updating In CMS_CARDSUMRY_DWMY in reversal txn. For pan code-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '-----Hash Combination---'
                     || prm_crdcomb_hash (i).comb_hash
                     || SQLERRM;
                  RETURN;
               END;
                          
           END IF;
         
         END IF;
      END LOOP;
      
      
    -------------------------------
    --SN:- Group Limit reversal Reset
    -------------------------------
    FOR i IN 1 .. prm_crdcomb_hash.COUNT
    LOOP
     --ST: Added for DFCTNM-4(MoneySend)
       if prm_delivery_channel = '02' and trim(prm_mcc_code) is not null and prm_payment_type is not null then
         
                 v_comb_hash_payment := gethash (TRIM (prm_lmt_prfl) 
                        || TRIM (v_delivery_channel)
                        || TRIM (v_tran_code)
                        || TRIM (v_tran_type)
                        || TRIM (v_intl_flag)
                        || TRIM (v_pnsign_flag)
                        || TRIM (trim(prm_mcc_code))
                        || TRIM ('NA')
                        ||TRIM (prm_payment_type) 
                       );                
                                  
                  BEGIN
                       SELECT count(1) into v_moneysend_flag                            
                         FROM cms_grplmt_param
                        WHERE cgp_inst_code = prm_inst_code AND cgp_grpcomb_hash = v_comb_hash_payment;
                     EXCEPTION
                       WHEN NO_DATA_FOUND
                       THEN
                          v_moneysend_flag := 0;                         
                       WHEN OTHERS
                       THEN
                          prm_err_code := '21';
                          prm_err_msg :=
                                'Error while selecting payment type For Group '
                             || SUBSTR (SQLERRM, 1, 200);
                          RETURN;
                  END;  
                  
                  if v_moneysend_flag = 1 then
                  
                    prm_crdcomb_hash (1).comb_hash := v_comb_hash_payment;
                  
                  end if;
                      
             end if;
        --END: Added for DFCTNM-4(MoneySend)
      BEGIN
         SELECT gethash (cgp_group_code || cgp_limit_prfl)
           INTO v_grplmt_hash
           FROM cms_grplmt_param
          WHERE cgp_inst_code = prm_inst_code
            AND cgp_grpcomb_hash = prm_crdcomb_hash (i).comb_hash;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL;
            RETURN;
         WHEN OTHERS THEN
            prm_err_code := '21';
            prm_err_msg := 'Error while Group and Limit Relation ' || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      BEGIN
         SELECT '''' || ROWID || ''''
           INTO v_rowid
           FROM cms_cardsumry_dwmy
          WHERE ccd_inst_code = prm_inst_code
            AND ccd_pan_code = prm_crdcomb_hash (i).pan_code
            AND ccd_comb_hash = v_grplmt_hash;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL;
            RETURN;
         WHEN OTHERS THEN
            prm_err_code := '21';
            prm_err_msg :='Error while Taking ROWID From CMS_CARDSUMRY_DWMY For Delivery Channel-- '
               || prm_crdcomb_hash (i).pan_code
               || ' -- '
               || '---- Group -Hash Combination---'
               || v_grplmt_hash
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;

      IF prm_crdcomb_hash (i).prfl_id IS NOT NULL THEN
         IF TRUNC (prm_orgnl_date) = TRUNC (SYSDATE) THEN
            IF prm_orgnl_txn_amnt = prm_txn_amt THEN
                    v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_daly_txncnt = CASE WHEN ccd_daly_txncnt <= 0 THEN
                         0  ELSE   ccd_daly_txncnt - 1  END,                         
                         ccd_daly_txnamnt = CASE WHEN  ccd_daly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_daly_txnamnt - '||V_TXN_AMT||' END,                                                  
                         ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                         0  ELSE   ccd_wkly_txncnt - 1  END,
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                                          
                         ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END, 
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		                         
                   WHERE ROWID =  ';              
               
              ELSE
              
                v_upd_query := 
                   ' UPDATE cms_cardsumry_dwmy
                     SET        
                         ccd_daly_txnamnt = CASE WHEN  ccd_daly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_daly_txnamnt - '||V_TXN_AMT||' END,          
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,               
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,     
						 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END                             
                   WHERE ROWID =  ';                  
                                
                                                  
              END IF;      
                            
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY') AND 
               TO_NUMBER(to_char(prm_orgnl_date,'YYYY')) < TO_NUMBER(to_char(SYSDATE,'YYYY')) THEN
                  
                   IF  prm_orgnl_txn_amnt = prm_txn_amt  THEN  
                            v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                             0  ELSE   ccd_wkly_txncnt - 1  END,
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,    
							 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
							 0  ELSE   ccd_lifetime_txncnt - 1  END,
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 				                     
                       WHERE ROWID =  ';          
                              
                     ELSE
                     
                       v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET 
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,    
                             ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	
                       WHERE ROWID =  ';  
                         
                                                   
                  END IF;  
                  
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY') AND 
               TO_NUMBER(to_char(prm_orgnl_date,'MM')) < TO_NUMBER(to_char(SYSDATE,'MM')) THEN    
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt THEN  
                            v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                             0  ELSE   ccd_wkly_txncnt - 1  END,
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,
                             ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                             0  ELSE   ccd_yerly_txncnt - 1  END,
                             ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  
							 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
							 0  ELSE   ccd_lifetime_txncnt - 1  END,
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		                        
                       WHERE ROWID =  ';          
                              
                     ELSE
                     
                       v_upd_query :=
                       ' UPDATE cms_cardsumry_dwmy
                         SET 
                             ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,
                             ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                             0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,     
							 ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
							 0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 		                                                 
                       WHERE ROWID =  ';  
                         
                                                   
                  END IF;   
              
              ELSIF  TRUNC(SYSDATE) <= NEXT_DAY(prm_orgnl_date,'SUNDAY') THEN
                 IF  prm_orgnl_txn_amnt = prm_txn_amt THEN  
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_wkly_txncnt = CASE WHEN ccd_wkly_txncnt <= 0 THEN
                         0  ELSE   ccd_wkly_txncnt - 1  END,
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,                                          
                         ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  	  
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	                                 
                   WHERE ROWID =  ';          
                          
                 ELSE
                 
                   v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET 
                         ccd_wkly_txnamnt = CASE WHEN  ccd_wkly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_wkly_txnamnt - '||V_TXN_AMT||' END,               
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,             
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,      
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	                          
                   WHERE ROWID =  ';  
                     
                                               
                 END IF;   
                 
             
              ELSIF  TRUNC(SYSDATE) <= TRUNC(LAST_DAY(prm_orgnl_date)) THEN
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt THEN  
                     
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_mntly_txncnt = CASE WHEN ccd_mntly_txncnt <= 0 THEN
                         0  ELSE   ccd_mntly_txncnt - 1  END,
                         ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,                                         
                         ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,    
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	                                
                   WHERE ROWID =  ';   
                
                 ELSE
                                     
                        v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_mntly_txnamnt = CASE WHEN ccd_mntly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_mntly_txnamnt - '||V_TXN_AMT||' END,              
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,  
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	                              
                   WHERE ROWID =  ';   
                       
                 END IF;     
                 
             
              ELSIF TRUNC(SYSDATE) <= LAST_DAY(ADD_MONTHS(TRUNC(prm_orgnl_date,'YYYY'),11)) THEN
              
                 IF  prm_orgnl_txn_amnt = prm_txn_amt 
                 THEN  
                   v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET ccd_yerly_txncnt = CASE WHEN ccd_yerly_txncnt <= 0 THEN
                         0  ELSE   ccd_yerly_txncnt - 1  END,
                         ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,
						 ccd_lifetime_txncnt = CASE WHEN ccd_lifetime_txncnt <= 0 THEN
                         0  ELSE   ccd_lifetime_txncnt - 1  END,
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END                         
                   WHERE ROWID =  ';   
                 
                 ELSE
                 
                    v_upd_query :=
                   ' UPDATE cms_cardsumry_dwmy
                     SET  ccd_yerly_txnamnt = CASE WHEN  ccd_yerly_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_yerly_txnamnt - '||V_TXN_AMT||' END,    
                         ccd_lifetime_txnamnt = CASE WHEN  ccd_lifetime_txnamnt <= '||V_TXN_AMT||' THEN
                         0  ELSE   ccd_lifetime_txnamnt - '||V_TXN_AMT||' END 	                               
                   WHERE ROWID =  ';                                  
                     
                 END IF;            
         END IF;
         
         IF v_upd_query IS NOT NULL
         THEN
            BEGIN
               v_upd_query1 := v_upd_query || v_rowid;

               EXECUTE IMMEDIATE v_upd_query1;

               v_upd_query1 := NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                        'Error while Updating In CMS_CARDSUMRY_DWMY in reversal txn. For pan code-- '
                     || prm_crdcomb_hash (i).pan_code
                     || ' -- '
                     || '----Group Hash Combination---'
                     || v_grplmt_hash
                     || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         END IF;
      END IF;
    END LOOP;
    -------------------------------
    --EN:- GroupLimit reversal Reset
    -------------------------------
    EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_code := '21';
         prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
   END;
 --EN Added on 03.04.2013 for MVHOST-298   
END;
/
show error