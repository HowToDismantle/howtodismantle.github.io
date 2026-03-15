---
layout: post
title: Mission RFC Possible – Executing Custom Function Modules with Integration Flows
date: 2025-06-07 03:00:00 +0200
tags: sap
image: /assets/2025-06-05/title.png
image_landscape: /assets/2025-06-05/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Breaking the Ice - How SAP Integration Suite and Peakboard Hub Became Best Friends
    url: /Breaking-the-Ice-How-SAP-Integration-Suite-and-Peakboard-Hub-Became-Best-Friends.html
  - name: Download CLoud Connector
    url: https://tools.hana.ondemand.com/#cloud
downloads:
  - name: Iflow Z_PB_DELIVERY_MONITOR.zip
    url: /assets/2025-06-05/Z_PB_DELIVERY_MONITOR.zip
  - name: SAPDeliveries.pbmx
    url: /assets/2025-06-05/SAPDeliveries.pbmx
---
A couple of weeks ago, we took introduced SAP BTP and the SAP Integration Suite. We explained how to [connect an integration flow to Peakboard Hub](/Breaking-the-Ice-How-SAP-Integration-Suite-and-Peakboard-Hub-Became-Best-Friends.html).
In this article, we will explain how to build an integration flow that exposes a JSON endpoint that Peakboard can call.

This integration flow calls an RFC function module in SAP. The SAP system is connected to BTP with a Cloud Connector. This setup is typical of a customer who has on-prem SAP systems, but would like to use BTP and the Integration Suite to communicate with the non-SAP programs (like a Peakboard application).

## The RFC function module

In our example, we use a simple custom function module called `Z_PB_DELIVERY_MONITOR`. It has one import parameter, `I_VSTEL`, which represents a shipping point. It returns a table of delivery rows that are in the shipping process on the shipping point.

The following screenshots show a call in the test cockpit of transaction SE37. When we submit the shipping point `I_VTEL = 1000`, it returns 11 deliveries that are about to be shipped. We want to build an integration flow that does this:
1. Receive the shipping point, `I_VSTEL`, as query parameter.
2. Return the deliveries as a JSON table.

![image](/assets/2025-06-05/010.png)

![image](/assets/2025-06-05/020.png)

## Set up the Cloud Connector

The [SAP Cloud Connector](https://tools.hana.ondemand.com/#cloud) must be installed in the on-prem side of the SAP system. To connect it to the BTP portal, follow these steps:

1. Configure the installed instance of the Cloud Connector through `https://localhost:8443/`.
2. In the Cloud Connector configuration, enter the sub-account of the BTP instance you want to connect to. You need the ID and region. You can look these up directly in BTP.
3. In the sub-menu of the sub-account, select **Cloud to on-premises** and create a new **Mapping virtual to Internal System**. In our case, the system is an ABAP system.
4. Enter all the standard attributes, like application host, instance number, and credentials. 
5. Below the system entry, provide the resources you want to connect to. That's the name of your function module. The following screenshot shows the configured sub-account, mapped system, and resource.
   ![image](/assets/2025-06-05/030.png)
6. Go to the BTP portal and select the corresponding sub-account. Select the **Cloud Connectors** tab. You can see the active connection under **Exposed Back-End Systems**.
   ![image](/assets/2025-06-05/040.png)
7. Select **Destination**. Enter the standard attributes like the application server, instance number, etc. Later, in the integration flow, we refer to the destination name. The integration flow finds its connection through the corresponding attributes. It "finds" the route through Cloud Connector.
   ![image](/assets/2025-06-05/050.png)
8. Click the **Check Connection** button to verify the connection works.
   ![image](/assets/2025-06-05/060.png)

## Build the integration flow

Our integration flow translates an incoming HTTP call into an RFC call. Here's an overview of the steps it takes:

1. Configure the incoming HTTP call.
2. Prepare the XML for the RFC call.
3. Make the RFC call.
4. Translate the RFC call's response from XML to JSON.
5. Return the JSON string to the caller.

This screenshot shows the whole integration flow:

![image](/assets/2025-06-05/070.png)

Now, let's explain each step in more detail.

### Configure the incoming HTTP call

We define the route for the external call. In our case, we use the name of the function module.

![image](/assets/2025-06-05/080.png)

It's also important to allow the parameter `i_vstel` to be routed from the external caller into a header within the integration flow.

![image](/assets/2025-06-05/075.png)

### Prepare the XML for the RFC call

The payload that represents the RFC call is in XML. For our relatively simple function module, this is the XML. The actual value of shipping point for the parameter `I_VSTEL` is filled with the script expression `${header.i_vstel}`. So, it's taken dynamically from the header.

{% highlight xml %}
<ns1:Z_PB_DELIVERY_MONITOR xmlns:ns1="urn:sap-com:document:sap:rfc:functions">
     <I_VSTEL>${header.i_vstel}</I_VSTEL>
</ns1:Z_PB_DELIVERY_MONITOR>
{% endhighlight %}

![image](/assets/2025-06-05/090.png)

There are different steps if you want to [form the XML with complex function modules](https://community.sap.com/t5/technology-blog-posts-by-sap/cloud-integration-creating-xml-structure-for-remote-function-call-rfc-that/ba-p/13559556).

### Make the RFC call

We send the RFC call with a request reply step. The only thing we need to configure is the name of the destination (see above). The payload and the name of the function module to call is defined in the XML. 

![image](/assets/2025-06-05/100.png)

### Translate the RFC call's response

The response from the RFC call is in XML, as part of the message body. It's easier to deal with JSON than RFC, when we're in Peakboard. So, we translate the XML code into JSON with an XML to JSON converter.

![image](/assets/2025-06-05/110.png)

## Authentication

The caller of the service must be authenticated. The easiest way to do this is to go to the integration runtime in the BTP portal and generate a pair of service keys. You can use the client ID and client secret to authenticate the call, with basic authentication.

![image](/assets/2025-06-05/120.png)

## The Peakboard application

In Peakboard Designer, we create a new JSON data source. It makes a call to our integration flow, with one query parameter called `I_VSTEL`. To choose the right path to the table data within the JSON string, we click on the three dots. This opens up a helper that makes things a lot easier.

If the function module is more complicated, the path for processing the body may also be more complicated. But in our case, the main payload is simply the table of deliveries.

![image](/assets/2025-06-05/130.png)

## Result

We use a table control with some fancy formatting to present the data. This screenshot shows the final result of the Peakboard application:

![image](/assets/2025-06-05/140.png)

