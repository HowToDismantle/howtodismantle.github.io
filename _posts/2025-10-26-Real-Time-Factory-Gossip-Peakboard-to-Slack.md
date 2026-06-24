---
layout: post
title: Real-Time Factory Gossip - Peakboard to Slack
date: 2025-10-26 05:00:00 +0000
tags: api
image: /assets/2025-10-26/title.png
image_header: /assets/2025-10-26/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Slack Apps
    url: https://api.slack.com/apps
  - name: How to use incoming webhooks
    url: https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks
downloads:
  - name: SendSlackMessage.pbmx
    url: /assets/2025-10-26/SendSlackMessage.pbmx
---
Many Peakboard applications are used to communicate and send messages. A common use case is to forward messages from a machine to a Slack channel. For example:
1. A machine sends a message to the Peakboard app, via OPC UA.
1. The Peakboard app processes the message.
1. The Peakboard app sends the message to a Slack channel dedicated for machine alerts.
1. A human sees the message on Slack and acts accordingly.

So, in today's article, we'll build a Peakboard app that lets the user write a message and send it to a Slack channel. We won't bother with connecting the app to an actual machine, since our only goal is to show how the Slack integration works. But we have plenty of other articles on [hardware integration](/category/hardware), if you're interested.

## Create a Slack App

In order for our Peakboard app to send messages to Slack, we first need to [create a Slack app](https://api.slack.com/apps). 

We select the *From scratch* option:

![image](/assets/2025-10-26/slack-create-app-from-scratch.png)

We give it a name and connect it to our Slack workspace. (It's also a good idea to upload an icon to make it pretty.) Then, we click *Create App*. 

![image](/assets/2025-10-26/slack-app-name-and-workspace.png)

Next, on the sidebar, under *Features*, we click on *Incoming Webhooks*. We turn on the *Activate Incoming Webhooks* toggle switch.

Then, we create a new webhook and copy the URL. We'll need it when building our Peakboard app.

![image](/assets/2025-10-26/slack-enable-incoming-webhooks.png)

## Build the Peakboard app

Now, let's build our Peakboard app. First, we create the UI:
1. We add a text box where the user can enter a message. We set the control name to `txtMessageText`. That way, we can refer to it later on, in our script.
1. We add a button that the user can press to send the message to Slack.

![image](/assets/2025-10-26/peakboard-app-text-box-setup.png)

Next, we create the tapped script for our button:

![image](/assets/2025-10-26/peakboard-http-call-webhook-setup.png)

It sends a POST request to the Slack webhook URL that we copied earlier. We set the body of the request to `{ "text": "#[Message]#" }`. We use the `#[Message]#` placeholder, and replace it with the message that the user entered in the text box. Finally, we also write the response that we get (after sending the request) to the log.

## Result

Now, let's take a look at our app in action. First, we type in the message that we want to send. Then, we press the send button.

![image](/assets/2025-10-26/peakboard-send-message-interface.png)

This sends an HTTP request with our message to the webhook URL. And as you can see, the message pops up in our `#machinealerts` channel (you can change the channel in the webhook settings):

![image](/assets/2025-10-26/slack-channel-message-result.png)

For more information about everything we covered today, take a look at Slack's [incoming webhook documentation](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks). The docs also explain how to use [advanced formatting options](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/#advanced_message_formatting)!