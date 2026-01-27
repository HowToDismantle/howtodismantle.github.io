---
layout: post
title: DIY Guide - Transform Your Peakboard Box into an MQTT Server 
date: 2025-02-21 00:00:00 +0000
tags: mqtt
image: /assets/2025-02-21/title.png
image_header: /assets/2025-02-21/title_landscape.png
read_more_links:
  - name: MQTT Server Extension
    url: https://templates.peakboard.com/extensions/MQTT-Server/index
  - name: Other MQTT topics
    url: /category/opcuamqtt
downloads:
  - name: MQTTDIY.pbmx
    url: /assets/2025-02-21/MQTTDIY.pbmx
---
On this blog, we've explored many projects that use MQTT to communicate between Peakboard apps and sensors and other hardware and software entities. MQTT is a nice and easy option to couple all these entities together. Especially because there's no need for the entities to "know" each other. They just submit their messages to an MQTT broker or subscribe to messages from the broker.

The downside of MQTT is that we need an MQTT broker. So even when there's only one sensor and one Peakboard application, we need an additional server to exchange the MQTT messages.

In this article, we'll explore an easy way to turn a Peakboard Box into a fully functional MQTT broker. So in a simple scenario with one sensor and one Peakboard application, no additional server is necessary. The sensors connect directly to a Peakboard Box that exposes an MQTT broker endpoint. This way, we can avoid the set-up of a separate MQTT server.

If scenarios get more complex (e.g. 5 sensors and multiple boxes with bidirectional message exchange), we must carefully evaluate if this technique still makes sense. For a good, robust architecture, it might be better to switch back to the traditional, separate MQTT server, and not rely on a single Box.

## Install and use the MQTT Server extension

To set up an MQTT broker alongside the Peakboard application, we use the MQTT Server extension, which can be installed directly from the extension pane when creating a new data source:

![image](/assets/2025-02-21/010.png)

The MQTT server only needs to know which port to listen to for incoming connections---by default, it's 1883. To complete the configuration, we must click the reload button. The output of the data source can be used to display the current state of the sever: `Init` or `Running`.

![image](/assets/2025-02-21/020.png)

The server needs a start command to open the endpoint for external connections. That's why we set up a timer that runs once. This timer event calls the `start` function of the MQTT Server data source.

![image](/assets/2025-02-21/030.png)

When Peakboard attempts to open a TCP/IP port to the outside world for the first time, it will trigger the Windows firewall. So, you need to allow Peakboard to open the port:

![image](/assets/2025-02-21/040.png)

## Configure a button to send MQTT messages

For our example MQTT-enabled sensor, we use a [Shelly button](/Building-an-emergency-button-with-Shelly-Button1-and-MQTT.html). Each time the button is pressed, a JSON string is sent to the dedicated MQTT broker. In our example, the MQTT broker is the Peakboard Box. So, we put the IP address of the Box in the **Server** field of the Shelly button web configuration.

![image](/assets/2025-02-21/050.png)

## Build the Peakboard app

For the MQTT source, we choose `localhost` as the MQTT broker address. So when the Peakboard application is running, the broker can always be reached as `localhost`. We also subscribe to the MQTT node where the Shelly button is submitting its events to. 

![image](/assets/2025-02-21/060.png)

The rest of the application displays the current status of the MQTT server and the JSON string sent by the button.

![image](/assets/2025-02-21/070.png)

## Result and conclusion

The following screenshot shows the result after a button press. As you can see in the JSON string, the type is `S`, which means that the button has been pressed only once for a short moment.

![image](/assets/2025-02-21/080.png)

