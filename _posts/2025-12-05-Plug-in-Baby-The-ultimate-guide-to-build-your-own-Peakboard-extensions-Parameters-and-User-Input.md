---
layout: post
title: Plug-in, Baby - The Ultimate Guide to Building Your Own Peakboard Extensions - Parameters and User Input
date: 2023-03-01 00:00:00 +0000
tags: dev
image: /assets/2025-12-05/title.png
image_header: /assets/2025-12-05/title.png
bg_alternative: true
read_more_links:
  - name: Other developer articles
    url: /category/dev
  - name: Extension template for Visual Studio
    url: https://marketplace.visualstudio.com/items?itemName=Peakboard.PBEKTEMP
downloads:
  - name: Source code for this article
    url: https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension
---
In the first part of the series we learned how to build the frame of a Peakboard extension. We used two classes to provide both metadata and the actual payload that is exchanged between the extension and the Peakboard application. Here's an overview of this article series:

* [Part I - The Basics](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html)
* [Part II - Parameters and User Input](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html)
* [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html)
* [Part IV - Event-triggered data sources](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Event-triggered-data-sources.html)

In today's article we will talk about how to build a user interface to let the user configure the extension. Typical parameters would be a URL or credentials to the source system. The understanding of the frame we discussed in the first part of the series is a crucial requirement. The sample code used in this article can be found at [github](https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension).

## Add a simple parameter

To add a parameter we will need to adjust the `GetDefinitionOverride` override and just add it to the `PropertyInputDefaults` collection and also set the `PropertyInputPossible` to true. In this example we will add a very simple text parameter named `CatsName` to our list.

{% highlight csharp %}
protected override CustomListDefinition GetDefinitionOverride()
{
    return new CustomListDefinition
    {
        ID = "CatCustomList",
        Name = "Cat List",
        Description = "A custom list for cats with breed and age information",
        PropertyInputPossible = true,
        PropertyInputDefaults =
        {
            new CustomListPropertyDefinition { Name = "CatsName", Value = ""}
        }
    };
}
{% endhighlight %}

The screenshot shows how the parameter looks in the Peakboard Designer UI.

![Peakboard custom list text parameter input](/assets/2025-12-05/peakboard-text-parameter-configuration.png)

To access the value of the user input we use the `data` object that is provided in the `GetItemsOverride` function. We can easily access all parameters through the `Properties` collection. The source code also shows how to generate a log entry. It uses the `Log` object to generate messages. All types of messages, for example Info, Verbose, Error, Critical, etc.... are supported in the same way.

{% highlight csharp %}
protected override CustomListObjectElementCollection GetItemsOverride(CustomListData data)
{
    this.Log.Info("Generating cat list items for " + data.Properties["CatsName"]);

    // ....
}
{% endhighlight %}

The extension kit offers a standardized way to check the user input and prevent the data source dialog from being closed when the validation of the values fails. This happens in the overridable function `CheckDataOverride`. In case there's anything wrong with the value we can throw an exception that is routed to the user and prevents the dialog from being closed.

{% highlight csharp %}
protected override void CheckDataOverride(CustomListData data)
{
    if (string.IsNullOrWhiteSpace(data.Properties["CatsName"]))
    {
        throw new InvalidDataException("Please provide a good name");
    }
    base.CheckDataOverride(data);
}
{% endhighlight %}

## Complex parameters

Besides the simple text parameter we have the option to force the value of a parameter into the other Peakboard data types such as number or bool. All the additional parameter objects are added to the `PropertyInputDefaults` collection.

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "IsItARealCat", Value = "True", TypeDefinition = TypeDefinition.Boolean },
new CustomListPropertyDefinition { Name = "Age", Value = "4", TypeDefinition = TypeDefinition.Number },
{% endhighlight %}

The dialogs to manipulate the data are adjusted automatically according to this meta data.

![Peakboard boolean and number parameter settings](/assets/2025-12-05/peakboard-boolean-number-parameter-settings.png)

Let's assume we want to give the user only a combo box of distinct values to be chosen rather than a free text, we just use the `selectableValues` attribute to restrict the entry to some values.

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MaximumOfSomething", Value = "5", 
      TypeDefinition = TypeDefinition.Number.With(selectableValues: [ 2, 3, 5, 10, 20, 50, 100]) },
{% endhighlight %}

Here's the corresponding view for the user of the extension to provide the distinct values they can choose from:

![Peakboard parameter selectable values dropdown](/assets/2025-12-05/peakboard-selectable-values-dropdown.png)

For passwords, connection strings or other potentially sensitive data, we can use the `TypeDefinition` attribute `masked: true`

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MySecretCode", Value = "18899", TypeDefinition = TypeDefinition.String.With(masked: true) },
{% endhighlight %}

Here's a sample screenshot of a masked parameter:

![image](/assets/2025-12-05/peakboard-masked-parameter-input.png)

The last thing we want to discuss are multliline texts. These are typically used for long SQL statement or JSON / XML fragments.

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MultilineDescription", 
      Value = "Please provide\nsome\nbeautiful SQL", TypeDefinition = TypeDefinition.String.With(multiLine: true) }
{% endhighlight %}

And here's how it looks like as part of the data source dialog UI.

![image](/assets/2025-12-05/peakboard-multiline-parameter.png)

## result

Defining the parameters of an extension with a good UI is a key point to make it as easy as possible for the user to provide his data. We need to choose them wisely :-)

In the next part of our series we learn how to build functions that can be used in both LUA scripts and building blocks: [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html)
