

INSERT INTO vmscms.VMS_FSAPI_DTLS(VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL)
VALUES (1,'VCVALIDATION','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~encryptedString:encryptedString','responseCode:responseCode~responseMessage:responseMessage~PAN:PAN~expirationDate:expirationDate~CVV2:CVV2~status:status~expiryDateUpdateFlag:expiryDateUpdateFlag~customerID:customerID','/b2b/cards/validation');

INSERT INTO vmscms.VMS_FSAPI_DTLS(VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL)
VALUES (1,'SERIALNOACTIVATION','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~serialnumber:serialnumber~activationCode:activationCode','responseCode:responseCode~responseMessage:responseMessage~PAN:PAN~expirationDate:expirationDate~CVV2:CVV2~status:status~customerID:customerID','/b2b/cards/{serialnumber}/serialnumberactivation');


INSERT INTO vmscms.VMS_FSAPI_DTLS(VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL)
VALUES (1,'PROXYNOACTIVATION','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~proxynumber:proxynumber~activationCode:activationCode','responseCode:responseCode~responseMessage:responseMessage~PAN:PAN~expirationDate:expirationDate~CVV2:CVV2~status:status~customerID:customerID','/b2b/cards/{proxynumber}/proxynumberactivation');


Insert into vmscms.VMS_FSAPI_DTLS (VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL) 
values (1,'RELOAD_POSTBACK',
'x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~cards:cards~type:type~value:value~denomination:denomination~comments:comments~merchantId:merchantId~postBackResponse:postBackResponse~postBackURL:postBackURL',
'cards:cards,serialNumber;serialNumber,proxyNumber;proxyNumber,availableBalance;availableBalance,responseCode;responseCode,responseMessage;responseMessage,type;type,value;value,denomination;denomination,comments;comments','/b2b/cards/reload');

Insert into vmscms.VMS_FSAPI_DTLS (VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL) 
values (1,'RELOAD','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~cards:cards~type:type~value:value~denomination:denomination~comments:comments~merchantId:merchantId~postBackResponse:postBackResponse~postBackURL:postBackURL','responseCode:responseCode~responseMessage:responseMessage','/b2b/cards/reload');


Insert into vmscms.VMS_FSAPI_DTLS (VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL,VFD_SUBTAG_RESPFIELD,VFD_SUBTAG_REQFIELD) values (1,'ORDER','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~orderID:orderID~merchantID:merchantID~orderShipState:orderShipState~postBackResponse:postBackResponse~postBackURL:postBackURL~acceptPartialOrders:acceptPartialOrders~activationCode:activationCode~programID:programID~shippingMethod:shippingMethod~shippingFee:shippingFee~shipToCompanyName:shipToCompanyName~firstName:firstName~middleInitial:middleInitial~lastName:lastName~phone:phone~email:email~shipToAddress:shipToAddress~lineItem:lineItem','orderID:orderID~status:status~responseCode:responseCode~responseMessage:responseMessage~lineItem:lineItem','/b2b/orders','lineItem,lineItemID:lineItemID,responseCode:responseCode,responseMessage:responseMessage','lineItem,lineItemID:lineItemID,denomination:denomination,embossedLine:embossedLine,embossedLine1:embossedLine1,productID:productID,packageID:packageID,offerCode:offerCode,quantity:quantity~shipToAddress,addressLine1:addressLine1,addressLine2:addressLine2,addressLine3:addressLine3,city:city,state:state,postalCode:postalCode,country:country');
Insert into vmscms.VMS_FSAPI_DTLS (VFD_INST_CODE,VFD_API_NAME,VFD_REQ_FIELDS,VFD_RES_FIELDS,VFD_API_URL,VFD_SUBTAG_RESPFIELD,VFD_SUBTAG_REQFIELD) values (1,'ORDERSTATUS','x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~lineItemID:lineItemID~orderID:orderID','orderID:orderID~status:status~responseCode:responseCode~responseMessage:responseMessage~lineItem:lineItem','/b2b/orders/{OrderID}/status','cards,proxyNumber:proxyNumber,pin:pin,encryptedString:encryptedString,serialNumber:serialNumber,status:status,trackingNumber:trackingNumber,shippingDateTime:shippingDateTime~lineItem,lineItemID:lineItemID,responseCode:responseCode,responseMessage:responseMessage,status:status,cards:cards',null);

update vmscms.VMS_FSAPI_DTLS set 
 vfd_res_fields='cards:cards',
 VFD_SUBTAG_RESPFIELD ='cards,
 serialNumber:serialNumber,proxyNumber:proxyNumber,availableBalance:availableBalance,responseCode:responseCode,responseMessage:responseMessage,type:type,value:value,denomination:denomination,comments:comments' where vfd_api_name='RELOAD_POSTBACK';
update vmscms.VMS_FSAPI_DTLS 
set vfd_req_fields='x-incfs-date:x-incfs-date~x-incfs-ip:x-incfs-ip~x-incfs-channel:x-incfs-channel~x-incfs-channel-identifier:x-incfs-channel-identifier~x-incfs-username:x-incfs-username~x-incfs-correlationid:x-incfs-correlationid~apikey:apikey~partnerid:partnerid~cards:cards~merchantId:merchantId~postBackResponse:postBackResponse~postBackURL:postBackURL',VFD_SUBTAG_REQFIELD='cards,type:type,value:value,denomination:denomination,comments:comments' where vfd_api_name='RELOAD';


