CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_minmax (
   prm_hash_pan           IN       VARCHAR2,
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
   prm_err_code           OUT      VARCHAR2,
   prm_err_msg            OUT      VARCHAR2,
   prm_mr_flag                IN     VARCHAR2 default 'N'   --Added by Pankaj S. for MR INGO limit issue( MVHOST-1041 )
)
AS
   /**************************************************************************
     * Created Date         : 25_Oct_2013
     * Created By           : Pankaj S.
     * Purpose              : Per txn min max amount checks
     * Reviewer             :  Dhiraj
     * Reviewed Date        :
     * Release Number       : RI0024.3.9_B0002
     
     * Modified Date         : 25.03.2014
     * Modified By           : Sachin P.
     * Purpose               : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)         
     * Reviewer              : spankaj
     * Reviewed Date         : 07-April-2014
     * Release Number        : RI0027.2_B0004     
     
       * Modified by       : Spankaj
      * Modified for      : MVHOST-1041     
      * Modified Date     : 12-Nov-2014
      * Build Number      : RI0027.4.2.1
     
   /**************************************************************************/
   v_prfl_clp_pertxn_minamnt   cms_limit_prfl.clp_pertxn_minamnt%TYPE;
   v_prfl_clp_pertxn_maxamnt   cms_limit_prfl.clp_pertxn_maxamnt%TYPE;
   v_hash_combination          VARCHAR2 (90);
   v_tran_type                 cms_limit_prfl.clp_tran_type%TYPE;
   v_delivery_channel          cms_limit_prfl.clp_dlvr_chnl%TYPE;
   v_tran_code                 cms_limit_prfl.clp_tran_code%TYPE;
   v_intl_flag                 cms_limit_prfl.clp_intl_flag%TYPE;
   v_pnsign_flag               cms_limit_prfl.clp_pnsign_flag%TYPE;
   v_mcc_code                  cms_limit_prfl.clp_mcc_code%TYPE;
   v_trfr_crdacnt              cms_limit_prfl.clp_trfr_crdacnt%TYPE;
   v_grplmt_hash               CMS_GROUP_LIMIT.Cgl_GRPLMT_HASH%type; --Added on 25.03.2014 MVHOST_756 & MVCSD-4113
   v_grp_chk                   VARCHAR2(1); --Added on 25.03.2014 MVHOST_756 & MVCSD-4113
