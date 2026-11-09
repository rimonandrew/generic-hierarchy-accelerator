# Generic Hierarchy Accelerator for Salesforce

A reusable, metadata-driven Salesforce solution for displaying record hierarchies across standard and custom objects.

The Generic Hierarchy Accelerator uses Apex, Lightning Web Components (LWC), and Custom Metadata Types to render configurable parent-child relationships without hardcoding object-specific hierarchy logic.

## Features

- Supports up to five hierarchy levels.
- Configurable Salesforce objects and parent relationship fields.
- Configurable fields displayed at each hierarchy level.
- Reusable across Account, Contact, and supported custom objects.
- Recursive Lightning Web Component rendering.
- Dynamic SOQL with user-mode access enforcement.
- Apex sharing enforcement.
- Configuration changes through Custom Metadata Types without changing Apex or LWC code.
- Permission Set for Apex controller access.
- Supports custom parent relationship fields, including the sample Account lookup field.

## Architecture

| Component | API Name | Purpose |
|---|---|---|
| Apex Controller | `GenericHierarchyController` | Reads metadata and retrieves hierarchy records |
| Parent LWC | `genericHierarchyViewer` | Loads and displays the hierarchy |
| Recursive Child LWC | `genericHierarchyNode` | Renders individual hierarchy nodes |
| Configuration CMDT | `Hierarchy_Configuration__mdt` | Defines object and parent relationship |
| Display CMDT | `Hierarchy_Display_Configuration__mdt` | Defines fields displayed at each level |
| Permission Set | `Generic_Hierarchy_User` | Grants access to the Apex controller |

## Prerequisites

- Salesforce Developer Edition, Sandbox, or compatible Salesforce org.
- Salesforce CLI.
- VS Code with Salesforce Extension Pack.
- Access to deploy Apex, Lightning Web Components, Custom Metadata Types, Custom Fields, and Permission Sets.

## Project Structure

```text
force-app/
  main/
    default/
      classes/
        GenericHierarchyController.cls
        GenericHierarchyControllerTest.cls
      customMetadata/
        Hierarchy_Configuration.*
        Hierarchy_Display_Configuration.*
      lwc/
        genericHierarchyViewer/
        genericHierarchyNode/
      objects/
        Account/
          fields/
            Generic_Parent_Account__c.field-meta.xml
        Hierarchy_Configuration__mdt/
        Hierarchy_Display_Configuration__mdt/
      permissionsets/
        Generic_Hierarchy_User.permissionset-meta.xml

manifest/
  package.xml

README.md
sfdx-project.json
```

## Installation

### 1. Clone or download the project

```bash
git clone <repository-url>
cd generic-hierarchy-accelerator
```

### 2. Authorize your Salesforce org

```bash
sf org login web --alias GenericHierarchyDev
```

### 3. Deploy the solution

```bash
sf project deploy start --manifest manifest/package.xml --target-org GenericHierarchyDev
```

For deployment validation without deploying the changes:

```bash
sf project deploy validate --manifest manifest/package.xml --target-org GenericHierarchyDev --test-level RunLocalTests
```

### 4. Assign the permission set

```bash
sf org assign permset --name Generic_Hierarchy_User --target-org GenericHierarchyDev
```

The permission set grants access to `GenericHierarchyController`.

Users must also have the necessary object and field read permissions for the configured hierarchy objects and display fields. The controller enforces record sharing and user-mode query access.

**Important:** The sample Custom Metadata configuration records are maintained in the source repository. If they are not included in the installed unmanaged package version, deploy them separately from the source project.

## Configuration

The accelerator is controlled through two Custom Metadata Types.

### 1. Hierarchy Configuration

Custom Metadata Type: `Hierarchy_Configuration__mdt`

| Field | Purpose |
|---|---|
| `Object_API_Name__c` | Salesforce object API name |
| `Parent_Field_API_Name__c` | Field defining the parent relationship |
| `Is_Active__c` | Enables or disables the configuration |

Each configuration record uses its Developer Name as the configuration name passed to the LWC.

Example:

| Developer Name | Object | Parent Field | Active |
|---|---|---|---|
| `Account_Hierarchy` | Account | `Generic_Parent_Account__c` | True |
| `Contact_Hierarchy` | Contact | `ReportsToId` | True |

### 2. Hierarchy Display Configuration

Custom Metadata Type: `Hierarchy_Display_Configuration__mdt`

