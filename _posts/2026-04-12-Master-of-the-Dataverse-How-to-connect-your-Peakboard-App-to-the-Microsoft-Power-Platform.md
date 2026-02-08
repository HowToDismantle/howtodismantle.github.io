---
layout: post
title: Master of the Dataverse - How to connect your Peakboard App to the Microsoft Power Platform
date: 2023-03-01 00:00:00 +0000
tags: office365
image: /assets/2026-04-12/dataverse-peakboard-title.png
image_header: /assets/2026-04-12/dataverse-peakboard-title.png
bg_alternative: true
read_more_links:
  - name: More Office 365
    url: /category/office365
  - name: Dataverse Extension
    url: https://templates.peakboard.com/extensions/Microsoft-Dataverse/en
  - name: Fetch XML Tutorial
    url: https://www.youtube.com/watch?v=d1-WWXND0x0&t=22s
---
In early 2024, we discussed how to [access Microsoft Dynamics CRM data](/Unlocking-Microsofts-Dataverse-with-Peakboard.html). Since then, Microsoft has changed the backend, and the architecture for handling extensions on the Peakboard side has shifted significantly. As a result, starting with Peakboard version 4.1, the Dynamics Extension is no longer available. It has been officially replaced by the [Dataverse extension](https://templates.peakboard.com/extensions/Microsoft-Dataverse/en). In this article, we will explore how to use the new Dataverse extension.

One of the main differences is that the new extension supports only client secret and app registration for authentication — no more username/password. When accessing Dataverse data, you can either query an entity directly or use FetchXML, which is a common and powerful way to define Dataverse queries.

## Setting up the necessary requirements

The security layer of Dataverse is built on Microsoft Entra ID. We need to create a registered app there.

![Microsoft Dataverse Connection Setup Example](/assets/2026-04-12/dataverse-connection-setup-example.png)

Within the registered app, we need to create a new client secret and note down the secret value for later use.

![Dataverse Authentication Settings Example](/assets/2026-04-12/dataverse-authentication-settings-example.png)

Besides the client secret, we also need the Client ID and Tenant ID.

![Peakboard Dataverse Data Source Example](/assets/2026-04-12/peakboard-dataverse-data-source-example.png)

For the API permissions, we need to add "user_impersonation" from the "Dynamics CRM" area.

![Dataverse Table Selection Example](/assets/2026-04-12/dataverse-table-selection-example.png)

The final step is to set the correct permissions and roles in Power Apps. Follow these steps to link your Entra ID app to a specific environment and apply the necessary permissions:

### Select the Environment:
1. Log in to the [Power Platform admin center](https://admin.powerplatform.microsoft.com/).
1. In the left-hand navigation pane, select Manage -> Environments.
1. Click on the Name of the environment where you want the app to have access.

### Navigate to Application Users:
1. On the environment details page, select Settings from the top command bar.
1. Expand the Users + permissions section and select Application users.
1. Create the New App User:
1. Select + New app user on the command bar.
1. Click + Add an app in the side pane that appears.
1. Search for your application by its Name or Application (Client) ID. Select it and click Add.

### Assign Business Unit and Security Roles:
1. Business Unit: Select the appropriate business unit (usually the root business unit).
1. Security Roles: Click the Edit (pencil) icon next to Security roles. Choose the roles that grant the necessary permissions (e.g., System Administrator for full access or a custom role for restricted access).
1. Click Save and then click Create.

![Dataverse Data Preview Example](/assets/2026-04-12/dataverse-data-preview-example.png)

## First steps with the Dataverse extension

The Dataverse extension can be installed from the extension area within the data source dialog. After installation there are two customer lists available:

- The `Dataverse Entities` list downloads entity data with the defined attributes. It's ideal for entities that don't contain too much data.
- The `Dataverse FetchXML` list can be used for complex queries that involve multiple entities or require advanced filtering.

![Peakboard Dataflow Dataverse Example](/assets/2026-04-12/peakboard-dataflow-dataverse-example.png)

Let's start with the simpler option: `Dataverse Entities`. For this, we need to provide three values from the setup earlier: Client ID, Tenant ID, and Client Secret. Additionally, we need to provide the URL to the backend. For a Dynamics CRM backend, the most common URL is `MyCompany.crm4.dynamics.com`. If the URL is unclear, you can find it in the environment settings where you added the app user.

![Dataverse Dataflow Transformation Example](/assets/2026-04-12/dataverse-dataflow-transformation-example.png)

For the data definition, we need to provide the name of the entity and the attributes to download. It's important to use the logical names of these artifacts—these are lowercase, technical names. The values are case-sensitive. Attributes must be separated by commas with no spaces between them.

![Dataverse Dataflow Output Example](/assets/2026-04-12/dataverse-dataflow-output-example.png)

All Dataverse data types are mapped to Peakboard data types. Linked entities are represented by the GUID, so you can easily create a second data source with the linked entity and then join them using a dataflow. For option sets, the plain text value is used as the payload, not the underlying numeric value.

## FetchXML

For more sophisticated queries, you can use the second data source available in the Dataverse extension. Like the entities list, it functions similarly for data access, but instead of selecting entities and attributes, it provides a multiline text field where you can enter FetchXML to define your query. FetchXML supports multiple entities, data ordering, and aggregation. For a good introduction, check out [this tutorial](https://www.youtube.com/watch?v=d1-WWXND0x0&t=22s).

![Peakboard App with Dataverse Integration Example](/assets/2026-04-12/peakboard-app-dataverse-integration-example.png)

## Conclusion

The new Dataverse extension is designed to cover all common requirements for extracting data from the Dataverse backend. FetchXML, in particular, handles even complex cases with ease. With the help of the [XRM Toolbox](https://www.xrmtoolbox.com/), creating the necessary XML should be straightforward. Sometimes it may require a bit of patience, but the results are worth it.


