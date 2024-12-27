declare
v_rule_id vmscms.vms_rule_mast.VRM_RULE_ID%type;
v_rule_set_id vmscms.VMS_RULESET_MAST.VRS_RULESET_ID%type;
v_msg clob:='{
  "condition": "OR",
  "rules": [
    {
      "id": "WALLET_ID",
      "field": "WALLET_ID",
      "type": "string",
      "input": "text",
      "operator": "countGreaterEqual",
      "value": "5"
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "101"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "2"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "102"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "2"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "103"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "2"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "216"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "2"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "217"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "2"
        }
      ]
    },
    {
      "id": "CHARGE_BACK_COUNT",
      "field": "CHARGE_BACK_COUNT",
      "type": "string",
      "operator": "countGreaterEqual",
      "value": "5.30"
    },
    {
      "id": "LAST_ACTIVE_PERIOD",
      "field": "LAST_ACTIVE_PERIOD",
      "type": "double",
      "input": "text",
      "operator": "greater",
      "value": "90"
    },
    {
      "id": "DEVICE_ID",
      "field": "DEVICE_ID",
      "type": "integer",
      "input": "text",
      "operator": "countGreaterEqual",
      "value": "5"
    },
    {
      "id": "DEVICE_SCORE",
      "field": "DEVICE_SCORE",
      "type": "double",
      "input": "text",
      "operator": "less_or_equal",
      "value": "2"
    },
    {
      "id": "ACCOUNT_SCORE",
      "field": "ACCOUNT_SCORE",
      "type": "double",
      "input": "text",
      "operator": "less_or_equal",
      "value": "2"
    },
    {
      "id": "NETWORK_TOKEN_DECISION",
      "field": "NETWORK_TOKEN_DECISION",
      "type": "string",
      "input": "text",
      "operator": "equal",
      "value": "05"
    },
    {
      "id": "TOKEN_SCORE",
      "field": "TOKEN_SCORE",
      "type": "double",
      "input": "text",
      "operator": "greater_or_equal",
      "value": "75"
    },
    {
      "id": "DEVICE_LOCATION_COUNTRY",
      "field": "DEVICE_LOCATION_COUNTRY",
      "type": "string",
      "input": "text",
      "operator": "not_equal",
      "value": "USA"
    },
    {
      "id": "DEVICE_LOCATION_DISTANCE",
      "field": "DEVICE_LOCATION_DISTANCE",
      "type": "double",
      "input": "text",
      "operator": "greater",
      "value": "600"
    },
    {
      "id": "ADDR_VERIFI_BOTH",
      "field": "ADDR_VERIFI_BOTH",
      "type": "string",
      "input": "select",
      "operator": "equal",
      "value": "N"
    },
    {
      "id": "DEVICE_ID_ADDRESS",
      "field": "DEVICE_ID_ADDRESS",
      "type": "string",
      "input": "text",
      "operator": "begins_with",
      "value": "1.6"
    },
    {
      "id": "PAN_SOURCE",
      "field": "PAN_SOURCE",
      "type": "string",
      "input": "text",
      "operator": "not_equal",
      "value": "01"
    },
    {
      "id": "DEVICE_TYPE",
      "field": "DEVICE_TYPE",
      "type": "string",
      "input": "text",
      "operator": "equal",
      "value": "00"
    },
    {
      "id": "TOKEN_STORAGE_TECHNOLOGY",
      "field": "TOKEN_STORAGE_TECHNOLOGY",
      "type": "string",
      "input": "text",
      "operator": "equal",
      "value": "06"
    },
    {
      "id": "TOKEN_TYPE",
      "field": "TOKEN_TYPE",
      "type": "string",
      "input": "text",
      "operator": "equal",
      "value": "05"
    }
  ]
}';

