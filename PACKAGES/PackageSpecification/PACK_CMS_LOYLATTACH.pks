CREATE OR REPLACE PACKAGE VMSCMS.pack_cms_loylattach
AS
   PROCEDURE sp_create_prodloyl (
      instcode    IN       NUMBER,
      prodcode    IN       VARCHAR2,
      loylcode    IN       NUMBER,
      validfrom   IN       DATE,
      validto     IN       DATE,
      lupduser    IN       NUMBER,
      errmsg      OUT      VARCHAR2
   );

   PROCEDURE sp_create_cardexcployl (
      instcode    IN       NUMBER,
      loylcode    IN       NUMBER,
      pancod     IN       VARCHAR2,
      mbrnumb     IN       VARCHAR2,
      validfrom   IN       DATE,
      validto     IN       DATE,
      lupduser    IN       NUMBER,
      errmsg      OUT      VARCHAR2
   );

   PROCEDURE sp_create_prodcattypeloyl (
      instcode     IN       NUMBER,
      prodcode     IN       VARCHAR2,
      cardtype     IN       NUMBER,
      loylcode     IN       NUMBER,
      validfrom    IN       DATE,
      validto      IN       DATE,
      flowsource   IN       VARCHAR2,
      lupduser     IN       NUMBER,
      errmsg       OUT      VARCHAR2
   );
   PROCEDURE sp_create_prodcccloyl(instcode      IN NUMBER   ,
        custcatg    IN NUMBER   ,
        prodcode   IN VARCHAR2 ,
        cardtype    IN NUMBER   ,
        loylcode    IN NUMBER   ,
        validfrom      IN DATE     ,
        validto     IN DATE     ,
        flowsource  IN VARCHAR2 ,
        lupduser    IN NUMBER   ,
        errmsg      OUT    VARCHAR2  
   );
END;                                                      --END PACKAGE HEADER
/
show error