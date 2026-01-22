---
layout: post
title: Draw, Sign, Approve – A New Interactive Drawing Area for Peakboard
date: 2026-01-22 00:00:00 +0000
tags: peakboardhub image
image: /assets/2026-01-22/title.jpg
image_header: /assets/2026-01-22/title.jpg
bg_alternative: true
read_more_links:
  - name: More image processing
    url: /category/image
  - name: How to build an auditing app
    url: /Digital-Walkaround-Inspections-Part-I-How-to-Build-an-Audit-App.html
downloads:
  - name: SignBoard.pbmx
    url: /assets/2026-01-22/SignBoard.pbmx
---
With the new version 4.1, released in late 2025, the Peakboard team introduced a new visual control: the Drawing Area. This control allows end users to draw on a touchscreen using their fingers or a pen, depending on the device. It can be used for signing documents, scribbling sketches, or similar tasks. The signature use case is likely the most common. Some readers may remember the [audit use case](/Digital-Walkaround-Inspections-Part-I-How-to-Build-an-Audit-App.html), which would be a perfect fit for using the drawing area to let users sign the final results of the audit.

## The Drawing Area Control

The control comes with several settings. End users can choose the color and thickness of the drawing line using built-in buttons. There is also a button for clearing the area and activating or deactivating the drawing process. Whether to show or hide these options to the end user can be defined through the corresponding property.

In our example, we will hide all these buttons and offer the end user only a black drawing line for their signature.

![image](/assets/2026-01-22/010.png)

## Preparing the Screen

For our example, we assume the user needs to sign an order. The order number is stored in a variable. To process the signature, we must place the drawing area control into a group and name the group `SignGroup`. 

![image](/assets/2026-01-22/020.png)

## Processing the Drawing

To process a drawing, we use a universal function. Peakboard offers several Building Blocks to process the screenshot of a group. Our group `SignGroup` consists of only one control: the drawing area control. For uploading the signature, we use the Peakboard Hub file system to store it. However, we could also choose different destinations like SharePoint or email (see the right area of the screenshot). If necessary, we can pass the signature to an external, generic API using Base64 encoding to submit the image for processing.

In our example, the signature is stored with a timestamp and the order number in the filename in a dedicated Hub file system folder. Then, the area is cleared for the next signature.

![image](/assets/2026-01-22/030.png)

## Result

For our test, we sign the order...

![image](/assets/2026-01-22/040.png)

... and check the Peakboard Hub filesystem to confirm the signature is stored successfully.

![image](/assets/2026-01-22/050.png)



