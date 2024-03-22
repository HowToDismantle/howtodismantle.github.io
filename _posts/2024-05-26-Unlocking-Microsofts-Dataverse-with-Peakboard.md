---
layout: post
title: Unlocking Microsoft's Dataverse with Peakboard
date: 2023-03-01 02:00:00 +0200
tags: bestpractice office365
image: /assets/2024-05-26/title.png
read_more_links:
  - name: Dismantle SharePoint - How to use a document library to store technical drawings and download them in Peakboard dynamically
    url: /2023-11-24-Dismantle-Sharepoint-How-to-use-a-document-library-to-store-techical-drawings-and-download-them-to-Peakboard-dynamically.html
  - name: MS Graph API - Understand the basics and get started
    url: /MS-Graph-API-Understand-the-basis-and-get-started.html
  - name: Peakboard Dynamics Extension on github
    url: https://github.com/Peakboard/PeakboardExtensions/tree/master/MicrosoftDynamics365
downloads:
  - name: D365GetOrders.pbmx
    url: /assets/2024-05-26/D365GetOrders.pbmx
---
The backbone of any Dynamics 365 application is the Microsoft Dataverse. This is true for any typical D365 app like CRM or Business Central, but also for any kind of Power App. So the dataverse can be seen as some kind of cloud based database. In this article we will cover a step-by-step guide on how to access the dataverse entities. The tricky part is the correct authentification. In general accessing the dataverse data with a regular user name and password is possible, but definetely not recommended. We will learn in this article to register an app in Microsoft Entra directory and then use this app to access the data instead of username and password.

## Installing the extension

Peakboard doesn't support the Dataverse access natively, so we have to install the Dynamics extension first by clicking on Manage Extension and choose the Dynamics Extension. After restarting the Peakboard Designer the list is available to be used. The naming is rather confusing and not pefectly accurate. This has historic reasons. To be more precise we can say, that this is a 'Dataverse' extension and what we query is an 'entity list'.

![image](/assets/2024-05-26/010.png)

![image](/assets/2024-05-26/020.png)

## Registering an app in the Micrsoft Entra ID directory

For accessing the data later wihout using a username and password we need to register an app in the Entry ID directory of the company's Azure portal. The screenshot shows the right place to do this.

![image](/assets/2024-05-26/030.png)

Within the app details we register a client secret (see screenshot). Beside the client secret, we will also need the Client ID. It can be found in the overview administration pane of the registered app.

![image](/assets/2024-05-26/040.png)

![image](/assets/2024-05-26/050.png)

There's no need to apply additional rights or other authorisation attributes.

## Applying the registered app to the dataverse environment

Before we can use the registered app we need to apply it to the Power Apps environment. In the [Power apps admin center](https://admin.powerplatform.microsoft.com/) we choose the environment we want to access and then go to "Settings" -> "User + permission" -> "Application users". With "new app user" we add the registered app we created earlier to the list of application users.

![image](/assets/2024-05-26/055.png)

After adding the app we must add a security role that fits to our needs. This depends on the existing roles in the Power App environment what to choose. In case we don't care about roles and just want to get it working, we can assign the role "System Administrator" to allow the app full access to all data of the dataverse.

![image](/assets/2024-05-26/060.png)

## Views

In genereal we have two options to access the data. We can either access the entity of the dataverse directly, this includes all attributes and all rows. Or the more preferred way is to use a view. We can build a view directly in the Power Apps dev environment. The screenshot shows a view as seen by an end user in the CRM portal. The view depends on the entity "salesorder" in the D365 CRM system. It shows several orders for the shipment team and very limited number of attributes (columns). This will basis for the data access in the next paragraph.

![image](/assets/2024-05-26/070.png)

## Setting up the data source

Back in the Peakboard designer we can now create a new Dynamics 365 data source on basis of the extension we installed earlier. We only need to provide four values for accessing the view:

1. The URL to the Dynamics 365 or dataverse system
2. The Client ID
3. The Client secret
4. The name of the view. In the combo box all views in the system are listed. Every entry starts with the entity name in alphanetical order followed by a pipe follwoed by the actual view name.

![image](/assets/2024-05-26/080.png)

That's it!

## result and conclusion

The actual output as shown in the screenshot actually is not the interesting point. The interesting point in this tutroial is how to set up the resgitered app in azure, bind it to a dataverse environment and access the data by using the CLient ID and client Secret. Once again we note the advice that it's not appropriate from a security perspective to use user name and password. Using a registered app in AZure is the official way to go and it's highly recommended to follow this advice, especially in production environments.

![image](/assets/2024-05-26/090.png)

