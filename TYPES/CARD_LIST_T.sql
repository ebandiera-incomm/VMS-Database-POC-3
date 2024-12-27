create or replace
TYPE                 CARD_LIST_T force IS OBJECT
(
   accountnumber   VARCHAR2(20),
   pan             VARCHAR2(20),
   productcategory VARCHAR2(100),
   activationdate  DATE,
   card_status     VARCHAR2(50),
   card_id         VARCHAR2(19),
   isstartercard   VARCHAR2(10),
   proxynumber     VARCHAR2(19),
   serialnumber    varchar2(50),
   parentserialnumber varchar2(20)
)