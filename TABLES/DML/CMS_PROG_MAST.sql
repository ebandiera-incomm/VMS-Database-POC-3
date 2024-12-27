DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND owner = 'VMSCMS'
      AND object_name = 'CMS_PROG_MAST_R1707B1';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+1 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         
				INSERT INTO vmscms.CMS_PROG_MAST_R1707B1
  (CPM_INST_CODE,
   CPM_PROG_CODE,
   CPM_TAB_TYPE,
   CPM_MENU_LINK,
   CPM_PROG_NAME,
   CPM_MENU_PATH,
   CPM_MENU_DESC,
   CPM_PROG_ORDER,
   CPM_PROG_STAT,
   CPM_INS_USER,
   CPM_INS_DATE,
   CPM_LUPD_USER,
   CPM_LUPD_DATE,
   CPM_ADMIN_MENU)
VALUES
  (1,
   (SELECT MAX(CPM.CPM_PROG_CODE)+1  FROM vmscms.CMS_PROG_MAST CPM where cpm_inst_code=1),
   'P',
   15,
   'Define Partner',
   '/cms/Product/DefinePartner.jsp',
   'cms.menu.prog.DefinePartner',
   201.43,
   'Y',
   1,
   sysdate,
   1,
   sysdate,
   'N');
   
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+2 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         
			INSERT INTO vmscms.CMS_PROG_MAST_R1707B1
  (CPM_INST_CODE,
   CPM_PROG_CODE,
   CPM_TAB_TYPE,
   CPM_MENU_LINK,
   CPM_PROG_NAME,
   CPM_MENU_PATH,
   CPM_MENU_DESC,
   CPM_PROG_ORDER,
   CPM_PROG_STAT,
   CPM_INS_USER,
   CPM_INS_DATE,
   CPM_LUPD_USER,
   CPM_LUPD_DATE,
   CPM_ADMIN_MENU)
VALUES
  (1,
   (SELECT MAX(CPM.CPM_PROG_CODE)+2  FROM vmscms.CMS_PROG_MAST CPM where cpm_inst_code=1),
   'P',
   20,
   'Define Fulfillment Vendor',
   '/cms/primary/DefineFulfillmentVendor.jsp',
   'cms.menu.prog.FulfillmentVendor',
   83.7,
   'Y',
   1,
   sysdate,
   1,
   sysdate,
   'N');
   
      END IF;
	  
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+3 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         
				INSERT INTO vmscms.CMS_PROG_MAST_R1707B1
  (CPM_INST_CODE,
   CPM_PROG_CODE,
   CPM_TAB_TYPE,
   CPM_MENU_LINK,
   CPM_PROG_NAME,
   CPM_MENU_PATH,
   CPM_MENU_DESC,
   CPM_PROG_ORDER,
   CPM_PROG_STAT,
   CPM_INS_USER,
   CPM_INS_DATE,
   CPM_LUPD_USER,
   CPM_LUPD_DATE,
   CPM_ADMIN_MENU)
VALUES
  (1,
   (SELECT MAX(CPM.CPM_PROG_CODE)+3  FROM vmscms.CMS_PROG_MAST CPM where cpm_inst_code=1),
   'P',
   20,
   'State Restriction Config',
   '/cms/Product/StateRestriction.jsp',
   'cms.menu.prog.StateRestriction',
   83.8,
   'Y',
   1,
   sysdate,
   1,
   sysdate,
   'N');
   
      END IF;
	  
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+4 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         
				INSERT INTO vmscms.CMS_PROG_MAST_R1707B1
  (CPM_INST_CODE,
   CPM_PROG_CODE,
   CPM_TAB_TYPE,
   CPM_MENU_LINK,
   CPM_PROG_NAME,
   CPM_MENU_PATH,
   CPM_MENU_DESC,
   CPM_PROG_ORDER,
   CPM_PROG_STAT,
   CPM_INS_USER,
   CPM_INS_DATE,
   CPM_LUPD_USER,
   CPM_LUPD_DATE,
   CPM_ADMIN_MENU)
VALUES
  (1,
   (SELECT MAX(CPM.CPM_PROG_CODE)+4  FROM vmscms.CMS_PROG_MAST CPM where cpm_inst_code=1),
   'P',
   15,
   'Group Access Id',
   '/cms/Product/GroupIdCreation.jsp',
   'cms.menu.prog.GroupIdCreation',
   201.42,
   'Y',
   1,
   sysdate,
   1,
   sysdate,
   'N');
   
      END IF;
	  
	  
	  SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+5 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         
				INSERT
