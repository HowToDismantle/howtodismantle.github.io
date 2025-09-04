---
layout: post
title: Because Nobody Likes MI05 - How to handle SAP Inventory
date: 2023-03-01 03:00:00 +0000
tags: sap usecase
image: /assets/2025-09-16/title.png
image_header: /assets/2025-09-16/title_landscape.png
bg_alternative: true
read_more_links:
  - name: SAP-related articles
    url: /category/sap
downloads:
  - name: SAPInventory.pbmx
    url: /assets/2025-09-16/SAPInventory.pbmx
---


We've covered many different ways of [integrating SAP with Peakboard](/category/sap) on this blog. In this article, we'll look at SAP's [physical inventory component](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/1e61bd534f22b44ce10000000a174cb4.html)---which lets warehouse staff do a physical inventory count, and then record the numbers in SAP.

In the past, workers had to carry around paper lists to do inventory counts. And once they finished their counts, they had to type the numbers into SAP manually. But with Peakboard, we can build a modern, tablet-based application for recording inventory counts into SAP. That way, the whole workflow is paperless and much more streamlined.

## The SAP side of things

This is what an inventory document looks like in SAP:
![image](/assets/2025-09-16/010.png)

Normally, after the warehouse staff to do an inventory count, they use the `MI05` transaction to manually enter the new numbers into the appropriate inventory document. Our Peakboard application will replace the `MI05` step and submit the inventory numbers directly to SAP.

### Inventory BAPIs

SAP provides a set of BAPIs to process inventory documents:
* `BAPI_MATPHYSINV_GETDETAIL` returns all the items in an inventory document.
* `BAPI_MATPHYSINV_COUNT` makes changes to an inventory document. 
* `BAPI_TRANSACTION_COMMIT` commits the changes to an inventory document.

Let's look at the XQL statements that we use to call these BAPIs.

For `BAPI_MATPHYSINV_GETDETAIL`, we provide the inventory number and fiscal year in order to specify the inventory document we want:

| Parameter       | Description                                |
|-----------------|--------------------------------------------|
| `PHYSINVENTORY` | The inventory number.
| `FISCALYEAR` | The fiscal year.

We also specify that we only want to get the `ITEMS` table.

{% highlight test %}
EXECUTE FUNCTION 'BAPI_MATPHYSINV_GETDETAIL'
   EXPORTS
      PHYSINVENTORY = '0100000004',
      FISCALYEAR = '2025'
   TABLES
      ITEMS INTO @RETVAL
{% endhighlight %}

For `BAPI_MATPHYSINV_COUNT`, we provide these parameters, so that SAP can identify the proper inventory document:

| Parameter       | Description                                |
|-----------------|--------------------------------------------|
| `PHYSINVENTORY` | The inventory number.
| `FISCALYEAR` | The fiscal year.
| `COUNT_DATE` | The date that the inventory count was performed.

We also pass in an `ITEMS` table, which contains the updated stock counts. Each row contains the following columns:

| Column     | Description          |
|------------|----------------------|
| `ITEM`       | The item number.     |
| `MATERIAL`   | The material number. |
| `ENTRY_QNT`  | The counted quantity.|
| `ENTRY_UOM`  | The unit.            |

Afterwards, we call `BAPI_TRANSACTION_COMMIT` to commit the changes.

Here's an example XQL query. This example only includes one item in the `ITEMS` table---but later, we'll build a script that generates the table rows dynamically, to handle any number of items.

{% highlight test %}
EXECUTE FUNCTION 'BAPI_MATPHYSINV_COUNT'
   EXPORTS
      PHYSINVENTORY = '0100000004',
      FISCALYEAR = '2025',
      COUNT_DATE = '20250824'
   TABLES
      ITEMS = ((ITEM, MATERIAL, ENTRY_QNT, ENTRY_UOM),
         ('002', '100-120', '51', 'ST')),
   RETURN INTO @RETVAL;

EXECUTE FUNCTION 'BAPI_TRANSACTION_COMMIT'
{% endhighlight %}


## Build the Peakboard application

Now, let's build the Peakboard application.

### Overview

First, here's an overview of how the application works.

![image](/assets/2025-09-16/result.gif)

