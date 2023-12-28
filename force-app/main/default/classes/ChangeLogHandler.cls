/**
 * @description       : Class to create change log records
 * @test class        :
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   27-12-2023   Shiji Mariam Mathew       Initial Version
 **/
public with sharing class ChangeLogHandler {
    public static String source;
    public static String updatedBy;

    public ChangeLogHandler() {
    }

    public void createdFieldHistoryOnInsert(String objectName, Map<Id, SObject> newMap) {
        system.debug('objectName: ' + objectName);
        system.debug(newMap);
        system.debug('source: ' + source);
        system.debug('updatedBy: ' + updatedBy);
        List<Change_Log__c> fhList = new List<Change_Log__c>();
        if (Label.FHS_User_Name == UserInfo.getName()) {
            source = 'FHS';
            updatedBy = UserInfo.getUserId();
        }
        for (String recId : newMap.keySet()) {
            Change_Log__c historyRecord = getFieldHistoryRecord(
                recId,
                objectName,
                source,
                updatedBy,
                false,
                '',
                '',
                '',
                new Map<Id, String>()
            );
            fhList.add(historyRecord);
            system.debug(historyRecord);
        }
        system.debug('fhList: ' + fhList);
        if (!fhList.isEmpty()) {
            upsertFieldHistoryList(fhList);
        }
    }

    public void createdFieldHistoryOnUpdate(String objectName, Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        system.debug('objectName: ' + objectName);
        system.debug(oldMap);
        system.debug(newMap);
        system.debug('source: ' + source);
        system.debug('updatedBy: ' + updatedBy);
        if (Label.FHS_User_Name == UserInfo.getName()) {
            source = 'FHS';
            updatedBy = UserInfo.getUserId();
        }
        Set<String> fieldAPINamesToCheck = getFieldNamesToCheck(objectName);
        List<Change_Log__c> fhList = new List<Change_Log__c>();
        Map<Id, String> relatedLookupMap = new Map<Id, String>();
        Map<String, List<String>> objRecsToQueryMap = new Map<String, List<String>>();
        for (String recId : newMap.keySet()) {
            for (String fieldAPI : fieldAPINamesToCheck) {
                if (newMap.get(recId).get(fieldAPI) != oldMap.get(recId).get(fieldAPI)) {
                    if (getFieldTypefromAPIName(objectName, fieldAPI) == 'REFERENCE') {
                        if (
                            newMap.get(recId).get(fieldAPI) != null &&
                            String.valueOf(newMap.get(recId).get(fieldAPI)) != ''
                        )
                            relatedLookupMap.put(String.valueOf(newMap.get(recId).get(fieldAPI)), '');
                        if (
                            oldMap.get(recId).get(fieldAPI) != null &&
                            String.valueOf(oldMap.get(recId).get(fieldAPI)) != ''
                        )
                            relatedLookupMap.put(String.valueOf(oldMap.get(recId).get(fieldAPI)), '');
                    }
                }
            }
        }
        system.debug('relatedLookupMap:' + relatedLookupMap);
        for (Id recordId : relatedLookupMap.keyset()) {
            system.debug('recordId: ' + recordId);
            List<String> recsList = new List<String>();
            String objName = recordId.getSObjectType().getDescribe().getName();
            if (objRecsToQueryMap.containsKey(objName)) {
                recsList = objRecsToQueryMap.get(objName);
            }
            recsList.add(recordId);
            objRecsToQueryMap.put(objName, recsList);
        }
        List<SObject> relatedRecs;
        system.debug('objRecsToQueryMap:' + objRecsToQueryMap);
        for (String objName : objRecsToQueryMap.keyset()) {
            List<String> recIds = objRecsToQueryMap.get(objName);
            relatedRecs = Database.query('SELECT Id, Name FROM ' + objName + ' WHERE Id IN: recIds');
            for (SObject rec : relatedRecs) {
                system.debug('rec:' + rec);
                relatedLookupMap.put(rec.Id, String.valueOf(rec.get('Name')));
            }
        }
        system.debug('relatedLookupMap:' + relatedLookupMap);

        for (String recId : newMap.keySet()) {
            for (String fieldAPI : fieldAPINamesToCheck) {
                if (newMap.get(recId).get(fieldAPI) != oldMap.get(recId).get(fieldAPI)) {
                    Change_Log__c historyRecord = getFieldHistoryRecord(
                        recId,
                        objectName,
                        source,
                        updatedBy,
                        true,
                        fieldAPI,
                        String.valueOf(newMap.get(recId).get(fieldAPI)),
                        String.valueOf(oldMap.get(recId).get(fieldAPI)),
                        relatedLookupMap
                    );
                    fhList.add(historyRecord);
                    system.debug(historyRecord);
                }
            }
        }
        system.debug('fhList: ' + fhList);
        if (!fhList.isEmpty()) {
            upsertFieldHistoryList(fhList);
        }
    }

    public void deleteFieldHistoryList(List<Change_Log__c> fhList) {
        if (!fhList.isEmpty()) {
            try {
                delete fhList;
            } catch (exception e) {
                system.debug('Exception while Deleting Field History Record');
                system.debug(e);
                system.debug('Exception: ' + e.getLineNumber() + ' --' + e.getMessage());
            }
        }
    }

    public Set<String> getFieldNamesToCheck(String objectName) {
        system.debug('objectName: ' + objectName);
        Set<String> fieldAPINamesToCheck = new Set<String>();
        try {
            /*
            for (History_Tracking_Configuration__mdt trackingList : [
                SELECT Field_API_Name__c
                FROM History_Tracking_Configuration__mdt
                WHERE Object__c = :objectName AND Is_Active__c = TRUE
            ]) {
                fieldAPINamesToCheck.add(trackingList.Field_API_Name__c);
            }
             ZKS-961
            */

            for (
                History_Tracking_Configuration__mdt trackingList : History_Tracking_Configuration__mdt.getAll().values()
            ) {
                if (trackingList.Is_Active__c && trackingList.Object__c == objectName)
                    fieldAPINamesToCheck.add(trackingList.Field_API_Name__c);
            }
        } catch (exception e) {
            system.debug('Exception while Fetching Field API Names to check: ');
            system.debug(e);
            system.debug('Exception: ' + e.getLineNumber() + ' --' + e.getMessage());
        }
        system.debug('fieldAPINamesToCheck: ' + fieldAPINamesToCheck);
        return fieldAPINamesToCheck;
    }

    public Change_Log__c getFieldHistoryRecord(
        String recId,
        String objectName,
        String source,
        String updatedBy,
        Boolean isUpdate,
        String fieldAPI,
        String newValue,
        String oldValue,
        Map<Id, String> relatedLookupMap
    ) {
        system.debug('relatedLookupMap:' + relatedLookupMap);
        Change_Log__c historyRecord = new Change_Log__c();

        historyRecord.Date__c = system.now();
        if (isUpdate) {
            historyRecord.Field__c = getFieldLabelfromAPIName(objectName, fieldAPI);
            historyRecord.Field_API_Name__c = fieldAPI;
            String fieldTypeVal = getFieldTypefromAPIName(objectName, fieldAPI);
            if (fieldTypeVal == 'PICKLIST') {
                historyRecord.New_Value__c = getPicklistLabelfromAPI(objectName, fieldAPI, newValue);
                historyRecord.Original_Value__c = getPicklistLabelfromAPI(objectName, fieldAPI, oldValue);
            } else if (fieldTypeVal == 'REFERENCE') {
                historyRecord.New_Value__c = relatedLookupMap.get(newValue);
                historyRecord.Original_Value__c = relatedLookupMap.get(oldValue);
            } else {
                historyRecord.New_Value__c = newValue;
                historyRecord.Original_Value__c = oldValue;
            }
        } else {
            historyRecord.Field__c = 'Created.';
        }

        historyRecord.Source__c = (source != null && source != '') ? source : 'SALESFORCE';
        if (updatedBy != null && updatedBy != '') {
            if (updatedBy.startsWith('003')) {
                historyRecord.Action_Done_By_Contact__c = updatedBy;
            } else if (updatedBy.startsWith('005')) {
                historyRecord.Action_Done_By_User__c = updatedBy;
            } else if (updatedBy.startsWith('001')) {
                historyRecord.Action_Done_By_Account__c = updatedBy; // ZKS-783_V2
            } else {
                historyRecord.Action_Done_By_Name__c = updatedBy;
            }
        } else {
            historyRecord.Action_Done_By_User__c = UserInfo.getUserId();
        }

        historyRecord.Opportunity__c = (objectName == 'Opportunity') ? recId : null;
        historyRecord.Treatment_Plan__c = (objectName == 'Treatment_Plan__c') ? recId : null;
        historyRecord.Treatment_Plan_Version__c = (objectName == 'Treatment_Plan_Version__c') ? recId : null;
        return historyRecord;
    }

    public void upsertFieldHistoryList(List<Change_Log__c> fhList) {
        if (!fhList.isEmpty()) {
            try {
                upsert fhList;
            } catch (exception e) {
                system.debug('Exception while Upserting Field History Record');
                system.debug(e);
                system.debug('Exception: ' + e.getLineNumber() + ' --' + e.getMessage());
            }
        }
    }
}
