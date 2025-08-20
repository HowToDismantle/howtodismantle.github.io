---
layout: post
title: Peakboard UI Hacks - Next-Level Custom Dialogs
date: 2023-03-01 05:00:00 +0300
tags: ui bestpractice
image: /assets/2025-08-24/title.png
image_header: /assets/2025-08-24/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Influx Docker Image
    url: https://hub.docker.com/_/influxdb
downloads:
  - name: CustomDialogs.pbmx
    url: /assets/2025-08-24/CustomDialogs.pbmx
---
Every Peakboard app consists of one or more screens, much like windows in classic desktop software. Sometimes we need a modal dialog to confirm an action or collect a value before continuing.
This article covers best practices for building such dialogs: place all required controls on the screen, hide them, and reveal them when needed. We walk through the process step by step.

## Preparing the screen

We start with a button that opens the dialog. We add a shape as the background and place a text box, text input, and another button on top of it.

![image](/assets/2025-08-24/010.png)

Next, we group the dialog-related controls. Dragging one control onto another in the control tree on the left creates a new group automatically. We give this group a descriptive name.

![image](/assets/2025-08-24/020.png)

We right-click the group and hide it so the dialog remains invisible.

![image](/assets/2025-08-24/030.png)

## Building the logic

The first button switches the group's visibility back to `Show`.

![image](/assets/2025-08-24/040.png)

The `OK` button processes the input and hides the group again.

![image](/assets/2025-08-24/050.png)

## Result

The result demonstrates the dialog in action. This technique lets us build any kind of complex input or alert dialog.

![image](/assets/2025-08-24/result.gif)
