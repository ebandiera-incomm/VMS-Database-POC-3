create or replace PROCEDURE        VMSCMS.SP_TRANSFER_PROXY_CNT (
   prm_inst_code                 NUMBER,
   prm_from_proxy_no    IN       VARCHAR2,
   prm_to_proxy_no      IN       VARCHAR2,
   prm_mer_id           IN       NUMBER,
   prm_locn_id          IN       VARCHAR2,
   prm_merprodcat_id    IN       NUMBER,
   prm_valid_cnt        OUT      NUMBER,
   prm_errmsg           OUT      VARCHAR2,
   prm_from_card_no     OUT      VARCHAR2,
   prm_to_card_no       OUT      VARCHAR2
)
AS
   /*************************************************
       * Created Date     : 23-05-2014
       * Created By       : MageshKumar S
       * PURPOSE          : MVHOST-898
       * Reviewer         : Spankaj
       * Build  No.       : RI0027.3_B0001
   *************************************************/
   v_from_prod_code   cms_appl_pan.cap_prod_code%TYPE;
   v_to_prod_code     cms_appl_pan.cap_prod_code%TYPE;
   v_hash_from_pan    cms_appl_pan.cap_pan_code%TYPE;
   v_hash_to_pan      cms_appl_pan.cap_pan_code%TYPE;
   excp_raise         EXCEPTION;
   v_cnt              NUMBER (10)                       := 0;
   v_cnt1             NUMBER (10)                       := 0;
   v_cnt2             NUMBER (10)                       := 0;
