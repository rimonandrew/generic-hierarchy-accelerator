
@IsTest
private class GenericHierarchyControllerTest {

    @TestSetup
    static void createTestData() {

        String suffix = String.valueOf(DateTime.now().getTime());

        // Account hierarchy
        Account a1 = new Account(
            Name = 'Automated Test Account L1 ' + suffix,
            AccountNumber = 'T001' + suffix.right(5)
        );
        insert a1;

        Account a2 = new Account(
            Name = 'Automated Test Account L2 ' + suffix,
            AccountNumber = 'T002' + suffix.right(5),
            ParentId = a1.Id,
            Generic_Parent_Account__c = a1.Id
        );
        insert a2;

        Account a3 = new Account(
            Name = 'Automated Test Account L3 ' + suffix,
            AccountNumber = 'T003' + suffix.right(5),
            ParentId = a2.Id,
            Generic_Parent_Account__c = a2.Id
        );
        insert a3;

        Account a4 = new Account(
            Name = 'Automated Test Account L4 ' + suffix,
            AccountNumber = 'T004' + suffix.right(5),
            ParentId = a3.Id,
            Generic_Parent_Account__c = a3.Id
        );
        insert a4;

        Account a5 = new Account(
            Name = 'Automated Test Account L5 ' + suffix,
            AccountNumber = 'T005' + suffix.right(5),
            ParentId = a4.Id,
            Generic_Parent_Account__c = a4.Id
        );
        insert a5;

        // Contact hierarchy
        Contact c1 = new Contact(
            FirstName = 'AutoTest',
            LastName = 'Hierarchy L1 ' + suffix,
            Title = 'Director',
            Email = 'autotest.' + suffix + '.l1@example.test',
            AccountId = a1.Id
        );
        insertContact(c1);

        Contact c2 = new Contact(
            FirstName = 'AutoTest',
            LastName = 'Hierarchy L2 ' + suffix,
            Title = 'Manager',
            Email = 'autotest.' + suffix + '.l2@example.test',
            AccountId = a1.Id,
            ReportsToId = c1.Id
        );
        insertContact(c2);

        Contact c3 = new Contact(
            FirstName = 'AutoTest',
            LastName = 'Hierarchy L3 ' + suffix,
            Title = 'Team Lead',
            Email = 'autotest.' + suffix + '.l3@example.test',
            AccountId = a1.Id,
            ReportsToId = c2.Id
        );
        insertContact(c3);

        Contact c4 = new Contact(
            FirstName = 'AutoTest',
            LastName = 'Hierarchy L4 ' + suffix,
            Title = 'Senior Executive',
            Email = 'autotest.' + suffix + '.l4@example.test',
            AccountId = a1.Id,
            ReportsToId = c3.Id
        );
        insertContact(c4);

        Contact c5 = new Contact(
            FirstName = 'AutoTest',
            LastName = 'Hierarchy L5 ' + suffix,
            Title = 'Executive',
            Email = 'autotest.' + suffix + '.l5@example.test',
            AccountId = a1.Id,
            ReportsToId = c4.Id
        );
        insertContact(c5);
    }

    // Insert test Contacts while preserving org duplicate rules.
    private static void insertContact(Contact contactRecord) {

        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;

        Database.SaveResult result = Database.insert(
            contactRecord,
            options
        );

        System.assert(
            result.isSuccess(),
            'Test Contact insertion failed: ' +
            (result.getErrors().isEmpty()
                ? 'Unknown error'
                : result.getErrors()[0].getMessage())
        );
    }

