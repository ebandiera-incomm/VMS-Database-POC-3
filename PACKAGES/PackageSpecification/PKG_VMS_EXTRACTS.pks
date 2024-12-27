CREATE OR REPLACE PACKAGE VMSCMS.PKG_VMS_EXTRACTS AS
  procedure p_bancorp(p_in_directory varchar2,p_in_date date default sysdate,p_in_inst_code number);
  procedure p_generate_settle_trans(p_in_directory varchar2,p_in_date varchar2 );
  procedure p_merch_return_reversal(p_in_directory varchar2,p_from_date date,p_to_date date);
  procedure p_iris(p_in_directory varchar2,p_from_date date,p_to_date date);
  procedure p_cmf_report (p_cmf_id IN number,p_in_date IN DATE,p_resp_msg OUT VARCHAR2);
  PROCEDURE p_cmf(p_in_directory VARCHAR2,p_cmf_id number,p_in_date date) ;
  PROCEDURE p_rec_rpt (prm_directory    VARCHAR2,prm_from_month   VARCHAR2,prm_to_month     VARCHAR2);
  procedure p_international_atm(p_in_directory varchar2,p_from_date date,p_to_date date);
  procedure p_nextcala(p_in_directory varchar2,p_in_date  DATE DEFAULT SYSDATE );
END PKG_VMS_EXTRACTS;
/