BEGIN
   prm_err_code := '1';
   prm_err_msg := 'OK';
   v_grp_chk  :='1';--Added on 25.03.2014 MVHOST_756 & MVCSD-4113

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
      v_tran_code := prm_tran_code;
   END IF;

   IF prm_tran_type IS NULL
   THEN
      v_tran_type := 'NA';
   ELSE
      v_tran_type := prm_tran_type;
   END IF;

   IF prm_intl_flag IS NULL
   THEN
      v_intl_flag := 'NA';
   ELSE
      v_intl_flag := prm_intl_flag;
   END IF;

   IF TRIM (prm_pnsign_flag) IS NULL
   THEN
      v_pnsign_flag := 'NA';
   ELSE
      v_pnsign_flag := prm_pnsign_flag;
   END IF;

   IF TRIM (prm_mcc_code) = '6010'
   THEN
      v_mcc_code := TRIM (prm_mcc_code);
   ELSE
      v_mcc_code := 'NA';
   END IF;
   

   BEGIN
      v_hash_combination :=
         gethash (   TRIM (prm_lmt_prfl)
                  || TRIM (v_delivery_channel)
                  || TRIM (v_tran_code)
                  || TRIM (v_tran_type)
                  || TRIM (v_intl_flag)
                  || TRIM (v_pnsign_flag)
                  || TRIM (v_mcc_code)
                  || TRIM (prm_trfr_crdacnt)
                 );
   --prm_crdcomb_hash (1).prfl_id := prm_lmt_prfl;

   --prm_crdcomb_hash (1).comb_hash := v_hash_combination;

   --prm_crdcomb_hash (1).pan_code := prm_hash_pan;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_code := '21';
         prm_err_msg := 'Error While Generating Hash Value ' || SQLERRM;
         RETURN;
   END;

   --FOR i IN 1 .. prm_crdcomb_hash.COUNT
   --LOOP
   BEGIN
      SELECT clp_pertxn_minamnt, clp_pertxn_maxamnt
        INTO v_prfl_clp_pertxn_minamnt, v_prfl_clp_pertxn_maxamnt
        FROM cms_limit_prfl
       WHERE clp_inst_code = prm_inst_code
         AND clp_lmtprfl_id = prm_lmt_prfl       --prm_crdcomb_hash(i).prfl_id
         AND clp_comb_hash = v_hash_combination;
                                             --prm_crdcomb_hash (i).comb_hash;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_code := '1';
         prm_err_msg := 'OK';
         --RETURN; --Commented and modified on 25.03.2014 MVHOST_756 & MVCSD-4113      
         v_grp_chk:= '2';
      WHEN OTHERS
      THEN
         prm_err_code := '21';
         prm_err_msg :=
                 'Error while selecting Limit Profile Parameters ' || SQLERRM;
         RETURN;
   END;
   
   IF v_grp_chk <> '2' THEN--Condition Added on 25.03.2014 MVHOST_756 & MVCSD-4113
      IF prm_mr_flag='N' then  --Added by Pankaj S. for MR INGO limit issue( MVHOST-1041 )
       IF prm_txn_amt < v_prfl_clp_pertxn_minamnt
       THEN
          prm_err_code := '79';
          prm_err_msg := 'Transaction Amount is Less Than Minimum Per Txn Amount';
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
   END IF ;
   
   --SN Added on 25.03.2014 MVHOST_756 & MVCSD-4113
    BEGIN   
    SELECT gethash (cgp_group_code || cgp_limit_prfl)
          INTO v_grplmt_hash
          FROM cms_grplmt_param
         WHERE cgp_inst_code = prm_inst_code
           AND cgp_grpcomb_hash = v_hash_combination;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           prm_err_code := '1';
           prm_err_msg := 'OK';
           RETURN;
        WHEN OTHERS THEN
           prm_err_code := '21';
           prm_err_msg := 'Error while Group and Limit Relation ' ||  SUBSTR (SQLERRM, 1, 300);
           RETURN;
    END;

     BEGIN
        SELECT cgl_pertxn_minamnt, cgl_pertxn_maxamnt
          INTO v_prfl_clp_pertxn_minamnt, v_prfl_clp_pertxn_maxamnt
          FROM cms_group_limit
         WHERE cgl_inst_code = prm_inst_code
           AND cgl_grplmt_hash = v_grplmt_hash;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           prm_err_code := '1';
           prm_err_msg := 'OK';
           RETURN;
        WHEN OTHERS THEN
           prm_err_code := '21';
           prm_err_msg :='Error while selecting Group Limit Profile Parameters '|| SUBSTR (SQLERRM, 1, 300);
           RETURN;
     END;
     
      IF v_grp_chk = '2' THEN
           IF prm_mr_flag='N' then  --Added by Pankaj S. for MR INGO limit issue( MVHOST-1041 )
           IF prm_txn_amt < v_prfl_clp_pertxn_minamnt
           THEN
              prm_err_code := '79';
              prm_err_msg := 'Transaction Amount is Less Than Minimum Per Txn Amount';
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
      END IF ;
   
   --eN Added on 25.03.2014 MVHOST_756 & MVCSD-4113
   
EXCEPTION
   WHEN OTHERS
   THEN
      prm_err_code := '21';
      prm_err_msg :=
              'Error while Min-Max Limit Checks ' || SUBSTR (SQLERRM, 1, 300);
      RETURN;
END; 
/
show error;
