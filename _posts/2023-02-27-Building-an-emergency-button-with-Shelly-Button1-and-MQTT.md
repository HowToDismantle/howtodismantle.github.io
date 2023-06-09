---
layout: post
title: Building an emergency button with Shelly Button1 and MQTT
date: 2023-02-27 12:00:00 +0200
tags: hardware
image: /assets/2023-02-27/title.jpg
read_more_links:
  - name: Shelly Button1 at Amazon
    url: https://www.amazon.de/Shelly-Button1-wei%C3%9F/dp/B08V22GWJS?th=1
  - name: Shelly Button1 API documentation
    url: https://shelly-api-docs.shelly.cloud/gen1/#shelly-button1-overview
downloads:
  - name: ShellyButtonMQTT.pbmx
    url: /assets/2023-02-27/ShellyButtonMQTT.pbmx
---
In [another article](Fun-with-Shelly-Plug-S-Switching-Power-on-and-off.html), we talked about some basics around [Shelly](https://www.shelly.cloud/) products.

In this article, we will use a Shelly Button1 to build an alarming system. The button press can send two levels of emergency to a Peakboard application, and then reset to a normal state. In a professional environment, it would be possible to use this pattern to give an end user the option to call for help, call for missing material at an assembly line, etc....

## The web interface of Shelly Button1

Please refer to the [official documentation](https://www.shelly.cloud/documents/user_guide/shelly_button_1.pdf) for how to integrate the Shelly Button into your local Wi-Fi. Then, access the web interface of the Button for the configuration.
When you click on _Actions_, you can put HTTP calls behind the different button press events (single, double, triple, long). This would be perfect for letting the Shelly Button call an external Peakboard function—then, we'd be done within minutes. The problem is: When calling an external Peakboard function, we must use an HTTP POST call, but Shelly only supports sending HTTP GET calls. Unfortunately, this is an unsolvable problem, unless you use an additional layer that transforms the HTTP GET call into an HTTP POST call. So we look for another option and ignore this feature.

![image](/assets/2023-02-27/010.png)

## Configuring Shelly's MQTT

The second best option is to use MQTT to let Peakboard and Shelly communicate. In Shelly's web interface, you can access the MQTT pane through _Internet & Security_ and _ADVANCED - DEVELOPER SETTINGS_. As you can see in this screenshot, we are using the Mosquitto MQTT broker to exchange messages and enable MQTT.

![image](/assets/2023-02-27/020.png)

When MQTT is enabled, the button sends state messages to the MQTT broker. The topic is `shellies/shellybutton1-<deviceid>/input_event/0`. The device ID depends on the button; you can check _Settings_ -> _Device Info_ to find it. The JSON message looks like this:

{% highlight json %}
{
    "event":"S",
    "event_cnt":2
}
{% endhighlight %}

The events can be _S_ for a single click, _SS_ for a double click, or _L_ for a long click. The attribute _event_cnt_ counts the number of clicks since the last reboot of the button. That's all the information we need to proceed. 

## Building the Peakboard application

On the Peakboard side, the magic happens in an MQTT data source. We connect to the known MQTT broker. The topic to subscribe to is explained above, and we provide a path that points to the _event_-Node within the JSON, so we don't need to worry about how to turn the JSON into usable information. As you see in the preview data, the _SS_ value for the double click is extracted and shown.

![image](/assets/2023-02-27/030.png)

The actual visualization is done with an Icon control. The switching between the three states is done with Conditional Formatting, so there's no coding, no scripts, and no blocks.

![image](/assets/2023-02-27/040.png)
![image](/assets/2023-02-27/050.png)
![image](/assets/2023-02-27/051.png)
![image](/assets/2023-02-27/052.png)

Finally, here you can see how the board works in real life....

{% include youtube.html id="sALXrWVR7f8" %}

