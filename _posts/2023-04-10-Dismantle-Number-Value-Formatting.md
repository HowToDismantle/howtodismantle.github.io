---
layout: post
title: Dismantle Number Value Formatting
date: 2023-04-10 12:00:00 +0200
tags: bestpractice basics
image: /assets/2023-04-10/title.png
outdated: true
---
**Please note, that the content of this article might not be aligned with the latest version of Pakboard designer or runtime but applies to an older version**

Displaying numbers in the correct format is one of the fundamental tasks of building a board. The basic features of number formatting in Peakboard are quite easy and well documented. Please check out the [documentation](https://help.peakboard.com/misc/en-formating-values.html), if you're not familiar with the formatting combo box that can be found everywhere.
This article digs a bit deeper into how to format a number when options in the combo box are insufficient.

*Please note: It's on the 2023 roadmap to rework the entire system of formatting numbers in Peakboard. This article uses the March 2023 version of Peakboard.*

Besides the standard formatting from the combo box, there is an option to build your own formatting pattern. A formatting pattern consists of the pattern itself (represented by characters like `#`, `0`, etc.), and the _locale_. The _locale_ represents the cultural background of the format, e.g. Germans use a `,` as a decimal separator, while Americans use a `.`.

Let's start with a simple example. The pattern `##.##` says that we want two digits before and two digits after the decimal separator.

![image](/assets/2023-04-10/010.png)

So if the locale is `de-DE` for Germany, it will generate `12,34`. If the locale is `en-US` for American, it will generate `12.34`.

The next formatting character to understand is `0`. `0` is almost the same as `#`, but it will print a `0` if the original number doesn't have enough digits. The number `12` will be turned into `12` when applying `###`, but it will be turned into `012` when applying `000`. So you can easily get leading zeros, if you want some.

![image](/assets/2023-04-10/020.png)

In lots of cases, it may be necessary to provide a unit along with the number. Feel free to just add it to the pattern. You can do this even with Unicode characters like a degree symbol.

![image](/assets/2023-04-10/030.png)

Here is our sample in action. BTW: the source is a public OPC UA server; feel free to download the sample pbmx and play around with it yourself....

![image](/assets/2023-04-10/title.png)

## Is there even more formatting madness?

Yes, there's a lot more you can do to format your numbers as perfectly as possible.
The format strings we learned about in this article are only a small subset of what is possible. Please check out the [official documentation provided by Microsoft](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-numeric-format-strings). All the option are available in Peakboard.

