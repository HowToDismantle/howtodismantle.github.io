---
layout: post
title: Breaking the Ice - How SAP Integration Suite and Peakboard Hub Became Best Friends
date: 2025-04-26 03:00:00 +0200
tags: peakboardhub peakboardhubapi sap
image: /assets/2025-04-26/title.png
image_landscape: /assets/2025-04-26/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Peakboard Hub API Swagger portal
    url: https://api.peakboard.com/public-api/index.html
  - name: Peakboard Hub API getting started
    url: /Cracking-the-code-Part-I-Getting-started-with-Peakboard-Hub-API.html
downloads:
  - name: Iflow TransferOrderToPeakboardHub.zip
    url: /assets/2025-04-26/TransferOrderToPeakboardHub.zip
---
The future of SAP is clear: Everything will be cloud based. The age of on-prem SAP systems is over. And when it comes to connecting systems---both SAP and non-SAP---with one another, the best solution is SAP BTP (Business Technology Platform).

A big part of SAP BTP is the SAP Integration Suite. This is where all the API magic happens, and where communication with the outside world is built and configured (more precisely, the outside-of-SAP world). One of the artifacts we can build with the SAP Integration Suite is an integration flow (iFlow). This is what we will do today.

We will build an iFlow that submits a transfer order to Peakboard Hub, and stores it in the transfer order table. That way, we can use the iFlow like a blueprint for general SAP-to-Peakboard-Hub communications.

## Setup

First, we create a simple table in Peakboard Hub to store our transfer orders:

![image](/assets/2025-04-26/010.png)

Next, we get an API key. You can learn how to do this in our [Peakboard Hub API getting started](/Cracking-the-code-Part-I-Getting-started-with-Peakboard-Hub-API.html) article. We also need a valid SAP BTP account.  And finally, we create a new package and a new integration flow. 

## Build the integration flow

We will build an integration flow that does the following:
1. Add a header with our API key.
2. Call Peakboard Hub to get an access token.
3. Convert the response from the access token request into XML.
4. Use XPath to extract the access token from the XML body and store it in a property.
5. Add a header with our access token.
5. Set the request body.
6. Call the Peakboard Hub API to store the values of the transfer order into the table.

Here's what the complete integration flow looks like:

![image](/assets/2025-04-26/020.png)

### Add a header with our API key

For our first step, we add an `apiKey` header that contains our API key.  We need this header in order to get our access token in the next step.

![image](/assets/2025-04-26/030.png)

## Call Peakboard Hub to get an access token

The next step is a request/response block that calls this external URL:

```url
https://api.peakboard.com/public-api/v1/auth/token
```

This Peakboard Hub API call returns an access token.

![image](/assets/2025-04-26/040.png)

## Convert the response from the access token request into XML

We need to get the token from the API response. But processing JSON in an SAP integration flow is tricky. So instead, we will use XPath get the token. In order to use XPath, we first need to convert the response body into XML:

![image](/assets/2025-04-26/050.png)

## Use XPath to extract the access token from the XML body and store it in a property

We apply the XPath command `//AccessToken` to the XML body in order to get the access token and store it in an internal property.

![image](/assets/2025-04-26/060.png)

## Add a header with our access token

We add an `Authorization` header, in order to authenticate our API calls. We set the header to `Bearer`, combined with our access token.

![image](/assets/2025-04-26/070.png)

## Set request body

Our request body needs to be a JSON string with the data that we want to store in the Peakboard Hub table. There are four values we need:
* `FromLocation`
* `ToLocation`
* `MaterialNo`
* `Quantity`

We get these values from the headers of the request sent to our integration flow. This means that the caller of this integration flow can submit their values by putting them into the query string of their API call.

![image](/assets/2025-04-26/080.png)

## Call the Peakboard Hub API to store the values of the transfer order into the table

The final step is to call the table-store endpoint of the Peakboard Hub API:
```url
https://api.peakboard.com/public-api/v1/lists/items
```

In this case, it's a `POST` call. We set the authentication method to **None**, because we're using our header from earlier to authenticate ourselves.

![image](/assets/2025-04-26/090.png)

After completing all these steps, we save and deploy the service.

## Result and test

The following screenshot shows our service handling a call sent from Postman. The values to be stored are submitted as query parameters. They are mapped to the JSON during the process. As you can see, our integration service returns the response body of the Peakboard Hub API. This is done automatically, because this call is last one to be processed in the flow.

![image](/assets/2025-04-26/100.png)

And here's what the data looks like in the Peakboard Hub table:

![image](/assets/2025-04-26/110.png)


