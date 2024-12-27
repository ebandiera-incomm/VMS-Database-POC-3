create or replace PACKAGE BODY   vmscms.GPP_ORDERS IS

  -- PL/SQL Package using FS Framework

  -- Author  : Ubaidur Rahman H
  -- Created : 29/04/2019
  -- Private type declarations

  -- Private constant declarations
  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata           fsfw.fserror_t;
  g_err_failure          fsfw.fserror_t;
  g_err_unknown          fsfw.fserror_t;
  g_err_mandatory        fsfw.fserror_t;
  g_err_invalid_data     fsfw.fserror_t;
  g_err_upd_token_status fsfw.fserror_t;

  -- Function and procedure implementations
  -- the init procedure is private and should always exist

   PROCEDURE get_order_status(p_order_id_in               IN  VARCHAR2,
                             p_fulfillment_orderid_in     IN  VARCHAR2,
                             p_serial_number_in           IN  VARCHAR2,
                             p_order_channel_in           IN  VARCHAR2,
                             p_order_id_out               OUT VARCHAR2,
                             p_isprintorder_out           OUT VARCHAR2,
                             p_order_status_out           OUT VARCHAR2,
                             p_shipping_method_out        OUT VARCHAR2,
                             c_cards_out                  OUT SYS_REFCURSOR,
                             p_status_out                 OUT VARCHAR2,
                             p_err_msg_out                OUT VARCHAR2
                            )  AS

    l_api_name                  VARCHAR2(50) := 'GET ORDER STATUS';
    l_order_id                  vmscms.vms_order_details.vod_order_id%TYPE;
    l_order_partner_id          vmscms.vms_order_details.vod_partner_id%TYPE;
    l_po_fulfillment_order_id   vmscms.vms_line_item_dtl.vli_po_fulfillment_order_id%TYPE;
    l_start_time                NUMBER;
    l_end_time                  NUMBER;
    l_timetaken                 NUMBER;
    exp_reject_record           EXCEPTION;

