CREATE OR REPLACE PACKAGE BODY VMSCMS.vmsredemptiondelay
IS
   -- Function and procedure implementations
   FUNCTION check_overlaps (p_existing_time_in    VARCHAR2,
                            p_new_time_in         VARCHAR2)
      RETURN VARCHAR2
   AS
      l_start_time   VARCHAR2 (10);
      l_end_time     VARCHAR2 (10);
      l_resp_msg     VARCHAR2 (100) := 'OK';
   BEGIN
      l_start_time := SUBSTR (p_new_time_in, 1, 6);
      l_end_time := SUBSTR (p_new_time_in, 8);

      FOR l_idx
         IN (SELECT SUBSTR (period, 1, 6) start_period, SUBSTR (period, 8) end_period
               FROM (    SELECT REGEXP_SUBSTR (p_existing_time_in, '[^|]+', 1, LEVEL) period
                           FROM DUAL
                     CONNECT BY REGEXP_SUBSTR (p_existing_time_in, '[^|]+', 1, LEVEL) IS NOT NULL))
      LOOP
         IF ( (l_start_time >= l_idx.start_period
               AND l_start_time <= l_idx.end_period)
             OR (l_end_time >= l_idx.start_period
                 AND l_end_time <= l_idx.end_period)
             OR (l_start_time <= l_idx.start_period
                 AND l_end_time >= l_idx.end_period))
         THEN
            l_resp_msg := 'THERE IS OVERLAP';
            EXIT;
         END IF;
      END LOOP;

      RETURN l_resp_msg;
   END check_overlaps;

   PROCEDURE redemption_delay (
      p_acct_no_in                VARCHAR2,
      p_rrn_in                    VARCHAR2,
      p_delivery_channel_in       VARCHAR2,
      p_txn_code_in               VARCHAR2,
      p_txn_amt_in                NUMBER,
      p_prod_code_in              VARCHAR2,
      p_card_typ_in               NUMBER,
      p_merchant_in            VARCHAR2,
      p_merchantZipCode_in      VARCHAR2 ,--added for VMS-622 (redemption_delay zip code validation)
      p_process_msg_out       OUT VARCHAR2,
      p_revsl_flag_in             VARCHAR2 DEFAULT 'N',
      P_MERCHANT_ID_IN            VARCHAR2 default null
      )
   AS
   
/*************************************************
	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11

     * Modified By      : John G
     * Modified Date    : 20-OCT-2022
     * Purpose          : VMS-6499 Ph2: Enhance Redemption Delays by MID
     * Reviewer         : Pankaj S
     * Release Number   : VMSGPRHOST R71
*************************************************/   

      l_redmption_delay   vms_redemption_delay_config.vrd_redemption_delay_time%TYPE;
      l_inst_code                cms_acct_mast.cam_inst_code%TYPE := 1;
      l_merchant_zip vms_redemption_delay_config.VRD_ZIP_CODE%TYPE;
      l_mid_flag  number := 0;

BEGIN
  p_process_msg_out      := 'OK';
  
  IF p_revsl_flag_in      = 'N' THEN
  
  --Zip Code validation check for VMS-622
  
    IF p_merchantZipCode_in IS NOT NULL THEN
      l_merchant_zip     :=REPLACE(p_merchantZipCode_in,' ','');
   
      if regexp_like(l_merchant_zip, '^[^a-zA-Z]*$') then
      l_merchant_zip :=substr(REPLACE(l_merchant_zip,'-',''),0,5);
      else 
      l_merchant_zip :=substr(REPLACE(l_merchant_zip,'-',''),0,6);
      end if;
  
    END IF;
---end zip code validation check for vms-622
--    BEGIN
--           SELECT a.vrd_redemption_delay_time
--              INTO l_redmption_delay
--              FROM vms_redemption_delay_config a, vms_merchant_mast b
--             WHERE     a.vrd_prod_code = p_prod_code_in
--                   AND a.vrd_prodcat_code = p_card_typ_in
--                   AND a.vrd_merchant_id = b.vmm_merchant_id
--                   AND UPPER (b.vmm_merchant_name) = p_merchant_in
--                   AND a.vrd_start_time_display <= TO_CHAR (SYSDATE, 'hh24miss')
--                   AND a.vrd_end_time_display >= TO_CHAR (SYSDATE, 'hh24miss')
--                   AND ROWNUM = 1;
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               RETURN;
--            WHEN OTHERS
--            THEN
--               p_process_msg_out :=
--                  'Error while selecting redemption delay:'
--                  || SUBSTR (SQLERRM, 1, 200);
--               RETURN;
--         END;