v_msg1 clob:='{
  "condition": "OR",
  "rules": [
    {
      "id": "NETWORK_TOKEN_DECISION",
      "field": "NETWORK_TOKEN_DECISION",
      "type": "string",
      "input": "text",
      "operator": "equal",
      "value": "85"
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "countLesserEqual",
          "value": "4"
        },
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "countGreaterEqual",
          "value": "3"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "101"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "1"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "102"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "1"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "103"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "1"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "216"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "1"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "WALLET_ID",
          "field": "WALLET_ID",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "217"
        },
        {
          "id": "RISK_ASSESMENT",
          "field": "RISK_ASSESMENT",
          "type": "string",
          "input": "text",
          "operator": "equal",
          "value": "1"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "CHARGE_BACK_COUNT",
          "field": "CHARGE_BACK_COUNT",
          "type": "string",
          "operator": "countLesserEqual",
          "value": "4.30"
        },
        {
          "id": "CHARGE_BACK_COUNT",
          "field": "CHARGE_BACK_COUNT",
          "type": "string",
          "operator": "countGreaterEqual",
          "value": "3.30"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "LAST_ACTIVE_PERIOD",
          "field": "LAST_ACTIVE_PERIOD",
          "type": "double",
          "input": "text",
          "operator": "greater",
          "value": "30"
        },
        {
          "id": "LAST_ACTIVE_PERIOD",
          "field": "LAST_ACTIVE_PERIOD",
          "type": "double",
          "input": "text",
          "operator": "less_or_equal",
          "value": "90"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "DEVICE_ID",
          "field": "DEVICE_ID",
          "type": "integer",
          "input": "text",
          "operator": "countLesserEqual",
          "value": "4"
        },
        {
          "id": "DEVICE_ID",
          "field": "DEVICE_ID",
          "type": "integer",
          "input": "text",
          "operator": "countGreaterEqual",
          "value": "3"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "DEVICE_SCORE",
          "field": "DEVICE_SCORE",
          "type": "double",
          "input": "text",
          "operator": "greater_or_equal",
          "value": "3"
        },
        {
          "id": "DEVICE_SCORE",
          "field": "DEVICE_SCORE",
          "type": "double",
          "input": "text",
          "operator": "less_or_equal",
          "value": "4"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "ACCOUNT_SCORE",
          "field": "ACCOUNT_SCORE",
          "type": "double",
          "input": "text",
          "operator": "greater_or_equal",
          "value": "3"
        },
        {
          "id": "ACCOUNT_SCORE",
          "field": "ACCOUNT_SCORE",
          "type": "double",
          "input": "text",
          "operator": "less_or_equal",
          "value": "4"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "TOKEN_SCORE",
          "field": "TOKEN_SCORE",
          "type": "double",
          "input": "text",
          "operator": "less",
          "value": "75"
        },
        {
          "id": "TOKEN_SCORE",
          "field": "TOKEN_SCORE",
          "type": "double",
          "input": "text",
          "operator": "greater_or_equal",
          "value": "50"
        }
      ]
    },
    {
      "condition": "AND",
      "rules": [
        {
          "id": "DEVICE_LOCATION_DISTANCE",
          "field": "DEVICE_LOCATION_DISTANCE",
          "type": "double",
          "input": "text",
          "operator": "greater",
          "value": "500"
        },
        {
          "id": "DEVICE_LOCATION_DISTANCE",
          "field": "DEVICE_LOCATION_DISTANCE",
          "type": "double",
          "input": "text",
          "operator": "less_or_equal",
          "value": "600"
        }
      ]
    },
    {
      "id": "ADDR_VERIFI_BOTH",
      "field": "ADDR_VERIFI_BOTH",
      "type": "string",
      "input": "select",
      "operator": "equal",
      "value": "U"
    },
    {
      "id": "ADDR_VERIFI_BOTH",
      "field": "ADDR_VERIFI_BOTH",
      "type": "string",
      "input": "select",
      "operator": "equal",
      "value": "Z"
    }
  ]
}';
begin

SELECT NVL(MAX(VRS_RULESET_ID),0)+1 INTO v_rule_set_id FROM vmscms.VMS_RULESET_MAST;

Insert into vmscms.VMS_RULESET_MAST (VRS_RULESET_ID,VRS_RULESET_NAME,VRS_INS_USER,VRS_INS_DATE,VRS_LUPD_USER,VRS_LUPD_DATE)
 values (v_rule_set_id,'TAR RULESET',1,sysdate,null,null);
 
 
SELECT NVL(MAX(VRM_RULE_ID),0)+1 INTO V_RULE_ID FROM vmscms.VMS_RULE_MAST;

Insert into vmscms.vms_rule_mast (VRM_RULE_ID,VRM_RULE_NAME,VRM_RULE_EXP,
VRM_TRANSACTION_TYPE,VRM_ACTION_TYPE,VRM_JSON_REQ,
VRM_INS_USER,VRM_INS_DATE,VRM_LUPD_USER,VRM_LUPD_DATE)
 values (V_RULE_ID,'TAR DECLINE RULE','( 1 OR ( 2 AND 3 ) OR ( 4 AND 5 ) OR ( 6 AND 7 ) OR ( 8 AND 9 ) OR ( 10 AND 11 ) OR 12 OR 13 OR 14 OR 15 OR 16 OR 17 OR 18 OR 19 OR 20 OR 21 OR 22 OR 23 OR 24 OR 25 OR 26 )','5','DECLINE_IF_TRUE',
v_msg,1,sysdate,1,sysdate);



Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,1,'WALLET_ID countGreaterEqual 5',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,2,'WALLET_ID equal 101',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,3,'RISK_ASSESMENT equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,4,'WALLET_ID equal 102',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,5,'RISK_ASSESMENT equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,6,'WALLET_ID equal 103',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,7,'RISK_ASSESMENT equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,8,'WALLET_ID equal 216',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,9,'RISK_ASSESMENT equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,10,'WALLET_ID equal 217',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,11,'RISK_ASSESMENT equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,12,'CHARGE_BACK_COUNT countGreaterEqual 5.30',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,13,'LAST_ACTIVE_PERIOD greater 90',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,14,'DEVICE_ID countGreaterEqual 5',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,15,'DEVICE_SCORE less_or_equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,16,'ACCOUNT_SCORE less_or_equal 2',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,17,'NETWORK_TOKEN_DECISION equal 05',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,18,'TOKEN_SCORE greater_or_equal 75',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,19,'DEVICE_LOCATION_COUNTRY not_equal USA',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,20,'DEVICE_LOCATION_DISTANCE greater 600',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,21,'ADDR_VERIFI_BOTH equal N',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,22,'DEVICE_ID_ADDRESS begins_with 1.6',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,23,'PAN_SOURCE not_equal 01',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,24,'DEVICE_TYPE equal 00',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,25,'TOKEN_STORAGE_TECHNOLOGY equal 06',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,26,'TOKEN_TYPE equal 05',1,sysdate,null,null);



