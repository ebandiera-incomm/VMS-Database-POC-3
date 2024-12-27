create or replace
PROCEDURE        VMSCMS.SP_CREATE_PROD(INSTCODE    IN NUMBER,
                                   ASSOCODE    IN NUMBER,
                                   INSTTYPE    IN NUMBER,
                                   INTERCHANGE IN VARCHAR2,
                                   CATEGORY    IN VARCHAR2,
                                   OPENVAR     IN VARCHAR2,
                                   DESCR       IN VARCHAR2,
                                   --V_SWTCHPROD  IN VARCHAR2     ,--switch specific product for caf refresh
                                   FROMDATE IN DATE,
                                   --V_TODATE       IN   date     ,--for sp_add_proddates
                                   --commented on 09-08-02, fixed internally
                                   BIN         IN NUMBER, --for sp_create_prodbin
                                   -- PROFILECODE IN VARCHAR2, --Prajakta --Commented By Vikrant 11june08
                                  -- VARPRODUCT  IN VARCHAR2, -- Hari
                                   -- PRGID       IN VARCHAR2, --T.Narayanan added for prg id
                                   
                                   PREAUTHEXP  IN VARCHAR2, --T.Narayanan added for prg id
                                   P_ROUTINGNUM IN VARCHAR2, -- ADDED BY SIVA KUMAR M AS ON 28/06/12 FOR ROUTING NUMBER.
                                   ISSUINGBANK IN VARCHAR2, -- Added on 01-OCT-2013 for JH-5 
				                   ICA         In Varchar2, --Added for JH-20
                                   EXPFLAG     IN VARCHAR2, -- // Changes made for Mantis ID : 13027 - amudhan
                                   STATEMENTFOOTER IN VARCHAR2, -- Added for DFCCSD-117 Kalees P
                                   --LUPDUSER    IN NUMBER,
                                  -- PROXYLENGTH IN NUMBER, -- ADDED by sagar on 29-mar-2012 to store proxy number length at product level 
                                   P_OLSRESPONSEFLAG IN VARCHAR2,
                                   P_EMVFLAG IN VARCHAR2,
                                   P_INSTITUTIONID IN VARCHAR2,  --Added for DFCTNM-26
                                   P_TRANSITNO IN VARCHAR2, --Added for DFCTNM-26
                                   P_RANDOMPIN IN VARCHAR2, --Added for DFCTNM-26
                                   P_PINCHANGE IN NUMBER, --Added for DFCTNM-26
                                   P_POA IN VARCHAR2, --Added for DFCTNM-26
                                   P_CTCBIN IN VARCHAR2, --Added for DFCTNM-26
                                   P_ISSUINGBANK_ADDR IN VARCHAR2, --Added for MVCSD-5596
                                   ONUSPREAUTHEXP  IN VARCHAR2,
                                   LUPDUSER    IN NUMBER,
                                   P_ISSUINGBANK_ID    IN NUMBER,
                                   PRODCODE    OUT VARCHAR2,
                                   ERRMSG      OUT VARCHAR2)

 AS
 
