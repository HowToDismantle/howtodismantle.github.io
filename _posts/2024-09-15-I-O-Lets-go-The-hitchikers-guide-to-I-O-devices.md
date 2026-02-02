---
layout: post
title: I/O, Let's go - The hitchhiker's guide to I/O devices 
date: 2024-09-15 12:00:00 +0200
tags: hardware mqtt api opcua
image: /assets/2024-09-15/title.png
read_more_links:
  - name: Unleashing the ICP DAS ET-2254 with MQTT and Peakboard
    url: /I-O-Lets-Go-Unleashing-the-ICP-DAS-ET-2254-with-MQTT-and-Peakboard.html
---
In this blog, we've explained how to connect various devices to Peakboard, and build beautiful applications. One family of devices is I/O devices. These are used to connect any kind of sensor, like light barriers, buttons, and temperature sensors. On the output side, we often see actors like traffic lights and sound alarms.

On the market, there are literally hundreds of these I/O devices, and the vast majority of them work very well with Peakboard. This can be confusing for customers who have just started their journey and are trying to figure out which brand or device they want to build their architecture on.

In this article, we'll take a look at the five most common ways for connecting a Peakboard Box to an I/O device. We'll also introduce four I/O devices and their features.

## Technical connectivity

There are countless ways to connect to I/O devices, but these five are the most common among Peakboard customers.

1. **OPC UA.** The I/O device exposes an OPC UA endpoint and Peakboard connects as a client to this OPC UA server. Depending on the device, the number of Peakboard clients might be limited to 3 or 5.
2. **MQTT.** The I/O device is connected to an MQTT broker, and Peakboard also connects to this broker. The bidirectional dataflow is established by exchanging messages through MQTT topics.
3. **Modbus.** The I/O device exposes a Modbus TCP endpoint and can be addressed by using the Modbus data source in the Peakboard application.
4. **REST API.** The I/O device exposes a REST API endpoint that Peakboard can use with the JSON data source.
5. **PLC.** The I/O device is not directly connected to the network, but instead connected to a PLC. In this case, the Peakboard application talks to the PLC (could be Siemens, Mitsubishi, Rockwell, or any other). This method only makes sense when the Peakboard app already uses this PLC connection for other activities.

### Advantech WISE-4012

The Advantech WISE-4012 comes with the following:

* 4 Analog / Digital Inputs
* 2 digital outputs

It supports MQTT, REST API, and Modbus access. It's meant to only be used with Wi-Fi, so no LAN plug is available.

Estimated cost: 160 EUR

Here's a relevant article on this blog: [Understanding the Advantech WISE-4012 module and use Peakboard to do some magic with it
](/I-O-Lets-go-Understanding-the-Advantech-WISE-4012-module-and-use-Peakboard-to-do-some-magic-with-it.html)

[Click here to jump directly to the vendor](https://buy.advantech.eu/SRP-IoT-Gateways/IoT-Gateways-Devices-IoT-Wireless-I-O/model-WISE-4012-AE.htm?gad_source=1&gclid=Cj0KCQjw6uWyBhD1ARIsAIMcADqrDuho0MeX74GCqbDntv0ghvNkM322MBmhCc3lf9Dh2iv-wFQGe7AaAl6ZEALw_wcB)

![image](/assets/2024-09-15/010.png)

### ICP DAS ET-2254

The ET-2254 is perfect for wired networks. It offers 16 I/O ports that can be freely defined as either input or output. Access is possible through MQTT and Modbus.

Estimated cost: 173 EUR

Here's a relevant article on this blog: [Unleashing the ICP DAS ET-2254 with MQTT and Peakboard](/I-O-Lets-Go-Unleashing-the-ICP-DAS-ET-2254-with-MQTT-and-Peakboard.html)

[Click here to jump directly to the vendor](https://www.icpdas.com/en/product/ET-2254)

![image](/assets/2024-09-15/020.png)

### ICP DAS U-7560M

The U-7500 series comes with an OPC UA interface for super easy connectivity. It has 6 inputs and 6 outputs. It also supports MQTT, but OPC UA is preferable to MQTT if both are available.

Estimated cost: 176 EUR

Here's a relevant article on this blog: [I/O, Let's Go - Unleashing the ICP DAS U-7500 series for cool I/O action with OPC UA ](/I-O-Lets-Go-Unleashing-the-ICP-DAS-U-7500-series-for-cool-I-O-action-with-OPC-UA.html)

[Click here to jump directly to the vendor](https://icpdas-europe.com/Remote-I-O-Module/MQTT/U-7560M-CR)

![image](/assets/2024-09-15/030.png)

### Pepperl+Fuchs IO-Link-Master ICE2-8IOL-G65L-V1D

This device supports IO-Link devices and sensors. The configuration via the web interface is easy.

For the connectivity, you can choose between OPC, MQTT and Modbus. The nice thing with OPC UA is that the attributes of the connected IO-Link device are reflected in the node structure. This makes it easy to connect and find the right values during design time. The downside is that IO-link-related devices are usually much more expensive.

Estimated cost: 700-900 EUR

Here's a relevant article on this blog: [I/O, Let's Go - Going crazy for Pepperl+Fuchs IO-Link-Master ICE2-8IOL-G65L-V1D](/I-O-Lets-Go-Going-crazy-for-Pepperl-Fuchs-IO-Link-Master-ICE2-8IOL-G65L-V1D)

[Click here to jump directly to the vendor](https://www.pepperl-fuchs.com/germany/de/classid_4996.htm?view=productdetails&prodid=96749
)

![image](/assets/2024-09-15/040.jpg)

## Overview


|  | WISE-4012​ | ET-2254​​ | U-7560M CR​​ | IO-Link​​ |
| ------------- | ------------- |
| WLAN​  | X |  |  |  |
| Ethernet​  |  | X | X | X |
| OPC-UA​  |  |  | X | X |
| MQTT​  | X | X | X | X |
| Modbus​  | X | X |  | X |
| IO-Link  |  |  |  | X |


