public without sharing class EI_EWI_SendManualEmailCls {
    
    public static List<Holiday> holidayList;
    public static List<String> attachmentList = new List<String>();
    
    @AuraEnabled
    public static String saveAttachments(String attachment){
       String str = attachment;
        system.debug('attachment>>>>>>'+str);
        return str;
    }
   
    @AuraEnabled
    public static void sendEmailsofList(string emailDetails){
        System.debug('Enterd in sendEmailofList');
        System.Debug('email List Details String => ' + emailDetails);
        List<emailDetailsWrapper> emailList = (List<emailDetailsWrapper>) System.JSON.deserialize(emailDetails, List<emailDetailsWrapper>.class);
        System.Debug('email List wrapper => ' + emailList);
        for(emailDetailsWrapper email : emailList){
            System.Debug('email CaseId  => ' + email.caseId);
            System.Debug('email fromEmail => ' + email.fromEmail);
            System.Debug('email to => ' + email.to);
            System.Debug('email mailBody => ' + email.mailbody);
            System.Debug('email Subject => ' + email.subject);
            System.Debug('email uploadedFiles => ' + email.uploadedFiles);
        }
    }
    
    public class emailDetailsWrapper {
        @AuraEnabled 
        public String CaseId { get; set; } 
        @AuraEnabled 
        public String fromEmail { get; set; }
        @AuraEnabled 
        public String to { get; set; }
        @AuraEnabled 
        public String mailBody { get; set; }
        @AuraEnabled 
        public String subject { get; set; }
        @AuraEnabled 
        public List<String> uploadedFiles { get; set; }     
    }

    //temprary testing method 
    @AuraEnabled
    public static List<Map<String, String>> getAllMetaDataList(){
        List<Map<String, String>> listToreturn = new List<Map<String, String>>();
        
        List<Matching_Temp_Var__c> getAllTemplates = [Select Template_Id__c, Custom_Metadata_Label__c, text_body__c, Subject__c from Matching_Temp_Var__c where Var_Name__c = '' and Scheme__c = 'EWI' ]; 
        for(Matching_Temp_Var__c mtv : getAllTemplates){
            Map<String, String> IdAndLabelMap = new Map<String, String>();
            IdAndLabelMap.put('Template_Id__c' , mtv.Template_Id__c); 
            IdAndLabelMap.put('Label', mtv.Custom_Metadata_Label__c); 
            listToreturn.add(IdAndLabelMap);
        }
        
        return listToreturn;
    }
    
    public static HttpRequest mailJetAuthentication(){
        List<API_Service__mdt> mailJetSettings = metaDataListbyLabel('EWIMailJet');
        
        HttpRequest req = new HttpRequest();
        String endPoint = mailJetSettings[0].EndPoint_URL__c; // String endPoint = 'https://api.mailjet.com/v3.1/send';
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/text'); 
        
        String username = mailJetSettings[0].Username__c; // String username = '149e22044add6860160c56c12a500708';   // SDS
        String password = mailJetSettings[0].Password__c; // String password = '3bc9ecf441468a0dee61982308eb7fb7';
       
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);       
        System.debug('authorizationHeader : ' + authorizationHeader);
        req.setHeader('Authorization', authorizationHeader);   
        return req;      
    }
    
    @AuraENabled
    public static manualEmailWrapper getMailJetTextBody(Integer tempId, String toEMail, Id recordId, Id toRecAccId, Id toCaseParId){
        List<API_Service__mdt> mailJetSettings = metaDataListbyLabel('EWIMailJet');
        System.debug('toEMail :' + toEMail);
        System.debug('tempId :' + tempId);
        System.debug('recordId :' + recordId);
        System.debug('toRecAccId :' + toRecAccId);
        System.debug('toCaseParId :' + toCaseParId);
        System.debug('object Name :' + recordId.getSobjectType().getDescribe().getName());
        String conId = ''; 
        String accId = ''; //toRecAccId;
        Contact con = new Contact();
        Case_Participant__c casePar = new Case_Participant__c();
        String caseParId = '';

        String ObjName = recordId.getSobjectType().getDescribe().getName();
        String toObjName = '';
        if(toRecAccId != null){
            toObjName = toRecAccId.getSobjectType().getDescribe().getName();
        
            if(toObjName == 'Contact'){
                con = [Select Id, Name, AccountId from Contact Where Id = :toRecAccId];
                accId = con.AccountId;
            }
            else{
                accId = toRecAccId; 
            }
            // casePar = [Select Id, Name from Case_Participant__c Where Account__c =:accId and Case__c =:recordId];
            // caseParId = casePar.Id;
        }
        if(toCaseParId != null){
            List<Case_Participant__c> caseParList = [Select Id, Name from Case_Participant__c Where Id =:toCaseParId];
            caseParId = caseParList[0].Id;
        }

        String caseId = '';
        String depositId = '';
        String repayReqLineId = '';
        String repayReqId = '';
        String installmentId = '';
        String schemeId = '';
        String adjudicationReportId = '';
        List<Repayment_Request_Line__c> RRL;
        List<Installment__c> inst;
    
        if(ObjName == 'Case'){
            RRL = [Select Id, Name, Repayment_Request__c From Repayment_Request_Line__c where Repayment_Request__r.Case__c =:recordId AND 
                  (Contact__c = :conId OR Account__c = :accId) limit 1];
            if(RRL.size() > 0){
                repayReqLineId = RRL[0].Id;
                repayReqId = RRL[0].Repayment_Request__c;
            }
            List<Case> cs = [Select Id, Deposit_Account_Number__c, Deposit_Account_Number__r.Scheme__c From Case Where Id = :recordId];
            if(cs.size() > 0){
                caseId = cs[0].Id;
                depositId = cs[0].Deposit_Account_Number__c;
                SchemeId = cs[0].Deposit_Account_Number__r.Scheme__c;
            }
            inst = [Select Id, Name From Installment__c Where Case__c = :recordId AND Contact__c = :conId limit 1];
            if(inst.size() > 0){
                installmentId = inst[0].Id;
            }
            List<Adjudication_Report__c> adjReportList = [Select Id, CreatedDate, Dispute__c From Adjudication_Report__c
                                                          Where Dispute__c =:caseId order by CreatedDate desc limit 1];
            if(adjReportList.size() > 0){
                adjudicationReportId = adjReportList[0].Id;
            }
        }
        /*else if(ObjName == 'Deposit__c'){
            RRL = [Select Id, Name, Repayment_Request__c From Repayment_Request_Line__c where Repayment_Request__r.Deposit__c =:recordId AND
                  (Contact__c = :conId OR Account__c = :accId) limit 1];
            if(RRL.size() > 0){
                repayReqLineId = RRL[0].Id;
                repayReqId = RRL[0].Repayment_Request__c;
            }
            List<Deposit__c> depo = [Select Id, Name, Scheme__c, caseId__c From Deposit__c Where Id = :recordId];
            if(depo.size() > 0){
                depositId = depo[0].Id;
                caseId = depo[0].caseId__c;
                SchemeId = depo[0].Scheme__c;
            }
            inst = [Select Id, Name From Installment__c Where Deposit__c = :recordId AND Contact__c = :conId limit 1];
            if(inst.size() > 0){
                installmentId = inst[0].Id;
            }
            List<Adjudication_Report__c> adjReportList = [Select Id, CreatedDate, Dispute__c From Adjudication_Report__c
                                                          Where Dispute__c =:caseId order by CreatedDate desc limit 1];
            if(adjReportList.size() > 0){
                adjudicationReportId = adjReportList[0].Id;
            }
        }*/
                
        String subject = '';
        String textPart = '';
            
       	try{
        Matching_Temp_Var__c gettextbody = [Select Template_Id__c, text_body__c, Subject__c, document__c from Matching_Temp_Var__c where Template_Id__c =:String.valueOf(tempId) and Var_Name__c = '' ]; //'a2F3H000000Bk7bUAC'
		textPart = gettextbody.text_body__c; 
        subject = gettextbody.Subject__c;
        System.debug('textPart: ' + textPart);
        System.debug('Subject: ' + subject);
        
        if(textPart.contains('resolution_executive_name') || 
        textPart.contains('resolution_executive_email') || 
        textPart.contains('direct_dial') )
        {
            User usr = [select Id, Title, FirstName, LastName, Name, Job_Title__c, email, Phone from User where Id =: UserInfo.getUserId()];
            System.debug('usr.Title => ' + usr.Title);
            System.debug('usr.FirstName => ' + usr.FirstName);
            System.debug('usr.LastName => ' + usr.LastName);
            System.debug('usr.Name => ' + usr.Name);
            System.debug('usr.Email => ' + usr.Email);
            System.debug('usr.Phone => ' + usr.Phone); //{{var:direct_dial:&quot;&quot;}}
            String userName = '';
            userName += usr.Title!=null?usr.Title+' ':'';
            userName += usr.FirstName!=null?usr.FirstName+' ':'';
            userName += usr.LastName!=null?usr.LastName:'';
            textPart = textPart.replace('{{var:resolution_executive_name:&quot;&quot;}}', userName);
            textPart = textPart.replace('{{var:resolution_executive_title:&quot;&quot;}}', usr.Job_Title__c!=null?usr.Job_Title__c:'');
            textPart = textPart.replace('{{var:resolution_executive_email:&quot;&quot;}}', usr.Email!=null?usr.Email:'');
            textPart = textPart.replace('{{var:direct_dial:&quot;&quot;}}', usr.Phone!=null?usr.Phone:'');
        }

        String varSet = ''; // selected template's variable names set
        String[] textPartSplit = textPart.split('var');
        for(Integer i=0; i< textPartSplit.size(); i++){
            
            String tp = textPartSplit[i];
            if(tp.startsWith(':')){
                System.debug('tp=> '+ tp);
                String varName = tp.substringBetween(':', ':');
                System.debug('var Name :' + varName);
                if(varName != null && varName.toLowerCase() != 'date'){
                    varSet += '\'' + varName + '\'';
                    if(i != textPartSplit.size()-1){
                        varSet += ', ';
                    }
                }
            }
        }
        System.debug('Text Part Temp var Set :' + varSet);
        
        String[] subjectSplit = subject.split('var');
        for(Integer i=0; i< subjectSplit.size(); i++){
            
            String tp = subjectSplit[i];
            if(tp.startsWith(':')){
                System.debug('tp=> '+ tp + ' i=> ' + i);
                String varName = tp.substringBetween(':', ':');
                System.debug('var Name :' + varName);
                if(!varSet.contains(varName)){
                    if(i == 1 && varSet != ''){
                        varSet += ', ';
                    }
                    if(varName != null && varName.toLowerCase() != 'date'){
                        varSet += '\'' + varName + '\'';
                        if(i != subjectSplit.size()-1){
                            varSet += ', ';
                        }
                    }
                }
            }
        }
        System.debug('Temp var Set :' + varSet);
        
        // get Object Field API names and where condition field of varnames from custom object Matching_Temp_Var__c
        String query = 'SELECT Var_Name__c, isTable__c, Date_Function__c, Object_Name__c, Field_API_Name__c, Where_Check_Field__c, Redirect_Link__c FROM Matching_Temp_Var__c where Var_Name__c IN ('+varSet+') AND Template_Id__c = \''+tempId+'\' '  ;
        System.debug(' query : ' + query);
        List<Matching_Temp_Var__c> mtvList = database.query(query); 
        System.debug('mtvList : ' + mtvList);
             
        Map<String, String> varValues = new Map<String, String>(); // Field's API names and their values
        Map<String, String> varnameANDRedirectLinkMap = new Map<String, String>(); // template variable and Redirect Link Map
        Map<String, String> varnameANDDateFuncMap = new Map<String, String>(); // template variable and date Function Map
        Map<String, String> varnameANDapinameMap = new Map<String, String>(); // template variable and Field API name's Map
        Map<String, String> objANDFieldMap = new Map<String, String>(); // Object and Field API name's Map
        Map<String, String> objANDWhereCheckFieldMap = new Map<String, String>(); // Object and where condition field Map
        String tableDate = '<table>';
        for(integer i=0; i< mtvList.size(); i++){
            Matching_Temp_Var__c matchObj = new Matching_Temp_Var__c();
            matchObj = mtvList[i];
            objANDWhereCheckFieldMap.put(matchObj.Object_Name__c, matchObj.Where_Check_Field__c);
            
            if(!mtvList[i].isTable__c && mtvList[i].Field_API_Name__c != null){
                
                String varFieldAPINames = '';
                if(objANDFieldMap.containsKey(matchObj.Object_Name__c)){  // if obj contains
                    varFieldAPINames = objANDFieldMap.get(matchObj.Object_Name__c);  // get fields
                }
                
                if(!varFieldAPINames.contains(','+ matchObj.Field_API_Name__c+' ')){ // check for duplicate variable names from template
                    System.debug('if not contains varFieldAPINames => ' + varFieldAPINames);
                    varFieldAPINames += ',' + matchObj.Field_API_Name__c + ' ';
                }
                objANDWhereCheckFieldMap.put(matchObj.Object_Name__c, matchObj.Where_Check_Field__c);
                objANDFieldMap.put(matchObj.Object_Name__c, varFieldAPINames);
                
                varnameANDapinameMap.put(mtvList[i].Var_Name__c, mtvList[i].Field_API_Name__c + mtvList[i].Object_Name__c);
                //varnameANDDateFuncMap.put(mtvList[i].Var_Name__c, mtvList[i].Date_Function__c);
            }
            else if(mtvList[i].isTable__c && mtvList[i].Field_API_Name__c != null){
                Map<String, String> tableVarValues = new Map<String, String>(); // table Field's API names and their values
                String tableDataQuery = '';
                /*if(mtvList[i].Object_Name__c == 'Repayment_Request__c' && repayReqId != null && repayReqId != ''){
                    System.debug('is table Repayment_Request__c');
                    List<String> labelFieldsList = mtvList[i].Field_API_Name__c.split(','); // label-fieldAPIName format data 
                    Map<String, String> FieldANDlabelMap = new Map<String, String>(); // field api name as key and label as value
                    
                    String fieldsAPIName = '';
                    for(String labelandField : labelFieldsList){
                        fieldsAPIName += labelandField.subStringAfter('-');
                        if(labelFieldsList[labelFieldsList.size()-1] != labelandField){
                            fieldsAPIName += ',';
                        }
                        FieldANDlabelMap.put(labelandField.subStringAfter('-'), labelandField.substringBefore('-'));
                    }
                    System.debug('FieldANDlabelMap => ' + FieldANDlabelMap);
                    System.debug('fieldsAPIName => ' + fieldsAPIName);
                    
                    tableDataQuery = 'Select '+ fieldsAPIName +' FROM '+mtvList[i].Object_Name__c+' WHERE Id = \''+repayReqId+'\' ';
                    if(tableDataQuery != ''){
                        System.debug('tableDataQuery => ' + tableDataQuery);
                        List<sObject> objList = database.query(tableDataQuery);
                        String[] allFieldAPInamesSplited = fieldsAPIName.split(',');
                        for(sObject CP : objList){
                            for(integer j=0; j<allFieldAPInamesSplited.size(); j++){
                                String fieldName = allFieldAPInamesSplited[j];
                                System.Debug('fieldName => ' + fieldName);
                                if(fieldName.contains('__r.')){
                                    Map<String, Object> convertedsubObjToMap = CP.getSobject(fieldName.substringBefore('.')).getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                                    for (String subfieldName : convertedsubObjToMap.keySet()){
                                        System.debug('subfieldName => ' + subfieldName + 'String.ValueOf(fieldName.substringAfter => ' + String.ValueOf(fieldName.substringAfter('.')));
                                        System.debug('sub field name is ' + fieldName.substringBefore('.').trim()+'.'+subfieldName.trim() + ', value is ' + convertedsubObjToMap.get(subfieldName));
                                        tableVarValues.put(fieldName.substringBefore('.').trim()+'.'+subfieldName , String.valueOf(convertedsubObjToMap.get(subfieldName) ));
                                    }
                                }else{
                                    Map<String, Object> convertedObjToMap = CP.getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                                    for (String mainfieldName : convertedObjToMap.keySet()){
                                        System.debug('field name is ' + mainfieldName + ', value is ' + convertedObjToMap.get(mainfieldName));
                                        tableVarValues.put(mainfieldName , String.valueOf(convertedObjToMap.get(mainfieldName) ));
                                        System.debug('tableVarValues => ' + tableVarValues.get(allFieldAPInamesSplited[1]));
                                    }
                                }
                            }
                            System.debug('allFieldAPInamesSplited[0] => ' + allFieldAPInamesSplited[0] + ' Value is => ' + tableVarValues.get(allFieldAPInamesSplited[0]));
                            System.debug('allFieldAPInamesSplited[1] => ' + allFieldAPInamesSplited[1] + 'Value is => ' + tableVarValues.get(allFieldAPInamesSplited[1]));
                        }
                        
                        for(integer t=0; t<allFieldAPInamesSplited.size(); t++){
                            if(String.valueOf(tableVarValues.get(allFieldAPInamesSplited[t])) != '0.00' 
                               && String.valueOf(tableVarValues.get(allFieldAPInamesSplited[t])) != ''
                                && String.valueOf(tableVarValues.get(allFieldAPInamesSplited[t])) != null)
                            {
                                tableDate += '<tr>';
                                tableDate += '<td>'+ FieldANDlabelMap.get(allFieldAPInamesSplited[t]) +':'+'<td>';
                                tableDate += '<td>'+'£'+ tableVarValues.get(allFieldAPInamesSplited[t]) +'<td>';
                                tableDate += '</tr>';
                            }
                        }
                        tableDate += '</table><br/><br/>';
                        varValues.put(mtvList[i].Field_API_Name__c+mtvList[i].Object_Name__c , tableDate);
                        varnameANDapinameMap.put(mtvList[i].Var_Name__c, mtvList[i].Field_API_Name__c + mtvList[i].Object_Name__c);
                    }
                }
                else{
                    /*if(mtvList[i].Object_Name__c == 'Repayment_Request_Line__c' && repayReqId != null && repayReqId != ''){
                        if(matchObj.Where_Check_Field__c != '' && matchObj.Where_Check_Field__c != null){
                            tableDataQuery = 'Select '+mtvList[i].Field_API_Name__c+' FROM '+mtvList[i].Object_Name__c+' WHERE Repayment_Request__c = \''+repayReqId+'\' AND '+ matchObj.Where_Check_Field__c;
                        }else{
                            tableDataQuery = 'Select '+mtvList[i].Field_API_Name__c+' FROM '+mtvList[i].Object_Name__c+' WHERE Repayment_Request__c = \''+repayReqId+'\' ';
                        }
                    }
                    else if(mtvList[i].Object_Name__c == 'Deposit_Allocation__c' && depositId != null && depositId != ''){
                        tableDataQuery = 'Select '+mtvList[i].Field_API_Name__c+' FROM '+mtvList[i].Object_Name__c+' WHERE Deposit__c = \''+depositId+'\' AND Istenantmoved__c = true ';
                    }
                    else*/ 
                	if(mtvList[i].Object_Name__c == 'Dispute_Item__c' && caseId != null && caseId != ''){
                        tableDataQuery = 'Select '+mtvList[i].Field_API_Name__c+' FROM '+mtvList[i].Object_Name__c+' WHERE Dispute__c = \''+caseId+'\' ';
                    }
                    
                    if(tableDataQuery != ''){
                        System.debug('tableDataQuery => ' + tableDataQuery);
                        List<sObject> objList = database.query(tableDataQuery);
                        String[] allFieldAPInamesSplited = mtvList[i].Field_API_Name__c.split(',');
                        string tableDate1 = '<table>';
                        for(sObject CP : objList){
                            for(integer j=0; j<allFieldAPInamesSplited.size(); j++){
                                String fieldName = allFieldAPInamesSplited[j];
                                System.Debug('fieldName => ' + fieldName);
                                if(fieldName.contains('__r.')){
                                    Map<String, Object> convertedsubObjToMap = CP.getSobject(fieldName.substringBefore('.')).getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                                    for (String subfieldName : convertedsubObjToMap.keySet()){
                                        System.debug('subfieldName => ' + subfieldName + 'String.ValueOf(fieldName.substringAfter => ' + String.ValueOf(fieldName.substringAfter('.')));
                                        System.debug('sub field name is ' + fieldName.substringBefore('.').trim()+'.'+subfieldName.trim() + ', value is ' + convertedsubObjToMap.get(subfieldName));
                                        tableVarValues.put(fieldName.substringBefore('.').trim()+'.'+subfieldName , String.valueOf(convertedsubObjToMap.get(subfieldName) ));
                                    }
                                }else{
                                    Map<String, Object> convertedObjToMap = CP.getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                                    for (String mainfieldName : convertedObjToMap.keySet()){
                                        System.debug('field name is ' + mainfieldName + ', value is ' + convertedObjToMap.get(mainfieldName));
                                        tableVarValues.put(mainfieldName , String.valueOf(convertedObjToMap.get(mainfieldName) ));
                                        System.debug('tableVarValues => ' + tableVarValues.get(allFieldAPInamesSplited[1]));
                                    }
                                }
                            }
                            System.debug('allFieldAPInamesSplited[0] => ' + allFieldAPInamesSplited[0] + ' Value is => ' + tableVarValues.get(allFieldAPInamesSplited[0]));
                            System.debug('allFieldAPInamesSplited[1] => ' + allFieldAPInamesSplited[1] + 'Value is => ' + tableVarValues.get(allFieldAPInamesSplited[1]));
                            
                            /*tableDate += '<tr>';
                            tableDate += '<td>'+ tableVarValues.get(allFieldAPInamesSplited[0]) +':'+'<td>';
                            tableDate += '<td>'+'£'+ tableVarValues.get(allFieldAPInamesSplited[1]) +'<td>';
                            tableDate += '</tr>';
                            tableDate += '<tr>';*/
                            tableDate1 += '<tr>';
                            for(integer t=0; t<allFieldAPInamesSplited.size(); t++){
                                if(t == 0){
                                    tableDate1 += '<td>'+ tableVarValues.get(allFieldAPInamesSplited[t]) +':'+'</td>';
                                }
                                else if(t == allFieldAPInamesSplited.size()-1){
                                    tableDate1 += '<td>'+'£'+ tableVarValues.get(allFieldAPInamesSplited[t]) +':'+ '</td>';
                                }
                                else{
                                    tableDate1 += '<td>'+'£'+ tableVarValues.get(allFieldAPInamesSplited[t]) +'</td>';
                                }
                            }
                            tableDate1 += '</tr>';
                            
                        }
                        tableDate1 += '</table>';
                        varValues.put(mtvList[i].Field_API_Name__c+mtvList[i].Object_Name__c , tableDate1);
                        varnameANDapinameMap.put(mtvList[i].Var_Name__c, mtvList[i].Field_API_Name__c + mtvList[i].Object_Name__c);
                    }
                //}
            }
            
            if(mtvList[i].Date_Function__c != null && mtvList[i].Date_Function__c != ''){
                varnameANDDateFuncMap.put(mtvList[i].Var_Name__c, mtvList[i].Date_Function__c);
            }
            else if(mtvList[i].Redirect_Link__c != null && mtvList[i].Redirect_Link__c != ''){
                varnameANDRedirectLinkMap.put(mtvList[i].Var_Name__c, mtvList[i].Redirect_Link__c);
            }
        }
        System.debug('varnameANDapinameMap : ' + varnameANDapinameMap);
        System.debug('varnameANDDateFuncMap : ' + varnameANDDateFuncMap);
        System.debug('objANDFieldMap : ' + objANDFieldMap);
        
        //Map<String, String> varValues = new Map<String, String>(); // Field's API names and their values
        for(String sobj : objANDFieldMap.keySet()){
            String WhereField = objANDWhereCheckFieldMap.get(sobj);
            String allFieldAPInames = objANDFieldMap.get(sobj);
            /*List<String> splitedWhereField = WhereField.split(',');
            String WhereStatement = '';
            for(String WField : splitedWhereField){
                WhereStatement += WField + ' = \''+recordId+'\' OR ' + WField + ' = \''+toRecAccID+'\'';
            }*/
            String getValueQuery = '';
            if(sobj == 'Contact' && conId != null && conId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + conId + '\' limit 1 ';
            }
            else if(sobj == 'Account' && accId != null && accId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + accId + '\' limit 1 ';
            }
            else if(sobj == 'Case_Participant__c'){
                if(WhereField != null && caseId != null && caseId != ''){
                    getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Case__c = \'' + caseId + '\' AND '+ WhereField +' limit 1 ';
                }else if(caseParId != null && caseParId != ''){
                    getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + caseParId + '\' limit 1 ';
                }
            }
            else if(sobj == 'Case' && caseId != null && caseId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + caseId + '\' limit 1 ';
            }
            else if(sobj == 'Deposit__c' && depositId != null && depositId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + depositId + '\' limit 1 ';
            }
            /*else if(sobj == 'Repayment_Request__c' && repayReqId != null && repayReqId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + repayReqId + '\' limit 1 ';
            }
            else if(sobj == 'Repayment_Request_Line__c' && repayReqLineId != null && repayReqLineId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + repayReqLineId + '\' limit 1 ';
            }*/
            else if(sobj == 'Installment__c' && installmentId != null && installmentId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + installmentId + '\' limit 1 ';
            }
            else if(sobj == 'Scheme__c' && schemeId != null && schemeId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + schemeId + '\' limit 1 ';
            }
            else if(sobj == 'API_Service__mdt' && tempId != null){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Template_Id__c = \'' + tempId + '\' limit 1 ';
            }
            else if(sobj == 'Adjudication_Report__c' && adjudicationReportId != null && adjudicationReportId != ''){
                getValueQuery = 'SELECT Id ' +allFieldAPInames+ ' FROM '+ sobj +' where Id = \'' + adjudicationReportId + '\' limit 1 ';
            }
            
            if(getValueQuery != ''){
                System.debug(' getValueQuery : ' + getValueQuery);
                sObject CP = database.query(getValueQuery);
                System.debug('CP : ' + CP);
                
                List<String> allFieldAPInamesSplited = allFieldAPInames.split(',');
                /*if(allFieldAPInames.contains(',')){
				allFieldAPInamesSplited = allFieldAPInames.split(',');
				System.Debug('allFieldAPInamesSplited => ' + allFieldAPInamesSplited[1]);
				}*/
                for(integer j=1; j<allFieldAPInamesSplited.size(); j++){
                    String fieldName = allFieldAPInamesSplited[j];
                    System.Debug('fieldName => ' + fieldName);
                    if(fieldName.contains('__r.')){
                        System.Debug('fieldNameSplited [0] => ' + fieldName.substringBefore('.'));
                        System.debug('deposit Acc => ' + fieldName.substringAfter('.'));
                        Map<String, Object> convertedsubObjToMap = new Map<String, Object>();
                        if(CP.getSobject(fieldName.substringBefore('.')) != null){
                            convertedsubObjToMap = CP.getSobject(fieldName.substringBefore('.')).getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                        }
                        for (String subfieldName : convertedsubObjToMap.keySet()){
                            if(CP.getSobject(fieldName.substringBefore('.')) != null){
                                System.debug('subfieldName => ' + subfieldName + 'String.ValueOf(fieldName.substringAfter => ' + String.ValueOf(fieldName.substringAfter('.')));
                                System.debug('sub field name is ' + fieldName.substringBefore('.').trim()+'.'+subfieldName.trim()+sobj.trim() + ', value is ' + convertedsubObjToMap.get(subfieldName));
                                varValues.put(fieldName.substringBefore('.').trim()+'.'+subfieldName.trim()+sobj.trim() , String.valueOf(convertedsubObjToMap.get(subfieldName) ));
                            }else{
                                varValues.put(fieldName.substringBefore('.').trim()+'.'+subfieldName.trim()+sobj.trim() , '' );
                            }
                        }
                    }else{
                        Map<String, Object> convertedObjToMap = CP.getPopulatedFieldsAsMap(); // map of populated field names(allFieldAPInames) and their corresponding values
                        for (String mainfieldName : convertedObjToMap.keySet()){
                            System.debug('field name is ' + mainfieldName + ', value is ' + convertedObjToMap.get(mainfieldName));
                            varValues.put(mainfieldName+sobj , String.valueOf(convertedObjToMap.get(mainfieldName) ));
                        }
                    }
                }        
            }
        }
    	System.debug('varValues : ' + varValues);
        
        for(String tp : textPartSplit){
            if(tp.startsWith(':')){
                String varName = tp.substringBetween(':', ':');
                System.debug('var Name :' + varName);
                String valueAPIname;
                String redirectLink = varnameANDRedirectLinkMap.get(varName);
                String dateFunction = varnameANDDateFuncMap.get(varName);
                System.debug('dateFunction => ' + dateFunction);
                if(varName.toLowerCase() == 'date'){
                    Date todayDate = System.today();
					String todayStr = todayDate.day()+'/'+todayDate.month()+'/'+todayDate.year();
                    System.debug('todayDate=> ' + todayStr);
                    textPart = textPart.replace(':'+varName+':', todayStr ); // replace varname(date/Date) with current date
                    //textPart = textPart.replace('{{var:' +varName+ ':&quot;&quot;}}', '');
                }
                if(redirectLink != null && redirectLink != ''){
                    // textPart = textPart.replace(':'+varName+':', redirectLink != null ? redirectLink : '' );
                    System.debug('redirectLink => ' + redirectLink);
                    System.debug('redirectLink valueAPIname => ' + varValues.get(valueAPIname));
                    valueAPIname = varnameANDapinameMap.get(varName); 
                    String accessCode = varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '';
                    String CTAbtn = '';
                    if(redirectLink == 'home'){
                        CTAbtn = '<a href="https://www.tenancydepositscheme.com/log-in/" target="_blank">login here</a>';
                    }else{
                        CTAbtn = '<a href="https://www.tenancydepositscheme.com/log-in/" target="_blank">login here</a>';
                    }
                    System.debug('CTAbtn => ' + CTAbtn);
                    textPart = textPart.replace(':'+varName+':', CTAbtn );
                } 
                if(dateFunction != null && dateFunction != ''){
                    /*if(dateFunction.toLowerCase().contains('adddays')){
                        System.debug('dateFunction. days => ' + dateFunction.substringBetween('(', ')'));
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        Date startDate = varValues.get(valueAPIname)!=null? Date.valueOf(varValues.get(valueAPIname)) : System.today();
                        Integer days = Integer.valueOf(dateFunction.substringBetween('(', ')'));
                        Date calcDate = calculateAddDays(startDate, days);
						String calcDateStr = calcDate.day()+'/'+calcDate.month()+'/'+calcDate.year();
                        textPart = textPart.replace(':'+varName+':', calcDateStr);
                    }
                    else if(dateFunction.toLowerCase().contains('addmonths')){
                        System.debug('dateFunction. days => ' + dateFunction.substringBetween('(', ')'));
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        Date startDate = varValues.get(valueAPIname)!=null? Date.valueOf(varValues.get(valueAPIname)) : System.today();
                        Integer months = Integer.valueOf(dateFunction.substringBetween('(', ')'));
                        Date calcDate = calculateAddMonths(startDate, months);
						String calcDateStr = calcDate.day()+'/'+calcDate.month()+'/'+calcDate.year();
                        textPart = textPart.replace(':'+varName+':', calcDateStr);
                    }
                    else if(dateFunction.toLowerCase().contains('nthworkingday')){
                        System.debug('dateFunction. days => ' + dateFunction.substringBetween('(', ')'));
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        Date startDate = varValues.get(valueAPIname)!=null? Date.valueOf(varValues.get(valueAPIname)) : System.today();
                        Integer days = Integer.valueOf(dateFunction.substringBetween('(', ')'));
                        Date calcDate = calculateNthWorkingDay(startDate, days);
						String calcDateStr = calcDate.day()+'/'+calcDate.month()+'/'+calcDate.year();
                        textPart = textPart.replace(':'+varName+':', calcDateStr);
                    }
                    else if(dateFunction.toLowerCase().contains('workingdaysbwtodates')){
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        Date endDate = varValues.get(valueAPIname)!=null? Date.valueOf(varValues.get(valueAPIname)) : System.today();
                        System.debug('endDate => ' + endDate);
                        textPart = textPart.replace(':'+varName+':', String.valueOf(calculateWorkingDaysBetweenTwoDates(System.today(), endDate)) );
                    }
                    else if(dateFunction.toLowerCase().contains('daysbw')){
                        System.debug('daysbw dateFunction => ' + dateFunction);
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        System.debug('daysbw valueAPIname => ' + valueAPIname + varValues.get(valueAPIname));
                        Date endDate = varValues.get(valueAPIname)!=null? Date.valueOf(varValues.get(valueAPIname)) : System.today();
                        Integer days = Integer.valueOf(dateFunction.substringBetween('(', ')'));
                        System.debug('end Date => ' + endDate + ' Days => ' + days);
                        textPart = textPart.replace(':'+varName+':', String.valueOf(calculateDaysBetween(endDate, days)) );
                    }
                    else if(dateFunction.toLowerCase().contains('todaydate')){
                        System.debug('todaydate dateFunction => ' + dateFunction);
                        Date todayDate = System.today();
                        String todayStr = todayDate.day()+'/'+todayDate.month()+'/'+todayDate.year();
                        textPart = textPart.replace(':'+varName+':', todayStr);
                    }
                    else*/ if(dateFunction.toLowerCase().contains('amounttoeachtenant')){
                        System.debug('daysbw dateFunction => ' + dateFunction);
                        valueAPIname = varnameANDapinameMap.get(varName); 
                        System.debug('daysbw valueAPIname => ' + valueAPIname + varValues.get(valueAPIname));
                        Decimal amountToTenants = varValues.get(valueAPIname)!=null? Decimal.valueOf(varValues.get(valueAPIname)) : 0.00;
                        Decimal AmountToEachTenant = amountToTenants>0 ? amountToEveryTenant(caseId, amountToTenants) : 0.00;
                        textPart = textPart.replace(':'+varName+':', String.valueOf(AmountToEachTenant));
                    }
                }
                else{
                    valueAPIname = varnameANDapinameMap.get(varName); // get Field API name of template variable
                    System.debug('varnameANDapinameMap var Name :' + valueAPIname + ':'+varName+':');
                    
                    System.debug(':'+varName+':' +'Field Value' + (varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '') );
                    
                    if(varName.containsIgnoreCase('date') && varValues.get(valueAPIname) != null){
                        date DateVal = Date.valueOf(varValues.get(valueAPIname));
                        textPart = textPart.replace(':'+varName+':', varValues.get(valueAPIname) != null ? DateVal.format() : '' );
                    }
                    else if(varName.containsIgnoreCase('Amount') || varName.containsIgnoreCase('Fund')){
                        textPart = textPart.replace(':'+varName+':', varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '0.00' ); // replace varname with its value in mail body
                    }
                    else{
                        textPart = textPart.replace(':'+varName+':', varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '' ); // replace varname with its value in mail body
                    }
                }
            }
        }
        
        for(String tp : subjectSplit){
            if(tp.startsWith(':')){
                String varName = tp.substringBetween(':', ':');
                System.debug('var Name :' + varName);
                String valueAPIname;
                if(varName.toLowerCase() == 'date'){
                    subject = subject.replace(tp.substringBetween(':', ':'), String.valueOf(System.today()) ); // replace varname(date/Date) with current date
                    subject = subject.replace('{{var:'+varName+':\""}}', '');
                }else{
                    valueAPIname = varnameANDapinameMap.get(varName); // get Field API name of template variable
                    System.debug('varnameANDapinameMap var Name :' + valueAPIname);
                    
                    System.debug( 'varName' + varName + 'Field Value' + varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '' );
                    subject = subject.replace(':'+varName+':', varValues.get(valueAPIname) != null ? varValues.get(valueAPIname) : '' ); // replace varname with its value in mail body
                }
            }
        }
        
        System.Debug('textPart =>>> ' + textPart);
        textPart = textPart.replace('{{var', '');
        textPart = textPart.replaceAll('&quot;&quot;}}', '');
        System.Debug('return textPart =>>> ' + textPart);
        System.Debug('subject =>>> ' + subject);
        subject = subject.replace('{{var', '');
        subject = subject.replaceAll('\""}}', '');
        System.Debug('return subject =>>> ' + subject);
        Map<String, String> returnTemplate = new Map<String, String>{'subject' => subject, 'body'=> textPart};
            
            manualEmailWrapper manualEmailContent = new manualEmailWrapper();
            manualEmailContent.subject = subject;
            manualEmailContent.body = textPart;
            if(gettextbody.document__c != '' && gettextbody.document__c != null && gettextbody.document__c != 'undefined'){
                Document doc = [Select Body, ContentType, Name, Type, DeveloperName From Document where DeveloperName =: gettextbody.document__c limit 1];
                String file = 'fileName:'+ doc.Name +';data:'+ doc.ContentType +';base64,'+ EncodingUtil.base64Encode(doc.Body);    
                manualEmailContent.attachedFiles = new List<String>{file};
            }
        return manualEmailContent; //returnTemplate;
        }catch(exception e){
            return null; //new Map<String, String>{'error' => e.getMessage()};
        }
    }
    
    public class manualEmailWrapper{
        @AuraEnabled
        Public String subject = '';
        @AuraEnabled
        Public String body = '';
        @AuraEnabled
        Public List<String> attachedFiles = new List<String>(); // string = 'fileName:'+'file name.pdf+';data:'+content/type+';base64,'+base64value;
    }
    
    public static Date calculateAddDays(Date startDate, integer noOfDays){
        return startDate.addDays(noOfDays);
    }
    
    public static Decimal amountToEveryTenant(String caseId, Decimal AmountToTenants){
        Case cs = [Select Id, Status, No_of_Tenants__c from Case Where Id =: caseId];
        return (AmountToTenants/ cs.No_of_Tenants__c);
    }
    
    public static Date calculateAddMonths(Date startDate, integer noOfMonths){
        return startDate.addMonths(noOfMonths);
    }
    
    public static Integer calculateDaysBetween(Date endDate, Integer days){
        return System.today().daysBetween(endDate.addDays(days));
    }
    
    public static Date calculateNthWorkingDay(Date startDate, integer noOfDays)
    {
        if(startDate == null){
            return null;
        }
        if(holidayList == null || holidayList.isEmpty()){
            holidayList = [Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];
        }
        Integer allWorkingDays=0;
        Integer totalDays = 1;
        while(allWorkingDays<=noOfDays)
        {
            if(checkifItisWorkingDay(startDate.addDays(totalDays),holidayList)){
                allWorkingDays++;
                if(allWorkingDays==noOfDays)
                    break;
            }
            totalDays++;
        }
        while(!checkifItisWorkingDay(startDate.addDays(totalDays), holidayList)) {
            totalDays++;
        }
        return startDate.addDays(totalDays);
    }
    
    public static Integer calculateWorkingDaysBetweenTwoDates(Date startDate, Date endDate)
    {        
        if(startDate == null || endDate==null) {
            return null;
        }
        if(holidayList == null || holidayList.isEmpty()) {
            holidayList = [Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];
        }  
        //List<Holiday> holidays = [Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];
        if(startDate != endDate)
        {
            Integer noOfDaysBetween = Integer.valueOf(math.abs(startDate.daysBetween(endDate)));
            Integer allWorkingDays=0;
            
            for(Integer i=0;i<=noOfDaysBetween;i++) {
                if(checkifItisWorkingDay(startDate.addDays(i),holidayList) && i!=0) {
                    allWorkingDays++;
                }
            }
            return allWorkingDays;
        }
        else 
        {
            return 0;           
        }
    }
    
    public static boolean checkifItisWorkingDay(Date currentDate, List<Holiday> holidays)
    {
        Date weekStart  = currentDate.toStartofWeek();
        Time timeflag  = Time.newInstance(0, 0, 0, 0);
        DateTime currentdatetime = DateTime.newInstance(currentDate,timeflag);
        for(Holiday hDay:holidays) {
            if(currentDate.daysBetween(hDay.ActivityDate) == 0) {
                return false;
            }
        }
        if( currentdatetime.format('EEEE').toLowercase() =='sunday' || currentdatetime.format('EEEE').toLowercase() =='saturday')
        {
            return false;
        }
        else
        {
           return true; 
        } 
    }
    
    public class saveMsgWrapper{
        public string resBody;
        Map<String,recipient> recMap;
        public string Subject;
    }   
    
    public class recipient{
        String Email;
        String name;
        String recId;
        String accId;
        String caseParId;
        public  String Link;
        public String buttonLink;
        public   String Label;
        
        public recipient(String Email,String name,String recId,String Link){
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.link = link;
        }
        public recipient(String Email,String name,String recId,String Link,String buttonLink,String Label ){
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.link = link;
            this.buttonLink = buttonLink;
            this.Label = Label;
        }
        public recipient(String Email,String name,String recId){
            this.Name = name;
            this.Email = email;
            this.recId = recId;
        }
        public recipient(String Email,String name,String recId, String accId, String caseParId){
            this.Name = name;
            this.Email = email;
            this.recId = recId;
            this.accId = accId;
            this.caseParId = caseParId;
        }
    }
    
    public static void saveErrorDetails(String recId,String error,String subject,String email){
        Mailjet_Message__c mm = new Mailjet_Message__c(response_status__c='Error',Subject__c=Subject,Record_ID__c=recId,
                                                       Error__c=error);
        insert mm;
    }
    
    /*public static void saveMessageDetails(String resJSON,Map<String,recipient> recMap, STring Subject){
        List<response> jsonList = new  List<response>();
        //add try catch if deserialize breaks create Message with error
        try{
            jsonList =    ( List<response>) System.JSON.deserialize(resJSON, List<response>.class);
        }
        catch(Exception e){
            system.debug('ERROR --> '+e.getMessage());
        }
        system.debug(jsonList);
        List<Mailjet_Message__c> mailJetList = new List<Mailjet_Message__c>();
        for(response res : jsonList){
            
            for(Messages msg : res.Messages){
                system.debug(msg);
                Mailjet_Message__c mm = new Mailjet_Message__c(response_status__c='success',Subject__c=Subject,Record_ID__c=recMap.get(msg.to[0].Email).recid,
                                                               Message_Id__c=msg.to[0].MessageID,Email_ID__c=msg.to[0].Email);
                mailJetList.add(mm);
            }
        }
        
        insert mailJetList;
    }*/
   
    public static List<API_Service__mdt> metaDataListbyLabel(String metaDataLabel){
        List<API_Service__mdt> metaDataList = [SELECT EndPoint_URL__c, Username__c, Password__c, From_Name__c, From_Address__c,
                                               Template_Id__c, Scheme_Signatory__c, Scheme_Address__c,Scheme_Bank_Account_Number__c,
                                               Scheme_Sort_Code__c,Scheme_Bank_Name__c, Label
                                               FROM API_Service__mdt 
                                               WHERE QualifiedApiName=:metaDataLabel];
        return metaDataList;
    }
    
    public class response{
        String Status;
        List<Messages> messages;
    }
    
    public class Messages{
        String Status;
        String CustomID;
        List<To> To;
    }
    
    
    public class To{
        String Email;
        String MessageUUID;
        String MessageID;
        String MessageHref;
    }
    
    @AuraEnabled
    public static List<Map<String,String>> fetchRecipients(Id recordId){
        String ObjName = recordId.getSobjectType().getDescribe().getName();
        System.debug('ObjName => ' + ObjName);
        List<Map<String,String>> returnRecipients = new List<Map<String,String>>();
       
        list<Case_Participant__c> CP = [select id, type__c, Contact__c, Contact__r.name, Contact__r.Email,
         Account__c, Account__r.name, Account__r.PersonEmail, Account__r.Email__c, Account__r.G_Number__c, Account__r.EWI_Landlord_Id__c,
         Primary_Email__c, Other_Emails__c, Disputes_credit_control__c 
         from Case_Participant__c where Case__c=:recordId];
        Set<Id> CPaccIdSet = new Set<Id>();
        map<Id, String> cpRoleIdMap = new map<Id, String>();
        for(Case_Participant__c participient : CP){
            CPaccIdSet.add(participient.Account__c);
            cpRoleIdMap.put(participient.Account__c, participient.type__c);
            /* for chnage mapping from COntact to Account */
            Map<String,String>  newMap = new Map<String,String>();
            newMap.put('name', participient.Account__r.name);
            newMap.put('Primary_Email__c', participient.Primary_Email__c);
            newMap.put('Other_Emails__c', participient.Other_Emails__c);
            newMap.put('Disputes_credit_control__c', participient.Disputes_credit_control__c);
            newMap.put('role', participient.type__c);
            newMap.put('Id', participient.Account__c);
            newMap.put('CaseParId', participient.Id);
            returnRecipients.add(newMap);
        }
        System.debug('returnRecipients => ' + returnRecipients);
        return returnRecipients;
    }

    public static Map<String, List<Map<String, String>>> getAllDepartmentList(){
        List<Map<String, String>> listOfDeptReturn = new List<Map<String, String>>();
        Map<String, List<Map<String, String>>> mapOfDeptReturn = new Map<String, List<Map<String, String>>>();
        
        List<Matching_Temp_Var__c> getAllDepartment = [Select Template_Id__c, Custom_Metadata_Label__c, text_body__c, 
                                                       Subject__c,Department__c from Matching_Temp_Var__c 
                                                       where Var_Name__c = '' and Scheme__c = 'EWI' and Department__c != null order by Department__c]; 
        for(Matching_Temp_Var__c mtv : getAllDepartment){
            Map<String, String> IdAndLabelMap = new Map<String, String>();
            IdAndLabelMap.put('Template_Id__c' , mtv.Template_Id__c); 
            IdAndLabelMap.put('Label', mtv.Custom_Metadata_Label__c); 
            IdAndLabelMap.put('Department__c', mtv.Department__c);
            
            if(!mapOfDeptReturn.containsKey(mtv.Department__c)){
                mapOfDeptReturn.put(mtv.Department__c, new List<Map<String, String>>());
            }
            mapOfDeptReturn.get(mtv.Department__c).add(IdAndLabelMap);
        }
        
        system.debug('---'+mapOfDeptReturn);
        return mapOfDeptReturn;        
    }
    
    @AuraEnabled
    public static doInitData getDoInitData(Id recordId){
        doInitData wrap = new doInitData();
        wrap.recipients = fetchRecipients(recordId);
        wrap.allMetaDataList = getAllMetaDataList();
        wrap.currentUser = [select Id, Name, Email, Phone from User where Id =: UserInfo.getUserId()];
        wrap.mapOfDepartment = getAllDepartmentList();
        if(!wrap.mapOfDepartment.isEmpty()){
            wrap.departments = new List<String>(wrap.mapOfDepartment.keySet());
        }
        return wrap;
    }
    
    public class doInitData{
        @AuraEnabled public List<Map<String, String>> recipients { get; set; }
        @AuraEnabled public List<Map<String, String>> allMetaDataList { get; set; }
        @AuraENabled public User currentUser { get; set; }
        @AuraENabled public Map<String, List<Map<String, String>>> mapOfDepartment;
        @AuraENabled public List<String> departments;
    }

    @AuraEnabled
    public static List<Case_Participant__c> getBranchList(String gNumber){
        List<Case_Participant__c> caseParList = [SELECT Id, case__r.Agent_Branch__c, case__r.Agent_Branch__r.EWI_Branch_Name__c, 
        Account__r.G_Number__c, Account__r.Name, House_No__c, Street__c, City__c, State__c, Postal_Code__c
        from Case_Participant__c 
        where (Account__r.G_Number__c =:gNumber OR Account__r.EWI_Landlord_Id__c =:gNumber ) AND case__r.recordtype.Name = 'Dispute EW Insured'
        //AND Case__r.Agent_Branch__r.EWI_Branch_Name__c != ''
        AND Case__r.Amount_of_Disputed_Funds_Remaining__c>0 AND Case__r.Evidence_Gathering_Start_Date__c!=null];
        return caseParList;
    }
    
    @AuraEnabled
    public static String sendEmailFromActivityTabAgain(Id recordId, Integer tempId, String fromEmail, String toEmails, String mailBody, String subject, String accId, String toCaseParId, List<String> uploadedFiles){
        
        String fromName = 'Tenancy Deposit Scheme';
        User usr = [select Id, Name, Title, FirstName, LastName, Email, Phone from User where Id =: UserInfo.getUserId()];
        if(usr.Email == fromEmail){
            String userName = '';
            userName += usr.Title!=null?usr.Title+' ':'';
            userName += usr.FirstName!=null?usr.FirstName+' ':'';
            userName += usr.LastName!=null?usr.LastName:'';
            fromName = userName;
        }
        
        String caseId = recordId;
        Case caseData;
        if(CaseId != null){
            caseData = [Select Id, status, Respond_Date__c From Case Where Id = :caseId];
        }
        
        HttpRequest req = mailJetAuthentication();
        
        Integer mailJetTemplateId;        
        List<API_Service__mdt> templateId = metaDataListbyLabel('EWIManualEMail'); 
        
        mailJetTemplateId  = Integer.valueof(templateId[0].Template_Id__c); //4025513;
        
        Map<String,recipient> recMap = new Map<String,recipient>();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();    
        gen.writeFieldName('Messages'); 
        List<String> emailsList = new List<String>();
        toEmails = toEmails.replaceAll(' ', '');
        if(toEmails.contains(',')){
            emailsList = toEmails.split(',');
        }else{
            emailsList.add(toEmails);
        }
        gen.writeStartArray();
        for(String to : emailsList)
        {
            recipient rec = new recipient(to, to, recordId, accId, toCaseParId);
            //recipient rec = new recipient(to, to, recordId);
            recMap.put(to,rec);
            
            gen.writeStartObject(); 
            gen.writeFieldName('From');
            
            gen.writeStartObject();
            gen.writeStringField('Email', fromEmail);  //'ashish.singh1@espire.com' // templateId[0].From_Address__c
            gen.writeStringField('Name', fromName );  //'SafeDeposits' // 'SafeDeposits Scotland'
            gen.writeEndObject();
            
            gen.writeFieldName('To');
            
            gen.writeStartArray();
            gen.writeStartObject(); 
            gen.writeStringField('Email',to); 
            gen.writeStringField('Name', to);
            gen.writeEndObject();      
            gen.writeEndArray();	
            
            gen.writeNumberField('TemplateID', mailJetTemplateId); 
            gen.writeBooleanField('TemplateLanguage', true);
            system.debug('subject**** '+subject );
            if(String.isNotBlank(Subject)){
                gen.writeStringField('Subject', Subject);
            }
            
            gen.writeFieldName('Variables');    
            
            gen.writeStartObject();
            gen.writeStringField('body',mailBody);
            gen.writeEndObject(); 
            
            gen.writeFieldName('Attachments');
            gen.writeStartArray();  
            for(String aFile: uploadedFiles){
                //String aFile = uploadedFiles[a];
                gen.writeStartObject();
                gen.writeStringField('ContentType', aFile.substringBetween('data:', ';base64')); 
                gen.writeStringField('Filename', aFile.substringBetween('fileName:', ';data:'));
                gen.writeStringField('Base64Content', aFile.substringAfter('base64,'));
                gen.writeEndObject();
            }
            gen.writeEndArray();
            
            gen.writeEndObject(); 
        }
        gen.writeEndArray();
        gen.writeEndObject();
        
        try{
            String jsonData = gen.getAsString();
            req.setBody(jsonData);
            system.debug(jsonData);
            Http http = new Http();
            HTTPResponse res;
            Date today = System.today();
            
            res = http.send(req);
            if(res.getStatusCode() == 200){
                String resBody = res.getBody();
                
                system.debug(resBody);                
                if(!resBody.startsWith('[')){
                    resBody = '['+resBody+']';
                }
                // recipient rec = new recipient(to,to,caseId);
                // recMap.put(to,rec);
                //saveMessageDetails(resBody,recMap,Subject );
                saveMessageDetailsAura(resBody,recMap,Subject,mailBody,tempId );
            }
            return 'Success';
            
            /*Http http = new Http();
            HTTPResponse res = http.send(req); 
            if(res.getStatusCode() == 200){
                String resBody = res.getBody();
                
                system.debug(resBody);                
                if(!resBody.startsWith('[')){
                    resBody = '['+resBody+']';
                }
                recipient rec = new recipient(to,to,caseId);
                recMap.put(to,rec);
                //saveMessageDetails(resBody,recMap,Subject );
                saveMessageDetailsAura(resBody,recMap,Subject,mailBody );
            }*/
            
            //system.debug('res-->>'+res.getBody());
        }
        catch(exception e){   
            //saveMessageDetails(resBody,recMap,Subject );
            system.debug(e);
            return 'Fail ' + e.getMessage() + 'line ' + e.getLineNumber();
            //Create Message(with error) from Here if no success response or it breaks  >>> res comes null  or status code is not expected 429 etc
        }
        
    }
    
    
    public static void saveMessageDetailsAura(String resJSON,Map<String,recipient> recMap, STring Subject,String body, integer tempId){
        List<response> jsonList = new  List<response>();
        //add try catch if deserialize breaks create Message with error
        try{
            jsonList =    ( List<response>) System.JSON.deserialize(resJSON, List<response>.class);
        }
        catch(Exception e){
            system.debug('ERROR --> '+e.getMessage());
        }
        system.debug(jsonList);
        List<Mailjet_Message__c> mailJetList = new List<Mailjet_Message__c>();
        
        /*List<Messages> msgList = jsonList[0].messages;
        
        for(integer i=0; i<msgList.size(); i++) {
            Messages msg = msgList[i];
            system.debug(msg);
            system.debug('>>>>>>>>>'+recMap);
            Mailjet_Message__c mm = new Mailjet_Message__c(response_status__c='success',Subject__c=Subject,Record_ID__c=recMap.get(msg.to[0].Email).recid,
                                                           Message_Id__c=msg.to[0].MessageID,Email_ID__c=msg.to[0].Email,sent_message__c =body);
            mailJetList.add(mm);
            
        }*/
        system.debug('jsonList => ' + jsonList);
        List<Messages> msgList = jsonList[0].messages;
        
        Matching_Temp_Var__c getTempDetails = [Select Template_Id__c, text_body__c, Subject__c, Is_Chaser_Email__c from Matching_Temp_Var__c where Template_Id__c =:String.valueOf(tempId) and Var_Name__c = '' ];
        set<Id> caseSetToUpdate = new set<Id>();

        for(integer i=0; i<msgList.size(); i++) {
           
            Mailjet_Message__c mm = new Mailjet_Message__c();
            Messages msg = msgList[i];
            
            mm.Account_Id__c = recMap.get(msg.to[0].Email).accId!=null&&recMap.get(msg.to[0].Email).accId!=''?recMap.get(msg.to[0].Email).accId:null;
            mm.Case_Participant__c = recMap.get(msg.to[0].Email).caseParId!=null&&recMap.get(msg.to[0].Email).caseParId!=''?recMap.get(msg.to[0].Email).caseParId:null;
            mm.response_status__c='success';
            mm.Subject__c=Subject;
            mm.Record_ID__c=recMap.get(msg.to[0].Email).recId;
            mm.Case__c=recMap.get(msg.to[0].Email).recId;
            mm.Message_Id__c=msg.to[0].MessageID;
            mm.Email_ID__c=msg.to[0].Email;
            mm.Template_Id__c = '4025513';
            mm.Sent_Message__c = body;
            mm.Source__c = 'EWI Insured';
            mm.Is_Chaser_Email__c = getTempDetails.Is_Chaser_Email__c;
            mailJetList.add(mm);
        
            if(mm.Is_Chaser_Email__c){
                caseSetToUpdate.add(recMap.get(msg.to[0].Email).recId);
            }
        }
    
        insert mailJetList;

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
            update casetoUpdate;
        }
    }
}