INTO vmscms.cms_prog_mast_R1707B1
  (
    CPM_INST_CODE,
    CPM_PROG_CODE,
    CPM_TAB_TYPE,
    CPM_MENU_LINK,
    CPM_PROG_NAME,
    CPM_MENU_PATH,
    CPM_MENU_DESC,
    CPM_PROG_ORDER,
    CPM_PROG_STAT,
    CPM_INS_USER,
    CPM_INS_DATE,
    CPM_LUPD_USER,
    CPM_LUPD_DATE,
    CPM_ADMIN_MENU
  )
  VALUES
  (
    1,(SELECT MAX(cpm_prog_code)+5 FROM vmscms.cms_prog_mast where cpm_inst_code=1),
    'P',
    8,
    'CCF Configuration',
    '/cms/CCFConfiguaration.jsp',
    'cms.menu.prog.ccfConfiguration',
    152.8,
    'Y',
    1,
    SYSDATE,
    1,
    SYSDATE,
    'N'
  );
   
      END IF;


      INSERT INTO vmscms.CMS_PROG_MAST
         SELECT *
           FROM vmscms.CMS_PROG_MAST_R1707B1
          WHERE (CPM_INST_CODE,
                 CPM_PROG_CODE
                ) NOT IN (
                   SELECT CPM_INST_CODE, CPM_PROG_CODE
                     FROM vmscms.CMS_PROG_MAST);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/


DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE object_type = 'TABLE'
      AND owner = 'VMSCMS'
      AND object_name = 'CMS_PROG_MAST_R1707B3';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+1 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         insert into vmscms.cms_prog_mast_R1707B3(cpm_inst_code,cpm_prog_code,cpm_tab_type,cpm_menu_link,cpm_prog_name,cpm_menu_path,cpm_menu_desc,cpm_prog_order,cpm_prog_stat,cpm_ins_user,cpm_ins_date,cpm_admin_menu,cpm_lupd_user,cpm_lupd_date)
values(1,(select max(cpm_prog_code)+1 from vmscms.cms_prog_mast where cpm_inst_code=1),'P',15,'PAN Inventory Generation Status','/cms/Product/CardGeneration.jsp','cms.menu.prog.PANNoGen','201.44','Y',1,sysdate,'N',1,sysdate);
   
      END IF;
	  
	   SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.CMS_PROG_MAST
       WHERE CPM_INST_CODE = 1
         AND CPM_PROG_CODE = (SELECT MAX(cpm_prog_code)+2 FROM vmscms.cms_prog_mast where cpm_inst_code=1);

      IF v_cnt = 0
      THEN
         INSERT INTO vmscms.CMS_PROG_MAST_R1707B3
  (CPM_INST_CODE,CPM_PROG_CODE,CPM_TAB_TYPE,CPM_MENU_LINK,CPM_PROG_NAME,CPM_MENU_PATH,
   CPM_MENU_DESC,CPM_PROG_ORDER,CPM_PROG_STAT,CPM_INS_USER,CPM_INS_DATE,CPM_LUPD_USER,
	CPM_LUPD_DATE,CPM_ADMIN_MENU)
VALUES
  (1,
   (SELECT MAX(CPM.CPM_PROG_CODE)+2  FROM vmscms.CMS_PROG_MAST CPM where cpm_inst_code=1),
   'P',20,'Define Package ID','/cms/primary/DefinePackageIDorUpdatePackageID.jsp','cms.menu.prog.DefinePackageID/UpdatePackageID','83.9',
   'Y',1,sysdate,1,sysdate,'N');
   
      END IF;
	  
      INSERT INTO vmscms.CMS_PROG_MAST
         SELECT *
           FROM vmscms.CMS_PROG_MAST_R1707B3
          WHERE (CPM_INST_CODE,
                 CPM_PROG_CODE
                ) NOT IN (
                   SELECT CPM_INST_CODE, CPM_PROG_CODE
                     FROM vmscms.CMS_PROG_MAST);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/

UPDATE vmscms.CMS_PROG_MAST SET CPM_PROG_STAT='N' WHERE CPM_MENU_DESC='cms.menu.prog.ProducCategoryProfile';

update vmscms.CMS_PROG_MAST set CPM_PROG_NAME='Product Category Profile' where CPM_MENU_DESC='cms.menu.prog.BINLevelParameters';

DELETE  FROM vmscms.CMS_GROUP_PROG WHERE CGP_PROG_CODE IN 
(SELECT  CPM_PROG_CODE FROM vmscms.CMS_PROG_MAST WHERE CPM_MENU_DESC='cms.menu.prog.ProducCategoryProfile'
AND CPM_TAB_TYPE='P');

UPDATE vmscms.CMS_PROG_MAST SET CPM_PROG_NAME='Define Partner ID' WHERE CPM_PROG_NAME='Define Partner';