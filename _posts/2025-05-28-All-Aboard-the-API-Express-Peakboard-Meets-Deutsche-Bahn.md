---
layout: post
title: All Aboard the API Express - Peakboard Meets Deutsche Bahn
date: 2023-03-01 03:00:00 +0200
tags: api
image: /assets/2025-05-28/title.png
image_landscape: /assets/2025-05-28/title_landscape.png
bg_alternative: true
read_more_links:
  - name: DBF
    url: https://dbf.finalrewind.org/
downloads:
  - name: DBDepartures.pbmx
    url: /assets/2025-05-28/DBDepartures.pbmx
---
In this blog we already discussed many APIs and how to integrate them with Peakboard. Today we will discuss the API of a website called DBF. They are providing an unofficial endpoint that returns the current arrivals and departure of trains for Germany cities. The website can be found [here](https://dbf.finalrewind.org/). The backend of the service is Open Source. More details on [github](https://github.com/derf/db-fakedisplay). We will use this API to build a board that lists all train departures of a German city and shows it like a public billboard within a train station. The benefit of this article is also to learn more about how to process API payload and turn it into information that is perfectly formatted and presented to the user.

## API call

The API call is quite simple: "https://dbf.finalrewind.org/<xxx>.json" where xxx is the station name. To find out the currect station name we can use the form on the website. It comes up with valid suggestions. If the station contains a blank, we must replace it with "%20", so the endpoint the Stuttgart main station "Stuttgart Hbf" turns into "Stuttgart%20Hbf".

![image](/assets/2025-05-28/010.png)

The screenshots shows the correctly configured data source with some sample data for the main station of the beautiful city of Stuttgart. The station name is set dynamically through a variable.

![image](/assets/2025-05-28/020.png)

## Processing the data

The data from the API endpoint is almost ideal but needs some minor improvements done through a data flow.
First we filter out all cancelled trains.

![image](/assets/2025-05-28/030.png)

In the next step we remove all columns that are not used for the visualisation to make the table clearer and easier to handle. The last column was initially named "Unknown" but it contains information about the train type, so we rename the column to "train".

![image](/assets/2025-05-28/040.png)

In the last step we filter out all trains without a sheduled departure. It seems useless for a train departure billboard.

![image](/assets/2025-05-28/050.png)

## Building the screen

For the actual screen we go fo a styled list with some text boxes and images. The pbmx is downloadable [here](/assets/2025-05-28/DBDepartures.pbmx) for more details.

![image](/assets/2025-05-28/060.png)

Most logic is done through conditional formatting. The screenshot shows how the train type generate different symbols depending if it's a long distance or local train.

![image](/assets/2025-05-28/070.png)

## result

The last screenshot shows the result with all the different colors and other functions to visualize the information. It's a very nice example how to do all important formatting tasks without any coding. Just by conditional formatting.

![image](/assets/2025-05-28/080.png)
