/**
 * @description       : Utility Class for generic methods
 * @test class        :
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   27-12-2023   Shiji Mariam Mathew       Initial Version
 **/
public with sharing class ApexUtility {
    /******************************************************************************************************************
     * @Method Name    : getObjectLabelfromAPIName
     * @description    : Method to fetch object label from object API Name
     * @param          : 1. String objectAPIName - API Name of Object
     * @return         : 1. String objetLabel - label of Field
     *****************************************************************************************************************/
    public static String getObjectLabelfromAPIName(String objectAPIName) {
        if (!String.IsBlank(objectAPIName)) {
            return String.valueOf(Schema.getGlobalDescribe().get(objectAPIName).getDescribe().getLabel());
        } else {
            return objectAPIName;
        }
    }

    /******************************************************************************************************************
     * @Method Name    : getFieldLabelfromAPIName
     * @description    : Method to fetch field label from Field API Name
     * @param          : 1. String objectAPIName - API Name of Object
     *                 : 2. String fieldAPIName - API Name of field
     * @return         : 1. String fieldLabel - label of Field
     *****************************************************************************************************************/
    public static String getFieldLabelfromAPIName(String objectAPIName, String fieldAPIName) {
        if (!String.IsBlank(objectAPIName) && !String.IsBlank(fieldAPIName)) {
            SObject instance = (SObject) Type.forName('Schema.' + objectAPIName).newInstance();
            return String.valueOf(
                instance.getSObjectType().getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getLabel()
            );
        } else {
            return fieldAPIName;
        }
    }

    /******************************************************************************************************************
     * @Method Name    : getFieldTypefromAPIName
     * @description    : Method to fetch field type from Field API Name
     * @param          : 1. String objectAPIName - API Name of Object
     *                 : 2. String fieldAPIName - API Name of field
     * @return         : 1. String fieldType - type of Field
     *****************************************************************************************************************/
    public static String getFieldTypefromAPIName(String objectAPIName, String fieldAPIName) {
        if (!String.IsBlank(objectAPIName) && !String.IsBlank(fieldAPIName)) {
            SObject instance = (SObject) Type.forName('Schema.' + objectAPIName).newInstance();
            return String.valueOf(
                instance.getSObjectType().getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getType()
            );
        } else {
            return fieldAPIName;
        }
    }

    /******************************************************************************************************************
     * @Method Name    : getPicklistLabelfromAPIName
     * @description    : Method to fetch picklist label from picklist API Name
     * @param          : 1. String objectAPIName - API Name of Object
     *                 : 2. String fieldAPIName - API Name of the picklist field
     *                 : 3. String valueAPIName - API Name of the picklist value
     * @return         : 1. String valueLabel - label of the picklist value
     *****************************************************************************************************************/
    public static String getPicklistLabelfromAPI(String objectAPIName, String fieldAPIName, String valueAPIName) {
        if (!String.IsBlank(objectAPIName) && !String.IsBlank(valueAPIName)) {
            String valueLabel = valueAPIName;
            SObject instance = (SObject) Type.forName('Schema.' + objectAPIName).newInstance();
            List<Schema.PicklistEntry> ple = instance.getSObjectType()
                .getDescribe()
                .fields.getMap()
                .get(fieldAPIName)
                .getDescribe()
                .getPickListValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                if (pickListVal.getValue() == valueAPIName) {
                    valueLabel = pickListVal.getLabel();
                }
            }
            return valueLabel;
        } else {
            return valueAPIName;
        }
    }
}
