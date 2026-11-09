
public with sharing class GenericHierarchyController {

    private static final Integer MAX_LEVELS = 5;
    @TestVisible
private static Boolean isAncestorAlreadyVisited(
    Set<Id> visitedIds,
    Id nextAncestorId
) {
    return nextAncestorId == null ||
        visitedIds.contains(nextAncestorId);
}
    public class HierarchyNode {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String recordName { get; set; }
        @AuraEnabled public Integer level { get; set; }
        @AuraEnabled public Boolean isCurrent { get; set; }
        @AuraEnabled public Map<String, Object> fieldValues { get; set; }
        @AuraEnabled public List<HierarchyNode> children { get; set; }

        public HierarchyNode() {
            fieldValues = new Map<String, Object>();
            children = new List<HierarchyNode>();
            isCurrent = false;
        }
    }

    public class HierarchyResponse {
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String hierarchyName { get; set; }
        @AuraEnabled public List<String> displayFields { get; set; }
        @AuraEnabled public HierarchyNode root { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static HierarchyResponse getHierarchy(
        Id recordId,
        String configurationName
    ) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }

        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();

        String actualObjectName =
            recordId.getSObjectType().getDescribe().getName();

        Hierarchy_Configuration__mdt config;

        // Resolve hierarchy configuration.
        if (String.isNotBlank(configurationName)) {
            config = Hierarchy_Configuration__mdt.getInstance(
                configurationName.trim()
            );
        } else {
            List<Hierarchy_Configuration__mdt> matchingConfigs = [
                SELECT DeveloperName, MasterLabel,
                       Object_API_Name__c,
                       Parent_Field_API_Name__c,
                       Is_Active__c
                FROM Hierarchy_Configuration__mdt
                WHERE Object_API_Name__c = :actualObjectName
                AND Is_Active__c = true
            ];

            if (matchingConfigs.size() != 1) {
                throw new AuraHandledException(
                    'Provide a configuration name when the object has ' +
                    'zero or multiple active hierarchy configurations.'
                );
            }

            config = matchingConfigs[0];
        }

        if (config == null || config.Is_Active__c != true) {
            throw new AuraHandledException(
                'The requested hierarchy configuration is missing or inactive.'
            );
        }

        String objectApiName = config.Object_API_Name__c;
        String parentField = config.Parent_Field_API_Name__c;

        if (String.isBlank(objectApiName) ||
            String.isBlank(parentField)) {
            throw new AuraHandledException(
                'Object API Name and Parent Field API Name are required.'
            );
        }

        if (objectApiName != actualObjectName) {
            throw new AuraHandledException(
                'The configuration object does not match the current record.'
            );
        }

        if (!globalDescribe.containsKey(objectApiName)) {
            throw new AuraHandledException(
                'The configured Salesforce object does not exist.'
            );
        }

        Schema.DescribeSObjectResult objectDescribe =
            globalDescribe.get(objectApiName).getDescribe();

        if (!objectDescribe.isAccessible()) {
            throw new AuraHandledException(
                'You do not have permission to read this object.'
            );
        }

        Map<String, Schema.SObjectField> fieldMap =
            objectDescribe.fields.getMap();

        // Validate parent relationship field.
        if (!fieldMap.containsKey(parentField)) {
            throw new AuraHandledException(
                'The configured parent field does not exist.'
            );
        }

        Schema.DescribeFieldResult parentDescribe =
            fieldMap.get(parentField).getDescribe();

        if (!parentDescribe.isAccessible()) {
            throw new AuraHandledException(
                'You do not have permission to read the parent field.'
            );
        }

        if (parentDescribe.getType() != Schema.DisplayType.REFERENCE) {
            throw new AuraHandledException(
                'The configured parent field must be a reference field.'
            );
        }

        Boolean referencesConfiguredObject = false;

        for (Schema.SObjectType referenceType :
             parentDescribe.getReferenceTo()) {

            if (referenceType.getDescribe().getName() == objectApiName) {
                referencesConfiguredObject = true;
                break;
            }
        }

        if (!referencesConfiguredObject) {
            throw new AuraHandledException(
                'The parent field must reference the configured object.'
            );
        }

        // Retrieve display configurations.
        String configKey = config.DeveloperName;

        List<Hierarchy_Display_Configuration__mdt> displayConfigs = [
            SELECT Object_API_Name__c,
                   Configuration_Key__c,
                   Hierarchy_Level__c,
                   Display_Fields__c,
                   Is_Active__c
            FROM Hierarchy_Display_Configuration__mdt
            WHERE Configuration_Key__c = :configKey
            AND Object_API_Name__c = :objectApiName
            AND Is_Active__c = true
            ORDER BY Hierarchy_Level__c
        ];

        if (displayConfigs.isEmpty()) {
            throw new AuraHandledException(
                'No active display configurations were found.'
            );
        }

        Map<Integer, List<String>> fieldsByLevel =
            new Map<Integer, List<String>>();

        Set<String> allSelectedFields =
            new Set<String>{'Id', parentField};

        List<String> allDisplayFields = new List<String>();

        // Add Name to the query when available and accessible.
        // This prevents an unselected-field exception for recordName.
        if (fieldMap.containsKey('Name') &&
            fieldMap.get('Name').getDescribe().isAccessible()) {
            allSelectedFields.add('Name');
        }

        // Validate and prepare configured display fields.
        for (Hierarchy_Display_Configuration__mdt displayConfig :
             displayConfigs) {

            if (displayConfig.Hierarchy_Level__c == null) {
                continue;
            }

            Integer levelNumber =
                displayConfig.Hierarchy_Level__c.intValue();

            if (levelNumber < 1 || levelNumber > MAX_LEVELS) {
                continue;
            }

            if (fieldsByLevel.containsKey(levelNumber)) {
                throw new AuraHandledException(
                    'Duplicate display configuration for level ' +
                    levelNumber + '.'
                );
            }

            List<String> levelFields = new List<String>();

            if (String.isNotBlank(displayConfig.Display_Fields__c)) {

                for (String fieldName :
                     displayConfig.Display_Fields__c.split(',')) {

                    String cleanField = fieldName.trim();

                    if (String.isBlank(cleanField) ||
                        !fieldMap.containsKey(cleanField)) {
                        continue;
                    }

                    if (!fieldMap.get(cleanField)
                        .getDescribe().isAccessible()) {
                        continue;
                    }

                    if (!levelFields.contains(cleanField)) {
                        levelFields.add(cleanField);
                        allSelectedFields.add(cleanField);

                        if (!allDisplayFields.contains(cleanField)) {
                            allDisplayFields.add(cleanField);
                        }
                    }
                }
            }

            fieldsByLevel.put(levelNumber, levelFields);
        }

        if (fieldsByLevel.isEmpty()) {
            throw new AuraHandledException(
                'No valid hierarchy levels are configured.'
            );
        }

        if (!fieldsByLevel.containsKey(1)) {
            throw new AuraHandledException(
                'An active Level 1 display configuration is required.'
            );
        }

        String queryFields = String.join(
            new List<String>(allSelectedFields),
            ','
        );

        // Find the highest accessible ancestor within five levels.
        // This uses a maximum of four bounded ancestor queries.
        Id rootId = recordId;

        Set<Id> ancestorIds = new Set<Id>{recordId};

        Id nextAncestorId;

        for (Integer depth = 1; depth < MAX_LEVELS; depth++) {

            List<SObject> currentRecords = Database.queryWithBinds(
                'SELECT Id, ' + parentField +
                ' FROM ' + objectApiName +
                ' WHERE Id = :searchId LIMIT 1',
                new Map<String, Object>{
                    'searchId' => rootId
                },
                AccessLevel.USER_MODE
            );

            if (currentRecords.isEmpty()) {
                break;
            }

            nextAncestorId =
                (Id) currentRecords[0].get(parentField);

           if (isAncestorAlreadyVisited(
    ancestorIds,
    nextAncestorId
)) {
    break;
}

            ancestorIds.add(nextAncestorId);
            rootId = nextAncestorId;
        }

        // Prepare hierarchy collections.
        HierarchyNode rootNode;

        Map<Id, HierarchyNode> nodeMap =
            new Map<Id, HierarchyNode>();

        // Stores the parent ID for each child.
        // This eliminates individual parent queries per node.
        Map<Id, Id> parentByChildId =
            new Map<Id, Id>();

        Set<Id> processedIds = new Set<Id>();

        Set<Id> currentLevelIds = new Set<Id>{rootId};

        // Retrieve and construct up to five hierarchy levels.
        for (Integer level = 1; level <= MAX_LEVELS; level++) {

            if (currentLevelIds.isEmpty()) {
                break;
            }

            List<SObject> levelRecords = Database.queryWithBinds(
                'SELECT ' + queryFields +
                ' FROM ' + objectApiName +
                ' WHERE Id IN :recordIds',
                new Map<String, Object>{
                    'recordIds' => currentLevelIds
                },
                AccessLevel.USER_MODE
            );

            for (SObject record : levelRecords) {

                Id currentId = (Id) record.get('Id');

                if (processedIds.contains(currentId)) {
                    continue;
                }

                processedIds.add(currentId);

                HierarchyNode node = new HierarchyNode();

                node.recordId = currentId;
                node.level = level;
                node.isCurrent = currentId == recordId;

                List<String> levelFields =
                    fieldsByLevel.get(level);

                // Populate configured field values.
                if (levelFields != null) {

                    for (String fieldName : levelFields) {

                        node.fieldValues.put(
                            fieldName,
                            record.get(fieldName)
                        );
                    }
                }

                // Resolve the record title.
                if (fieldMap.containsKey('Name') &&
                    fieldMap.get('Name').getDescribe().isAccessible()) {

                    node.recordName =
                        String.valueOf(record.get('Name'));

                } else if (levelFields != null &&
                           !levelFields.isEmpty()) {

                    Object displayValue =
                        record.get(levelFields[0]);

                    node.recordName = displayValue == null
                        ? String.valueOf(currentId)
                        : String.valueOf(displayValue);

                } else {

                    node.recordName = String.valueOf(currentId);
                }

                nodeMap.put(currentId, node);

                if (currentId == rootId) {
                    rootNode = node;
                }
            }

            if (level == MAX_LEVELS) {
                break;
            }

            // Retrieve children for the current level.
            List<SObject> childRecords = Database.queryWithBinds(
                'SELECT Id, ' + parentField +
                ' FROM ' + objectApiName +
                ' WHERE ' + parentField + ' IN :parentIds',
                new Map<String, Object>{
                    'parentIds' => currentLevelIds
                },
                AccessLevel.USER_MODE
            );

            Set<Id> nextLevelIds = new Set<Id>();

            for (SObject child : childRecords) {

                Id childId = (Id) child.get('Id');

                Id childParentId =
                    (Id) child.get(parentField);

                if (!processedIds.contains(childId)) {

                    nextLevelIds.add(childId);

                    parentByChildId.put(
                        childId,
                        childParentId
                    );
                }
            }

            currentLevelIds = nextLevelIds;
        }

        if (rootNode == null) {
            throw new AuraHandledException(
                'The hierarchy root could not be accessed.'
            );
        }

        // Connect hierarchy nodes without additional SOQL queries.
        for (Id childId : parentByChildId.keySet()) {

            Id nodeParentId =
                parentByChildId.get(childId);

            if (nodeMap.containsKey(childId) &&
                nodeMap.containsKey(nodeParentId)) {

                nodeMap.get(nodeParentId).children.add(
                    nodeMap.get(childId)
                );
            }
        }

        // Prepare response for the LWC.
        HierarchyResponse response = new HierarchyResponse();

        response.objectApiName = objectApiName;
        response.hierarchyName = config.MasterLabel;
        response.displayFields = allDisplayFields;
        response.root = rootNode;

        return response;
    }
}
