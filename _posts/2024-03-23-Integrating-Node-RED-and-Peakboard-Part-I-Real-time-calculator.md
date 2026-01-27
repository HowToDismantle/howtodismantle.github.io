---
layout: post
title: Integrating Node-RED and Peakboard - Part I - Real-time calculator
date: 2024-03-23 12:00:00 +0200
tags: api mqtt
image: /assets/2024-03-23/title.png
read_more_links:
  - name: How to install Node-RED on Windows
    url: https://nodered.org/docs/getting-started/windows
  - name: Node-RED main website
    url: https://nodered.org/
  - name: Part I - Real-time calculator
    url: /Integrating-Node-RED-and-Peakboard-Part-I-Real-time-calculator.html
  - name: Part II - Sending Alerts to a Peakboard application
    url: /Integrating-Node-RED-and-Peakboard-Part-II-Sending-Alerts-to-an-Peakboard-application.html
  - name: Questions? Please post in reddit
    url: https://www.reddit.com/r/Peakboard/comments/1bnb7tm/integrating_nodered_and_peakboard/
downloads:
  - name: NodeRedCalculator.pbmx
    url: /assets/2024-03-23/NodeRedCalculator.pbmx
  - name: Node-RED flow used in this article
    url: /assets/2024-03-23/flow.json
---
In this two-part article series, we discuss some best practices for integrating Peakboard with Node-RED applications.

Most of the time, communication between Node-RED and the outside world happens through MQTT or HTTP. We will use the HTTP option:

[Part I - Real-time calculator](/Integrating-Node-RED-and-Peakboard-Part-I-Real-time-calculator.html) -
How to send information from Peakboard to Node-RED, do something with it, and then process the result in real-time.

[Part II - Sending Alerts to a Peakboard application](/Integrating-Node-RED-and-Peakboard-Part-II-Sending-Alerts-to-an-Peakboard-application.html) -
How to send an alert from a Node-RED flow and visualize it in a Peakboard application.

## Goals for this article

In this article, we build a Peakboard application that does the following:
1. Take in two numbers from the user.
2. Submit the two numbers to a Node-RED flow, which will add the numbers and return the sum.

The purpose of this exercise is to understand how to use Peakboard to submit and receive information from Node-RED.

## Building the Node-RED flow

The following screenshot shows the flow we're using. Here's what the flow does:
1. An `HTTP In` node receives the call.
2. A Function node adds the two numbers from the JSON payload of the call.
3. A Template node creates the response.
4. An `HTTP Response` node returns the response to the caller.

We also add Debug nodes so that we can follow the flow in the debug window, when it's executed.

![image](/assets/2024-03-23/010.png)

The `HTTP In` node listens at the `/Add` URL:

![image](/assets/2024-03-23/020.png)

The Function node adds the two numbers, `X` and `Y`. It creates a third attribute in the payload, `result`, to hold the result:

![image](/assets/2024-03-23/021.png)

The actual response is created with a Template node. It's a simple JSON object which has a `Result` property that points to the result we created in the last step:

![image](/assets/2024-03-23/022.png)

The `HTTP Response` node doesn't need any additional configuration. It simply returns the payload to the caller:

![image](/assets/2024-03-23/023.png)

## Building the Peakboard app

The Peakboard app is super simple. There are two text fields for the input, a button that sends the request, and a text field for the output. We also make sure to give the text fields proper names, so we can use them in scripting.

![image](/assets/2024-03-23/030.png)

The actual script consists of two steps:

1. Call the HTTP endpoint of the Node-RED flow.
2. Concatenate the strings to build a proper JSON object with the two numbers from the text fields, `X` and `Y`.

Here's what the JSON looks like:

{% highlight json %}
{
    "X": 36,
    "Y": 42
}
{% endhighlight %}

We also set the `Content-Type` header to `application/json`. Otherwise, the flow won't know that we're sending a JSON object.

The call returns the JSON response. Here's what it looks like:

{% highlight json %}
{
    "Result": 78
}
{% endhighlight %}

To extract the result from the response, we use a JSON path block, and address the `Result` attribute. The value is put into the text field we prepared earlier.

![image](/assets/2024-03-23/040.png)

## Conclusion

Here's the application in action, along with the debug window in Node-RED:

![image](/assets/2024-03-23/result.gif)

![image](/assets/2024-03-23/050.png)

