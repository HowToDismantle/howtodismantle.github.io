---
layout: post
title: Peakboard UI Hacks - Next-Level Custom Dialogs
date: 2025-08-24 05:00:00 +0300
tags: ui bestpractice
image: /assets/2025-08-24/title.png
image_header: /assets/2025-08-24/title_landscape.png
bg_alternative: true
read_more_links:
  - name: UI - User Interface
    url: /category/ui
downloads:
  - name: CustomDialogs.pbmx
    url: /assets/2025-08-24/CustomDialogs.pbmx
---
Every Peakboard application is built around one or more screens. These screens are like the windows in a traditional desktop application. However, we sometimes want to have a [modal window](https://en.wikipedia.org/wiki/Modal_window) that forces the user to interact with it, before they can do anything else.

For example, we might want a modal window that forces the user read a warning and acknowledge that they have read it---before proceeding.

In Peakboard Designer, we can create a modal window by building a *custom dialog*. In this article, we'll explain the best practices around custom dialogs.

## Overview

The core idea is to build a custom dialog using multiple controls. But, we make the controls invisible, so the user doesn't see them. Then, when we want the dialog to show up, we make the controls visible. Let's go through this step by step with an example.

We'll make a simple app that prompts the user to enter their name. Here's what the finished app looks like:
![image](/assets/2025-08-24/result.gif)

Here's how it works:
1. The user clicks on the *Call me by my name* button.
1. A dialog pops up and asks the user to enter their name.
1. The user enters their name into the dialog and clicks *OK*.
1. The dialog goes away.
1. The user's name is displayed.

Now, let's build the app.

## Add the controls

First, we add the following controls to the app:
1. A button that initiates the modal dialog. We label it, *Call me by my name*.
1. Controls for the dialog:
  * A rectangle shape for the background of the dialog.
  * A text box that prompts the user, *Please type in your name*.
  * A text input where the user enters their name.
  * A button for the user to submit their name, labelled *OK*.

![image](/assets/2025-08-24/010.png)

Next, we group the dialog controls together, by doing the following:
1. We drag and drop one control on top of another, in the control tree on the left side. This automatically creates a new control group.
1. We drag the rest of the controls into the group.
1. We rename the group to `MyDialogGroup`.

Now, we can easily make the entire dialog visible and invisible.

![image](/assets/2025-08-24/020.png)

Next, we right click the control group and select *Hide*. 

![image](/assets/2025-08-24/030.png)

This makes the dialog invisible by default. We will use Building Blocks to make it visible.

## Add the Building Blocks

We add two Building Blocks scripts---one for each button.

### The *Call me by my name* button

The *Call me by my name* button initiates the modal dialog. So, we use a Building Block that makes `MyDialogGroup` visible, when the button is clicked:

![image](/assets/2025-08-24/040.png)

### The *OK* button

The *OK* button does two things:
1. Display the user's name as a notification.
1. Make the modal dialog hidden.

So, this is what the Building Blocks look like:
![image](/assets/2025-08-24/050.png)

## Result

Let's take another look at the end result. With the techniques we showed off in this article, it's easy to build all sorts of user input and alert dialogs in Peakboard!

![image](/assets/2025-08-24/result.gif)