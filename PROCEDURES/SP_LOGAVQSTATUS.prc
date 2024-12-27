create or replace
PROCEDURE               vmscms.SP_LOGAVQSTATUS(
P_INSTCODE   IN       NUMBER,
P_DELIVERY_CHANNEL   IN       VARCHAR2,
p_card_no            IN       VARCHAR2,
P_PROD_CODE          IN       VARCHAR2,
P_CUST_CODE          IN       VARCHAR2,
P_RESPCODE           OUT       VARCHAR2,
P_ERRMSG             OUT       VARCHAR2,
p_card_type          in        number
) as
 /**********************************************************************************************
      * Created Date     :  12-Dec-2014
      * Created By       :  Ramesh A
      * PURPOSE          :  FSS-1961(Melissa)
      * Reviewer         : 	Spankaj
      * Build Number     : RI0027.5_B0002

      * Modified Date    :  30-Dec-2014
      * Modified By      :  Ramesh A
      * PURPOSE          :  Defect id :0015974
      * Reviewer         :  Spankaj
      * Build Number     :  RI0027.5_B0003

      * Modified Date    :  14-JAN-2016
      * Modified By      :  Ramesh A
      * PURPOSE          :  AVQ Issue
      * Reviewer         :  Spankaj
      * Build Number     :  3.2.2.2 Release
      
      * Modified Date    :  18-MAY-2016
      * Modified By      :  MageshKumar S
      * PURPOSE          :  FSS-4322(AVQ Issue)
      * Reviewer         :  Saravanan/Spankaj
      * Build Number     :  VMSGPRHOSTCSD_4.1_B0001
	  
	  * Modified Date    :  16-JAN-2018
      * Modified By      :  Divya Bhaskaran
      * PURPOSE          :  Consolidated FSAPI Changes
      * Reviewer         :  Saravanan
      * Build Number     :  VMSGPRHOST_18.01
	  
	  * Modified by      :  Vini
      * Modified Date    :  18-Jan-2018
      * Modified For     :  VMS-162
      * Reviewer         :  Saravanankumar
      * Build Number     :  VMSGPRHOSTCSD_18.01

	  * Modified by      :  Vini Pushkaran
      * Modified Date    :  02-Feb-2018
      * Modified For     :  VMS-162
      * Reviewer         :  Saravanankumar
      * Build Number     :  VMSGPRHOSTCSD_18.01
        
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18      
	 
	* Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 13-May-2021
    * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0003
	  **********************************************************************************************/
v_hash_pan    cms_appl_pan.cap_pan_code%TYPE;
v_encr_pan    cms_appl_pan.cap_pan_code_encr%TYPE;

V_CUST_ID  CMS_CUST_MAST.CCM_CUST_ID%TYPE;
 
V_FULL_NAME  CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
V_MAILADDR_LINEONE CMS_ADDR_MAST.CAM_ADD_ONE%TYPE;
V_MAILADDR_LINETWO CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;
V_MAILADDR_CITY    CMS_ADDR_MAST.CAM_CITY_NAME%TYPE;
V_MAILADDR_ZIP 	   CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;
 
V_AVQ_FLAG VMS_SCORECARD_PRODCAT_MAPPING.VSP_AVQ_FLAG%TYPE;
v_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE ;
V_DELIVERY_CHANNEL   VMS_SCORECARD_PRODCAT_MAPPING.VSP_DELIVERY_CHANNEL%TYPE;
V_PHONE_NO 		   CMS_ADDR_MAST.CAM_PHONE_ONE%TYPE;
V_OTHER_NO 		   CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;
V_EMAIL 		   CMS_ADDR_MAST.CAM_EMAIL%TYPE;
V_CNTRY_CODE VARCHAR2(2);
V_STATE VARCHAR2(2);
V_ENCRYPT_ENABLE 		CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
v_encr_full_name        cms_avq_status.cas_cust_name%type;       

EXP_REJECT_RECORD EXCEPTION;

BEGIN
P_RESPCODE := '1';
P_ERRMSG :='OK';  --Modified for defect id :0015974

-- Modified for VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 

if P_DELIVERY_CHANNEL in ('05','10','11','07','17') then --Modified for defect id :0015974 
  V_DELIVERY_CHANNEL := '06';--card issuance cms_delchannel_mast
else
  V_DELIVERY_CHANNEL :=P_DELIVERY_CHANNEL;
