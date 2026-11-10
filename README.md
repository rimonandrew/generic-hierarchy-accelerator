# Generic Hierarchy Accelerator for Salesforce

**Version:** 1.4.0
**Publisher:** Brite Systems
**Package Type:** Salesforce 1GP Unmanaged Package
**Release:** Beta

## Overview

Generic Hierarchy Accelerator is a reusable, metadata-driven Salesforce solution that displays record hierarchies using Lightning Web Components (LWC), Apex, and Custom Metadata Types.

Version 1.4.0 supports two standard Salesforce objects:

- **Account:** Uses the standard `ParentId` relationship.
- **Contact:** Uses the standard `ReportsToId` relationship.

The component automatically identifies the current record's object and loads the corresponding hierarchy configuration. Users do not need to manually select a configuration when adding the component to a Lightning Record Page.

The solution supports up to five hierarchy levels and works with existing Salesforce records and relationships.

## Features

- Supports standard Account and Contact hierarchies.
- Automatically detects the current record's object.
- Uses Account `ParentId` for Account hierarchies.
- Uses Contact `ReportsToId` for Contact hierarchies.
- Supports up to five hierarchy levels.
- Metadata-driven hierarchy configuration.
- Configurable display fields at each hierarchy level.
- Recursive Lightning Web Component rendering.
- Dynamic SOQL with user-mode access enforcement.
- Apex sharing enforcement.
- Custom Metadata-based configuration.
- Dedicated permission set for Apex controller access.
- No additional custom parent relationship fields required.

## Supported Objects

| Salesforce Object | Parent Relationship Field | Configuration |
|---|---|---|
| Account | `ParentId` | `Account_Hierarchy` |
| Contact | `ReportsToId` | `Contact_Hierarchy` |

**Release scope:** Version 1.4.0 is designed and packaged for standard Account and Contact hierarchies. Support for additional custom objects is outside the scope of this release.

## Architecture

| Component | API Name | Purpose |
|---|---|---|
| Apex Controller | `GenericHierarchyController` | Reads metadata and retrieves hierarchy records |
| Parent LWC | `genericHierarchyViewer` | Detects the current object and displays its hierarchy |
| Recursive Child LWC | `genericHierarchyNode` | Renders individual hierarchy nodes |
| Configuration CMDT | `Hierarchy_Configuration__mdt` | Defines object and parent relationship |
| Display CMDT | `Hierarchy_Display_Configuration__mdt` | Defines fields displayed at each level |
| Permission Set | `Generic_Hierarchy_User` | Grants access to the Apex controller |

## Prerequisites

For package installation and configuration:

- A compatible Salesforce org.
- Salesforce administrator access to install packages.
- Permission to assign permission sets.
- Permission to edit and activate Lightning Record Pages.

**Important:** Customers do not need Salesforce CLI, Visual Studio Code, or a source-code deployment to install and configure the released package.

## Installation

### 1. Install the Package

Use the Salesforce package installation link provided by Brite Systems.

For the current beta version:

[Install Generic Hierarchy Accelerator v1.4.0](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tak000000tEtZAAU)

Before proceeding, verify that the installation page displays:

- Package: Generic Hierarchy Accelerator
- Version: 1.4.0

Choose the appropriate installation access option and complete the installation.

For a sandbox org, use the corresponding Salesforce test login domain with the package installation path.

### 2. Verify Package Installation

1. Open Salesforce Setup.
2. Search for **Installed Packages**.
3. Locate Generic Hierarchy Accelerator.
4. Verify that version 1.4.0 is installed.

### 3. Assign the Permission Set

1. Open Setup.
2. Navigate to Permission Sets.
3. Open `Generic Hierarchy User`.
4. Select Manage Assignments.
5. Assign the permission set to the users who need to view hierarchies.

The permission set grants access to `GenericHierarchyController`.

Users must also have the required object-level and field-level read permissions for the records and fields displayed in the hierarchy.

### 4. Add the Component to the Account Record Page

1. Open an Account record.
2. Select Setup and navigate to Lightning App Builder.
3. Open the Account Record Page.
4. Drag **Generic Hierarchy Viewer** onto the page.
5. Leave the **Hierarchy Configuration Developer Name** property blank.
6. Save and activate the page.

The component automatically detects the Account object and loads the Account hierarchy configuration.

### 5. Add the Component to the Contact Record Page

1. Open a Contact record.
2. Navigate to Lightning App Builder.
3. Open the Contact Record Page.
4. Drag **Generic Hierarchy Viewer** onto the page.
5. Leave the **Hierarchy Configuration Developer Name** property blank.
6. Save and activate the page.

