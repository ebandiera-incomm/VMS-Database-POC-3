CREATE OR REPLACE
PACKAGE VMSCMS.VMSPRM AS 

  --function to get the clear card number based on the card id 
    FUNCTION get_clr_pan (p_card_id_in IN VARCHAR2)
      RETURN VARCHAR2;  

END VMSPRM;
/
show error