| Field | Purpose |
|---|---|
| `Configuration_Key__c` | Links the display record to its hierarchy configuration |
| `Object_API_Name__c` | Object API name |
| `Hierarchy_Level__c` | Hierarchy level from 1 to 5 |
| `Display_Fields__c` | Comma-separated fields to display |
| `Is_Active__c` | Enables or disables the display configuration |

Example Account configuration:

| Level | Display Fields |
|---|---|
| 1 | `Name,Industry,Website` |
| 2 | `Name,Phone` |
| 3 | `Name,AccountNumber,Phone,Type` |
| 4 | `Name,AccountNumber,Phone,Type` |
| 5 | `Name,AccountNumber,Phone,Type` |

Example Contact configuration:

| Level | Display Fields |
|---|---|
| 1 | `Name,Title,Email` |
| 2 | `Name,Title,Email` |
| 3 | `Name,Title,Email` |
| 4 | `Name,Title,Email` |
| 5 | `Name,Title,Email` |

The configuration key must match the Developer Name of the corresponding Hierarchy Configuration record.

## Add the LWC to a Lightning Record Page

1. Open Salesforce Setup.
2. Navigate to Lightning App Builder.
3. Create or edit a Lightning Record Page.
4. Drag **Generic Hierarchy Viewer** onto the page.
5. Set the Hierarchy Configuration Developer Name property.

Examples:

- Account record page: `Account_Hierarchy`
- Contact record page: `Contact_Hierarchy`

6. Save and activate the page.
7. Open a record to view its hierarchy.

The component uses the current record ID and the selected configuration to retrieve the hierarchy.

## Configure a New Object

To support another object:

1. Identify the object API name.
2. Identify a parent relationship field that references the same object.
3. Create a Hierarchy Configuration record.
4. Set the object API name, parent field API name, and active status.
5. Create up to five Hierarchy Display Configuration records.
6. Set the matching configuration key, object API name, hierarchy level, display fields, and active status.
7. Add Generic Hierarchy Viewer to the object's Lightning Record Page.
8. Set its configuration Developer Name.

No object-specific Apex or LWC changes should be required when the object and relationship satisfy the controller's supported schema requirements.

## Testing

The project includes `GenericHierarchyControllerTest`.

Run local Apex tests:

```bash
sf apex run test --class-names GenericHierarchyControllerTest --target-org GenericHierarchyDev --result-format human --wait 30
```

### Automated validation

The latest deployment validation against a fresh Salesforce Developer Edition org completed successfully:

- **28 metadata components validated successfully.**
- **16 Apex tests passed.**
- **0 Apex test failures.**
- Target org: Fresh Salesforce Developer Edition.

### Manual testing

Manual validation has covered:

- Account and Contact hierarchy rendering.
- Five-level hierarchy structures.
- Middle-level record navigation.
- Multiple children and branching hierarchies.
- Custom parent relationship fields.
- Metadata-driven display field changes.
- Empty hierarchies and invalid or inactive configurations.
- Object-level and field-level access restrictions.
- A 200-record hierarchy dataset.

The 200-record test completed successfully in the development environment. Further large-volume and concurrent-user testing is recommended before production adoption.

## Security

- Apex controller uses `with sharing`.
- Dynamic queries use user-mode access enforcement.
- Object and field accessibility are checked.
- Invalid or inaccessible metadata is handled by the controller.
- Users require appropriate object and field permissions.
- Apex controller access is provided through the `Generic_Hierarchy_User` permission set.

## Current Limitations

- Maximum supported hierarchy depth: five levels.
- The current implementation retrieves child records without pagination or a configurable record cap. Very large hierarchies require additional scalability testing.
- Hierarchy rendering depends on valid configuration metadata and accessible relationship fields.
- The 200-record test is a development validation, not a production-scale performance guarantee.
- The solution should undergo broader fresh-org installation, security, and data-volume testing before production adoption.

## Package Contents

The source project contains:

- `GenericHierarchyController` and `GenericHierarchyControllerTest`.
- `Hierarchy_Configuration__mdt` and `Hierarchy_Display_Configuration__mdt`.
- Sample Custom Metadata configuration records for Account and Contact.
- `Generic_Parent_Account__c` custom Account lookup field.
- `genericHierarchyViewer` and `genericHierarchyNode` Lightning Web Components.
- `Generic_Hierarchy_User` permission set.
- Deployment manifest and project configuration files.

The sample Custom Metadata configuration records are maintained in the source repository. When installing the unmanaged package, deploy these records separately if they are not included in the package version.

The Account sample configuration requires the `Generic_Parent_Account__c` lookup field.

Diagnostic classes used during development are not included in the project package manifest.

## License

Add your chosen license and distribution terms before publishing or distributing this project.
