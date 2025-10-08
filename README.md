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

## Static Field Control (BDEF)

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






















