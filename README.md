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

ID | Scenario | BDEF Property | Technical Effect | 
| **SFC-01** | Always Read-Only (Nobody Can Touch This) | `field (read only)` | Nope, you **can't create or change** this field through the UI or code (EML/OData). Your BO will flat-out reject any attempts to change it! | 
| **SFC-02** | Must Be Filled When Creating | `field (mandatory:create)` | You **must provide a value** when you first create an entry. If it's missing, the system throws a fit and won't let you save! | 
| **SFC-03** | Read-Only *After* Creation | `field (read only:update)` | Once you've created the entry (or set the first value), that's it! You **can't change it later** through the UI or by coding an `UPDATE`. | 
| **SFC-04** | Set It and Forget It (Mandatory First, Then Locked) | `field (mandatory:create, read only:update)` | This is a mix! You **must give it a value initially**, and then it's locked down forever. Perfect for things like an external ID that should never change! | 
| **SFC-05** | Hidden Away (Purely Technical) | `field (suppress)` | Poof! It **vanishes** from all the generated stuff (like EML fields). Just remember to add the `@Consumption.hidden: true` annotation to your CDS view, or it might still sneak into your OData service!
