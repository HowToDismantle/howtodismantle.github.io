---
layout: post
title: Peakboard Meets Shelly - Building a Smart Dashboard for Tracking Temperature and Humidity
date: 2025-04-02 01:00:00 +0200
tags: hardware mqtt
image: /assets/2025-04-02/title.png
image_landscape: /assets/2025-04-02/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Shelly H&T Gen3
    url: https://www.shelly.com/products/shelly-h-t-gen3-matte-black
  - name: Shelly H&T API Documentation
    url: https://shelly-api-docs.shelly.cloud/gen2/Devices/Gen3/ShellyHTG3/
  - name: Shelly H&T Technical Documentation
    url: https://www.shelly.com/blogs/documentation/shelly-h-t-gen3?srsltid=AfmBOop_uRRkBuYODH76QXhhOjD3FCpFxvW4KtqyH2xq85LxG6U4f19C
downloads:
  - name: ShellyHT.pbmx
    url: /assets/2025-04-02/ShellyHT.pbmx
---
Over two years ago, we published two articles about Shelly products: One about [how to use the button](/Building-an-emergency-button-with-Shelly-Button1-and-MQTT.html) and another about [how to use the power plug](/Fun-with-Shelly-Plug-S-Switching-Power-on-and-off.html). A lot of time has passed since then, and many readers have come back and have actually used Shelly products in a professional industrial environment.

Today, we'll take a closer look at a relatively new product: The Shelly [Humidity and Temperature sensor](https://www.shelly.com/products/shelly-h-t-gen3-matte-black). It comes with an e-ink display and supports a Wi-Fi connection. To learn how to configure the Wi-Fi connection during the initial setup, see the [official documentation](https://www.shelly.com/blogs/documentation/shelly-h-t-gen3?srsltid=AfmBOop_uRRkBuYODH76QXhhOjD3FCpFxvW4KtqyH2xq85LxG6U4f19C).

In our example, we'll use MQTT to build a Peakboard dashboard that displays the current temperature and humidity from the Shelly sensor. We'll also store the values in Peakboard Hub and build charts to analyze the historical data.

![image](/assets/2025-04-02/010.png)

## Shelly sensor configuration

Our Shelly sensor offers two options for configuration. It comes with a built-in web interface that can be accessed during the setup process (see the official documentation). The configuration can be also done through the Shelly cloud services, provided that it's configured properly. However, if it's necessary to avoid any kind of outside connection due to security restrictions, then a cloud connection can be avoided (it's not mandatory).

The following screenshot shows the cloud-based configuration dialog. The only thing we need to configure here is the MQTT connectivity. We use a public MQTT broker, but a private one does the same. Besides the address, we also need to provide a suffix, which determines the MQTT topic.

![image](/assets/2025-04-02/020.png)

The sensor sends multiple MQTT messages every couple of minutes. Besides metadata and health information, we can also find the temperature and humidity, along with a Unix timestamp with the exact time of the last measurement. The following screenshot shows the MQTT message, in MQTT Explorer.

It's important to note that the Shelly sensor goes to sleep in between the two measurements, to save energy. It evens disconnects from Wi-Fi during that time. So we usually can't ping the sensor within the local network.

![image](/assets/2025-04-02/030.png)

## Build the Peakboard app

On the Peakboard side, we need an MQTT connection. As shown in the following screenshot, we subscribe to three different topics: temperature, humidity, and time.

- `MyShellyTemperature/status/humidity:0`
- `MyShellyTemperature/status/temperature:0`
- `MyShellyTemperature/status/sys`

We then use the data path to find the desired value within the JSON message.

![image](/assets/2025-04-02/040.png)

In order to turn the Unix timestamp into a properly formatted value, we use a data flow, along with single line of LUA code:

{% highlight lua %}
os.date("%Y-%m-%d %H:%M:%S", tonumber(item.Unixtime))
{% endhighlight %}

![image](/assets/2025-04-02/050.png)

To display the values to the user, we use tiles, bind it to the source, and make sure the data is formatted correctly with a unit.

![image](/assets/2025-04-02/060.png)

## Historical analysis

To store the values for future analysis, we create a list in [Peakboard Hub](/Peakboard-Hub-Online-An-introduction-for-complete-beginners.html). We add a timestamp column and two integer columns for the temperature and humidity.

![image](/assets/2025-04-02/070.png)

In the Peakboard app, we set up a data connection to this Hub list and query the last 100 records. This will supply the data for our historical data charts.

![image](/assets/2025-04-02/080.png)

For our charts, we use a simple line chart and connect it to the Hub list data connection. In our example, we have two separate charts: one for temperature and one for humidity.

![image](/assets/2025-04-02/090.png)

The last thing we need is to write the current values regularly to the Hub list. To do that, we set up a timer that triggers every 10 minutes and takes the value from the data flow and appends in to the list:

![image](/assets/2025-04-02/100.png)

## Result

The following screenshot shows the final result in action. The real-time data is sent from the Shelly H&T sensor to Peakboard, via MQTT. On a regular basis, these values are stored in a Hub list. The Hub list is also queried to create the historical data charts, which show the last 100 data points.

![image](/assets/2025-04-02/result.png)