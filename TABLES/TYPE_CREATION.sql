CREATE OR REPLACE TYPE vmscms.rule_set_type IS OBJECT(rule_id NUMBER(9),execution_order NUMBER(3));
/
CREATE OR REPLACE TYPE vmscms.rule_set_type_tab IS TABLE OF rule_set_type;
/
CREATE OR REPLACE TYPE vmscms.RULE_TYPE AS OBJECT (RULE_DETAIL_ID NUMBER(9),rule_filter VARCHAR2(100));	
/
CREATE OR REPLACE TYPE vmscms.rule_type_tab IS TABLE OF rule_type;
/
CREATE OR REPLACE type vmscms.rule_details
AS
  OBJECT
  (
    rule_detl_id NUMBER,
    rule_filter  VARCHAR2(1000));
/

CREATE OR REPLACE TYPE vmscms.TAB_RULE_DETAILS IS TABLE OF RULE_DETAILS;
/
CREATE OR REPLACE type vmscms.RULE_SET_DETAILS
AS
  object
  (
    RULE_ID              NUMBER,
    RULE_NAME        VARCHAR2(50),
	rule_priority     number(2,0),
    RULE_EXP         VARCHAR2(1000),
    TRANSACTION_TYPE varchar2(50),
    ACTION_TYPE      varchar2(50),
    rule_detail TAB_rule_details);
/
CREATE OR REPLACE TYPE vmscms.TAB_RULE_SET_DETAILS IS TABLE OF RULE_SET_DETAILS;
/

create or replace type vmscms.RULE_SET
as
object(PRODUCT_CODE varchar2(6),PRODCAT_TYPE number,RULESET_ID number,RULESET_NAME varchar2(50),
rule_set_detail TAB_RULE_SET_DETAILS);
/

CREATE OR REPLACE TYPE vmscms.tab_rule_set IS TABLE OF RULE_SET; 
/