BEGIN
   prm_errmsg := 'OK';
   prm_valid_cnt := 0;
   
   BEGIN
   
    select fn_dmaps_main(cap_pan_code_encr) ,cap_pan_code, cap_prod_code
    into prm_from_card_no ,v_hash_from_pan, v_from_prod_code
    from cms_appl_pan 
    where cap_proxy_number = prm_from_proxy_no 
    and cap_inst_code = prm_inst_code
    and cap_startercard_flag='Y';
    
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'From Proxy No not found in pan master ';
         RAISE excp_raise;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting from proxy no'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   
   END;

  /* BEGIN
      v_hash_from_pan := gethash (prm_from_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while converting pan (hash) for from card no '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   END;

   BEGIN
      SELECT cap_prod_code
        INTO v_from_prod_code
        FROM cms_appl_pan
       WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_from_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'From Card No. not found in pan master ';
         RAISE excp_raise;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting product code for from card no'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   END;*/
   
   BEGIN
   
    select fn_dmaps_main(cap_pan_code_encr) ,cap_pan_code, cap_prod_code
    into prm_to_card_no ,v_hash_to_pan, v_to_prod_code
    from cms_appl_pan 
    where cap_proxy_number = prm_to_proxy_no 
    and cap_inst_code = prm_inst_code
    and cap_startercard_flag='Y';
    
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'To Proxy No not found in pan master ';
         RAISE excp_raise;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting to proxy no'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   
   END;

  /* BEGIN
      v_hash_to_pan := gethash (prm_to_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while converting pan (hash) for to card no '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   END;

   BEGIN
      SELECT cap_prod_code
        INTO v_to_prod_code
        FROM cms_appl_pan
       WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_to_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'To Card No. not found in pan master ';
         RAISE excp_raise;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting product code for to card no'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   END;*/

   IF v_from_prod_code <> v_to_prod_code
   THEN
      prm_errmsg :=
                   'From card no and To card no belongs to different product';
      RAISE excp_raise;
   END IF;

   BEGIN
    /*  SELECT COUNT (*)
        INTO prm_valid_cnt
        FROM cms_merinv_merpan a
       WHERE SUBSTR (fn_dmaps_main (cmm_pancode_encr),
                     1,
                     LENGTH (fn_dmaps_main (cmm_pancode_encr)) - 1
                    ) BETWEEN SUBSTR (prm_from_card_no,
                                      1,
                                      LENGTH (prm_from_card_no) - 1
                                     )
                          AND SUBSTR ((prm_to_card_no),
                                      1,
                                      LENGTH (prm_to_card_no) - 1
                                     )
         AND TRUNC (cmm_expiry_date) > TRUNC (SYSDATE)
         AND cmm_activation_flag = 'M'
         AND cmm_mer_id = prm_mer_id
         AND cmm_location_id = prm_locn_id;*/
         
         SELECT COUNT (*)
        INTO prm_valid_cnt
        FROM cms_merinv_merpan a, cms_appl_pan b
       WHERE  a.cmm_pan_code = b.cap_pan_code
         and a.CMM_INST_CODE = b.CAP_INST_CODE
         and to_number(b.cap_proxy_number) between  to_number(prm_from_proxy_no) and to_number(prm_to_proxy_no)
         AND TRUNC (cmm_expiry_date) > TRUNC (SYSDATE)
         AND cmm_activation_flag = 'M'
         AND cmm_mer_id = prm_mer_id
         AND cmm_location_id = prm_locn_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting product code for from card no'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_raise;
   END;

   IF prm_valid_cnt > 0
   THEN
      BEGIN
         SELECT COUNT (*)
           INTO v_cnt
           FROM cms_merinv_transfer
          WHERE cmt_inst_code = prm_inst_code
            and CMT_MERPRODCAT_ID = PRM_MERPRODCAT_ID
           -- AND cmt_authorize_flag IN 'O'
           AND cmt_authorize_flag not in ('R','A')
            AND cmt_from_location = prm_locn_id
            AND ( (prm_from_card_no BETWEEN cmt_from_cardno AND cmt_to_cardno) or 
            (prm_from_proxy_no between CMT_FROM_PROXYNO and CMT_TO_PROXYNO) );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while validating card ranges1'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;
      BEGIN
         SELECT COUNT (*)
           INTO v_cnt1
           from CMS_MERINV_TRANSFER
          where CMT_INST_CODE = PRM_INST_CODE
            and CMT_MERPRODCAT_ID = PRM_MERPRODCAT_ID
          --  and CMT_AUTHORIZE_FLAG = 'O' 
            AND cmt_authorize_flag not in ('R','A')
            AND cmt_from_location = prm_locn_id
            AND (prm_to_card_no BETWEEN cmt_from_cardno AND cmt_to_cardno or 
             prm_to_proxy_no between CMT_FROM_PROXYNO and CMT_TO_PROXYNO);
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while validating card ranges2'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;
      BEGIN
             SELECT COUNT (*)
           INTO v_cnt2
           from CMS_MERINV_TRANSFER
          where CMT_INST_CODE = PRM_INST_CODE
            and CMT_MERPRODCAT_ID = PRM_MERPRODCAT_ID
          --  and CMT_AUTHORIZE_FLAG = 'O' 
            AND cmt_authorize_flag not in ('R','A')
            AND cmt_from_location = prm_locn_id
            AND (cmt_from_cardno BETWEEN prm_from_card_no AND prm_to_card_no or 
             to_number(CMT_FROM_PROXYNO) between to_number(prm_from_proxy_no) and to_number(prm_to_proxy_no));
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while validating card ranges3'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;
         IF v_cnt > 0 AND v_cnt1 > 0 and v_cnt2 > 0
         then
            prm_errmsg := 'From And To Proxy Number Is Not Valid ';
            PRM_VALID_CNT := 0;
         elsif V_CNT > 0
         then
            PRM_ERRMSG := 'From Proxy Number Is Not Valid ';
            PRM_VALID_CNT := 0;
         elsif V_CNT1 > 0
         THEN
            PRM_ERRMSG := 'To Proxy Number Is Not Valid ';
            prm_valid_cnt := 0;
          elsif V_CNT2 > 0
         THEN
            PRM_ERRMSG := 'From And To Proxy Number Is Not Valid ';
            prm_valid_cnt := 0;
         END IF;
         
   /*   EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while validating card ranges'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;*/
   END IF;
EXCEPTION
   WHEN excp_raise
   THEN
      prm_errmsg := prm_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg :=
            'Error While getting the valid transfer card count '
         || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR