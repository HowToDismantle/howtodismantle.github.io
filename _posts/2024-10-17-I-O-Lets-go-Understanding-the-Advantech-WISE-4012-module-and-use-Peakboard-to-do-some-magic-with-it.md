---
layout: post
title: I/O, Let's go - Understanding the Advantech WISE-4012 module and use Peakboard to do some magic with it
date: 2024-10-17 12:00:00 +0200
tags: hardware mqtt api
image: /assets/2024-10-17/title.png
read_more_links:
  - name: Wise 4012 operating manual
    url: https://www.digimax.it/media_import/INDUSTRIAL%20PC/ADVANTECH/IoT%20-%20INTERNET%20OF%20THINGS/WISE-4012/WISE-4012_MAN_001.pdf
  - name: Unleashing the ICP DAS ET-2254 with MQTT and Peakboard
    url: /I-O-Lets-Go-Unleashing-the-ICP-DAS-ET-2254-with-MQTT-and-Peakboard.html
downloads:
  - name: Wise4012TestBoard.pbmx
    url: /assets/2024-10-17/Wise4012TestBoard.pbmx
---
In the past few weeks, we've discussed two I/O modules provided by ICP DAS: the [ET-2254](/I-O-Lets-Go-Unleashing-the-ICP-DAS-ET-2254-with-MQTT-and-Peakboard.html) and the [U-7560M](/I-O-Lets-Go-Unleashing-the-ICP-DAS-U-7500-series-for-cool-I-O-action-with-OPC-UA.html). In this article, we'll take a look at the Advantech WISE-4012. This module provides a network connection via Wi-Fi. It offers two digital-only outputs and four analog/digital inputs.

We will look at the traditional way of communicating with MQTT, as well as an alternative method: The REST webservice. Depending on your use case, REST may be better than MQTT, because no MQTT broker is needed.

![image](/assets/2024-10-17/010.png)

## Module Configuration

The Wise-4012 comes with a typical interface for configuring the module. Under the **Cloud** tab, there is an option to activate MQTT connectivity and provide a broker for sending and receiving messages. The actual message consists of a single JSON string that covers all inputs and outputs.

![image](/assets/2024-10-17/020.png)

Under **I/O Status**, we can set the four analog/digital inputs to either analog or digital. In our case, we use channel 1 for analog input.

![image](/assets/2024-10-17/030.png)

The **AI** tab tells us if there's already a real value on the analog input. This provides insight into the current measured at the input.

![image](/assets/2024-10-17/040.png)

## MQTT access

Here's what the incoming JSON looks like:

{% highlight json %}
{
  "s": 1,
  "t": "2024-08-08T17:48:21Z",
  "q": 192,
  "c": 0,
  "di1": true,
  "di3": false,
  "di4": false,
  "do1": true,
  "do2": false,
  "ai2": 7158.464,
  "ai_st2": 1
}
{% endhighlight %}

 The following screenshot shows how to configure the MQTT data source on the Peakboard side. We use a data path to access the information inside the JSON. The actual values are translated directly into the columns of the output table, so there's no need to process the JSON. The data source does it automatically.

![image](/assets/2024-10-17/050.png)

Let's discuss the other direction. In our [test board](/assets/2024-10-17/Wise4012TestBoard.pbmx), there are two buttons for switching the output on and off.

![image](/assets/2024-10-17/060.png)

Let's take a look at how to send the MQTT message. We're re-using the MQTT connection from the data source.

The topic is `Advantech/74FE488E8B86/ctl/do1`. It's made up of the serial number, followed by `ctl`, followed by the output channel name.

The JSON we send is pretty simple:
* `{"v":true}` to switch the output on.
* `{"v":false}` to switch the output off.

![image](/assets/2024-10-17/070.png)

## Webservice and JSON

Besides the traditional MQTT connectivity, the Wise-4012 also offers REST endpoints to check the state of the input channels and set the output channels.

For the digital input, we use the `http://<MyServer>/di_value/slot_0` endpoint. The following screenshot shows the JSON data source and the structure that is returned. We use the `DIVal[0]` path to access the first channel and get its value.

![image](/assets/2024-10-17/080.png)

The endpoints for the analog inputs have `/ai_value/` instead of `/di_value/`.  So `http://<MyServer>/ai_value/slot_0` returns the JSON with the analog input data.

![image](/assets/2024-10-17/090.png)

To set the value of an output, we use the endpoint `http://<MyServer>/do_value/slot_0` and submit the JSON string `{"DOVal":[{"Ch":0,"Val":1}]}`. This is similar to the MQTT message we used earlier. It's very important to use the `PATCH` verb to submit the message. A regular `PUT` won't do the trick. Here's the Building Block script that performs the call:

![image](/assets/2024-10-17/100.png)

## Result and conclusion

Being able to use both MQTT and REST is a great feature of the Wise-4012. However, the following video shows a downside. Since MQTT is an event based protocol, any change in value is transferred and processed immediately.

On the other hand, getting input values via REST works by sending a pull request every few seconds. So when you need precise, real-time input, MQTT is a better choice. If a couple of seconds of lag is acceptable, REST might be easier, because no MQTT broker is needed.

![image](/assets/2024-10-17/result.gif)
