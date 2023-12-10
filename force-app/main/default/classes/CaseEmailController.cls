global without Sharing class CaseEmailController {
    global Case caseObject {get;set;}
    global string caseId = '5005g00000nK2mJAAS';
    public String emailTemplateName = 'Custom Template with vf';
    public String outputBody;
    
    
    global String getOutputBody(){
        CaseObject = [Select id from Case where Id ='5005g00000nK2mJAAS'];
        Emailtemplate emailT = [Select HtmlValue,id  from EmailTemplate where Name = 'Custom Template with vf'];
        
        
        //String inputText = 'This is some $$text$$ between $$symbols$$ that we want to $$capture$$.';
        
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailT.Id, userInfo.getUserId(), caseId);
        String htmlBody = mail.getHtmlBody();
        if(test.isRunningTest()){
            htmlBody='$$WM_Details__r.Prefrred_Date_Time__c$$';
        }
        String inputText = htmlBody;
        String pattern1 = '\\$\\$(.*?)\\$\\$';
        
        system.debug('inputText'+inputText);
        Pattern regex = Pattern.compile(pattern1);
        Matcher matcher = regex.matcher(inputText);
        
        List<String> dynamicFieldsToReplace = new List<String>();
        Map<String,String> resultMap;
        set<string> objectschemas = new set<string>();
        
        while (matcher.find()) {
            String capturedString = matcher.group(1);
            system.debug('capturedString'+capturedString);
            if (!dynamicFieldsToReplace.contains(capturedString)){
                
                if(capturedString.contains('__r')){
                   // system.debug(capturedString);
                   // system.debug(capturedString.split('\\.'));
                    string objectName=capturedString.split('\\.')[0].replace('__r','__c');
                    objectschemas.add(objectName);
                }
                dynamicFieldsToReplace.add(capturedString);
            }
        }
        
       
        if (dynamicFieldsToReplace != null && dynamicFieldsToReplace.size() > 0){
            resultMap = getDynamicFields(dynamicFieldsToReplace,caseId,objectschemas);
        }
        if (resultMap != null){
            for(String s : resultMap.keyset()){
                if(resultMap.get(s) != null){
                    htmlBody =htmlBody.replace('$$' + s + '$$',resultMap.get(s));
                }
                else{
                    htmlBody =htmlBody.replace('$$' + s + '$$','');
                }
            }
        }
		return htmlBody; 
    }
    
    private static Map<String,String> getDynamicFields(List<String> fieldsToQuery, String recordId,set<String> objectNames) {
        Map<String,String> resultMap = new Map<String,String>();
        
       
        Id recordId1 = Id.valueOf(recordId);
        set<String> fieldsToQueryUniqueset = new set<String>();
        fieldsToQueryUniqueset.addAll(fieldsToQuery);
        List<String> fieldsToQuerUiqueList = new List<String>();
        fieldsToQuerUiqueList.addAll(fieldsToQueryUniqueset);
        String sobjectType = recordId1.getSObjectType().getDescribe().getName();
        String dynamicSOQL ;
        
        dynamicSOQL = 'Select Id, ' + String.join(fieldsToQuerUiqueList,',') + ' From ' + sobjectType +' Where Id =:recordId1';
        system.debug(dynamicSOQL);
        List<sObject> documentGenerationList = Database.query(dynamicSOQL);
        sObject documentGenObject = documentGenerationList.get(0);
        system.debug(JSON.serialize(documentGenObject));
        map<string,Map<String,Schema.SObjectField>> objectSchemas =getObjectSchemas(objectNames);
        for(String s : fieldsToQuerUiqueList){
            //documentGenObject.getSObject('Primary_Borrower__r').get('Full_Name__c')
            //relationship queries need second level. 
            if (s.contains('__r')){
                system.debug(s);
                List<String> relationShipfield = s.split('\\.');
                //if (documentGenObject.getSObject(relationShipfield.get(0)) != null)
                //System.debug(relationShipfield);
                object value=documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1)); 
                resultMap.put(s,String.valueOF(documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1))));
               system.debug('value'+value);
                if( value!=null){
           		String objectName=relationShipfield.get(0).replace('__r','__c');
                if(objectSchemas.get(objectName)!=null){
                    system.debug(objectName);
                Map<String,Schema.SObjectField> fields= objectSchemas.get(objectName);
                    if(fields.containsKey(relationShipfield.get(1))){
                        String dataType=string.valueOf(fields.get(relationShipfield.get(1)).getDescribe().getType());
                         system.debug(dataType);
                        if(dataType.equals('DATETIME')){
                            datetime datetimeValue = (datetime)value;
                            system.debug(datetimeValue);
                            system.debug(string.valueOF(datetimeValue.format('MM-dd-yyyy HH:mm:ss', 'IST')));
                            resultMap.put(s,string.valueOf( datetimeValue.format('MM-dd-yyyy HH:mm:ss', 'IST')));
                           
                        }
                    }
                }
                }
            }
            else if(s.contains('.')) {
                system.debug('Coming here');
                
                String objectName = s.substring(0,s.indexOf('.'));
                String fieldName = s.substring(s.indexOf('.') + 1);
                system.debug('Coming '+ objectName);
                system.debug('Field Name '+ fieldName);
                resultMap.put(s,String.valueOF(documentGenObject.getSObject(objectName).get(fieldName)));
                //resultMap.put(s,String.valueOF(documentGenObject.get(s)));
            }
            else {
                resultMap.put(s,String.valueOF(documentGenObject.get(s)));
            } 
            
        }
        
        return resultMap;
    } 
    
    public static map<string,Map<String,Schema.SObjectField>> getObjectSchemas(set<String> objectNames){
       map<string,Map<String,Schema.SObjectField>> returnMap= new map<string,Map<String,Schema.SObjectField>>();
        for(String objectName: objectNames ){
     		 SObjectType s = Schema.getGlobalDescribe().get(objectName);
		if(s!=null){
            Map<String,Schema.SObjectField> mfields = s.getDescribe().fields.getMap();
            
                returnMap.put(objectName,mfields);
            }
        }
        return returnMap;
    }
}