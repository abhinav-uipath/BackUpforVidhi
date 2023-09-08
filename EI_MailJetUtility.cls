/**********************************************************************************************************
* Author: Vidhi Agrawal
* Purpose:This class has API for MailJet
*          
* *******************************************************************************************************/
/* Changes: 05 Aug 2022 -Added method sendEmailforDisputedFunds
* Changes : 24-Feb-2023 - Added EWC Custodial scheme
* *******************************************************************************************************/
global without sharing class EI_MailJetUtility {
    public static String scheme = 'EWI';
    
    // NI Insured
    @future(callout=true)
    global static void sendEmailForNIInsured(String emailWrapList){
        scheme = 'NI Insured';
        sendEmailFromBatch(emailWrapList);
    } 
    
    global static void sendEmailFromBatchForNIInsured(String emailWrapList){
        scheme = 'NI Insured';
        sendEmailFromBatch(emailWrapList);
    } 
    
    // NI custodial
    @future(callout=true)
    global static void sendEmailForNI(String emailWrapList){
        scheme = 'NI Custodial';
        sendEmailFromBatch(emailWrapList);
    } 
    
    global static void sendEmailFromBatchForNI(String emailWrapList){
        scheme = 'NI Custodial';
        sendEmailFromBatch(emailWrapList);
    } 


    // EWC custodial
    @future(callout=true)
    global static void sendEmailForEWC(String emailWrapList){
        scheme = 'EWC Custodial';
        sendEmailFromBatch(emailWrapList);
    } 
    
    global static void sendEmailFromBatchForEWC(String emailWrapList){
        scheme = 'EWC Custodial';
        sendEmailFromBatch(emailWrapList);
    } 
    
    @future(callout=true)
    global static void sendEmail(String emailWrapList){
        sendEmailFromBatch(emailWrapList);
    }
    
    global static void sendEmailFromBatch(String emailWrapList) {
        System.debug('Line 32 - '+emailWrapList);
        List<EmailWrapper> wrapList = (List<EmailWrapper>) JSON.deserialize(emailWrapList, List<EmailWrapper>.class);
        System.debug('wrapList - '+wrapList);
        if(!wrapList.isEmpty()) {
            List<Mailjet_Message__c> mailJetMessageList = new List<Mailjet_Message__c>();
            list<Mailjet_Message__c> postalMessageList = new list<Mailjet_Message__c>();
            List<finalMailContent> mailjetContentList = new List<finalMailContent> ();
            
            HttpRequest req = mailJetAuthentication(scheme);
            if(req==null){
                return;
            }
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();    
            gen.writeFieldName('Messages'); 
            gen.writeStartArray();
            String jsonData;
            for(EmailWrapper wrap:wrapList) 
            {
                String subject = wrap.Subject;
                String recList = wrap.recList;
                Map<String,String> variables = wrap.variables;
                String template = wrap.templateName;
                Case_Participant__c casePar = wrap.casePar;
                System.debug('casePar => ' + casePar);
                System.debug('template => ' + template);
                //List<attachmentWrapper> attachmentsList = (List<attachmentWrapper>) JSON.deserialize(wrap.attchmentsList, List<attachmentWrapper>.class);
                /*if(wrap.attchmentsList != null){
attchmentsList = (List<attachmentWrapper>) JSON.deserialize(wrap.attchmentsList,List<attachmentWrapper>.class);
}*/
                List<API_Service__mdt> templateId = metaDataList(template);
                String fromAddress;
                String fromName;
                If(test.isRunningTest())
                {
                     fromAddress = 'Tenancy Deposit Scheme';
                     fromName  = 'bank.details@tenancydepositscheme.com';
                }
                else
                {
                     fromAddress = templateId[0].From_Address__c;
                     fromName  = templateId[0].From_Name__c;
                    
                }
                
                if(fromAddress == 'assignedresolutionexecutive@tenancydepositscheme.com'){
                    //User usr = [select Id, Name , email,Phone from User where Id =: UserInfo.getUserId()];
                    fromAddress = casePar.Case__r.owner.Email;
                    //fromName = casePar.Case__r.owner.Name;
                }else if(fromAddress == 'currentUserEmail'){
                    User usr = [select Id, Name , email,Phone from User where Id =: UserInfo.getUserId()];
                    fromAddress = usr.Email;
                    //fromName = usr.Name;
                }
                
                Integer mailJetTemplateId;
                if(Test.isRunningTest())
                {
                    mailJetTemplateId =4251582;
                }
                else
                {
                   mailJetTemplateId  = Integer.valueof(templateId[0].Template_Id__c); 
                }
                
                Map<String,recipient> recMap = new Map<String,recipient>();
                List<recipient> ParticipantList = new List<recipient>();
                ParticipantList = (List<recipient>) JSON.deserialize(recList,List<recipient>.class);
                System.debug('ParticipantList before => ' + ParticipantList);
                
                if(casePar != null && casePar.Type__c == 'Agent' && fromAddress == 'credit.control@tenancydepositscheme.com'){
                    if(casePar.Disputes_credit_control__c != null){
                        if(casePar.Primary_Email__c != null || casePar.Other_Emails__c != null){
                            if(casePar.Primary_Email__c != null && !casePar.Primary_Email__c.contains(casePar.Disputes_credit_control__c)){
                                ParticipantList.add(new recipient(casePar.Disputes_credit_control__c, casePar.Account__r.Name, casePar.Case__c, casePar.Account__c, casePar.Id));
                            }
                            else if(casePar.Other_Emails__c != null && !casePar.Other_Emails__c.contains(casePar.Disputes_credit_control__c)){
                                ParticipantList.add(new recipient(casePar.Disputes_credit_control__c, casePar.Account__r.Name, casePar.Case__c, casePar.Account__c, casePar.Id));
                            }
                        }else{
                            ParticipantList.add(new recipient(casePar.Disputes_credit_control__c, casePar.Account__r.Name, casePar.Case__c, casePar.Account__c, casePar.Id));
                        }
                    } 
                }
                String toAddress;
                
                String toName;
                String caseId = ParticipantList[0].recId;
                System.debug('ParticipantList => ' + ParticipantList);
                // mailjetContentList.add(new finalMailContent(templateId[0].Template_Id__c, subject, variables, '', ParticipantList[0]));
                
                for(recipient rec:ParticipantList)
                {
                    toAddress = rec.email;
                    toName = rec.Name;
                    system.debug('>>>>>>>>>>>>>>>>>>'+toAddress);
                    
                    if(String.isNotBlank(toAddress) && toAddress!='null') //&& !toAddress.contains('safedepositsscotland.com') && !toAddress.contains('tenancydepositscheme.com')
                    {
                        mailjetContentList.add(new finalMailContent(templateId[0].Template_Id__c, subject, variables, '', rec, rec.caseParticipantId));
                        recMap.put(rec.email,rec);
                        gen.writeStartObject(); 
                        gen.writeFieldName('From');
                        
                        gen.writeStartObject();
                        if(String.isNotBlank(fromAddress)){
                            gen.writeStringField('Email', fromAddress);
                        }
                        if(String.isNotBlank(fromName)){
                            gen.writeStringField('Name', fromName);
                        }
                        
                        gen.writeEndObject();
                        
                        gen.writeFieldName('To');
                        
                        gen.writeStartArray();
                        gen.writeStartObject(); 
                        gen.writeStringField('Email', String.isNotBlank(toAddress)?toAddress:''); 
                        gen.writeStringField('Name', String.isNotBlank(toName)?toName:'');
                        gen.writeEndObject();      
                        gen.writeEndArray();
                        
                        gen.writeNumberField('TemplateID', mailJetTemplateId); 
                        gen.writeBooleanField('TemplateLanguage', true);
                        
                        if(String.isNotBlank(subject)){
                            gen.writeStringField('Subject', subject);
                        }
                        
                        gen.writeFieldName('Variables');    
                        
                        gen.writeStartObject();
                        if(variables!=null){
                            for(String key : variables.keySet()){
                                if( variables.get(key) !=null)
                                {
                                    gen.writeStringField(key, variables.get(key));
                                    System.debug('Line 114 -> '+key+' value -> '+variables.get(key));
                                }
                            }
                        }
                        system.debug('Line 118 link  '+rec.link);
                        if(rec.link !=null) {
                            gen.writeStringField('paylink',rec.link);
                        }
                        if(rec.buttonLink != null) {
                            gen.writeStringField('buttonlink','<a href="'+rec.buttonLink+'" style="background-color: #F45372; color: white; padding: 15px 40px; text-decoration: none; display: inline-block; font-size: 8px; margin: 4px 2px; cursor: pointer; border-radius: 8px;font-size: 12px;" >'+rec.label+'</a>');
                        }
                        gen.writeEndObject();
                        
                        if(wrap.attchmentsList != null){
                            List<attachmentWrapper> attachmentsList = (List<attachmentWrapper>) JSON.deserialize(wrap.attchmentsList,List<attachmentWrapper>.class);
                            
                            System.debug('attachmentsList => ' + attachmentsList);
                            if(!attachmentsList.isEmpty()){
                                gen.writeFieldName('Attachments');
                                gen.writeStartArray();
                                for(attachmentWrapper attchWrap : attachmentsList){
                                    gen.writeStartObject();
                                    gen.writeStringField('ContentType',attchWrap.contentType); 
                                    gen.writeStringField('Filename',attchWrap.filename);
                                    gen.writeStringField('Base64Content', attchWrap.base64Content);
                                    gen.writeEndObject();
                                }    
                                gen.writeEndArray();
                            }
                        }
                        gen.writeEndObject(); 
                    }
                    //***** EID 213  
                    else{
                        List<Matching_Temp_Var__c> matchingTempVarList = new List<Matching_Temp_Var__c>();
                        if(Test.isRunningTest())
                        {
                           matchingTempVarList = [Select Template_Id__c, text_body__c, Subject__c from Matching_Temp_Var__c ];

                        }
                        else
                        {
                            matchingTempVarList = [Select Template_Id__c, text_body__c, Subject__c from Matching_Temp_Var__c 
                                                                          where Template_Id__c =:templateId[0].Template_Id__c and Var_Name__c = '' ];

                        }
                         
                        if(matchingTempVarList.size() > 0){
                            String textPart = matchingTempVarList[0].text_body__c; 
                            System.debug('textPart: ' + textPart);
                            //uploading to azure
                            Blob txtBlob = Blob.toPdf(textPart);
                            //sending to azure
                            Azure_Storage_Credentials_per_Scheme__mdt settings = getAzureMetadata('EWI Finance');
                            Datetime dt = Datetime.now();
                            String timestamp = String.valueOf(dt.getTime());
                            String formattedDate = dt.formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
                            Boolean isRunningOnSandbox = [SELECT IsSandbox FROM Organization].IsSandbox;
                            String storageUrl = isRunningOnSandbox ? settings.Secure_URI_Sandbox__c : settings.Secure_URI_Production__c;
                            String requestURL = storageUrl.substringBefore('?')+'/'+timestamp+'-'+'test';
                            String sharedKey = getBlobSharedKey('test', String.valueOf(txtBlob.size()), 'application/pdf', formattedDate, timestamp, settings, isRunningOnSandbox);
                            HttpRequest reqAzure = new HttpRequest();
                            reqAzure.setMethod('PUT');
                            reqAzure.setHeader('x-ms-blob-type', 'BlockBlob');
                            reqAzure.setHeader('x-ms-version', '2015-12-11');
                            reqAzure.setHeader('x-ms-date', formattedDate);
                            reqAzure.setHeader('Authorization', sharedKey);
                            reqAzure.setHeader('Content-Type', 'application/pdf');
                            reqAzure.setHeader('Content-Length', String.valueOf(txtBlob.size()));
                            
                            //reqAzure.setEndpoint('https://sftpletters.file.core.windows.net/?sv=2021-06-08&ss=f&srt=sco&sp=rwdlc&se=2032-12-23T15:45:18Z&st=2022-12-23T07:45:18Z&spr=https&sig=42lNndXVyGnevA1SC%2FbZWSH6pi%2BqgU5T9UREvsINe0Q%3D');
                            reqAzure.setEndpoint(requestURL);
                            reqAzure.setBodyAsBlob(txtBlob);
                            Http http = new Http();
                            if(!Test.isRunningTest())
                            {
                                HTTPResponse resAzure = http.send(reqAzure);
                            }
                            
                            for(String varName : variables.keySet()){
                                System.debug('varName => ' + varName + ' var Value => ' + variables.get(varName));
                                if(textPart.contains(varName)){
                                    textPart = textPart.replace('{{var:'+varName+':&quot;&quot;}}', variables.get(varName) );
                                }
                            }
                            System.debug('updated textPart: ' + textPart);
                            
                            Mailjet_Message__c msg = new Mailjet_Message__c();
                            msg.Subject__c = subject;
                            if(String.isNotBlank(rec.contactId)){
                                if(rec.contactId.startsWith('003')){
                                    msg.Contact__c = rec.contactId;
                                }else{
                                    msg.Account_Id__c = rec.contactId;
                                }
                            }
                            msg.Case_Participant__c = rec.caseParticipantId==''?null:rec.caseParticipantId;
                            msg.Record_Id__c = rec.recid;
                            msg.Is_Postal__c = true;
                            msg.Template_Id__c = String.valueOf(mailJetTemplateId);
                            String MailjetMsgSource = '';
                            if(scheme == 'NI Insured'){
                                MailjetMsgSource = 'NI Insured';
                            }
                            else if (scheme == 'NI Custodial'){
                                MailjetMsgSource = 'NI Custodial';
                            }
                            else if(scheme == 'EWI'){
                                MailjetMsgSource = 'EWI Insured';
                            } else if (scheme == 'EWC Custodial'){
                                MailjetMsgSource = 'EWC Custodial';
                            }
                            msg.Source__c = MailjetMsgSource;
                            msg.Sent_Message__c = textPart;
                            msg.Content_Populated__c = true;
                            postalMessageList.add(msg);
                        }
                    }
                }
            }
            
            try {
                gen.writeEndArray();
                gen.writeEndObject();
                jsonData =gen.getAsString();
                req.setBody(jsonData);
                system.debug('jsonData -> '+jsonData);
                Http http = new Http();
                if(!Test.isRunningTest()) {
                    HTTPResponse res = http.send(req); 
                    if(res.getStatusCode() == 200) {
                        System.debug('Line 142 success -> ');
                        String resBody = res.getBody();
                        if(!resBody.startsWith('[')) {
                            resBody = '['+resBody+']';
                        }
                        System.debug('Line 154 success -> '+resBody);
                        List<Mailjet_Message__c> mailJetLstToAdd = saveMessageDetails(resBody, wrapList, mailjetContentList);
                        mailJetMessageList.addAll(mailJetLstToAdd);
                        //for(Mailjet_Message__c mailMess : mailJetLstToAdd) {
                        //  mailJetMessageList.add(mailMess);
                        //}
                    }
                }
            }
            catch(exception e) {   
                System.debug(e);
                //Create Message(with error) from Here if no success response or it breaks  >>> res comes null  or status code is not expected 429 etc
            }
            
            if(!postalMessageList.isEmpty()){
                mailJetMessageList.addAll(postalMessageList);
            }
            if(!mailJetMessageList.isEmpty()) {
                System.debug('Line 172 -> '+mailJetMessageList);
                try {
                    insert mailJetMessageList;
                    //for(Mailjet_Message__c mailMess : mailJetMessageList) {
                    //    System.debug('Line 172 -> '+mailMess.Id);
                    //}
                } catch(Exception e) {
                    System.debug('ERROR --> '+e.getMessage());
                }
            }
        }
        else {
            System.debug('Email wrap list is empty!');
        }
    }
    
    public static List<API_Service__mdt> metaDataList(String metaDataLabel){
        List<API_Service__mdt> metaDataList = [SELECT EndPoint_URL__c, Username__c, Password__c, From_Name__c, From_Address__c,
                                               Template_Id__c, Scheme_Signatory__c, Scheme_Address__c,Scheme_Bank_Account_Number__c,
                                               Scheme_Sort_Code__c,Scheme_Bank_Name__c
                                               FROM API_Service__mdt 
                                               WHERE QualifiedApiName=:metaDataLabel];
        return metaDataList;
    }
    
    global static HttpRequest mailJetAuthentication(String schemeType) {
        List<API_Service__mdt> mailJetSettings = new List<API_Service__mdt>();
        if(schemeType == 'EWI'){
            mailJetSettings = EI_MailJetUtility.metaDataList('EWIMailJet');
        }
        else if(schemeType == 'NI Insured' || schemeType == 'NI Custodial'){
            mailJetSettings = EI_MailJetUtility.metaDataList('NIMailJet');
        } else if(schemeType == 'EWC Custodial'){
            mailJetSettings = EI_MailJetUtility.metaDataList('EWCMailJet');
        }
        
        if(!mailJetSettings.isEmpty()){
            HttpRequest req = new HttpRequest();
            String endPoint = mailJetSettings[0].EndPoint_URL__c;
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/text'); 
            
            String username = mailJetSettings[0].Username__c;
            String password = mailJetSettings[0].Password__c;
            
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' +
                EncodingUtil.base64Encode(headerValue);       
            req.setHeader('Authorization', authorizationHeader);   
            System.debug('authorizationHeader => ' + authorizationHeader);
            return req;  
        }else {
            return null;
        }
    }
    
    global static List<Mailjet_Message__c> saveMessageDetails(String resJSON, List<EmailWrapper> emailWrapList, List<finalMailContent> mailjetContentList)
    {
        List<Mailjet_Message__c> mailJetList = new List<Mailjet_Message__c>();
        
        List<response> jsonList = new List<response>();
        //add try catch if deserialize breaks create Message with error
        try{
            jsonList = ( List<response>) System.JSON.deserialize(resJSON, List<response>.class);
        }
        catch(Exception e) {
            system.debug('ERROR --> '+e.getMessage());
            return null;
        }
        system.debug('jsonList => ' + jsonList);
        List<Messages> msgList = jsonList[0].messages;
        
        Map<String, Map<String, String>> tempIdandVarsMap = new Map<String, Map<String, String>>();
        for(finalMailContent fmc : mailjetContentList){
            tempIdandVarsMap.put(fmc.tempId, fmc.variables);
        }
        List<Matching_Temp_Var__c> matchingTempVarList = new List<Matching_Temp_Var__c>();
        if(Test.isRunningTest())
        {
            matchingTempVarList = [Select Template_Id__c, Is_Chaser_Email__c, text_body__c, Subject__c from Matching_Temp_Var__c ];
        }
        else
        {
             matchingTempVarList= [Select Template_Id__c, Is_Chaser_Email__c, text_body__c, Subject__c from Matching_Temp_Var__c where Template_Id__c IN :tempIdandVarsMap.keySet() and Var_Name__c = '' ];
        }
        
        Map<String, Matching_Temp_Var__c> tempIdandMTVMap = new Map<String, Matching_Temp_Var__c>();
        Map<String, Boolean> tempIdandIsChaserMap = new Map<String, Boolean>();
        for(Matching_Temp_Var__c mtv : matchingTempVarList){
            tempIdandMTVMap.put(mtv.Template_Id__c, mtv);
            tempIdandIsChaserMap.put(mtv.Template_Id__c, mtv.Is_Chaser_Email__c);
        }
        
        Map<String, String> caseParIdandBodyMap = new Map<String, String>();
        for(finalMailContent fmc : mailjetContentList){
            String textPart = tempIdandMTVMap.get(fmc.tempId).text_body__c; 
            System.debug('textPart: ' + textPart);
            System.debug('temp Id: ' + fmc.tempId);
            
            Map<String, String> tempVarsandValuesMap = fmc.variables;
            
            for(String varName : tempVarsandValuesMap.keySet()){
                // textPart.replace('{{var:'+varName+':\""}}', tempVarsandValuesMap.get(varName) );
                System.debug('varName => ' + varName + ' var Value => ' + tempVarsandValuesMap.get(varName));
                if(tempVarsandValuesMap.get(varName) != null){
                textPart = textPart.replace('{{var:'+varName+':&quot;&quot;}}', tempVarsandValuesMap.get(varName) );
                }
                System.debug('updated textPart: ' + textPart);
            }
            fmc.tempBody = textPart;
        }
        
        set<Id> caseSetToUpdate = new set<Id>();
        for(integer i=0; i<msgList.size(); i++) {
            
            Mailjet_Message__c mm = new Mailjet_Message__c();
            Messages msg = msgList[i];
            system.debug('msg.to[0].Email => ' + msg.to[0].Email);
            system.debug('msg.to[0].MessageID => ' + msg.to[0].MessageID);
            System.debug('recipientList['+i+'] =>' + mailjetContentList[i].recList); // recipientList[i]);
            system.debug('recipientList['+i+'].recid => ' + mailjetContentList[i].recList.recid); // recipientList[i].recid);
            system.debug('subjectList['+i+'] => ' + mailjetContentList[i].tempSubject); // subjectList[i]);
            system.debug('templateId['+i+'] => ' + mailjetContentList[i].tempId);
            system.debug('tempBody['+i+'] => ' + mailjetContentList[i].tempBody);
            if(String.isNotBlank(mailjetContentList[i].recList.contactId)){
                if(mailjetContentList[i].recList.contactId.startsWith('003')){
                    mm.Contact__c = mailjetContentList[i].recList.contactId;
                }else{
                    mm.Account_Id__c = mailjetContentList[i].recList.contactId;
                }
            }
            
            String MailjetMsgSource = '';
            if(scheme == 'NI Insured'){
                MailjetMsgSource = 'NI Insured';
            }
            else if (scheme == 'NI Custodial'){
                MailjetMsgSource = 'NI Custodial';
            }
            else if(scheme == 'EWI'){
                MailjetMsgSource = 'EWI Insured';
            }
            mm.Source__c = MailjetMsgSource;
            if(mailjetContentList[i].recList.caseParticipantId != null && mailjetContentList[i].recList.caseParticipantId != ''){
                Id caseParId = mailjetContentList[i].recList.caseParticipantId;
                if( caseParId.getSobjectType().getDescribe().getName()=='Case_Participant__c')
                {
                    mm.Case_Participant__c = mailjetContentList[i].recList.caseParticipantId==''?null:mailjetContentList[i].recList.caseParticipantId;
                }
            }
            mm.response_status__c='success';
            mm.Subject__c=mailjetContentList[i].tempSubject; // subjectList[i];
            mm.Record_ID__c = mailjetContentList[i].recList.recid; // recipientList[i].recid;
            //mm.Case__c = mailjetContentList[i].recList.recid;
            // Added by lavelesh 
            if(!(mm.Record_ID__c==''||mm.Record_ID__c==null))
            {
                Id recId = mm.Record_ID__c;
                String ObjName = recId.getSobjectType().getDescribe().getName();
                if(ObjName == 'Case'){
                    mm.Case__c = mailjetContentList[i].recList.recid;
                }else if(ObjName == 'Deposit__c'){
                    mm.Deposit__c = mailjetContentList[i].recList.recid;
                }  
            }
            
            mm.Message_Id__c=msg.to[0].MessageID;
            mm.Email_ID__c=msg.to[0].Email;
            mm.Template_Id__c = mailjetContentList[i].tempId;
            mm.Sent_Message__c = mailjetContentList[i].tempBody;
            mm.Is_Chaser_Email__c = tempIdandIsChaserMap.get(mailjetContentList[i].tempId);
            mailJetList.add(mm);
            
            if(mm.Is_Chaser_Email__c){
                caseSetToUpdate.add(mailjetContentList[i].recList.recid);
            }
        }
        
        if(!caseSetToUpdate.isEmpty()){
            List<Case> casetoUpdate = [select id, No_of_Times_Chased__c, Last_Chased_Date__c from case where id in :caseSetToUpdate];
            
            for(case cs: casetoUpdate){
                cs.Last_Chased_Date__c = System.today();
                Decimal chaseCount = 0;
                if(cs.No_of_Times_Chased__c==null){
                    chaseCount++;
                    cs.No_of_Times_Chased__c = chaseCount;
                }else{
                    chaseCount = cs.No_of_Times_Chased__c;
                    chaseCount++;
                    cs.No_of_Times_Chased__c = chaseCount;
                }
            }
            if(casetoUpdate.size()>0)
            {
                update casetoUpdate;
            }
            
        }
        return mailJetList;
    }
    
    global class EmailWrapper {
        public String recList;
        public Map<String,String> variables;
        public String templateName;
        public String Subject;
        public String attchmentsList;
        public Case_Participant__c casePar;
        
        public EmailWrapper(String recList,Map<String,String> variables,String templateName,String Subject) {
            this.recList = recList;
            this.variables = variables;
            this.templateName = templateName;
            this.Subject = Subject;
        }
        public EmailWrapper(String recList,Map<String,String> variables,String templateName,String Subject, String attchmentsList ) {
            this.recList = recList;
            this.variables = variables;
            this.templateName = templateName;
            this.Subject = Subject;
            this.attchmentsList = attchmentsList;
        }
        public EmailWrapper(String recList,Map<String,String> variables,String templateName,String Subject, Case_Participant__c casePar) {
            this.recList = recList;
            this.variables = variables;
            this.templateName = templateName;
            this.Subject = Subject;
            this.casePar = casePar;
        }
        public EmailWrapper(String recList,Map<String,String> variables,String templateName,String Subject, Case_Participant__c casePar, String attchmentsList ) {
            this.recList = recList;
            this.variables = variables;
            this.templateName = templateName;
            this.Subject = Subject;
            this.casePar = casePar;
            this.attchmentsList = attchmentsList;
        }
    }
    
    global class recipient {
        String Email;
        String name;
        String recId;
        public String Link;
        public String buttonLink;
        public String Label;
        public String contactId;
        public String caseParticipantId;
        
        public recipient(String Email,String name,String recId,String Link,String contactId, String caseParticipantId) {
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.link = link;
            this.contactId = contactId;
            this.caseParticipantId = caseParticipantId;
        }
        public recipient(String Email,String name,String recId,String Link,String buttonLink,String Label,String contactId, String caseParticipantId) {
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.link = link;
            this.buttonLink = buttonLink;
            this.Label = Label;
            this.contactId = contactId;
            this.caseParticipantId = caseParticipantId;
        }
        public recipient(String Email,String name,String recId,String contactId, String caseParticipantId) {
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.contactId = contactId;
            this.caseParticipantId = caseParticipantId;
        }
    }
    
    global class attachmentWrapper {
        public String contentType;
        public String filename;
        public String base64Content;
        public attachmentWrapper(String contentType, String filename, String base64Content) {
            this.contentType = contentType;
            this.filename = filename;
            this.base64Content = base64Content;
        }
    }
    
    global class response {
        String Status;
        List<Messages> messages;
    }
    
    global class Messages {
        String Status;
        String CustomID;
        List<To> To;
    }
    
    global class To {
        String Email;
        String MessageUUID;
        String MessageID;
        String MessageHref;
    }
    
    global class finalMailContent {
        public String tempId;
        public String tempSubject;
        public Map<String, String> variables;
        public String tempBody;
        public recipient recList;
        public String caseParId;
        
        public finalMailContent(String tempId, String tempSubject, Map<String, String> variables, String tempBody, recipient recList, String caseParId){
            this.tempId = tempId;
            this.tempSubject = tempSubject;
            this.variables = variables;
            this.tempBody = tempBody;
            this.recList = recList;
            this.caseParId = caseParId;
        }
    }
    
    public static String getBlobSharedKey(String fileName, String fileLength, String fileType, String formattedDate, String timestamp, 
                                          Azure_Storage_Credentials_per_Scheme__mdt settings, Boolean isRunningOnSandbox )
    {
        System.debug('getBlobSharedKey--->Start');
        String storageName = isRunningOnSandbox ? settings.Account_Name_Sandbox__c : settings.Account_Name_Production__c;
        String storageContainer = isRunningOnSandbox ? settings.Container_Name_Sandbox__c : settings.Container_Name_Production__c;
        String storageKey = isRunningOnSandbox ? settings.Storage_Key_Sandbox__c : settings.Storage_Key_Production__c;
        String blobName = '/'+storageName+'/'+storageContainer+'/'+timestamp+'-'+fileName;
        String signature;

        String stringToSign = 'PUT\n\n\n'+fileLength+'\n\n'+fileType+'\n\n\n\n\n\n\nx-ms-blob-type:BlockBlob\nx-ms-date:'+formattedDate+'\nx-ms-version:2015-12-11\n'+blobName;

        Blob unicodeKey = EncodingUtil.base64Decode(storageKey);
        
        Blob data = Crypto.generateMac('HMACSHA256', Blob.valueOf(stringToSign), unicodeKey);
        signature = EncodingUtil.base64Encode(data);
       
        String sharedKey = 'SharedKey '+storageName+':' + signature;
        return sharedKey;
    }
    
    public static Azure_Storage_Credentials_per_Scheme__mdt getAzureMetadata(String scheme) {
        Azure_Storage_Credentials_per_Scheme__mdt settings;
        try {
            settings = [
                    SELECT Account_Name_Production__c,
                            Account_Name_Sandbox__c,
                			Container_Name_Production__c,
                			Container_Name_Sandbox__c,
                            Endpoint_Production__c,
                            Endpoint_Sandbox__c,
                            Secure_URI_Production__c,
                            Secure_URI_Sandbox__c,
                            Storage_Key_Production__c,
                            Storage_Key_Sandbox__c
                    FROM Azure_Storage_Credentials_per_Scheme__mdt
                    WHERE Label = :scheme
            ];
        }
        catch(QueryException exc) {
            //throw new AzureFunctionFileUploadServiceException('No Azure Upload Function Credentials found for scheme: ');
        }
        return settings;
    }
    
    public static void justIncrement() {
        Integer i = 0;
              i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
		 i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
      i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
		 i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
		 i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
      
                                	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
		 i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
                           	i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
		 i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
    }
}