--added for VMS-6499 (redemption_delay for merchant_id)
IF p_merchant_id_in is not null then
    BEGIN
      SELECT a.vrd_redemption_delay_time
      INTO l_redmption_delay
      FROM vms_redemption_delay_config a,
        vms_merchant_mast b
      WHERE a.vrd_prod_code             = p_prod_code_in
      AND a.vrd_prodcat_code            = p_card_typ_in
      AND a.vrd_merchant_id         = b.vmm_merchant_id
      AND UPPER (b.vmm_merchant_id) = p_merchant_id_in
      AND UPPER( a.vrd_zip_code )   = UPPER(l_merchant_zip)
      AND a.vrd_start_time_display     <= TO_CHAR (SYSDATE, 'hh24miss')
      AND a.vrd_end_time_display       >= TO_CHAR (SYSDATE, 'hh24miss')
      AND ROWNUM                        = 1;
     l_mid_flag:=1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    BEGIN
      SELECT a.vrd_redemption_delay_time
      INTO l_redmption_delay
      FROM vms_redemption_delay_config a,
        vms_merchant_mast b
      WHERE a.vrd_prod_code             = p_prod_code_in
      AND a.vrd_prodcat_code            = p_card_typ_in
      AND a.vrd_merchant_id         = b.vmm_merchant_id
      AND UPPER (b.vmm_merchant_id) = p_merchant_id_in
      AND UPPER( a.vrd_zip_code )   is null
      AND a.vrd_start_time_display     <= TO_CHAR (SYSDATE, 'hh24miss')
      AND a.vrd_end_time_display       >= TO_CHAR (SYSDATE, 'hh24miss')
      AND ROWNUM                        = 1;
      l_mid_flag:=1;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
        NULL;
END;
END;
END IF;

IF l_mid_flag = 0 THEN
--added for VMS-622 (redemption_delay for both zip code and merchant)

