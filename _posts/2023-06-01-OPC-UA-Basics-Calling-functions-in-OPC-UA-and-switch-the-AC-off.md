---
layout: post
title: OPC UA Basics - Calling functions in OPC UA to turn the AC on and off
date: 2023-06-01 12:00:00 +0200
tags: opcua tutorial
image: /assets/2023-06-01/title.png
---
In this [article]({% post_url 2023-05-15-OPC-UA-Basics-Getting-started-with-a-public-OPC-UA-server %}), we learned how to subscribe to OPC UA nodes and process the incoming values. The example was based on an A/C that provided several values, like the temperature and power consumption. Make sure to read that article first, because today we will learn how to switch the A/C on and off by using OPC UA functions.

You should download a very useful tool called [UaExpert](https://www.unified-automation.com/products/development-tools/uaexpert.html). It's free of charge and is the perfect tool to play around with any kind of OPC UA server. We will also be using it in this tutorial.

After opening UaExpert, right click on the `Servers` node in the upper left pane, and add the server `opc.tcp://opcuaserver.com:48010`, which we used in the previous tutorial. After the connection is established, you can find the hierarchy of nodes in the pane on the left side, which is the same as what we had in Peakboard. If you want to play around with the subscriptions, just drag and drop a node into the middle pane.

![image](/assets/2023-06-01/010.png)

Besides the regular nodes, there are some nodes with a pink box icon. These represent functions. In our example, there are functions for starting and stopping the A/C. To try it out, right click on the function node and click on `Call`. You can see that when the `State` of the A/C is set to `0` (off), the temperature value will start to rise, because the A/C is not running.

![image](/assets/2023-06-01/020.png)

## How to use OPC UA functions in Peakboard?

Before we begin, we need to know two things: the node ID of the function we want to call, and the node ID of the object that the function belongs to. You can find the node IDs in the `Attributes` pane on the upper right corner in UaExpert.

![image](/assets/2023-06-01/030.png)

Let's go back to our sample board and add a button to the canvas. Unfortunately (as of June 2023), there's no Building Block available for calling an OPC UA function, so we need to add a line of script. However, it's not too complicated. In the right function helper pane, just browse to `FUNCTIONS` -> `Publish to external systems` -> `MyAC (OPC UA)` -> `Call method`, and drag and drop the line to the editor.

This script function needs two parameters: the node ID of the object which the function belongs to, and the node ID of the function itself.

![image](/assets/2023-06-01/040.png)

Here's the original line of script, in case you want to copy and paste. Make sure to change the ID of the shared connection before using this.

{% highlight lua %}
connections.getfromid('FaaQ/H+xDfhKpywNrZl64jMXlx0=').callmethod('ns=3;s=AirConditioner_1', 'ns=3;s=AirConditioner_1.Start')
{% endhighlight %}

To make our sample more beautiful, we add two buttons for each A/C: one for turning it on and one for turning it off. And we also put an icon on the canvas to indicate the `State` of the A/C, with the help of some conditional formatting (see the other tutorial or just download the sample).

![image](/assets/2023-06-01/050.png)

And here's what it looks like in action. As soon as we switch the A/C off, the ON/OFF icon turns dark (conditional formatting on the subscribed `State` node), and the temperature starts to rise. When we switch it on again, the cooling begins and the temperature starts to drop.

![image](/assets/2023-06-01/060.gif)