1. The user enters the inventory number and year for the inventory document they want to update.
1. The user taps the *Load Document* button.
1. The application uses  `BAPI_MATPHYSINV_GETDETAIL` to get the data for the inventory document that the user specified.
1. The application displays each item from the inventory document, so that the user can update the stock numbers.
1. The user updates the stock numbers. 
1. The user taps the *Submit Count* button. 
1. The application uses `BAPI_MATPHYSINV_COUNT` and `BAPI_TRANSACTION_COMMIT` to submit the new stock numbers to SAP.
1. The application displays the response message from SAP.


### The UI
To create the UI, we first add a couple of simple controls onto the canvas:
* A text box for the inventory number.
* A text box for the fiscal year.
* A button to load the document, based on the inventory number and fiscal year that the user entered.

Then, we add a styled list to the center of the screen. This is what shows all the line items from the inventory document. It makes the data easy to scan and provides a familiar layout for warehouse staff.

![image](/assets/2025-09-16/020.png)

The styled list is bound to a variable list. This variable list contains the items that the application is currently processing. 

In addition, we use three scalar variables that feed the XQL statements (a pattern you may recognize from other SAP-based apps that we've built on this blog). These variables let us update the inventory number, fiscal year, and dynamic table content---all without rewriting the XQL.

![image](/assets/2025-09-16/030.png)


### Get the inventory document from SAP

To query the inventory document, we use a standard SAP data source, configured with the `BAPI_MATPHYSINV_COUNT` XQL query from before.

We use placeholders to keep the query dynamic, so it can reference whatever inventory number and fiscal year the user typed in. The text boxes are bound to variables, and those variables are plugged into the XQL when the data source is refreshed.

![image](/assets/2025-09-16/040.png)

In the refresh script, we loop through the raw data returned by SAP, copy the fields we need into the variable list, and use that list as the backend for the UI. This keeps the interface responsive and lets the user edit the counts directly in the list.

![image](/assets/2025-09-16/050.png)

The *Load Document* button triggers a refresh of the dynamic data source. When tapped, the placeholders are replaced with the current variable values, and the application pulls the latest data from SAP.

![image](/assets/2025-09-16/060.png)

### Submit the inventory count to SAP

As previously mentioned, we use `BAPI_MATPHYSINV_COUNT` to submit the inventory count, and then `BAPI_TRANSACTION_COMMIT` to finalize the update. The XQL sits inside a standard SAP data source.

The XQL query has placeholders for the inventory number and fiscal year. It also has a `CountTablePayload` placeholder that contains the updated rows of the `ITEMS` table (more on that in a bit). This setup keeps the script flexible, no matter how many items the inventory document contains.

{% highlight test %}
EXECUTE FUNCTION 'BAPI_MATPHYSINV_COUNT'
   EXPORTS
      PHYSINVENTORY = '#[MyInventoryNo]#',
      FISCALYEAR = '#[MyFiscalYear]#',
      COUNT_DATE = '20250824'
   TABLES
      ITEMS = ((ITEM, MATERIAL, ENTRY_QNT, ENTRY_UOM),
         #[CountTablePayload]#),
      RETURN INTO @RETVAL;

EXECUTE FUNCTION 'BAPI_TRANSACTION_COMMIT'
{% endhighlight %}

![image](/assets/2025-09-16/070.png)

The *Submit* button iterates over the variable list and turns it into an XQL-friendly string. This string is stored in the `CountTablePayload` variable, and when the data source is triggered, the placeholder is replaced with the generated string, so that the proper SAP call is sent.

![image](/assets/2025-09-16/080.png)

In the refresh event, we process the `RETURN` table, extract the status message, and display it to the user. That way, the user immediately sees if the submission was successful or not.

![image](/assets/2025-09-16/090.png)


## Result and conclusion

We explained how to query an inventory document from SAP and submit new numbers back to the system. Let's take a look at the demo video again. But remember, this is just a simple example. A production-ready solution would need additional features to make the application more robust. For example:
- Material text, in addition to the material number.
- Value help, for selecting an inventory document.
- Better checks to ensure that the user has filled all text inputs correctly.
- Proper handling of error messages, instead of just displaying them.

![image](/assets/2025-09-16/result.gif)
