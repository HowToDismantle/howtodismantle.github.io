---
layout: post
title: Digital Walkaround Inspections Part II - How to Build an Audit App
date: 2023-03-01 03:00:00 +0200
tags: bestpractice usecase
image: /assets/2025-06-21/title.png
image_landscape: /assets/2025-06-21/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Digital Walkaround Inspections Part I - How to Build an Audit App
    url: /Digital-Walkaround-Inspections-Part-I-How-to-Build-an-Audit-App.html
downloads:
  - name: MyAudit.pbmx
    url: /assets/2025-06-13/MyAudit.pbmx
---
In [the last article](/Digital-Walkaround-Inspections-Part-I-How-to-Build-an-Audit-App.html) we already discussed what an audit is and how the necessary data stucture looks like. We understand, that the meta data of an audit is stored in the table "AuditTemplateHeader" an "AuditTemplateItem". While the actual audit including the input of the user is stored in the table "AutiHeader" and "AuditItem". We also discussed the sample data that is necessary to conduct a CNC machine walkthrough.

In this second part of the mini series we will learn how to build the actual Peakboard application on top of this data structure.

## Main Screen

The main Screen is super simple, just these two buttons. One for creating a new audit from a template, one for launching an existing audit.

![image](/assets/2025-06-21/010.png)

## Preparing the data sources and variables

For our app we need to prepare some data source. For details the pbmx is downloadable [here](/assets/2025-06-13/MyAudit.pbmx)

![image](/assets/2025-06-21/020.png)

- ActiveAuditHeader and ActiveAuditItem point to the AuditHeader and AuditItem table with a filter on the column TS filled with variable ActiveTS.
- AllAuditHeader contains all audits. We need this for the overview so the user can pick one. The filter is "State" in case the user chooses to filter only active audits
- AuditTemplateHeader nd AuditTemplateItem contains all metadata of audit and corresponds to the same table in the Hub.

For the variables we need these:

- ActiveStep is the active step of the currently active audit
- ActiveStepState is the state of the current step (we need this for the UI formatting)
- ActiveTS is the time stamp of the currently active audit
- AuditFilter is the state the user can set when selecting an audit

## Create a new audit

The screenshot show the overview of all possible audits (table AuditTemplateHeader). The user can pick one to create a new audit from the template.

![image](/assets/2025-06-21/030.png)

The procedure behind the create button is shown in the screenshot. The basic idea is that the template header is copied into the new audit header, and the template items are all copied in the the new audit items. This includes all 5 variables of the item template.

We use the time stamp TS as a database key to build a relationship between header and items.

![image](/assets/2025-06-21/040.png)

## Load an audit

For the screen to let the user load an existing audit, we just present a list of available audits to the user. The user can use a simple filter to choose between open and completed audits.

![image](/assets/2025-06-21/050.png)

The actual procedure behind is pretty simple. It just reloads the two corresponding table according to the filter TS. The active step is set to 0, so we always start with the first screen and activate it.

![image](/assets/2025-06-21/060.png)

## Load a single audit step

The actual magic is happening when a new single step is loaded or ativated. This is coded within the function "ActivateStep". First we check, if the step is valid. If not we pop out an error message. In case there are only D steps (D for DOne), we set the overall state of the audit also to D. This case covers the end of the audit when all steps are done.

![image](/assets/2025-06-21/070.png)

The more important branch is a vlaid, active step. In that case we check for the layout. Depening on the layout in the metadata the corresponding screen is loaded and all variables are set to screen elements (monstly but not limited to textboxes). Through this process the layout value determines the screen to be shown for a certain step.

![image](/assets/2025-06-21/071.png)

Let's check a sample screen with layout "FT01". There are two test fields to be filled with Var1 and Var2, and also an image to be filled with an URL which is stored in Var3.

![image](/assets/2025-06-21/080.png)

## Putting a step to done

Let's discuss the procedure behind the "Mark as Done" button which can be found on any layout screen. The screenshots shows another layout. It's the "ENTRY01" layout where the user can or must make an input entry.

![image](/assets/2025-06-21/090.png)

Here's the logic behind the "Mark as done" button. We just write back to the hub list into the table AuditItem and set the state to D for Done, and also we store the user's input  to one of the input variable columns. In that case "Input01". Then we do a reload to make sure the changed data is available on our datasource. Calling the function "ActivateStep" is re-adjusting the UI elements (e.g. set the "Mark as done" button to disabled)

![image](/assets/2025-06-21/100.png)

## result

The animation shows the audit with our example data. First a new audit is generated from a tamplate. Then the audit starts and every step is marked as done. Two of the steps require the user's input.
It's very important to understand that our example only shows a small part od the options. It's easy to use the same architecture and principle to build even very complex audits with lot's of different layouts and much more user input. For the sake of clearity we only did a very simple example here.

![image](/assets/2025-06-21/result.gif)





