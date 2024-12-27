CREATE OR REPLACE TRIGGER VMSCMS.trg_issuence_entry_duplcheck
   BEFORE INSERT
   ON pcms_caf_issuance_entry
   FOR EACH ROW
DECLARE
   p_err     NUMBER;
   v_count   NUMBER;
   /*************************************************
     * VERSION             :  1.0
     * Created Date       : 2/Apr/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : this trigger is user for checkin duplicate recordn in issuance entry on the basis of some creiteria

     * Modified By:    :
     * Modified Date  :
 ***********************************************/
BEGIN
   SELECT COUNT (*)
     INTO v_count
     FROM pcms_caf_issuance_entry
    WHERE cci_serial_no = :NEW.cci_serial_no
      AND cci_upld_stat IN ('P', 'A', 'C')
      AND cci_approved IN ('P', 'A', 'C');

   IF (v_count > 0)
   THEN
      p_err := 1;
   END IF;

   IF p_err = 1
   THEN
      RAISE_APPLICATION_ERROR (-20003,
                                  'SAME SERIAL NO. IS EXIST  '
                               || :NEW.cci_serial_no
                               || SQLERRM
                              );
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      p_err := 0;
   WHEN OTHERS
   THEN
      RAISE_APPLICATION_ERROR (-20003,
                                  'SAME SERIAL NO. IS EXIST  '
                               || :NEW.cci_serial_no
                               || SQLERRM
                              );
END;
/


