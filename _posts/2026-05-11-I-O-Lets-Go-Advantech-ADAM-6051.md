---
layout: post
title: I/O, Let's Go - Advantech ADAM-6051
date: 2023-03-01 12:00:00 +0200
tags: hardware mqtt api opcua
image: /assets/2026-05-11/title.png
bg_alternative: true
read_more_links:
  - name: I/O, Let's go - The hitchhiker's guide to I/O devices
    url: /I-O-Lets-go-The-hitchikers-guide-to-I-O-devices.html
  - name: Advantech Adam 6051
    url: https://www.advantech.com/en-us/products/a67f7853-013a-4b50-9b20-01798c56b090/adam-6051/mod_553e7ce9-ca10-4990-a130-0033d1b28566
  - name: Advantech Adam series manual
    url: https://advdownload.advantech.com/productfile/Downloadfile4/1-2B6FKTG/ADAM-6000_User_Manaul_Ed.12-FINAL.pdf
  - name: Advantech Adam discovery tool
    url: https://www.advantech.com/en-us/support/details/utility?id=1-9VJDY
downloads:
  - name: Adam6051TestBoard.pbmx
    url: /assets/2026-05-11/Adam6051TestBoard.pbmx
---
In this blog, we've discussed a few different ways to integrate sensors into a Peakboard application. We can find an overview of these articles in [The hitchhiker's guide to I/O devices](/I-O-Lets-go-The-hitchikers-guide-to-I-O-devices.html).

In today's article, we'll take a look at the ADAM-6051 by Advantech. The ADAM-6051 is a compact, Ethernet-based I/O module that provides 12 digital input channels and 2 digital output channels, along with 2 built-in counters. It supports Modbus/TCP, MQTT, and SNMP protocols. In this article, we will walk through the basic steps of configuration and then primarily use the MQTT interface to build a demo dashboard that reads input states and controls output channels.

## Configuration

There are two ways to configure the device: via a web interface, like most other I/O adapters, and through a desktop tool. We will have a look at the desktop tool, which can be downloaded [here](https://www.advantech.com/en-us/support/details/utility?id=1-9VJDY). It requires a .NET runtime 2.0 to work, which feels a bit like a throwback to the 90s. After installation, we can right-click on the Ethernet node and choose `Find Devices`. Chances are high that it automatically discovers our ADAM device and adds it to the tree. On the right side, there are several configuration tabs.

![Advantech ADAM-6051 discovered in the desktop configuration tool with device tree and settings tabs](/assets/2026-05-11/advantech-adam-6051-desktop-discovery-tool.png)

The first thing we need to check is whether the device should use a static IP address or obtain a dynamic IP address from DHCP. If we're unsure about the right configuration for our network, we can ask the sys admin or simply try both options and see which one works.

![Configuring static or DHCP IP address for the Advantech ADAM-6051 module](/assets/2026-05-11/advantech-adam-6051-static-dhcp-ip-configuration.png)

For the MQTT connection, we choose the `Cloud` tab, change the Service to `MQTT`, and fill in the address of our MQTT broker. It's possible to adjust how and which MQTT topics are published when the I/O status changes. For our experimental purposes, the default mode works perfectly fine.

![Advantech ADAM-6051 Cloud tab with MQTT broker address and topic configuration](/assets/2026-05-11/advantech-adam-6051-mqtt-broker-cloud-tab-configuration.png)

Let's switch over to the Peakboard side. For the data source, we simply use a regular MQTT source and subscribe to the topic `Advantech/74FE48BE369F/data`, where `74FE48BE369F` is the MAC address of our device. Every time the ADAM module publishes an update, it returns a JSON string that contains the values of all input and output channels along with some additional status information.

![Peakboard MQTT data source subscribing to the Advantech ADAM-6051 data topic](/assets/2026-05-11/peakboard-mqtt-data-source-subscribing-adam-6051-topic.png)

It's not necessary to parse the JSON manually. We just add a dataflow that uses the `Parse JSON` activity to turn the raw payload into a usable Peakboard table with exactly one row and a column for each attribute. This way, we can bind individual channel values directly to visual elements on our canvas.

![Peakboard dataflow using Parse JSON to convert ADAM-6051 MQTT payload into a table](/assets/2026-05-11/peakboard-dataflow-parse-json-adam-6051-payload.png)

For our demo board, we use some conditional formatting to color the indicator bubbles red by default and switch them to green when the channel value is `True`. This gives us an immediate visual representation of which inputs are currently active.

![Peakboard dashboard with conditional formatting showing digital input channel states as colored indicators](/assets/2026-05-11/peakboard-dashboard-conditional-formatting-digital-inputs.png)

## Setting the output values

Setting the output channels is actually straightforward. The MQTT topic for a channel follows the pattern `Advantech/<MAC>/ctl/sensor/do_value/<channel>`. The tricky part is the JSON payload. For reasons only the Advantech engineers know, the JSON value to set the output to `true` is `{"Ch":0,"En":1,"Md":0,"Stat":1,"Val":1,"PsCtn":0,"PsIV":0}`. To change it back to `false`, we need to adjust both the `Stat` and the `Val` fields to `{"Ch":0,"En":1,"Md":0,"Stat":0,"Val":0,"PsCtn":0,"PsIV":0}`. The screenshot below shows the Building Blocks logic that we use to toggle the output:

![Peakboard Building Blocks logic to toggle ADAM-6051 digital output via MQTT publish](/assets/2026-05-11/peakboard-building-blocks-mqtt-toggle-digital-output.png)

## Alternative to MQTT: Using Modbus

In case we don't want to use MQTT — for example, because we don't have an MQTT broker in place — we can easily use Modbus/TCP to communicate with our ADAM-6051 instead. The Modbus register addresses can be looked up in the Modbus tab of the admin tool. Let's check the first output channel as an example. It shows that the output channels start with Base 17, which means we need to address the byte ordinal number 16 in the Peakboard data source (since Modbus addressing is zero-based).

![Advantech ADAM-6051 Modbus register address table showing output channel base addresses](/assets/2026-05-11/advantech-adam-6051-modbus-register-address-configuration.png)

And here's how the corresponding Modbus data source is configured in the Peakboard Designer. We simply point it to the IP address of our ADAM device and specify the register range we want to read.

![Peakboard Modbus TCP data source configured to read from ADAM-6051](/assets/2026-05-11/peakboard-modbus-tcp-data-source-adam-6051.png)

## Result

The video shows the final result in action. When we toggle the output through MQTT, the color of the button changes accordingly. This happens because setting the output value causes the ADAM device to publish a new MQTT message with the updated state, which in turn triggers the conditional formatting on our dashboard. So when the color actually changes, we can be confident that the device has received and confirmed the command — a nice built-in feedback loop.

![Demo of Peakboard dashboard toggling ADAM-6051 digital outputs via MQTT with real-time feedback](/assets/2026-05-11/advantech-adam-6051-peakboard-mqtt-toggle-demo.gif)


