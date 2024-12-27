create or replace
TYPE          VMSCMS.ACCOUNT_DETAIL_TOKEN_TYP_T IS OBJECT
(
  pan                   varchar2(1000),
  token                varchar2(1000),
  token_provision_date date,
  device_type          varchar2(1000),
  device_id            varchar2(1000),
  device_number        varchar2(1000),
  device_name          varchar2(1000),
  device_location      varchar2(1000),
  device_ip            varchar2(1000),
  token_expiry         varchar2(1000),
  token_type           varchar2(1000),
  token_status         varchar2(1000),
  wallet               varchar2(1000),
  devicelanguage       varchar2(1000),
  se_id                varchar2(1000)
  );
  /