    @IsTest
    static void testAccountHierarchyFromRoot() {

        Account parent = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L1%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);
        System.assertEquals('Account', result.objectApiName);
        System.assertEquals(parent.Id, result.root.recordId);
        System.assertEquals(1, result.root.level);
        System.assertEquals(1, result.root.children.size());
    }

    @IsTest
    static void testAccountHierarchyFromMiddleLevel() {

        Account level3 = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L3%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                level3.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result.root);
        System.assertEquals(
            true,
            result.root.children[0].children[0].isCurrent
        );
    }

    @IsTest
    static void testAccountFiveLevelHierarchy() {

        Account parent = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L1%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertEquals('Account', result.objectApiName);
        hierarchyNodeCheck(result.root, 1);
    }

    @IsTest
    static void testContactHierarchyFromRoot() {

        Contact parent = [
            SELECT Id
            FROM Contact
            WHERE LastName LIKE 'Hierarchy L1%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Contact_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);
        System.assertEquals('Contact', result.objectApiName);
        System.assertEquals(parent.Id, result.root.recordId);
        System.assertEquals(1, result.root.children.size());
    }

    @IsTest
    static void testContactHierarchyFromMiddleLevel() {

        Contact level3 = [
            SELECT Id
            FROM Contact
            WHERE LastName LIKE 'Hierarchy L3%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                level3.Id,
                'Contact_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result.root);
        System.assertEquals(
            true,
            result.root.children[0].children[0].isCurrent
        );
    }

    @IsTest
    static void testContactFiveLevelHierarchy() {

        Contact parent = [
            SELECT Id
            FROM Contact
            WHERE LastName LIKE 'Hierarchy L1%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Contact_Hierarchy'
            );

        Test.stopTest();

        System.assertEquals('Contact', result.objectApiName);
        hierarchyNodeCheck(result.root, 1);
    }

    // Checks hierarchy depth and child structure.
    private static void hierarchyNodeCheck(
        GenericHierarchyController.HierarchyNode node,
        Integer expectedLevel
    ) {

        System.assertNotEquals(null, node);
        System.assertEquals(expectedLevel, node.level);

        if (expectedLevel < 5) {

            System.assertEquals(1, node.children.size());

            hierarchyNodeCheck(
                node.children[0],
                expectedLevel + 1
            );

        } else {

            System.assertEquals(0, node.children.size());
        }
    }

    @IsTest
    static void testAutomaticConfigurationResolution() {

        Account parent = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L1%'
            LIMIT 1
        ];

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                null
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);
        System.assertEquals('Account', result.objectApiName);
        System.assertEquals(parent.Id, result.root.recordId);
    }

    @IsTest
    static void testInvalidConfigurationName() {

        Account parent = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L1%'
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Invalid_Hierarchy_Config'
            );

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An invalid configuration name should throw an exception.'
        );
    }

    @IsTest
    static void testObjectWithoutHierarchyConfiguration() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            GenericHierarchyController.getHierarchy(
                UserInfo.getUserId(),
                null
            );

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'An object without an active hierarchy configuration should throw an exception.'
        );
    }

    @IsTest
    static void testSingleAccountHierarchy() {

        Account standaloneAccount = new Account(
            Name = 'Standalone Hierarchy Test Account'
        );

        insert standaloneAccount;

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                standaloneAccount.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);
        System.assertEquals(standaloneAccount.Id, result.root.recordId);
        System.assertEquals(1, result.root.level);
        System.assertEquals(
            0,
            result.root.children.size(),
            'A standalone account should not have child nodes.'
        );
    }

    @IsTest
    static void testConfigurationObjectMismatch() {

        Contact testContact = [
            SELECT Id
            FROM Contact
            WHERE LastName LIKE 'Hierarchy L1%'
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            GenericHierarchyController.getHierarchy(
                testContact.Id,
                'Account_Hierarchy'
            );

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Account configuration should not work with a Contact record.'
        );
    }

    @IsTest
    static void testDeletedRecordHandling() {

        Account deletedAccount = new Account(
            Name = 'Deleted Hierarchy Test Account'
        );

        insert deletedAccount;

        Id deletedAccountId = deletedAccount.Id;

        delete deletedAccount;

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            GenericHierarchyController.getHierarchy(
                deletedAccountId,
                'Account_Hierarchy'
            );

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'The controller should handle a deleted hierarchy root.'
        );
    }

    @IsTest
    static void testNullRecordId() {

        Boolean exceptionThrown = false;

        try {

            GenericHierarchyController.getHierarchy(
                null,
                'Account_Hierarchy'
            );

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown);
    }

    // NEW TEST 1: Multiple children under the same parent.
    @IsTest
    static void testMultipleChildrenUnderSameParent() {

        String suffix = String.valueOf(DateTime.now().getTime());

        Account parent = new Account(
            Name = 'Multiple Children Parent ' + suffix
        );
        insert parent;

        Account child1 = new Account(
            Name = 'Multiple Children Child 1 ' + suffix,
            ParentId = parent.Id,
            Generic_Parent_Account__c = parent.Id
        );

        Account child2 = new Account(
            Name = 'Multiple Children Child 2 ' + suffix,
            ParentId = parent.Id,
            Generic_Parent_Account__c = parent.Id
        );

        insert new List<Account>{ child1, child2 };

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                parent.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);

        System.assertEquals(
            2,
            result.root.children.size(),
            'The parent should contain two child records.'
        );
    }

    // NEW TEST 2: Hierarchy must stop at five levels.
    @IsTest
    static void testHierarchyStopsAtMaximumFiveLevels() {

        Account level1 = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L1%'
            LIMIT 1
        ];

        Account level5 = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Automated Test Account L5%'
            LIMIT 1
        ];

        Account level6 = new Account(
            Name = 'Automated Test Account L6',
            ParentId = level5.Id,
            Generic_Parent_Account__c = level5.Id
        );

        insert level6;

        Test.startTest();

        GenericHierarchyController.HierarchyResponse result =
            GenericHierarchyController.getHierarchy(
                level1.Id,
                'Account_Hierarchy'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.root);

        hierarchyNodeCheck(result.root, 1);

        System.assertEquals(
            0,
            result.root.children[0]
                .children[0]
                .children[0]
                .children[0]
                .children.size(),
            'The hierarchy should stop at level five.'
        );
    }
    @IsTest
static void testAncestorCycleDetection() {

    Account accountA = new Account(
        Name = 'Cycle Test Account A'
    );
    insert accountA;

    Account accountB = new Account(
        Name = 'Cycle Test Account B'
    );
    insert accountB;

    Set<Id> visitedIds = new Set<Id>{
        accountA.Id,
        accountB.Id
    };

    // A previously visited ancestor must be detected.
    System.assertEquals(
        true,
        GenericHierarchyController.isAncestorAlreadyVisited(
            visitedIds,
            accountA.Id
        ),
        'A previously visited ancestor should be detected.'
    );

    // A new ancestor must not be treated as a cycle.
    System.assertEquals(
        false,
        GenericHierarchyController.isAncestorAlreadyVisited(
            visitedIds,
            UserInfo.getUserId()
        ),
        'An unvisited ID should not be treated as a cycle.'
    );

    // A null parent must stop ancestor traversal.
    System.assertEquals(
        true,
        GenericHierarchyController.isAncestorAlreadyVisited(
            visitedIds,
            null
        ),
        'A null ancestor should stop traversal.'
    );
}
}