/**************************************************
     * Created Date                 :  NA
     * Created By                   :  NA
     * Purpose                      :  To crate new product in product master
     * Last Modification Done by    :  Siva Kumar .M
     * Last Modification Date       :  28/06/2012
     * Mofication Reason            :  To add routing number at product level
     * Reviewer                     :  B.Besky Anand
     * Reviewed Date                :  10-July-2012
     * Build Number                 :  CMS3.5.1_RI0011_B0004
	 
	 * Modified by      : MageshKumar.S
     * Modified Reason  : JH-5
     * Modified Date    : 01-OCT-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001
	 
     * Modified by      : Anil Kumar
     * Modified Reason  : JH-20 : Addition of ICA
     * Modified Date    : 11-OCT-2013
     * Reviewer         : Dhiraj  
     * Reviewed Date    : 17-Oct-2013 
     * Build Number     : RI0024.6_B0001 
     
     * Modified by      : Kaleeswaran P
     * Modified Reason  : DFCCSD-117
     * Modified Date    : 04-Feb-2014
     * Reviewer         : Dhiraj  
     * Reviewed Date    :  
     * Build Number     : RI0027.1_B0001 
     
 
       * Modified by      : Amudhan S
       * Modified Reason  : Mantis Id : 13027
       * Modified Date    : 20-NOV-2013
       * Reviewer         : Dhiraj 
       * Reviewed Date    : 
       * Build Number     : RI0024.6.1_B0002 

       * Modified by      : Dhinakaran B
       * Modified Reason  : EMV CHANGES
       * Modified Date    : 12-FEB-2015
       * Reviewer         :  
       * Reviewed Date    : 
       * Build Number     : RI0027.5.1
       
       * Modified by      : MAGESHKUMAR S
       * Modified Reason  : DFCTNM-10(EMV CCF CHANGES)
       * Modified Date    : 19-FEB-2015
       * Reviewer         : PANKAJ S 
       * Build Number     : RI0027.5_B0009
       
       * Modified by       : Ramesh A
       * Modified Date     : 02-Mar-15
       * Modified For      : DFCTNM-26
       * Reviewer          : 
       * Build Number      :
       
       * Modified by       : Ramesh A
       * Modified Date     : 21-Mar-15
       * Modified For      : MVCSD-5596
       * Reviewer          : SarvanaKumar
       * Build Number      : 3.0
	   
	   * Modified by       : Abdul Hameed M.A
       * Modified Date     : 23-June-15
       * Modified For      : FSS 1960
       * Reviewer          : Pankaj S
       * Build Number      : VMSGPRHOSTCSD_3.1
       
       * Modified by       : T.Narayanaswamy
       * Modified Date     : 20-June-17
       * Modified Reason   : FSS-5157 - B2B Gift Card - Phase 2 (fixed variable field moved from product to product category  )
       * Reviewer          : SarvanaKumar
       * Build Number      : 17.07_B0001

	   * Modified by       : T.Narayanaswamy
       * Modified Date     : 21-July-17
       * Modified Reason   : FSS-5157 - B2B Gift Card - Phase 2 -- removed Proxy number length and program ID.
       * Reviewer          : SarvanaKumar
       * Build Number      : 17.08_B0001
	   
	   * Modified by       : Baskar Krishnan
       * Modified Date     : 10-Sep-19
       * Modified Reason   : VMS-1081 - Enhance Sweep Job for Amex products.
       * Reviewer          : SarvanaKumar
       * Build Number      : R20_B0003
	   
	   * Modified by       : Baskar Krishnan
       * Modified Date     : 17-Dec-19
       * Modified Reason   : VMS-1573 - Adding a new product is failing in Setup > Product > Product Parameters screen
       * Reviewer          : SarvanaKumar
       * Build Number      : R24_B0001

 ******************************************************/
       
       
      
  --1CH270303 Anup changed the calling of sp_create_prodcattype
  V_INTERCHANGE   VARCHAR2(2);
  V_CATEGORY      VARCHAR2(2);
  V_OPENVAR       VARCHAR2(2);
  V_MESG2           VARCHAR2(500);
  V_CARDTYPE      NUMBER;
  V_TYPEDESC        VARCHAR2(1);
  V_CCT_CTRL_NUMB VARCHAR2(100);
  V_TODATE          DATE := TO_DATE('01-JAN-9999', 'DD_MON_YYYY');
  V_VENDOR          CMS_PROD_CATTYPE.CPC_VENDOR%TYPE;
  V_STOCK           CMS_PROD_CATTYPE.CPC_STOCK%TYPE;
  V_SWTCHPROD       VARCHAR2(10);
  --V_SEQ_NO        NUMBER(10); --T.Narayanan added for prg id
  --V_GET_SEQ_QUERY   VARCHAR2(500); --T.Narayanan added for prg id
