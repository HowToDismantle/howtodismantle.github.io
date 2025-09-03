---
layout: post
title: 2025-09-16 Because Nobody Loves MI05 - How to handle SAP Inventory
date: 2023-03-01 03:00:00 +0000
tags: sap usecase
image: /assets/2025-09-16/title.png
image_header: /assets/2025-09-16/title_landscape.png
bg_alternative: true
read_more_links:
  - name: SAP related article
    url: /category/sap
downloads:
  - name: xxx.pbmx
    url: /assets/2025-09-16/xxx.pbmx
---
We have already covered many [SAP-related use cases](/category/sap) on this blog. Today we will dig deeper into what SAP calls a physical inventory. In that process warehouse staff walk through the aisles and count the goods item by item. When the counting is finished the recorded quantities in the system are corrected so they match the real stock levels. In the past this relied on paper lists that had to be carried around and typed back into SAP later. Now we'll build a modern, tablet-based version that makes the workflow completely paperless.

## The SAP side

In SAP, the main transaction for creating a new inventory list is MI01. After the list exists, warehouse clerks would normally use transaction MI05 to enter the counted quantities. Our application takes over the MI05 part and lets the counts be submitted directly from Peakboard. The screenshots below show how the document appears in SAP.

![image](/assets/2025-09-16/010.png)

SAP provides a set of BAPIs to process inventory documents. We call BAPI_MATPHYSINV_GETDETAIL after the user has entered the inventory number and fiscal year, which returns all items belonging to that document. Once the counts are typed in, BAPI_MATPHYSINV_COUNT sends the results back to SAP and updates the inventory list accordingly.

The following XQL statement shows how these BAPIs are called. For BAPI_MATPHYSINV_GETDETAIL we read only the ITEMS table, supplying the inventory number and fiscal year to make the call specific:

{% highlight test %}
EXECUTE FUNCTION 'BAPI_MATPHYSINV_GETDETAIL'
   EXPORTS
      PHYSINVENTORY = '0100000004',
      FISCALYEAR = '2025'
   TABLES
      ITEMS INTO @RETVAL
{% endhighlight %}

For BAPI_MATPHYSINV_COUNT we must send the inventory number, the fiscal year, and the actual count date so SAP can identify the document precisely. The counted items are passed in the ITEMS table, and each row needs the item number, material number, counted quantity, and unit. The example below shows a call with one item, but later the script generates the table rows dynamically to handle any number of items.

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

## The Peakboard application

For the UI part we place a couple of simple controls on the Peakboard canvas. At the top the user enters the inventory number and the fiscal year. After loading the document the user types the counts into the list and then presses a button to submit everything back to SAP.

In the center there's a styled list showing all the line items from the inventory document. It makes the data easy to scan and provides a familiar layout for warehouse staff.

![image](/assets/2025-09-16/020.png)

The list is bound to a variable list that holds the items the application is currently processing. In addition we use three scalar variables that feed the XQL statements, a pattern you may recognize from other SAP applications on this blog. These variables let us update the inventory number, fiscal year, and dynamic table content without rewriting the XQL.

![image](/assets/2025-09-16/030.png)

## Getting the inventory document from SAP

To query the inventory document we use a standard SAP data source configured with the XQL shown above. We insert placeholders to keep the query dynamic so it can reference whatever inventory number and fiscal year the user has typed in. The text boxes on the canvas are bound to variables, and those variables are plugged into the XQL when the data source is refreshed.

![image](/assets/2025-09-16/040.png)

In the refresh script we loop through the raw data returned by SAP, copy the fields we need into the variable list, and use that list as the backend for the UI. This keeps the interface responsive and allows the user to edit the counts directly in the list.

![image](/assets/2025-09-16/050.png)

The `Load Document` button simply triggers a refresh of the dynamic data source. When pressed, the placeholders are replaced with the current variable values and the application pulls the latest data from SAP.

![image](/assets/2025-09-16/060.png)

## Submitting the count to SAP

As noted earlier, we call BAPI_MATPHYSINV_COUNT to submit the counts and then BAPI_TRANSACTION_COMMIT to finalize the update. All XQL resides in a standard SAP data source with placeholders for the inventory number, fiscal year, and a `CountTablePayload` that holds a dynamic number of table rows based on the document's items. This setup keeps the script flexible no matter how many items the inventory document contains.

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

The `Submit` button iterates over the items table and builds a string representing the table content in the format required by the XQL. This string is stored in the `CountTablePayload` variable, and when the data source is triggered the placeholder is replaced with the generated string so the proper SAP call is sent.

![image](/assets/2025-09-16/080.png)

In the refresh event we process the `RETURN` table, extract the SAP message, and display it to the user. That way the operator immediately sees whether the submission was successful or if something went wrong.

![image](/assets/2025-09-16/090.png)

## Result and conclusion

We learned how to query an inventory document from SAP and submit the counted quantities back to the system. The video below shows the entire process from loading the document to sending the counts. Please remember this example is meant for demonstration only; a production-ready solution would need additional features such as material texts, value help for selecting a list, better validation for user input, and proper error handling rather than simply displaying messages:

- Material text in addition to the material number
- Value help for selecting an inventory list
- Better checks to ensure the user has filled the text inputs correctly
- Proper handling of error messages, not just displaying them

![image](/assets/2025-09-16/result.gif)
