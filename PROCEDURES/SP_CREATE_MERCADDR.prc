CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Mercaddr (
   instcode         IN       NUMBER,
   custcode         IN       VARCHAR2,
   propriter_name   IN       VARCHAR2,
   add1             IN       VARCHAR2,
   add2             IN       VARCHAR2,
   add3             IN       VARCHAR2,
   pincode          IN       VARCHAR2,
   phon1            IN       VARCHAR2,
   phon2            IN       VARCHAR2,
   email            IN       VARCHAR2,
   cntrycode        IN       NUMBER,
   cityname         IN       VARCHAR2,
   switchstat       IN       VARCHAR2,           --state as coming from switch
   fax1             IN       VARCHAR2,
   addrflag         IN       CHAR,
   lupduser         IN       NUMBER,
   mobileno			IN		 VARCHAR2,
   addrcode         OUT      NUMBER,
   errmsg           OUT      VARCHAR2
) AS
 /**************************************************
    * Created Date     : 11/Feb/2009.
    * Created By       : Kaustubh.
    * PURPOSE          : Create Merchent Address
    * LAST MODIFICATION DONE BY :
    * LAST MODIFICATION DATE    :
**************************************************/
BEGIN                                           --Main Begin Block Starts Here
--this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
--IF instcode IS NOT NULL AND custcode IS NOT NULL AND add1 IS NOT NULL AND pincode IS NOT NULL AND cntrycode IS NOT NULL AND cityname IS NOT NULL AND lupduser IS NOT NULL THEN
--IF 1
   SELECT seq_mercaddr_code.NEXTVAL
     INTO addrcode
     FROM DUAL;

   INSERT INTO CMS_MERC_ADDR_MAST
               (cam_inst_code, cam_merc_code, cam_addr_code, cam_add_one,
                cam_add_two, cam_add_three, cam_pin_code, cam_phone_one,
                cam_phone_two, cam_email, cam_cntry_code, cam_city_name,
                cam_fax_one, cam_addr_flag, cam_state_switch, cam_ins_user,
                cam_lupd_user, cma_propriter_name,cam_mobl_one
               )
        VALUES (instcode, custcode, addrcode, add1,
                add2, add3, pincode, phon1,
                phon2, email, cntrycode, cityname,
                fax1, addrflag, switchstat, lupduser,
                lupduser, propriter_name,mobileno
               );

   errmsg := 'OK';
--ELSE      --IF 1
--errmsg := 'sp_create_addr expected a not null parameter';
--END IF;   --IF 1
IF SQL%ROWCOUNT = 0 THEN 
   errmsg := 'Error While inserting record in  CMS_MERC_ADDR_MAST ' ||  SQLERRM;
   END IF;
EXCEPTION                                               --Main block Exception
   WHEN OTHERS THEN
      errmsg := 'Main exexption ' || SQLCODE || '---' || SQLERRM;
END;                                              --Main Begin Block Ends Here
/
show error