The component automatically detects the Contact object and loads the Contact hierarchy configuration.

### 6. View the Hierarchy

Open an Account or Contact record that has an existing parent relationship.

The component retrieves and displays the hierarchy based on the standard Salesforce relationship field.

No additional parent lookup fields or manual configuration selection are required.

## How Automatic Configuration Detection Works

The component uses the current Salesforce record ID to identify the object's API name.

The Apex controller then:

1. Identifies the current record's Salesforce object.
2. Retrieves the active hierarchy configuration for that object.
3. Identifies the configured parent relationship field.
4. Retrieves the corresponding display configuration records.
5. Builds the hierarchy up to five levels.
6. Returns the hierarchy data to the Lightning Web Component.

### Default Hierarchy Configurations

| Developer Name | Object API Name | Parent Field | Active |
|---|---|---|---|
| `Account_Hierarchy` | Account | `ParentId` | True |
| `Contact_Hierarchy` | Contact | `ReportsToId` | True |

The configuration property on the Lightning Web Component can remain blank for automatic detection.

An explicit configuration name is available for scenarios where a specific configuration needs to be selected.

## Custom Metadata Configuration

The accelerator uses two Custom Metadata Types.

### 1. Hierarchy Configuration

**Custom Metadata Type:** `Hierarchy_Configuration__mdt`

| Field | Purpose |
|---|---|
| `Object_API_Name__c` | Salesforce object API name |
| `Parent_Field_API_Name__c` | Field defining the parent relationship |
| `Is_Active__c` | Enables or disables the configuration |

The packaged configuration records define the Account and Contact hierarchy relationships.

### 2. Hierarchy Display Configuration

**Custom Metadata Type:** `Hierarchy_Display_Configuration__mdt`

| Field | Purpose |
|---|---|
| `Configuration_Key__c` | Links the display configuration to its hierarchy configuration |
| `Object_API_Name__c` | Salesforce object API name |
| `Hierarchy_Level__c` | Hierarchy level from 1 to 5 |
| `Display_Fields__c` | Comma-separated fields to display |
| `Is_Active__c` | Enables or disables the display configuration |

Each supported object has up to five display configuration records.

#### Example Account Display Fields

| Level | Example Display Fields |
|---|---|
| 1 | `Name,Phone` |
| 2 | `Name,AccountNumber,Phone,Type` |
| 3 | `Name,AccountNumber,Phone,Type` |
| 4 | `Name,AccountNumber,Phone,Type` |
| 5 | `Name,AccountNumber,Phone,Type` |

#### Example Contact Display Fields

| Level | Example Display Fields |
|---|---|
| 1 | `Name,Title,Email` |
| 2 | `Name,Title,Email` |
| 3 | `Name,Title,Email` |
| 4 | `Name,Title,Email` |
| 5 | `Name,Title,Email` |

Display fields can be maintained through Custom Metadata without modifying Apex or LWC code, subject to the controller's supported schema and security checks.

## Relationship Requirements

### Account Hierarchy

The Account hierarchy uses Salesforce's standard Parent Account relationship.

Field:

`Account.ParentId`

Example:

```text
GHA Global Corporation
    +-- GHA India
          +-- GHA Tamil Nadu
                +-- GHA Chennai
                      +-- GHA Chennai Branch
```

### Contact Hierarchy

The Contact hierarchy uses Salesforce's standard Reports To relationship.

Field:

`Contact.ReportsToId`

Example:

```text
GHA Contact1 - CEO
    +-- GHA Contact2 - Director
          +-- GHA Contact3 - Manager
                +-- GHA Contact4 - Team Lead
                      +-- GHA Contact5 - Employee
```

The relationships must be saved on the Salesforce records before the component can display them.

## Developer Setup

This section is intended for developers who want to work with the source project rather than install the released package.

### Prerequisites

- Salesforce CLI.
- Visual Studio Code.
- Salesforce Extension Pack.
- Access to a Salesforce development org.

### Project Structure

