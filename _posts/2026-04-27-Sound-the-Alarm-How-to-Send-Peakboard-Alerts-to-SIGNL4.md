---
layout: post
title: Sound the Alarm - How to Send Peakboard Alerts to SIGNL4
date: 2023-03-01 00:00:00 +0200
tags: api usecase
image: /assets/2026-04-27/title.png
bg_alternative: true
read_more_links:
  - name: SIGNL4 Website
    url: https://www.signl4.com
  - name: Peakboard on SIGNL4 repo
    url: https://github.com/signl4/docs/blob/main/integrations/peakboard/peakboard.md
  - name: Documentation Webhook
    url: https://docs.signl4.com/integrations/webhook/webhook.html
  - name: More about APIs
    url: /category/api
downloads:
  - name: SIGNL4DemoBoard.pbmx
    url: /assets/2026-04-27/SIGNL4DemoBoard.pbmx
---
SIGNL4 is a mobile alerting platform built by [Derdack](https://www.derdack.com/) that bridges the gap between automated systems and the people who need to react. It delivers critical alerts via push notifications, SMS, and voice calls. But it's more than just a notification cannon. SIGNL4 adds on-call scheduling, automatic escalation, acknowledgment tracking, and team collaboration right out of the box. If an alert isn't acknowledged within a defined time window, it automatically escalates to the next person on duty and a lot more features.

For industrial environments, this is a game changer. Imagine a Peakboard application monitoring production KPIs, machine states, or sensor data on the shop floor. The moment a critical threshold is crossed — a temperature spike, a conveyor belt stop, or an OEE drop below target — Peakboard can fire off an alert directly to SIGNL4. Within seconds, the right technician gets a push notification on their phone, complete with all the context they need: which machine, what happened, and how bad it is.

The integration itself is surprisingly simple. SIGNL4 exposes a clean REST API (essentially a webhook) that accepts JSON payloads. Since Peakboard supports HTTP calls through Lua scripting and Building Blocks, connecting the two is just a matter of crafting a POST request with the right data.

In this article, we'll walk through the complete setup: creating a SIGNL4 team, getting the webhook URL, and putting together the Building Blocks in Peakboard. As a nice extension we will even create a notificaition with an cam image attached.

## Setting up the SIGNL4 account