BEGIN
  --Main Begin Block Starts Here

  V_INTERCHANGE := LTRIM(RTRIM(INTERCHANGE));
  V_CATEGORY    := LTRIM(RTRIM(CATEGORY));
  V_OPENVAR     := LTRIM(RTRIM(OPENVAR));
  PRODCODE      := V_INTERCHANGE || V_CATEGORY || V_OPENVAR;
  V_SWTCHPROD     := V_INTERCHANGE || V_CATEGORY;
  --dbms_output.put_line('inside proc mapcode==>'||v_mapcode);
  --dbms_output.put_line('inside proc interchange==>'||v_interchange);
  --dbms_output.put_line('inside proc category==>'||v_category);
  --dbms_output.put_line('inside proc openvar==>'||v_openvar);

  --dbms_output.put_line('inside proc prodcode==>'||prodcode);
  --dbms_output.put_line('inside proc feecode==>'||feecode);
  --dbms_output.put_line('inside proc loyl code==>'||loylcode);

  BEGIN
    SELECT lpad(cct_ctrl_numb, DECODE(length(cct_ctrl_numb), 1, 2, length(cct_ctrl_numb)), 0)
     INTO V_CCT_CTRL_NUMB
     FROM CMS_CTRL_TABLE
    WHERE SUBSTR(CCT_CTRL_CODE, 0, 2) =
         LTRIM(RTRIM(INTERCHANGE || CATEGORY)) AND
         CCT_CTRL_KEY = 'PROD CODE'
      FOR UPDATE;
    PRODCODE := INTERCHANGE || CATEGORY || V_CCT_CTRL_NUMB;
  
    UPDATE CMS_CTRL_TABLE
      SET CCT_CTRL_NUMB = CCT_CTRL_NUMB + 1, CCT_LUPD_USER = LUPDUSER
    WHERE SUBSTR(CCT_CTRL_CODE, 0, 2) =
         LTRIM(RTRIM(INTERCHANGE || CATEGORY)) AND
         CCT_CTRL_KEY = 'PROD CODE';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     PRODCODE := INTERCHANGE || CATEGORY || '01';
    
     INSERT INTO CMS_CTRL_TABLE
       (CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_LUPD_USER)
     VALUES
       (LTRIM(RTRIM(PRODCODE)),
        'PROD CODE',
        2,
        'Latest prod type for interchange ' || INTERCHANGE ||
        ' and category ' || CATEGORY || '.',
        LUPDUSER,
        LUPDUSER);   
  END;

  BEGIN
    --begin 1
    INSERT INTO CMS_PROD_MAST
     (CPM_INST_CODE,
      CPM_ASSO_CODE,
      CPM_INST_TYPE,
      CPM_PROD_CODE,
      CPM_INTERCHANGE_CODE,
      CPM_CATG_CODE,
      CPM_PROD_DESC,
      CPM_SWITCH_PROD,
      CPM_FROM_DATE,
      CPM_TO_DATE,
     -- CPM_PROFILE_CODE, -- Prajakta     --Commented By Vikrant 11June08
      CPM_INS_USER,
      CPM_INS_DATE, --T.Narayanan added for prg id
      CPM_LUPD_USER,
      CPM_LUPD_DATE, --T.Narayanan added for prg id
    --  CPM_PROGRAM_ID, --T.Narayanan added for prg id
      CPM_PRE_AUTH_EXP_DATE, --T.Narayanan added for prg id
    --  CPM_VAR_FLAG,
     -- CPM_PROXY_LENGTH,  --ADDED by sagar on 29-mar-2012 to store proxy number length at product level 
      CPM_ROUT_NUM,        -- Added by siva kumar .M on 28/06/2012 for routing Number at product level.
      CPM_ISSU_BANK, -- Added on 01-OCT-2013 for JH-5
      CPM_ICA, -- Added for JH-20
      cpm_ols_expiry_flag, -- // Changes made for Mantis ID : 13027 - amudhan
      CPM_STATEMENT_FOOTER,  --Added for DFCCSD-117
      CPM_OLSRESP_FLAG,
      CPM_EMV_FLAG, --Added for EMV CCF Changes
      CPM_INSTITUTION_ID,   --Added for DFCTNM-26
      CPM_TRANSIT_NUMBER, --Added for DFCTNM-26
      cpm_random_pin, --Added for DFCTNM-26
      cpm_pinchange_flag, --Added for DFCTNM-26
      CPM_POA_PROD, --Added for DFCTNM-26
      cpm_ctc_bin, --Added for DFCTNM-26
      CPM_ISSU_BANK_ADDR, --Added for MVCSD-5596
      CPM_ONUS_AUTH_EXPIRY,
      CPM_ISSUBANK_ID
      )
    VALUES
     (INSTCODE,
      ASSOCODE,
      INSTTYPE,
      PRODCODE,
      V_INTERCHANGE,
      V_CATEGORY,
      DESCR,
      V_SWTCHPROD,
      FROMDATE,
      V_TODATE,
     -- PROFILECODE, -- Prajakta            --Commented By Vikrant 11june08
      LUPDUSER,
      SYSDATE,
      LUPDUSER,
      SYSDATE,
      --PRGID, --T.Narayanan added for prg id
      PREAUTHEXP,
   --   VARPRODUCT,
     -- PROXYLENGTH, --ADDED by sagar on 29-mar-2012 to store proxy number length at product level
      P_ROUTINGNUM,  -- Added by siva kumar .M on 28/06/2012 for routing Number at product level.
      ISSUINGBANK, -- Added on 01-OCT-2013 for JH-5
      ICA,   -- Added for JH-20
      EXPFLAG,        -- // Changes made for Mantis ID : 13027 - amudhan
      STATEMENTFOOTER, --Added for DFCCSD-117
      P_OLSRESPONSEFLAG,
      P_EMVFLAG, --Added for EMV CCF Changes
      P_INSTITUTIONID, --Added for DFCTNM-26
      P_TRANSITNO, --Added for DFCTNM-26
      P_RANDOMPIN, --Added for DFCTNM-26
      P_PINCHANGE, --Added for DFCTNM-26
      P_POA, --Added for DFCTNM-26
      P_CTCBIN, --Added for DFCTNM-26
      P_ISSUINGBANK_ADDR, --Added for MVCSD-5596
      ONUSPREAUTHEXP,
      P_ISSUINGBANK_ID
      );
    ERRMSG := 'OK';
  EXCEPTION
    --excp of begin 1
    WHEN OTHERS THEN
     ERRMSG := 'Excp 1  ' || SQLERRM;
  END; --end of begin 1
  --T.Narayanan added for prg id beg
