---
layout: post
title: Barcode Bliss - Part III - Bringing ProGlove and SAP together - Transfer Order Use Case
date: 2024-10-25 12:00:00 +0200
tags: hardware mqtt
image: /assets/2024-10-25/title.png
read_more_links:
  - name: Barcode Bliss - Part I - Integrating ProGlove Scanners with Peakboard
    url: /Barcode-Bliss-Part-I-Integrating-ProGlove-Scanners-with-Peakboard.html
  - name: Barcode Bliss - Part II - Sending Feedback to ProGlove Scanners
    url: /Barcode-Bliss-Part-II-Sending-Feedback-to-ProGlove-Scanners.html
  - name: ProGlove Documentation
    url: https://docs.proglove.com/en/connect-gateway-to-your-network-using-mqtt-integration.html
downloads:
  - name: SAPProGloveTransferOrder.pbmx
    url: /assets/2024-10-25/SAPProGloveTransferOrder.pbmx
---
In [part one](/Barcode-Bliss-Part-I-Integrating-ProGlove-Scanners-with-Peakboard.html) and [part two](/Barcode-Bliss-Part-II-Sending-Feedback-to-ProGlove-Scanners.html) of our ProGlove mini-series, we discussed the basics of integrating ProGlove scanners into Peakboard applications. We used both the USB and MQTT modes to get the scan event and related metadata. We also discussed options to send feedback to the scanner operator, such as a light with various colors and a small display that's mounted to the scanner.

In this article, we'll put together what we've already learned, in order to build a complete use case. We will handle a typical transfer order from SAP using only Peakboard and ProGlove.

## Process overview

In SAP, a transfer order is a standard object that indicates that some goods must be collected from the warehouse and moved to different location. Transfer orders can be used to feed production needs or to fulfill a customer order. Transfer orders are usually handled in SAP with transaction LT01, LT02, etc.

Here's the process for handling a transfer order with ProGlove and Peakboard:

1. The worker scans a QR code to indicate the start of a new transfer order process.
2. The system looks up the next untouched transfer order from SAP.
3. The screen shows the line items of the transfer order, and the scanner display shows the warehouse bin of the first line.
4. The worker finds the warehouse bin and scans the code of the bin. The scan makes sure that the worker is not grabbing goods from the wrong bin.
5. ProGlove display specifies the quantity of goods to take.
6. The worker takes out that many goods from the bin.
7. The worker confirms that they have the goods by double-clicking the ProGlove button.
8. The next line items are activated, and the ProGlove display shows the next warehouse bin.
9. Repeat steps 3-6 until all line items have been retrieved by the worker. 

The overall progress is displayed on the Peakboard screen. So in case something goes wrong or the worker gets lost, they can always walk back to the display and analyze the current situation. It's not necessary for the worker to have the screen in sight at all times, because all the necessary information is shown on the ProGlove display.

The following screenshot shows an order where the first two line items have already been retrieved. The third line item is currently being retrieved. The remaining line items are still in the pending state.

![image](/assets/2024-10-25/010.png)

## The data sources

Let's take a look at the necessary data connections. The following screenshot shows a simple SAP connection. To get the line items for a transfer order, we use a query for the LTAP table. In a real world scenario, it might be useful to put the logic into an RFC function module to determine the next active transfer order.

![image](/assets/2024-10-25/020.png)

For the ProGlove connectivity, we use a standard MQTT connection along with some data paths. That way, we can extract the useful information from the JSON string that's sent from ProGlove. We need the following information:
* The scanned code.
* The serial number (to send back information to the display of the same scanner).
* Information about if the user double-clicked.

![image](/assets/2024-10-25/030.png)

The last thing we need is a table-like variable to store the order items. We need a separate list from the original SAP data source data, because we need to add a `Status` column. This column specifies the status of an item:
* "O" - Already open
* "A" - Active
* "D" - Done

![image](/assets/2024-10-25/040.png)

## The UI 

The UI is pretty simple. We use a QR code with a fixed value, `$Order_Start$`, and a styled list. To learn how the color and icon change according to the item state, see [the PBMX](/assets/2024-10-25/SAPProGloveTransferOrder.pbmx).

![image](/assets/2024-10-25/050.png)

## The application logic

The application logic (the magic behind everything) happens in the refreshed event of the MQTT data source. This process is triggered every time the worker does something with the ProGove scanner. There are three cases:

* The "Order Started" barcode is scanned.
* The warehouse bin is scanned.
* The button on the scanner is double-clicked.

It doesn't make sense to go through any single command in detail, but the following are the three high-level cases.

### Auxiliary functions

We use three different functions to send the MQTT message to the display and the lights of the scanner. The purpose is to encapsulate the JSON and make the main function easier to understand. How the JSON works is explained in [part two](/Barcode-Bliss-Part-II-Sending-Feedback-to-ProGlove-Scanners.html) of this article series.

![image](/assets/2024-10-25/055.png)

#### The order is started

If we receive a scan of the string `$order_started$`, that means the user wants to start a new order. Here's what we do:
1. Tell the ProGlove display that the order has started.
2. Query the data from SAP and fill our variable list with the items (just loop over the original source).
3. Send positive feedback (green light).
4. Set the first column to "A" for active.
5. Send the bin information to the display.

![image](/assets/2024-10-25/060.png)

#### The bin is scanned

If the bin is scanned, we check if the bin is correct by comparing it to the bin of the active line item. This action is necessary to check if the worker is about to pick from the correct bin. If that is the case, we send the worker the quantity to pick. If not, we send an error message.

![image](/assets/2024-10-25/070.png)

#### Confirm the pick

When the worker has finished picking up the goods, they confirm this by double-clicking the ProGlove button. The current line item is set to "D" for "Done," and we send the worker the next bin on the list.

![image](/assets/2024-10-25/080.png)

## Result and conclusion

In this article, we learned how easy it is to build a Peakboard application that feeds a ProGlove scanner with all the information about an SAP transfer order. We learned how to build the complete picking process. All other details about the Peakboard app are not necessary to understand the logic and architecture of the app.

The most impressive part here is how the power of Peakboard and the power of ProGlove can be combined to build a perfect and secure process.

Here's a video that shows off the application and the process of building it:

{% include youtube.html id="0NR78z-Igq0" %}



