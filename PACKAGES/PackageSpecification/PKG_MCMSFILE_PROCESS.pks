CREATE OR REPLACE PACKAGE vmscms.pkg_mcmsfile_process
AS
    /**************************************************************************
   * Created Date              : 18-Nov-2014
   * Created By                : Pankaj S.
   * Purpose                   : MCMS Return File
   * Release Number            :
   **************************************************************************/
   PROCEDURE sp_mcmsfile_process (
      prm_instcode   IN       NUMBER,
      prm_src_dir    IN       VARCHAR2,
      prm_dest_dir   IN       VARCHAR2,
      prm_errmsg     OUT      VARCHAR2
   );

   PROCEDURE sp_get_mcmsfile_list (prm_directory IN VARCHAR2);

   PROCEDURE sp_log_mcmserr (prm_acctno IN VARCHAR2,prm_filename IN VARCHAR2, prm_errmsg IN VARCHAR2);
END;
/
SHOW ERROR
