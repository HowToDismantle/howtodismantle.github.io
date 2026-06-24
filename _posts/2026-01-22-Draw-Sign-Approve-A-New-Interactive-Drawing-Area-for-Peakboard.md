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
With the release of [Peakboard version 4.1](/Peakboard-4.1-Is-Here-And-Its-a-Game-Changer.html), we now have access to a new interactive control: the **drawing area.** This control lets users create a drawing with their finger or a stylus.

You can use this control whenever you want the user to draw or sign something.
You may remember the [audit app that we made](/Digital-Walkaround-Inspections-Part-I-How-to-Build-an-Audit-App.html). That's the perfect example of an app that would benefit from this new control. For the final step of the audit process, we could make the user sign off on the audit, by adding a drawing area control.

Now, let's go over how the drawing area control works and how to set it up! We'll create a demo app where the user can sign their name and upload the signature to Peakboard Hub.

## Add the drawing area control

To add a drawing area control, look under the interactive controls, and drag-and-drop or double-click the pencil icon.

![image](/assets/2026-01-22/010.png)

The drawing area control is made up of a white canvas, with some optional buttons in the corners. These buttons let the user modify the drawing area in different ways:
* Color selection
* Thickness selection
* Clear button (erase the canvas)
* Activation button (enable/disable the drawing area)

You can activate or deactivate individual buttons, through the control configuration, under *Appearance > Drawing > Toolbar.*

For our demo, we'll hide all the buttons. That way, the user is presented with a simple blank space where they can sign their name in black, with the default thickness.

## Add an order number variable

To make our demo app a little more realistic, let's pretend like the purpose of the signature is to sign off on an order. So, we create a new `OrderNo` variable and store a random number in it. This represents the order number of the order that the user is signing off on.

![image](/assets/2026-01-22/020.png)

## Add a submit button

Next, we add a *Confirm and Submit to Hub* button. The user presses this button when they are finished with their signature and are ready to upload it to Peakboard Hub.

### Create the script

Now, let's create the tapped script for the button. Here's what the finished script looks like:

![image](/assets/2026-01-22/030.png)

The main function that we use is *CONTROLS > Screen1 > Groups > Save screenshot in Peakboard Hub*. We use this function to capture a screenshot of the `SignGroup` group. `SignGroup` only contains our drawing area control, so the screenshot will only contain the user's signature.

We also set the folder and filename to save the screenshot under, inside Peakboard Hub. We construct the filename by combining the value of the `OrderNo` variable and the current timestamp.

Of course, you can also choose to send the screenshot elsewhere, like Sharepoint or an email address. All you have to do is choose one of the other Building Blocks, under *CONTROLS > Screen1 > Groups.* You can even converting the screenshot to Base64, by using *Generate a Base64 string.* Then, you can send it to any arbitrary external system.

## Result

Now, let's take a look at the finished app. First, we sign our name and submit the signature:

![image](/assets/2026-01-22/040.png)

Inside our Peakboard Hub's filesystem, we see that the signature was successfully uploaded:

![image](/assets/2026-01-22/050.png)