Insert into vmscms.VMS_RULESET_MAST_DETAILS (VSD_RULESET_ID,VSD_RULEID,VSD_INS_USER,VSD_INS_DATE,VSD_LUPD_USER,VSD_LUPD_DATE) 
values (v_rule_set_id,V_RULE_ID,1,sysdate,null,null);


SELECT NVL(MAX(VRM_RULE_ID),0)+1 INTO V_RULE_ID FROM vmscms.VMS_RULE_MAST;

Insert into vmscms.vms_rule_mast (VRM_RULE_ID,VRM_RULE_NAME,VRM_RULE_EXP,
VRM_TRANSACTION_TYPE,VRM_ACTION_TYPE,VRM_JSON_REQ,VRM_INS_USER,
VRM_INS_DATE,VRM_LUPD_USER,VRM_LUPD_DATE) 
values (V_RULE_ID,'TAR CONDITIONAL APPROVAL RULE','( 1 OR ( 2 AND 3 ) OR ( 4 AND 5 ) OR ( 6 AND 7 ) OR ( 8 AND 9 ) OR ( 10 AND 11 ) OR ( 12 AND 13 ) OR ( 14 AND 15 ) OR ( 16 AND 17 ) OR ( 18 AND 19 ) OR ( 20 AND 21 ) OR ( 22 AND 23 ) OR ( 24 AND 25 ) OR ( 26 AND 27 ) OR 28 OR 29 )','5','CONDITIONAL_IF_TRUE',
v_msg1,1,sysdate,1,sysdate);


Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,1,'NETWORK_TOKEN_DECISION equal 85',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,2,'WALLET_ID countLesserEqual 4',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,3,'WALLET_ID countGreaterEqual 3',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,4,'WALLET_ID equal 101',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,5,'RISK_ASSESMENT equal 1',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,6,'WALLET_ID equal 102',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,7,'RISK_ASSESMENT equal 1',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,8,'WALLET_ID equal 103',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,9,'RISK_ASSESMENT equal 1',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,10,'WALLET_ID equal 216',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,11,'RISK_ASSESMENT equal 1',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,12,'WALLET_ID equal 217',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,13,'RISK_ASSESMENT equal 1',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,14,'CHARGE_BACK_COUNT countLesserEqual 4.30',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,15,'CHARGE_BACK_COUNT countGreaterEqual 3.30',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,16,'LAST_ACTIVE_PERIOD greater 30',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,17,'LAST_ACTIVE_PERIOD less_or_equal 90',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,18,'DEVICE_ID countLesserEqual 4',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,19,'DEVICE_ID countGreaterEqual 3',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,20,'DEVICE_SCORE greater_or_equal 3',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,21,'DEVICE_SCORE less_or_equal 4',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,22,'ACCOUNT_SCORE greater_or_equal 3',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,23,'ACCOUNT_SCORE less_or_equal 4',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,24,'TOKEN_SCORE less 75',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,25,'TOKEN_SCORE greater_or_equal 50',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,26,'DEVICE_LOCATION_DISTANCE greater 500',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,27,'DEVICE_LOCATION_DISTANCE less_or_equal 600',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE)
 values (V_RULE_ID,28,'ADDR_VERIFI_BOTH equal U',1,sysdate,null,null);
Insert into vmscms.vms_rule_mast_details (VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,VRD_LUPD_USER,VRD_LUPD_DATE) 
values (V_RULE_ID,29,'ADDR_VERIFI_BOTH equal Z',1,sysdate,null,null);



Insert into vmscms.VMS_RULESET_MAST_DETAILS (VSD_RULESET_ID,VSD_RULEID,VSD_INS_USER,VSD_INS_DATE,VSD_LUPD_USER,VSD_LUPD_DATE)
 values (v_rule_set_id,V_RULE_ID,1,sysdate,null,null);
 
 commit;


end;
/







