# abap-rap-example
ABAP RAP Implementation Example

**Goal**: I wanted to create example implementation for RAP business objects abd expose the most features in educational purposes.

**Data Model**: I used pretty simple two node hierarchical model. The root node is Purchase Order. Purchase Order Item is direct child.

**Implemented scenarios:**
1. Managed RAP business object with draft and with late numbering;
2. Unmanged RAP business object with draft and with external early numbering;
3. Unmanaged query with Gemini AI summary  API;
4. Extensibility enablement for managed RAP business object;
5. Extension with new fields, new behavior and with new node of managed RAP business object;
6. local event consumtion for events raised in managed and unmanaged RAP business objects.

**RAP application types:**
1. RAP Fiori UI with draft(managed and unmanaged);
2. RAP Web API(managed and unmanaged);
3. RAP Internal API(interface);
4. RAP unmanaged query;
5. RAP business events;
6. RAP business object extensions.


RAP Feature Control Cookbook: Atomic Technical Scenarios
These scenarios are designed to be independent and combinable for more complex business requirements.

I. Static Field Control (Behavior Definition - BDEF)
These restrictions are constant for all instances.

## Static Field Control (SFC)

These restrictions are constant for all instances in the ABAP RESTful Application Programming Model (RAP).

| ID | Scenario | BDEF Property | Technical Effect | 
| :---: | :--- | :--- | :--- | 
| **SFC-01** | Field is **Read-Only (Always)** | `field (read only)` | Consumer cannot create or update the field via EML/OData. BO runtime rejects external EML `MODIFY` with this field. | 
| **SFC-02** | Field is **Mandatory during CREATE** | `field (mandatory:create)` | System checks if the field is filled *before* persistence during a `CREATE`. `SAVE` is rejected if empty. | 
| **SFC-03** | Field is **Read-Only during UPDATE** | `field (readonly:update)` | Field cannot be changed via the UI or external EML `UPDATE` after an instance is created (or initial value set in draft). | 
| **SFC-04** | Field is **Mandatory on Create & Read-Only on Update** | `field (mandatory:create, readonly:update)` | Combines SFC-02 and SFC-03. Value must be set once during creation and can never be changed afterward (e.g., ID via external numbering). | 
| **SFC-05** | Field is **Suppressed (Technical Field)** | `field (suppress)` | Removes the field from appearance in BDEF-generated components (derived types, EML fields). Requires `@Consumption.hidden: true` for OData removal. |

II. Static Operation/Action Control (Behavior Definition - BDEF)
These operations are either permanently available or disabled at the entity level.

## Static Operation Control (SOC)

These rules define the general CREATE, UPDATE, and DELETE (CUD) permissions for the entire entity.

| ID | Scenario | BDEF Syntax | Technical Effect |
| :---: | :--- | :--- | :--- |
| **SOC-01** | `CREATE` is enabled for the entity (Default) | `create` | The consumer can create new instances of this entity. |
| **SOC-02** | `UPDATE` is enabled for the entity (Default) | `update` | The consumer can modify existing instances of this entity. |
| **SOC-03** | `DELETE` is enabled for the entity (Default) | `delete` | The consumer can delete existing instances of this entity. |
| **SOC-04** | Action is **Always Available** | `action ActionName [...]` | The action button/operation is always available on the UI/API, regardless of instance state. |
| **SOC-05** | **Internal Operation/Action** | `internal *operation*/ internal action ActionName` | The operation/action can only be triggered by business logic *inside* the BO implementation (validations, determinations, other actions), not by external consumers (UI/API). |
| **SOC-06** | **Create-by-Association** is enabled | `_Association { create; }` | The consumer can create a child instance via the parent's association. |

III. Dynamic Field Control (Instance Features)
These restrictions depend on the instance's current data/state, implemented in the behavior pool's FOR INSTANCE FEATURES.

## Dynamic Field Control (DFC)

These rules allow you to change a field's read-only or mandatory status based on the data of the current instance.

| ID | Scenario | BDEF Syntax | Implementation Status | Technical Effect |
| :---: | :--- | :--- | :--- | :--- |
| **DFC-01** | Field is **Dynamically Mandatory** | `field (features:instance)` | Set status to `MANDATORY` | Field becomes mandatory based on instance data/condition, requiring input before saving. |
| **DFC-02** | Field is **Dynamically Read-Only** | `field (features:instance)` | Set status to `READONLY` | Field becomes read-only based on instance data/condition, preventing modification. |
| **DFC-03** | Field is **Dynamically Unrestricted** | `field (features:instance)` | Set status to `UNRESTRICTED` | Field has no dynamic restrictions (e.g., overriding a global restriction for specific instances). |

IV. Dynamic Operation/Action Control (Instance Features)
These are enabled/disabled based on the instance's current data/state, implemented in the behavior pool's FOR INSTANCE FEATURES.

## Dynamic Operation Control (DOC)

These rules allow you to enable or disable CUD operations (UPDATE, DELETE) and custom actions based on the state of the current business object instance.

| ID | Scenario | BDEF Syntax | Implementation Status | Technical Effect |
| :---: | :--- | :--- | :--- | :--- |
| **DOC-01** | **Standard Operation (UPDATE or DELETE) is Dynamically Disabled** | `update (features:instance)` or `delete (features:instance)` | Set status to `DISABLED` | The operation is disabled for the specific instance (e.g., cannot delete a "booked" instance). |
| **DOC-02** | Action is **Dynamically Disabled** | `action ActionName (features:instance)` | Set status to `DISABLED` | The action button/operation is disabled/hidden on the UI for the specific instance (e.g., cannot book an already booked flight). |
| **DOC-03** | Action is **Dynamically Enabled** | `action ActionName (features:instance)` | Set status to `ENABLED` | The action button/operation is enabled for the specific instance (used to control availability when the default is disabled). |

V. Global Operation/Action Control (Global Features)
These are enabled/disabled based on a condition independent of the BO instance state (e.g., system configuration, BAdI implementation, business scope), implemented in the behavior pool's FOR GLOBAL FEATURES.

## Global Operation Control (GOC)

These controls permanently disable CUD operations, actions, or associations for **all instances** of the entity, overriding any instance-specific settings.

| ID | Scenario | BDEF Syntax | Implementation Status | Technical Effect |
| :---: | :--- | :--- | :--- | :--- |
| **GOC-01** | **Standard Operation (CREATE, UPDATE, or DELETE) is Globally Disabled** | `create (features:global)` or `update (features:global)` or `delete (features:global)` | Set status to `DISABLED` | The operation is disabled for **all** instances of the entity, regardless of instance state. |
| **GOC-02** | Action is **Globally Disabled** | `action ActionName (features:global)` | Set status to `DISABLED` | The action button/operation is disabled/hidden on the UI for all instances (e.g., if a feature is switched off globally). |
| **GOC-03** | **Create-by-Association is Globally Disabled** | `_Association { create(features:global); }` | Set status to `DISABLED` | Creation of child entities via the parent's association is disabled globally. |