```text
generic-hierarchy-accelerator/
�
+-- force-app/
�   +-- main/
�       +-- default/
�           +-- classes/
�           �   +-- GenericHierarchyController.cls
�           �   +-- GenericHierarchyControllerTest.cls
�           �
�           +-- customMetadata/
�           �   +-- Hierarchy_Configuration.*
�           �   +-- Hierarchy_Display_Configuration.*
�           �
�           +-- lwc/
�           �   +-- genericHierarchyViewer/
�           �   +-- genericHierarchyNode/
�           �
�           +-- objects/
�           �   +-- Hierarchy_Configuration__mdt/
�           �   +-- Hierarchy_Display_Configuration__mdt/
�           �
�           +-- permissionsets/
�               +-- Generic_Hierarchy_User.permissionset-meta.xml
�
+-- manifest/
�   +-- package.xml
�
+-- README.md
+-- sfdx-project.json
```

### Clone the Repository

```bash
git clone https://github.com/rimonandrew/generic-hierarchy-accelerator.git

cd generic-hierarchy-accelerator
```

### Authorize a Development Org

```bash
sf org login web --alias GenericHierarchyDev
```

### Deploy the Source

```bash
sf project deploy start --manifest manifest/package.xml --target-org GenericHierarchyDev
```

### Assign the Permission Set

```bash
sf org assign permset --name Generic_Hierarchy_User --target-org GenericHierarchyDev
```

### Run Apex Tests

```bash
sf apex run test --class-names GenericHierarchyControllerTest --target-org GenericHierarchyDev --result-format human --wait 30
```

## Testing

The project includes the Apex test class:

`GenericHierarchyControllerTest`

### Latest Regression Test Results

The updated implementation was deployed and tested in both the development org and the original package org.

| Metric | Result |
|---|---:|
| Tests executed | 17 |
| Passed | 17 |
| Failed | 0 |
| Pass rate | 100% |

### Test Coverage

The test suite covers:

- Five-level Account hierarchy.
- Five-level Contact hierarchy.
- Account hierarchy from root records.
- Account hierarchy from middle-level records.
- Contact hierarchy from root records.
- Contact hierarchy from middle-level records.
- Multiple children under the same parent.
- Maximum five-level restriction.
- Automatic configuration resolution.
- Invalid configuration handling.
- Object configuration mismatch.
- Deleted record handling.
- Null record ID handling.
- Objects without hierarchy configuration.
- Ancestor cycle detection.

### Manual Validation Areas

Development validation has included:

- Account and Contact hierarchy rendering.
- Five-level hierarchy structures.
- Middle-level record navigation.
- Multiple children and branching hierarchies.
- Standard Account parent relationship using `ParentId`.
- Standard Contact Reports To relationship using `ReportsToId`.
- Metadata-driven display field changes.
- Empty hierarchies and invalid or inactive configurations.
- Object-level and field-level access restrictions.
- A 200-record hierarchy dataset.

The 200-record test was a development validation and is not a production-scale performance guarantee.

### Package Validation Status

Version 1.4.0 was successfully uploaded as a beta package version.

The Apex regression suite passed in both the development org and the original package org.

Version 1.4.0 was successfully installed in a clean Salesforce Developer Edition org. Account and Contact hierarchy rendering was manually verified after installation.

Broader production-scale performance, concurrent-user, and customer acceptance testing is still recommended before production adoption.

## Security

The solution follows Salesforce security practices:

- Apex controller uses `with sharing`.
- Dynamic queries use user-mode access enforcement.
- Object and field accessibility are checked.
- Invalid or inaccessible metadata is handled by the controller.
- Users require appropriate object and field permissions.
- Apex controller access is provided through the `Generic_Hierarchy_User` permission set.

## Current Limitations

- Supports Account and Contact hierarchies in version 1.4.0.
- Maximum supported hierarchy depth: five levels.
- Uses standard Account `ParentId` and Contact `ReportsToId` relationships.
- The current implementation retrieves child records without pagination or a configurable record cap.
- Very large hierarchies require additional scalability testing.
- Hierarchy rendering depends on valid configuration metadata and accessible relationship fields.
- Production-scale performance and concurrent-user testing are still recommended.

## Package Contents

The package includes:

- `GenericHierarchyController`
- `GenericHierarchyControllerTest`
- `Hierarchy_Configuration__mdt`
- `Hierarchy_Display_Configuration__mdt`
- Account hierarchy configuration records.
- Contact hierarchy configuration records.
- Five-level display configuration records for Account and Contact.
- `genericHierarchyViewer` Lightning Web Component.
- `genericHierarchyNode` Lightning Web Component.
- `Generic_Hierarchy_User` permission set.

No additional custom Account parent lookup field is required.

## License

Add your chosen license and distribution terms before publishing or distributing this project.

---

**Generic Hierarchy Accelerator | Brite Systems**
Version 1.4.0 | Beta Release