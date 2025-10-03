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