end if;

      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            P_RESPCODE := '21';
            P_ERRMSG :='Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;

       BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            P_RESPCODE := '21';
            P_ERRMSG :='Error while converting encr pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;

      BEGIN

         SELECT CPC_ENCRYPT_ENABLE INTO V_ENCRYPT_ENABLE
           FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE = P_PROD_CODE
            AND CPC_CARD_TYPE = P_CARD_TYPE
            AND CPC_INST_CODE = P_INSTCODE;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESPCODE := '21';
             P_ERRMSG := 'Product Category not defined for product code ' ||P_PROD_CODE;
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              P_RESPCODE := '21';
             P_ERRMSG := 'Error while selecting Product Category ' ||
                       SUBSTR(SQLERRM, 1, 300);
             RAISE EXP_REJECT_RECORD;
        END;
	  
	  
	  BEGIN

         SELECT  VSP_AVQ_FLAG INTO V_AVQ_FLAG
         FROM VMS_SCORECARD_PRODCAT_MAPPING
         where vsp_prod_code=P_PROD_CODE
         and vsp_card_type=p_card_type
         AND VSP_INST_CODE = P_INSTCODE
         AND VSP_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESPCODE := '21';
             P_ERRMSG := 'AVQ flag not defined for product code ' ||P_PROD_CODE;
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              P_RESPCODE := '21';
             P_ERRMSG := 'Error while selecting AVQ flag from scorecard Mapping table' ||
                       SUBSTR(SQLERRM, 1, 300);
             RAISE EXP_REJECT_RECORD;
        END;

      IF V_AVQ_FLAG = 'Y' THEN

          BEGIN

              SELECT cust.ccm_cust_id,
			         decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)||' '||
			         decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
                        --cam_add_one,cam_add_two,cam_city_name,cam_state_switch,cam_pin_code
				     addr.cam_add_one,addr.cam_add_two,addr.cam_city_name,
					 (select state_mast.gsm_switch_state_code from gen_state_mast state_mast where 
               state_mast.gsm_cntry_code = addr.CAM_CNTRY_CODE and state_mast.GSM_STATE_CODE=addr.cam_state_code),
               addr.cam_pin_code
               INTO V_CUST_ID,V_FULL_NAME,V_MAILADDR_LINEONE,V_MAILADDR_LINETWO,
               V_MAILADDR_CITY,v_mailing_switch_state_code,V_MAILADDR_ZIP
               FROM CMS_CUST_MAST CUST,cms_addr_mast ADDR
               WHERE addr.cam_inst_code = cust.ccm_inst_code
               AND addr.cam_cust_code = cust.ccm_cust_code
               AND cust.CCM_INST_CODE = P_INSTCODE
               AND cust.CCM_CUST_CODE = P_CUST_CODE
               and addr.cam_addr_flag='O';

           EXCEPTION
             WHEN NO_DATA_FOUND THEN

              BEGIN

                 SELECT cust.ccm_cust_id,
				        decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)||' '||
			            decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
                          --cam_add_one,cam_add_two,cam_city_name,cam_state_switch,cam_pin_code,cam_phone_one,cam_mobl_one,cam_email,cam_cntry_code,cam_state_code
                        addr.cam_add_one,addr.cam_add_two,addr.cam_city_name,
                 (select state_mast.gsm_switch_state_code from gen_state_mast state_mast where 
                 state_mast.gsm_cntry_code = addr.CAM_CNTRY_CODE and state_mast.GSM_STATE_CODE=addr.cam_state_code),--Modified for FSS-4322(AVQ Issue)
				 addr.cam_pin_code,addr.cam_phone_one,addr.cam_mobl_one,addr.cam_email,
				 addr.cam_cntry_code,addr.cam_state_code
                 INTO V_CUST_ID,V_FULL_NAME,V_MAILADDR_LINEONE,V_MAILADDR_LINETWO,
                 V_MAILADDR_CITY,v_mailing_switch_state_code,V_MAILADDR_ZIP,V_PHONE_NO,V_OTHER_NO,V_EMAIL,V_CNTRY_CODE,V_STATE
                 FROM CMS_CUST_MAST CUST,cms_addr_mast ADDR
                 WHERE addr.cam_inst_code = cust.ccm_inst_code
                 AND addr.cam_cust_code = cust.ccm_cust_code
                 AND cust.CCM_INST_CODE = P_INSTCODE
                 AND cust.CCM_CUST_CODE = P_CUST_CODE
                 and addr.cam_addr_flag='P';

				   INSERT INTO cms_addr_mast
                             (cam_inst_code,
                              cam_cust_code,
                              cam_addr_code,
                              cam_add_one,
                              cam_add_two,
                              cam_phone_one,
                              cam_mobl_one,
                              cam_email,
                              cam_pin_code,
                              cam_cntry_code,
                              cam_city_name,
                              cam_addr_flag,
                              cam_state_code,
                              cam_state_switch,
                              cam_ins_user,
                              cam_ins_date,
                              cam_lupd_user,
                              cam_lupd_date,
                              CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,
                              CAM_CITY_NAME_ENCR, 
                              CAM_PIN_CODE_ENCR ,
                              CAM_EMAIL_ENCR
                             )
                      VALUES (P_INSTCODE,
                              P_CUST_CODE,
                              seq_addr_code.NEXTVAL,
                              V_MAILADDR_LINEONE,
                              V_MAILADDR_LINETWO,
                              V_PHONE_NO,
                              V_OTHER_NO,
                              V_EMAIL,
                              V_MAILADDR_ZIP,
                              V_CNTRY_CODE,
                              V_MAILADDR_CITY,
                              'O',
                              V_STATE,
                              v_mailing_switch_state_code,
                              1,
                              SYSDATE,
                              1,
                              SYSDATE,                              
                              decode(V_ENCRYPT_ENABLE,'Y',V_MAILADDR_LINEONE,fn_emaps_main(V_MAILADDR_LINEONE)),
                              decode(V_ENCRYPT_ENABLE,'Y',V_MAILADDR_LINETWO,fn_emaps_main(V_MAILADDR_LINETWO)), 
                              decode(V_ENCRYPT_ENABLE,'Y',V_MAILADDR_CITY,fn_emaps_main(V_MAILADDR_CITY)),   
                              decode(V_ENCRYPT_ENABLE,'Y',V_MAILADDR_ZIP,fn_emaps_main(V_MAILADDR_ZIP)),  
                              decode(V_ENCRYPT_ENABLE,'Y',V_EMAIL,fn_emaps_main(V_EMAIL))   
                             );

               EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   P_RESPCODE := '21';
                   P_ERRMSG := 'Physical Addess Not Found';
                   RAISE EXP_REJECT_RECORD;
                 WHEN OTHERS THEN
                   P_RESPCODE := '21';
                   P_ERRMSG := 'Error while selecting physical address ' || SUBSTR (SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
              END;
             WHEN EXP_REJECT_RECORD THEN
             RAISE;
             WHEN OTHERS THEN
             P_RESPCODE := '21';
             P_ERRMSG := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;

        BEGIN

            UPDATE CMS_CARDISSUANCE_STATUS SET CCS_CARD_STATUS=17 , CCS_LUPD_USER =1 , CCS_LUPD_DATE=SYSDATE
            WHERE CCS_INST_CODE=P_INSTCODE AND CCS_PAN_CODE=v_hash_pan;

              IF SQL%ROWCOUNT =0 THEN
                 P_RESPCODE := '21';
                 P_ERRMSG := 'Not updated Card issu Status';
                RAISE EXP_REJECT_RECORD;
              END IF;

            EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
              RAISE;
             WHEN OTHERS THEN
               P_RESPCODE := '21';
               P_ERRMSG := 'Error while updating Card issu Status ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
        
         IF  V_ENCRYPT_ENABLE = 'Y' then
             v_encr_full_name:=fn_emaps_main(V_FULL_NAME);
         else
             v_encr_full_name:=V_FULL_NAME;
         END IF;  
        
                INSERT INTO CMS_AVQ_STATUS
                (CAS_INST_CODE,
                 CAS_AVQSTAT_ID,
                 CAS_CUST_ID,
                 CAS_PAN_CODE,
                 CAS_PAN_ENCR,
                 CAS_CUST_NAME,
                 CAS_ADDR_ONE,
                 CAS_ADDR_TWO,
                 CAS_CITY_NAME,
                 CAS_STATE_NAME,
                 CAS_POSTAL_CODE,
                 CAS_AVQ_FLAG,
                 CAS_INS_USER,
                 CAS_INS_DATE)
                VALUES
                (P_INSTCODE,
                 AVQ_SEQ.NEXTVAL,
                 V_CUST_ID,
                 v_hash_pan,
                 v_encr_pan,
                 v_encr_full_name,
                 V_MAILADDR_LINEONE,            
                 V_MAILADDR_LINETWO, 
                 V_MAILADDR_CITY, 
                 v_mailing_switch_state_code,    
                 V_MAILADDR_ZIP,
                 'P',
                 1,
                 SYSDATE);
           EXCEPTION
            WHEN OTHERS THEN
             P_RESPCODE := '21';
             P_ERRMSG := 'Exception while Inserting in CMS_AVQ_STATUS Table ' ||SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
        END;

      END IF;
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
ROLLBACK;
WHEN OTHERS THEN
ROLLBACK;
P_RESPCODE := '21';
P_ERRMSG := 'Exception while AVQ Status update process ' ||P_ERRMSG || SUBSTR(SQLERRM, 1, 200);
END;

/
show error
