---
layout: post
title: I/O, Let's Go - Advantech ADAM-6051
date: 2023-03-01 12:00:00 +0200
tags: hardware mqtt api opcua
image: /assets/2026-05-11/title.png
image_header: /assets/2026-05-11/title_landscape.png
read_more_links:
  - name: I/O, Let's go - The hitchhiker's guide to I/O devices
    url: /I-O-Lets-go-The-hitchikers-guide-to-I-O-devices.html
  - name: Advantech Adam 6051
    url: https://www.advantech.com/en-us/products/a67f7853-013a-4b50-9b20-01798c56b090/adam-6051/mod_553e7ce9-ca10-4990-a130-0033d1b28566
  - name: Advantech Adam series manual
    url: https://advdownload.advantech.com/productfile/Downloadfile4/1-2B6FKTG/ADAM-6000_User_Manaul_Ed.12-FINAL.pdf
  - name: Advantech Adam discovery tool
    url: https://advdownload.advantech.com/productfile/Downloadfile4/1-2B6FKTG/ADAM-6000_User_Manaul_Ed.12-FINAL.pdf
downloads:
  - name: xxx.pbmx
    url: /assets/2026-05-11/xxx.pbmx
---
In this blog, we've discussed a few different ways to integrate sensors into a Peakboard application. You can see an overview of these articles in [The hitchhiker's guide to I/O devices](/I-O-Lets-go-The-hitchikers-guide-to-I-O-devices.html).

In today's article, we'll take a look at the Adam 6051 by Advantech. The ADAM-6051 is a compact, Ethernet-based I/O module that provides 12 digital input channels and 2 digital output channels, along with 2 built-in counters. It supports Modbus/TCP, MQTT, and SNMP protocols. In this article we will walk through the basic steps of configuration and mainly use of their MQTT interface to build a demo dashboard.

## configuration




![image](/assets/2024-11-25/010.png)

