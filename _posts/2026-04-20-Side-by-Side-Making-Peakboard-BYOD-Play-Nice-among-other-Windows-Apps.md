---
layout: post
title: Side-by-Side - Making Peakboard BYOD Play Nice among other Windows Apps
date: 2026-04-20 00:00:00 +0200
tags: administration
image: /assets/2026-04-20/title.png
bg_alternative: true
read_more_links:
  - name: Desktop Toolbox Extension
    url: https://templates.peakboard.com/extensions/Desktop-Toolbox/index
  - name: Desktop Toolbox Extension on github
    url: https://github.com/Peakboard/PeakboardExtensions/tree/master/DesktopToolbox
downloads:
  - name: DesktopAppSamples.pbmx
    url: /assets/2026-04-20/DesktopAppSamples.pbmx
---
Peakboard applications are designed to run on tablets, on a Peakboard Box connected to a touch screen, or on other industrial PCs. In all of these scenarios, they are typically the sole application on the machine, running in full screen mode. The user usually doesn't know or see that there is a Windows OS in the background that actually allows multiple Windows apps on a single desktop. In this article, we will discuss how to use a Peakboard application on a Windows desktop alongside other applications. This usage pattern is not very common, but it can come in handy for certain use cases.

## Setup

To set up the runtime, we just use a regular BYOD installation as described in [this article](https://how-to-dismantle-a-peakboard-box.com/Peakboard-BYOD-The-beginners-guide-to-BYOD-setup.html). The runtime can be launched like any other Windows application by running `Peakboard.Runtime.WPF.exe`. It can only be started once. After the runtime has booted, it shows the last activated application. If we want to switch between applications, we can simply double-click on a pbmx file in the Windows Explorer.

Besides the runtime itself, there are two Windows services: the Peakboard Management Service and the Peakboard Webserver. They are necessary to access the BYOD instance like any other Peakboard instance through the Designer or the Hub, both locally and remotely.

If we don't need any kind of external control of the application through Hub or Designer, we can also stop the two Windows services and just run the runtime as a normal Windows executable.

## Controlling the window

To gain control over the window of the Peakboard application, there are several Building Blocks available for switching the window between minimized, full screen, and window mode.

If we want the application to start in non-full-screen mode, we just place the corresponding Building Block into the activation script of the startup screen.

![Peakboard Building Blocks for switching the application window from full screen to window mode](/assets/2026-04-20/peakboard-building-blocks-switch-window-fullscreen-mode.png)

In case we need to bring the Peakboard application to the foreground, there is also a corresponding Building Block for that.

![Peakboard Building Blocks showing application window controls like bring to front, minimize, window mode, and fullscreen](/assets/2026-04-20/peakboard-building-blocks-application-window-controls.png)

## The Desktop Toolbox extension

For getting more information about the operating system environment of the end user, we can use the [Desktop Toolbox extension](https://templates.peakboard.com/extensions/Desktop-Toolbox/index). As the name implies, it offers a set of tools and functions around the topic of using a Peakboard application alongside other applications. The data source itself provides the current Windows user name and the operating system version. More functions will probably be added in the future.

![Peakboard Designer Desktop Toolbox extension data source configuration with Windows user name and OS version preview](/assets/2026-04-20/peakboard-desktop-toolbox-extension-data-source-configuration.png)

## Opening a browser

For opening a browser outside of the Peakboard application, we can use the corresponding custom function of the Desktop Toolbox extension.

For more custom functions that are available in the toolbox, check out the GitHub documentation for this extension: [Desktop Toolbox Extension on GitHub](https://github.com/Peakboard/PeakboardExtensions/tree/master/DesktopToolbox).

![Peakboard Building Blocks calling the OpenURLInBrowser custom function to launch an external browser from the application](/assets/2026-04-20/peakboard-building-blocks-open-url-external-browser.png)

