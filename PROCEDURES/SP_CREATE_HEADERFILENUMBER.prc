CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_HEADERFILENUMBER(   instcode            IN     number     ,
                                                     lupduser                 IN     number     ,
                                                     headfileno               OUT    VARCHAR2,
                                                     cardrecordcnt            OUT    VARCHAR2,
                                                     errmsg                   OUT    varchar2)
AS
/**************************************************
      * Modified By      : Ubaid
      * Modified Date    : 28-Jun-2018
      * Purpose          : VMS-375
      * Reviewer         : Saravanakumar
      * Build Number     : VMSR03_B0002
 **************************************************/
v_ccc_header_seq     varchar2 (12);
v_ccc_cardrec_seq    varchar2 (12);
pragma autonomous_transaction;

BEGIN        --Main Begin Block Starts Here        
      BEGIN  
      errmsg := 'OK';    
      SELECT  CCC_HEADER_SEQ,CCC_DETAIL_SEQ
      INTO    v_ccc_header_seq,v_ccc_cardrec_seq
      FROM    CMS_CCF_CTRL
      WHERE    ccc_inst_code = instcode
      AND        trunc(CCC_CCFGEN_DATE) = trunc(sysdate);      
      
      headfileno := v_ccc_header_seq+1;
      cardrecordcnt := v_ccc_cardrec_seq+1;
      
      UPDATE CMS_CCF_CTRL SET CCC_HEADER_SEQ= headfileno,CCC_DETAIL_SEQ=cardrecordcnt
      WHERE ccc_inst_code = instcode
      AND        trunc(CCC_CCFGEN_DATE) = trunc(sysdate);
                
      EXCEPTION	--Exception of begin 1
		WHEN NO_DATA_FOUND THEN
                
                headfileno:='100000';
                cardrecordcnt:='200000';
                
                INSERT INTO CMS_CCF_CTRL VALUES
                (instcode,
                SYSDATE,
                100000,
                200000,
                1,
                SYSDATE,
                1,
                SYSDATE                
                );
                
                errmsg := 'OK';
                
	   WHEN OTHERS THEN
			errmsg := 'Exeption 1 -- '||SQLCODE||'--'||SQLERRM;
        END;  
       commit;
EXCEPTION    --Exception of Main Begin
    WHEN OTHERS THEN
    rollback;
    errmsg := 'Exeption Main -- '||SQLCODE||'--'||SQLERRM;
END    ;        --Main Begin Block Ends Here
/
show error