/***************************************************************************************
	    	 * Created By        : UBAIDUR RAHMAN H
         * Created Date      : 29-Apr-2019
         * Created Reason    : Modified for FSAPI-391 VMS-888 (FSAPI-B2B - Support for Print Order Status)
         * Reviewer          : SaravanaKumar A
         * Reviewed Date     : 29-Apr-2019
         * Build Number      : R15_B0004
	 
	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
***************************************************************************************/

   BEGIN
    l_start_time  :=  dbms_utility.get_time;
    p_err_msg_out := 'SUCCESS';

      IF  p_order_id_in IS NULL
      AND p_fulfillment_orderid_in IS NULL
      AND p_serial_number_in IS NULL
      THEN
           p_status_out := vmscms.gpp_const.c_mandatory_status;
           g_err_mandatory.raise(l_api_name,
                                ',0002,',
                                ' One of the orderId, fulfillmentOrderId or serialNumber is mandatory ');
           p_err_msg_out := g_err_mandatory.get_current_error;
           vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        'F',
                                                        p_err_msg_out,
                                                        vmscms.gpp_const.c_failure_res_id,
                                                        NULL,
                                                        l_timetaken);
          RETURN;
      END IF;

      IF  p_order_id_in IS NOT NULL AND p_order_channel_in IS NULL
      THEN
           p_status_out := vmscms.gpp_const.c_mandatory_status;
           g_err_mandatory.raise(l_api_name,
                                ',0002,',
                                ' Whenever lookup through orderId is requested, the orderChannel is mandatory ');
           p_err_msg_out := g_err_mandatory.get_current_error;
           vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        'F',
                                                        p_err_msg_out,
                                                        vmscms.gpp_const.c_failure_res_id,
                                                        NULL,
                                                        l_timetaken);
          RETURN;
      END IF;

      IF p_order_id_in IS NOT NULL
      THEN

           BEGIN
              SELECT vod_order_id,
                  vod_partner_id,
                  nvl(upper(vod_print_order),'FALSE'),
                  vod_order_status,
                  vod_shipping_method
              INTO p_order_id_out,
                  l_order_partner_id,
                  p_isprintorder_out,
                  p_order_status_out,
                  p_shipping_method_out
             FROM vmscms.vms_order_details,
                 vmscms.vms_partner_id_mast
            WHERE vod_order_id = p_order_id_in
            AND vod_partner_id = vpi_partner_id
            AND vpi_order_channel = p_order_channel_in;

           EXCEPTION
           WHEN no_data_found THEN
              p_status_out := vmscms.gpp_const.c_ora_error_status;
              p_err_msg_out := 'Order details not found for the order id and order channel';
              RAISE exp_reject_record;
           WHEN OTHERS THEN
              p_status_out := vmscms.gpp_const.c_ora_error_status;
              p_err_msg_out := 'Error while selecting order details based on order id and order channel ' || SQLERRM;
              RAISE exp_reject_record;
           END;

      ELSE

          IF  p_serial_number_in IS NOT NULL
          THEN

              BEGIN

                  SELECT vli_po_fulfillment_order_id
                  INTO l_po_fulfillment_order_id
                  FROM vmscms.vms_line_item_dtl
                  WHERE vli_serial_number = p_serial_number_in
                  AND vli_partner_id     <> 'Replace_Partner_ID';

              EXCEPTION
              WHEN no_data_found THEN
                  p_status_out := vmscms.gpp_const.c_ora_error_status;
                  p_err_msg_out := 'Serial number is not present';
                  RAISE exp_reject_record;
              WHEN OTHERS THEN
                  p_status_out := vmscms.gpp_const.c_ora_error_status;
                  p_err_msg_out := 'Error while selecting fulfillment order id for the given serial number ' || SQLERRM;
                  RAISE exp_reject_record;
              END;

              IF l_po_fulfillment_order_id IS NULL
              THEN
                  p_status_out  := vmscms.gpp_const.c_ora_error_status;
                  p_err_msg_out := 'Fullfillment order id is not present for the serial number';
                  RAISE exp_reject_record;
              END IF;

          ELSE
             l_po_fulfillment_order_id := p_fulfillment_orderid_in;
          END IF;

         BEGIN
             SELECT vod_order_id,
                  vod_partner_id,
                  nvl(upper(vod_print_order),'FALSE'),
                  vod_order_status,
                  vod_shipping_method
              INTO p_order_id_out,
                  l_order_partner_id,
                  p_isprintorder_out,
                  p_order_status_out,
                  p_shipping_method_out
              FROM (SELECT vod_order_id,
                        vod_partner_id,
                        vod_print_order,
                        vod_order_status,
                        vod_shipping_method
                    FROM vmscms.vms_line_item_dtl,
                      vmscms.vms_order_details
                    WHERE vod_order_id    = vli_order_id
                    AND vod_partner_id    = vli_partner_id
                    AND vli_po_fulfillment_order_id = l_po_fulfillment_order_id
                    ORDER BY vod_ins_date DESC)
              WHERE rownum = 1;

          EXCEPTION
          WHEN no_data_found THEN
              p_status_out := vmscms.gpp_const.c_ora_error_status;
              p_err_msg_out := 'Order details not found for the fulfillment order id';
              RAISE exp_reject_record;
          WHEN OTHERS THEN
              p_status_out := vmscms.gpp_const.c_ora_error_status;
              p_err_msg_out := 'Error while selecting order details based on the fulfillment order id ' || SQLERRM;
              RAISE exp_reject_record;
          END;

      END IF;

        -- Cards array
            OPEN c_cards_out FOR
              SELECT lineitem.vol_line_item_id lineItemId,
                  lineitem.vol_order_status lineitem_status,
                  lineitem_dtl.vli_serial_number serial_number,
                  (SELECT card_stat.ccs_stat_desc
                   FROM vmscms.cms_appl_pan pan,
                    vmscms.cms_card_stat card_stat
                   WHERE pan.cap_inst_code   = 1
                   AND pan.cap_serial_number = lineitem_dtl.vli_serial_number
                   AND pan.cap_card_stat     = card_stat.ccs_stat_code
                   AND pan.cap_pangen_date   =
                    (SELECT MAX(cap_pangen_date)
                     FROM vmscms.cms_appl_pan appl_pan
                     WHERE appl_pan.cap_acct_no = pan.cap_acct_no
                    )
                  ) card_status,
                  (
                  CASE
                    WHEN p_isprintorder_out = 'TRUE'
                    THEN to_char(lineitem_dtl.vli_po_shipping_datetime, 'yyyy-mm-dd hh24:mi:ss')
                    ELSE to_char(lineitem_dtl.vli_shipping_datetime, 'yyyy-mm-dd hh24:mi:ss')
                  END) shippingDateTime,
                  (
                  CASE
                    WHEN p_isprintorder_out = 'TRUE'
                    THEN lineitem_dtl.vli_po_tracking_no
                    ELSE lineitem_dtl.vli_tracking_no
                  END) trackingNumber
            FROM vmscms.vms_order_lineitem lineitem,
              vmscms.vms_line_item_dtl lineitem_dtl
            WHERE lineitem.vol_order_id   = lineitem_dtl.vli_order_id
            AND lineitem.vol_partner_id   = lineitem_dtl.vli_partner_id
            AND lineitem.vol_line_item_id = lineitem_dtl.vli_lineitem_id
            AND lineitem.vol_order_id     = p_order_id_out
            AND lineitem.vol_partner_id   = l_order_partner_id;

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  'C',
                                                  p_err_msg_out,
                                                  vmscms.gpp_const.c_success_res_id,
                                                  NULL,
                                                  l_timetaken);*/

   EXCEPTION
    WHEN exp_reject_record THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := p_err_msg_out;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_order_status;


  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata           := fsfw.fserror_t('E-NO-DATA',
                                             '$1 $2');
    g_err_unknown          := fsfw.fserror_t('E-UNKNOWN',
                                             'Unknown error: $1 $2',
                                             'NOTIFY');
    g_err_mandatory        := fsfw.fserror_t('E-MANDATORY',
                                             'Mandatory Field is NULL: $1 $2 $3',
                                             'NOTIFY');
    g_err_failure          := fsfw.fserror_t('E-FAILURE',
                                             'Procedure failed: $1 $2 $3');
    g_err_invalid_data     := fsfw.fserror_t('E-INVALID_DATA',
                                             '$1 $2 $3');
    g_err_upd_token_status := fsfw.fserror_t('E-UPDATE_TOKEN_FAILED',
                                             'UPDATE TOKEN FAILED : $1 $2 $3');
    -- load configuration elements
    g_config := fsfw.fsconfig.get_configuration($$PLSQL_UNIT);
    IF g_config.exists(fsfw.fsconst.c_debug)
    THEN
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                g_config(fsfw.fsconst.c_debug));
    ELSE
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                '');
    END IF;
  END init;

  -- the get_cpp_context function returns the value of the specific
  -- context value set in the application context for the GPP application
  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

BEGIN
  -- Initialization
  init;
END gpp_orders;
/
show error