--  IF ERRMSG = 'OK' THEN
--    BEGIN
--     V_GET_SEQ_QUERY := 'SELECT COUNT(*)  FROM CMS_PROGRAM_ID_CNT CPI WHERE CPI.CPI_PROGRAM_ID=' ||
--                   CHR(39) || PRGID || CHR(39) || ' AND CPI_INST_CODE=' ||
--                   INSTCODE;
--     EXECUTE IMMEDIATE V_GET_SEQ_QUERY
--       INTO V_SEQ_NO;
--     IF V_SEQ_NO = 0 THEN
--       INSERT INTO CMS_PROGRAM_ID_CNT
--        (CPI_INST_CODE,
--         CPI_PROGRAM_ID,
--         CPI_SEQUENCE_NO,
--         CPI_INS_USER,
--         CPI_INS_DATE)
--       VALUES
--        (INSTCODE, PRGID, 0, '', SYSDATE);
--     END IF;
--    EXCEPTION
--     WHEN OTHERS THEN
--       ERRMSG := 'Error when inserting into  CMS_PROGRAM_ID_CNT ' ||
--               SQLERRM;
--    END;
--  END IF;
  --T.Narayanan added for prg id end

  /*commented on 09-08-02 because it was decided that the product from date and to date was to be stored only once for a product
  
  i.e. in the product master
  IF errmsg = 'OK' THEN
       BEGIN               --begin 2   procedure adds product from and to dates while creating products
  
       --same procedure can be called independently to add more from to dates at a later stage(once the product has been created)
  
            sp_add_proddates(instcode,prodcode,fromdate,V_TODATE,lupduser,mesg2);
            --dbms_output.put_line('from called proc for add date----->'||mesg2);
            IF V_MESG2 != 'OK' THEN
                 errmsg := mesg2;
            END IF;
       EXCEPTION       --excp of begin 2
            WHEN OTHERS THEN
            errmsg := 'Excp 2 --- '||SQLERRM;
       END;        --end of begin 2
  END IF;
  */
  /*IF errmsg = 'OK' THEN
                 BEGIN          --begin 3  procedure adds default product card types while creating products
  
                 --same procedure can be called independently to create more product card types (i.e. after tha product with a default product card type is created)
  
                      Sp_Create_Prodcattype(instcode,prodcode,V_TYPEDESC,NULL,NULL,V_VENDOR,V_STOCK,lupduser,v_cardtype,mesg2);--two null parameters given here since it creates a default card type and the cust catg is attached to the def card type in edit mode only
  
                      IF V_MESG2 != 'OK' THEN
                           errmsg := mesg2;
                      END IF;
                 EXCEPTION    --excp of begin 3
                      WHEN OTHERS THEN
                      errmsg := 'Excp 3 --- '||SQLERRM;
                 END;       --end of begin 2
            END IF;
  */

  IF ERRMSG = 'OK' THEN
    BEGIN
     --begin 4 starts
     SP_CREATE_PRODBIN(INSTCODE,
                    PRODCODE,
                    BIN,
                    V_INTERCHANGE,
                    LUPDUSER,
                    V_MESG2);
     IF V_MESG2 != 'OK' THEN
       ERRMSG := 'From sp_create_prodbin - ' || V_MESG2;
     END IF;
    EXCEPTION
     --excp of begin 4
     WHEN OTHERS THEN
       ERRMSG := 'Excp 4  ' || SQLERRM;
    END; --end of begin 4
  END IF;

  --begin block 5 added on 25/09/2002
  /*IF errmsg = 'OK' THEN
       BEGIN          --begin 5
            Sp_Create_Prodccc(instcode,'1',NULL,v_cardtype,prodcode,lupduser,mesg2);--cuatomer catg 1 is hard coded because it is created while creating the default data for an inst
  
            IF V_MESG2 != 'OK' THEN
                 errmsg := 'From sp_create_prodccc - '||mesg2;
            END IF;
       EXCEPTION    --excp of begin 5
            WHEN OTHERS THEN
            errmsg := 'Excp 5 --- '||SQLERRM;
       END;       --end begin 5
  END IF;*/

EXCEPTION
  --Excp of Main Begin Block
  WHEN OTHERS THEN
    ERRMSG := 'Main Exception FROM   ' || SQLERRM;
END; --Main Begin Block Ends Here
/
SHOW ERROR;