begin
      SELECT a.vrd_redemption_delay_time
      INTO l_redmption_delay
      FROM vms_redemption_delay_config a,
        vms_merchant_mast b
      WHERE a.vrd_prod_code             = p_prod_code_in
      AND a.vrd_prodcat_code            = p_card_typ_in
      AND a.vrd_merchant_id         = b.vmm_merchant_id
      AND UPPER (b.vmm_merchant_name) = p_merchant_in
      AND UPPER( a.vrd_zip_code )   = UPPER(l_merchant_zip)
      AND a.vrd_start_time_display     <= TO_CHAR (SYSDATE, 'hh24miss')
      AND a.vrd_end_time_display       >= TO_CHAR (SYSDATE, 'hh24miss')
      AND ROWNUM                        = 1;
     
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
	--added for VMS-622 (redemption_delay for only merchant)
      BEGIN
        SELECT a.vrd_redemption_delay_time
        INTO l_redmption_delay
        FROM vms_redemption_delay_config a,
          vms_merchant_mast b
        WHERE a.vrd_prod_code         = p_prod_code_in
        AND a.vrd_prodcat_code        = p_card_typ_in
        AND a.vrd_merchant_id         = b.vmm_merchant_id
        and (UPPER (b.vmm_merchant_name) = p_merchant_in
        and a.vrd_zip_code is null)
        AND a.vrd_start_time_display <= TO_CHAR (SYSDATE, 'hh24miss')
        AND a.vrd_end_time_display   >= TO_CHAR (SYSDATE, 'hh24miss')
        AND ROWNUM                    = 1;
         
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
	  --added for VMS-622 (redemption_delay for only zip code)
        BEGIN
          SELECT a.vrd_redemption_delay_time
          INTO l_redmption_delay
          FROM vms_redemption_delay_config a,
            vms_merchant_mast b
          WHERE a.vrd_prod_code         = p_prod_code_in
          AND a.vrd_prodcat_code        = p_card_typ_in
          AND (UPPER( a.vrd_zip_code )   = UPPER(l_merchant_zip) and   a.vrd_merchant_id  is null)
          AND a.vrd_start_time_display <= TO_CHAR (SYSDATE, 'hh24miss')
          AND a.vrd_end_time_display   >= TO_CHAR (SYSDATE, 'hh24miss')
          AND ROWNUM                    = 1;
             
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN;
        END;
      WHEN OTHERS THEN
        p_process_msg_out := 'Error while selecting redemption delay:' || SUBSTR (SQLERRM, 1, 200);
        RETURN;
      END;
    WHEN OTHERS THEN
      p_process_msg_out := 'Error while selecting redemption delay:' || SUBSTR (SQLERRM, 1, 200);
      RETURN;
    END;
    END IF;
    BEGIN

      INSERT
      INTO vms_delayed_load
        (
          vdl_acct_no,
          vdl_delivery_channel,
          vdl_txn_code,
          vdl_rrn,
          vdl_tran_amt,
          vdl_expiry_date,
          vdl_ins_date
        )
        VALUES
        (
          p_acct_no_in,
          p_delivery_channel_in,
          p_txn_code_in,
          p_rrn_in,
          p_txn_amt_in,
          SYSDATE + l_redmption_delay / 1440,
          SYSDATE);
    EXCEPTION
    WHEN OTHERS THEN
      p_process_msg_out := 'Error while inserting into vms_delayed_load:' || SUBSTR (SQLERRM, 1, 200);

      RETURN;
    END;
    BEGIN

      UPDATE cms_acct_mast
      SET cam_redemption_delay_flag          ='Y'
      WHERE cam_inst_code                    = l_inst_code
      AND cam_acct_no                        = p_acct_no_in
      AND NVL(cam_redemption_delay_flag,'N') = 'N';
    EXCEPTION
    WHEN OTHERS THEN
      p_process_msg_out :='Error while updating cms_acct_mast:' || SUBSTR (SQLERRM, 1, 200);
    END;
  ELSE
    BEGIN

      UPDATE vms_delayed_load
      SET vdl_expiry_date      = SYSDATE
      WHERE vdl_acct_no        = p_acct_no_in
      AND vdl_rrn              = p_rrn_in
      AND vdl_delivery_channel = p_delivery_channel_in
      AND vdl_txn_code         = p_txn_code_in
      AND vdl_tran_amt         = p_txn_amt_in
      AND vdl_expiry_date      > SYSDATE;
    EXCEPTION
    WHEN OTHERS THEN
      p_process_msg_out := 'Error while updating vms_delayed_load:' || SUBSTR (SQLERRM, 1, 200);
    END;
    END IF;
END redemption_delay;

    PROCEDURE check_delayed_load (p_acct_no_in            VARCHAR2,
                                p_delayed_amt_out   OUT NUMBER,
                                p_process_msg_out   OUT VARCHAR2)
    AS
       l_inst_code   cms_acct_mast.cam_inst_code%TYPE := 1;
    BEGIN
       p_process_msg_out := 'OK';

       BEGIN
          SELECT NVL (SUM (vdl_tran_amt), 0)
            INTO p_delayed_amt_out
            FROM vms_delayed_load
           WHERE vdl_acct_no = p_acct_no_in AND vdl_expiry_date > SYSDATE;
       EXCEPTION
          WHEN OTHERS
          THEN
             p_process_msg_out :=
                'Error while getting delayed load amount:'
                || SUBSTR (SQLERRM, 1, 200);
            RETURN;    
       END;

       IF p_delayed_amt_out = 0
       THEN
          BEGIN
             UPDATE cms_acct_mast
                SET cam_redemption_delay_flag = 'N'
              WHERE     cam_inst_code = l_inst_code
                    AND cam_acct_no = p_acct_no_in
                    AND cam_redemption_delay_flag = 'Y';
          EXCEPTION
             WHEN OTHERS
             THEN
                p_process_msg_out :=
                   'Error while updating cms_acct_mast:'
                   || SUBSTR (SQLERRM, 1, 200);
          END;
       END IF;
    END check_delayed_load;                    
BEGIN
   NULL;
END vmsredemptiondelay;
/
show error